DECLARE start_date DATE DEFAULT '2021-04-01';
DECLARE end_date DATE DEFAULT '2021-06-30';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-08-01';
DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];


with new_customers as (
select o.pd_customer_uuid
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
join `fulfillment-dwh-production.pandata_curated.sf_accounts` a
  on a.global_entity_id = v.global_entity_id and a.global_vendor_id = v.global_vendor_id 
left join `fulfillment-dwh-production.pandata_report.marketing_pd_orders_agg_acquisition_dates` acq
       on acq.uuid = o.uuid
where a.is_marked_for_testing_training = false
  and v.is_test = false
  and v.is_private = false
  and v.chain_code in unnest(chains)
  and o.created_date_local between start_date and end_date
  and o.created_date_utc between start_utc and end_utc
  and o.is_test_order = false
  and acq.is_first_order_with_this_chain),
 
existing_customers as (
  select o.pd_customer_uuid
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
join `fulfillment-dwh-production.pandata_curated.sf_accounts` a
  on a.global_entity_id = v.global_entity_id and a.global_vendor_id = v.global_vendor_id 
left join `fulfillment-dwh-production.pandata_report.marketing_pd_orders_agg_acquisition_dates` acq
       on acq.uuid = o.uuid
where a.is_marked_for_testing_training = false
  and v.is_test = false
  and v.is_private = false
  and v.chain_code in unnest(chains)
  and o.created_date_local between start_date and end_date
  and o.created_date_utc between start_utc and end_utc
  and o.is_test_order = false
  and o.pd_customer_uuid not in (select pd_customer_uuid from new_customers)
),

previous as (
select o.pd_customer_uuid, 
  o.created_date_local as order_date, 
  lag(o.created_date_local) over (partition by o.pd_customer_uuid order by o.created_date_local) as prev_date
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v 
  on o.vendor_code = v.vendor_code 
  and o.global_entity_id = v.global_entity_id 
where o.created_date_utc >= start_utc
  and o.global_entity_id = 'FP_PK'
  and o.created_date_local between start_date - 70 and end_date
  and v.chain_code in unnest(chains)
  and o.pd_customer_uuid in (select pd_customer_uuid from new_customers)
qualify rank() over (partition by o.pd_customer_uuid order by o.created_date_local desc) = 1
order by 1,2),

data as (
  select pd_customer_uuid, order_date, prev_date, date_diff(order_date, prev_date, day) as days_between_orders
  from previous
  where order_date >= start_date
    and prev_date is not null
    and date_diff(order_date, prev_date, day) <= 60
)

select safe_divide(count(distinct d.pd_customer_uuid), count(distinct p.pd_customer_uuid))
from data d, new_customers p
