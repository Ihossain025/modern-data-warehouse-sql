--==========================================================================
-- Quality Check of a 'source_sell' table before cleaning and transformation
--==========================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [seller_id_sou]
      ,[seller_zip_code_prefix_sou]
      ,[seller_city_sou]
      ,[seller_state_sou]
  FROM [Olist_DWH].[Source_Layer].[source_sell]


  /* 
 -- At a first glance, we see that our primary key column ('customer_id_sou') value starts and ends with double quote ('"').
 -- Check whether this double quote ('"') exists in every row. If not we must remove them.
 -- It's better to remove them anyway because may be other tables will not have in every row for key columns
 -- Otherwise, our join will break.
 */

 SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN seller_id_sou LIKE '"%"' THEN 1 
        ELSE 0 
    END) AS rows_with_quotes,
    CASE 
        WHEN COUNT(*) = SUM(CASE WHEN seller_id_sou LIKE '"%"' THEN 1 ELSE 0 END) 
        THEN 'YES - Every row has quotes. Safe to keep.'
        ELSE 'NO - Mixed data found! We must clean them.'
    END AS final_verdict
FROM Olist_DWH.Source_Layer.source_sell;

-- Note: Not every row has this double quote. So, we must remove them


-- Check whether primary key ('customer_id_sou' Column) is unique / has duplicates / has Null
-- Expected Output: No Result

SELECT
	REPLACE(TRIM(seller_id_sou),'"','') AS seller_id_sou,
	COUNT(*) AS Seller_id_count
FROM Olist_DWH.Source_Layer.source_sell
GROUP BY REPLACE(TRIM(seller_id_sou),'"','')
HAVING COUNT(*) > 1 OR REPLACE(TRIM(seller_id_sou),'"','') IS NULL

-- No Duplicates or Null in Primary Key. Looks Good!


-- Check for unwanted spaces in string columns
-- Expected Output: No Result

-- Check in 'seller_city_sou' column
SELECT
seller_city_sou
FROM Olist_DWH.Source_Layer.source_sell
WHERE seller_city_sou != TRIM(seller_city_sou);

-- Check in 'seller_state_sou' column
SELECT
seller_state_sou
FROM Olist_DWH.Source_Layer.source_sell
WHERE seller_state_sou != TRIM(seller_state_sou)

-- Note: No unwanted spaces in 'seller_city_sou', but we do have in 'seller_state_sou' columns. In column 'seller_state_sou'has more than two abbreviated characters. Doesn't Looks good! Need Attention!

-- Check 'seller_state_sou' for more than 2 characters 
SELECT
seller_state_sou
FROM Olist_DWH.Source_Layer.source_sell
WHERE LEN(seller_state_sou)>2

-- Note: Only 2 rows, which we have found out in earlier check. We will take care of them while cleaning or transforming.


--==========================================================================
-- Quality Check of a 'stage_sell' table after cleaning and transformation
--==========================================================================

-- Check the whole Table at a Glance

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_Sell

-- Check the uniqueness of Primary Key ('seller_id_stg')

SELECT
seller_id_stg,
COUNT (*) AS Row_Count
FROM Olist_DWH.Stage_Layer.Stage_Sell
GROUP BY seller_id_stg
HAVING COUNT (*) > 1 OR seller_id_stg IS NULL

-- Check 'state_stg' for more than 2 characters 
SELECT
state_stg
FROM Olist_DWH.Stage_Layer.Stage_Sell
WHERE LEN(state_stg)>2

-- Check all distinct states

SELECT DISTINCT state_stg
FROM Olist_DWH.Stage_Layer.Stage_Sell

-- Note: Looks good!