DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

Select
Avg (o.actual_delivery_time_in_seconds/60) as Delivery_time,

from
(`fulfillment-dwh-production.pandata_curated.lg_orders` o
      left join unnest(deliveries) as c on c.is_primary and DATE(c.rider_dropped_off_at_local) between Date_Sub(date_trunc(Current_Date(),isoweek),Interval 1 YEAR) and date_sub(current_date(), interval 1 day) 
  AND DATE_DIFF(DATE(c.rider_dropped_off_at_local), DATE(o.order_placed_at_local), DAY) <= 1
      )
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
on v.vendor_code = left(o.code,4)
and v.global_entity_id = o.global_entity_id

where
o.created_date_utc >= start_utc
and o.global_entity_id = 'FP_PK'
and o.order_status = 'completed'
and o.created_date_local between start_date and end_date
and v.chain_code in unnest(chains)