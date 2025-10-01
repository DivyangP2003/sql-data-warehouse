/***************************************************************************************************
 Project       : Data Warehouse - Gold Layer Views
 Author        : [Your Name or Team Name]
 Date Created  : [YYYY-MM-DD]
 Last Modified : [YYYY-MM-DD]

 Description   :
   This SQL script creates consolidated views for the Gold layer of the data warehouse. 
   It integrates customer, product, and sales transaction data from multiple source systems
   (CRM and ERP) into dimension and fact tables optimized for analytics and reporting.

   The script includes:
     1. Customer Dimension (gold.dim_customers)
        - Consolidates customer information from CRM and ERP sources.
        - Generates a surrogate customer key.
        - Handles gender prioritization and demographic attributes.
     2. Product Dimension (gold.dim_products)
        - Consolidates product information from CRM and ERP sources.
        - Generates a surrogate product key.
        - Includes product hierarchy, cost, and maintenance information.
        - Only active products are included.
     3. Sales Fact (gold.fact_sales)
        - Links sales transactions to customer and product dimensions.
        - Captures sales metrics such as amount, quantity, and price.
        - Includes key date fields for transaction analysis.

 Notes         :
   - Surrogate keys are generated using ROW_NUMBER() for uniqueness.
   - Left joins are used to ensure all primary records are retained from source systems.
   - Historical products are excluded; only current products are considered.
   - Gender is derived with prioritization logic (CRM > ERP > 'n/a').

 Source Systems :
   - CRM: silver.crm_cust_info, silver.crm_prd_info, silver.crm_sales_details
   - ERP: silver.erp_cust_az12, silver.erp_loc_a101, silver.erp_px_cat_g1v2

***************************************************************************************************/

PRINT '================================================================'
PRINT 'Creating Customer Dimension View'
PRINT '================================================================'

PRINT '>> Dropping gold.dim_customers if it exists...';
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

PRINT '>> Creating gold.dim_customers view...';
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
GO

PRINT 'gold.dim_customers created successfully.';

PRINT '================================================================'
PRINT 'Creating Products Dimension View'
PRINT '================================================================'

PRINT '>> Dropping gold.dim_products if it exists...';
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

PRINT '>> Creating gold.dim_products view...';
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
GO

PRINT 'gold.dim_products created successfully.';

PRINT '================================================================'
PRINT 'Creating Sales Fact View'
PRINT '================================================================'

PRINT '>> Dropping gold.fact_sales if it exists...';
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
PRINT '>> Creating gold.fact_sales view...';
GO
CREATE VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS dc
       ON dc.customer_id = sd.sls_cust_id
LEFT JOIN gold.dim_products AS dp
       ON dp.product_number = sd.sls_prd_key;
GO

PRINT 'gold.fact_sales created successfully.';
