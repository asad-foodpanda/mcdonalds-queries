-- DECLARE start_date DATE DEFAULT '2021-01-01';
-- DECLARE end_date DATE DEFAULT '2021-03-31';
-- DECLARE start_utc date DEFAULT '2020-12-31';
-- DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

with new_customers as (
select o.pd_customer_uuid,
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
  and acq.is_first_order_with_this_chain
)

select 
  avg(distinct case when o.pd_customer_uuid in (select pd_customer_uuid from new_customers)
  and acq.is_first_order_with_this_chain then av.voucher.value_local end)
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_report.marketing_pd_orders_agg_acquisition_dates` acq
  on acq.uuid = o.uuid
join `fulfillment-dwh-production.pandata_curated.pd_orders_agg_vouchers` av
  on o.uuid = av.uuid and av.created_date_utc >= start_utc
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
where 
  v.chain_code in unnest(chains)
  and o.created_date_utc >= start_utc
  and o.created_date_local between start_date and end_date
  and o.global_entity_id = 'FP_PK'
  and v.is_private = false
  and v.is_test = false
  and o.is_test_order = false