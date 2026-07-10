--==========================================================================
-- Quality Check of a 'source_geo' table before cleaning and transformation
--==========================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [Geo_ZipCode_sou]
      ,[Geo_Lat_sou]
      ,[Geo_Lon_sou]
      ,[Geo_City_sou]
      ,[Geo_State_sou]
  FROM [Olist_DWH].[Source_Layer].[source_geo];


-- Check whether Zip Code (Primary Key) Column is unique / has duplicates / has Null
-- Expected Output: No Result
SELECT
[Geo_ZipCode_sou],
COUNT(*) AS ZipCode_Count
FROM [Olist_DWH].[Source_Layer].[source_geo]
GROUP BY [Geo_ZipCode_sou]
HAVING COUNT(*)>1 OR [Geo_ZipCode_sou] IS NULL;


-- Check for unwanted spaces in string columns
-- Expected Output: No Result
SELECT
Geo_City_sou
FROM Olist_DWH.Source_Layer.source_geo
WHERE [Geo_City_sou] != TRIM([Geo_City_sou]);

SELECT
Geo_State_sou
FROM Olist_DWH.Source_Layer.source_geo
WHERE [Geo_State_sou] != TRIM([Geo_State_sou]);

-- Check for the distinct number of States and Cities
-- Expected Output: Distinct Values

-- Check the distinct number of states 
SELECT DISTINCT Geo_State_sou
FROM [Olist_DWH].[Source_Layer].[source_geo];

-- Check the distinct number of cities 
SELECT DISTINCT Geo_City_sou
FROM [Olist_DWH].[Source_Layer].[source_geo];

-- Check any state name has more than 2 characters 
SELECT
Geo_State_sou
FROM Olist_DWH.Source_Layer.source_geo
WHERE LEN(Geo_State_sou)>2


--=========================================================================
-- Quality Check of a 'stage_geo' table after cleaning and transformation
--=========================================================================

-- First look at the data. Select Top 1000 Rows.

SELECT TOP (1000) [zip_code_prefix_stg]
      ,[latitude_stg]
      ,[longitude_stg]
      ,[city_stg]
      ,[state_stg]
      ,[dwh_create_date_stg]
      ,[file_location]
  FROM [Olist_DWH].[Stage_Layer].[Stage_Geo]


-- Check whether Zip Code (Primary Key) Column is unique / has duplicates / has Null
-- Expected Output: No Result
SELECT
[zip_code_prefix_stg],
COUNT(*) AS ZipCode_Count
FROM [Olist_DWH].[Stage_Layer].[Stage_Geo]
GROUP BY [zip_code_prefix_stg]
HAVING COUNT(*)>1 OR [zip_code_prefix_stg] IS NULL;


-- Check for unwanted spaces in string columns
-- Expected Output: No Result
SELECT
[city_stg]
FROM [Olist_DWH].[Stage_Layer].[Stage_Geo]
WHERE [city_stg] != TRIM([city_stg]);

SELECT
[state_stg]
FROM [Olist_DWH].[Stage_Layer].[Stage_Geo]
WHERE [state_stg] != TRIM([state_stg]);

-- Check for the distinct number of States and Cities
-- Expected Output: Distinct Values

-- Check the distinct number of states 
SELECT DISTINCT [state_stg]
FROM [Olist_DWH].[Stage_Layer].[Stage_Geo];

-- Check any state name has more than 2 characters 
SELECT
[state_stg]
FROM [Olist_DWH].[Stage_Layer].[Stage_Geo]
WHERE LEN([state_stg])>2