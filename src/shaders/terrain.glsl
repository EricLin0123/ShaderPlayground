float hash(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
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
  float value = 0.0;
  float amp = 0.5;
  mat2 rot = mat2(1.6, 1.2, -1.2, 1.6);
  for (int i = 0; i < 6; i++) {
    value += amp * noise(p);
    p = rot * p * 1.05;
    amp *= 0.5;
  }
  return value;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution;
  vec2 p = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  float large = fbm(p * 1.4);
  float detail = fbm(p * 5.0 + vec2(0.0, u_time * 0.03));
  float h = large * 0.9 + detail * 0.25;
  float ridge = 1.0 - abs(2.0 * h - 1.0);
  h += ridge * 0.08;

  vec3 deep = vec3(0.05, 0.16, 0.30);
  vec3 shallow = vec3(0.12, 0.35, 0.55);
  vec3 grass = vec3(0.20, 0.50, 0.22);
  vec3 rock = vec3(0.42, 0.37, 0.31);
  vec3 snow = vec3(0.88, 0.90, 0.95);

  float waterLevel = 0.42;
  float grassLevel = 0.50;
  float rockLevel = 0.66;
  float snowLevel = 0.80;

  vec3 col = mix(deep, shallow, smoothstep(0.32, waterLevel, h));
  col = mix(col, grass, smoothstep(waterLevel, grassLevel, h));
  col = mix(col, rock, smoothstep(grassLevel, rockLevel, h));
  col = mix(col, snow, smoothstep(rockLevel, snowLevel, h));

  vec2 e = vec2(2.0 / u_resolution.y, 0.0);
  float hx = fbm((p + e.xy) * 1.4) * 0.9 + fbm((p + e.xy) * 5.0 + vec2(0.0, u_time * 0.03)) * 0.25;
  float hy = fbm((p + e.yx) * 1.4) * 0.9 + fbm((p + e.yx) * 5.0 + vec2(0.0, u_time * 0.03)) * 0.25;
  vec3 n = normalize(vec3(h - hx, 0.06, h - hy));
  vec3 l = normalize(vec3(0.6, 0.9, 0.5));
  float diff = clamp(dot(n, l), 0.0, 1.0);

  col *= 0.45 + 0.75 * diff;

  float fog = smoothstep(0.2, 1.2, length(uv - 0.5) * 1.4);
  col = mix(col, vec3(0.75, 0.82, 0.9), fog * 0.2);

  fragColor = vec4(col, 1.0);
}
