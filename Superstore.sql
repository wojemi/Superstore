use superstore; 

-- 1) Number of customers by segment
select * from rc_upload;
select 
	segment,
	count(customer_id) as count
from rc_upload 
group by segment;

-- 2) How the number of customers changed month to month
select * from rc_upload; 

with 
first_step as
(
	select 
		date_format(order_date, '%Y-%m') as month_and_year,
		count(customer_id) as customer_count
	from rc_upload 
	group by date_format(order_date, '%Y-%m')
),
second_step as
(
	select 
		month_and_year,
		customer_count,
		customer_count - lag(customer_count) over (order by month_and_year) as previous_customer_count
	from first_step 
)
select * from second_step;

-- 3) What is the average time difference between order placement and delivery date depending on the type of delivery?
select * from rc_upload;

select 
	ship_mode,
	round(avg(datediff(ship_date, order_date)), 2) as time_diff
from rc_upload
group by ship_mode;

-- 4) W jaki dzień tygodnia najczęściej składane są zamówienia
select * from rc_upload; 

select 
	case 
		when dayofweek(order_date) = 1 then 'Sunday'
		when dayofweek(order_date) = 2 then 'Monday'
		when dayofweek(order_date) = 3 then 'Tuesday'
		when dayofweek(order_date) = 4 then 'Wednesday'
		when dayofweek(order_date) = 5 then 'Thursday'
		when dayofweek(order_date) = 6 then 'Friday'
		when dayofweek(order_date) = 7 then 'Saturday'
	end as day_of_week,
	count(*) as order_count
from rc_upload
group by day_of_week
order by 
	case
		when day_of_week = 'Monday' then 1
		when day_of_week = 'Tuesday' then 2
		when day_of_week = 'Wednesday' then 3
		when day_of_week = 'Thursday' then 4
		when day_of_week = 'Friday' then 5
		when day_of_week = 'Saturday' then 6
		when day_of_week = 'Sunday' then 7
	end;

-- 5) In which category and subcategory are sales the highest?
select * from rc_upload; 

select 
	cetegory,
	sub_category,
	sum(sales) as total_sales
from rc_upload
where 
	cetegory is not null
group by cetegory, sub_category
order by 1;

-- 6) List of subcategories from each category where sales are the highest
select * from rc_upload; 

with 
first_step as
(
	select  
		cetegory,
		sub_category,
		sum(sales) as total_sales
	from rc_upload
	group by cetegory, sub_category
),
second_step as
(
	select 
		cetegory,
		sub_category,
		total_sales,
		row_number() over (partition by cetegory order by total_sales desc) as total_sales_ranked
	from first_step
)
select * from second_step
where 
	cetegory is not null
and 
	total_sales_ranked = 1;

-- 7) Correlation between discount volume and sales volume over time (monthly)
select * from rc_upload; 

with
first_step as
(
	select 
		date_format(order_date, '%Y-%m') as year_and_month,
		(count(*) * sum(discount * sales) - sum(discount) * sum(sales)) / (sqrt(count(*) * sum(power(discount, 2)) - power(sum(discount), 2)) * sqrt(count(*) * sum(power(sales, 2)) - power(sum(sales), 2))) as Pearson
	from rc_upload
	where 
		discount is not null
	and 
		sales is not null
	group by date_format(order_date, '%Y-%m')
),
second_step as
(
	select
		year_and_month,
		Pearson,
		case 
			when Pearson = -1 then 'Idealna ujemna korelacja'
			when Pearson > -1 and Pearson < -0.7 then 'Silna / bardzo silna ujemna zależność'
			when Pearson >= -0.7 and Pearson < -0.5 then 'Umiarkowana / silna ujemna zależność'
			when Pearson >= -0.5 and Pearson < -0.3 then 'Słaba / umiarkowana ujemna zależność'
			when Pearson >= -0.3 and Pearson < 0 then 'Bardzo słaba ujemna zależność'
			when Pearson = 0 then 'Brak zależności liniowej'
			when Pearson >= 0 and Pearson < 0.3 then 'Bardzo słaba zależność'
			when Pearson >= 0.3 and Pearson < 0.5 then 'Słaba / umiarkowana zależność'
			when Pearson >= 0.5 and Pearson < 0.7 then 'Umiarkowana / silna zależność'
			when Pearson >= 0.7 and Pearson < 1 then 'Silna / bardzo silna zależność'
			when Pearson = 1 then 'Idealna dodatnia korelacja'
		end as Pearson_definition
	from first_step 
)
select * from second_step 
order by 1;

-- 8) Customer list and number of orders over time
select * from rc_upload; 

with 
first_step as
(
	select 
		customer_id,
		customer_name,
		date_format(order_date, '%Y-%m') as year_and_month,
		count(order_id) as order_count
	from rc_upload
	where 
		customer_id is not null
	group by customer_id, customer_name, date_format(order_date, '%Y-%m')
)
select * from first_step 
where 
	customer_name = 'Alex Avila'  -- przykład dla konkretnego klienta
order by 1, 3;
	
-- 9) In which quarter of 2014 were there the most orders?
select * from rc_upload;

with 
first_step as
(
	select 
		quarter(order_date) as quarter_of_the_year,
		count(*) as order_count
	from rc_upload 
	where 
		extract(year from order_date) = 2014
	group by quarter(order_date)
),
second_step as
(
	select 	
		case 
			when quarter_of_the_year = 1 then 'I kwartał'
			when quarter_of_the_year = 2 then 'II kwartał'
			when quarter_of_the_year = 3 then 'III kwartał'
			when quarter_of_the_year = 4 then 'IV kwartał'
		end as quart,
		order_count,
		dense_rank() over (order by order_count desc) as ranked
	from first_step
)
select * from second_step 
where 
	ranked = 1
order by 1;  -- w IV kwartale 2014 roku było najwięcej złożonych zamówień

-- 10) Which states (select 5) have the highest sales by product in the 'Technology' category?
select * from rc_upload; 

with 
first_step as
(
	select 
		state,
		cetegory,
		sum(sales) as total_sales
	from rc_upload
	where 
		state is not null
	and 
		cetegory = 'Technology'
	group by state, cetegory 
),
second_step as
(
	select 
		state,
		cetegory,
		total_sales,
		row_number() over (order by total_sales desc) as total_sales_ranked
	from first_step
)
select * from second_step
where 
	total_sales_ranked <= 5;

-- 11) Top 10 Products That Create the Highest Income (Which Category and Subcategory Do They Belong to)
select * from rc_upload; 

with 
first_step as
(
	select 
		cetegory,
		sub_category,
		product_name,
		sum(profit) as total_profit
	from rc_upload
	group by cetegory, sub_category, product_name
),
second_step as
(
	select 
		cetegory,
		sub_category,
		product_name,
		total_profit,
		dense_rank() over (order by total_profit desc) as total_profit_ranked
	from first_step
)
select * from second_step
where 
	total_profit_ranked <= 10;

-- 12) How sales and profits change by category in 2014
select * from rc_upload; 

select  
	date_format(order_date, '%Y-%m') as order_date,
	cetegory,
	sum(sales) as total_sales,
	sum(profit) as total_profit
from rc_upload
where 
	extract(year from order_date) = 2014
group by date_format(order_date, '%Y-%m'), cetegory
order by 2, 1;

-- 13) Cumulative sales value month-on-month from 2014 to the end of 2017
select * from rc_upload;

with 
first_step as
(
	select 
		date_format(order_date, '%Y-%m') as order_date,
		sum(sales) as total_sales
	from rc_upload
	where 
		order_date is not null
	group by date_format(order_date, '%Y-%m')
),
second_step as
(
	select 
		order_date,
		total_sales,
		sum(total_sales) over(order by order_date) as cumulative_value
	from first_step
)
select * from second_step 
order by 1;





















