float hash12(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec4 stateAt(vec2 uv) {
  return texture(u_prev_state, uv);
}

void mainSim(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 texel = 1.0 / u_resolution.xy;

  vec4 prev = stateAt(uv);

  if (u_frame < 0.5) {
    vec3 base = texture(u_texture, uv).rgb;
    fragColor = vec4(base * 0.5, 0.8);
    return;
  }

  vec4 sL = stateAt(uv - vec2(texel.x, 0.0));
  vec4 sR = stateAt(uv + vec2(texel.x, 0.0));
  vec4 sD = stateAt(uv - vec2(0.0, texel.y));
  vec4 sU = stateAt(uv + vec2(0.0, texel.y));

  vec3 avgPigment = (sL.rgb + sR.rgb + sD.rgb + sU.rgb + prev.rgb) / 5.0;
  float avgWater = (sL.a + sR.a + sD.a + sU.a + prev.a) / 5.0;

  vec2 flow = vec2(
    hash12(uv * 130.0 + u_time * 0.15) - 0.5,
    hash12(uv.yx * 130.0 - u_time * 0.13) - 0.5
  ) * 0.8 * texel;

  vec3 advected = stateAt(uv - flow).rgb;
  vec3 pigment = mix(prev.rgb, advected, 0.45 * prev.a);
  pigment = mix(pigment, avgPigment, 0.18 * avgWater);

  float drying = 0.0018;
  float water = clamp(mix(prev.a, avgWater, 0.2) - drying, 0.0, 1.0);

  vec2 mouseUv = u_mouse / u_resolution.xy;
  float mouseDist = distance(uv, mouseUv);
  if ((u_mouse.x > 1.0 || u_mouse.y > 1.0) && mouseDist < 0.08) {
    float brush = exp(-mouseDist * 45.0);
    vec3 brushColor = texture(u_texture, uv + flow * 12.0).rgb;
    pigment = mix(pigment, brushColor, brush * 0.45);
    water = clamp(water + brush * 0.25, 0.0, 1.0);
  }

  fragColor = vec4(clamp(pigment, 0.0, 1.0), water);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec2 texel = 1.0 / u_resolution.xy;
  vec4 s = stateAt(uv);
  vec3 color = s.rgb;

  // Approximate pigment edge darkening on drying paper.
  vec3 neighborhood = (
    stateAt(uv + vec2(texel.x, 0.0)).rgb +
    stateAt(uv - vec2(texel.x, 0.0)).rgb +
    stateAt(uv + vec2(0.0, texel.y)).rgb +
    stateAt(uv - vec2(0.0, texel.y)).rgb
  ) * 0.25;
  float edge = length(color - neighborhood);
  color += edge * (1.0 - s.a) * vec3(0.18, 0.12, 0.08);

  float paper = hash12(floor(fragCoord * 0.5)) * 0.06;
  color = color * (0.9 + 0.1 * s.a) + paper;

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
