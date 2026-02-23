uniform float u_ec_exposure;
uniform float u_ec_reflectivity;
uniform float u_ec_roughness;
uniform float u_ec_face_tint;
uniform float u_ec_edge_boost;
uniform float u_ec_spin;
uniform float u_ec_object_scale;
uniform float u_ec_show_axes;
uniform float u_ec_animate;

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

vec3 envCube(vec3 dir) {
  vec3 d = normalize(dir);
  vec3 a = abs(d);
  vec3 c;

  if (a.x > a.y && a.x > a.z) {
    c = d.x > 0.0 ? vec3(0.96, 0.36, 0.31) : vec3(0.24, 0.35, 0.89);
  } else if (a.y > a.z) {
    c = d.y > 0.0 ? vec3(0.34, 0.82, 0.56) : vec3(0.2, 0.16, 0.25);
  } else {
    c = d.z > 0.0 ? vec3(0.88, 0.72, 0.28) : vec3(0.28, 0.78, 0.96);
  }

  vec3 tint = mix(vec3(1.0), vec3(0.9, 0.95, 1.06), clamp(u_ec_face_tint, 0.0, 1.0));
  float edge = pow(max(max(a.x, a.y), a.z), mix(5.0, 22.0, clamp(u_ec_edge_boost * 0.5, 0.0, 1.0)));
  return mix(c * 0.4, c, edge) * tint;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  float spin = u_ec_spin * (u_ec_animate > 0.5 ? u_time : 1.0);

  vec3 ro = vec3(0.0, 0.0, 2.9);
  ro.xz *= rot(spin * 0.55);

  vec3 rd = normalize(vec3(uv, -1.8));
  rd.xz *= rot(spin);

  vec3 color = envCube(rd);

  float t = sphereHit(ro, rd, clamp(u_ec_object_scale, 0.4, 1.5));
  if (t > 0.0) {
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);
    vec3 refl = reflect(rd, n);
    vec3 roughRefl = normalize(mix(refl, n, clamp(u_ec_roughness, 0.0, 1.0)));
    vec3 env = envCube(roughRefl);
    color = mix(vec3(0.2, 0.2, 0.24), env, clamp(u_ec_reflectivity, 0.0, 1.0));
  }

  if (u_ec_show_axes > 0.5) {
    color += 0.14 * normalize(abs(rd));
  }

  color *= u_ec_exposure;
  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
