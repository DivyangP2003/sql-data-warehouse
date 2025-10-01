/***************************************************************************************************
 Description   :
   This view consolidates sales transaction data for analytical and reporting purposes. It 
   combines CRM sales details with product and customer dimensions to create a fact table 
   suitable for business intelligence and data warehousing.

 Key Features :
   - Links sales transactions to dimensional tables:
       - Customers (gold.dim_customers)
       - Products  (gold.dim_products)
   - Captures transactional metrics such as sales amount, quantity, and unit price
   - Includes key date fields: order date, shipping date, and due date

 Source Tables :
   - silver.crm_sales_details (raw sales transactions)
   - gold.dim_customers        (customer dimension)
   - gold.dim_products         (product dimension)

***************************************************************************************************/

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
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
