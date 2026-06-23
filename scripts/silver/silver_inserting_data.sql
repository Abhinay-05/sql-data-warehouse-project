/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_procedure;
===============================================================================
*/

-- Inserting into silver layer
CREATE OR ALTER PROCEDURE silver.load_procedure AS
BEGIN
	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
	DECLARE @start_time DATETIME, @end_time DATETIME;
	SET @batch_start_time = GETDATE();
	BEGIN TRY
		PRINT '========================================';
		PRINT 'Loading the Silver Layer';
		PRINT '========================================';

		PRINT '----------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------------------';

		-- crm_customer_information
		SET @start_time = GETDATE();
		PRINT '-> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '-> Inserting Data into Table: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)
		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) cst_firstname,--Remove void spaces
			TRIM(cst_lastname) cst_lastname,--Remove void spaces
			CASE
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END cst_marital_status,-- Set Marital status as full Status
			CASE
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				ELSE 'n/a'
			END cst_gndr,-- Resolving NULL(s) and giving full name to gender
			cst_create_date
		FROM (
			SELECT
				*,
				ROW_NUMBER() OVER(Partition By cst_id Order By cst_create_date DESC) flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t
		WHERE flag_last = 1;--Remove duplicate entries which are not valid
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		--crm_product_information
		SET @start_time = GETDATE();
		PRINT '-> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '-> Inserting Data into Table: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,--Making it valid for Joining
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,--Making it valid for Joining
			prd_nm,
			COALESCE(prd_cost, 0) AS prd_cost,--Treat NULL as 0
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END prd_line, -- Giving value to the product line as specified by business
			CAST(prd_start_dt AS DATE), -- Cast DATETIME as DATE
			CAST(DATEADD(day, -1, LEAD(prd_start_dt) OVER(Partition By prd_key Order By prd_start_dt)) AS DATE) AS prd_end_dt
			-- Resolve end_date < order_date
			-- By taking entries from future dates
		FROM bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		--crm_sales_details
		SET @start_time = GETDATE();
		PRINT '-> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '-> Inserting Data into Table: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			CASE
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)-- Sales IS NULL OR <= 0 OR not equals to our calculation
				THEN sls_quantity * ABS(sls_price) --Calculate it ourselves
				ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE
				WHEN sls_price IS NULL OR sls_price <= 0 -- Price is NULL OR Price <= 0
				THEN sls_sales / NULLIF(sls_quantity, 0) -- Calculate by Setting Quantity as 0 if it is NULL
				ELSE sls_sales
			END AS sls_price 
		FROM bronze.crm_sales_details
		WHERE sls_order_dt < sls_ship_dt OR sls_order_dt < sls_due_dt;
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		PRINT '----------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------------------';
	

		-- erp_CUST_AZ12
		SET @start_time = GETDATE();
		PRINT '-> Truncating Table: silver.erp_CUST_AZ12';
		TRUNCATE TABLE silver.erp_CUST_AZ12;
		PRINT '-> Inserting Data into Table: silver.erp_CUST_AZ12';
		INSERT INTO silver.erp_CUST_AZ12(
			CID,
			BDATE,
			GEN
		)
		SELECT
			CASE
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))--Remove 'NAS' prefix if it is present
				ELSE CID
			END	AS CID,
			CASE
				WHEN BDATE > GETDATE() THEN NULL
				ELSE BDATE
			END AS BDATE,-- Set future birthdates as NULL
			CASE
				WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END GEN--Normalize gender values and handle unknown cases
		FROM bronze.erp_CUST_AZ12
		WHERE BDATE > DATEADD(year, -100, GETDATE())--Filter person whose age > 100
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		-- erp_LOCATION_A101
		SET @start_time = GETDATE();
		PRINT '-> Truncating Table: silver.erp_LOC_A101';
		TRUNCATE TABLE silver.erp_LOC_A101;
		PRINT '-> Inserting Data into Table: silver.erp_LOC_A101';
		INSERT INTO silver.erp_LOC_A101(
			CID,
			CNTRY
		)
		SELECT
			REPLACE(CID, '-', '') CID, -- Remove '-' for Joining
			CASE
				WHEN CNTRY IS NULL OR TRIM(CNTRY) = '' THEN 'n/a'
				WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
				WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United Sates'
				ELSE TRIM(CNTRY)
			END CNTRY -- Normalize and Handle missing or Blank Country Codes
		FROM bronze.erp_LOC_A101;
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		-- erp_PX_CAT_G1V2
		SET @start_time = GETDATE();
		PRINT '-> Truncating Table: silver.erp_PX_CAT_G1V2';
		TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
		PRINT '-> Inserting Data into Table: silver.erp_PX_CAT_G1V2';
		INSERT INTO silver.erp_PX_CAT_G1V2(
			CID,
			CAT,
			SUBCAT,
			MAINTENANCE
		)
		SELECT
			CID,
			CAT,
			SUBCAT,
			MAINTENANCE
		FROM bronze.erp_PX_CAT_G1V2
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

	END TRY
	BEGIN CATCH
		PRINT '========================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'Error Message ' + CAST(ERROR_MESSAGE() AS NVARCHAR);
		PRINT 'Error Number ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '========================================';
	END CATCH
	SET @batch_end_time = GETDATE();
	PRINT 'Silver Layer Execution Complete';
	PRINT '-> Silver Layer Duration: ' + CAST(DATEDIFF(millisecond, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'ms';
END

EXEC silver.load_procedure