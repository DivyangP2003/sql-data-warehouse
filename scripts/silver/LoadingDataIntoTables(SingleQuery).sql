/*
============================================================
Silver Layer ETL: Load and Standardize Data from Bronze
============================================================

Script Purpose:
   This ETL script loads data from various bronze tables into corresponding silver tables.
   Key operations include:
     - Data cleansing (trimming, normalizing values, handling nulls)
     - Standardization of IDs, keys, and categorical fields
     - Date validation and correction
     - Calculation of derived fields where necessary (e.g., product end dates, sales/price)
General Notes:
   - All silver tables are truncated before loading, so each run completely refreshes the dataset.
   - Only the most recent records per primary key are selected where applicable (e.g., customers).
   - Unmapped or null categorical fields are standardized to 'n/a'.
   - Date fields are validated; invalid dates are set to NULL.
   - Business rules and mappings (gender, marital status, product lines, country names) must align with source definitions.
   - Any changes to source structure or key formats should be reflected in this script.

WARNING:
   Running this procedure will permanently delete all existing data in the bronze tables. 
   Use with caution.

Tables Affected:
   - [silver].[crm_cust_info]
   - [silver].[crm_prd_info]
   - [silver].[crm_sales_details]
   - [silver].[erp_cust_az12]
   - [silver].[erp_loc_a101]
   - [silver].[erp_px_cat_g1v2]

Usage:
	To load the data into respective tables run the following query:
	USE DataWarehouse;
	GO
	EXEC silver.load_silver;
	GO
============================================================
*/

USE DataWarehouse;
GO
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time Date, @end_time Date
    SET @start_time = GETDATE();
    PRINT '==========================================================';
	PRINT 'Loading Silver Layer';
	PRINT '==========================================================';
    
	PRINT '----------------------------------------------------------';
	PRINT 'Loading CRM Tables';
	PRINT '----------------------------------------------------------';

    BEGIN TRY
        PRINT '>> Truncating Table: silver.crm_cust_info'
        TRUNCATE TABLE [silver].[crm_cust_info];    
        PRINT '>> Loading Data into : silver.crm_cust_info';

        INSERT INTO [silver].[crm_cust_info] (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
                WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
                ELSE 'n/a'                 
            END AS cst_marital_status,
            CASE 
                WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
                WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
                ELSE 'n/a' 
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS row_cst
            FROM [bronze].[crm_cust_info]
        ) b
        WHERE cst_id IS NOT NULL        -- Avoid inserting records without valid IDs
          AND row_cst = 1               -- Keep only the latest record per customer

        PRINT '---------------------'
        
        PRINT '>> Truncating Table: bronze.crm_prd_info'
        TRUNCATE TABLE [silver].[crm_prd_info];
        PRINT '>> Loading Data into: bronze.crm_prd_info';

        INSERT INTO [silver].[crm_prd_info] (
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
            REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS prd_cat_id,      -- Extract category ID from product key
            TRIM(SUBSTRING(prd_key,7,LEN(prd_key))) AS prd_key,         -- Clean product key
            prd_nm,                                                     -- No trimming needed
            COALESCE(prd_cost,0) AS prd_cost,                           -- Default cost for nulls
            CASE 
                WHEN UPPER(prd_line) = 'M' THEN 'Mountain'
                WHEN UPPER(prd_line) = 'R' THEN 'Road'
                WHEN UPPER(prd_line) = 'S' THEN 'Other Sales'
                WHEN UPPER(prd_line) = 'T' THEN 'Touring'
                ELSE 'n/a' -- Default for unmapped/null values
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            DATEADD(
                DAY,
                -1,
                CAST(
                    LEAD(prd_start_dt,1,NULL) OVER(
                        PARTITION BY prd_key 
                        ORDER BY prd_start_dt ASC
                    ) AS DATE
                )
            ) AS prd_end_dt                                             -- End date is day before next product start date
        FROM [bronze].[crm_prd_info]
                                                                
		PRINT '---------------------'

		PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE [silver].[crm_sales_details];
		PRINT '>> Loading Data into: bronze.crm_sales_details';

        INSERT INTO [silver].[crm_sales_details] (
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
            CASE 
                WHEN ISDATE(sls_order_dt) = 1 AND sls_order_dt > 19000101 AND sls_order_dt < 20500101  
                    THEN CAST(CAST(sls_order_dt AS NVARCHAR(10)) AS DATE)
                ELSE NULL
            END AS sls_order_dt,  -- Validate order date
            CASE 
                WHEN ISDATE(sls_ship_dt) = 1 AND sls_ship_dt > 19000101 AND sls_ship_dt < 20500101 
                    THEN CAST(CAST(sls_ship_dt AS NVARCHAR(10)) AS DATE)
                ELSE NULL
            END AS sls_ship_dt,   -- Validate ship date
            CASE 
                WHEN ISDATE(sls_due_dt) = 1 AND sls_due_dt > 19000101 AND sls_due_dt < 20500101 
                    THEN CAST(CAST(sls_due_dt AS NVARCHAR(10)) AS DATE)
                ELSE NULL
            END AS sls_due_dt,    -- Validate due date
            CASE 
                WHEN sls_price IS NOT NULL AND (sls_sales IS NULL OR sls_sales != sls_price * sls_quantity) 
                    THEN ABS(sls_price) * ABS(sls_quantity)
                ELSE ABS(sls_sales)
            END AS sls_sales,     -- Recalculate sales if inconsistent
            sls_quantity,
            CASE 
                WHEN sls_price IS NULL AND sls_sales IS NOT NULL 
                    THEN ABS(sls_sales) / ABS(sls_quantity)
                ELSE ABS(sls_price)
            END AS sls_price      -- Recalculate price if missing
        FROM [bronze].[crm_sales_details]

        PRINT '----------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------------------------------------';


		PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE [silver].[erp_cust_az12];
        PRINT '>> Loading Data into: bronze.erp_cust_az12';

        INSERT INTO [silver].[erp_cust_az12] (
            cid,
            bdate,
            gen
        )
    
        SELECT 
            CASE 
                WHEN cid LIKE 'NAS%' THEN REPLACE(cid,'NAS','')             -- Remove 'NAS' prefix
                ELSE cid
            END AS cid,
            CASE 
                WHEN bdate > GETDATE() OR bdate < '1925-01-01' THEN NULL    -- Validate birth date
                ELSE bdate
            END AS bdate,
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
                ELSE 'n/a'                                                  -- Default for unmapped/null values
            END AS gen
        FROM [bronze].[erp_cust_az12]
                                                                    
		PRINT '---------------------'

		PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE [silver].[erp_loc_a101];
        PRINT '>> Loading Data into: bronze.erp_loc_a101';

        INSERT INTO [silver].[erp_loc_a101] (
            cid,
            cntry
        )

        SELECT
            TRIM(REPLACE(cid,'-','')) AS cid,                                          -- Remove hyphens from customer ID
            CASE
                WHEN TRIM(cntry) IN ('DE','Germany') THEN 'Germany'
                WHEN TRIM(cntry) IN ('USA','US','United States') THEN 'USA'
                WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'                -- Handle null/empty
                ELSE TRIM(cntry)                                                       -- Keep other country values as-is
            END AS cntry
        FROM [bronze].[erp_loc_a101]
                                                                  
		PRINT '---------------------'
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE [silver].[erp_px_cat_g1v2];
		PRINT '>> Loading Data into: bronze.erp_px_cat_g1v2';

        INSERT INTO [silver].[erp_px_cat_g1v2] (
            id,
            cat,
            subcat,
            maintenance
        )

        SELECT 
            UPPER(id) AS id,       -- Standardize ID to uppercase
            TRIM(cat) AS cat,      -- Remove leading/trailing spaces
            TRIM(subcat) AS subcat,
            TRIM(maintenance) AS maintenance
        FROM [bronze].[erp_px_cat_g1v2]

        SET @end_time = GETDATE();

    END TRY
    BEGIN CATCH
        PRINT '======================================================='
        PRINT 'Error loading data into Silver Layer: '+ERROR_MESSAGE();
        PRINT '======================================================='
    END CATCH
    PRINT '==========================================================';
    PRINT 'All Silver Layer loads completed successfully!';
    PRINT '>> Total Time Taken: '+CAST(DATEDIFF(second,@start_time,@end_time)AS NVARCHAR(50))+' seconds';
    PRINT '==========================================================';

END
