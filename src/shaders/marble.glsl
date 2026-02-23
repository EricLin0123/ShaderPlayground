float hash(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p + 19.19);
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
  mat2 m = mat2(1.8, 1.3, -1.3, 1.8);
  for (int i = 0; i < 6; i++) {
    v += a * noise(p);
    p = m * p * 1.02;
    a *= 0.52;
  }
  return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 p = fragCoord / u_resolution;
  p.x *= u_resolution.x / u_resolution.y;

  float n = fbm(p * 5.0 + vec2(0.0, u_time * 0.05));
  float veins = sin((p.x * 12.0 + n * 8.0 + fbm(p * 18.0) * 2.0));
  veins = 0.5 + 0.5 * veins;
  veins = smoothstep(0.2, 0.9, veins);

  vec3 base = vec3(0.90, 0.88, 0.84);
  vec3 dark = vec3(0.24, 0.22, 0.20);
  vec3 tint = vec3(0.72, 0.72, 0.76);

  vec3 col = mix(base, tint, fbm(p * 3.0) * 0.35);
  col = mix(dark, col, veins);

  float polish = pow(1.0 - abs(2.0 * p.y - 1.0), 3.0);
  col += vec3(1.0) * polish * 0.08;

  fragColor = vec4(col, 1.0);
}
