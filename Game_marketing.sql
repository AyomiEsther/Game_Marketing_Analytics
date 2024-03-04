-- Loading my dataset
SELECT * FROM marketing_db.comprehensive_marketing_data;

-- Renaming my table name
RENAME TABLE comprehensive_marketing_data TO game_marketing;

-- checking the demographics of players
SELECT Age, Gender, Location,
COUNT(*) AS Total_Customers
FROM game_marketing
GROUP BY Age, Gender, Location;

-- Segmenting players by the product purchased
SELECT product_purchased,
COUNT(*) AS num_of_customers
FROM game_marketing
GROUP BY product_purchased;

-- Segmenting players by purchase amount range
SELECT
CASE
WHEN purchase_amount < 50 THEN '0-50'
WHEN purchase_amount BETWEEN 50 AND 100 THEN '50-100'
WHEN purchase_amount BETWEEN 101 AND 200 THEN '101-200'
ELSE 'Over 200'
END AS purchase_amount_range, COUNT(*) AS number_of_customers
FROM game_marketing 
GROUP BY purchase_amount_range;
-- Segmenting Players according to their age group
SELECT
CASE
WHEN age < 25 THEN 'Under 25'
WHEN age BETWEEN 25 AND 35 THEN '25-35'
WHEN age BETWEEN 36 AND 45 THEN '36-45'
ELSE 'Over 45'
END AS age_group, 
COUNT(*) AS number_of_customers
FROM game_marketing
GROUP BY age_group;
-- Analysing the difference between new and returning players 
SELECT Customer_Type, COUNT(*) AS Total_Customers,
ROUND((COUNT(*) / (SELECT COUNT(*) FROM game_marketing)) * 100, 2) AS Percentage
FROM game_marketing
GROUP BY Customer_Type;
-- Calculating total number of purchase for each product
SELECT count(product_purchased) AS Count_of_product, Product_Purchased FROM game_marketing
Group by Product_Purchased;
-- Calculating the amount made for each product
SELECT round(Avg(Purchase_Amount)) AS Avg_amount, Product_Purchased FROM game_marketing
Group by Product_Purchased;
-- Calculating Average amount made from each gender and counting the number of product tehy purchased
SELECT Gender, AVG(Purchase_Amount) AS Avg_Purchase_Amount, COUNT(Product_Purchased) AS Total_Purchases
FROM game_marketing
GROUP BY Gender;
-- Analyzing the conversion for all purchase channel
SELECT Purchase_Channel, SUM(CASE WHEN Product_Purchased IS NOT NULL THEN 1 ELSE 0 END) AS Conversions
FROM game_marketing
GROUP BY
    Purchase_Channel;
-- Counting the numbers of players that clicked the Ad 
SELECT 
COUNT(*) AS total_clicked_ads FROM game_marketing
WHERE Ad_Clicked = 'true';


-- Counting the number of customers who didn't click on ads
SELECT 
COUNT(*) AS total_clicked_ads FROM game_marketing
WHERE Ad_Clicked = 'False';

-- Creating a temporary table to store attribution data
CREATE TEMPORARY TABLE temp_marketing_table AS
SELECT c.Customer_ID, c.Customer_Type, p.Purchase_Amount,
CASE
WHEN c.Source = 'Online' AND p.Purchase_Channel = 'Website' THEN 'Online - Website'
WHEN c.Source = 'Online' AND p.Purchase_Channel = 'Mobile App' THEN 'Online - Mobile App'
WHEN c.Source = 'Offline' THEN 'Offline'
ELSE 'Other'
END AS Marketing_Channel
FROM game_marketing c
JOIN game_marketing p ON c.Customer_ID = p.Customer_ID;

-- Calculating  the total purchase amount for each customer segment and marketing channel
SELECT Customer_Type, Marketing_Channel,
COUNT(*) AS Purchase_Count,
SUM(Purchase_Amount) AS Total_Purchase_Amount
FROM temp_marketing_table
GROUP BY Customer_Type, Marketing_Channel;

-- CUSTOMER ENGAGEMENT
-- Calculating the average time spent per session
SELECT  DISTINCT(customer_ID), Avg(time_on_site) AS Average_time_spent FROM game_marketing GROUP BY Time_on_Site ORDER BY Time_on_Site DESC;

-- Calculating the average number of pages viewed per session for each customer
SELECT Customer_ID, AVG(Pages_Viewed) AS Average_Pages_Viewed_Per_Session
FROM game_marketing
GROUP BY Customer_ID;

-- Calculating average engagement metrics for email subscribers
SELECT
AVG(Time_on_Site) AS Avg_Time_on_Site,
AVG(Pages_Viewed) AS Avg_Pages_Viewed
FROM game_marketing
WHERE
    Email_Subscribed = 'True'

UNION

-- Calculating average engagement metrics for non-email subscribers
SELECT
    AVG(Time_on_Site) AS Avg_Time_on_Site,
    AVG(Pages_Viewed) AS Avg_Pages_Viewed
FROM game_marketing
WHERE
    Email_Subscribed = 'False';
-- Calculating average time spent by players, average pages viewed for email and news letters subscribers
SELECT Avg(Time_on_Site), Avg(Pages_Viewed), count(*) From game_marketing WHERE Email_Subscribed = 'TRUE' AND Newsletter_Subscribed = 'TRUE';
-- Calculating average time spent by players, average pages viewed for non-email and non-newsletters subscribers
SELECT Avg(Time_on_Site), Avg(Pages_Viewed), Count(*) From game_marketing WHERE Email_Subscribed = 'False'  AND Newsletter_Subscribed = 'False'


-- Calculating Customer's lifetime value(CLV) for different customer segments
SELECT
Customer_Type,
AVG(Total_Purchase_Amount) AS Average_CLV
FROM
(SELECT Customer_Type, Customer_ID, SUM(Purchase_Amount) AS Total_Purchase_Amount
FROM game_marketing
GROUP BY Customer_Type, Customer_ID) AS temp
GROUP BY Customer_Type;

-- Calculating the total number of customers for each subscription type
SELECT
Subscription_Type,
COUNT(*) AS Total_Customers,
COUNT(*) / (SELECT COUNT(*) FROM game_marketing) * 100 AS Percentage
FROM game_marketing
GROUP BY
Subscription_Type;
    
-- Creating a temporary table to store subscription changes
CREATE TEMPORARY TABLE temp_subscriptions AS
SELECT Customer_ID, Subscription_Type, Purchase_Date, LAG(Subscription_Type) OVER (PARTITION BY Customer_ID ORDER BY Purchase_Date) AS Previous_Subscription_Type
FROM game_marketing
WHERE
Subscription_Type IS NOT NULL;

-- Identifying subscription upgrades/downgrades
SELECT
Previous_Subscription_Type AS Previous_Type,
Subscription_Type AS Current_Type,
COUNT(*) AS Count
FROM temp_subscriptions
WHERE Previous_Subscription_Type IS NOT NULL
GROUP BY Previous_Subscription_Type, Subscription_Type
ORDER BY Previous_Subscription_Type, Subscription_Type;

-- Calculating conversion rate from website visit to product view
SELECT
'Website Visit -> Product View' AS Stage,
COUNT(DISTINCT Customer_ID) AS Total_Website_Visits,
SUM(CASE WHEN Pages_Viewed > 0 THEN 1 ELSE 0 END) AS Total_Product_Views,
SUM(CASE WHEN Pages_Viewed > 0 THEN 1 ELSE 0 END) / COUNT(DISTINCT Customer_ID) AS Conversion_Rate
FROM game_marketing;

-- Counting the number of customers at each stage of the funnel to gain insight into where customers drop off
SELECT 'Total Customers' AS Stage, COUNT(DISTINCT Customer_ID) AS Count
FROM game_marketing
UNION ALL
SELECT 'Website Visit' AS Stage,
COUNT(DISTINCT Customer_ID) AS Count 
FROM game_marketing
WHERE Source IS NOT NULL  -- Assuming Source indicates website visits
UNION ALL
SELECT 'Product View' AS Stage, COUNT(DISTINCT Customer_ID) AS Count FROM game_marketing
WHERE Pages_Viewed > 0  -- Assuming Pages_Viewed indicates product views
UNION ALL
SELECT 'Add to Cart' AS Stage, COUNT(DISTINCT Customer_ID) AS Count
FROM game_marketing
WHERE Purchase_Channel IN ('Website', 'Mobile App')  -- Assuming Purchase_Channel indicates adding to cart
UNION ALL
SELECT 'Purchase' AS Stage, COUNT(DISTINCT Customer_ID) AS Count
FROM game_marketing
WHERE
    Purchase_Amount > 0;


-- Counting the numbers of customer acquisitions and conversions by channel
SELECT Source,
COUNT(DISTINCT CASE WHEN Source IS NOT NULL THEN Customer_ID END) AS Acquisitions,
COUNT(DISTINCT CASE WHEN Purchase_Amount > 0 THEN Customer_ID END) AS Conversions
FROM game_marketing
GROUP BY Source
ORDER BY Conversions DESC, Acquisitions DESC;
    
-- Identifying the sequence of channel interactions before purchase for each customer
SELECT Customer_ID,
GROUP_CONCAT(DISTINCT Source ORDER BY Time_on_Site SEPARATOR ' -> ') AS Channel_Interactions,
Purchase_Date
FROM game_marketing
WHERE Customer_ID IN (
SELECT DISTINCT Customer_ID
FROM game_marketing
WHERE Purchase_Date IS NOT NULL)
GROUP BY Customer_ID, Purchase_Date;
    
-- Calculating revenue and conversions attributed to each source
SELECT Source,
SUM(CASE WHEN Purchase_Date IS NOT NULL THEN Purchase_Amount ELSE 0 END) AS Revenue,
COUNT(DISTINCT CASE WHEN Purchase_Date IS NOT NULL THEN Customer_ID END) AS Conversions
FROM game_marketing
WHERE Purchase_Date IS NOT NULL
GROUP BY Source;
    
-- Calculating churn rate according to my definition
SELECT
COUNT(DISTINCT CASE WHEN Purchase_Date < CURDATE() - INTERVAL 100 DAY THEN Customer_ID END) AS Churned_Customers,
COUNT(DISTINCT Customer_ID) AS Total_Customers,
(COUNT(DISTINCT CASE WHEN Purchase_Date < CURDATE() - INTERVAL 100 DAY THEN Customer_ID END) / COUNT(DISTINCT Customer_ID)) * 100 AS Churn_Rate
FROM game_marketing;

-- I should compare churn rates before and after implementing retention strategies...
-- Segmenting customers based on risk factors
SELECT
CASE
WHEN Pages_Viewed < 5 THEN 'Low Engagement'
ELSE 'High Engagement'
END AS Engagement_Level,
COUNT(DISTINCT Customer_ID) AS Customer_Count
FROM game_marketing
GROUP BY
CASE
WHEN Pages_Viewed < 5 THEN 'Low Engagement'
ELSE 'High Engagement' 
END;
