/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This procedure loads the data into 'bronze' schema tables from external CSV files
	This performs the following actions:
	-> Truncates the table
	-> Inserts data into the tables

Additional Features:
	Defines the time duration of the:
	-> Program in milliseconds(ms).
	-> Every single Table insertion

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.
	  This stored procedure handles errors via try and catch blocks.

Usage Example:
    EXEC bronze.load_procedure;
===============================================================================
*/


-- FULL LOAD
CREATE OR ALTER PROCEDURE bronze.load_procedure AS
BEGIN
	DECLARE @bronze_start_time DATETIME, @bronze_end_time DATETIME;
	DECLARE @start_time DATETIME, @end_time DATETIME;
	SET @bronze_start_time = GETDATE();
	BEGIN TRY
		PRINT '========================================';
		PRINT 'Loading the Bronze Layer';
		PRINT '========================================';

		PRINT '----------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------------------';

		-- 1.
		SET @start_time = GETDATE();
		PRINT ' -> Truncating Table: bronze.crm_cust_info'
		-- Make table empty
		TRUNCATE TABLE bronze.crm_cust_info;
		-- Load Full data
		PRINT '->Inserting Data Into: bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		-- 2.
		SET @start_time = GETDATE();
		PRINT ' -> Truncating Table: bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '->Inserting Data Into: bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		-- 3.
		SET @start_time = GETDATE();
		PRINT ' -> Truncating Table: crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '->Inserting Data Into: crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';


		PRINT '----------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------------------';

		-- 4.
		SET @start_time = GETDATE();
		PRINT ' -> Truncating Table: bronze.erp_CUST_AZ12'
		TRUNCATE TABLE bronze.erp_CUST_AZ12;
		PRINT '->Inserting Data Into: bronze.erp_CUST_AZ12'
		BULK INSERT bronze.erp_CUST_AZ12
		FROM 'D:\SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		-- 5.
		SET @start_time = GETDATE();
		PRINT ' -> Truncating Table: bronze.erp_LOC_A101'
		TRUNCATE TABLE bronze.erp_LOC_A101;
		PRINT '->Inserting Data Into: bronze.erp_LOC_A101'
		BULK INSERT bronze.erp_LOC_A101
		FROM 'D:\SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';

		-- 6.
		SET @start_time = GETDATE();
		PRINT ' -> Truncating Table: bronze.erp_PX_CAT_G1V2'
		TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;
		PRINT '->Inserting Data Into: bronze.erp_PX_CAT_G1V2'
		BULK INSERT bronze.erp_PX_CAT_G1V2
		FROM 'D:\SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '-> Load Duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT'- - - - - - - - - - - - - - - - - - - - - ';
	END TRY
	BEGIN CATCH
		PRINT '========================================';
		PRINT 'ERROR OCCURED DURING LADING BRONZE LAYER';
		PRINT 'Error Message ' + CAST(ERROR_MESSAGE() AS NVARCHAR);
		PRINT 'Error Number ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '========================================';
	END CATCH

	SET @bronze_end_time = GETDATE();
	PRINT 'Bronze Layer Execution Complete';
	PRINT '-> Bronze Layer Duration: ' + CAST(DATEDIFF(millisecond, @bronze_start_time, @bronze_end_time) AS NVARCHAR) + 'ms';
END

EXEC bronze.load_procedure;