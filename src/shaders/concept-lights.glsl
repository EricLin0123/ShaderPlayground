uniform float u_cl_ambient;
uniform float u_cl_diffuse;
uniform float u_cl_specular;
uniform float u_cl_shininess;
uniform float u_cl_light_height;
uniform float u_cl_light_spin;
uniform float u_cl_light_distance;
uniform float u_cl_light_color_mix;
uniform float u_cl_use_blinn;
uniform float u_cl_animate_light;

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

vec3 lightColor(float m) {
  return mix(vec3(0.9, 0.95, 1.0), vec3(1.0, 0.78, 0.55), clamp(m, 0.0, 1.0));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 ro = vec3(0.0, 0.0, 2.6);
  vec3 rd = normalize(vec3(uv, -1.4));

  float t = sphereHit(ro, rd, 0.85);
  vec3 bg = mix(vec3(0.09, 0.12, 0.2), vec3(0.02, 0.03, 0.06), length(uv));
  vec3 color = bg;

  if (t > 0.0) {
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);
    vec3 v = normalize(ro - p);

    float lightAngle = (u_cl_animate_light > 0.5 ? u_time : 0.0) * u_cl_light_spin;
    vec3 lightPos = vec3(cos(lightAngle), u_cl_light_height, sin(lightAngle)) * u_cl_light_distance;
    vec3 l = normalize(lightPos - p);

    float ndl = max(dot(n, l), 0.0);

    float spec;
    if (u_cl_use_blinn > 0.5) {
      vec3 h = normalize(l + v);
      spec = pow(max(dot(n, h), 0.0), max(2.0, u_cl_shininess));
    } else {
      vec3 r = reflect(-l, n);
      spec = pow(max(dot(v, r), 0.0), max(2.0, u_cl_shininess));
    }

    vec3 lColor = lightColor(u_cl_light_color_mix);
    vec3 base = vec3(0.27, 0.37, 0.6);

    color = base * u_cl_ambient;
    color += base * ndl * u_cl_diffuse * lColor;
    color += spec * u_cl_specular * lColor;
  }

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
