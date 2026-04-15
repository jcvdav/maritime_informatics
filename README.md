# maritime_informatics

Notes and exercises related to "Guide to Maritime Informatics" by Artikis and Zissis

From chapter 3:

- [x] Load vessel tarcking data to BigQuery, but have lat/lon be listed as `ST_POINT()` in the schema
- [x] Build Voronoi tessellation of `mex_ports` locally, upload to BigQuery as WKT
- [x] Use SQL to perform a spatial filter for vessels operating in different "area of influences of ports". Check whether this can be done with `dplyr` verbs too.
