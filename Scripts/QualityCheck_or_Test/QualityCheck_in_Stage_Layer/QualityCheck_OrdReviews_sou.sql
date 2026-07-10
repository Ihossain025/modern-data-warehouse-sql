
--==================================================================================
-- Quality Check of a 'source_orderReview' table before cleaning and transformation
--==================================================================================

-- First look at the data. Check whether data imported correctly. Any column shifted or not (just a visual check).

SELECT
*
FROM Olist_DWH.Source_Layer.source_orderReview;

-- Note: At a first glance, it looks like data imported correctly. 


-- Count total rows. Make sure it matches original .csv/.text data.

SELECT
COUNT(*) Row_Count
FROM Olist_DWH.Source_Layer.source_orderReview;

-- Note: Yes, it align with the number of rows of source data. 


/* 
-- As we had double quotes ('"') in key columns for other tables, let's also check for this table.
-- If it has, then we must remove them. Otherwise, our later join will break.
*/

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN review_id_sou LIKE '"%"' THEN 1 ELSE 0 END) AS rows_with_quotes,
	SUM(CASE WHEN order_id_sou LIKE '"%"' THEN 1 ELSE 0 END) AS rows_with_quotes   
FROM Olist_DWH.Source_Layer.source_orderReview;

-- Note: No rows with quotes in both key columns. That looks Good!


-- Now, let's check whether key columns ('order_id_sou' and 'review_id_sou' Columns) has Nulls / has duplicates
-- Expected Output: No Result

-- Check for Null first

SELECT
COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_id_sou IS NULL; -- change the column name here  

-- Note: No null values in key columns. That Looks Awesome!

-- Check for duplicates

-- for order_id
SELECT
	order_id_sou, 
	COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_orderReview
GROUP BY order_id_sou
HAVING COUNT(*) > 1;

--for review_id
SELECT
	review_id_sou, 
	COUNT(*) AS Rows_Count
FROM Olist_DWH.Source_Layer.source_orderReview
GROUP BY review_id_sou
HAVING COUNT(*) > 1;

-- Note: We do have duplicates in order_id_sou and review_id_sou. Let's find out why? Is it dúe to business logic or is it error? Let's explore!

SELECT
*
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_id_sou = '1fb4ddc969e6bea80e38deec00393a6f';     -- This is a review_id attached to more than 1 order. You can select several ones to see the pattern.

-- Note:
-- As we can see, each review_id is attached to  at least one order_id or more. In case of duplicates, it attched to either 2 or 3 order-id where review_score, review_title, review_comment, review_creation_date, review_answer_timestamp are equal.
-- What does it mean by business context?
/* The Business Context: 
- In modern e-commerce marketplaces like Olist, a customer adds multiple items to a single shopping cart and checks out all at once. 
- However, behind the scenes, those items might come from different third-party sellers or different warehouses.
- To handle shipping and logistics cleanly, the marketplace system splits that single checkout into separate sub-orders (different order_id values) for each seller or delivery package.
- When it comes time to collect feedback, Instead of annoying the customer with 3 separate emails asking for 3 separate reviews, the system sends one single email containing one single review link (review_id).
- The customer clicks the link once, writes a single comment, gives a single rating, and hits submit once.
- To ensure this feedback maps to all parts of that customer's purchasing journey, the system attaches that exact same review action to all the sub-orders generated during that checkout session.
*/
-- So, duplicate review_id_sou (same review_id_sou for different order_id_sou) make sense. We will keep it as it is for next layer. 

SELECT
*
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE order_id_sou = '02e0b68852217f5715fb9cc885829454';    -- This is a order_id_sou attched to 1 or more review_id_sou. You can select several ones to see the pattern.

-- Note: A single order_id can be mapped to multiple unique review_ids.

/* The Business Context: 
- This represents a timeline tracking history (similar to an SCD Type 2 pattern) for a single transaction. 
- It occurs when a customer interacts with the system multiple times for the same order, such as:
	1. Delivery Follow-ups: Separate items within the same order arrive on different days, triggering separate satisfaction surveys.
	2. Customer Support/Updates: A user submits an initial review, then later submits an updated comment/score after a resolution or delay.
*/

-- Note: So, thése duplicates are not actually data errors, rather a business logic or tactics.

/*
SILVER LAYER STRATEGY:
	# Because these are business logic, no rows are deleted. 
	# The combination of (order_id, review_id) is defined as the Composite Primary Key to safely preserve the full data spectrum.
*/


-- Check for Null values in other columns

SELECT
*
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_creation_date_sou IS NULL OR review_answer_timestamp_sou IS NULL;   -- change the column name here

-- Note: 
-- No Null values in review_score_sou, review_creation_date_sou, and review_answer_timestamp_sou column. That's good!
-- review_comment_title_sou and review_comment_message_sou have Nulls. But they are allowed to have Nulls. So, it's okay!


-- Check that each review score falls within the review score scale from 1-5

SELECT DISTINCT review_score_sou 
FROM Olist_DWH.Source_Layer.source_orderReview
ORDER BY review_score_sou ASC;

--Note: It falls within the scale. That's good!


-- Check Line Break Test for review_comment_title_sou & review_comment_message_sou

SELECT 
review_id_sou,
order_id_sou,
review_comment_message_sou -- Change column name here
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_comment_message_sou LIKE '%\r%'   -- Change column name here
   OR review_comment_message_sou LIKE '%\n%';  -- Change column name here

-- Note: We have found no rows for review_comment_title_sou, but found two rows for review_comment_message_sou. As it is very small percentage compared to our dataset, We will fix it while doing ETL for silver layer instead of importing source data again. 


-- Check Timestamp Validation (Review Creation Timestamp must be earlier than Review Answer Timestamp)

SELECT
*
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_creation_date_sou > review_answer_timestamp_sou;

-- Note: We got only 1 row. However, it is not due to date validation error, rather data import broke for this row. As only 1 row, we will also correct or handle it during ETL for next layer (Silver)


-- Validation Query to catch all broken rows

SELECT 
*
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_answer_timestamp_sou IS NOT NULL 
  -- A valid date string like '2018-01-24 00:00:00' should never contain quotes or tabs
  AND (review_answer_timestamp_sou LIKE '%"%' 
       OR review_answer_timestamp_sou LIKE '%' + CHAR(9) + '%' -- Tab character
       OR LEN(TRIM(review_answer_timestamp_sou)) > 19);       -- Normal date length is 19

-- Note: We got only 3 rows. We will fix them during ETL for stage layer.


-- Check for unwanted spaces (leading or trailing spaces in string columns)

SELECT
review_comment_title_sou   -- Change column name here
FROM Olist_DWH.Source_Layer.source_orderReview
WHERE review_comment_title_sou != TRIM(review_comment_title_sou);   -- Change column name here

-- Note: We do have leading or trailing spaces in string columns like review_comment_title_sou and review_comment_message_sou. We have to remove  them during ETL for next layer. 



--================================================================================
-- Quality Check of a 'Stage_OrdReviews' table after cleaning and transformation
--================================================================================

-- # Check the whole Table at a glance

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews;


-- # Check whether primary key (combination of 'review_id_stg' and 'order_id_stg') has any duplicates

SELECT
	review_id_stg,
	order_id_stg,
	COUNT(*) AS Rows_Count
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
GROUP BY review_id_stg, order_id_stg
HAVING COUNT(*) > 1;

-- Note: No duplicates present in primary key. Very Good!


-- # Check for Null values in datetime columns

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_creation_date_stg IS NULL OR review_answer_timestamp_stg IS NULL;

-- Note: No Null values present in review_creation_date_stg and review_answer_timestamp_stg. Very Good!


-- # Check datetime validation in date columns

SELECT
*
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_creation_date_stg > review_answer_timestamp_stg;

-- Note: No Datetime validation error in datetime columns. Looks Good!


-- # Check any broken string literal like '"' or '#' or Tab exist in date columns

-- Check review_answer_timestamp
SELECT 
*
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_answer_timestamp_stg IS NOT NULL                         
  -- A valid date string like '2018-01-24 00:00:00' should never contain quotes or tabs
  AND (review_answer_timestamp_stg LIKE '%"%'                         
       OR review_answer_timestamp_stg LIKE '%' + CHAR(9) + '%'        
       OR LEN(review_answer_timestamp_stg) > 19);                     

-- Check review_creation_date
SELECT 
*
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_creation_date_stg IS NOT NULL                         
  -- A valid date string like '2018-01-24 00:00:00' should never contain quotes or tabs
  AND (review_creation_date_stg LIKE '%"%'                         
       OR review_creation_date_stg LIKE '%' + CHAR(9) + '%'        
       OR LEN(review_creation_date_stg) > 19);  

-- Note: No unexpected literal string  exist in date columns. Looks good!


-- # Check whether review_comment_message contains literal correcters like '\r' or '\n' 
SELECT 
*
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_comment_message_stg LIKE '%\r%'
	  OR review_comment_message_stg LIKE '%\n%';

-- Note: No rows found. That means no rows in review_comment_message contain literal string like '\r' or '\n'. Good! 


-- # Check for unwanted spaces (leading or trailing spaces in string columns)

-- Check review_comment_title
SELECT
review_comment_title_stg   -- Change column name here
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_comment_title_stg != TRIM(review_comment_title_stg);

-- Check review_comment_message
SELECT
review_comment_message_stg   -- Change column name here
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
WHERE review_comment_message_stg != TRIM(review_comment_message_stg);

-- Note: No leading or trailing spaces found in string columns. Good!


-- Check the review score. Make sure  it falls within the review score scale from 1-5

SELECT DISTINCT review_score_stg 
FROM Olist_DWH.Stage_Layer.Stage_OrdReviews
ORDER BY review_score_stg ASC;


--===========================================
-- All checks return expected results. Wow!!!
--===========================================