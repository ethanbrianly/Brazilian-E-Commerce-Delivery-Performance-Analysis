-- Column types, to confirm the dates were read as timestamps
DESCRIBE orders;

-- Order status breakdown
SELECT order_status, COUNT(*) AS n FROM orders GROUP BY 1 ORDER BY 2 DESC;

-- Duplicate order IDs
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders FROM orders;

-- Delivered orders missing a delivery date
SELECT COUNT(*) AS delivered_missing_date
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- Orders with more than one review (these would double-count in a join)
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (SELECT order_id FROM order_reviews GROUP BY 1 HAVING COUNT(*) > 1);

-- Orders with more than one seller
SELECT COUNT(*) AS orders_with_multiple_sellers
FROM (SELECT order_id FROM order_items GROUP BY 1 HAVING COUNT(DISTINCT seller_id) > 1);