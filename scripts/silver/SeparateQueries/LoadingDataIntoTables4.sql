/*
============================================================
Load ERP Customer Records into Silver Layer
============================================================

Script Purpose:
   This script loads ERP customer records from [bronze].[erp_cust_az12] into [silver].[erp_cust_az12]. 
   It standardizes customer IDs, validates birth dates and normalizes gender values.

WARNING:
   - Customer IDs starting with 'NAS' are modified to remove the prefix.
   - Birth dates outside the range 1925-01-01 to today are set to NULL.
   - Unmapped or invalid gender values are set to 'n/a'.
   - Duplicate customer IDs are prevented by checking the silver table.
*/

INSERT INTO [silver].[erp_cust_az12] (
    cid,
    bdate,
    gen
)
SELECT *
FROM (
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
) b
WHERE NOT EXISTS (
    SELECT 1 
    FROM [silver].[erp_cust_az12] AS s 
    WHERE s.cid = b.cid
);                                                                      -- Prevent duplicates in silver
