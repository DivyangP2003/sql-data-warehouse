/*
============================================================
Load Product Records into Silver Layer
============================================================

Script Purpose:
   This script loads product records from [bronze].[crm_prd_info] into [silver].[crm_prd_info]. 
   It standardizes product keys, trims values where necessary, applies default values for null product costs, maps product lines to descriptive names, 
   and calculates product end dates based on the next product's start date.

WARNING:
   - Existing records in silver are not overwritten; duplicates are prevented.
   - Any unmapped or null product line values are set to 'n/a'.
   - Ensure product key format assumptions remain consistent with source data.
*/

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
SELECT *
FROM (
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
) b
WHERE NOT EXISTS (
    SELECT 1 
    FROM [silver].[crm_prd_info] AS s 
    WHERE s.prd_id = b.prd_id
);                                                                  -- Prevent duplicates in silver
