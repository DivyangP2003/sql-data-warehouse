/*
============================================================
Load ERP Price Category Records into Silver Layer
============================================================

Script Purpose:
   This script loads ERP price category records from [bronze].[erp_px_cat_g1v2] into [silver].[erp_px_cat_g1v2]. 
   It standardizes IDs to uppercase, trims whitespace from all text fields, and ensures only non-duplicate records are inserted.

WARNING:
   - All IDs are converted to uppercase to maintain consistency.
   - Leading/trailing whitespace in category, subcategory, and maintenance fields is removed.
   - Duplicate IDs are prevented by checking the silver table.
*/

INSERT INTO [silver].[erp_px_cat_g1v2] (
    id,
    cat,
    subcat,
    maintenance
)
SELECT *
FROM (
    SELECT 
        UPPER(id) AS id,       -- Standardize ID to uppercase
        TRIM(cat) AS cat,      -- Remove leading/trailing spaces
        TRIM(subcat) AS subcat,
        TRIM(maintenance) AS maintenance
    FROM [bronze].[erp_px_cat_g1v2]
) b
WHERE NOT EXISTS (
    SELECT 1 
    FROM [silver].[erp_px_cat_g1v2] AS s 
    WHERE s.id = b.id
); -- Prevent duplicates in silver
