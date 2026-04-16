# Exploratory queries on longline tracks and port Voronoi regions in BigQuery.
# Examples of spatial filtering using ST_INTERSECTS with dplyr and raw SQL.

pacman::p_load(
  DBI,
  bigrquery,
  tidyverse,
  sf
)

# Connect to BigQuery
bq_auth("juancarlos.villader@gmail.com")

maritime_informatics <- dbConnect(drv = bigquery(),
                                  project = "mex-fisheries",
                                  billing = "mex-fisheries",
                                  dataset = "maritime_informatics")

# Load table references
tracks <- tbl(maritime_informatics, "longline_tracks")
ports <- tbl(maritime_informatics, "voronoi_ports")

# A few tests...

# 1) Can I just bring down data and convert to sf?
local_ports <- ports |> 
  collect() |> 
  st_as_sf(wkt = "geography",
           crs = "EPSG:4326") # I know it's stored as 4326

plot(local_ports, max.plot = 1) # yes

# 2) How about doing spatial computations on the cloud?
# Calculate area of each port's Voronoi region
# And then get ports with an area of influence > 100 km2
# This computation is done in the cloud
large_areas <- ports |> 
  mutate(area = ST_AREA(geography) / 1e6) |>  # See https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/geography_functions#st_area
  filter(area > 100000) |> 
  collect()

large_areas |> 
  st_as_sf(wkt = "geography",
           crs = "EPSG:4326") |> 
  ggplot(aes(fill = area)) + 
  geom_sf()

# Yep... that works

  
# 3) Now find vessels inside port 04002 (CAYO DE ARCAS) using dplyr with spatial filter
# There are five ways of doing this.
# a) Type things in BigQuery, but not very reproducible (not shown in repo)
# b) Write the query locally, execute via bq query < scripts/ch3/04_vessels_inside_area.sql (see sql script)
# c) Execute the query from within R. This is a bit annoying, but it works:
# d) Combine dplyr verbs as much as possible, and swith to SQL when needed
# e) Use a crossjoin. This is flexible to multiple ports being used.

# This is approach c: Run the query via R
sql('SELECT DISTINCT vessel_rnpa
FROM `mex-fisheries.maritime_informatics.longline_tracks`
WHERE
  ST_INTERSECTS(
    geography,
    (
      SELECT geography
      FROM `mex-fisheries.maritime_informatics.voronoi_ports`
      WHERE port_id = "04002"
    ))') |> 
  dbGetQuery(conn = maritime_informatics)

# This is approach d: Write MOST of it in R, but some must be written in SQL
tracks |> 
  filter(ST_INTERSECTS(geography,
                       sql('(SELECT geography
                              FROM `mex-fisheries.maritime_informatics.voronoi_ports`
             WHERE port_id = "04002")'))) |> 
  select(vessel_rnpa) |> 
  distinct()

# Final option... use a cross-join and two lazy tables
# First define the object that contains the geometry
target_port <- ports |> 
  filter(port_id %in% c("04002", "30010", "04009")) |> 
  select(port_geography = geography)

# Then perform a cross join. Once they are together, perform the spatial intersection.
tracks |>
  cross_join(target_port) |>
  filter(ST_INTERSECTS(geography, port_geography)) |>
  select(vessel_rnpa) |>
  distinct()






