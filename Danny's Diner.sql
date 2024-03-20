--1. What is the total amount each customer spent at the restaurant
select  customer_id, sum(price) as Total_Spend
from sales s
left join menu m
on s.product_id = m.product_id
group by customer_id


-- How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as no_of_days
from sales
group by customer_id

--What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT customer_id, order_date, product_name,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY sales.order_date) AS rank
  FROM sales
  left JOIN menu
    ON sales.product_id = menu.product_id
)

SELECT 
  customer_id, 
  product_name
FROM ordered_sales
WHERE rank = 1
GROUP BY customer_id, product_name;

--Which item was the most popular for each customer?
select top 3 customer_id, product_name, count(s.product_id) as popular
from sales s
left join menu m
on s.product_id = m.product_id
group by customer_id, product_name
order by  3 desc

-- Which item was purchased just before the customer became a member?#

WITH joined AS (
  SELECT
    members.customer_id, 
    sales.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY members.customer_id
      ORDER BY sales.order_date) AS row_num
  FROM members
  INNER JOIN sales
    ON members.customer_id = sales.customer_id
    AND sales.order_date > members.join_date
)

SELECT 
  customer_id, 
  product_name 
FROM joined
INNER JOIN menu
  ON joined.product_id = menu.product_id
WHERE row_num = 1
ORDER BY customer_id ASC

--What is the total items and amount spent for each member before they became a member?

select m.customer_id, count(s.product_id) as total_items, sum(me.price) as totaal_amount_spent from members m
left join sales s
on m.customer_id = s.customer_id
left join menu me
on s.product_id = me.product_id
where s.order_date < m.join_date
group by m.customer_id

  
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
  
with point_system as(
select product_name, product_id, 
case 
when product_name != 'sushi' then price * 10 
when product_name = 'sushi' then 2*(price * 10)  end as points
from menu)

select distinct s.customer_id, sum(ps.points) as total_points
from sales s
left join point_system ps
on s.product_id = ps.product_id
group by s.customer_id

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

  WITH dates_cte AS (
  SELECT 
    customer_id, 
      join_date, 
      join_date + 6 AS valid_date, 
      DATE_TRUNC(
        'month', '2021-01-31'::DATE)
        + interval '1 month' 
        - interval '1 day' AS last_date
  FROM dannys_diner.members
)

SELECT 
  sales.customer_id, 
  SUM(CASE
    WHEN menu.product_name = 'sushi' THEN 2 * 10 * menu.price
    WHEN sales.order_date between dates.join_date and dates.valid_date THEN 2 * 10 * menu.price
    ELSE 10 * menu.price END) AS points
FROM dannys_diner.sales
left join dates_cte AS dates
  ON sales.customer_id = dates.customer_id
  AND dates.join_date <= sales.order_date
  AND sales.order_date <= dates.last_date
left join dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
