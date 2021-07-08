DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

select safe_divide(sum(s.count_of_shop_menu_loaded), sum(s.count_of_shop_list_loaded)), 
from `fulfillment-dwh-production.pandata_report.product_vendor_session_metrics` s
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on s.vendor_code = v.vendor_code and s.global_entity_id = v.global_entity_id 
join `fulfillment-dwh-production.pandata_curated.sf_accounts` a
  on a.global_entity_id = v.global_entity_id and a.global_vendor_id = v.global_vendor_id 
where a.is_marked_for_testing_training = false
  and v.is_test = false
  and v.is_private = false
  and v.chain_code in unnest(chains)
  and s.date between start_date and end_date