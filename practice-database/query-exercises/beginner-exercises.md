# Beginner T-SQL Exercises

These exercises use the **Contoso Retail Analytics** practice database. Make sure you have run the schema and seed-data scripts before attempting them.

**Topics covered:** SELECT, WHERE, ORDER BY, GROUP BY, basic JOINs, aggregate functions (COUNT, SUM, AVG, MIN, MAX).

---

## Exercise 1 — Select All Products

**Prompt:** Write a query to retrieve all columns from the `DimProduct` table.

<details>
<summary>Solution</summary>

```sql
SELECT *
FROM DimProduct;
```

</details>

---

## Exercise 2 — Filter by Category

**Prompt:** List the `ProductName`, `Category`, and `UnitPrice` for all products in the **Electronics** category. Order the results by `UnitPrice` descending.

<details>
<summary>Solution</summary>

```sql
SELECT ProductName, Category, UnitPrice
FROM DimProduct
WHERE Category = 'Electronics'
ORDER BY UnitPrice DESC;
```

</details>

---

## Exercise 3 — Count Active Customers by Country

**Prompt:** How many active customers are there in each country? Return the `Country` and the count, ordered by count descending.

<details>
<summary>Solution</summary>

```sql
SELECT Country, COUNT(*) AS CustomerCount
FROM DimCustomer
WHERE IsActive = 1
GROUP BY Country
ORDER BY CustomerCount DESC;
```

</details>

---

## Exercise 4 — Total Sales Amount

**Prompt:** What is the total `SalesAmount` across all completed orders?

<details>
<summary>Solution</summary>

```sql
SELECT SUM(SalesAmount) AS TotalSales
FROM FactSales
WHERE OrderStatus = 'Completed';
```

</details>

---

## Exercise 5 — Customers in a Specific Tier

**Prompt:** List the `FirstName`, `LastName`, `City`, and `MembershipTier` for all customers in the **Gold** or **Platinum** membership tier. Sort alphabetically by `LastName`.

<details>
<summary>Solution</summary>

```sql
SELECT FirstName, LastName, City, MembershipTier
FROM DimCustomer
WHERE MembershipTier IN ('Gold', 'Platinum')
ORDER BY LastName;
```

</details>

---

## Exercise 6 — Average Unit Price by Category

**Prompt:** Calculate the average `UnitPrice` for each product `Category`. Round the result to 2 decimal places and alias it as `AvgPrice`.

<details>
<summary>Solution</summary>

```sql
SELECT Category, ROUND(AVG(UnitPrice), 2) AS AvgPrice
FROM DimProduct
GROUP BY Category
ORDER BY AvgPrice DESC;
```

</details>

---

## Exercise 7 — Basic JOIN: Sales with Product Names

**Prompt:** Write a query that returns the `OrderID`, `ProductName`, `Quantity`, and `SalesAmount` for all rows in `FactSales`. Join with `DimProduct` to get the product name.

<details>
<summary>Solution</summary>

```sql
SELECT
    fs.OrderID,
    dp.ProductName,
    fs.Quantity,
    fs.SalesAmount
FROM FactSales fs
INNER JOIN DimProduct dp ON fs.ProductKey = dp.ProductKey;
```

</details>

---

## Exercise 8 — Orders on Holidays

**Prompt:** Find all sales that occurred on a holiday. Return the `OrderID`, `FullDate`, and `SalesAmount`. Use the `DimDate` table to identify holidays.

<details>
<summary>Solution</summary>

```sql
SELECT
    fs.OrderID,
    dd.FullDate,
    fs.SalesAmount
FROM FactSales fs
INNER JOIN DimDate dd ON fs.DateKey = dd.DateKey
WHERE dd.IsHoliday = 1;
```

</details>

---

## Exercise 9 — Minimum and Maximum Sales

**Prompt:** Find the minimum and maximum `SalesAmount` in the `FactSales` table. Alias them as `MinSale` and `MaxSale`.

<details>
<summary>Solution</summary>

```sql
SELECT
    MIN(SalesAmount) AS MinSale,
    MAX(SalesAmount) AS MaxSale
FROM FactSales;
```

</details>

---

## Exercise 10 — Store Sales Summary

**Prompt:** For each store, show the `StoreName`, the total number of orders (count of distinct `OrderID` values), and the total `SalesAmount`. Order by total sales descending.

<details>
<summary>Solution</summary>

```sql
SELECT
    ds.StoreName,
    COUNT(DISTINCT fs.OrderID) AS TotalOrders,
    SUM(fs.SalesAmount) AS TotalSales
FROM FactSales fs
INNER JOIN DimStore ds ON fs.StoreKey = ds.StoreKey
GROUP BY ds.StoreName
ORDER BY TotalSales DESC;
```

</details>
