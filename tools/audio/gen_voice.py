"""Generate Voice-bus clips from voice_lines.csv with Kokoro-82M (voice af_heart, US English).

  /Users/akshay/Downloads/baby_apps/.tools/kokoro-venv/bin/python tools/audio/gen_voice.py [--force] [--only id,id]

Idempotent: a clip is skipped when its file exists and its text/voice/speed/post-process
version hash matches tools/audio/.voice_cache.json. Text may use Kokoro's inline phoneme
markup, e.g. "[A](/ˈA/)" (the plain word "Ay" is read as "eye").
Output: assets/audio/voice/<id>.ogg, mono 24 kHz, trimmed, ~-16 LUFS.
"""
import argparse
import csv
import hashlib
import json
import os
import pathlib
import sys
import warnings

import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from scipy import signal

warnings.filterwarnings("ignore")
for lib in ("/opt/homebrew/lib/libespeak-ng.1.dylib", "/opt/homebrew/lib/libespeak-ng.dylib"):
    if "PHONEMIZER_ESPEAK_LIBRARY" not in os.environ and os.path.exists(lib):
        os.environ["PHONEMIZER_ESPEAK_LIBRARY"] = lib

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parents[1] / "assets/audio/voice"
CACHE = HERE / ".voice_cache.json"
SR = 24000
VOICE = "af_heart"
SPEED = 0.9
POST_VERSION = 2
TARGET_LUFS = -16.0
PEAK_CEIL_DB = -1.5
PAD_S = 0.030
TRIM_DB = -45.0


def postprocess(x):
    sos = signal.butter(2, 70, "high", fs=SR, output="sos")
    x = signal.sosfilt(sos, x - np.mean(x))
    thr = np.max(np.abs(x)) * 10 ** (TRIM_DB / 20)
    idx = np.nonzero(np.abs(x) > thr)[0]
    pad = int(PAD_S * SR)
    x = x[max(idx[0] - pad, 0): idx[-1] + pad + 1]
    fi, fo = int(0.008 * SR), int(0.030 * SR)
    x[:fi] *= 0.5 - 0.5 * np.cos(np.pi * np.arange(fi) / fi)
    x[-fo:] *= 0.5 + 0.5 * np.cos(np.pi * np.arange(fo) / fo)
    # Reach the target loudness, soft-limiting the odd peaky consonant instead of
    # leaving the whole clip quieter than its neighbours.
    ceil = 10 ** (PEAK_CEIL_DB / 20)
    knee = 0.4
    limited = False
    for _ in range(4):
        meas = np.concatenate([x, np.zeros(max(0, int(0.6 * SR) - len(x)))])
        x = x * 10 ** ((TARGET_LUFS - pyln.Meter(SR).integrated_loudness(meas)) / 20)
        over = np.abs(x) > knee
        limited = limited or bool(np.any(np.abs(x) > ceil))
        x[over] = np.sign(x[over]) * (knee + (ceil - knee) * np.tanh((np.abs(x[over]) - knee) / (ceil - knee)))
    return x, limited


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    rows = list(csv.DictReader(open(HERE / "voice_lines.csv", encoding="utf-8")))
    only = set(filter(None, args.only.split(",")))
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    OUT.mkdir(parents=True, exist_ok=True)

    todo = []
    for r in rows:
        key = hashlib.sha1(f"{r['text']}|{VOICE}|{SPEED}|{POST_VERSION}".encode()).hexdigest()
        path = OUT / f"{r['id']}.ogg"
        if only and r["id"] not in only:
            continue
        if not args.force and path.exists() and cache.get(r["id"]) == key:
            continue
        todo.append((r["id"], r["text"], key, path))
    if not todo:
        print("voice: all clips up to date")
        return

    from kokoro import KPipeline
    pipe = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    for cid, text, key, path in todo:
        parts = [np.asarray(res.audio, dtype=np.float64) for res in pipe(text, voice=VOICE, speed=SPEED)]
        x, capped = postprocess(np.concatenate(parts))
        sf.write(str(path), x.astype(np.float32), SR, format="OGG", subtype="VORBIS")
        back, rate = sf.read(str(path))
        assert rate == SR and abs(len(back) - len(x)) < 2048, cid
        cache[cid] = key
        print(f"{cid:28s} {len(x) / SR:5.2f}s{'  (soft-limited)' if capped else ''}  {text}")
        CACHE.write_text(json.dumps(cache, indent=1, sort_keys=True))


if __name__ == "__main__":
    sys.exit(main())
