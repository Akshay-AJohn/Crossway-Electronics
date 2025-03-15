-- What were the order counts, sales, and AOV for Macbooks sold in NA for each quarter across all years?

with first_cte as(
SELECT date_trunc(orders.purchase_ts, quarter) as quarter,
count(distinct orders.id) as Order_count, round(sum(orders.usd_price),2) as Sales, round(avg(orders.usd_price)) as AOV
from core.orders
LEFT JOIN core.customers
on orders.customer_id = customers.id
LEFT JOIN core.geo_lookup 
on geo_lookup.country = customers.country_code
WHERE lower(orders.product_name) LIKE '%macbook%' AND region = 'NA'
group by 1
order by 1 desc
)

--What is the average quarterly order count and total sales for Macbooks sold in North America? (i.e. “For North America Macbooks, average of X units sold per quarter and Y in dollar sales per quarter”)

SELECT 
    ROUND(AVG(first_cte.Order_count), 2) AS avg_quarter_count, 
    ROUND(SUM(first_cte.Sales), 2) AS total_sales
FROM first_cte;

--2. For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 

-- Time to deliver is calculated as the difference in days between purchase time and deliver time
select geo_lookup.region, 
  avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, day)) as time_to_deliver
from core.order_status
left join core.orders
  on order_status.order_id = orders.id
left join core.customers
  on customers.id = orders.customer_id
left join core.geo_lookup
  on geo_lookup.country = customers.country_code
where (extract(year from orders.purchase_ts) = 2022 and purchase_platform = 'website')
  or purchase_platform = 'mobile app'
group by 1
order by 2 desc;

--3) What was the refund rate and refund count for each product overall? 

select case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as product_clean,
    sum(case when refund_ts is not null then 1 else 0 end) as refunds,
    avg(case when refund_ts is not null then 1 else 0 end) as refund_rate
from core.orders 
left join core.order_status 
    on orders.id = order_status.order_id
group by 1
order by 3 desc;

--4) Within each region, what is the most popular product?

with sales_by_product as (
  select region,
    case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as product_clean,
    count(distinct orders.id) as total_orders
  from core.orders
  left join core.customers
    on orders.customer_id = customers.id
  left join core.geo_lookup
    on geo_lookup.country = customers.country_code
  group by 1,2),

ranked_orders as (
  select *,
    row_number() over (partition by region order by total_orders desc) as order_ranking
  from sales_by_product
  order by 4 asc)

select *
from ranked_orders 
where order_ranking = 1;

--5) How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 

select customers.loyalty_program, 
  round(avg(date_diff(orders.purchase_ts, customers.created_on, day)),1) as days_to_purchase,
  round(avg(date_diff(orders.purchase_ts, customers.created_on, month)),1) as months_to_purchase
from core.customers
left join core.orders
  on customers.id = orders.customer_id
group by 1
