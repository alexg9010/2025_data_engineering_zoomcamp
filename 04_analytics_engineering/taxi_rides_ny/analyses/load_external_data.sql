-- Create external table referring to gcs path
-- use PARQUET format (https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-parquet?hl=de)
CREATE OR REPLACE EXTERNAL TABLE `trips_data_all.green_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['https://storage.cloud.google.com/dezoomcamp-dbt--451819-bucket/green/green_tripdata_2019-*.parquet']
);

-- Create external table referring to gcs path
-- use PARQUET format (https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-parquet?hl=de)
CREATE OR REPLACE EXTERNAL TABLE `trips_data_all.yellow_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['https://storage.cloud.google.com/dezoomcamp-dbt--451819-bucket/yellow/yellow_tripdata_2019-*.parquet']
);

-- Create external table referring to gcs path
-- use PARQUET format (https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-parquet?hl=de)
CREATE OR REPLACE EXTERNAL TABLE `trips_data_all.fhv_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['https://storage.cloud.google.com/dezoomcamp-dbt--451819-bucket/fhv/fhv_tripdata_2019-*.parquet']
);