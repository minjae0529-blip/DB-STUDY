select *
from customers;

select *
from menus;

select count(*)   as menu_count,
       min(price) as min_price,
       max(price) as max_price,
       sum(price) as price_sum,
       avg(price) as avg_price
from menus;


select count(*)                    as customers,
       count(customers.email)      as with_email,
       count(customers.birth_date) as with_brith,
       count(distinct customers.district)
from customers;


SELECT COUNT(*)                     AS orders,
       SUM(delivery_fee)            AS fee_sum,
       IFNULL(SUM(delivery_fee), 0) AS fee_sum_safe
FROM orders
WHERE restaurant_id = 15;

select *
from restaurants;

# 단순 중복제거용
select distinct restaurants.category,
                district
from restaurants
order by category;

# 집계함수를 사용해야한다면, Group by
select category,
       district
from restaurants
group by category,
         district
order by category;

select category,
       count(*)          as restaurants_count,
       max(delivery_fee) as max_delivery_fee
from restaurants
group by category
order by restaurants_count desc, category;

select status,
       count(*) as 배달상태
from orders
group by status;

select date_format(ordered_at, '%Y-%m') as order_month,
       count(*)                         as order_count
from orders
group by date_format(ordered_at, '%Y-%m')
order by date_format(ordered_at, '%Y-%m');

select hour(orders.ordered_at) as order_hour,
       count(*)                as order_count
from orders
group by hour(orders.ordered_at)
order by order_count desc
limit 6;

select category,
       count(*)                         as cnt,
       group_concat(name separator ',') as name
from restaurants
group by category;

select restaurant_id,
       sum(price)
from menus
group by restaurant_id
having sum(price) > 50000;

select restaurant_id,
       count(*) as 주문건수
from orders
where status = '배달완료'
group by restaurant_id
having count(*) > 50;

select *
from order_items;

select order_id,
       count(*)                                           as item_lines,
       sum(order_items.quantity)                          as total_q,
       sum(order_items.quantity * order_items.unit_price) as food_amount
from order_items
group by order_id
order by food_amount desc, order_id;


select ifnull(payment_method, '합계') as payment_method,
       count(*)                     as delivery_orders,
       sum(orders.delivery_fee)     as fee_sum
from orders
where status = '배달완료'
group by payment_method
with rollup
order by payment_method;

select *
from (select payment_method,
             count(*)                 as delivery_orders,
             sum(orders.delivery_fee) as fee_sum
      from orders
      where status = '배달완료'
      group by payment_method
      order by fee_sum) as group_orders

union all

select '합계',
       count(*)          as delivery_orders,
       sum(delivery_fee) as fee_sum
from orders
where status = '배달완료';


select *
from menus;

#문제 1번
select count(menu_id)    as menu_count,
       min(price)        as min_price,
       max(price)        as max_prcie,
       floor(avg(price)) as avg_price
from menus;

#문제 2번
select category,
       count(restaurant_id) as restaurant_count
from restaurants
group by category
order by count(restaurant_id) desc, category;

#문제 3번
select rating,
       count(rating)                                      as review_count,
       count(case when content is null then 1 else 0 end) as rating_only,
       count(if(content is null, 1, null))                as rating_only2
from reviews
group by rating;

select *
from reviews;

#문제4번
select round(avg(rating), 2)          as avg_rating,
       count(*)                       as review_content,
       round(count(*) / 511 * 100, 1) as review_rate
from reviews;

#문제 5번
select *
from customers;

select grade,
       count(*)                                 as members,
       count(if(marketing_agreed = 1, 1, null)) as marketing_agreed,
       count(email)                             as email_count
from customers
group by grade
order by grade;

#문제 6번
select *
from orders;

select payment_method,
       count(if(status = '배달완료', 1, null))     as delivered_orders,
       round(avg(discount_amount), 0)          as avg_discount,
       count(if(discount_amount = 0, null, 1)) as discounted_orders
from orders
where status = '배달완료'
group by payment_method
order by delivered_orders desc;

#문제 7번
select *
from orders;

select hour(ordered_at) as order_hour,
       count(*)         as delivery_orders
from orders
where status = '배달완료'
group by hour(ordered_at)
order by delivery_orders desc
limit 5;

#문제 8번
select *
from orders;

select customer_id,
       count(*)                                 as order_count,
       date_format(min(ordered_at), '%Y-%m-%d') as fisrt_order,
       date_format(max(ordered_at), '%Y-%m-%d') as last_order
from orders
where status = '배달완료'
group by customer_id
having count(*) >= 30
order by order_count desc, customer_id asc
limit 5;

select *
from order_items;

#문제 9번
select order_id,
       sum(quantity * unit_price) as food_amount
from order_items
group by order_id
order by food_amount desc, order_id
limit 5;

#문제 10번
select unit_price,
       sum(quantity) as sold_quantity,
       sum(quantity * unit_price ) as sale_amount
from order_items
where menu_id = 1
group by unit_price;

#문제 11
select * from orders;

select
    rider_id,
    count(delivered_at) as deliveries,
    round(avg(timestampdiff(MINUTE , ordered_at, delivered_at)), 1) as avg_minute,
    count(case when timestampdiff(MINUTE , ordered_at, delivered_at) > 60 then 1 end) as late_count,
    round(count(case when timestampdiff(MINUTE , ordered_at, delivered_at) > 60 then 1 end) / count(*) * 100, 1) as late_rate
from orders
where status = '배달완료'
group by rider_id
order by deliveries desc;

#문제 12
select * from orders;

select
    date_format(ordered_at, '%Y-%m') as order_month,
    count(case when payment_method = '카드' then 1 end) as card,
    count(case when payment_method = '간편결제' then 1 end) as easy_pay,
    count(case when payment_method = '계좌이체' then 1 end) as transfer,
    count(case when payment_method = '현장결제' then 1 end) as on_site,
    count(*) as total

from orders
where status = '배달완료'
group by date_format(ordered_at, '%Y-%m');