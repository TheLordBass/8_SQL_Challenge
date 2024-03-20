--How many customers has Foodie-Fi ever had?
select * from plans, subscriptions

 select count( distinct customer_id)
 from subscriptions

 --What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
 month(start_date) month_mumber -- Cast start_date as month in numerical format
 , datename(month, start_date)AS month_name, 
 COUNT(s.customer_id) AS trial_plan_subscriptions
FROM subscriptions AS s
JOIN plans p
  ON s.plan_id = p.plan_id
WHERE s.plan_id = 0
group by  month(start_date), datename(month, start_date)
order by 1
