-- Section B — Window functions
-- Question 6 — County leaderboards
-- 42 rows (screenshot: screenshots/q06-county-leaderboards.png)
with customer_lifetime_revenue as (
	select c.customer_id,c.first_name || ' ' || c.last_name as full_name, c.county,
		sum(o.total_amount) as lifetime_revenue
	from sokomart.customers c 
	left join sokomart.orders o
	using(customer_id)
	where o.order_status = 'completed'
	group by c.customer_id, c.first_name || ' ' || c.last_name, c.county
), 
ranked_county_customer_lifetime_revenue as (
	select *,
		dense_rank() over(partition by county order by lifetime_revenue desc) as rank
	from customer_lifetime_revenue
)
select *
from ranked_county_customer_lifetime_revenue
where rank < 4;

-- Question 7 — Best sellers per category, 2025
-- 15 rows (screenshot: screenshots/q07-best-sellers-2025.png)
with product_sales_2025 as( 
	select p.product_id,p.product_name, p.category, sum(oi.quantity) as units_sold,
		sum(oi.line_total) as sold_amount
	from sokomart.products p 
	left join sokomart.order_items oi
	using(product_id)
	left join sokomart.orders o
	using(order_id)
	where o.order_status = 'completed' and
		o.order_date >= '2025-01-01' and o.order_date < '2026-01-01'
	group by p.product_id,p.product_name, p.category
),
ranked_product_sales_2025 as (
	select *,
		row_number() over(partition by category order by sold_amount desc, product_id) as rank
	from product_sales_2025
)
select *
from ranked_product_sales_2025
where rank < 4;
-- Question 8 — Month-over-month growth
-- 22 rows (screenshot: screenshots/q08-month-over-month-growth.png)
with monthly_revenue as (
	select extract(month from order_date) as month_no, extract(year from order_date) as year,
		to_char(order_date,'FMMonth-YYYY') as month,sum(oi.line_total) as revenue
	from sokomart.orders o
	join sokomart.order_items oi
	using(order_id)
	where o.order_status = 'completed'
	group by extract(month from order_date),extract(year from order_date),to_char(order_date,'FMMonth-YYYY')
	order by year,month_no
)
select month, revenue,
	lag(revenue) over() as previous_month,
	round(((revenue - lag(revenue) over())/revenue) * 100,2) as "growth%"
from monthly_revenue;
-- Question 9 — Is each order bigger than the last?
-- 393 rows (screenshot: screenshots/q09-nyeri-customer-order-comparison.png)
with nyeri_customers_ranked_orders as (
	select customer_id, order_id, order_date, total_amount,
		lag(o.total_amount) over(partition by c.customer_id order by order_date) as previous_order
	from sokomart.customers c
	left join sokomart.orders o
	using(customer_id)
	where o.order_date >='2026-01-01' and o.order_date < '2027-01-01'
		and o.order_status = 'completed'
		and c.county = 'Nyeri'
)
select *,
	total_amount - previous_order as change,
	case when previous_order is null then 'first order'
		when previous_order < total_amount then 'up'
		when previous_order > total_amount then 'down'
		else 'same'
		end as direction
from nyeri_customers_ranked_orders;
-- Question 10 — Year-to-date revenue
-- 22 rows (screenshot: screenshots/q10-yearly-monthly-running-revenue-total.png)
with yearly_monthly_revenue as (
	select extract(year from o.order_date) as year, extract(month from o.order_date) as month_no,
		to_char(o.order_date,'Month') as month, sum(oi.line_total) as monthly_revenue
	from sokomart.order_items oi 
	join sokomart.orders o 
	using(order_id)
	where o.order_status = 'completed'
	group by extract(year from o.order_date), extract(month from o.order_date),
		to_char(o.order_date,'Month')
)
select year, month, monthly_revenue,
	sum(monthly_revenue) over(
		partition by year
		rows between unbounded preceding and current row
		) as running_revenue_ytd,
	sum(monthly_revenue) over(rows between unbounded preceding and current row) as running_revenue_all_time
from yearly_monthly_revenue
order by year, month_no;

