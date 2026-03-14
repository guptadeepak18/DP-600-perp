# Domain 1: Plan, Implement, and Manage a Solution for Data Analytics (10–15%)

> **Exam Weight:** This domain represents 10–15% of the DP-600 Implementing Analytics Solutions Using Microsoft Fabric exam. While it is the smallest weighted domain, it establishes the foundational knowledge required for every other domain.

---

## Table of Contents

1. [Design and Architect Analytics Solutions in Microsoft Fabric](#1-design-and-architect-analytics-solutions-in-microsoft-fabric)
2. [Manage and Configure Workspaces and Environments](#2-manage-and-configure-workspaces-and-environments)
3. [Apply Governance, Security, and Compliance](#3-apply-governance-security-and-compliance)
4. [Workspace Roles and Permissions](#4-workspace-roles-and-permissions)
5. [Monitoring and Auditing Usage](#5-monitoring-and-auditing-usage)
6. [Data Lineage and Impact Analysis](#6-data-lineage-and-impact-analysis)
7. [Managing Capacity and Resource Allocation](#7-managing-capacity-and-resource-allocation)

---

## 1. Design and Architect Analytics Solutions in Microsoft Fabric

### 1.1 Microsoft Fabric Overview and Components

Microsoft Fabric is a unified, end-to-end analytics platform that brings together data engineering, data integration, data warehousing, data science, real-time analytics, and business intelligence into a single SaaS experience built on a shared foundation called **OneLake**.

#### Core Components (Experiences)

| Experience | Description | Primary Persona |
|---|---|---|
| **Data Factory** | Data integration and orchestration (pipelines, dataflows) | Data Engineer |
| **Synapse Data Engineering** | Lakehouse, Spark notebooks, Spark job definitions | Data Engineer |
| **Synapse Data Warehouse** | T-SQL based data warehousing | Data Warehouse Developer |
| **Synapse Data Science** | ML models, experiments, notebooks | Data Scientist |
| **Synapse Real-Time Analytics** | KQL databases, eventstreams, real-time dashboards | Data Analyst / Engineer |
| **Power BI** | Reports, dashboards, semantic models (datasets) | Business Analyst |

#### OneLake — The Foundation

OneLake is the unified data lake that underpins all of Microsoft Fabric. Key characteristics:

- **Single copy of data** — all Fabric workloads read and write to OneLake, eliminating data silos
- **Built on Azure Data Lake Storage Gen2 (ADLS Gen2)** under the hood
- **Hierarchical namespace** — data is organized by tenant → workspace → item (lakehouse, warehouse, etc.)
- **Open format by default** — data is stored in **Delta Parquet** (Delta Lake) format
- **OneLake shortcuts** — allow referencing data in external storage (ADLS Gen2, Amazon S3, Google Cloud Storage, Dataverse) without copying it

> **Exam Tip:** Understand that OneLake is a single logical lake per tenant. You do NOT create multiple lakes — you organize data within workspaces and items.

#### Key Terminology

| Term | Definition |
|---|---|
| **Tenant** | The top-level organizational boundary in Fabric (maps to an Azure AD / Entra ID tenant) |
| **Capacity** | The compute and resource pool assigned to run Fabric workloads, measured in Capacity Units (CUs) |
| **Workspace** | A logical container for Fabric items (lakehouses, warehouses, reports, etc.) |
| **Item** | Any artifact within a workspace (lakehouse, warehouse, notebook, pipeline, report, semantic model, etc.) |
| **OneLake** | The unified storage layer for all Fabric data |
| **Shortcut** | A pointer to data stored in another location (internal or external) without copying the data |

### 1.2 Solution Architecture Patterns

When designing analytics solutions in Fabric, consider these common patterns:

#### Medallion Architecture (Bronze → Silver → Gold)

The most recommended pattern for organizing data in a Fabric Lakehouse:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Bronze     │────▶│   Silver     │────▶│    Gold      │
│  (Raw Data)  │     │ (Cleansed)   │     │ (Curated)    │
└─────────────┘     └─────────────┘     └─────────────┘
   Ingestion          Transformation       Serving
   as-is              validated            aggregated
   full fidelity      conformed            business-ready
```

- **Bronze (Raw):** Land data as-is from source systems. Preserve full fidelity.
- **Silver (Cleansed):** Apply data quality rules, schema enforcement, deduplication, and joins.
- **Gold (Curated):** Business-level aggregations, star schemas, and metrics ready for reporting.

> **Best Practice:** Implement Bronze → Silver → Gold using separate lakehouses or schemas within a single lakehouse, connected via shortcuts or Spark notebooks.

#### Hub-and-Spoke Architecture

For enterprise deployments with multiple business units:

- **Hub workspace:** Central data engineering workspace with shared datasets, master data, and governance controls
- **Spoke workspaces:** Business-unit-specific workspaces consuming data from the hub via shortcuts or shared semantic models

#### Data Mesh

For highly decentralized organizations:

- Each domain team owns and publishes their data products
- OneLake shortcuts enable cross-domain data sharing without duplication
- Endorsement and data catalog features help consumers discover trusted data

### 1.3 Choosing the Right Compute

One of the most critical architectural decisions in Fabric is choosing between **Lakehouse**, **Warehouse**, and **Dataflow Gen2**.

#### Lakehouse vs. Warehouse vs. Dataflow Gen2

| Feature | Lakehouse | Warehouse | Dataflow Gen2 |
|---|---|---|---|
| **Storage Format** | Delta Lake (Parquet) | Delta Lake (Parquet) | N/A (processing engine) |
| **Query Language** | Spark (PySpark, SparkSQL, Scala, R) + T-SQL (via SQL analytics endpoint) | T-SQL | Power Query M |
| **Schema** | Schema-on-read (flexible) | Schema-on-write (enforced) | Schema defined in flow |
| **Best For** | Data engineering, big data, ML, unstructured/semi-structured data | Traditional data warehousing, complex SQL queries, stored procedures | Low-code/no-code ETL, simple transformations |
| **Write Support** | Full (Spark, APIs) | Full (T-SQL DML: INSERT, UPDATE, DELETE, MERGE) | Write to lakehouse or warehouse as destination |
| **Primary Persona** | Data Engineer, Data Scientist | Data Warehouse Developer, SQL Analyst | Citizen Integrator, Power BI Developer |
| **V-Order Optimization** | Yes | Yes | N/A |
| **Cross-database Queries** | Yes (via SQL analytics endpoint) | Yes (cross-database SQL) | No |

> **Exam Tip:** The Lakehouse has a **SQL analytics endpoint** that provides a read-only T-SQL interface over the Delta tables. You CANNOT write to a Lakehouse via T-SQL — writing requires Spark or APIs.

#### Decision Framework

```
Do you need to write data with T-SQL (INSERT/UPDATE/DELETE)?
  ├── YES → Use Warehouse
  └── NO
       ├── Do you need Spark for processing (PySpark, ML)?
       │    ├── YES → Use Lakehouse
       │    └── NO
       │         ├── Is it a simple, low-code transformation?
       │         │    ├── YES → Use Dataflow Gen2
       │         │    └── NO → Use Lakehouse or Warehouse
       └── Do you have unstructured/semi-structured data?
            ├── YES → Use Lakehouse (Files section)
            └── NO → Either works; consider team skills
```

### 1.4 Capacity Planning and SKU Selection

Fabric capacities are measured in **Capacity Units (CUs)**, which determine the compute power available for all workloads.

#### Fabric SKUs

| SKU | Capacity Units (CUs) | Power BI Equivalent | Max Memory per Query | Suitable For |
|---|---|---|---|---|
| F2 | 2 | — | 3 GB | Dev/Test, POC |
| F4 | 4 | — | 3 GB | Small teams |
| F8 | 8 | EM/A1 | 3 GB | Small workloads |
| F16 | 16 | EM2/A2 | 6 GB | Medium workloads |
| F32 | 32 | EM3/A3 | 6 GB | Department-level |
| F64 | 64 | P1/A4 | 25 GB | Enterprise |
| F128 | 128 | P2/A5 | 50 GB | Large enterprise |
| F256 | 256 | P3/A6 | 100 GB | Large enterprise |
| F512 | 512 | P4/A7 | 200 GB | Very large enterprise |
| F1024 | 1024 | P5/A8 | 400 GB | Mission-critical |
| F2048 | 2048 | — | 400 GB | Largest workloads |

> **Note:** Fabric Trial capacities provide an F64 equivalent for 60 days. Production workloads require a paid capacity.

#### Key Capacity Concepts

- **Bursting:** Fabric allows short-term bursting above your CU allocation, with throttling applied when sustained
- **Smoothing:** Fabric smooths compute usage over time windows to avoid sudden throttling
- **Throttling:** When capacity is consistently exceeded, interactive operations are delayed
- **Autoscale:** Can be configured to automatically add CUs during peak usage (additional cost)

> **Best Practice:** Start with a smaller SKU (F64) for development and scale up based on actual usage patterns observed in the Capacity Metrics app.

**Reference:** [Microsoft Fabric capacity and SKUs](https://learn.microsoft.com/en-us/fabric/enterprise/licenses)

---

## 2. Manage and Configure Workspaces and Environments

### 2.1 Creating and Configuring Workspaces

A **workspace** is the primary organizational unit in Fabric. It serves as a container for items and provides a collaboration boundary.

#### Creating a Workspace

1. Navigate to the Fabric portal (app.fabric.microsoft.com)
2. Click **Workspaces** in the left navigation pane
3. Click **+ New workspace**
4. Configure the following settings:
   - **Name:** Descriptive, following your organization's naming convention
   - **Description:** Purpose and contents of the workspace
   - **License mode:** Select the capacity (Trial, Premium, Fabric, or Embedded)
   - **Default storage format:** Typically leave as default (Delta/Parquet)
   - **Contact list:** Specify who to contact about the workspace
   - **OneLake data access:** Configure data access settings

> **Best Practice:** Adopt a consistent naming convention. Example:  
> `{BusinessUnit}_{Environment}_{Purpose}`  
> e.g., `Finance_Prod_DataWarehouse`, `Marketing_Dev_Analytics`

#### Workspace Types

| Type | Description | Use Case |
|---|---|---|
| **Personal workspace ("My workspace")** | Private workspace for each user | Individual exploration, personal reports |
| **Shared workspace** | Collaborative workspace assigned to a capacity | Team-based projects, production workloads |
| **Admin monitoring workspace** | Special system workspace for tenant-level monitoring | Tenant administrators monitoring usage |

> **Exam Tip:** "My workspace" does NOT support all Fabric features and should NOT be used for production workloads. Items in "My workspace" cannot be shared as easily and don't support workspace roles.

### 2.2 Workspace Settings and Properties

Key workspace settings to understand:

#### License / Capacity Assignment

- Each workspace must be assigned to a capacity to use Fabric features
- Workspaces on shared (Pro) capacity have limited features
- Fabric items (Lakehouse, Warehouse, etc.) require at minimum an F64 or equivalent capacity

#### Azure DevOps / Git Integration

- Connect the workspace to an Azure DevOps or GitHub repository
- Enables version control for workspace items
- Supports branching strategies for development workflows

#### Spark Settings (Workspace Level)

- Default Spark pool configuration
- Environment (libraries, Spark properties) for notebooks and Spark job definitions

#### Domain Assignment

- Associate a workspace with a Fabric domain for governance and discoverability
- Domains provide a logical grouping across workspaces for data mesh scenarios

### 2.3 Environment Configuration

**Environments** in Fabric define the runtime configuration for Spark-based items (notebooks, Spark job definitions).

#### What an Environment Contains

| Component | Description |
|---|---|
| **Public libraries** | PyPI or Conda packages to install |
| **Custom libraries** | Uploaded `.whl`, `.jar`, `.tar.gz` files |
| **Spark properties** | Configuration overrides (e.g., `spark.sql.shuffle.partitions`) |
| **Resources** | Uploaded data files accessible from Spark sessions |

#### Creating and Attaching an Environment

```python
# Example: Using a custom environment in a notebook
# 1. Create the environment in the workspace
# 2. Add required libraries (e.g., great_expectations, openpyxl)
# 3. Publish the environment
# 4. Attach the environment to the notebook via the notebook toolbar
```

Steps:
1. In the workspace, click **+ New** → **Environment**
2. Add public libraries (from PyPI/Conda) and/or upload custom libraries
3. Configure Spark properties as needed
4. Click **Publish** to build the environment
5. Attach the environment to a notebook or Spark job definition

> **Note:** After publishing, the environment build process takes a few minutes. Library conflicts are resolved during the publish step.

### 2.4 Spark Compute Configuration

Fabric Spark compute is managed through **Starter pools** and **Custom pools**.

#### Starter Pool (Default)

- Pre-warmed pool for quick session start
- Automatically allocated based on capacity SKU
- Suitable for most ad hoc and development scenarios
- Provides medium-sized nodes with a default node count

#### Custom Spark Pools

For more control over compute resources:

| Setting | Options |
|---|---|
| **Node family** | Memory Optimized |
| **Node size** | Small, Medium, Large, XLarge, XXLarge |
| **Autoscale** | Enable/disable, min and max nodes |
| **Dynamic allocation** | Enable/disable for Spark executors |

```
Workspace Settings → Data Engineering/Science → Spark Compute
├── Starter Pool (default, pre-warmed)
├── Custom Pool 1
│   ├── Node Size: Large
│   ├── Min Nodes: 1
│   ├── Max Nodes: 10
│   └── Autoscale: Enabled
└── Custom Pool 2
    ├── Node Size: Medium
    ├── Min Nodes: 2
    ├── Max Nodes: 5
    └── Autoscale: Enabled
```

> **Best Practice:** Use the Starter pool for development and exploration. Create custom pools for production workloads that need consistent, predictable performance.

### 2.5 Git Integration for Workspaces

Fabric supports Git integration for version control of workspace items.

#### Supported Source Control Providers

- **Azure DevOps (Azure Repos)**
- **GitHub**

#### How Git Integration Works

1. Connect the workspace to a Git repository (branch)
2. Fabric items are serialized into definition files within the repository
3. Changes can be committed from the workspace to the repo
4. Changes in the repo can be synced (pulled) to the workspace

#### Supported Items for Git Integration

Most Fabric items support Git integration, including:
- Notebooks
- Spark job definitions
- Lakehouses (metadata only, not data)
- Warehouses (metadata only, not data)
- Semantic models
- Reports
- Pipelines
- Dataflows Gen2

#### Branching Strategy Example

```
main (production)
  └── develop (staging/integration)
       ├── feature/add-sales-pipeline
       ├── feature/update-dim-customer
       └── bugfix/fix-date-transform
```

Each branch maps to a Fabric workspace:
- `main` → Production workspace
- `develop` → Staging workspace
- `feature/*` → Developer-specific workspaces

> **Exam Tip:** Git integration in Fabric tracks item **definitions** (metadata), not the actual data stored in OneLake. Data is not versioned through Git integration.

**Reference:** [Introduction to Git integration](https://learn.microsoft.com/en-us/fabric/cicd/git-integration/intro-to-git-integration)

---

## 3. Apply Governance, Security, and Compliance

### 3.1 Data Governance in Fabric

Data governance in Fabric ensures that data is managed, secured, and used appropriately across the organization.

#### Governance Pillars in Fabric

| Pillar | Description | Fabric Feature |
|---|---|---|
| **Discovery** | Find and understand data assets | Data hub, data catalog, endorsement |
| **Protection** | Classify and secure sensitive data | Sensitivity labels, DLP policies |
| **Compliance** | Meet regulatory requirements | Audit logs, Purview integration |
| **Lineage** | Track data flow and dependencies | Lineage view, impact analysis |
| **Quality** | Ensure data accuracy and consistency | Data profiling, validation rules |

#### Domains

Fabric **domains** provide a way to logically group workspaces by business area. They help implement data mesh concepts:

- Created by Fabric administrators
- Each workspace can be assigned to one domain
- Domain admins can manage workspaces within their domain
- Enables decentralized ownership while maintaining central oversight

```
Fabric Tenant
├── Domain: Finance
│   ├── Finance_Prod_Warehouse
│   ├── Finance_Dev_Lakehouse
│   └── Finance_Reports
├── Domain: Marketing
│   ├── Marketing_Analytics
│   └── Marketing_Campaigns
└── Domain: HR
    ├── HR_DataLake
    └── HR_Reports
```

### 3.2 Microsoft Purview Integration

Microsoft Fabric integrates with **Microsoft Purview** for advanced governance capabilities.

#### Key Integration Points

| Feature | Description |
|---|---|
| **Information protection** | Apply sensitivity labels from Microsoft Purview Information Protection to Fabric items |
| **Data Loss Prevention** | Configure DLP policies to detect sensitive data in Fabric items |
| **Data catalog** | Fabric items are automatically registered in the Purview data catalog |
| **Audit** | Fabric activities are captured in the unified audit log (accessible via Purview) |
| **Data lineage** | Purview can display lineage across Fabric and other data sources |

> **Note:** Microsoft Purview integration is configured at the tenant level by Fabric and Purview administrators. Individual workspace users leverage the features but don't set them up.

### 3.3 Information Protection and Sensitivity Labels

Sensitivity labels from Microsoft Purview Information Protection can be applied to Fabric items to classify and protect sensitive data.

#### How Sensitivity Labels Work in Fabric

1. **Labels are defined** in the Microsoft Purview compliance portal
2. **Labels are applied** to Fabric items (reports, datasets, lakehouses, etc.) manually or through automation
3. **Labels are inherited** — when data flows from one item to another, the label can propagate downstream
4. **Labels are enforced** — export controls, encryption, and visual markings are applied based on the label configuration

#### Label Inheritance Flow

```
Data Source (Labeled "Confidential")
  → Lakehouse (Inherits "Confidential")
    → Semantic Model (Inherits "Confidential")
      → Report (Inherits "Confidential")
        → Exported PDF (Encrypted per label policy)
```

#### Common Sensitivity Labels

| Label | Description | Typical Protection |
|---|---|---|
| **Public** | Non-sensitive data | No restrictions |
| **General** | Internal business data | Minimal restrictions |
| **Confidential** | Sensitive business data | Encryption, restricted sharing |
| **Highly Confidential** | Most sensitive data | Strong encryption, no external sharing |

> **Exam Tip:** Sensitivity labels in Fabric flow **downstream** through the data lineage. If a source lakehouse is labeled "Confidential," downstream reports inherit that label unless overridden with a MORE restrictive label.

### 3.4 Data Loss Prevention (DLP) Policies

DLP policies in Fabric help prevent accidental sharing of sensitive information.

#### Supported DLP Scenarios in Fabric

- Detect sensitive data types (e.g., Social Security numbers, credit card numbers) in **semantic models (datasets)**
- Detect sensitive data types in **Lakehouse tables** (preview)
- Generate policy tips warning users when sensitive data is detected
- Create alerts for administrators when DLP violations occur

#### DLP Policy Configuration

DLP policies for Fabric are configured in the **Microsoft Purview compliance portal**:

1. Navigate to **Data Loss Prevention** → **Policies**
2. Create a new policy or use a template
3. Select **Fabric** (and/or Power BI) as the location
4. Define sensitive information types to detect
5. Configure actions (policy tips, alerts, blocking)
6. Set notification preferences

> **Best Practice:** Start DLP policies in **audit-only mode** before enforcing them. This allows you to assess the impact without disrupting users.

### 3.5 Compliance and Regulatory Considerations

| Consideration | Fabric Capability |
|---|---|
| **Data residency** | Fabric capacity is deployed to a specific Azure region; OneLake data resides in that region |
| **Encryption at rest** | Enabled by default using Microsoft-managed keys |
| **Encryption in transit** | TLS 1.2+ for all communications |
| **Audit trail** | Unified audit logs capture all Fabric activities |
| **Access reviews** | Integration with Azure AD / Entra ID access reviews |
| **Conditional Access** | Entra ID Conditional Access policies apply to Fabric |
| **Certifications** | Fabric inherits Microsoft 365 and Azure compliance certifications (SOC 1/2, ISO 27001, HIPAA, GDPR, etc.) |

> **Note:** For highly regulated industries, verify that the specific compliance certifications required by your organization are supported by Fabric in your region.

**Reference:** [Governance and compliance in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/governance/governance-compliance-overview)

---

## 4. Workspace Roles and Permissions

### 4.1 Workspace Roles Overview

Fabric workspaces use a role-based access control (RBAC) model with four built-in roles.

#### The Four Workspace Roles

| Role | Description |
|---|---|
| **Admin** | Full control over the workspace, including managing membership, settings, and all items |
| **Member** | Can create, edit, and delete all items in the workspace. Cannot manage workspace settings or membership |
| **Contributor** | Can create, edit, and delete items in the workspace. Cannot publish or manage apps, or manage membership |
| **Viewer** | Can view and interact with all items but cannot create, edit, or delete anything |

### 4.2 Permissions Matrix

The following table details the permissions for each role:

| Permission | Admin | Member | Contributor | Viewer |
|---|---|---|---|---|
| **View workspace items** | ✅ | ✅ | ✅ | ✅ |
| **Read data** | ✅ | ✅ | ✅ | ✅ |
| **Connect to SQL analytics endpoint** | ✅ | ✅ | ✅ | ✅ |
| **Create items** | ✅ | ✅ | ✅ | ❌ |
| **Edit items** | ✅ | ✅ | ✅ | ❌ |
| **Delete items** | ✅ | ✅ | ✅ | ❌ |
| **Run notebooks and Spark jobs** | ✅ | ✅ | ✅ | ❌ |
| **Execute pipelines** | ✅ | ✅ | ✅ | ❌ |
| **Create and publish apps** | ✅ | ✅ | ❌ | ❌ |
| **Share items with others** | ✅ | ✅ | ❌ | ❌ |
| **Add Members/Contributors/Viewers** | ✅ | ✅ | ❌ | ❌ |
| **Update workspace metadata** | ✅ | ❌ | ❌ | ❌ |
| **Add/Remove Admins** | ✅ | ❌ | ❌ | ❌ |
| **Manage workspace settings** | ✅ | ❌ | ❌ | ❌ |
| **Configure Git integration** | ✅ | ❌ | ❌ | ❌ |
| **Delete workspace** | ✅ | ❌ | ❌ | ❌ |
| **Assign workspace to capacity** | ✅ | ❌ | ❌ | ❌ |
| **Manage workspace-level Spark settings** | ✅ | ❌ | ❌ | ❌ |

### 4.3 Best Practices for Role Assignment

1. **Principle of Least Privilege:** Assign the minimum role needed for each user or group
2. **Use Security Groups:** Assign roles to Entra ID (Azure AD) security groups rather than individual users
3. **Limit Admin access:** Only workspace owners and IT administrators should have the Admin role
4. **Viewers for consumers:** Report consumers should be assigned the Viewer role
5. **Contributors for developers:** Data engineers and developers who build items but don't manage the workspace should be Contributors
6. **Members for leads:** Team leads who need to share and publish content should be Members

> **Exam Tip:** A common exam question involves determining the minimum role needed for a specific task. Remember:  
> - Sharing items → **Member** (minimum)  
> - Creating items → **Contributor** (minimum)  
> - Managing workspace → **Admin** only

### 4.4 Service Principal Access

Service principals (app registrations in Entra ID) can be used for automated and programmatic access to Fabric workspaces.

#### Enabling Service Principal Access

1. **Tenant setting:** The Fabric admin must enable "Service principals can use Fabric APIs" in the tenant admin settings
2. **Workspace role:** Add the service principal (or its security group) to the workspace with the appropriate role
3. **API access:** The service principal authenticates via OAuth 2.0 client credentials flow

#### Common Service Principal Scenarios

| Scenario | Description |
|---|---|
| **Automated deployments** | CI/CD pipelines deploying Fabric items |
| **Scheduled data refresh** | Triggering data pipeline runs programmatically |
| **Embedding** | Embedding Fabric reports in custom applications |
| **Admin operations** | Tenant-level administration via REST APIs |

```python
# Example: Authenticating with a service principal
import msal

app = msal.ConfidentialClientApplication(
    client_id="<your-client-id>",
    client_credential="<your-client-secret>",
    authority="https://login.microsoftonline.com/<tenant-id>"
)

result = app.acquire_token_for_client(
    scopes=["https://api.fabric.microsoft.com/.default"]
)

access_token = result["access_token"]
```

> **Best Practice:** Use managed identities or certificate-based authentication for service principals instead of client secrets in production. Rotate secrets regularly if they must be used.

### 4.5 Item-Level Permissions

Beyond workspace roles, Fabric supports granular item-level permissions:

#### Sharing and Per-Item Permissions

| Permission | Description |
|---|---|
| **Read** | View the item and its data |
| **ReadAll** | Read all data via the SQL analytics endpoint or XMLA endpoint |
| **Write** | Edit the item |
| **Reshare** | Share the item with others |
| **Execute** | Run the item (for executable items like notebooks) |
| **Explore** | Access the Power BI semantic model for building reports |

#### OneLake Data Access Roles (Preview)

OneLake data access roles provide fine-grained access control at the folder level within a lakehouse:

- Define custom roles with read access to specific folders/tables
- Applied on top of workspace roles
- Enables column-level and row-level security concepts at the storage layer

**Reference:** [Workspace roles in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/get-started/roles-workspaces)

---

## 5. Monitoring and Auditing Usage

### 5.1 Monitoring Hub

The **Monitoring Hub** is the centralized place to track the status of activities across your Fabric workspace.

#### What the Monitoring Hub Shows

| Information | Description |
|---|---|
| **Activity name** | Name of the notebook, pipeline, Spark job, etc. |
| **Activity type** | Type of item being executed |
| **Status** | In progress, Completed, Failed, Cancelled |
| **Start time** | When the activity started |
| **Duration** | How long the activity has been running or total runtime |
| **Submitted by** | Who triggered the activity |
| **Location** | The workspace where the activity is running |

#### Accessing the Monitoring Hub

- Click **Monitoring Hub** in the left navigation pane of the Fabric portal
- Filter by item type, status, time range, and workspace
- Drill into individual activities for detailed run information

> **Note:** The Monitoring Hub shows activities for workspaces you have access to. It does NOT show tenant-wide activities — that requires the Admin monitoring workspace.

### 5.2 Admin Monitoring Workspace

The **Admin monitoring workspace** is a special system-generated workspace available to Fabric administrators.

#### Features

- Pre-built reports on tenant-wide Fabric usage
- Provides a semantic model with detailed activity data
- Includes data about:
  - Item inventory across all workspaces
  - User activities and access patterns
  - Feature usage statistics
  - Capacity utilization

#### Access Requirements

- Must be a **Fabric administrator** or **Global administrator** to access
- Cannot be modified or deleted by users
- Automatically created and maintained by the system

### 5.3 Capacity Metrics App

The **Microsoft Fabric Capacity Metrics App** is a dedicated Power BI app for monitoring capacity consumption.

#### Installation and Setup

1. Install from AppSource (search for "Microsoft Fabric Capacity Metrics")
2. Connect to your Fabric capacity
3. Configure scheduled refresh for ongoing monitoring

#### Key Metrics Available

| Metric | Description |
|---|---|
| **CU consumption** | Total Capacity Unit usage over time |
| **CU % utilization** | Percentage of available CUs being used |
| **Throttling** | Instances where operations were delayed due to overutilization |
| **Interactive vs. Background** | Breakdown of compute usage by operation type |
| **By item type** | CU consumption broken down by item (Lakehouse, Warehouse, Notebook, etc.) |
| **By workspace** | CU consumption per workspace |
| **By user** | Who is consuming the most capacity |
| **Overages** | Periods where usage exceeded capacity allocation |

#### Key Pages in the Capacity Metrics App

1. **Multi-metric ribbon chart:** Visualizes CU%, throttling, and overages over a 14-day window
2. **Timepoint detail table:** Drill into specific time windows to see which items are consuming capacity
3. **Throttling detail:** Understand when and why throttling occurred

> **Exam Tip:** The Capacity Metrics app uses a **30-second aggregation** to track CU consumption. Background operations (e.g., data refresh) are smoothed over a **24-hour window**, while interactive operations are evaluated over shorter windows.

### 5.4 Audit Logs and Activity Events

Fabric activities are tracked in the **Microsoft 365 unified audit log**, providing a comprehensive record of user and system actions.

#### Enabling Audit Logging

- Audit logging is enabled by default for Microsoft 365 tenants
- Fabric admin settings may need to be configured to ensure all activities are captured
- Logs are retained for 90 days (default) or up to 10 years (with advanced audit licenses)

#### Accessing Audit Logs

| Method | Description |
|---|---|
| **Microsoft Purview compliance portal** | Search and filter audit logs via the UI |
| **PowerShell** | Use `Search-UnifiedAuditLog` cmdlet |
| **REST API** | Office 365 Management Activity API |
| **Microsoft Sentinel** | Stream audit logs to Sentinel for SIEM integration |

#### Common Audited Activities

```
# Examples of audited Fabric activities:
- CreateWorkspace
- DeleteWorkspace
- AddWorkspaceMember
- RemoveWorkspaceMember
- CreateReport
- ViewReport
- ExportReport
- CreateLakehouse
- RunNotebook
- ExecutePipeline
- ShareItem
- ChangeSensitivityLabel
- UpdateCapacitySetting
```

> **Best Practice:** Set up automated alerts for critical activities like workspace deletion, permission changes, and data exports. Use Microsoft Sentinel or a SIEM solution for real-time monitoring.

#### PowerShell Example — Querying Audit Logs

```powershell
# Search for all Fabric activities in the last 7 days
Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -RecordType PowerBIAudit `
    -ResultSize 1000
```

### 5.5 Usage Metrics Reports

Usage metrics provide workspace-level insights into how reports and dashboards are being used.

#### Available Metrics

| Metric | Description |
|---|---|
| **Report views** | Number of times each report was viewed |
| **Unique viewers** | Number of distinct users who viewed reports |
| **View trend** | How report views change over time |
| **Distribution method** | How users accessed the report (direct, app, shared) |
| **Platform** | Device/browser breakdown |
| **Top users** | Most active consumers of workspace content |

> **Note:** Usage metrics are available to workspace Members and Admins. A pre-built "Usage metrics report" can be generated from any report's context menu.

**Reference:** [Monitor Fabric usage](https://learn.microsoft.com/en-us/fabric/admin/monitoring-hub)

---

## 6. Data Lineage and Impact Analysis

### 6.1 Lineage View in Fabric

The **Lineage view** provides a visual representation of how data flows through items within a workspace.

#### Accessing Lineage View

1. Open a workspace in the Fabric portal
2. Click **Lineage view** (icon in the top-right toolbar, next to list view and card view)
3. The visual shows all items and their dependencies

#### What Lineage View Shows

```
[Data Source] → [Dataflow Gen2] → [Lakehouse] → [Semantic Model] → [Report]
     │                                  │
     └──────→ [Warehouse] ─────────────┘
```

- **Upstream dependencies:** Where data comes from
- **Downstream dependencies:** What items depend on this data
- **External data sources:** Connections to sources outside Fabric
- **Data flow direction:** Visual arrows showing the flow of data

#### Key Features

| Feature | Description |
|---|---|
| **Visual dependency graph** | Interactive diagram showing relationships between items |
| **External source tracking** | Shows connections to external data sources (SQL Server, APIs, files, etc.) |
| **Cross-workspace lineage** | Displays dependencies across workspaces when items reference each other |
| **Drill-down** | Click on any item to see its specific upstream and downstream dependencies |

### 6.2 Impact Analysis

**Impact analysis** helps you understand the downstream effects of changing or deleting an item.

#### How Impact Analysis Works

1. Right-click any item in the workspace (or use the item's menu)
2. Select **Impact analysis**
3. View a summary showing:
   - Number of dependent workspaces
   - Number of dependent items
   - Approximate number of affected users (based on report view data)

#### Impact Analysis Summary Example

```
Changing: Sales_Lakehouse

Impact Summary:
├── 3 Dependent workspaces
├── 12 Dependent items
│   ├── 2 Semantic models
│   ├── 5 Reports
│   ├── 3 Dashboards
│   └── 2 Dataflows
├── ~45 Affected viewers (last 30 days)
└── Contact: data-engineering@contoso.com
```

> **Exam Tip:** Impact analysis uses **usage data** to estimate affected users. If a report was viewed by 45 people in the last 30 days, that's the estimated impact. Always run impact analysis BEFORE making breaking changes.

### 6.3 Data Catalog Capabilities

Fabric provides data discovery and catalog features through integration with OneLake and the data hub.

#### Data Hub

The **Data Hub** (accessible from the left navigation) allows users to:

- Browse available data items across workspaces they have access to
- Search for specific tables, lakehouses, warehouses, and semantic models
- Filter by endorsement status, sensitivity label, and item type
- View item details including description, owner, and last refresh time

#### OneLake Data Hub Features

| Feature | Description |
|---|---|
| **Search** | Full-text search across item names and descriptions |
| **Filter** | Filter by type, endorsement, workspace, and more |
| **Preview** | Preview table data directly from the hub |
| **Details** | View metadata, schema, description, endorsement status |
| **Quick actions** | Open items, create reports, or copy SQL connection strings |

### 6.4 Endorsement (Promoted and Certified)

Endorsement is a mechanism to help users identify trusted, high-quality data assets.

#### Endorsement Levels

| Level | Description | Who Can Apply |
|---|---|---|
| **None** | Default state — no endorsement | — |
| **Promoted** | Item is considered production-ready and valuable | Any workspace Member or Admin |
| **Certified** | Item has been reviewed and meets organizational quality standards | Only users authorized by the Fabric admin (configured in tenant settings) |

#### How to Endorse an Item

1. Open the item settings
2. Navigate to the **Endorsement** section
3. Select **Promoted** or **Certified** (if authorized)
4. Optionally add a description explaining the endorsement

#### Endorsement Best Practices

- **Promoted:** Use for items that are ready for broader consumption but haven't gone through formal review
- **Certified:** Reserve for items that have been validated, documented, and approved by a data steward or governance team
- Define a clear certification process in your organization
- Limit who can certify items (configured in Fabric admin settings under Endorsement)

> **Best Practice:** Encourage users to search for **Certified** items first when looking for data. This helps prevent users from building reports on unvalidated or test data.

#### Visual Indicators

Endorsed items display badges throughout the Fabric portal:

- 🏷️ **Promoted:** Blue badge with an up-arrow icon
- ✅ **Certified:** Orange badge with a checkmark icon

These badges appear in:
- Workspace list view
- Data Hub search results
- Lineage view
- Get Data dialogs in Power BI

**Reference:** [Endorsement in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/governance/endorsement-overview)

---

## 7. Managing Capacity and Resource Allocation

### 7.1 Fabric Capacity Concepts

Understanding how Fabric capacity works is essential for managing costs and performance.

#### Capacity Units (CUs)

- The fundamental unit of compute in Fabric
- All workloads (Spark, SQL, Power BI, pipelines, etc.) consume CUs
- CU consumption is measured per second
- Different operations consume different amounts of CUs

#### How CU Consumption Works

```
┌─────────────────────────────────────────────────┐
│              Fabric Capacity (F64)               │
│              64 CU available                     │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Lakehouse │  │ Warehouse│  │ Power BI │      │
│  │  Spark    │  │  T-SQL   │  │ Queries  │      │
│  │  20 CU    │  │  15 CU   │  │  8 CU    │      │
│  └──────────┘  └──────────┘  └──────────┘      │
│                                                  │
│  Total: 43 CU / 64 CU = 67% utilization        │
└─────────────────────────────────────────────────┘
```

#### Operation Types and Throttling

Fabric classifies operations into two categories:

| Type | Description | Smoothing Window | Throttling Behavior |
|---|---|---|---|
| **Interactive** | User-initiated queries, report views, ad hoc notebook runs | 5 minutes | Delayed when capacity is exceeded |
| **Background** | Scheduled refreshes, Spark jobs, pipeline runs | 24 hours | Queued and delayed; may be rejected at extreme overload |

#### Throttling Stages

| Stage | CU Usage | Effect |
|---|---|---|
| **No throttling** | 0–100% of CU allocation | Normal operation |
| **Smoothing** | Temporary bursts above 100% | Operations proceed normally; usage is smoothed over time |
| **Interactive delay** | Sustained overuse (>100%) | Interactive operations experience increasing delays (10s, 20s, 40s, etc.) |
| **Background rejection** | Extreme sustained overuse | Background operations may be rejected; interactive operations heavily delayed |

> **Exam Tip:** Fabric uses **background smoothing** over a 24-hour window. This means a large Spark job that consumes many CUs can be spread across the day without causing immediate throttling. Interactive operations, however, are evaluated in shorter windows and will throttle sooner.

### 7.2 Capacity Settings and Management

#### Capacity Administration

Capacity can be managed from multiple places:

| Location | Capabilities |
|---|---|
| **Azure portal** | Create, resize, pause/resume Fabric capacities |
| **Fabric Admin portal** | Assign workspaces, manage tenant settings, delegate capacity |
| **Fabric Admin APIs** | Programmatic capacity management |

#### Key Capacity Settings

| Setting | Description |
|---|---|
| **Region** | Azure region where the capacity is deployed (affects data residency and latency) |
| **SKU / Size** | The CU allocation (F2 through F2048) |
| **Capacity admins** | Users who can manage the capacity |
| **Workspace assignment** | Which workspaces use this capacity |
| **Notifications** | Alert thresholds for capacity utilization |
| **Autoscale** | Automatic scaling configuration |

#### Pausing and Resuming Capacity

One major cost optimization feature is the ability to **pause** Fabric capacity:

- When paused, no CU charges are incurred
- Data in OneLake is retained (storage charges still apply)
- Running operations will fail when capacity is paused
- Useful for development/test capacities that are only needed during business hours

```bash
# Azure CLI example: Pause a Fabric capacity
az fabric capacity suspend \
    --resource-group "rg-fabric" \
    --capacity-name "fabriccapacity01"

# Resume a Fabric capacity
az fabric capacity resume \
    --resource-group "rg-fabric" \
    --capacity-name "fabriccapacity01"
```

### 7.3 Auto-Scale Configuration

Autoscale allows Fabric to automatically add CUs when demand exceeds the base capacity.

#### How Autoscale Works

1. You configure a maximum number of additional CUs
2. When utilization exceeds 100% of base capacity, Fabric adds CUs in increments
3. Autoscaled CUs are billed separately at a per-CU, per-second rate
4. When demand decreases, the additional CUs are released

#### Configuration

| Parameter | Description |
|---|---|
| **Enable autoscale** | Toggle on/off |
| **Max CU add-on** | Maximum number of CUs that can be automatically added |
| **Notification threshold** | CU% at which to notify administrators |

> **Note:** Autoscale is designed for handling temporary peaks, not sustained growth. If you consistently need more CUs, consider upgrading your base SKU instead.

### 7.4 Cost Optimization Strategies

#### Strategy 1: Right-Size Your Capacity

- Start with a smaller SKU and monitor usage with the Capacity Metrics app
- Upgrade only when you observe consistent throttling or performance issues
- Consider separate capacities for Dev/Test (smaller, can be paused) and Production (larger, always on)

#### Strategy 2: Schedule Capacity Pause/Resume

For non-production environments:

```python
# Example: Azure Automation runbook to pause capacity at night
# Schedule: Every day at 7:00 PM

# Pause at 7 PM
az fabric capacity suspend --resource-group "rg-fabric" --capacity-name "dev-capacity"

# Resume at 7 AM (separate runbook)
az fabric capacity resume --resource-group "rg-fabric" --capacity-name "dev-capacity"
```

#### Strategy 3: Optimize Workloads

| Technique | Benefit |
|---|---|
| **V-Order optimization** | Faster reads with optimized Parquet files (enabled by default) |
| **Partition pruning** | Query only relevant partitions to reduce CU consumption |
| **Incremental refresh** | Refresh only new/changed data instead of full refresh |
| **Query folding** | Push transformations to the source to reduce Fabric compute |
| **Caching** | Use Power BI import mode or aggregations to reduce query load |

#### Strategy 4: Workspace-to-Capacity Mapping

| Workspace Type | Recommended Capacity |
|---|---|
| Development/Sandbox | Shared (smaller SKU, can be paused) |
| Testing/QA | Shared (smaller SKU, can be paused) |
| Production Analytics | Dedicated (appropriately sized, always on) |
| Ad hoc / Exploration | Trial or shared capacity |

#### Strategy 5: Monitor and Govern

- **Set up alerts** for capacity utilization thresholds (e.g., 80% sustained usage)
- **Review** Capacity Metrics app weekly
- **Implement chargeback** — use workspace-level CU tracking to allocate costs to business units
- **Audit unused items** — identify and remove unused lakehouses, warehouses, and reports to free capacity

> **Exam Tip:** Cost optimization questions on the exam often focus on choosing the right SKU, pausing non-production capacity, and optimizing workload patterns. Know the difference between interactive and background smoothing windows.

**Reference:** [Microsoft Fabric capacity management](https://learn.microsoft.com/en-us/fabric/enterprise/licenses)

---

## Quick Review — Key Concepts Summary

| Concept | Key Takeaway |
|---|---|
| **OneLake** | Single, unified data lake per tenant; all Fabric items store data here |
| **Workspace** | Organizational container for Fabric items; has its own role-based access |
| **Capacity** | Compute pool measured in CUs; determines performance and cost |
| **Lakehouse** | Schema-on-read, Spark + SQL analytics endpoint (read-only T-SQL) |
| **Warehouse** | Schema-on-write, full T-SQL DML support |
| **Sensitivity labels** | Flow downstream through lineage; enforce data protection |
| **Endorsement** | Promoted (self-serve) and Certified (admin-controlled) |
| **Monitoring Hub** | Per-user activity tracking within accessible workspaces |
| **Capacity Metrics App** | Detailed CU consumption and throttling analysis |
| **Git integration** | Version control for item definitions (NOT data) |
| **DLP policies** | Detect sensitive data in semantic models and lakehouses |
| **Lineage view** | Visual graph of data dependencies within a workspace |
| **Impact analysis** | Downstream dependency and user impact assessment |
| **Throttling** | Occurs when CU usage exceeds capacity; background ops smoothed over 24h |

---

## Exam Preparation Tips for Domain 1

1. **Understand the role boundaries:** Know exactly what each workspace role (Admin, Member, Contributor, Viewer) can and cannot do. Expect at least one question on minimum required role.

2. **Know Lakehouse vs. Warehouse:** The key differentiator is T-SQL write support. Lakehouse SQL analytics endpoint is **read-only**.

3. **Capacity and throttling:** Understand that background operations are smoothed over 24 hours and interactive over shorter windows. Autoscale handles peaks; base SKU handles baseline.

4. **Sensitivity labels flow downstream:** If a lakehouse is labeled "Confidential," downstream semantic models and reports inherit that label.

5. **Git integration tracks metadata, not data:** Item definitions are version-controlled; the actual data in OneLake is not stored in Git.

6. **OneLake shortcuts don't copy data:** They reference external data in place. This is critical for data mesh and cross-workspace scenarios.

7. **Service principals need tenant admin enablement:** The Fabric tenant admin must explicitly allow service principals to use Fabric APIs.

8. **Impact analysis shows user impact:** It uses historical usage data (last 30 days) to estimate how many users would be affected by a change.

---

## Additional Resources

- [Microsoft Fabric documentation](https://learn.microsoft.com/en-us/fabric/)
- [Microsoft Fabric capacity and licenses](https://learn.microsoft.com/en-us/fabric/enterprise/licenses)
- [Workspace roles in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/get-started/roles-workspaces)
- [Git integration in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/cicd/git-integration/intro-to-git-integration)
- [Governance and compliance in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/governance/governance-compliance-overview)
- [Endorsement in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/governance/endorsement-overview)
- [Microsoft Fabric Monitoring Hub](https://learn.microsoft.com/en-us/fabric/admin/monitoring-hub)
- [OneLake overview](https://learn.microsoft.com/en-us/fabric/onelake/onelake-overview)
- [Data Loss Prevention in Fabric](https://learn.microsoft.com/en-us/fabric/governance/data-loss-prevention-overview)

---

*Last updated: 2025*
