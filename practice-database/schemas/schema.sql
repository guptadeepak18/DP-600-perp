-- ============================================================================
-- Contoso Retail Analytics — Dimensional Model Schema
-- ============================================================================
-- Target: Microsoft Fabric Warehouse (also compatible with SQL Server 2019+)
--
-- This schema implements a star-schema dimensional model for a fictional
-- retail company. It is designed for DP-600 exam practice and covers
-- fact tables, dimension tables, and Fabric-compatible data types.
-- ============================================================================

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DimDate: Calendar dimension for time-based analysis.
-- Grain: One row per calendar date.
-- ----------------------------------------------------------------------------
CREATE TABLE DimDate (
    DateKey              INT            NOT NULL,   -- Surrogate key in YYYYMMDD format
    FullDate             DATE           NOT NULL,   -- Actual calendar date
    DayOfWeek            TINYINT        NOT NULL,   -- 1 (Sunday) through 7 (Saturday)
    DayName              VARCHAR(10)    NOT NULL,   -- e.g. 'Monday'
    DayOfMonth           TINYINT        NOT NULL,   -- 1–31
    DayOfYear            SMALLINT       NOT NULL,   -- 1–366
    WeekOfYear           TINYINT        NOT NULL,   -- 1–53
    MonthNumber          TINYINT        NOT NULL,   -- 1–12
    MonthName            VARCHAR(10)    NOT NULL,   -- e.g. 'January'
    Quarter              TINYINT        NOT NULL,   -- 1–4
    QuarterName          VARCHAR(2)     NOT NULL,   -- e.g. 'Q1'
    Year                 SMALLINT       NOT NULL,   -- e.g. 2024
    IsWeekend            BIT            NOT NULL,   -- 1 if Saturday or Sunday
    IsHoliday            BIT            NOT NULL,   -- 1 if public holiday
    FiscalMonth          TINYINT        NOT NULL,   -- Fiscal month (July = 1)
    FiscalQuarter        TINYINT        NOT NULL,   -- Fiscal quarter
    FiscalYear           SMALLINT       NOT NULL,   -- Fiscal year

    CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);

-- ----------------------------------------------------------------------------
-- DimCustomer: Customer dimension for customer analytics.
-- Grain: One row per customer.
-- ----------------------------------------------------------------------------
CREATE TABLE DimCustomer (
    CustomerKey          INT            NOT NULL,   -- Surrogate key
    CustomerID           VARCHAR(20)    NOT NULL,   -- Business/natural key
    FirstName            VARCHAR(50)    NOT NULL,
    LastName             VARCHAR(50)    NOT NULL,
    Email                VARCHAR(100)   NULL,
    Phone                VARCHAR(20)    NULL,
    Gender               VARCHAR(10)    NULL,       -- 'Male', 'Female', 'Non-Binary'
    BirthDate            DATE           NULL,
    City                 VARCHAR(50)    NULL,
    StateProvince        VARCHAR(50)    NULL,
    Country              VARCHAR(50)    NOT NULL,
    PostalCode           VARCHAR(15)    NULL,
    MembershipTier       VARCHAR(20)    NOT NULL,   -- 'Bronze', 'Silver', 'Gold', 'Platinum'
    AccountCreatedDate   DATE           NOT NULL,
    IsActive             BIT            NOT NULL,

    CONSTRAINT PK_DimCustomer PRIMARY KEY (CustomerKey)
);

-- ----------------------------------------------------------------------------
-- DimProduct: Product dimension for product-level analysis.
-- Grain: One row per product.
-- ----------------------------------------------------------------------------
CREATE TABLE DimProduct (
    ProductKey           INT            NOT NULL,   -- Surrogate key
    ProductID            VARCHAR(20)    NOT NULL,   -- Business/natural key (SKU)
    ProductName          VARCHAR(100)   NOT NULL,
    Category             VARCHAR(50)    NOT NULL,   -- e.g. 'Electronics', 'Clothing'
    Subcategory          VARCHAR(50)    NOT NULL,   -- e.g. 'Laptops', 'Shirts'
    Brand                VARCHAR(50)    NOT NULL,
    UnitCost             DECIMAL(10,2)  NOT NULL,   -- Wholesale cost
    UnitPrice            DECIMAL(10,2)  NOT NULL,   -- Retail selling price
    Weight               DECIMAL(8,2)   NULL,       -- Weight in kg
    Color                VARCHAR(30)    NULL,
    Size                 VARCHAR(20)    NULL,        -- e.g. 'S', 'M', 'L', '15-inch'
    IsDiscontinued       BIT            NOT NULL,
    LaunchDate           DATE           NOT NULL,

    CONSTRAINT PK_DimProduct PRIMARY KEY (ProductKey)
);

-- ----------------------------------------------------------------------------
-- DimStore: Store / location dimension.
-- Grain: One row per store location.
-- ----------------------------------------------------------------------------
CREATE TABLE DimStore (
    StoreKey             INT            NOT NULL,   -- Surrogate key
    StoreID              VARCHAR(10)    NOT NULL,   -- Business key
    StoreName            VARCHAR(100)   NOT NULL,
    StoreType            VARCHAR(30)    NOT NULL,   -- 'Retail', 'Outlet', 'Online'
    City                 VARCHAR(50)    NOT NULL,
    StateProvince        VARCHAR(50)    NOT NULL,
    Country              VARCHAR(50)    NOT NULL,
    PostalCode           VARCHAR(15)    NULL,
    Region               VARCHAR(30)    NOT NULL,   -- e.g. 'West', 'East', 'Central'
    SquareFootage        INT            NULL,
    OpenDate             DATE           NOT NULL,
    ManagerName          VARCHAR(100)   NULL,
    IsActive             BIT            NOT NULL,

    CONSTRAINT PK_DimStore PRIMARY KEY (StoreKey)
);

-- ----------------------------------------------------------------------------
-- DimPromotion: Promotion / campaign dimension.
-- Grain: One row per promotion.
-- ----------------------------------------------------------------------------
CREATE TABLE DimPromotion (
    PromotionKey         INT            NOT NULL,   -- Surrogate key
    PromotionID          VARCHAR(20)    NOT NULL,   -- Business key
    PromotionName        VARCHAR(100)   NOT NULL,
    PromotionType        VARCHAR(30)    NOT NULL,   -- 'Discount', 'BOGO', 'Bundle', 'Clearance'
    DiscountPercent      DECIMAL(5,2)   NOT NULL,   -- e.g. 10.00 for 10%
    StartDate            DATE           NOT NULL,
    EndDate              DATE           NOT NULL,
    IsActive             BIT            NOT NULL,

    CONSTRAINT PK_DimPromotion PRIMARY KEY (PromotionKey)
);

-- ============================================================================
-- FACT TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FactSales: Sales transactions fact table.
-- Grain: One row per line item in a sales transaction.
-- ----------------------------------------------------------------------------
CREATE TABLE FactSales (
    SalesKey             BIGINT         NOT NULL,   -- Surrogate key
    OrderID              VARCHAR(20)    NOT NULL,   -- Business key for the order
    LineItemNumber       TINYINT        NOT NULL,   -- Line number within the order
    DateKey              INT            NOT NULL,   -- FK to DimDate
    CustomerKey          INT            NOT NULL,   -- FK to DimCustomer
    ProductKey           INT            NOT NULL,   -- FK to DimProduct
    StoreKey             INT            NOT NULL,   -- FK to DimStore
    PromotionKey         INT            NOT NULL,   -- FK to DimPromotion (0 = no promo)
    Quantity             INT            NOT NULL,
    UnitPrice            DECIMAL(10,2)  NOT NULL,
    UnitCost             DECIMAL(10,2)  NOT NULL,
    DiscountAmount       DECIMAL(10,2)  NOT NULL,   -- Dollar discount applied
    SalesAmount          DECIMAL(12,2)  NOT NULL,   -- Quantity * UnitPrice - DiscountAmount
    CostAmount           DECIMAL(12,2)  NOT NULL,   -- Quantity * UnitCost
    ProfitAmount         DECIMAL(12,2)  NOT NULL,   -- SalesAmount - CostAmount
    OrderDate            DATE           NOT NULL,
    ShipDate             DATE           NULL,
    DeliveryDate         DATE           NULL,
    OrderStatus          VARCHAR(20)    NOT NULL,   -- 'Completed', 'Shipped', 'Returned'
    PaymentMethod        VARCHAR(20)    NOT NULL,   -- 'Credit Card', 'Debit', 'Cash', 'Online'
    CreatedAt            DATETIME2(3)   NOT NULL,

    CONSTRAINT PK_FactSales PRIMARY KEY (SalesKey)
);

-- ----------------------------------------------------------------------------
-- FactInventory: Daily inventory snapshot fact table.
-- Grain: One row per product per store per day.
-- ----------------------------------------------------------------------------
CREATE TABLE FactInventory (
    InventoryKey         BIGINT         NOT NULL,   -- Surrogate key
    DateKey              INT            NOT NULL,   -- FK to DimDate
    ProductKey           INT            NOT NULL,   -- FK to DimProduct
    StoreKey             INT            NOT NULL,   -- FK to DimStore
    QuantityOnHand       INT            NOT NULL,   -- Current stock level
    QuantityOnOrder      INT            NOT NULL,   -- Ordered but not received
    ReorderPoint         INT            NOT NULL,   -- Minimum stock before reorder
    SafetyStockLevel     INT            NOT NULL,
    DaysOfSupply         DECIMAL(6,1)   NULL,       -- Estimated days before stockout
    SnapshotDate         DATE           NOT NULL,
    CreatedAt            DATETIME2(3)   NOT NULL,

    CONSTRAINT PK_FactInventory PRIMARY KEY (InventoryKey)
);
