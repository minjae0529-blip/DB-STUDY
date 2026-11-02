select * from customers;

select * from menus;

select
    count(*) as menu_count,
    min(price) as min_price,
    max(price) as max_price,
    sum(price) as price_sum,
    avg(price) as avg_price
from
    menus;


select
    count(*) as customers,
    count(customers.email) as with_email,
    count(customers.birth_date) as with_brith,
    count(distinct customers.district)
from customers;


SELECT
    COUNT(*) AS orders,
    SUM(delivery_fee) AS fee_sum,
    IFNULL(SUM(delivery_fee), 0) AS fee_sum_safe
FROM orders
WHERE restaurant_id = 15;

select * from restaurants;

# 단순 중복제거용
select
    distinct
    restaurants.category,
    district
from restaurants
order by
    category;

# 집계함수를 사용해야한다면, Group by
select
    category,
    district
from restaurants
group by
    category,
    district
order by
    category;

select category,
       count(*) as restaurants_count,
       max(delivery_fee) as max_delivery_fee
from restaurants
group by category
order by restaurants_count desc, category;

select
    status,
    count(*) as 배달상태
from orders
group by status;

