Drop table If Exists coupons_draft;
create table coupons_draft
(
    coupon_id       int,
    code            varchar(30),
    name            varchar(50),
    discount_amount int
);

select *
from coupons_draft;
show tables;

insert into coupons_draft(coupon_id, code, name, discount_amount)
values (1, 'WELCOME3000', '첫 주문 3,000원 할인', 3000),
       (1, 'WELCOME3000', null, 3000),
       (1, 'WELCOME3000', null, -3000);

create table coupons
(
    coupon_id        int         not null auto_increment,
    code             varchar(20) not null,
    name             varchar(50) not null,
    discount_type    varchar(10) not null,
    discount_value   int         not null,
    min_order_amount int         not null default 0,
    vaild_days       int         not null default 30,
    is_active        boolean     not null default true,
    create_at        datetime    not null default current_timestamp,

    constraint pk_coupons primary key (coupon_id),
    constraint uq_coupons unique (code),
    constraint ck_coupons_type check ( discount_type in ('정액', '정률') ),
    constraint ck_coupons_value check (
        (discount_type = '정액' and discount_value > 0)
            or
        (discount_type = '정률' and discount_value between 1 and 50)
        ),
    constraint ck_coupons_min check ( min_order_amount >= 0 ),
    constraint ck_coupons_day check ( vaild_days > 0 )
);

CREATE table customer_coupons
(
    customer_coupon_id int      not null auto_increment,
    customer_id        int      not null,
    coupon_id          int      not null,
    issued_at          datetime not null default current_timestamp,
    expires_at         datetime not null,
    used_order_id      int      null,

    constraint pk_customer_coupons primary key (customer_coupon_id),
    constraint fk_cc_customer foreign key (customer_id) references customers (customer_id),
    constraint fk_cc_coupon foreign key (coupon_id) references coupons (coupon_id),
    constraint fk_cc_order foreign key (used_order_id) references orders (order_id),
    constraint uq_cc_customer_coupon unique (customer_id, coupon_id),
    constraint uq_cc_used_order unique (used_order_id),
    constraint ck_cc_period check ( expires_at > issued_at )
);

#현재 사용하고 있는 스키마 조회하는 법
select database();

select COLUMN_NAME,
       DATA_TYPE
from information_schema.COLUMNS
where TABLE_SCHEMA = database()
  and TABLE_NAME = 'orders'
  and IS_NULLABLE = 'yes'
group by COLUMN_NAME, DATA_TYPE;

#CHECK 제약 조건 읽기
select CONSTRAINT_NAME
from information_schema.TABLE_CONSTRAINTS
where TABLE_SCHEMA = database()
  and TABLE_NAME = 'orders'
  and CONSTRAINT_TYPE = 'CHECK';


#문제 4 : 공지사항 테이블
create table notices
(
    notice_id int          not null auto_increment,
    title     varchar(100) not null,
    content   TEXT         not null,
    is_pinned boolean      not null default false,
    published datetime     not null default current_timestamp,

    constraint pk_notice_id primary key (notice_id)
);

show tables;
select *
from notices;

insert into notices (notice_id, title, content, is_pinned, published)
values (1, '7월 정산일 안내', '7월 정산은 10일에 진행됩니다', true, current_time);

insert into notices (notice_id, title, content, is_pinned, published)
values (2, '배달팁 정책변경 안내', '8월부터ㅏ 5만원 이상 무료배달 기준이 4만원으로 변경', false, current_time);

select notice_id,
       title,
       is_pinned
from notices;

Drop table If Exists restaurant_holidays;
create table restaurant_holidays
(
    holiday_id    int primary key auto_increment,
    restaurant_id int         not null,
    hoilday_date  datetime    not null,
    reason        varchar(50) null,

    constraint fk_restaurant_id foreign key (restaurant_id) references restaurants (restaurant_id),
    constraint uq_holidays_date unique (hoilday_date, restaurant_id)
);

select *
from restaurant_holidays;
select *
from restaurants
where name = '서면옛날돼지국밥';

insert into restaurant_holidays (restaurant_id, hoilday_date, reason)
values (1, '2025-07-15', '내부수리');

insert into restaurant_holidays (restaurant_id, hoilday_date, reason)
values (6, '2025-07-15', 'NULL');

insert into restaurant_holidays (restaurant_id, hoilday_date, reason)
values (1, '2025-07-16', '내부수리');

select date_format(rh.hoilday_date, '%Y-%m-%d') as holiday_date, rs.name, rh.reason
from restaurants rs
         left join restaurant_holidays rh on rh.restaurant_id = rs.restaurant_id
where rh.reason is not null
order by hoilday_date;

Drop table If Exists menu_options;

create table menu_options
(
    option_id         int auto_increment,
    menu_id           int         not null,
    option_name       varchar(30) not null,
    price_with_option int default 0,

    constraint pk_option_id primary key (option_id),
    constraint price_with_option check ( price_with_option >= 0 ),
    constraint fk_option_name foreign key (menu_id) references menus (menu_id) on delete cascade,
    constraint uq_option_name unique (option_name, menu_id));

#pk auto increment는 값을 넣을떄, null, default 적어주면 됨
insert into menu_options(menu_id, option_name, price_with_option)
values (35, '곱배기', 1000);

insert into menu_options(menu_id, option_name, price_with_option)
values (35, '계란 프라이', 1500);

insert into menu_options(menu_id, option_name, price_with_option)
values (35, '면추가 없음', 0);

select m.name as menu_name, option_name, (mo.price_with_option + m.price) as price_with_option
from
    menu_options mo
    inner join menus m on m.menu_id = mo.menu_id
order by price_with_option;

select ms.name                                                                                 as menu_name,
       option_name,
       case when option_name = '면추가 없음' then ms.price else mo.price_with_option + ms.price end as price_with_option

from menu_options mo
         inner join menus ms on ms.menu_id = mo.menu_id
order by price_with_option;

#문제 8 : 기사 월 정산 테이블
select * from riders;

#집가서 해보기 !!, 개별적으로 유니크 걸때는 위에 걸면 되지만, 그게 아니라면 밑에서 진행하기
create table rider_settlements(
    rider_settlement_id int not null primary key auto_increment,
    rider_id int not null

);