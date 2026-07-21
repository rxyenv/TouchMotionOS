import sys
sys.stdout.reconfigure(line_buffering=True, write_through=True)

import cv2
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
import numpy as np
import math
import time
import json
import socket
import threading
import struct
import os
import urllib.request
from typing import Optional
from fastapi import FastAPI
from pydantic import BaseModel

# ================= POSE INDEX =================
POSE_IDX = {
    "LEFT_SHOULDER": 11, "RIGHT_SHOULDER": 12, "LEFT_ELBOW": 13, "RIGHT_ELBOW": 14,
    "LEFT_WRIST": 15, "RIGHT_WRIST": 16, "LEFT_PINKY": 17, "RIGHT_PINKY": 18,
    "LEFT_INDEX": 19, "RIGHT_INDEX": 20, "LEFT_THUMB": 21, "RIGHT_THUMB": 22,
    "LEFT_HIP": 23, "RIGHT_HIP": 24, "LEFT_KNEE": 25, "RIGHT_KNEE": 26,
    "LEFT_ANKLE": 27, "RIGHT_ANKLE": 28, "LEFT_HEEL": 29, "RIGHT_HEEL": 30,
    "LEFT_FOOT_INDEX": 31, "RIGHT_FOOT_INDEX": 32
}

MODEL_PATH = "/var/lib/tomoro-server/pose_landmarker_full.task"
MODEL_URL = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task"

# ================= HARD LOGGER =================
def log(msg):
    ts = time.strftime("%H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open("pose_debug.log", "a") as f:
        f.write(line + "\n")

# ================= CONFIG =================
CONFIG = {
    "CAM_INDEX": 0,
    "PCK_THRESHOLD": 0.2,
    "REFERENCE_FRAMES": 60,
    "enable_segmentation": False,
    "min_detection_confidence": 0.5,
    "min_tracking_confidence": 0.5,
    "debug": True,
    "UDP_IP": "127.0.0.1",
    "UDP_PORT": 5005,
    "JPEG_QUALITY": 60,
    "TARGET_FPS": 30,
    "UDP_CHUNK_SIZE": 700
}

# ================= FASTAPI =================
app = FastAPI()

# ================= STATE =================
pose = None
cap = None
tracking_active = False
reference_recording = False
reference_gt = None
reference_buffer = []
capture_thread = None

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setblocking(True)

frame_counter = 0

# ================= MODELS =================
class ConfigUpdate(BaseModel):
    CAM_INDEX: Optional[int] = None
    PCK_THRESHOLD: Optional[float] = None
    REFERENCE_FRAMES: Optional[int] = None
    enable_segmentation: Optional[bool] = None
    min_detection_confidence: Optional[float] = None
    min_tracking_confidence: Optional[float] = None
    debug: Optional[bool] = None
    TARGET_FPS: Optional[int] = None
    UDP_CHUNK_SIZE: Optional[int] = None

# ================= HELPERS =================
def download_model():
    if not os.path.exists(MODEL_PATH):
        log(f"Downloading pose model...")
        os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
        urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
        log("Model downloaded")

def build_pose():
    global pose
    log("Initializing MediaPipe Pose")
    download_model()

    if pose:
        try:
            pose.close()
        except:
            pass
        pose = None

    base_opts = mp_python.BaseOptions(model_asset_path=MODEL_PATH)
    opts = mp_vision.PoseLandmarkerOptions(
        base_options=base_opts,
        running_mode=mp_vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=CONFIG["min_detection_confidence"],
        min_pose_presence_confidence=CONFIG["min_detection_confidence"],
        min_tracking_confidence=CONFIG["min_tracking_confidence"],
        output_segmentation_masks=CONFIG["enable_segmentation"],
    )
    pose = mp_vision.PoseLandmarker.create_from_options(opts)

def open_camera():
    global cap
    log(f"Opening camera index {CONFIG['CAM_INDEX']}")

    if sys.platform.startswith("win"):
        cap = cv2.VideoCapture(CONFIG["CAM_INDEX"], cv2.CAP_DSHOW)
    else:
        cap = cv2.VideoCapture(CONFIG["CAM_INDEX"], cv2.CAP_V4L2)

    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    ok = cap.isOpened()
    log(f"Camera opened: {ok}")
    return ok

def close_camera():
    global cap, pose

    log("Closing camera")

    if cap:
        try:
            cap.release()
        except:
            pass
        cap = None

    if not sys.platform.startswith("win"):
        time.sleep(0.5)

    if pose:
        try:
            pose.close()
        except:
            pass
        pose = None

    if CONFIG["debug"]:
        cv2.destroyAllWindows()

def send_udp_json(payload: dict):
    try:
        sock.sendto(json.dumps(payload).encode("utf-8"),
                    (CONFIG["UDP_IP"], CONFIG["UDP_PORT"]))
    except Exception as e:
        log("UDP JSON send error: " + str(e))

def send_udp_jpeg_chunks(jpeg_bytes: bytes, frame_id: int, timestamp_ms: int):
    chunk_size = CONFIG["UDP_CHUNK_SIZE"]
    total_chunks = (len(jpeg_bytes) + chunk_size - 1) // chunk_size

    for i in range(total_chunks):
        start = i * chunk_size
        end = start + chunk_size
        chunk = jpeg_bytes[start:end]

        try:
            header = struct.pack("!IHHII",
                frame_id,
                i,
                total_chunks,
                len(chunk),
                timestamp_ms
            )
            sock.sendto(header + chunk,
                        (CONFIG["UDP_IP"], CONFIG["UDP_PORT"]))
        except Exception as e:
            log("UDP send error: " + str(e))
            break

def euclidean_3d(a, b):
    return math.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2 + (a[2]-b[2])**2)

def compute_pck(pred, gt):
    if not gt:
        return None

    ls, rs = gt[11], gt[12]
    ref_len = euclidean_3d(ls, rs) + 1e-6

    correct = 0
    for i in range(len(gt)):
        if euclidean_3d(pred[i], gt[i]) <= CONFIG["PCK_THRESHOLD"] * ref_len:
            correct += 1

    score = round((correct / len(gt)) * 100.0, 2)
    log(f"PCK={score}")
    return score

def map_full_body(world_landmarks):
    out = {}
    for name, i in POSE_IDX.items():
        lm = world_landmarks[i]
        out[name.lower()] = {
            "x": round(lm.x, 4),
            "y": round(lm.y, 4),
            "z": round(lm.z, 4),
            "score": round(lm.visibility if lm.visibility is not None else 0.0, 3),
            "presence": round(lm.presence if lm.presence is not None else 0.0, 3)
        }
    return out

def update_reference(world_landmarks):
    global reference_gt, reference_buffer
    pts = [(lm.x, lm.y, lm.z) for lm in world_landmarks]
    reference_buffer.append(pts)

    if len(reference_buffer) >= CONFIG["REFERENCE_FRAMES"]:
        avg = np.mean(np.array(reference_buffer), axis=0)
        reference_gt = avg.tolist()
        reference_buffer.clear()
        log("Reference posture locked")

# ================= MAIN LOOP =================
def tracking_loop():
    global frame_counter, tracking_active

    log("Tracking loop started")
    frame_interval = 1.0 / max(CONFIG["TARGET_FPS"], 1)
    start_time_ms = int(time.time() * 1000)

    while tracking_active:
        t0 = time.time()

        try:
            ret, frame = cap.read()
            if not ret:
                log("Camera read failed")
                time.sleep(0.2)
                continue

            frame = cv2.flip(frame, 1)
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            timestamp_ms = int(time.time() * 1000) - start_time_ms
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result = pose.detect_for_video(mp_image, timestamp_ms)

            joints = {}
            pck = None

            if result.pose_world_landmarks:
                world_lms = result.pose_world_landmarks[0]
                joints = map_full_body(world_lms)
                pred_points = [(lm.x, lm.y, lm.z) for lm in world_lms]

                if reference_recording:
                    update_reference(world_lms)

                if reference_gt:
                    pck = compute_pck(pred_points, reference_gt)

            encode_ok, jpeg = cv2.imencode(".jpg", frame,
                [int(cv2.IMWRITE_JPEG_QUALITY), CONFIG["JPEG_QUALITY"]])

            if not encode_ok:
                continue

            jpeg_bytes = jpeg.tobytes()
            udp_ts = int(time.time() * 1000) & 0xFFFFFFFF
            frame_counter = (frame_counter + 1) & 0xFFFFFFFF

            send_udp_jpeg_chunks(jpeg_bytes, frame_counter, udp_ts)

            meta = {
                "timestamp_ms": udp_ts,
                "frame_id": frame_counter,
                "joints": joints,
                "pck": pck,
                "reference_active": reference_recording,
                "reference_ready": reference_gt is not None
            }

            send_udp_json(meta)

            if CONFIG["debug"]:
                cv2.imshow("Pose Tracking DEBUG", frame)
                if cv2.waitKey(1) & 0xFF == 27:
                    break

        except Exception as e:
            log("Loop error: " + str(e))
            time.sleep(0.1)

        elapsed = time.time() - t0
        sleep_time = frame_interval - elapsed
        if sleep_time > 0:
            time.sleep(sleep_time)

    close_camera()
    log("Tracking loop exited")

# ================= API ENDPOINTS =================
@app.post("/start")
def start_tracking():
    global tracking_active, capture_thread

    log(">>> /start called")

    if tracking_active:
        return {"status": "already_running"}

    if not sys.platform.startswith("win"):
        time.sleep(0.5)

    build_pose()
    if not open_camera():
        return {"status": "camera_error"}

    tracking_active = True

    capture_thread = threading.Thread(target=tracking_loop, daemon=False)
    capture_thread.start()

    return {"status": "started"}

@app.post("/stop")
def stop_tracking():
    global tracking_active, capture_thread

    log(">>> /stop called")

    tracking_active = False

    if capture_thread and capture_thread.is_alive():
        capture_thread.join(timeout=2.0)

    capture_thread = None
    return {"status": "stopped"}

@app.get("/health")
def health():
    return {
        "service": "pose_service",
        "tracking_active": tracking_active,
        "reference_recording": reference_recording,
        "reference_ready": reference_gt is not None,
        "camera_open": cap.isOpened() if cap else False,
        "config": CONFIG
    }

# ================= ENTRY =================
if __name__ == "__main__":
    import multiprocessing
    multiprocessing.freeze_support()
    import uvicorn

    log("Starting Pose Service (DEBUG MODE)")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=False
    )
