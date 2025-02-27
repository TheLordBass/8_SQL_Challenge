-- Table cleaning
DROP TABLE IF EXISTS #customer_orders_temp
SELECT * INTO #customer_orders_temp FROM		
(SELECT 
  customer_orders.order_id, 
  customer_id, 
  pizza_id, 
  CASE
	  WHEN exclusions IS null OR exclusions LIKE 'null' THEN ' '
	  ELSE exclusions
	  END AS exclusions,
  CASE
	  WHEN extras IS NULL or extras LIKE 'null' THEN ' '
	  ELSE extras
	  END AS extras,
	order_time
FROM customer_orders) AS A;


DROP TABLE IF EXISTS #runner_orders_temp
SELECT * INTO #runner_orders_temp FROM
(SELECT 
  order_id, 
  runner_id,  
  CASE
	  WHEN pickup_time LIKE 'null' THEN ' '
	  ELSE pickup_time
	  END AS pickup_time,
  CASE
	  WHEN distance LIKE 'null' THEN ' '
	  WHEN distance LIKE '%km' THEN TRIM('km' from distance)
	  ELSE distance 
    END AS distance,
  CASE
	  WHEN duration LIKE 'null' THEN ' '
	  WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
	  WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
	  WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
	  ELSE duration
	  END AS duration,
  CASE
	  WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ' '
	  ELSE cancellation
	  END AS cancellation
FROM runner_orders) AS B;


ALTER TABLE #runner_orders_temp
ALTER COLUMN pickup_time DATETIME;
ALTER TABLE #runner_orders_temp
ALTER COLUMN distance FLOAT;
ALTER TABLE #runner_orders_temp
ALTER COLUMN duration INT;
ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(100);

-- A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS pizza_order_count
FROM #customer_orders_temp;

--2. 2. How many unique customer orders were made?#
SELECT COUNT(DISTINCT order_id) AS unique_order_count
FROM #customer_orders_temp;

--3. How many successful orders were delivered by each runner?
SELECT 
  runner_id, 
  COUNT(order_id) AS successful_orders
FROM #runner_orders_temp
WHERE distance != 0
GROUP BY runner_id;

--4. How many of each type of pizza was delivered?
SELECT 
  p.pizza_name, 
  COUNT(c.pizza_id) AS delivered_pizza_count
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
  ON c.order_id = r.order_id
JOIN pizza_names AS p
  ON c.pizza_id = p.pizza_id
WHERE r.distance != 0
GROUP BY p.pizza_name;

--5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
  c.customer_id, 
  p.pizza_name, 
  COUNT(p.pizza_name) AS order_count
FROM #customer_orders_temp AS c
JOIN pizza_names AS p
  ON c.pizza_id= p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id;

--6. What was the maximum number of pizzas delivered in a single order?
WITH pizza_count_cte AS
(
  SELECT 
    c.order_id, 
    COUNT(c.pizza_id) AS pizza_per_order
  FROM #customer_orders_temp AS c
  JOIN #runner_orders_temp AS r
    ON c.order_id = r.order_id
  WHERE r.distance != 0
  GROUP BY c.order_id
)

SELECT 
  MAX(pizza_per_order) AS pizza_count
FROM pizza_count_cte;

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  c.customer_id,
  SUM(
    CASE WHEN c.exclusions <> ' ' OR c.extras <> ' ' THEN 1
    ELSE 0
    END) AS at_least_1_change,
  SUM(
    CASE WHEN c.exclusions = ' ' AND c.extras = ' ' THEN 1 
    ELSE 0
    END) AS no_change
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
  ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.customer_id
ORDER BY c.customer_id;

--8. How many pizzas were delivered that had both exclusions and extras?
SELECT  
  SUM(
    CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
    ELSE 0
    END) AS pizza_count_w_exclusions_extras
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
  ON c.order_id = r.order_id
WHERE r.distance >= 1 
  AND exclusions <> ' ' 
  AND extras <> ' ';

  --9. What was the total volume of pizzas ordered for each hour of the day?
  SELECT 
  DATEPART(HOUR, order_time) AS hour_of_day, 
  COUNT(order_id) AS pizza_count
FROM #customer_orders_temp
GROUP BY DATEPART(HOUR, order_time);

--10. What was the volume of orders for each day of the week?
SELECT 
  FORMAT(DATEADD(DAY, 2, order_time),'dddd') AS day_of_week, -- add 2 to adjust 1st day of the week as Monday
  COUNT(order_id) AS total_pizzas_ordered
FROM #customer_orders_temp
GROUP BY FORMAT(DATEADD(DAY, 2, order_time),'dddd');

-- B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
  DATEPART(WEEK, registration_date) AS registration_week,
  COUNT(runner_id) AS runner_signup
FROM runners
GROUP BY DATEPART(WEEK, registration_date);


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH time_taken_cte AS
(
  SELECT 
    c.order_id, 
    c.order_time, 
    r.pickup_time, 
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS pickup_minutes
  FROM #customer_orders_temp AS c
  JOIN #runner_orders_temp AS r
    ON c.order_id = r.order_id
  WHERE r.distance != 0
  GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT 
  AVG(pickup_minutes) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prep_time_cte AS
(
  SELECT 
    c.order_id, 
    COUNT(c.order_id) AS pizza_order, 
    c.order_time, 
    r.pickup_time, 
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time_minutes
  FROM #customer_orders_temp AS c
  JOIN #runner_orders_temp AS r
    ON c.order_id = r.order_id
  WHERE r.distance != 0
  GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT 
  pizza_order, 
  AVG(prep_time_minutes) AS avg_prep_time_minutes
FROM prep_time_cte
WHERE prep_time_minutes > 1
GROUP BY pizza_order;

-- 4. What was the average distance travelled for each customer?

SELECT 
  c.customer_id, 
  AVG(r.distance) AS avg_distance
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
  ON c.order_id = r.order_id
WHERE r.duration != 0
GROUP BY c.customer_id;


-- 5.What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN(duration) AS delivery_time_difference
FROM #runner_orders_temp
where duration != 0;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
  r.runner_id, 
  c.customer_id, 
  c.order_id, 
  COUNT(c.order_id) AS pizza_count, 
  r.distance, (r.duration / 60) AS duration_hr , 
  ROUND((r.distance/r.duration * 60), 2) AS avg_speed
FROM #runner_orders_temp AS r
JOIN #customer_orders_temp AS c
  ON r.order_id = c.order_id
WHERE distance != 0
GROUP BY r.runner_id, c.customer_id, c.order_id, r.distance, r.duration
ORDER BY c.order_id;

-- 7.What is the successful delivery percentage for each runner?

SELECT 
  runner_id, 
  ROUND(100 * SUM(
    CASE WHEN distance = 0 THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_perc
FROM #runner_orders_temp
GROUP BY runner_id;
