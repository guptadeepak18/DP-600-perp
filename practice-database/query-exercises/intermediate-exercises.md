# Intermediate T-SQL Exercises

These exercises use the **Contoso Retail Analytics** practice database. Make sure you have run the schema and seed-data scripts before attempting them.

**Topics covered:** Window functions (ROW_NUMBER, RANK, LAG, LEAD, running totals), CTEs, HAVING, subqueries, multi-table JOINs, CASE expressions.

---

## Exercise 1 — Rank Products by Revenue

**Prompt:** Rank all products by their total revenue (`SUM(SalesAmount)`) across all orders. Return `ProductName`, `TotalRevenue`, and a `RevenueRank` column. Use the `RANK()` window function and order by total revenue descending.

<details>
<summary>Solution</summary>

```sql
SELECT
    dp.ProductName,
    SUM(fs.SalesAmount) AS TotalRevenue,
    RANK() OVER (ORDER BY SUM(fs.SalesAmount) DESC) AS RevenueRank
FROM FactSales fs
INNER JOIN DimProduct dp ON fs.ProductKey = dp.ProductKey
GROUP BY dp.ProductName
ORDER BY RevenueRank;
```

</details>

---

## Exercise 2 — Running Total of Sales by Date

**Prompt:** Using a window function, calculate a running total of `SalesAmount` ordered by `OrderDate`. Return `OrderDate`, `SalesAmount`, and `RunningTotal`.

<details>
<summary>Solution</summary>

```sql
SELECT
    OrderDate,
    SalesAmount,
    SUM(SalesAmount) OVER (ORDER BY OrderDate, SalesKey) AS RunningTotal
FROM FactSales
ORDER BY OrderDate, SalesKey;
```

</details>

---

## Exercise 3 — CTE: Top Spending Customers

**Prompt:** Using a Common Table Expression (CTE), find the top 5 customers by total spending. Return `FirstName`, `LastName`, `MembershipTier`, and `TotalSpent`.

<details>
<summary>Solution</summary>

```sql
WITH CustomerSpending AS (
    SELECT
        fs.CustomerKey,
        SUM(fs.SalesAmount) AS TotalSpent
    FROM FactSales fs
    GROUP BY fs.CustomerKey
)
SELECT TOP 5
    dc.FirstName,
    dc.LastName,
    dc.MembershipTier,
    cs.TotalSpent
FROM CustomerSpending cs
INNER JOIN DimCustomer dc ON cs.CustomerKey = dc.CustomerKey
ORDER BY cs.TotalSpent DESC;
```

</details>

---

## Exercise 4 — HAVING: High-Volume Products

**Prompt:** Find products that have been ordered more than 3 times (count of rows in `FactSales`). Return the `ProductName` and `OrderCount`. Use `HAVING` to filter.

<details>
<summary>Solution</summary>

```sql
SELECT
    dp.ProductName,
    COUNT(*) AS OrderCount
FROM FactSales fs
INNER JOIN DimProduct dp ON fs.ProductKey = dp.ProductKey
GROUP BY dp.ProductName
HAVING COUNT(*) > 3
ORDER BY OrderCount DESC;
```

</details>

---

## Exercise 5 — CASE: Classify Orders by Size

**Prompt:** Classify each sale in `FactSales` as `'Small'` (SalesAmount < 100), `'Medium'` (100–500), or `'Large'` (> 500). Return `OrderID`, `SalesAmount`, and `OrderSize`. Count how many orders fall into each category.

<details>
<summary>Solution</summary>

```sql
SELECT
    OrderSize,
    COUNT(*) AS OrderCount
FROM (
    SELECT
        OrderID,
        SalesAmount,
        CASE
            WHEN SalesAmount < 100 THEN 'Small'
            WHEN SalesAmount BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'Large'
        END AS OrderSize
    FROM FactSales
) AS Classified
GROUP BY OrderSize
ORDER BY OrderCount DESC;
```

</details>

---

## Exercise 6 — Multi-Table JOIN: Detailed Sales Report

**Prompt:** Create a detailed sales report with: `OrderID`, `OrderDate`, customer full name (`FirstName + ' ' + LastName` as `CustomerName`), `ProductName`, `StoreName`, `PromotionName`, `Quantity`, `SalesAmount`, and `ProfitAmount`. Join all relevant dimension tables.

<details>
<summary>Solution</summary>

```sql
SELECT
    fs.OrderID,
    fs.OrderDate,
    dc.FirstName + ' ' + dc.LastName AS CustomerName,
    dp.ProductName,
    ds.StoreName,
    dpr.PromotionName,
    fs.Quantity,
    fs.SalesAmount,
    fs.ProfitAmount
FROM FactSales fs
INNER JOIN DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
INNER JOIN DimProduct dp ON fs.ProductKey = dp.ProductKey
INNER JOIN DimStore ds ON fs.StoreKey = ds.StoreKey
INNER JOIN DimPromotion dpr ON fs.PromotionKey = dpr.PromotionKey
ORDER BY fs.OrderDate, fs.OrderID;
```

</details>

---

## Exercise 7 — Subquery: Products Never Sold

**Prompt:** Find all products from `DimProduct` that have never been sold (i.e., have no matching rows in `FactSales`). Return `ProductName` and `Category`.

<details>
<summary>Solution</summary>

```sql
SELECT ProductName, Category
FROM DimProduct
WHERE ProductKey NOT IN (
    SELECT DISTINCT ProductKey
    FROM FactSales
);
```

</details>

---

## Exercise 8 — LAG: Month-over-Month Sales Comparison

**Prompt:** Calculate total monthly sales and compare each month to the previous month. Return `Year`, `MonthNumber`, `MonthName`, `MonthlySales`, and `PreviousMonthSales` using the `LAG()` window function.

<details>
<summary>Solution</summary>

```sql
WITH MonthlySales AS (
    SELECT
        dd.Year,
        dd.MonthNumber,
        dd.MonthName,
        SUM(fs.SalesAmount) AS MonthlySales
    FROM FactSales fs
    INNER JOIN DimDate dd ON fs.DateKey = dd.DateKey
    GROUP BY dd.Year, dd.MonthNumber, dd.MonthName
)
SELECT
    Year,
    MonthNumber,
    MonthName,
    MonthlySales,
    LAG(MonthlySales) OVER (ORDER BY Year, MonthNumber) AS PreviousMonthSales
FROM MonthlySales
ORDER BY Year, MonthNumber;
```

</details>

---

## Exercise 9 — ROW_NUMBER: Latest Order per Customer

**Prompt:** For each customer, find their most recent order. Return `CustomerName`, `OrderID`, `OrderDate`, and `SalesAmount`. Use `ROW_NUMBER()` partitioned by customer and ordered by `OrderDate DESC`.

<details>
<summary>Solution</summary>

```sql
WITH RankedOrders AS (
    SELECT
        dc.FirstName + ' ' + dc.LastName AS CustomerName,
        fs.OrderID,
        fs.OrderDate,
        fs.SalesAmount,
        ROW_NUMBER() OVER (
            PARTITION BY fs.CustomerKey
            ORDER BY fs.OrderDate DESC, fs.SalesKey DESC
        ) AS RowNum
    FROM FactSales fs
    INNER JOIN DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
)
SELECT CustomerName, OrderID, OrderDate, SalesAmount
FROM RankedOrders
WHERE RowNum = 1
ORDER BY CustomerName;
```

</details>

---

## Exercise 10 — Profit Margin Analysis with CASE and Aggregation

**Prompt:** For each product category, calculate the total `SalesAmount`, total `ProfitAmount`, and profit margin percentage (`ProfitAmount / SalesAmount * 100`). Classify each category's margin as `'High'` (≥ 40%), `'Medium'` (20–39%), or `'Low'` (< 20%). Order by profit margin descending.

<details>
<summary>Solution</summary>

```sql
SELECT
    dp.Category,
    SUM(fs.SalesAmount) AS TotalSales,
    SUM(fs.ProfitAmount) AS TotalProfit,
    ROUND(SUM(fs.ProfitAmount) * 100.0 / NULLIF(SUM(fs.SalesAmount), 0), 2) AS ProfitMarginPct,
    CASE
        WHEN SUM(fs.ProfitAmount) * 100.0 / NULLIF(SUM(fs.SalesAmount), 0) >= 40 THEN 'High'
        WHEN SUM(fs.ProfitAmount) * 100.0 / NULLIF(SUM(fs.SalesAmount), 0) >= 20 THEN 'Medium'
        ELSE 'Low'
    END AS MarginClassification
FROM FactSales fs
INNER JOIN DimProduct dp ON fs.ProductKey = dp.ProductKey
GROUP BY dp.Category
ORDER BY ProfitMarginPct DESC;
```

</details>
