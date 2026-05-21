CREATE OR REPLACE TABLE `mex-fisheries.maritime_informatics.stops`
AS
WITH
  raw_stops AS (
    SELECT 
      vessel_rnpa, 
      datetime2 AS t_begin,
      -- Find the first 'stop_end' event that happens AFTER this 'stop_begin' for this vessel
      (
        SELECT MIN(datetime) 
        FROM `mex-fisheries.maritime_informatics.segments` 
        WHERE vessel_rnpa = s.vessel_rnpa 
          AND datetime >= s.datetime2 
          AND speed1 <= 0.1 AND speed2 > 0.1
      ) AS t_end
    FROM `mex-fisheries.maritime_informatics.segments` AS s
    WHERE speed1 > 0.1 AND speed2 < 0.1
  ),
  #
  #
  #
  stops AS (
    SELECT
      vessel_rnpa,
      t_begin,
      t_end,
      DATETIME_DIFF(t_end, t_begin, SECOND) AS duration_s
    FROM raw_stops
    WHERE t_end IS NOT NULL
  )
#
#
#
#
SELECT
  s.vessel_rnpa,
  s.t_begin,
  s.t_end,
  s.duration_s,
  ST_CENTROID(ST_UNION_AGG(t.geography)) AS centroid,
  COUNT(*) AS nb
FROM stops AS s
LEFT JOIN `mex-fisheries.maritime_informatics.longline_tracks` AS t
  ON
    s.vessel_rnpa = t.vessel_rnpa
    AND t.datetime BETWEEN s.t_begin AND s.t_end
GROUP BY 1, 2, 3, 4
