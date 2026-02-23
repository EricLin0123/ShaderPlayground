uniform float u_fs_fresnel_power;
uniform float u_fs_rim_strength;
uniform float u_fs_shadow_strength;
uniform float u_fs_ao_strength;
uniform float u_fs_steps;
uniform float u_fs_eps;
uniform float u_fs_max_dist;
uniform float u_fs_light_spin;
uniform float u_fs_enable_shadow;
uniform float u_fs_enable_ao;
uniform float u_fs_animate;

float sdf(vec3 p) {
  float sphere = length(p - vec3(0.0, 0.1, 0.0)) - 0.7;
  float plane = p.y + 0.85;
  return min(sphere, plane);
}

vec3 nrm(vec3 p) {
  float e = max(0.0005, u_fs_eps);
  vec2 k = vec2(1.0, -1.0);
  return normalize(
    k.xyy * sdf(p + k.xyy * e) +
    k.yyx * sdf(p + k.yyx * e) +
    k.yxy * sdf(p + k.yxy * e) +
    k.xxx * sdf(p + k.xxx * e)
  );
}

float shadow(vec3 ro, vec3 rd) {
  float t = 0.03;
  float res = 1.0;
  for (int i = 0; i < 64; i += 1) {
    float h = sdf(ro + rd * t);
    if (h < u_fs_eps) {
      return 0.0;
    }
    res = min(res, 11.0 * h / t);
    t += clamp(h, 0.01, 0.25);
    if (t > 8.0) {
      break;
    }
  }
  return clamp(res, 0.0, 1.0);
}

float ao(vec3 p, vec3 n) {
  float occ = 0.0;
  float s = 1.0;
  for (int i = 1; i <= 5; i += 1) {
    float h = 0.05 * float(i);
    float d = sdf(p + n * h);
    occ += (h - d) * s;
    s *= 0.62;
  }
  return clamp(1.0 - occ, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 ro = vec3(0.0, 0.25, 3.0);
  vec3 rd = normalize(vec3(uv, -1.8));

  float t = 0.0;
  float hit = -1.0;
  int maxSteps = int(clamp(u_fs_steps, 8.0, 256.0));

  for (int i = 0; i < 256; i += 1) {
    if (i >= maxSteps) {
      break;
    }

    vec3 p = ro + rd * t;
    float d = sdf(p);
    if (d < u_fs_eps) {
      hit = t;
      break;
    }

    t += d;
    if (t > u_fs_max_dist) {
      break;
    }
  }

  vec3 color = mix(vec3(0.1, 0.1, 0.14), vec3(0.03, 0.03, 0.05), length(uv));

  if (hit > 0.0) {
    vec3 p = ro + rd * hit;
    vec3 n = nrm(p);
    vec3 v = normalize(ro - p);

    float lightTime = (u_fs_animate > 0.5 ? u_time : 0.0) * u_fs_light_spin;
    vec3 l = normalize(vec3(cos(lightTime), 1.2, sin(lightTime)));

    float diff = max(dot(n, l), 0.0);
    vec3 h = normalize(l + v);
    float spec = pow(max(dot(n, h), 0.0), 56.0);
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), clamp(u_fs_fresnel_power, 0.5, 8.0));

    float sh = 1.0;
    if (u_fs_enable_shadow > 0.5) {
      sh = mix(1.0, shadow(p + n * (2.0 * u_fs_eps), l), clamp(u_fs_shadow_strength, 0.0, 1.0));
    }

    float occ = 1.0;
    if (u_fs_enable_ao > 0.5) {
      occ = mix(1.0, ao(p, n), clamp(u_fs_ao_strength, 0.0, 1.0));
    }

    vec3 base = vec3(0.48, 0.56, 0.82);
    vec3 rim = vec3(0.8, 0.88, 1.0) * fresnel * u_fs_rim_strength;
    color = base * (0.1 + diff * sh) + vec3(spec) * sh + rim;
    color *= occ;
  }

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));
  fragColor = vec4(color, 1.0);
}
