float hash(vec3 p) {
  p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
  p *= 17.0;
  return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  vec3 u = f * f * (3.0 - 2.0 * f);

  float n000 = hash(i + vec3(0.0, 0.0, 0.0));
  float n100 = hash(i + vec3(1.0, 0.0, 0.0));
  float n010 = hash(i + vec3(0.0, 1.0, 0.0));
  float n110 = hash(i + vec3(1.0, 1.0, 0.0));
  float n001 = hash(i + vec3(0.0, 0.0, 1.0));
  float n101 = hash(i + vec3(1.0, 0.0, 1.0));
  float n011 = hash(i + vec3(0.0, 1.0, 1.0));
  float n111 = hash(i + vec3(1.0, 1.0, 1.0));

  float nx00 = mix(n000, n100, u.x);
  float nx10 = mix(n010, n110, u.x);
  float nx01 = mix(n001, n101, u.x);
  float nx11 = mix(n011, n111, u.x);
  float nxy0 = mix(nx00, nx10, u.y);
  float nxy1 = mix(nx01, nx11, u.y);
  return mix(nxy0, nxy1, u.z);
}

float fbm3(vec3 p) {
  float v = 0.0;
  float a = 0.5;
  mat3 m = mat3(
    1.6, 1.1, 0.4,
    -1.1, 1.6, -0.3,
    -0.4, 0.3, 1.8
  );
  for (int i = 0; i < 6; i++) {
    v += a * noise3(p);
    p = m * p * 1.03;
    a *= 0.52;
  }
  return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;
  float r = length(uv);

  vec3 bg = mix(vec3(0.01, 0.02, 0.05), vec3(0.03, 0.06, 0.12), smoothstep(0.0, 1.0, uv.y + 0.4));

  if (r > 0.42) {
    float stars = step(0.9985, fract(sin(dot(floor(fragCoord * 0.4), vec2(12.9898, 78.233))) * 43758.5453));
    fragColor = vec4(bg + stars * vec3(1.0), 1.0);
    return;
  }

  vec3 n = normalize(vec3(uv, sqrt(max(0.0, 0.42 * 0.42 - r * r))));
  float spin = u_time * 0.18;
  vec3 samplePos = vec3(
    n.x * cos(spin) - n.z * sin(spin),
    n.y,
    n.x * sin(spin) + n.z * cos(spin)
  ) * 3.8;

  float h = fbm3(samplePos);
  float mtn = pow(max(0.0, h - 0.45), 1.6);

  vec3 ocean = vec3(0.06, 0.24, 0.55);
  vec3 land = vec3(0.16, 0.52, 0.21);
  vec3 desert = vec3(0.62, 0.56, 0.33);
  vec3 snow = vec3(0.94, 0.96, 1.0);

  vec3 col = mix(ocean, land, smoothstep(0.40, 0.52, h));
  col = mix(col, desert, smoothstep(0.58, 0.70, h));
  col = mix(col, snow, smoothstep(0.72, 0.86, h + mtn * 0.3));

  vec3 lightDir = normalize(vec3(-0.7, 0.45, 0.55));
  float diff = max(dot(n, lightDir), 0.0);
  float rim = pow(1.0 - max(dot(n, vec3(0.0, 0.0, 1.0)), 0.0), 2.5);
  col *= 0.25 + diff * 1.0;
  col += vec3(0.2, 0.5, 0.9) * rim * 0.4;

  col = mix(bg, col, smoothstep(0.43, 0.40, r));
  fragColor = vec4(col, 1.0);
}
