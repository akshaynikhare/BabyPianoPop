"""Check every expected clip exists, decodes, and report sizes.

  /Users/akshay/Downloads/baby_apps/.tools/kokoro-venv/bin/python tools/audio/verify_assets.py
"""
import csv
import pathlib
import sys
import soundfile as sf

HERE = pathlib.Path(__file__).resolve().parent
AUDIO = HERE.parents[1] / "assets/audio"
letters = [f"letter_{c}" for c in "abcdefghijklmnopqrstuvwxyz"]
EXPECTED = {
    "sfx": ["pop", "giggle", "star", "tick"] + [f"chime_{h}" for h in (523, 587, 659, 784, 880, 1047, 1175)],
    "music": ["music_box"],
    "voice": letters + [f"number_{i}" for i in range(10)]
    + [f"shape_{s}" for s in ("star", "heart", "circle", "triangle", "square")]
    + ["tier_6_12m", "tier_1_2y", "tier_2_3y"]
    + [f"praise_{i}" for i in range(6)] + [f"three_stars_praise_{i}" for i in range(6)] + ["three_stars_hooray"]
    + [f"mascot_{i}" for i in range(6)] + [f"gear_{i}" for i in range(4)] + [f"stars_{i}" for i in range(4)],
}


def main():
    missing, total = [], 0
    for folder, names in EXPECTED.items():
        for n in names:
            p = AUDIO / folder / f"{n}.ogg"
            if not p.exists():
                missing.append(f"{folder}/{n}")
                continue
            data, _ = sf.read(str(p))
            assert len(data) > 0, p
        for p in (AUDIO / folder).glob("*.ogg"):
            total += p.stat().st_size
    csv_ids = {r["id"] for r in csv.DictReader(open(HERE / "voice_lines.csv", encoding="utf-8"))}
    extra = csv_ids - set(EXPECTED["voice"])
    print(f"expected clips: {sum(map(len, EXPECTED.values()))}, missing: {missing or 'none'}, csv ids not expected: {sorted(extra) or 'none'}")
    print(f"total ogg size: {total / 1024:.1f} KiB")
    sys.exit(1 if missing or extra else 0)


if __name__ == "__main__":
    main()
