## Module 3 Homework

ATTENTION: At the end of the submission form, you will be required to include a link to your GitHub repository or other public code-hosting site. 
This repository should contain your code for solving the homework. If your solution includes code that is not in file format (such as SQL queries or 
shell commands), please include these directly in the README file of your repository.

<b><u>Important Note:</b></u> <p> For this homework we will be using the Yellow Taxi Trip Records for **January 2024 - June 2024 NOT the entire year of data** 
Parquet Files from the New York
City Taxi Data found here: </br> https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page </br>
If you are using orchestration such as Kestra, Mage, Airflow or Prefect etc. do not load the data into Big Query using the orchestrator.</br> 
Stop with loading the files into a bucket. </br></br>

**Load Script:** You can manually download the parquet files and upload them to your GCS Bucket or you can use the linked script [here](./load_yellow_taxi_data.py):<br>
You will simply need to generate a Service Account with GCS Admin Priveleges or be authenticated with the Google SDK and update the bucket name in the script to the name of your bucket<br>
Nothing is fool proof so make sure that all 6 files show in your GCS Bucket before begining.</br><br>

### Prepare Bucket

#### Use micromamba to create a conda environment

Setup a conda environment that contains `terraform` and the required python packages (`google-cloud-storage`).

```sh
micromamba create -f environment.yaml
micromamba activate 03-data-warehouse-homework
```

#### Use terraform to create a GCS bucket
Follow the [docs](https://cloud.google.com/storage/docs/terraform-create-bucket-upload-object?hl=de#local-shell) to prepare your GCS bucket.

Create a terraform directory that contains [main.tf](./terraform/main.tf) and [variables.tf](./terraform/variables.tf) with your global unique project and bucket name.

Then run the following commands to initialize, plan and apply the terraform configuration.

```sh
terraform -chdir=terraform/ init 
terraform -chdir=terraform/ plan
terraform -chdir=terraform/ apply
```


#### Use the script to load the data into your GCS Bucket
```sh
gcloud auth application-default login
python load_yellow_taxi_data.py
```


#### Use terraform to destroy your GCS bucket after you are done
```sh
terraform -chdir=terraform/ destroy
```

### Prepare Big Query SQL Queries

<u>NOTE:</u> You will need to use the PARQUET option files when creating an External Table</br>

<b>BIG QUERY SETUP:</b></br>
Create an external table using the Yellow Taxi Trip Records. </br>

```sql
-- Creating external table referring to gcs path
-- use PARQUET format (https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-parquet?hl=de)
CREATE OR REPLACE EXTERNAL TABLE `homework_dataset.external_yellow_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['https://storage.cloud.google.com/dezoomcamp_hw3_2025-123456/yellow_tripdata_2024-*.parquet']
);
```


Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table). </br>

```sql
-- Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records
CREATE OR REPLACE TABLE `homework_dataset.internal_yellow_tripdata` AS 
SELECT * FROM `homework_dataset.external_yellow_tripdata`;

-- Create a materialized table in BQ using the Yellow Taxi Trip Records
CREATE MATERIALIZED VIEW IF NOT EXISTS `homework_dataset.mv_yellow_tripdata` AS 
SELECT * FROM `homework_dataset.internal_yellow_tripdata`;
```


</p>

## Question 1:
Question 1: What is count of records for the 2024 Yellow Taxi Data?
- 65,623
- 840,402
- **20,332,093** <<-
- 85,431,289

### Solution:

```sql
SELECT COUNT(*) FROM `homework_dataset.internal_yellow_tripdata`;
```
> 20332093


## Question 2:
Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.</br> 
What is the **estimated amount** of data that will be read when this query is executed on the External Table and the Table?

- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- **0 MB for the External Table and 155.12 MB for the Materialized Table** <<-- 
- 2.14 GB for the External Table and 0MB for the Materialized Table
- 0 MB for the External Table and 0MB for the Materialized Table

### Solution:

```sql
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
```

## Question 3:
Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table. Why are the estimated number of Bytes different?
- **BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires 
reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.** <<-- 
- BigQuery duplicates data across multiple storage partitions, so selecting two columns instead of one requires scanning the table twice, 
doubling the estimated bytes processed.
- BigQuery automatically caches the first queried column, so adding a second column increases processing time but does not affect the estimated bytes scanned.
- When selecting multiple columns, BigQuery performs an implicit join operation between them, increasing the estimated bytes processed

### Solution:

```sql
-- query to retrieve the PULocationID from the internal table in BigQuery. 
SELECT
    PULocationID,
FROM 
    `homework_dataset.internal_yellow_tripdata`;
-- This query will process 155.12 MB when run.

-- query to retrieve the PULocationID and DOLocationID on the same table
SELECT
    PULocationID,
    DOLocationID
FROM 
    `homework_dataset.internal_yellow_tripdata`;
-- This query will process 310.24 MB when run.
```

## Question 4:
How many records have a fare_amount of 0?
- 128,210
- 546,578
- 20,188,016
- **8,333** <<--

### Solution:

```sql
-- How many records have a fare_amount of 0?
SELECT
  COUNT(1)
FROM
    `homework_dataset.internal_yellow_tripdata`
WHERE
  fare_amount = 0;
-- 8333
```


## Question 5:
What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)
- **Partition by tpep_dropoff_datetime and Cluster on VendorID** <<--
- Cluster on by tpep_dropoff_datetime and Cluster on VendorID
- Cluster on tpep_dropoff_datetime Partition by VendorID
- Partition by tpep_dropoff_datetime and Partition by VendorID

### Solution:

```sql
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

```


## Question 6:
Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime
2024-03-01 and 2024-03-15 (inclusive)</br>

Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values? </br>

Choose the answer which most closely matches.</br> 

- 12.47 MB for non-partitioned table and 326.42 MB for the partitioned table
- **310.24 MB for non-partitioned table and 26.84 MB for the partitioned table** <<-- 
- 5.87 MB for non-partitioned table and 0 MB for the partitioned table
- 310.31 MB for non-partitioned table and 285.64 MB for the partitioned table

```sql
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
```

## Question 7: 
Where is the data stored in the External Table you created?

- Big Query
- Container Registry
- **GCP Bucket** <<--
- Big Table

### Solution:

The external table is not saved in Big Query, the data stays in the GCP bucket.

## Question 8:
It is best practice in Big Query to always cluster your data:
- True
- **False** <<-- 

### Solution:

This depends on the data and the query. Clustering can improve query performance for certain types of queries, but it can also increase storage and processing costs. Especially for small datasets, clustering may not be necessary and can even decrease performance.

## (Bonus: Not worth points) Question 9:
No Points: Write a `SELECT count(*)` query FROM the materialized table you created. How many bytes does it estimate will be read? Why?



## Submitting the solutions

Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw3