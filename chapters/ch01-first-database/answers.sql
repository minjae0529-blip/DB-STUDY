-- Ch01 실습 — 처음 보는 DB 파악하기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery01)
USE hanip_delivery01;

-- 문제 1. 테이블 목록 ★
SHOW TABLES;

-- 문제 2. 고객 테이블 구조 ★
DESC customers;

-- 문제 3. 메뉴 미리보기 ★
SELECT * FROM menus LIMIT 5;

-- 문제 4. 배달 기사 명단 ★
SELECT name, vehicle, district, is_active FROM riders;

-- 문제 5. 주문 상세는 몇 줄일까 ★★
SELECT COUNT(*) FROM order_items;

-- 문제 6. 에러 고치기 ① ★★
SELECT name, phone, grade FROM customers LIMIT 3;

-- 문제 7. 에러 고치기 ② ★★
SELECT name, price FROM menus LIMIT 3;
