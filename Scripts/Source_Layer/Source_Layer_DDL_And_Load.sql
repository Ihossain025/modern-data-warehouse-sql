/*
--=================================================
-- Combined DDL and ETL Script for Source_Layer: 
-- Create Bronze or Source Layer Tables
-- Then load source data into these tables
--=================================================
This script creates tables for Bronze or Source Layer in the Datawarehouse. 
The Bronze/Source Layer represents raw, uncleaned, and unprocessed data (as-it-is in the source).
In this layer, all table columns are defined as NVARCHAR(MAX) to load data without Failure.
*/

--=====================================
-- Database and Schema Creation
--=====================================

-- Check whether Database exist

IF DB_ID(N'Olist_DWH') IS NULL
BEGIN
	CREATE DATABASE Olist_DWH
	PRINT('Database created successfully')
END
ELSE
BEGIN
	PRINT('Database already exist')
END;
GO

-- Use the newly created Database

USE Olist_DWH;
GO

-- Create Schemas in Database

CREATE SCHEMA Source_Layer;
GO

CREATE SCHEMA Stage_Layer;
GO

CREATE SCHEMA Final_Layer;
GO
--==================================================
-- Table Creation and Data Load for Source Layer
--==================================================

CREATE OR ALTER PROCEDURE Source_Layer.SourceData AS
BEGIN
	DECLARE @StartTime DATETIME, @EndTime DATETIME;
	BEGIN TRY
		PRINT '======================================';
		PRINT 'Creating Bronze or Source Layer';
		PRINT '======================================';

		--=======================================================
		-- Create a geolocation table and then insert data to it
		--=======================================================

		-- Create a geolocation table

		PRINT'====================================';
		PRINT'Create and Load geolocation table';
		PRINT'====================================';
		PRINT'Drop Table: Olist_DWH.Source_Layer.source_geo';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_geo;

		PRINT'Create Table: Olist_DWH.Source_Layer.source_geo';
		CREATE TABLE Olist_DWH.Source_Layer.source_geo (
			Geo_ZipCode_sou NVARCHAR(MAX),
			Geo_Lat_sou NVARCHAR(MAX),
			Geo_Lon_sou NVARCHAR(MAX),
			Geo_City_sou NVARCHAR(MAX),
			Geo_State_sou NVARCHAR(MAX)  
		);

		-- Insert data to the geolocation table from source by bulk insert

		SET @StartTime = GETDATE();
		PRINT'TRUNCATE Table: Olist_DWH.Source_Layer.source_geo';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_geo;

		PRINT'Insert data into Table: Olist_DWH.Source_Layer.source_geo';
		BULK INSERT Olist_DWH.Source_Layer.source_geo
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_geolocation_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';

		-- Test the Table and inserted Data
		/*
		SELECT TOP 50 * FROM Olist_DWH.Source_Layer.source_geo;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_geo;
		*/

		--======================================================
		-- Create a customer Table and then insert data to it
		--======================================================

		-- Creating a customer table

		PRINT'====================================';
		PRINT'Create and Load customer table';
		PRINT'====================================';
		PRINT 'Drop Table: Olist_DWH.Source_Layer.source_cus';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_cus;

		PRINT 'Create Table: Olist_DWH.Source_Layer.source_cus';
		CREATE TABLE Olist_DWH.Source_Layer.source_cus (

			customer_id_sou NVARCHAR(MAX),
			customer_unique_id_sou NVARCHAR(MAX),
			customer_zip_code_prefix_sou NVARCHAR(MAX),
			customer_city_sou NVARCHAR(MAX),
			customer_state_sou NVARCHAR(MAX)  
		);

		-- Insert data to the table from source by bulk insert
		SET @StartTime = GETDATE();
		PRINT ' Truncate Table: Olist_DWH.Source_Layer.source_cus';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_cus;

		PRINT ' Insert data into Table: Olist_DWH.Source_Layer.source_cus';
		BULK INSERT Olist_DWH.Source_Layer.source_cus
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_customers_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'-------------------------';

		-- Test the Table and inserted data
		/*
		SELECT TOP 50* FROM Olist_DWH.Source_Layer.source_cus;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_cus;
		*/

		--=======================================================
		-- Create a table for Seller and then insert data to it
		--=======================================================

		-- Creating a seller table

		PRINT'====================================';
		PRINT'Create and Load seller table';
		PRINT'====================================';
		PRINT 'Drop Table: Olist_DWH.Source_Layer.source_sell';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_sell;

		PRINT 'Create Table: Olist_DWH.Source_Layer.source_sell';
		CREATE TABLE Olist_DWH.Source_Layer.source_sell (

			seller_id_sou NVARCHAR(MAX),
			seller_zip_code_prefix_sou NVARCHAR(MAX),
			seller_city_sou NVARCHAR(MAX),
			seller_state_sou NVARCHAR(MAX)  
		);

		-- Insert data to the table from source by bulk insert
		SET @StartTime = GETDATE();
		PRINT 'Truncate Table: Olist_DWH.Source_Layer.source_sell';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_sell; 

		PRINT 'Insert data into Table: Olist_DWH.Source_Layer.source_sell';
		BULK INSERT Olist_DWH.Source_Layer.source_sell
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_sellers_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------------';

		-- Test the Table and inserted data
		/*
		SELECT TOP 50 * FROM Olist_DWH.Source_Layer.source_sell;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_sell;
		*/

		--===================================================================================
		-- Create a table for Products and then insert data to Products
		--===================================================================================

		-- Creating a products table

		PRINT'====================================';
		PRINT'Create and Load products table';
		PRINT'====================================';
		PRINT'Drop Table: Olist_DWH.Source_Layer.source_pro';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_pro;

		PRINT'Create Table: Olist_DWH.Source_Layer.source_pro';
		CREATE TABLE Olist_DWH.Source_Layer.source_pro (

			product_id_sou NVARCHAR(MAX),
			product_category_name_sou NVARCHAR(MAX),
			product_name_lenght_sou NVARCHAR(MAX),
			product_description_lengh_sou NVARCHAR(MAX),
			product_photos_qty_sou NVARCHAR (MAX),
			product_weight_sou NVARCHAR (MAX),
			product_length_sou NVARCHAR (MAX),
			product_height_sou NVARCHAR (MAX),
			product_width_sou NVARCHAR (MAX)

		);

		-- Insert data to the table from source by bulk insert
		SET @StartTime = GETDATE();
		PRINT'Truncate Table: Olist_DWH.Source_Layer.source_pro';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_pro;

		PRINT'Insert data into Table: Olist_DWH.Source_Layer.source_pro';
		BULK INSERT Olist_DWH.Source_Layer.source_pro
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_products_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'------------------------';

		-- Test the Table and data insert
		/*
		SELECT TOP 50 * FROM Olist_DWH.Source_Layer.source_pro;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_pro;
		*/

		--============================================================
		-- Create a table for Orders and then insert data to Orders
		--============================================================

		-- Create a orders table

		PRINT'====================================';
		PRINT'Create and Load orders table';
		PRINT'====================================';
		PRINT 'Drop Table: Olist_DWH.Source_Layer.source_ord';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_ord;
	
		PRINT 'Create Table: Olist_DWH.Source_Layer.source_ord';
		CREATE TABLE Olist_DWH.Source_Layer.source_ord (

			order_id_sou NVARCHAR(MAX),
			customer_id_sou NVARCHAR(MAX),
			order_status_sou NVARCHAR(MAX),
			order_purchase_timestamp_sou NVARCHAR(MAX),
			order_approved_at_sou NVARCHAR (MAX),
			order_delivered_carier_date_sou NVARCHAR (MAX),
			order_delivered_customer_date_sou NVARCHAR (MAX),
			order_estimated_delivery_date_sou NVARCHAR (MAX)
    
		);

		-- Insert data to the table from source by using bulk insert method
		SET @StartTime = GETDATE();
		PRINT 'Truncate Table: Olist_DWH.Source_Layer.source_ord';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_ord

		PRINT 'Insert data into Table: Olist_DWH.Source_Layer.source_ord';
		BULK INSERT Olist_DWH.Source_Layer.source_ord
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_orders_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'-------------------------';

		-- Test the table and data import
		/*
		SELECT TOP 50 * FROM Olist_DWH.Source_Layer.source_ord;
		SELECT COUNT(*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_ord;
		*/

		--=====================================================================
		-- Create a table for Order Items and then insert data to Order Items
		--=====================================================================

		-- Create a order items table

		PRINT'====================================';
		PRINT'Create and Load order items table';
		PRINT'====================================';
		PRINT 'Drop Table: Olist_DWH.Source_Layer.source_ordItems';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_ordItems;

		PRINT 'Create Table: Olist_DWH.Source_Layer.source_ordItems';
		CREATE TABLE Olist_DWH.Source_Layer.source_ordItems (

			order_id_sou NVARCHAR(MAX),
			order_item_id_sou NVARCHAR(MAX),
			product_id_sou NVARCHAR(MAX),
			seller_id_sou NVARCHAR(MAX),
			shipping_limit_date_sou NVARCHAR (MAX),
			price_sou NVARCHAR (MAX),
			freight_value_sou NVARCHAR (MAX)   
		);

		-- Insert data to the table from source by using bulk insert method
		SET @StartTime = GETDATE();
		PRINT 'Truncate Table: Olist_DWH.Source_Layer.source_ordItems';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_ordItems;

		PRINT 'Insert data into Table: Olist_DWH.Source_Layer.source_ordItems';
		BULK INSERT Olist_DWH.Source_Layer.source_ordItems
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_order_items_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'-------------------------';

		-- Test the table and data import
		/*
		SELECT TOP 50 * FROM Olist_DWH.Source_Layer.source_ordItems;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_ordItems;
		*/

		--===========================================================================
		-- Create a table for Order Payments and then insert data to Order Payments
		--===========================================================================

		-- Create a order payment table

		PRINT'====================================';
		PRINT'Create and Load order payment table';
		PRINT'====================================';
		PRINT 'Drop Table: Olist_DWH.Source_Layer.source_ordPayment';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_ordPayment;

		PRINT 'Create Table: Olist_DWH.Source_Layer.source_ordPayment';
		CREATE TABLE Olist_DWH.Source_Layer.source_ordPayment (

			order_id_sou NVARCHAR(MAX),
			payment_sequential_sou NVARCHAR(MAX),
			payment_type_sou NVARCHAR(MAX),
			payment_installments_sou NVARCHAR(MAX),
			payment_value_sou NVARCHAR (MAX)
    
		);

		-- Insert data to the table from source by using bulk insert method
		SET @StartTime = GETDATE();
		PRINT 'Truncate Table: Olist_DWH.Source_Layer.source_ordPayment';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_ordPayment;

		PRINT 'Insert data into Table: Olist_DWH.Source_Layer.source_ordPayment';
		BULK INSERT Olist_DWH.Source_Layer.source_ordPayment
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_order_payments_dataset.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a', -- This is the Hex value for \n (Line Feed)
			CODEPAGE = '65001'      -- This ensures Brazilian characters (like �) load correctly
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------------';

		-- Test the table and data import
		/*
		SELECT TOP 50 * FROM Olist_DWH.Source_Layer.source_ordPayment;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_ordPayment;
		*/

		--========================================================================
		-- Create a table for Order Reviews and then insert data to Order Reviews
		--========================================================================

		-- Create a order review table

		PRINT'====================================';
		PRINT'Create and Load order reviews table';
		PRINT'====================================';
		PRINT 'Drop Table: Olist_DWH.Source_Layer.source_orderReview';
		DROP TABLE IF EXISTS Olist_DWH.Source_Layer.source_orderReview;

		PRINT 'Create Table: Olist_DWH.Source_Layer.source_orderReview';
		CREATE TABLE Olist_DWH.Source_Layer.source_orderReview (

			review_id_sou NVARCHAR(MAX),
			order_id_sou NVARCHAR(MAX),
			review_score_sou NVARCHAR(MAX),
			review_comment_title_sou NVARCHAR(MAX),
			review_comment_message_sou NVARCHAR (MAX),
			review_creation_date_sou NVARCHAR (MAX),
			review_answer_timestamp_sou NVARCHAR (MAX)
    
		);

		-- Insert data to the table from source by using bulk insert method
		SET @StartTime = GETDATE();
		PRINT 'Truncate Table: Olist_DWH.Source_Layer.source_orderReview';
		TRUNCATE TABLE Olist_DWH.Source_Layer.source_orderReview;

		PRINT 'Insert data into Table: Olist_DWH.Source_Layer.source_orderReview';
		BULK INSERT Olist_DWH.Source_Layer.source_orderReview
		FROM 'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_order_reviews_dataset_cleaned.txt'
		WITH (
			DATAFILETYPE = 'char',        
			FIELDTERMINATOR = '\t',       -- Bypasses the customer commas
			ROWTERMINATOR = '\n',         -- Windows and Linux line breaks are unified
			FIRSTROW = 2,
			CODEPAGE = '65001',           -- Keeps Brazilian Portuguese symbols or character
			TABLOCK
		);
		SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'------------------------------';

		-- Test the table and data loaded
		/*
		SELECT * FROM Olist_DWH.Source_Layer.source_orderReview;
		SELECT COUNT (*) AS Rows_Count FROM Olist_DWH.Source_Layer.source_orderReview;
		*/

	END TRY
	BEGIN CATCH
	PRINT'======================================================';
	PRINT 'Error Message' + ERROR_MESSAGE();
	PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
	PRINT'======================================================';
	END CATCH
END

EXEC Source_Layer.SourceData;