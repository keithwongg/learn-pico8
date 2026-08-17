# Learn PICO-8: Snake

A feature-rich, standalone classic Snake game cartridge built for **PICO-8** (compatible with both Desktop and the free **PICO-8 Education Edition**).

---

## 🎮 Features

- **Fluid 60 FPS Gameplay & Input Buffering**: Implements a 2-command input queue to allow fast, responsive corner turns without accidental 180° self-collisions.
- **Dynamic Speed Scaling & Dash**: Movement gradually speeds up as you eat apples. Holding **❎** boosts your speed to dash through open areas.
- **Golden Apples**: Every 5 apples, a special golden apple spawns on a timed countdown, granting bonus points, sparkling particles, and a fanfare chime.
- **Sprite-Based Pixel Art**: Custom 8x8 sprites for the directional snake head (with animated eyes & tongue), textured body segments, tapered tail, juicy apples, golden apples, and dizzy 'X'-eyed game over animation.
- **Visual Juice & Effects**: Particle bursts when eating food or dying, and screen shake on collision.
- **Persistent High Scores**: Uses `cartdata()` and `dget()` / `dset()` to store your best score across sessions (including browser local storage in the Education Edition).
- **Embedded SFX**: Custom sound effects for eating, golden apple fanfare, alert pings, crash explosions, and menu selections.

---

## 🕹️ Controls

| Action | PICO-8 Button | Keyboard (Desktop / Web) |
| :--- | :--- | :--- |
| **Move** | ⬅️ ➡️ ⬆️ ⬇️ (D-Pad) | Arrow Keys / `E S D F` |
| **Speed Boost (Dash)** | ❎ (Hold) | `X` / `V` |
| **Start / Retry** | ❎ or 🅾️ | `X` / `Z` / `C` / `V` |

---

## 🎨 Sprite Sheet Index (`__gfx__`)

| Sprite ID | Sprite Graphic | Description |
| :---: | :--- | :--- |
| `1` | **Head (Right)** | Green head facing right with eye and tongue |
| `2` | **Head (Up)** | Green head facing up with twin eyes |
| `3` | **Head (Down)** | Green head facing down with twin eyes |
| `4` | **Head (Left)** | Green head facing left with eye and tongue |
| `5` | **Body Segment** | Rounded green body segment with scale highlights |
| `6` | **Tail** | Tapered tail segment |
| `7` | **Apple** | Red apple with green leaf, brown stem, and shine |
| `8` | **Golden Apple** | Golden apple with shimmering crown and sparkles |
| `9` | **Dead Head** | Dizzy head with **X** eyes on game over |
| `10` | **Trophy Icon** | Golden trophy icon for HUD high score and records |
| `11` | **Wall Tile** | Textured border tile |

---

## 📁 Code Architecture (`snake.p8`)

The cartridge is organized into self-contained sections:

1. **Section 1: Initialization & State Management**: `_init()`, cartdata setup, state routing (`title`, `play`, `gameover`).
2. **Section 2: Main Game Loop**: `_update60()`, `_draw()`, input polling, and state updates.
3. **Section 3: Snake Mechanics & Collisions**: `step_snake()`, `queue_dir()`, self/wall collision detection, and `die()`.
4. **Section 4: Food Management**: Regular & golden apple spawning, vacant cell verification, and timers.
5. **Section 5: Particles & Screen Juice**: `add_particle()`, `emit_burst()`, and `apply_camera_shake()`.
6. **Section 6: Sprite Rendering & UI**: Sprite rendering via `spr()`, HUD, title screen, and game-over overlay.
7. **`__gfx__` & `__sfx__`**: Built-in 8x8 sprite sheet and sound effect data.

---

## 🚀 How to Run

### Option A: PICO-8 Education Edition (Browser)
1. Open [pico-8.education](https://www.pico-8-edu.com/) in your web browser.
2. Drag and drop [`snake.p8`](file:///Users/keithwong/Repos/learn-pico8/snake.p8) onto the window.
3. Type `run` (or press `CTRL+R` / `CMD+R`) to play.

### Option B: PICO-8 Desktop
1. Launch PICO-8.
2. In the console, load the cartridge:
   ```sh
   load snake.p8
   run
   ```
