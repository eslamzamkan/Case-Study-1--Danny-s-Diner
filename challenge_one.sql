 /*What is the total amount each customer spent at the restaurant?*/
 select customer_id,sum(price) as Total_Price from menu m
 inner join sales s
 on m.product_id=s.product_id
 group by customer_id

 /*How many days has each customer visited the restaurant?*/
 select * from sales
 select customer_id,count(distinct order_date) as days_visited from sales
 group by customer_id
 order by days_visited desc

 /*What was the first item from the menu purchased by each customer?*/

 /*using dense rank*/
 with ordered_sales As (select s.customer_id,u.product_name,s.order_date,
 DENSE_RANK() over(partition by s.customer_id order by s.order_date)
  as Rank from sales s
 inner join menu u
 on s.product_id=u.product_id
 )
 select customer_id,product_name from ordered_sales
 where Rank=1
 group by customer_id ,product_name

 /*using rank function*/
 select distinct customer_id,product_name,order_date from(
 select s.customer_id,u.product_name,s.order_date,
 rank() over(partition by s.customer_id order by s.order_date)
  as Rank from sales s
 inner join menu u
 on s.product_id=u.product_id
 )a
 where rank=1

/*What is the most purchased item on the menu and how many times was it purchased by all customers?*/
select top 1 product_name,count(sales.product_id)as most_purchased from menu
inner join sales
on sales.product_id=menu.product_id
group by  product_name
order by most_purchased desc

/*Which item was the most popular for each customer?*/
select customer_id,product_name,order_count from( 
select sales.customer_id,menu.product_name,count(sales.product_id) as order_count,
rank()over(partition by sales.customer_id order by count(sales.product_id) desc)as rank from menu
inner join sales 
on sales.product_id=menu.product_id
group by sales.customer_id,menu.product_name
) a
where rank=1

/*Which item was purchased first by the customer after they became a member?*/
with order_sales as(
select sales.product_id,members.customer_id,
rank() over(partition by members.customer_id order by order_date)as rank from members
inner join sales
on
 members.customer_id=sales.customer_id
and members.join_date < sales.order_date
)
select customer_id,product_name from order_sales
inner join menu
on
menu.product_id=order_sales.product_id
where rank=1

/*Which item was purchased just before the customer became a member?*/
with order_sales as(
select sales.product_id,members.customer_id,
row_number() over(partition by members.customer_id order by order_date desc)as rank from members
inner join sales
on
 members.customer_id=sales.customer_id
and members.join_date > sales.order_date
)
select customer_id,product_name from order_sales
inner join menu
on
menu.product_id=order_sales.product_id
where rank=1

/*What is the total items and amount spent for each member before they became a member?*/
select sales.customer_id,count(sales.product_id)as total_item,sum(menu.price)as total_sale from  sales
inner join members
on
members.customer_id=sales.customer_id
and members.join_date > sales.order_date
inner join menu
on
menu.product_id=sales.product_id
group by sales.customer_id

/*If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?*/
with cte_point as ( select menu.product_id,
case when menu.product_name='sushi' then price*20 
else price*10 
end as points
 from menu
)
select sales.customer_id,sum(cte_point.points)as total_points  from sales
inner join cte_point
on cte_point.product_id=sales.product_id
group by sales.customer_id

/*anothe solution using left join*/
select customer_id,sum(case when menu.product_name='sushi' then price*20 
else price*10 
end )as points from sales
left join menu 
on 
sales.product_id=menu.product_id
group by customer_id

/*In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?*/
select customer_id,
       sum(points) points
from (select s.customer_id,
         case when product_name = 'sushi' and
                s.order_date between dateadd(day,-1,ms.join_date) and dateadd(day, 6, ms.join_date) then m.price*40
              when product_name = 'sushi' or
                s.order_date between dateadd(day,-1,ms.join_date) and dateadd(day, 6, ms.join_date) then m.price*20
         else price*10 end points
      from members ms
      left join sales s on s.customer_id = ms.customer_id
      left join menu m on s.product_id = m.product_id
      where s.order_date <= '20210131') a
group by customer_id;

/*BONUS QUESTIONS*/
/*Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)*/
select sales.customer_id,sales.order_date,menu.product_name,menu.price,
case
when members.join_date>sales.order_date then 'N'
when members.join_date<=sales.order_date then 'Y'
else 'N'
end as member
 from sales
inner join menu
on sales.product_id=menu.product_id
LEFT join members
on members.customer_id=sales.customer_id
order by sales.customer_id, sales.order_date 

/*Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.*/

with cte_rank as(select sales.customer_id,sales.order_date,menu.product_name,menu.price,
case
when members.join_date>sales.order_date then 'N'
when members.join_date<=sales.order_date then 'Y'
else 'N' end as member
from sales
inner join menu
on sales.product_id=menu.product_id
LEFT join members
on members.customer_id=sales.customer_id)
select *,case when
member='N' then Null
else rank() over(partition by customer_id,member order by order_date)
 end as ranking
from cte_rank


