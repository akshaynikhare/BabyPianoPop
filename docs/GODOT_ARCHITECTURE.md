# BabyPianoPop: Godot architecture and agent rules

Godot 4.7.2 (GDScript), Compatibility renderer, 2D, portrait, 60 fps cap. The project lives at the repo root next to the legacy web app. The web app is hidden from Godot by `.gdignore` and will be removed after parity.

## Rules for every agent
1. **Never touch git.** No add, commit, stash, checkout or restore. The human commits.
2. **Check locks before editing.** Run `bash .actionplan/scripts/lock.sh check <path>`; on overlap, stop and report.
3. **Edit only the folders your brief assigns** (see Ownership). If you need a change outside them, report it.
4. **Never install on the phone.** The orchestrator does all device work.
5. **No plan ids in code.** Comments explain *why*, briefly.
6. **Keep sounds out of code.** Every sound is a pre-rendered OGG played through `AudioDirector`; there is no runtime synthesis.
7. **Keep the hot path cheap.** Tiles are `Node2D`s moved in `_process`. No allocations per frame, and no layout containers for moving things.

## Verify (run from the repo root)
```bash
godot --headless --path . --import                    # must print no ERROR
godot --headless --path . -s tests/run_tests.gd       # logic tests; exit code 0
godot --headless --path . --quit-after 120            # run main scene ~2 s headless; no ERROR/SCRIPT ERROR
```
- **Tests:** `tests/test_<area>.gd` scripts extend `TestCase`. Keep game rules in a pure class, e.g. `scripts/game/tile_rules.gd`, and test it with synthetic frames.
- **Export:** only the orchestrator runs `godot --headless --path . --export-debug "Android" build/BabyPianoPop.apk`.

## Autoloads (`autoload/`, owned by the orchestrator)
| Autoload | API |
|---|---|
| `EventBus` | Signals: `game_started`, `tile_popped`, `tile_stuck`, `stars_changed`, `round_completed`, `mascot_mood_changed`, `settings_opened/closed`, `app_paused/resumed`, `settings_changed`. The game agent may add signals here; list them in its report. |
| `Settings` | `get_value(key)`, `set_value(key, value)`. Keys: `age_tier` (`6-12m` / `1-2y` / `2-3y`), `praise_mode`, `music_on`. |
| `AudioDirector` | `play_sfx`, `play_voice` (interrupts), `stop_voice`, `play_music` (loops), `stop_music`, `set_bus_muted(bus, muted)`, `pause_all` / `resume_all`. Buses: Music, SFX, Voice. Files: `assets/audio/{sfx,voice,music}/<name>.ogg`. |
| `Haptics` | `play(pattern)`: pop, stuck, stars, unlock, tick. |
| `Lifecycle` | Pauses the tree and audio when the app is backgrounded. |

## Folders and ownership
| Path | Owner |
|---|---|
| `project.godot`, `export_presets.cfg`, `docs/`, `icon.svg` | orchestrator |
| `autoload/` | orchestrator (the game agent may add EventBus signals and Settings keys) |
| `tools/audio/`, `assets/audio/` | audio-assets agent |
| `scenes/`, `scripts/`, `shaders/`, `assets/textures/`, `assets/fonts/`, `tests/test_*.gd` (Phase 2) | game agent |

## Conventions
- **Naming:** snake_case files, PascalCase `class_name`, typed GDScript, tabs for indentation.
- **Viewport and input:** 720×1600 base, `canvas_items` stretch, `expand` aspect. The header (and its 100 px touch guard) and tile start y scale with `unit`, matching the old app's ~100 dp header.
- **Touch:** handle `InputEventScreenTouch` / `InputEventScreenDrag` with their `index` (multi-touch). Mouse emulates touch on desktop.
