-- Ch10 실습 — 저장하고, 빠르게, 안전하게 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery10)
USE hanip_delivery10;

-- 문제 1. 가게 평점 뷰 ★
CREATE VIEW v_restaurant_ratings AS
SELECT r.restaurant_id, r.name AS restaurant_name,
    COUNT(*) AS review_count, ROUND(AVG(rv.rating), 2) AS avg_rating
FROM reviews rv
JOIN orders o      ON rv.order_id     = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name;

SELECT restaurant_name, review_count, avg_rating
FROM v_restaurant_ratings
ORDER BY avg_rating DESC, review_count DESC
LIMIT 3;

-- 문제 2. 기사 공개 뷰 ★
CREATE VIEW v_riders_public AS
SELECT rider_id, CONCAT(LEFT(name, 1), '*', RIGHT(name, 1)) AS name_masked,
    vehicle, district, is_active
FROM riders;

SELECT * FROM v_riders_public ORDER BY rider_id;

-- 문제 3. 뷰 위에 쿼리 쌓기 ★★
CREATE VIEW v_order_amounts AS
SELECT o.order_id, o.ordered_at, o.customer_id, o.restaurant_id, o.status,
    SUM(oi.quantity * oi.unit_price) AS food_amount,
    o.delivery_fee, o.discount_amount,
    SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS total_amount
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;

SELECT c.name AS customer_name, COUNT(*) AS orders, SUM(a.total_amount) AS total_paid
FROM v_order_amounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE a.status = '배달완료'
  AND a.ordered_at >= '2026-06-01' AND a.ordered_at < '2026-07-01'
GROUP BY c.customer_id, c.name
ORDER BY total_paid DESC
LIMIT 5;

-- 문제 4. 조건을 지키는 뷰 ★★
CREATE VIEW v_menus_on_sale AS
SELECT menu_id, restaurant_id, name, price, is_sold_out
FROM menus
WHERE is_sold_out = FALSE
WITH CHECK OPTION;

UPDATE v_menus_on_sale SET price = 4500 WHERE menu_id = 51;

SELECT menu_id, name, price, is_sold_out
FROM menus
WHERE menu_id = 51;

-- 문제 5. 이미 있는 인덱스 ★
SELECT index_name AS index_name, column_name AS column_name,
    seq_in_index AS seq_in_index, non_unique AS non_unique
FROM information_schema.statistics
WHERE table_schema = DATABASE() AND table_name = 'order_items'
ORDER BY index_name, seq_in_index;

-- 문제 6. EXPLAIN 전후 비교 ★★
EXPLAIN
SELECT review_id, rating, created_at FROM reviews WHERE created_at >= '2026-06-01';

CREATE INDEX idx_reviews_created_at ON reviews (created_at);

EXPLAIN
SELECT review_id, rating, created_at FROM reviews WHERE created_at >= '2026-06-01';

-- 문제 7. 인덱스를 살리는 쿼리 ★★
EXPLAIN
SELECT review_id, rating, created_at FROM reviews
WHERE created_at >= '2026-06-01' AND created_at < '2026-07-01';

-- 문제 8. 정렬까지 인덱스로 ★★★
CREATE INDEX idx_orders_customer_date ON orders (customer_id, ordered_at);

EXPLAIN
SELECT order_id, status, ordered_at FROM orders
WHERE customer_id = 1 ORDER BY ordered_at DESC LIMIT 5;

-- 문제 9. 읽기 전용 분석가 계정 ★★
DROP USER IF EXISTS 'hanip_analyst'@'localhost';
CREATE USER 'hanip_analyst'@'localhost' IDENTIFIED BY 'Analyst!2026';
GRANT SELECT ON hanip_delivery10.* TO 'hanip_analyst'@'localhost';

SHOW GRANTS FOR 'hanip_analyst'@'localhost';

-- 문제 10. CS 상담원 역할 ★★★
DROP USER IF EXISTS 'hanip_cs01'@'localhost';
DROP ROLE IF EXISTS 'hanip_cs';

CREATE ROLE 'hanip_cs';
GRANT SELECT, UPDATE (status) ON hanip_delivery10.orders TO 'hanip_cs';
GRANT SELECT ON hanip_delivery10.v_riders_public TO 'hanip_cs';

CREATE USER 'hanip_cs01'@'localhost' IDENTIFIED BY 'Cs01!2026';
GRANT 'hanip_cs' TO 'hanip_cs01'@'localhost';
SET DEFAULT ROLE 'hanip_cs' TO 'hanip_cs01'@'localhost';

SHOW GRANTS FOR 'hanip_cs01'@'localhost' USING 'hanip_cs';
