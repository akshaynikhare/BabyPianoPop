# Baby Piano Pop

An ad-free, offline toddler game (6 months – 3 years). Candy tiles fall gently; each tap pops one with a chime and speaks the letter, number or shape. Tiles never go anywhere bad: if one reaches the bottom it waits, glowing, for the child to tap it. Every three pops earns three stars and a new pastel colour.

Built with **Godot 4.7** (GDScript, 2D, Compatibility renderer). Portrait only, 60 fps cap.

## Age tiers
| Tier | Age | Content | Input |
|---|---|---|---|
| Infant | 6–12 months | 5 shapes, A–C, 1–3 | Glide: dragging a finger over tiles pops them |
| Young Toddler | 1–2 years (default) | 5 shapes, A–J, 0–9 | Tap |
| Toddler | 2–3+ years | 5 shapes, A–Z, 0–9 | Tap |

Speed adapts to the child: it speeds up when they pop quickly and slows down when a tile gets stuck.

## For parents
- **Settings:** hold the gear for 3 seconds. Inside you can change the age tier, turn music on or off, toggle praise lines, and turn on Quiet Mode (everything 8 dB softer).
- **Privacy:** no ads, no network, no data collection. Everything is offline.
- **Background:** sound stops when the app is minimised.

## Develop
```bash
make run      # open in Godot
make test     # headless logic tests
make apk      # debug APK → build/BabyPianoPop.apk
make install  # adb install the debug APK
```
- **Architecture and agent rules:** [docs/GODOT_ARCHITECTURE.md](docs/GODOT_ARCHITECTURE.md).
- **Behaviour spec:** [docs/REWRITE_SPEC.md](docs/REWRITE_SPEC.md).
- **Voice and sounds:** generated with ElevenLabs by the scripts in `tools/audio/` (voice, sound effects and one music loop per age tier). See [assets/audio/LICENSES.md](assets/audio/LICENSES.md).

## Release
Every push to `main` runs CI: it bumps a tag, runs the tests, exports a signed APK and publishes a GitHub Release. Signing uses the `KEYSTORE_B64`, `KEY_ALIAS` and `KEY_PASS` repo secrets; without them CI publishes a debug-signed build.

The previous React/Capacitor version is in git history (last web release: v0.3.0).
