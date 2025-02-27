{% macro sum_with_lag(value, shift, order_colum) -%}   


    lag(sum({{ value }}), {{shift}}) over (order by {{order_colum}})


{%- endmacro %}