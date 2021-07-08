DECLARE start_date DATE DEFAULT '2021-01-01';
DECLARE end_date DATE DEFAULT '2021-03-31';
DECLARE start_utc date DEFAULT '2020-12-31';
DECLARE end_utc date DEFAULT '2021-08-01';
DECLARE chains ARRAY <STRING> DEFAULT ['cm4kh', 'cz5ud', 'cz8ck', 'co5oz'];

SELECT
  AVG(restaurant_food_rating.value) AS restaurant_food_rating,
  AVG(packaging_rating.value) AS packaging_rating,
  AVG(punctuality_rating.value) AS punctuality_rating,
  AVG(rider_rating.value) AS rider_rating,
FROM `fulfillment-dwh-production.pandata_curated.marvin_reviews` as marvin_reviews
LEFT JOIN marvin_reviews.ratings AS restaurant_food_rating
       ON restaurant_food_rating.name = 'restaurant_food'
LEFT JOIN marvin_reviews.ratings AS packaging_rating
       ON packaging_rating.name = 'packaging'
LEFT JOIN marvin_reviews.ratings AS rider_rating
       ON rider_rating.name = 'rider'
LEFT JOIN marvin_reviews.ratings AS punctuality_rating
       ON punctuality_rating.name = 'punctuality'

WHERE marvin_reviews.created_date_utc >= start_utc
  AND marvin_reviews.created_date_local between start_date and end_date
  AND marvin_reviews.state = 'filled'
  AND marvin_reviews.global_entity_id = 'FP_PK'
  AND marvin_reviews.vendor_code in (
    select vendor_code 
    from `fulfillment-dwh-production.pandata_curated.pd_vendors` 
    where chain_code in unnest(chains)
      AND global_entity_id = 'FP_PK'
    )