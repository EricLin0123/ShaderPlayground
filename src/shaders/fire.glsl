float hash(vec2 p) {
  p = fract(p * vec2(123.4, 456.7));
  p += dot(p, p + 23.45);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);

  float a = hash(i + vec2(0.0, 0.0));
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  mat2 m = mat2(1.7, 1.2, -1.2, 1.7);
  for (int i = 0; i < 6; i++) {
    v += a * noise(p);
    p = m * p * 1.03;
    a *= 0.55;
  }
  return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution;
  vec2 p = vec2((fragCoord.x - 0.5 * u_resolution.x) / u_resolution.y, uv.y);

  vec2 flow = vec2(0.0, u_time * 1.6);
  float n1 = fbm(vec2(p.x * 5.0, p.y * 3.2) - flow);
  float n2 = fbm(vec2(p.x * 9.0, p.y * 6.0) - flow * 1.35);
  float shape = n1 * 0.75 + n2 * 0.35;

  float flame = smoothstep(0.12, 0.88, shape + (1.0 - uv.y) * 0.95 - abs(p.x) * 1.8);
  flame *= smoothstep(1.02, 0.0, uv.y);

  vec3 dark = vec3(0.02, 0.01, 0.01);
  vec3 red = vec3(0.86, 0.12, 0.02);
  vec3 orange = vec3(0.96, 0.44, 0.03);
  vec3 yellow = vec3(1.0, 0.82, 0.28);

  float heat = clamp(flame * (1.2 - uv.y), 0.0, 1.0);
  vec3 col = mix(dark, red, smoothstep(0.05, 0.35, heat));
  col = mix(col, orange, smoothstep(0.28, 0.68, heat));
  col = mix(col, yellow, smoothstep(0.62, 1.0, heat));
  col += vec3(1.0, 0.95, 0.7) * pow(max(heat - 0.72, 0.0), 4.0) * 2.2;

  float smoke = smoothstep(0.2, 1.0, fbm(vec2(p.x * 3.0, p.y * 2.2) - vec2(0.0, u_time * 0.4)) - uv.y * 0.9);
  vec3 bg = mix(vec3(0.02, 0.02, 0.03), vec3(0.10, 0.07, 0.06), smoke * 0.25);

  fragColor = vec4(mix(bg, col, flame), 1.0);
}
