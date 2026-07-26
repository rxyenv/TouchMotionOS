//! tomoro-store: Unix socket daemon bridging Flutter ↔ game downloads/launches.
//!
//! Socket: /run/tomoro/store.sock (TOMORO_SOCK env to override)
//! Backend: TOMORO_BACKEND env (default: http://localhost:8000)
//! Games dir: /var/lib/tomoro/games/ (TOMORO_GAMES_DIR env to override)
//!
//! Protocol: newline-delimited JSON both directions.

use std::{
    collections::HashMap,
    path::{Path, PathBuf},
    sync::Arc,
};

use flate2::read::GzDecoder;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tokio::{
    fs,
    io::{AsyncBufReadExt, AsyncWriteExt, BufReader},
    net::{UnixListener, UnixStream},
    sync::{broadcast, Mutex},
};

// ── config ───────────────────────────────────────────────────────────────────

fn sock_path() -> String {
    std::env::var("TOMORO_SOCK").unwrap_or_else(|_| "/run/tomoro/store.sock".to_string())
}

fn backend_url() -> String {
    std::env::var("TOMORO_BACKEND").unwrap_or_else(|_| "http://localhost:8000".to_string())
}

fn games_dir() -> PathBuf {
    PathBuf::from(
        std::env::var("TOMORO_GAMES_DIR").unwrap_or_else(|_| "/var/lib/tomoro/games".to_string()),
    )
}

fn manifest_path() -> PathBuf {
    PathBuf::from(
        std::env::var("TOMORO_GAMES_DIR").unwrap_or_else(|_| "/var/lib/tomoro".to_string()),
    )
    .join("manifest.json")
}

// ── types ────────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
struct GameMeta {
    id: String,
    version: String,
    download_url: String,
    binary: String,
    size_bytes: u64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct ManifestEntry {
    version: String,
    binary: String,
    installed_at: String,
}

type Manifest = HashMap<String, ManifestEntry>;

#[derive(Clone, Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum Event {
    List {
        games: Vec<ListGame>,
    },
    Progress {
        id: String,
        pct: u8,
        bytes_done: u64,
        bytes_total: u64,
    },
    Installed {
        id: String,
    },
    Error {
        id: String,
        msg: String,
    },
    Launched {
        id: String,
    },
}

#[derive(Clone, Debug, Serialize)]
struct ListGame {
    id: String,
    version: String,
    installed: bool,
}

// ── manifest helpers ──────────────────────────────────────────────────────────

async fn read_manifest() -> Manifest {
    let path = manifest_path();
    let Ok(text) = fs::read_to_string(&path).await else {
        return HashMap::new();
    };
    let Ok(val) = serde_json::from_str::<Value>(&text) else {
        return HashMap::new();
    };
    val.get("games")
        .and_then(|v| serde_json::from_value(v.clone()).ok())
        .unwrap_or_default()
}

async fn write_manifest(manifest: &Manifest) -> std::io::Result<()> {
    let path = manifest_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).await?;
    }
    let json = serde_json::json!({ "games": manifest });
    fs::write(&path, serde_json::to_string_pretty(&json).unwrap()).await
}

// ── download + install ────────────────────────────────────────────────────────

async fn install_game(
    id: String,
    meta: GameMeta,
    tx: broadcast::Sender<(Option<String>, Event)>,
    client_id: Option<String>,
) {
    let dir = games_dir();
    let part_path = dir.join(format!("{}.tar.gz.part", id));
    let game_dir = dir.join(&id);

    if let Err(e) = fs::create_dir_all(&dir).await {
        let _ = tx.send((client_id.clone(), Event::Error { id: id.clone(), msg: e.to_string() }));
        return;
    }

    // download
    let client = reqwest::Client::new();
    let resp = match client.get(&meta.download_url).send().await {
        Ok(r) => r,
        Err(e) => {
            let _ = tx.send((client_id, Event::Error { id, msg: format!("download failed: {e}") }));
            return;
        }
    };

    let total = meta.size_bytes.max(1);
    let mut downloaded: u64 = 0;
    let mut last_pct: u8 = 255;

    let mut file = match tokio::fs::File::create(&part_path).await {
        Ok(f) => f,
        Err(e) => {
            let _ = tx.send((client_id, Event::Error { id, msg: e.to_string() }));
            return;
        }
    };

    use futures_util::StreamExt;
    let mut stream = resp.bytes_stream();
    let mut last_progress = std::time::Instant::now();

    while let Some(chunk) = stream.next().await {
        let chunk: bytes::Bytes = match chunk {
            Ok(c) => c,
            Err(e) => {
                let _ = tx.send((client_id, Event::Error { id, msg: format!("stream error: {e}") }));
                return;
            }
        };
        if let Err(e) = file.write_all(&chunk).await {
            let _ = tx.send((client_id, Event::Error { id, msg: e.to_string() }));
            return;
        }
        downloaded += chunk.len() as u64;

        if last_progress.elapsed().as_secs() >= 1 {
            let pct = ((downloaded * 100) / total).min(100) as u8;
            if pct != last_pct {
                last_pct = pct;
                let _ = tx.send((
                    client_id.clone(),
                    Event::Progress { id: id.clone(), pct, bytes_done: downloaded, bytes_total: total },
                ));
            }
            last_progress = std::time::Instant::now();
        }
    }
    drop(file);

    // extract
    let part_path_clone = part_path.clone();
    let game_dir_clone = game_dir.clone();
    let id_clone = id.clone();
    let extract_result = tokio::task::spawn_blocking(move || {
        let file = std::fs::File::open(&part_path_clone)?;
        let gz = GzDecoder::new(file);
        let mut archive = tar::Archive::new(gz);
        std::fs::create_dir_all(&game_dir_clone)?;
        archive.unpack(&game_dir_clone)?;
        std::fs::remove_file(&part_path_clone)?;
        Ok::<_, std::io::Error>(())
    })
    .await;

    match extract_result {
        Ok(Ok(())) => {}
        Ok(Err(e)) => {
            let _ = tx.send((client_id, Event::Error { id, msg: format!("extract failed: {e}") }));
            return;
        }
        Err(e) => {
            let _ = tx.send((client_id, Event::Error { id, msg: format!("task panic: {e}") }));
            return;
        }
    }

    // update manifest
    let mut manifest = read_manifest().await;
    manifest.insert(
        id.clone(),
        ManifestEntry {
            version: meta.version,
            binary: meta.binary,
            installed_at: chrono_now(),
        },
    );
    if let Err(e) = write_manifest(&manifest).await {
        let _ = tx.send((client_id, Event::Error { id, msg: format!("manifest write failed: {e}") }));
        return;
    }

    let _ = tx.send((client_id, Event::Installed { id }));
}

fn chrono_now() -> String {
    // RFC3339 without pulling in chrono — format manually from SystemTime
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs();
    // minimal ISO8601 UTC
    let s = secs;
    let sec = s % 60;
    let min = (s / 60) % 60;
    let hour = (s / 3600) % 24;
    let days = s / 86400;
    // Approximate date from epoch days (good enough for manifest timestamps)
    let (y, m, d) = days_to_ymd(days);
    format!("{y:04}-{m:02}-{d:02}T{hour:02}:{min:02}:{sec:02}Z")
}

fn days_to_ymd(mut days: u64) -> (u64, u64, u64) {
    let mut y = 1970u64;
    loop {
        let leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);
        let dy = if leap { 366 } else { 365 };
        if days < dy {
            break;
        }
        days -= dy;
        y += 1;
    }
    let leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);
    let mdays = [31u64, if leap { 29 } else { 28 }, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    let mut m = 0usize;
    for &md in &mdays {
        if days < md {
            break;
        }
        days -= md;
        m += 1;
    }
    (y, (m + 1) as u64, days + 1)
}

// ── launch ────────────────────────────────────────────────────────────────────

async fn launch_game(id: &str) -> Result<(), String> {
    let manifest = read_manifest().await;
    let entry = manifest.get(id).ok_or_else(|| format!("game '{id}' not installed"))?;
    let binary = games_dir().join(id).join(&entry.binary);
    tokio::process::Command::new("steam-run")
        .arg(&binary)
        .spawn()
        .map_err(|e| format!("spawn failed: {e}"))?;
    Ok(())
}

// ── connection handler ────────────────────────────────────────────────────────

async fn handle_client(
    stream: UnixStream,
    tx: broadcast::Sender<(Option<String>, Event)>,
    client: reqwest::Client,
    backend: String,
    client_id: String,
) {
    let mut rx = tx.subscribe();
    let (read_half, mut write_half) = stream.into_split();
    let mut lines = BufReader::new(read_half).lines();
    let cid = client_id.clone();

    // read commands
    let tx_cmd = tx.clone();
    let client_cmd = client.clone();
    let backend_cmd = backend.clone();
    let cid_cmd = cid.clone();
    tokio::spawn(async move {
        while let Ok(Some(line)) = lines.next_line().await {
            let Ok(val) = serde_json::from_str::<Value>(&line) else { continue };
            let cmd = val.get("cmd").and_then(Value::as_str).unwrap_or("");
            match cmd {
                "list" => {
                    let manifest = read_manifest().await;
                    let games = manifest
                        .iter()
                        .map(|(id, e)| ListGame {
                            id: id.clone(),
                            version: e.version.clone(),
                            installed: true,
                        })
                        .collect();
                    let _ = tx_cmd.send((Some(cid_cmd.clone()), Event::List { games }));
                }
                "install" => {
                    let Some(id) = val.get("id").and_then(Value::as_str) else { continue };
                    let url = format!("{}/catalog/{}", backend_cmd, id);
                    match client_cmd.get(&url).send().await {
                        Ok(resp) => match resp.json::<GameMeta>().await {
                            Ok(meta) => {
                                let id = id.to_string();
                                let tx2 = tx_cmd.clone();
                                let cid2 = cid_cmd.clone();
                                tokio::spawn(async move {
                                    install_game(id, meta, tx2, Some(cid2)).await;
                                });
                            }
                            Err(e) => {
                                let _ = tx_cmd.send((
                                    Some(cid_cmd.clone()),
                                    Event::Error { id: id.to_string(), msg: format!("metadata parse failed: {e}") },
                                ));
                            }
                        },
                        Err(e) => {
                            let _ = tx_cmd.send((
                                Some(cid_cmd.clone()),
                                Event::Error { id: id.to_string(), msg: format!("metadata fetch failed: {e}") },
                            ));
                        }
                    }
                }
                "cancel" => {
                    // TODO: cooperative cancellation via CancellationToken per download
                }
                "launch" => {
                    let Some(id) = val.get("id").and_then(Value::as_str) else { continue };
                    match launch_game(id).await {
                        Ok(()) => {
                            let _ = tx_cmd.send((Some(cid_cmd.clone()), Event::Launched { id: id.to_string() }));
                        }
                        Err(msg) => {
                            let _ = tx_cmd.send((Some(cid_cmd.clone()), Event::Error { id: id.to_string(), msg }));
                        }
                    }
                }
                _ => {}
            }
        }
    });

    // forward events to this client
    loop {
        match rx.recv().await {
            Ok((target, event)) => {
                let send = match &target {
                    None => true,
                    Some(t) => t == &cid,
                };
                if send {
                    let mut line = serde_json::to_string(&event).unwrap();
                    line.push('\n');
                    if write_half.write_all(line.as_bytes()).await.is_err() {
                        break;
                    }
                }
            }
            Err(broadcast::error::RecvError::Lagged(_)) => continue,
            Err(broadcast::error::RecvError::Closed) => break,
        }
    }
}

// ── main ──────────────────────────────────────────────────────────────────────

#[tokio::main]
async fn main() {
    let sock = sock_path();
    let backend = backend_url();

    // remove stale socket
    let _ = std::fs::remove_file(&sock);
    if let Some(parent) = Path::new(&sock).parent() {
        std::fs::create_dir_all(parent).ok();
    }

    let listener = UnixListener::bind(&sock).expect("bind Unix socket");
    eprintln!("tomoro-store listening on {sock}");

    let (tx, _) = broadcast::channel::<(Option<String>, Event)>(256);
    let http = reqwest::Client::new();
    let mut next_id: u64 = 0;

    loop {
        match listener.accept().await {
            Ok((stream, _)) => {
                next_id += 1;
                let cid = next_id.to_string();
                tokio::spawn(handle_client(
                    stream,
                    tx.clone(),
                    http.clone(),
                    backend.clone(),
                    cid,
                ));
            }
            Err(e) => eprintln!("accept error: {e}"),
        }
    }
}
