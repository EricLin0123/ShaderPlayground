float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 random2(vec2 p) {
  return vec2(hash(p), hash(p + 19.19));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution;
  vec2 st = uv * 8.0;

  vec2 i = floor(st);
  vec2 f = fract(st);

  float minDist = 10.0;

  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 neighbor = vec2(float(x), float(y));
      vec2 point = random2(i + neighbor);

      vec2 mouseUv = u_mouse / u_resolution;
      point = 0.5 + 0.45 * sin(u_time + 6.2831 * point);
      point = mix(point, mouseUv, 0.25);

      vec2 diff = neighbor + point - f;
      float dist = length(diff);
      minDist = min(minDist, dist);
    }
  }

  float cells = smoothstep(0.0, 0.65, minDist);
  float edges = smoothstep(0.08, 0.1, minDist);

  vec3 cellColor = mix(vec3(0.1, 0.15, 0.28), vec3(0.7, 0.86, 1.0), cells);
  vec3 edgeColor = vec3(0.98, 0.99, 1.0);
  vec3 color = mix(edgeColor, cellColor, edges);

  fragColor = vec4(color, 1.0);
}
