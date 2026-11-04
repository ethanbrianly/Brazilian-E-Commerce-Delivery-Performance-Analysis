-- Summary tables and CSV exports for Excel and Tableau.

CREATE OR REPLACE TABLE state_scorecard AS
SELECT customer_state, COUNT(*) AS orders,
       SUM(CAST(is_late AS INT)) AS late_orders,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(review_score), 2) AS avg_review,
       ROUND(AVG(days_to_deliver), 1) AS avg_days,
       ROUND(AVG(days_estimated), 1) AS avg_promised
FROM orders_enriched
GROUP BY 1;

CREATE OR REPLACE TABLE lane_scorecard AS
SELECT seller_state, customer_state, COUNT(*) AS orders,
       SUM(CAST(is_late AS INT)) AS late_orders,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(days_to_deliver), 1) AS avg_days,
       ROUND(AVG(review_score), 2) AS avg_review
FROM orders_enriched
WHERE seller_state IS NOT NULL
GROUP BY 1, 2;

CREATE OR REPLACE TABLE seller_scorecard AS
SELECT seller_id, seller_state, COUNT(*) AS orders,
       SUM(CAST(is_late AS INT)) AS late_orders,
       ROUND(100 * AVG(CAST(is_late AS INT)), 1) AS late_pct,
       ROUND(AVG(review_score), 2) AS avg_review
FROM orders_enriched
WHERE seller_id IS NOT NULL
GROUP BY 1, 2;

COPY orders_enriched TO 'C:/Users/ethan/Downloads/archive/orders_enriched.csv' (HEADER, DELIMITER ',');
COPY state_scorecard TO 'C:/Users/ethan/Downloads/archive/state_scorecard.csv' (HEADER, DELIMITER ',');
COPY lane_scorecard TO 'C:/Users/ethan/Downloads/archive/lane_scorecard.csv' (HEADER, DELIMITER ',');
COPY seller_scorecard TO 'C:/Users/ethan/Downloads/archive/seller_scorecard.csv' (HEADER, DELIMITER ',');

CREATE OR REPLACE TABLE lateness_review AS
SELECT CASE WHEN NOT is_late THEN '1 on time'
            WHEN days_late BETWEEN 1 AND 3 THEN '2 1-3 days late'
            WHEN days_late BETWEEN 4 AND 7 THEN '3 4-7 days late'
            ELSE '4 8+ days late' END AS bucket,
       COUNT(*) AS orders,
       ROUND(AVG(review_score), 2) AS avg_review,
       ROUND(100 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_or_2_stars
FROM orders_enriched
WHERE review_score IS NOT NULL
GROUP BY 1;

COPY lateness_review TO 'C:/Users/ethan/Downloads/archive/lateness_review.csv' (HEADER, DELIMITER ',');