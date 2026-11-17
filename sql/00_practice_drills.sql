-- D1 List the products whose unit_price is above the average unit_price of all products.
-- Show the 10 most expensive, then on a second query the count.
select p.product_id, p.product_name, p.category, p.unit_price,
	(
	select avg(p2.unit_price )
	from sokomart.products p2
	)
from sokomart.products p
where p.unit_price > (
	select avg(p2.unit_price )
	from sokomart.products p2 
)
order by p.unit_price desc
limit 10;

select count(*) as product_count
from sokomart.products p
where p.unit_price > (
	select avg(p2.unit_price )
	from sokomart.products p2 
);
-- D2 List customers living in Mombasa who placed at least one order (any status) in December 2025.
select *
from sokomart.customers c
where c.county = 'Mombasa' and
	c.customer_id in (
	select o.customer_id
	from sokomart.orders o
	group by o.customer_id 
	having count(*) >=1
);
-- D3 How many customers living in Kisumu have at least one payment with payment_status = 'failed'?
select count(*) as kisumu_customers_with_failed_payment
from sokomart.customers c
where c.county ='Kisumu'
	and exists (
	select 1
	from sokomart.payments p
	join sokomart.orders o 
	using (order_id)
	where p.payment_status = 'failed'
	and o.customer_id =c.customer_id 
) ;
-- D4 For each order_status, show the number of orders, the average number of lines per order and the average 
-- number of units per order. Compute the per-order figures in a subquery in FROM.
select order_status, count(*) as no_of_orders, avg(line_total) as avg_no_of_lines,
	avg(quantity) as avg_no_of_units
from (
	select o.order_status, oi.line_total, oi.quantity
	from sokomart.orders o
	join sokomart.order_items oi 
	using(order_id)
)
group by order_status ;

-- D5 Top 5 shipping counties by number of completed orders in 2026. Put the filtered orders in a CTE.
with completed_orders_2026 as (
	select o.order_id, o.shipping_county
	from sokomart.orders o 
	where o.order_date >= '2026-01-01' and
		o.order_date <= '2026-12-31' and
		o.order_status = 'completed'
)
select shipping_county, count(*) as completed_orders
from completed_orders_2026
group by shipping_county
order by count(*) desc
limit 5;
-- D6 For 2025: completed orders per month, the 2025 monthly average, and whether each month 
-- is above average or at/below average.Use two CTEs (monthly counts, then the stats).
with monthly_counts as(
	select extract(month from o.order_date) as month_no, 
		to_char(o.order_date,'Month') as month,count(*) as order_count
	from sokomart.orders o 
	where o.order_date >= '2025-01-01' and 
		o.order_date<'2026-01-01' and 
		o.order_status = 'completed'
	group by extract(month from o.order_date),to_char(o.order_date,'Month')
	order by 1
),
stats as(
	select month,order_count,
		(select avg(order_count) from monthly_counts) as overall_avg
	from monthly_counts
)
select *,
	case when order_count > overall_avg then 'Above Average'
		when order_count = overall_avg then 'At  Average'
		else 'Below Average'
		end 
from stats;
-- D7 Write sokomart.fn_order_count(p_customer_id INTEGER) RETURNS INTEGER — 
-- the number of orders (any status) a customer has. Call it for customer 177 and for a
-- customer that does not exist (-1).
create or replace function sokomart.fn_order_count(p_customer_id INTEGER)
returns integer
language plpgsql
as $$
declare v_count integer;
begin
	select count(*)
	into v_count
	from sokomart.orders o
	where o.customer_id = p_customer_id;
	
	return v_count;
end
$$;

select sokomart.fn_order_count(1);
select sokomart.fn_order_count(-1);
-- D8 Write sokomart.sp_set_customer_status(p_customer_id INTEGER, p_status VARCHAR). 
-- It raises an exception for a status other than active / inactive / suspended, and for a customer that does
-- not exist. Inside BEGIN … ROLLBACK, set customer 177 to suspended, show it, roll back, show it is active again.
-- Then show the exception for status 'vip'.
create or replace procedure sokomart.sp_set_customer_status(p_customer_id INTEGER, p_status VARCHAR)
language plpgsql
as $$
begin
	--	status exception
	if p_status is null or p_status not in ('active','inactive','suspended') then
		raise exception 'Invalid status. Only "active","inactive","suspended" accepted';
	end if;
	--	update customer status
	update sokomart.customers
	set customer_status = p_status
	where customer_id = p_customer_id;
	
    --	customer doesn't exist
    if not found then
    	raise exception 'Customer with ID % doesn''t exist', p_customer_id;
    end if;
end
$$;

-- transaction
begin;
-- set customer 177 to suspended
call sokomart.sp_set_customer_status(177,'suspended');
-- show update
select *
from sokomart.customers c
where c.customer_id = 177;
-- rollback
rollback;
-- show customer 177
select *
from sokomart.customers c
where c.customer_id = 177;

-- D9 Beauty products whose stock_quantity is below the average Beauty stock.
with beauty_products as (
	select *
	from sokomart.products p
	where p.category = 'Beauty'
)
select *
from beauty_products
where stock_quantity < (
	select avg(stock_quantity)
	from beauty_products 
);
-- D10 Write sokomart.sp_county_summary(IN p_county VARCHAR, OUT p_customers INTEGER, OUT p_revenue NUMERIC)
-- returning the number of customers living in the county and their completed revenue.
-- CALL sokomart.sp_county_summary('Nakuru', NULL, NULL);
create or replace procedure sokomart.sp_county_summary
(IN p_county VARCHAR, OUT p_customers INTEGER, OUT p_revenue NUMERIC)
language plpgsql
as $$
begin
	select count(*), sum(o.total_amount)
	into p_customers,p_revenue
	from sokomart.customers c
	left join sokomart.orders o
	using(customer_id)
	where c.county = p_county;
end;
$$;

call sokomart.sp_county_summary('Nakuru', NULL, NULL);


-- Customer Order Summary - stored procedure
create or replace procedure sokomart.sp_customer_order_summary
(in p_customer_id int,out p_return_customer_id int,out p_customer_name varchar ,out p_order_id int,out p_order_total numeric)
language plpgsql
as $$
begin
	select c.customer_id,
			c.first_name ||' '|| c.last_name as customer_name,
			count(o.order_id),
			sum(o.total_amount)
	into p_return_customer_id,p_customer_name,p_order_id,p_order_total
	from sokomart.customers c
	join sokomart.orders o
	using(customer_id)
	where customer_id = p_customer_id
	group by c.first_name ||' '|| c.last_name,c.customer_id;
end;
$$;
drop procedure sokomart.sp_customer_order_summary;
call sokomart.sp_customer_order_summary(311,null, null, null, null);
-- Customer Order Summary - function
create or replace function sokomart.fn_customer_order_summary(p_customer_id int)
returns table(
	customer_name text,
	customer_id int,
	order_count bigint,
	total_spend numeric
)
language plpgsql
as $$
begin
	return query
	select c.first_name ||' '|| c.last_name as customer_name,c.customer_id,
			count(o.order_id),
			sum(o.total_amount)
	from sokomart.customers c
	join sokomart.orders o
	using(customer_id)
	where c.customer_id = p_customer_id
	group by c.first_name ||' '|| c.last_name,c.customer_id;
end;
$$;

select * from sokomart.fn_customer_order_summary(311);












