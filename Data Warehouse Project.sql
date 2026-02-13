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

/*
1. Sales Performance Over Time
Purpose:
  Analyze how sales performance evolves over time.

Key Features:
  ● Monthly total sales
  ● Unique customers per month
  ● Total quantity sold
  ● Identifies seasonality and growth trends
*/

SELECT 
    TO_CHAR(order_date, 'YYYY-Mon') AS order_date,
    SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date, 'YYYY-Mon')
ORDER BY TO_CHAR(order_date, 'YYYY-Mon');

/*
2. Monthly Sales with Running Totals
Purpose:
  Track cumulative sales growth and pricing behavior over time.

Key Features:
  ● Monthly total sales
  ● Running total of sales
  ● Running average price
  ● Highlights long-term growth patterns
*/

SELECT 
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    ROUND(AVG(avg_price) OVER (ORDER BY order_month),0) AS running_avg_price
FROM (
    SELECT
        DATE(DATE_TRUNC('month', order_date)) AS order_month,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE(DATE_TRUNC('month', order_date))
) t
ORDER BY order_month;

/*
3. Yearly Product Performance Analysis
Purpose:
  Evaluate product performance on a yearly basis and compare trends.

Key Features:
  ● Year-wise product sales
  ● Comparison with product’s average historical sales
  ● Identification of above/below average performance
  ● Year-over-Year (YoY) sales growth or decline
*/

WITH yearly_product_sales AS (
    SELECT 
        EXTRACT(YEAR FROM f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY 
        EXTRACT(YEAR FROM f.order_date),
        p.product_name
)
SELECT 
    order_year,
    product_name,
    current_sales,
    ROUND(AVG(current_sales) OVER (PARTITION BY product_name),0) AS avg_sales_per_product,
	current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name),0) AS diff_from_avg_sales,
	CASE WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name),0) > 0 THEN 'Above Average'
	     WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name),0) < 0 THEN 'Below Average'
		 ELSE 'Average'
	END avg_change,
-- YEAR OVER YEAR ANALYSIS
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) previous_year_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_previous_year_sales,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'Average'
END previous_year_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

/*
4. Category Contribution Analysis
Purpose:
  Identify which product categories contribute most to overall revenue.

Key Features:
  ● Total sales per category
  ● Overall sales across all categories
  ● Percentage contribution by category
  ● Supports category-level business decisions
*/

WITH category_sales AS (
    SELECT 
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT 
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(
        ROUND(
            (total_sales * 1.0 / NULLIF(SUM(total_sales) OVER (), 0)) * 100,
            2
        ),
        '%'
    ) AS percentage_of_sales
FROM category_sales
ORDER BY total_sales DESC;

/*
5. Product Cost Segmentation
Purpose:
  Segment products into cost-based pricing bands.

Key Features:
  ● Classification of products by cost range
  ● Count of products in each cost segment
  ● Helps analyze pricing strategy and product mix
*/

WITH product_segments AS (
    SELECT 
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 501 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*
6. Customer Segmentation Based on Spending Behaviour
Purpose:
  Classify customers based on lifespan and spending patterns.

Customer Segments:
  ● VIP: ≥ 12 months lifespan and spending > €5,000
  ● Regular: ≥ 12 months lifespan and spending ≤ €5,000
  ● New: < 12 months lifespan

Key Features:
  - Customer count per segment
  - Supports retention and targeted marketing strategies
*/

WITH customer_spending AS (
    SELECT 
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        (
            EXTRACT(YEAR FROM AGE(MAX(f.order_date), MIN(f.order_date))) * 12 +
            EXTRACT(MONTH FROM AGE(MAX(f.order_date), MIN(f.order_date)))
        ) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT 
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT 
        customer_key,
        CASE 
            WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;

/*
7. Customer Analytics Report
Purpose:
  Build a comprehensive customer-level analytics report.

Key Features:
  ● Customer demographics (name, age, age group)
  ● Customer segmentation (VIP, Regular, New)
  ● Aggregated metrics:
      • total orders
      • total sales
      • total quantity purchased
      • total products purchased
      • lifespan (months)
  - KPIs:
      • recency (months since last order)
      • average order value
      • average monthly spend
*/

CREATE VIEW gold.report_customers AS
WITH base_query AS (
    SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),
customer_aggregation AS (
    SELECT 
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        (
            EXTRACT(YEAR  FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
            EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
        ) AS lifespan_months
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and Above'
    END AS age_group,
    CASE 
        WHEN lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    (
        EXTRACT(YEAR  FROM AGE(CURRENT_DATE, last_order_date)) * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date))
    ) AS recency_months,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan_months,
    ROUND((total_sales * 1.0) / NULLIF(total_orders, 0), 2) AS avg_order_value,
    ROUND((total_sales * 1.0) / NULLIF(lifespan_months, 0), 2) AS avg_monthly_spend
FROM customer_aggregation;

/*
8. Product Analytics Report
Purpose:
  Create a consolidated product-level performance report.

Key Features:
  ● Product attributes (name, category, subcategory, cost)
  ● Revenue-based segmentation (High / Mid / Low)
  ● Aggregated metrics:
      • total orders
      • total sales
      • total quantity sold
      • total customers
      • lifespan (months)
  - KPIs:
      • recency (months since last sale)
      • average order revenue
      • average monthly revenue
*/

CREATE VIEW gold.report_products AS
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.sales_amount,
        f.quantity,
        f.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost,
        f.customer_key
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),
product_aggregation AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity_sold,
        MAX(order_date)              AS last_sale_date,
        (
            EXTRACT(YEAR  FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
            EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
        ) AS lifespan_months,
        ROUND(
            CAST(AVG(sales_amount * 1.0 / NULLIF(quantity, 0)) AS NUMERIC),
            0
        ) AS avg_selling_price
    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    (
        EXTRACT(YEAR  FROM AGE(CURRENT_DATE, last_sale_date)) * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_sale_date))
    ) AS recency_months,
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Range'
    END AS product_segment,
    lifespan_months,
    total_orders,
    total_sales,
    total_quantity_sold,
    total_customers,
    avg_selling_price,

-- Average Order Revenue (AOR)
	CASE WHEN total_orders = 0 THEN 0
	     ELSE total_sales / total_orders
	END AS avg_order_revenue,
	
-- Average Monthly Revenue
   CASE WHEN lifespan_months = 0 THEN 0
	     ELSE total_sales / lifespan_months
	END AS avg_monthly_revenue
	
FROM product_aggregation;
