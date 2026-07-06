/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
	DROP VIEW gold.report_customers
GO

CREATE VIEW gold.report_customers AS
/*
Derived from :-
    (i) gold.fact_sales
    (ii) gold.dim_customers
*/    

/*
---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------
*/
WITH CTE_base_query AS
(
	SELECT
		s.order_number,
		s.product_key,
		s.order_date,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name , ' ' , c.last_name) customer_name,
		DATEDIFF(YEAR, c.birthdate, GETDATE()) customer_age
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_customers AS c
	ON s.customer_key = c.customer_key
	WHERE s.order_date IS NOT NULL
)
/*
---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------
*/
, CTE_customer_aggregation AS
(
	SELECT
		customer_key,
		customer_number,
		customer_name,
		customer_age,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order_date,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) lifespan
	FROM CTE_base_query
	GROUP BY customer_key, customer_number, customer_name, customer_age
)

SELECT
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	DATEDIFF(MONTH, last_order_date, GETDATE()) months_since_last_order,
	lifespan,
	CASE 
		WHEN lifespan >= 12 THEN
			CASE 
				WHEN total_sales > 5000 THEN 'VIP'
				ELSE 'Regular'
			END
		ELSE 'New'
	END customer_category,
	CASE
		WHEN customer_age < 20 THEN 'Under 20'
		WHEN customer_age < 29 THEN '20 - 29'
		WHEN customer_age < 39 THEN '30 - 39'
		WHEN customer_age < 49 THEN '40 - 49'
		ELSE '50 and above'
	END age_group,
	-- Average Order Value
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE ROUND((total_sales*1.0 / total_orders), 2)
	END avg_order_value,
	-- Average Monthly Spent
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE ROUND((total_sales*1.0 / lifespan), 2)
	END avg_monthly_spent
FROM CTE_customer_aggregation