# A-Modern-Data-Warehouse-sql

**End-to-End Data Warehouse Project** implementing a Medallion-inspired architecture, ETL pipeline, data quality validation, and a Kimball dimensional model using Microsoft SQL Server.

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-025E8C?style=for-the-badge)
![ETL](https://img.shields.io/badge/ETL_Pipeline-blue?style=for-the-badge)
![Data Warehouse](https://img.shields.io/badge/Data_Warehouse-green?style=for-the-badge)
![Star Schema](https://img.shields.io/badge/Star_Schema-orange?style=for-the-badge)
![Kimball](https://img.shields.io/badge/Kimball_Dimensional_Model-purple?style=for-the-badge)

---

## Project Overview

Olist, a Brazilian e-commerce marketplace, generates transactional data spread across multiple disconnected CSV extracts — orders, customers, sellers, payments, and reviews — making cross-functional reporting slow and error-prone. This project builds a centralized **Data Warehouse (`Olist_DWH`)** on SQL Server that ingests, cleans, and models this raw data into a Kimball-style **Star Schema**. The result is a single source of truth that supports fast, scalable analytical queries for sales performance, customer behavior, and seller performance — ready to plug into any BI tool (Power BI, Tableau, etc.) without further transformation.

**Key goals of this project:**
- Design a full-cycle DWH: ingestion → cleaning → dimensional modeling
- Apply Kimball-style star schema modeling to a real, messy, multi-table dataset
- Build in data quality checks at each layer rather than assuming clean data
- Handle several common real-world challenges in data projects: clean up messy data, deduplication, granularity, etc.
- SQL development best practices

---

## Key Features

✔ End-to-End ETL Pipeline

✔ Medallion-inspired Data Warehouse Architecture

✔ Kimball Star Schema

✔ SQL Server & T-SQL

✔ Data Cleaning & Transformation

✔ Data Quality Validation

✔ Fact & Dimension Modeling

✔ Business-Ready Analytics Layer

---

## Architecture & Data Pipeline

The pipeline follows a three-layer Medallion architecture, renamed to keep the project's own terminology:

| Medallion term | This project's term | Purpose |
|---|---|---|
| Bronze | **Source Layer** | Raw data, loaded as-is from source (full load, batch) |
| Silver | **Stage Layer** | Cleaned, standardized, type-corrected, per-table |
| Gold | **Final Layer** | Integrated, dimensionally modeled (star schema) for reporting |


### Data Warehouse Architecture (DWH Arch)
The high-level system architecture illustrates the key characteristics of each layer and how data moves between layers.

![DWH Architecture](Images/DWH_Architecture.jpg)

---

### Data Flow Diagram (DFD)
A detailed data flow diagram indicating the exact flow of a data table between layers.

![Data Flow Diagram](Images/Data_Flow_Diagram.jpg)

### ETL Process

#### 1. Source Layer
Raw CSV data is loaded directly into SQL Server tables that mirror the original dataset schema, with no cleaning applied. This preserves an unmodified reference point and supports re-processing if downstream logic needs revision.

#### 2. Stage Layer
Each source table is individually cleaned and transformed, including:
- Data type correction
- Null and blank value handling
- Deduplication where applicable
- Standardizing categorical values
- Date validation

Every staged table has a **dedicated quality-check script** that validates null rates, duplicate primary keys, and referential integrity before it's trusted for integration.

#### 3. Final Layer
Cleaned Stage tables are integrated and modeled into a **star schema**:
- Four dimension tables (`Dim_Date`, `Dim_Product`, `Dim_Seller`, `Dim_Customer`) are loaded directly from their
  corresponding stage tables.
- One fact table (`Fact_Order_Items`) integrates four stage tables (`order_items`, `orders`, `order_payments`, `order_reviews`) into a single, business-ready table for analysis.

---

## Data Modeling (Kimball Star Schema)

This warehouse is modeled using **Ralph Kimball's dimensional modeling methodology**, implemented as a **Star Schema** in the Final layer.

### Fact Tables

- `Fact_Order_Items` — Order-item level transactional metrics (price, freight-value, payment_value_allocated)

### Dimension Tables

- `dim_customers` — Customer profile and location attributes
- `dim_sellers` — Seller profile and location attributes
- `dim_products` — Product category, dimensions, and attributes
- `dim_date` — Standard calendar/date dimension for time-based analysis

### Design Decisions

- Adopted **surrogate keys** for all dimension tables to decouple the warehouse from source system keys
- Applied **Type 1 SCD** for most dimensions (overwrite on change), given reporting needs prioritize current-state analysis.
- The grain of the primary fact table is defined at the **order item level, not the order level**
- Naming conventions follow `fact_*` and `dim_*` prefixes for immediate schema readability.

#### Key decision points to remember

**1. Fact table grain is order-item, not order.**
Order-grain was considered as an alternative (it would make `payment_value` and `review_score` natively correct, with no allocation needed). It was rejected because `Dim_Product` and `Dim_Seller` require item-level grain — an order can span multiple products and sellers, and order-level grain would make product/seller-level analysis impossible without introducing a bridge table. Item-level grain was chosen to preserve this analytical capability.

**2. `review_score_avg` in the fact table is an order-level measure repeated across item rows.**
Olist records one review per *order*, not per item. This column carries the same value for every item in that order.
Do not `SUM()` this column — it will overcount for multi-item orders; instead, use `AVG()`, or aggregate at the order level first.

**3. `payment_value_allocated` in the fact table is an order-level measure proportionally allocated to items.**
Payments are recorded per *order* in the source data, not per item. This column splits the order's total payment across its items, proportional to each item's share of the order's total price:

```
item_allocated_payment = order_total_payment × (item_price ÷ order_total_price)
```                                                      
---

## Tech Stack

| Tool | Role in Project |
|------|------------------|
| **SQL Server** | Core data warehouse platform (`Olist_DWH`) hosting all Source/Stage/Final layers |
| **T-SQL** | Data cleansing, transformation logic, and star schema build scripts |
| **SQL Server Management Studio (SSMS)** | Primary IDE for database development, query testing, and administration |
| **Python** | Messy Source data extraction and initial cleaning |

---

## Project Structure

```
A-Modern-Data-Warehouse/
│
├── Dataset                                                      # Store source CSV files (Olist dataset)
│     
├── Documentation                                                # Store all project documentation
│     
├── Images                                                       # Store screenshots or images related to the project
│ 
├── scripts/ 
│   ├── Source_Layer/
│   │   └── Source_Layer_DDL_And_Load.sql                        # Source Layer DDL and Load script
│   │ 
│   ├── Stage_Layer/
│   │   └── Stage_Layer_DDL.sql                                  # Stage Layer DDL script
│   │   └── Stage_Layer_CleanAndTransform.sql                    # Stage Layer ETL script
│   │ 
│   ├── Final_Layer/
│   │   └── Final_Layer_DDL.sql                                  # Final Layer DDL script
│   │   └── Final_Layer_CleanAndTransform.sql                    # Final Layer ETL script
│   │                                                    
│   ├── QualityCheck_or_Test/
│       └── QualityCheck_in_Stage_Layer                          # Stage Layer Quality Check script
│       └── QualityCheck_in_Final_Layer                          # Final Layer Quality Check script
│
├── README.md
│
```
---

## How to Run / Getting Started

### Prerequisites

- SQL Server (2019+)
- SQL Server Management Studio (SSMS) / Visual Studio Code
- Olist E-commerce dataset (download from [Kaggle](https://www.kaggle.com/) or place under `Dataset/`)

### 1. Clone the Repository

```bash
git clone https://github.com/ihossain025/modern-data-warehouse-sql.git
cd modern-data-warehouse-sql
```

### 2. Create the Database, Schemas, and Load Data into the Source Layer

```sql
-- Scripts/Source_Layer/Source_Layer_DDL_And_Load.sql 
```

### 3. Clean, Transform, and Load Source Layer Data into Stage Layer

```sql
Scripts/Stage_Layer/Stage_Layer_DDL.sql
Scripts/Stage_Layer/Stage_Layer_CleanAndTransform.sql
```

### 4. Clean, Transform, and Load Stage Layer Data into Final Layer

```sql
Scripts/Final_Layer/Final_Layer_DDL.sql
Scripts/Final_Layer/Final_Layer_CleanAndTransform.sql
```

### 5. Verify the Warehouse

```sql
SELECT TOP 100 * FROM Olist_DWH.Final_Layer.Fact_Order_Items;
SELECT TOP 100 * FROM Olist_DWH.Final_Layer.Dim_Customers;
```

You're now ready to connect a BI tool of your choice to `Olist_DWH` and start building dashboards.

---

## Future Improvements

- Implement incremental ETL loading
- Add Slowly Changing Dimensions (SCD Type 2)
- Automate pipeline scheduling
- Integrate Power BI dashboards
- Implement indexing and performance tuning
- Containerize the solution using Docker

---

## 👤 Author

**Md. Iqbal Hossain**

Business & Data Analyst | Data Engineer | BI Analyst | Technical Consultant

---

