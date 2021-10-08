DECLARE start_date DATE DEFAULT '2020-03-01';
DECLARE end_date DATE DEFAULT '2021-05-31';

with ratings as (
    SELECT
        order_code,
        AVG(restaurant_food_rating.value) AS food_rating,
        AVG(packaging_rating.value) AS packaging_rating,
        AVG(punctuality_rating.value) AS punctuality_rating,
        AVG(rider_rating.value) AS rider_rating,
    FROM fulfillment-dwh-production.pandata_curated.marvin_reviews
    LEFT JOIN marvin_reviews.ratings AS restaurant_food_rating
        ON restaurant_food_rating.name = 'restaurant_food'
    LEFT JOIN marvin_reviews.ratings AS packaging_rating
        ON packaging_rating.name = 'packaging'
    LEFT JOIN marvin_reviews.ratings AS rider_rating
        ON rider_rating.name = 'rider'
    LEFT JOIN marvin_reviews.ratings AS punctuality_rating
        ON punctuality_rating.name = 'punctuality'
    WHERE marvin_reviews.created_date_utc between start_date - 1 and end_date + 1
    AND marvin_reviews.state = 'filled'
    AND global_entity_id = 'FP_PK'
    GROUP BY 1
)

, delivery_orders as (
    select o.vendor_code, 
      v.vendor_name, 
      format_date('%B %Y', o.created_date_local) as month,
      count(distinct case when o.is_valid_order 
        and not o.is_test_order 
        and o.expedition_type = 'delivery' then o.code end) as delivery_orders,
      count(distinct case when o.is_valid_order 
        and not o.is_test_order 
        and o.expedition_type = 'delivery' 
        and o.is_own_delivery then o.code end) as od_orders,
      count(distinct case when o.is_valid_order 
        and not o.is_test_order 
        and o.expedition_type = 'delivery'
        and coalesce(r.food_rating, r.punctuality_rating, r.packaging_rating, r.rider_rating) is not null
        then o.code end) as orders_with_ratings,
      count(distinct case when o.is_failed_order 
        and not o.is_test_order
        and o.decline_reason.title in ('Customer received wrong order', 'Customer received food in inedible condition') then o.code end) as incorrect_orders
    from `fulfillment-dwh-production.pandata_curated.pd_orders` o
    join `dhh---analytics-apac.pandata_pk.pk_accurate_verticals` v
      on v.vendor_code = o.vendor_code
    left join ratings r
           on r.order_code = o.code 
    where o.created_date_utc between start_date - 1 and end_date + 1
      and o.created_date_local between start_date and end_date
      and o.global_entity_id = 'FP_PK'
      and group_name = "McDonald's (Group)"
    group by 1,2,3
)

, lg_kpis as (
    select format_date('%B %Y', po.created_date_local) as month,
      po.vendor_code, 
      avg (o.at_vendor_time_in_seconds) as average_restaurant_time_in_seconds,
      avg (o.actual_delivery_time_in_seconds) as average_delivery_time_in_seconds
    from `fulfillment-dwh-production.pandata_curated.lg_orders` o
    join `fulfillment-dwh-production.pandata_curated.pd_orders` po
      on po.code = o.code 
      and po.global_entity_id = o.global_entity_id
      and po.created_date_utc = o.created_date_utc
    join `dhh---analytics-apac.pandata_pk.pk_accurate_verticals` v
      on v.vendor_code = po.vendor_code
    where o.global_entity_id = 'FP_PK'
      and po.expedition_type = 'delivery'
      and v.group_name = "McDonald's (Group)"
      and o.created_date_utc between start_date - 1 and end_date + 1
      and not po.is_test_order
      and po.is_valid_order
    group by 1,2
)

select  d.*, l.average_delivery_time_in_seconds, l.average_restaurant_time_in_seconds
from delivery_orders d
left join lg_kpis l
       on l.vendor_code = d.vendor_code and l.month = d.month
