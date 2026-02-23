# Shader Playground

Minimal WebGL2 shader playground built with Vite. It renders a full-screen triangle and loads fragment shaders from `src/shaders`.

## Tech Stack

- JavaScript (ES modules)
- WebGL2
- Vite
- `vite-plugin-glsl` (imports `.glsl` files as strings)

## Project Structure

```text
ShaderPlayground/
├─ index.html                  # App shell and base page styles
├─ vite.config.js              # Vite config + GLSL plugin
├─ package.json                # Scripts: dev/build/preview
├─ src/
│  ├─ main.js                  # Entry point, shader selection, app bootstrap
│  ├─ core/
│  │  ├─ Renderer.js           # Canvas/WebGL setup, resize, render loop, input
│  │  ├─ ShaderProgram.js      # Shader compile/link + uniform helpers
│  │  └─ uniforms.js           # Shared uniform names
│  └─ shaders/
│     ├─ gradient.glsl         # Default shader
│     ├─ concept-lights.glsl
│     ├─ concept-normal-maps.glsl
│     ├─ concept-bump-maps.glsl
│     ├─ concept-ray-marching.glsl
│     ├─ concept-env-spherical.glsl
│     ├─ concept-env-cube.glsl
│     ├─ concept-reflect-refract.glsl
│     ├─ concept-fresnel-shadows-ao.glsl
│     ├─ image-processing.glsl
│     ├─ voronoi.glsl
│     ├─ metaballs.glsl
│     ├─ terrain.glsl
│     ├─ clouds.glsl
│     ├─ marble.glsl
│     ├─ water.glsl
│     ├─ planet.glsl
│     └─ fire.glsl
├─ docs/
│  ├─ image-processing.md
│  └─ rendering-concepts.md    # Per-concept rendering guide
└─ public/
```

## Concept Learning Pack

Use these dedicated shaders (one concept per shader):

- `/?shader=concept-lights`
- `/?shader=concept-normal-maps`
- `/?shader=concept-bump-maps`
- `/?shader=concept-ray-marching`
- `/?shader=concept-env-spherical`
- `/?shader=concept-env-cube`
- `/?shader=concept-reflect-refract`
- `/?shader=concept-fresnel-shadows-ao`

Detailed notes: `docs/rendering-concepts.md`.

## Run Locally

### Prerequisites

- Node.js 18+ (or Bun)

### Install

```bash
npm install
```

### Start Dev Server

```bash
npm run dev
```

Then open the local URL shown by Vite (typically `http://localhost:5173`).

## Production Build

```bash
npm run build
```

Preview production output locally:

```bash
npm run preview
```

## Add a New Shader

1. Create `src/shaders/<name>.glsl` implementing `mainImage(...)`.
2. Add slider/toggle schema in `src/main.js` if custom uniforms are used.
3. Run `npm run dev` and open `/?shader=<name>`.
