DECLARE start_date DATE DEFAULT '2021-04-01';
DECLARE end_date DATE DEFAULT '2021-06-30';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-08-01';
DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

with data as (
  select 
  count(distinct case when o.is_failed_order then o.code end) as failed_orders,
  count(distinct case when o.is_gross_order then o.code end) as gross_orders,
  from `fulfillment-dwh-production.pandata_curated.pd_orders` o
  join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
    on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
  where v.global_entity_id = 'FP_PK'
    and o.created_date_utc >= start_utc
    and v.chain_code in unnest(chains)
    and o.created_date_local between start_date and end_date
)

select failed_orders / gross_orders as cancelled from data