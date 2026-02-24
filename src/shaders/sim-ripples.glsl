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
  float hl = decodeHeight(texture(u_prev_state, uv - vec2(texel.x, 0.0)).r);
  float hr = decodeHeight(texture(u_prev_state, uv + vec2(texel.x, 0.0)).r);
  float hd = decodeHeight(texture(u_prev_state, uv - vec2(0.0, texel.y)).r);
  float hu = decodeHeight(texture(u_prev_state, uv + vec2(0.0, texel.y)).r);

  vec2 grad = vec2(hr - hl, hu - hd);
  vec3 n = normalize(vec3(-grad.x * 13.0, 1.0, -grad.y * 13.0));

  float aspect = u_resolution.x / u_resolution.y;
  vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
  vec3 viewDir = normalize(vec3(p, 1.35));
  vec3 lightDir = normalize(vec3(0.35, 0.84, 0.42));

  vec3 reflDir = reflect(-viewDir, n);
  vec3 skyTop = vec3(0.52, 0.74, 0.92);
  vec3 skyHorizon = vec3(0.88, 0.95, 1.0);
  vec3 sky = mix(skyHorizon, skyTop, clamp(reflDir.y * 0.5 + 0.5, 0.0, 1.0));

  float facing = clamp(dot(n, viewDir), 0.0, 1.0);
  float fresnel = 0.02 + (1.0 - 0.02) * pow(1.0 - facing, 5.0);

  float waterDepth = clamp(0.55 - h * 0.85, 0.0, 1.0);
  vec3 shallow = vec3(0.09, 0.45, 0.62);
  vec3 deep = vec3(0.01, 0.15, 0.28);
  vec3 base = mix(shallow, deep, waterDepth);

  vec3 halfVec = normalize(lightDir + viewDir);
  float spec = pow(max(dot(n, halfVec), 0.0), 96.0);
  float sun = pow(max(dot(reflDir, lightDir), 0.0), 16.0);

  float lap = abs((hl + hr + hd + hu) - 4.0 * h);
  float foam = smoothstep(0.03, 0.14, lap);

  vec3 color = mix(base, sky, fresnel);
  color *= 0.72 + 0.28 * max(dot(n, lightDir), 0.0);
  color += vec3(1.0, 0.97, 0.9) * spec * 0.9;
  color += vec3(1.0, 0.95, 0.82) * sun * 0.22;
  color = mix(color, vec3(0.9, 0.96, 1.0), foam * 0.5);

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
