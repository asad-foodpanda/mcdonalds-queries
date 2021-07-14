DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
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

data as (
  select 
  format_date("%B %Y", o.created_date_local) as month,
  count(distinct case when o.is_valid_order then o.code end) as valid_orders,
  count(distinct o.pd_customer_uuid) as existing_customers,
  safe_divide(count(distinct case when o.is_valid_order then o.code end), count(distinct o.pd_customer_uuid)) as orders_per_customer
  from `fulfillment-dwh-production.pandata_curated.pd_orders` o
  join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
    on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
  where v.global_entity_id = 'FP_PK'
    and o.created_date_utc >= start_utc
    and v.chain_code in unnest(chains)
    and o.created_date_local between start_date and end_date
    and o.pd_customer_uuid not in (select pd_customer_uuid from new_customers)
    group by 1
)


select avg(orders_per_customer) from data
-- select valid_orders / 3 / existing_customers  as average_orders_per_month from data