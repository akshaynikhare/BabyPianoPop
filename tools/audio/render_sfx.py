"""Render BabyPianoPop SFX + music box to OGG Vorbis (44.1 kHz mono).

  /Users/akshay/Downloads/baby_apps/.tools/kokoro-venv/bin/python tools/audio/render_sfx.py

Recipes follow docs/REWRITE_SPEC.md "Audio", softened: click-free envelopes,
a short synthetic-room reverb tail, peak-normalised to about -3 dBFS.
"""
import pathlib
import numpy as np
import dsp
from dsp import SR

ROOT = pathlib.Path(__file__).resolve().parents[2]
SFX = ROOT / "assets/audio/sfx"
MUSIC = ROOT / "assets/audio/music"

MELODY = [
    523.25, 659.25, 783.99, 1046.50,
    880.00, 783.99, 659.25, 523.25,
    587.33, 659.25, 783.99, 880.00,
    783.99, 659.25, 587.33, 523.25,
    659.25, 783.99, 1046.50, 1174.66,
    1046.50, 880.00, 783.99, 659.25,
    587.33, 783.99, 659.25, 523.25,
]


def chime_dry(f, g=1.0):
    """Sine + 3.01x partial through a 2.8 kHz lowpass (old chime(f))."""
    n = int(1.4 * SR)
    a = dsp.osc("sine", f, n) * dsp.env(n, 0.65, 1e-4, 1.3, 0.006)
    b = dsp.osc("sine", f * 3.01, n) * dsp.env(n, 0.14, 1e-4, 0.6, 0.006)
    return g * dsp.lowpass(a + b, 2800)


def note(kind, f, dur, g0, dec, attack=0.004):
    n = int(dur * SR)
    return dsp.osc(kind, f, n) * dsp.env(n, g0, 0.001, dec, attack)


def pop():
    n = int(0.16 * SR)
    f = dsp.freq_curve(n, [(0, 523.25), (0.08, 1046.5)], "exp")
    x = dsp.osc("sine", f, n) * dsp.env(n, 0.32, 0.001, 0.14, 0.003)
    return dsp.finish(dsp.reverb(x, wet=0.15, rt60=0.35))


def giggle():
    buf = np.zeros(1)
    for i, f in enumerate([659.25, 783.99, 1046.5]):
        buf = dsp.place(buf, note("sine", f, 0.2, 0.25, 0.18, 0.006), i * 0.08)
    return dsp.finish(dsp.reverb(buf, wet=0.2, rt60=0.5))


def star():
    buf = np.zeros(1)
    for i, f in enumerate([1318.51, 1975.53]):
        buf = dsp.place(buf, dsp.lowpass(note("triangle", f, 0.36, 0.25, 0.32, 0.006), 6000), i * 0.06)
    return dsp.finish(dsp.reverb(buf, wet=0.25, rt60=0.7))


def tick():
    n = int(0.16 * SR)
    f = dsp.freq_curve(n, [(0, 880), (0.06, 1760)], "exp")
    x = dsp.osc("sine", f, n) * dsp.env(n, 0.24, 0.001, 0.14, 0.003)
    return dsp.finish(dsp.reverb(x, wet=0.15, rt60=0.35))


def chime(f):
    return dsp.finish(dsp.reverb(chime_dry(f), wet=0.2, rt60=0.8))


def music_box():
    # Note i sounds at the running sum of gaps; 950 ms after notes 8, 16, 24, else 520 ms.
    starts, t = [], 0.0
    for i in range(len(MELODY)):
        starts.append(t)
        t += 0.95 if (i + 1) % 8 == 0 else 0.52
    loop_len = int(round(t * SR))
    buf = np.zeros(loop_len)
    for f, s in zip(MELODY, starts):
        buf = dsp.place(buf, chime_dry(f, 0.8), s)
    buf = dsp.fold_loop(buf, loop_len)        # ring-out of the last notes wraps onto the head
    buf = dsp.circular_reverb(buf, wet=0.22, rt60=1.4)
    buf = buf - np.mean(buf)
    return dsp.normalise(buf, -6.0), t


def main():
    SFX.mkdir(parents=True, exist_ok=True)
    MUSIC.mkdir(parents=True, exist_ok=True)
    clips = {"pop": pop(), "giggle": giggle(), "star": star(), "tick": tick()}
    for f in sorted(set(MELODY)):
        clips[f"chime_{int(f + 0.5)}"] = chime(f)
    for name, x in clips.items():
        d = dsp.write_ogg(SFX / f"{name}.ogg", x)
        print(f"sfx/{name}.ogg  {d:.3f}s")
    x, t = music_box()
    d = dsp.write_ogg(MUSIC / "music_box.ogg", x)
    print(f"music/music_box.ogg  {d:.3f}s (loop {t:.3f}s)")


if __name__ == "__main__":
    main()
