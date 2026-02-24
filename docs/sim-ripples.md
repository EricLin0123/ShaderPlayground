# `sim-ripples.glsl`: How It Works

Shader file:

- `src/shaders/sim-ripples.glsl`

This shader is a stateful water ripple simulation built on the project ping-pong pipeline.  
Each animation frame runs two passes:

1. `mainSim`: update ripple state into an offscreen texture.
2. `mainImage`: shade that state as water on screen.

## Runtime Contract

`SimulationRenderer` provides these uniforms each frame:

- `u_prev_state`: previous simulation texture (read-only this pass)
- `u_resolution`: simulation resolution in pixels
- `u_mouse`: pointer position in pixel space
- `u_frame`: frame index (`0`, `1`, `2`, ...)
- `u_pass`: `0` for simulation pass, `1` for display pass

The simulation texture is `RGBA8` (`UNSIGNED_BYTE`), so values are stored in `[0, 1]` per channel.

## State Encoding

The shader stores signed heights by packing/unpacking:

```glsl
decodeHeight(v) = v * 2.0 - 1.0
encodeHeight(h) = h * 0.5 + 0.5
```

Channel meaning:

- `R`: current height `h(t)`
- `G`: previous height `h(t - dt)`
- `B`: velocity-like term `h(t + dt) - h(t)` (debug/auxiliary)
- `A`: constant `1.0`

## Simulation Pass (`mainSim`)

### 1) Initialization

On the first frame (`u_frame < 0.5`), the shader seeds a tiny sinusoidal pattern:

```glsl
seed = sin(uv.x * 20.0) * sin(uv.y * 20.0) * 0.05
```

This avoids a completely flat start.

### 2) Discrete Wave Update

For later frames, it samples 4-neighbors from `R` and computes a Laplacian:

```text
lap = left + right + down + up - 4 * current
```

Then updates height with a second-order wave step:

```text
next = (2 * current - previous) + 0.25 * lap
```

- `2 * current - previous` is temporal inertia.
- `0.25 * lap` is spatial propagation (effective wave speed term).

### 3) Damping

```text
next *= 0.995
```

This slowly removes energy so waves decay instead of ringing forever.

### 4) Mouse Disturbance

If pointer coordinates are valid (`u_mouse.x > 1.0 || u_mouse.y > 1.0`), it injects a local impulse:

```text
next += exp(-distance(uv, mouseUv) * 90.0) * 0.4
```

That Gaussian bump creates expanding ripples centered at the cursor.

### 5) Write Next State

The pass writes:

- `R = encode(next)`
- `G = encode(current)`
- `B = encode(next - current)`

So the next frame has both `h(t)` and `h(t - dt)`.

## Display Pass (`mainImage`)

### 1) Reconstruct Surface Normal

It reads current height and neighboring heights, computes a gradient, then builds a normal:

```text
grad = (hr - hl, hu - hd)
n = normalize(vec3(-grad.x * 13, 1, -grad.y * 13))
```

The `13` multiplier increases apparent surface steepness.

### 2) View/Light Setup

- View direction comes from screen position (`uv`) with aspect correction.
- Light direction is fixed: `normalize(vec3(0.35, 0.84, 0.42))`.

### 3) Reflection + Fresnel

It computes reflection direction from the normal and samples a procedural sky gradient.  
Fresnel term:

```text
F = 0.02 + (1 - 0.02) * (1 - dot(n, viewDir))^5
```

This gives stronger reflection at grazing angles.

### 4) Water Base Color

Height drives a shallow/deep blend:

- Shallower (higher surface) looks brighter turquoise.
- Deeper (lower surface) looks darker blue.

### 5) Specular Highlights + Foam

- Blinn-Phong style specular (`pow(dot(n, halfVec), 96)`).
- Sun glint from reflection/light alignment.
- Foam mask from local curvature (`abs(laplacian(height))`) and `smoothstep`.

Final color combines base water, sky reflection, lighting, and foam, then clamps to `[0, 1]`.

## Stability and Tuning Notes

- Increase `0.25` (Laplacian scale): faster, less stable waves.
- Decrease damping (`0.995 -> 0.99`): shorter ripple lifetime.
- Raise mouse amplitude (`0.4`): stronger disturbances.
- Reduce normal scale (`13`): flatter visual surface.

Because state is `RGBA8`, very small amplitudes quantize; large amplitudes can clip after encoding.  
If you need smoother physics, switch state textures to floating-point formats.
