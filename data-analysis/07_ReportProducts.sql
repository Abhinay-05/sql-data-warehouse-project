/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products
GO

CREATE VIEW gold.report_products AS
/*
Derived from :-
    (i) gold.fact_sales
    (ii) gold.dim_products
*/    

/*
---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------
*/
WITH CTE_base_query AS(
    SELECT
        s.order_number,
        s.product_key,
        s.customer_key,
        p.product_name,
        p.category,
        p.subcategory,
        s.quantity,
        p.product_cost,
        s.sales_amount,
        s.order_date,
        p.start_date
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL -- no invalid states allowed
)

/*
---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------
*/
, CTE_product_aggregation AS(
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        product_cost,
        start_date,
        MAX(order_date) last_order_date,
        DATEDIFF(month, start_date, MAX(order_date)) lifespan, -- lastOrderDate - ProductStartDate in months
        SUM(sales_amount) total_sales,
        COUNT(DISTINCT customer_key) total_customers,
        COUNT(DISTINCT order_number) number_of_orders,
        SUM(quantity) total_quantity
    FROM CTE_base_query
    GROUP BY product_key, product_name, category, subcategory, product_cost, start_date
)


/*
---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------
*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    product_cost,
    start_date,
    last_order_date,
    DATEDIFF(month, last_order_date, GETDATE()) months_since_last_order, -- currentDate - lastOrderDate in months
    lifespan,
    -- Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND((total_sales*1.0 / lifespan), 2)
    END avg_monthly_sales,
    total_sales,
    -- Categorization Of Products According 
    CASE
        WHEN total_sales > 50000 THEN 'High'
        WHEN total_sales >=  10000 THEN 'Medium'
        ELSE 'Low'
    END product_performance,
    total_customers,
    number_of_orders,
    -- Average Order Values
    CASE
        WHEN number_of_orders = 0 THEN 0
        ELSE ROUND((total_sales*1.0 / number_of_orders), 2)
    END avg_order_value,
    total_quantity
FROM CTE_product_aggregation