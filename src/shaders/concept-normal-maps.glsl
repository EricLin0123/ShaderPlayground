const float PI = 3.14159265359;

uniform float u_nm_strength;
uniform float u_nm_scale;
uniform float u_nm_detail;
uniform float u_nm_speed;
uniform float u_nm_light_height;
uniform float u_nm_light_spin;
uniform float u_nm_specular;
uniform float u_nm_shininess;
uniform float u_nm_use_map;
uniform float u_nm_show_split;

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

float hash(vec2 p) {
  p = fract(p * vec2(321.1, 91.7));
  p += dot(p, p + 17.17);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec2 sphereUv(vec3 n) {
  return vec2(atan(n.z, n.x) / (2.0 * PI) + 0.5, asin(clamp(n.y, -1.0, 1.0)) / PI + 0.5);
}

mat3 tbn(vec3 n) {
  vec3 up = abs(n.y) > 0.98 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
  vec3 t = normalize(cross(up, n));
  vec3 b = cross(n, t);
  return mat3(t, b, n);
}

vec3 normalMap(vec2 uv) {
  float a = noise(uv * u_nm_scale + vec2(u_nm_speed * u_time, 0.0)) * 2.0 * PI;
  float tilt = 0.2 + 0.5 * noise(uv * u_nm_scale * u_nm_detail + vec2(0.0, -u_nm_speed * u_time));
  vec2 xy = vec2(cos(a), sin(a)) * tilt;
  float z = sqrt(max(0.0, 1.0 - dot(xy, xy)));
  return normalize(vec3(xy, z));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 ro = vec3(0.0, 0.0, 2.5);
  vec3 rd = normalize(vec3(suv, -1.35));

  float t = sphereHit(ro, rd, 0.85);
  vec3 bg = mix(vec3(0.14, 0.1, 0.18), vec3(0.03, 0.02, 0.05), length(suv));
  vec3 color = bg;

  if (t > 0.0) {
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);
    vec3 v = normalize(ro - p);
    vec2 uv = sphereUv(n);

    vec3 nFinal = n;
    if (u_nm_use_map > 0.5) {
      vec3 mapN = normalMap(uv);
      nFinal = normalize(mix(n, normalize(tbn(n) * mapN), clamp(u_nm_strength, 0.0, 2.0)));
    }

    if (u_nm_show_split > 0.5 && suv.x < 0.0) {
      nFinal = n;
    }

    float angle = u_time * u_nm_light_spin;
    vec3 lightPos = vec3(cos(angle), u_nm_light_height, sin(angle)) * 2.2;
    vec3 l = normalize(lightPos - p);

    float diff = max(dot(nFinal, l), 0.0);
    vec3 h = normalize(l + v);
    float spec = pow(max(dot(nFinal, h), 0.0), max(2.0, u_nm_shininess));

    vec3 base = vec3(0.66, 0.78, 0.94);
    color = base * (0.12 + diff);
    color += spec * u_nm_specular;
  }

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
