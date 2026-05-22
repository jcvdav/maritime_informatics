CREATE OR REPLACE TABLE `mex-fisheries.maritime_informatics.cluster_centroids` AS 
SELECT cid, ST_CENTROID_AGG(centroid) AS centroid
FROM
  `mex-fisheries.maritime_informatics.cluster_stops`
GROUP BY cid

