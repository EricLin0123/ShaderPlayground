export class Renderer {
  constructor(fragmentShaderSource, ShaderProgramClass) {
    this.canvas = document.createElement('canvas');
    this.gl = this.canvas.getContext('webgl2');

    if (!this.gl) {
      throw new Error('WebGL2 is not supported in this browser.');
    }

    this.mouse = { x: 0, y: 0 };
    this.startTime = performance.now();

    document.body.appendChild(this.canvas);

    this.program = new ShaderProgramClass(this.gl, fragmentShaderSource);
    this.program.use();

    this.#createFullscreenTriangle();
    this.#bindEvents();
    this.#resize();
  }

  start() {
    const frame = () => {
      this.#draw();
      requestAnimationFrame(frame);
    };

    requestAnimationFrame(frame);
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

  #bindEvents() {
    window.addEventListener('resize', () => this.#resize());

    window.addEventListener('pointermove', (event) => {
      const rect = this.canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = rect.height - (event.clientY - rect.top);
      this.mouse.x = x;
      this.mouse.y = y;
    });
  }

  #resize() {
    const dpr = window.devicePixelRatio || 1;
    const width = Math.floor(window.innerWidth * dpr);
    const height = Math.floor(window.innerHeight * dpr);

    if (this.canvas.width === width && this.canvas.height === height) {
      return;
    }

    this.canvas.width = width;
    this.canvas.height = height;
    this.canvas.style.width = `${window.innerWidth}px`;
    this.canvas.style.height = `${window.innerHeight}px`;

    this.gl.viewport(0, 0, width, height);
  }

  #draw() {
    const gl = this.gl;
    const now = performance.now();

    this.program.use();
    this.program.setUniform('resolution', this.canvas.width, this.canvas.height);
    this.program.setUniform('time', (now - this.startTime) * 0.001);
    this.program.setUniform('mouse', this.mouse.x, this.mouse.y);

    gl.bindVertexArray(this.vao);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.bindVertexArray(null);
  }
}
