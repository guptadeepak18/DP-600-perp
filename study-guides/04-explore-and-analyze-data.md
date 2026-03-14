# Domain 4: Explore and Analyze Data (20–25%)

## Study Guide for Microsoft DP-600 Exam

> **Exam Weight:** This domain represents 20–25% of the DP-600 exam. It covers reporting,
> querying with T-SQL/KQL/DAX, advanced analytics, deployment pipelines, source control,
> sensitivity labels, and performance monitoring.

---

## Table of Contents

1. [Power BI Reporting and Dashboards](#1-power-bi-reporting-and-dashboards)
2. [T-SQL Querying](#2-t-sql-querying)
3. [KQL (Kusto Query Language)](#3-kql-kusto-query-language)
4. [DAX Querying](#4-dax-querying)
5. [Advanced Analytics](#5-advanced-analytics)
6. [Deployment Pipelines](#6-deployment-pipelines)
7. [Source Control and CI/CD](#7-source-control-and-cicd)
8. [Sensitivity Labels and Data Endorsement](#8-sensitivity-labels-and-data-endorsement)
9. [Monitoring and Optimizing Performance and Cost](#9-monitoring-and-optimizing-performance-and-cost)

---

## 1. Power BI Reporting and Dashboards

### Report Design Best Practices

Effective report design focuses on **clarity**, **performance**, and **user experience**. Key principles include:

- **Start with the audience**: Identify who will consume the report and what decisions they need to make.
- **Use a consistent layout**: Place filters at the top or left, KPIs prominently, and details below.
- **Limit visuals per page**: Aim for 6–8 visuals maximum per page to reduce cognitive overload and improve rendering performance.
- **Use white space**: Avoid cluttering the canvas; give visuals room to breathe.
- **Follow a Z-pattern or F-pattern**: Users scan left-to-right, top-to-bottom.
- **Provide context**: Use titles, subtitles, and data labels to clarify what the visual shows.

> **💡 Tip:** Use the Performance Analyzer in Power BI Desktop (View → Performance Analyzer) to identify slow-rendering visuals and optimize them before publishing.

### Visual Types and When to Use Each

| Visual Type | Best Used For | Key Notes |
|---|---|---|
| **Bar/Column Chart** | Comparing categories | Horizontal bars for many categories; vertical columns for time-based |
| **Line Chart** | Trends over time | Best for continuous data; use markers for discrete points |
| **Pie/Donut Chart** | Part-to-whole (≤5 categories) | Avoid for many slices; consider treemap instead |
| **Table/Matrix** | Detailed data exploration | Matrix supports row/column hierarchies and subtotals |
| **Card/Multi-row Card** | Single KPI or metric | Use conditional formatting for thresholds |
| **KPI Visual** | Goal tracking | Shows value, target, and trend |
| **Map (Filled/Bubble)** | Geographic data | Use Azure Maps for advanced geo scenarios |
| **Scatter Chart** | Correlation between two measures | Add a play axis for animation over time |
| **Waterfall Chart** | Incremental changes | Great for financial analysis (revenue breakdown) |
| **Funnel Chart** | Sequential stage reduction | Sales pipeline, conversion funnels |
| **Gauge** | Single value against a target | Keep the range meaningful |
| **Treemap** | Hierarchical part-to-whole | Better than pie charts for many categories |
| **Decomposition Tree** | AI-driven root cause analysis | Allows drill-down by any dimension |
| **Key Influencers** | AI-driven factor analysis | Identifies what drives a metric |
| **Ribbon Chart** | Ranking changes over time | Shows how rank positions shift across periods |
| **Slicer** | Interactive filtering | Dropdown, list, between, relative date, etc. |

### Bookmarks, Drill-Through, and Drill-Down

**Bookmarks** capture the current state of a report page including filters, slicers, visibility, and sort order.

- **Use cases**: Toggle between views, create guided narratives, simulate page navigation.
- **Types**: Personal bookmarks (viewer-created) and Report bookmarks (author-created).
- Combine bookmarks with **buttons** and **images** for interactive navigation.

**Drill-through** allows users to right-click a data point and navigate to a detail page filtered to that context.

- Configure by adding fields to the **Drill-through filters** well on the target page.
- Use **cross-report drill-through** to navigate between different reports.
- The back button is automatically added; customize its position.

**Drill-down** works within hierarchies (e.g., Year → Quarter → Month → Day).

- Enable by adding multiple fields to the axis or category well.
- Users can drill down/up using the visual header icons.
- **Expand all down one level** expands all data points simultaneously.

### Report-Level, Page-Level, and Visual-Level Filters

| Filter Scope | Applies To | Configured In |
|---|---|---|
| **Report-level** | All pages in the report | Filters pane → Filters on all pages |
| **Page-level** | All visuals on the current page | Filters pane → Filters on this page |
| **Visual-level** | Only the selected visual | Filters pane → Filters on this visual |

> **📝 Note:** You can lock filters or hide the entire filter pane from end users. Use `Format → Filter pane → Allow filtering` settings.

- **Slicer sync** allows a slicer on one page to affect visuals on other pages.
- **Advanced filtering** supports conditions like "contains", "starts with", "is blank", TopN, and relative date filtering.

### Paginated Reports Basics

Paginated reports (`.rdl` format) are designed for **printing** and **pixel-perfect output**. They are built in **Power BI Report Builder**.

- **Key differences from interactive reports**:
  - Every row of data can be rendered (no visual-level row limits).
  - Ideal for invoices, statements, and regulatory documents.
  - Support parameters for user-driven filtering.
  - Can export to PDF, Excel, Word, CSV, XML, and more.

- **Data sources**: Can connect to Power BI datasets, Azure SQL, SQL Server, and other sources.
- **Publishing**: Paginated reports are published to Power BI Service workspaces backed by Premium, PPU, or Fabric capacity.

### Mobile Layout Optimization

- Use the **Mobile layout** view in Power BI Desktop to arrange visuals for phone screens.
- Drag and drop visuals from the desktop layout onto a phone-sized canvas.
- Not all visuals render identically on mobile; test in the Power BI mobile app.
- Mobile layouts support **bookmarks** and **buttons** for navigation.

### Themes and Formatting

- **Built-in themes**: Apply pre-configured color palettes from View → Themes.
- **Custom themes**: Create a `.json` theme file to define colors, fonts, visual defaults, and more.
- **Conditional formatting**: Apply background color, font color, data bars, icons, and web URLs based on field values or rules.

```json
{
  "name": "Corporate Theme",
  "dataColors": ["#0078D4", "#50E6FF", "#00BCF2", "#8661C5", "#E3008C"],
  "background": "#FFFFFF",
  "foreground": "#323130",
  "tableAccent": "#0078D4"
}
```

> **🔗 Docs:** [Power BI Report Design Best Practices](https://learn.microsoft.com/power-bi/guidance/power-bi-optimization)

---

## 2. T-SQL Querying

### SELECT, JOINs, Subqueries, and CTEs

T-SQL is essential for querying data in **Fabric Warehouses** and **Lakehouse SQL endpoints**.

#### Basic SELECT

```sql
SELECT
    ProductName,
    Category,
    UnitPrice,
    UnitsInStock
FROM dbo.Products
WHERE UnitPrice > 20
ORDER BY UnitPrice DESC;
```

#### JOINs

| Join Type | Description |
|---|---|
| `INNER JOIN` | Returns rows with matches in both tables |
| `LEFT JOIN` | Returns all rows from the left table plus matched rows from the right |
| `RIGHT JOIN` | Returns all rows from the right table plus matched rows from the left |
| `FULL OUTER JOIN` | Returns all rows from both tables, with NULLs where no match exists |
| `CROSS JOIN` | Cartesian product of both tables |

```sql
SELECT
    o.OrderID,
    c.CustomerName,
    p.ProductName,
    od.Quantity,
    od.UnitPrice * od.Quantity AS TotalAmount
FROM dbo.Orders o
INNER JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN dbo.Products p ON od.ProductID = p.ProductID
WHERE o.OrderDate >= '2024-01-01';
```

#### Subqueries

```sql
-- Scalar subquery
SELECT ProductName, UnitPrice
FROM dbo.Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM dbo.Products);

-- EXISTS subquery
SELECT c.CustomerName
FROM dbo.Customers c
WHERE EXISTS (
    SELECT 1 FROM dbo.Orders o
    WHERE o.CustomerID = c.CustomerID
    AND o.OrderDate >= '2024-01-01'
);
```

#### Common Table Expressions (CTEs)

```sql
WITH MonthlySales AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(TotalAmount) AS MonthlyTotal
    FROM dbo.Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),
RankedMonths AS (
    SELECT *,
        RANK() OVER (PARTITION BY OrderYear ORDER BY MonthlyTotal DESC) AS MonthRank
    FROM MonthlySales
)
SELECT * FROM RankedMonths
WHERE MonthRank <= 3;
```

### Window Functions

Window functions perform calculations across a set of rows related to the current row **without collapsing the result set**.

```sql
SELECT
    EmployeeID,
    Department,
    Salary,
    ROW_NUMBER() OVER (ORDER BY Salary DESC) AS RowNum,
    RANK() OVER (ORDER BY Salary DESC) AS SalaryRank,
    DENSE_RANK() OVER (ORDER BY Salary DESC) AS DenseSalaryRank,
    LAG(Salary, 1) OVER (PARTITION BY Department ORDER BY HireDate) AS PrevSalary,
    LEAD(Salary, 1) OVER (PARTITION BY Department ORDER BY HireDate) AS NextSalary,
    SUM(Salary) OVER (PARTITION BY Department) AS DeptTotalSalary,
    AVG(Salary) OVER (PARTITION BY Department) AS DeptAvgSalary
FROM dbo.Employees;
```

| Function | Description |
|---|---|
| `ROW_NUMBER()` | Unique sequential number for each row; no ties |
| `RANK()` | Ranking with gaps for ties (1, 2, 2, 4) |
| `DENSE_RANK()` | Ranking without gaps for ties (1, 2, 2, 3) |
| `LAG(col, n)` | Access a value from `n` rows before the current row |
| `LEAD(col, n)` | Access a value from `n` rows after the current row |
| `NTILE(n)` | Distributes rows into `n` groups |
| `SUM() OVER()` | Running or partitioned sum |
| `AVG() OVER()` | Running or partitioned average |

### Aggregate Functions

```sql
SELECT
    Category,
    COUNT(*) AS ProductCount,
    SUM(UnitPrice) AS TotalPrice,
    AVG(UnitPrice) AS AvgPrice,
    MIN(UnitPrice) AS MinPrice,
    MAX(UnitPrice) AS MaxPrice,
    STDEV(UnitPrice) AS PriceStdDev,
    VAR(UnitPrice) AS PriceVariance,
    STRING_AGG(ProductName, ', ') AS ProductList
FROM dbo.Products
GROUP BY Category
HAVING COUNT(*) > 5
ORDER BY ProductCount DESC;
```

### T-SQL in Fabric Lakehouse SQL Endpoint

The **SQL analytics endpoint** provides a read-only T-SQL interface to Lakehouse Delta tables.

- **Automatically generated**: When you create a Lakehouse, the SQL endpoint is created automatically.
- **Read-only**: You can run `SELECT` queries but not `INSERT`, `UPDATE`, or `DELETE`.
- **Supports views**: You can create views, stored procedures (read-only), and functions.
- **Schema**: Tables appear in the `dbo` schema by default.

```sql
-- Query a Lakehouse table via SQL endpoint
SELECT
    ProductCategory,
    COUNT(*) AS TotalProducts,
    AVG(Price) AS AvgPrice
FROM dbo.Products
GROUP BY ProductCategory;

-- Create a view in the SQL endpoint
CREATE VIEW dbo.vw_TopProducts AS
SELECT TOP 100
    ProductName,
    TotalSales
FROM dbo.SalesSummary
ORDER BY TotalSales DESC;
```

> **💡 Tip:** The SQL endpoint is ideal for BI tools (like Power BI) that connect via SQL, or for analysts who prefer T-SQL over PySpark.

### T-SQL in Fabric Warehouse

The **Fabric Warehouse** supports full read-write T-SQL operations.

- **Full DML**: Supports `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `CREATE TABLE`, etc.
- **Automatic distribution**: Tables are automatically distributed; no need to specify distribution keys.
- **Cross-database queries**: Query across warehouses and lakehouses in the same workspace.

```sql
-- Create and populate a table in Fabric Warehouse
CREATE TABLE dbo.SalesFact (
    SaleID INT,
    ProductID INT,
    CustomerID INT,
    SaleDate DATE,
    Amount DECIMAL(18, 2)
);

INSERT INTO dbo.SalesFact
SELECT * FROM dbo.StagingSales
WHERE SaleDate >= '2024-01-01';

-- MERGE example
MERGE dbo.DimCustomer AS target
USING dbo.StagingCustomer AS source
ON target.CustomerID = source.CustomerID
WHEN MATCHED THEN
    UPDATE SET
        target.CustomerName = source.CustomerName,
        target.Email = source.Email
WHEN NOT MATCHED THEN
    INSERT (CustomerID, CustomerName, Email)
    VALUES (source.CustomerID, source.CustomerName, source.Email);
```

### Cross-Database Queries

In Microsoft Fabric, you can query across databases within the same workspace:

```sql
-- Query across a Warehouse and a Lakehouse SQL endpoint
SELECT
    w.OrderID,
    w.OrderDate,
    l.ProductName,
    l.Category
FROM MyWarehouse.dbo.Orders w
INNER JOIN MyLakehouse.dbo.Products l
    ON w.ProductID = l.ProductID;
```

> **📝 Note:** Cross-database queries work within the same workspace. The user must have permissions on both items.

> **🔗 Docs:** [T-SQL in Microsoft Fabric](https://learn.microsoft.com/fabric/data-warehouse/tsql-surface-area)

---

## 3. KQL (Kusto Query Language)

### KQL Fundamentals and Syntax

KQL is the primary query language for **Real-Time Analytics** in Microsoft Fabric, including **KQL Databases** and **Eventhouses**.

Key characteristics:
- **Read-only** query language (data ingestion is separate).
- **Pipe-based syntax**: Statements flow from left to right using the `|` operator.
- **Case-sensitive**: Table and column names are case-sensitive.
- **Schema-on-read**: Flexible handling of semi-structured data.

```kql
// Basic KQL query structure
TableName
| where Timestamp > ago(1h)
| summarize Count = count() by Category
| order by Count desc
| take 10
```

### KQL Database and Queryset

- **KQL Database**: Stores data in an optimized columnar format, ideal for time-series and log data. Created inside an **Eventhouse**.
- **KQL Queryset**: A saved collection of KQL queries that can be shared and version-controlled in a Fabric workspace.
- **One-click ingestion**: Load data from local files, Azure Storage, Event Hubs, or other sources.

### Common Operators

#### `where` – Filtering rows

```kql
StormEvents
| where State == "TEXAS"
| where StartTime between (datetime(2024-01-01) .. datetime(2024-12-31))
| where DamageProperty > 1000
```

#### `summarize` – Aggregation

```kql
StormEvents
| summarize
    TotalEvents = count(),
    AvgDamage = avg(DamageProperty),
    MaxDamage = max(DamageProperty)
    by State, EventType
| order by TotalEvents desc
```

#### `extend` – Adding calculated columns

```kql
StormEvents
| extend DurationHours = (EndTime - StartTime) / 1h
| extend DamageCategory = case(
    DamageProperty > 1000000, "Severe",
    DamageProperty > 100000, "Significant",
    DamageProperty > 10000, "Moderate",
    "Minor"
)
```

#### `project` – Selecting and renaming columns

```kql
StormEvents
| project
    EventDate = StartTime,
    State,
    EventType,
    Damage = DamageProperty
| take 100
```

#### `join` – Combining tables

```kql
StormEvents
| join kind=inner (
    PopulationData
    | project State, Population
) on State
| extend DamagePerCapita = DamageProperty / Population
```

KQL join kinds: `inner`, `leftouter`, `rightouter`, `fullouter`, `leftanti`, `rightanti`, `leftsemi`, `rightsemi`.

#### `render` – Visualization

```kql
StormEvents
| summarize EventCount = count() by bin(StartTime, 1d)
| render timechart with (title="Daily Storm Events")
```

Render types: `timechart`, `barchart`, `piechart`, `columnchart`, `areachart`, `scatterchart`, `table`.

### Time Series Analysis with KQL

KQL excels at time series operations:

```kql
// Time series with bins
SensorData
| where Timestamp > ago(7d)
| summarize AvgTemperature = avg(Temperature) by bin(Timestamp, 1h)
| render timechart

// make-series for regular time series
SensorData
| make-series AvgTemp = avg(Temperature) default=0
    on Timestamp from ago(7d) to now() step 1h
    by SensorId
| render timechart

// Anomaly detection on time series
SensorData
| make-series AvgTemp = avg(Temperature) default=0
    on Timestamp from ago(30d) to now() step 1h
| extend anomalies = series_decompose_anomalies(AvgTemp)
```

### Real-Time Analytics Scenarios

| Scenario | Fabric Component | Description |
|---|---|---|
| IoT telemetry | Eventhouse + KQL DB | Ingest device telemetry, analyze in real time |
| Application logs | Eventhouse + KQL DB | Stream logs for monitoring and alerting |
| Clickstream | Eventstream + KQL DB | Analyze user behavior patterns |
| Financial ticks | Eventstream + KQL DB | Monitor market data with low latency |

- **Eventstream** captures and routes real-time events to KQL Databases.
- **Real-Time Dashboards** visualize KQL query results with auto-refresh.
- **Data Activator** triggers alerts based on conditions in real-time data.

### KQL vs T-SQL Comparison

| Feature | KQL | T-SQL |
|---|---|---|
| **Syntax style** | Pipe-based (`\|`) | Clause-based (`SELECT...FROM...WHERE`) |
| **Primary use** | Log/time-series analytics | Relational data operations |
| **Case sensitivity** | Case-sensitive | Case-insensitive (default) |
| **Write operations** | No (read-only queries) | Yes (full DML in Warehouse) |
| **Time operations** | Native (`ago()`, `bin()`, `between`) | Requires `DATEADD`, `DATEDIFF`, etc. |
| **String operations** | `has`, `contains`, `matches regex` | `LIKE`, `CHARINDEX`, `PATINDEX` |
| **Visualization** | Built-in `render` operator | No built-in rendering |
| **Fabric component** | Eventhouse / KQL Database | Warehouse / Lakehouse SQL endpoint |

```kql
// KQL equivalent
StormEvents
| where State == "TEXAS"
| summarize Count = count() by EventType
| order by Count desc
```

```sql
-- T-SQL equivalent
SELECT EventType, COUNT(*) AS Count
FROM StormEvents
WHERE State = 'TEXAS'
GROUP BY EventType
ORDER BY Count DESC;
```

> **🔗 Docs:** [KQL in Microsoft Fabric](https://learn.microsoft.com/fabric/real-time-intelligence/kusto-query-language)

---

## 4. DAX Querying

### EVALUATE Statement

The `EVALUATE` statement is the foundation of DAX queries. Unlike DAX measures (which return scalar values), DAX queries return **tables**.

```dax
// Basic EVALUATE query
EVALUATE
    SUMMARIZECOLUMNS(
        'Product'[Category],
        "Total Sales", [Total Sales],
        "Avg Price", [Average Price]
    )

// With ORDER BY
EVALUATE
    SUMMARIZECOLUMNS(
        'Date'[Year],
        'Date'[Month],
        "Monthly Revenue", [Total Revenue]
    )
ORDER BY 'Date'[Year] ASC, 'Date'[Month] ASC

// Multiple EVALUATE statements
DEFINE
    MEASURE 'Sales'[YTD Sales] =
        TOTALYTD([Total Sales], 'Date'[Date])

EVALUATE
    SUMMARIZECOLUMNS(
        'Date'[Year],
        'Date'[Quarter],
        "YTD Sales", [YTD Sales]
    )
```

### DAX Queries in DAX Studio

**DAX Studio** is a free, open-source tool for writing and optimizing DAX queries.

Key features:
- **Query editor** with IntelliSense for DAX.
- **Server Timings**: Shows Formula Engine (FE) and Storage Engine (SE) times.
- **Query Plan**: Reveals the logical and physical query plans.
- **VertiPaq Analyzer**: Examines model size, column cardinality, and encoding.
- **Export results**: To CSV, Excel, or clipboard.

Common workflow:
1. Connect DAX Studio to your Power BI dataset.
2. Write a DAX query using `EVALUATE`.
3. Enable Server Timings (under Traces).
4. Run the query and analyze FE/SE times.
5. Optimize by reducing FE time (complex calculations) or SE time (data scanning).

> **💡 Tip:** If Storage Engine time is high, consider optimizing your model (reduce cardinality, remove unnecessary columns). If Formula Engine time is high, simplify your DAX expressions.

### TOPN, FILTER, and CALCULATETABLE

#### TOPN

```dax
// Top 10 products by sales
EVALUATE
    TOPN(
        10,
        SUMMARIZECOLUMNS(
            'Product'[ProductName],
            "Sales", [Total Sales]
        ),
        [Sales], DESC
    )
```

#### FILTER

```dax
// Filtered table expression
EVALUATE
    FILTER(
        ALL('Product'),
        'Product'[Category] = "Electronics"
            && RELATED('Sales'[Quantity]) > 100
    )
```

#### CALCULATETABLE

```dax
// Returns a table with modified filter context
EVALUATE
    CALCULATETABLE(
        SUMMARIZECOLUMNS(
            'Product'[Category],
            "Sales", [Total Sales]
        ),
        'Date'[Year] = 2024,
        'Product'[IsActive] = TRUE
    )
```

### Query Performance Analysis

| Metric | Meaning | Target |
|---|---|---|
| **Total Duration** | End-to-end query time | < 1 second for interactive |
| **FE (Formula Engine)** | Time spent on DAX calculations | Minimize; runs single-threaded |
| **SE (Storage Engine)** | Time spent scanning data | Optimize model; can be multi-threaded |
| **SE Queries** | Number of storage engine requests | Fewer is better |
| **SE Cache** | Whether SE results were cached | Cache hits improve performance |

Best practices for DAX performance:
- Avoid iterating over large tables with `FILTER` when `CALCULATE` suffices.
- Use variables (`VAR`) to avoid redundant calculations.
- Prefer `DISTINCTCOUNT` over `COUNTROWS(DISTINCT(...))`.
- Minimize use of `EARLIER` (use `VAR` instead).
- Test with both cold and warm cache scenarios.

> **🔗 Docs:** [DAX Queries](https://learn.microsoft.com/dax/dax-queries)

---

## 5. Advanced Analytics

### Statistical Functions and Analysis

Power BI and DAX support built-in statistical analysis:

```dax
// Statistical measures in DAX
Average Sales = AVERAGE(Sales[Amount])
Median Sales = MEDIAN(Sales[Amount])
Standard Deviation = STDEV.S(Sales[Amount])
Variance = VAR.S(Sales[Amount])
Percentile 95 = PERCENTILEX.INC(Sales, Sales[Amount], 0.95)

// Correlation (using DAX)
Correlation =
VAR MeanX = AVERAGE(Data[X])
VAR MeanY = AVERAGE(Data[Y])
VAR Numerator =
    SUMX(Data, (Data[X] - MeanX) * (Data[Y] - MeanY))
VAR DenomX =
    SUMX(Data, (Data[X] - MeanX) ^ 2)
VAR DenomY =
    SUMX(Data, (Data[Y] - MeanY) ^ 2)
RETURN
    DIVIDE(Numerator, SQRT(DenomX * DenomY))
```

### Forecasting and Trend Analysis

- **Built-in forecasting** in line charts: Right-click a line chart → Analytics → Forecast.
  - Configure forecast length, confidence interval, and seasonality.
  - Uses exponential smoothing algorithms.
- **Trend lines**: Add linear, exponential, logarithmic, polynomial, or moving average trend lines.
- **DAX-based forecasting**: Use time intelligence functions with custom regression formulas.

```dax
// Linear trend calculation in DAX
Linear Trend =
VAR KnownX = RANKX(ALL('Date'[Month]), 'Date'[Month])
VAR KnownY = [Total Sales]
VAR AvgX = AVERAGEX(ALL('Date'[Month]), RANKX(ALL('Date'[Month]), 'Date'[Month]))
VAR AvgY = AVERAGEX(ALL('Date'[Month]), [Total Sales])
VAR Slope =
    DIVIDE(
        SUMX(ALL('Date'[Month]),
            (RANKX(ALL('Date'[Month]), 'Date'[Month]) - AvgX) *
            ([Total Sales] - AvgY)
        ),
        SUMX(ALL('Date'[Month]),
            (RANKX(ALL('Date'[Month]), 'Date'[Month]) - AvgX) ^ 2
        )
    )
VAR Intercept = AvgY - Slope * AvgX
RETURN
    Slope * KnownX + Intercept
```

### Anomaly Detection

- **Built-in anomaly detection** in Power BI line charts:
  - Enable via Analytics pane → Find Anomalies.
  - Automatically detects unexpected spikes or dips.
  - Uses the **SR-CNN** (Spectral Residual and Convolutional Neural Network) algorithm.
  - Provides **explanations** for each anomaly with contributing factors.

- **KQL-based anomaly detection**:

```kql
SensorData
| make-series AvgValue = avg(Value) on Timestamp from ago(30d) to now() step 1h
| extend (anomalies, score, baseline) = series_decompose_anomalies(AvgValue, 1.5)
| mv-expand Timestamp to typeof(datetime),
    AvgValue to typeof(double),
    anomalies to typeof(int),
    score to typeof(double),
    baseline to typeof(double)
| where anomalies != 0
```

### AI Insights in Power BI

Power BI integrates AI capabilities directly into the report authoring experience:

| Feature | Description | Location |
|---|---|---|
| **Key Influencers** | Identifies factors driving a metric | AI visuals gallery |
| **Decomposition Tree** | Interactive drill-down analysis | AI visuals gallery |
| **Smart Narratives** | Auto-generated text summaries | Visuals gallery |
| **Q&A Visual** | Natural language queries | Visuals gallery |
| **Anomaly Detection** | Detects outliers in line charts | Analytics pane |
| **Azure ML Integration** | Use registered ML models in dataflows | Power Query / Dataflows |
| **Cognitive Services** | Sentiment analysis, key phrase extraction, image tagging | Power Query / Dataflows |

### Python and R Visuals

Power BI supports Python and R script visuals for advanced custom visualizations.

**Python visual example:**

```python
# Python script visual in Power BI
import matplotlib.pyplot as plt
import seaborn as sns

# 'dataset' is automatically created from fields dragged into the visual
fig, ax = plt.subplots(figsize=(10, 6))
sns.boxplot(data=dataset, x='Category', y='Sales', ax=ax)
ax.set_title('Sales Distribution by Category')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

**R visual example:**

```r
# R script visual in Power BI
library(ggplot2)

# 'dataset' is automatically provided
ggplot(dataset, aes(x = Category, y = Sales, fill = Category)) +
  geom_violin() +
  theme_minimal() +
  labs(title = "Sales Distribution by Category")
```

> **📝 Note:** Python/R visuals require a local Python/R installation. They render as static images and have security implications in the Service (must be enabled by admin).

### Smart Narratives and Q&A

**Smart Narratives:**
- Auto-generate natural language summaries of your data.
- Dynamically update as filters and slicers change.
- Customizable with manual text and dynamic value references.

**Q&A Visual:**
- Users type natural language questions (e.g., "total sales by region last quarter").
- Power BI interprets the question and generates a visual.
- **Improve Q&A** by adding synonyms, featured questions, and teaching Q&A new terms in the model.
- Works best with well-modeled data (proper naming, relationships, descriptions).

> **🔗 Docs:** [AI Visuals in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-ai-insights)

---

## 6. Deployment Pipelines

### Dev/Test/Prod Pipeline Stages

Deployment pipelines in Microsoft Fabric enable **application lifecycle management (ALM)** with up to 10 custom stages (commonly Dev → Test → Prod).

```
┌─────────┐     ┌─────────┐     ┌──────────┐
│   DEV   │ ──► │  TEST   │ ──► │   PROD   │
│Workspace│     │Workspace│     │Workspace │
└─────────┘     └─────────┘     └──────────┘
```

- Each stage maps to a **Fabric workspace**.
- Items are deployed (copied) from one stage to the next.
- Supported items: Semantic models, reports, dashboards, dataflows, datamarts, lakehouses, warehouses, notebooks, and more.

### Pipeline Configuration

1. **Create a pipeline** in the Fabric portal under Deployment Pipelines.
2. **Assign workspaces** to each stage.
3. **Configure deployment rules** (see below).
4. **Set permissions**: Pipeline admins, workspace contributors.

### Deployment Rules

Deployment rules allow you to **change configuration values** when deploying between stages, such as:

| Rule Type | Example |
|---|---|
| **Data source rules** | Change connection string from dev DB to prod DB |
| **Parameter rules** | Change Power Query parameters (e.g., server name) |
| **Lakehouse rules** | Point to different lakehouse in target stage |
| **Warehouse rules** | Point to different warehouse in target stage |

```
Example: Data source rule
  Source stage (Dev):  Server = dev-sql-server.database.windows.net
  Target stage (Prod): Server = prod-sql-server.database.windows.net
```

### Comparing Stages

- The pipeline UI shows a **comparison view** between adjacent stages.
- Indicators show whether items are: **Identical**, **Different**, **New** (only in source), or **Missing** (only in target).
- Use the comparison to decide which items to deploy.

### Selective Deployment

- Deploy **all items** or **select specific items** to move between stages.
- Choose between deploying:
  - Content only (report layout)
  - Content + data source bindings
  - Content + rules applied
- **Backwards deployment** is supported (e.g., Prod → Test for hotfixes).

### Automating Deployment with APIs

Use the **Fabric REST APIs** to automate pipeline deployments in CI/CD:

```powershell
# PowerShell example: Trigger deployment via REST API
$pipelineId = "your-pipeline-id"
$sourceStage = 0  # Dev = 0, Test = 1, Prod = 2

$body = @{
    sourceStageOrder = $sourceStage
    isBackwardDeployment = $false
    newWorkspace = @{
        capacityId = "target-capacity-id"
    }
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "https://api.fabric.microsoft.com/v1/deploymentPipelines/$pipelineId/deploy" `
    -Method POST `
    -Headers @{ Authorization = "Bearer $token" } `
    -Body $body `
    -ContentType "application/json"
```

> **🔗 Docs:** [Deployment Pipelines in Fabric](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines)

---

## 7. Source Control and CI/CD

### Git Integration in Fabric

Microsoft Fabric natively integrates with **Git repositories** (Azure DevOps or GitHub) for version control.

Key concepts:
- **Connect workspace to a Git repo**: Settings → Git integration.
- **Sync direction**: Workspace ↔ Git (bidirectional).
- **Commit**: Save workspace changes to the Git branch.
- **Update**: Pull changes from Git into the workspace.
- **Conflict resolution**: Handled in the Fabric portal when changes conflict.
- **Supported items**: Semantic models, reports, notebooks, pipelines, lakehouses, and more.

### Azure DevOps Integration

1. Create an Azure DevOps project with a Git repository.
2. In Fabric, go to Workspace Settings → Git integration → Azure DevOps.
3. Select the organization, project, repository, and branch.
4. Map the workspace folder path.

```yaml
# Example: Azure DevOps pipeline for Fabric deployment
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: PowerShell@2
    displayName: 'Deploy to Fabric'
    inputs:
      targetType: 'inline'
      script: |
        # Authenticate and deploy using Fabric REST APIs
        $token = (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token
        # Trigger deployment pipeline or update workspace
```

### GitHub Integration

1. Create a GitHub repository.
2. In Fabric, go to Workspace Settings → Git integration → GitHub.
3. Authenticate with GitHub and select the repository and branch.
4. Same bidirectional sync capabilities as Azure DevOps.

> **📝 Note:** GitHub integration requires the Fabric admin to enable it at the tenant level.

### Branching Strategies

| Strategy | Description | Best For |
|---|---|---|
| **Feature branching** | Create a branch per feature/change | Teams with multiple developers |
| **GitFlow** | Separate branches for dev, release, hotfix | Complex release cycles |
| **Trunk-based** | Small, frequent commits to main | Continuous delivery teams |
| **Release branching** | Branch per release version | Products with multiple supported versions |

Recommended approach for Fabric:
1. **Main branch** → connected to the Production workspace.
2. **Development branch** → connected to the Dev workspace.
3. **Feature branches** → developers work in isolation, merge to dev via Pull Requests.

### CI/CD Automation for Fabric Items

Automate the full lifecycle:

1. **Source Control**: Store Fabric item definitions in Git.
2. **Build**: Validate item definitions (schema checks, linting).
3. **Test**: Deploy to a test workspace and run validation queries.
4. **Release**: Use deployment pipelines or REST APIs to promote to production.

```bash
# Example: Using Fabric REST API to create/update items
curl -X POST "https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "SalesReport",
    "type": "Report",
    "definition": { ... }
  }'
```

### TMDL (Tabular Model Definition Language)

**TMDL** is a human-readable, text-based format for defining semantic models (formerly known as tabular models).

- **File-based**: Each table, measure, and relationship is stored in a separate `.tmdl` file.
- **Git-friendly**: Text-based format enables meaningful diffs and merge conflict resolution.
- **Replaces BIM**: TMDL is the modern alternative to the monolithic `.bim` (JSON) file.

```
// Example TMDL file: Sales.tmdl
table Sales
    column SaleID
        dataType: int64
        sourceColumn: SaleID

    column Amount
        dataType: decimal
        sourceColumn: Amount
        formatString: "$#,##0.00"

    measure 'Total Sales' =
        SUM(Sales[Amount])
        formatString: "$#,##0.00"

    measure 'YoY Growth' =
        VAR CurrentYear = [Total Sales]
        VAR PriorYear = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))
        RETURN DIVIDE(CurrentYear - PriorYear, PriorYear)
        formatString: "0.00%"
```

> **🔗 Docs:** [Git Integration in Fabric](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)

---

## 8. Sensitivity Labels and Data Endorsement

### Microsoft Information Protection Labels

Sensitivity labels from **Microsoft Purview Information Protection** can be applied to Fabric items to classify and protect data.

| Label | Typical Usage | Effect |
|---|---|---|
| **Public** | Non-sensitive data | No restrictions |
| **General** | Internal business data | Basic classification |
| **Confidential** | Sensitive business data | Encryption, access restrictions |
| **Highly Confidential** | Restricted data (PII, financial) | Strict encryption, limited access |

Key behaviors:
- Labels are applied at the **item level** (dataset, report, dashboard, dataflow, etc.).
- Labels **persist when data is exported** (e.g., to Excel, PDF, PowerPoint).
- Encryption follows the data even outside Power BI / Fabric.
- Labels are defined and managed in the **Microsoft Purview Compliance Portal**.

### Applying and Managing Labels

- **Manual application**: Users with appropriate permissions can apply labels in Fabric portal.
- **Default labels**: Admins can configure a default label that is automatically applied to new items.
- **Mandatory labeling**: Require users to apply a label before saving or publishing.
- **Label policies**: Defined in Microsoft Purview and pushed to users/groups.

To apply a label in Power BI:
1. Open a report or dataset in the Fabric portal.
2. Go to **File → Settings** or **More options (…) → Settings**.
3. Under **Sensitivity label**, select the appropriate label.

### Endorsement Types: Promoted and Certified

Endorsement helps users discover **trusted, authoritative content** in the organization.

| Endorsement | Who Can Apply | Purpose |
|---|---|---|
| **Promoted** | Any workspace member (Contributor+) | Indicates the item is ready for use; owner vouches for quality |
| **Certified** | Designated certifiers (configured by admin) | Organization-level approval; highest trust signal |

- **No endorsement** (default): Item is not explicitly trusted or promoted.
- **Promoted**: Appears with a blue badge; self-service endorsement.
- **Certified**: Appears with a gold badge; requires admin-designated certification authority.

To endorse an item:
1. Navigate to the item in the workspace.
2. Select **More options (…) → Settings → Endorsement**.
3. Choose **Promoted** or **Certified** (if authorized).

### Downstream Inheritance of Labels

Sensitivity labels can **inherit downstream** through the data lineage:

- When a **semantic model** has a label, reports built on it can automatically inherit the label.
- When data is **exported** from a labeled report, the export file receives the same label.
- **Inheritance rules**:
  - If a downstream item has no label, it inherits from the upstream item.
  - If a downstream item already has a label, the more restrictive label takes precedence.
  - Admins can enforce mandatory downstream inheritance.

```
Data Source → Lakehouse → Semantic Model → Report → Export
   (Confidential) →  (Confidential) →  (Confidential) → (Confidential)
```

> **💡 Tip:** For the exam, remember that sensitivity labels are part of **Microsoft Purview** and that endorsement is configured in **Fabric workspace settings**. These are often tested together.

> **🔗 Docs:** [Sensitivity Labels in Fabric](https://learn.microsoft.com/fabric/governance/information-protection)

---

## 9. Monitoring and Optimizing Performance and Cost

### Capacity Metrics App

The **Microsoft Fabric Capacity Metrics App** provides detailed monitoring of capacity utilization.

Key metrics:
- **CU (Capacity Units) consumption**: Track compute usage across all Fabric workloads.
- **Throttling status**: Shows when workloads are being throttled due to overutilization.
- **Background vs. interactive operations**: Understand what is consuming capacity.
- **Per-item breakdown**: See which items (datasets, reports, pipelines) consume the most resources.
- **Overages and smoothing**: Fabric uses a 24-hour smoothing window for capacity usage.

How to install:
1. Go to **AppSource** and search for "Microsoft Fabric Capacity Metrics".
2. Install the app and connect it to your capacity.
3. Monitor dashboards for utilization trends.

> **📝 Note:** Fabric uses a **burstable capacity model**. You can temporarily exceed your CU allocation, but sustained overuse leads to throttling. Background operations are throttled first, then interactive operations.

### Query Insights

Query Insights provide visibility into query execution in **Fabric Warehouses** and **SQL endpoints**.

- **queryinsights.exec_requests_history**: View historical query executions.
- **queryinsights.long_running_queries**: Identify queries that take too long.
- **queryinsights.frequently_run_queries**: Find the most common queries.

```sql
-- View recent query history
SELECT
    start_time,
    end_time,
    DATEDIFF(SECOND, start_time, end_time) AS duration_seconds,
    command,
    status
FROM queryinsights.exec_requests_history
WHERE start_time > DATEADD(HOUR, -24, GETDATE())
ORDER BY duration_seconds DESC;

-- Identify long-running queries
SELECT *
FROM queryinsights.long_running_queries
ORDER BY median_total_elapsed_time_ms DESC;
```

### Performance Monitoring Tools

| Tool | Purpose | Scope |
|---|---|---|
| **Capacity Metrics App** | Monitor capacity utilization | Entire capacity |
| **Query Insights** | Analyze SQL query performance | Warehouse / SQL endpoint |
| **Performance Analyzer** | Identify slow visuals in reports | Power BI Desktop |
| **DAX Studio** | Analyze DAX query performance | Semantic model |
| **SQL Server Profiler / Trace** | Trace Analysis Services queries | Semantic model |
| **Log Analytics** | Centralized logging and alerting | Azure-level monitoring |
| **Monitoring Hub** | View running and recent activities | Fabric workspace |
| **Admin Monitoring Workspace** | Tenant-level admin insights | Entire tenant |

### Cost Management Strategies

- **Right-size capacity**: Choose the appropriate Fabric SKU (F2, F4, F8, F16, F32, F64, etc.) based on workload.
- **Use reservation pricing**: Commit to 1-year reservations for significant discounts.
- **Pause unused capacities**: Stop paying for compute when not in use.
- **Optimize queries**: Reduce CU consumption through efficient queries and data models.
- **Use workspace-level monitoring**: Identify which workspaces/items consume the most resources.
- **Archive infrequently used data**: Move cold data to OneLake archive storage.

### Pause/Resume Capacity

Fabric capacities can be **paused** to stop billing when not in use.

- **Pause**: Stops all compute. No operations can run. Data is retained in OneLake.
- **Resume**: Restarts compute. Operations can resume where they left off.
- **Automation**: Use Azure Resource Manager APIs, PowerShell, or Azure CLI to schedule pause/resume.

```powershell
# Pause a Fabric capacity
az fabric capacity suspend \
    --resource-group "my-resource-group" \
    --capacity-name "my-fabric-capacity"

# Resume a Fabric capacity
az fabric capacity resume \
    --resource-group "my-resource-group" \
    --capacity-name "my-fabric-capacity"
```

> **💡 Tip:** Schedule pause/resume using Azure Automation runbooks or Logic Apps to automatically stop capacity outside business hours. This can save 50–70% on capacity costs.

### Autoscale Configuration

Autoscale allows Fabric capacity to **automatically scale up** during peak usage to avoid throttling.

- **How it works**: When utilization exceeds a threshold, additional CUs are temporarily added.
- **Configuration**:
  - Set a **maximum CU limit** to control costs.
  - Enable/disable autoscale in the Azure portal for the Fabric capacity.
  - Autoscale charges are billed per-second for the additional CUs consumed.

- **Considerations**:
  - Autoscale prevents throttling but increases cost.
  - Monitor autoscale events in the Capacity Metrics App.
  - Combine autoscale with query optimization for best cost-performance balance.

> **🔗 Docs:** [Monitor Fabric Capacity](https://learn.microsoft.com/fabric/enterprise/metrics-app)

---

## Exam Tips for Domain 4

### Common Exam Scenarios

1. **"A report is slow to render."** → Use Performance Analyzer to identify the slow visual, check DAX complexity, optimize the data model.

2. **"You need to query Lakehouse data with T-SQL."** → Use the SQL analytics endpoint (read-only). For write operations, use the Fabric Warehouse.

3. **"Real-time data needs to be analyzed."** → Use Eventstream → KQL Database → KQL Queryset → Real-Time Dashboard.

4. **"You need to move a report from Dev to Prod."** → Use Deployment Pipelines. Configure deployment rules for data source changes.

5. **"You need to protect sensitive data in reports."** → Apply Microsoft Purview sensitivity labels. Enable downstream inheritance.

6. **"Which endorsement should be used?"** → Promoted = self-service, team-level trust. Certified = admin-designated, org-level trust.

7. **"How to version control semantic models?"** → Use Git integration with TMDL format for readable diffs.

8. **"Capacity is being throttled."** → Check the Capacity Metrics App. Options: optimize queries, upgrade SKU, or enable autoscale.

9. **"You need anomaly detection on streaming data."** → Use `series_decompose_anomalies()` in KQL against an Eventhouse.

10. **"Compare DAX query performance."** → Use DAX Studio with Server Timings to compare FE vs SE times.

### Key Terminology Quick Reference

| Term | Definition |
|---|---|
| **CU** | Capacity Unit – the compute billing unit in Fabric |
| **SE** | Storage Engine – the data retrieval layer in a semantic model |
| **FE** | Formula Engine – the calculation layer for DAX expressions |
| **TMDL** | Tabular Model Definition Language – text-based model format |
| **KQL** | Kusto Query Language – query language for real-time analytics |
| **Eventhouse** | Fabric item that hosts KQL Databases |
| **Eventstream** | Fabric item for capturing and routing real-time events |
| **ALM** | Application Lifecycle Management |
| **MIP** | Microsoft Information Protection (sensitivity labels) |
| **SR-CNN** | Algorithm used for anomaly detection in Power BI |

---

## Additional Resources

- [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)
- [Power BI Documentation](https://learn.microsoft.com/power-bi/)
- [DAX Reference](https://learn.microsoft.com/dax/)
- [KQL Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)
- [T-SQL Reference for Fabric](https://learn.microsoft.com/fabric/data-warehouse/tsql-surface-area)
- [DP-600 Exam Skills Outline](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-600)
- [Fabric Deployment Pipelines](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines)
- [Git Integration in Fabric](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)

---

*Last updated: 2025*
