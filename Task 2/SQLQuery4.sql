
/* 1 */
SELECT 
    p.product_id,
    p.product_name,
    p.list_price
FROM production.products AS p
WHERE p.list_price > 1000;


/* 2 */
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.state
FROM sales.customers AS c
WHERE c.state IN ('CA', 'NY');


/* 3 */
SELECT 
    o.order_id,
    o.order_date,
    o.customer_id
FROM sales.orders AS o
WHERE YEAR(o.order_date) = 2023;


/* 4 */
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email
FROM sales.customers AS c
WHERE c.email LIKE '%@gmail.com';


/* 5 */
SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    s.active
FROM sales.staffs AS s
WHERE s.active = 0;


/* 6 */
SELECT TOP 5
    p.product_id,
    p.product_name,
    p.list_price
FROM production.products AS p
ORDER BY p.list_price DESC;


/* 7 */
SELECT TOP 10
    o.order_id,
    o.order_date,
    o.customer_id
FROM sales.orders AS o
ORDER BY o.order_date DESC;


/* 8 */
SELECT TOP 3
    c.customer_id,
    c.first_name,
    c.last_name
FROM sales.customers AS c
ORDER BY c.last_name ASC;


/* 9 */
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name
FROM sales.customers AS c
WHERE c.phone IS NULL;


/* 10 */
SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    s.manager_id
FROM sales.staffs AS s
WHERE s.manager_id IS NOT NULL;


/* 11 */
SELECT 
    c.category_name,
    COUNT(p.product_id) AS product_count
FROM production.categories AS c
LEFT JOIN production.products AS p
    ON c.category_id = p.category_id
GROUP BY c.category_name;


/* 12. Count number of customers in each state */
SELECT 
    c.state,
    COUNT(c.customer_id) AS customer_count
FROM sales.customers AS c
GROUP BY c.state;


/* 13 */
SELECT 
    b.brand_name,
    AVG(p.list_price) AS avg_price
FROM production.brands AS b
JOIN production.products AS p
    ON b.brand_id = p.brand_id
GROUP BY b.brand_name;


/* 14 */
SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    COUNT(o.order_id) AS total_orders
FROM sales.staffs AS s
LEFT JOIN sales.orders AS o
    ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name;


/* 15 */
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS order_count
FROM sales.customers AS c
JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > 2;


/* 16 */
SELECT 
    p.product_id,
    p.product_name,
    p.list_price
FROM production.products AS p
WHERE p.list_price BETWEEN 500 AND 1500;


/* 17 */
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city
FROM sales.customers AS c
WHERE c.city LIKE 'S%';


/* 18 */
SELECT 
    o.order_id,
    o.order_status,
    o.order_date
FROM sales.orders AS o
WHERE o.order_status IN (2, 4);


/* 19 */
SELECT 
    p.product_id,
    p.product_name,
    p.category_id
FROM production.products AS p
WHERE p.category_id IN (1, 2, 3);


/* 20 */
SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    s.store_id,
    s.phone
FROM sales.staffs AS s
WHERE s.store_id = 1
   OR s.phone IS NULL;
