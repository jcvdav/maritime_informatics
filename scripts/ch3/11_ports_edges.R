# Get 2024 VMS tracks for tuna longline vessels from BigQuery,
# convert to sf, and export as CSV with WKT geometry.

pacman::p_load(
  DBI,
  bigrquery,
  tidyverse,
  sf
)

# Authenticate and connect to the mex_vms dataset in BigQuery
bq_auth("juancarlos.villader@gmail.com")

mex_vms <- dbConnect(drv = bigquery(),
                     project = "mex-fisheries",
                     billing = "mex-fisheries",
                     dataset = "maritime_informatics")

# Create lazy references to the vessel info and VMS tables
edges <- tbl(mex_vms, "edges")

local <- edges |> 
  collect() |> 
  st_as_sf(wkt = "straight_edge",
           crs = "EPSG:4326")

coast <- rnaturalearth::ne_countries()

mapview::mapview(list(local, coast))
mapview::mapview()
