
--==========================================================================
-- Quality Check of a 'source_cus' table before cleaning and transformation
--==========================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [customer_id_sou]
      ,[customer_unique_id_sou]
      ,[customer_zip_code_prefix_sou]
      ,[customer_city_sou]
      ,[customer_state_sou]
  FROM [Olist_DWH].[Source_Layer].[source_cus];


 /* 
 -- At a first glance, we see that our primary key column ('customer_id_sou') value starts and ends with double quote ('"').
 -- Check whether this double quote ('"') exists in every row. If not we must remove them.
 -- It's better to remove them anyway because may be other tables will not have in every row for key columns
 -- Otherwise, our join will break.
 */

 SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN customer_id_sou LIKE '"%"' THEN 1 
        ELSE 0 
    END) AS rows_with_quotes,
    CASE 
        WHEN COUNT(*) = SUM(CASE WHEN customer_id_sou LIKE '"%"' THEN 1 ELSE 0 END) 
        THEN 'YES - Every row has quotes. Safe to keep.'
        ELSE 'NO - Mixed data found! We must clean them.'
    END AS final_verdict
FROM Olist_DWH.Source_Layer.source_cus;

-- Note: Not every row has this double quote. So, we must remove them


-- Check whether 'customer_id_sou' Column is unique / has duplicates / has Null
-- Expected Output: No Result

SELECT
REPLACE(TRIM(customer_id_sou),'"','') AS Cus_id,
COUNT(*) AS Cus_id_count
FROM Olist_DWH.Source_Layer.source_cus
GROUP BY REPLACE(TRIM(customer_id_sou),'"','')
HAVING COUNT(*) > 1 OR REPLACE(TRIM(customer_id_sou),'"','') IS NULL;

-- Note: No Duplicate or Null in Primary Key. Looks Good!


-- Check for unwanted spaces in string columns
-- Expected Output: No Result

-- Check in 'customer_city_sou' column
SELECT
customer_city_sou
FROM Olist_DWH.Source_Layer.source_cus
WHERE customer_city_sou != TRIM(customer_city_sou);

-- Check in 'customer_state_sou' column
SELECT
customer_state_sou
FROM Olist_DWH.Source_Layer.source_cus
WHERE customer_state_sou != TRIM(customer_state_sou)

-- Note: No unwanted spaces in 'customer_city_sou'  & 'customer_state_sou' columns. Looks good!

-- Check for the distinct number of States and Cities
-- Expected Output: Distinct Values

-- check 'customer_state_sou'
SELECT DISTINCT customer_state_sou
FROM Olist_DWH.Source_Layer.source_cus

-- -- check 'customer_city_sou'
SELECT DISTINCT customer_city_sou
FROM Olist_DWH.Source_Layer.source_cus

-- Check any state name has more than 2 characters 
SELECT
customer_state_sou
FROM Olist_DWH.Source_Layer.source_cus
WHERE LEN(customer_state_sou)>2

-- Note: All States names are abbreviated two characters. Looks Good!


--==========================================================================
-- Quality Check of a 'stage_Cus' table after cleaning and transformation
--==========================================================================

-- Check the whole Table at first

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_Cus


-- Check the uniqueness of Primary Key ('customer_id_stg')

SELECT
customer_id_stg AS Cus_id,
COUNT(*) AS Cus_id_count
FROM Olist_DWH.Stage_Layer.Stage_Cus
GROUP BY customer_id_stg
HAVING COUNT(*) > 1 OR customer_id_stg IS NULL;

-- No duplicate or No Nulls in Primary Key. Looks good!
