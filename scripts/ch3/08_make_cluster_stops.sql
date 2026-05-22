CREATE OR REPLACE TABLE `mex-fisheries.maritime_informatics.cluster_stops`
AS
SELECT *
FROM
  (
    SELECT
      *, ST_CLUSTERDBSCAN(centroid, 10000, 5) OVER () AS cid
    FROM `mex-fisheries.maritime_informatics.stops`
    WHERE duration_s >= 3600 * 12
  )
WHERE cid IS NOT NULL
