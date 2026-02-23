float hash12(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void mainSim(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec3 prev = texture(u_prev_state, uv).rgb;
  vec3 inputTex = texture(u_texture, uv + 0.02 * vec2(sin(u_time * 0.4), cos(u_time * 0.33))).rgb;

  float seed = hash12(floor(fragCoord));
  if (u_frame < 0.5) {
    fragColor = vec4(mix(inputTex, vec3(seed), 0.15), 1.0);
    return;
  }

  vec2 mouseUv = u_mouse / u_resolution.xy;
  float mouseDist = distance(uv, mouseUv);
  float splat = exp(-mouseDist * 55.0);

  vec3 next = prev * 0.985 + inputTex * 0.02;
  next += vec3(1.0, 0.4, 0.1) * splat * 0.25;

  fragColor = vec4(clamp(next, 0.0, 1.0), 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec3 state = texture(u_prev_state, uv).rgb;

  vec3 color = vec3(
    smoothstep(0.1, 0.9, state.r),
    smoothstep(0.05, 0.8, state.g),
    smoothstep(0.0, 0.7, state.b)
  );

  fragColor = vec4(color, 1.0);
}
