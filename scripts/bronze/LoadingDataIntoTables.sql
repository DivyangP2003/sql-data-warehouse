/*
============================================================
Load Bronze-Level CRM and ERP Data
============================================================

Script Purpose:
   This procedure loads data into bronze-level tables for CRM and ERP sources within the 'DataWarehouse' database.
   Existing data in these tables is truncated before loading to ensure a fresh dataset.

WARNING:
   Running this procedure will permanently delete all existing data in the bronze tables. 
   Use with caution.

USAGE:
	To load the data into respective tables run the following query:
	USE DataWarehouse;
	GO
	EXEC bronze.load_bronze;
	GO
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME, @start_time_batch DATETIME, @end_time_batch DATETIME, @start_time_bronze DATETIME, @end_time_bronze DATETIME;
	BEGIN TRY
		SET @start_time_bronze = GETDATE();

		SET @start_time_batch = GETDATE();
		PRINT '==========================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '==========================================================';

		PRINT '----------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------------------------------------';

		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting Data into : bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\divya.LAPTOP-0B1GN7G7\Desktop\sql-ultimate-course\DivyangSQL\Projects\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time  = GETDATE();
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------'

		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '>> Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\divya.LAPTOP-0B1GN7G7\Desktop\sql-ultimate-course\DivyangSQL\Projects\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time  = GETDATE();
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------'

		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting Data into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\divya.LAPTOP-0B1GN7G7\Desktop\sql-ultimate-course\DivyangSQL\Projects\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time  = GETDATE();
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------'

		SET @end_time_batch = GETDATE();
		PRINT '>> Load Duration for CRM Tables: '+ CAST(DATEDIFF(second,@start_time_batch,@end_time_batch) AS NVARCHAR) + ' seconds'
		PRINT '----------------------------------------------------------';


		SET @start_time_batch = GETDATE();
		PRINT '----------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------------------------------------';


		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting Data into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\divya.LAPTOP-0B1GN7G7\Desktop\sql-ultimate-course\DivyangSQL\Projects\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time  = GETDATE();
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------'

		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> Inserting Data into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\divya.LAPTOP-0B1GN7G7\Desktop\sql-ultimate-course\DivyangSQL\Projects\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time  = GETDATE();
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------'

		SET @start_time  = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\divya.LAPTOP-0B1GN7G7\Desktop\sql-ultimate-course\DivyangSQL\Projects\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time  = GETDATE();
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------'
		
		SET @end_time_batch = GETDATE();
		PRINT '>> Load Duration for ERP Tables: '+ CAST(DATEDIFF(second,@start_time_batch,@end_time_batch) AS NVARCHAR) + ' seconds'
		PRINT '----------------------------------------------------------';

		SET @end_time_bronze = GETDATE();
		PRINT '==========================================================';
		PRINT 'LOADING BRONZE LAYER IS COMPLETED'
		PRINT '>> Load Duration for Bronze Layer: '+ CAST(DATEDIFF(second,@start_time_bronze,@end_time_bronze) AS NVARCHAR) + ' seconds'
		PRINT '==========================================================';


	END TRY
	BEGIN CATCH
		PRINT '==========================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE: '+ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: '+CAST(ERROR_NUMBER()AS NVARCHAR);
		PRINT '==========================================================';

	END CATCH

END
