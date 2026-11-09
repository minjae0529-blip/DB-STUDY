select *
from riders;

insert into riders (rider_id, name, phone, vehicle, district, hired_at, is_active)
values (default, '강민재', '010-7303-5153', '오토바이', '부산 진구', curdate(), 1);


create table rider_settlements
(
    settlement_id     int            not null auto_increment,
    rider_id          int            not null,
    settle_month      char(7)        not null,
    delivery_count    int            not null,
    settlement_amount decimal(12, 0) not null,
    is_paid           tinyint(1)     not null default 0,
    paid_at           datetime       null,

    constraint pk_rider_settlements primary key (settlement_id),
    constraint fk_settle_rider foreign key (rider_id) references riders (rider_id),
    constraint uq_settle_rider_month unique (rider_id, settle_month),
    constraint ck_settle_month check (settle_month regexp '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    constraint ck_settle_count check (delivery_count >= 0),
    constraint ck_settle_amount check (settlement_amount >= 0),
    constraint ck_settle_paid check (
        (is_paid = 1 and paid_at is not null)
            or (is_paid = 0 and paid_at is null)
        )
);

select *
from rider_settlements;
select *
from orders;
select *
from riders;

select rid.rider_id,
       rid.name,
       sum(os.delivery_fee),
       count(os.rider_id)
from orders os
         left join rider_settlements rs on rs.rider_id = os.rider_id
         left join riders rid on rid.rider_id = os.rider_id
where os.rider_id is not null
group by rid.rider_id, rid.name
order by rid.rider_id;

#조회한 결과를 바로 결과 삽입 해주는 행위(insert select) , 단 데이터타입, 컬럼 다 맞춰줘야 함

insert into rider_settlements
(rider_id, settle_month, delivery_count, settlement_amount, is_paid, paid_at)
select os.rider_id,
       date_format(os.delivered_at, '%Y-%m'),
       count(*),
       sum(os.delivery_fee),
       0,
       null
from orders os
where os.delivered_at is not null
  and os.rider_id is not null
group by os.rider_id, date_format(os.delivered_at, '%Y-%m');

select rider_id, is_paid, paid_at
from rider_settlements
group by rider_id, is_paid, paid_at
order by rider_id;

#update에서는 select 기능이 있음
update rider_settlements rs
    join riders rd on rd.rider_id = rs.rider_id
set rs.is_paid = true,
    rs.paid_at = '2026-01-10 00:00:00'
where rs.settle_month = '2026-01'
  and rd.is_active = 1;

update riders
set is_active = 0
where rider_id in (4, 8);

select *
from riders;

select *
from rider_settlements;

select @@autocommit;
set @@autocommit = 1;

start transaction;
insert into riders
values (default, '김준일', '010-1234-5153', '오토바이', '부산 진구', curdate(), 1);

select *
from riders;

rollback;
commit;


delete
from riders
where rider_id = 9;
delete
from riders
where rider_id = 11;

#트랜잭션 시작, 오토 커밋 0인 전제
start transaction;
insert into orders(customer_id, restaurant_id, status, payment_method, delivery_fee, discount_amount, request_note,
                   orders.ordered_at)
values (1, 1, '접수', '간편결제', 2500, 5000, '문앒에 두고 벨 눌러주새요', '2026-06-30 19:05:00');

set @order_id = LAST_INSERT_ID();

insert into order_items (order_id, menu_id, quantity, unit_price)
select @order_id,
       menu_id,
       case menu_id when 1 then 2 else 1 end,
       price
from menus
where menu_id in (1, 4);

#쿠폰 사용 표시
update customer_coupons
set used_order_id = @order_id
where customer_id = 1
  and coupon_id = 3
  and used_order_id is null;

select @order_id as new_order_id, row_count() as coupon_row_updated;

drop table if exists daily_sales;
create table daily_sales
(
    sales_date date not null,
    orders     int  not null,
    food_sales int  not null
);

# insert into daily_sales (sales_date, orders, food_sales)
select date(os.ordered_at)              as sales_date,
       count(distinct os.order_id)               as orders,
       sum(oi.quantity * oi.unit_price) as food_sales
from orders os
         join order_items oi on oi.order_id = os.order_id
where os.ordered_at >= '2026-06-23'
  and os.ordered_at < '2026-07-01'
  and os.status = '배달완료'
group by date(os.ordered_at);

select * from customers;

select
    cs.name,
    cs.grade
from
    orders os
    left join customers cs on cs.customer_id = os. customer_id
where ordered_at >= '2026-06-01' and ordered_at < '2026-07-01' and grade in ('일반') and status = '배달완료'
group by os.customer_id, cs.name, cs.grade
having count(*) >= 4
order by grade;

update customers  c
       inner join orders os on os.customer_id = c.customer_id
set grade = '실버'
where ordered_at >= '2026-06-01' and ordered_at < '2026-07-01' and grade in ('일반');

rollback ;
select * from customers where grade = '실버';


select * from coupons;
start transaction;
savepoint sp1;
update coupons
set is_active = 0
where is_active = 1;

rollback ;