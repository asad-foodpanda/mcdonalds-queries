DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

select 
  count(distinct case when acq.is_first_valid_order_platform then o.pd_customer_uuid end) /
  count(distinct case when acq.is_first_valid_order_with_this_chain then o.pd_customer_uuid end)
  

from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_report.marketing_pd_orders_agg_acquisition_dates` acq
  on acq.uuid = o.uuid
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