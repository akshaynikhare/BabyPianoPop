# Baby Piano Pop 🍬🎹

A minimalist, high-contrast sensory exploration and reinforcement learning game built specifically for infants and toddlers (ages 6 to 36 months).

Clean, soothing, and zero-distraction: babies learn letters, numbers, and geometric shapes through immediate tactile feedback, gentle acoustic chimes, and articulate phonetic speech.

---

## 🌟 Philosophy: Low-Cognitive-Load Reinforcement Learning

Traditional toddler apps are often cluttered with distracting menus, advertisements, and confusing controls. **Baby Piano Pop** is designed with the following principles:

1. **Immediate Cause & Effect**: Every single touch generates instant multi-sensory feedback: a soft musical chime, crisp vocal articulation, and dynamic celebratory confetti.
2. **Never Punish**: There are no "game over" screens, timers, or negative buzzers. If a tile reaches the bottom, it gently pauses with a warm breathing glow, softly encouraging the baby to tap it.
3. **Adaptive Developmental Progression**: 3 distinct developmental stages adapt the cognitive load, lane count, curriculum size, and touch mechanics to match the child's age.
4. **Child-Proof Ergonomics**: A 100px protected top header shields system buttons, and parental settings are locked behind an intentional 3-second hold circular fill button.

---

## 👶 Developmental Age Tiers

| Tier | Target Age | Lanes | Curriculum | Touch Mechanics | Confetti & Particle Burst |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Infant** | 6–12 months | 3 | Starter Shapes (★, ♥, ●, ▲, ■), Letters (A, B, C), Numbers (1, 2, 3) | **Continuous Touch-Enter Glide**: Baby can swipe or drag finger across tiles to pop them immediately | Soft round pastel bubble circles (`shapes: ['circle']`), slow float with gentle gravity |
| **Young Toddler** | 1–2 years | 4 | Shapes, Letters (A–J), Numbers (0–9) | **Discrete Tap-to-Pop**: Encourages deliberate finger taps and coordination | Lively fruit punch candies with mixed round bubbles and stars (`shapes: ['circle', 'star']`) |
| **Toddler** | 2–3 years | 5 | All 5 Shapes, Full Alphabet (A–Z), All Numbers (0–9) | **Discrete Tap-to-Pop**: Refined motor control with faster rhythm | High-energy neon gummy star bursts (`shapes: ['star', 'circle']`) |

---

## 🎨 Sensory & Visual Features

- **Floating Background Bubbles**: Delicate, translucent pastel bubbles slowly drift upward across the screen with gentle organic sway, creating atmospheric depth without interfering with touch targets.
- **Dynamic Tile-Pop Confetti**: Confetti bursts dynamically adapt their shapes and color palettes to the active age tier, blending the active candy tile's hue with tier-specific accents.
- **Full Shape Buttons**: When a geometric shape appears (Star, Heart, Circle, Triangle, Square), the entire button transforms into a tactile 3D candy shape with cute friendly micro-expressions.
- **Responsive Counter Guard**: The star counter in the top header handles scores from 0 to 100,000+ stars with dynamic font down-scaling, zero layout shift, and `shrink-0` bounds protection so the UI never clips off-screen on small mobile devices.
- **Interactive Jelly Bear Mascot**: Tap the friendly Jelly Bear in the top header for peekaboo giggles, cheerful voice affirmations, and micro-confetti.

---

## 🔊 Acoustic Engineering & Phonetics

- **Procedural Pentatonic Music Box Synth**: Built using the Web Audio API with zero external audio assets. Utilizes dual harmonic sine waves filtered through a 2800Hz lowpass filter to prevent harsh high frequencies and acoustic fatigue.
- **High-Clarity Phonetic Speech**: Letters and numbers are pronounced with intentional phonetics (e.g., "Ay", "Bee", "See", "Zee") using the Web Speech API with automatic high-clarity natural voice selection and Capacitor native Text-to-Speech fallback.
- **Baby Tap Interactions**: Quick taps (<1.2s) on the locked parental gear button produce a cheerful tick sound, playful wiggle animation, and reassuring spoken feedback.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: React 19 + TypeScript
- **Bundler & Dev Server**: Vite 6
- **Styling**: Tailwind CSS 4 (GPU-accelerated animations, zero-pill discipline)
- **Motion & Physics**: Motion (`motion/react`) + Canvas-Confetti
- **Audio**: Web Audio API (procedural synthesis) + Web Speech API / Capacitor TTS
- **Development Tooling**: ActionPlan Kit (`akshaynikhare/action-plan-kit`) for spec-driven workflows

---

## 🚀 Getting Started

### Prerequisites
- Node.js 20+
- npm or pnpm

### Installation
```bash
npm install
```

### Development Server
```bash
npm run dev
```
Open `http://localhost:3000` in your browser.

### Type Check & Build
```bash
npm run lint      # TypeScript validation (tsc --noEmit)
npm run build     # Production Vite build
```

---

## 📄 License
MIT License. Created with love for babies, parents, and curious minds.
