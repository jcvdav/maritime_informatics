CREATE OR REPLACE TABLE `mex-fisheries.maritime_informatics.tracks`
AS
SELECT
  vessel_rnpa,
  cid AS start_cid,
  next_cid AS end_cid,
  t_end AS t_start,
  next_t_begin AS t_end
FROM
  (
    SELECT
      vessel_rnpa,
      cid,
      t_end,
      LEAD(cid) OVER (PARTITION BY vessel_rnpa ORDER BY t_begin) AS next_cid,
      LEAD(t_begin)
        OVER (PARTITION BY vessel_rnpa ORDER BY t_begin) AS next_t_begin
    FROM `mex-fisheries.maritime_informatics.cluster_stops`
  )
WHERE next_cid IS NOT NULL;

-- Step 2: Add the geography column
ALTER TABLE `mex-fisheries.maritime_informatics.tracks`
  ADD COLUMN IF NOT EXISTS route_line GEOGRAPHY;

-- Step 3: Update the table using a JOIN (de-correlated)
UPDATE `mex-fisheries.maritime_informatics.tracks` t
SET route_line = aggregated_lines.line
FROM
  (
    SELECT
      t.vessel_rnpa,
      t.start_cid,
      ST_MAKELINE(ARRAY_AGG(p.geography ORDER BY p.datetime)) AS line
    FROM `mex-fisheries.maritime_informatics.tracks` t
    JOIN `mex-fisheries.maritime_informatics.longline_tracks` p
      ON
        p.vessel_rnpa = t.vessel_rnpa
        AND p.datetime >= t.t_start
        AND p.datetime <= t.t_end
    GROUP BY 1, 2
  ) AS aggregated_lines
WHERE
  t.vessel_rnpa = aggregated_lines.vessel_rnpa
  AND t.start_cid = aggregated_lines.start_cid;

