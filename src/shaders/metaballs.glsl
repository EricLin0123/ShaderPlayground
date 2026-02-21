float metaball(vec2 p, vec2 center, float radius) {
  float d = length(p - center);
  return (radius * radius) / max(d * d, 0.0001);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

  vec2 c1 = vec2(0.35 * sin(u_time * 0.9), 0.30 * cos(u_time * 1.1));
  vec2 c2 = vec2(0.40 * sin(u_time * 1.3 + 2.1), 0.35 * cos(u_time * 0.7 + 0.6));
  vec2 c3 = vec2(0.30 * sin(u_time * 1.7 + 4.2), 0.38 * cos(u_time * 1.4 + 2.9));

  float field = 0.0;
  field += metaball(uv, c1, 0.18);
  field += metaball(uv, c2, 0.20);
  field += metaball(uv, c3, 0.16);

  float edge = smoothstep(0.9, 1.1, field);
  float glow = smoothstep(0.3, 1.0, field);

  vec3 base = vec3(0.02, 0.03, 0.05);
  vec3 ink = vec3(0.15, 0.9, 0.75);
  vec3 color = mix(base, ink, edge) + glow * vec3(0.05, 0.15, 0.2);

  fragColor = vec4(color, 1.0);
}
