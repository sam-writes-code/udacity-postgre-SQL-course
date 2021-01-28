/* Query 1 */

SELECT f.title, c.name, COUNT(*)
FROM film f
JOIN film_category fc
ON f.film_id = fc.film_id
JOIN category c
ON fc.category_id = c.category_id
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
WHERE c.name IN (
  SELECT name
  FROM category
  WHERE name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
)
GROUP BY 1,2
ORDER BY 2;


/* Query 2 */

WITH all_categories AS (
  SELECT *
  FROM film f
  JOIN film_category fc
  ON f.film_id = fc.film_id
  JOIN category c
  ON fc.category_id = c.category_id
),
  quartiles AS (
  	SELECT title, name AS category_name, rental_duration,
  	NTILE(4) OVER (ORDER BY rental_duration)
  	FROM all_categories
  )

SELECT category_name,
  CASE WHEN ntile = 1 THEN '1st'
	WHEN ntile = 2 THEN '2nd'
	WHEN ntile = 3 THEN '3rd'
	ELSE '4th' END AS Quartile,
	COUNT(*) film_count
FROM quartiles
WHERE category_name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
GROUP BY 1,2
;


/* Query 3 */

WITH top_10 AS (
  SELECT customer_id, SUM(amount)
  FROM payment
  GROUP BY 1
  ORDER BY 2 DESC
  LIMIT 10)

SELECT DATE_TRUNC('month', p.payment_date) month_trunc,
      to_char(DATE_TRUNC('month', p.payment_date), 'Mon') AS pay_month,
      c.first_name || ' ' || c.last_name AS customer_name,
      SUM(p.amount) sum_per_month
FROM payment p
JOIN top_10 t
ON p.customer_id = t.customer_id
JOIN customer c
ON c.customer_id = p.customer_id
GROUP BY 1,2,3
ORDER BY 3;


/* Query 4 */

WITH top_10 AS (
  SELECT customer_id, SUM(amount)
  FROM payment
  GROUP BY 1
  ORDER BY 2 DESC
  LIMIT 10),

top10_month AS
(SELECT DATE_TRUNC('month', p.payment_date) payment_month,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(p.*) count_per_month, SUM(p.amount) sum_per_month
FROM payment p
JOIN top_10 t
ON p.customer_id = t.customer_id
JOIN customer c
ON c.customer_id = p.customer_id
GROUP BY 1,2
ORDER BY 2)

SELECT to_char(payment_month, 'Mon') AS pay_month, customer_name,
		COALESCE(sum_per_month - LAG(sum_per_month) OVER
    (PARTITION BY customer_name ORDER BY payment_month), 0) monthly_diff
FROM top10_month
ORDER BY payment_month;
