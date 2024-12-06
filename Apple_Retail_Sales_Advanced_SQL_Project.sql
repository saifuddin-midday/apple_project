
-- Apple Sales Project - 1M rows sales datasets

SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM stores;
SELECT * FROM sales;
SELECT * FROM warranty;

-- Exploratory Data Analysis

SELECT DISTINCT repair_status FROM warranty;

SELECT DISTINCT store_name FROM stores;

SELECT DISTINCT category_name FROM category;

SELECT DISTINCT product_name FROM products;

SELECT COUNT(*) FROM sales;

-- execution time - 99.5 ms
-- planning time - 0.076 ms

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id = 'P-48';


-- Improving Query Performance
CREATE INDEX sales_product_id ON sales(product_id);
-- execution time after index 5-10 ms

-- execution time - 100 ms
-- planning time - 0.15 ms

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-3';

CREATE INDEX sales_store_id ON sales(store_id);
-- execution time after index 10 ms

CREATE INDEX sales_sale_date ON sales(sale_date);


-- BUSINESS PROBLEMS

-- MEDIUM PROBLEMS

-- Q.1 Find the number of stores in each country.

SELECT 
	country,
	COUNT(*) AS number_of_stores
FROM stores
GROUP BY 1
ORDER BY 2 DESC;


-- Q.2 Calculate the total number of units sold by each store.

SELECT * FROM stores;
SELECT * FROM sales;

SELECT
	s.store_id,
	st.store_name,
	SUM(s.quantity) AS total_unit_sold
FROM sales as s
JOIN
stores as st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;


-- Q.3 Identify how many sales occurred in December 2023.

SELECT
	COUNT(sale_id) as total_sale
FROM sales
WHERE
	TO_CHAR(sale_date, 'MM-YYYY') = '12-2023'


-- Q.4 Determine how many stores have never had a warranty claim filed.

SELECT COUNT(*)
FROM stores
WHERE store_id NOT IN (
						SELECT
							DISTINCT s.store_id
						FROM sales as s
						RIGHT JOIN warranty as w
						ON s.sale_id = w.sale_id
						)

-- Q.5 Calcutate th percentage of warranty claims marked as "Rejected"

SELECT 
	ROUND(COUNT(claim_id) / 
							(SELECT COUNT(*) FROM warranty):: numeric
		*100,
	2) AS warranty_void_percentage
FROM warranty
WHERE repair_status = 'Rejected'


-- Q.6 Identify which store had the highest total units sold in the last year.

SELECT
	s.store_id,
	st.store_name,
	SUM(s.quantity) AS total_unit_sold
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 1, 2
ORDER BY 3 DESC


-- Q.7 Count the number of unique products sold in the last year.

SELECT 
	COUNT(DISTINCT product_id)	
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'


-- Q.8 Find the average price of products in each category.

SELECT
	p.category_id,
	c.category_name,
	AVG(p.price) as average_price
FROM products as p
JOIN category as c
On p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;


-- Q.9 How many warranty claims were filed in 2024?

SELECT 
	COUNT(*) as num_of_claims	
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2024


-- Q.10 For each store, identify the best-selling day based on highest quantity sold.

SELECT *
FROM
	(SELECT
		store_id,
		TO_CHAR(sale_date, 'Day') as day_name,
		SUM(quantity) as total_quantity_sold,
		RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) as rank
	FROM sales
	GROUP BY 1, 2
) as t1
WHERE rank = 1;


--- MEDIUM TO HARD QUESTIONS:

-- Q.11 Identify the least selling product in each country for each year based on total units sold.

--- Sub-query method:

SELECT * 
FROM
	(SELECT
		st.country,
		p.product_name,
		SUM(s.quantity) as total_unit_sold,
		RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) as rank	
	FROM sales as s
	JOIN stores as st
	ON s.store_id = st.store_id
	JOIN products as p
	ON s.product_id = p.product_id
	GROUP BY 1, 2
) as t1
WHERE rank = 1

--- CTE method:
 
WITH product_rank
AS
(SELECT
		st.country,
		p.product_name,
		SUM(s.quantity) as total_unit_sold,
		RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) as rank	
	FROM sales as s
	JOIN stores as st
	ON s.store_id = st.store_id
	JOIN products as p
	ON s.product_id = p.product_id
	GROUP BY 1, 2
)
SELECT *
FROM product_rank
WHERE rank = 1;


-- Q.12 Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT
	w.*,
	s.sale_date,
	(w.claim_date - sale_date) as diff_days
FROM warranty as w
LEFT JOIN sales as s
ON s.sale_id = w.sale_id
WHERE w.claim_date - sale_date <= 180
AND w.claim_date - sale_date >= 0;


-- Q.13 Determine how many warranty claims were filed for products launched in the last two years.

SELECT
	p.product_name,
	COUNT(w.claim_id) as no_claim,
	COUNT(s.sale_id) as total_unit_sold
FROM warranty as w
RIGHT JOIN sales as s
ON s.sale_id = w.sale_id
JOIN products as p
ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
ORDER BY 2 DESC

-- SHOWING CLAIM PERCENTAGE FOR THE SAME
SELECT
    p.product_name,
    COUNT(w.claim_id) AS no_claim,
    COUNT(s.sale_id) AS total_unit_sold,
    CONCAT
		(ROUND((COUNT(w.claim_id) * 100.0 / NULLIF(COUNT(s.sale_id), 0)), 2), '%'
    ) AS claim_percentage
FROM warranty AS w
RIGHT JOIN sales AS s
ON s.sale_id = w.sale_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
ORDER BY 2 DESC;



-- Q.14 List the months in the last three years where sales exceeded 5000 units in the USA.

SELECT
	TO_CHAR(s.sale_date, 'MM-YYYY') AS month,
	SUM(s.quantity) AS total_unit_sold
FROM sales as s
JOIN 
stores as st
ON s.store_id = st.store_id
WHERE 
	st.country = 'United States'
	AND
	s.sale_date >= CURRENT_DATE - INTERVAL '3 year'
GROUP BY 1
HAVING SUM(s.quantity) > 5000;



-- Q.15 Identify the product category with the most warranty claims filed in the last two years.

SELECT
	c.category_name,
	COUNT(w.claim_id) as total_claims
FROM warranty AS w
LEFT JOIN
sales AS s
ON w.sale_id = s.sale_id
JOIN 
products as p
ON p.product_id = s.product_id
JOIN
category as c
ON p.category_id = c.category_id
WHERE 
	w.claim_date >= CURRENT_DATE - INTERVAL '2 year'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


-- Q.16 Determine the percentage chance of receiving warranty claims after each purchase for each country.

SELECT
    country,
    total_unit_sold,
    total_claim,
    ROUND((total_claim::numeric / total_unit_sold::numeric) * 100, 2) AS risk
FROM (
    SELECT
        st.country,
        SUM(s.quantity) AS total_unit_sold,
        COUNT(w.claim_id) AS total_claim
    FROM sales AS s
    JOIN stores AS st
    ON s.store_id = st.store_id
    LEFT JOIN warranty AS w
    ON w.sale_id = s.sale_id
    GROUP BY st.country
) AS t1
ORDER BY 4 DESC;



-- Q.17 Analyze the year-by-year growth ratio for each store.

SELECT
	store_name,
	year,
	last_year_sale,
	current_year_sale,
	ROUND(
		   (current_year_sale - last_year_sale)::numeric / 
		   last_year_sale::numeric * 100
		   ,3) as growth_ratio
FROM
(
	SELECT
		store_name,
		year,
		LAG(total_sale, 1) OVER(PARTITION BY store_name ORDER BY year) as last_year_sale,
		total_sale as current_year_sale
	FROM
	(
		SELECT
			s.store_id,
			st.store_name,
			EXTRACT(YEAR FROM sale_date) as year,
			SUM(s.quantity * p.price) as total_sale
		FROM sales as s
		JOIN
		stores as st
		ON st.store_id = s.store_id
		JOIN 
		products as p
		ON p.product_id = s.product_id 
		GROUP BY 1, 2, 3
		ORDER BY 2, 3
	) as t1
) as t2
WHERE 
	last_year_sale IS NOT NULL
	AND
	year <> EXTRACT(YEAR FROM CURRENT_DATE)



-- Q.18 Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.

SELECT
	CASE
		WHEN p.price < 500 THEN 'Less Expensive Product'
		WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
		ELSE 'Expensive Product'
	END as price_segment,
	COUNT(w.claim_id) as total_claim
FROM warranty as w
LEFT JOIN
sales as s
ON w.sale_id = s.sale_id
JOIN 
products as p
ON p.product_id = s.product_id
WHERE claim_date >= CURRENT_DATE - INTERVAL '5 year'
GROUP BY 1


-- Q.19 Identify the store with the highest percentage of "Completed" claims relative to total claims filed


WITH completed
AS
(SELECT 
	s.store_id,
	COUNT(w.claim_id) as completed
FROM sales as s
RIGHT JOIN
warranty as w
ON w.sale_id = s.sale_id
WHERE w.repair_status = 'Completed'
GROUP BY 1
),

total_repaired
AS
(SELECT 
	s.store_id,
	COUNT(w.claim_id) as total_repaired
FROM sales as s
RIGHT JOIN
warranty as w
ON w.sale_id = s.sale_id
GROUP BY 1)

SELECT
	tr.store_id,
	st.store_name,
	st.country,
	c.completed,
	tr.total_repaired,
	CONCAT(ROUND(c.completed::numeric / tr.total_repaired::numeric * 100, 2), '%') as percentage_of_completed
FROM completed as c
JOIN
total_repaired as tr
ON c.store_id = tr.store_id
JOIN
stores as st
ON tr.store_id = st.store_id
ORDER BY 6 DESC


-- Q.20 Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

WITH monthly_sales
AS
(SELECT 
	store_id,
	EXTRACT(YEAR FROM sale_date) as year,
	EXTRACT(MONTH FROM sale_date) as month,
	SUM(p.price * s.quantity) as total_revenue
FROM sales s
JOIN products p
ON s.product_id = p.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
)
SELECT 
	store_id,
	year,
	month,
	total_revenue,
	SUM(total_revenue) OVER(PARTITION BY store_id ORDER BY year, month) as running_total
FROM monthly_sales


-- BONUS QUESTION

-- Q.21 Analyze product sales trends over time, segmented into key periods, from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.

SELECT
	p.product_name,
	CASE
		WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN '0-6 month'
		WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 month' AND p.launch_date + INTERVAL '12 month' THEN '6-12'
		WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 month' AND p.launch_date + INTERVAL '18 month' THEN '12-18'
		ELSE '18+'
	END as product_life_cycle,
	SUM(s.quantity) as total_qty_sale
FROM sales s
JOIN products p
ON p.product_id = s.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC

-- Including country & store name

SELECT
	st.country,
	st.store_name,
	p.product_name,
	CASE
		WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN '0-6 month'
		WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 month' AND p.launch_date + INTERVAL '12 month' THEN '6-12'
		WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 month' AND p.launch_date + INTERVAL '18 month' THEN '12-18'
		ELSE '18+'
	END as product_life_cycle,
	SUM(s.quantity) as total_qty_sale
FROM sales s
JOIN products p
ON p.product_id = s.product_id
JOIN stores st
ON s.store_id = st.store_id
GROUP BY 1, 2, 3, 4
ORDER BY 1, 3, 5 DESC











