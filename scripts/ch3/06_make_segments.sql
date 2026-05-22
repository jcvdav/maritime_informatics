# Query 1 - Builds a table of segments
CREATE OR REPLACE TABLE mex-fisheries.maritime_informatics.segments
AS
SELECT
  vessel_rnpa,
  datetime, datetime2,
  speed1, speed2,
  p1,
  p2,
  ST_MAKELINE(p1, p2) AS segment,
  ST_DISTANCE(p1, p2) AS distance,
  TIMESTAMP_DIFF(datetime2, datetime, SECOND) AS duration_s,
  ST_DISTANCE(p1, p2) / TIMESTAMP_DIFF(datetime2, datetime, SECOND) AS speed_m_s
FROM
  (
    SELECT
      vessel_rnpa,
      LEAD(vessel_rnpa) OVER (ORDER BY vessel_rnpa, datetime) AS vessel_rnpa2,
      datetime,
      LEAD(datetime) OVER (ORDER BY vessel_rnpa, datetime) AS datetime2,
      implied_speed_knots AS speed1,
      LEAD(implied_speed_knots) OVER (ORDER BY vessel_rnpa, datetime) AS speed2,
      geography AS p1,
      LEAD(geography) OVER (ORDER BY vessel_rnpa, datetime) AS p2
    FROM `mex-fisheries.maritime_informatics.longline_tracks`
  )
WHERE vessel_rnpa = vessel_rnpa2 AND datetime != datetime2