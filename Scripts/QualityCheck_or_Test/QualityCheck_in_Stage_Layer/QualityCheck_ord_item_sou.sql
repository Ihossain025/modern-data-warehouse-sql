
-===============================================================================
-- Quality Check of a 'source_ordItems' table before cleaning and transformation
--==============================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [order_id_sou]
      ,[order_item_id_sou]
      ,[product_id_sou]
      ,[seller_id_sou]
      ,[shipping_limit_date_sou]
      ,[price_sou]
      ,[freight_value_sou]
  FROM [Olist_DWH].[Source_Layer].[source_ordItems];


 /* 
 -- At a first glance, we see that our key columns ('order_id_sou', 'product_id_sou', 'seller_id_sou') value starts and ends with double quote ('"').
 -- Check whether this double quote ('"') exists in every row. If not, we must remove them.
 -- As we have removed it from previous tables we must remove them.
 -- Otherwise, our join will break.
 */

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN order_id_sou LIKE '"%"' THEN 1 -- change the column name here
        ELSE 0 
    END) AS rows_with_quotes,
    CASE 
        WHEN COUNT(*) = SUM(CASE WHEN order_id_sou LIKE '"%"' THEN 1 ELSE 0 END) -- change the column name here 
        THEN 'YES - Every row has quotes. Safe to keep.'
        ELSE 'NO - Mixed data found! We must clean them.'
    END AS final_verdict
FROM Olist_DWH.Source_Layer.source_ordItems;

-- Note: Not every row has this double quote. So, we must remove them

-- Check for the distinct order_item_id

-- Check whether primary key (combination of 'order_id' and 'order_item_id' Columns) is unique / has duplicates / has Null
-- Expected Output: No Result

-- Check for Null first
SELECT
COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_ordItems
WHERE order_id_sou IS NULL OR order_item_id_sou IS NULL  

-- Note: No null values in key columns. Looks good!

-- Check for duplicates
SELECT
COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_ordItems
GROUP BY order_id_sou, order_item_id_sou
HAVING COUNT(*) > 1;

-- Note: No duplicate values in primary key. Looks good!

-- Check for Null values in other columns

SELECT
*
FROM [Olist_DWH].[Source_Layer].[source_ordItems]
WHERE product_id_sou IS NULL -- change the column name here

-- Note: No Null values in other column. Looks very good!

--=============================================================================
-- Quality Check of a 'stage_Ord_Items' table after cleaning and transformation
--=============================================================================

-- Check the whole Table at a glance

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_Ord_Items;

-- Check whether double quotes '"' still exist in key columns
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id_stg LIKE '"%"' THEN 1 ELSE 0 END) AS rows_with_quotes_in_OrderID,
    SUM(CASE WHEN product_id_stg LIKE '"%"' THEN 1 ELSE 0 END) AS rows_with_quotes_in_ProduktID,
	SUM(CASE WHEN seller_id_stg LIKE '"%"' THEN 1 ELSE 0 END) AS rows_with_quotes_in_SellerID
FROM Olist_DWH.Stage_Layer.Stage_Ord_Items;

-- Note: No double quotes ('"') present in key columns. Sehr Gut!

-- Check whether primary key has any duplicates
SELECT
order_id_stg, 
order_item_id_stg,
COUNT(*) AS Rows_Count
FROM Olist_DWH.Stage_Layer.Stage_Ord_Items
GROUP BY order_id_stg, order_item_id_stg
HAVING COUNT(*) > 1;

-- Note: No duplicates present in primary key column. Sehr Gut!