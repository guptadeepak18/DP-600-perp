# Advanced T-SQL Exercises

These exercises use the **Contoso Retail Analytics** practice database and focus on **Microsoft Fabric-specific** T-SQL features that are heavily tested on the DP-600 exam.

**Topics covered:** COPY INTO, CREATE TABLE AS SELECT (CTAS), cross-database queries, stored procedures, performance optimization, medallion architecture patterns, dynamic management views, and Fabric Warehouse T-SQL.

> **Note:** Some exercises reference Fabric-specific syntax that may not work in standard SQL Server. Where applicable, a SQL Server–compatible alternative is noted.

---

## Exercise 1 — COPY INTO: Load Data from Azure Storage

**Prompt:** Write a `COPY INTO` statement to load CSV data from an Azure Data Lake Storage Gen2 account into the `FactSales` table. The file is located at `https://contosolake.dfs.core.windows.net/raw/sales/2024/*.csv`. The files are comma-delimited with a header row, and use `DATEFORMAT` of `ymd`.

<details>
<summary>Solution</summary>

```sql
-- COPY INTO is the recommended high-performance ingestion method
-- for Microsoft Fabric Warehouse (replaces BULK INSERT / PolyBase).
COPY INTO FactSales
(
    SalesKey,
    OrderID,
    LineItemNumber,
    DateKey,
    CustomerKey,
    ProductKey,
    StoreKey,
    PromotionKey,
    Quantity,
    UnitPrice,
    UnitCost,
    DiscountAmount,
    SalesAmount,
    CostAmount,
    ProfitAmount,
    OrderDate,
    ShipDate,
    DeliveryDate,
    OrderStatus,
    PaymentMethod,
    CreatedAt
)
FROM 'https://contosolake.dfs.core.windows.net/raw/sales/2024/*.csv'
WITH (
    FILE_TYPE = 'CSV',
    FIRSTROW = 2,             -- Skip header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    DATEFORMAT = 'ymd',
    MAXERRORS = 10
);
```

</details>

---

## Exercise 2 — COPY INTO: Load Parquet Data

**Prompt:** Write a `COPY INTO` statement to load Parquet-formatted product data from `https://contosolake.dfs.core.windows.net/curated/products/` into the `DimProduct` table. Parquet files are self-describing, so field/row terminators are not needed.

<details>
<summary>Solution</summary>

```sql
-- Parquet is the preferred format in Fabric due to columnar storage
-- and built-in schema. No delimiters needed.
COPY INTO DimProduct
FROM 'https://contosolake.dfs.core.windows.net/curated/products/*.parquet'
WITH (
    FILE_TYPE = 'PARQUET'
);
```

</details>

---

## Exercise 3 — CREATE TABLE AS SELECT (CTAS): Aggregate Summary Table

**Prompt:** Using `CREATE TABLE AS SELECT`, create a new table called `Summary_MonthlySalesByStore` that contains the year, month, store name, total quantity sold, total sales amount, and total profit. This is a common pattern for building Gold-layer aggregation tables.

<details>
<summary>Solution</summary>

```sql
-- CTAS is the preferred pattern in Fabric Warehouse for creating
-- materialized summary/aggregate tables (Gold layer).
CREATE TABLE Summary_MonthlySalesByStore
AS
SELECT
    dd.Year,
    dd.MonthNumber,
    dd.MonthName,
    ds.StoreName,
    ds.Region,
    SUM(fs.Quantity)     AS TotalQuantity,
    SUM(fs.SalesAmount)  AS TotalSales,
    SUM(fs.ProfitAmount) AS TotalProfit,
    COUNT(*)             AS TransactionCount
FROM FactSales fs
INNER JOIN DimDate dd ON fs.DateKey = dd.DateKey
INNER JOIN DimStore ds ON fs.StoreKey = ds.StoreKey
GROUP BY
    dd.Year,
    dd.MonthNumber,
    dd.MonthName,
    ds.StoreName,
    ds.Region;
```

</details>

---

## Exercise 4 — Cross-Database Query in Fabric

**Prompt:** In Microsoft Fabric, you can query across databases within the same workspace using three-part naming. Write a query that joins the `FactSales` table in the current warehouse with a `DimGeography` table in a warehouse called `SharedDimensions`. Return the `OrderID`, `SalesAmount`, and geography `RegionName`.

<details>
<summary>Solution</summary>

```sql
-- Fabric supports cross-database queries using three-part naming:
-- [DatabaseName].[SchemaName].[TableName]
-- All warehouses in the same workspace are accessible.
SELECT
    fs.OrderID,
    fs.SalesAmount,
    geo.RegionName,
    geo.CountryName
FROM FactSales fs
INNER JOIN [SharedDimensions].[dbo].[DimGeography] geo
    ON fs.StoreKey = geo.StoreKey
ORDER BY fs.OrderDate;
```

</details>

---

## Exercise 5 — Stored Procedure: Refresh Summary Table

**Prompt:** Create a stored procedure called `usp_RefreshMonthlySalesSummary` that drops the `Summary_MonthlySalesByStore` table if it exists, then recreates it using the CTAS pattern from Exercise 3. This simulates a repeatable ETL refresh step.

<details>
<summary>Solution</summary>

```sql
CREATE PROCEDURE usp_RefreshMonthlySalesSummary
AS
BEGIN
    -- Drop existing summary table if it exists
    IF OBJECT_ID('Summary_MonthlySalesByStore', 'U') IS NOT NULL
        DROP TABLE Summary_MonthlySalesByStore;

    -- Recreate the summary using CTAS
    CREATE TABLE Summary_MonthlySalesByStore
    AS
    SELECT
        dd.Year,
        dd.MonthNumber,
        dd.MonthName,
        ds.StoreName,
        ds.Region,
        SUM(fs.Quantity)     AS TotalQuantity,
        SUM(fs.SalesAmount)  AS TotalSales,
        SUM(fs.ProfitAmount) AS TotalProfit,
        COUNT(*)             AS TransactionCount
    FROM FactSales fs
    INNER JOIN DimDate dd ON fs.DateKey = dd.DateKey
    INNER JOIN DimStore ds ON fs.StoreKey = ds.StoreKey
    GROUP BY
        dd.Year,
        dd.MonthNumber,
        dd.MonthName,
        ds.StoreName,
        ds.Region;
END;
```

</details>

---

## Exercise 6 — Medallion Architecture: Bronze to Silver Transformation

**Prompt:** You have a Bronze-layer staging table `Bronze_RawSalesEvents` with raw JSON-like string columns. Write a query to transform it into a clean Silver-layer table `Silver_Sales` with proper data types, deduplication (keep latest by `EventTimestamp`), and null handling. Use CTAS.

<details>
<summary>Solution</summary>

```sql
-- Medallion architecture: Bronze (raw) → Silver (cleansed/conformed)
-- This pattern deduplicates, casts types, and handles nulls.

CREATE TABLE Silver_Sales
AS
WITH Deduplicated AS (
    SELECT
        CAST(OrderID AS VARCHAR(20))           AS OrderID,
        CAST(CustomerID AS INT)                AS CustomerKey,
        CAST(ProductID AS INT)                 AS ProductKey,
        CAST(StoreID AS INT)                   AS StoreKey,
        CAST(Quantity AS INT)                  AS Quantity,
        CAST(SalesAmount AS DECIMAL(12,2))     AS SalesAmount,
        CAST(OrderDate AS DATE)                AS OrderDate,
        CAST(EventTimestamp AS DATETIME2(3))   AS EventTimestamp,
        ROW_NUMBER() OVER (
            PARTITION BY OrderID
            ORDER BY CAST(EventTimestamp AS DATETIME2(3)) DESC
        ) AS RowNum
    FROM Bronze_RawSalesEvents
    WHERE OrderID IS NOT NULL
      AND SalesAmount IS NOT NULL
)
SELECT
    OrderID,
    CustomerKey,
    ProductKey,
    StoreKey,
    COALESCE(Quantity, 0) AS Quantity,
    SalesAmount,
    OrderDate,
    EventTimestamp
FROM Deduplicated
WHERE RowNum = 1;
```

</details>

---

## Exercise 7 — Silver to Gold: Building a Denormalized Fact Table

**Prompt:** Create a Gold-layer denormalized table `Gold_SalesAnalysis` that combines `FactSales` with all dimension attributes needed for reporting. Include customer name, product details (name, category, brand), store info (name, region, type), date attributes (month, quarter, year), and calculated fields for profit margin percentage. Use CTAS.

<details>
<summary>Solution</summary>

```sql
-- Gold layer: Fully denormalized, ready for Power BI / Direct Lake.
CREATE TABLE Gold_SalesAnalysis
AS
SELECT
    -- Fact measures
    fs.SalesKey,
    fs.OrderID,
    fs.Quantity,
    fs.UnitPrice,
    fs.SalesAmount,
    fs.CostAmount,
    fs.ProfitAmount,
    fs.DiscountAmount,
    ROUND(fs.ProfitAmount * 100.0 / NULLIF(fs.SalesAmount, 0), 2) AS ProfitMarginPct,

    -- Date attributes
    dd.FullDate        AS OrderDate,
    dd.MonthName,
    dd.Quarter,
    dd.QuarterName,
    dd.Year,
    dd.FiscalYear,
    dd.FiscalQuarter,
    dd.IsWeekend,
    dd.IsHoliday,

    -- Customer attributes
    dc.FirstName + ' ' + dc.LastName AS CustomerName,
    dc.City            AS CustomerCity,
    dc.Country         AS CustomerCountry,
    dc.MembershipTier,

    -- Product attributes
    dp.ProductName,
    dp.Category        AS ProductCategory,
    dp.Subcategory     AS ProductSubcategory,
    dp.Brand,

    -- Store attributes
    ds.StoreName,
    ds.StoreType,
    ds.Region          AS StoreRegion,
    ds.Country         AS StoreCountry,

    -- Promotion attributes
    dpr.PromotionName,
    dpr.PromotionType,
    dpr.DiscountPercent AS PromoDiscountPct

FROM FactSales fs
INNER JOIN DimDate dd       ON fs.DateKey       = dd.DateKey
INNER JOIN DimCustomer dc   ON fs.CustomerKey   = dc.CustomerKey
INNER JOIN DimProduct dp    ON fs.ProductKey     = dp.ProductKey
INNER JOIN DimStore ds      ON fs.StoreKey       = ds.StoreKey
INNER JOIN DimPromotion dpr ON fs.PromotionKey   = dpr.PromotionKey;
```

</details>

---

## Exercise 8 — Dynamic Management Views: Query Performance Analysis

**Prompt:** Write queries using Fabric Warehouse dynamic management views (DMVs) to: (a) find the top 10 longest-running queries, and (b) find queries that were executed most frequently. These are key skills for performance troubleshooting in Fabric.

<details>
<summary>Solution</summary>

```sql
-- (a) Top 10 longest-running queries by total elapsed time
-- Fabric Warehouse exposes queryinsights views for monitoring.
SELECT TOP 10
    distributed_statement_id,
    start_time,
    end_time,
    DATEDIFF(SECOND, start_time, end_time) AS DurationSeconds,
    command,
    status
FROM queryinsights.exec_requests_history
ORDER BY DATEDIFF(SECOND, start_time, end_time) DESC;

-- (b) Most frequently executed query patterns
SELECT TOP 10
    command,
    COUNT(*) AS ExecutionCount,
    AVG(DATEDIFF(SECOND, start_time, end_time)) AS AvgDurationSeconds,
    MAX(DATEDIFF(SECOND, start_time, end_time)) AS MaxDurationSeconds
FROM queryinsights.exec_requests_history
WHERE status = 'Succeeded'
GROUP BY command
ORDER BY ExecutionCount DESC;
```

</details>

---

## Exercise 9 — Performance Optimization: Statistics and Query Tuning

**Prompt:** You notice a slow query joining `FactSales` with `DimProduct` filtering on `Category = 'Electronics'`. Write T-SQL to: (a) manually create column-level statistics on the join and filter columns, and (b) rewrite the query to be more efficient by filtering early with a CTE and minimizing the columns selected.

<details>
<summary>Solution</summary>

```sql
-- (a) Create statistics on key columns for the query optimizer.
-- Fabric Warehouse supports manual statistics creation.
CREATE STATISTICS stat_FactSales_ProductKey
    ON FactSales (ProductKey);

CREATE STATISTICS stat_DimProduct_ProductKey_Category
    ON DimProduct (ProductKey, Category);

-- (b) Optimized query: filter dimension first, select only needed columns.
WITH ElectronicsProducts AS (
    SELECT ProductKey, ProductName, Subcategory, Brand
    FROM DimProduct
    WHERE Category = 'Electronics'
)
SELECT
    ep.ProductName,
    ep.Subcategory,
    ep.Brand,
    SUM(fs.Quantity)    AS TotalQuantity,
    SUM(fs.SalesAmount) AS TotalSales
FROM FactSales fs
INNER JOIN ElectronicsProducts ep ON fs.ProductKey = ep.ProductKey
GROUP BY ep.ProductName, ep.Subcategory, ep.Brand
ORDER BY TotalSales DESC;
```

</details>

---

## Exercise 10 — End-to-End Pipeline: Incremental Load Pattern

**Prompt:** Write a T-SQL script that implements an incremental load pattern for `FactSales`. The script should: (a) find the maximum `CreatedAt` timestamp already in the warehouse, (b) use `COPY INTO` to load only new records from a staging area into a temporary table, (c) insert only truly new records (that don't already exist) into the main fact table, and (d) log the load metadata. This is a common Fabric data pipeline pattern.

<details>
<summary>Solution</summary>

```sql
-- Step 1: Capture the high-water mark (last loaded timestamp)
DECLARE @LastLoadTimestamp DATETIME2(3);
SELECT @LastLoadTimestamp = MAX(CreatedAt) FROM FactSales;

-- Step 2: Load new data from staging into a temp table using CTAS
-- (In Fabric, COPY INTO + CTAS is preferred over traditional temp tables)
CREATE TABLE Staging_NewSales
AS
SELECT *
FROM FactSales
WHERE 1 = 0;  -- Empty shell with matching schema

COPY INTO Staging_NewSales
FROM 'https://contosolake.dfs.core.windows.net/raw/sales/incremental/*.parquet'
WITH (
    FILE_TYPE = 'PARQUET'
);

-- Step 3: Insert only new records (avoid duplicates)
INSERT INTO FactSales
SELECT s.*
FROM Staging_NewSales s
WHERE NOT EXISTS (
    SELECT 1
    FROM FactSales f
    WHERE f.SalesKey = s.SalesKey
)
AND s.CreatedAt > @LastLoadTimestamp;

-- Step 4: Log the load operation
-- (In practice, write to an audit/metadata table)
CREATE TABLE IF NOT EXISTS LoadAuditLog (
    LoadId         INT IDENTITY(1,1),
    TableName      VARCHAR(100),
    RowsLoaded     INT,
    LoadTimestamp  DATETIME2(3)
);

INSERT INTO LoadAuditLog (TableName, RowsLoaded, LoadTimestamp)
SELECT
    'FactSales',
    COUNT(*),
    GETDATE()
FROM Staging_NewSales s
WHERE NOT EXISTS (
    SELECT 1 FROM FactSales f WHERE f.SalesKey = s.SalesKey
);

-- Step 5: Clean up staging
DROP TABLE Staging_NewSales;
```

> **Note:** In a production Fabric environment, you would typically orchestrate this via a **Data Pipeline** or **Notebook**, passing parameters for the file path and watermark. The T-SQL here demonstrates the warehouse-side logic.

</details>
