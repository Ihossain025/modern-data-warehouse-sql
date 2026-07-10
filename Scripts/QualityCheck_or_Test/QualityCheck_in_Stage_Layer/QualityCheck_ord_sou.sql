
--==========================================================================
-- Quality Check of a 'source_ord' table before cleaning and transformation
--==========================================================================

-- -- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [order_id_sou]
      ,[customer_id_sou]
      ,[order_status_sou]
      ,[order_purchase_timestamp_sou]
      ,[order_approved_at_sou]
      ,[order_delivered_carier_date_sou]
      ,[order_delivered_customer_date_sou]
      ,[order_estimated_delivery_date_sou]
  FROM [Olist_DWH].[Source_Layer].[source_ord]


 /* 
 -- At a first glance, we see that our primary key column ('order_id_sou') value starts and ends with double quote ('"').
 -- Check whether this double quote ('"') exists in every row. If not we must remove them.
 -- It's better to remove them anyway because may be other tables will not have in every row for key columns
 -- Otherwise, our join will break.
 */

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN order_id_sou LIKE '"%"' THEN 1 
        ELSE 0 
    END) AS rows_with_quotes,
    CASE 
        WHEN COUNT(*) = SUM(CASE WHEN order_id_sou LIKE '"%"' THEN 1 ELSE 0 END) 
        THEN 'YES - Every row has quotes. Safe to keep.'
        ELSE 'NO - Mixed data found! We must clean them.'
    END AS final_verdict
FROM Olist_DWH.Source_Layer.source_ord;

-- -- Note: Not every row has this double quote. So, we must remove them

-- Check whether primary key ('order_id_sou' Column) is unique / has duplicates / has Null
-- Expected Output: No Result

SELECT
	REPLACE(TRIM(order_id_sou),'"','') AS order_id_sou,
	COUNT(*) AS Row_Count
FROM [Olist_DWH].[Source_Layer].[source_ord]
GROUP BY REPLACE(TRIM(order_id_sou),'"','')
HAVING COUNT(*) > 1 OR REPLACE(TRIM(order_id_sou),'"','') IS NULL

-- Note: No duplicate or null values in primary key column. Looks good!

-- Check whether a 'Null' values exist in columns which defined as 'NOT NULL' in DDL

SELECT
*
FROM [Olist_DWH].[Source_Layer].[source_ord]
WHERE 
	customer_id_sou IS NULL
 OR order_status_sou IS NULL
 OR	order_purchase_timestamp_sou IS NULL
	 
-- Note: No Null values exist in columns defined with 'NOT NULL'. Looks good!


-- Check for unwanted spaces in string columns
-- Expected Output: No Result

-- Check in 'order_status_sou' / 'customer_id_sou' / 'order_id_sou' columns

SELECT
order_status_sou
FROM Olist_DWH.Source_Layer.source_ord
WHERE order_status_sou != TRIM(order_status_sou) -- change the column name here

-- Note: No leading or trailing spaces in the column. Looks Good!

-- Check the distinct values for 'order_status_sou'

SELECT DISTINCT 
order_status_sou
FROM Olist_DWH.Source_Layer.source_ord;


-- We have several date columns in this table. Let's check the validity of our date columns. 
-- Validity Criteria / Formula: order_purchase_timestamp_sou <= order_approved_at_sou <= order_delivered_carier_date_sou <= order_delivered_customer_date_sou

WITH Date_Validity_Check AS (
SELECT 
    order_purchase_timestamp_sou,
    order_approved_at_sou,
    order_delivered_carier_date_sou,
    order_delivered_customer_date_sou,
    order_estimated_delivery_date_sou,
    
        -- Check 1: Chronological flow
    CASE 
        WHEN order_approved_at_sou < order_purchase_timestamp_sou THEN 'FAIL: Approved before Purchase'
        WHEN order_delivered_carier_date_sou < order_approved_at_sou THEN 'FAIL: Shipped before Approved'
        WHEN order_delivered_customer_date_sou < order_delivered_carier_date_sou THEN 'FAIL: Delivered before Shipped'
        
        -- Check 2: Missing data step-skipping
        WHEN order_delivered_customer_date_sou IS NOT NULL AND order_delivered_carier_date_sou IS NULL THEN 'FAIL: Customer received but no Carrier date'
        WHEN order_delivered_carier_date_sou IS NOT NULL AND order_approved_at_sou IS NULL THEN 'FAIL: Shipped but no Approval date'
        
        -- Check 3: Missing baseline estimates
        WHEN order_estimated_delivery_date_sou IS NULL THEN 'FAIL: Missing Estimated Delivery Date'
        
        -- Check 4: System defaults or impossible future dates
        WHEN order_purchase_timestamp_sou > GETDATE() THEN 'FAIL: Purchase date is in the future'
        
        ELSE 'VALID'
    END AS Date_Validity_Status
FROM Olist_DWH.Source_Layer.source_ord
)
SELECT
	Date_Validity_Status AS Fail_Type,
	COUNT(*) AS Rows_Count
FROM Date_Validity_Check 
WHERE Date_Validity_Status != 'VALID'
GROUP BY Date_Validity_Status
ORDER BY COUNT(*) DESC;

-- Note: We do have logical errors in date columns. We found following issues: 
-- 1. Fail:Shipped before Approved - 1359
-- 2. Fail: Delivered before Shipped: 23
-- 3. Fail: Shipped but no Approval Date
-- 4. Customer received but no Carrier Date
--We have to fixed this issues in ETL before inserting data into Stage / Silver Layer. 


-- Check the NULL values in date columns by order_status

SELECT 
    order_status_sou,
    COUNT(*) AS Total_Orders,
	SUM(CASE WHEN order_purchase_timestamp_sou IS NULL THEN 1 ELSE 0 END) AS Null_PurchaseDate_Count,
    SUM(CASE WHEN order_approved_at_sou IS NULL THEN 1 ELSE 0 END) AS Null_ApprovalDate_Count,
    SUM(CASE WHEN order_delivered_carier_date_sou IS NULL THEN 1 ELSE 0 END) AS Null_CarrierDate_Count,
    SUM(CASE WHEN order_delivered_customer_date_sou IS NULL THEN 1 ELSE 0 END) AS Null_CustomerDelDate_Count,
	SUM(CASE WHEN order_estimated_delivery_date_sou IS NULL THEN 1 ELSE 0 END) AS Null_EstimatedDelDate_Count
FROM Olist_DWH.Source_Layer.source_ord
GROUP BY order_status_sou
ORDER BY Total_Orders DESC;

-- Notes/Findings:
-- No Null values found in 'order_purchase_timestamp_sou' and in 'order_estimated_delivery_date_sou'. Other Date Columns have Nulls. However, not all these null values are irrelevant or illogical.
-- How to handle this null values of course depends on business context or subject-matter expert. However, from our investigation and understanding, we can see the following points:
-- 1. Whether date columns will be empty or not depends on order status. If a order delivered to customers (order_status = 'delivered'), it should have non-empty (Not Null) date columns (order_purchase_date < order_approval_date < delivered_carrier_date < delivered_customer_date)
-- 2. If a order has placed, but later canceled, may have purchase_date, but not approval_date, delivered_carrier_date, delivered_customer_date (depends on when a order canceled)
-- 3. If a order has a order_status = ['created', 'processing', 'invoiced', 'approved', 'shipped'] that means order is still processing and may have earlier date columns (purchase_date, approve_date) filled, but later date columns (delivered_carrier_date, delivered_customer_date) are empty 

-- ### Our solution Approach to Date Columns:
-- # Handling Null Values in Date Columns:
-- Orders with order_status = 'delivered' should have non-empty date columns. If there is a null, we shall fill it. 
-- If Null is in
	-- 1. Approved Date > Replace by Purchase Date
	-- 2. Carrier Date > Replace by Approved Date. If Approved Date is empty, then Purchase Date
	-- 3. Customer Delivery Date > Replace by Estimated Delivery Date
-- # Handling Logical Errors in Date Columns:
	-- 1. IF [order_approved_at] < [order_purchase_timestamp], THEN [order_purchase_timestamp]
	-- 2. IF [order_delivered_carrier_date] < [order_approved_at], THEN [order_approved_at]
	-- 3. IF [order_delivered_customer_date] < [order_delivered_carrier_date], THEN [order_delivered_carrier_date] 
	-- 4. IF [order_estimated_delivery_date] < [order_delivered_customer_date], THEN [order_estimated_delivery_date] will not be replaced by [order_delivered_customer_date], because a delivery may arrive later than estimated delivery date.

--==========================================================================
-- Quality Check of a 'Stage_Ord' table before cleaning and transformation
--==========================================================================

-- Check the whole Table at a glance
SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_Ord;
--Findings: Looks Good!


-- Check whether 'order_id_stg' and 'customer_id_stg' contains any double quotes (")
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id_stg LIKE '"%"' THEN 1 ELSE 0 END) AS count_rows_with_quotes_orderid,
	SUM(CASE WHEN customer_id_stg LIKE '"%"' THEN 1 ELSE 0 END) AS count_rows_with_quotes_customerid
FROM Olist_DWH.Stage_Layer.Stage_Ord;
-- Findings: No double quotes ('"') found. Good!

-- Check for duplicates or nulls in Primary Key Column 'order_id_stg'
SELECT
	order_id_stg,
	COUNT (*) Rows_Count
FROM Olist_DWH.Stage_Layer.Stage_Ord
GROUP BY order_id_stg
HAVING COUNT (*) > 1 OR order_id_stg IS NULL 
-- Findings: No Nulls or Duplicates in primary key column. Good!


-- Check the validity of date columns
WITH CTE_DateColumn_Check AS ( 
SELECT 
    purchase_timestamp_stg,
    approved_at_stg,
    delivered_carrier_date_stg,
    delivered_customer_date_stg,
    estimated_delivery_date_stg,

        -- Check: Chronological flow
    CASE 
        WHEN approved_at_stg < purchase_timestamp_stg THEN 'FAIL: Approved before Purchase'
        WHEN delivered_carrier_date_stg < approved_at_stg THEN 'FAIL: Shipped before Approved'
        WHEN delivered_customer_date_stg < delivered_carrier_date_stg THEN 'FAIL: Delivered before Shipped'        
        ELSE 'VALID'
    END AS Date_Validity_Status
FROM Olist_DWH.Stage_Layer.Stage_Ord

)
SELECT
	Date_Validity_Status,
	COUNT(*) Total_Rows
FROM CTE_DateColumn_Check
GROUP BY Date_Validity_Status
ORDER BY COUNT(*) DESC;
-- Findings:  All rows are valid. That looks good!


-- Check whether orders with order_status = 'delivered' have any null values in date columns
SELECT
	SUM(CASE WHEN purchase_timestamp_stg IS NULL THEN 1 ELSE 0 END) AS Count_NULL_In_PurDate,
	SUM(CASE WHEN approved_at_stg IS NULL THEN 1 ELSE 0 END) AS Count_Null_In_ApprovDate,
	SUM(CASE WHEN delivered_carrier_date_stg IS NULL THEN 1 ELSE 0 END) AS Count_Null_In_CarrierDate,
	SUM(CASE WHEN delivered_customer_date_stg IS NULL THEN 1 ELSE 0 END) AS Count_Null_In_CustomerDate,
	SUM(CASE WHEN estimated_delivery_date_stg IS NULL THEN 1 ELSE 0 END) AS Count_Null_In_EstDelDate
FROM Olist_DWH.Stage_Layer.Stage_Ord
WHERE order_status_stg = 'delivered';
-- Findings: No Null values found in date columns for orders with order_status = 'delivered'. Very Good!

-- So, overall our stage table data quality looks good and solved issued we found in 'source_ord'. 













