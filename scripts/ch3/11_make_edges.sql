CREATE OR REPLACE TABLE `mex-fisheries.maritime_informatics.edges`
AS
WITH
  q1 AS (
    SELECT
      start_cid,
      end_cid,
      COUNT(*) AS nb_traj,
      COUNT(DISTINCT vessel_rnpa) AS nb_vessels,
      AVG(ST_LENGTH(route_line)) AS avg_length,
      MIN(ST_LENGTH(route_line)) AS min_length,
      MAX(ST_LENGTH(route_line)) AS max_length
    FROM `mex-fisheries.maritime_informatics.tracks`
    GROUP BY start_cid, end_cid
  )
#
#
#
#
SELECT
  start_cid,
  end_cid,
  nb_traj,
  nb_vessels,
  avg_length,
  min_length,
  max_length,
  ST_MAKELINE(c1.centroid, c2.centroid) AS straight_edge
FROM q1
LEFT JOIN `mex-fisheries.maritime_informatics.cluster_stops` AS c1
  ON (c1.cid = start_cid)
LEFT JOIN `mex-fisheries.maritime_informatics.cluster_stops` AS c2
  ON (c1.cid = end_cid)
