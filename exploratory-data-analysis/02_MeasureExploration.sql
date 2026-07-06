/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
===============================================================================
*/

-- Find Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

-- Find how many items are sold
SELECT SUM(quantity) number_of_items_sold FROM gold.fact_sales

-- Find the average selling price
SELECT AVG(price) average_price FROM gold.fact_sales

-- Find the total number of orders
SELECT COUNT(DISTINCT order_number) total_number_of_orders FROM gold.fact_sales

-- Find total number of products
SELECT COUNT(DISTINCT product_id) AS number_of_products FROM gold.dim_products

-- Find total number of customers
SELECT COUNT(DISTINCT customer_id) AS number_of_customers FROM gold.dim_customers

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS number_of_customers_that_placed_an_order FROM gold.fact_sales


-- Genarate a Report that shows all key metrics of hte business 
SELECT 'Total Sales' AS measure_name,SUM(sales_amount) AS measure_values FROM gold.fact_sales
	UNION ALL
SELECT 'Total Quantity' AS measure_name,SUM(quantity) AS measure_values FROM gold.fact_sales
	UNION ALL
SELECT 'Average Price' AS measure_name,AVG(price) AS measure_values FROM gold.fact_sales
	UNION ALL
SELECT 'Total Number Of Orders' AS measure_name,COUNT(DISTINCT order_number) AS measure_values FROM gold.fact_sales
	UNION ALL
SELECT 'Total Number of Products', COUNT(DISTINCT product_id) AS measure_values FROM gold.dim_products
	UNION ALL
SELECT 'Total Number of Customers', COUNT(DISTINCT customer_id) AS measure_values FROM gold.dim_customers
	UNION ALL
SELECT 'Total Number of Customers that placed an Order', COUNT(DISTINCT customer_key) AS measure_values FROM gold.fact_sales
