# Planet Shader Technical Notes

Shader file: `src/shaders/planet.glsl`

This planet shader is built to be article-friendly: each visual feature is tied to a concrete rendering concept (procedural geology, biome synthesis, cloud optics, night-side emission, and atmospheric scattering).

## 1. Camera, ray setup, and sphere intersection

The shader ray-traces an analytic sphere rather than masking a 2D circle.

Core pieces:
- Camera origin: `ro = vec3(0.0, 0.0, 2.7)`
- View ray: `rd = normalize(vec3(uv, -1.8))`
- Sphere hit function: `sphereIntersect(ro, rd, radius)`

Math:
- Sphere equation: `|ro + t*rd|^2 = r^2`
- Quadratic terms:
  - `b = dot(ro, rd)`
  - `c = dot(ro, ro) - r^2`
  - discriminant `h = b^2 - c`
- Hit distances: `t = -b ± sqrt(h)`

Why it matters:
- Gives perspective-correct limb shape and depth-aware atmosphere integration.
- Lets the atmosphere be computed along the actual ray segment through a shell.

## 2. Procedural terrain: domain-warped continents + ridged mountains

Main functions:
- `noise3(vec3 p)` (value noise)
- `fbm(vec3 p)` (fractal Brownian motion)
- `ridgedFbm(vec3 p)` (ridge-style noise)
- `planetHeight(vec3 p)` (final terrain model)

Pipeline in `planetHeight`:
1. Build a warp field from low-frequency FBM.
2. Evaluate warped continental noise.
3. Convert to a continent mask via `smoothstep`.
4. Add ridged mountains on continents.
5. Add erosion/tectonic detail terms.

Key idea for article:
- Don’t use a single noise octave stack for terrain. Split shape by scale and role:
  - low frequency: continental layout
  - mid frequency: tectonic modulation
  - high frequency: ridges/erosion micro-structure

## 3. Height-derived normal mapping on a sphere

Function:
- `surfaceNormalFromHeight(vec3 sphereN, float h0)`

Method:
1. Build a tangent basis `(t, b)` from normal `sphereN`.
2. Sample height on nearby points projected back to unit sphere.
3. Estimate derivatives `dh/dt` and `dh/db` by finite differences.
4. Bend the normal against gradient direction.

This is a procedural bump mapping approach without texture maps.

Article angle:
- Demonstrates how to do normal perturbation in object space for analytic geometry.

## 4. Physically inspired biome classification

Function:
- `biomeColor(vec3 p, float elevation, float latitude, float humidity)`

Inputs:
- Elevation from `planetHeight - seaLevel`
- Latitude from `abs(p.y)`
- Humidity from procedural FBM

Rules:
- Ocean depth controls shallow/deep water palette.
- Temperature proxy decreases with latitude and elevation.
- Aridity from inverse humidity.
- Terrain transitions: beach -> grass/forest/desert -> rock -> snow.

Article angle:
- Shows climate-driven color synthesis instead of purely threshold-based noise coloring.

## 5. Lighting model: wrapped diffuse + material-specific specular

Diffuse:
- Uses wrapped diffuse term: `(dot(N,L) + wrap) / (1 + wrap)`.
- Prevents harsh terminator while keeping directional shape.

Specular:
- Ocean gets strong, tight highlights and Fresnel boost.
- Land gets broad, weak highlight.

Benefits:
- Better readability across day/night boundary.
- Distinguishes water and terrain materials clearly.

## 6. Cloud layer and cloud-ground coupling

Function:
- `cloudCoverage(vec3 p)`

Construction:
- Animated cloud field from FBM + ridged noise.
- Wind advection via time offset in noise domain.

Coupling to surface shading:
- `cloudShadow` attenuates surface light on lit side.
- Cloud albedo is blended on top with lighting-dependent brightness.

Article angle:
- Clouds should affect the surface, not just be painted white on top.

## 7. Night-side city lights

City mask:
- Product of two high-frequency FBM signals.
- Gated by elevation so oceans/mountains emit less.

Activation:
- Driven by negative `dot(N,L)` (night side).
- Reduced under clouds.

Article angle:
- Emissive terms can encode human presence and improve terminator storytelling.

## 8. Atmospheric scattering approximation

Function:
- `atmosphereScatter(ro, rd, lightDir, tMax, planetRadius, atmRadius)`

Model:
- Atmosphere as spherical shell (radius `1.07`).
- Integrate one midpoint sample over ray segment in shell.
- Density falls exponentially with altitude: `exp(-h * k)`.
- Combine Rayleigh-like and Mie-like phase functions:
  - Rayleigh phase: proportional to `1 + mu^2`
  - Mie phase: Henyey-Greenstein (forward scattering)

Why this works:
- Cheap and stable for real-time rendering.
- Produces blue limb glow and sun-forward haze.

## 9. Space background and solar bloom

Functions/terms:
- `starfield(uv, bg)` for sparse stars + slow nebula variation
- Sun disk bloom from `pow(max(dot(rd, lightDir), 0), n)`

Purpose:
- Contextualizes lighting direction and makes the frame feel astronomical.

## 10. Color pipeline

Finalization:
- Adds atmosphere and sun glow after surface shading.
- Applies gamma correction: `pow(color, vec3(0.4545))` (approx linear->sRGB).

## 11. Suggested article structure

1. Why ray-sphere rendering beats 2D masking.
2. Multi-band procedural terrain design.
3. Spherical normal reconstruction from height gradients.
4. Climate-driven biome synthesis.
5. Water vs land material response.
6. Cloud lighting and shadow coupling.
7. Emissive night detail.
8. Cheap atmospheric scattering model.
9. Performance/quality knobs (octave count, shell thickness, bump strength).

## 12. Practical tuning knobs (in current shader)

- Planet spin speed: `spin = u_time * 0.13`
- Cloud wind speed: `u_time * 0.028`
- Sea level: `seaLevel = 0.04`
- Atmosphere radius: `atmosphereRadius = 1.07`
- Normal bump strength: `bumpStrength = 0.16`
- Scattering density falloff: `exp(-h * 12.0)`

These are good parameters to discuss in your article because each one maps to a visible, intuitive effect.
