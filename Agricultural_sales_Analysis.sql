	CREATE TABLE products (
product_id       SERIAL PRIMARY KEY,
product_name     VARCHAR(255) NOT NULL,
category         VARCHAR(255),
price_per_unit   NUMERIC(10, 2) NOT NULL,
units_shipped    INTEGER,
units_sold       INTEGER,
units_on_hand    INTEGER,
supplier         VARCHAR(255),
farm_location    VARCHAR(255),
sale_date        DATE
);


ALTER TABLE products DROP CONSTRAINT products_pkey;

SELECT * FROM products

--ROW COUNT

SELECT COUNT(*) FROM products;

SELECT * FROM products
LIMIT 10;


--MISSING/MULL VALUES PER COLUMN

SELECT
	SUM (CASE WHEN product_name IS NULL OR product_name = '' THEN 1 ELSE 0 END) AS Missing_product_name,
	SUM (CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END) AS Missing_Category,
	SUM (CASE WHEN price_per_unit IS NULL THEN 1 ELSE 0 END) AS Missing_Price,
	SUM (CASE WHEN units_sold IS NULL THEN 1 ELSE 0 END) AS Missing_solds,
	SUM (CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END) AS Missing_date
FROM products;


-- Distinct categories

SELECT DISTINCT category FROM products;


-- Date range
SELECT MIN(sale_date), MAX(sale_date) FROM products;

--check for duplicates

select * from products

SELECT COUNT(*) AS duplicate_count
FROM (
    SELECT product_id
    FROM products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) t;

--total revenue and standardize text columns.

SELECT sale_date FROM products

CREATE TABLE agri_sales AS
SELECT
    product_id,
    INITCAP(TRIM(product_name)) AS product_name,
    INITCAP(TRIM(category)) AS category,
    price_per_unit,
    units_shipped,
    units_sold,
    units_on_hand,
    INITCAP(TRIM(supplier)) AS supplier,
    INITCAP(TRIM(farm_location)) AS farm_location,
    sale_date,

    (units_sold * price_per_unit) AS revenue
FROM products
WHERE sale_date IS NOT NULL;

select * from agri_sales

-----EDA : EXPLORATORY DATA ANALYSIS


-- MONTHLY SALES BY REGION 

SELECT 
    EXTRACT(YEAR FROM sale_date) AS year,
    EXTRACT(MONTH FROM sale_date) AS month,
    INITCAP(farm_location) AS region,
    SUM(revenue) AS monthly_revenue,
    SUM(units_sold) AS monthly_units_sold
FROM agri_sales
GROUP BY year, month, region
ORDER BY year, month, region;


--TOP 10 PRODUCTS BY REVENUE

SELECT 
	product_name,
	SUM(units_sold) AS Total_Sold,
	SUM(revenue) AS Total_Revenue
FROM agri_sales
GROUP BY product_name
ORDER BY Total_revenue DESC
LIMIT 10;

select * from agri_sales

--SUPPLIER PERFORMANCE

SELECT 
	supplier,
	COUNT(*) AS total_orders,
	SUM(revenue) AS total_revenue,
	AVG(revenue) As Avg_revenue
FROM agri_sales
GROUP BY supplier
ORDER BY total_revenue desc
LIMIT 20;

--REVENUE BY FARM LOCATION

SELECT
	farm_location,
	SUM(revenue) as total_revenue
FROM agri_sales
GROUP BY farm_location
ORDER BY total_revenue desc
LIMIT 20;


--SEASONALITY ( MONTH OF YEAR)

SELECT
	TO_CHAR(sale_date,'MM') AS Month_num,
	TO_CHAR(sale_date, 'MON') AS Month_name,
	SUM(revenue) AS total_revenue
FROM agri_sales
GROUP BY  Month_num, month_name
ORDER BY Total_revenue desc;

--MONTHLY TREND FOR A PRODUCT

SELECT
	DATE_TRUNC( 'month', sale_date)::Date AS month,
	product_name,
	SUM(revenue) as Total_revenue
FROM agri_sales
GROUP BY month, product_name
ORDER BY total_revenue desc;



--------KEY PERFORMANCE QUETIONS---------

--KPQ1: Sales Performance Over Time
--How are total sales and revenue trending month by month?

SELECT DATE_TRUNC('month', sale_date)::date AS month,
       SUM(units_sold) AS total_units,
       SUM(revenue) AS total_revenue
FROM agri_sales
GROUP BY month
ORDER BY month;


--KPQ2: Top & Bottom Products
--Which products generate the highest and lowest revenue?

SELECT 
	product_name, 
	SUM(units_sold) AS total_sold,
	SUM(revenue) as Total_revenue
FROM agri_sales
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 10;

--Regional / Farm Location Performance
--Which farm locations contribute the most sales?

SELECT
	farm_location,
	SUM(units_sold) AS total_units_sold,
	SUM(revenue) as total_revenue,
	ROUND(AVG(revenue)) as avg_revenue
FROM agri_sales
GROUP BY farm_location
ORDER BY total_revenue DESC
LIMIT 5;

--Supplier Contribution & Dependency
--Which suppliers bring the most revenue, and are we over-dependent on a few?

SELECT supplier,
       COUNT(DISTINCT product_id) AS product_count,
       SUM(revenue) AS total_revenue,
       ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM agri_sales),2) AS pct_share
FROM agri_sales
GROUP BY supplier
ORDER BY total_revenue DESC;

--Inventory / Stock Insights
--Which products are at risk of stockouts or overstock?


SELECT 
    product_name,
    SUM(units_on_hand) AS stock_remaining,
    SUM(units_sold) AS total_sold,
    SUM(revenue) AS total_revenue,
    ROUND(SUM(units_on_hand)::numeric / NULLIF(SUM(units_sold),0), 2) AS stock_to_sales_ratio
FROM agri_sales
GROUP BY product_name
ORDER BY stock_remaining ASC
LIMIT 10;

