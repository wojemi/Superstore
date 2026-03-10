use SUPERSTORE;

select * from rc_upload;

show columns from rc_upload;

-- 1) Analysis of several variables
select 
	count(*) as total_rows,
	round(avg(sales), 2) as avg_sales,
	min(quantity) as min_quantity,
	max(discount) as max_discount
from rc_upload;

-- The table consists of 10,290 rows, average sales are 113,227.11, minimum quantity of sold items are 1 and maximum discount was granted at 45%.

-- 2) Missing variables
select 
	count(*) - count(returned) as missing_values
from 
	rc_upload;

-- 3) Let's check how discounts affect sales
with correlation as
(  
	select 
		avg(discount) as avg_discount,
		avg(sales) as avg_sales,
		count(*) as count 
	from rc_upload
),
second_step as
(
	select 
		discount - avg_discount as x_1,
		sales - avg_sales as x_2
	from rc_upload, correlation c
)
select 
	sum(x_1 * x_2) / (sqrt(sum(x_1 * x_1)) * sqrt(sum(x_2 * x_2))) as corr
from second_step;

-- Correlation between discounts and sales is equal to 0.394. We have a positive correlation (> 0 ), so our variables grow together in the same direction.

-- 4) How sales and profits changed over the time (2014-2017)
select 
	min(order_date),  -- the first order was made on 3.01.2014 
	max(order_date)   -- the last order was made on 30.12.2017
from rc_upload;

select 
	date_format(order_date, '%Y') as order_year,
	sum(sales) as total_sales,
	sum(profit) as total_profit
from rc_upload
where 
	sales is not null
and 
	profit is not null
group by order_year
order by order_year;

-- Total sales increased every year, but profit fell in 2015 compared to 2014. From 2015 profit started to increase.

-- 5) Why in 2015 profit decreased even if the sales increased?
select
	date_format(order_date, '%Y') as order_year,
	sum(sales) as total_sales,
	sum(profit) as total_profit,
	sum(sales) / count(distinct order_id) as avg_order_id
from rc_upload
where 
	sales is not null
group by order_year;

-- in 2015 total sales increased, total profit decreased and average order value increased

-- Let's check the amount of orders in each year
select 
	date_format(order_date, '%Y') as order_year,
	count(distinct order_id) as order_count
from rc_upload
where 
	order_id is not null
and 
	order_date is not null
group by order_year ;

-- In 2015 the number of orders increased from 969 to 1,038. This is not the reason for klower profits. I need to check further.

-- So let's check the margin.
select  
	date_format(order_date, '%Y') as order_year,
	sum(sales) as total_sales,
	sum(profit) as total_profit,
	sum(profit) / sum(sales) as margin
from rc_upload
where 
	sales is not null
and 
	 profit is not null 
group by order_year
order by order_year;

-- The margin decreased in 2015 from 1.64 to 1.25 -> this is the reason for the lower profit in 2015 compared to 2014.

-- Let's check the discount level:
select 
	date_format(order_date, '%Y') as order_year,
	avg(discount) as avg_discount,
	sum(discount) as total_discount
from rc_upload
where
	discount is not null 
group by order_year
order by order_year;

-- The average discount level in 2015 increased compared to 2014 so this is also the reason for the lower profit in 2015.

-- 6) Which months of 2014 are known for high and low sales?
with first_step as
(
	select 
		date_format(order_date, '%Y-%m') as order_year,
		sum(sales) as total_sales
	from rc_upload
	where 
		sales is not null
	group by order_year 
),
second_step as
(
	select 
		order_year,
		total_sales,
		row_number() over (order by total_sales desc) as total_sales_ranked
	from first_step
)
select * from second_step
where 
	order_year = 2015;

-- In 2014 the month with highest sales was September, and with lowest - February.

-- 7) Let's compare sales in each quarter of years 2014-2017
with first_step as
(
	select 
		date_format(order_date, '%Y') as order_year,
		quarter(order_date) as quarter,
		sum(sales) as total_sales
	from rc_upload
	where sales is not null 
	group by order_year, quarter
),
second_step as
(
	select 
		order_year,
		quarter,
		total_sales,
		lag(total_sales) over (order by order_year, quarter) as previous_quarter,
		total_sales - lag(total_sales) over (order by order_year , quarter) as previous_quarter_comparison,
		concat(round((total_sales - lag(total_sales) over (order by order_year, quarter)) / lag(total_sales) over (order by order_year, quarter) * 100,2), '%')
	from first_step
)
select * from second_step
order by order_year, quarter;

-- In the second quarter of 2014 the store registered 55.01% increase in sales compared to first quarter of 2014. But in first quarter of 2015 the store's sales decreased about 35.17% compared to the fourth quarter of 2014.
-- What we can observe is the fact that first quarters of each year are characterized by a decline in sales.

-- 8) Which product's categories generate the highest sales?
select * from rc_upload;

with first_step as
(
	select 
		category,
		sum(sales) as total_sales
	from rc_upload
	where 
		sales is not null
	group by category
),
second_step as
(
	select 
		category,
		total_sales,
		row_number() over (order by total_sales desc) as total_sales_ranked
	from first_step
)
select * from second_step;

-- The highest sales are generated by Furniture category, then by Technology and at the end we have Office Supplies.

-- 9) Which product's category generates high sales and low profit
select 
	category,
	sum(sales) as total_sales,
	sum(profit) as total_profit
from rc_upload
where 
	sales is not null
and 
	profit is not null 
group by category;

-- Furnitures generate the highest sales nad at the same time the lowest profits.
-- Products from Technology category generate the highest profits with the highest sales.
-- Office supplies category generates high profits with the lowest sales.
-- Conclusion: Company should focus on selling Office Supplies and Technology products, because they generate the highest profits with low sales.

-- 10) What's the average time difference between placing and receiving an order?
select 
	ship_mode,
	round(avg(datediff(ship_date, order_date)), 2) as time_diff
from rc_upload
where ship_mode is not null
group by ship_mode;

-- People who order 'Standard Class' delivery wait the longest -> about 5 days

-- 11) How many customers are responsible for 75% of sales?
select * from rc_upload;

with first_step as
(
	select 
		customer_id,
		sum(sales) as total_sales
	from rc_upload
	group by customer_id 
),
second_step as
(
	select 	
		customer_id,
		total_sales,
		sum(total_sales) over (order by total_sales) as running_total_sales,
		sum(total_sales) over () as total
	from first_step
)
select 
	count(*) as customer,
	max(running_total_sales) / max(total) * 100 as prc_sales
from second_step 
where 
	running_total_sales <= 0.75 * total;

-- 759 customers generate 75% of sales.

-- 12) Which region generates the highest sales and profit?
select 
	state,
	sum(sales) as total_sales,
	sum(profit) as total_profit
from rc_upload
where sales is not null
group by state
order by total_sales desc

-- The US state that generates the highest sales is California - one of the largest states and the most populous state in the US.
-- California also generates the second highest profits.
-- The highest profits are generated by New York. California and New York are the wealthiest states in the US, so most profits come from these regions.
-- What's more, New York needs half of the sales generated by California to generate the same (or even slighlty higher) profits.
-- On the other hand Texas generates the largest losses with high sales (Texas is on the second place in terms of high sales).

-- 13) List of products that generate the largest losses
select  
	product_name,
	sum(profit) as total_profit
from rc_upload
where 
	profit is not null
group by product_name
having total_profit < 0
order by total_profit asc;

-- Product that generates the largest losses is called: 'Cubify CubeX 3D Printer Triple Head Print' 
-- Company should consider reducing sales of this product to minimize losses.

-- 14) Which poducts generate the highest profit?
select 
	product_name,
	sum(profit) as total_profit
from rc_upload
where profit is not null
group by product_name
having total_profit > 0 
order by total_profit desc;

-- Product that generates the highest profit is called 'Canon PC1060 Personal Laser Copier' 
-- Company should consider increasing sales of this product.














