# 3D Rendering Concepts: One Shader Per Concept

This guide maps each learning concept to a dedicated shader in `src/shaders`.

Open any concept from the side menu, or by URL:

- `/?shader=concept-lights`
- `/?shader=concept-normal-maps`
- `/?shader=concept-bump-maps`
- `/?shader=concept-ray-marching`
- `/?shader=concept-env-spherical`
- `/?shader=concept-env-cube`
- `/?shader=concept-reflect-refract`
- `/?shader=concept-fresnel-shadows-ao`

All tunable uniforms in these shaders are exposed in the side menu as sliders or toggles.

## 1) Lights

Shader: `src/shaders/concept-lights.glsl`

Focus:

- ambient, diffuse, specular terms
- light position, color, and animation
- Blinn vs Phong-style specular toggle

Key controls:

- `Ambient`, `Diffuse`, `Specular`, `Shininess`
- `Light Height`, `Light Spin`, `Light Distance`
- `Light Color Mix`
- `Use Blinn Specular`, `Animate Light`

## 2) Normal Maps

Shader: `src/shaders/concept-normal-maps.glsl`

Focus:

- tangent-space normal perturbation
- blending geometric normal with map normal
- visual comparison via split mode

Key controls:

- `Normal Strength`, `Normal Scale`, `Normal Detail`
- `Animation Speed`
- `Light Height`, `Light Spin`
- `Specular`, `Shininess`
- `Enable Normal Map`, `Split View`

## 3) Bump Maps

Shader: `src/shaders/concept-bump-maps.glsl`

Focus:

- scalar height field
- finite-difference gradient to reconstruct normal
- difference between perceived depth and true geometry

Key controls:

- `Bump Strength`, `Height Scale`, `Animation Speed`
- `Gradient Epsilon`
- `Specular`, `Shininess`
- `Light Height`, `Light Spin`
- `Enable Bump Map`, `Show Height Field`

## 4) Ray Marching

Shader: `src/shaders/concept-ray-marching.glsl`

Focus:

- signed distance fields (SDF)
- marching step budget/epsilon/max distance tradeoff
- shading on SDF surfaces

Key controls:

- `Step Count`, `Surface Epsilon`, `Max Distance`
- `Shape Blend`, `Twist`
- `Light Intensity`
- `Shadow Strength`, `AO Strength`
- `Enable Shadows`, `Enable AO`, `Animate Shape`

## 5) Environment Mapping (Spherical)

Shader: `src/shaders/concept-env-spherical.glsl`

Focus:

- direction-to-latlong style environment lookup
- sky/horizon/sun procedural environment
- reflective material under spherical environment

Key controls:

- `Exposure`, `Reflectivity`, `Roughness`
- `Sun Strength`, `Horizon Warmth`
- `Env Spin`, `Object Scale`
- `Show Background`, `Animate`

## 6) Environment Mapping (Cube)

Shader: `src/shaders/concept-env-cube.glsl`

Focus:

- cube-map style face selection by dominant axis
- face tint and edge emphasis
- reflection under cube-style environment

Key controls:

- `Exposure`, `Reflectivity`, `Roughness`
- `Face Tint Mix`, `Edge Boost`
- `Env Spin`, `Object Scale`
- `Show Axis Colors`, `Animate`

## 7) Reflect and Refract

Shader: `src/shaders/concept-reflect-refract.glsl`

Focus:

- reflection vector (`reflect`)
- refraction vector (`refract`)
- IOR and absorption behavior
- Fresnel-weighted blending

Key controls:

- `Reflectivity`, `Refractivity`
- `IOR`, `Fresnel Power`, `Absorption`
- `Environment Mix`
- `Object Scale`, `Camera Spin`
- `Enable Reflection`, `Enable Refraction`, `Animate`

## 8) Relevant Extra Topic: Fresnel + Shadows + AO

Shader: `src/shaders/concept-fresnel-shadows-ao.glsl`

Focus:

- rim lighting via Fresnel term
- soft shadow approximation
- ambient occlusion approximation

Key controls:

- `Fresnel Power`, `Rim Strength`
- `Shadow Strength`, `AO Strength`
- `Step Count`, `Surface Epsilon`, `Max Distance`
- `Light Spin`
- `Enable Shadow`, `Enable AO`, `Animate`

## How to Study Efficiently

1. Start with `concept-lights`.
2. Compare `concept-normal-maps` vs `concept-bump-maps`.
3. Move to `concept-ray-marching` and vary step/epsilon aggressively.
4. Compare `concept-env-spherical` and `concept-env-cube` side-by-side.
5. Finish with `concept-reflect-refract` and then `concept-fresnel-shadows-ao`.

## Performance Notes

- Ray marching cost scales mostly with `Step Count`.
- Lower `Surface Epsilon` improves precision but can cause more marching work and artifacts.
- Enabling AO and shadows adds additional ray queries.
- Reflection/refraction are cheaper in these demos because environment maps are procedural.
