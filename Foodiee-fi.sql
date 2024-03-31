--How many customers has Foodie-Fi ever had?
select * from plans, subscriptions

 select count( distinct customer_id)
 from subscriptions

 --What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
 month(start_date) month_mumber, datename(month, start_date)AS month_name, -- Cast start_date as month in numerical format
 COUNT(s.customer_id) AS trial_plan_subscriptions
FROM subscriptions AS s
JOIN plans p
  ON s.plan_id = p.plan_id
WHERE s.plan_id = 0
group by  month(start_date), datename(month, start_date)
order by 1;

--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
 select distinct plan_name, count(start_date) as start_dates
 from plans p
 left join subscriptions s
 on p.plan_id = s.plan_id
 where YEAR(start_date) > 2020
 group by plan_name;

 -- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
 select
  count(distinct s.customer_id) AS churned_customers,
  round(100.0 * count(s.customer_id)
    / (select count(distinct customer_id) 
    	from subscriptions)
  ,1) AS churn_percentage
from subscriptions s
WHERE plan_id = 4;
 
 
