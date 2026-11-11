select *
from ex_rider_sheet;

create table ex_rider_sheet_2
(
    rider_id   int primary key auto_increment,
    rider_name varchar(20) not null,
    phone      varchar(20) not null,
    zone       varchar(20) not null
);

insert into ex_rider_sheet_2
values (default, '곽태호', '010-3105-2205', '해운대'),
       (default, '곽태호', '010-3105-2205', '송정'),
       (default, '노지환', '010-3105-2202', '서면'),
       (default, '노지환', '010-3105-2202', '부전');

insert into ex_rider_sheet_2
select 0,
       rider_name,
       phone,
       substring_index(substring_index(ers.zones, ', ', seq.n), ', ', -1) as zone
from ex_rider_sheet ers
         inner join (select 1 as n
                     union all
                     select 2
                     union all
                     select 3
                     union all
                     select 4
                     union all
                     select 5) seq on seq.n <= (CHAR_LENGTH(replace(ers.zones, ', ', ''))) / 2 + 1
order by ers.rider_name
;

select *
from ex_rider_sheet_2;

create table ex_riders
(
    rider_id int         not null primary key auto_increment,
    name     varchar(20) not null,
    phone    varchar(20) not null
);

create table ex_riding_zones
(
    rinding_zone_id int auto_increment primary key,
    rider_id        int not null,
    zone_id         int not null
);

create table ex_zones
(
    zone_id int primary key auto_increment,
    name    varchar(20) not null
);

#문제 : customer_phone, name -> customers
select *
from ex_coupon_sheet;

create table ex_customers
(
    customer_id int primary key auto_increment,
    name        varchar(20) not null,
    phone       varchar(20) not null
);

create table ex_coupons
(
    coupon_id   int primary key auto_increment,
    customer_id int         not null,
    coupon_code varchar(20) not null,
    used_at     date        not null
);

create table ex_customer_coupons
(
    customer_coupon_id int auto_increment primary key,
    customer_id        int      not null,
    coupon_id          int      not null,
    used_at            datetime null
);

insert into ex_customer_coupons
select null,
       ec.customer_id,
       e.coupon_id,
       ecs.used_at
from ex_coupon_sheet ecs
         left outer join ex_customers ec on ec.customer_name = ecs.customer_name
    and ec.phone = ecs.customer_phone
         left outer join ex_coupons e on e.coupon_code = ecs.coupon_code;

insert into ex_customers
select distinct null,
                customer_name,
                customer_phone
from ex_coupon_sheet;

select *
from ex_coupon_sheet;

insert into ex_coupons
select distinct null,
                coupon_code,
                coupon_name,
                discount_amount
from ex_coupon_sheet;
#=======================================================
#데이터 활용 정규화 과정
select *
from book_flat;

alter table books
    modify column publisher_id int null;

insert into publishers
select distinct null,
                출판사
from book_flat
where 출판사 is not null
order by 출판사;

insert into categorys
select distinct null, 카테고리
from book_flat
order by 카테고리;

insert into libraries
select distinct null, 도서관명, `도서관홈페이지 주소`
from book_flat;

insert into p
select bf.`형식(전자책)`,
       bf.국제표준도서번호,
       bf.도서명,
       bf.저자명,
       bf.표지주소
from book_flat bf
         left outer join publishers pb on pb.name = bf.출판사;

select *
from book_flat bf
         left outer join books bs on bs.book_id = bf.국제표준도서번호;


#=======================================================
create table books
(
    book_id      int primary key auto_increment,
    book_type    varchar(20) not null,
    isbn         varchar(20) null,
    name         varchar(50) not null,
    author_name  varchar(20) not null,
    publisher_id int         not null,
    poster_url   text        null
);

create table libraries
(
    library_id int primary key auto_increment,
    name       varchar(50) not null,
    site_url   text        null
);

create table publishers
(
    publisher_id int primary key auto_increment,
    name         varchar(50) not null
);

create table categorys
(
    category_id int primary key auto_increment,
    name        varchar(20) not null
);

create table registration_books
(
    registration_id int primary key auto_increment,
    library_id      int not null,
    book_id         int not null,
    category_id     int not null
);

select null,
       lb.library_id,
       bk.book_id,
       ct.category_id
from book_flat bf
         left outer join libraries lb on lb.name = bf.도서관명
         left outer join books bk on bk.name = bf.도서명 and ifnull(bk.author_name, '') = ifnull(bf.저자명, '')
         left outer join categorys ct on ct.name = bf.카테고리;

#교과목, 개설학과, 교과구분
select distinct
    null,
    개설학과코드
from
    subject_flat;

select distinct
    null,
    대표교원번호
from
    subject_flat;

select distinct
    null,
    교과목코드
from
    subject_flat;

drop table majors;
create table majors
(
 major_id int auto_increment primary key ,
    name varchar(50) not null
);
