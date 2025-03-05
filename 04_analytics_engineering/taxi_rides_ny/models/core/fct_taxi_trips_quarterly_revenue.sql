-- Compute the Quarterly Revenues for each year for based on `total_amount`
-- Compute the Quarterly YoY (Year-over-Year) revenue growth 
{{ config(materialized='table') }}

with trips_data as (
    select * from {{ ref('fact_trips') }}
)
    select 
    -- Revenue grouping 
    year_quarter as revenue_quarter,

    service_type, 
    -- Revenue calculation 
    sum(total_amount) as revenue_quarterly_total_amount,

    -- Additional calculations
    count(tripid) as total_quarterly_trips,
    avg(passenger_count) as avg_quarterly_passenger_count,
    avg(trip_distance) as avg_quarterly_trip_distance,


    {{ sum_with_lag("total_amount", 8, "year_quarter || service_type") }} as revenue_last_year_same_quarter, 
    100 * (sum(total_amount) / nullif({{ sum_with_lag("total_amount", 8, "year_quarter || service_type") }}, 0) - 1) as yoy_quarter_revenue_growth

    from trips_data
    where year in (2019,2020)
    group by revenue_quarter,service_type
    ORDER BY revenue_quarter,service_type DESC