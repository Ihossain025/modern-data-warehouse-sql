
--=====================================================================================
-- Test the ETL Code for 'Order_Review' Table before inserting it to the silver layer
--=====================================================================================

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

-- Check whether that specific rows (message broken and shifted to right side columns) are fixed. 
SELECT 
    review_id_sou,
    order_id_sou,
	review_score_sou
	review_comment_title_sou,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM ETL_OrdReview_Final
WHERE review_id_sou IN ('a055208b63d6d19194742d36b6d0b80e', '79827eb040b1b36623d82e7f0ea06200', 'ff1b17c14d325000c4e2e54afd18c2f0')
  AND order_id_sou IN ('9bdf94af058f959fbc09c3ea1eb32465', '527676fa1c791f44e2eef1579abf401e', '180956bcbdf2ff42e547ec8dec11ed1f');

-- Note: Yes, those specific columns are now fixed. All columns now contain the right value or content, specifically date columns now contains correct datetime value.



-- Check whether the fixation created any Nulls or errors in date columns
SELECT 
*
FROM ETL_OrdReview_Final
WHERE review_creation_date IS NULL OR review_answer_timestamp IS NULL;

-- Note: No Nulls in review_creation_date and review_answer_timestamp



-- Check whether fixation created any logical date errors in date columns
SELECT
*
FROM ETL_OrdReview_Final
WHERE review_creation_date > review_answer_timestamp;

--Note: No rows found. Means all review_creation_date are smaller than review_answer_timestamp. That's good! 



-- Check whether review_comment_message still contains literal correcters like '\r' or '\n' 
SELECT 
*
FROM ETL_OrdReview_Final
WHERE review_comment_message LIKE '%\r%'   -- Change column name here
	  OR review_comment_message LIKE '%\n%';  -- Change column name here

-- Note: No rows found. That means no rows in review_comment_message contain literal string like '\r' or '\n'. Good! 


--======================================================================
-- All key checks or tests were successful. 
-- Now, let's insert the data into 'OrdReviews' Table for Stage Layer
--======================================================================














