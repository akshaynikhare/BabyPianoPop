"""Check every clip eleven_sounds.csv and eleven_lines.csv describe is on disk and decodes, that no
other clip is lying around, and that the music loops.

  /Users/akshay/Downloads/baby_apps/.tools/kokoro-venv/bin/python tools/audio/verify_assets.py
"""
import csv
import pathlib
import sys
import soundfile as sf

HERE = pathlib.Path(__file__).resolve().parent
AUDIO = HERE.parents[1] / "assets/audio"


def clips():
    """Every clip the CSVs describe, as {folder: {file stem: description}}.

    A sound kept once is <id>.ogg; kept N > 1 times it is <id>_1.ogg ... <id>_N.ogg (a variant group).
    Music goes to music/, every other sound to sfx/, voice lines to voice/.
    """
    out = {"sfx": {}, "music": {}, "voice": {}}
    for row in csv.DictReader(open(HERE / "eleven_sounds.csv", encoding="utf-8")):
        keep = int(row["keep"])
        stems = [row["id"]] if keep == 1 else [f"{row['id']}_{n}" for n in range(1, keep + 1)]
        for stem in stems:
            out["music" if row["kind"] == "music" else "sfx"][stem] = row["prompt"]
    for row in csv.DictReader(open(HERE / "eleven_lines.csv", encoding="utf-8")):
        out["voice"][row["id"]] = f"Says: \"{row['text']}\""
    return out


def main():
    missing, unexpected, total = [], [], 0
    expected = clips()
    for folder, stems in expected.items():
        for stem in stems:
            p = AUDIO / folder / f"{stem}.ogg"
            if not p.exists():
                missing.append(f"{folder}/{stem}")
                continue
            data, _ = sf.read(str(p))
            assert len(data) > 0, p
        on_disk = {p.stem for p in (AUDIO / folder).glob("*.ogg") if not p.stem.startswith("smoke_")}
        unexpected += [f"{folder}/{stem}" for stem in sorted(on_disk - set(stems))]
        total += sum(p.stat().st_size for p in (AUDIO / folder).glob("*.ogg"))
    not_looping = [
        stem for stem in expected["music"]
        if "loop=true" not in (AUDIO / "music" / f"{stem}.ogg.import").read_text()
    ]
    print(f"expected clips: {sum(map(len, expected.values()))}, missing: {missing or 'none'}, "
          f"not in the CSVs: {unexpected or 'none'}, music not looping: {not_looping or 'none'}")
    print(f"total ogg size: {total / 1024:.1f} KiB")
    sys.exit(1 if missing or unexpected or not_looping else 0)


if __name__ == "__main__":
    main()
