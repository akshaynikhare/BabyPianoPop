# AGENT.md: Engineering & Design Guidelines for AI Agents

This document defines the strict architectural contracts, sensory UX standards, and safety invariants for any AI agent or developer modifying the **Baby Piano Pop** codebase.

---

## 🎯 1. Core Mission & Invariants

Baby Piano Pop is a **low-cognitive-load reinforcement learning game** for infants (6–36 months). Every design decision must prioritize simplicity, baby sensory safety, and instant positive feedback.

### Non-Negotiable Invariants:
1. **Never Punish**: No game over, no failing states, no harsh red buzzers, no negative audio.
2. **Top 100px Touch Guard**: The top 100px header is strictly guarded against accidental tile touches. Any touch event occurring with `y < 100` must NEVER activate falling tiles.
3. **Parent Lock Gate**: Settings and parental configurations must ALWAYS be guarded by the 3-second hold circular fill button. Fast taps (<1.2s) must trigger playful feedback (wiggle, tick chime, voice), never open settings.
4. **Phonetic Pronunciation First**: Never speak raw single characters directly to speech synthesis. Always look up `PHONETIC_MAP` in `/src/App.tsx` (e.g., `'A': 'Ay'`, `'C': 'See'`, `'Z': 'Zee'`).
5. **Zero UI Clutter**: Never inject debug panels, telemetry counters, chat widgets, unrequested pills, or cluttered menus into the infant interface.

---

## 🕹️ 2. Developmental Tiers & Touch Ergonomics

When implementing new features or adjusting difficulty, always respect the active `AgeTier`:

```typescript
export type AgeTier = '6-12m' | '1-2y' | '2-3y';
```

- **Infant (`6-12m`)**:
  - Touch interaction: **Continuous Touch-Enter Glide**. Baby can swipe across the screen; tiles touching the finger path pop immediately.
  - Sticky Hit Area: When the finger is in motion, detection radius expands by **+15%** to accommodate loose infant motor precision.
  - Confetti: Soft round bubble circles only (`shapes: ['circle']`), pastel macaron palette, low gravity (`0.65`).
  - Speed: Base speed is calm (`0.9x`).

- **Young Toddler (`1-2y`)**:
  - Touch interaction: **Discrete Tap-to-Pop** only (dragging does not trigger tiles).
  - Confetti: Mixed round bubbles and stars (`shapes: ['circle', 'star']`), fruit punch palette.
  - Speed: Base speed `1.3x`.

- **Toddler (`2-3y`)**:
  - Touch interaction: **Discrete Tap-to-Pop** only.
  - Confetti: Energetic star bursts (`shapes: ['star', 'circle']`), neon gummy palette, higher velocity (`1.05` gravity).
  - Speed: Base speed `1.75x`.

---

## 🎨 3. Responsive Header & Counter Safety

The header must never overflow or break layout on any screen size (from 320px mobile viewport to desktop):
- All 3 top header items (`JellyBearMascot`, `Candy Score Counter`, `ParentLockButton`) must have `shrink-0`.
- The top header inner container must have `overflow-hidden relative` and `justify-between`.
- The score counter button must use:
  - `min-w-[68px] max-w-[110px] shrink-0 overflow-hidden`
  - Score formatted through `formatScore(score)` (e.g. `99k` for 100k+)
  - Text size dynamically computed via `getScoreTextClass(score)`
  - Tap animation scale restricted to `scale: 0.94` to prevent visual collisions.

---

## 🔊 4. Audio Architecture

All sound is generated procedurally via the Web Audio API inside the `CandyMusicBox` class:
- **Synth**: Pure sine oscillators with second harmonic layer and `BiquadFilterNode` lowpass filter (2800Hz cutoff).
- **Audio Unlock**: Unlocks on the first user interaction (`touchstart`, `pointerdown`, or `handleStart`).
- **Mute Support**: Muting routes through `masterGain.gain.setValueAtTime(0, ctx.currentTime)`.
- **Speech**: `BabyTTS` uses `window.speechSynthesis` with warm English voice prioritization (`Natural`, `Google`, `Samantha`) and Capacitor native TTS fallback.

---

## 🚀 5. ActionPlan Kit & Workflow Integration

This project integrates **ActionPlan Kit** (`https://github.com/akshaynikhare/action-plan-kit`):
- Action plan templates and gates are located in `.actionplan/`.
- Specifications and design documents reside in `docs/`.
- Pre-commit & build verification gates:
  ```bash
  npm run lint      # tsc --noEmit
  npm run build     # vite build
  ```
- Always verify zero TypeScript compiler errors before finishing any turn.
