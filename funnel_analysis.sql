SELECT * FROM `tidal-vim-477911-a8.SQLOHMYGOD.user_events`;

SELECT DISTINCT event_type from tidal-vim-477911-a8.SQLOHMYGOD.user_events;

--Identifying numbers in each stage
WITH funnel_stages AS (
  SELECT 
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS page_views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS add_to_cart,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS checkout_start,
  COUNT (DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS payment_info,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase
  FROM `tidal-vim-477911-a8.SQLOHMYGOD.user_events`
  WHERE event_date BETWEEN TIMESTAMP('2025-12-01') AND TIMESTAMP('2026-01-01')
  )


SELECT * from funnel_stages;

-- conversion rate


WITH funnel_stages AS (
  SELECT 
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS page_views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS add_to_cart,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS checkout_start,
  COUNT (DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS payment_info,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase
  FROM `tidal-vim-477911-a8.SQLOHMYGOD.user_events`
  WHERE event_date BETWEEN TIMESTAMP('2025-12-01') AND TIMESTAMP('2026-01-01')
  )


SELECT 
page_views, add_to_cart, ROUND(add_to_cart/page_views *100) AS view_to_cart_rate,
checkout_start, ROUND(checkout_start/add_to_cart *100) AS cart_to_checkout_rate,
payment_info, ROUND(payment_info/checkout_start *100) AS checkout_to_payment_rate,
purchase, ROUND(purchase/payment_info *100) AS payment_to_purchase_rate,
purchase, ROUND(purchase/page_views *100) AS conversion_rate
FROM funnel_stages;

-- funnel by traffic
SELECT DISTINCT traffic_source FROM tidal-vim-477911-a8.SQLOHMYGOD.user_events;
WITH traffic_sources AS (
  SELECT 
  traffic_source,
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases


FROM tidal-vim-477911-a8.SQLOHMYGOD.user_events
WHERE event_date BETWEEN TIMESTAMP('2025-12-01') AND TIMESTAMP('2026-01-01')
GROUP BY traffic_source


 )

SELECT 
traffic_source, views, carts, purchases,
ROUND(carts/views *100) AS view_to_cart,
ROUND(purchases / carts *100) AS cart_to_purchase_rate,
ROUND(purchases / views *100) AS purchases_to_views_rate
FROM traffic_sources
ORDER BY purchases DESC;

 -- time to conversion analysis

  WITH time_to_conversion AS (
  
  SELECT
  user_id,
  MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS view_time,
  MIN (CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
  MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time # the min is important to collapse the nulls in the 
  FROM `tidal-vim-477911-a8.SQLOHMYGOD.user_events`
  WHERE event_date BETWEEN TIMESTAMP('2025-12-01') AND TIMESTAMP('2026-01-01')
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase'  THEN event_date END ) IS NOT NULL #this filters only the users who made a purchase

  )

  SELECT 
  COUNT (*) AS converted_users,
  ROUND(AVG(TIMESTAMP_DIFF(cart_time, view_time, MINUTE)),2) AS average_time_to_cart,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, cart_time, MINUTE)),2) AS average_time_to_purchase,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time, MINUTE)),2) AS average_overall_time
  FROM time_to_conversion;

--- revenue funnel analysis

  WITH funnel_revenue AS (
  
  SELECT
  
  COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
  SUM(CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
  COUNT(CASE WHEN event_type = 'purchase' THEN user_id END) AS total_orders
  FROM `tidal-vim-477911-a8.SQLOHMYGOD.user_events`
  WHERE event_date BETWEEN TIMESTAMP('2025-12-01') AND TIMESTAMP('2026-01-01')
 

  )

  SELECT 
  total_visitors, total_buyers, total_revenue, total_orders,
  ROUND(total_revenue / total_buyers,2) AS revenue_per_buyer,
  ROUND(total_revenue / total_orders,2) AS revenue_per_order,
  ROUND(total_revenue / total_visitors,2) AS revenue_per_visitor
  FROM funnel_revenue;

