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
