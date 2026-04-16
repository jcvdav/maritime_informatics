# Build Voronoi tessellation around Mexican ports, clipped to fishing regions
# using st_intersection. Assigns each polygon to its nearest port.

library(rnaturalearth)
library(sf)
library(tidyverse)

# Read ports from the mex_ports repo and project to EPSG:6372 (Mexico-specific
# equal-area CRS) so Voronoi cells are computed in meters, not degrees.
mex_ports_sf <- st_read("https://github.com/mex-fisheries/mex_ports/raw/refs/heads/main/data/clean/mex_ports.gpkg",
                        quiet = TRUE) |>
  st_transform(crs = "EPSG:6372") |>
  select(port_name, port_id)

# Load fishing regions and dissolve into a single boundary polygon
mex_fishing_regions <- st_read(here::here("data/raw/mexico_fishing_regions.gpkg")) |>
  st_transform(crs = "EPSG:6372") |>
  st_union()

# Build Voronoi polygons from port points, clip to fishing regions, and
# rejoin port attributes by nearest feature (since st_voronoi loses them).
voronoi <- mex_ports_sf |>
  st_union() |>
  st_voronoi() |>
  st_collection_extract() |>
  st_crop(mex_fishing_regions) |>
  st_as_sf() |>
  rename(geometry = x) |>
  st_join(mex_ports_sf, st_nearest_feature)

# Save as geopackage and as CSV with WKT (for BigQuery upload)
write_sf(obj = voronoi, dsn = here::here("data", "processed", "voronoi_ports.gpkg"))
write_csv(x = voronoi |>
            st_transform(crs = "EPSG:4326") |>
            st_make_valid() |> 
            mutate(geography = st_as_text(geometry)) |>
            st_drop_geometry(),
          file = here::here("data", "processed", "voronoi_ports_wkt.csv"))


