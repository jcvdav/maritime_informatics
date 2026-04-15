# Upload CSVs with WKT geometry to BigQuery.
# The WKT column is automatically parsed as a GEOGRAPHY type.
# Uses --replace to overwrite existing tables.

### Load longline tracks (from 01_get_longline_tracks.R)
bq load --replace --source_format=CSV \
  --skip_leading_rows=1 \
  --schema="vessel_rnpa:STRING,datetime:TIMESTAMP,geography:GEOGRAPHY" \
  maritime_informatics.longline_tracks data/processed/longline_tracks_wkt.csv

### Load voronoi ports (from 02_voronoi_tesselation.R)
bq load --replace --source_format=CSV \
  --skip_leading_rows=1 \
  --schema="port_name:STRING,port_id:STRING,geography:GEOGRAPHY" \
  maritime_informatics.voronoi_ports data/processed/voronoi_ports_wkt.csv
  