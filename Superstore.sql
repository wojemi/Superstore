use superstore; 

-- 1) Liczba klientów w podziale na segmenty
select * from rc_upload;
select 
	segment,
	count(customer_id) as count
from rc_upload 
group by segment;

-- 2) Jak zmieniała się liczba klientów miesiąc do miesiąca
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

-- 3) Jaka jest średnia różnica czasu pomiędzy złożeniem zamówienia a datą dostawy w zależności od rodzaju dostawy
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

-- 5) W której kategorii i podkategorii sprzedaż jest największa
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

-- 6) Lista podkategorii z każdej kategorii gdzie sprzedaż jest największa
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

-- 7) Korelacja pomiędzy wielkością rabatów a wielkością sprzedaży w czasie (miesięcznie)
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

-- 8) Lista klientów oraz liczba zamówień na przestrzeni czasu
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
	
-- 9) W którym kwartale 2014 roku było najwięcej zamówień?
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

-- 10) W których stanach (wskaż 5) jest najwyższa sprzedaż w podziale na produkty z kategorii 'Technology'
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

-- 11) 10 produktów, które tworzą najwyższy dochód (do której kategorii i subkategorii należą)
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

-- 12) Jak zmieniają się sprzedaż i zyski w zależności od kategorii w 2014 roku
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

-- 13) Wartość skumulowana sprzedaży miesiąc do miesiąca od 2014 roku do końca 2017
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
		sum(total_sales) over(order by order_date) as cumulated_value
	from first_step
)
select * from second_step 
order by 1;




















