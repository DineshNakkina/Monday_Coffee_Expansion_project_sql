
-- MONDAY COFFEE DATA ANALYSIS

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports and Data Analysis

-- Q1. Coffee Consumers Count
-- Hom many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name, round((population * 0.25)/1000000,2) as coffee_consumers_in_millions, city_rank
FROM
    city
ORDER BY population DESC;

-- Q2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    city_name, SUM(total) AS total_revenue
FROM
    sales s
        JOIN
    customers cu ON s.customer_id = cu.customer_id
        JOIN
    city c ON cu.city_id = c.city_id
WHERE
    YEAR(sale_date) = 2023
        AND QUARTER(sale_date) = 4
GROUP BY city_name
ORDER BY total_revenue DESC;

-- Q3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    product_name, COUNT(sale_id) AS units_sold
FROM
    products p
        LEFT JOIN
    sales s ON p.product_id = s.product_id
GROUP BY product_name
ORDER BY units_sold DESC;

-- Q4. Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    city_name,
    SUM(total) AS total_revenue,
    COUNT(DISTINCT (cu.customer_id)) AS total_customers,
    ROUND(SUM(total) / COUNT(DISTINCT (cu.customer_id)),
            2) AS avg_per_customer
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON cu.customer_id = s.customer_id
GROUP BY city_name
ORDER BY 4 DESC;

-- Q5. City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cosumers , estimated coffee consumers (25%)
 
WITH city_table AS
 (SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions
FROM
    city), customer_table AS
(SELECT 
    city_name, COUNT(DISTINCT cu.customer_id) AS current_customers
FROM
    sales s
        JOIN
    customers cu ON s.customer_id = cu.customer_id
        JOIN
    city c ON cu.city_id = c.city_id
GROUP BY city_name) 
SELECT 
    c.city_name, coffee_consumers_in_millions, current_customers
FROM
    city_table c
        JOIN
    customer_table cu ON c.city_name = cu.city_name;

-- -- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT city_name,product_name,total_orders,ranks 
FROM
(SELECT 
    c.city_name, p.product_name, COUNT(s.sale_id) AS total_orders ,dense_rank() over(partition by c.city_name order by count(s.sale_id) desc) as ranks
    FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON cu.customer_id = s.customer_id
        JOIN
    products p ON s.product_id = p.product_id
    group by 1,2 ) AS t1 
    WHERE ranks<=3;


-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
    c.city_name, COUNT(DISTINCT cu.customer_id) AS Unq_customers
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
WHERE
    s.product_id IN (1 , 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY c.city_name;

-- -- Q8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/ct.total_cx
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
