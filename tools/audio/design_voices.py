"""Design Jelly Bear's voice with ElevenLabs Voice Design, then save the one you pick.

  python3 tools/audio/design_voices.py audition <out_dir> [style ...]   # 3 previews per style + index.html
  python3 tools/audio/design_voices.py save <style> <generated_voice_id>  # keeps it as the mascot voice

The API key is read from ~/.elevenlabs/api_key and never printed. Saved voice ids go to
tools/audio/eleven_voices.json (ids only, no secrets).
"""
import base64
import html
import json
import pathlib
import sys
import urllib.error
import urllib.request

API = "https://api.elevenlabs.io/v1"
KEY_FILE = pathlib.Path("~/.elevenlabs/api_key").expanduser()
VOICES = pathlib.Path(__file__).resolve().parent / "eleven_voices.json"
MODEL = "eleven_ttv_v3"
SEEDS = (11,)

STYLES = {
    "warm": {
        "description": "Native English. A sweet, bouncy cartoon jelly bear mascot with a warm, bright, gentle female voice. "
                       "Studio-quality recording. Cheerful, patient and loving; clear, slow and sing-song, "
                       "with long happy vowels and soft giggles.",
        "text": "[excited] Yay! Hello friend! [giggles] Peekaboo! I see you! Let's pop the candies! A! B! C! One, two, three! Circle! Star! [happily] You did it! Three stars! Hooray!",
    },
    "soft": {
        "description": "Native English. A cute, squishy cartoon jelly bear mascot with a soft, youthful, friendly voice, "
                       "neither deep nor squeaky. Studio-quality recording. Playful and kind, speaking clearly and slowly "
                       "with a gentle sing-song lilt and little giggles.",
        "text": "[excited] Yay! Hello friend! [giggles] Peekaboo! I see you! Let's pop the candies! A! B! C! One, two, three! Circle! Star! [happily] You did it! Three stars! Hooray!",
    },
}


def post(path, body):
    key = KEY_FILE.read_text().strip()
    if not key or key.startswith("PASTE_"):
        sys.exit(f"Put your ElevenLabs API key in {KEY_FILE}")
    req = urllib.request.Request(API + path, json.dumps(body).encode(), method="POST",
                                 headers={"xi-api-key": key, "Content-Type": "application/json"})
    try:
        return json.load(urllib.request.urlopen(req, timeout=180))
    except urllib.error.HTTPError as e:
        sys.exit(f"{path}: HTTP {e.code} {e.read()[:400].decode(errors='replace')}")


def audition(out, styles):
    out.mkdir(parents=True, exist_ok=True)
    takes = json.loads((out / "takes.json").read_text()) if (out / "takes.json").exists() else {}
    for style in styles:
        spec = STYLES[style]
        takes[style] = []
        for seed in SEEDS:
            res = post("/text-to-voice/design", {"voice_description": spec["description"], "text": spec["text"],
                                                 "model_id": MODEL, "seed": seed})
            for i, p in enumerate(res["previews"]):
                name = f"{style}_{seed}_{i + 1}.mp3"
                (out / name).write_bytes(base64.b64decode(p["audio_base_64"]))
                takes[style].append({"file": name, "id": p["generated_voice_id"], "secs": p.get("duration_secs")})
            print(style, "seed", seed, "->", len(res["previews"]), "previews")
    (out / "takes.json").write_text(json.dumps(takes, indent=1))
    rows = []
    for style, items in takes.items():
        rows.append(f"<h2>{style}</h2><p>{html.escape(STYLES[style]['description'])}</p>")
        for n, t in enumerate(items, 1):
            rows.append(f"<div><b>{style} {n}</b> <audio controls preload=auto src='{t['file']}'></audio> "
                        f"<code>{t['id']}</code></div>")
    (out / "index.html").write_text("<meta charset=utf-8><title>PurrPal voices</title>"
                                    "<body style='font-family:sans-serif;max-width:60em'>" + "".join(rows))
    print(out / "index.html")


def save(style, generated_id):
    spec = STYLES[style]
    res = post("/text-to-voice", {"voice_name": f"PianoPop Jelly Bear ({style})", "voice_description": spec["description"],
                                  "generated_voice_id": generated_id})
    voices = json.loads(VOICES.read_text()) if VOICES.exists() else {}
    voices["mascot"] = {"voice_id": res["voice_id"], "model": MODEL, "description": spec["description"]}
    VOICES.write_text(json.dumps(voices, indent=1) + "\n")
    print(style, "->", res["voice_id"])


if __name__ == "__main__":
    if sys.argv[1:2] == ["audition"]:
        audition(pathlib.Path(sys.argv[2]), sys.argv[3:] or list(STYLES))
    elif sys.argv[1:2] == ["save"]:
        save(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
