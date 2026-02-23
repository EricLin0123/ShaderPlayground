import { Renderer } from './core/Renderer.js';
import { ShaderProgram } from './core/ShaderProgram.js';
import { SimulationRenderer } from './core/SimulationRenderer.js';
import { SimulationShaderProgram } from './core/SimulationShaderProgram.js';

const SHADER_MODULES = import.meta.glob('./shaders/*.glsl');
const DEFAULT_RENDER_WIDTH = 500;
const DEFAULT_RENDER_HEIGHT = 500;

function toTitleCase(text) {
  return text
    .split('-')
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function getShaderIdFromPath(path) {
  return path
    .replace('./shaders/', '')
    .replace('.glsl', '');
}

function buildShaderList() {
  const shaders = Object.entries(SHADER_MODULES).map(([path, load]) => {
    const id = getShaderIdFromPath(path);
    const normalized = id
      .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
      .replace(/[_\s]+/g, '-')
      .toLowerCase();
    const label = toTitleCase(normalized);
    return { id, label, load };
  });

  shaders.sort((a, b) => a.label.localeCompare(b.label));

  const gradientIndex = shaders.findIndex((shader) => shader.id === 'gradient');
  if (gradientIndex > 0) {
    const [gradient] = shaders.splice(gradientIndex, 1);
    shaders.unshift(gradient);
  }

  return shaders;
}

const SHADERS = buildShaderList();
const SHADER_MAP = Object.fromEntries(SHADERS.map((shader) => [shader.id, shader]));

function getShaderName() {
  const params = new URLSearchParams(window.location.search);
  const shader = params.get('shader');

  if (shader && SHADER_MAP[shader]) {
    return shader;
  }

  return SHADERS[0].id;
}

function createShaderMenu(activeShaderId, options) {
  const { renderWidth, renderHeight, onRenderSizeChange, buildExtraControls } = options;

  const menu = document.createElement('aside');
  menu.className = 'shader-menu';

  const title = document.createElement('h1');
  title.className = 'shader-menu__title';
  title.textContent = 'Shader Playground';
  menu.appendChild(title);

  const subtitle = document.createElement('p');
  subtitle.className = 'shader-menu__subtitle';
  subtitle.textContent = `Current: ${SHADER_MAP[activeShaderId].label}`;
  menu.appendChild(subtitle);

  const resolutionForm = document.createElement('form');
  resolutionForm.className = 'shader-menu__resolution';

  const widthInput = document.createElement('input');
  widthInput.className = 'shader-menu__number';
  widthInput.type = 'number';
  widthInput.min = '1';
  widthInput.max = '8192';
  widthInput.step = '1';
  widthInput.value = String(renderWidth);
  widthInput.placeholder = 'Width';
  widthInput.setAttribute('aria-label', 'Render width in pixels');

  const heightInput = document.createElement('input');
  heightInput.className = 'shader-menu__number';
  heightInput.type = 'number';
  heightInput.min = '1';
  heightInput.max = '8192';
  heightInput.step = '1';
  heightInput.value = String(renderHeight);
  heightInput.placeholder = 'Height';
  heightInput.setAttribute('aria-label', 'Render height in pixels');

  const applyButton = document.createElement('button');
  applyButton.type = 'submit';
  applyButton.className = 'shader-menu__apply';
  applyButton.textContent = 'Apply';

  resolutionForm.appendChild(widthInput);
  resolutionForm.appendChild(heightInput);
  resolutionForm.appendChild(applyButton);

  const resolutionHint = document.createElement('p');
  resolutionHint.className = 'shader-menu__hint';
  resolutionHint.textContent = 'Render size (px). Default: 500 x 500.';

  resolutionForm.addEventListener('submit', (event) => {
    event.preventDefault();

    const nextWidth = Number(widthInput.value);
    const nextHeight = Number(heightInput.value);
    const appliedSize = onRenderSizeChange(nextWidth, nextHeight);

    widthInput.value = String(appliedSize.width);
    heightInput.value = String(appliedSize.height);
  });

  menu.appendChild(resolutionForm);
  menu.appendChild(resolutionHint);

  if (typeof buildExtraControls === 'function') {
    const extraControls = buildExtraControls();
    if (extraControls) {
      menu.appendChild(extraControls);
    }
  }

  const list = document.createElement('nav');
  list.className = 'shader-menu__list';

  for (const shader of SHADERS) {
    const link = document.createElement('a');
    link.className = 'shader-menu__item';
    if (shader.id === activeShaderId) {
      link.classList.add('is-active');
    }

    link.href = `/?shader=${shader.id}`;
    link.textContent = shader.label;
    list.appendChild(link);
  }

  menu.appendChild(list);
  document.body.appendChild(menu);
}

function createSliderControl({ label, min, max, step, value, onInput }) {
  const row = document.createElement('label');
  row.className = 'shader-menu__slider';

  const labelText = document.createElement('span');
  labelText.className = 'shader-menu__slider-label';
  labelText.textContent = label;

  const valueText = document.createElement('span');
  valueText.className = 'shader-menu__slider-value';
  valueText.textContent = Number(value).toFixed(4);

  const input = document.createElement('input');
  input.type = 'range';
  input.min = String(min);
  input.max = String(max);
  input.step = String(step);
  input.value = String(value);
  input.className = 'shader-menu__slider-input';

  input.addEventListener('input', () => {
    const next = Number(input.value);
    valueText.textContent = next.toFixed(4);
    onInput(next);
  });

  row.appendChild(labelText);
  row.appendChild(valueText);
  row.appendChild(input);
  return row;
}

function createToggleControl({ label, value, onInput }) {
  const row = document.createElement('label');
  row.className = 'shader-menu__toggle';

  const labelText = document.createElement('span');
  labelText.className = 'shader-menu__toggle-label';
  labelText.textContent = label;

  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = value > 0.5;
  input.className = 'shader-menu__toggle-input';

  input.addEventListener('change', () => {
    onInput(input.checked ? 1 : 0);
  });

  row.appendChild(labelText);
  row.appendChild(input);
  return row;
}

function createSchemaControls(renderer, config) {
  const params = { ...config.uniforms };

  const applyUniforms = () => {
    if (typeof renderer.setCustomUniforms === 'function') {
      renderer.setCustomUniforms({ ...params });
    }
  };

  applyUniforms();

  const section = document.createElement('section');
  section.className = 'shader-menu__controls';

  const title = document.createElement('p');
  title.className = 'shader-menu__controls-title';
  title.textContent = config.title;
  section.appendChild(title);

  for (const control of config.controls) {
    if (control.type === 'toggle') {
      section.appendChild(createToggleControl({
        label: control.label,
        value: params[control.uniform],
        onInput: (next) => {
          params[control.uniform] = next;
          applyUniforms();
        }
      }));
      continue;
    }

    section.appendChild(createSliderControl({
      label: control.label,
      min: control.min,
      max: control.max,
      step: control.step,
      value: params[control.uniform],
      onInput: (next) => {
        params[control.uniform] = next;
        applyUniforms();
      }
    }));
  }

  if (config.includeSimulationReset) {
    const resetButton = document.createElement('button');
    resetButton.type = 'button';
    resetButton.className = 'shader-menu__apply shader-menu__reset';
    resetButton.textContent = 'Reset Simulation';
    resetButton.addEventListener('click', () => {
      if (typeof renderer.resetSimulation === 'function') {
        renderer.resetSimulation();
      }
    });
    section.appendChild(resetButton);
  }

  return section;
}

const SHADER_CONTROL_SCHEMAS = {
  'sim-reaction-diffusion': {
    title: 'Gray-Scott Parameters',
    includeSimulationReset: true,
    uniforms: {
      u_rd_feed: 0.055,
      u_rd_kill: 0.062,
      u_rd_da: 1.0,
      u_rd_db: 0.5
    },
    controls: [
      { type: 'slider', label: 'Feed', uniform: 'u_rd_feed', min: 0.01, max: 0.09, step: 0.0005 },
      { type: 'slider', label: 'Kill', uniform: 'u_rd_kill', min: 0.02, max: 0.09, step: 0.0005 },
      { type: 'slider', label: 'Diffusion A', uniform: 'u_rd_da', min: 0.2, max: 1.4, step: 0.01 },
      { type: 'slider', label: 'Diffusion B', uniform: 'u_rd_db', min: 0.05, max: 0.9, step: 0.01 }
    ]
  },
  'concept-lights': {
    title: 'Lights',
    uniforms: {
      u_cl_ambient: 0.08,
      u_cl_diffuse: 1.0,
      u_cl_specular: 0.8,
      u_cl_shininess: 48.0,
      u_cl_light_height: 1.1,
      u_cl_light_spin: 0.7,
      u_cl_light_distance: 2.0,
      u_cl_light_color_mix: 0.5,
      u_cl_use_blinn: 1.0,
      u_cl_animate_light: 1.0
    },
    controls: [
      { type: 'slider', label: 'Ambient', uniform: 'u_cl_ambient', min: 0.0, max: 0.5, step: 0.01 },
      { type: 'slider', label: 'Diffuse', uniform: 'u_cl_diffuse', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Specular', uniform: 'u_cl_specular', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Shininess', uniform: 'u_cl_shininess', min: 2.0, max: 128.0, step: 1.0 },
      { type: 'slider', label: 'Light Height', uniform: 'u_cl_light_height', min: 0.1, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Light Spin', uniform: 'u_cl_light_spin', min: -3.0, max: 3.0, step: 0.01 },
      { type: 'slider', label: 'Light Distance', uniform: 'u_cl_light_distance', min: 0.5, max: 4.0, step: 0.01 },
      { type: 'slider', label: 'Light Color Mix', uniform: 'u_cl_light_color_mix', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'toggle', label: 'Use Blinn Specular', uniform: 'u_cl_use_blinn' },
      { type: 'toggle', label: 'Animate Light', uniform: 'u_cl_animate_light' }
    ]
  },
  'concept-normal-maps': {
    title: 'Normal Maps',
    uniforms: {
      u_nm_strength: 1.0,
      u_nm_scale: 8.0,
      u_nm_detail: 3.0,
      u_nm_speed: 0.5,
      u_nm_light_height: 1.2,
      u_nm_light_spin: 0.5,
      u_nm_specular: 0.9,
      u_nm_shininess: 72.0,
      u_nm_use_map: 1.0,
      u_nm_show_split: 0.0
    },
    controls: [
      { type: 'slider', label: 'Normal Strength', uniform: 'u_nm_strength', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Normal Scale', uniform: 'u_nm_scale', min: 1.0, max: 20.0, step: 0.1 },
      { type: 'slider', label: 'Normal Detail', uniform: 'u_nm_detail', min: 0.5, max: 10.0, step: 0.1 },
      { type: 'slider', label: 'Animation Speed', uniform: 'u_nm_speed', min: -2.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Light Height', uniform: 'u_nm_light_height', min: 0.1, max: 2.5, step: 0.01 },
      { type: 'slider', label: 'Light Spin', uniform: 'u_nm_light_spin', min: -3.0, max: 3.0, step: 0.01 },
      { type: 'slider', label: 'Specular', uniform: 'u_nm_specular', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Shininess', uniform: 'u_nm_shininess', min: 2.0, max: 128.0, step: 1.0 },
      { type: 'toggle', label: 'Enable Normal Map', uniform: 'u_nm_use_map' },
      { type: 'toggle', label: 'Split View', uniform: 'u_nm_show_split' }
    ]
  },
  'concept-bump-maps': {
    title: 'Bump Maps',
    uniforms: {
      u_bm_strength: 0.9,
      u_bm_scale: 9.0,
      u_bm_speed: 0.35,
      u_bm_epsilon: 0.0025,
      u_bm_specular: 0.8,
      u_bm_shininess: 56.0,
      u_bm_light_height: 1.0,
      u_bm_light_spin: 0.6,
      u_bm_use_bump: 1.0,
      u_bm_show_height: 0.0
    },
    controls: [
      { type: 'slider', label: 'Bump Strength', uniform: 'u_bm_strength', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Height Scale', uniform: 'u_bm_scale', min: 1.0, max: 20.0, step: 0.1 },
      { type: 'slider', label: 'Animation Speed', uniform: 'u_bm_speed', min: -2.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Gradient Epsilon', uniform: 'u_bm_epsilon', min: 0.0005, max: 0.01, step: 0.0001 },
      { type: 'slider', label: 'Specular', uniform: 'u_bm_specular', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Shininess', uniform: 'u_bm_shininess', min: 2.0, max: 128.0, step: 1.0 },
      { type: 'slider', label: 'Light Height', uniform: 'u_bm_light_height', min: 0.1, max: 2.5, step: 0.01 },
      { type: 'slider', label: 'Light Spin', uniform: 'u_bm_light_spin', min: -3.0, max: 3.0, step: 0.01 },
      { type: 'toggle', label: 'Enable Bump Map', uniform: 'u_bm_use_bump' },
      { type: 'toggle', label: 'Show Height Field', uniform: 'u_bm_show_height' }
    ]
  },
  'concept-ray-marching': {
    title: 'Ray Marching',
    uniforms: {
      u_rm_steps: 96.0,
      u_rm_eps: 0.0015,
      u_rm_max_dist: 30.0,
      u_rm_shape_blend: 0.4,
      u_rm_twist: 0.8,
      u_rm_light_intensity: 1.2,
      u_rm_shadow_strength: 0.8,
      u_rm_ao_strength: 0.7,
      u_rm_use_shadow: 1.0,
      u_rm_use_ao: 1.0,
      u_rm_animate: 1.0
    },
    controls: [
      { type: 'slider', label: 'Step Count', uniform: 'u_rm_steps', min: 8.0, max: 256.0, step: 1.0 },
      { type: 'slider', label: 'Surface Epsilon', uniform: 'u_rm_eps', min: 0.0005, max: 0.01, step: 0.0001 },
      { type: 'slider', label: 'Max Distance', uniform: 'u_rm_max_dist', min: 3.0, max: 80.0, step: 0.5 },
      { type: 'slider', label: 'Shape Blend', uniform: 'u_rm_shape_blend', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Twist', uniform: 'u_rm_twist', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Light Intensity', uniform: 'u_rm_light_intensity', min: 0.0, max: 3.0, step: 0.01 },
      { type: 'slider', label: 'Shadow Strength', uniform: 'u_rm_shadow_strength', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'AO Strength', uniform: 'u_rm_ao_strength', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'toggle', label: 'Enable Shadows', uniform: 'u_rm_use_shadow' },
      { type: 'toggle', label: 'Enable AO', uniform: 'u_rm_use_ao' },
      { type: 'toggle', label: 'Animate Shape', uniform: 'u_rm_animate' }
    ]
  },
  'concept-env-spherical': {
    title: 'Environment Map (Spherical)',
    uniforms: {
      u_es_exposure: 1.0,
      u_es_reflectivity: 0.85,
      u_es_roughness: 0.18,
      u_es_sun_strength: 1.5,
      u_es_horizon_warmth: 0.6,
      u_es_spin: 0.25,
      u_es_object_scale: 0.9,
      u_es_show_background: 1.0,
      u_es_animate: 1.0
    },
    controls: [
      { type: 'slider', label: 'Exposure', uniform: 'u_es_exposure', min: 0.2, max: 3.0, step: 0.01 },
      { type: 'slider', label: 'Reflectivity', uniform: 'u_es_reflectivity', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Roughness', uniform: 'u_es_roughness', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Sun Strength', uniform: 'u_es_sun_strength', min: 0.0, max: 4.0, step: 0.01 },
      { type: 'slider', label: 'Horizon Warmth', uniform: 'u_es_horizon_warmth', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Env Spin', uniform: 'u_es_spin', min: -2.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Object Scale', uniform: 'u_es_object_scale', min: 0.4, max: 1.5, step: 0.01 },
      { type: 'toggle', label: 'Show Background', uniform: 'u_es_show_background' },
      { type: 'toggle', label: 'Animate', uniform: 'u_es_animate' }
    ]
  },
  'concept-env-cube': {
    title: 'Environment Map (Cube)',
    uniforms: {
      u_ec_exposure: 1.0,
      u_ec_reflectivity: 0.9,
      u_ec_roughness: 0.22,
      u_ec_face_tint: 0.5,
      u_ec_edge_boost: 0.6,
      u_ec_spin: 0.35,
      u_ec_object_scale: 0.9,
      u_ec_show_axes: 0.0,
      u_ec_animate: 1.0
    },
    controls: [
      { type: 'slider', label: 'Exposure', uniform: 'u_ec_exposure', min: 0.2, max: 3.0, step: 0.01 },
      { type: 'slider', label: 'Reflectivity', uniform: 'u_ec_reflectivity', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Roughness', uniform: 'u_ec_roughness', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Face Tint Mix', uniform: 'u_ec_face_tint', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Edge Boost', uniform: 'u_ec_edge_boost', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Env Spin', uniform: 'u_ec_spin', min: -2.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Object Scale', uniform: 'u_ec_object_scale', min: 0.4, max: 1.5, step: 0.01 },
      { type: 'toggle', label: 'Show Axis Colors', uniform: 'u_ec_show_axes' },
      { type: 'toggle', label: 'Animate', uniform: 'u_ec_animate' }
    ]
  },
  'concept-reflect-refract': {
    title: 'Reflect + Refract',
    uniforms: {
      u_rr_reflectivity: 0.55,
      u_rr_refractivity: 0.55,
      u_rr_ior: 1.35,
      u_rr_fresnel_power: 5.0,
      u_rr_absorption: 3.0,
      u_rr_env_mix: 0.8,
      u_rr_object_scale: 0.9,
      u_rr_spin: 0.3,
      u_rr_enable_reflect: 1.0,
      u_rr_enable_refract: 1.0,
      u_rr_animate: 1.0
    },
    controls: [
      { type: 'slider', label: 'Reflectivity', uniform: 'u_rr_reflectivity', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Refractivity', uniform: 'u_rr_refractivity', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'IOR', uniform: 'u_rr_ior', min: 1.01, max: 2.2, step: 0.01 },
      { type: 'slider', label: 'Fresnel Power', uniform: 'u_rr_fresnel_power', min: 0.5, max: 8.0, step: 0.1 },
      { type: 'slider', label: 'Absorption', uniform: 'u_rr_absorption', min: 0.0, max: 8.0, step: 0.05 },
      { type: 'slider', label: 'Environment Mix', uniform: 'u_rr_env_mix', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Object Scale', uniform: 'u_rr_object_scale', min: 0.4, max: 1.5, step: 0.01 },
      { type: 'slider', label: 'Camera Spin', uniform: 'u_rr_spin', min: -2.0, max: 2.0, step: 0.01 },
      { type: 'toggle', label: 'Enable Reflection', uniform: 'u_rr_enable_reflect' },
      { type: 'toggle', label: 'Enable Refraction', uniform: 'u_rr_enable_refract' },
      { type: 'toggle', label: 'Animate', uniform: 'u_rr_animate' }
    ]
  },
  'concept-fresnel-shadows-ao': {
    title: 'Fresnel + Shadows + AO',
    uniforms: {
      u_fs_fresnel_power: 4.0,
      u_fs_rim_strength: 0.8,
      u_fs_shadow_strength: 0.85,
      u_fs_ao_strength: 0.75,
      u_fs_steps: 96.0,
      u_fs_eps: 0.0014,
      u_fs_max_dist: 26.0,
      u_fs_light_spin: 0.6,
      u_fs_enable_shadow: 1.0,
      u_fs_enable_ao: 1.0,
      u_fs_animate: 1.0
    },
    controls: [
      { type: 'slider', label: 'Fresnel Power', uniform: 'u_fs_fresnel_power', min: 0.5, max: 8.0, step: 0.1 },
      { type: 'slider', label: 'Rim Strength', uniform: 'u_fs_rim_strength', min: 0.0, max: 2.0, step: 0.01 },
      { type: 'slider', label: 'Shadow Strength', uniform: 'u_fs_shadow_strength', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'AO Strength', uniform: 'u_fs_ao_strength', min: 0.0, max: 1.0, step: 0.01 },
      { type: 'slider', label: 'Step Count', uniform: 'u_fs_steps', min: 8.0, max: 256.0, step: 1.0 },
      { type: 'slider', label: 'Surface Epsilon', uniform: 'u_fs_eps', min: 0.0005, max: 0.01, step: 0.0001 },
      { type: 'slider', label: 'Max Distance', uniform: 'u_fs_max_dist', min: 3.0, max: 60.0, step: 0.5 },
      { type: 'slider', label: 'Light Spin', uniform: 'u_fs_light_spin', min: -3.0, max: 3.0, step: 0.01 },
      { type: 'toggle', label: 'Enable Shadow', uniform: 'u_fs_enable_shadow' },
      { type: 'toggle', label: 'Enable AO', uniform: 'u_fs_enable_ao' },
      { type: 'toggle', label: 'Animate', uniform: 'u_fs_animate' }
    ]
  }
};

function buildExtraControlsForShader(shaderName, renderer) {
  const schema = SHADER_CONTROL_SCHEMAS[shaderName];
  if (!schema) {
    return null;
  }

  return () => createSchemaControls(renderer, schema);
}

async function bootstrap() {
  if (SHADERS.length === 0) {
    throw new Error('No shaders found in src/shaders.');
  }

  const shaderName = getShaderName();

  const module = await SHADER_MAP[shaderName].load();
  const fragmentShaderSource = module.default;
  const isSimulation = shaderName.startsWith('sim-');

  const RendererClass = isSimulation ? SimulationRenderer : Renderer;
  const ProgramClass = isSimulation ? SimulationShaderProgram : ShaderProgram;

  const renderer = new RendererClass(fragmentShaderSource, ProgramClass, {
    renderWidth: DEFAULT_RENDER_WIDTH,
    renderHeight: DEFAULT_RENDER_HEIGHT
  });

  createShaderMenu(shaderName, {
    renderWidth: DEFAULT_RENDER_WIDTH,
    renderHeight: DEFAULT_RENDER_HEIGHT,
    onRenderSizeChange: (width, height) => renderer.setRenderSize(width, height),
    buildExtraControls: buildExtraControlsForShader(shaderName, renderer)
  });

  renderer.start();
}

bootstrap().catch((error) => {
  console.error(error);
  document.body.innerHTML = '<pre style="color:#ff6b6b;padding:16px">Failed to initialize shader playground.</pre>';
});
