# BabyPianoPop audio licences

- **Voice** (`voice/*.ogg`): generated offline with [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) (`kokoro` 0.9.x, Apache-2.0 code and Apache-2.0 weights), American English voice `af_heart`, speed 0.9. Phonemisation by `misaki` + espeak-ng (build-time only, not shipped). Lines are in `tools/audio/voice_lines.csv`; regenerate with `tools/audio/gen_voice.py`.
- **SFX and music** (`sfx/*.ogg`, `music/music_box.ogg`): original renders from our own recipes in `tools/audio/render_sfx.py` (numpy/scipy synthesis, written for this project). No third-party samples or recordings. The music-box melody is the pentatonic tune from the original app.
- `smoke_tone.ogg` and `smoke_loop.ogg` are internal test tones from the build pipeline.
