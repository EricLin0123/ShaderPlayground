uniform float u_rd_feed;
uniform float u_rd_kill;
uniform float u_rd_da;
uniform float u_rd_db;

vec2 chemicalsAt(vec2 uv) {
  return texture(u_prev_state, uv).rg;
}

void mainSim(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 texel = 1.0 / u_resolution.xy;

  vec2 c = chemicalsAt(uv);
  float a = c.r;
  float b = c.g;

  if (u_frame < 0.5) {
    vec2 center = uv - 0.5;
    float radius = length(center);
    float seedB = 1.0 - smoothstep(0.05, 0.14, radius);
    fragColor = vec4(1.0 - 0.6 * seedB, seedB, 0.0, 1.0);
    return;
  }

  vec2 n = chemicalsAt(uv + vec2(0.0, texel.y));
  vec2 s = chemicalsAt(uv - vec2(0.0, texel.y));
  vec2 e = chemicalsAt(uv + vec2(texel.x, 0.0));
  vec2 w = chemicalsAt(uv - vec2(texel.x, 0.0));
  vec2 ne = chemicalsAt(uv + vec2(texel.x, texel.y));
  vec2 nw = chemicalsAt(uv + vec2(-texel.x, texel.y));
  vec2 se = chemicalsAt(uv + vec2(texel.x, -texel.y));
  vec2 sw = chemicalsAt(uv + vec2(-texel.x, -texel.y));

  float lapA = n.r + s.r + e.r + w.r + 0.5 * (ne.r + nw.r + se.r + sw.r) - 6.0 * a;
  float lapB = n.g + s.g + e.g + w.g + 0.5 * (ne.g + nw.g + se.g + sw.g) - 6.0 * b;

  float reaction = a * b * b;
  float nextA = a + (u_rd_da * lapA - reaction + u_rd_feed * (1.0 - a));
  float nextB = b + (u_rd_db * lapB + reaction - (u_rd_kill + u_rd_feed) * b);

  vec2 mouseUv = u_mouse / u_resolution.xy;
  float mouseDist = distance(uv, mouseUv);
  if ((u_mouse.x > 1.0 || u_mouse.y > 1.0) && mouseDist < 0.045) {
    float brush = exp(-mouseDist * 70.0);
    nextB = clamp(nextB + brush * 0.6, 0.0, 1.0);
    nextA = clamp(nextA - brush * 0.3, 0.0, 1.0);
  }

  fragColor = vec4(clamp(nextA, 0.0, 1.0), clamp(nextB, 0.0, 1.0), 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 ab = chemicalsAt(uv);
  float pattern = clamp(ab.r - ab.g, 0.0, 1.0);

  vec3 c0 = vec3(0.04, 0.07, 0.15);
  vec3 c1 = vec3(0.2, 0.52, 0.78);
  vec3 c2 = vec3(0.95, 0.87, 0.48);

  vec3 color = mix(c0, c1, smoothstep(0.1, 0.65, pattern));
  color = mix(color, c2, smoothstep(0.55, 0.95, pattern));
  fragColor = vec4(color, 1.0);
}
