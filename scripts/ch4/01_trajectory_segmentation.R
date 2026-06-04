################################################################################
# title
################################################################################
#
# Juan Carlos Villaseñor-Derbez
# jc_villasenor@miami.edu
# date
#
# Description
#
################################################################################
  
# SET UP #######################################################################

## Load packages ---------------------------------------------------------------
pacman::p_load(
  DBI,
  bigrquery,
  tidyverse,
  sf,
  mapview
)

## Load data -------------------------------------------------------------------

# Connect to BigQuery
bq_auth("juancarlos.villader@gmail.com")

get_angle <- function(geom1, geom2) {
  coord1 <- st_coordinates(geom1)
  coord2 <- st_coordinates(geom2)
}

maritime_informatics <- dbConnect(drv = bigquery(),
                                  project = "mex-fisheries",
                                  billing = "mex-fisheries",
                                  dataset = "maritime_informatics")

get_angle <- function(geog1, geog2) {
  if(is.na(geog2)) {
    return(NA)
  } else {
    lwgeom::st_geod_azimuth(c(geog1, geog2)) |> 
      units::set_units("degrees")
  }
}

# Load table references
tracks <- tbl(maritime_informatics, "longline_tracks")

vessel <- tracks |> 
  filter(vessel_rnpa == "00066001",
         sql("EXTRACT(YEAR FROM datetime) = 2024")) |> 
  arrange(datetime) |> 
  select(-vessel_rnpa) |> 
  collect() |> 
  st_as_sf(wkt = "geography",
           crs = "EPSG:4326") |> 
  mutate(distance = st_distance(geography, lag(geography), by_element = T),
         time = c(NA, diff(datetime)),
         angle = c(NA, units::set_units(st_geod_azimuth(geography), "degrees"))) |> 
  mutate_at(.vars = c("distance", "angle", "time"), as.numeric)

mapview(vessel)

dt <- ggplot(data = vessel,
             aes(x = time)) +
  geom_histogram() +
  labs(x = "Time (seconds)")

ds <- ggplot(data = vessel,
             aes(x = distance)) +
  geom_histogram() +
  labs(x = "Distance (m)")

speed <- ggplot(data = vessel,
                aes(x = implied_speed_knots)) +
  geom_histogram() +
  labs(x = "Speed (knots)")

angle <- ggplot(data = vessel,
                aes(x = angle)) +
  geom_histogram() +
  labs(x = "Angle")


cowplot::plot_grid(dt, ds, speed, angle)

# PROCESSING ###################################################################

## Split based on raw gaps -----------------------------------------------------
gaps <- vessel |> 
  drop_na() |> 
  mutate(seg_t = (time > 3600),
         seg_d = (distance > 20000),
         seg = cumsum(1 * (seg_t | seg_d))) 

mapview(gaps, zcol = "seg")

## Split based on correlation --------------------------------------------------
time <- ggplot(vessel,
               aes(x = datetime,
                   y = time)) +
  geom_line() +
  geom_point()

dist <- ggplot(vessel,
               aes(x = datetime,
                   y = distance)) +
  geom_line() +
  geom_point()

speed <- ggplot(vessel,
                aes(x = datetime,
                    y = implied_speed_knots)) +
  geom_line() +
  geom_point()

angle <- ggplot(vessel,
                aes(x = datetime,
                    y = angle)) +
  geom_line() +
  geom_point()

cowplot::plot_grid(time, dist, speed, angle)

## Split based on stop detection -----------------------------------------------

clusters <- vessel |> 
  select(geography) |> 
  st_transform("ESRI:54009") |> 
  st_coordinates() |> 
  dbscan::dbscan(minPts = 10, eps = 500)

stops <- vessel |> 
  mutate(cluster = clusters$cluster) |> 
  filter(cluster > 0)

mapview(stops, zcol = "cluster")

stops_clusters <- vessel |> 
  mutate(cluster = clusters$cluster,
         seg = cumsum(cluster != lead(cluster)))


mapview(stops_clusters, zcol = "seg")

# VISUALIZE ####################################################################

## Another step ----------------------------------------------------------------


# EXPORT #######################################################################

## The final step --------------------------------------------------------------
  