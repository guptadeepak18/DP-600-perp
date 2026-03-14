# Case Study 2: Healthcare Reporting Platform

## Scenario

MedVista Health is a regional hospital network comprising **12 hospitals**, **85 outpatient clinics**, and over **8,000 clinical and administrative staff**. The network treats approximately **50,000 inpatients** and **600,000 outpatient visits per year**. MedVista's current analytics landscape is fragmented: each hospital maintains its own reporting database, clinical dashboards are built in a legacy BI tool that is reaching end-of-support, and regulatory submissions are compiled manually in spreadsheets by the compliance team.

The Chief Data Officer (CDO) has initiated the **"One MedVista" analytics program** with a mandate to consolidate all clinical, operational, and financial analytics onto **Microsoft Fabric**. The program has four primary objectives:

1. **Patient Outcome Dashboards** — near-real-time visibility into readmission rates, average length of stay, and mortality indices across all 12 hospitals.
2. **Regulatory Compliance Reporting** — automated generation of reports required by CMS (Centers for Medicare & Medicaid Services), Joint Commission, and state health departments. All data handling must comply with **HIPAA** (Health Insurance Portability and Accountability Act).
3. **Clinical Trial Reporting** — the research division conducts 25–30 active trials at any time and needs a secure, auditable environment for trial-specific data sets.
4. **Emergency Department (ED) Wait-Time Tracking** — real-time dashboards showing current ED patient volumes, triage acuity distributions, and average door-to-provider times, refreshed every five minutes.

Data volumes are significant. The EHR system generates approximately **1.2 million clinical events per day** (admissions, discharges, lab orders, medication administrations). The laboratory information system produces **300,000 result records daily**. The SAP billing system exports **150,000 claim-line items per day**. IoT patient monitors in ICUs across all 12 hospitals stream approximately **500 MB of telemetry per hour** (heart rate, SpO2, blood pressure).

MedVista's data-governance council requires that **Protected Health Information (PHI)** — including patient name, date of birth, Social Security Number, and medical record number — be protected at every layer. Sensitivity labels must be applied to Fabric items containing PHI, and **Object-Level Security (OLS)** must hide PHI columns from non-clinical analysts. The analytics team consists of four data engineers, two BI developers, one data architect, one security/compliance analyst, and a clinical informaticist.

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           DATA SOURCES                                    │
│                                                                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────────┐ │
│  │  EHR System   │ │ Lab Systems   │ │ SAP Billing  │ │ IoT Patient     │ │
│  │  (HL7/FHIR)  │ │ (On-prem SQL) │ │ (SAP HANA)   │ │ Monitors        │ │
│  │  via API      │ │ via Gateway   │ │ via Gateway   │ │ (Event Hubs)    │ │
│  └──────┬────────┘ └──────┬────────┘ └──────┬────────┘ └───────┬─────────┘│
└─────────┼──────────────────┼──────────────────┼──────────────────┼─────────┘
          │                  │                  │                  │
          ▼                  ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        MICROSOFT FABRIC                                   │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                      INGESTION LAYER                             │    │
│  │  Data Pipeline      │ Dataflow Gen2     │ Eventstream            │    │
│  │  (EHR API, Labs,    │ (SAP transform)   │ (IoT telemetry →       │    │
│  │   batch loads)      │                   │  KQL Database)         │    │
│  └──────────┬──────────┴──────────┬────────┴──────────┬─────────────┘    │
│             │                     │                   │                   │
│             ▼                     ▼                   ▼                   │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    MEDALLION LAKEHOUSE                            │    │
│  │                                                                  │    │
│  │  ┌──────────┐     ┌──────────┐     ┌──────────┐                 │    │
│  │  │  BRONZE  │────▶│  SILVER  │────▶│   GOLD   │                 │    │
│  │  │ (raw /   │     │ (HIPAA   │     │ (analytic│                 │    │
│  │  │  landed) │     │  masked, │     │  models) │                 │    │
│  │  │          │     │  conformed│     │          │                 │    │
│  │  └──────────┘     └──────────┘     └──────────┘                 │    │
│  └──────────────────────────┬───────────────────────────────────────┘    │
│                             │                                            │
│        ┌────────────────────┼────────────────────┐                       │
│        ▼                    ▼                    ▼                       │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐            │
│  │ Semantic Model │  │ KQL Database  │  │ Clinical Trial    │            │
│  │ (Direct Lake)  │  │ (Real-time    │  │ Lakehouse         │            │
│  │ + OLS + RLS    │  │  ED telemetry)│  │ (Isolated,        │            │
│  └───────┬────────┘  └───────┬───────┘  │  audit-logged)    │            │
│          │                   │          └─────────┬─────────┘            │
│          ▼                   ▼                    ▼                       │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    POWER BI REPORTS & DASHBOARDS                  │    │
│  │  Patient Outcomes │ Compliance │ ED Wait-Time │ Clinical Trials   │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    GOVERNANCE & SECURITY                          │    │
│  │  Microsoft Purview │ Sensitivity Labels │ Audit Logs │ OLS + RLS  │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Requirements

- **Medallion architecture** in a Fabric Lakehouse: Bronze (raw/landed), Silver (HIPAA-masked and conformed), Gold (analytics-ready aggregates).
- **Real-time ED telemetry** ingested via Eventstream from Azure Event Hubs into a KQL Database for sub-minute latency dashboards.
- **Batch ingestion** for EHR, lab, and billing data using Data Pipelines and Dataflow Gen2 with on-premises data gateways.
- **Direct Lake semantic model** over Gold-layer Delta tables with both **RLS** (hospital-level filtering) and **OLS** (hiding PHI columns from non-clinical roles).
- **Sensitivity labels** applied to all Fabric items containing PHI using Microsoft Purview Information Protection integration.
- **Clinical trial isolation** — dedicated Lakehouse with restricted workspace access and full audit logging.
- **Incremental refresh** for large fact tables (clinical events, lab results) to minimize processing time and capacity consumption.
- **Automated compliance reports** scheduled for monthly CMS and Joint Commission submissions.

---

## Data Sources

| Source | System | Protocol | Volume (Daily) | Refresh Cadence |
|---|---|---|---|---|
| Electronic Health Records | Epic / Cerner (HL7 FHIR R4) | REST API (HTTPS) | ~1.2 M clinical events | Hourly batch |
| Laboratory Information System | On-premises SQL Server | On-premises data gateway | ~300 K result records | Every 30 minutes |
| Billing & Claims | SAP S/4HANA | On-premises data gateway | ~150 K claim-line items | Daily batch |
| IoT Patient Monitors | Philips IntelliVue (ICU) | Azure Event Hubs (streaming) | ~500 MB/hour (~12 GB/day) | Real-time (5-sec intervals) |

---

## Constraints and Considerations

- **HIPAA Compliance:** All PHI must be encrypted at rest and in transit. De-identification or masking must occur no later than the Silver layer. Audit logs must be retained for six years.
- **Data Residency:** All data must remain within the continental United States (Fabric capacity deployed in US regions).
- **Access Control:** Least-privilege model; clinical researchers access only their assigned trial data; hospital administrators see only their hospital's metrics.
- **SLA:** ED wait-time dashboards must refresh within 5 minutes; patient outcome dashboards updated hourly; compliance reports generated by the 5th business day of each month.
- **Disaster Recovery:** RPO of 4 hours, RTO of 8 hours for all analytics workloads.
- **Budget:** F128 capacity with reserved instance pricing; no bursting beyond F128.
- **Team:** 4 data engineers, 2 BI developers, 1 data architect, 1 security/compliance analyst, 1 clinical informaticist.
- **Change Management:** All schema changes to Silver and Gold layers must go through a formal review process with the data-governance council.

---

## Questions

### Question 1

MedVista's data engineers need to ingest real-time telemetry from ICU patient monitors into Fabric for the ED wait-time tracking dashboard. The monitors publish data to Azure Event Hubs. Which Fabric component should they use to ingest this streaming data and where should it be stored for sub-minute query latency?

- A) Use a Data Pipeline with a Copy activity on a 1-minute schedule to load data into a Lakehouse Delta table.
- B) Use Fabric Eventstream to ingest from Azure Event Hubs and route the data to a KQL Database (Eventhouse) for real-time analytics.
- C) Use Dataflow Gen2 to connect to Event Hubs and write to a Lakehouse Bronze table.
- D) Write a custom Spark Structured Streaming job in a Fabric Notebook that reads from Event Hubs and writes to a Delta table.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Use Fabric Eventstream to ingest from Azure Event Hubs and route the data to a KQL Database (Eventhouse) for real-time analytics.**

**Explanation:** Fabric Eventstream is the native streaming ingestion service designed for exactly this pattern — it connects to Azure Event Hubs (and other streaming sources) and can route data to a KQL Database (Eventhouse), which is optimized for sub-second query latency on time-series and streaming data. A Data Pipeline on a 1-minute schedule (A) is micro-batch, not true streaming, and introduces latency. Dataflow Gen2 (C) does not support streaming sources. While Spark Structured Streaming (D) could technically work, it adds development complexity and does not match the KQL Database's query performance for real-time dashboards.

</details>

---

### Question 2

The security/compliance analyst must ensure that PHI columns (patient name, SSN, date of birth, medical record number) are visible to clinical staff in Power BI reports but hidden from financial analysts who use the same semantic model. Which Fabric/Power BI feature should they implement?

- A) Row-Level Security (RLS) with DAX filters that return BLANK() for PHI columns when the user is a financial analyst.
- B) Object-Level Security (OLS) to restrict visibility of PHI columns to specific roles, granting access only to the clinical role.
- C) Create two separate semantic models — one with PHI for clinical staff and one without PHI for financial analysts.
- D) Use Power BI field-level formatting to conditionally hide columns based on the user's email domain.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Object-Level Security (OLS) to restrict visibility of PHI columns to specific roles, granting access only to the clinical role.**

**Explanation:** Object-Level Security (OLS) is the Power BI / Fabric feature specifically designed to control visibility of individual columns (or tables) based on the user's role. By defining an OLS role that restricts PHI columns and assigning financial analysts to that role, the columns become completely invisible in reports and DAX queries for those users. RLS (A) filters rows, not columns — it cannot hide an entire column. Maintaining two separate models (C) doubles maintenance effort and introduces drift risk. Conditional formatting (D) is a presentation feature with no security enforcement — the underlying data is still accessible via DAX queries or Analyze in Excel.

</details>

---

### Question 3

The data architect is designing the Silver-layer transformation for EHR data. Raw FHIR resources land in Bronze as JSON documents. PHI fields must be de-identified for non-clinical downstream use while preserving a linkage key for authorized re-identification. What is the BEST approach?

- A) Delete all PHI fields at the Silver layer; there is no need to maintain linkage.
- B) Apply a deterministic, salted hash (e.g., SHA-256 with a secret salt stored in Azure Key Vault) to PHI fields, storing the hashed values in the Silver table and the original values only in a restricted reference table with audit logging.
- C) Encrypt PHI fields using AES-256 and store the encryption key in a Fabric Notebook cell.
- D) Leave PHI in plain text in the Silver layer and rely entirely on OLS at the semantic-model layer for protection.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Apply a deterministic, salted hash (e.g., SHA-256 with a secret salt stored in Azure Key Vault) to PHI fields, storing the hashed values in the Silver table and the original values only in a restricted reference table with audit logging.**

**Explanation:** This approach satisfies HIPAA's Safe Harbor de-identification requirements while preserving the ability for authorized users to re-identify records when clinically necessary. The hash is deterministic (same input → same output), enabling joins across data sets without exposing raw PHI. Storing the salt in Azure Key Vault follows secrets-management best practices. Deleting PHI entirely (A) prevents legitimate clinical use cases like re-identification for patient safety. Storing encryption keys in a Notebook cell (C) is a critical security violation — keys must be in a secrets manager. Relying solely on OLS (D) does not protect data at the storage layer, leaving PHI exposed in the Lakehouse files.

</details>

---

### Question 4

MedVista's compliance team requires that all Fabric items containing PHI are automatically labeled and that these labels enforce encryption and access restrictions. Which Microsoft technology should the security analyst configure?

- A) Microsoft Purview Information Protection sensitivity labels, integrated with Fabric to automatically label and protect items containing PHI.
- B) Azure Policy definitions applied at the Azure subscription level to tag Fabric resources.
- C) Power BI data classification tags set manually by report authors.
- D) Microsoft Defender for Cloud alerts configured to scan Lakehouse files for PHI patterns.

<details>
<summary>Show Answer</summary>

**Correct Answer: A) Microsoft Purview Information Protection sensitivity labels, integrated with Fabric to automatically label and protect items containing PHI.**

**Explanation:** Microsoft Purview Information Protection sensitivity labels integrate natively with Microsoft Fabric. Labels can be applied automatically (via auto-labeling policies that detect PHI patterns) or manually, and they enforce downstream protections such as encryption, watermarking, and access restrictions. These labels persist when data is exported, providing end-to-end protection. Azure Policy (B) operates at the infrastructure level and cannot label individual Fabric items. Manual data classification tags (C) are cosmetic annotations with no enforcement. Defender for Cloud (D) provides alerting but does not apply labels or enforce data protection policies within Fabric.

</details>

---

### Question 5

The clinical trial Lakehouse must be isolated so that only researchers assigned to a specific trial can access its data. All access must be auditable for FDA inspection. How should the data architect configure this?

- A) Store all clinical trial data in the main analytics Lakehouse and use RLS to filter by trial ID.
- B) Create a separate Fabric workspace for clinical trials with workspace-level access control, enable audit logging via Microsoft Purview, and assign researchers to the workspace using Azure AD security groups per trial.
- C) Store trial data in Azure Blob Storage outside of Fabric and provide researchers with SAS tokens.
- D) Use a shared Lakehouse but apply sensitivity labels that prevent researchers from viewing non-trial data.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Create a separate Fabric workspace for clinical trials with workspace-level access control, enable audit logging via Microsoft Purview, and assign researchers to the workspace using Azure AD security groups per trial.**

**Explanation:** A dedicated workspace provides the strongest isolation boundary in Fabric. Workspace roles (Admin, Member, Contributor, Viewer) control who can access, modify, or read artifacts. Azure AD security groups allow fine-grained assignment per trial. Microsoft Purview audit logs capture all access events, which is essential for FDA 21 CFR Part 11 compliance. RLS in a shared Lakehouse (A) does not provide workspace-level audit isolation. SAS tokens on external storage (C) move data outside the governed Fabric environment. Sensitivity labels (D) control what happens to data after access but do not provide row-level or object-level data isolation for trial-specific datasets.

</details>

---

### Question 6

The BI developers are building the Patient Outcome dashboard. The Gold-layer `fact_patient_encounters` table contains 80 million rows spanning three years. The semantic model uses Direct Lake mode. Reports are slow during initial load. The team wants to reduce the data scanned by Power BI for typical queries that filter by hospital and discharge date. Which TWO optimization strategies should they apply?

- A) Apply V-Order optimization when writing the Gold-layer Delta table to align data for the Analysis Services engine.
- B) Partition the Delta table by individual `patient_id` to enable per-patient file pruning.
- C) Use Z-Order on `hospital_id` and `discharge_date` columns to improve file-level data skipping.
- D) Convert the Delta table to CSV format to reduce file size overhead.
- E) Increase the Fabric capacity from F128 to F256 instead of optimizing the table.

<details>
<summary>Show Answer</summary>

**Correct Answer: A) Apply V-Order optimization when writing the Gold-layer Delta table AND C) Use Z-Order on `hospital_id` and `discharge_date` columns to improve file-level data skipping.**

**Explanation:** V-Order is a Fabric-specific Parquet optimization that reorders data within files for fast reads by the Analysis Services engine used in Direct Lake mode. Z-Order co-locates rows with similar values for the specified columns within the same file groups, allowing Delta's data-skipping statistics (min/max per file) to prune irrelevant files when queries filter by hospital or discharge date. Partitioning by `patient_id` (B) would create millions of tiny files — a severe anti-pattern. CSV (D) loses Delta's ACID guarantees, data skipping, and time travel. Simply scaling up capacity (E) is a brute-force approach that increases cost without addressing the root cause.

</details>

---

### Question 7

The data engineers need to implement incremental refresh for the `fact_clinical_events` table in the semantic model. The table has a `event_timestamp` column and grows by 1.2 million rows per day. Which configuration is MOST appropriate?

- A) Configure incremental refresh on the semantic model to store 3 years of historical data and refresh the most recent 7 days, using `event_timestamp` as the date/time column with the RangeStart and RangeEnd parameters.
- B) Perform a full refresh of all 3 years of data every hour to ensure completeness.
- C) Use incremental refresh with a 1-day refresh window and 30-day storage window to minimize capacity usage.
- D) Disable incremental refresh and rely on Direct Lake's automatic framing to handle data freshness.

<details>
<summary>Show Answer</summary>

**Correct Answer: A) Configure incremental refresh on the semantic model to store 3 years of historical data and refresh the most recent 7 days, using `event_timestamp` as the date/time column with the RangeStart and RangeEnd parameters.**

**Explanation:** Incremental refresh partitions the semantic model's table by the specified date column. Archival partitions (older than 7 days) are not re-queried during refresh, dramatically reducing processing time and capacity consumption. Refreshing the most recent 7 days accommodates late-arriving clinical events (which are common in healthcare — e.g., delayed lab results or amended discharge notes). A full refresh hourly (B) is extremely wasteful for a table with hundreds of millions of rows. A 30-day storage window (C) would discard most of the historical data needed for trend analysis. While Direct Lake framing (D) handles data freshness for querying, incremental refresh is still relevant when managing the partitioning and processing strategy of the underlying data model.

</details>

---

### Question 8

The compliance team needs to generate a monthly CMS Quality Reporting submission. The report pulls data from multiple Gold-layer tables, applies complex business rules, and must be delivered as a formatted PDF by the 5th business day of each month. Which approach is BEST?

- A) Have a BI developer manually export the Power BI report to PDF on the 5th business day of each month.
- B) Create a Power BI paginated report (SSRS-based) connected to the semantic model, schedule it via a Fabric Data Pipeline that triggers on the 1st of each month, and deliver the rendered PDF via email subscription.
- C) Build a custom Python script in a Fabric Notebook that queries Gold tables and generates a PDF using a third-party library, triggered manually.
- D) Use a standard Power BI interactive report with a scheduled email subscription.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Create a Power BI paginated report (SSRS-based) connected to the semantic model, schedule it via a Fabric Data Pipeline that triggers on the 1st of each month, and deliver the rendered PDF via email subscription.**

**Explanation:** Paginated reports in Power BI (built on SQL Server Reporting Services technology) are specifically designed for pixel-perfect, print-ready documents like regulatory submissions. They support precise page layout, headers/footers, and multi-page rendering — essential for CMS format requirements. Scheduling via a Data Pipeline and delivering via email subscription automates the process end-to-end. Manual export (A) introduces human error and does not scale. A custom Python PDF generator (C) requires significant development and maintenance effort for formatting. Standard Power BI interactive reports (D) are designed for on-screen exploration, not formatted document generation — they lack precise page control needed for regulatory submissions.

</details>

---

### Question 9

A data engineer discovers that the Bronze-layer lab results table is accumulating small Delta files (less than 1 MB each) because lab data arrives in small batches every 30 minutes. The Silver-layer Notebook that reads from this table is experiencing increasingly slow reads. What should the engineer do?

- A) Switch the lab data storage format from Delta to Parquet without Delta transaction logs.
- B) Schedule a recurring OPTIMIZE operation on the Bronze-layer Delta table to compact small files, and consider enabling Auto-Optimize (optimized writes and auto-compaction) for the table.
- C) Increase the Spark executor memory in the Silver-layer Notebook to compensate for the small-file overhead.
- D) Reduce the ingestion frequency from every 30 minutes to once per day to produce larger files.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Schedule a recurring OPTIMIZE operation on the Bronze-layer Delta table to compact small files, and consider enabling Auto-Optimize (optimized writes and auto-compaction) for the table.**

**Explanation:** The "small-file problem" is a well-known Delta Lake performance issue. Each small file requires a separate I/O operation, and the overhead of tracking thousands of small files degrades both read and write performance. The OPTIMIZE command compacts small files into larger, optimally sized files. Enabling Auto-Optimize (which includes optimized writes and auto-compaction) prevents the problem from recurring by automatically compacting files during writes. Switching away from Delta (A) loses critical features like ACID transactions and time travel. Increasing Spark memory (C) is a costly workaround that does not address the root cause. Reducing ingestion frequency (D) violates the 30-minute SLA for lab data freshness.

</details>

---

### Question 10

The data governance council requires that any schema change to Silver or Gold-layer tables (adding, removing, or modifying columns) be reviewed and approved before deployment. How should the team implement this governance process within their Fabric development workflow?

- A) Allow data engineers to make schema changes directly in the Production workspace and document changes in a shared spreadsheet after the fact.
- B) Use Fabric Git integration to connect workspaces to an Azure DevOps repository, require pull requests for all schema changes with mandatory code review by the data architect, and use deployment pipelines (Dev → Test → Prod) to promote approved changes.
- C) Restrict all schema changes to the data architect's personal account and have them apply changes manually.
- D) Disable schema evolution on all Delta tables so that no schema changes can be made.

<details>
<summary>Show Answer</summary>

**Correct Answer: B) Use Fabric Git integration to connect workspaces to an Azure DevOps repository, require pull requests for all schema changes with mandatory code review by the data architect, and use deployment pipelines (Dev → Test → Prod) to promote approved changes.**

**Explanation:** Fabric's Git integration connects workspace items (Notebooks, Pipelines, Lakehouse definitions, semantic models) to a Git repository in Azure DevOps or GitHub. This enables standard software-engineering governance: changes are made in a Development workspace, committed to a feature branch, reviewed via pull request (with the data architect as a required reviewer), merged to main, and promoted through deployment pipelines to Test and Production. This provides auditability, rollback capability, and formal approval gates. Making changes directly in Production (A) is high-risk and lacks governance. Restricting changes to one person (C) creates a bottleneck and bus-factor risk. Disabling schema evolution (D) prevents legitimate changes and is not a governance strategy — it is a technical lockdown.

</details>
