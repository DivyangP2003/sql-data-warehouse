/***************************************************************************************************
 Description   :
   This view consolidates product information from CRM and ERP systems into a single dimension 
   table for analytical and reporting purposes. It includes:
     - A surrogate product key (row number)
     - Core product identifiers (ID, number, name)
     - Product hierarchy details (category, subcategory, product line)
     - Cost and maintenance information
     - Product start date (currently active products only)

 Source Tables :
   - silver.crm_prd_info       (core CRM product attributes)
   - silver.erp_px_cat_g1v2    (ERP product category and hierarchy details)

 Notes:
   - The surrogate key is generated using ROW_NUMBER() for uniqueness.
   - Only currently active products are included (prd_end_dt IS NULL).
   - Historical products are excluded from this view.
***************************************************************************************************/

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cp.prd_start_dt, cp.prd_key) AS product_key,
    cp.prd_id        AS product_id,
    cp.prd_key       AS product_number,
    cp.prd_nm        AS product_name,
    cp.cat_id        AS category_id,
    ep.cat           AS category_name,
    ep.subcat        AS subcategory_name,
    ep.maintenance   AS maintenance,
    cp.prd_cost      AS product_cost,
    cp.prd_line      AS product_line,
    cp.prd_start_dt  AS product_start_date
FROM silver.crm_prd_info AS cp
LEFT JOIN silver.erp_px_cat_g1v2 AS ep
       ON cp.cat_id = ep.id
WHERE cp.prd_end_dt IS NULL;  -- Selecting only current products, filtering out historical products
