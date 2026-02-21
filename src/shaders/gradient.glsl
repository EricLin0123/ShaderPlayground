void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution;
  float waveR = 0.5 + 0.5 * sin(u_time + uv.x * 6.2831);
  float waveG = 0.5 + 0.5 * sin(u_time * 0.8 + uv.y * 6.2831 + 1.4);
  float waveB = 0.5 + 0.5 * sin(u_time * 1.2 + (uv.x + uv.y) * 4.5 + 2.2);

  vec3 color = vec3(waveR, waveG, waveB);
  fragColor = vec4(color, 1.0);
}
