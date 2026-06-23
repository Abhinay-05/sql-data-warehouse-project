/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers' , 'V') IS NOT NULL
	DROP VIEW gold.dim_customers
GO
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for Gender info.
		ELSE COALESCE(ca.GEN, 'n/a')
	END AS gender,
	ca.BDATE AS birthdate,
	ci.cst_create_date AS create_date,
	la.CNTRY AS country
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_CUST_AZ12 AS ca
ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_LOC_A101 AS la
ON ci.cst_key = la.CID;

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products' , 'V') IS NOT NULL
	DROP VIEW gold.dim_products
GO
CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pin.prd_start_dt, pin.prd_key) AS product_key,
	pin.prd_id AS product_id,
	pin.prd_key AS product_number,
	pin.prd_nm AS product_name,
	pin.cat_id AS category_name,
	pc.CAT AS category,
	pc.SUBCAT AS subcategory,
	pc.maintenance ,
	pin.prd_cost AS prduct_cost,
	pin.prd_line AS product_line,
	pin.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pin
LEFT JOIN silver.erp_PX_CAT_G1V2 AS pc
ON pin.cat_id = pc.CID
WHERE pin.prd_end_dt IS NULL; -- Filter out all the historical data

-- =============================================================================
-- Create Dimension: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales' , 'V') IS NOT NULL
	DROP VIEW gold.fact_sales
GO
CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
ON sd.sls_cust_id = cu.customer_id

