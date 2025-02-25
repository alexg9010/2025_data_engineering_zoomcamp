# Notes

next lesson: [01_3_terraform](../01_3_terraform/README.md)

- [Notes](#notes)
  - [Local environment management](#local-environment-management)
  - [1.2.1 Intro to Docker](#121-intro-to-docker)
    - [Creating a custom pipeline with Docker](#creating-a-custom-pipeline-with-docker)
  - [1.2.3 Connect Postgres via PgAdmin](#123-connect-postgres-via-pgadmin)
    - [install pgAdmin](#install-pgadmin)
    - [docker create network](#docker-create-network)
    - [Explore database](#explore-database)
    - [Fix broken Postgress Docker container](#fix-broken-postgress-docker-container)
  - [1.2.4 Dockerize Ingestion Script](#124-dockerize-ingestion-script)
    - [Pandas v2.2.3 error](#pandas-v223-error)
    - [Write Dockerfile](#write-dockerfile)
    - [Run in postgres network](#run-in-postgres-network)
      - [Upload taxi zones to postgres](#upload-taxi-zones-to-postgres)
  - [1.2.5 Running Postgres and pgAdmin with Docker-Compose](#125-running-postgres-and-pgadmin-with-docker-compose)
    - [Safe connected servers](#safe-connected-servers)
  - [1.2.6 SQL Refresher](#126-sql-refresher)
    - [Important functions](#important-functions)
  - [1.5.1 Port Mapping and Networks in Docker](#151-port-mapping-and-networks-in-docker)




## Local environment management

I use [micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html) to manage my local environment: 

Environment is defined in `environment.yaml`.Folder basename (`$(basename $PWD)`) is used as environment name.

This allows to use distinct environment for every folder in the project.

Environment is created with:

```bash
micromamba env create -f environment.yaml
micromamba activate $(basename $PWD`
```

This can be used together with [direnv](https://direnv.net/) to automatically activate the environment when entering a folder. See [direnv-automamba](https://github.com/zoof/direnv-automamba/tree/main). 

Add this to your global direnvrc (`$HOME/.config/direnv/direnvrc`):

```bash
# https://github.com/zoof/direnv-automamba/blob/main/.direnvrc
layout_mamba() {
  # initialize micromamba
  eval "$(micromamba shell hook --shell=zsh)"

  # check if environment name is specified
  if [ -n "$1" ]; then
    # Explicit environment name from layout command.
    local env_name="$1"
    # activate environment
    micromamba activate ${env_name}
  elif (grep -q name: environment.y*ml 2> /dev/null); then
    # Detect environment name from `environment.yml` file in `.envrc` directory
    micromamba activate `grep name: environment.y*ml | sed -e 's/name: //'`
  else
    # if all else fails, activate base environment
    micromamba activate base;
  fi;
}
```


## 1.2.1 Intro to Docker
![alt text](image.png)

_([Video source](https://www.youtube.com/watch?v=EYNwNlOrpr0&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=3))_

### Creating a custom pipeline with Docker

_([Video source](https://www.youtube.com/watch?v=EYNwNlOrpr0&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=3))_

Let's create an example pipeline. We will create a dummy `pipeline.py` Python script that receives an argument and prints it.

```python
import sys
import pandas # we don't need this but it's useful for the example

# print arguments
print(sys.argv)

# argument 0 is the name os the file
# argumment 1 contains the actual first argument we care about
day = sys.argv[1]

# cool pandas stuff goes here

# print a sentence with the argument
print(f'job finished successfully for day = {day}')
```

We can run this script with `python pipeline.py <some_number>` and it should print 2 lines:
* `['pipeline.py', '<some_number>']`
* `job finished successfully for day = <some_number>`

Let's containerize it by creating a Docker image. Create the folllowing `Dockerfile` file:

```dockerfile
# base Docker image that we will build on
FROM python:3.9.1

# set up our image by installing prerequisites; pandas in this case
RUN pip install pandas

# set up the working directory inside the container
WORKDIR /app
# copy the script to the container. 1st name is source file, 2nd is destination
COPY pipeline.py pipeline.py

# define what to do first when the container runs
# in this example, we will just run the script
ENTRYPOINT ["python", "pipeline.py"]
```

Let's build the image:


```ssh
docker build -t test:pandas .
```
* The image name will be `test` and its tag will be `pandas`. If the tag isn't specified it will default to `latest`.

We can now run the container and pass an argument to it, so that our pipeline will receive it:

```ssh
docker run -it test:pandas some_number
```

You should get the same output you did when you ran the pipeline script by itself.

>Note: these instructions asume that `pipeline.py` and `Dockerfile` are in the same directory. The Docker commands should also be run from the same directory as these files.

## 1.2.3 Connect Postgres via PgAdmin

### install pgAdmin

(pgAdmin)[https://www.pgadmin.org] is an open source management gui for postgres.

We can run it via (docker container)[https://www.pgadmin.org/download/pgadmin-4-container/] see (here)[https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html] for more information about the container.

Using this command will start pgAdmin and make it available at `http://localhost:8080/`.

```bash
docker run -it \
	-e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
	-e PGADMIN_DEFAULT_PASSWORD="root" \
	-p 8080:80 \
	dpage/pgadmin4
```

Now if we try to find the postgres server runnning from before, this will not work, since they are runnning in distinct containers, which do not see each other. 

A solution to let them see each other is to create a shared network in docker. 

### docker create network

```bash
docker network create pg-network
```


Start the postgres server and pgadmin in the same network:

```bash
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network pg-network \
  --name pg-database \
  --restart yes \
  postgres:13
```


```bash
docker run -it \
	-e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
	-e PGADMIN_DEFAULT_PASSWORD="root" \
	-p 8080:80 \
	--network pg-network \
  --name pgadmin \
  --rm \
	dpage/pgadmin4
```

### Explore database

In pgAdmin, we now move on to create a new server with connection to "pg-database".

Via rightclick on Servers, we first register a new server "Docker localhost", that connects to "pg-database" using the above credentials (see (video)[https://youtu.be/hCAIVe9N0ow?si=ughlrJBRoel4nKje&t=540]).

Then we can view the data via Servers > Docker localhost > ny_taxi > Schemas > Tables > rightclick yellow_taxi_data > View/edit data > first 100 rows.

### Fix broken Postgress Docker container 

I got this error when trying to start the postgress docker container. The container would directly shut down. The reason this happened is most likely an interruppted shutdown where the database could not save all progres. 

```bash
 docker run -it\
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network pg-network \
  postgres:13

PostgreSQL Database directory appears to contain a database; Skipping initialization

2025-01-22 19:30:47.213 UTC [1] LOG:  starting PostgreSQL 13.18 (Debian 13.18-1.pgdg120+1) on aarch64-unknown-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2025-01-22 19:30:47.213 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2025-01-22 19:30:47.213 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2025-01-22 19:30:47.216 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2025-01-22 19:30:47.221 UTC [27] LOG:  database system was shut down at 2025-01-20 09:32:42 UTC
2025-01-22 19:30:47.222 UTC [27] LOG:  could not read from log segment 00000001000000000000001B, offset 0: Resource deadlock avoided
2025-01-22 19:30:47.222 UTC [27] LOG:  invalid primary checkpoint record
2025-01-22 19:30:47.222 UTC [27] PANIC:  could not locate a valid checkpoint record
2025-01-22 19:30:47.222 UTC [1] LOG:  startup process (PID 27) was terminated by signal 6: Aborted
2025-01-22 19:30:47.222 UTC [1] LOG:  aborting startup due to startup process failure
2025-01-22 19:30:47.223 UTC [1] LOG:  database system is shut down
```

To fix this I had to enter the docker container and reset the write-ahead lock using pg_resetwal see https://stackoverflow.com/a/73339220. 

```bash 
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network pg-network \
  postgres:13 \
  /bin/bash -c 'gosu postgres pg_resetwal /var/lib/postgresql/data'
```


## 1.2.4 Dockerize Ingestion Script


```bash
jupyter nbconvert --to=script load_nyc_taxi_data_csv.ipynb 
```

We clean up the code and remove all the jupyter code and bash magic. 
We rename the script to `ingest_data.py` and add cli argument parsing via argparse.

We need to fetch the csv from [github](https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz) since trip records from the [original page](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)  have been converted to PARQUET format since 2022. 

```bash
# URL="https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2021-01.csv"
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

python ingest_data.py \
  --user="root" \
  --password="root" \
  --host="localhost" \
  --port="5432" \
  --db="ny_taxi" \
  --table="yellow_taxi_trips" \
  --url=${URL}
```

### Pandas v2.2.3 error 

When using python 3.9, with pandas version 2.2.3 I get this error: 

```
--2025-01-22 22:32:38--  https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz
Resolving github.com (github.com)... 140.82.121.3
Connecting to github.com (github.com)|140.82.121.3|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://objects.githubusercontent.com/github-production-release-asset-2e65be/513814948/f6895842-79e6-4a43-9458-e5b0b454a340?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=releaseassetproduction%2F20250122%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250122T213239Z&X-Amz-Expires=300&X-Amz-Signature=b29c2d45ee989c1457023561d070805ed0efb2e78f30a39e635b661259a12157&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3Dyellow_tripdata_2021-01.csv.gz&response-content-type=application%2Foctet-stream [following]
--2025-01-22 22:32:39--  https://objects.githubusercontent.com/github-production-release-asset-2e65be/513814948/f6895842-79e6-4a43-9458-e5b0b454a340?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=releaseassetproduction%2F20250122%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250122T213239Z&X-Amz-Expires=300&X-Amz-Signature=b29c2d45ee989c1457023561d070805ed0efb2e78f30a39e635b661259a12157&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3Dyellow_tripdata_2021-01.csv.gz&response-content-type=application%2Foctet-stream
Resolving objects.githubusercontent.com (objects.githubusercontent.com)... 185.199.110.133, 185.199.111.133, 185.199.108.133, ...
Connecting to objects.githubusercontent.com (objects.githubusercontent.com)|185.199.110.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 25031880 (24M) [application/octet-stream]
Saving to: ‘output.csv.gz’

output.csv.gz                                100%[==============================================================================================>]  23.87M  7.20MB/s    in 3.4s

/Users/agosdsc/Library/CloudStorage/OneDrive-Personal/Courses/2025_data_engineering_zoomcamp/01_docker/ingest_data.py:43: UserWarning: pandas only supports SQLAlchemy connectable (engine/connection) or database string URI or sqlite3 DBAPI2 connection. Other DBAPI2 objects are not tested. Please consider using SQLAlchemy.
  df.head(n=0).to_sql(name=table_name, con=engine, if_exists='replace')
Traceback (most recent call last):
  File "/Users/agosdsc/Library/CloudStorage/OneDrive-Personal/Courses/2025_data_engineering_zoomcamp/01_docker/ingest_data.py", line 89, in <module>
    main(args)
  File "/Users/agosdsc/Library/CloudStorage/OneDrive-Personal/Courses/2025_data_engineering_zoomcamp/01_docker/ingest_data.py", line 43, in main
    df.head(n=0).to_sql(name=table_name, con=engine, if_exists='replace')
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/util/_decorators.py", line 333, in wrapper
    return func(*args, **kwargs)
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/core/generic.py", line 3087, in to_sql
    return sql.to_sql(
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/io/sql.py", line 842, in to_sql
    return pandas_sql.to_sql(
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/io/sql.py", line 2850, in to_sql
    table.create()
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/io/sql.py", line 984, in create
    if self.exists():
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/io/sql.py", line 970, in exists
    return self.pd_sql.has_table(self.name, self.schema)
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/io/sql.py", line 2865, in has_table
    return len(self.execute(query, [name]).fetchall()) > 0
  File "/Users/agosdsc/micromamba/envs/de_zoomcamp_01_docker/lib/python3.9/site-packages/pandas/io/sql.py", line 2672, in execute
    cur = self.con.cursor()
AttributeError: 'Engine' object has no attribute 'cursor'
```

To resolve this I downgraded my version of pandas to pandas<=2, then everything worked.

### Write Dockerfile

Now, to make this reproducible, we want to run the script in a docker container.

```Dockerfile
FROM python:3.9.1

RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

WORKDIR /app
COPY ingest_data.py ingest_data.py

ENTRYPOINT [ "python", "ingest_data.py" ]
```

We build the docker image. 

```bash 
docker build -t ingest_data:v01 .
```

And run the image. 

```bash 
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

docker run -it ingest_data:v01 \
  --user="root" \
  --password="root" \
  --host="localhost" \
  --port="5432" \
  --db="ny_taxi" \
  --table="yellow_taxi_trips" \
  --url=${URL}
```

After downloading the file, this will fail, since we again do not have postgress running in this docker image. 

> #### Kill non-responsive container
>
> If you forget to pass the `-it` flag on a long running container, you might not be able to stop interactively. Instead you have to check running containers with `docker ps` to find the right ID, then use `docker kill <ID>` to stop it.

### Run in postgres network

We have to specify the `pg-network` that we created before. Note the order of arguments to the docker run command, the docker specific parameters have to be given before specifying the image and script arguments.

We also use the local address of the already downloaded dataset to speed up "downloading". 
We spin up a local webserver using python http module, which open a server at [localhost:8000](http://localhost:8000). 

```bash
python -m http.server
```

Then we have to find our ip address, because localhost in the container will be different then on host machine. We use `ifconfig` (`ipconfig` on windows) to find the `inet` or ip4 address and replace the localhost in the weburl with it. 
Refreshing the browser should still work, now we copy the url to the local file.

We also have to update the host from `localhost` to `pg-database`.

```bash
URL="http://192.168.64.1:8000/yellow_tripdata_2021-01.csv.gz"

docker run -it \
  --network=pg-network \
  ingest_data:v01 \
  --user="root" \
  --password="root" \
  --host="pg-database" \
  --port="5432" \
  --db="ny_taxi" \
  --table="yellow_taxi_trips" \
  --url=${URL}
```


#### Upload taxi zones to postgres


We copy url taxi zone lookup data from https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page. And we store the data in the `zones` table.

First we start the postgres container with the `pg-network` network.

```bash
 docker run -it\
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network pg-network \
  --name pg-database \
  --rm \
  postgres:13
```

[This](./upload_nyc_taxi_zones.ipynb) simple juypyter notebook shows how to upload the zones data similar to the taxi trips data.

But, we can also do this with the ingestion docker container.



```bash
URL="https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

docker run -it \
  --network=pg-network \
  ingest_data:v01 \
  --user="root" \
  --password="root" \
  --host="pg-database" \
  --port="5432" \
  --db="ny_taxi" \
  --table="zones" \
  --url=${URL}
```

This will fail, because in the ingestion script we are doing some type conversions for the datetime columns. 

```bash
[...]
Traceback (most recent call last):
  File "/app/ingest_data.py", line 89, in <module>
    main(args)
  File "/app/ingest_data.py", line 39, in main
    df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
  File "/usr/local/lib/python3.9/site-packages/pandas/core/generic.py", line 6299, in __getattr__
    return object.__getattribute__(self, name)
AttributeError: 'DataFrame' object has no attribute 'tpep_pickup_datetime'
```


We update ingest_data.py to skip datetime conversion if "tpep_pickup_datetime" is not available in dataframe. 


Then we build a newer image with newer version of ingest_data.py

```bash
docker build -t ingest_data:v02 .
```

And now we ingest the zones table.

```bash
URL="https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

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

This should work now.


## 1.2.5 Running Postgres and pgAdmin with Docker-Compose

[Docker Compose](https://docs.docker.com/compose/) is a tool for defining and running multi-container applications. 

We translate out `docker run` commands with all arguments into `docker-compose` services. 
If environment variables where quoted before, now the quotes have to be removed. Instead the `volumes` and `ports` specifciations are quoted. Volumes can be read-only (`:ro`) or read-write (`:rw`).
There is no need to specify a shared network, because the containers live in the same local network.

We start both containers with:

```bash
docker-compose up
```

Unfortunately we have to recreate the server in pgAdmin. This time we use `pgdabase` as the connection host. 

We can end the containers with `ctrl-c` and remove with `docker compose down`. 

We can also run in detached mode via `docker compose up -d`, where containers are running in background and we gain access to the terminal. 

### Safe connected servers

Run a container and save persistent configuration and settings using a shared config/storage directory in ./pgadmin_config on the host. 
For `docker run` add  `-v $(pwd)/pgadmin_config:/var/lib/pgadmin`, in `docker-compose` add this to the pgadmin service:

```compose
volumes:
      - "./pgadmin_config:/var/lib/pgadmin:rw"
```

Source: 

- https://github.com/thaJeztah/pgadmin4-docker/issues/26#issuecomment-354291987
- third example of https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html#examples
- https://stackoverflow.com/a/77519799

To peek inside the pgadming container use: `docker compose exec pgadmin /bin/bash`


## 1.2.6 SQL Refresher

we upload the taxi zone data into the database (see [text](upload_nyc_taxi_zones.ipynb)).

Then we run some `query`'s against the `zone` database:

- count elements in table:

```sql
SELECT 
  count(1)
FROM 
  zones;
```

- print all rows from table `zone`

```sql
SELECT 
  *
FROM 
  zones;
```


- print the first 100 rows from table `yellow_taxi_trips`

```sql
SELECT 
  *
FROM 
  yellow_taxi_trips
LIMIT
  100
```


- perform **inner join** with the location table, but display extended location name instead of ID

```sql
-- INNER JOIN
-- perform a join with the location table, but display location name instead of ID	
SELECT 
  t.tpep_pickup_datetime,
  t.tpep_dropoff_datetime,
  t.total_amount,
  -- "Borough" means district in BE
  CONCAT(zpu."Borough",' / ',zpu."Zone") as "pickup_location",
  CONCAT(zdo."Borough",' / ',zdo."Zone") as "dropoff_location"
FROM 
  -- join all tables listed here
  yellow_taxi_trips t,
  zones zpu,
  zones zdo
WHERE
  -- and filter by conditions
  t."PULocationID" = zpu."LocationID" AND
  t."DOLocationID" = zdo."LocationID"
LIMIT
  100
```

- perform **explicit inner join** with the location table, but display location name instead of ID

```sql
-- EXPLICIT INNER JOIN
-- perform a join with the location table, but display location name instead of ID	
SELECT 
  t.tpep_pickup_datetime,
  t.tpep_dropoff_datetime,
  t.total_amount,
  -- "Borough" means district in British English
  CONCAT(zpu."Borough",' / ',zpu."Zone") as "pickup_location",
  CONCAT(zdo."Borough",' / ',zdo."Zone") as "dropoff_location"
FROM 
  -- specifiy JOINing conditions via ON 
  yellow_taxi_trips t JOIN zones zpu ON t."PULocationID" = zpu."LocationID" 
  JOIN zones zdo t."DOLocationID" = zdo."LocationID"  
LIMIT
  100
```


- Checking for records with NULL Location IDs in the Yellow Taxi table

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    "PULocationID",
    "DOLocationID"
FROM 
    yellow_taxi_trips t
WHERE
    "PULocationID" IS NULL
    OR "DOLocationID" IS NULL
LIMIT 100;
```

- Checking for Location IDs in the Zones table NOT IN the Yellow Taxi table

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    "PULocationID",
    "DOLocationID"
FROM 
    yellow_taxi_trips t
WHERE
    "DOLocationID" NOT IN (SELECT "LocationID" from zones)
    OR "PULocationID" NOT IN (SELECT "LocationID" from zones)
LIMIT 100;
```

- Using LEFT, RIGHT, and OUTER JOINS when some Location IDs are not in either Tables

```sql
DELETE FROM zones WHERE "LocationID" = 142;

SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropff_loc"
FROM 
    yellow_taxi_trips t
LEFT JOIN 
    zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN
    zones zdo ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;
```

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropff_loc"
FROM 
    yellow_taxi_trips t
RIGHT JOIN 
    zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN
    zones zdo ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;
```

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropff_loc"
FROM 
    yellow_taxi_trips t
OUTER JOIN 
    zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN
    zones zdo ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;
```

- Using GROUP BY to calculate number of trips per day

```sql
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1)
FROM 
    yellow_taxi_trips t
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
LIMIT 100;
```

- Using ORDER BY to order the results of your query

```sql
-- Ordering by day

SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1)
FROM 
    yellow_taxi_trips t
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
ORDER BY
    "day" ASC
LIMIT 100;

-- Ordering by count

SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1) AS "count"
FROM 
    yellow_taxi_trips t
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
ORDER BY
    "count" DESC
LIMIT 100;
```

- Other kinds of aggregations

```sql
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1) AS "count",
    MAX(total_amount) AS "total_amount",
    MAX(passenger_count) AS "passenger_count"
FROM 
    yellow_taxi_trips t
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
ORDER BY
    "count" DESC
LIMIT 100;
```

- Grouping by multiple fields


```sql
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    "DOLocationID",
    COUNT(1) AS "count",
    MAX(total_amount) AS "total_amount",
    MAX(passenger_count) AS "passenger_count"
FROM 
    yellow_taxi_trips t
GROUP BY
    1, 2
ORDER BY
    "day" ASC, 
    "DOLocationID" ASC
LIMIT 100;
```


### Important functions

- `SELECT`: choose columns to print
- `FROM`: choose tables where to `SELECT` from
- `LIMIT`: limit number of rows printed (i.e. head()) 
- `WHERE`: filter by conditions **after** joining
- `JOIN/ON`: filter by conditions **during** joining
- `CAST`: cast column to a different type
- `GROUP BY`: group by one or more columns
- `ORDER BY`: order by one or more columns (set `ASC` or `DESC` order)
- `COUNT`: count number of rows
- `MAX`: find maximum value of a column
- `MIN`: find minimum value of a column





## 1.5.1 Port Mapping and Networks in Docker

[Video](https://youtu.be/tOr4hTsHOzU?si=KIMr8WiN-mvbR3Jv)

This video summarizes the concepts of port mapping inside a Docker container. 
The concepts and information are partically useful if you already a local instance of postgres running and want to make sure applications or scripts are connecting to the right instance.

![alt text](videoframe_942352.png)