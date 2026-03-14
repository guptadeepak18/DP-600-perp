# Domain 2: Prepare and Serve Data (40–45%)

> **Exam Weight:** This is the **largest domain** on the DP-600 exam, covering nearly half of all questions.  
> Master every section below to maximize your score.

---

## Table of Contents

1. [Data Ingestion](#1-data-ingestion)
2. [Data Transformation](#2-data-transformation)
3. [Dataflows Gen2](#3-dataflows-gen2)
4. [Data Factory Pipelines](#4-data-factory-pipelines)
5. [Notebooks and Spark Jobs](#5-notebooks-and-spark-jobs)
6. [Lakehouse Architecture](#6-lakehouse-architecture)
7. [Warehouse](#7-warehouse)
8. [Data Quality and Connection Management](#8-data-quality-and-connection-management)
9. [Medallion Architecture](#9-medallion-architecture)

---

## 1. Data Ingestion

### Batch vs. Streaming Ingestion

| Feature | Batch | Streaming |
|---|---|---|
| **Latency** | Minutes to hours | Seconds to minutes |
| **Tools** | Copy Activity, Dataflows Gen2, Notebooks | Eventstreams, KQL Querysets |
| **Use Case** | Periodic ETL loads, historical data | Real-time dashboards, IoT telemetry |
| **Data Freshness** | Scheduled intervals | Near real-time |
| **Complexity** | Lower | Higher (ordering, dedup, windowing) |

### Connectors

Microsoft Fabric supports **170+ connectors** for data ingestion:

- **Azure-native:** Azure SQL, Azure Blob, ADLS Gen2, Cosmos DB, Synapse
- **SaaS:** Salesforce, Dynamics 365, SharePoint, Dataverse
- **Databases:** SQL Server, PostgreSQL, MySQL, Oracle
- **Files:** CSV, Parquet, JSON, Excel, XML
- **Cloud platforms:** AWS S3, Google Cloud Storage, Snowflake

### Copy Activity

The Copy Activity moves data between supported stores. It is the primary tool for **batch ingestion** in Data Factory pipelines.

```json
{
  "name": "CopyFromBlobToLakehouse",
  "type": "Copy",
  "inputs": [{ "referenceName": "AzureBlobSource" }],
  "outputs": [{ "referenceName": "LakehouseDestination" }],
  "typeProperties": {
    "source": {
      "type": "DelimitedTextSource",
      "storeSettings": { "type": "AzureBlobStorageReadSettings", "recursive": true }
    },
    "sink": {
      "type": "LakehouseTableSink",
      "tableActionOption": "Append"
    }
  }
}
```

> **💡 Exam Tip:** Know the difference between **Append**, **Overwrite**, and **Merge** table actions for the Copy Activity sink.

### Eventstreams

Eventstreams enable **real-time data ingestion** in Fabric:

- Source from Azure Event Hubs, IoT Hub, or custom apps
- Process with no-code transformations (filter, aggregate, group by)
- Route to Lakehouse, KQL Database, or Reflex destinations
- Supports **tumbling**, **hopping**, and **sliding** time windows

### Shortcuts (OneLake, ADLS Gen2, S3)

Shortcuts provide **zero-copy, virtualized access** to data without physically moving it.

| Shortcut Type | Source | Authentication |
|---|---|---|
| **OneLake** | Other Fabric Lakehouses/Warehouses | Fabric identity |
| **ADLS Gen2** | Azure Data Lake Storage Gen2 | Service principal, SAS, or account key |
| **Amazon S3** | AWS S3 buckets | Access key + secret |
| **Google Cloud Storage** | GCS buckets | Service account key |
| **Dataverse** | Dynamics 365 / Power Platform | Organizational account |

> **💡 Exam Tip:** Shortcuts do **not** copy data — they create a pointer. Data remains in its original location. This reduces storage costs and avoids data duplication.

**Creating a shortcut via PySpark:**

```python
# Shortcuts are created through the Fabric UI or REST API
# Once created, access shortcut data in Spark like any other table:
df = spark.read.format("delta").load("Tables/my_shortcut_table")
df.show(5)
```

📖 [Microsoft Docs — Data Ingestion in Fabric](https://learn.microsoft.com/en-us/fabric/data-factory/connector-overview)

---

## 2. Data Transformation

### Power Query (M Language)

Power Query is the transformation engine behind **Dataflows Gen2** and the Power BI data pipeline. M is a functional, case-sensitive language.

**Common M transformations:**

```m
let
    // Connect to SQL Server
    Source = Sql.Database("server.database.windows.net", "SalesDB"),
    
    // Navigate to table
    Sales = Source{[Schema="dbo", Item="FactSales"]}[Data],
    
    // Filter rows: keep only current year
    FilteredRows = Table.SelectRows(Sales, each Date.Year([OrderDate]) = 2024),
    
    // Add calculated column
    AddMargin = Table.AddColumn(FilteredRows, "ProfitMargin", 
        each [Revenue] - [Cost], type number),
    
    // Group and aggregate
    Grouped = Table.Group(AddMargin, {"ProductCategory"}, {
        {"TotalRevenue", each List.Sum([Revenue]), type number},
        {"AvgMargin", each List.Average([ProfitMargin]), type number},
        {"OrderCount", each Table.RowCount(_), Int64.Type}
    }),
    
    // Sort descending by revenue
    Sorted = Table.Sort(Grouped, {{"TotalRevenue", Order.Descending}}),
    
    // Change column types
    TypedResult = Table.TransformColumnTypes(Sorted, {
        {"TotalRevenue", Currency.Type},
        {"AvgMargin", Currency.Type}
    })
in
    TypedResult
```

**Key M functions for the exam:**

| Function | Purpose |
|---|---|
| `Table.SelectRows` | Filter rows by condition |
| `Table.AddColumn` | Add a calculated column |
| `Table.Group` | Group by and aggregate |
| `Table.TransformColumnTypes` | Set data types |
| `Table.ExpandRecordColumn` | Flatten nested records |
| `Table.Pivot` / `Table.Unpivot` | Reshape data |
| `Table.Join` / `Table.NestedJoin` | Combine tables |
| `Table.RemoveColumns` | Drop unneeded columns |
| `Table.ReplaceValue` | Find and replace values |
| `Table.Buffer` | Load table into memory for performance |

### Spark Notebooks (PySpark)

PySpark is the most common transformation language in Fabric notebooks.

```python
from pyspark.sql.functions import col, year, sum, avg, when, lit

# Read from Lakehouse Delta table
df = spark.read.format("delta").load("Tables/raw_sales")

# Filter, transform, and aggregate
result = (
    df
    .filter(year(col("order_date")) == 2024)
    .withColumn("profit_margin", col("revenue") - col("cost"))
    .withColumn("margin_tier", 
        when(col("profit_margin") > 100, "High")
        .when(col("profit_margin") > 50, "Medium")
        .otherwise("Low")
    )
    .groupBy("product_category", "margin_tier")
    .agg(
        sum("revenue").alias("total_revenue"),
        avg("profit_margin").alias("avg_margin"),
        count("order_id").alias("order_count")
    )
    .orderBy(col("total_revenue").desc())
)

# Write to Lakehouse as Delta table
result.write.format("delta").mode("overwrite").saveAsTable("gold_sales_summary")
```

### Spark SQL

```sql
-- Create a temporary view for SQL access
CREATE OR REPLACE TEMP VIEW raw_sales AS
SELECT * FROM delta.`Tables/raw_sales`;

-- Transform and aggregate using Spark SQL
CREATE OR REPLACE TABLE gold_sales_summary AS
SELECT 
    product_category,
    CASE 
        WHEN revenue - cost > 100 THEN 'High'
        WHEN revenue - cost > 50  THEN 'Medium'
        ELSE 'Low'
    END AS margin_tier,
    SUM(revenue) AS total_revenue,
    AVG(revenue - cost) AS avg_margin,
    COUNT(order_id) AS order_count
FROM raw_sales
WHERE YEAR(order_date) = 2024
GROUP BY product_category, margin_tier
ORDER BY total_revenue DESC;
```

### T-SQL Transformations (Warehouse)

```sql
-- Create a stored procedure for repeatable transformations
CREATE PROCEDURE dbo.TransformSalesData
AS
BEGIN
    -- Merge pattern: upsert from staging to target
    MERGE dbo.DimProduct AS target
    USING dbo.staging_products AS source
    ON target.ProductKey = source.ProductKey
    WHEN MATCHED THEN
        UPDATE SET 
            target.ProductName = source.ProductName,
            target.Category = source.Category,
            target.UpdatedDate = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (ProductKey, ProductName, Category, UpdatedDate)
        VALUES (source.ProductKey, source.ProductName, source.Category, GETDATE());
END;
```

> **💡 Exam Tip:** Know when to use each transformation tool:
> - **Power Query / M** → low-code, Dataflows Gen2, citizen developers
> - **PySpark** → large-scale data, complex logic, data science
> - **Spark SQL** → SQL-familiar analysts working with Lakehouse
> - **T-SQL** → Warehouse transformations, stored procedures

📖 [Microsoft Docs — Transform Data in Fabric](https://learn.microsoft.com/en-us/fabric/data-factory/transform-data)

---

## 3. Dataflows Gen2

### Overview

Dataflows Gen2 are **cloud-based Power Query (M) transformations** that run in the Fabric service. They are the evolution of Power BI Dataflows.

### Creating and Configuring Dataflows Gen2

Key configuration options:

| Setting | Description |
|---|---|
| **Data destination** | Lakehouse, Warehouse, KQL Database, or Azure SQL |
| **Update method** | Replace or Append |
| **Column mapping** | Map source columns to destination columns |
| **Staging** | Enable staging Lakehouse for large data volumes |

### Incremental Refresh

Configure incremental refresh to load only new or changed data:

1. Create a **date/time parameter** (e.g., `RangeStart`, `RangeEnd`)
2. Filter your query using these parameters
3. Configure the incremental refresh policy:
   - **Store rows in the last:** e.g., 3 years
   - **Refresh rows in the last:** e.g., 10 days

```m
// Incremental refresh pattern in M
let
    Source = Sql.Database("server.database.windows.net", "SalesDB"),
    Sales = Source{[Schema="dbo", Item="FactSales"]}[Data],
    // Filter using RangeStart and RangeEnd parameters
    Filtered = Table.SelectRows(Sales, each 
        [ModifiedDate] >= RangeStart and [ModifiedDate] < RangeEnd)
in
    Filtered
```

> **💡 Exam Tip:** The parameters must be named exactly `RangeStart` and `RangeEnd` (case-sensitive) for incremental refresh to work.

### Error Handling

- **Row-level error handling:** Configure how errors are treated per column (replace value, remove row, keep error)
- **Query diagnostics:** Monitor step-by-step performance
- **Refresh history:** View success/failure status and error messages in the Fabric portal

### Data Destinations

Dataflows Gen2 can output to multiple destinations:

- **Fabric Lakehouse** — writes Delta tables
- **Fabric Warehouse** — writes to SQL tables
- **Azure SQL Database** — external SQL destination
- **KQL Database** — for real-time analytics

### Staging

Staging uses a **Lakehouse as an intermediary** to improve performance for large datasets:

- Enable staging in the Dataflow settings
- Data is first written to a staging Lakehouse, then loaded to the destination
- **Recommended** for datasets larger than a few hundred MB

> **💡 Exam Tip:** Staging is required when using certain transformations with large datasets and when the destination is a Warehouse.

📖 [Microsoft Docs — Dataflows Gen2](https://learn.microsoft.com/en-us/fabric/data-factory/create-first-dataflow-gen2)

---

## 4. Data Factory Pipelines

### Pipeline Activities

| Activity Type | Purpose | Example |
|---|---|---|
| **Copy** | Move data between stores | Blob → Lakehouse |
| **Dataflow** | Run a Dataflow Gen2 | Transform and load |
| **Notebook** | Execute a Spark notebook | Complex PySpark logic |
| **Stored Procedure** | Run T-SQL procedures | Warehouse transformations |
| **KQL** | Run KQL queries | Real-time analytics |
| **Script** | Run T-SQL scripts | DDL/DML in Warehouse |
| **Lookup** | Retrieve data for pipeline logic | Get config values |
| **Set Variable** | Assign a value to a variable | Store intermediate results |
| **Web** | Call a REST API | Trigger external services |
| **Delete** | Delete files from storage | Clean up staging data |

### Control Flow Activities

```
ForEach    → Iterate over a collection of items
If         → Conditional branching (if/else)
Switch     → Multi-branch conditional (like case/switch)
Until      → Loop until condition is met
Wait       → Pause execution for a duration
Fail       → Force pipeline failure with custom error
```

**ForEach example — processing multiple tables:**

```json
{
  "name": "ForEachTable",
  "type": "ForEach",
  "typeProperties": {
    "items": {
      "value": "@pipeline().parameters.TableList",
      "type": "Expression"
    },
    "isSequential": false,
    "batchCount": 10,
    "activities": [
      {
        "name": "CopyTable",
        "type": "Copy",
        "typeProperties": {
          "source": { "type": "SqlSource", "sqlReaderQuery": "SELECT * FROM @{item().TableName}" },
          "sink": { "type": "LakehouseTableSink" }
        }
      }
    ]
  }
}
```

### Parameters and Variables

| Concept | Scope | Mutability | Use Case |
|---|---|---|---|
| **Parameters** | Pipeline-level, passed at trigger time | Read-only at runtime | Table names, dates, connection strings |
| **Variables** | Pipeline-level, defined in pipeline | Read/write at runtime | Counters, flags, intermediate results |

**Common expressions:**

```
@pipeline().parameters.SourceTable        // Access parameter
@variables('RecordCount')                  // Access variable
@utcnow()                                 // Current UTC timestamp
@formatDateTime(utcnow(), 'yyyy-MM-dd')   // Formatted date
@concat('dbo.', pipeline().parameters.TableName) // String concatenation
@if(equals(activity('Lookup').output.count, 0), 'Empty', 'HasData') // Conditional
```

### Triggers

| Trigger Type | Description |
|---|---|
| **Schedule** | Run on a cron schedule (e.g., daily at 2 AM) |
| **Tumbling Window** | Fixed-size, non-overlapping time intervals |
| **Event-based** | React to file arrival in storage |

### Monitoring and Error Handling

- **Monitor Hub** — centralized view of all pipeline runs
- **Activity-level retry** — configure retry count and interval
- **Activity dependencies** — Succeeded, Failed, Completed, Skipped
- **On-failure paths** — chain activities on failure for alerts or cleanup

```
Activity A (Copy) ──[On Success]──► Activity B (Transform)
                  ──[On Failure]──► Activity C (Send Alert)
```

> **💡 Exam Tip:** Understand activity dependency conditions:
> - **Succeeded** — runs only if previous activity succeeded
> - **Failed** — runs only if previous activity failed
> - **Completed** — runs regardless of success or failure
> - **Skipped** — runs only if previous activity was skipped

📖 [Microsoft Docs — Data Factory Pipelines](https://learn.microsoft.com/en-us/fabric/data-factory/activity-overview)

---

## 5. Notebooks and Spark Jobs

### PySpark in Notebooks

```python
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Read data from Lakehouse Files section (raw files)
df_raw = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv("Files/raw/customers/*.csv")
)

# Schema enforcement with explicit types
schema = StructType([
    StructField("customer_id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("email", StringType(), True),
    StructField("signup_date", DateType(), True),
    StructField("lifetime_value", DoubleType(), True)
])

df_typed = spark.read.schema(schema).csv("Files/raw/customers/*.csv")

# Write as Delta table
df_typed.write.format("delta").mode("overwrite").saveAsTable("bronze_customers")
```

### Delta Lake Read/Write Operations

```python
# --- READ operations ---
# Read a Delta table by name
df = spark.read.table("bronze_customers")

# Read by path
df = spark.read.format("delta").load("Tables/bronze_customers")

# Time travel: read a previous version
df_v2 = spark.read.format("delta").option("versionAsOf", 2).load("Tables/bronze_customers")

# Time travel: read as of a timestamp
df_ts = (spark.read.format("delta")
    .option("timestampAsOf", "2024-01-15T10:00:00Z")
    .load("Tables/bronze_customers"))

# --- WRITE operations ---
# Overwrite entire table
df.write.format("delta").mode("overwrite").saveAsTable("silver_customers")

# Append new rows
df_new.write.format("delta").mode("append").saveAsTable("silver_customers")

# Merge (upsert) using Delta Lake API
from delta.tables import DeltaTable

target = DeltaTable.forName(spark, "silver_customers")
target.alias("t").merge(
    df_updates.alias("s"),
    "t.customer_id = s.customer_id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()
```

### Spark SQL in Notebooks

```sql
%%sql
-- Create a managed Delta table
CREATE TABLE IF NOT EXISTS silver_customers (
    customer_id INT,
    name STRING,
    email STRING,
    signup_date DATE,
    lifetime_value DOUBLE,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA;

-- Insert with deduplication
MERGE INTO silver_customers AS t
USING bronze_customers AS s
ON t.customer_id = s.customer_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- Query table history
DESCRIBE HISTORY silver_customers;
```

### Spark Job Definitions

Spark Job Definitions allow you to run **production Spark scripts** on a schedule:

- Upload `.py` or `.jar` files as the main definition
- Reference library dependencies
- Configure Spark properties (executor memory, cores)
- Schedule via pipelines or manual execution

### Library Management

```python
# Install inline (session-scoped, notebook only)
%pip install great-expectations

# Or use the Fabric Environment:
# 1. Create an Environment item in the workspace
# 2. Add public libraries (PyPI) or upload custom .whl files
# 3. Attach the Environment to your notebook or Spark Job Definition
```

> **💡 Exam Tip:** Libraries installed with `%pip install` are **session-scoped** and lost when the session ends. For persistent libraries, use **Fabric Environments**.

📖 [Microsoft Docs — Notebooks in Fabric](https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook)

---

## 6. Lakehouse Architecture

### OneLake

OneLake is Fabric's **unified data lake** — a single, tenant-wide storage layer built on ADLS Gen2.

Key concepts:
- **One copy of data** shared across all Fabric workloads
- **Automatic Delta/Parquet format** for all managed tables
- **Hierarchical namespace:** `onelake.dfs.fabric.microsoft.com/{workspace}/{lakehouse}/`
- **Built-in governance** via Fabric workspace roles and item permissions

### Delta Lake

Delta Lake is the **default table format** in Fabric Lakehouse:

| Feature | Benefit |
|---|---|
| **ACID transactions** | Reliable reads/writes, no corrupted data |
| **Schema enforcement** | Prevents bad data from being written |
| **Schema evolution** | Add columns without rewriting data |
| **Time travel** | Query previous versions of data |
| **Audit history** | Full transaction log for compliance |
| **Unified batch + streaming** | Same table for both workloads |

### Managed vs. External Tables

| Aspect | Managed Table | External Table |
|---|---|---|
| **Location** | `Tables/` folder (auto-managed) | `Files/` folder or external path |
| **Metadata** | Managed by Fabric | User-managed |
| **DROP behavior** | Deletes data + metadata | Deletes metadata only |
| **Discovery** | Auto-registered in SQL endpoint | Must be explicitly registered |
| **Use case** | Standard analytics tables | Raw files, shared data |

```python
# Create a managed table
df.write.format("delta").mode("overwrite").saveAsTable("managed_table")

# Create an external table
df.write.format("delta").mode("overwrite").save("Files/external/my_table")

# Register the external table in the metastore
spark.sql("""
    CREATE TABLE external_table
    USING DELTA
    LOCATION 'Files/external/my_table'
""")
```

### Shortcuts

Shortcuts enable **cross-Lakehouse, cross-workspace, and cross-cloud** data access:

```
OneLake Shortcut:      Lakehouse A → Lakehouse B (same or different workspace)
ADLS Gen2 Shortcut:    Lakehouse → Azure Data Lake Gen2 container
S3 Shortcut:           Lakehouse → Amazon S3 bucket
GCS Shortcut:          Lakehouse → Google Cloud Storage bucket
Dataverse Shortcut:    Lakehouse → Dataverse tables
```

### Table Maintenance

Regular maintenance ensures optimal query performance:

```sql
-- OPTIMIZE: Compacts small files into larger ones (target ~1 GB)
OPTIMIZE silver_customers;

-- OPTIMIZE with Z-ORDER: Co-locate data by frequently filtered columns
OPTIMIZE silver_customers ZORDER BY (signup_date, customer_id);

-- VACUUM: Remove old files no longer referenced by the Delta log
-- Default retention: 7 days. Files older than retention are deleted.
VACUUM silver_customers RETAIN 168 HOURS;

-- ANALYZE: Collect statistics for the query optimizer
ANALYZE TABLE silver_customers COMPUTE STATISTICS FOR ALL COLUMNS;
```

**Maintenance recommendations:**

| Operation | Frequency | Purpose |
|---|---|---|
| `OPTIMIZE` | Daily or after large writes | Compact small files |
| `VACUUM` | Weekly | Reclaim storage |
| `Z-ORDER` | With OPTIMIZE, on filter columns | Speed up filtered queries |
| `ANALYZE` | After significant data changes | Update query optimizer stats |

### V-Order

V-Order is a **write-time optimization** unique to Fabric that applies special sorting and compression:

- Enables **ultra-fast reads** across all Fabric engines (Spark, SQL, Power BI)
- Applied automatically to managed tables in Lakehouse
- Compatible with open Delta/Parquet format (no vendor lock-in)
- Improves compression ratios by 10–50%

```python
# V-Order is enabled by default in Fabric Lakehouse
# To explicitly enable/disable:
spark.conf.set("spark.sql.parquet.vorder.enabled", "true")

# Write with V-Order
df.write.format("delta").mode("overwrite").saveAsTable("optimized_table")
```

### SQL Analytics Endpoint

Every Lakehouse automatically gets a **read-only SQL analytics endpoint**:

- **Auto-generated T-SQL views** for all Delta tables
- Query with any SQL tool (SSMS, Azure Data Studio, Power BI)
- Supports **cross-database queries** to other Lakehouses and Warehouses
- Does **not** support DML (INSERT, UPDATE, DELETE) — read-only

```sql
-- Query Lakehouse tables via SQL analytics endpoint
SELECT 
    product_category,
    SUM(revenue) AS total_revenue
FROM dbo.silver_sales
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Cross-database query
SELECT l.customer_name, w.total_orders
FROM MyLakehouse.dbo.customers l
JOIN MyWarehouse.dbo.order_summary w
    ON l.customer_id = w.customer_id;
```

> **💡 Exam Tip:** The SQL analytics endpoint is **read-only**. To write data, use Spark notebooks or Dataflows Gen2.

📖 [Microsoft Docs — Lakehouse in Fabric](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview)

---

## 7. Warehouse

### T-SQL in Fabric Warehouse

Fabric Warehouse supports a **subset of T-SQL** based on the Synapse Analytics engine.

**Supported:**
- SELECT, INSERT, UPDATE, DELETE, MERGE
- CREATE TABLE, ALTER TABLE, DROP TABLE
- Views, stored procedures, functions
- CTEs, window functions, subqueries
- Cross-database queries

**Not supported:**
- Triggers
- Materialized views (use regular views or aggregation tables)
- Certain system stored procedures

### Distribution Strategies

| Strategy | Description | Best For |
|---|---|---|
| **Round-Robin** | Distributes rows evenly across distributions | Staging tables, no join key |
| **Hash** | Distributes rows by hash of a column | Large fact tables, frequent joins on that column |
| **Replicated** | Full copy on every compute node | Small dimension tables (< 2 GB) |

```sql
-- Round-Robin distribution (default)
CREATE TABLE dbo.staging_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount DECIMAL(18, 2)
);

-- Hash distribution on a join key
CREATE TABLE dbo.fact_sales (
    sale_id BIGINT,
    customer_id INT,
    product_id INT,
    sale_date DATE,
    quantity INT,
    revenue DECIMAL(18, 2)
)
WITH (DISTRIBUTION = HASH(customer_id));

-- Replicated table for small dimensions
CREATE TABLE dbo.dim_product (
    product_id INT,
    product_name NVARCHAR(200),
    category NVARCHAR(100),
    subcategory NVARCHAR(100)
)
WITH (DISTRIBUTION = REPLICATE);
```

> **💡 Exam Tip:** Choose **Hash** distribution on the column most frequently used in **JOIN** and **GROUP BY** clauses. Choose **Replicated** for dimension tables under 2 GB. Default to **Round-Robin** for staging/temp tables.

### Partitioning

Fabric Warehouse does not currently support user-defined partitioning in the same way as Synapse Dedicated SQL Pool. However, **Delta Lake partitioning** can be used in Lakehouse scenarios:

```python
# Partition by date column when writing Delta tables
df.write.format("delta") \
    .partitionBy("sale_year", "sale_month") \
    .mode("overwrite") \
    .saveAsTable("fact_sales_partitioned")
```

### Performance Tuning

| Technique | Description |
|---|---|
| **Statistics** | Auto-created; ensure they are up to date |
| **Result set caching** | Caches query results for repeated queries |
| **Workload management** | Fabric capacity manages concurrency automatically |
| **Distribution choice** | Minimize data movement with correct hash column |
| **Avoid SELECT *** | Only query needed columns |
| **Use CTEs and temp tables** | Break complex queries into stages |

```sql
-- Performance-optimized query pattern
WITH recent_sales AS (
    SELECT 
        customer_id,
        product_id,
        revenue,
        sale_date
    FROM dbo.fact_sales
    WHERE sale_date >= DATEADD(MONTH, -3, GETDATE())
),
customer_totals AS (
    SELECT 
        customer_id,
        SUM(revenue) AS total_revenue,
        COUNT(*) AS order_count,
        AVG(revenue) AS avg_order_value
    FROM recent_sales
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    d.customer_name,
    c.total_revenue,
    c.order_count,
    c.avg_order_value,
    RANK() OVER (ORDER BY c.total_revenue DESC) AS revenue_rank
FROM customer_totals c
JOIN dbo.dim_customer d ON c.customer_id = d.customer_id
ORDER BY c.total_revenue DESC;
```

### Cross-Database Queries

```sql
-- Query across Lakehouse and Warehouse in the same workspace
SELECT 
    w.customer_id,
    w.customer_name,
    l.total_purchases,
    l.last_purchase_date
FROM MyWarehouse.dbo.dim_customer w
JOIN MyLakehouse.dbo.customer_activity l
    ON w.customer_id = l.customer_id
WHERE l.last_purchase_date >= '2024-01-01';
```

### Stored Procedures and Views

```sql
-- Create a reusable view
CREATE VIEW dbo.vw_ActiveCustomers AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    MAX(s.sale_date) AS last_purchase,
    SUM(s.revenue) AS lifetime_value
FROM dbo.dim_customer c
JOIN dbo.fact_sales s ON c.customer_id = s.customer_id
WHERE s.sale_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.customer_id, c.customer_name, c.email;

-- Create a parameterized stored procedure
CREATE PROCEDURE dbo.usp_LoadFactSales
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    -- Truncate and reload for the date range
    DELETE FROM dbo.fact_sales 
    WHERE sale_date BETWEEN @StartDate AND @EndDate;

    INSERT INTO dbo.fact_sales (sale_id, customer_id, product_id, sale_date, quantity, revenue)
    SELECT 
        sale_id, customer_id, product_id, sale_date, quantity, revenue
    FROM dbo.staging_sales
    WHERE sale_date BETWEEN @StartDate AND @EndDate;
END;
```

📖 [Microsoft Docs — Warehouse in Fabric](https://learn.microsoft.com/en-us/fabric/data-warehouse/data-warehousing)

---

## 8. Data Quality and Connection Management

### Data Quality Monitoring

Implement quality checks across your data pipeline:

```python
from pyspark.sql.functions import col, count, when, isnan, isnull

# Profile a DataFrame for quality issues
def profile_data_quality(df, table_name):
    """Generate data quality metrics for a DataFrame."""
    total_rows = df.count()
    
    # Null counts per column
    null_counts = df.select([
        count(when(isnull(c) | isnan(c), c)).alias(c) 
        for c in df.columns
    ])
    
    # Duplicate check
    duplicate_count = total_rows - df.dropDuplicates().count()
    
    print(f"Table: {table_name}")
    print(f"Total rows: {total_rows}")
    print(f"Duplicate rows: {duplicate_count}")
    print("Null counts per column:")
    null_counts.show()
    
    return {
        "table": table_name,
        "total_rows": total_rows,
        "duplicates": duplicate_count
    }

# Run quality checks
quality_report = profile_data_quality(df, "silver_customers")
```

**Quality validation with assertions:**

```python
# Validate data quality before writing to Gold layer
assert df.filter(col("customer_id").isNull()).count() == 0, \
    "FAIL: Null customer_id found"

assert df.count() == df.dropDuplicates(["customer_id"]).count(), \
    "FAIL: Duplicate customer_id found"

assert df.filter(col("revenue") < 0).count() == 0, \
    "FAIL: Negative revenue values found"

print("All quality checks passed!")
```

**T-SQL quality checks in Warehouse:**

```sql
-- Data quality validation procedure
CREATE PROCEDURE dbo.usp_ValidateFactSales
AS
BEGIN
    DECLARE @NullCount INT, @DuplicateCount INT, @NegativeCount INT;

    -- Check for null keys
    SELECT @NullCount = COUNT(*) 
    FROM dbo.fact_sales 
    WHERE customer_id IS NULL OR product_id IS NULL;

    -- Check for duplicates
    SELECT @DuplicateCount = COUNT(*) - COUNT(DISTINCT sale_id) 
    FROM dbo.fact_sales;

    -- Check for negative revenue
    SELECT @NegativeCount = COUNT(*) 
    FROM dbo.fact_sales 
    WHERE revenue < 0;

    -- Report results
    IF @NullCount > 0 OR @DuplicateCount > 0 OR @NegativeCount > 0
    BEGIN
        RAISERROR('Data quality validation failed. Nulls: %d, Duplicates: %d, Negatives: %d', 
            16, 1, @NullCount, @DuplicateCount, @NegativeCount);
    END
    ELSE
        PRINT 'All data quality checks passed.';
END;
```

### Connection Types

| Connection Type | Use Case | Authentication |
|---|---|---|
| **Cloud connection** | Azure services, SaaS apps | OAuth, service principal, managed identity |
| **On-premises data gateway** | SQL Server, file shares, Oracle on-prem | Windows auth, basic auth |
| **VNet data gateway** | Azure resources in a VNet | Managed identity |

### Gateway Configuration

- **On-premises data gateway:** Install on a local Windows machine to bridge Fabric and on-premises data sources
- **VNet data gateway:** Managed gateway for securely connecting to Azure VNet resources
- **Gateway cluster:** Multiple gateways for high availability and load balancing

> **💡 Exam Tip:** On-premises data gateways are needed for **scheduled refresh** of data from on-premises sources. DirectQuery to on-premises sources also requires a gateway.

📖 [Microsoft Docs — Data Gateways](https://learn.microsoft.com/en-us/fabric/data-factory/data-factory-overview)

---

## 9. Medallion Architecture

### Overview

The Medallion Architecture organizes data into three quality layers:

```
┌──────────┐      ┌──────────┐      ┌──────────┐
│  Bronze   │ ───► │  Silver   │ ───► │   Gold    │
│  (Raw)    │      │ (Cleansed)│      │(Aggregated│
│           │      │           │      │ / Curated) │
└──────────┘      └──────────┘      └──────────┘
```

| Layer | Purpose | Data Quality | Consumers |
|---|---|---|---|
| **Bronze** | Raw ingestion, minimal transformation | As-is from source | Data engineers |
| **Silver** | Cleansed, deduplicated, conformed | Validated, typed | Data analysts, data scientists |
| **Gold** | Business-level aggregations, KPIs | Trusted, governed | Business users, Power BI reports |

### Implementation Patterns

#### Bronze Layer — Raw Ingestion

```python
# Bronze: Ingest raw data with metadata columns
from pyspark.sql.functions import current_timestamp, input_file_name, lit

df_raw = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv("Files/raw/sales/*.csv")
)

df_bronze = (
    df_raw
    .withColumn("_ingestion_timestamp", current_timestamp())
    .withColumn("_source_file", input_file_name())
    .withColumn("_batch_id", lit("batch_2024_01_15"))
)

df_bronze.write.format("delta").mode("append").saveAsTable("bronze_sales")
```

#### Silver Layer — Cleansed and Conformed

```python
# Silver: Clean, deduplicate, enforce schema, apply business rules
from delta.tables import DeltaTable
from pyspark.sql.functions import col, trim, lower, to_date, when

df_bronze = spark.read.table("bronze_sales")

df_silver = (
    df_bronze
    # Data cleansing
    .withColumn("customer_name", trim(col("customer_name")))
    .withColumn("email", lower(trim(col("email"))))
    .withColumn("order_date", to_date(col("order_date"), "yyyy-MM-dd"))
    # Remove nulls in key columns
    .filter(col("order_id").isNotNull() & col("customer_id").isNotNull())
    # Data type enforcement
    .withColumn("revenue", col("revenue").cast("decimal(18,2)"))
    .withColumn("quantity", col("quantity").cast("int"))
    # Business rule: flag suspicious orders
    .withColumn("is_suspicious", 
        when(col("revenue") > 10000, True).otherwise(False))
    # Deduplicate
    .dropDuplicates(["order_id"])
)

# Upsert into Silver table
if spark.catalog.tableExists("silver_sales"):
    target = DeltaTable.forName(spark, "silver_sales")
    target.alias("t").merge(
        df_silver.alias("s"), "t.order_id = s.order_id"
    ).whenMatchedUpdateAll() \
     .whenNotMatchedInsertAll() \
     .execute()
else:
    df_silver.write.format("delta").mode("overwrite").saveAsTable("silver_sales")
```

#### Gold Layer — Business Aggregations

```python
# Gold: Business-ready aggregations and KPIs
from pyspark.sql.functions import sum, avg, countDistinct, max, min
from pyspark.sql.window import Window

df_silver = spark.read.table("silver_sales")

# Customer summary
df_gold_customers = (
    df_silver
    .groupBy("customer_id", "customer_name")
    .agg(
        sum("revenue").alias("lifetime_revenue"),
        countDistinct("order_id").alias("total_orders"),
        avg("revenue").alias("avg_order_value"),
        max("order_date").alias("last_order_date"),
        min("order_date").alias("first_order_date")
    )
    .withColumn("customer_segment",
        when(col("lifetime_revenue") > 10000, "Platinum")
        .when(col("lifetime_revenue") > 5000, "Gold")
        .when(col("lifetime_revenue") > 1000, "Silver")
        .otherwise("Bronze")
    )
)

df_gold_customers.write.format("delta").mode("overwrite").saveAsTable("gold_customer_summary")

# Daily sales KPIs
df_gold_daily = (
    df_silver
    .groupBy("order_date")
    .agg(
        sum("revenue").alias("daily_revenue"),
        countDistinct("order_id").alias("daily_orders"),
        countDistinct("customer_id").alias("unique_customers")
    )
    .orderBy("order_date")
)

df_gold_daily.write.format("delta").mode("overwrite").saveAsTable("gold_daily_sales_kpi")
```

### Medallion Architecture with T-SQL (Warehouse)

```sql
-- Bronze → Silver transformation in Warehouse
CREATE PROCEDURE dbo.usp_BronzeToSilver_Sales
AS
BEGIN
    MERGE INTO dbo.silver_sales AS t
    USING (
        SELECT DISTINCT
            order_id,
            customer_id,
            TRIM(customer_name) AS customer_name,
            LOWER(TRIM(email)) AS email,
            CAST(order_date AS DATE) AS order_date,
            CAST(revenue AS DECIMAL(18,2)) AS revenue,
            CAST(quantity AS INT) AS quantity,
            GETDATE() AS _processed_at
        FROM dbo.bronze_sales
        WHERE order_id IS NOT NULL 
          AND customer_id IS NOT NULL
    ) AS s
    ON t.order_id = s.order_id
    WHEN MATCHED THEN
        UPDATE SET 
            t.customer_name = s.customer_name,
            t.email = s.email,
            t.revenue = s.revenue,
            t._processed_at = s._processed_at
    WHEN NOT MATCHED THEN
        INSERT (order_id, customer_id, customer_name, email, order_date, revenue, quantity, _processed_at)
        VALUES (s.order_id, s.customer_id, s.customer_name, s.email, s.order_date, s.revenue, s.quantity, s._processed_at);
END;

-- Silver → Gold aggregation
CREATE PROCEDURE dbo.usp_SilverToGold_CustomerSummary
AS
BEGIN
    -- Recreate gold table
    IF OBJECT_ID('dbo.gold_customer_summary', 'U') IS NOT NULL
        DROP TABLE dbo.gold_customer_summary;

    CREATE TABLE dbo.gold_customer_summary
    WITH (DISTRIBUTION = HASH(customer_id))
    AS
    SELECT 
        customer_id,
        customer_name,
        SUM(revenue) AS lifetime_revenue,
        COUNT(DISTINCT order_id) AS total_orders,
        AVG(revenue) AS avg_order_value,
        MAX(order_date) AS last_order_date,
        MIN(order_date) AS first_order_date,
        CASE 
            WHEN SUM(revenue) > 10000 THEN 'Platinum'
            WHEN SUM(revenue) > 5000 THEN 'Gold'
            WHEN SUM(revenue) > 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_segment,
        GETDATE() AS _generated_at
    FROM dbo.silver_sales
    GROUP BY customer_id, customer_name;
END;
```

### Best Practices

| Practice | Recommendation |
|---|---|
| **Bronze** | Append-only, preserve raw data, add metadata columns (`_ingestion_timestamp`, `_source_file`) |
| **Silver** | Deduplicate, cleanse, conform data types, use MERGE for upserts |
| **Gold** | Pre-aggregate for reporting, use star schema design, optimize for Power BI |
| **Naming** | Prefix tables: `bronze_`, `silver_`, `gold_` or use separate Lakehouses |
| **Separate Lakehouses** | Consider one Lakehouse per layer for clear governance and permissions |
| **Idempotency** | Design pipelines to produce the same result when re-run |
| **Schema evolution** | Use Delta Lake `mergeSchema` option when schema changes are expected |
| **Maintenance** | Schedule OPTIMIZE and VACUUM on Silver/Gold tables |

> **💡 Exam Tip:** The exam frequently tests the Medallion Architecture. Know the purpose of each layer and be able to identify which transformations belong in Bronze, Silver, or Gold.

📖 [Microsoft Docs — Medallion Architecture](https://learn.microsoft.com/en-us/fabric/onelake/onelake-medallion-lakehouse-architecture)

---

## Quick Reference: Choosing the Right Tool

| Scenario | Recommended Tool |
|---|---|
| Batch ETL from cloud sources | **Copy Activity** in Pipeline |
| Low-code transformation | **Dataflows Gen2** (Power Query) |
| Complex data processing at scale | **Spark Notebook** (PySpark) |
| SQL-based warehouse transformations | **T-SQL** in Warehouse |
| Real-time data ingestion | **Eventstreams** |
| Cross-cloud data access (no copy) | **Shortcuts** |
| Orchestration of multiple activities | **Data Factory Pipeline** |
| Small dimension table refresh | **Dataflows Gen2** |
| ML feature engineering | **Spark Notebook** |
| Scheduled production Spark jobs | **Spark Job Definitions** |

---

## Key Exam Topics Checklist

- [ ] Describe batch vs. streaming ingestion patterns
- [ ] Configure Copy Activity with different source/sink types
- [ ] Create and optimize Dataflows Gen2 with incremental refresh
- [ ] Build pipelines with control flow (ForEach, If, Switch)
- [ ] Use parameters, variables, and expressions in pipelines
- [ ] Write PySpark transformations and Delta Lake operations
- [ ] Implement MERGE/upsert patterns (PySpark and T-SQL)
- [ ] Choose correct distribution strategy for Warehouse tables
- [ ] Configure and use shortcuts for virtualized data access
- [ ] Perform table maintenance (OPTIMIZE, VACUUM, Z-ORDER)
- [ ] Explain V-Order and its benefits
- [ ] Implement Medallion Architecture (Bronze → Silver → Gold)
- [ ] Configure gateways for on-premises data access
- [ ] Monitor pipeline runs and handle errors
- [ ] Implement data quality validation checks

---

> **📚 Additional Resources:**
> - [DP-600 Exam Study Guide (Microsoft)](https://learn.microsoft.com/en-us/credentials/certifications/fabric-analytics-engineer-associate/)
> - [Microsoft Fabric Documentation](https://learn.microsoft.com/en-us/fabric/)
> - [Delta Lake Documentation](https://docs.delta.io/latest/index.html)
> - [Microsoft Learn — Fabric Learning Paths](https://learn.microsoft.com/en-us/training/paths/get-started-fabric/)
