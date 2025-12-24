use storeDB

-- 1

DECLARE @CustomerID INT = 50;
DECLARE @TotalSpent DECIMAL(10,2);

SELECT @TotalSpent = SUM(oi.quantity * oi.list_price)
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = @CustomerID;

IF @TotalSpent > 50000
    PRINT 'VIP Customer - Total Spent: $' + CAST(@TotalSpent AS VARCHAR);
ELSE
    PRINT 'Regular Customer - Total Spent: $' + CAST(@TotalSpent AS VARCHAR);

-- 2

DECLARE @Threshold MONEY = 1500;
DECLARE @ProductCount INT;

SELECT @ProductCount = COUNT(*)
FROM production.products
WHERE list_price > @Threshold;

PRINT 'Products above $' + CAST(@Threshold AS VARCHAR) +
      ': ' + CAST(@ProductCount AS VARCHAR);

-- 3

DECLARE @StaffID INT = 1;
DECLARE @Year INT = 2017;
DECLARE @TotalSales INT;

SELECT @TotalSales = ISNULL(SUM(oi.quantity * oi.list_price), 0)
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.staff_id = @StaffID
AND YEAR(o.order_date) = @Year;

PRINT 'Staff ' + CAST(@StaffID AS VARCHAR) +
      ' Sales in ' + CAST(@Year AS VARCHAR) +
      ': $' + CAST(@TotalSales AS VARCHAR);

-- 4

SELECT
    @@SERVERNAME AS ServerName,
    @@VERSION AS SQLVersion,
    @@ROWCOUNT AS RowsAffected;

-- 5

DECLARE @Quantity INT;

SELECT @Quantity = quantity
FROM production.stocks
WHERE product_id = 1 AND store_id = 1;

IF @Quantity > 20
    PRINT 'Well stocked';
ELSE IF @Quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE
    PRINT 'Low stock - reorder needed';

-- 6

DECLARE @Counter INT = 1;

WHILE EXISTS (
    SELECT 1 FROM production.stocks WHERE quantity < 5
)
BEGIN
    UPDATE TOP (3) production.stocks
    SET quantity = quantity + 10
    WHERE quantity < 5;

    PRINT 'Batch ' + CAST(@Counter AS VARCHAR) + ' updated';

    SET @Counter += 1;
END

-- 7

SELECT
    product_name,
    list_price,
    CASE
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        ELSE 'Luxury'
    END AS category
FROM production.products;

-- 8

IF EXISTS (
    SELECT 1 FROM sales.customers WHERE customer_id = 5
)
BEGIN
    SELECT COUNT(*) AS OrderCount
    FROM sales.orders
    WHERE customer_id = 5;
END
ELSE
    PRINT 'Customer does not exist';

-- 9
GO
CREATE or ALTER FUNCTION dbo.CalculateShipping (@Total MONEY)
RETURNS MONEY
AS
BEGIN
    RETURN
    CASE
        WHEN @Total > 100 THEN 0
        WHEN @Total BETWEEN 50 AND 99 THEN 5.99
        ELSE 12.99
    END;
END;

-- 10
GO
CREATE or ALTER FUNCTION dbo.GetProductsByPriceRange
(@Min INT, @Max INT)
RETURNS TABLE
AS
RETURN
(
    SELECT p.product_name, b.brand_name, c.category_name, p.list_price
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @Min AND @Max
);

-- 11

GO
CREATE FUNCTION dbo.GetCustomerYearlySummary (@CustomerID INT)
RETURNS @Summary TABLE (
    OrderYear INT,
    TotalOrders INT,
    TotalSpent MONEY,
    AvgOrderValue MONEY
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT
        YEAR(o.order_date),
        COUNT(DISTINCT o.order_id),
        SUM(oi.quantity * oi.list_price),
        AVG(oi.quantity * oi.list_price)
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
    GROUP BY YEAR(o.order_date);

    RETURN;
END;

-- 12

GO
CREATE FUNCTION dbo.CalculateBulkDiscount (@Qty INT)
RETURNS INT
AS
BEGIN
    RETURN
    CASE
        WHEN @Qty BETWEEN 1 AND 2 THEN 0
        WHEN @Qty BETWEEN 3 AND 5 THEN 5
        WHEN @Qty BETWEEN 6 AND 9 THEN 10
        ELSE 15
    END;
END;

-- 13

GO
CREATE PROCEDURE sp_GetCustomerOrderHistory
@CustomerID INT,
@StartDate DATE = NULL,
@EndDate DATE = NULL
AS
BEGIN
    SELECT o.order_id, o.order_date,
           SUM(oi.quantity * oi.list_price) AS order_total
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
      AND (@StartDate IS NULL OR o.order_date >= @StartDate)
      AND (@EndDate IS NULL OR o.order_date <= @EndDate)
    GROUP BY o.order_id, o.order_date;
END;

-- 14
GO
CREATE or ALTER PROCEDURE sp_RestockProduct
@StoreID INT,
@ProductID INT,
@RestockQty INT,
@OldQty INT OUTPUT,
@NewQty INT OUTPUT
AS
BEGIN
    SELECT @OldQty = quantity
    FROM production.stocks
    WHERE store_id = @StoreID AND product_id = @ProductID;

    UPDATE production.stocks
    SET quantity = quantity + @RestockQty
    WHERE store_id = @StoreID AND product_id = @ProductID;

    SELECT @NewQty = quantity
    FROM production.stocks
    WHERE store_id = @StoreID AND product_id = @ProductID;
END;

-- 15


GO
CREATE OR ALTER PROCEDURE sp_ProcessNewOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @StoreID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @OrderID INT;
        DECLARE @Price DECIMAL(10,2);

        SELECT @Price = list_price
        FROM production.products
        WHERE product_id = @ProductID;

        INSERT INTO sales.orders (customer_id, order_status, order_date, store_id)
        VALUES (@CustomerID, 1, GETDATE(), @StoreID);

        SET @OrderID = SCOPE_IDENTITY();

        INSERT INTO sales.order_items
        (order_id, product_id, quantity, list_price)
        VALUES
        (@OrderID, @ProductID, @Quantity, @Price);

        UPDATE production.stocks
        SET quantity = quantity - @Quantity
        WHERE product_id = @ProductID
          AND store_id = @StoreID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- 16

GO
CREATE OR ALTER PROCEDURE sp_SearchProducts
    @ProductName NVARCHAR(100) = NULL,
    @CategoryID INT = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) =
        'SELECT * FROM production.products WHERE 1=1';

    IF @ProductName IS NOT NULL
        SET @SQL += ' AND product_name LIKE ''%' + @ProductName + '%''';

    IF @CategoryID IS NOT NULL
        SET @SQL += ' AND category_id = ' + CAST(@CategoryID AS VARCHAR);

    IF @MinPrice IS NOT NULL
        SET @SQL += ' AND list_price >= ' + CAST(@MinPrice AS VARCHAR);

    IF @MaxPrice IS NOT NULL
        SET @SQL += ' AND list_price <= ' + CAST(@MaxPrice AS VARCHAR);

END;
GO

-- 17

DECLARE @StartDate DATE = '2017-01-01';
DECLARE @EndDate DATE = '2017-03-31';

SELECT
    s.staff_id,
    s.first_name,
    SUM(oi.quantity * oi.list_price) AS total_sales,
    CASE
        WHEN SUM(oi.quantity * oi.list_price) >= 50000 THEN 0.10
        WHEN SUM(oi.quantity * oi.list_price) >= 25000 THEN 0.07
        ELSE 0.03
    END AS bonus_rate
FROM sales.staffs s
JOIN sales.orders o ON s.staff_id = o.staff_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.order_date BETWEEN @StartDate AND @EndDate
GROUP BY s.staff_id, s.first_name;

-- 18

DECLARE @Qty INT;
DECLARE @CategoryID INT;

SELECT 
    @Qty = s.quantity,
    @CategoryID = p.category_id
FROM production.stocks s
JOIN production.products p ON s.product_id = p.product_id
WHERE s.product_id = 1 AND s.store_id = 1;

IF @Qty < 5
BEGIN
    IF @CategoryID = 1
        UPDATE production.stocks SET quantity += 30 WHERE product_id = 1;
    ELSE
        UPDATE production.stocks SET quantity += 15 WHERE product_id = 1;
END

-- 19

SELECT
    c.customer_id,
    c.first_name,
    ISNULL(SUM(oi.quantity * oi.list_price), 0) AS total_spent,
    CASE
        WHEN ISNULL(SUM(oi.quantity * oi.list_price), 0) >= 10000 THEN 'Platinum'
        WHEN ISNULL(SUM(oi.quantity * oi.list_price), 0) >= 5000 THEN 'Gold'
        WHEN ISNULL(SUM(oi.quantity * oi.list_price), 0) >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier
FROM sales.customers c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name;

-- 20

GO
CREATE OR ALTER PROCEDURE sp_DiscontinueProduct
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 
        FROM production.products 
        WHERE product_id = @ProductID
    )
    BEGIN
        PRINT 'Product does not exist';
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM sales.order_items oi
        JOIN sales.orders o 
            ON oi.order_id = o.order_id
        WHERE oi.product_id = @ProductID
          AND o.order_status IN (1, 2) 
    )
    BEGIN
        PRINT 'Product has pending orders and cannot be discontinued';
        RETURN;
    END

    UPDATE production.stocks
    SET quantity = 0
    WHERE product_id = @ProductID;

    PRINT 'Product discontinued successfully (inventory cleared)';
END;
GO
