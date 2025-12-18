USE StoreDB;
GO


-- 1

SELECT COUNT(*) AS total_products
FROM production.products;


-- 2 

SELECT 
    AVG(list_price) AS avg_price,
    MIN(list_price) AS min_price,
    MAX(list_price) AS max_price
FROM production.products;


-- 3

SELECT 
    c.category_name,
    COUNT(p.product_id) AS product_count
FROM production.categories c
LEFT JOIN production.products p
    ON c.category_id = p.category_id
GROUP BY c.category_name;


-- 4 

SELECT 
    s.store_name,
    COUNT(o.order_id) AS total_orders
FROM sales.stores s
LEFT JOIN sales.orders o
    ON s.store_id = o.store_id
GROUP BY s.store_name;

--5

SELECT TOP 10
    UPPER(first_name) AS first_name_upper,
    LOWER(last_name) AS last_name_lower
FROM sales.customers
ORDER BY customer_id;

-- 6

SELECT TOP 10
    product_name,
    LEN(product_name) AS name_length
FROM production.products
ORDER BY product_id;


-- 7

SELECT
    customer_id,
    LEFT(phone, 3) AS area_code
FROM sales.customers
WHERE customer_id BETWEEN 1 AND 15;

-- 8
SELECT
    order_id,
    GETDATE() AS currentDate,
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month
FROM sales.orders
WHERE order_id BETWEEN 1 AND 10;



-- 9

SELECT TOP 10
    p.product_name,
    c.category_name
FROM production.products p
JOIN production.categories c
    ON p.category_id = c.category_id
ORDER BY p.product_id;

-- 10

SELECT TOP 10
    c.first_name + ' ' + c.last_name AS customer_name,
    o.order_date
FROM sales.orders o
JOIN sales.customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id;

-- 11

SELECT
    p.product_name,
    ISNULL(b.brand_name, 'No Brand') AS brand_name
FROM production.products p
LEFT JOIN production.brands b
    ON p.brand_id = b.brand_id;

    -- 12
SELECT
    product_name,
    list_price
FROM production.products
WHERE list_price >
(
    SELECT AVG(list_price)
    FROM production.products
);


/*----------------------------------------------------------
13. Find customers who placed at least one order (IN subquery)
----------------------------------------------------------*/
SELECT
    customer_id,
    first_name + ' ' + last_name AS customer_name
FROM sales.customers
WHERE customer_id IN
(
    SELECT DISTINCT customer_id
    FROM sales.orders
    WHERE customer_id IS NOT NULL
);

-- 14

SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    (
        SELECT COUNT(*)
        FROM sales.orders o
        WHERE o.customer_id = c.customer_id
    ) AS total_orders
FROM sales.customers c;

-- 15

CREATE VIEW easy_product_list AS
SELECT
    p.product_name,
    c.category_name,
    p.list_price
FROM production.products p
JOIN production.categories c
    ON p.category_id = c.category_id;
GO
SELECT *
FROM easy_product_list
WHERE list_price > 100;

-- 16
CREATE VIEW customer_info AS
SELECT
    customer_id,
    first_name + ' ' + last_name AS full_name,
    email,
    city + ', ' + state AS location
FROM sales.customers;
GO

SELECT *
FROM customer_info
WHERE location LIKE '%, CA';

-- 17 

SELECT
    product_name,
    list_price
FROM production.products
WHERE list_price BETWEEN 50 AND 200
ORDER BY list_price ASC;

-- 18

SELECT
    state,
    COUNT(customer_id) AS customer_count
FROM sales.customers
GROUP BY state
ORDER BY customer_count DESC;


--19 

SELECT
    c.category_name,
    p.product_name,
    p.list_price
FROM production.products p
JOIN production.categories c
    ON p.category_id = c.category_id
WHERE p.list_price =
(
    SELECT MAX(p2.list_price)
    FROM production.products p2
    WHERE p2.category_id = p.category_id
);

-- 20

SELECT
    s.store_name,
    s.city,
    COUNT(o.order_id) AS total_orders
FROM sales.stores s
LEFT JOIN sales.orders o
    ON s.store_id = o.store_id
GROUP BY s.store_name, s.city;

-- Query 1

SELECT
    product_id,
    product_name,
    list_price,
    CASE
        WHEN list_price < 300 THEN 'Economy'
        WHEN list_price BETWEEN 300 AND 999 THEN 'Standard'
        WHEN list_price BETWEEN 1000 AND 2499 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_category
FROM production.products;


-- Query 2 
SELECT
    order_id,
    order_date,
    order_status,
    CASE order_status
        WHEN 1 THEN 'Order Received'
        WHEN 2 THEN 'In Preparation'
        WHEN 3 THEN 'Order Cancelled'
        WHEN 4 THEN 'Order Delivered'
    END AS status_description,
    CASE
        WHEN order_status = 1 AND DATEDIFF(DAY, order_date, GETDATE()) > 5 THEN 'URGENT'
        WHEN order_status = 2 AND DATEDIFF(DAY, order_date, GETDATE()) > 3 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS priority_level
FROM sales.orders;


-- Query 3

SELECT
    s.staff_id,
    s.first_name + ' ' + s.last_name AS staff_name,
    COUNT(o.order_id) AS total_orders,
    CASE
        WHEN COUNT(o.order_id) = 0 THEN 'New Staff'
        WHEN COUNT(o.order_id) BETWEEN 1 AND 10 THEN 'Junior Staff'
        WHEN COUNT(o.order_id) BETWEEN 11 AND 25 THEN 'Senior Staff'
        ELSE 'Expert Staff'
    END AS staff_level
FROM sales.staffs s
LEFT JOIN sales.orders o
    ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name;

-- Query 4

SELECT
    customer_id,
    first_name,
    last_name,
    ISNULL(phone, 'Phone Not Available') AS phone,
    email,
    COALESCE(phone, email, 'No Contact Method') AS preferred_contact
FROM sales.customers;


-- Query 5

SELECT
    p.product_id,
    p.product_name,
    s.quantity,
    ISNULL(p.list_price / NULLIF(s.quantity, 0), 0) AS price_per_unit,
    CASE
        WHEN s.quantity = 0 OR s.quantity IS NULL THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM production.products p
JOIN production.stocks s
    ON p.product_id = s.product_id
WHERE s.store_id = 1;

-- Query 6

SELECT
    customer_id,
    COALESCE(street, '') + ', ' +
    COALESCE(city, '') + ', ' +
    COALESCE(state, '') + ' ' +
    COALESCE(zip_code, 'N/A') AS formatted_address
FROM sales.customers;




