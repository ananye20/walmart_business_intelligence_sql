--Create Table

CREATE TABLE walmart (
    invoice_id INTEGER PRIMARY KEY,
    Branch TEXT,
    City TEXT,
    category TEXT,
    unit_price MONEY,
    quantity DECIMAL,
    date TEXT,
    time TIME,
    payment_method TEXT,
    rating DECIMAL(4,2),
    profit_margin DECIMAL(5,2)
);

--Check if imported succesfully
SELECT *
FROM walmart;

--Convert Date
ALTER TABLE walmart 
ALTER COLUMN date TYPE DATE 
USING TO_DATE(date, 'DD/MM/YY');

/* 
██     ██  █████  ██      ███    ███  █████  ██████  ████████
██     ██ ██   ██ ██      ████  ████ ██   ██ ██   ██    ██   
██  █  ██ ███████ ██      ██ ████ ██ ███████ ██████     ██   
██ ███ ██ ██   ██ ██      ██  ██  ██ ██   ██ ██   ██    ██   
 ███ ███  ██   ██ ███████ ██      ██ ██   ██ ██   ██    ██   
*/


-- 🛒 WALMART BUSINESS PROBLEMS

-- Question: What are the different payment methods, and how many transactions and items were sold with each method?
-- Purpose: This helps understand customer preferences for payment methods, aiding in payment optimization strategies.

SELECT payment_method,
COUNT(*) as transactions_count,
SUM(quantity) as items_sold
FROM walmart
GROUP BY 1;

-- Question: Which category received the highest average rating in each branch?
-- Purpose: This allows Walmart to recognize and promote popular categories in specific branches, enhancing customer satisfaction and branch-specific marketing.

WITH highest_avg as (SELECT branch, category, AVG(rating) as avg1,
RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
FROM walmart
GROUP BY branch, category
ORDER BY 1)

SELECT branch, category, ROUND(avg1,2) as avg_rating
FROM highest_avg
WHERE rank = 1;

--Question: What is the busiest day of the week for each branch based on transaction volume?
--Purpose: This insight helps in optimizing staffing and inventory management to accommodate peak days.

WITH dayinc as (SELECT branch, TO_CHAR(date, 'Day') AS day_name, COUNT(*) trans_ct,
RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
FROM walmart
GROUP BY branch, day_name
ORDER BY 1)

SELECT branch, day_name, trans_ct as transaction_volume
FROM dayinc
WHERE rank=1;

--Question: Which cities contribute the most to overall revenue (TOP 5)?
--Purpose: Helps in market segmentation and identifying high-value locations for future investments.

SELECT city, SUM(unit_price*quantity) as overall_revenue
FROM walmart
GROUP BY 1
ORDER BY 1 DESC
LIMIT 5;

--Question: What are the average, minimum, and maximum ratings for each category in each city?
--Purpose: This data can guide city-level promotions, allowing Walmart to address regional preferences and improve customer experiences.

SELECT city, category, ROUND(AVG(rating),2) as avg_rating, ROUND(MIN(rating),2) as min_rating, ROUND(MAX(rating),2) as max_rating
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 2;

--Question: What is the total profit for each category, ranked from highest to lowest?
--Purpose: Identifying high-profit categories helps focus efforts on expanding these products or managing pricing strategies effectively.

SELECT category, SUM(unit_price*quantity*profit_margin) as profit,
RANK() OVER (ORDER BY SUM(unit_price*quantity*profit_margin) DESC) as rank_of_category
FROM walmart
GROUP BY 1;

--Question: What is the most frequently used payment method in each branch?
--Purpose: This information aids in understanding branch-specific payment preferences, potentially allowing branches to streamline their payment processing systems.

WITH payment as (SELECT branch, payment_method, COUNT(payment_method) as count_of_pym_method,
RANK() OVER (PARTITION BY branch ORDER BY COUNT(payment_method) DESC) as rank_of_pym_method
FROM walmart
GROUP BY 1,2)

SELECT branch, payment_method, count_of_pym_method
FROM payment
WHERE rank_of_pym_method=1;

--Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
--Purpose: This insight helps in managing staff shifts and stock replenishment schedules, especially during high-sales periods.

WITH shifts as (SELECT *,
CASE WHEN EXTRACT(HOUR FROM time)<12 THEN 'Morning'
WHEN EXTRACT(HOUR FROM time) BETWEEN 12 AND 15 THEN 'Afternoon'
ELSE 'Evening' END
as Shift
FROM walmart)

SELECT branch, Shift, COUNT(*) as total_transactions
FROM shifts
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

--Question: Which branches experienced the largest decrease in revenue compared to the previous year?
--Purpose: Detecting branches with declining revenue is crucial for understanding possible local issues and creating strategies to boost sales or mitigate losses.

WITH cte as(SELECT branch, EXTRACT(YEAR FROM date) as year, SUM(unit_price*quantity) as revenue
FROM walmart
WHERE EXTRACT(YEAR FROM date) IN ('2023', '2022')
GROUP BY 1, 2
ORDER BY 1,2 DESC),

year_wise as(SELECT branch,
SUM(CASE WHEN year='2022' THEN revenue
END) as "2022",
SUM(CASE WHEN year='2023' THEN revenue
END) as "2023"
FROM cte
GROUP BY 1)

--TOP 10 WITH MOST DECLINE THIS YEAR
SELECT branch, "2022", "2023", ("2022"-"2023")*100/"2022" as revenue_percentage_decline
FROM year_wise
ORDER BY revenue_percentage_decline DESC
LIMIT 10;

--Question: Do higher-rated categories have higher sales?
--Purpose: Helps determine if customer satisfaction directly impacts sales volume.

SELECT category, 
ROUND(AVG(rating),2) AS avg_rating, ROUND(AVG(CAST(unit_price AS NUMERIC) * quantity),2) AS avg_sales_value
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

--Question: Which month has the highest total sales for each branch (TOP 3)?
--Purpose: Helps optimize inventory, staffing, and marketing for peak sales periods.

WITH monthly_rank as (SELECT branch, EXTRACT(MONTH FROM date) as month, SUM(unit_price*quantity) as total_sales,
RANK() OVER (PARTITION BY branch ORDER BY SUM(unit_price*quantity) DESC) as rank_of_sales
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 4)

SELECT branch, TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month') AS month_name, total_sales
FROM monthly_rank
WHERE rank_of_sales IN (1,2,3);

--Question: Which branch has the highest profit margin relative to its sales volume? (TOP 5)
--Purpose: Helps assess which stores are performing most efficiently.

SELECT branch, (SUM(unit_price*profit_margin*quantity)*100)/SUM(unit_price*quantity) as efficiency_percentage
FROM walmart
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

--Question: Do higher purchase quantities result in higher profit margins?
--Purpose: Helps assess if bulk purchases lead to greater profitability.

SELECT quantity, SUM(unit_price*profit_margin*quantity)*100/SUM(unit_price*quantity) as profit_margin_percentage
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

--Question: How many transactions occurred on weekends (Saturday, Sunday)?
--Purpose: Helps identify sales trends on certain days, which could guide staffing or promotional strategies.

WITH week_data as(SELECT TO_CHAR(date, 'Day') AS day_of_week, COUNT(*) as count_of_transactions
FROM walmart
GROUP BY 1)

SELECT *
FROM week_data
WHERE day_of_week LIKE 'S%';

--Question: Which invoice corresponds to the transaction where a branch’s cumulative sales touches $10K, identifying the customer eligible for a lucky gift coupon (cashback reward of amount exceeding $10K in that transaction)? (Not all branches might have had $10K+ sales)
--Purpose: Walmart wants to reward customers who contribute to significant sales milestones in a branch. By identifying the first transaction where a branch’s cumulative sales exceed $1000, Walmart can recognize and reward the customer extra amount he/she spent over $10K in that transaction.

WITH msum as (SELECT branch, invoice_id, SUM(unit_price*quantity) OVER (PARTITION BY branch ORDER BY date) as moving_sum
FROM walmart
GROUP BY 1, 2),

ranked as (SELECT branch, invoice_id, moving_sum, ROW_NUMBER() OVER (PARTITION BY branch ORDER BY moving_sum) as rank_ids
FROM msum
WHERE moving_sum> '$10000')

SELECT branch, invoice_id, moving_sum as amount_after_10K, moving_sum-'$10000' as cashback_reward
FROM ranked
WHERE rank_ids =1
ORDER BY cashback_reward DESC;

--Question: What percentage of transactions are above a certain spending threshold (e.g., $100)?
--Purpose: Helps analyze high-value customer behavior and potential for premium customer segmentation.

SELECT (SELECT COUNT(*)
FROM walmart
WHERE (unit_price*quantity)>'$100')*100/COUNT(*) as transactions_above100$_percentage
FROM walmart;

--Question: What is the contribution of each category to total revenue per branch?
--Purpose: Helps determine which product categories drive revenue and which need improvement.

WITH cte as (SELECT SUM(unit_price*quantity) as tot FROM walmart)

SELECT category, SUM(unit_price*quantity)*100/(SELECT tot FROM cte) as percentage_contribution
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

--Question: Which branches contribute the most to overall profit margins?
--Purpose: Helps Walmart identify the most profitable branches, allowing for strategic investment in high-performing locations and targeted improvements in lower-margin branches. 

WITH cte as (SELECT SUM(unit_price*quantity*profit_margin) as tot FROM walmart)

SELECT branch, SUM(unit_price*quantity*profit_margin)*100/(SELECT tot FROM cte) as percentage_contribution
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

--Question: Which customer has made the highest total purchases in terms of cost?
--Purpose: Helps Walmart identify high-value customers, enabling targeted loyalty programs, personalized promotions, and VIP rewards

SELECT invoice_id
FROM walmart
WHERE invoice_id = (SELECT invoice_id
FROM walmart
GROUP BY 1
ORDER BY SUM(unit_price*quantity) DESC
LIMIT 1);

--Question: What is the average transaction value per city?
--Purpose: Helps understand spending behavior in different locations for pricing strategies.

SELECT city, SUM(unit_price*quantity)/COUNT(*) as ct
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

--Question: Which city has the highest total revenue, and what percentage does it contribute to overall sales?
--Purpose: Helps focus marketing efforts on high-revenue locations.

WITH revenue_per_city AS (SELECT city, SUM(unit_price * quantity) AS total_revenue
FROM walmart
GROUP BY city),

total_sales AS (SELECT SUM(total_revenue) AS overall_revenue FROM revenue_per_city),

highest AS (SELECT city, total_revenue 
FROM revenue_per_city
ORDER BY total_revenue DESC
LIMIT 1)

SELECT h.city, h.total_revenue, (h.total_revenue * 100.0 / t.overall_revenue) AS percentage_contribution
FROM highest h
CROSS JOIN total_sales t;

--END--