uniform float u_rr_reflectivity;
uniform float u_rr_refractivity;
uniform float u_rr_ior;
uniform float u_rr_fresnel_power;
uniform float u_rr_absorption;
uniform float u_rr_env_mix;
uniform float u_rr_object_scale;
uniform float u_rr_spin;
uniform float u_rr_enable_reflect;
uniform float u_rr_enable_refract;
uniform float u_rr_animate;

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

vec3 env(vec3 d) {
  vec3 sky = mix(vec3(0.1, 0.16, 0.28), vec3(0.56, 0.78, 0.96), 0.5 + 0.5 * d.y);
  vec3 horizon = vec3(0.95, 0.8, 0.64);
  sky = mix(sky, horizon, exp(-10.0 * abs(d.y)));

  vec3 cube;
  vec3 a = abs(d);
  if (a.x > a.y && a.x > a.z) {
    cube = d.x > 0.0 ? vec3(0.95, 0.48, 0.35) : vec3(0.24, 0.34, 0.86);
  } else if (a.y > a.z) {
    cube = d.y > 0.0 ? vec3(0.36, 0.8, 0.58) : vec3(0.16, 0.14, 0.2);
  } else {
    cube = d.z > 0.0 ? vec3(0.86, 0.72, 0.3) : vec3(0.3, 0.74, 0.92);
  }

  return mix(sky, cube, clamp(u_rr_env_mix, 0.0, 1.0));
}

vec3 absorption(vec3 c, float dist) {
  vec3 sigma = vec3(0.1, 0.03, 0.01) * clamp(u_rr_absorption, 0.0, 8.0);
  return c * exp(-sigma * dist);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  float spin = u_rr_spin * (u_rr_animate > 0.5 ? u_time : 1.0);
  vec3 ro = vec3(0.0, 0.0, 3.0);
  ro.xz *= rot(spin * 0.5);

  vec3 rd = normalize(vec3(uv, -1.85));
  rd.xz *= rot(spin);

  vec3 color = env(rd);

  float t = sphereHit(ro, rd, clamp(u_rr_object_scale, 0.4, 1.5));
  if (t > 0.0) {
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);
    vec3 v = normalize(-rd);

    float fresnel = pow(1.0 - max(dot(v, n), 0.0), clamp(u_rr_fresnel_power, 0.5, 8.0));

    vec3 outCol = vec3(0.2, 0.24, 0.32);

    if (u_rr_enable_reflect > 0.5) {
      vec3 r = reflect(rd, n);
      outCol = mix(outCol, env(r), clamp(u_rr_reflectivity, 0.0, 1.0) * (0.2 + 0.8 * fresnel));
    }

    if (u_rr_enable_refract > 0.5) {
      float eta = 1.0 / max(1.01, u_rr_ior);
      vec3 refr = refract(rd, n, eta);
      vec3 refrCol = length(refr) > 0.0 ? env(refr) : outCol;
      refrCol = absorption(refrCol, t);
      outCol = mix(outCol, refrCol, clamp(u_rr_refractivity, 0.0, 1.0) * (1.0 - fresnel));
    }

    color = outCol;
  }

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
