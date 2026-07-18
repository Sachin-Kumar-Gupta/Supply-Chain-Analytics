SELECT 'supplier_master' AS table_name, COUNT(*) AS row_count
FROM supply_chain.supplier_master

UNION ALL

SELECT 'warehouse_master', COUNT(*)
FROM supply_chain.warehouse_master

UNION ALL

SELECT 'product_master', COUNT(*)
FROM supply_chain.product_master

UNION ALL

SELECT 'current_inventory', COUNT(*)
FROM supply_chain.current_inventory

UNION ALL

SELECT 'sales_orders', COUNT(*)
FROM supply_chain.sales_orders

UNION ALL

SELECT 'demand_forecast', COUNT(*)
FROM supply_chain.demand_forecast;

-- Product lookups
CREATE INDEX idx_sales_product
ON supply_chain.sales_orders(product_id);

CREATE INDEX idx_inventory_product
ON supply_chain.current_inventory(product_id);

CREATE INDEX idx_forecast_product
ON supply_chain.demand_forecast(product_id);

-- Warehouse lookups
CREATE INDEX idx_sales_warehouse
ON supply_chain.sales_orders(warehouse_id);

CREATE INDEX idx_inventory_warehouse
ON supply_chain.current_inventory(warehouse_id);

-- Date lookups
CREATE INDEX idx_sales_date
ON supply_chain.sales_orders(order_date);

CREATE INDEX idx_forecast_date
ON supply_chain.demand_forecast(forecast_date);

-- Product Coverage - How many products exist?
SELECT COUNT(*) AS total_products
FROM supply_chain.product_master;

--Warehouse Coverage
SELECT COUNT(*) AS warehouses
FROM supply_chain.warehouse_master;

-- Supplier Covergae
SELECT COUNT(*) AS suppliers
FROM supply_chain.supplier_master;

-- Date Range
SELECT
MIN(order_date),
MAX(order_date)
FROM supply_chain.sales_orders;

-- Duplicate Orders
SELECT order_id, COUNT(*) 
FROM supply_chain.sales_orders
GROUP BY order_id
HAVING COUNT(*) >1;

/*
# Validation Summary
The database import was successfully completed. 
All tables contain the expected number of records, no missing values were identified in key analytical fields, and no duplicate order IDs were detected. 
The database is ready for business analysis.
*/

--What is the total inventory value currently held across all warehouses?
SELECT ROUND(SUM(inventory_value), 2) AS total_inventory_value
FROM supply_chain.current_inventory;

-- How is inventory distributed across different inventory health statuses?
SELECT inventory_status,
COUNT(*) AS sku_count,
ROUND(SUM(inventory_value),2) AS inventory_value,
SUM(closing_stock) AS total_units
FROM supply_chain.current_inventory
GROUP BY inventory_status
ORDER BY inventory_value DESC;

-- Which product categories hold the highest inventory value?
SELECT p.category, COUNT(*) AS total_records,
ROUND(SUM(ci.inventory_value),2) AS inventory_value,
SUM(ci.closing_stock) AS units
FROM supply_chain.current_inventory ci
JOIN supply_chain.product_master p
ON ci.product_id = p.product_id
GROUP BY p.category
ORDER BY inventory_value DESC;

-- Top 10 Highest Inventory Products
SELECT p.product_id,p.product_name,p.category,
ROUND(SUM(ci.inventory_value),2) AS inventory_value
FROM supply_chain.current_inventory ci
JOIN supply_chain.product_master p
ON ci.product_id = p.product_id
GROUP BY p.product_id,p.product_name,p.category
ORDER BY inventory_value DESC
LIMIT 10;

-- Inventory Value by Warehouse
SELECT w.warehouse_name,
ROUND(SUM(ci.inventory_value),2) AS inventory_value,
SUM(ci.closing_stock) AS units
FROM supply_chain.current_inventory ci
JOIN supply_chain.warehouse_master w
ON ci.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name
ORDER BY inventory_value DESC;

-- Warehouse Capacity Utilization
SELECT warehouse_name,storage_capacity,current_utilization_pct
FROM supply_chain.warehouse_master
ORDER BY current_utilization_pct DESC;

-- Inventory Status by Warehouse
SELECT ci.warehouse_id,ci.inventory_status, COUNT(*) AS products,
ROUND(SUM(ci.inventory_value),2) AS inventory_value
FROM supply_chain.current_inventory ci
GROUP BY ci.warehouse_id,ci.inventory_status
ORDER BY ci.warehouse_id,inventory_value DESC;

-- Which product categories generate the highest revenue and profit?
SELECT p.category,
ROUND(SUM(s.revenue),2) AS revenue,
ROUND(SUM(s.profit),2) AS profit,
COUNT(s.order_id) AS total_orders,
SUM(s.quantity) AS units_sold
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Top 10 Revenue-Generating Products
SELECT p.product_id,p.product_name,p.category,
ROUND(SUM(s.revenue),2) AS revenue,
ROUND(SUM(s.profit),2) AS profit,
SUM(s.quantity) AS units_sold
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
GROUP BY p.product_id,p.product_name,p.category
ORDER BY revenue DESC
LIMIT 10;

-- Which warehouse generates the most sales and profit?
SELECT w.warehouse_name,
ROUND(SUM(s.revenue),2) AS revenue,
ROUND(SUM(s.profit),2) AS profit,
COUNT(s.order_id) AS total_orders,
SUM(s.quantity) AS units_sold
FROM supply_chain.sales_orders s
JOIN supply_chain.warehouse_master w
ON s.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name
ORDER BY revenue DESC;

-- Forecast Accuracy by Category
SELECT p.category,
ROUND(AVG(f.forecast_accuracy_pct),2) AS avg_accuracy,
ROUND(AVG(f.forecast_error_pct),2) AS avg_error,
SUM(f.actual_qty) AS total_actual_demand
FROM supply_chain.demand_forecast f
JOIN supply_chain.product_master p
ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY avg_accuracy DESC;

--Which ABC class contributes the most revenue?
SELECT p.abc_class,
ROUND(SUM(s.revenue),2) AS revenue,
ROUND(SUM(s.profit),2) AS profit,
COUNT(*) AS orders
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
GROUP BY p.abc_class
ORDER BY revenue DESC;

--Revenue by Warehouse and Category
SELECT w.warehouse_name,p.category,
ROUND(SUM(s.revenue),2) AS revenue,
ROUND(SUM(s.profit),2) AS profit
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
JOIN supply_chain.warehouse_master w
ON s.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name,p.category
ORDER BY w.warehouse_name,revenue DESC;

-- Classify inventory records based on days of inventory.
SELECT product_id,warehouse_id,days_of_inventory,
CASE 
WHEN days_of_inventory < 60 THEN 'Critical'
WHEN days_of_inventory < 120 THEN 'Healthy'
WHEN days_of_inventory < 210 THEN 'Slow Moving'
ELSE 'Dead Stock'
END AS inventory_risk
FROM supply_chain.current_inventory
ORDER BY days_of_inventory DESC;

--Which categories generated more than ₹4,000,000 in revenue?
SELECT p.category,
ROUND(SUM(s.revenue),2) AS revenue
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
GROUP BY p.category
HAVING SUM(s.revenue) > 4000000
ORDER BY revenue DESC;

--Which products have an inventory value higher than the company average?
SELECT product_id,warehouse_id,inventory_value
FROM supply_chain.current_inventory
WHERE inventory_value >
(
SELECT AVG(inventory_value)
FROM supply_chain.current_inventory
)
ORDER BY inventory_value DESC;

-- Revenue and Profit by Category 
WITH category_sales AS
(
SELECT p.category,
SUM(s.revenue) AS revenue,
SUM(s.profit) AS profit
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
GROUP BY p.category
)
SELECT category,ROUND(revenue,2) as revenue,ROUND(profit,2) as profit
FROM category_sales
ORDER BY revenue DESC;

-- What is the inventory value for each inventory status ?
SELECT 
ROUND(SUM(CASE WHEN inventory_status='Healthy' THEN inventory_value ELSE 0 END),2) AS healthy_inventory,
ROUND(SUM(CASE WHEN inventory_status='Overstock' THEN inventory_value ELSE 0 END ),2) AS overstock_inventory,
ROUND(SUM(CASE WHEN inventory_status='Reorder Required' THEN inventory_value ELSE 0 END ),2) AS reorder_inventory,
ROUND(SUM(CASE WHEN inventory_status='Stockout Risk' THEN inventory_value ELSE 0 END),2) AS stockout_inventory
FROM supply_chain.current_inventory;

-- Which products have the highest inventory value?
SELECT product_id,warehouse_id,inventory_value,
RANK() OVER(ORDER BY inventory_value DESC) AS inventory_rank
FROM supply_chain.current_inventory
ORDER BY inventory_rank;

-- Find the top 5 products by revenue in every category.
WITH product_sales AS
(
SELECT p.category,p.product_id,p.product_name,
SUM(s.revenue) AS revenue
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id
GROUP BY p.category,p.product_id,p.product_name
)

SELECT *
FROM 
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY category ORDER BY revenue DESC) AS rank
FROM product_sales
) ranked_products
WHERE rank <= 5;

-- Top 10 suppliers based on delivery performance.
SELECT supplier_id,supplier_name,on_time_delivery_pct,defect_rate_pct,
RANK() OVER(ORDER BY on_time_delivery_pct DESC) AS delivery_rank
FROM supply_chain.supplier_master
ORDER BY delivery_rank
LIMIT 10;

-- How does revenue accumulate month by month?
WITH monthly_sales AS
(
SELECT DATE_TRUNC('month', order_date::date) AS month,
SUM(revenue) AS revenue
FROM supply_chain.sales_orders
GROUP BY month
)

SELECT month,
ROUND(revenue,2) AS monthly_revenue,
ROUND(SUM(revenue) OVER(ORDER BY month),2) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;

-- Did revenue increase or decrease compared with the previous month?
WITH monthly_sales AS
(
SELECT DATE_TRUNC('month', order_date::date) AS month,
SUM(revenue) AS revenue
FROM supply_chain.sales_orders
GROUP BY month
)

SELECT month,
ROUND(revenue,2) AS revenue,
ROUND(revenue - LAG(revenue) OVER(ORDER BY month),2) AS revenue_change
FROM monthly_sales
ORDER BY month;

-- What percentage of inventory falls into each status?
SELECT inventory_status,
COUNT(*) AS sku_count,
ROUND(COUNT(*) * 100.0 /SUM(COUNT(*)) OVER(),2) AS percentage
FROM supply_chain.current_inventory
GROUP BY inventory_status;


-- Inventory Dashboard View
CREATE VIEW vw_inventory_dashboard AS
SELECT i.product_id,p.product_name,p.category,i.warehouse_id,i.closing_stock,
i.inventory_value,i.days_of_inventory,i.inventory_status
FROM supply_chain.current_inventory i
JOIN supply_chain.product_master p
ON i.product_id = p.product_id;

SELECT *
FROM vw_inventory_dashboard
LIMIT 10;

-- Sales Dashboard View
CREATE VIEW vw_sales_dashboard AS

SELECT s.order_date, s.product_id,p.category,s.warehouse_id,
s.quantity,s.revenue,s.profit
FROM supply_chain.sales_orders s
JOIN supply_chain.product_master p
ON s.product_id = p.product_id;

SELECT *
FROM supply_chain.supplier_master
LIMIT 10;