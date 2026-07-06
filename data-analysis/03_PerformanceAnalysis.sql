-- Performance Analysis

-- Comparing the current values to a target value.
-- Helps measure success and compare performance.

/*
Analyse the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sale
*/
WITH CTE_yearly_product_sales AS
(
	SELECT
		p.product_name AS product_name,
		YEAR(s.order_date) order_year,
		SUM(s.sales_amount) current_year_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(s.order_date), p.product_name
)

SELECT
	product_name,
	order_year,
	current_year_sales,
	AVG(current_year_sales) OVER(PARTITION BY product_name) AS average_sales,
	current_year_sales - AVG(current_year_sales) OVER(PARTITION BY product_name) AS comparison_with_avg_sales,
	CASE 
		WHEN current_year_sales - AVG(current_year_sales) OVER(PARTITION BY product_name)>0 THEN 'Higer than Average'
		WHEN current_year_sales - AVG(current_year_sales) OVER(PARTITION BY product_name)=0 THEN 'Equal to Average'
		ELSE 'Less than Average'
	END AS avg_flag,
	LAG(current_year_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS last_year_sales,
	current_year_sales - LAG(current_year_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS comparison_with_last_year_sales,
	CASE
		WHEN current_year_sales - LAG(current_year_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Higher than Last year'
		WHEN current_year_sales - LAG(current_year_sales) OVER(PARTITION BY product_name ORDER BY order_year) = 0 THEN 'Equal to Last Year'
		WHEN current_year_sales - LAG(current_year_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Less than last Year'
		ELSE 'No Record'
	END AS last_year_flag
FROM CTE_yearly_product_sales
