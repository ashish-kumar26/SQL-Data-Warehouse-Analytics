📊 SQL Data Warehouse & Business Analytics Project
📌 Project Overview
In this project, I built a simple data warehouse in PostgreSQL using a star schema design.
The goal was to analyze sales, customer behavior, and product performance using SQL.
I created dimension tables and a fact table, and then wrote analytical queries to generate business insights and reports.
This project demonstrates:
•	Data modeling (Star Schema)
•	SQL aggregation & window functions
•	Customer & product segmentation
•	KPI calculations
•	Business reporting using views

🏗️ Data Warehouse Design
I created a schema called gold to store analytics-ready tables.
Tables Created
1️⃣ dim_customers
Contains customer information such as:
•	Name
•	Gender
•	Country
•	Birthdate
•	Marital status
Grain: One row per customer

2️⃣ dim_products
Contains product details such as:
•	Product name
•	Category
•	Subcategory
•	Cost
•	Product line
Grain: One row per product

3️⃣ fact_sales
Contains transactional sales data:
•	Order number
•	Product
•	Customer
•	Sales amount
•	Quantity
•	Order date
Grain: One row per product per order

📈 Business Analysis Performed

1️⃣ Sales Performance Over Time
I analyzed:
•	Monthly total sales
•	Unique customers per month
•	Total quantity sold
This helps identify:
•	Sales trends
•	Seasonality
•	Growth patterns

2️⃣ Monthly Running Sales & Price Trends
I calculated:
•	Monthly sales
•	Running total of sales (cumulative growth)
•	Running average price
This shows how the business is growing over time.

3️⃣ Yearly Product Performance (YoY Analysis)
For each product, I analyzed:
•	Yearly sales
•	Comparison with average performance
•	Year-over-Year (YoY) growth
•	Increase or decrease compared to last year
This helps identify:
•	Strong performing products
•	Declining products
•	Stable performers

4️⃣ Category Contribution to Total Revenue
I calculated:
•	Total sales by category
•	Percentage contribution of each category
This helps understand which categories drive the business.

5️⃣ Product Cost Segmentation
I grouped products into cost ranges:
•	Below 100
•	100–500
•	500–1000
•	Above 1000
This helps analyze pricing strategy and product mix.

6️⃣ Customer Segmentation
Customers were grouped based on spending and history:
•	VIP → 12+ months lifespan & spending > €5,000
•	Regular → 12+ months lifespan & spending ≤ €5,000
•	New → Less than 12 months
This supports marketing and retention strategies.

📊 Advanced Analytical Reports

7️⃣ Customer Analytics Report (View Created)
I created a view: gold.report_customers
This report includes:
•	Customer demographics
•	Age group segmentation
•	Customer segment (VIP / Regular / New)
•	Total orders
•	Total sales
•	Total quantity
•	Total products purchased
•	Customer lifespan (months)
•	Recency (months since last order)
•	Average Order Value (AOV)
•	Average Monthly Spend
This gives a complete 360° customer view.

8️⃣ Product Analytics Report (View Created)
I created another view: gold.report_products
This report includes:
•	Product details
•	Revenue-based segmentation:
o	High Performer
o	Mid-Range
o	Low-Range
•	Total orders
•	Total sales
•	Total quantity sold
•	Total customers
•	Product lifespan
•	Recency (since last sale)
•	Average Order Revenue
•	Average Monthly Revenue
This helps evaluate product performance clearly.

🛠️ SQL Concepts Used
In this project, I used:
•	CTEs (WITH clause)
•	Window Functions (SUM() OVER, LAG())
•	Aggregations (SUM, COUNT, AVG)
•	Date functions (AGE, EXTRACT)
•	CASE statements for segmentation
•	Views for reporting
•	Percentage calculations
•	Running totals

🎯 Key Learnings
Through this project, I learned:
•	How to design a simple star schema
•	How to calculate business KPIs in SQL
•	How to perform YoY analysis using window functions
•	How to segment customers and products
•	How to create reusable reporting views

🚀 Conclusion
This project demonstrates my ability to:
•	Design a structured data warehouse
•	Write advanced SQL queries
•	Generate meaningful business insights
•	Build reusable analytics reports
It can be directly connected to Power BI or Tableau for dashboard creation.
