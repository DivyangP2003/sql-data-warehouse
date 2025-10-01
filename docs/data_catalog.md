# 📊 Data Catalog — Gold Layer

## Overview
The **Gold Layer** represents the **business-level data model**, designed to support **analytics and reporting**.  
It is structured into **dimension tables** and **fact tables**, enabling efficient querying and consistent metric definitions.

---

## 📂 Dimension Tables

### 1. `gold.dim_customers`
**Purpose:** Stores customer details enriched with demographic and geographic data.  

| Column Name     | Data Type     | Description                                                                                   |
|-----------------|---------------|-----------------------------------------------------------------------------------------------|
| **customer_key**    | INT           | Surrogate key uniquely identifying each customer record.                                     |
| **customer_id**     | INT           | Unique numerical identifier assigned to each customer.                                        |
| **customer_number** | NVARCHAR(50)  | Alphanumeric identifier representing the customer, used for tracking and referencing.         |
| **first_name**      | NVARCHAR(50)  | Customer's first name.                                                                       |
| **last_name**       | NVARCHAR(50)  | Customer's last/family name.                                                                 |
| **country**         | NVARCHAR(50)  | Country of residence (e.g., *Australia*).                                                    |
| **marital_status**  | NVARCHAR(50)  | Marital status (e.g., *Married*, *Single*).                                                  |
| **gender**          | NVARCHAR(50)  | Gender (e.g., *Male*, *Female*, *n/a*).                                                      |
| **birthdate**       | DATE          | Date of birth (YYYY-MM-DD, e.g., *1971-10-06*).                                              |
| **create_date**     | DATE          | Record creation date.                                                                        |

---

### 2. `gold.dim_products`
**Purpose:** Provides descriptive attributes and classifications for products.  

| Column Name          | Data Type     | Description                                                                                   |
|----------------------|---------------|-----------------------------------------------------------------------------------------------|
| **product_key**      | INT           | Surrogate key uniquely identifying each product record.                                       |
| **product_id**       | INT           | Unique identifier for internal tracking.                                                      |
| **product_number**   | NVARCHAR(50)  | Alphanumeric product code, often used for inventory.                                          |
| **product_name**     | NVARCHAR(50)  | Descriptive name (e.g., type, color, size).                                                   |
| **category_id**      | NVARCHAR(50)  | Identifier linking product to its high-level category.                                        |
| **category**         | NVARCHAR(50)  | Broad product classification (e.g., *Bikes*, *Components*).                                  |
| **subcategory**      | NVARCHAR(50)  | More detailed product classification.                                                         |
| **maintenance_required** | NVARCHAR(50) | Indicates if product requires maintenance (*Yes* / *No*).                                    |
| **cost**             | INT           | Base product cost (in whole currency units).                                                  |
| **product_line**     | NVARCHAR(50)  | Specific product line (e.g., *Road*, *Mountain*).                                             |
| **start_date**       | DATE          | Date product became available for sale.                                                       |

---

## 📂 Fact Tables

### 3. `gold.fact_sales`
**Purpose:** Stores transactional sales data for analytics.  

| Column Name     | Data Type     | Description                                                                                   |
|-----------------|---------------|-----------------------------------------------------------------------------------------------|
| **order_number** | NVARCHAR(50)  | Unique alphanumeric identifier for sales order (e.g., *SO54496*).                             |
| **product_key**  | INT           | Foreign key linking to `dim_products`.                                                        |
| **customer_key** | INT           | Foreign key linking to `dim_customers`.                                                       |
| **order_date**   | DATE          | Date when the order was placed.                                                               |
| **shipping_date**| DATE          | Date when the order was shipped.                                                              |
| **due_date**     | DATE          | Date when payment was due.                                                                    |
| **sales_amount** | INT           | Total sale value for the line item (whole currency units).                                    |
| **quantity**     | INT           | Number of product units ordered.                                                              |
| **price**        | INT           | Price per unit of the product (whole currency units).                                         |

---

## 📐 Entity Relationship Diagram (ERD)

Below is the visual representation of the Gold Layer data model:

![Gold Layer ERD](/data_model.png)

---
✅ **This Gold Layer model ensures consistent reporting, traceability, and structured analytics across dimensions and facts.**
