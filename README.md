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
│     ├─ voronoi.glsl          # Voronoi effect (mouse-reactive)
│     └─ metaballs.glsl        # Animated metaballs
└─ public/                     # Static assets (if needed)
```

## How It Works

- `src/main.js` reads `?shader=<name>` from the URL.
- It dynamically imports the matching shader from `src/shaders`.
- `Renderer` creates a WebGL2 canvas and draws each frame.
- `ShaderProgram` wraps your fragment source with a shared header/footer and expects:
  - `void mainImage(out vec4 fragColor, in vec2 fragCoord);`
- Common uniforms available in every shader:
  - `u_resolution` (`vec2`) canvas pixel size
  - `u_time` (`float`) seconds since start
  - `u_mouse` (`vec2`) pointer position in pixels

## Run Locally

### Prerequisites

- Node.js 18+ (or Bun if you prefer Bun workflows)

### Install

```bash
npm install
```

### Start Dev Server

```bash
npm run dev
```

Then open the local URL shown by Vite (typically `http://localhost:5173`).

## Choose a Shader

Use the `shader` query param:

- `http://localhost:5173/?shader=gradient`
- `http://localhost:5173/?shader=voronoi`
- `http://localhost:5173/?shader=metaballs`

If the param is missing or invalid, it falls back to `gradient`.

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
2. Register it in `SHADER_LOADERS` inside `src/main.js`.
3. Run `npm run dev` and open `/?shader=<name>`.
