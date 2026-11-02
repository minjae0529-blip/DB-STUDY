-- =============================================================
--  Ch05. JOIN — 흩어진 데이터 잇기 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery05)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery05;


-- -------------------------------------------------------------
-- 1. 왜 테이블을 나눴을까 — 다시 보는 주문 7번
-- -------------------------------------------------------------
SELECT order_id, customer_id, restaurant_id, status
FROM orders
WHERE order_id = 7;


-- -------------------------------------------------------------
-- 2. INNER JOIN — 짝이 있는 행만
-- -------------------------------------------------------------
SELECT orders.order_id,
    orders.status,
    restaurants.name
FROM orders
JOIN restaurants ON orders.restaurant_id = restaurants.restaurant_id
ORDER BY orders.order_id;


-- -------------------------------------------------------------
-- 2-1. 테이블 별칭
-- -------------------------------------------------------------
SELECT o.order_id,
    o.status,
    r.name AS restaurant_name
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
ORDER BY o.order_id;


-- -------------------------------------------------------------
-- 2-2. ⚠️ 1052 — 이름이 겹치는 열
-- -------------------------------------------------------------
-- ⚠ 에러 예제
SELECT name, price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id;

SELECT r.name AS restaurant_name,
    m.name AS menu_name,
    m.price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
ORDER BY m.menu_id;


-- -------------------------------------------------------------
-- 2-3. INNER JOIN은 짝이 없는 행을 버린다
-- -------------------------------------------------------------
SELECT COUNT(*) AS all_orders FROM orders;

SELECT COUNT(*) AS orders_with_rider
FROM orders o
JOIN riders rd ON o.rider_id = rd.rider_id;


-- -------------------------------------------------------------
-- 3-1. 주문 7번을 한 화면에
-- -------------------------------------------------------------
SELECT o.order_id,
    o.ordered_at,
    c.name AS customer_name,
    r.name AS restaurant_name,
    m.name AS menu_name,
    oi.quantity,
    oi.unit_price
FROM orders o
JOIN customers c    ON o.customer_id   = c.customer_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN menus m        ON oi.menu_id      = m.menu_id
WHERE o.order_id = 7
ORDER BY oi.order_item_id;


-- -------------------------------------------------------------
-- 3-3. USING — 열 이름이 같을 때의 축약
-- -------------------------------------------------------------
SELECT o.order_id, c.name AS customer_name
FROM orders o
JOIN customers c USING (customer_id)
ORDER BY o.order_id;


-- -------------------------------------------------------------
-- 4. JOIN과 WHERE·ORDER BY
-- -------------------------------------------------------------
SELECT o.order_id,
    o.ordered_at,
    c.name AS customer_name,
    r.name AS restaurant_name,
    o.status
FROM orders o
JOIN customers c   ON o.customer_id   = c.customer_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE r.category = '치킨'
    AND o.ordered_at >= '2026-06-27'
ORDER BY o.ordered_at;


-- -------------------------------------------------------------
-- 5-1. 모든 주문과 담당 기사
-- -------------------------------------------------------------
SELECT o.order_id,
    o.status,
    rd.name AS rider_name
FROM orders o
LEFT JOIN riders rd ON o.rider_id = rd.rider_id
WHERE o.ordered_at >= '2026-06-30'
ORDER BY o.order_id;


-- -------------------------------------------------------------
-- 5-2. 짝이 없는 행 찾기 — LEFT JOIN + IS NULL
-- -------------------------------------------------------------
SELECT c.customer_id,
    c.name,
    c.joined_at
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

SELECT r.name, r.opened_at
FROM restaurants r
LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
WHERE o.order_id IS NULL;


-- -------------------------------------------------------------
-- 6. ⚠️ LEFT JOIN에서 ON과 WHERE는 다르다
-- -------------------------------------------------------------
SELECT c.name,
    COUNT(o.order_id) AS canceled
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = '취소'
GROUP BY c.customer_id, c.name
ORDER BY canceled, c.customer_id;

SELECT c.name,
    COUNT(o.order_id) AS canceled
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.status = '취소'
GROUP BY c.customer_id, c.name
ORDER BY canceled, c.customer_id;

SELECT COUNT(*) AS customers_total,
    SUM(CASE WHEN canceled = 0 THEN 1 ELSE 0 END) AS never_canceled
FROM (
    SELECT c.customer_id, COUNT(o.order_id) AS canceled
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = '취소'
    GROUP BY c.customer_id
) t;


-- -------------------------------------------------------------
-- 7-1. 가게 이름으로 매출 순위
-- -------------------------------------------------------------
SELECT r.name AS restaurant_name,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity * oi.unit_price) AS food_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY food_sales DESC;


-- -------------------------------------------------------------
-- 7-2. ⚠️ fan-out — JOIN하면 행이 불어난다
-- -------------------------------------------------------------
SELECT COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.delivery_fee) AS fee_sum_wrong
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료';

SELECT COUNT(*) AS orders,
    SUM(delivery_fee) AS fee_sum_right
FROM orders
WHERE status = '배달완료';


-- -------------------------------------------------------------
-- 8-1. SELF JOIN — 같은 테이블끼리
-- -------------------------------------------------------------
SELECT a.name AS customer_a,
    b.name AS customer_b,
    a.district
FROM customers a
JOIN customers b
    ON a.district = b.district
    AND a.customer_id < b.customer_id
WHERE a.district = '금정구'
ORDER BY a.customer_id, b.customer_id;


-- -------------------------------------------------------------
-- 8-2. CROSS JOIN — 모든 조합
-- -------------------------------------------------------------
SELECT COUNT(*) AS combinations
FROM restaurants r
CROSS JOIN riders rd;


-- -------------------------------------------------------------
-- ② 월별 음식 매출
-- -------------------------------------------------------------
SELECT DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity * oi.unit_price) AS food_sales,
    ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id)) AS avg_food_per_order
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
GROUP BY order_month
ORDER BY order_month;

