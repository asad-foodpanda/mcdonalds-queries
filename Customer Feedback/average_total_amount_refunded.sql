DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

with issued_vouchers as (SELECT 
  voucher_code, 
  id as voucher_id,
  vouchers.uuid,
  right(trim(description), 9) as order_code,
  case when description like 'Partial refund for order%' then 'Mercury Partial refund'
     when description like 'Full refund for order%' then 'Mercury Full refund'
     when description like '%re sorry voucher for order%' then 'Mercury Compensation'
  end as voucher_type,
  value,
  date (vouchers.created_date_utc) as date,
FROM  `fulfillment-dwh-production.pandata_curated.pd_vouchers` vouchers
LEFT JOIN `fulfillment-dwh-production.pandata_curated.pd_vendors` vendors
       ON vendors.vendor_code = left(right(trim(description), 9), 4) and vouchers.global_entity_id = vendors.global_entity_id 
WHERE 
  vouchers.created_date_utc >= start_utc
  and vouchers.global_entity_id = 'FP_PK'
  and vendors.chain_code in unnest(chains)
  and voucher_mgmt_created_by = 'GCC-OneView')
  
, final_vouchers as (
select
  o.code, issued_vouchers.value,
FROM 
  issued_vouchers
JOIN `fulfillment-dwh-production.pandata_curated.pd_orders` o
  ON o.code = issued_vouchers.order_code
JOIN `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  ON o.pd_vendor_uuid = v.uuid
WHERE 
  o.global_entity_id = 'FP_PK'
  and o.created_date_utc >= start_utc
  and o.created_date_local between start_date and end_date)
,
inaccurate_orders as (
select o.code
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
where v.global_entity_id = 'FP_PK'
  and o.created_date_utc >= start_utc
  and v.chain_code in unnest(chains)
  and o.created_date_local between start_date and end_date
  and o.decline_reason.title in ("No rider available","Customer received food in inedible condition","Customer received food totally spilled","Customer received order too late (>1h)","Customer received wrong order","Outside of delivery area","Rider accident","Rider unreachable","Unable to find or reach customer")
)
select sum(value) / count(distinct code)
from final_vouchers where code in (select code from inaccurate_orders)
