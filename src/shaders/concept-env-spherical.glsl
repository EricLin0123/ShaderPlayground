const float PI = 3.14159265359;

uniform float u_es_exposure;
uniform float u_es_reflectivity;
uniform float u_es_roughness;
uniform float u_es_sun_strength;
uniform float u_es_horizon_warmth;
uniform float u_es_spin;
uniform float u_es_object_scale;
uniform float u_es_show_background;
uniform float u_es_animate;

mat2 rot(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c, -s, s, c);
}

float sphereHit(vec3 ro, vec3 rd, float r) {
  float b = dot(ro, rd);
  float c = dot(ro, ro) - r * r;
  float h = b * b - c;
  if (h < 0.0) {
    return -1.0;
  }

  h = sqrt(h);
  float t = -b - h;
  return t > 0.0 ? t : -b + h;
}

vec3 envSpherical(vec3 dir) {
  vec3 d = normalize(dir);
  float h = clamp(0.5 + 0.5 * d.y, 0.0, 1.0);

  vec3 skyLow = vec3(0.12, 0.21, 0.35);
  vec3 skyHigh = vec3(0.52, 0.77, 0.98);
  vec3 horizon = mix(vec3(0.96, 0.84, 0.64), vec3(0.9, 0.86, 0.8), clamp(u_es_horizon_warmth, 0.0, 1.0));

  vec3 col = mix(skyLow, skyHigh, pow(h, 1.35));
  col = mix(col, horizon, exp(-14.0 * abs(d.y)));

  vec3 sunDir = normalize(vec3(0.45, 0.66, 0.58));
  float sun = pow(max(dot(d, sunDir), 0.0), 170.0);
  col += vec3(1.0, 0.9, 0.7) * sun * u_es_sun_strength;

  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  float spin = u_es_spin * (u_es_animate > 0.5 ? u_time : 1.0);
  vec3 target = vec3(0.0);
  vec3 ro = vec3(sin(spin) * 2.9, 0.0, cos(spin) * 2.9);
  vec3 forward = normalize(target - ro);
  vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
  vec3 up = normalize(cross(right, forward));
  vec3 rd = normalize(forward + uv.x * right + uv.y * up);

  vec3 color = envSpherical(rd);

  float t = sphereHit(ro, rd, clamp(u_es_object_scale, 0.4, 1.5));
  if (t > 0.0) {
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);

    vec3 refl = reflect(rd, n);
    vec3 blurred = normalize(mix(refl, n, clamp(u_es_roughness, 0.0, 1.0)));
    vec3 env = envSpherical(blurred);

    vec3 base = vec3(0.22, 0.28, 0.38);
    color = mix(base, env, clamp(u_es_reflectivity, 0.0, 1.0));
  } else if (u_es_show_background < 0.5) {
    color *= 0.0;
  }

  color *= u_es_exposure;
  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
