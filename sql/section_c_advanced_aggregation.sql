-- Section C — Advanced aggregation with subqueries
-- Question 11 — Customer tiers
-- Platinum ≥ KES 1,000,000; Gold ≥ 500,000; Silver ≥ 100,000; Bronze below 100,000.
-- 4 rows (screenshot: screenshots/q11-customer-tiers.png)
with customer_lifetime_tier as (
	select *,
		case when lifetime_revenue >=1000000 then 'Platinum'
			when lifetime_revenue >=500000 then 'Gold'
			when lifetime_revenue >=100000 then 'Silver'
			else 'Bronze'
			end as tier
	from (
		select c.customer_id ,cr.lifetime_revenue
		from sokomart.customers c
		join (
			select o.customer_id, sum(oi.line_total) as lifetime_revenue
			from sokomart.orders o
			join sokomart.order_items oi
			using(order_id)
			where o.order_status ='completed'
			group by customer_id
		) cr
		using(customer_id)
	)
)
select tier, count(*) as customer_count,
	min(lifetime_revenue) as min_spent, max(lifetime_revenue) as max_spent,
	avg(lifetime_revenue) as avg_spent,
	round(sum(lifetime_revenue)/(
		select sum(lifetime_revenue)
		from customer_lifetime_tier
	) *100,2) as revenue_share_pct
from customer_lifetime_tier
group by tier;
-- Question 12 — What did Mombasa buy in October?
-- 152 rows (screenshot: screenshots/q12-mombasa-customers-products.png)
select c.customer_id, c.first_name|| ' '|| c.last_name as full_name,
	count(p.product_id) as product_count,
	STRING_AGG(DISTINCT p.product_name, ', ' ORDER BY product_name ASC) as products_ordered
from sokomart.customers c
join sokomart.orders o
using(customer_id)
join sokomart.order_items oi
using(order_id)
join sokomart.products p
using(product_id)
where c.county ='Mombasa'
	and exists (
	select 1
	from  sokomart.orders o
	where o.order_status != 'cancelled'
		and o.customer_id = c.customer_id
		and o.order_date >='2026-10-01' and o.order_date < '2026-11-01'
)
group by c.customer_id, c.first_name|| ' '|| c.last_name ;
-- Question 13 — Payment health by method, 2026
-- 4 rows (screenshot: screenshots/q13-payment-methods-2026-health.png)
with payments_2026_counts as (
	select p.payment_method, count(*) as payment_total,
		count(*) filter(where p.payment_status = 'successful') as successfull_total,
		count(*) filter(where p.payment_status = 'pending') as pending_total,
		count(*) filter(where p.payment_status = 'failed') as failed_total,
		sum(p.amount) filter(where p.payment_status = 'failed') as failed_amount
	from sokomart.payments p 
	where p.payment_date >='2026-01-01' and p.payment_date <'2027-01-01'
	group by p.payment_method
)
select *,
	round((successfull_total ::Numeric / payment_total)*100,2) as success_rate_pct
from payments_2026_counts;
-- Question 14 — Which departments carry the profit?
-- 2 rows (screenshot: screenshots/q14-categories-profit-above-average.png)
with category_revenue_profit_2025 as (
	select p.category, sum(oi.line_total) as revenue,
		sum(oi.line_total) - sum(oi.quantity * p.cost_price) as gross_profit
	from sokomart.order_items oi
	join sokomart.orders o 
	using(order_id)
	join sokomart.products p
	using(product_id)
	where o.order_status='completed'
		and o.order_date >='2025-01-01' and o.order_date < '2026-01-01'
	group by p.category
),above_average_category_profit as (
	select *,
		round((gross_profit / revenue)*100,2) as margin_pct,
		(
		select avg(gross_profit)
		from category_revenue_profit_2025
		) as avg_category_gross_profit
	from category_revenue_profit_2025 
	where gross_profit > (
		select avg(gross_profit)
		from category_revenue_profit_2025
	)
)
select *,
	round(((gross_profit - avg_category_gross_profit) / avg_category_gross_profit )*100,2) as pct_above_avg
from above_average_category_profit ;
-- Question 15 — One sales table with subtotals
-- 36 rows (screenshot: screenshots/q15-sales-table-with-subtotals.png)
with counties_2026_revenue as (
select o.shipping_county as county, p.category,oi.line_total
from sokomart.order_items oi 
join sokomart.orders o 
using(order_id)
join sokomart.products p
using(product_id)
where o.order_status = 'completed'
	and o.shipping_county in ('Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Uasin Gishu')
	and o.order_date >='2026-01-01' and o.order_date < '2027-01-01'
)
select 
	case when grouping(county) = 0 and grouping(category) = 0 then 'county x category'
		when grouping(county) = 0 then 'county total'
		when grouping(category) = 0 then 'category total'
		else 'grand total'
		end as grouping_level,
		coalesce(county,'ALL COUNTIES') as county,
		coalesce(category,'ALL CATEGORIES') as category, 
		sum(line_total) as revenue,
		count(*) as order_count
from counties_2026_revenue 
group by grouping sets(
	(county,category),
	(county),
	(category),
	()
);




