/*
--=====================================================================
-- ETL Script: Clean, Transform, and Populate Gold/Final Layer Tables
--=====================================================================
This script performed some business transformation (aggregation of measures, tables integration etc.) on stage layer tables and then populate gold/final layer tables. 

The 'Dim_Date' dimension table creates by our own. Other dimension tables comes from our silver or stage layer with cleaned and transformed data. 
The Fact Table combines data from several tables (See our Data Flow Diagram) of silver or stage layer to produce clean, transformed, and business ready data.
*/

--=================================
--Populate Dimension Tables first
--=================================

-- Populate 'Dim_Date' Table (Generate dynamically across operational bounds)
DECLARE @StartDate DATE = '2016-01-01';   -- Min(CAST((purchase_timestamp_stg) AS date)) = 2016-09-04
DECLARE @EndDate DATE = '2020-12-31';     -- MAX(CAST((purchase_timestamp_stg) AS date)) = 2018-10-17

DELETE FROM Olist_DWH.Final_Layer.Dim_Date;

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO Olist_DWH.Final_Layer.Dim_Date(
	date_key, 
	full_date, 
	day_of_month, 
	month_number, 
	month_name, 
	_quarter, 
	_year, 
	day_of_week, 
	day_name,
	file_location
)
VALUES(
    YEAR(@StartDate) * 10000 + MONTH(@StartDate) * 100 + DAY(@StartDate),
    @StartDate,
    DAY(@StartDate),
    MONTH(@StartDate),
    DATENAME(month, @StartDate),
    DATEPART(quarter, @StartDate),
    YEAR(@StartDate),
    DATEPART(weekday, @StartDate),
    DATENAME(weekday, @StartDate),
	'Deducted from data'
);
    SET @StartDate = DATEADD(day, 1, @StartDate);
END;
GO

-- Populate 'Dim_Customer' Table

DELETE FROM Olist_DWH.Final_Layer.Dim_Customer; 

INSERT INTO Olist_DWH.Final_Layer.Dim_Customer(
    customer_id,
    customer_unique_id,
    customer_zip_code,
    customer_city,
    customer_state,
	file_location
)
SELECT 
	customer_id_stg, 
	customer_unique_id_stg, 
	zip_code_prefix_stg, 
	city_stg, 
	state_stg,
	'Olist_DWH.Stage_Layer.Stage_Cus'
FROM Olist_DWH.Stage_Layer.Stage_Cus;


-- Populate 'Dim_Seller' Table

DELETE FROM Olist_DWH.Final_Layer.Dim_Seller; 

INSERT INTO Olist_DWH.Final_Layer.Dim_Seller(
    seller_id,
    seller_zip_code,
    seller_city,
    seller_state,
	file_location
)
SELECT 
	seller_id_stg, 
	zip_code_prefix_stg, 
	city_stg, 
	state_stg,
	'Olist_DWH.Stage_Layer.Stage_Sell'
FROM Olist_DWH.Stage_Layer.Stage_Sell;


-- Populate 'Dim_Product' Table

DELETE FROM Olist_DWH.Final_Layer.Dim_Product;

INSERT INTO Olist_DWH.Final_Layer.Dim_Product(
    product_id,
    category_name,
    weight_g,
	length_cm,
	height_cm,
	width_cm,
	file_location
)
SELECT 
	product_id_stg, 
	product_category_name_stg, 
	product_weight_g_stg,
	product_length_cm_stg,
	product_height_cm_stg,
	product_width_cm_stg,
	'Olist_DWH.Stage_Layer.Stage_Pro'
FROM Olist_DWH.Stage_Layer.Stage_Pro;


--=============================================
--Populate Fact Tables after Dimension Tables
--=============================================

-- Populate 'Fact_Order_Items' Table (Denormalizing and Aggregating Measures)

DELETE FROM Olist_DWH.Final_Layer.Fact_Order_Items;

INSERT INTO Olist_DWH.Final_Layer.Fact_Order_Items(
    order_id,
    order_item_id,
    customer_key,
    seller_key,
    product_key,
    purchase_date_key,
    order_status,
    price,
    freight_value,
    review_score_avg,
    payment_value_allocated,
	file_location
)
SELECT 
    oi.order_id_stg,
    oi.order_item_id_stg,
    dc.customer_key,
    ds.seller_key,
    dp.product_key,
    (YEAR(o.purchase_timestamp_stg) * 10000 + MONTH(o.purchase_timestamp_stg) * 100 + DAY(o.purchase_timestamp_stg)) AS purchase_date_key,
    o.order_status_stg,
    oi.price_stg,
    oi.freight_value_stg,
	rev.avg_score,
    -- Business Logic: Evenly distribute structural payments down to the explicit line-item level
    ISNULL((pay.total_payment * (oi.price_stg / NULLIF(tot.total_price, 0))), 0) AS payment_value_allocated,
	'Deducted from Data'
FROM Olist_DWH.Stage_Layer.Stage_Ord_Items oi
LEFT JOIN Olist_DWH.Stage_Layer.Stage_Ord o ON oi.order_id_stg = o.order_id_stg
LEFT JOIN Olist_DWH.Final_Layer.Dim_Customer dc ON o.customer_id_stg = dc.customer_id
LEFT JOIN Olist_DWH.Final_Layer.Dim_Seller ds ON oi.seller_id_stg = ds.seller_id
LEFT JOIN Olist_DWH.Final_Layer.Dim_Product dp ON oi.product_id_stg = dp.product_id
LEFT JOIN (
    SELECT order_id_stg, AVG(review_score_stg) AS avg_score 
    FROM Olist_DWH.Stage_Layer.Stage_OrdReviews GROUP BY order_id_stg
) rev ON oi.order_id_stg = rev.order_id_stg
LEFT JOIN (
    SELECT order_id_stg, SUM(payment_value_stg) AS total_payment 
    FROM Olist_DWH.Stage_Layer.Stage_OrdPayments GROUP BY order_id_stg
) pay ON oi.order_id_stg = pay.order_id_stg
LEFT JOIN (
    SELECT order_id_stg, SUM(price_stg) AS total_price 
    FROM Olist_DWH.Stage_Layer.Stage_Ord_Items GROUP BY order_id_stg
) tot ON oi.order_id_stg = tot.order_id_stg;
GO
