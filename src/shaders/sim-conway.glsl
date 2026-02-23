float hash12(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float aliveAt(vec2 uv) {
  return step(0.5, texture(u_prev_state, uv).r);
}

void mainSim(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 texel = 1.0 / u_resolution.xy;

  if (u_frame < 0.5) {
    float seed = step(0.82, hash12(floor(fragCoord)));
    fragColor = vec4(seed, seed, seed, 1.0);
    return;
  }

  float current = aliveAt(uv);
  float neighbors = 0.0;

  neighbors += aliveAt(uv + texel * vec2(-1.0, -1.0));
  neighbors += aliveAt(uv + texel * vec2( 0.0, -1.0));
  neighbors += aliveAt(uv + texel * vec2( 1.0, -1.0));
  neighbors += aliveAt(uv + texel * vec2(-1.0,  0.0));
  neighbors += aliveAt(uv + texel * vec2( 1.0,  0.0));
  neighbors += aliveAt(uv + texel * vec2(-1.0,  1.0));
  neighbors += aliveAt(uv + texel * vec2( 0.0,  1.0));
  neighbors += aliveAt(uv + texel * vec2( 1.0,  1.0));

  float next = 0.0;
  if (current > 0.5 && (neighbors == 2.0 || neighbors == 3.0)) {
    next = 1.0;
  }
  if (current < 0.5 && neighbors == 3.0) {
    next = 1.0;
  }

  vec2 mouseUv = u_mouse / u_resolution.xy;
  float mouseDist = distance(uv, mouseUv);
  if ((u_mouse.x > 1.0 || u_mouse.y > 1.0) && mouseDist < 0.025) {
    next = 1.0;
  }

  fragColor = vec4(next, next, next, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  float cell = texture(u_prev_state, uv).r;
  vec3 aliveColor = vec3(0.95, 0.98, 1.0);
  vec3 deadColor = vec3(0.07, 0.08, 0.1);
  vec3 color = mix(deadColor, aliveColor, step(0.5, cell));
  fragColor = vec4(color, 1.0);
}
