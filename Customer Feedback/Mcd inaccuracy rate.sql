DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

with data as (select count(distinct case when o.decline_reason.title in ("Customer received food in inedible condition","Customer received food totally spilled","Customer received order too late (>1h)","Customer received wrong order") then o.code end) as inaccurate_orders,
count(distinct case when o.is_gross_order then o.code end) as gross_orders,
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
where v.global_entity_id = 'FP_PK'
  and o.created_date_utc >= start_utc
  and v.chain_code in unnest(chains)
  and o.created_date_local between start_date and end_date)

select inaccurate_orders / gross_orders as inaccuracy from data