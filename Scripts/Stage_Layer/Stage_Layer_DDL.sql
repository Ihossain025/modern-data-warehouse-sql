/*
--=================================================
-- DDL Script: Create Silver or Stage Layer Tables
--=================================================
This script creates tables for Silver or Stage Layer in the Datawarehouse. 
The Silver/Stage Layer represents cleaned, transformed, and processed data.
In this layer, table columns are defined with correct data types.
*/

-- Use or Select the correct Database
USE Olist_DWH;

-- Drop tables in reverse dependency order to prevent drop errors

DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_OrdReviews;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_OrdPayments;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_Ord_Items;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_Ord;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_Pro;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_Sell;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_Cus;
DROP TABLE IF EXISTS Olist_DWH.Stage_Layer.Stage_Geo;

-- Create Geolocation Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_Geo (
    zip_code_prefix_stg VARCHAR(50) NOT NULL,
    latitude_stg DECIMAL(10, 6) NULL,
    longitude_stg DECIMAL(10, 6) NULL,
    city_stg VARCHAR(100) NULL,
    state_stg VARCHAR(100) NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_Stage_Geo PRIMARY KEY (zip_code_prefix_stg)
);

-- Create Customers Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_Cus (
    customer_id_stg VARCHAR(50) NOT NULL,
    customer_unique_id_stg VARCHAR(50) NOT NULL,
    zip_code_prefix_stg VARCHAR(50) NOT NULL,
    city_stg VARCHAR(100) NULL,
    state_stg VARCHAR(100) NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_Stage_Cus PRIMARY KEY (customer_id_stg)
);

-- Create Sellers Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_Sell (
    seller_id_stg VARCHAR(50) NOT NULL,
    zip_code_prefix_stg VARCHAR(50) NOT NULL,
    city_stg VARCHAR(100) NULL,
    state_stg VARCHAR(100) NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_Stage_Sell PRIMARY KEY (seller_id_stg)
);

-- Create Products Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_Pro (
    product_id_stg VARCHAR(50) NOT NULL,
    product_category_name_stg VARCHAR(100) NULL,
    product_name_length_stg INT NULL,
    product_description_length_stg INT NULL,
    product_photos_qty_stg INT NULL,
    product_weight_g_stg INT NULL,
    product_length_cm_stg INT NULL,
    product_height_cm_stg INT NULL,
    product_width_cm_stg INT NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_Stage_Pro PRIMARY KEY (product_id_stg)
);

-- Create Orders Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_Ord (
    order_id_stg VARCHAR(50) NOT NULL,
    customer_id_stg VARCHAR(50) NOT NULL,
    order_status_stg VARCHAR(50) NOT NULL,
    purchase_timestamp_stg DATETIME2(0) NOT NULL,
    approved_at_stg DATETIME2(0) NULL,
    delivered_carrier_date_stg DATETIME2(0) NULL,
    delivered_customer_date_stg DATETIME2(0) NULL,
    estimated_delivery_date_stg DATETIME2(0) NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_Stage_Ord PRIMARY KEY (order_id_stg),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (customer_id_stg) REFERENCES Olist_DWH.Stage_Layer.Stage_Cus(customer_id_stg)
);

-- Create Order Items Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_Ord_Items (
    order_id_stg VARCHAR(50) NOT NULL,
    order_item_id_stg INT NOT NULL,
    product_id_stg VARCHAR(50) NOT NULL,
    seller_id_stg VARCHAR(50) NOT NULL,
    shipping_limit_date_stg DATETIME2(0) NOT NULL,
    price_stg DECIMAL(10, 2) NOT NULL,
    freight_value_stg DECIMAL(10, 2) NOT NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY (order_id_stg, order_item_id_stg),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (order_id_stg) REFERENCES Olist_DWH.Stage_Layer.Stage_Ord(order_id_stg),
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (product_id_stg) REFERENCES Olist_DWH.Stage_Layer.Stage_Pro(product_id_stg),
    CONSTRAINT FK_OrderItems_Sellers FOREIGN KEY (seller_id_stg) REFERENCES Olist_DWH.Stage_Layer.Stage_Sell(seller_id_stg)
);

-- Create Order Payments Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_OrdPayments (
    order_id_stg VARCHAR(50) NOT NULL,
    payment_sequential_stg INT NOT NULL,
    payment_type_stg VARCHAR(50) NOT NULL,
    payment_installments_stg INT NOT NULL,
    payment_value_stg DECIMAL(10, 2) NOT NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_Stage_OrdPayments PRIMARY KEY (order_id_stg, payment_sequential_stg),
    CONSTRAINT FK_OrderPayments_Orders FOREIGN KEY (order_id_stg) REFERENCES Olist_DWH.Stage_Layer.Stage_Ord(order_id_stg)
);

-- Create Order Reviews Table

CREATE TABLE Olist_DWH.Stage_Layer.Stage_OrdReviews (
    review_id_stg VARCHAR(50) NOT NULL,
    order_id_stg VARCHAR(50) NOT NULL,
    review_score_stg INT NOT NULL,
    review_comment_title_stg VARCHAR(250) NULL,
    review_comment_message_stg VARCHAR(MAX) NULL,
    review_creation_date_stg DATETIME2(0) NOT NULL,
    review_answer_timestamp_stg DATETIME2(0) NOT NULL,
	dwh_create_date_stg DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,
    CONSTRAINT PK_OrderReviews PRIMARY KEY (review_id_stg, order_id_stg),
    CONSTRAINT FK_OrderReviews_Orders FOREIGN KEY (order_id_stg) REFERENCES Olist_DWH.Stage_Layer.Stage_Ord(order_id_stg)
);
GO
