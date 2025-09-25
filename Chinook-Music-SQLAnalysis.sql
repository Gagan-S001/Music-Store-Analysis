USE chinook;
-- OBJECTIVE QUESTIONS

-- Q1. Does any table have missing values or duplicates? If yes how would you handle it ?
SELECT * FROM album;  -- No Duplicates and Missing Values

SELECT * FROM artist;  -- No Duplicates and Missing Values

SELECT * FROM customer;  
-- No Duplicates but have Missing/Null Values in 
-- Column -- "company, state, fax, phone, postal code"
-- Handling NULL Values with COALESCE
SELECT customer_id, first_name, last_name,
COALESCE (company, 'NA') AS company,
address, city,
COALESCE(state, 'NA') AS state,
country,
COALESCE(postal_code, 'NA') AS postal_code,
COALESCE (phone, 'NA') AS phone,
COALESCE (fax, 'NA') AS fax,
email, support_rep_id
FROM customer;

SELECT * FROM employee;  -- No Duplicates but have Missing/Null Values in 
-- Column -- "report_to"
-- Handling NULL Values with COALESCE
SELECT employee_id, last_name, first_name, title,
COALESCE(reports_to,'NA') AS reports_to,
birthdate, hire_date, address, city, state, country, postal_code, phone, fax, email
FROM employee;

SELECT * FROM genre;  -- No Duplicates and Missing Values

SELECT * FROM invoice;  -- No Duplicates and Missing Values

SELECT * FROM invoice_line;  -- No Duplicates and Missing Values

SELECT * FROM media_type;  -- No Duplicates and Missing Values

SELECT * FROM playlist;  -- No Duplicates and Missing Values

SELECT * FROM playlist_track;  -- No Duplicates and Missing Values

SELECT * FROM track;  
-- No Duplicates but have Missing/Null Values in 
-- Column -- "composer" 
-- Handling NULL Values with COALESCE
SELECT track_id, name, album_id, media_type_id, genre_id, 
COALESCE(composer, 'NA') AS composer, 
milliseconds, bytes, unit_price 
from track;

-- Q2. Find the top-selling tracks and top artist in the USA and identify their most famous genres.
-- Top-Selling Track in USA
SELECT t.track_id,
t.name AS track_name, 
SUM(il.quantity) AS top_selling_quantity
FROM track AS t 
JOIN invoice_line il ON t.track_id= il.track_id 
JOIN invoice i ON il.invoice_id= i.invoice_id 
JOIN customer c ON i.customer_id = c.customer_id 
WHERE c.country = 'USA' 
GROUP BY t.name,t.track_id 
ORDER BY  Top_Selling_quantity DESC 
LIMIT 10;

-- Top Artist in USA
SELECT ar.artist_id,
ar.name AS artist_name,
SUM(il.quantity) AS total_quantity_sold
FROM invoice_line il
JOIN invoice i ON i.invoice_id = il.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album a ON t.album_id = a.album_id
JOIN artist ar ON a.artist_id = ar.artist_id
WHERE i.billing_country = 'USA'
GROUP BY ar.artist_id, ar.name
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Famous Genre of Top Artist
SELECT g.genre_id, 
g.name AS genre_name, 
SUM(il.quantity) AS total_qty_sold
FROM invoice_line il
JOIN invoice i ON i.invoice_id = il.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album a ON t.album_id = a.album_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN artist ar ON ar.artist_id = a.artist_id
WHERE i.billing_country = 'USA'
GROUP BY g.genre_id, g.name
ORDER BY total_qty_sold DESC
LIMIT 10;

-- Q3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
-- Location: directly available from customer.country , customer.state , customer.city ,Aggregate counts.
-- Age & Gender: schema does not include birthdate or gender for customers.
SELECT country, COALESCE(state,"NA") AS state, city, COUNT(*) AS num_customers
FROM customer
GROUP BY country, state, city
ORDER BY country, num_customers DESC;

-- Q4. Calculate the total revenue and number of invoices for each country, state, and city
SELECT billing_country, billing_state, billing_city,
COUNT(DISTINCT invoice_id) AS num_invoices,
SUM(total) AS total_revenue
FROM invoice
GROUP BY billing_country, billing_state, billing_city
ORDER BY total_revenue DESC;

-- Q5. Find the top 5 customers by total revenue in each country

SELECT customer_id, first_name, last_name, country, total_spent
FROM ( SELECT c.customer_id, c.first_name, c.last_name, c.country,
SUM(i.total) AS total_spent,
ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS rn
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country, c.customer_id, c.first_name, c.last_name
) AS tab 
WHERE rn <= 5
ORDER BY country, total_spent DESC;

-- Q6. Identify the top-selling track for each customer
WITH customer_tracks AS (
	SELECT c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		SUM(il.quantity) AS total_quantity
	FROM customer AS c 
	JOIN invoice i ON c.customer_id = i.customer_id
	JOIN invoice_line il ON i.invoice_id = il.invoice_id
	GROUP BY c.customer_id, customer_name
),
customer_top_track AS (
	SELECT ct.customer_id, ct.customer_name, ct.total_quantity,
	ROW_NUMBER() OVER(PARTITION BY ct.customer_id ORDER BY ct.total_quantity DESC) AS rnk,
	t.track_id,
	t.name AS track_name
	from customer_tracks ct
	JOIN invoice i ON ct.customer_id = i.customer_id
	JOIN invoice_line il ON i.invoice_id = il.invoice_id
	JOIN track t ON il.track_id = t.track_id
)
SELECT customer_id, customer_name, track_name, total_quantity
FROM customer_top_track
WHERE rnk = 1
ORDER BY customer_id;

-- Q7. Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?
-- Payment method field is not present
-- Frequency of Purchases
SELECT c.customer_id, c.first_name, c.last_name,
YEAR(i.invoice_date) AS years,
COUNT(i.invoice_id) AS frequency
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, years
ORDER BY c.customer_id, years DESC;

-- Average order value of each customer
SELECT c.customer_id,
CONCAT(c.first_name,' ',c.last_name) AS customer_name,
ROUND(AVG(i.total),2) AS average_order_value
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY  c.customer_id
ORDER BY average_order_value DESC;

-- Q8. What is the customer churn rate?
WITH reference_date AS (
	SELECT DATE_SUB(recent_date, INTERVAL 1 YEAR) AS cutoff_date
	FROM (
		SELECT MAX(invoice_date) AS recent_date
		FROM invoice) AS temp
),
inactive_customers AS (
	SELECT c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		MAX(i.invoice_date) AS last_purchase_date
	FROM customer c
	JOIN invoice i ON c.customer_id = i.customer_id
	GROUP BY c.customer_id, customer_name
	HAVING max(i.invoice_date) IS NULL OR MAX(i.invoice_date) < (SELECT * FROM reference_date)
)
SELECT (SELECT count(*) FROM inactive_customers) / (SELECT COUNT(*) FROM customer) * 100 AS churn_rate;

-- Q9. Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
 -- Percent by genre (USA)
WITH genre_sales AS (
		SELECT g.genre_id, g.name AS genre_name,
		SUM(il.quantity * il.unit_price) AS revenue
		FROM invoice_line il
		JOIN invoice i ON il.invoice_id = i.invoice_id
		JOIN track t ON il.track_id = t.track_id
		LEFT JOIN genre g ON t.genre_id = g.genre_id
		WHERE i.billing_country = 'USA'
		GROUP BY g.genre_id, g.name
), 
total AS (
SELECT SUM(revenue) AS total_revenue FROM genre_sales
)
SELECT gs.genre_id, gs.genre_name, gs.revenue,
ROUND(100.0 * gs.revenue / t.total_revenue, 2) AS pct_of_us_sales
FROM genre_sales gs CROSS JOIN total t
ORDER BY gs.revenue DESC;

-- Identify best-selling artists per genre
SELECT g.genre_id, g.name AS genre_name,
ar.name AS artist_name,
SUM(il.quantity * il.unit_price) AS artist_revenue,
DENSE_RANK() OVER( ORDER BY SUM(il.quantity * il.unit_price) DESC) as rnk
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN track t ON il.track_id = t.track_id
LEFT JOIN album a ON t.album_id = a.album_id
LEFT JOIN artist ar ON a.artist_id = ar.artist_id
LEFT JOIN genre g ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.genre_id, g.name, ar.artist_id, ar.name
ORDER BY  artist_revenue DESC;

-- Q10. Find customers who have purchased tracks from at least 3 different genres
SELECT c.customer_id, c.first_name, c.last_name, 
COUNT(DISTINCT t.genre_id) AS num_genres
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING num_genres >= 3
ORDER BY num_genres DESC;

-- Q11. Rank genres based on their sales performance in the USA

SELECT genre_id, genre_name, revenue,
RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM (
	SELECT g.genre_id, g.name AS genre_name, 
	SUM(il.quantity * il.unit_price) AS revenue
	FROM invoice_line il
	JOIN invoice i ON il.invoice_id = i.invoice_id
	JOIN track t ON il.track_id = t.track_id
	JOIN genre g ON t.genre_id = g.genre_id
	WHERE i.billing_country = 'USA'
	GROUP BY g.genre_id, g.name
) tab
ORDER BY revenue DESC;

-- Q12. Identify customers who have not made a purchase in the last 3 months
SELECT c.customer_id, c.first_name, c.last_name, 
MAX(i.invoice_date) AS last_purchase
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING last_purchase <= CURDATE() -  INTERVAL 3 MONTH 
ORDER BY c.customer_id, last_purchase;


-- Subjective Questions

--  Q1. Recommend the three albums from the new record label that should be prioritised
 -- for advertising and promotion in the USA based on genre sales analysis. 
 
 SELECT g.name AS genre_name,
      al.title AS album_title,
	SUM(il.quantity * il.unit_price) AS total_sales,
	DENSE_RANK() OVER(ORDER BY SUM(il.quantity * tr.unit_price) DESC) AS sales_rank
FROM track tr
JOIN album al ON tr.album_id = al.album_id
JOIN invoice_line il ON tr.track_id = il.track_id
JOIN invoice inv ON il.invoice_id = inv.invoice_id
JOIN customer cust ON inv.customer_id = cust.customer_id
JOIN genre g ON tr.genre_id = g.genre_id
WHERE cust.country = 'USA'
GROUP BY genre_name, album_title
ORDER BY  sales_rank
LIMIT 3;

-- Q2. Determine the top-selling genres in countries other than the USA and identify any commonalities or differences
SELECT g.name,
SUM(i.total) AS genre_sum,
RANK() OVER (ORDER BY SUM(i.total) DESC) AS rankk
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE c.country != 'USA'
GROUP BY g.name;

-- Q3. Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount)
-- of long-term customers differ from those of new customers?
-- What insights can these patterns provide about customer loyalty and retention strategies?

WITH purchase_details AS (
    SELECT c.customer_id,
        COUNT(il.invoice_id) AS purchase_count,
        SUM(il.quantity) AS total_items_bought,
        SUM(i.total) AS total_spent,
        AVG(i.total) AS avg_spent_per_order,
        DATEDIFF(MAX(i.invoice_date), MIN(i.invoice_date)) AS customer_lifetime_days
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id
),
customer_details AS (
    SELECT customer_id, purchase_count, total_items_bought,
    total_spent, avg_spent_per_order,customer_lifetime_days,
	CASE
		WHEN customer_lifetime_days < 365 THEN 'recent' 
		ELSE 'long-term' 
        END AS customer_category
    FROM purchase_details	
)
SELECT customer_category,
    ROUND(AVG(purchase_count), 2) AS average_purchase_frequency,
    ROUND(AVG(total_items_bought), 2) AS average_basket_size,
    ROUND(AVG(total_spent), 2) AS average_spending,
    ROUND(AVG(avg_spent_per_order), 2) AS average_order_value
FROM customer_details
GROUP BY customer_category;

-- Q4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased 
 -- together by customers? How can this information guide product recommendations and cross-selling initiatives?
 
 -- Genre Affinity 
SELECT 
    g1.name AS genre_a,
    g2.name AS genre_b,
    COUNT(*) AS cooccurrence_count
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN genre g1 ON t1.genre_id = g1.genre_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id < il2.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN genre g2 ON t2.genre_id = g2.genre_id
WHERE g1.genre_id <> g2.genre_id
GROUP BY g1.name, g2.name
ORDER BY cooccurrence_count DESC
LIMIT 20;

-- Artist Affinity
SELECT 
    ar1.name AS artist_a,
    ar2.name AS artist_b,
    COUNT(*) AS cooccurrence_count
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN artist ar1 ON al1.artist_id = ar1.artist_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id < il2.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
JOIN artist ar2 ON al2.artist_id = ar2.artist_id
WHERE ar1.artist_id <> ar2.artist_id
GROUP BY ar1.name, ar2.name
ORDER BY cooccurrence_count DESC
LIMIT 20;

-- Album Affinity
SELECT 
    al1.title AS album_a,
    al2.title AS album_b,
    COUNT(*) AS cooccurrence_count
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id < il2.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
WHERE al1.album_id <> al2.album_id
GROUP BY al1.title, al2.title
ORDER BY cooccurrence_count DESC
LIMIT 20;

-- Q5. Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations?
-- How might these correlate with local demographic or economic factors?

SELECT country,
COUNT(*) AS total_customers,
SUM(CASE WHEN last_purchase < DATE_SUB(CURDATE(), INTERVAL 3 MONTH) OR
last_purchase IS NULL THEN 1 ELSE 0 END) AS churned_customers,
ROUND(100.0 * SUM(CASE WHEN last_purchase < DATE_SUB(CURDATE(), INTERVAL
3 MONTH) OR last_purchase IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_pct
FROM (
SELECT c.customer_id, c.country, MAX(i.invoice_date) AS last_purchase
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.country
) tab
GROUP BY country
ORDER BY churn_pct DESC;

-- Q6.Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history),
-- which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?

WITH Details_customer AS (
	SELECT c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        c.country,
        COALESCE(c.state,"NA") AS state,
        c.city,
        MAX(i.invoice_date) AS last_purchase_date,
        COUNT(i.invoice_id) AS purchase_frequency,
        SUM(i.total) AS total_spending,
        AVG(i.total) AS avg_order_value,
        CASE 
			WHEN MAX(i.invoice_date) < DATE_SUB(CURDATE(),INTERVAL 1 YEAR) THEN 'High Risk'
			WHEN SUM(i.total) < 100 THEN 'Medium Risk'
            ELSE 'Low Risk'
		END AS risk_profile
    FROM customer c 
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id,customer_name,c.country,state,c.city
	ORDER BY total_spending DESC
),
Details_risk AS (
	SELECT country, state, city, risk_profile,
        COUNT(customer_id) AS num_customer,
        ROUND(AVG(total_spending),2) AS avg_total_spending,
        ROUND(AVG(purchase_frequency),2) AS avg_purchase_frequency,
        ROUND(AVG(avg_order_value),2) AS avg_order_value
	FROM Details_customer
    GROUP BY country,state,city,risk_profile
)
SELECT * FROM Details_risk
ORDER BY risk_profile,avg_total_spending DESC;

-- Q7.Customer Lifetime Value Modelling: How can you leverage customer data (tenure, purchase history, engagement)
-- to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies.
-- Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?

WITH CLV_per_Customer AS (
	SELECT c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        c.country,
        COALESCE(c.state,'Not Available') AS  state,
        c.city,
        MIN(i.invoice_date) AS first_purchase_date,
        MAX(i.invoice_date) AS last_purchse_date,
        DATEDIFF(MAX(i.invoice_date),MIN(i.invoice_date)) AS customer_tenure_days,
        COUNT(i.invoice_id) AS total_purchase,
        SUM(i.total) AS total_spending,
        AVG(i.total) AS avg_order_value,
        CASE 
			WHEN MAX(i.invoice_date) < DATE_SUB(CURDATE(),INTERVAL 1 YEAR) THEN 'Churn' ELSE 'Active' 
		END AS status,
        CASE
			WHEN DATEDIFF(MAX(i.invoice_date),MIN(i.invoice_date)) >= 365 THEN 'Long term' ELSE 'short term'
		END AS customer_segment,
		SUM(i.total)/GREATEST(DATEDIFF(MAX(i.invoice_date),MIN(i.invoice_date)),1)* 365 AS predicted_annual_value,
        SUM(i.total) AS lifetime_value
	FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY customer_id
),

CLV_segmentation  AS (
	SELECT customer_segment, status,
        COUNT(customer_id) AS num_customer,
        AVG(customer_tenure_days) AS avg_tenure_days,
        AVG(total_spending) AS avg_lifetime_value,
        AVG(predicted_annual_value) AS avg_predicted_annual_value
	FROM CLV_per_Customer 
    GROUP BY customer_segment, status
),

churn_cust AS (
	SELECT country, state,city, customer_segment,
        COUNT(customer_id) AS churned_customer,
        AVG(total_spending) AS avg_lifetime_value
	FROM CLV_per_Customer
    WHERE status = 'churn'
    GROUP BY country,state,city,customer_segment
)
-- To get customer lifeStyle analysis
select * from CLV_per_Customer;

-- To get customer Segment analysis
select * from CLV_segmentation ;

-- To get Customer churn analysis
select * from churn_cust;

-- Q8. If data on promotional campaigns (discounts, events, email marketing) is available,
-- how could you measure their impact on customer acquisition, retention, and overall sales?
-- ANSWER IN DOCS FILE

-- Q9. How would you approach this problem, if the objective and subjective questions weren't given?
-- ANSWER IN DOCS FILE

-- Q10. How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?
ALTER TABLE album
ADD COLUMN ReleaseYear INT;

SELECT * FROM album;

-- Q11. Chinook is interested in understanding the purchasing behavior of customers based on their 
-- geographical location. They want to know the average total amount spent by customers from each country, 
-- along with the number of customers and the average number of tracks purchased per customer. 
-- Write an SQL query to provide this information.

SELECT c.country,
COUNT(*) AS num_customers,
ROUND(AVG(cs.total_spent),2) AS avg_total_spent_per_customer,
ROUND(AVG(COALESCE(cs.total_tracks, 0)), 2) AS avg_tracks_per_customer
FROM customer c
LEFT JOIN (
SELECT i.customer_id,
SUM(i.total) AS total_spent,
SUM(il.quantity) AS total_tracks
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY i.customer_id
) cs ON c.customer_id = cs.customer_id
GROUP BY c.country
ORDER BY avg_total_spent_per_customer DESC;




 








 















































