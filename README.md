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
