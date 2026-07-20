//! Detects network interfaces on the appliance by walking `/sys/class/net`.
//!
//! Classification: an interface with a `wireless/` sysfs directory is wifi;
//! otherwise ARPHRD_ETHER (`type == 1`) is ethernet. Loopback and virtual
//! interfaces without a device backing are ignored.

use std::ffi::CStr;
use std::fs;
use std::path::Path;
use std::process::Command;

use serde::Serialize;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Kind {
    Ethernet,
    Wifi,
}

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct Interface {
    pub name: String,
    pub kind: Kind,
    /// Administratively up (IFF_UP via operstate/flags).
    pub up: bool,
    /// Physical link detected (cable plugged / associated to AP).
    pub carrier: bool,
    pub ipv4: Vec<String>,
    pub ipv6: Vec<String>,
    pub mac: Option<String>,
    /// Wifi only; best effort via `iw`, None when unavailable.
    pub ssid: Option<String>,
    /// Wifi only; dBm from /proc/net/wireless.
    pub signal_dbm: Option<i32>,
}

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct Status {
    pub interfaces: Vec<Interface>,
    /// True when at least one interface has carrier and an IPv4 address.
    pub online: bool,
}

pub fn status() -> Status {
    let mut interfaces = detect_interfaces();
    let addrs = if_addresses();
    for iface in &mut interfaces {
        if let Some((v4, v6)) = addrs.iter().find(|(name, _)| name == &iface.name).map(|(_, a)| a) {
            iface.ipv4 = v4.clone();
            iface.ipv6 = v6.clone();
        }
        if iface.kind == Kind::Wifi {
            iface.signal_dbm = wireless_signal(&iface.name);
            iface.ssid = wifi_ssid(&iface.name);
        }
    }
    let online = interfaces.iter().any(|i| i.carrier && !i.ipv4.is_empty());
    Status { interfaces, online }
}

fn detect_interfaces() -> Vec<Interface> {
    let mut out = Vec::new();
    let Ok(entries) = fs::read_dir("/sys/class/net") else {
        return out;
    };
    for entry in entries.flatten() {
        let name = entry.file_name().to_string_lossy().into_owned();
        let base = entry.path();
        let kind = if base.join("wireless").is_dir() {
            Kind::Wifi
        } else if read_trim(&base.join("type")).as_deref() == Some("1")
            && base.join("device").exists()
        {
            Kind::Ethernet
        } else {
            continue; // loopback, bridges, tunnels, etc.
        };
        let operstate = read_trim(&base.join("operstate")).unwrap_or_default();
        // carrier reads fail with EINVAL while the interface is down.
        let carrier = read_trim(&base.join("carrier")).as_deref() == Some("1");
        out.push(Interface {
            name,
            kind,
            up: operstate != "down",
            carrier,
            ipv4: Vec::new(),
            ipv6: Vec::new(),
            mac: read_trim(&base.join("address")),
            ssid: None,
            signal_dbm: None,
        });
    }
    out.sort_by(|a, b| a.name.cmp(&b.name));
    out
}

fn read_trim(path: &Path) -> Option<String> {
    fs::read_to_string(path).ok().map(|s| s.trim().to_string())
}

type AddrsByIface = Vec<(String, (Vec<String>, Vec<String>))>;

/// IPv4/IPv6 addresses per interface via getifaddrs(3).
fn if_addresses() -> AddrsByIface {
    let mut out: AddrsByIface = Vec::new();
    unsafe {
        let mut ifap: *mut libc::ifaddrs = std::ptr::null_mut();
        if libc::getifaddrs(&mut ifap) != 0 {
            return out;
        }
        let mut cur = ifap;
        while !cur.is_null() {
            let ifa = &*cur;
            cur = ifa.ifa_next;
            if ifa.ifa_addr.is_null() {
                continue;
            }
            let name = CStr::from_ptr(ifa.ifa_name).to_string_lossy().into_owned();
            let family = (*ifa.ifa_addr).sa_family as i32;
            let addr = match family {
                libc::AF_INET => {
                    let sa = &*(ifa.ifa_addr as *const libc::sockaddr_in);
                    Some((
                        std::net::Ipv4Addr::from(u32::from_be(sa.sin_addr.s_addr)).to_string(),
                        true,
                    ))
                }
                libc::AF_INET6 => {
                    let sa = &*(ifa.ifa_addr as *const libc::sockaddr_in6);
                    Some((std::net::Ipv6Addr::from(sa.sin6_addr.s6_addr).to_string(), false))
                }
                _ => None,
            };
            if let Some((ip, is_v4)) = addr {
                let slot = match out.iter_mut().find(|(n, _)| n == &name) {
                    Some((_, a)) => a,
                    None => {
                        out.push((name, (Vec::new(), Vec::new())));
                        &mut out.last_mut().unwrap().1
                    }
                };
                if is_v4 {
                    slot.0.push(ip);
                } else {
                    slot.1.push(ip);
                }
            }
        }
        libc::freeifaddrs(ifap);
    }
    out
}

/// Signal level in dBm from /proc/net/wireless, e.g. line
/// `wlan0: 0000   54.  -56.  -256        0 ...`
fn wireless_signal(iface: &str) -> Option<i32> {
    let content = fs::read_to_string("/proc/net/wireless").ok()?;
    for line in content.lines().skip(2) {
        let mut parts = line.split_whitespace();
        let name = parts.next()?.trim_end_matches(':');
        if name != iface {
            continue;
        }
        // fields: status, link, level, noise
        let level = parts.nth(2)?;
        return level.trim_end_matches('.').parse::<f64>().ok().map(|v| v as i32);
    }
    None
}

/// SSID via `iw dev <iface> link`; None when `iw` missing or not associated.
fn wifi_ssid(iface: &str) -> Option<String> {
    let out = Command::new("iw").args(["dev", iface, "link"]).output().ok()?;
    if !out.status.success() {
        return None;
    }
    String::from_utf8_lossy(&out.stdout)
        .lines()
        .find_map(|l| l.trim().strip_prefix("SSID: ").map(str::to_string))
}

// ---- wifi control via wpa_supplicant (wpa_cli) ----

#[derive(Debug, Clone, Serialize)]
pub struct WifiNetwork {
    pub ssid: String,
    pub bssid: String,
    pub signal_dbm: i32,
    /// True when the AP requires a passphrase (WPA/WEP flags present).
    pub secured: bool,
}

#[derive(Debug)]
pub enum WifiError {
    Command(String),
    Failed(String),
}

impl std::fmt::Display for WifiError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            WifiError::Command(e) => write!(f, "wpa_cli unavailable: {e}"),
            WifiError::Failed(e) => write!(f, "{e}"),
        }
    }
}

fn wpa_cli(iface: &str, args: &[&str]) -> Result<String, WifiError> {
    let out = Command::new("wpa_cli")
        .arg("-p")
        .arg("/run/wpa_supplicant/control")
        .arg("-i")
        .arg(iface)
        .args(args)
        .output()
        .map_err(|e| WifiError::Command(e.to_string()))?;
    let stdout = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if !out.status.success() || stdout.starts_with("FAIL") {
        return Err(WifiError::Failed(format!(
            "wpa_cli {} failed: {}",
            args.join(" "),
            if stdout.is_empty() {
                String::from_utf8_lossy(&out.stderr).trim().to_string()
            } else {
                stdout
            }
        )));
    }
    Ok(stdout)
}

/// Trigger a scan and return visible networks, strongest first,
/// deduplicated by SSID.
pub fn scan(iface: &str) -> Result<Vec<WifiNetwork>, WifiError> {
    // OK or FAIL-BUSY (scan already running) both mean results are coming.
    match wpa_cli(iface, &["scan"]) {
        Ok(_) => {}
        Err(WifiError::Failed(msg)) if msg.contains("FAIL-BUSY") => {}
        Err(e) => return Err(e),
    }
    std::thread::sleep(std::time::Duration::from_secs(3));
    let raw = wpa_cli(iface, &["scan_results"])?;
    let mut nets: Vec<WifiNetwork> = Vec::new();
    // Format: bssid \t frequency \t signal \t flags \t ssid
    for line in raw.lines().skip(1) {
        let fields: Vec<&str> = line.split('\t').collect();
        if fields.len() < 5 {
            continue;
        }
        let ssid = fields[4].trim();
        if ssid.is_empty() {
            continue; // hidden network
        }
        let signal: i32 = fields[2].parse().unwrap_or(-100);
        let secured = fields[3].contains("WPA") || fields[3].contains("WEP");
        match nets.iter_mut().find(|n| n.ssid == ssid) {
            Some(existing) if existing.signal_dbm < signal => {
                existing.signal_dbm = signal;
                existing.bssid = fields[0].to_string();
                existing.secured = secured;
            }
            Some(_) => {}
            None => nets.push(WifiNetwork {
                ssid: ssid.to_string(),
                bssid: fields[0].to_string(),
                signal_dbm: signal,
                secured,
            }),
        }
    }
    nets.sort_by_key(|n| -n.signal_dbm);
    Ok(nets)
}

/// Connect to an SSID; `psk` None for open networks. Persists the network
/// via save_config so it survives reboot. Blocks until COMPLETED or ~20s
/// timeout, removing the network entry on failure (e.g. wrong password).
pub fn connect(iface: &str, ssid: &str, psk: Option<&str>) -> Result<(), WifiError> {
    // Drop any stale entry for the same SSID first.
    forget(iface, ssid).ok();

    let id = wpa_cli(iface, &["add_network"])?;
    let id = id.trim();
    let quoted_ssid = format!("\"{}\"", ssid.replace('"', "\\\""));
    let cleanup = |e: WifiError| {
        wpa_cli(iface, &["remove_network", id]).ok();
        e
    };
    wpa_cli(iface, &["set_network", id, "ssid", &quoted_ssid]).map_err(cleanup)?;
    match psk {
        Some(p) => {
            let quoted = format!("\"{}\"", p.replace('"', "\\\""));
            wpa_cli(iface, &["set_network", id, "psk", &quoted]).map_err(cleanup)?
        }
        None => wpa_cli(iface, &["set_network", id, "key_mgmt", "NONE"]).map_err(cleanup)?,
    };
    wpa_cli(iface, &["enable_network", id]).map_err(cleanup)?;
    wpa_cli(iface, &["select_network", id]).map_err(cleanup)?;

    for _ in 0..40 {
        std::thread::sleep(std::time::Duration::from_millis(500));
        let status = wpa_cli(iface, &["status"])?;
        if status.contains("wpa_state=COMPLETED") {
            // Re-enable other saved networks disabled by select_network.
            wpa_cli(iface, &["enable_network", "all"]).ok();
            wpa_cli(iface, &["save_config"]).ok();
            return Ok(());
        }
    }
    wpa_cli(iface, &["remove_network", id]).ok();
    Err(WifiError::Failed(format!(
        "could not join '{ssid}' (wrong password or out of range)"
    )))
}

/// Remove all saved entries matching the SSID.
pub fn forget(iface: &str, ssid: &str) -> Result<(), WifiError> {
    let raw = wpa_cli(iface, &["list_networks"])?;
    let mut removed = false;
    for line in raw.lines().skip(1) {
        let fields: Vec<&str> = line.split('\t').collect();
        if fields.len() >= 2 && fields[1] == ssid {
            wpa_cli(iface, &["remove_network", fields[0]])?;
            removed = true;
        }
    }
    if removed {
        wpa_cli(iface, &["save_config"]).ok();
    }
    Ok(())
}
