create view v_names as
select
    distinct
    od.order_id,
    ct.customer_id,
    ct.name,
    od.restaurant_id,
    rt.name,
    rd.rider_id,
    rd.name
from
    orders od
    left outer join  order_items oi on od.order_id = oi.order_id
    left outer join customers ct on od.customer_id = ct.customer_id
    left outer join restaurants rt on od.restaurant_id = rt.restaurant_id
    left outer join riders rd on od.rider_id = rd.rider_id;

create view v_names as
select
    od.order_id,
    ct.customer_id,
    ct.name as customer_name,
    rt.restaurant_id,
    rt.name as restaurant_name,
    rd.rider_id,
    rd.name as rider_name
from orders od
         join customers ct   on ct.customer_id = od.customer_id
         join restaurants rt on rt.restaurant_id = od.restaurant_id
         left join riders rd on rd.rider_id = od.rider_id;

select * from v_names;
show create view v_names;

explain select * from restaurants where name like '%버거%'; #like쓰면 무조건 행 검사 해야 함, 와이들카드 제거하면 다름
create index idx_restaurant_name on restaurants(name); #데이터가 삽입, 삭제되면 다시 인덱스를 정리해야

explain
select
    *
from
    orders
where restaurant_id =10;

create index idx_ordered_at on orders(ordered_at);
SET @@explain_format = TRADITIONAL;
explain
select
    *
from
    orders
where ordered_at = '2026-01-02 12:48:43';

#계정 생성
create user '@user1'@'localhost' identified by '1q2w3e4r!'; # 로컬 호스트일 때만 접근 가능

#문자열 안에는 * 안쓰고 % 씀
create user 'user1'@'%' identified by '1q2w3e4r!'; #외부에서 접근 가능

grant select, insert on `hanip_delivery10`.customers to 'user1'@'%'; #hanip_delivery10에 있는 모든 테이블 조회 기능 권한 부여 user1하넽

select  * from mysql.user;

select * from customers;
insert into customers
values (null, '강민재', '010-1234-5678', 'test@gmail.com', '2001-05-29', '대연동', '베르디하우스', 'vip', 1, now())

show grants  for 'user1'@'%';

revoke select on `hanip_delivery10`.* from 'user1'@'%';
revoke insert on `hanip_delivery10`.customers from 'user1'@'%';

