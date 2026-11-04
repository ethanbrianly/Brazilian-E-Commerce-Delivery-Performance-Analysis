-- Load the nine Olist CSV files into DuckDB

.open C:/Users/ethan/Downloads/archive/olist.duckdb
CREATE TABLE orders AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_orders_dataset.csv');
CREATE TABLE order_items AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_order_items_dataset.csv');
CREATE TABLE order_payments AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_order_payments_dataset.csv');
CREATE TABLE order_reviews AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_order_reviews_dataset.csv');
CREATE TABLE customers AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_customers_dataset.csv');
CREATE TABLE sellers AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_sellers_dataset.csv');
CREATE TABLE products AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_products_dataset.csv');
CREATE TABLE geolocation AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/olist_geolocation_dataset.csv');
CREATE TABLE product_category_name_translation AS SELECT * FROM read_csv_auto('C:/Users/ethan/Downloads/archive/product_category_name_translation.csv');
SHOW TABLES;
SELECT COUNT(*) AS orders FROM orders;
SELECT COUNT(*) AS items FROM order_items;
SELECT COUNT(*) AS reviews FROM order_reviews;