-- Cumulative Analysis
-- Aggregate the data progressively over time.
-- Helps to understand  whether our business is growing or declining

-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER(ORDER BY order_date) running_total_sales, -- Running total
	AVG(total_sales) OVER(ORDER BY order_date) moving_average_total
FROM(	
	SELECT
		DATETRUNC(month, order_date) order_date,
		SUM(sales_amount) total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t

-- Calculate the total sales per year
-- and the running total of sales over time
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER(ORDER BY order_date) running_total_sales, -- Running total
	AVG(total_sales) OVER(ORDER BY order_date) moving_average_total
FROM(	
	SELECT
		DATETRUNC(YEAR, order_date) order_date,
		SUM(sales_amount) total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(YEAR, order_date)
)t

