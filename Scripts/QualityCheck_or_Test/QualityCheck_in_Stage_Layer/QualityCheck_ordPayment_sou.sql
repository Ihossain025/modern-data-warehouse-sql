
--==========================================================================
-- Quality Check of a 'source_ordPayment' table before cleaning and transformation
--==========================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [order_id_sou]
      ,[payment_sequential_sou]
      ,[payment_type_sou]
      ,[payment_installments_sou]
      ,[payment_value_sou]
  FROM [Olist_DWH].[Source_Layer].[source_ordPayment];


 /* 
 -- At a first glance, we see that our key column ('order_id_sou') value starts and ends with double quote ('"').
 -- Check whether this double quote ('"') exists in every row. If not, we must remove them.
 -- As we have removed it from previous tables we must remove them.
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
FROM Olist_DWH.Source_Layer.source_ordPayment;

-- Note: Not every row has this double quote. So, we must remove them


-- Check whether primary key (combination of 'order_id' and 'payment_sequential' Columns) is unique / has duplicates / has Null
-- Expected Output: No Result

-- Check for Null first
SELECT
COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_ordPayment
WHERE order_id_sou IS NULL OR payment_sequential_sou IS NULL  

-- Note: No null values in key columns. Looks good!

-- Check for duplicates
SELECT
COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_ordPayment
GROUP BY order_id_sou, payment_sequential_sou
HAVING COUNT(*) > 1;

-- Note: No duplicate values in primary key. Looks good!

-- Check for Null values in other columns

SELECT
*
FROM Olist_DWH.Source_Layer.source_ordPayment
WHERE payment_value_sou IS NULL -- change the column name here

-- Note: No Null values in other column. Looks very good!

-- Check for unwanted spaces (leading or trailing spaces in string columns)

SELECT
order_id_sou,
payment_type_sou
FROM Olist_DWH.Source_Layer.source_ordPayment
WHERE payment_type_sou != TRIM(payment_type_sou)

-- Check the distinct values for 'payment_sequential', 'payment_type', and 'payment_installments'

SELECT DISTINCT TRY_CAST(payment_sequential_sou AS int) AS Payment_Seq
FROM Olist_DWH.Source_Layer.source_ordPayment
ORDER BY TRY_CAST(payment_sequential_sou AS int) ASC;  

SELECT DISTINCT payment_type_sou
FROM Olist_DWH.Source_Layer.source_ordPayment;

SELECT DISTINCT payment_installments_sou 
FROM Olist_DWH.Source_Layer.source_ordPayment
ORDER BY TRY_CAST(payment_installments_sou AS int) ASC; 

-- Note: 
-- In total, 29 payment sequential
-- 5 Payment Types: Debit Card, Credit Card, Boleto, Voucher, Not_Defined
-- Total 24 installments


--================================================================================
-- Quality Check of a 'Stage_OrdPayments' table after cleaning and transformation
--================================================================================

-- Check the whole Table at a glance

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_OrdPayments;

-- Check whether double quotes '"' still exist in key columns
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id_stg LIKE '"%"' THEN 1 ELSE 0 END) AS rows_with_quotes_in_OrderID
FROM Olist_DWH.Stage_Layer.Stage_OrdPayments;

-- Note: No double quotes ('"') present in key column. Sehr Gut!

-- Check whether primary key (combination of 'order_id' and 'payment_sequential') has any duplicates
SELECT
	order_id_stg,
	payment_sequential_stg,
	COUNT(*) AS Rows_Count
FROM Olist_DWH.Stage_Layer.Stage_OrdPayments
GROUP BY order_id_stg, payment_sequential_stg
HAVING COUNT(*) > 1;

-- Note: No duplicates present in primary key. Sehr Gut!
