/*
============================================================
Load Sales Details into Silver Layer
============================================================

Script Purpose:
   This script loads sales transaction details from [bronze].[crm_sales_details] into [silver].[crm_sales_details]. 
   It performs data validation for dates and calculates missing sales or price values where necessary

WARNING:
   - Records with invalid dates (outside 1900-01-01 to 2050-01-01) are set to NULL.
   - Sales and price values are recalculated if inconsistencies are detected.
   - Duplicate inserts are prevented by checking for existing customer IDs in silver.
*/

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
SELECT *
FROM (
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
) b
WHERE NOT EXISTS (
    SELECT 1 
    FROM [silver].[crm_sales_details] AS s 
    WHERE s.sls_cust_id = b.sls_cust_id
); -- Prevent duplicates in silver
