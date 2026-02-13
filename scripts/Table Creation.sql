/* ============================================================
   SCHEMA: GOLD
   Purpose:
     Stores clean, analytics-ready dimensional and fact tables.
     This layer follows a star-schema design for reporting and BI.
   ============================================================ */

CREATE SCHEMA IF NOT EXISTS gold;

/* ============================================================
   TABLE: dim_customers
   Purpose:
     Stores customer master data and demographic attributes.
   Grain:
     One row per customer.
   ============================================================ */

CREATE TABLE gold.dim_customers (
    customer_key INT,
    customer_id INT,
    customer_number VARCHAR(50),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    marital_status VARCHAR(50),
    gender VARCHAR(50),
    birthdate DATE,
    create_date DATE
);

/* ============================================================
   TABLE: dim_products
   Purpose:
     Stores product master data and classification attributes.
   Grain:
     One row per product.
   ============================================================ */

CREATE TABLE gold.dim_products (
    product_key INT,
    product_id INT,
    product_number VARCHAR(50),
    product_name VARCHAR(50),
    category_id VARCHAR(50),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    maintenance VARCHAR(50),
    cost INT,
    product_line VARCHAR(50),
    start_date DATE
);

/* ============================================================
   TABLE: fact_sales
   Purpose:
     Stores transactional sales data for analysis.
   Grain:
     One row per product per order.
   ============================================================ */

CREATE TABLE gold.fact_sales (
    order_number VARCHAR(50),
    product_key INT,
    customer_key INT,
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    sales_amount INT,
    quantity SMALLINT,
    price INT
);