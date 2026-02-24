const float PI = 3.14159265359;

float hash11(float p) {
  p = fract(p * 0.1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

float hash31(vec3 p) {
  p = fract(p * 0.1031);
  p += dot(p, p.yzx + 33.33);
  return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  vec3 u = f * f * (3.0 - 2.0 * f);

  float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
  float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
  float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
  float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
  float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
  float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
  float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
  float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

  float nx00 = mix(n000, n100, u.x);
  float nx10 = mix(n010, n110, u.x);
  float nx01 = mix(n001, n101, u.x);
  float nx11 = mix(n011, n111, u.x);
  float nxy0 = mix(nx00, nx10, u.y);
  float nxy1 = mix(nx01, nx11, u.y);
  return mix(nxy0, nxy1, u.z);
}

float fbm(vec3 p) {
  float v = 0.0;
  float a = 0.5;
  mat3 m = mat3(
    1.6, 1.2, 0.4,
    -1.2, 1.6, -0.3,
    -0.4, 0.3, 1.8
  );

  for (int i = 0; i < 6; i++) {
    v += a * noise3(p);
    p = m * p * 1.03;
    a *= 0.52;
  }

  return v;
}

float ridgedFbm(vec3 p) {
  float v = 0.0;
  float a = 0.55;

  for (int i = 0; i < 5; i++) {
    float n = noise3(p) * 2.0 - 1.0;
    n = 1.0 - abs(n);
    n *= n;
    v += n * a;
    p = p * 2.06 + vec3(7.1, -3.9, 4.7);
    a *= 0.55;
  }

  return v;
}

vec3 rotateY(vec3 p, float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return vec3(c * p.x - s * p.z, p.y, s * p.x + c * p.z);
}

vec2 sphereIntersect(vec3 ro, vec3 rd, float radius) {
  float b = dot(ro, rd);
  float c = dot(ro, ro) - radius * radius;
  float h = b * b - c;

  if (h < 0.0) {
    return vec2(-1.0);
  }

  h = sqrt(h);
  return vec2(-b - h, -b + h);
}

void tangentBasis(vec3 n, out vec3 t, out vec3 b) {
  vec3 up = abs(n.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  t = normalize(cross(up, n));
  b = cross(n, t);
}

float planetHeight(vec3 p) {
  vec3 warp = vec3(
    fbm(p * 1.70 + vec3(11.0, 0.0, 7.0)),
    fbm(p * 1.70 + vec3(3.0, 19.0, 1.0)),
    fbm(p * 1.70 + vec3(5.0, 9.0, 23.0))
  ) * 2.0 - 1.0;

  float continents = fbm(p * 1.05 + warp * 0.85);
  float continentMask = smoothstep(0.50, 0.76, continents);

  float tectonic = fbm(p * 2.30 + vec3(4.0, -3.0, 2.0));
  float ridges = ridgedFbm(p * 5.60 + warp * 0.65);
  float erosion = fbm(p * 9.0 + vec3(8.0, 5.0, -2.0));

  float base = mix(-0.24, 0.52, continentMask);
  float mountains = continentMask * pow(ridges, 1.7) * 0.72;
  float detail = (erosion - 0.5) * 0.12 + (tectonic - 0.5) * 0.22;

  return base + mountains + detail;
}

vec3 surfaceNormalFromHeight(vec3 sphereN, float h0) {
  vec3 t;
  vec3 b;
  tangentBasis(sphereN, t, b);

  float eps = 0.0035;
  vec3 pT = normalize(sphereN + t * eps);
  vec3 pB = normalize(sphereN + b * eps);

  float hT = planetHeight(pT);
  float hB = planetHeight(pB);

  float dhT = (hT - h0) / eps;
  float dhB = (hB - h0) / eps;

  float bumpStrength = 0.16;
  return normalize(sphereN - t * dhT * bumpStrength - b * dhB * bumpStrength);
}

vec3 biomeColor(vec3 p, float elevation, float latitude, float humidity) {
  vec3 deepOcean = vec3(0.015, 0.09, 0.23);
  vec3 shallowOcean = vec3(0.04, 0.24, 0.50);
  vec3 beach = vec3(0.70, 0.63, 0.46);
  vec3 desert = vec3(0.63, 0.52, 0.31);
  vec3 grass = vec3(0.20, 0.47, 0.22);
  vec3 forest = vec3(0.08, 0.30, 0.16);
  vec3 rock = vec3(0.45, 0.43, 0.41);
  vec3 snow = vec3(0.95, 0.97, 1.0);

  if (elevation < 0.0) {
    float depth = clamp(-elevation * 2.5, 0.0, 1.0);
    return mix(shallowOcean, deepOcean, depth);
  }

  float temp = clamp(1.0 - latitude * 1.25 - elevation * 0.55, 0.0, 1.0);
  float arid = clamp(1.0 - humidity * 1.1, 0.0, 1.0);

  vec3 col = mix(grass, forest, smoothstep(0.45, 0.82, humidity));
  col = mix(col, desert, smoothstep(0.45, 0.85, arid) * smoothstep(0.35, 0.85, temp));
  col = mix(col, beach, smoothstep(0.0, 0.03, elevation) * (1.0 - smoothstep(0.03, 0.08, elevation)));
  col = mix(col, rock, smoothstep(0.45, 0.85, elevation));
  col = mix(col, snow, smoothstep(0.50, 0.90, latitude + elevation * 0.45));

  return col;
}

vec3 randomCloudDrift(float t) {
  float cell = t * 0.055;
  float i = floor(cell);
  float f = fract(cell);
  float s = f * f * (3.0 - 2.0 * f);

  vec3 dirA = normalize(vec3(
    hash11(i + 1.0) * 2.0 - 1.0,
    hash11(i + 2.0) * 2.0 - 1.0,
    hash11(i + 3.0) * 2.0 - 1.0
  ));

  vec3 dirB = normalize(vec3(
    hash11(i + 11.0) * 2.0 - 1.0,
    hash11(i + 12.0) * 2.0 - 1.0,
    hash11(i + 13.0) * 2.0 - 1.0
  ));

  vec3 wander = normalize(mix(dirA, dirB, s));
  return wander * t * 0.030;
}

float cloudCoverage(vec3 p) {
  vec3 drift = randomCloudDrift(u_time);
  vec3 warp = vec3(
    fbm(p * 1.7 + drift + vec3(4.0, 0.0, 9.0)),
    fbm(p * 1.7 + drift + vec3(1.0, 6.0, 3.0)),
    fbm(p * 1.7 + drift + vec3(7.0, 2.0, 5.0))
  ) * 2.0 - 1.0;

  float base = fbm(p * 3.4 + drift + warp * 0.65);
  float detail = fbm(p * 7.2 - drift * 1.4 - warp * 0.35);
  float coverage = base * 0.72 + detail * 0.38;
  return smoothstep(0.56, 0.80, coverage);
}

vec3 starfield(vec2 uv, vec3 bg) {
  vec2 cell = floor((uv + 2.0) * 340.0);
  float star = step(0.9988, hash11(cell.x * 17.0 + cell.y * 131.0));
  float twinkle = 0.65 + 0.35 * sin(u_time * 2.5 + hash11(cell.x + cell.y * 3.0) * 6.2831);

  vec3 stars = vec3(star * twinkle);
  vec3 nebula = vec3(0.05, 0.08, 0.16) * pow(fbm(vec3(uv * 1.5, u_time * 0.01)), 2.0);
  return bg + stars + nebula;
}

vec3 atmosphereScatter(vec3 ro, vec3 rd, vec3 lightDir, float tMax, float planetRadius, float atmRadius) {
  vec2 atmoHit = sphereIntersect(ro, rd, atmRadius);
  if (atmoHit.x < 0.0) {
    return vec3(0.0);
  }

  float t0 = max(atmoHit.x, 0.0);
  float t1 = min(atmoHit.y, tMax);

  if (t1 <= t0) {
    return vec3(0.0);
  }

  float segLen = t1 - t0;
  float tMid = t0 + segLen * 0.5;
  vec3 pos = ro + rd * tMid;

  float h = max(length(pos) - planetRadius, 0.0);
  float density = exp(-h * 12.0) * segLen;

  float mu = dot(rd, lightDir);
  float phaseR = 3.0 / (16.0 * PI) * (1.0 + mu * mu);
  float g = 0.76;
  float denom = pow(max(1.0 + g * g - 2.0 * g * mu, 0.001), 1.5);
  float phaseM = 1.0 / (4.0 * PI) * ((1.0 - g * g) / denom);

  vec3 betaR = vec3(0.26, 0.52, 1.0) * 0.45;
  vec3 betaM = vec3(1.0) * 0.10;

  return (betaR * phaseR + betaM * phaseM) * density * 1.7;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - 0.5 * u_resolution) / u_resolution.y;

  vec3 ro = vec3(0.0, 0.0, 4.2);
  vec3 rd = normalize(vec3(uv, -1.8));

  vec3 lightDir = normalize(vec3(-0.72, 0.36, 0.58));
  float spin = u_time * 0.13;

  vec3 bg = mix(vec3(0.005, 0.01, 0.03), vec3(0.015, 0.03, 0.08), smoothstep(-0.4, 1.1, uv.y));
  bg = starfield(uv, bg);

  float planetRadius = 1.0;
  float cloudRadius = 1.018;
  float atmosphereRadius = 1.07;

  vec2 pHit = sphereIntersect(ro, rd, planetRadius);
  vec2 cHit = sphereIntersect(ro, rd, cloudRadius);
  bool hitPlanet = pHit.x > 0.0;
  bool hitCloud = cHit.x > 0.0;

  vec3 color = bg;

  float tPlanet = 1e9;
  if (hitPlanet) {
    tPlanet = pHit.x;

    vec3 pos = ro + rd * tPlanet;
    vec3 sphereN = normalize(pos);

    vec3 sampleN = rotateY(sphereN, spin);
    vec3 lightLocal = rotateY(lightDir, spin);
    vec3 viewLocal = rotateY(-rd, spin);

    float h = planetHeight(sampleN);
    float seaLevel = 0.16;
    float elevation = h - seaLevel;

    vec3 surfN = surfaceNormalFromHeight(sampleN, h);

    float humidity = fbm(sampleN * 2.7 + vec3(1.0, 6.0, 2.0));
    float latitude = abs(sampleN.y);
    vec3 albedo = biomeColor(sampleN, elevation, latitude, humidity);

    float cloud = cloudCoverage(sampleN * 1.2);

    float ndl = max(dot(surfN, lightLocal), 0.0);
    float ndv = max(dot(surfN, viewLocal), 0.0);

    vec3 halfVec = normalize(lightLocal + viewLocal);
    float ndh = max(dot(surfN, halfVec), 0.0);

    float ambient = 0.14 + 0.23 * (1.0 - latitude * 0.6);
    float wrappedDiffuse = max((dot(surfN, lightLocal) + 0.22) / 1.22, 0.0);

    vec3 lighting = albedo * (ambient + wrappedDiffuse * 0.95);

    if (elevation < 0.0) {
      float fresnel = pow(1.0 - ndv, 5.0);
      float spec = pow(ndh, mix(120.0, 260.0, clamp(-elevation * 2.2, 0.0, 1.0)));
      vec3 oceanSpec = vec3(0.9, 0.95, 1.0) * spec * (0.10 + ndl * 1.4);
      lighting += oceanSpec * (0.20 + fresnel * 1.8);
    } else {
      float landSpec = pow(ndh, 28.0) * 0.10 * ndl;
      lighting += vec3(1.0, 0.95, 0.9) * landSpec;
    }

    float cloudLight = mix(0.35, 1.0, max(dot(sampleN, lightLocal), 0.0));
    float cloudShadow = mix(1.0, 0.58, cloud * smoothstep(0.05, 0.65, ndl));
    lighting *= cloudShadow;

    float night = smoothstep(0.18, -0.28, dot(surfN, lightLocal));
    float cityPattern = fbm(sampleN * 26.0 + vec3(9.0, 3.0, 4.0));
    cityPattern *= fbm(sampleN * 53.0 + vec3(-2.0, 1.0, 7.0));
    float city = smoothstep(0.26, 0.52, elevation) * smoothstep(0.56, 0.80, cityPattern);
    vec3 cityLights = vec3(1.0, 0.62, 0.25) * city * night * (1.0 - cloud * 0.75) * 1.35;

    float rim = pow(1.0 - max(dot(sampleN, viewLocal), 0.0), 4.0);
    vec3 atmosphereRim = vec3(0.20, 0.45, 0.95) * rim * (0.28 + ndl * 0.9);

    color = lighting + cityLights + atmosphereRim;

    vec3 sunRef = reflect(-viewLocal, surfN);
    float glint = pow(max(dot(sunRef, lightLocal), 0.0), 90.0) * smoothstep(-0.03, -0.18, elevation);
    color += vec3(1.0, 0.95, 0.84) * glint * 0.45;
  }

  float cloudT = 1e9;
  if (hitCloud) {
    cloudT = cHit.x;
    bool cloudInFront = !hitPlanet || (cloudT < tPlanet);
    if (cloudInFront) {
      vec3 cloudPos = ro + rd * cloudT;
      vec3 cloudN = normalize(cloudPos);
      vec3 cloudSample = rotateY(cloudN, spin * 1.03);
      vec3 cloudLightDir = rotateY(lightDir, spin * 1.03);

      float c = cloudCoverage(cloudSample * 1.15);
      float cLight = mix(0.30, 1.0, max(dot(cloudSample, cloudLightDir), 0.0));
      vec3 cloudCol = vec3(1.0, 1.02, 1.05) * cLight;
      float cloudAlpha = c * 0.72;

      color = mix(color, cloudCol, cloudAlpha);
    }
  }

  float maxDist = hitPlanet ? tPlanet : 100.0;
  vec3 atm = atmosphereScatter(ro, rd, lightDir, maxDist, planetRadius, atmosphereRadius);
  color += atm;

  float sunGlow = pow(max(dot(rd, lightDir), 0.0), 120.0) * 3.5;
  color += vec3(1.0, 0.83, 0.62) * sunGlow;

  color = pow(color, vec3(0.4545));
  fragColor = vec4(color, 1.0);
}
