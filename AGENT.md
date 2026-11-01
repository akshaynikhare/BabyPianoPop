# AGENT.md: Baby Piano Pop

This repo uses **ActionPlan Kit** (`.actionplan/`; see `CLAUDE.md` / `AGENTS.md`). The human commits; agents never change git state.

The app is a **Godot 4.7** project (GDScript, 2D, Compatibility renderer). Start here:
- [docs/GODOT_ARCHITECTURE.md](docs/GODOT_ARCHITECTURE.md): rules for agents, autoload APIs, folder ownership, verify commands.
- [docs/REWRITE_SPEC.md](docs/REWRITE_SPEC.md): the behaviour contract, with exact numbers.

## Non-negotiables
1. **Never punish.** No game over, timers or negative sounds. A tile that reaches the bottom waits, glowing.
2. **Keep game rules pure.** They live in `scripts/game/tile_rules.gd`, which has no nodes and is unit-tested. Change rules there and add tests.
3. **Voice comes from pre-made clips only.** Use `AudioDirector.play_voice(id)` with the ids listed in `assets/audio/MANIFEST.md`. Never call TTS at runtime.
4. **60 fps on a Helio G95.**
   - **Drawing:** bake static art once, aim for about 60 draw calls or fewer in gameplay, and keep the single background shader.
   - **Code:** no per-frame allocations, and pooled particles.
5. **Toddler safety.** The header has a scaled 100 px touch guard, the parent gate is a 3 s hold, and the back gesture doesn't quit the app.
6. **Verify before reporting:** `make import`, `make test`, and a headless main-scene run with no `ERROR`.
