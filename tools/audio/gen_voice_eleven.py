"""Render Jelly Bear's voice lines (eleven_lines.csv) with its ElevenLabs voice (eleven_voices.json).

  PY=/Users/akshay/Downloads/baby_apps/.tools/kokoro-venv/bin/python
  $PY tools/audio/gen_voice_eleven.py audition <out_dir> [id ...]   # TAKES per line + index.html
  $PY tools/audio/gen_voice_eleven.py pick <out_dir>                # -> assets/audio/voice/<id>.ogg

audition renders every take through gen_voice.postprocess (trim, -16 LUFS, soft limit) at 24 kHz
and skips takes already on disk with the same text, so re-runs only pay for changes. Take 1 is
the default pick; <out_dir>/picks.json ({"letter_a": 2}) overrides it.
The API key is read from ~/.elevenlabs/api_key and never printed.
"""
import concurrent.futures
import csv
import html
import json
import pathlib
import sys
import urllib.error
import urllib.request

import numpy as np
import soundfile as sf

from gen_voice import OUT, SR, postprocess

HERE = pathlib.Path(__file__).resolve().parent
KEY_FILE = pathlib.Path("~/.elevenlabs/api_key").expanduser()
# (model, stability, seed): the designed voice is tuned for v3; v4 is the comparison take.
TAKES = (("eleven_v3", 0.5, 1), ("eleven_v3", 0.0, 2), ("eleven_v4", 0.5, 3))


def tts(voice_id, text, model, stability, seed):
    key = KEY_FILE.read_text().strip()
    body = {"text": text, "model_id": model, "seed": seed,
            "voice_settings": {"stability": stability, "similarity_boost": 0.8}}
    req = urllib.request.Request(f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=pcm_{SR}",
                                 json.dumps(body).encode(), method="POST",
                                 headers={"xi-api-key": key, "Content-Type": "application/json"})
    try:
        raw = urllib.request.urlopen(req, timeout=120).read()
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code} {e.read()[:300].decode(errors='replace')}") from None
    return np.frombuffer(raw, "<i2").astype(np.float64) / 32768.0


def lines(only=()):
    rows = list(csv.DictReader(open(HERE / "eleven_lines.csv", encoding="utf-8")))
    return [r for r in rows if not only or r["id"] in only]


def audition(out, only):
    voice_id = json.loads((HERE / "eleven_voices.json").read_text())["mascot"]["voice_id"]
    out.mkdir(parents=True, exist_ok=True)
    meta_path = out / "takes.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    jobs = [(r, n, f"{r['id']}_{n}.wav", *take) for r in lines(only) for n, take in enumerate(TAKES, 1)
            if not ((out / f"{r['id']}_{n}.wav").exists() and meta.get(f"{r['id']}_{n}.wav", {}).get("text") == r["text"])]

    def run(job):
        r, n, name, model, stability, seed = job
        x, _ = postprocess(tts(voice_id, r["text"], model, stability, seed))
        sf.write(str(out / name), x, SR, subtype="PCM_16")
        return name, {"id": r["id"], "take": n, "text": r["text"], "model": model, "secs": round(len(x) / SR, 2)}

    with concurrent.futures.ThreadPoolExecutor(2) as pool:
        for i, (name, info) in enumerate(pool.map(run, jobs), 1):
            meta[name] = info
            print(f"{i}/{len(jobs)} {name} {info['secs']}s")
    meta_path.write_text(json.dumps(meta, indent=1))
    write_page(out, meta)


def chosen(out):
    picks = json.loads((out / "picks.json").read_text()) if (out / "picks.json").exists() else {}
    return {r["id"]: picks.get(r["id"], 1) for r in lines()}


def write_page(out, meta):
    best = chosen(out)
    rows = ["<meta charset=utf-8><title>Jelly Bear lines</title><body style='font-family:sans-serif'>",
            "<p>&#9733; = current pick. Takes: 1 = v3, 2 = v3 expressive, 3 = v4.</p><table>"]
    for r in lines():
        cells = []
        for n in range(1, len(TAKES) + 1):
            m = meta.get(f"{r['id']}_{n}.wav")
            if m:
                star = "&#9733;" if best[r["id"]] == n else ""
                cells.append(f"<td>{star}{n} <audio controls preload=none src='{r['id']}_{n}.wav'></audio>"
                             f"<br><small>{m['secs']}s</small></td>")
        rows.append(f"<tr><td><b>{r['id']}</b><br><small>{html.escape(r['text'])}</small></td>{''.join(cells)}</tr>")
    (out / "index.html").write_text("".join(rows) + "</table>")
    print(out / "index.html")


def pick(out):
    for line_id, take in chosen(out).items():
        x, _ = sf.read(str(out / f"{line_id}_{take}.wav"))
        sf.write(str(OUT / f"{line_id}.ogg"), x, SR, format="OGG", subtype="VORBIS")
        print(f"{line_id:22s} take {take}  {len(x) / SR:4.2f}s")


if __name__ == "__main__":
    if sys.argv[1:2] == ["audition"]:
        audition(pathlib.Path(sys.argv[2]), set(sys.argv[3:]))
    elif sys.argv[1:2] == ["pick"]:
        pick(pathlib.Path(sys.argv[2]))
    else:
        sys.exit(__doc__)
