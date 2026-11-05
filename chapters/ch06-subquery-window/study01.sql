use hanip_delivery06;

#일반적인 표의 형태
select menu_id,
       name as menu_name
from menus;

select *
from (select menu_id, name as menu_name from menus) m
where menu_name like '%국밥';


#목록
select menu_id
from menus;

select *
from order_items
where menu_id in (select menu_id from menus where menus.menu_id mod 2 = 0);

#스칼라 쿼리
select *
from menus;

select menu_id,
       name,
       (select name from restaurants where restaurants.restaurant_id = menus.restaurant_id)
from menus
where restaurant_id = (select restaurant_id from restaurants where name = '장전동든든김밥');

#null이 포함된 걸 서브쿼리에 사용했을 떄
select rider_id
from orders
where ordered_at > '2026-06-30';

select *
from riders
where rider_id not in (select rider_id
                       from orders
                       where ordered_at > '2026-06-30'
                         and orders.rider_id is not null);

#경로, 데이터베이스가 있는지 없는지
select rd.name,
       rd.rider_id
from riders rd
where not exists(select 1
                 from orders o
                 where o.rider_id = rd.rider_id
                   and o.ordered_at >= '2026-06-30');

with ap_cte as (
    select
        od.restaurant_id,
        date_format(ordered_at, '%Y-%m') as order_month,
        round(avg(quantity * unit_price), 0) as avg_price
    from
        orders od
         left outer join order_items oi on oi.order_id = od.order_id
    group by
        od.restaurant_id,
        date_format(ordered_at, '%Y-%m')
    order by restaurant_id, order_month
)

select
    *
from
    restaurants rt
left join ap_cte ap on ap.restaurant_id = rt.restaurant_id;

with day_of_week_kor as (select 1 as day_id, '일' as kor_name
union all
select 2, '월'
union all
select 3, '화'
union all
select 4, '수'
union all
select 5, '목'
union all
select 6, '금'
union all
select 7, '토')

select
    order_id,
    ordered_at,
    dowk.kor_name
from orders od
    left outer join day_of_week_kor dowk on dowk.day_id = dayofweek(od.ordered_at);

#카테고리 별로 판매 총 수량이 높은 가게순위
select * from restaurants;
select * from order_items;
select * from menus;

#Nullif(a.b) -> a가 null이면 B반환, a가 널이 아니면 a반환
select rs.category,
       RANK() over (partition by category order by sum(quantity*price) desc) as restaurant_rank,
       rs.restaurant_id,
       rs.name,
       ifnull(sum(oi.quantity), 0) as total_quantity
from menus ms
         left outer join  order_items oi on oi.menu_id = ms.menu_id
         left outer join restaurants rs on rs.restaurant_id = ms.restaurant_id
group by rs.restaurant_id, rs.category, rs.name
order by category asc;


select
    date_format(ordered_at,'%Y-%m') as order_month,
    sum(ifnull(delivery_fee, 0)) as delivery_fee_sum,
    sum(sum(ifnull(delivery_fee, 0))) over(order by date_format(ordered_at,'%Y-%m')) as cumlative_fee
from
    orders
group by date_format(ordered_at,'%Y-%m');


#문제1
select * from restaurants;
select * from menus;

select restaurant_id,
       name,
       price
from menus
where price = (select max(price) from menus);

#문제 2
select * from reviews;
select * from orders;

select
    rt.restaurant_id,
    rt.name
from orders o
    left join reviews rs on rs.order_id = o.order_id
    left join restaurants rt on rt.restaurant_id = o.restaurant_id
where exists(select 1 from reviews where o.restaurant_id = rt.restaurant_id)
group by rt.restaurant_id, rt.name;

#문제 3
select * from orders;

select o.order_id,
       max(o.ordered_at),
       cs.name,
       o.status
from orders o
         inner join customers cs on cs.customer_id = o.customer_id
group by o.order_id, cs.name, o.status
order by max(o.ordered_at) desc
limit 1;

#문제 5
select * from customers;
select * from orders;

select
    cs.name,
    cs.joined_at
from orders o
    left join customers cs on cs.customer_id = o.customer_id
where date(joined_at) < '2026-06-01' and
      not exists(
    select 1
    from orders o1
    where o1.customer_id = cs.customer_id
    and o.ordered_at >= '2026-06-01'
    and o.ordered_at < '2026-07-01'
)
group by cs.name, cs.name, cs.joined_at
order by joined_at;

#문제 7 : 결제금액
select * from orders;

select
    o.order_id,
    sum(quantity * unit_price) as food_amount,
    delivery_fee
from orders o
     inner join order_items oi on oi.order_id = o.order_id
where status = '배달완료'
group by o.order_id, delivery_fee
order by food_amount desc, order_id asc
limit 5;



#문제 8
select * from orders;

select
    cs.name,
    max(o.ordered_at) as last_order_date,
    timestampdiff(day, max(o.ordered_at), '2026-07-01') as day_since_last
from orders o
         join customers cs on cs.customer_id = o.customer_id
where o.ordered_at < '2026-07-01'
group by cs.customer_id, cs.name
having day_since_last > 29
order by day_since_last desc;

#문제 10

select * from restaurants;

select
    cs.name,
    min(os.ordered_at) as first_ordered_at,
    rs.name
from
    orders os
        inner join restaurants rs on rs.restaurant_id = os.restaurant_id
        inner join customers cs on cs.customer_id = os.customer_id
where os.ordered_at = (
    select min(o2.ordered_at)
    from orders o2
    where o2.customer_id = os.customer_id
)
group by rs.name, cs.name, cs.customer_id
order by cs.customer_id;


#문제 11
select
        rs.category,
        row_number() over (partition by rs.category order by os.restaurant_id desc)  as cate_gory,
        rs.name,
        sum(oi.quantity * oi.unit_price) as food_sales
    from
        orders os
        inner join restaurants rs on rs.restaurant_id = os.restaurant_id
        inner join order_items oi on oi.order_id = os.order_id
    where status = '배달완료'
    group by rs.category, rs.name, rs.restaurant_id
    order by food_sales desc ;





#문제 12
select
    date_format(od.ordered_at, '%Y-%m') as order_month,
    rt.name as restaurant_name,
    sum(oi.unit_price * oi.quantity) as food_sales
from orders od
         inner join order_items oi on oi.order_id = od.order_id
         join restaurants rt on rt.restaurant_id = od.restaurant_id
    and rt.name in ('대연동크런치치킨', '서면야식치킨')

group by date_format(od.ordered_at, '%Y-%m'), rt.name
