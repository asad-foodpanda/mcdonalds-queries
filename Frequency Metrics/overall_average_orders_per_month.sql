DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-08-01';
DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

with data as (
  select 
  format_date("%B %Y", o.created_date_local) as month,
  count(distinct case when o.is_valid_order then o.code end) as valid_orders,
  safe_divide(count(distinct case when o.is_valid_order then o.code end), count(distinct o.pd_customer_uuid)) as orders_per_customer
  from `fulfillment-dwh-production.pandata_curated.pd_orders` o
  join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
    on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
  where v.global_entity_id = 'FP_PK'
    and o.created_date_utc >= start_utc
    and v.chain_code in unnest(chains)
    and o.created_date_local between start_date and end_date
    group by 1
)

select avg(orders_per_customer) from data
-- select valid_orders / 3 as average_orders_per_month from data