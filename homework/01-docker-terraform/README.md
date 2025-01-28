
# Module 1 Homework: Docker & SQL

In this homework we'll prepare the environment and practice
Docker and SQL

When submitting your homework, you will also need to include
a link to your GitHub repository or other public code-hosting
site.

This repository should contain the code for solving the homework. 

When your solution has SQL or shell commands and not code
(e.g. python files) file format, include them directly in
the README file of your repository.


## Question 1. Understanding docker first run 

Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of `pip` in the image?

- **24.3.1 <<-**
- 24.2.1
- 23.3.1
- 23.2.1

### Solution

```bash
docker run -it  python:3.12.8 /bin/bash -c 'pip --version' 
#>  pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)

```

## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that **pgadmin** should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- **db:5432 <<-**

If there are more than one answers, select only one of them

### Solution

The port mapping inside the `docker-compose.yaml` is defined as `HOST_PORT:CONTAINER_PORT`, thus within the container the port is `5432`. The hostname of the postgress database is `db`.

##  Prepare Postgres

Run Postgres and load data as shown in the videos
We'll use the green taxi trips from October 2019:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
```

You will also need the dataset with zones:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Download this data and put it into Postgres.

You can use the code from the course. It's up to you whether
you want to use Jupyter or a python script.

### Ingest taxi trips from October 2019 

update ingest_data.py to: 
- use 'lpep' instead of 'tpep' prefix
- skip datetime conversion if lepp_pickup_datetime is not in data

build new image with newer version of ingest_data.py

```bash
docker build -t ingest_data:v02 .
```

start postgres container

```bash 
 docker run --rm -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network pg-network \
  --name pg-database \
  postgres:13
```

ingest data

```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz"

docker run \
  --network="pg-network" \
    -it ingest_data:v02 \
  --user="root" \
  --password="root" \
  --host="pg-database" \
  --port="5432" \
  --db="ny_taxi" \
  --table="green_taxi_trips" \
  --url=${URL}
```

```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv"

docker run \
  --network="pg-network" \
    -it ingest_data:v02 \
  --user="root" \
  --password="root" \
  --host="pg-database" \
  --port="5432" \
  --db="ny_taxi" \
  --table="zones" \
  --url=${URL}
```



## Question 3. Trip Segmentation Count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
1. Up to 1 mile
2. In between 1 (exclusive) and 3 miles (inclusive),
3. In between 3 (exclusive) and 7 miles (inclusive),
4. In between 7 (exclusive) and 10 miles (inclusive),
5. Over 10 miles 

Answers:

- 104,802;  197,670;  110,612;  27,831;  35,281 
- **104,802;  198,924;  109,603;  27,678;  35,189** <<-
- 104,793;  201,407;  110,612;  27,831;  35,281
- 104,793;  202,661;  109,603;  27,678;  35,189
- 104,838;  199,013;  109,645;  27,688;  35,202


### Solution

Add the 

```sql
-- 0. query the period, and extract the trip_distance
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  CAST(lpep_dropoff_datetime AS DATE) AS "dropoff_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
WHERE
	CAST(lpep_pickup_datetime AS DATE) >= '2019-10-01' AND
	CAST(lpep_dropoff_datetime AS DATE) < '2019-11-01'
LIMIT 100;
```

```sql
-- 1. Up to 1 mile
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  CAST(lpep_dropoff_datetime AS DATE) AS "dropoff_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
WHERE
	CAST(lpep_pickup_datetime AS DATE) >= '2019-10-01' AND
	CAST(lpep_dropoff_datetime AS DATE) < '2019-11-01'
	trip_distance <= 1
ORDER BY
    "distance" DESC
```

--> 104,802

```sql
-- 2. In between 1 (exclusive) and 3 miles (inclusive),
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  CAST(lpep_dropoff_datetime AS DATE) AS "dropoff_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
WHERE
	CAST(lpep_pickup_datetime AS DATE) >= '2019-10-01' AND
	CAST(lpep_dropoff_datetime AS DATE) < '2019-11-01' AND
	trip_distance > 1 AND trip_distance <= 3
ORDER BY
    "distance" DESC
```
--> 198,924

```sql
-- 3. In between 3 (exclusive) and 7 miles (inclusive),
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  CAST(lpep_dropoff_datetime AS DATE) AS "dropoff_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
WHERE
	CAST(lpep_pickup_datetime AS DATE) >= '2019-10-01' AND
	CAST(lpep_dropoff_datetime AS DATE) < '2019-11-01' AND
	trip_distance > 3 AND trip_distance <= 7
ORDER BY
    "distance" DESC
```

--> 109,603 

```sql
-- 4. In between 7 (exclusive) and 10 miles (inclusive),
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  CAST(lpep_dropoff_datetime AS DATE) AS "dropoff_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
WHERE
	CAST(lpep_pickup_datetime AS DATE) >= '2019-10-01' AND
	CAST(lpep_dropoff_datetime AS DATE) < '2019-11-01' AND
	trip_distance > 7 AND trip_distance <= 10
ORDER BY
    "distance" DESC
```

--> 27,678

```sql
-- 5. Over 10 miles 
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  CAST(lpep_dropoff_datetime AS DATE) AS "dropoff_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
WHERE
	CAST(lpep_pickup_datetime AS DATE) >= '2019-10-01' AND
	CAST(lpep_dropoff_datetime AS DATE) < '2019-11-01' AND
	trip_distance > 10
ORDER BY
    "distance" DESC
```

--> 35,189


## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance?
Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance. 

- 2019-10-11
- 2019-10-24
- 2019-10-26
- **2019-10-31** <<-


### Solution

```sql
-- pick up day with the longest trip distance
SELECT
  CAST(lpep_pickup_datetime AS DATE) AS "pickup_day",
  trip_distance AS "distance"
FROM 
	green_taxi_trips t 
ORDER BY
    "distance" DESC

```

## Question 5. Three biggest pickup zones

Which were the top pickup locations with over 13,000 in
`total_amount` (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.
 
- **East Harlem North, East Harlem South, Morningside Heights**  <<-
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park

### Solution

in addition to the functions learned in the sql-refresher, we can use the `HAVING`  filter after the  `GROUP BY`. 

```sql
SELECT
    SUM(total_amount) AS "sum_total_amount",
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc"
FROM 
    green_taxi_trips t
JOIN 
    zones zpu ON t."PULocationID" = zpu."LocationID"
WHERE
	CAST(lpep_pickup_datetime AS DATE) = '2019-10-18'
GROUP BY
	"pickup_loc"
HAVING SUM(total_amount) > 13000
ORDER BY
    "sum_total_amount" DESC
LIMIT
    10
```

## Question 6. Largest tip

For the passengers picked up in October 2019 in the zone
named "East Harlem North" which was the drop off zone that had
the largest tip?

Note: it's `tip` , not `trip`

We need the name of the zone, not the ID.

- Yorkville West
- **JFK Airport** <<-
- East Harlem North
- East Harlem South


### Solution

```sql
SELECT
    tip_amount,
    zpu."Zone" AS "pickup_loc",
    zdo."Zone" AS "dropoff_loc"
FROM 
    green_taxi_trips t
JOIN 
    zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN
    zones zdo ON t."DOLocationID" = zdo."LocationID" 
WHERE
	zpu."Zone" = 'East Harlem North'
GROUP BY
	"dropoff_loc", "pickup_loc", tip_amount
ORDER BY
    tip_amount DESC
LIMIT
    10
```

## Terraform

In this section homework we'll prepare the environment by creating resources in GCP with Terraform.

In your VM on GCP/Laptop/GitHub Codespace install Terraform. 
Copy the files from the course repo
[here](../../../01-docker-terraform/1_terraform_gcp/terraform) to your VM/Laptop/GitHub Codespace.

Modify the files as necessary to create a GCP Bucket and Big Query Dataset.

### Solution

see [01_3_terraform_gcp/terrademo](../../01_3_terraform/terrademo/)


## Question 7. Terraform Workflow

Which of the following sequences, **respectively**, describes the workflow for: 
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- **terraform init, terraform apply -auto-approve, terraform destroy** <<-
- terraform import, terraform apply -y, terraform rm


## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw1