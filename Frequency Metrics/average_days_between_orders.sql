DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-04-01';

DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

with data as (
  select o.pd_customer_uuid,
  o.created_at_local, 
  lag(o.created_at_local) over (partition by o.pd_customer_uuid order by o.created_at_local) as lag_orderdate
from `fulfillment-dwh-production.pandata_curated.pd_orders` o
join `fulfillment-dwh-production.pandata_curated.pd_vendors` v
  on o.vendor_code = v.vendor_code and o.global_entity_id = v.global_entity_id 
join `fulfillment-dwh-production.pandata_curated.sf_accounts` a
  on a.global_entity_id = v.global_entity_id and a.global_vendor_id = v.global_vendor_id 
where a.is_marked_for_testing_training = false
  and v.is_test = false
  and v.is_private = false
  and v.chain_code in unnest(chains)
  and o.created_date_local between start_date and end_date
  and o.created_date_utc between start_utc and end_utc
  and o.is_test_order = false
  and o.is_valid_order
)

select avg(datetime_diff(created_at_local, lag_orderdate, DAY))
from data