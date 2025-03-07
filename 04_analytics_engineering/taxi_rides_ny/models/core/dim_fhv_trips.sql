{{ config(materialized="table") }}


with
    fhv_tripdata as (select * from {{ ref("stg_fhv_tripdata") }}),
    dim_zones as (select * from {{ ref("dim_zones") }} where borough != 'Unknown')

select
    fhv_tripdata.dispatching_base_num,
    fhv_tripdata.pickup_datetime,
    fhv_tripdata.dropoff_datetime,
    fhv_tripdata.pickup_locationid,
    fhv_tripdata.dropoff_locationid,
    fhv_tripdata.sr_flag,
    fhv_tripdata.affiliated_base_number,
    {{ extract_time_dimension("fhv_tripdata.pickup_datetime") }}
from fhv_tripdata
inner join
    dim_zones as pickup_zone on fhv_tripdata.pickup_locationid = pickup_zone.locationid
inner join
    dim_zones as dropoff_zone on fhv_tripdata.dropoff_locationid = dropoff_zone.locationid
