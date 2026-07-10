/*
--=================================================
-- DDL Script: Create Gold or Final Layer Tables
--=================================================
This script creates tables for Gold or Final Layer in the Datawarehouse. 
The Gold/Final Layer represents final Fact and Dimension Tables (Star Schema)
*/

-- Use target database and schema
Use Olist_DWH;
GO

-- Drop tables in reverse dependency in order to prevent drop errors
DROP TABLE IF EXISTS Olist_DWH.Final_Layer.Fact_Order_Items;
DROP TABLE IF EXISTS Olist_DWH.Final_Layer.Dim_Product;
DROP TABLE IF EXISTS Olist_DWH.Final_Layer.Dim_Seller;
DROP TABLE IF EXISTS Olist_DWH.Final_Layer.Dim_Customer;
DROP TABLE IF EXISTS Olist_DWH.Final_Layer.Dim_Date;

--==========================
-- Create Dimension Tables
--==========================

-- Create Table 'Dim_Date'
CREATE TABLE Olist_DWH.Final_Layer.Dim_Date (
    date_key INT NOT NULL,
    full_date DATE NOT NULL,
    day_of_month INT NOT NULL,
    month_number INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    _quarter INT NOT NULL,
    _year INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,

	dwh_create_date DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,

    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (date_key)
);

-- Create Table 'Dim_Customer'
CREATE TABLE Olist_DWH.Final_Layer.Dim_Customer (
    customer_key INT IDENTITY(1,1) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code VARCHAR(50) NULL,
    customer_city VARCHAR(100) NULL,
    customer_state VARCHAR(100) NULL,

	dwh_create_date DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,

    CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (customer_key)
);

-- Create Table 'Dim_Seller'
CREATE TABLE Olist_DWH.Final_Layer.Dim_Seller (
    seller_key INT IDENTITY(1,1) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    seller_zip_code VARCHAR(50) NOT NULL,
    seller_city VARCHAR(100) NULL,
    seller_state VARCHAR(100) NULL,

	dwh_create_date DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,

    CONSTRAINT PK_DimSeller PRIMARY KEY CLUSTERED (seller_key)
);

-- Create Table 'Dim_Product'
CREATE TABLE Olist_DWH.Final_Layer.Dim_Product (
    product_key INT IDENTITY(1,1) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    category_name VARCHAR(100) NULL,
    weight_g INT NULL,
	length_cm INT NULL,
	height_cm INT NULL,
	width_cm INT NULL,

	dwh_create_date DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,

    CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (product_key)
);

--=====================
-- Create Fact Tables
--=====================

-- Create Table 'Fact_Order_Items'
CREATE TABLE Olist_DWH.Final_Layer.Fact_Order_Items (
    fact_item_key INT IDENTITY(1,1) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    customer_key INT NOT NULL,
    seller_key INT NOT NULL,
    product_key INT NOT NULL,
    purchase_date_key INT NOT NULL,
    order_status VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,
    review_score_avg INT NULL,
    payment_value_allocated DECIMAL(10,2) NOT NULL,

	dwh_create_date DATETIME2(0) NOT NULL DEFAULT GETDATE(),
	file_location VARCHAR(250) NOT NULL,

    CONSTRAINT PK_FactOrderItems PRIMARY KEY CLUSTERED (fact_item_key),
    CONSTRAINT FK_Fact_Customer FOREIGN KEY (customer_key) REFERENCES Olist_DWH.Final_Layer.Dim_Customer(customer_key),
    CONSTRAINT FK_Fact_Seller FOREIGN KEY (seller_key) REFERENCES Olist_DWH.Final_Layer.Dim_Seller(seller_key),
    CONSTRAINT FK_Fact_Product FOREIGN KEY (product_key) REFERENCES Olist_DWH.Final_Layer.Dim_Product(product_key),
    CONSTRAINT FK_Fact_Date FOREIGN KEY (purchase_date_key) REFERENCES Olist_DWH.Final_Layer.Dim_Date(date_key)
);
GO
