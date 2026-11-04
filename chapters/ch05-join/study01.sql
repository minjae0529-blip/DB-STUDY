select *
from restaurants;
select *
from orders;

select *
from orders,
     restaurants
where orders.restaurant_id = restaurants.restaurant_id
order by orders.order_id;

select *
from orders
         inner join restaurants on orders.restaurant_id = restaurants.restaurant_id
order by orders.order_id;

select *
from orders o
         left join order_items oi on oi.order_id = o.order_id
         left join menus m on m.menu_id = oi.menu_id
         left join reviews rb on rb.order_id = o.order_id
         left join customers c on c.customer_id = o.customer_id
         left join restaurants rt on rt.restaurant_id = o.restaurant_id
         left join riders rd on rd.rider_id = o.rider_id
where c.name = '윤지아';


select count(*)
from orders o
         left outer join reviews rv on rv.order_id = o.order_id
where rv.review_id is null;

select orders.order_id, orders.status
from orders
where ordered_at >= '2026-06-30';

select o.order_id,
       o.status,
       rd.name as rider_name
from orders o
         LEFT outer join riders rd on rd.rider_id = o.rider_id
where o.ordered_at >= '2026-06-30'
order by o.order_id;

select o.restaurant_id,
       rt.name,
       count(distinct o.order_id),
       sum(oi.quantity * oi.unit_price)
from orders o
         inner join restaurants rt on rt.restaurant_id = o.restaurant_id
         inner join order_items oi on oi.order_id = o.order_id
group by o.restaurant_id,
         rt.name;

#문제1번
select r.name,
       m.name,
       m.price
from menus m
         LEFT OUTER JOIN restaurants r on r.restaurant_id = m.restaurant_id
where r.name like '%치킨'
order by m.restaurant_id asc, m.price desc;

#문제2번
select *
from riders;
select *
from orders;

select rs.name,
       rs.vehicle,
       count(o.rider_id)
from riders rs
         left join orders o on o.rider_id = rs.rider_id
group by rs.name, rs.vehicle
order by `count(o.rider_id)` desc;

#문제3번
select *
from reviews;
select *
from orders;
select *
from customers;


select
    rv.review_id,
    rv.rating,
    rs.name as restaurant_name,
    cs.name as customer_name,
    rv.content
from orders os
         join reviews rv on rv.order_id = os.order_id
         join restaurants rs on rs.restaurant_id =os.restaurant_id
         join customers cs on cs.customer_id = os.customer_id
where rating <= 2
order by rv.review_id desc;

#문제 4번
select * from orders;
select * from restaurants;
select * from riders;
select * from customers;
select * from reviews;

select
    o.order_id,
    o.status,
    cs.name,
    rs.name,
    r.name
from orders o
    join restaurants rs on rs.restaurant_id = o.restaurant_id
    join customers cs on cs.customer_id = o.customer_id
    left join riders r on r.rider_id = o.rider_id
where ordered_at <= '2026-06-30 19:00' and o.status not in ('배달완료', '취소');

#문제 5번
select
    rs.name,
    round(avg(rv.rating),2),
    count(*) as review_count
from orders os
    join restaurants rs on rs.restaurant_id = os.restaurant_id
    join reviews rv on rv.order_id = os.order_id
group by rs.name, rs.restaurant_id
having count(*) >= 10
order by `round(avg(rv.rating),2)` desc;

#문제 6번
select * from menus;
select * from restaurants;
select * from order_items;
select * from orders;

#문제 6 (다시 풀어보기)
select
    rs.name,
    m.name,
    sum(oi.quantity) as sold_quantity
from menus m
    join restaurants rs on rs.restaurant_id = m.restaurant_id
    join order_items oi on oi.menu_id = m.menu_id
    join orders o on o.order_id = oi.order_id
where o.status = '배달완료'
  and o.ordered_at >= '2026-01-01'
  and o.ordered_at <  '2026-07-01'
group by rs.name, m.name
order by sold_quantity desc
limit 5;


#문제 7
select * from menus;
select * from restaurants;
select * from order_items;
select * from orders;

select
    rs.category,
    count(distinct oi.order_id),
    sum(oi.quantity * oi.unit_price) as food_sales
from orders o
    join restaurants rs on rs.restaurant_id = o.restaurant_id
    join order_items oi on oi.order_id = o.order_id
where status = '배달완료'
group by rs.category
order by  food_sales desc;

#문제 8
select * from menus;
select * from order_items;
select * from orders;

select
    ms.menu_id,
    ms.name,
    rs.name
from menus ms
    join restaurants rs on rs.restaurant_id = ms.restaurant_id
    left join order_items oi on oi.menu_id = ms.menu_id
where oi.menu_id is null
order by menu_id asc;

#문제 9
select * from customers;
select * from orders;

select
    cs.name,
    cs.grade,
    count(os.order_id) as delivered_orders
from customers cs
         left join orders os
                   on os.customer_id = cs.customer_id
                       and os.status = '배달완료'
group by cs.customer_id, cs.name, cs.grade
order by delivered_orders, cs.name asc;

#문제 10번
select * from riders;
select * from orders;

select o.ordered_at
from orders  o
    inner join riders rs on rs.rider_id = o.rider_id
where name = '민경수';

select
    ri.name,
    ri.hired_at,
    count(*),
    max(delivered_at) as last_delivered_at
from riders ri
    inner join orders os on os.rider_id = ri.rider_id
    and is_active = 0
group by ri.name, hired_at;

#문제 11
select * from menus;
select * from orders;
select * from order_items;

#왼쪽에 최대한 많이 나오게 기준을 잡아야 함], left outer 한다는 기준 하
select
    ms.name,
    oi.unit_price,
    ms.price as current_price,
    sum(oi.quantity)
from
    menus ms
        join order_items oi on oi.menu_id = ms.menu_id
        join orders os on os.order_id = oi.order_id

where
    status = '배달완료' and oi.unit_price != ms.price
group by
    ms.name, oi.unit_price, ms.price, ms.menu_id
order by
    `sum(oi.quantity)` desc;

