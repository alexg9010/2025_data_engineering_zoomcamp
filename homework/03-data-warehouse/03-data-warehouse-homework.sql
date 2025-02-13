-- Create external table referring to gcs path
-- use PARQUET format (https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-parquet?hl=de)
CREATE OR REPLACE EXTERNAL TABLE `homework_dataset.external_yellow_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['https://storage.cloud.google.com/dezoomcamp_hw3_2025-123456/yellow_tripdata_2024-*.parquet']
);

-- Create a regular table in BQ using the Yellow Taxi Trip Records
CREATE OR REPLACE TABLE `homework_dataset.internal_yellow_tripdata` AS 
SELECT * FROM `homework_dataset.external_yellow_tripdata`;

-- Create a materialized table in BQ using the Yellow Taxi Trip Records
CREATE MATERIALIZED VIEW IF NOT EXISTS `homework_dataset.mv_yellow_tripdata` AS 
SELECT * FROM `homework_dataset.internal_yellow_tripdata`;



-- What is count of records for the 2024 Yellow Taxi Data?
SELECT COUNT(*) FROM `homework_dataset.internal_yellow_tripdata`;
-- 20332093

-- query the regular table to count the distinct number of PULocationIDs for the entire dataset on both the tables.
SELECT
    PULocationID,
    COUNT(1)
FROM 
    `homework_dataset.internal_yellow_tripdata`
GROUP BY
    PULocationID;
-- This query will process 155.12 MB when run.

-- query the materialized table to count the distinct number of PULocationIDs for the entire dataset on both the tables.
SELECT
    PULocationID,
    COUNT(1)
FROM 
    `homework_dataset.mv_yellow_tripdata`
GROUP BY
    PULocationID;
-- This query will process 155.12 MB when run.

-- query the external table to count the distinct number of PULocationIDs for the entire dataset on both the tables.
SELECT
    PULocationID,
    COUNT(1)
FROM 
    `homework_dataset.external_yellow_tripdata`
GROUP BY
    PULocationID;
-- This query will process 0 B when run.


-- query to retrieve the PULocationID from the internal table in BigQuery. 
SELECT
    PULocationID,
FROM 
    `homework_dataset.internal_yellow_tripdata`;
-- This query will process 155.12 MB when run.

-- query to retrieve the PULocationID and DOLocationID on the same table
SELECT
    PULocationID,
    DOLocationID,
FROM 
    `homework_dataset.internal_yellow_tripdata`;
-- This query will process 310.24 MB when run.

-- How many records have a fare_amount of 0?
SELECT
  COUNT(1)
FROM
    `homework_dataset.internal_yellow_tripdata`
WHERE
  fare_amount = 0;
-- 8333

-- What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

-- Creating a partition on dropoff time and cluster table by VendorID, will be best since we filter on a single column
CREATE OR REPLACE TABLE `homework_dataset.yellow_tripdata_partitioned_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `homework_dataset.external_yellow_tripdata`;

-- test query on regular table
SELECT
    t.tpep_dropoff_datetime,
    t.VendorID
FROM
    `homework_dataset.internal_yellow_tripdata` t
WHERE
    DATE(tpep_dropoff_datetime) BETWEEN '2024-01-01' AND '2024-01-31';
--- This query will process 310.24 MB when run.

-- test query on partioned-clustered table
SELECT
    t.tpep_dropoff_datetime,
    t.VendorID
FROM
    `homework_dataset.yellow_tripdata_partitioned_clustered` t
WHERE
    DATE(tpep_dropoff_datetime) BETWEEN '2024-01-01' AND '2024-01-31';
--- This query will process 45.23 MB when run.


-- query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive)
SELECT
    t.VendorID
FROM
    `homework_dataset.yellow_tripdata_partitioned_clustered` t
WHERE
    DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15'
GROUP BY
    VendorID;
-- This query will process 26.84 MB when run

SELECT
    t.VendorID
FROM
    `homework_dataset.internal_yellow_tripdata` t
WHERE
    DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15'
GROUP BY
    VendorID;
-- This query will process 310.24 MB when run.


-- count row numbers from regular table
SELECT count(*) FROM `homework_dataset.internal_yellow_tripdata`;

-- count row numbers from materialized table
SELECT count(*) FROM `homework_dataset.mv_yellow_tripdata`;

-- count row numbers from external table
SELECT count(*) FROM `homework_dataset.external_yellow_tripdata`;
