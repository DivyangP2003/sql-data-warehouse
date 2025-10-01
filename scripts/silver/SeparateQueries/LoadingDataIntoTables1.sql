/*
============================================================
Load Latest Unique Customer Records into Silver Layer
============================================================

Script Purpose:
   This script loads the latest unique customer records from [bronze].[crm_cust_info] into [silver].[crm_cust_info]. 
   It applies basic data cleansing (trimming names, normalizing gender and marital status values) and prevents duplicate inserts.

WARNING:
   - Only the most recent record per customer (based on cst_create_date) is inserted into the silver table.  
   - Any unmapped or null marital status/gender values are set to 'n/a'.  
   - Ensure business mappings ('M'/'S'/'F') align with source system definitions.
*/

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
  AND NOT EXISTS (
        SELECT 1 
        FROM [silver].[crm_cust_info] AS s 
        WHERE s.cst_id = b.cst_id
    );                          -- Prevent inserting duplicates into silver
