-- Section A
-- Question 1 — Big spenders of 2025
-- 3,145 rows (screenshot: screenshots/q01-big-spenders-2025.png)
with customers_2025_completed_orders as (
	select o.customer_id,c.first_name||' '|| c.last_name as full_name,
		c.county,coalesce(sum(o.total_amount),0) as total_revenue,
		avg(o.total_amount) as avg_Spent
	from sokomart.customers c
	left join sokomart.orders o
	using(customer_id)
	where o.order_date between '2024-12-31' and '2026-01-01' and 
		o.order_status = 'completed'
	group by o.customer_id,c.first_name||' '|| c.last_name, c.county
), average_2025 as (
	select avg(o.total_amount)
	from sokomart.orders o
	where o.order_date between '2024-12-31' and '2026-01-01' and 
		o.order_status = 'completed'
)
select *,
	total_revenue - (select * from average_2025) as amount_above_avg
from customers_2025_completed_orders
where total_revenue > (select * from average_2025);

-- Question 2 — Premium-priced products
-- 104 rows (screenshot: screenshots/q02-premium-priced-products.png)
select p.product_id , p.product_name, p.category, p.unit_price,
	(
	select avg(p2.unit_price)
	from sokomart.products p2
	where p2.category = p.category
	) category_avg_price,
	p.unit_price - (
	select avg(p2.unit_price)
	from sokomart.products p2
	where p2.category = p.category
	) price_gap
from sokomart.products p
where p.product_status = 'active' and
	p.unit_price > (
	select avg(p2.unit_price)
	from sokomart.products p2
	where p2.category = p.category
)
order by category, price_gap desc;

-- counting the rows per category
with premium_products as (
	select p.product_id , p.product_name, p.category, p.unit_price,
		(
		select avg(p2.unit_price)
		from sokomart.products p2
		where p2.category = p.category
		) category_avg_price,
		p.unit_price - (
		select avg(p2.unit_price)
		from sokomart.products p2
		where p2.category = p.category
		) price_gap
	from sokomart.products p
	where p.product_status = 'active' and
		p.unit_price > (
		select avg(p2.unit_price)
		from sokomart.products p2
		where p2.category = p.category
	)
	order by category, price_gap desc
)
select category, count(*) as product_count
from premium_products
group by category ;

-- Question 3 — 2026 monthly profit and loss
-- 10 rows (screenshot: screenshots/q03-2026-monthly-p&l.png) 
with completed_orders as (
	select to_char(o.order_date,'Month') as month, extract(month from order_date) month_no,
		oi.line_total as revenue, p.cost_price * oi.quantity as cost
	from sokomart.orders o 
	left join sokomart.order_items oi 
	using(order_id)
	left join sokomart.products p
	using(product_id)
	where o.order_status = 'completed' and
		o.order_date >= '2026-01-01' and o.order_date < '2026-11-01'
)
, monthly_revenue_cost as (
	select month,month_no, sum(revenue) as total_revenue, sum(cost) as total_cost
	from completed_orders
	group by month, month_no 
	order by month_no 
)
, gross_profit as (
	select month, total_revenue , total_cost , total_revenue - total_cost as gross_profit
	from monthly_revenue_cost
)
select *, round(gross_profit/total_revenue *100,2) as margin_pct
from gross_profit ;

-- Question 4 — Cross-category shoppers in Nakuru
-- 346 rows (screenshot: screenshots/q04-nakuru-cross-category-customers.png)
select cs.customer_id,concat(c.first_name,' ',c.last_name) as full_name, c.county,
	cs.category_count , cs.total_spent 
from sokomart.customers c
join (
	select o.customer_id, count(distinct(category)) as category_count,sum(oi.line_total ) as total_spent
	from sokomart.orders o
	left join sokomart.order_items oi 
	using(order_id)
	left join sokomart.products p
	using(product_id)
	where o.order_status = 'completed'
	group by customer_id
	having count(distinct(category)) >=3
	order by category_count desc, total_spent desc
) cs
using(customer_id)
where c.county = 'Nakuru';

-- second query
select count(*) as qualifying_customers_count,
	count(*) filter(where cs.category_count = 5) as bought_5_categories_count
from sokomart.customers c
join (
	select o.customer_id, count(distinct(category)) as category_count,sum(oi.line_total ) as total_spent
	from sokomart.orders o
	left join sokomart.order_items oi 
	using(order_id)
	left join sokomart.products p
	using(product_id)
	where o.order_status = 'completed'
	group by customer_id
	having count(distinct(category)) >=3
	order by category_count desc, total_spent desc
) cs
using(customer_id)
where c.county = 'Nakuru';

-- Question 5 — Products nobody has ordered
-- 8 rows (screenshot: screenshots/q05-products-not-ordered.png)
-- not in
select *
from sokomart.products
where product_id not in (
	select distinct(product_id)
	from sokomart.order_items
);
-- left join ---is null
select p.*
from sokomart.products p
left join sokomart.order_items oi
using(product_id)
where oi.order_item_id is null;
-- anti join - not exist
select category, count(*)
from sokomart.products p
where not exists (
	select 1
	from sokomart.order_items oi
	where oi.product_id = p.product_id 
)
group by category ;





