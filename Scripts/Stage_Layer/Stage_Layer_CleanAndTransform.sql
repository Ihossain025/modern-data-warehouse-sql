/*
--=====================================================================
-- ETL Script: Clean, Transform, and Load Data to Silver/Stage Layer Tables
--=====================================================================
This script performed data cleaning and transformation (
data type conversion, replace redundant string, date validation, 
handle missing Values, handles duplicates etc.
) 
on source layer tables and then populate silver/stage layer tables. 
*/

-- Use or Select right Database
USE Olist_DWH;

-- Create a Stored Procedure for whole ETL script
CREATE OR ALTER PROCEDURE Stage_Layer.StageData AS
BEGIN
    DECLARE @StartTime DATETIME, @EndTime DATETIME;
	
    --==========================================
    -- Clean and Transform 'geolocation' Table
    --==========================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_Geo;

    WITH Ranked_Geo AS (
    SELECT
        REPLACE(TRIM(Geo_ZipCode_sou), '"','') AS Geo_ZipCode_sou,
        TRY_CAST(Geo_Lat_sou AS decimal(10,6)) AS Geo_Lat_sou,
        TRY_CAST(Geo_Lon_sou AS decimal(10,6)) AS Geo_Lon_sou,
        TRIM(Geo_City_sou) AS Geo_City_sou,
        UPPER(RIGHT(TRIM(Geo_State_sou),2)) AS Geo_State_sou,
        ROW_NUMBER () OVER (PARTITION BY REPLACE(TRIM(Geo_ZipCode_sou), '"','') ORDER BY TRY_CAST(Geo_Lat_sou AS decimal(10,6)), TRY_CAST(Geo_Lon_sou AS decimal(10,6))) AS rn 
    FROM Olist_DWH.Source_Layer.source_geo
    WHERE REPLACE(TRIM(Geo_ZipCode_sou), '"','') IS NOT NULL
    )
    INSERT INTO Olist_DWH.Stage_Layer.Stage_Geo (
        zip_code_prefix_stg,
        latitude_stg,
        longitude_stg,
        city_stg,
        state_stg,
        file_location
    )
    SELECT
    Geo_ZipCode_sou,
    Geo_Lat_sou,
    Geo_Lon_sou,
    Geo_City_sou,
    Geo_State_sou,
    'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Ranked_Geo
    WHERE rn = 1;

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';

    --========================================
    -- Clean and Transform 'customer' Table
    --========================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_Cus;

    INSERT INTO Olist_DWH.Stage_Layer.Stage_Cus (
        customer_id_stg,
        customer_unique_id_stg,
        zip_code_prefix_stg,
        city_stg,
        state_stg,
        file_location  
    )
    SELECT
        REPLACE(TRIM(customer_id_sou),'"','') AS customer_id_sou,
        REPLACE(TRIM(customer_unique_id_sou),'"','') AS customer_unique_id_sou, 
        REPLACE(TRIM(customer_zip_code_prefix_sou),'"','') AS customer_zip_code_prefix_sou,
        customer_city_sou,
        customer_state_sou,
        'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Olist_DWH.Source_Layer.source_cus;

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';


    --========================================
    -- Clean and Transform 'seller' Table
    --========================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_Sell;

    INSERT INTO Olist_DWH.Stage_Layer.Stage_Sell (
        seller_id_stg,
        zip_code_prefix_stg,
        city_stg,
        state_stg,
        file_location
    )
    SELECT
        REPLACE(TRIM(seller_id_sou),'"','') AS seller_id_sou,
        REPLACE(TRIM(seller_zip_code_prefix_sou),'"','') AS seller_zip_code_prefix_sou,
        seller_city_sou,
        UPPER(RIGHT(TRIM(seller_state_sou),2)) AS seller_state_sou,
        'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Olist_DWH.Source_Layer.source_sell;

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';


    --========================================
    -- Clean and Transform 'product' Table
    --========================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_Pro;

    INSERT INTO Olist_DWH.Stage_Layer.Stage_Pro (
        product_id_stg,
        product_category_name_stg,
        product_name_length_stg,
        product_description_length_stg,
        product_photos_qty_stg,
        product_weight_g_stg,
        product_length_cm_stg,
        product_height_cm_stg,
        product_width_cm_stg,
        file_location
    )
    SELECT
    REPLACE(TRIM(product_id_sou),'"','') AS product_id_sou,
    COALESCE(product_category_name_sou,'Unknown') AS product_category_name_sou,
    COALESCE(TRY_CAST(product_name_lenght_sou AS int),0) AS product_name_lenght_sou, 
    COALESCE(TRY_CAST(product_description_lengh_sou AS int),0) AS product_description_lengh_sou,
    COALESCE(TRY_CAST(product_photos_qty_sou AS int),0) AS product_photos_qty_sou, 
    COALESCE(TRY_CAST(product_weight_sou AS int),0) AS product_weight_sou,
    COALESCE(TRY_CAST(product_length_sou AS int),0) AS product_length_sou,
    COALESCE(TRY_CAST(product_height_sou AS int),0) AS product_height_sou,
    COALESCE(TRY_CAST(product_width_sou AS int),0) AS product_width_sou,
    'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Olist_DWH.Source_Layer.source_pro; 

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';

    --========================================
    -- Clean and Transform 'order' Table
    --========================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_Ord;

    -- Standardized the Table first

    WITH Standardized_SourceOrd AS (
        SELECT 
            REPLACE(TRIM([order_id_sou]), '"', '') AS [order_id],
            REPLACE(TRIM([customer_id_sou]), '"', '') AS [customer_id],
            LOWER(TRIM([order_status_sou])) AS [order_status],
            TRY_CAST([order_purchase_timestamp_sou] AS datetime2) AS [order_purchase_timestamp],
            TRY_CAST([order_approved_at_sou] AS datetime2) AS [order_approved_at],
            TRY_CAST([order_delivered_carier_date_sou] AS datetime2) AS [order_delivered_carrier_date],
            TRY_CAST([order_delivered_customer_date_sou] AS datetime2) AS [order_delivered_customer_date],
            TRY_CAST([order_estimated_delivery_date_sou] AS datetime2) AS [order_estimated_delivery_date]
        FROM [Olist_DWH].[Source_Layer].[source_ord]
    ),

    -- Handling Null and logical date error in Order Approval Date

    Handling_ApprovalDate AS (
        SELECT 
            [order_id], 
            [customer_id], 
            [order_status], 
            [order_purchase_timestamp],

            -- Clean and validate Approval Date
            CASE 
                -- Step 1: Null Handling for 'delivered' order status
                WHEN [order_status] = 'delivered' AND [order_approved_at] IS NULL THEN [order_purchase_timestamp]
                -- Step 2: Logic Handling: If approved before purchased, snap to purchase timestamp
                WHEN [order_approved_at] < [order_purchase_timestamp] THEN [order_purchase_timestamp]
                ELSE [order_approved_at]
            END AS [clean_order_approved_at],
            
            [order_delivered_carrier_date], 
            [order_delivered_customer_date],
            [order_estimated_delivery_date]
        FROM Standardized_SourceOrd
    ),

    -- Handling Null and logical date error in Order Carrier Date

    Handling_CarrierDate AS (
        SELECT 
            [order_id], 
            [customer_id], 
            [order_status], 
            [order_purchase_timestamp], 
            [clean_order_approved_at],

            -- Clean and validate Carrier Date
            CASE 
                -- Step 1: Null Handling for 'delivered' order status
                WHEN [order_status] = 'delivered' AND [order_delivered_carrier_date] IS NULL 
                    THEN COALESCE([clean_order_approved_at], [order_purchase_timestamp])
                -- Step 2: Logic Handling: If shipped before approved, snap to the approved timestamp
                WHEN [order_delivered_carrier_date] < [clean_order_approved_at] THEN [clean_order_approved_at]
                ELSE [order_delivered_carrier_date]
            END AS [clean_order_delivered_carrier_date],

            [order_delivered_customer_date], 
            [order_estimated_delivery_date]
        FROM Handling_ApprovalDate
    )

    -- Final Step: Handling Null and logical date error in Customer Delivery Date and insert into 'Stage_Ord' Table

    INSERT INTO Olist_DWH.Stage_Layer.Stage_Ord (
        order_id_stg,
        customer_id_stg,
        order_status_stg,
        purchase_timestamp_stg,
        approved_at_stg,
        delivered_carrier_date_stg,
        delivered_customer_date_stg,
        estimated_delivery_date_stg,
        file_location  
    )
    SELECT 
        [order_id],
        [customer_id],
        [order_status],
        [order_purchase_timestamp],
        [clean_order_approved_at],
        [clean_order_delivered_carrier_date],
        
        -- Clean and validate Customer Delivery Date
        CASE 
            -- Step 1: Null Handling for 'delivered' order status
            WHEN [order_status] = 'delivered' AND [order_delivered_customer_date] IS NULL THEN [order_estimated_delivery_date]
            -- Step 2: Logic Handling: If delivered before shipped, snap to carrier timestamp
            WHEN [order_delivered_customer_date] < [clean_order_delivered_carrier_date] THEN [clean_order_delivered_carrier_date]
            ELSE [order_delivered_customer_date]
        END AS [clean_order_delivered_customer_date],
        
        [order_estimated_delivery_date],
        'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Handling_CarrierDate;

    SET @EndTime = GETDATE();
	    PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
	    PRINT'--------------------';


    --==========================================
    -- Clean and Transform 'order Items' Table
    --==========================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_Ord_Items;

    INSERT INTO Olist_DWH.Stage_Layer.Stage_Ord_Items (
        order_id_stg,
        order_item_id_stg,
        product_id_stg,
        seller_id_stg,
        shipping_limit_date_stg,
        price_stg,
        freight_value_stg,
        file_location
    )
    SELECT
        REPLACE(TRIM(order_id_sou),'"','') AS order_id_sou,
        TRY_CAST(TRIM(order_item_id_sou) AS int) AS order_item_id_sou, 
        REPLACE(TRIM(product_id_sou),'"','') AS product_id_sou, 
        REPLACE(TRIM(seller_id_sou),'"','') AS seller_id_sou,
        TRY_CAST(TRIM(shipping_limit_date_sou) AS datetime2) AS shipping_limit_date_sou,
        TRY_CAST(TRIM(price_sou) AS decimal(10,2)) AS price_sou,
        TRY_CAST(TRIM(freight_value_sou) AS decimal(10,2)) AS freight_value_sou,
        'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Olist_DWH.Source_Layer.source_ordItems;

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';


    --============================================
    -- Clean and Transform 'order Payments' Table
    --============================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_OrdPayments;

    INSERT INTO Olist_DWH.Stage_Layer.Stage_OrdPayments (
        order_id_stg,
        payment_sequential_stg,
        payment_type_stg,
        payment_installments_stg,
        payment_value_stg,
        file_location
    )
    SELECT
        REPLACE(TRIM(order_id_sou),'"','') AS order_id_sou,
        TRY_CAST(TRIM(payment_sequential_sou) AS int) AS payment_sequential_sou, 
        UPPER(LEFT(TRIM (payment_type_sou),1)) + SUBSTRING(TRIM(payment_type_sou),2,LEN(TRIM(payment_type_sou))) AS payment_type_sou,
        TRY_CAST(TRIM(payment_installments_sou) AS int) AS payment_installments_sou, 
        TRY_CAST(TRIM(payment_value_sou) AS decimal(10,2)) AS payment_value_sou,
        'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive'
    FROM Olist_DWH.Source_Layer.source_ordPayment;

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';


    --============================================
    -- Clean and Transform 'order Reviews' Table
    --============================================

    SET @StartTime = GETDATE();

    DELETE FROM Olist_DWH.Stage_Layer.Stage_OrdReviews;

    -- First, find out rows that shifted due to broken 'review_comment_message' string
    WITH CleanedBase AS (
        SELECT
            review_id_sou,
            order_id_sou,
            TRY_CAST(review_score_sou AS INT) AS review_score_sou,
            TRIM(review_comment_title_sou) AS review_comment_title_sou,
            
            -- DYNAMIC FLAG: Detects any row shifted by quotes, tabs, or abnormal length
            CASE 
                WHEN LEN(TRIM(review_creation_date_sou)) > 19 
                    OR review_creation_date_sou LIKE '%"%'
                    OR review_creation_date_sou LIKE '%' + CHAR(9) + '%' -- Tab character
                THEN 1 ELSE 0 
            END AS is_shifted,

            review_comment_message_sou,
            review_creation_date_sou,
            review_answer_timestamp_sou
        FROM Olist_DWH.Source_Layer.source_orderReview
    ),

    -- Do the ETL for problematic columns or issues [ Found out during quality check]
    ETL_OrdReview_Final AS (
        SELECT
            review_id_sou,
            order_id_sou,
            review_score_sou,
            review_comment_title_sou,
            
            -- Recombine all text parts to restore the complete message
            CASE 
                WHEN is_shifted = 1
                THEN REPLACE(REPLACE(REPLACE(REPLACE(TRIM(CONCAT(review_comment_message_sou, ' ', review_creation_date_sou, ' ', review_answer_timestamp_sou)), CHAR(13), ''), CHAR(10), ' '), CONCAT(CHAR(92), 'r'), ''), CONCAT(CHAR(92), 'n'), ' ')
                ELSE REPLACE(REPLACE(REPLACE(REPLACE(TRIM(review_comment_message_sou), CHAR(13), ''), CHAR(10), ' '), CONCAT(CHAR(92), 'r'), ''), CONCAT(CHAR(92), 'n'), ' ') 
            END AS review_comment_message,

            -- Pull creation date from review_answer_timestamp_sou when shifted
            CASE 
                WHEN is_shifted = 1
                -- Take the last 40 characters of the timestamp column, and grab the first 19 characters
                THEN TRY_CAST(SUBSTRING(RIGHT(TRIM(review_answer_timestamp_sou), 39), 1, 19) AS DATETIME)
                ELSE TRY_CAST(TRIM(review_creation_date_sou) AS DATETIME)
            END AS review_creation_date,

            -- Pull answer timestamp from the end of review_answer_timestamp_sou when shifted
            CASE 
                WHEN is_shifted = 1
                -- Grab the right side 19 characters of the review_answer_timestamp column
                THEN TRY_CAST(RIGHT(TRIM(review_answer_timestamp_sou), 19) AS DATETIME)
                ELSE TRY_CAST(TRIM(review_answer_timestamp_sou) AS DATETIME)
            END AS review_answer_timestamp,
        
            'D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive' AS file_source_path
        FROM CleanedBase
    )

    INSERT INTO Olist_DWH.Stage_Layer.Stage_OrdReviews (
        review_id_stg,
        order_id_stg,
        review_score_stg,
        review_comment_title_stg,
        review_comment_message_stg,
        review_creation_date_stg,
        review_answer_timestamp_stg,
        file_location
    )

    SELECT
        review_id_sou,
        order_id_sou,
        review_score_sou,
        review_comment_title_sou,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        file_source_path
    FROM ETL_OrdReview_Final

    SET @EndTime = GETDATE();
		PRINT'>> Load Duration: ' + CAST (DATEDIFF(second, @startTime, @EndTime) AS NVARCHAR) + ' seconds';
		PRINT'--------------------';

END


EXEC Stage_Layer.StageData;


--======================================================
-- End of Extraction, Transform, and Load (ETL) Process
--======================================================
