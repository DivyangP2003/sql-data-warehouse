/*
============================================================
Load ERP Customer Location Records into Silver Layer
============================================================

Script Purpose:
   This script loads ERP customer location records from [bronze].[erp_loc_a101] into [silver].[erp_loc_a101]. 
   It standardizes customer IDs, normalizes country names and handles null or empty values.

WARNING:
   - Hyphens in customer IDs are removed.
   - Country names are normalized to standard values (e.g., 'Germany', 'USA').
   - Null or empty country values are set to 'n/a'.
   - Duplicate customer IDs are prevented by checking the silver table.
*/

INSERT INTO [silver].[erp_loc_a101] (
    cid,
    cntry
)
SELECT *
FROM (
    SELECT
        TRIM(REPLACE(cid,'-','')) AS cid,                                          -- Remove hyphens from customer ID
        CASE
            WHEN TRIM(cntry) IN ('DE','Germany') THEN 'Germany'
            WHEN TRIM(cntry) IN ('USA','US','United States') THEN 'USA'
            WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'                -- Handle null/empty
            ELSE TRIM(cntry)                                                       -- Keep other country values as-is
        END AS cntry
    FROM [bronze].[erp_loc_a101]
) b
WHERE NOT EXISTS (
    SELECT 1 
    FROM [silver].[erp_loc_a101] AS s 
    WHERE s.cid = b.cid
);                                                                                 -- Prevent duplicates in silver
