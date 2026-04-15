# Find vessels whose tracks intersect a specific port's Voronoi polygon.
# Uses ST_INTERSECTS to test whether each VMS point falls within the
# Voronoi polygon for port 04002. Change the port_id to query other ports.
# Run with: bq query < scripts/ch3/04_vessels_inside_area.sql

# The subquery pulls the polygon geometry for a single port,
# and the outer query returns all distinct vessels that have
# at least one VMS position inside that polygon.
SELECT DISTINCT vessel_rnpa
FROM `mex-fisheries.maritime_informatics.longline_tracks`
WHERE
  ST_INTERSECTS(
    geography,
    (
      SELECT geography
      FROM `mex-fisheries.maritime_informatics.voronoi_ports`
      WHERE port_id = "04002"
    ))