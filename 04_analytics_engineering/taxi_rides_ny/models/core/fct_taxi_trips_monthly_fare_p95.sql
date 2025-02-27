-- Filter out invalid entries (`fare_amount > 0`, `trip_distance > 0`, and
-- `payment_type_description in ('Cash', 'Credit Card')`)
-- Compute the **continous percentile** of `fare_amount` partitioning by service_type,
-- year and and month
{{ config(materialized="table") }}

with valid_trips as (
    select 
        service_type,
        year,
        month,
        percentile_cont(fare_amount, 0.97) over (
            partition by service_type, year, month
        ) as p97,
        percentile_cont(fare_amount, 0.95) over (
            partition by service_type, year, month
        ) as p95,
        percentile_cont(fare_amount, 0.90) over (
            partition by service_type, year, month
        ) as p90
    from {{ ref('fact_trips') }}
    where year in (2020,2019)
    and fare_amount > 0 
    and trip_distance > 0
    and payment_type_description in ('Cash', 'Credit Card')
)

select 
    service_type,
    year,
    month,
    max(p97) as p97_fare_amount,
    max(p95) as p95_fare_amount,
    max(p90) as p90_fare_amount
from valid_trips
group by service_type, year, month
order by service_type, year, month



