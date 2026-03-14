# Practice Database for DP-600 Exam Preparation

This directory contains a hands-on SQL practice environment designed for the **DP-600: Implementing Analytics Solutions Using Microsoft Fabric** certification exam. It provides a realistic retail/sales analytics dimensional model, sample data, and graded query exercises.

## Overview

The practice database models a fictional retail company — **Contoso Retail Analytics** — with a star-schema dimensional model. It covers the types of data warehousing patterns you will encounter on the DP-600 exam, including:

- Dimensional modeling (star schema with fact and dimension tables)
- T-SQL querying in Microsoft Fabric Warehouse
- Aggregation, window functions, and analytical queries
- Fabric-specific SQL features (COPY INTO, CTAS, cross-database queries)

## Table of Contents

| Folder | Description |
|---|---|
| [`schemas/`](schemas/) | Table definitions (DDL) for the dimensional model |
| [`seed-data/`](seed-data/) | INSERT statements to populate the tables with sample data |
| [`query-exercises/`](query-exercises/) | Beginner, intermediate, and advanced T-SQL exercises with solutions |

## How to Use

### Option 1: Microsoft Fabric Warehouse (Recommended)

1. Open your **Microsoft Fabric workspace** and create a new **Warehouse**.
2. Open the SQL query editor.
3. Run [`schemas/schema.sql`](schemas/schema.sql) to create all tables.
4. Run [`seed-data/seed-data.sql`](seed-data/seed-data.sql) to populate the tables with sample data.
5. Work through the exercises in [`query-exercises/`](query-exercises/).

### Option 2: SQL Server / Azure SQL Database

The schema and seed data use standard T-SQL syntax and are compatible with:

- SQL Server 2019+
- Azure SQL Database
- Azure Synapse Analytics (dedicated SQL pool)

Simply run the schema and seed-data scripts in your preferred SQL client (SSMS, Azure Data Studio, etc.).

### Option 3: sqlcmd or CLI

```bash
# Connect to your Fabric Warehouse or SQL Server instance
sqlcmd -S <server> -d <database> -U <user> -P <password> -i schemas/schema.sql
sqlcmd -S <server> -d <database> -U <user> -P <password> -i seed-data/seed-data.sql
```

## Schema Diagram

```
                    ┌──────────────┐
                    │  DimCustomer │
                    └──────┬───────┘
                           │
┌────────────┐    ┌────────┴────────┐    ┌────────────┐
│  DimStore  ├────┤    FactSales    ├────┤ DimProduct  │
└────────────┘    └────────┬────────┘    └────────────┘
                           │
                    ┌──────┴───────┐
                    │   DimDate    │
                    └──────┬───────┘
                           │
┌──────────────┐   ┌───────┴────────┐
│ DimPromotion ├───┤ FactInventory  │
└──────────────┘   └────────────────┘
```

## Tips for Exam Preparation

- Pay attention to **Fabric-supported data types** — Fabric Warehouse supports a subset of T-SQL types.
- Practice writing queries with **window functions** (ROW_NUMBER, RANK, LAG, LEAD) — these are heavily tested.
- Understand the **medallion architecture** (Bronze → Silver → Gold) for data transformation patterns.
- Know how to use **COPY INTO** for data ingestion and **CREATE TABLE AS SELECT (CTAS)** for data transformation.

## Prerequisites

- Basic familiarity with T-SQL / SQL
- Access to a Microsoft Fabric Workspace (free trial available) or SQL Server instance
- A SQL client (Fabric web editor, SSMS, or Azure Data Studio)
