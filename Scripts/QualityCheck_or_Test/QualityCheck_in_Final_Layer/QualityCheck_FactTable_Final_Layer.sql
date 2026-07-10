
--==============================================
-- Gold or Final Layer Fact Table Sanity Check
--==============================================

-- Check the Row Number. It must be equal
SELECT COUNT (*) FROM Olist_DWH.Stage_Layer.Stage_Ord_Items;
SELECT COUNT (*) FROM Olist_DWH.Final_Layer.Fact_Order_Items;

-- Note: Yes, they are equal.

-- Duplicate check on Fact Table
SELECT order_id, order_item_id, COUNT(*) 
FROM Olist_DWH.Final_Layer.Fact_Order_Items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Note: No duplicate found.

/*   
If Stage_Ord Table has more than one row per order_id_stg (e.g., duplicate loads), 
LEFT JOIN oi-o will duplicate every order_item row. Let's check for 'order_id_stg' duplicate in this table.
*/
-- Duplicate check on Stage_Ord Table. 
SELECT order_id_stg, COUNT(*) 
FROM Olist_DWH.Stage_Layer.Stage_Ord
GROUP BY order_id_stg
HAVING COUNT(*) > 1;

-- Note: No duplicate found.

/*
Using LEFT JOIN to Dim_Customer, Dim_Seller, Dim_Product means unmatched business keys produce NULL surrogate keys instead of failing loudly. 
If our dimensions aren't 100% complete relative to staging, we'll get orphaned facts that silently break any downstream join/filter by those dimensions.
Let's check for this
*/
-- Check whether any NULL Surrogate Keys exist in our Fact Table
SELECT 
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS missing_customer,
    SUM(CASE WHEN seller_key IS NULL THEN 1 ELSE 0 END) AS missing_seller,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS missing_product,
    SUM(CASE WHEN purchase_date_key IS NULL THEN 1 ELSE 0 END) AS missing_date
FROM Olist_DWH.Final_Layer.Fact_Order_Items;

-- Note: No missing or NULL surrograte keys found in our fact table.

-- Reconciliation Test. Does the allocated total match the source total, per order?
SELECT 
    f.order_id,
    SUM(f.payment_value_allocated) AS allocated_total,
    p.total_payment AS source_total,
    SUM(f.payment_value_allocated) - p.total_payment AS diff
FROM Olist_DWH.Final_Layer.Fact_Order_Items f
JOIN (
    SELECT order_id_stg, SUM(payment_value_stg) AS total_payment 
    FROM Olist_DWH.Stage_Layer.Stage_OrdPayments 
    GROUP BY order_id_stg
) p ON f.order_id = p.order_id_stg
GROUP BY f.order_id, p.total_payment
HAVING ABS(SUM(f.payment_value_allocated) - p.total_payment) > 0.05
ORDER BY diff DESC;

-- For some rows (around 40), there is a little difference, but is less than 0.05 which is mostly because fraction calculation. No logical or calculation error.

SELECT 
oi.order_id_stg, 
SUM(oi.price_stg) AS total_price, 
pay.total_payment
FROM Olist_DWH.Stage_Layer.Stage_Ord_Items oi
LEFT JOIN (
    SELECT order_id_stg, SUM(payment_value_stg) AS total_payment 
    FROM Olist_DWH.Stage_Layer.Stage_OrdPayments GROUP BY order_id_stg
) pay ON oi.order_id_stg = pay.order_id_stg
GROUP BY oi.order_id_stg, pay.total_payment
HAVING SUM(oi.price_stg) = 0 OR SUM(oi.price_stg) IS NULL;


--=========================================
-- End of Sanity Check or Quality Test. 
-- Everything looks good!
--=========================================