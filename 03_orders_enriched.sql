-- Build one clean row per delivered order: customer and seller state, price and freight, average review score, delivery days, and a late flag

CREATE OR REPLACE TABLE orders_enriched AS
WITH items AS (
    SELECT order_id,
           COUNT(*) AS n_items,
           COUNT(DISTINCT seller_id) AS n_sellers,
           MIN(seller_id) AS seller_id,
           SUM(price) AS price,
           SUM(freight_value) AS freight
    FROM order_items
    GROUP BY order_id
),
rev AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT o.order_id,
       c.customer_state,
       i.seller_id,
       s.seller_state,
       i.n_items,
       i.n_sellers,
       i.price,
       i.freight,
       r.review_score,
       o.order_purchase_timestamp,
       o.order_delivered_customer_date,
       o.order_estimated_delivery_date,
       date_diff('day', o.order_purchase_timestamp, o.order_delivered_customer_date) AS days_to_deliver,
       date_diff('day', o.order_purchase_timestamp, o.order_estimated_delivery_date) AS days_estimated,
       CAST(o.order_delivered_customer_date AS DATE) > CAST(o.order_estimated_delivery_date AS DATE) AS is_late,
       GREATEST(date_diff('day', CAST(o.order_estimated_delivery_date AS DATE),
                                  CAST(o.order_delivered_customer_date AS DATE)), 0) AS days_late
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN items i ON i.order_id = o.order_id
LEFT JOIN sellers s ON s.seller_id = i.seller_id
LEFT JOIN rev r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;