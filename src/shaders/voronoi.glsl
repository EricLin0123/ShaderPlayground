// Author: @patriciogv
// Title: 4 cells voronoi

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 st = fragCoord / u_resolution;
  st.x *= u_resolution.x / u_resolution.y;

  vec3 color = vec3(0.0);

  // Cell positions
  vec2 point[5];
  point[0] = vec2(0.83, 0.75);
  point[1] = vec2(0.60, 0.07);
  point[2] = vec2(0.28, 0.64);
  point[3] = vec2(0.31, 0.26);
  point[4] = u_mouse / u_resolution;
  point[4].x *= u_resolution.x / u_resolution.y;

  float m_dist = 1.0; // minimum distance
  vec2 m_point = vec2(0.0); // minimum position

  // Iterate through the points positions
  for (int i = 0; i < 5; i++) {
    float dist = distance(st, point[i]);
    if (dist < m_dist) {
      // Keep the closer distance
      m_dist = dist;

      // Keep the position of the closer point
      m_point = point[i];
    }
  }

  // Add distance field to closest point center
  color += m_dist * 2.0;

  // Tint according the closest point position
  color.rg = m_point;

  // Show isolines
  color -= abs(sin(80.0 * m_dist)) * 0.07;

  // Draw point center
  color += 1.0 - step(0.02, m_dist);

  fragColor = vec4(color, 1.0);
}
