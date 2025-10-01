/***************************************************************************************************
 Description   :
   This view consolidates customer information from multiple source systems into a single 
   dimension table for analytical and reporting purposes. It includes:
     - A surrogate customer key (row number)
     - Core customer identifiers (ID, number)
     - Demographics (first name, last name, marital status, gender, birthdate, country)
     - Audit information (customer create date)

 Source Tables :
   - silver.crm_cust_info   (core CRM customer attributes)
   - silver.erp_cust_az12   (ERP customer demographics, gender, birthdate)
   - silver.erp_loc_a101    (ERP customer location details)

 Notes:
   - Gender is derived with a prioritization logic:
       1. Use CRM gender if not 'n/a'
       2. Otherwise, use ERP gender if available
       3. Default to 'n/a' if both are missing
   - The surrogate key is generated using ROW_NUMBER() for uniqueness.
***************************************************************************************************/

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id ASC) AS customer_key,
    ci.cst_id        AS customer_id,
    ci.cst_key       AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname  AS last_name,
    el.cntry         AS country,
    ci.cst_marital_status AS marital_status,
    CASE 
        WHEN ci.cst_gndr = 'n/a' AND (ca.gen = 'n/a' OR ca.gen IS NULL) THEN 'n/a'
        WHEN ci.cst_gndr = 'n/a' THEN ca.gen
        ELSE ci.cst_gndr
    END AS gender,
    ca.bdate         AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info   AS ci
LEFT JOIN silver.erp_cust_az12 AS ca 
       ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS el 
       ON ci.cst_key = el.cid;
