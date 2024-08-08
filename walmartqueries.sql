CREATE DATABASE IF NOT EXISTS salesdatawalmart;

CREATE TABLE IF NOT EXISTS sales( 
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
	branch VARCHAR(1) NOT NULL,
	city VARCHAR(30) NOT NULL,
	customer_type VARCHAR(15) NOT NULL,
	gender VARCHAR(10) NOT NULL,
	product_line VARCHAR(100) NOT NULL,
	unit_price DECIMAL(10, 2) NOT NULL,
	quantity INT NOT NULL,
	VAT DECIMAL(6, 4) NOT NULL,
	total DECIMAL(10, 2) NOT NULL,
	date DATE NOT NULL,
	time TIME NOT NULL,
	payment_method TEXT NOT NULL,
	COGS DECIMAL(10, 2) NOT NULL,
	gross_margin_pct DECIMAL(11, 9) NOT NULL,
	gross_income DECIMAL(10, 2) NOT NULL,
	rating DECIMAL(2, 1) NOT NULL
);
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ***====Feature Engineering====***

-- ***====time_of_day====***
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(10); -- // Adds our new column to our table. //

UPDATE sales  
SET time_of_day = CASE  -- // This will actually add data to the time_of_day column. Otherwise, it'll return a ton of NULL values. //
	WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
    WHEN time BETWEEN '12:00:01' AND '16:00:00' THEN 'Afternoon'
    ELSE 'Evening'
END;

-- ***====day_name====***
ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(date);

-- ***====month_name====***
ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(DATE);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ***==== Generic Business Questions ====*** 
-- 1.) How many unique cities does the data have? *A.) 3 unique cities.
SELECT DISTINCT city 
FROM sales;

-- 2.) In which city is each branch? *A.) Yangon is located in A branch, Mandalay is located in B branch, and finally Naypyitaw is located in C branch.
SELECT DISTINCT branch, city
FROM sales;

-- ***==== Product Questions ====***

-- 1.) How many unique product lines does the data have? *A.) 6 unique product lines.
SELECT COUNT(DISTINCT product_line)
FROM sales;

-- 2.) What is the most common payment method? *A.) Cash is the most common payment method.
SELECT payment_method, COUNT(*) AS cnt
FROM sales
	GROUP BY payment_method
	ORDER BY cnt DESC;

-- 3.) What is the best selling product line? *A.) Fashion Accessories is the best selling product line with 178 sales.
SELECT product_line, COUNT(*) AS cnt
FROM sales
	GROUP BY product_line
	ORDER BY cnt DESC;

-- 4.) What is the total revenue by month? *A.) January Total Rev.: $116,292.11, February Total Rev.: $95,727.58, March Total Rev.: $108,867.38.
SELECT DISTINCT month_name AS month, ROUND(SUM(total), 2) AS total_revenue
FROM sales
	GROUP BY month_name
	ORDER BY CASE month_name
		WHEN 'January' THEN 1
		WHEN 'February' THEN 2
		WHEN 'March' THEN 3			
END;

-- 5.) What month had the largest COGS? *A.) January with a combined $110,754.16 in COGS.
SELECT month_name AS month, SUM(COGS) AS total_cogs
FROM sales
	GROUP BY month_name
	ORDER BY total_cogs DESC;

-- 6.) What product line had the largest revenue? *A.) Food and Beverages with a combined $56,144.96 in total revenue.
SELECT product_line, ROUND(SUM(total), 2) AS total_product_revenue
FROM sales
	GROUP BY product_line
	ORDER BY total_product_revenue DESC;

-- 7.) What is the city with the largest revenue? *A.) Naypyitaw with a combined $110,490.93 in total revenue.
SELECT city, ROUND(SUM(total), 2) AS total_city_revenue
FROM sales
	GROUP BY city
	ORDER BY total_city_revenue DESC;

-- 8.) What product_line had the largest VAT? *A.) Home and Lifestyle with a 16.03% average. 
SELECT product_line, ROUND(AVG(VAT), 2) AS avg_tax
FROM sales
	GROUP BY product_line
	ORDER BY avg_tax DESC;

-- 9.) Fetch (a) product line(s) and add a column to those product lines showing whether its sales are 'Good' or 'Bad' based on if it's greater than average sales.
WITH AverageSales AS (
    SELECT AVG(total) AS avg_sales 
    FROM sales -- // This calculates overall average sales. //
)

SELECT
	product_line,
	ROUND(AVG(total), 2) AS avg_product_sales, -- // Using our CTE to give us a predfined average value, we can compare the average sales of each product line to this predefined value. //
	CASE
		WHEN ROUND(AVG(total), 2) > (SELECT avg_sales from AverageSales) THEN 'Good'
		ELSE 'Bad'
	END AS sales_category
	
FROM sales
	GROUP BY product_line
	ORDER BY avg_product_sales DESC;

-- 10.) Which branch sold more products than average product sold? *A.) Branch A & C sold more than the average(1824) with 1849 & 1828 quantities sold respectively.
SELECT branch, SUM(quantity) AS total_quantity 
FROM sales -- // Calculates total quantity per branch. //
GROUP BY branch;

WITH branch_totals AS ( 
	SELECT SUM(quantity) AS total_quantity -- // Calculates the average quantity sold over all branches to the nearest third decimal. //
	FROM sales
	GROUP BY branch
)
SELECT ROUND(AVG(total_quantity), 3) AS avg_quantity -- // Calculates the average of 'branch totals' to give us the overall average of overall quantity sold per branch. //
FROM branch_totals;

WITH branch_totals AS ( 
	SELECT branch, SUM(quantity) AS total_quantity -- // Finds branches that sold more than the average quantity. //
	FROM sales
	GROUP BY branch
),
avg_sales AS (
	SELECT AVG(total_quantity) AS avg_quantity
	FROM branch_totals
)
SELECT branch, total_quantity
FROM branch_totals
WHERE total_quantity > (SELECT avg_quantity FROM avg_sales);

-- 11.) What is the most common product line by gender? *A.) The most common product line for women is Fashion Accessories, while for men it is the Health & Beauty product line.
SELECT gender, product_line, COUNT(gender) AS total_cnt
FROM sales
GROUP BY gender, product_line
ORDER BY total_cnt DESC;

-- 12.) What is the average rating of each product line? * A.) The overall average rating of each product line is 6.96.
SELECT product_line, ROUND(AVG(rating), 3) AS avg_rating -- // Finds the average ratings of each product line. //
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;

WITH avg_ratings AS (
	SELECT product_line, -- // Gives an overall average of the average product line ratings. So many averages. //
		AVG(rating) AS avg_rating
	FROM sales
	GROUP BY product_line
)
SELECT ROUND(AVG(avg_rating), 3) AS overall_avg_rating
FROM avg_ratings;

-- ***==== Sales Questions ====*** ---------------------------------------------------------------------------------------------------------------------------------------

-- 1.) Give the number of sales made in each time of the day, per weekday. *A.)
SELECT 
    time_of_day,
    day_name,
    COUNT(*) AS number_of_sales
FROM (
    SELECT 
        CASE
            WHEN TIME(time) BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
            WHEN TIME(time) BETWEEN '12:00:01' AND '16:00:00' THEN 'Afternoon'
            ELSE 'Evening'
        END AS time_of_day,
        CASE DAYOFWEEK(date)
            WHEN 1 THEN 'Sunday'
            WHEN 2 THEN 'Monday'
            WHEN 3 THEN 'Tuesday'
            WHEN 4 THEN 'Wednesday'
            WHEN 5 THEN 'Thursday'
            WHEN 6 THEN 'Friday'
            WHEN 7 THEN 'Saturday'
        END AS day_name,
        DAYOFWEEK(date) AS weekday_order
    FROM sales
) AS day_names
GROUP BY time_of_day, day_name, weekday_order
ORDER BY weekday_order, 
         FIELD(time_of_day, 'Morning', 'Afternoon', 'Evening');

-- 2.) Which of the customer types brings in the most revenue? *A.) Customers that are Members bring in the most revenue with a total revenue of $163,625.47.
SELECT customer_type, ROUND(SUM(total), 2) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- 3.) Which city has the largest tax percent/VAT? *A.) Naypyitaw has the highest tax percentage with 16.09%.
SELECT city, ROUND(AVG(VAT), 3) AS average_vat
FROM sales
GROUP BY city
ORDER BY average_vat DESC;

-- 4.) Which customer type pays the most in VAT? *A.) Customers that are Members pay the most in VAT, with an average of 15.62%.
SELECT customer_type, ROUND(AVG(VAT), 3) AS average_vat
FROM sales
GROUP BY customer_type
ORDER BY average_vat DESC;

-- ***==== Customer Questions ====*** ---------------------------------------------------------------------------------------------------------------------------------------

-- 1.) How many unique customer types does the data have? *A.) The data has two unique customer types, Normal & Member.
SELECT DISTINCT customer_type
FROM sales;

-- 2.) How many unique payment methods does the data have? *A.) The data has three unique payment methods: Ewallet, Cash, & Credit Card.
SELECT DISTINCT payment_method
FROM sales;

-- 3.) What is the most common customer type? *A.) Members are the most common customer type, but it's nearly even between the amount of Normal customers and Members.
SELECT customer_type, COUNT(*) AS count
FROM sales
GROUP BY customer_type
ORDER BY count DESC;

-- 4.) Which customer type buys the most? *A.) Customers that are Members not only spend the most, but buy the most quantity of products as well.
SELECT customer_type, ROUND(SUM(total), 2) AS total_purchase, SUM(quantity) AS total_quantity
FROM sales
GROUP by customer_type
ORDER BY total_purchase DESC, total_quantity DESC;

-- 5.) What is the gender of most of the customers? *A.) Most of the customers are Male, but the difference between the amount of Male & Female customers is quite low.
SELECT gender, COUNT(gender) AS gender_count
FROM sales
GROUP by gender
ORDER BY gender_count DESC;

-- 6.) What is the gender distribution per branch? *A.)Both branches A & B have slightly more male customers than Male customers, while branch C has more Female customers than Male. 
SELECT gender, branch, COUNT(*) count
FROM sales
GROUP by branch, gender
ORDER BY branch, gender DESC;

-- 7.) Which time of the day customers give the most ratings? *A.) Customers give the most ratings during the Afternoon.
SELECT time_of_day, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY time_of_day
ORDER BY avg_rating DESC;

-- 8.) Which time of the day do customer give the most ratings PER branch? *A.) Branches A & C's customers give the most amount of ratings during the Afternoon, while branch B's give them the most during the Afternoon.
SELECT branch, time_of_day, ROUND(AVG(rating), 3) AS avg_rating
FROM sales
GROUP BY branch, time_of_day
ORDER BY branch, avg_rating DESC;

-- 9.) Which day of the week has the best average ratings? *A.) Monday has the best average ratings of the week, averaging a rating of 7.13.
SELECT day_name, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC;

-- 10.) Which day of the week has the best average ratings per branch? *A.) For A, their best day is Friday. For branch B it's Monday and for branch C it's Saturday.
SELECT day_name, branch, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
WHERE branch = 'A'
GROUP BY branch, day_name
ORDER BY branch, avg_rating DESC;