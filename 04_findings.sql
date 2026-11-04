-- 04_findings.sql
-- Findings queries for the Olist late-delivery analysis.
-- Run after 03_orders_enriched.sql has built the orders_enriched table.


-- Q1. How often are orders late, and where?

-- Overall late rate
SELECT COUNT(*) AS delivered_orders,
       ROUND(AVG(CAST(is_late AS INT)) * 100, 1) AS late_pct
FROM orders_enriched;

-- Late rate by customer state
SELECT customer_state,
       COUNT(*) AS orders,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(review_score), 2) AS avg_review
FROM orders_enriched
GROUP BY 1
ORDER BY late_pct DESC;

-- Late orders by state, with each state's share of all late orders
SELECT customer_state,
       COUNT(*) AS orders,
       SUM(CAST(is_late AS INT)) AS late_orders,
       ROUND(100.0 * SUM(CAST(is_late AS INT)) / SUM(SUM(CAST(is_late AS INT))) OVER (), 1) AS pct_of_all_late,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct
FROM orders_enriched
GROUP BY 1
ORDER BY late_orders DESC;

-- Late rate by product category (at least 100 orders)
SELECT t.product_category_name_english AS category,
       COUNT(DISTINCT e.order_id) AS orders,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.is_late THEN e.order_id END)
             / COUNT(DISTINCT e.order_id), 1) AS late_pct
FROM order_items i
JOIN orders_enriched e ON e.order_id = i.order_id
JOIN products p ON p.product_id = i.product_id
LEFT JOIN product_category_name_translation t ON t.product_category_name = p.product_category_name
GROUP BY 1
HAVING COUNT(DISTINCT e.order_id) >= 100
ORDER BY late_pct DESC
LIMIT 15;

-- Same-state vs cross-state deliveries
SELECT (customer_state = seller_state) AS same_state,
       COUNT(*) AS orders,
       ROUND(AVG(days_to_deliver), 1) AS avg_days,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(review_score), 2) AS avg_review
FROM orders_enriched
WHERE seller_state IS NOT NULL
GROUP BY 1;


-- Q2. Does lateness lower review scores, and by how much?

-- Late vs on-time
SELECT is_late,
       COUNT(*) AS orders,
       ROUND(AVG(review_score), 2) AS avg_review
FROM orders_enriched
GROUP BY is_late;

-- By how many days late
SELECT CASE WHEN NOT is_late THEN 'on time'
            WHEN days_late BETWEEN 1 AND 3 THEN '1-3 days late'
            WHEN days_late BETWEEN 4 AND 7 THEN '4-7 days late'
            ELSE '8+ days late' END AS bucket,
       COUNT(*) AS orders,
       ROUND(AVG(review_score), 2) AS avg_review,
       ROUND(100 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_or_2_stars
FROM orders_enriched
WHERE review_score IS NOT NULL
GROUP BY 1
ORDER BY MIN(days_late);


-- Q3. Which sellers or routes cause the lateness?

-- Seller scorecard: top 20 by late orders (sellers with at least 30 orders)
SELECT seller_id, seller_state,
       COUNT(*) AS orders,
       SUM(CAST(is_late AS INT)) AS late_orders,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(review_score), 2) AS avg_review
FROM orders_enriched
WHERE seller_id IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(*) >= 30
ORDER BY late_orders DESC
LIMIT 20;

-- Are the top 10% of sellers worse, or just bigger?
WITH s AS (
    SELECT seller_id, COUNT(*) AS orders, SUM(CAST(is_late AS INT)) AS late_orders
    FROM orders_enriched
    WHERE seller_id IS NOT NULL
    GROUP BY 1
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY late_orders DESC) AS rn, COUNT(*) OVER () AS n
    FROM s
)
SELECT CASE WHEN rn <= n * 0.1 THEN 'top 10% by late orders' ELSE 'other 90%' END AS grp,
       COUNT(*) AS sellers,
       SUM(orders) AS orders,
       SUM(late_orders) AS late_orders,
       ROUND(100.0 * SUM(late_orders) / SUM(orders), 1) AS late_pct,
       ROUND(100.0 * SUM(orders) / SUM(SUM(orders)) OVER (), 1) AS pct_of_orders
FROM ranked
GROUP BY 1;

-- Seller-state to customer-state lanes (at least 300 orders)
SELECT seller_state, customer_state,
       COUNT(*) AS orders,
       SUM(CAST(is_late AS INT)) AS late_orders,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(days_to_deliver), 1) AS avg_days
FROM orders_enriched
WHERE seller_state IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(*) >= 300
ORDER BY late_orders DESC
LIMIT 15;


-- Q4. How much does freight cost compared with the item price?

-- Freight as a share of price, by category
SELECT t.product_category_name_english AS category,
       COUNT(DISTINCT i.order_id) AS orders,
       ROUND(100 * SUM(i.freight_value) / SUM(i.price), 1) AS freight_pct_of_price
FROM order_items i
JOIN products p ON p.product_id = i.product_id
LEFT JOIN product_category_name_translation t ON t.product_category_name = p.product_category_name
GROUP BY 1
HAVING COUNT(DISTINCT i.order_id) >= 100
ORDER BY freight_pct_of_price DESC
LIMIT 15;

-- Freight as a share of price, by destination state
SELECT customer_state,
       COUNT(*) AS orders,
       ROUND(100 * SUM(freight) / SUM(price), 1) AS freight_pct_of_price
FROM orders_enriched
GROUP BY 1
HAVING COUNT(*) >= 300
ORDER BY freight_pct_of_price DESC;

-- Freight: same-state vs cross-state
SELECT (customer_state = seller_state) AS same_state,
       ROUND(100 * SUM(freight) / SUM(price), 1) AS freight_pct_of_price,
       ROUND(AVG(freight), 2) AS avg_freight
FROM orders_enriched
WHERE seller_state IS NOT NULL
GROUP BY 1;


-- Q5. What delivery promise should the site show?

-- Promised vs actual delivery days by state (median and 90th percentile)
SELECT customer_state,
       COUNT(*) AS orders,
       ROUND(AVG(days_estimated), 1) AS avg_promised,
       ROUND(quantile_cont(days_to_deliver, 0.5), 1) AS median_actual,
       ROUND(quantile_cont(days_to_deliver, 0.9), 1) AS p90_actual,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct
FROM orders_enriched
GROUP BY 1
HAVING COUNT(*) >= 300
ORDER BY late_pct DESC;


-- Q6. What are customers complaining about in written reviews?
-- Keyword pass in Portuguese. The first version counted "prazo" (deadline) as a
-- delay complaint, which wrongly caught praise like "chegou antes do prazo".
-- This version separates delay complaints from on-time praise.
-- Accuracy is checked by hand on a sample in 05_review_sample.sql.

WITH txt_reviews AS (
    SELECT rv.order_id,
           rv.review_score,
           e.is_late,
           strip_accents(lower(rv.review_comment_message)) AS txt
    FROM order_reviews rv
    JOIN orders_enriched e ON e.order_id = rv.order_id
    WHERE rv.review_comment_message IS NOT NULL
)
SELECT is_late,
       COUNT(*) AS reviews_with_text,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'nao recebi|nao chegou|nunca chegou|nao foi entregue|nao entregaram') AS INT)), 1) AS pct_not_received,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'atras|demor|fora do prazo|depois do prazo|passou do prazo') AS INT)), 1) AS pct_delay,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'antes do prazo|dentro do prazo|no prazo|antes da data') AS INT)), 1) AS pct_praises_on_time,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'quebrad|danific|defeito|estraga') AS INT)), 1) AS pct_damaged_defect,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'errad|diferente|faltou') AS INT)), 1) AS pct_wrong_or_missing,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'qualidade|pessim|ruim') AS INT)), 1) AS pct_quality,
       ROUND(100 * AVG(CAST(regexp_matches(txt, 'vendedor|atendimento|reembols|devol') AS INT)), 1) AS pct_service_refund
FROM txt_reviews
GROUP BY is_late;