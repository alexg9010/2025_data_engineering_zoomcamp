{% macro extract_time_dimension(date_column, date_format) -%}   

    extract(year from {{ date_column }}) as year,
    extract(quarter from {{ date_column }}) as quarter,
    extract(year from {{ date_column }}) || '/Q' || extract(quarter from {{ date_column }}) as year_quarter,
    extract(month from {{ date_column }}) as month

{%- endmacro %}