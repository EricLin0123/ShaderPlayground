const float PI = 3.14159265359;

uniform float u_bm_strength;
uniform float u_bm_scale;
uniform float u_bm_speed;
uniform float u_bm_epsilon;
uniform float u_bm_specular;
uniform float u_bm_shininess;
uniform float u_bm_light_height;
uniform float u_bm_light_spin;
uniform float u_bm_use_bump;
uniform float u_bm_show_height;

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

vec2 sphereUv(vec3 n) {
  return vec2(atan(n.z, n.x) / (2.0 * PI) + 0.5, asin(clamp(n.y, -1.0, 1.0)) / PI + 0.5);
}

mat3 tbn(vec3 n) {
  vec3 up = abs(n.y) > 0.98 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
  vec3 t = normalize(cross(up, n));
  vec3 b = cross(n, t);
  return mat3(t, b, n);
}

float bumpHeight(vec2 uv) {
  vec2 p = uv * u_bm_scale;
  float h1 = sin(p.x * 2.3 + u_bm_speed * u_time);
  float h2 = sin(p.y * 2.9 - u_bm_speed * u_time * 0.6);
  float h3 = sin((p.x + p.y) * 2.0 + u_time * u_bm_speed * 0.7);
  return 0.5 + 0.2 * h1 + 0.2 * h2 + 0.1 * h3;
}

vec3 bumpNormal(vec2 uv) {
  float e = max(0.0002, u_bm_epsilon);
  float h = bumpHeight(uv);
  float hx = bumpHeight(uv + vec2(e, 0.0));
  float hy = bumpHeight(uv + vec2(0.0, e));
  vec2 g = vec2((hx - h) / e, (hy - h) / e);
  return normalize(vec3(-g, 1.0));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 suv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 ro = vec3(0.0, 0.0, 2.5);
  vec3 rd = normalize(vec3(suv, -1.35));

  float t = sphereHit(ro, rd, 0.85);
  vec3 bg = mix(vec3(0.08, 0.12, 0.09), vec3(0.02, 0.04, 0.03), length(suv));
  vec3 color = bg;

  if (t > 0.0) {
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);
    vec3 v = normalize(ro - p);
    vec2 uv = sphereUv(n);

    float h = bumpHeight(uv);
    vec3 nFinal = n;
    if (u_bm_use_bump > 0.5) {
      vec3 bn = bumpNormal(uv);
      nFinal = normalize(mix(n, normalize(tbn(n) * bn), clamp(u_bm_strength, 0.0, 2.0)));
    }

    float angle = u_time * u_bm_light_spin;
    vec3 lightPos = vec3(cos(angle), u_bm_light_height, sin(angle)) * 2.3;
    vec3 l = normalize(lightPos - p);

    float diff = max(dot(nFinal, l), 0.0);
    vec3 hvec = normalize(l + v);
    float spec = pow(max(dot(nFinal, hvec), 0.0), max(2.0, u_bm_shininess));

    vec3 base = mix(vec3(0.38, 0.65, 0.46), vec3(0.8, 0.94, 0.86), h);
    color = base * (0.1 + diff) + spec * u_bm_specular;

    if (u_bm_show_height > 0.5) {
      color = mix(color, vec3(h), 0.7);
    }
  }

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
