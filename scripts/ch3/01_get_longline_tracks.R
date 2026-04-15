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
                     dataset = "mex_vms")

# Create lazy references to the vessel info and VMS tables
info <- tbl(mex_vms, "vessel_info_latest")
vms <- tbl(mex_vms, "mex_vms_processed_latest")

# Filter for vessels that target tuna (not shark) using longline (not purse seine)
tuna_longline <- info |>
  filter(target_tuna == 1, target_shark == 0,
         gear_longline == 1, gear_purse_seine == 0) |>
  select(vessel_rnpa) |>
  distinct()

# Join VMS positions to the tuna longline fleet and pull 2024 data locally
tracks <- vms |>
  inner_join(tuna_longline, by = join_by("vessel_rnpa")) |>
  filter(year == 2024) |>
  select(vessel_rnpa, datetime, lon, lat) |>
  collect()

# Convert to sf points with WGS84 projection
tracks_sf <- tracks |>
  st_as_sf(coords = c("lon", "lat"),
           crs = "EPSG:4326")

# Convert geometry to WKT text and drop the sf geometry column.
# BigQuery can ingest WKT as a GEOGRAPHY column (see 03_load_wkt.sh).
tracks_wkt <- tracks_sf |>
  mutate(geography = st_as_text(geometry)) |>
  st_drop_geometry()

write_csv(x = tracks_wkt, file = here::here("data/processed/longline_tracks_wkt.csv"))



