float hash(vec2 p) {
  p = fract(p * vec2(213.12, 371.73));
  p += dot(p, p + 45.32);
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
  mat2 m = mat2(1.7, 1.1, -1.1, 1.7);
  for (int i = 0; i < 7; i++) {
    v += a * noise(p);
    p = m * p * 1.03;
    a *= 0.53;
  }
  return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution;
  vec2 p = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 skyBottom = vec3(0.45, 0.63, 0.86);
  vec3 skyTop = vec3(0.76, 0.88, 0.97);
  vec3 sky = mix(skyBottom, skyTop, smoothstep(0.0, 1.0, uv.y));

  vec2 wind = vec2(u_time * 0.07, u_time * 0.02);
  float base = fbm(p * 2.0 + wind);
  float detail = fbm(p * 5.0 + wind * 1.7);
  float density = base * 0.8 + detail * 0.35;
  float clouds = smoothstep(0.45, 0.78, density + uv.y * 0.12);

  float light = smoothstep(0.3, 1.0, fbm(p * 3.0 + vec2(0.0, u_time * 0.04)));
  vec3 cloudColor = mix(vec3(0.85, 0.87, 0.9), vec3(1.0), light);
  vec3 col = mix(sky, cloudColor, clouds);

  float sun = 1.0 - smoothstep(0.0, 0.22, length(uv - vec2(0.78, 0.82)));
  col += vec3(1.0, 0.8, 0.55) * sun * 0.35;

  fragColor = vec4(col, 1.0);
}
