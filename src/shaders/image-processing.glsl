// Image processing playground:
// top-left: texture + color operations
// top-right: gaussian blur (3x3)
// bottom-left: sharpen (3x3)
// bottom-right: edge detect (3x3)

const float KERNEL_BLUR[9] = float[](
  1.0, 2.0, 1.0,
  2.0, 4.0, 2.0,
  1.0, 2.0, 1.0
);

const float KERNEL_SHARPEN[9] = float[](
   0.0, -1.0,  0.0,
  -1.0,  5.0, -1.0,
   0.0, -1.0,  0.0
);

const float KERNEL_EDGE[9] = float[](
  -1.0, -1.0, -1.0,
  -1.0,  8.0, -1.0,
  -1.0, -1.0, -1.0
);

vec3 sourceTexture(vec2 uv) {
  return texture(u_texture, clamp(uv, 0.0, 1.0)).rgb;
}

vec3 adjustColor(vec3 color, float brightness, float contrast, float saturation) {
  vec3 bright = color + brightness;
  vec3 cont = (bright - 0.5) * contrast + 0.5;
  float luma = dot(cont, vec3(0.299, 0.587, 0.114));
  return mix(vec3(luma), cont, saturation);
}

vec3 convolve3x3(vec2 uv, const float kernel[9], float divisor, float bias) {
  vec2 texel = 1.0 / u_resolution.xy;
  vec3 acc = vec3(0.0);
  int index = 0;

  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 offset = vec2(float(x), float(y)) * texel;
      acc += sourceTexture(uv + offset) * kernel[index];
      index++;
    }
  }

  return acc / divisor + bias;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy;
  vec3 base = sourceTexture(uv);
  vec3 color = base;

  bool left = uv.x < 0.5;
  bool top = uv.y > 0.5;

  if (left && top) {
    float brightness = 0.06 * sin(u_time);
    float contrast = 1.15;
    float saturation = 1.35;
    color = adjustColor(base, brightness, contrast, saturation);
  } else if (!left && top) {
    color = convolve3x3(uv, KERNEL_BLUR, 16.0, 0.0);
  } else if (left && !top) {
    color = convolve3x3(uv, KERNEL_SHARPEN, 1.0, 0.0);
  } else {
    color = abs(convolve3x3(uv, KERNEL_EDGE, 1.0, 0.5));
  }

  float border = step(0.497, abs(uv.x - 0.5)) * step(abs(uv.x - 0.5), 0.503)
               + step(0.497, abs(uv.y - 0.5)) * step(abs(uv.y - 0.5), 0.503);
  color = mix(color, vec3(0.98), clamp(border, 0.0, 1.0));

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
