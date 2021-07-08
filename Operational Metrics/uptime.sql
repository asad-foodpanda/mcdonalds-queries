DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

select 1 - safe_divide(
      ifnull(sum(total_unavailable_seconds/3600),0),
      ifnull(sum( total_scheduled_open_seconds/3600),0))
from `fulfillment-dwh-production.pandata_report.vendor_offline` offline
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on v.vendor_code = offline.vendor_code and offline.global_entity_id = v.global_entity_id
join `fulfillment-dwh-production.pandata_curated.sf_accounts` a
  on a.global_entity_id = v.global_entity_id and a.global_vendor_id = v.global_vendor_id 
where v.global_entity_id = 'FP_PK'
  and a.is_marked_for_testing_training = false
  and v.is_test = false
  and v.is_private = false
  and v.chain_code in unnest(chains)
  and offline.report_date between start_date and end_date