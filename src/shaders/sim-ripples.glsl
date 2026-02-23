float decodeHeight(float value) {
  return value * 2.0 - 1.0;
}

float encodeHeight(float value) {
  return value * 0.5 + 0.5;
}

void mainSim(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 texel = 1.0 / u_resolution.xy;

  vec4 prev = texture(u_prev_state, uv);
  float current = decodeHeight(prev.r);
  float previous = decodeHeight(prev.g);

  if (u_frame < 0.5) {
    float seed = sin(uv.x * 20.0) * sin(uv.y * 20.0) * 0.05;
    fragColor = vec4(encodeHeight(seed), encodeHeight(0.0), 0.5, 1.0);
    return;
  }

  float l = decodeHeight(texture(u_prev_state, uv - vec2(texel.x, 0.0)).r);
  float r = decodeHeight(texture(u_prev_state, uv + vec2(texel.x, 0.0)).r);
  float d = decodeHeight(texture(u_prev_state, uv - vec2(0.0, texel.y)).r);
  float u = decodeHeight(texture(u_prev_state, uv + vec2(0.0, texel.y)).r);

  float lap = l + r + d + u - 4.0 * current;
  float next = (2.0 * current - previous) + lap * 0.25;
  next *= 0.995;

  vec2 mouseUv = u_mouse / u_resolution.xy;
  float mouseDist = distance(uv, mouseUv);
  if (u_mouse.x > 1.0 || u_mouse.y > 1.0) {
    next += exp(-mouseDist * 90.0) * 0.4;
  }

  fragColor = vec4(encodeHeight(next), encodeHeight(current), encodeHeight(next - current), 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 texel = 1.0 / u_resolution.xy;

  float h = decodeHeight(texture(u_prev_state, uv).r);
  float hx = decodeHeight(texture(u_prev_state, uv + vec2(texel.x, 0.0)).r) - h;
  float hy = decodeHeight(texture(u_prev_state, uv + vec2(0.0, texel.y)).r) - h;

  vec2 offset = vec2(hx, hy) * 0.08;
  vec3 refracted = texture(u_texture, clamp(uv + offset, 0.0, 1.0)).rgb;

  vec3 deep = vec3(0.04, 0.24, 0.48);
  vec3 color = mix(deep, refracted, 0.75);
  color += vec3(0.3, 0.45, 0.6) * smoothstep(0.05, 0.4, abs(h));

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
