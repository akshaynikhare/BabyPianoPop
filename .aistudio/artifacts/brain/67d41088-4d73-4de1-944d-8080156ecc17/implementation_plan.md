# Implementation Plan: Floating Background Bubbles, Dynamic Age-Tier Confetti, and Project Documentation

Implement gentle floating background bubbles, tier-responsive confetti celebrations, and a comprehensive documentation and design suite for the baby reinforcement learning app.

---

## 1. Background Floating Bubbles Layer
- **Component**: Create `src/components/FloatingBubbles.tsx` (or embedded background layer).
- **Aesthetic**:
  - Soft, translucent pastel bubbles drifting slowly upward with subtle organic horizontal swaying (`@keyframes floatUp`).
  - Varying sizes (18px to 64px), varied opacities (0.15 to 0.35), and gentle pastel radial gradients.
  - Zero performance cost: GPU-accelerated CSS transforms (`transform: translate3d(...)`), `will-change: transform`, and `pointer-events-none z-0`.
  - Never obscures tile readability or causes accidental touches.

---

## 2. Dynamic Age-Tier Confetti Bursts
- **Infant Tier (6-12 mo)**:
  - Colors: Calm macaron pastels (`#f472b6`, `#38bdf8`, `#fbbf24`, `#a78bfa`, `#34d399`).
  - Shapes: Soft round circles and gentle bubbles (`shapes: ['circle']`).
  - Physics: Lower velocity, gentle gravity, soft float-down mimicking soap bubbles.
- **Young Toddler Tier (1-2 yr)**:
  - Colors: Lively fruit punch candies (`#ec4899`, `#06d6a0`, `#f59e0b`, `#8b5cf6`, `#3b82f6`).
  - Shapes: Mixed circles and stars (`shapes: ['circle', 'star']`).
  - Physics: Medium velocity and festive burst.
- **Toddler Tier (2-3 yr)**:
  - Colors: Vibrant neon gummy palette (`#d946ef`, `#10b981`, `#0ea5e9`, `#f43f5e`, `#eab308`).
  - Shapes: High-energy star bursts and celebratory particles (`shapes: ['star', 'circle']`).
  - Physics: High velocity, wide spread, crisp festive pops.

---

## 3. Project Documentation & Design Suite
- **`README.md`**:
  - High-level overview: ultra-clean, low-IQ baby sensory exploration app.
  - Reinforcement learning principles: immediate tactile feedback, phonetic articulation, visual reward loops.
  - Age tier matrix (Infant, Young Toddler, Toddler) detailing columns, content scope, and touch mechanics (touch-enter vs standard click).
  - Parent safety features: 3-second hold gate for settings, protected top header bar, accidental tap mitigation.
  - Development setup, scripts, and architecture overview.
- **`AGENT.md`**:
  - Strict coding and design rules for AI agents and future engineers.
  - Baby UX guidelines: zero-pill discipline, no micro-copy or clutter, strict touch guards.
  - Audio architecture: Web Audio API synthesis + curated speech synthesis fallback rules.
  - Performance rules: 60fps animations, GPU offloading, zero blocking tasks.
- **`docs/DESIGN.md`**:
  - Sensory UX & design system: color tokens, typography, hit-area ergonomics (15% sticky touch detection).
  - Cognitive load management for developmental phases.
  - Sound design & acoustic engineering (harmonic pentatonic scale, mascot giggles, chime frequencies).

---

## 4. Verification Plan
- Run `lint_applet` to confirm zero lint or TypeScript errors.
- Run `compile_applet` to ensure production Vite build passes cleanly.
- Verify smooth animation performance and touch response.
