# DP-600 Exam Tips & Strategies Cheat Sheet

> **Purpose:** A practical, actionable guide for last-minute review and exam-day strategy.
> Covers format, pacing, decision frameworks, must-know facts, and common traps.

---

## 1. Exam Format at a Glance

| Detail              | Value                                                    |
| ------------------- | -------------------------------------------------------- |
| **Number of Qs**    | 40–60 questions                                          |
| **Duration**        | 120 minutes (+ ~10 min survey/NDA)                       |
| **Passing score**   | 700 / 1000                                               |
| **Question types**  | Multiple-choice, case studies, drag-and-drop, scenario   |
| **Case studies**    | Typically 1–3 sets with 4–6 questions each               |
| **Adaptive?**       | No — all questions scored equally                        |
| **Back-tracking**   | Allowed within a section; **not** between sections       |

> **⚠️ Key rule:** Once you leave a case-study section you **cannot** return to it.
> Read every tab of the case study before answering.

---

## 2. Domain Weights

| Domain | Topic                                       | Weight   | Priority |
| ------ | ------------------------------------------- | -------- | -------- |
| 1      | Plan, implement, and manage a solution      | 10–15%   | Low      |
| 2      | Prepare and serve data                      | 40–45%   | **High** |
| 3      | Implement and manage semantic models        | 20–25%   | Medium   |
| 4      | Explore and analyze data                    | 20–25%   | Medium   |

> **💡 Study priority:** Domain 2 alone is nearly half the exam.
> Master lakehouses, warehouses, dataflows, pipelines, and data transformations first.

### What Each Domain Covers

- **Domain 1:** Workspace setup, capacity management, deployment pipelines, lifecycle management, Git integration
- **Domain 2:** Lakehouse & warehouse ingestion, Dataflow Gen2, notebooks, pipelines, shortcuts, data modeling, SQL analytics endpoint
- **Domain 3:** Semantic models, relationships, DAX measures, calculation groups, field parameters, incremental refresh
- **Domain 4:** DAX queries, visual-level queries, notebooks for exploration, KQL, Spark SQL, paginated reports

---

## 3. Time Management Strategy

### Pacing Guide

| Phase              | Minutes | Activity                                      |
| ------------------ | ------- | --------------------------------------------- |
| First pass         | 70–80   | Answer confident Qs, flag uncertain ones       |
| Case studies       | 20–30   | Read all tabs first, then answer               |
| Review flagged     | 10–15   | Revisit flagged questions                      |
| Final sweep        | 5       | Sanity-check unanswered items                  |

### Rules of Thumb

- **90-second rule:** If a question takes longer than 90 seconds, flag it and move on.
- **Never leave blanks:** There is no penalty for guessing — always pick something.
- **Case studies first or last?** If they appear at the start, do them first (you can't return). If they're a separate section, budget 5–7 minutes per case study.
- **Flag generously:** Flag anything you're not 95% confident about.

> **💡 Tip:** After your first pass, count flagged items. Divide remaining time evenly among them.

---

## 4. Key Decision Trees

### Lakehouse vs. Warehouse

| Criteria                        | Lakehouse                          | Warehouse                          |
| ------------------------------- | ---------------------------------- | ---------------------------------- |
| **Data format**                 | Delta/Parquet (files + tables)     | Structured tables only             |
| **Query language**              | Spark SQL, PySpark, SQL endpoint   | T-SQL (full DML/DDL)              |
| **Best for**                    | Data science, semi-structured data | Traditional BI, complex joins      |
| **Schema enforcement**          | Schema-on-read flexibility         | Schema-on-write strictness         |
| **Stored procedures**           | ❌ Not supported                   | ✅ Supported                       |
| **Cross-database queries**      | Via shortcuts                      | ✅ Native three-part naming        |

> **Decision:** Need stored procs or strict T-SQL? → **Warehouse.**
> Need Spark notebooks or mixed file types? → **Lakehouse.**

### Dataflow Gen2 vs. Pipeline

| Criteria                     | Dataflow Gen2                     | Pipeline                            |
| ---------------------------- | --------------------------------- | ----------------------------------- |
| **Interface**                | Power Query (low-code)            | Orchestration canvas                |
| **Best for**                 | Data transformations, cleansing   | Orchestrating multiple activities   |
| **Compute**                  | Mashup engine                     | Spark / Copy engine                 |
| **Scheduling**               | Standalone or inside a pipeline   | Triggers, schedules, event-based    |

> **Decision:** Need to **transform** data with a visual UI? → **Dataflow Gen2.**
> Need to **orchestrate** multiple steps (copy, transform, notify)? → **Pipeline.**

### Import vs. DirectQuery vs. Direct Lake

| Mode             | Data Location         | Performance  | Freshness       | Size Limit         |
| ---------------- | --------------------- | ------------ | --------------- | ------------------ |
| **Import**       | In-memory (model)     | ⚡ Fastest   | Scheduled refresh | Dataset size cap   |
| **DirectQuery**  | Source system          | 🐢 Slowest  | Real-time        | No cap             |
| **Direct Lake**  | Delta tables in lake   | ⚡ Fast      | Near real-time   | Capacity-dependent |

> **Decision:** Fabric Lakehouse/Warehouse as source? → **Direct Lake** (default and recommended).
> Need real-time against external SQL? → **DirectQuery.**
> Small dataset, full control? → **Import.**

### Copy Activity vs. Dataflow Gen2

- **Copy Activity:** High-speed bulk data movement, minimal transformation (column mapping only)
- **Dataflow Gen2:** Complex transformations, merges, conditional columns, Power Query M

> **Decision:** Moving data as-is at scale? → **Copy Activity.**
> Need to reshape, merge, or clean data? → **Dataflow Gen2.**

### Notebook vs. Dataflow Gen2

- **Notebook:** PySpark/Spark SQL, complex logic, ML, large-scale processing
- **Dataflow Gen2:** Power Query, low-code, business-user friendly

> **Decision:** Data engineer / data scientist workload? → **Notebook.**
> Business analyst / citizen developer workload? → **Dataflow Gen2.**

---

## 5. Top 20 Must-Know Facts

1. **Direct Lake** is the default and recommended semantic model mode in Fabric — it reads Delta tables directly with no import or DirectQuery overhead.
2. **Shortcuts** create virtual references to data without copying — they work across OneLake, ADLS Gen2, S3, and Dataverse.
3. **V-Order** optimization is applied to Delta tables by default in Fabric for faster reads.
4. **COPY INTO** is the fastest way to bulk-load data into a Fabric warehouse from files.
5. **Dataflow Gen2** outputs go to destinations (lakehouse tables, warehouse tables, etc.) — you must configure the destination explicitly.
6. **Deployment pipelines** have three stages: Development → Test → Production.
7. **Workspace roles** (Admin, Member, Contributor, Viewer) control access at the workspace level; item-level permissions offer finer control.
8. **Row-Level Security (RLS)** is defined with DAX expressions in the semantic model and filters rows.
9. **Object-Level Security (OLS)** restricts access to specific tables or columns in a semantic model.
10. **Sensitivity labels** (from Microsoft Purview) classify and protect data — they propagate downstream when data is exported.
11. **Delta Lake** is the standard storage format in OneLake — all tables in lakehouses are Delta tables.
12. **SQL analytics endpoint** is auto-generated for every lakehouse, enabling T-SQL read queries on lakehouse tables.
13. **Incremental refresh** partitions a table by date and only refreshes recent partitions, reducing refresh time.
14. **Calculation groups** let you reuse DAX logic (e.g., time-intelligence patterns) across multiple measures.
15. **Field parameters** allow report consumers to dynamically swap dimensions or measures on a visual.
16. **Git integration** in Fabric workspaces connects to Azure DevOps repos for version control.
17. **The Fabric capacity model** uses CU (Capacity Units); throttling occurs when utilization exceeds the CU limit.
18. **Spark notebooks** in Fabric run on a managed Spark cluster — sessions auto-start and auto-terminate.
19. **Mirroring** replicates external databases (Azure SQL, Cosmos DB, Snowflake) into OneLake as Delta tables in near real-time.
20. **Semantic model refresh** can be triggered manually, on a schedule, or via the REST API / pipeline.

---

## 6. Common Traps & Pitfalls

> **⚠️ The exam loves "almost correct" answers. Watch for these traps:**

| Trap                                         | Why It's Wrong                                                   | Correct Answer                                      |
| -------------------------------------------- | ---------------------------------------------------------------- | --------------------------------------------------- |
| Using Import mode for Fabric lakehouse       | Direct Lake is the default and preferred mode                    | Use **Direct Lake**                                 |
| Confusing workspace roles                    | "Member" can publish; "Contributor" cannot manage access         | Know the exact permissions per role                  |
| RLS on the source vs. on the semantic model  | RLS in Fabric is defined on the **semantic model**, not the lake | Define RLS with DAX in the model                     |
| Using DirectQuery for Fabric sources         | DirectQuery adds latency; Direct Lake is purpose-built           | Use **Direct Lake** for Fabric-native sources        |
| Copy Activity for complex transforms         | Copy Activity only maps columns                                  | Use **Dataflow Gen2** or **Notebook**                |
| Thinking SQL endpoint supports writes        | SQL analytics endpoint is **read-only**                          | Write via Spark or warehouse T-SQL                   |
| Scheduling Dataflow Gen2 inside pipeline     | A Dataflow Gen2 activity in a pipeline uses the pipeline trigger | Remove the standalone schedule to avoid double runs  |
| CTAS in a lakehouse                          | CREATE TABLE AS SELECT is for **warehouses**, not lakehouses     | Use Spark SQL for lakehouse table creation            |

### More Gotchas

- **Paginated reports** are for pixel-perfect, print-ready output — not interactive dashboards.
- **KQL databases** are for real-time analytics on streaming data — don't confuse with warehouse.
- **OneLake** is a single logical data lake per tenant — every workspace stores data in it.
- **Shortcuts ≠ copies:** Shortcuts don't duplicate data; they're pointers. Changes in the source reflect immediately.

---

## 7. DAX Essentials — 10 Functions to Know Cold

| #  | Function                | What It Does                                      | Example                                                         |
| -- | ----------------------- | ------------------------------------------------- | --------------------------------------------------------------- |
| 1  | `CALCULATE`             | Changes filter context for an expression          | `CALCULATE(SUM(Sales[Amount]), Product[Color]="Red")`           |
| 2  | `FILTER`                | Returns a filtered table                          | `FILTER(ALL(Product), Product[Price] > 100)`                    |
| 3  | `ALL`                   | Removes filters from a table or column            | `CALCULATE(SUM(Sales[Amount]), ALL(Date))`                      |
| 4  | `SUMX`                  | Row-by-row sum (iterator)                         | `SUMX(Sales, Sales[Qty] * Sales[Price])`                        |
| 5  | `RELATED`               | Pulls value from related table (many-to-one side) | `RELATED(Product[Category])`                                    |
| 6  | `DIVIDE`                | Safe division (handles divide-by-zero)            | `DIVIDE(SUM(Sales[Profit]), SUM(Sales[Revenue]), 0)`            |
| 7  | `DISTINCTCOUNT`         | Counts unique values                              | `DISTINCTCOUNT(Sales[CustomerID])`                              |
| 8  | `TOTALYTD`              | Year-to-date total                                | `TOTALYTD(SUM(Sales[Amount]), Date[Date])`                      |
| 9  | `SELECTEDVALUE`         | Returns value if single item in filter context    | `SELECTEDVALUE(Product[Name], "Multiple")`                      |
| 10 | `SWITCH`                | Multi-condition branching (replaces nested IF)     | `SWITCH(TRUE(), [Score]>90, "A", [Score]>80, "B", "C")`        |

> **💡 Exam tip:** Understand `CALCULATE` deeply — it appears in the majority of DAX questions.
> Know the difference between `FILTER` (iterator, row context) and `CALCULATE` modifiers (filter context).

### Key DAX Concepts

- **Row context** vs. **filter context** — iterators (SUMX, AVERAGEX) create row context
- **Context transition** — occurs when CALCULATE wraps a row-context expression
- **REMOVEFILTERS** is an alias for `ALL` when used as a CALCULATE modifier
- **Variables (`VAR`)** are evaluated once and improve readability and performance

---

## 8. T-SQL Essentials for Fabric

### COPY INTO (Warehouse Bulk Load)

```sql
COPY INTO dbo.Sales
FROM 'https://storage.blob.core.windows.net/container/sales/*.parquet'
WITH (
    FILE_TYPE = 'PARQUET',
    CREDENTIAL = (IDENTITY = 'Shared Access Signature', SECRET = '<sas>')
);
```

> **Key fact:** `COPY INTO` is the highest-throughput method for loading data into a Fabric warehouse.

### CREATE TABLE AS SELECT (CTAS)

```sql
CREATE TABLE dbo.SalesSummary
AS
SELECT ProductID, SUM(Amount) AS TotalSales
FROM dbo.Sales
GROUP BY ProductID;
```

> **Key fact:** CTAS creates a new table from a query result — useful for materializing aggregations.

### Cross-Database Queries

```sql
SELECT a.CustomerID, b.OrderTotal
FROM LakehouseDB.dbo.Customers AS a
JOIN WarehouseDB.dbo.Orders AS b
    ON a.CustomerID = b.CustomerID;
```

> **Key fact:** Cross-database queries use three-part naming and work across Fabric warehouses and SQL analytics endpoints within the same workspace.

### Other T-SQL Tips

- **Views** are supported in warehouses for abstraction and security.
- **Stored procedures** work in warehouses — not in lakehouse SQL endpoints.
- The SQL analytics endpoint is **read-only** — no INSERT, UPDATE, or DELETE.
- **Table clones** in warehouses create zero-copy clones for testing.

---

## 9. Security Checklist

### Workspace Roles

| Role            | Build models | Create items | Manage access | Share items |
| --------------- | ------------ | ------------ | ------------- | ----------- |
| **Admin**       | ✅           | ✅           | ✅            | ✅          |
| **Member**      | ✅           | ✅           | ❌            | ✅          |
| **Contributor** | ✅           | ✅           | ❌            | ❌          |
| **Viewer**      | ❌           | ❌           | ❌            | ❌          |

> **⚠️ Trap:** Members can share items but cannot grant workspace access. Only Admins manage workspace roles.

### Row-Level Security (RLS)

- Defined in the **semantic model** using DAX filter expressions
- Applied when users have **Viewer** role (or Build permission without model edit access)
- **Not enforced** for workspace Admins, Members, or Contributors viewing the model
- Test using "View as Role" in Power BI Desktop or the service

### Object-Level Security (OLS)

- Restricts visibility of **tables or columns** — users see the model but hidden objects are inaccessible
- Defined via **Tabular Model Scripting Language (TMSL)** or Tabular Editor
- Cannot be configured from the Power BI Desktop UI

### Sensitivity Labels

- Applied from **Microsoft Purview** (formerly Microsoft Information Protection)
- Propagate to downstream exports (Excel, PDF, PowerPoint)
- Can enforce encryption, watermarks, and access restrictions
- Admins can mandate labels via tenant-level policies

### Security Best Practices

- ✅ Use **Entra ID security groups** for role assignments — not individual users
- ✅ Apply RLS even if you trust workspace members — defense in depth
- ✅ Use **item-level sharing** for granular access outside the workspace
- ✅ Audit access with the **admin monitoring workspace**

---

## 10. Last-Minute Review Checklist

> **📋 Review this the night before your exam:**

### Core Concepts (Quick Self-Test)

- [ ] Can I explain Direct Lake vs. DirectQuery vs. Import in one sentence each?
- [ ] Can I list the four workspace roles and their key differences?
- [ ] Can I describe when to use a Lakehouse vs. a Warehouse?
- [ ] Can I write a basic CALCULATE statement from memory?
- [ ] Do I know what COPY INTO does and when to use it?
- [ ] Can I explain what shortcuts do and their limitations?
- [ ] Do I know where RLS is defined and when it's enforced?
- [ ] Can I list three ways to ingest data into a lakehouse?
- [ ] Do I understand deployment pipelines and their three stages?
- [ ] Can I describe what V-Order optimization does?

### Quick-Reference Numbers

- Passing score: **700/1000**
- Exam time: **120 minutes**
- Domain 2 weight: **40–45%** (largest domain — prepare and serve data)
- Workspace roles: **4** (Admin, Member, Contributor, Viewer)
- Deployment pipeline stages: **3** (Dev → Test → Prod)

### Last-Minute Mnemonics

- **DWCS** — Direct Lake, Warehouse for T-SQL, Copy for bulk, Shortcuts for no-copy
- **AMCV** — Admin, Member, Contributor, Viewer (most to least access)
- **DTP** — Dev → Test → Prod (deployment pipeline stages)

---

## 11. Exam Day Tips

### Before the Exam

- **ID:** Bring two forms of identification (government-issued photo ID required)
- **Testing center:** Arrive 15–30 minutes early; for online proctoring, test your system the day before
- **Online proctoring checklist:** Clear desk, close all apps, stable internet, working webcam and mic
- **Comfort:** Eat a light meal, stay hydrated, avoid excessive caffeine

### During the Exam

- **Read the full question** — especially the last sentence (it often contains the actual ask)
- **Watch for qualifiers:** "MOST efficient," "LEAST amount of effort," "FIRST step" — these change the correct answer
- **Case studies:** Read **all** tabs (overview, environment, requirements, existing setup) before answering any question
- **Eliminate wrong answers first** — on MCQ, narrowing to 2 options gives you a 50% guess
- **Flag and move on** — don't spend 5 minutes on one question when 3 easy ones await
- **Trust your first instinct** — only change an answer if you find concrete evidence it's wrong

### Managing Anxiety

- **Breathe:** If stress builds, pause for 10 seconds and take three deep breaths
- **Progress, not perfection:** You don't need 100% — you need 70% correct
- **It's okay to guess:** Flag it, pick the best option, and move on
- **Mindset:** You've prepared. The exam tests practical knowledge, not trick questions

> **💡 Final reminder:** The exam rewards **practical Fabric knowledge** over rote memorization.
> Focus on *when and why* to use each tool, not just *what* each tool does.

---

## Quick-Reference: Fabric Item Cheat Sheet

| Item                  | Purpose                                    | Key Detail                             |
| --------------------- | ------------------------------------------ | -------------------------------------- |
| **Lakehouse**         | Store files + Delta tables                 | Spark + SQL analytics endpoint         |
| **Warehouse**         | Structured T-SQL analytics                 | Full DML/DDL, stored procs             |
| **Dataflow Gen2**     | Low-code data transformation               | Power Query M, configurable output     |
| **Pipeline**          | Orchestration of activities                | Copy, Dataflow, Notebook, etc.         |
| **Notebook**          | Code-first Spark processing                | PySpark, Spark SQL, R, Scala           |
| **Semantic Model**    | Business logic layer for BI               | Measures, relationships, RLS           |
| **Report**            | Interactive visuals                        | Connected to a semantic model          |
| **KQL Database**      | Real-time analytics                        | Streaming data, time-series            |
| **Eventstream**       | Real-time event ingestion                  | Routes events to KQL, lakehouse, etc.  |

---

> **Good luck on your DP-600 exam! You've got this. 🎯**
