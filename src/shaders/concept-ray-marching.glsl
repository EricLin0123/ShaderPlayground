uniform float u_rm_steps;
uniform float u_rm_eps;
uniform float u_rm_max_dist;
uniform float u_rm_shape_blend;
uniform float u_rm_twist;
uniform float u_rm_light_intensity;
uniform float u_rm_shadow_strength;
uniform float u_rm_ao_strength;
uniform float u_rm_use_shadow;
uniform float u_rm_use_ao;
uniform float u_rm_animate;

float smin(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

mat2 rot(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c, -s, s, c);
}

float sdfScene(vec3 p) {
  float t = (u_rm_animate > 0.5 ? u_time : 0.0);
  p.xz *= rot(u_rm_twist * (0.5 + 0.5 * sin(t * 0.6)) * p.y * 0.6);

  float s = length(p - vec3(0.0, 0.12, 0.0)) - 0.65;
  vec3 q = p - vec3(0.0, 0.05, 0.0);
  float b = length(max(abs(q) - vec3(0.45), 0.0)) - 0.02;
  float blend = mix(0.01, 0.35, clamp(u_rm_shape_blend, 0.0, 1.0));

  float obj = smin(s, b, blend);
  float plane = p.y + 0.85;
  return min(obj, plane);
}

vec3 normalAt(vec3 p) {
  float e = max(0.0005, u_rm_eps);
  vec2 k = vec2(1.0, -1.0);
  return normalize(
    k.xyy * sdfScene(p + k.xyy * e) +
    k.yyx * sdfScene(p + k.yyx * e) +
    k.yxy * sdfScene(p + k.yxy * e) +
    k.xxx * sdfScene(p + k.xxx * e)
  );
}

float softShadow(vec3 ro, vec3 rd) {
  float t = 0.03;
  float shade = 1.0;

  for (int i = 0; i < 64; i += 1) {
    float h = sdfScene(ro + rd * t);
    if (h < u_rm_eps) {
      return 0.0;
    }

    shade = min(shade, 10.0 * h / t);
    t += clamp(h, 0.01, 0.25);
    if (t > 8.0) {
      break;
    }
  }

  return clamp(shade, 0.0, 1.0);
}

float ao(vec3 p, vec3 n) {
  float occ = 0.0;
  float s = 1.0;
  for (int i = 1; i <= 5; i += 1) {
    float h = 0.05 * float(i);
    float d = sdfScene(p + n * h);
    occ += (h - d) * s;
    s *= 0.6;
  }
  return clamp(1.0 - occ, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 ro = vec3(0.0, 0.25, 3.2);
  vec3 rd = normalize(vec3(uv, -1.7));

  int maxSteps = int(clamp(u_rm_steps, 8.0, 256.0));
  float t = 0.0;
  float dist = -1.0;

  for (int i = 0; i < 256; i += 1) {
    if (i >= maxSteps) {
      break;
    }

    vec3 p = ro + rd * t;
    float d = sdfScene(p);
    if (d < u_rm_eps) {
      dist = t;
      break;
    }

    t += d;
    if (t > u_rm_max_dist) {
      break;
    }
  }

  vec3 color = mix(vec3(0.08, 0.09, 0.12), vec3(0.02, 0.02, 0.03), length(uv));

  if (dist > 0.0) {
    vec3 p = ro + rd * dist;
    vec3 n = normalAt(p);
    vec3 v = normalize(ro - p);

    vec3 l = normalize(vec3(cos(u_time * 0.4), 1.2, sin(u_time * 0.4)));
    float diff = max(dot(n, l), 0.0);
    vec3 h = normalize(l + v);
    float spec = pow(max(dot(n, h), 0.0), 48.0);

    float sh = 1.0;
    if (u_rm_use_shadow > 0.5) {
      sh = mix(1.0, softShadow(p + n * (2.0 * u_rm_eps), l), clamp(u_rm_shadow_strength, 0.0, 1.0));
    }

    float occ = 1.0;
    if (u_rm_use_ao > 0.5) {
      occ = mix(1.0, ao(p, n), clamp(u_rm_ao_strength, 0.0, 1.0));
    }

    vec3 base = mix(vec3(0.28, 0.56, 0.72), vec3(0.6, 0.44, 0.3), step(p.y, -0.82));
    color = base * (0.1 + diff * sh * u_rm_light_intensity) + vec3(spec) * sh;
    color *= occ;
  }

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
