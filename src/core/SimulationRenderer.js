export class SimulationRenderer {
  constructor(fragmentShaderSource, ShaderProgramClass, options = {}) {
    this.canvas = document.createElement('canvas');
    this.gl = this.canvas.getContext('webgl2');

    if (!this.gl) {
      throw new Error('WebGL2 is not supported in this browser.');
    }

    this.mouse = { x: 0, y: 0 };
    this.startTime = performance.now();
    this.frame = 0;
    this.pingPong = { read: 0, write: 1 };
    this.customUniforms = {};

    this.renderWidth = this.#normalizeSize(options.renderWidth, 500);
    this.renderHeight = this.#normalizeSize(options.renderHeight, 500);

    document.body.appendChild(this.canvas);

    this.program = new ShaderProgramClass(this.gl, fragmentShaderSource);
    this.program.use();
    this.texture = this.#createDemoTexture();

    this.#createFullscreenTriangle();
    this.#createPingPongTargets();
    this.#bindEvents();
    this.setRenderSize(this.renderWidth, this.renderHeight);

    this.program.setTextureUnit('texture', 0);
    this.program.setTextureUnit('prevState', 1);
  }

  start() {
    const frame = () => {
      this.#draw();
      requestAnimationFrame(frame);
    };

    requestAnimationFrame(frame);
  }

  setRenderSize(width, height) {
    const nextWidth = this.#normalizeSize(width, this.renderWidth);
    const nextHeight = this.#normalizeSize(height, this.renderHeight);

    if (this.canvas.width === nextWidth && this.canvas.height === nextHeight) {
      return { width: this.renderWidth, height: this.renderHeight };
    }

    this.renderWidth = nextWidth;
    this.renderHeight = nextHeight;

    this.canvas.width = nextWidth;
    this.canvas.height = nextHeight;
    this.canvas.style.width = `${nextWidth}px`;
    this.canvas.style.height = `${nextHeight}px`;

    this.#resizePingPongTargets(nextWidth, nextHeight);
    this.frame = 0;
    this.gl.viewport(0, 0, nextWidth, nextHeight);
    return { width: this.renderWidth, height: this.renderHeight };
  }

  setCustomUniforms(nextUniforms) {
    this.customUniforms = { ...nextUniforms };
  }

  resetSimulation() {
    this.#resizePingPongTargets(this.canvas.width, this.canvas.height);
    this.frame = 0;
  }

  #normalizeSize(value, fallback) {
    const numeric = Number(value);

    if (!Number.isFinite(numeric)) {
      return fallback;
    }

    return Math.min(8192, Math.max(1, Math.floor(numeric)));
  }

  #createFullscreenTriangle() {
    const gl = this.gl;
    const vertices = new Float32Array([
      -1, -1,
      3, -1,
      -1, 3
    ]);

    this.vao = gl.createVertexArray();
    this.vbo = gl.createBuffer();

    gl.bindVertexArray(this.vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, this.vbo);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);

    gl.bindVertexArray(null);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);
  }

  #createPingPongTargets() {
    this.stateTextures = [this.#createStateTexture(), this.#createStateTexture()];
    this.framebuffers = [this.#createFramebuffer(this.stateTextures[0]), this.#createFramebuffer(this.stateTextures[1])];
    this.pingPong = { read: 0, write: 1 };
  }

  #resizePingPongTargets(width, height) {
    const gl = this.gl;
    for (let i = 0; i < 2; i += 1) {
      gl.bindTexture(gl.TEXTURE_2D, this.stateTextures[i]);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffers[i]);
      gl.clearColor(0, 0, 0, 1);
      gl.clear(gl.COLOR_BUFFER_BIT);
    }

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindTexture(gl.TEXTURE_2D, null);
    this.pingPong = { read: 0, write: 1 };
  }

  #createStateTexture() {
    const gl = this.gl;
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.renderWidth, this.renderHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.bindTexture(gl.TEXTURE_2D, null);
    return texture;
  }

  #createFramebuffer(texture) {
    const gl = this.gl;
    const framebuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);

    if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) {
      throw new Error('Simulation framebuffer is incomplete.');
    }

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    return framebuffer;
  }

  #bindEvents() {
    window.addEventListener('pointermove', (event) => {
      const rect = this.canvas.getBoundingClientRect();
      const x = (event.clientX - rect.left) * (this.canvas.width / rect.width);
      const y = (rect.bottom - event.clientY) * (this.canvas.height / rect.height);
      this.mouse.x = x;
      this.mouse.y = y;
    });
  }

  #createDemoTexture() {
    const gl = this.gl;
    const size = 256;
    const data = new Uint8Array(size * size * 4);

    for (let y = 0; y < size; y += 1) {
      for (let x = 0; x < size; x += 1) {
        const index = (y * size + x) * 4;
        const fx = x / (size - 1);
        const fy = y / (size - 1);
        const checker = ((x >> 4) + (y >> 4)) & 1;
        const ring = Math.sin(Math.hypot(x - size * 0.5, y - size * 0.5) * 0.24);

        const r = Math.floor(255 * (0.2 + 0.8 * fx));
        const g = Math.floor(255 * (0.2 + 0.8 * fy));
        const b = Math.floor(255 * (0.3 + 0.35 * checker + 0.35 * (0.5 + 0.5 * ring)));

        data[index] = r;
        data[index + 1] = g;
        data[index + 2] = b;
        data[index + 3] = 255;
      }
    }

    const texture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, size, size, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.bindTexture(gl.TEXTURE_2D, null);

    return texture;
  }

  #draw() {
    const gl = this.gl;
    const now = performance.now();
    const time = (now - this.startTime) * 0.001;

    this.program.use();
    this.program.setUniform('resolution', this.canvas.width, this.canvas.height);
    this.program.setUniform('time', time);
    this.program.setUniform('mouse', this.mouse.x, this.mouse.y);
    this.program.setUniform('frame', this.frame);
    for (const [name, value] of Object.entries(this.customUniforms)) {
      this.program.setUniform(name, value);
    }

    gl.bindVertexArray(this.vao);

    // Simulation pass: prev state -> next state framebuffer.
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this.texture);
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, this.stateTextures[this.pingPong.read]);

    this.program.setUniform('pass', 0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffers[this.pingPong.write]);
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    gl.drawArrays(gl.TRIANGLES, 0, 3);

    // Display pass: latest state -> screen.
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, this.stateTextures[this.pingPong.write]);
    this.program.setUniform('pass', 1);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.bindVertexArray(null);

    const nextRead = this.pingPong.write;
    const nextWrite = this.pingPong.read;
    this.pingPong.read = nextRead;
    this.pingPong.write = nextWrite;
    this.frame += 1;
  }
}
