-- 1

CREATE NONCLUSTERED INDEX IX_Customers_Email
ON sales.customers (email)
    WHERE email = 'someone@gmail.com';

-- 2

CREATE NONCLUSTERED INDEX IX_Products_Category_Brand
ON production.products (category_id, brand_id);

-- 3

CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
ON sales.orders (order_date)
INCLUDE (customer_id, store_id, order_status);

-- Creating tables for the next step

CREATE TABLE sales.customer_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    action VARCHAR(50),
    log_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE production.price_history (
    history_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    change_date DATETIME DEFAULT GETDATE(),
    changed_by VARCHAR(100)
);

CREATE TABLE sales.order_audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    customer_id INT,
    store_id INT,
    staff_id INT,
    order_date DATE,
    audit_timestamp DATETIME DEFAULT GETDATE()
);

-- 4

GO
CREATE TRIGGER trg_InsertCustomerLog
ON sales.customers
AFTER INSERT
AS
BEGIN
    INSERT INTO sales.customer_log (customer_id, action)
    SELECT customer_id, 'Customer Created'
    FROM inserted;
END;
GO

-- 5

GO
CREATE TRIGGER trg_ProductPriceHistory
ON production.products
AFTER UPDATE
AS
BEGIN
    IF UPDATE(list_price)
    BEGIN
        INSERT INTO production.price_history (
            product_id,
            old_price,
            new_price,
            changed_by
        )
        SELECT 
            d.product_id,
            d.list_price,
            i.list_price,
            SYSTEM_USER
        FROM deleted d
        JOIN inserted i
            ON d.product_id = i.product_id;
    END
END;
GO

-- 6

GO
CREATE TRIGGER trg_PreventCategoryDelete
ON production.categories
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM production.products p
        JOIN deleted d
            ON p.category_id = d.category_id
    )
    BEGIN
        RAISERROR ('Cannot delete category with existing products', 16, 1);
        RETURN;
    END

    DELETE FROM production.categories
    WHERE category_id IN (SELECT category_id FROM deleted);
END;
GO

-- 7

GO
CREATE TRIGGER trg_UpdateStockOnOrder
ON sales.order_items
AFTER INSERT
AS
BEGIN
    UPDATE s
    SET s.quantity = s.quantity - i.quantity
    FROM production.stocks s
    JOIN inserted i
        ON s.product_id = i.product_id
    JOIN sales.orders o
        ON o.order_id = i.order_id
       AND o.store_id = s.store_id;
END;
GO

-- 8

GO
CREATE TRIGGER trg_OrderAudit
ON sales.orders
AFTER INSERT
AS
BEGIN
    INSERT INTO sales.order_audit (
        order_id,
        customer_id,
        store_id,
        staff_id,
        order_date
    )
    SELECT 
        order_id,
        customer_id,
        store_id,
        staff_id,
        order_date
    FROM inserted;
END;
GO


