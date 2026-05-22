# Upload CSVs with WKT geometry to BigQuery.
# The WKT column is automatically parsed as a GEOGRAPHY type.
# Uses --replace to overwrite existing tables.

# 1. Delete the existing table to apply the new schema and null marker
#bq rm -f maritime_informatics.longline_tracks

# 2. Reload with the null_marker flag
bq load --source_format=CSV \
  --skip_leading_rows=1 \
  --null_marker="NA" \
  --time_partitioning_field=datetime \
  --time_partitioning_type=DAY \
  --clustering_fields=vessel_rnpa,datetime \
  --schema="vessel_rnpa:STRING,datetime:TIMESTAMP,implied_speed_knots:FLOAT64,geography:GEOGRAPHY" \
  maritime_informatics.longline_tracks data/processed/longline_tracks_wkt.csv



### Load voronoi ports (from 02_voronoi_tesselation.R)
bq load --replace --source_format=CSV \
  --skip_leading_rows=1 \
  --schema="port_name:STRING,port_id:STRING,geography:GEOGRAPHY" \
  maritime_informatics.voronoi_ports data/processed/voronoi_ports_wkt.csv
  