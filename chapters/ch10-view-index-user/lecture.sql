-- =============================================================
--  Ch10. 뷰·인덱스·사용자 관리 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery10)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery10;


-- -------------------------------------------------------------
-- 1-1. 주문 금액 뷰
-- -------------------------------------------------------------
CREATE VIEW v_order_amounts AS
SELECT o.order_id, o.ordered_at, o.customer_id, o.restaurant_id, o.status,
    SUM(oi.quantity * oi.unit_price) AS food_amount,
    o.delivery_fee, o.discount_amount,
    SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS total_amount
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;

SELECT order_id, status, food_amount, delivery_fee, discount_amount, total_amount
FROM v_order_amounts
WHERE ordered_at >= '2026-06-30'
ORDER BY order_id;


-- -------------------------------------------------------------
-- 1-2. 뷰 위에 뷰 — 가게별 월 매출 리포트
-- -------------------------------------------------------------
CREATE VIEW v_store_monthly_sales AS
SELECT DATE_FORMAT(a.ordered_at, '%Y-%m') AS sales_month,
    r.restaurant_id, r.name AS restaurant_name, r.category,
    COUNT(*) AS orders, SUM(a.total_amount) AS sales
FROM v_order_amounts a
JOIN restaurants r ON a.restaurant_id = r.restaurant_id
WHERE a.status = '배달완료'
GROUP BY DATE_FORMAT(a.ordered_at, '%Y-%m'), r.restaurant_id, r.name, r.category;

SELECT restaurant_name, category, orders, sales
FROM v_store_monthly_sales
WHERE sales_month = '2026-06'
ORDER BY sales DESC;

SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema = DATABASE()
ORDER BY table_name;


-- -------------------------------------------------------------
-- 1-3. 뷰로 데이터를 바꿀 수 있나
-- -------------------------------------------------------------
CREATE VIEW v_open_restaurants AS
SELECT restaurant_id, name, category, delivery_fee, is_open
FROM restaurants
WHERE is_open = TRUE
WITH CHECK OPTION;

UPDATE v_open_restaurants SET delivery_fee = 2500 WHERE restaurant_id = 4;

SELECT restaurant_id, name, delivery_fee FROM restaurants WHERE restaurant_id = 4;

-- ⚠ 에러 예제
UPDATE v_open_restaurants SET is_open = FALSE WHERE restaurant_id = 4;

-- ⚠ 에러 예제
UPDATE v_store_monthly_sales SET sales = 0 WHERE restaurant_id = 1;


-- -------------------------------------------------------------
-- 1-4. 보안 뷰 — 전화번호 가리기
-- -------------------------------------------------------------
CREATE VIEW v_customers_masked AS
SELECT customer_id, name, CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS phone_masked,
    district, grade, joined_at
FROM customers;

SELECT * FROM v_customers_masked ORDER BY customer_id;


-- -------------------------------------------------------------
-- 2-2. 이미 있는 인덱스
-- -------------------------------------------------------------
SELECT index_name AS index_name, column_name AS column_name,
    seq_in_index AS seq_in_index, non_unique AS non_unique
FROM information_schema.statistics
WHERE table_schema = DATABASE() AND table_name = 'orders'
ORDER BY index_name, seq_in_index;


-- -------------------------------------------------------------
-- 2-3. EXPLAIN — 실행 계획 읽기
-- -------------------------------------------------------------
EXPLAIN
SELECT order_id, customer_id, status, ordered_at
FROM orders
WHERE ordered_at >= '2026-06-30';


-- -------------------------------------------------------------
-- 2-4. CREATE INDEX
-- -------------------------------------------------------------
CREATE INDEX idx_orders_ordered_at ON orders (ordered_at);

EXPLAIN
SELECT order_id, customer_id, status, ordered_at
FROM orders
WHERE ordered_at >= '2026-06-30';


-- -------------------------------------------------------------
-- 2-5. 인덱스를 못 쓰게 만드는 쿼리
-- -------------------------------------------------------------
EXPLAIN
SELECT order_id, customer_id, status, ordered_at
FROM orders
WHERE DATE(ordered_at) = '2026-06-30';


-- -------------------------------------------------------------
-- 2-6. 복합 인덱스 — 열 순서가 중요하다
-- -------------------------------------------------------------
EXPLAIN
SELECT order_id, status, ordered_at
FROM orders
WHERE restaurant_id = 4 AND ordered_at >= '2026-06-01';

CREATE INDEX idx_orders_restaurant_date ON orders (restaurant_id, ordered_at);

EXPLAIN
SELECT order_id, status, ordered_at
FROM orders
WHERE restaurant_id = 4 AND ordered_at >= '2026-06-01';

ALTER TABLE orders ALTER INDEX idx_orders_ordered_at INVISIBLE;

EXPLAIN
SELECT order_id, status, ordered_at
FROM orders
WHERE ordered_at >= '2026-06-30';

ALTER TABLE orders ALTER INDEX idx_orders_ordered_at VISIBLE;


-- -------------------------------------------------------------
-- 3-2. CREATE USER · GRANT
-- -------------------------------------------------------------
DROP USER IF EXISTS 'hanip_intern'@'localhost';
CREATE USER 'hanip_intern'@'localhost' IDENTIFIED BY 'Intern!2026';

GRANT SELECT ON hanip_delivery10.v_store_monthly_sales TO 'hanip_intern'@'localhost';
GRANT SELECT ON hanip_delivery10.v_customers_masked    TO 'hanip_intern'@'localhost';

SHOW GRANTS FOR 'hanip_intern'@'localhost';


-- -------------------------------------------------------------
-- 3-4. REVOKE — 권한 회수
-- -------------------------------------------------------------
REVOKE SELECT ON hanip_delivery10.v_customers_masked FROM 'hanip_intern'@'localhost';

SHOW GRANTS FOR 'hanip_intern'@'localhost';


-- -------------------------------------------------------------
-- 3-5. 역할(ROLE) — 권한 묶음
-- -------------------------------------------------------------
DROP ROLE IF EXISTS 'hanip_report_reader';
CREATE ROLE 'hanip_report_reader';
GRANT SELECT ON hanip_delivery10.v_store_monthly_sales TO 'hanip_report_reader';
GRANT SELECT ON hanip_delivery10.v_customers_masked    TO 'hanip_report_reader';

GRANT 'hanip_report_reader' TO 'hanip_intern'@'localhost';
SET DEFAULT ROLE 'hanip_report_reader' TO 'hanip_intern'@'localhost';

SHOW GRANTS FOR 'hanip_intern'@'localhost' USING 'hanip_report_reader';

