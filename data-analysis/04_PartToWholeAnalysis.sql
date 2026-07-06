-- Proportional Analysis

/* 
	Analyse how an individual part is performing compared to the overall,
	allowing us to understand which category has the gratest impact on the business.
*/
USE DataWarehouse;

-- Which category contributes the most to the overall sales
WITH CTE_Sales_By_Category AS
(
	SELECT
		DISTINCT p.category AS category,
		SUM(s.sales_amount) OVER(PARTITION BY p.category)sales_of_category,
		SUM(s.sales_amount) OVER() total_sales,
		ROUND((SUM(s.sales_amount) OVER(PARTITION BY p.category)*100.0 / SUM(s.sales_amount) OVER()), 2) sales_percentage
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key 
	WHERE order_date IS NOT NULL
)
SELECT
	*
FROM CTE_Sales_By_Category
WHERE sales_percentage = (SELECT MAX(sales_percentage) FROM CTE_Sales_By_Category);