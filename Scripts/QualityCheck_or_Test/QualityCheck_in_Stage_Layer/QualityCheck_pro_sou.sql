
--==========================================================================
-- Quality Check of a 'source_pro' table before cleaning and transformation
--==========================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [product_id_sou]
      ,[product_category_name_sou]
      ,[product_name_lenght_sou]
      ,[product_description_lengh_sou]
      ,[product_photos_qty_sou]
      ,[product_weight_sou]
      ,[product_length_sou]
      ,[product_height_sou]
      ,[product_width_sou]
  FROM [Olist_DWH].[Source_Layer].[source_pro];

 /* 
 -- At a first glance, we see that our primary key column ('customer_id_sou') value starts and ends with double quote ('"').
 -- Check whether this double quote ('"') exists in every row. If not we must remove them.
 -- It's better to remove them anyway because may be other tables will not have in every row for key columns
 -- Otherwise, our join will break.
 */

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN product_id_sou LIKE '"%"' THEN 1 
        ELSE 0 
    END) AS rows_with_quotes,
    CASE 
        WHEN COUNT(*) = SUM(CASE WHEN product_id_sou LIKE '"%"' THEN 1 ELSE 0 END) 
        THEN 'YES - Every row has quotes. Safe to keep.'
        ELSE 'NO - Mixed data found! We must clean them.'
    END AS final_verdict
FROM Olist_DWH.Source_Layer.source_pro;

-- -- Note: Not every row has this double quote. So, we must remove them

-- Check whether primary key ('product_id_sou' Column) is unique / has duplicates / has Null
-- Expected Output: No Result

SELECT
product_id_sou,
COUNT(*) AS count_pro_id
FROM Olist_DWH.Source_Layer.source_pro
GROUP BY product_id_sou
HAVING COUNT(*) > 1 OR product_id_sou IS NULL; 

-- No duplicate or null values in primary key column. Looks good!

-- Other columns are allowed to have Nulls. However, Find out rows with Null values in other columns.

SELECT
*
FROM Olist_DWH.Source_Layer.source_pro
WHERE 
[product_category_name_sou] IS NULL OR
[product_name_lenght_sou] IS NULL OR
[product_description_lengh_sou] IS NULL OR
[product_photos_qty_sou] IS NULL OR
[product_weight_sou] IS NULL OR
[product_length_sou] IS NULL OR
[product_height_sou] IS NULL OR
[product_width_sou] IS NULL

-- Note: We have null values in other columns. We will handle them by either 'unknown' (for string columns) and 0 (for numeric columns) while cleaning or transforming.


-- Check for unwanted spaces in string columns
-- Expected Output: No Result

-- Check in 'product_category_name_sou' column
SELECT
product_category_name_sou
FROM Olist_DWH.Source_Layer.source_pro
WHERE product_category_name_sou != TRIM(product_category_name_sou)

-- Note: No unwanted space in one only string column 'product_category_name_sou'. Looks good!


--==========================================================================
-- Quality Check of a 'stage_pro' table after cleaning and transformation
--==========================================================================

-- Check the whole Table

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_Pro;

-- Check is there any duplicate or Null values exist in Primary Column ('product_id_stg')

SELECT
product_id_stg,
COUNT(*) AS Rows_Count
FROM Olist_DWH.Stage_Layer.Stage_Pro
GROUP BY product_id_stg
HAVING COUNT(*) > 1 OR product_id_stg IS NULL

-- Note: No Duplicate or Nulls in Primary Key Column. Looks Good!




