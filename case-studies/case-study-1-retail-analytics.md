# Case Study 1: Retail Analytics Platform

## Scenario

NorthStar Retail is a mid-size retail company operating **200 stores** across four U.S. regions (Northeast, Southeast, Midwest, and West). The company sells approximately **5,000 SKUs** spanning electronics, apparel, home goods, and grocery. NorthStar currently runs an on-premises SQL Server 2019 data warehouse hosted in a co-located data center. The warehouse ingests nightly batch loads from point-of-sale (POS) systems, an inventory management application, a customer loyalty program database, and web-analytics CSV exports.

The existing platform suffers from several pain points. Nightly ETL jobs frequently exceed their six-hour maintenance window, causing stale morning reports. Regional managers rely on emailed Excel extracts rather than self-service dashboards. The data-engineering team of three spends most of its time troubleshooting SSIS packages instead of building new analytics. Storage costs are rising because the team keeps full historical snapshots rather than incremental loads.

NorthStar's CTO has approved a migration to **Microsoft Fabric**. The project goals are:

1. **Near-real-time inventory tracking** — inventory positions must refresh within 15 minutes of a POS transaction.
2. **Daily sales reporting** — executive dashboards updated by 6:00 AM local time each day.
3. **Seasonal demand forecasting** — monthly ML-driven forecasts consumed by the merchandising team in Power BI.
4. **Self-service analytics** — regional managers must be able to explore data relevant only to their region via Power BI without seeing other regions' data.
5. **Cost optimization** — the Fabric capacity should remain within an F64 SKU budget except during seasonal peaks (Black Friday, back-to-school) when it may burst to F128.

The analytics engineering team consists of two data engineers, one analytics engineer, one Power BI developer, and a part-time data steward. They plan a phased rollout: Phase 1 covers sales and inventory; Phase 2 adds loyalty and web analytics; Phase 3 introduces the forecasting model.

Daily data volumes are approximately **2.5 million POS transactions**, **400,000 inventory movement records**, **120,000 loyalty events**, and **50 GB of web-analytics CSV files**. Historical data going back five years must be migrated (roughly 3 TB compressed in Parquet).

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                                  │
│                                                                      │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│
│  │ POS Systems  │ │  Inventory   │ │  Customer    │ │ Web Analytics││
│  │ (SQL Server) │ │  (REST API)  │ │  Loyalty     │ │ (Azure Blob) ││
│  │              │ │              │ │  (Azure SQL) │ │  CSV files   ││
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘│
└─────────┼────────────────┼────────────────┼────────────────┼─────────┘
          │                │                │                │
          ▼                ▼                ▼                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     MICROSOFT FABRIC                                 │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    INGESTION LAYER                             │  │
│  │  Data Pipeline (POS, Loyalty)  │  Dataflow Gen2 (Inventory)   │  │
│  │  Shortcut (Azure Blob CSVs)                                   │  │
│  └────────────────────────┬───────────────────────────────────────┘  │
│                           ▼                                          │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                   MEDALLION LAKEHOUSE                         │  │
│  │                                                               │  │
│  │  ┌──────────┐    ┌──────────┐    ┌──────────┐                │  │
│  │  │  BRONZE  │───▶│  SILVER  │───▶│   GOLD   │                │  │
│  │  │ (raw)    │    │ (cleaned)│    │ (curated)│                │  │
│  │  │ Delta    │    │ Delta    │    │ Delta    │                │  │
│  │  └──────────┘    └──────────┘    └──────────┘                │  │
│  └────────────────────────┬───────────────────────────────────────┘  │
│                           ▼                                          │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │               SEMANTIC LAYER & CONSUMPTION                    │  │
│  │                                                               │  │
│  │  ┌───────────────┐   ┌──────────────┐   ┌─────────────────┐  │  │
│  │  │ Semantic Model │   │  Power BI     │   │  ML Forecasting │  │  │
│  │  │ (Direct Lake)  │   │  Reports      │   │  (Notebook)     │  │  │
│  │  │ + RLS roles    │   │  + Dashboards │   │                 │  │  │
│  │  └───────────────┘   └──────────────┘   └─────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Requirements

- **Medallion architecture** with Bronze (raw ingestion), Silver (cleansed and conformed), and Gold (business-level aggregates) layers in a Fabric Lakehouse using Delta tables.
- **Near-real-time inventory** via Eventstream or a micro-batch pipeline running on a 15-minute schedule.
- **Incremental data loading** for POS and loyalty data to replace full nightly snapshots.
- **Direct Lake semantic model** connected to Gold-layer Delta tables for optimal query performance.
- **Row-Level Security (RLS)** in the semantic model so each regional manager sees only their region.
- **Deployment pipelines** (Dev → Test → Prod) for all Fabric artifacts.
- **Data quality checks** at the Silver layer using Notebook-based validation or Dataflow Gen2 transformations.
- **Capacity auto-scaling** during peak retail periods with monitoring via Fabric Capacity Metrics app.

---

## Data Sources

| Source | System | Protocol | Volume (Daily) | Refresh Cadence |
|---|---|---|---|---|
| Point-of-Sale | SQL Server 2019 (on-prem) | On-premises data gateway | ~2.5 M rows | 15-min micro-batch |
| Inventory | Inventory Management App | REST API (JSON) | ~400 K records | 15-min micro-batch |
| Customer Loyalty | Azure SQL Database | Direct connection | ~120 K events | Hourly |
| Web Analytics | Azure Blob Storage | Shortcut / ADLS Gen2 | ~50 GB CSV | Daily batch |

---

## Constraints and Considerations

- **Budget:** F64 capacity steady-state; burst to F128 during Nov–Dec and Jul–Aug.
- **SLA:** Executive dashboards available by 06:00 local time with 99.5 % uptime.
- **Data Retention:** Five years of transactional history; aggregates retained indefinitely.
- **Security:** Azure AD authentication; regional managers must not see cross-region data.
- **Compliance:** PCI-DSS for payment-card data — card numbers must be masked or tokenized before landing in Bronze.
- **Team:** 2 data engineers, 1 analytics engineer, 1 Power BI developer, 1 part-time data steward.
- **Legacy Decommission:** On-prem SQL Server warehouse must run in parallel for 90 days post-go-live.

---

## Questions

### Question 1

NorthStar's data engineers need to ingest POS transaction data from the on-premises SQL Server into the Bronze layer of the Fabric Lakehouse every 15 minutes. The on-premises network has no direct private endpoint to Microsoft Fabric. Which approach should they use?

- A) Create a Dataflow Gen2 that connects directly to SQL Server over the public internet using SQL authentication.
- B) Install an on-premises data gateway and configure a Fabric Data Pipeline with a Copy activity using a 15-minute tumbling-window trigger.
- C) Export POS data to CSV files, upload them to Azure Blob Storage manually, and create a shortcut in the Lakehouse.
- D) Use Fabric Eventstream with a direct JDBC connection to SQL Server.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Install an on-premises data gateway and configure a Fabric Data Pipeline with a Copy activity using a 15-minute tumbling-window trigger.**

**Explanation:** An on-premises data gateway is required to bridge the on-prem SQL Server to Microsoft Fabric when no private endpoint exists. A Data Pipeline with a Copy activity supports scheduled triggers (including tumbling-window) for micro-batch ingestion. Option A is insecure and would require the SQL Server to be exposed to the internet. Option C is a manual process that cannot meet 15-minute freshness. Option D is not a supported pattern — Eventstream is designed for streaming sources like Azure Event Hubs or Kafka, not direct JDBC connections to relational databases.

</details>

---

### Question 2

The analytics engineer is designing the Silver layer transformation for POS data. The Bronze table contains raw JSON payloads with nested arrays for line items. Some records arrive with null `store_id` values due to POS system glitches. Which combination of actions is MOST appropriate for the Silver layer?

- A) Leave the data as-is in nested JSON format and handle flattening in the semantic model using DAX.
- B) Use a Fabric Notebook with PySpark to flatten the nested arrays into a relational schema and drop all rows where `store_id` is null.
- C) Use a Fabric Notebook with PySpark to flatten the nested arrays, quarantine rows with null `store_id` to a data-quality error table, and write valid rows to the Silver Delta table.
- D) Use Dataflow Gen2 to flatten the JSON and replace null `store_id` values with a default value of "UNKNOWN".

<details>
<summary>Show Answer</summary>

**Correct Answer: C) Use a Fabric Notebook with PySpark to flatten the nested arrays, quarantine rows with null `store_id` to a data-quality error table, and write valid rows to the Silver Delta table.**

**Explanation:** The Silver layer's purpose is to cleanse and conform data. Flattening nested structures is essential for downstream usability. Silently dropping bad records (Option B) loses data and makes it impossible to investigate issues. Replacing nulls with "UNKNOWN" (Option D) masks data-quality problems and can produce misleading analytics. Leaving raw JSON for DAX handling (Option A) is a poor practice that pushes transformation complexity to the semantic layer. Quarantining invalid records preserves them for investigation while keeping the Silver table clean.

</details>

---

### Question 3

The Power BI developer needs to implement Row-Level Security so that each of the four regional managers sees only their own region's data. The semantic model uses Direct Lake mode connected to the Gold layer. What is the correct implementation approach?

- A) Create four separate Power BI reports, each hard-coded with a filter for one region.
- B) Define RLS roles in the semantic model using DAX filter expressions on the Region dimension table, and assign each regional manager's Azure AD account to the appropriate role.
- C) Create four separate Gold-layer Delta tables (one per region) and build four separate semantic models.
- D) Use object-level security (OLS) to hide the Region column from managers who should not see other regions.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Define RLS roles in the semantic model using DAX filter expressions on the Region dimension table, and assign each regional manager's Azure AD account to the appropriate role.**

**Explanation:** Row-Level Security in Power BI / Fabric semantic models is implemented by creating roles with DAX filter expressions (e.g., `[Region] = "Northeast"`) and mapping users to roles. This is the standard, scalable approach. Creating separate reports (A) or separate models (C) causes maintenance overhead and defeats the purpose of a unified model. OLS (D) hides entire columns or tables from view; it does not filter rows and would not solve the requirement of showing region-specific data.

</details>

---

### Question 4

During Phase 1 testing, the team discovers that the Direct Lake semantic model occasionally falls back to DirectQuery mode during peak usage hours, causing slow report performance. What is the MOST likely cause, and how should they address it?

- A) The Delta tables have too many small Parquet files; they should run an OPTIMIZE (bin-compaction) operation on the Gold-layer tables.
- B) The Direct Lake model does not support DAX calculations; they should remove all measures.
- C) The Power BI reports are using Import mode; they should switch to Direct Lake.
- D) The Fabric capacity is paused; they should resume it.

<details>
<summary>Show Answer</summary>

**Correct Answer: A) The Delta tables have too many small Parquet files; they should run an OPTIMIZE (bin-compaction) operation on the Gold-layer tables.**

**Explanation:** Direct Lake mode reads Delta/Parquet files directly into the Analysis Services engine. When tables have too many small files (the "small-file problem"), the model may exceed framing limits and fall back to DirectQuery, which is significantly slower. Running `OPTIMIZE` compacts small files into larger ones and may also apply V-Order sorting, keeping the model within its framing guardrails. Option B is incorrect — Direct Lake fully supports DAX measures. Options C and D describe unrelated problems.

</details>

---

### Question 5

The data steward must ensure that PCI-DSS compliance is maintained for payment-card data. Credit-card numbers are present in the raw POS feeds. At which layer should card numbers be masked or tokenized, and what is the recommended approach?

- A) Mask card numbers in the Gold layer so that all historical raw data is preserved for auditors.
- B) Tokenize card numbers before they land in the Bronze layer by applying the transformation in the ingestion pipeline's Copy activity mapping.
- C) Store card numbers in plain text in all layers but restrict access using workspace roles.
- D) Mask card numbers in the Power BI report using a DAX measure that replaces digits with asterisks.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Tokenize card numbers before they land in the Bronze layer by applying the transformation in the ingestion pipeline's Copy activity mapping.**

**Explanation:** PCI-DSS requires that cardholder data be protected at the earliest possible point in the data flow. Tokenizing or masking during ingestion — before the data is persisted in the Lakehouse — minimizes the PCI scope of the entire platform. Storing raw card numbers in Bronze (Option A) expands PCI scope to every layer that touches Bronze data. Relying solely on workspace roles (Option C) does not satisfy PCI's encryption/tokenization requirements. DAX-level masking (Option D) is a presentation-layer trick that does not protect the underlying data at rest.

</details>

---

### Question 6

NorthStar wants to implement deployment pipelines for their Fabric artifacts. The team needs to promote changes from Development to Test to Production workspaces. Which set of artifacts can be included in a Fabric deployment pipeline?

- A) Only Power BI reports and semantic models.
- B) Semantic models, reports, paginated reports, Lakehouses, Data Pipelines, Dataflows Gen2, and Notebooks.
- C) Only Lakehouses and Notebooks.
- D) All Fabric items including Eventstreams, KQL Databases, and Fabric capacities.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Semantic models, reports, paginated reports, Lakehouses, Data Pipelines, Dataflows Gen2, and Notebooks.**

**Explanation:** Fabric deployment pipelines support a broad set of item types including semantic models (datasets), reports, paginated reports, dataflows, data pipelines, Lakehouses, and Notebooks. Not every Fabric item type is supported — for example, Eventstreams and KQL databases have limited or no deployment-pipeline support at this time. Fabric capacities are administrative resources, not deployable artifacts. Option A is too narrow (the legacy Power BI-only view), and Option C excludes critical items like semantic models and pipelines.

</details>

---

### Question 7

The data engineers are designing the incremental load strategy for the POS transactions table. The source SQL Server table has a monotonically increasing `transaction_id` (BIGINT) column and a `transaction_timestamp` (DATETIME2) column. Which approach is BEST for incremental ingestion into the Bronze layer?

- A) Perform a full table extract every 15 minutes and overwrite the Bronze Delta table.
- B) Use a watermark pattern in the Data Pipeline: store the last loaded `transaction_id` in a watermark table and query only rows with `transaction_id` greater than the watermark on each run.
- C) Use Change Data Capture (CDC) on the source SQL Server and configure the Data Pipeline to read from the CDC tables, capturing inserts, updates, and deletes.
- D) Export the entire table to Parquet once per day and use a shortcut.

<details>
<summary>Show Answer</summary>

**Correct Answer: C) Use Change Data Capture (CDC) on the source SQL Server and configure the Data Pipeline to read from the CDC tables, capturing inserts, updates, and deletes.**

**Explanation:** CDC is the most robust incremental strategy because it captures all change types (inserts, updates, deletes) directly from the transaction log, ensuring nothing is missed — even late-arriving corrections or voids. A watermark approach (Option B) handles inserts well but can miss updates to previously loaded rows (e.g., a voided transaction). Full extracts (Option A) waste network bandwidth and compute for 2.5 M rows every 15 minutes. Daily Parquet exports (Option D) cannot meet the 15-minute freshness SLA.

</details>

---

### Question 8

The analytics engineer is building the Gold-layer `fact_daily_sales` aggregate table. The table must support fast dashboard queries for sales by store, product category, and date. Which optimization strategies should they apply to the Delta table? (Choose TWO.)

- A) Enable V-Order on the Delta table to optimize for the Analysis Services engine in Direct Lake mode.
- B) Partition the table by `transaction_id` to maximize parallelism.
- C) Use Z-Order (OPTIMIZE ZORDER) on the `store_id` and `category_id` columns to improve data-skipping efficiency.
- D) Store the table as CSV instead of Delta to reduce storage costs.
- E) Disable all statistics collection to reduce write overhead.

<details>
<summary>Show Answer</summary>

**Correct Answer: A) Enable V-Order on the Delta table to optimize for the Analysis Services engine in Direct Lake mode AND C) Use Z-Order (OPTIMIZE ZORDER) on the `store_id` and `category_id` columns to improve data-skipping efficiency.**

**Explanation:** V-Order is a Fabric-specific write-time optimization that arranges data within Parquet files for optimal read performance by the Analysis Services engine powering Direct Lake — it is highly recommended for Gold tables consumed by semantic models. Z-Order co-locates data for specified columns within the same file groups, enabling Delta's data-skipping statistics to eliminate irrelevant files during queries filtered by store or category. Partitioning by `transaction_id` (B) creates millions of tiny partitions and is an anti-pattern. CSV (D) loses Delta features like ACID transactions and time travel. Disabling statistics (E) degrades query performance.

</details>

---

### Question 9

During capacity planning, the team needs to decide how to handle the burst from F64 to F128 during the Black Friday period. Which Fabric feature or practice should they use to manage this?

- A) Manually delete unused Lakehouses to free up capacity units before Black Friday.
- B) Scale the Fabric capacity SKU from F64 to F128 in the Azure portal before the peak period and scale it back down afterward.
- C) Create a second F64 capacity and split workloads across both capacities permanently.
- D) Switch all semantic models from Direct Lake to Import mode to reduce capacity consumption.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Scale the Fabric capacity SKU from F64 to F128 in the Azure portal before the peak period and scale it back down afterward.**

**Explanation:** Fabric capacities can be scaled up or down in the Azure portal (or via Azure Resource Manager APIs / automation). Scaling to F128 during known peak periods and scaling back to F64 afterward is the cost-effective, operationally correct approach. Deleting Lakehouses (A) removes data and is not a capacity-management strategy. Splitting workloads across two capacities permanently (C) doubles steady-state costs. Switching to Import mode (D) would actually increase capacity consumption because import refreshes are compute-intensive, and it would lose the benefits of Direct Lake.

</details>

---

### Question 10

The team has completed Phase 1 and is preparing for Phase 3 — seasonal demand forecasting. They plan to train an ML model in a Fabric Notebook and surface predictions in Power BI. Which approach allows the merchandising team to consume the forecast data in their existing Power BI dashboards with minimal effort?

- A) Export the model predictions to a CSV file and email it to the merchandising team weekly.
- B) Write the prediction results to a Gold-layer Delta table in the Lakehouse and add the table to the existing Direct Lake semantic model as a new forecast table.
- C) Build a standalone Python Flask API that serves predictions and connect Power BI to it via a web connector.
- D) Store predictions in a separate Azure Machine Learning workspace and require the merchandising team to use Azure ML Studio for visualization.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Write the prediction results to a Gold-layer Delta table in the Lakehouse and add the table to the existing Direct Lake semantic model as a new forecast table.**

**Explanation:** Writing predictions back to the Gold layer as a Delta table seamlessly integrates forecasts into the existing medallion architecture. Adding the table to the Direct Lake semantic model means the merchandising team can explore forecasts in the same Power BI dashboards they already use, with no new tools or workflows. Option A is a manual, non-scalable process. Option C introduces unnecessary infrastructure outside of Fabric. Option D forces end users onto a different platform, violating the self-service analytics goal.

</details>
