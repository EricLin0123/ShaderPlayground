# GLSL Image Processing: Textures, Image Operations, Kernel Convolutions, Filters

This project includes a runnable shader example at:

- `src/shaders/image-processing.glsl`

Run with:

```bash
npm run dev
```

Then open:

- `http://localhost:5173/?shader=image-processing`

## 1. Textures

A texture is an image stored on the GPU. In this playground, the renderer binds a demo texture to `u_texture`.

Core sampling pattern:

```glsl
vec2 uv = fragCoord / u_resolution.xy;
vec3 color = texture(u_texture, uv).rgb;
```

- `uv` should be normalized in `[0, 1]`.
- `texture(...)` fetches interpolated color at that coordinate.

## 2. Image Operations

Image operations change each pixel independently (no neighborhood needed).  
In `image-processing.glsl`, the top-left panel applies brightness, contrast, and saturation:

```glsl
vec3 bright = color + brightness;
vec3 cont = (bright - 0.5) * contrast + 0.5;
float luma = dot(cont, vec3(0.299, 0.587, 0.114));
vec3 result = mix(vec3(luma), cont, saturation);
```

These are point operations:

- Brightness: shift pixel values
- Contrast: scale around mid-gray (`0.5`)
- Saturation: mix between grayscale and original color

## 3. Kernel Convolutions

Convolution uses neighboring texels to compute a new pixel value.

General 3x3 form:

```text
output(x, y) = sum(kernel[i, j] * input(x + i, y + j))
```

Shader implementation (simplified):

```glsl
vec2 texel = 1.0 / u_resolution.xy;
for (int y = -1; y <= 1; y++) {
  for (int x = -1; x <= 1; x++) {
    vec2 offset = vec2(float(x), float(y)) * texel;
    acc += texture(u_texture, uv + offset).rgb * kernel[index];
  }
}
```

- `texel` converts from pixel offsets to UV offsets.
- Divide by kernel sum (for blur, sum is often `16`, `9`, or `1` depending on the kernel).

## 4. Filters (Examples in the Shader)

The shader shows four panels:

1. Top-left: color operations (brightness/contrast/saturation)
2. Top-right: Gaussian blur
3. Bottom-left: Sharpen
4. Bottom-right: Edge detect

Kernels used:

Gaussian blur:

```text
1 2 1
2 4 2   / 16
1 2 1
```

Sharpen:

```text
 0 -1  0
-1  5 -1
 0 -1  0
```

Edge detect:

```text
-1 -1 -1
-1  8 -1
-1 -1 -1
```

## Practical Notes

- `CLAMP_TO_EDGE` is used in the renderer to avoid invalid sampling outside texture bounds.
- `LINEAR` filtering smooths sampled values.
- Keep kernel sizes small (3x3 or 5x5) unless you optimize with separable filters.

## Suggested Exercises

1. Add an emboss filter kernel.
2. Add a grayscale-only edge detector (compute edge from luminance).
3. Animate blur strength over time by blending original and blurred color.
