-- =============================================================
--  Ch04. 집계와 그룹 — 563건을 한 장의 리포트로 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery04)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery04;


-- -------------------------------------------------------------
-- 0. 단일행 함수 vs 집계 함수
-- -------------------------------------------------------------
SELECT COUNT(*)      AS menu_count,
    MIN(price)       AS min_price,
    MAX(price)       AS max_price,
    SUM(price)       AS price_sum,
    AVG(price)       AS avg_price
FROM menus;


-- -------------------------------------------------------------
-- 1. COUNT — 세 가지 얼굴
-- -------------------------------------------------------------
SELECT COUNT(*)                 AS customers,
    COUNT(email)                AS with_email,
    COUNT(birth_date)           AS with_birth,
    COUNT(DISTINCT district)    AS districts
FROM customers;

SELECT COUNT(*)                     AS orders,
    COUNT(DISTINCT customer_id)     AS ordering_customers,
    COUNT(rider_id)                 AS rider_assigned
FROM orders;


-- -------------------------------------------------------------
-- 2-1. 집계 함수는 NULL을 건너뛴다
-- -------------------------------------------------------------
SELECT COUNT(*) AS customers,
    COUNT(birth_date) AS with_birth,
    AVG(TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30')) AS avg_age
FROM customers;

SELECT COUNT(*) AS orders,
    COUNT(delivered_at) AS delivered,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_minutes,
    MAX(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)) AS max_minutes
FROM orders;


-- -------------------------------------------------------------
-- 2-2. 대상이 0행이면?
-- -------------------------------------------------------------
SELECT COUNT(*) AS orders,
    SUM(delivery_fee) AS fee_sum,
    IFNULL(SUM(delivery_fee), 0) AS fee_sum_safe
FROM orders
WHERE restaurant_id = 15;


-- -------------------------------------------------------------
-- 2-3. 문자·날짜에도 MIN·MAX
-- -------------------------------------------------------------
SELECT MIN(ordered_at) AS first_order,
    MAX(ordered_at) AS last_order
FROM orders;

SELECT MIN(name) AS first_name,
    MAX(name) AS last_name
FROM customers;


-- -------------------------------------------------------------
-- 3. GROUP BY — 묶어서 요약하기
-- -------------------------------------------------------------
SELECT category,
    COUNT(*) AS restaurant_count
FROM restaurants
GROUP BY category
ORDER BY restaurant_count DESC, category;

SELECT status,
    COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- -------------------------------------------------------------
-- 3-1. 여러 열로 묶기
-- -------------------------------------------------------------
SELECT district,
    category,
    COUNT(*) AS restaurant_count
FROM restaurants
GROUP BY district, category
ORDER BY district, category;


-- -------------------------------------------------------------
-- 3-2. 식으로 묶기 — 월별, 시간대별
-- -------------------------------------------------------------
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_month
ORDER BY order_month;

SELECT HOUR(ordered_at) AS order_hour,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_hour
ORDER BY order_hour;


-- -------------------------------------------------------------
-- 4. ⚠️ GROUP BY의 규칙 — 1055 에러
-- -------------------------------------------------------------
-- ⚠ 에러 예제
SELECT category,
    name,
    COUNT(*) AS restaurant_count
FROM restaurants
GROUP BY category;

-- 의도 A: 묶음 안의 이름을 전부 보고 싶다 → GROUP_CONCAT
SELECT category,
    COUNT(*) AS restaurant_count,
    GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') AS restaurant_names
FROM restaurants
GROUP BY category
ORDER BY restaurant_count DESC, category;


-- -------------------------------------------------------------
-- 5. WHERE vs HAVING
-- -------------------------------------------------------------
SELECT restaurant_id,
    COUNT(*) AS delivered_count
FROM orders
WHERE status = '배달완료'          -- ② 행 조건: 배달 완료된 주문만 남기고
GROUP BY restaurant_id             -- ③ 가게별로 묶은 뒤
HAVING COUNT(*) >= 50              -- ④ 그룹 조건: 50건 이상인 가게만
ORDER BY delivered_count DESC;

-- ⚠ 에러 예제
SELECT restaurant_id, COUNT(*) AS delivered_count
FROM orders
WHERE status = '배달완료' AND COUNT(*) >= 50
GROUP BY restaurant_id;


-- -------------------------------------------------------------
-- 6. 조건부 집계 — 한 쿼리로 여러 지표
-- -------------------------------------------------------------
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = '배달완료' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled
FROM orders
GROUP BY order_month
ORDER BY order_month;

SELECT payment_method,
    COUNT(*) AS orders,
    SUM(CASE WHEN status = '배달완료' THEN delivery_fee ELSE 0 END) AS delivered_fee_sum,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled
FROM orders
GROUP BY payment_method
ORDER BY orders DESC;


-- -------------------------------------------------------------
-- 비율 계산
-- -------------------------------------------------------------
SELECT restaurant_id,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled,
    ROUND(SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) * 100 / NULLIF(COUNT(*), 0), 1) AS cancel_rate
FROM orders
GROUP BY restaurant_id
ORDER BY cancel_rate DESC, restaurant_id;


-- -------------------------------------------------------------
-- 7. 주문 상세(order_items) 집계
-- -------------------------------------------------------------
SELECT order_id,
    COUNT(*) AS item_lines,
    SUM(quantity) AS total_quantity,
    SUM(quantity * unit_price) AS food_amount
FROM order_items
GROUP BY order_id
ORDER BY food_amount DESC, order_id;

SELECT menu_id,
    SUM(quantity) AS sold_quantity,
    SUM(quantity * unit_price) AS sales_amount
FROM order_items
GROUP BY menu_id
ORDER BY sold_quantity DESC, menu_id;


-- -------------------------------------------------------------
-- 8. WITH ROLLUP — 소계와 합계
-- -------------------------------------------------------------
SELECT IFNULL(payment_method, '합계') AS payment_method,
    COUNT(*) AS delivered_orders,
    SUM(delivery_fee) AS fee_sum
FROM orders
WHERE status = '배달완료'
GROUP BY payment_method WITH ROLLUP;


-- -------------------------------------------------------------
-- 월별 운영 리포트
-- -------------------------------------------------------------
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = '배달완료' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled,
    ROUND(SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) * 100 / COUNT(*), 1) AS cancel_rate,
    SUM(CASE WHEN status = '배달완료' THEN delivery_fee ELSE 0 END) AS fee_sum,
    SUM(CASE WHEN status = '배달완료' THEN discount_amount ELSE 0 END) AS discount_sum,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_delivery_min
FROM orders
GROUP BY order_month
ORDER BY order_month;


-- -------------------------------------------------------------
-- 배달 완료 Top 5 가게
-- -------------------------------------------------------------
SELECT restaurant_id,
    COUNT(*) AS delivered_count
FROM orders
WHERE status = '배달완료'
GROUP BY restaurant_id
ORDER BY delivered_count DESC, restaurant_id
LIMIT 5;

