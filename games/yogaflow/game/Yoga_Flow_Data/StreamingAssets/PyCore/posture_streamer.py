import cv2
import socket
import struct
import numpy as np
from dataclasses import dataclass

from mediapipe import Image as MpImage, ImageFormat
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# ======================================================
# CONFIG
# ======================================================
POSE_MODEL_PATH = "./pose_landmarker_heavy.task"

CAM_W, CAM_H = 640, 480
WINDOW_NAME = "Video (Left) | Skeleton (Right)"

POINT_COLOR = (0, 255, 0)
LINE_COLOR = (0, 255, 0)

SMOOTH_FACTOR = 0.7

ENABLE_CV_WINDOW = True
ENABLE_UDP_STREAM = True

UDP_IP = "127.0.0.1"
UDP_PORT = 5055
UDP_MAX_BYTES = 1400

# ======================================================
# LANDMARK INDICES
# ======================================================
LM = {
    "shoulder_l": 11, "shoulder_r": 12,
    "elbow_l": 13, "elbow_r": 14,
    "wrist_l": 15, "wrist_r": 16,
    "hand_l": 19, "hand_r": 20,
    "hip_l": 23, "hip_r": 24,
    "knee_l": 25, "knee_r": 26,
    "ankle_l": 27, "ankle_r": 28,
    "toe_l": 31, "toe_r": 32,
}

BONES = [
    ("shoulder_l", "elbow_l"), ("elbow_l", "wrist_l"),
    ("shoulder_r", "elbow_r"), ("elbow_r", "wrist_r"),
    ("shoulder_l", "shoulder_r"),
    ("hip_l", "hip_r"),
    ("shoulder_c", "hip_c"),
    ("hip_l", "knee_l"), ("knee_l", "ankle_l"), ("ankle_l", "toe_l"),
    ("hip_r", "knee_r"), ("knee_r", "ankle_r"), ("ankle_r", "toe_r"),
]

JOINT_ID = {name: i for i, name in enumerate(LM.keys(), start=1)}
JOINT_ID["shoulder_c"] = 50
JOINT_ID["hip_c"] = 51

# ======================================================
# JOINT MODEL
# ======================================================
@dataclass
class Joint2D:
    name: str
    x: float
    y: float
    score: float
    z: float = 0.0
    presence: float = 0.0

# ======================================================
# TEMPORAL SMOOTHER
# ======================================================
def smooth_joints(prev, curr, factor):
    if not curr:
        return {}
    if not prev or factor <= 0:
        return curr

    out = {}
    for k, j in curr.items():
        pj = prev.get(k)
        if pj is None:
            out[k] = j
            continue

        out[k] = Joint2D(
            name=j.name,
            x=pj.x * factor + j.x * (1 - factor),
            y=pj.y * factor + j.y * (1 - factor),
            score=j.score,
            z=pj.z * factor + j.z * (1 - factor),
            presence=pj.presence * factor + j.presence * (1 - factor),
        )
    return out

# ======================================================
# INIT
# ======================================================
def init_pose():
    return vision.PoseLandmarker.create_from_options(
        vision.PoseLandmarkerOptions(
            base_options=python.BaseOptions(model_asset_path=POSE_MODEL_PATH),
            running_mode=vision.RunningMode.VIDEO,
            num_poses=1,
        )
    )

# ======================================================
# MAIN
# ======================================================
def main():
    pose = init_pose()
    cap = cv2.VideoCapture(0)

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAM_W)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAM_H)

    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) if ENABLE_UDP_STREAM else None
    prev_joints = {}

    while True:
        ok, frame = cap.read()
        if not ok:
            break

        frame = cv2.flip(frame, 1)
        timestamp_ms = int(cv2.getTickCount() / cv2.getTickFrequency() * 1000)

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_img = MpImage(ImageFormat.SRGB, rgb)
        res = pose.detect_for_video(mp_img, timestamp_ms)

        joints = {}

        if ENABLE_CV_WINDOW:
            h, w = frame.shape[:2]
            canvas = np.zeros((h, w * 2, 3), dtype=np.uint8)
            canvas[:, :w] = frame
            skel = np.zeros((h, w, 3), dtype=np.uint8)

        if res.pose_landmarks:
            lms = res.pose_landmarks[0]

            for name, idx in LM.items():
                lm = lms[idx]
                joints[name] = Joint2D(
                    name=name,
                    x=lm.x,
                    y=lm.y,
                    z=lm.z,
                    score=lm.visibility,
                    presence=lm.presence,
                )

            if "shoulder_l" in joints and "shoulder_r" in joints:
                l, r = joints["shoulder_l"], joints["shoulder_r"]
                joints["shoulder_c"] = Joint2D(
                    "shoulder_c",
                    (l.x + r.x) * 0.5,
                    (l.y + r.y) * 0.5,
                    min(l.score, r.score),
                    (l.z + r.z) * 0.5,
                    min(l.presence, r.presence),
                )

            if "hip_l" in joints and "hip_r" in joints:
                l, r = joints["hip_l"], joints["hip_r"]
                joints["hip_c"] = Joint2D(
                    "hip_c",
                    (l.x + r.x) * 0.5,
                    (l.y + r.y) * 0.5,
                    min(l.score, r.score),
                    (l.z + r.z) * 0.5,
                    min(l.presence, r.presence),
                )

            joints = smooth_joints(prev_joints, joints, SMOOTH_FACTOR)
            prev_joints = joints

            # -------- UDP STREAM (BINARY + NAME) --------
            if ENABLE_UDP_STREAM:
                buf = bytearray()
                buf += struct.pack("<IB", timestamp_ms, len(joints))

                for name, j in joints.items():
                    jid = JOINT_ID.get(name, 0)
                    name_bytes = name.encode("ascii")
                    buf += struct.pack("<BB", jid, len(name_bytes))
                    buf += name_bytes
                    buf += struct.pack(
                        "<fffff",
                        j.x, j.y, j.z,
                        j.score, j.presence
                    )

                if len(buf) <= UDP_MAX_BYTES:
                    udp.sendto(buf, (UDP_IP, UDP_PORT)) # type: ignore

            if ENABLE_CV_WINDOW:
                for a, b in BONES:
                    if a in joints and b in joints:
                        p1, p2 = joints[a], joints[b]
                        cv2.line(
                            skel,
                            (int(p1.x * w), int(p1.y * h)),
                            (int(p2.x * w), int(p2.y * h)),
                            LINE_COLOR,
                            2,
                        )

                for j in joints.values():
                    cv2.circle(
                        skel,
                        (int(j.x * w), int(j.y * h)),
                        5,
                        POINT_COLOR,
                        -1,
                    )

        if ENABLE_CV_WINDOW:
            canvas[:, w:] = skel
            cv2.imshow(WINDOW_NAME, canvas)
            if cv2.waitKey(1) == 27:
                break

    cap.release()
    cv2.destroyAllWindows()

# ======================================================
# ENTRY
# ======================================================
if __name__ == "__main__":
    main()
