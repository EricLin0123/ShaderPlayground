float hash(vec2 p) {
  p = fract(p * vec2(103.1, 313.7));
  p += dot(p, p + 33.33);
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
  mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
  for (int i = 0; i < 6; i++) {
    v += a * noise(p);
    p = m * p * 1.08;
    a *= 0.54;
  }
  return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution;
  vec2 p = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec2 flow = vec2(u_time * 0.25, -u_time * 0.18);
  float wavesA = fbm(p * 8.0 + flow);
  float wavesB = fbm(p * 15.0 - flow * 1.4);
  float h = wavesA * 0.7 + wavesB * 0.35;

  vec2 e = vec2(2.0 / u_resolution.y, 0.0);
  float hx = fbm((p + e.xy) * 8.0 + flow) * 0.7 + fbm((p + e.xy) * 15.0 - flow * 1.4) * 0.35;
  float hy = fbm((p + e.yx) * 8.0 + flow) * 0.7 + fbm((p + e.yx) * 15.0 - flow * 1.4) * 0.35;

  vec3 n = normalize(vec3(h - hx, 0.08, h - hy));
  vec3 lightDir = normalize(vec3(0.3, 0.95, 0.2));
  float diff = max(dot(n, lightDir), 0.0);
  float spec = pow(max(dot(reflect(-lightDir, n), vec3(0.0, 1.0, 0.0)), 0.0), 35.0);

  vec3 deep = vec3(0.02, 0.15, 0.30);
  vec3 shallow = vec3(0.04, 0.43, 0.62);
  vec3 col = mix(deep, shallow, uv.y + h * 0.25);
  col *= 0.45 + diff * 0.8;
  col += vec3(0.9, 0.95, 1.0) * spec * 0.9;

  fragColor = vec4(col, 1.0);
}
