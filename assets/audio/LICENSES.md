# BabyPianoPop audio licences

Everything shipped here except the two smoke files was generated with ElevenLabs on a paid Starter plan on 2026-11-01.

- **Voice** (`voice/*.ogg`): ElevenLabs text-to-speech (Eleven v3 / Eleven v4) in a voice designed with ElevenLabs Voice Design ("PianoPop Jelly Bear"; the voice id is in `tools/audio/eleven_voices.json`). Lines are in `tools/audio/eleven_lines.csv`. The voice was designed with `tools/audio/design_voices.py` and the lines rendered with `tools/audio/gen_voice_eleven.py`, which trims them and sets their loudness through the post-processing in `gen_voice.py`.
- **SFX** (`sfx/*.ogg` except `smoke_tone.ogg`): ElevenLabs Sound Effects v3 renders. The prompts are in `tools/audio/eleven_sounds.csv`; rendered with `tools/audio/gen_sounds_eleven.py`.
- **Music** (`music/music_box.ogg`, `music_calm.ogg`, `music_play.ogg`): Eleven Music v2.5 renders from the same CSV and script.
- `sfx/smoke_tone.ogg` and `music/smoke_loop.ogg` are internal test tones from the build pipeline, made in this project.
- The earlier Kokoro-82M voice and the hand-synthesised effects were replaced by the renders above. Their tools (`gen_voice.py`'s Kokoro synthesis, `render_sfx.py`, `dsp.py`, `voice_lines.csv`) are still in `tools/audio/`, but no shipped clip comes from them.
