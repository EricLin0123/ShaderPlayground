# GLSL Simulations: Ping-Pong, Conway, Ripples, Watercolor, Reaction-Diffusion

This project now includes simulation shaders that rely on framebuffer ping-pong (stateful updates each frame).

## Run

```bash
npm run dev
```

Open:

- `http://localhost:5173/?shader=sim-pingpong`
- `http://localhost:5173/?shader=sim-conway`
- `http://localhost:5173/?shader=sim-ripples`
- `http://localhost:5173/?shader=sim-watercolor`
- `http://localhost:5173/?shader=sim-reaction-diffusion`

For `sim-reaction-diffusion`, the sidebar includes live sliders:

- Feed (`u_rd_feed`)
- Kill (`u_rd_kill`)
- Diffusion A (`u_rd_da`)
- Diffusion B (`u_rd_db`)

Use `Reset Simulation` after parameter changes to re-seed from frame 0.

## 1. Ping-Pong (Core Technique)

Location:

- `src/core/SimulationRenderer.js`
- `src/core/SimulationShaderProgram.js`

Ping-pong means alternating two textures each frame:

1. Read previous state from texture A
2. Write next state into texture B (offscreen framebuffer)
3. Display texture B
4. Swap A and B

This avoids reading and writing the same texture in one pass, which is invalid in WebGL.

Simulation shader contract:

- `mainSim(out vec4, in vec2)` updates state
- `mainImage(out vec4, in vec2)` visualizes state
- `u_prev_state` is the previous frame state texture
- `u_frame` is the frame index
- `u_pass` selects simulation pass (`0`) or display pass (`1`)

## 2. Conway’s Game of Life

Shader:

- `src/shaders/sim-conway.glsl`

State:

- `R` channel stores alive (`1`) / dead (`0`) cell.

Rule per cell (8-neighbor Moore neighborhood):

- Alive survives with 2 or 3 neighbors
- Dead becomes alive with exactly 3 neighbors

The shader supports mouse seeding (paint alive cells).

## 3. Ripples

Shader:

- `src/shaders/sim-ripples.glsl`
- Detailed doc: `docs/sim-ripples.md`

State:

- `R` = current height
- `G` = previous height

Update uses a discrete wave equation:

```text
next = 2 * current - previous + c * Laplacian(current)
```

Then damping is applied to avoid infinite oscillation.

Display pass uses height gradients to refract `u_texture`, creating water-like distortion.

## 4. Watercolor

Shader:

- `src/shaders/sim-watercolor.glsl`

State:

- `RGB` = pigment concentration
- `A` = water amount

Model:

- Pigment advection (flow field driven movement)
- Diffusion/smoothing from neighbors
- Gradual drying (water decay)
- Mouse adds moisture and pigment

Display includes simple edge darkening and paper grain.

## 5. Reaction-Diffusion (Gray-Scott Style)

Shader:

- `src/shaders/sim-reaction-diffusion.glsl`

State:

- `R` = chemical A
- `G` = chemical B

Continuous update:

```text
dA/dt = Da * Lap(A) - A * B^2 + f * (1 - A)
dB/dt = Db * Lap(B) + A * B^2 - (k + f) * B
```

Where:

- `Da`, `Db` are diffusion rates
- `f` is feed rate
- `k` is kill rate

This produces spots, stripes, and labyrinth-like patterns. Mouse injects chemical B locally.

## 6. Dedicated Ping-Pong Demo

Shader:

- `src/shaders/sim-pingpong.glsl`

This shader is intentionally simple: it demonstrates temporal feedback, decay, and mouse injection so you can clearly see how ping-pong state accumulates over time.

## Suggested Experiments

1. Change `feed/kill` in reaction-diffusion to explore different regimes.
2. Increase Conway resolution and compare visual behavior at 500x500 vs 1000x1000.
3. Tune ripple damping and wave speed for stable vs explosive simulations.
4. Add a laplacian blur pass in watercolor to exaggerate pigment blooming.
