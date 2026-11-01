# BabyPianoPop: Godot rewrite spec

This spec covers the behaviour of the React/Capacitor version (v0.3.0) that the Godot 4 rewrite must keep, plus the changes the rewrite introduces.

- **Values:** taken from the old source, where the code wins over older docs. `A:` means `src/App.tsx` in the old web app, which is kept in the repo until the rewrite reaches parity.
- **Changes:** listed in the "Rewrite changes" section at the end.

## Flow
1. **Start screen**
   - Pastel gradient background with floating bubbles.
   - Jelly Bear mascot (120px, "happy" mood). It can be tapped, with the same effect as tapping it in the header.
   - Age selector: 3 buttons plus a 0–2 slider. Each button shows the stage name and its title.
   - Pulsing **PLAY** button (scale [1, 1.04, 1] over 2 s). Pressing it unlocks audio, starts the music box and sets the mood to happy for 1500 ms.
2. **Gameplay**
   - The board is at most 448 px wide (scale this to the viewport) and has 4 dashed lanes.
   - The header is fixed and 100 px tall (scaled): Jelly Bear (52 px) on the left, a 3-star pill in the middle, a 44 px gear on the right.
3. **Choosing an age tier** does all of the following:
   - saves the tier
   - resets speed to that tier's `baseSpeed`
   - plays the pop chime
   - speaks the tier title
   - sets the mood to happy for 1400 ms

## Age tiers (A:74-126, content pools A:43-50 and A:205-213)
| Tier | baseSpeed (px/frame at 60 fps) | Input | Content pool |
|---|---|---|---|
| `6-12m` Infant | 0.62 | touch-enter glide (move events also pop) | 5 shapes + A, B, C + 1, 2, 3 |
| `1-2y` Young Toddler (**default**) | 0.85 | tap only | 5 shapes + 0–9 + A–J |
| `2-3y` Toddler | 1.05 | tap only | 5 shapes + 0–9 + A–Z |

- Shapes are `★ ♥ ● ▲ ■`.
- Each tier also has title, subtitle, badge, description and accent strings at A:74-126.

## Game loop (A:1418-1479)
**Frame timing and speed**
- `dt = min(35 ms, frame delta)`, and `ts = dt / 16.67`.
- Tempo decay: if more than 950 ms has passed since the last pop and `tempo > 1`, then `tempo = max(1, tempo − 0.015·ts)`.
- Each frame a tile moves down by `speed × tempo × ts`.

**When a tile reaches the bottom**
- A tile that reaches `viewportHeight − 110` becomes **stuck**: y is clamped there and the mood is set to "encourage" for 2000 ms.
- While any tile is stuck, everything rewinds upward until the stuck tile reaches `centerY = max(160, viewportHeight × 0.44)`.
  - The rewind step is `max(0.65, diff × 0.08) × ts`.
  - Once it gets there, everything holds still and nothing spawns.
- Visuals for a stuck tile: scale pulse [1.02, 1.08, 1.02] over 1.2 s, a yellow glow `rgba(253,224,71,.65)`, and a star badge that rotates 360° every 4 s.

**Spawning**
- A new tile spawns when the highest tile's y is greater than `gap`. If there are no tiles, highest y counts as 1000.
- `gap` starts at 240. After each spawn it becomes `220 + rand × 80`.
- A new tile gets:
  - a random lane, 0–3
  - the next `candyIndex` in order, cycling through 6 themes
  - random content from the tier's pool
  - a starting y of 95

**Layout**
- Width is 24% of the board for shapes and 23% for letters and numbers. `left = lane × 25% + 1%`.
- Letter and number tiles are 3:4; shape tiles are square.
- Tiles are clipped above y = 100.

## Popping a tile (A:1482-1590)
1. Ignore the tile if its id has already been popped.
2. Play the pop chime, then speak the tile's content (voice clip; see PHONETIC_MAP).
3. Burst particles. Origin y is 0.72 of the screen for every tier; the rest depends on the tier:

   | Tier | Count | Spread | Gravity | Scale | Shapes | Colours (`theme.shadow` first) |
   |---|---|---|---|---|---|---|
   | 6-12m | 20 | 55° | 0.65 | 1.15 | circles | `#f472b6 #38bdf8 #fbbf24 #a78bfa #fff` |
   | 1-2y | 32 | 72° | 0.88 | 1.05 | circles, stars | `#ec4899 #06d6a0 #f59e0b #8b5cf6 #fff` |
   | 2-3y | 44 | 85° | 1.05 | 1.0 | stars, circles | `#d946ef #10b981 #0ea5e9 #f43f5e #eab308 #fff` |

4. **Tempo boost:** if less than 1500 ms passed since the previous pop, `tempo = min(2.4, tempo + 0.35)`.
5. **Stars:** `next = prev >= 3 ? 1 : prev + 1`.
   - When `next` reaches 3:
     - `completedRounds++`, which shifts the palette
     - mood "celebrate" for 2400 ms
     - star chime
     - a burst of 28 particles, spread 70°, at (0.5, 0.12), colours `#ff70a6 #ffd166 #06d6a0 #a855f7`
     - after 280 ms, speak "Three stars! {PRAISE[i++]}" if praise mode is on, otherwise "Three stars! Hooray!"
     - after 1800 ms, reset stars to 0
   - Otherwise: mood "happy" for 900 ms.
6. **Speed adapt:**
   - If the tile was stuck: `speed = max(base × 0.7, speed − 0.25)`.
   - Otherwise: `speed = min(base × 2.2, speed + 0.05)`.

## Hit testing (A:1593-1695)
Steps, in order:
1. Reject if `y < 100` (the header touch guard).
2. Reject if the event is a move and the tier is not `6-12m`.
3. Pop the tile directly under the finger, if there is one.
4. Otherwise do a sticky search: the hit box half-size is `(w/2 + 16, h/2 + 16)`, multiplied by 1.15 when the finger is moving. Pick the nearest tile by squared distance.

Inputs:
- Every touch point is checked (multi-touch).
- Drag/move is checked only for the infant tier.

## Header interactions
- **Mascot tap:**
  - giggle sound
  - mood "celebrate" for 1200 ms
  - speak the next of MASCOT_PHRASES, cycling in order
  - a burst of 22 particles, spread 70°, at (0.18, 0.12)
- **Star pill tap:** star chime, then a burst of 16 particles at (0.5, 0.12) in `#fbbf24 #f59e0b #fef08a #fff`, then speak by star count:
  - 0: "Tap candies to earn three stars!"
  - 1: "One star! Get two more!"
  - 2: "Two stars! One more to go!"
  - 3: "Three stars! Super job!"
- **Gear (parent gate):**
  - Hold for **3000 ms** (ring progress r = 20, gradient `#ec4899 → #8b5cf6`) to:
    - vibrate (`unlock`)
    - burst 22 particles at (0.8, 0.12) in `#a855f7 #ec4899 #3b82f6`
    - open settings
  - Releasing after 40–1200 ms:
    - wobble (rotate [0, 90, −45, 30, 0] over 0.45 s)
    - tick sound
    - speak the next of `['Click!','Beep beep!','Twirl!','Tick tock!']`, cycling
    - burst 12 particles at (0.88, 0.12)
  - Releasing between 1200 and 3000 ms does nothing.
- **Settings modal:**
  - **Age:** the same 3-way selector.
  - **Music:** ON/OFF. Muting silences synth sounds and music, but not speech.
  - **Praise Mode:** "Jelly Bear Cheers", ON/OFF.
  - **Done** and **X** both close it.
  - **Rewrite change:** the game pauses while the modal is open.

## Content to port verbatim (from the old `src/App.tsx`)
| Data | Location |
|---|---|
| ALPHABET, NUMBERS, SHAPES | A:28-35 |
| Tier subsets | A:43-50 |
| AGE_CONFIGS strings | A:74-126 |
| PASTEL_PALETTES (6) | A:138-187 |
| PRAISE_PHRASES | A:196-203 |
| PHONETIC_MAP (A–Z, 0–9, shapes; e.g. A → "Ay", W → "Double-you", ★ → "Star") | A:216-263 |
| CANDY_THEMES (6) | A:265-272 |
| Music-box melody | A:296-304 |
| SETTING_TAP_PHRASES | A:851 |
| MASCOT_PHRASES ("Peekaboo!", "Yay! Hello baby!", "Giggle giggle!", "Wheee!", "I see you!", "Peekaboo! Big smile!") | A:1341 |

**Palette:** `index = (completedRounds + tierOffset[0,1,2]) % 6`. The background is a vertical 3-stop gradient:

| Palette | Stops |
|---|---|
| lavender | `#fce7f3 → #f3e8ff → #e0e7ff` |
| peach | `#fef3c7 → #ffe4e6 → #ffedd5` |
| mint | `#d1fae5 → #ccfbf1 → #e0f2fe` |
| rose | `#ffe4e6 → #fce7f3 → #fae8ff` |
| sky | `#e0f2fe → #dbeafe → #e0e7ff` |
| lemon | `#fef9c3 → #fef3c7 → #d1fae5` |

**Candy themes** (gradient / shadow):

| Theme | Gradient | Shadow |
|---|---|---|
| strawberry | `#f43f5e → #ec4899 → #e11d48` | `#9f1239` |
| tangerine | `#fbbf24 → #fb923c → #f97316` | `#c2410c` |
| lemon | `#fcd34d → #facc15 → #f59e0b` | `#b45309` |
| apple-mint | `#34d399 → #2dd4bf → #059669` | `#047857` |
| blue-raspberry | `#38bdf8 → #3b82f6 → #4f46e5` | `#1d4ed8` |
| grape-jelly | `#a855f7 → #d946ef → #7e22ce` | `#6b21a8` |

## Audio (old recipes; master gain 0.12, set to 0 when muted)
| Sound | Recipe |
|---|---|
| Music-box loop | 28-note melody (A:296). Each note plays `chime(f)`. Gap between notes is 520 ms, or 950 ms when `noteIndex % 8 == 0`. |
| chime(f) | Sine at f, attack to 0.65 in 6 ms, exponential decay to 0.0001 at 1.3 s. Plus sine at f×3.01, 0.14 in 6 ms, decays by 0.6 s. Both go through a lowpass at 2800 Hz. |
| pop | Sine 523.25 → 1046.5 Hz (exponential, 80 ms). Gain 0.32, decays by 140 ms. |
| giggle | Sines 659.25, 783.99, 1046.5 Hz, 80 ms apart. Each 0.25, decays by 180 ms. |
| star | Triangles 1318.51 and 1975.53 Hz, 60 ms apart. Each 0.25, decays by 320 ms. |
| setting tick | Sine 880 → 1760 Hz over 60 ms. Gain 0.24, decays by 140 ms. |

**Old speech:** TTS en-US, pitch 1.08, rate 0.86, interrupting.

## Saved settings
| Key | Values | Default |
|---|---|---|
| `age_tier` | `6-12m` / `1-2y` / `2-3y` | `1-2y` |
| `praise_mode` | bool | true |
| `music_on` | bool | true (new: now saved) |

## Visual identity to keep
- **Jelly Bear:**
  - body `#ff70a6 → #ff477e → #d90429`
  - inner ears and muzzle `#ffd6e0 → #ffb3c1`
  - cheeks `#ff758f`
  - eyes `#3a0ca3`; eyes switch to `^ ^` arcs when happy or celebrating
  - nose and mouth `#5c0029`
  - yellow star on the head (`#fef08a`, stroke `#eab308`)
  - sparkle aura when celebrating
- **Mascot moods:**
  - idle: y [0, −3, 0], 2.4 s loop
  - happy: y [0, −10, 2, 0], scale up to 1.12
  - encourage: rotate ±8°
  - celebrate: y [0, −14, 0, −10, 0], rotate ±12°
  - every mood except idle runs once over 0.6 s
- **Shape tiles:**
  - ★ is amber `#fbbf24`, ♥ is rose `#f43f5e`, ▲ is emerald `#10b981`; each has a 6 px drop bevel in the theme's shadow colour, a gloss highlight and a cute face.
  - ● and ■ use the candy gradient, with a white dot face.
  - Letter and number tiles: big white extra-bold glyph, 8 px bottom border in `theme.shadow`.
- **Floating bubbles:** 16 bubbles. Values for bubble i:
  - `size = 18 + (i×17+7) % 36`
  - `left = (i×23+11) % 94 + 3` (%)
  - `duration = 14 + (i×7) % 12` (s)
  - `delay = −((i×3.5) % 16)` (s)
  - `sway = 3.5 + (i×1.8) % 4` (s), ±18 px
  - `opacity = 0.22 + ((i×5) % 18) / 100`
  - They rise from 105% to −15% of the screen height.

## Rewrite changes (new requirements)
1. **Engine:** Godot 4.7, Compatibility renderer, 2D. Portrait locked. 60 fps cap.
2. **Look ("cozy pastel", inspired by the mood of *Organized Inside*; no assets copied):**
   - pastel polka-dot background (shader) over the palette gradient
   - cream panels and buttons with **warm-brown outlines (`#7A5233`)** and rounded corners
   - rounded OFL font (Fredoka or Nunito)
   - candy tiles keep the candy colours, plus a brown outline and a soft bevel
   - the Jelly Bear is redrawn in the same outlined style
3. **Performance:**
   - Tiles are Node2D moved in `_process`. No per-frame allocations and no layout containers for moving things.
   - Particles use CPUParticles2D, or one pooled custom burst node.
   - No full-screen blur.
4. **Audio:**
   - Every sound is a pre-rendered OGG through AudioDirector: SFX bus (pop, chime notes, giggle, star, tick), Music bus (music-box loop rendered as one seamless OGG), Voice bus (Kokoro clips).
   - No runtime synthesis.
   - Speech interrupts the previous line.
5. **Voice clips** (ids used by code): ids are snake_case of the content.
   - letters `letter_a` … `letter_z`
   - numbers `number_0` … `number_9`
   - shapes `shape_star`, `shape_heart`, `shape_circle`, `shape_triangle`, `shape_square`
   - tier titles `tier_6_12m`, `tier_1_2y`, `tier_2_3y`
   - praise `praise_<n>`
   - mascot `mascot_<n>`
   - gear `gear_<n>`
   - stars `stars_0` … `stars_3`
   - `three_stars_hooray`
   - praise lines are spoken as "Three stars! {praise}", so pre-render the full lines as `three_stars_praise_<n>`
6. **Lifecycle:** when the app leaves the foreground everything pauses (the Lifecycle autoload) and resumes on return.
7. **Haptics:** light `pop` buzz on each pop, `stuck` when a tile sticks, `stars` on 3 stars, `unlock` on the parent gate.
