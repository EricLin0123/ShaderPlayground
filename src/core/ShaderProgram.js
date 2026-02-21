import { COMMON_UNIFORMS } from './uniforms.js';

const FULLSCREEN_TRIANGLE_VERTEX = `#version 300 es
layout(location = 0) in vec2 a_position;
void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}`;

const FRAGMENT_PREFIX = `#version 300 es
precision highp float;
uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
out vec4 outColor;
`;

const FRAGMENT_SUFFIX = `
void mainImage(out vec4 fragColor, in vec2 fragCoord);
void main() {
  mainImage(outColor, gl_FragCoord.xy);
}`;

export class ShaderProgram {
  constructor(gl, userFragmentShader) {
    this.gl = gl;
    const vertexShader = this.#compile(gl.VERTEX_SHADER, FULLSCREEN_TRIANGLE_VERTEX);
    const fragmentShader = this.#compile(gl.FRAGMENT_SHADER, this.#buildFragmentSource(userFragmentShader));

    this.program = gl.createProgram();
    gl.attachShader(this.program, vertexShader);
    gl.attachShader(this.program, fragmentShader);
    gl.linkProgram(this.program);

    if (!gl.getProgramParameter(this.program, gl.LINK_STATUS)) {
      const info = gl.getProgramInfoLog(this.program);
      gl.deleteProgram(this.program);
      gl.deleteShader(vertexShader);
      gl.deleteShader(fragmentShader);
      throw new Error(`Program link failed: ${info}`);
    }

    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    this.uniformLocations = {
      resolution: gl.getUniformLocation(this.program, COMMON_UNIFORMS.resolution),
      time: gl.getUniformLocation(this.program, COMMON_UNIFORMS.time),
      mouse: gl.getUniformLocation(this.program, COMMON_UNIFORMS.mouse)
    };
  }

  use() {
    this.gl.useProgram(this.program);
  }

  setUniform(name, ...values) {
    const gl = this.gl;
    const location = this.uniformLocations[name];

    if (location == null) {
      return;
    }

    if (values.length === 1) {
      gl.uniform1f(location, values[0]);
      return;
    }

    if (values.length === 2) {
      gl.uniform2f(location, values[0], values[1]);
      return;
    }

    throw new Error(`Unsupported uniform arity for ${name}`);
  }

  #buildFragmentSource(userSource) {
    return `${FRAGMENT_PREFIX}\n${userSource.trim()}\n${FRAGMENT_SUFFIX}`;
  }

  #compile(type, source) {
    const gl = this.gl;
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const info = gl.getShaderInfoLog(shader);
      gl.deleteShader(shader);
      throw new Error(`Shader compile failed: ${info}`);
    }

    return shader;
  }
}
