import { Renderer } from './core/Renderer.js';
import { ShaderProgram } from './core/ShaderProgram.js';

const SHADER_LOADERS = {
  gradient: () => import('./shaders/gradient.glsl'),
  voronoi: () => import('./shaders/voronoi.glsl'),
  metaballs: () => import('./shaders/metaballs.glsl')
};

function getShaderName() {
  const params = new URLSearchParams(window.location.search);
  const shader = params.get('shader');

  if (shader && SHADER_LOADERS[shader]) {
    return shader;
  }

  return 'gradient';
}

async function bootstrap() {
  const shaderName = getShaderName();
  const module = await SHADER_LOADERS[shaderName]();
  const fragmentShaderSource = module.default;

  const renderer = new Renderer(fragmentShaderSource, ShaderProgram);
  renderer.start();
}

bootstrap().catch((error) => {
  console.error(error);
  document.body.innerHTML = '<pre style="color:#ff6b6b;padding:16px">Failed to initialize shader playground.</pre>';
});
