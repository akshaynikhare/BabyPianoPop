# Baby Piano Pop: Sensory UX & Design System Specification

This document details the visual tokens, cognitive load models, acoustic frequencies, and interaction physics governing **Baby Piano Pop**.

---

## 🎨 1. Color System & Candy Themes

The visual system uses high-saturation, candy-gloss aesthetics inspired by classic confectionery, designed to attract infant ocular fixation while maintaining gentle contrast.

### Candy Color Themes
| Theme Name | Gradient Stops | Shadow Hex | Glow (RGBA) | Dominant Fruit / Flavor |
| :--- | :--- | :--- | :--- | :--- |
| **Strawberry** | `from-rose-500 via-pink-500 to-rose-600` | `#9f1239` | `rgba(244,63,94,0.6)` | Sweet Berry Red |
| **Tangerine** | `from-amber-400 via-orange-400 to-orange-500` | `#c2410c` | `rgba(251,146,60,0.6)` | Citrus Orange |
| **Lemon** | `from-amber-300 via-yellow-400 to-amber-500` | `#b45309` | `rgba(250,204,21,0.6)` | Sun Yellow |
| **Apple-Mint** | `from-emerald-400 via-teal-400 to-emerald-600` | `#047857` | `rgba(52,211,153,0.6)` | Cool Green |
| **Blue-Raspberry** | `from-sky-400 via-blue-500 to-indigo-600` | `#1d4ed8` | `rgba(96,165,250,0.6)` | Electric Blue |
| **Grape-Jelly** | `from-purple-500 via-fuchsia-500 to-purple-700` | `#6b21a8` | `rgba(192,132,252,0.6)` | Royal Purple |

### Age Tier Accents
- **Infant (`6-12m`)**: Soft rose & lavender pastels (`from-pink-400 to-rose-500`)
- **Young Toddler (`1-2y`)**: Energetic citrus & amber punch (`from-amber-400 to-orange-500`)
- **Toddler (`2-3y`)**: Vibrant royal violet & fuchsia (`from-purple-500 to-indigo-600`)

---

## 🫧 2. Particle Systems & Ambient Layer

### Background Floating Bubbles
- **Component**: `src/components/FloatingBubbles.tsx`
- **Count**: 16 deterministic drifting particles.
- **Size Distribution**: 18px to 54px with dual-sheen glass radial gradient highlights.
- **Motion**:
  - Vertical Drift: 14s to 25s linear upward float (`translate3d(0, 105vh, 0) -> translate3d(0, -15vh, 0)`).
  - Horizontal Sway: 3.5s to 7.5s ease-in-out gentle sine wave sway (18px range).
  - Staggered Negative Delays: `-16s` to `0s` ensures smooth instantaneous coverage upon screen load.
- **Touch Layer**: Strictly `pointer-events-none` with GPU `will-change: transform`.

### Age-Tier Confetti Dynamics
- **Infant Tier**:
  - Shapes: `['circle']` (soft pastel macaron bubbles)
  - Count: 20 particles
  - Gravity: 0.65 (slow, gentle floating descent)
  - Scalar: 1.15 (larger, easy-to-track dots)
- **Young Toddler Tier**:
  - Shapes: `['circle', 'star']` (lively fruit candies)
  - Count: 32 particles
  - Gravity: 0.88 (moderate festive pop)
  - Scalar: 1.05
- **Toddler Tier**:
  - Shapes: `['star', 'circle']` (energetic star bursts)
  - Count: 44 particles
  - Gravity: 1.05
  - Spread: 85 degrees

---

## 👆 3. Touch Ergonomics & Sticky Hit Area

Infant motor coordination develops rapidly between 6 and 24 months. Standard 44px tap targets frequently cause frustration for infants.

### The +15% Motion Sticky Detection Algorithm
1. When finger contact is registered (`onTouchStart` / `onPointerDown`), standard touch bounds apply (`baseHalfW = rect.width / 2 + 16px`).
2. When finger movement is detected (`onTouchMove` / `onPointerMove`), `motionMultiplier` increases to **1.15x (+15% expanded radius)**.
3. For infants (6–12 months), continuous glide popping is enabled: any tile entering the expanded hit radius is popped instantly.
4. For older toddlers (1–3 years), discrete tap-to-pop encourages deliberate fine motor skills.

---

## 🔒 4. Top 100px Header & Child-Safety Guard

1. **Header Boundary**: Fixed height `h-[100px]` with touch shield. `checkPoint(x, y)` rejects any tile collision where `y < 100`.
2. **Score Counter Layout**:
   - `min-w-[68px] max-w-[110px]` with `shrink-0` ensures the counter button never expands to push the mascot or settings off-screen.
   - For `score >= 100,000`, values are compactly formatted as `99k+`.
   - Dynamic typography scales font down from `text-xl` to `text-sm` as character count increases.
3. **Parental Settings Gate**:
   - Hold duration: Exactly **3.0 seconds**.
   - Visual feedback: Animated SVG circular progress ring filling from 0% to 100%.
   - Fast baby tap (<1.2s): Triggers tick chime, playful wiggle, and baby-friendly spoken phrase ("Tick tock! Hold 3 seconds!").

---

## 🎶 5. Acoustic Engineering

The soothing pentatonic lullaby sequence avoids dissonant half-steps (semitones):
- Notes: **C5** (523Hz), **D5** (587Hz), **E5** (659Hz), **G5** (784Hz), **A5** (880Hz), **C6** (1046Hz), **D6** (1175Hz).
- Synthesis Architecture:
  - Primary sine oscillator: warm fundamental tone.
  - Secondary harmonic oscillator: `freq * 3.01` at 14% amplitude for rich candy bell resonance.
  - Biquad lowpass filter: 2800Hz cutoff with zero resonance to eliminate harsh transients.
