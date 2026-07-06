/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/


-- Which 5 products generate the highest revenue
-- (i)
SELECT TOP 5
	p.product_key,
	p.product_name,
	SUM(f.sales_amount) AS total_sales	
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY p.product_key,
		 p.product_name
ORDER BY total_sales DESC;

-- (ii)
SELECT 
	product_key,
	product_name,
	total_sales
FROM(
	SELECT 
		p.product_key,
		p.product_name,
		SUM(f.sales_amount) AS total_sales,
		ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) DESC) rn
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	GROUP BY p.product_key, p.product_name
	)t
WHERE rn <= 5;

-- What are the 5 worst-performing products in terms of sales
-- (i)
SELECT TOP 5
	p.product_key,
	p.product_name,
	SUM(f.sales_amount) AS total_sales	
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY p.product_key,
		 p.product_name
ORDER BY total_sales ASC;

-- (ii)
SELECT 
	product_key,
	product_name,
	total_sales
FROM(
	SELECT 
		p.product_key,
		p.product_name,
		SUM(f.sales_amount) AS total_sales,
		ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) ASC) rn
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	GROUP BY p.product_key, p.product_name
	)t
WHERE rn <= 5;


-- Find the top 10 customers who have generated the highest revenue
-- (i)
SELECT TOP 10
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_sales DESC;

-- (ii)
SELECT
	customer_key,
	first_name,
	last_name,
	total_sales
FROM(
	SELECT
		c.customer_key,
		c.first_name,
		c.last_name,
		SUM(sales_amount) AS total_sales,
		ROW_NUMBER() OVER(ORDER BY SUM(sales_amount) DESC) rn
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_customers AS c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key, c.first_name, c.last_name
	)t
WHERE rn <= 10;


-- The 3 customers with the fewest orders placed
-- (i)
SELECT TOP 3
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(s.order_number) AS number_of_orders
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = s.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY number_of_orders ASC, c.customer_key ASC;

-- (ii)
SELECT 
	customer_key,
	first_name,
	last_name,
	number_of_orders
FROM(
	SELECT
		c.customer_key,
		c.first_name,
		c.last_name,
		COUNT(s.order_number) AS number_of_orders,
		ROW_NUMBER() OVER(ORDER BY COUNT(s.order_number) ASC) AS rn
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_customers AS c
	ON c.customer_key = s.customer_key
	GROUP BY c.customer_key, c.first_name, c.last_name
	)t
WHERE rn <= 3;