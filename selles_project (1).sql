# Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:
#1. Data type of all columns in the customers table.
#2. Get the time range between which the orders were placed. 
select *
from `SQL_TARGET.customers`
limit 10;

select * 
from `SQL_TARGET.geolocation` 
limit 5;

#  Get the time range between which the orders were placed.

select  
min(order_purchase_timestamp) as start_time,
max(order_purchase_timestamp) as end_time
from `SQL_TARGET.orders`;

# Display count the cities and states of customer who ordered during the given time

select
c.customer_city , c.customer_state
from `SQL_TARGET.orders` as o
join `SQL_TARGET.customers` as c
on o.customer_id = c.customer_id
where extract(YEAR FROM o.order_purchase_timestamp) = 2018
and extract(month from o.order_purchase_timestamp) between 1 and 3;

# is there a growing trend in the no. of orders placed over the past years?

 select
 extract(month from order_purchase_timestamp) as month,
 count(order_id) as order_num
 from `SQL_TARGET.orders`
 group by extract(month from order_purchase_timestamp) 
 order by order_num desc;

 # during what time of the day , do the brazilian customers mostaly place their orders? (Dawn, Morning,Afternoon or Night)
 # 0-6 hrs: Dawn
 # 7-12 hrs: Morning
 # 13-18 hrs: Afternoon
 # 19-23 hrs: Night

 select
 extract(hour from order_purchase_timestamp) as time,
 count(order_id) as order_num
 from `SQL_TARGET.orders`
 group by extract(hour from order_purchase_timestamp) 
 order by order_num desc;

 # get month on month number of orders

 select 
 extract(month from order_purchase_timestamp) as month,
 extract(year from order_purchase_timestamp) as year,
 count(*) as num_orders
 from `SQL_TARGET.orders`
 group by year,month
 order by year,month;

 SELECT 
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    COUNT(*) OVER(PARTITION BY EXTRACT(MONTH FROM order_purchase_timestamp)) AS orders_per_month,
    COUNT(*) OVER(PARTITION BY EXTRACT(YEAR FROM order_purchase_timestamp)) AS orders_per_year
FROM `SQL_TARGET.orders`
ORDER BY year, month;

# how are the customers distributed across all the states?

select customer_state,customer_city,
count(distinct customer_id) as customer_count
from `SQL_TARGET.customers`
group by customer_state,customer_city
order by customer_count;

SELECT 
    customer_state,
    COUNT(DISTINCT customer_id) OVER(PARTITION BY customer_state) AS customer_count
FROM `SQL_TARGET.customers`
ORDER BY customer_count;

SELECT DISTINCT
    customer_state,
    customer_city,
    COUNT(DISTINCT customer_id) OVER(PARTITION BY customer_state, customer_city) AS customer_count
FROM `SQL_TARGET.customers`
ORDER BY customer_count;

# get the % increase in the cost of orders from year 2017 to 2018 (include months between jan to aug only)
# you can use the "pyment_value" column n the payments table to get the cost of orders.


# STEP 1: CALCULATE Total payments per year

SELECT DISTINCT
  EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
  SUM(p.payment_value) OVER (PARTITION BY EXTRACT(YEAR FROM o.order_purchase_timestamp)) AS total_payment
FROM `SQL_TARGET.payments` AS p
JOIN `SQL_TARGET.orders` AS o
  ON p.order_id = o.order_id;




with yearly_totals as (
select 
extract (year from o.order_purchase_timestamp) as year,
sum(p.payment_value) as total_payment
from `SQL_TARGET.payments`as p
join SQL_TARGET.orders as o
on p.order_id = o.order_id
where extract (year from o.order_purchase_timestamp) in (2017,2018)
and extract (month from o.order_purchase_timestamp) between 1 and 8
group by extract (year from o.order_purchase_timestamp)
),

# STEP 2: Use LEAD window function to compare each year's payments with the previous year

yearly_comparisons as (
select
year,total_payment,
lead(total_payment) over (order by year desc) as prev_year_payment
from yearly_totals
)

# STEP 3: Calculate % increase

select 
((total_payment - prev_year_payment) / prev_year_payment)*100
from yearly_comparisons;



# mean & sum of price and fright value by customer

select
c.customer_state,
avg(price) as avg_price,
sum(price) as sum_price,
avg(freight_value) as avg_freight,
sum(freight_value) as sum_freight
from `SQL_TARGET.orders` as o
join `SQL_TARGET.order_items` as oi
on o.order_id = oi.order_id
join `SQL_TARGET.customers` as c
on o.customer_id = c.customer_id
group by c.customer_state;

# calculate days between purchasing,delivering and estimated delivery.

select 
order_id,
date_diff(date(order_delivered_customer_date), date(order_purchase_timestamp), day) as days_to_delivery,
date_diff(date(order_delivered_customer_date), date(order_estimated_delivery_date), day) as diff_estimated_delivery
from `SQL_TARGET.orders`;

# find out the top 5 states with the highest and lowest average freight value.

select 
c.customer_state,
avg(freight_value) as avg_freight_value
from `SQL_TARGET.orders` as o 
join `SQL_TARGET.order_items` as oi 
on o.order_id = oi.order_id
join `SQL_TARGET.customers` as c
on o.customer_id = c.customer_id 
group by customer_state
order by avg_freight_value desc
limit 5;

# find out the top 5 states with the highest & lowest average delivery time.

select
c.customer_state,
avg(extract(date from o.order_delivered_customer_date) - extract(date from o.order_purchase_timestamp)) as avg_time_to_delivery
from `SQL_TARGET.orders` as o
join `SQL_TARGET.order_items` as oi
on o.order_id = oi.order_id
join `SQL_TARGET.customers` as c
on o.customer_id = c.customer_id
group by customer_state
order by avg_time_to_delivery desc # this is lowest and for highest desc change to asc
limit 5;


# find the month on month no. of orders placed using different payment types.

select
payment_type,
extract(year from order_purchase_timestamp) as year,
extract(month from order_purchase_timestamp) as month,
count(distinct o.order_id) as order_count
from `SQL_TARGET.orders` as o
inner join `SQL_TARGET.payments` as p
on o.order_id = p.order_id
group by payment_type,year,month
order by payment_type,year,month;

# count of order based on the number of payment installments

select
payment_installments,
count(distinct order_id) as num_orders
from `SQL_TARGET.payments` 
group by payment_installments;

















