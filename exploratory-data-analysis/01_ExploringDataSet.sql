/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
===============================================================================
*/

USE DataWarehouse;

-- Explore all objects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Explore all Columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

-- Explore All Countries our Customers come from
SELECT DISTINCT country from gold.dim_customers

-- Explore all categories 
SELECT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1, 2, 3

-- Find the date of the first and last order
SELECT	MIN(order_date) first_order_date,
		MAX(order_date) last_order_date,
		DATEDIFF(year, MIN(order_date), MAX(order_date)) order_range_years,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) order_range_months
FROM gold.fact_sales


-- Find the youngest and the oldest customer
SELECT
	MAX(birthdate) youngest_birthdate,
	DATEDIFF(year, MAX(birthdate), GETDATE()) youngest_customer,
	MIN(birthdate) oldest_birthdate,
	DATEDIFF(year, MIN(birthdate), GETDATE()) oldest_customer
FROM gold.dim_customers

