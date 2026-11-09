#문제1 : 카테고리 별 배송완료 주문 건수, 판매수량, 매출을 보여주세용

select *
from orders;
select *
from products;
select *
from categories;
select *
from order_items;
select *
from members;


select cs.name                          as main_category,
       count(os.order_id)               as orders,
       sum(oi.quantity)                 as quantity,
       sum(oi.quantity * oi.unit_price) as sales
from categories cs
         left join products ps on ps.category_id = cs.category_id
         left join order_items oi on oi.product_id = ps.product_id
         left join orders os on os.order_id = oi.order_id
where os.status = '배달완료'
group by cs.name;


#문제 2 : 지역별로 회원 수, 배송완료 주문이 한 번이라도 있는 회원수, 구매 전환율
#주문이 없는 화원도 회원 수에는 들어가야 함

select *
from members;
select *
from orders;

select ms.region,
       count(distinct ms.member_id)                                                as members,
       count(distinct os.member_id)                                                as buyer,
       round(count(distinct os.member_id) / count(distinct ms.member_id) * 100, 1) as conversion_rate
from members ms
         left outer join orders os on os.member_id = ms.member_id
    and status = '배송완료'
group by ms.region
order by conversion_rate desc;

#문제 3 : 리뷰로 본 브랜드 품질
select *
from reviews;
select *
from products;

select ps.brand,
       count(rs.review_id)                 as reviews,
       round(avg(rs.rating), 2)            as avg_rating,
       round(avg(rs.rating <= 2) * 100, 1) as low_rating_pct
from reviews rs
         inner join products ps on ps.product_id = rs.product_id
group by ps.brand
having reviews >= 10
order by avg_rating;

#문제 4
select *
from orders;

select date_format(ordered_at, '%Y-%m')                           as ym,
       count(case when orders.payment_method = '카드' then 1 end)   as card,
       count(case when orders.payment_method = '간편결제' then 1 end) as easy_pay,
       count(case when orders.payment_method = '계좌이체' then 1 end) as bank_transfer,
       count(*)                                                   as total
from orders
where status = '배송완료'
group by date_format(ordered_at, '%Y-%m');

#문제 6
select *
from members;
select *
from orders;

select ms.name,
       count(distinct os.order_id)                as orders,
       date_format(min(ordered_at), '%Y-%m-%d')   as first_order,
       date_format(max(ordered_at), '%Y-%m-%d')   as last_order,
       round(avg(oi.unit_price * oi.quantity), 0) as avg_amount

from members ms
         left join orders os on ms.member_id = os.member_id
         left join order_items oi on os.order_id = oi.order_id
    and os.status = '배달완료'
group by ms.name
having count(*) >= 10
order by avg_amount desc, orders desc, first_order;

#answp 10

select *
from categories;

select *
from products;

select cs.name  as category,
       ps.name  as name,
       ps.brand as brand,
       ps.price
from products ps
         join categories cs on cs.category_id = ps.category_id
where ps.price = (select max(ps1.price)
                  from products ps1
                  where ps1.category_id = ps.category_id)
order by price desc;

#answp 11
select ps.name,
       ms.name,
       ms.region,
       count(distinct os.order_id) as times
from orders os
         inner join members ms on ms.member_id = os.member_id
         inner join order_items oi on oi.order_id = os.order_id
         inner join products ps on oi.product_id = ps.product_id
where status = '배송완료'
  and ps.category_id in (11)
group by ps.name, ms.name, ms.region;

select mb.name,
       mb.member_id,
       mb.region,
       count(od.order_id) as times
from (select rank() over (order by sum(oi.quantity) desc) as rank_num,
             oi.product_id,
             pd.name                                      as product_name,
             sum(oi.quantity)                             as total_quqntity
      from orders od
               inner join order_items oi on od.order_id = oi.order_id and od.status = '배송완료'
               inner join products pd on pd.product_id = oi.product_id

      group by pd.name,
               oi.product_id) as pr
         left outer join order_items oi on oi.product_id = pr.product_id
         inner join orders od on oi.order_id = od.order_id and od.status = '배송완료'

         left outer join members mb on od.member_id = mb.member_id
where rank_num = 1
group by oi.product_id,
         mb.name,
         mb.member_id,
         mb.region;

#문제 14 : 누적 구매액과 도달 시점
select *
from members;
select *
from order_items;
select *
from orders;

select row_number() over (order by oi.order_id) as order_seq,
       oi.order_id,
       date_format(os.ordered_at, '%Y-%m-%d')   as ordered_at,
       sum(oi.quantity * oi.unit_price)         as amount
from orders os
         left join members ms on os.member_id = ms.member_id
         left join order_items oi on os.order_id = oi.order_id
where os.status = '배송완료'
  and ms.member_id = 1
group by oi.order_id, os.ordered_at;

select order_seq,
       order_id,
       ordered_at,
       amount,
       running_total,
       if(row_number() over (partition by running_total_group order by ordered_at) = 1
              and running_total_group = 1, 'VIP 달성', null) as vip_reached
from (select row_number() over (order by date(od.ordered_at))                       as order_seq,
             od.order_id,
             date(od.ordered_at)                                                    as ordered_at,
             sum((oi.quantity * unit_price) + od.shipping_fee - od.coupon_discount) as amount,
             sum(sum((oi.quantity * unit_price) + od.shipping_fee - od.coupon_discount))
                 over (order by od.order_id)                                        as running_total,
             sum(sum((oi.quantity * unit_price) + od.shipping_fee - od.coupon_discount))
                 over (order by od.order_id) >= 500000
                                                                                    as running_total_group
      from orders od
               inner join order_items oi
                          on od.order_id = oi.order_id and od.status = '배송완료'
                              and od.member_id = 1
      group by od.order_id,
               date(od.ordered_at)) result;


#핋요 : orders : status, orders_items, members, categorys
#서브쿼리 : from 절에서 가상 테이블 1개 생성
select
    pct.name,
    count(foi.member_id),
    round(count(*) / sum(count(*)) over * 100, 1) as pct
from (select od.member_id,
             min(oi.order_item_id) as first_order_item_id
      from orders od
               inner join order_items oi on od.order_id = oi.order_id and od.status = '배송완료'
      group by od.member_id) as foi
         left outer join order_items oi on oi.order_item_id = foi.first_order_item_id
         left outer join products pd on pd.product_id = oi.product_id
         left outer join categories ct on pd.category_id = ct.category_id
         left outer join categories pct on pct.category_id = ct.parent_id
group by
    pct.category_id,
    pct.name;


#Union

SELECT
    join_quarter,
    COUNT(*)               AS joined,    -- 전체 가입자 수 (현재회원 + 탈퇴회원)
    COUNT(withdrawn_at)    AS withdrawn -- 탈퇴일이 NULL이 아닌 사람만 카운트!
FROM (
         SELECT
             CONCAT(YEAR(joined_at), '-Q', QUARTER(joined_at)) AS join_quarter,
             NULL AS withdrawn_at
         FROM members

         UNION ALL

         SELECT
             CONCAT(YEAR(joined_at), '-Q', QUARTER(joined_at)) AS join_quarter,
             withdrawn_at
         FROM withdrawn_members
     ) all_members
GROUP BY
    join_quarter
ORDER BY
    join_quarter;


#문제 19

SELECT
    (SELECT COUNT(*)
     FROM (
              SELECT member_id, product_id FROM wishlists
              UNION ALL
              SELECT member_id, product_id FROM carts
          ) a) AS union_all_cnt,

    (SELECT COUNT(*)
     FROM (
              SELECT member_id, product_id FROM wishlists
              UNION
              SELECT member_id, product_id FROM carts
          ) b) AS union_cnt,

    (SELECT COUNT(*)
     FROM (
              SELECT member_id, product_id FROM wishlists
              INTERSECT
              SELECT member_id, product_id FROM carts
          ) c) AS intersect_cnt;

