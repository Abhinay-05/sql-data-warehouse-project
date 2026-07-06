-- Data Segmentation

/*
	Group the data bases in specific range.
	Helps understand the correlation between two measures.
*/

-- Segment products into cost range
-- Count how many products fall into each segment
WITH CTE_ProductCost_Segment AS(
	SELECT
		product_name,
		category,
		product_cost,
		CASE
			WHEN product_cost = 0 THEN '0'
			WHEN product_cost < 100 THEN 'Below 100'
			WHEN product_cost BETWEEN 101 AND 500 THEN '101 - 500'
			WHEN product_cost BETWEEN 501 AND 1000 THEN '501 - 1000'
			WHEN product_cost BETWEEN 1001 AND 1500 THEN '1001 - 1500'
			WHEN product_cost BETWEEN 1501 AND 2000 THEN '1501 - 2000'
			ELSE '2000+'
		END cost_range
	FROM gold.dim_products 
	WHERE product_key IS NOT NULL
	)
SELECT
	cost_range,
	COUNT(*) number_of_products
FROM CTE_ProductCost_Segment
GROUP BY cost_range
ORDER BY COUNT(*)


/*
	Group customers into three segments based on their spending behavior:
		- VIP: Customers with at least 12 months of history and spending more than €5,000.
		- Regular: Customers with at least 12 months of history but spending €5,000 or less.
		- New: Customers with a lifespan less than 12 months.
	And find the total number of customers by each group
*/
WITH CTE_customer_order_duration AS(
SELECT
	s.customer_key,
	MIN(s.order_date) first_order_date,
	MAX(s.order_date) last_order_date,
	DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) lifespan,
	SUM(sales_amount) AS spending
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY s.customer_key
),

CTE_customer_segmentation AS
(
	SELECT
		customer_key,
		spending 'spending(€)',
		lifespan 'lifespan(Months)',
		CASE 
			WHEN lifespan >= 12 THEN
				CASE 
					WHEN spending > 5000 THEN 'VIP'
					ELSE 'Regular'
				END
			ELSE 'New'
		END customer_category
	FROM CTE_customer_order_duration
)

SELECT
	customer_category,
	COUNT(customer_key) AS number_of_customers
FROM CTE_customer_segmentation
GROUP BY customer_category
ORDER BY COUNT(customer_key) DESC