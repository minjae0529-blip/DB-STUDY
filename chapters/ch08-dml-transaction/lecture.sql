-- =============================================================
--  Ch08. 데이터 변경과 트랜잭션 (DML · TCL) — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery08)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery08;


-- -------------------------------------------------------------
-- 수업 준비
-- -------------------------------------------------------------
SELECT cc.customer_coupon_id, c.name AS customer_name, cp.code, cc.expires_at, cc.used_order_id
FROM customer_coupons cc
JOIN customers c ON cc.customer_id = c.customer_id
JOIN coupons cp  ON cc.coupon_id   = cp.coupon_id
ORDER BY cc.customer_coupon_id;


-- -------------------------------------------------------------
-- 1-1. 열을 지정해서 넣기
-- -------------------------------------------------------------
INSERT INTO menus (restaurant_id, name, price, description)
VALUES (15, '명란 크림 파스타', 15000, '저염 명란과 생크림');

SELECT menu_id, restaurant_id, name, price, is_signature, is_sold_out
FROM menus
WHERE restaurant_id = 15;


-- -------------------------------------------------------------
-- 1-2. 여러 행 한 번에
-- -------------------------------------------------------------
INSERT INTO menus (restaurant_id, name, price) VALUES
    (15, '봉골레 파스타', 16000),
    (15, '레몬 에이드',   4500);


-- -------------------------------------------------------------
-- 1-3. 방금 넣은 번호 받기 — LAST_INSERT_ID()
-- -------------------------------------------------------------
SELECT LAST_INSERT_ID() AS last_id;


-- -------------------------------------------------------------
-- 1-4. INSERT … SELECT — 조회 결과를 그대로 넣기
-- -------------------------------------------------------------
CREATE TABLE monthly_store_sales (
    sales_month   CHAR(7)  NOT NULL,
    restaurant_id INT      NOT NULL,
    orders        INT      NOT NULL,
    food_sales    INT      NOT NULL,
    CONSTRAINT pk_monthly_store_sales PRIMARY KEY (sales_month, restaurant_id),
    CONSTRAINT fk_mss_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)
);

INSERT INTO monthly_store_sales (sales_month, restaurant_id, orders, food_sales)
SELECT DATE_FORMAT(o.ordered_at, '%Y-%m'),
    o.restaurant_id,
    COUNT(DISTINCT o.order_id),
    SUM(oi.quantity * oi.unit_price)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
GROUP BY DATE_FORMAT(o.ordered_at, '%Y-%m'), o.restaurant_id;

SELECT COUNT(*) AS rows_inserted, SUM(food_sales) AS total_sales
FROM monthly_store_sales;


-- -------------------------------------------------------------
-- 2-1. WHERE가 안전핀이다
-- -------------------------------------------------------------
-- ⚠ 에러 예제
SET SQL_SAFE_UPDATES = 1;
UPDATE menus SET price = price + 500;


-- -------------------------------------------------------------
-- 2-2. 바꾸기 전에 SELECT
-- -------------------------------------------------------------
SELECT menu_id, name, price
FROM menus
WHERE restaurant_id = 3 AND is_signature = TRUE;

UPDATE menus
SET price = price + 500
WHERE restaurant_id = 3 AND is_signature = TRUE;

SELECT menu_id, name, price
FROM menus
WHERE restaurant_id = 3 AND is_signature = TRUE;


-- -------------------------------------------------------------
-- 2-3. 여러 열 한 번에
-- -------------------------------------------------------------
UPDATE menus
SET is_sold_out = FALSE,
    description = '딸기 시즌 재입고'
WHERE menu_id = 67;

SELECT menu_id, name, is_sold_out, description FROM menus WHERE menu_id = 67;


-- -------------------------------------------------------------
-- 3-1. 지울 수 있는 것
-- -------------------------------------------------------------
SELECT review_id, order_id, rating, content FROM reviews WHERE review_id = 1;

DELETE FROM reviews WHERE review_id = 1;

SELECT COUNT(*) AS reviews_left FROM reviews;


-- -------------------------------------------------------------
-- 3-2. FK가 막는 삭제
-- -------------------------------------------------------------
-- ⚠ 에러 예제
DELETE FROM restaurants WHERE restaurant_id = 13;


-- -------------------------------------------------------------
-- 4-3. 자동 커밋(autocommit)
-- -------------------------------------------------------------
SELECT @@autocommit;


-- -------------------------------------------------------------
-- 5-1. ROLLBACK — 없던 일로
-- -------------------------------------------------------------
START TRANSACTION;
DELETE FROM reviews WHERE rating >= 4 AND review_id > 0;
SELECT COUNT(*) AS reviews_after_delete FROM reviews;

ROLLBACK;
SELECT COUNT(*) AS reviews_after_rollback FROM reviews;


-- -------------------------------------------------------------
-- 5-2. COMMIT — 확정
-- -------------------------------------------------------------
START TRANSACTION;
UPDATE coupons SET is_active = FALSE WHERE coupon_id = 2;
COMMIT;

SELECT code, is_active FROM coupons ORDER BY coupon_id;


-- -------------------------------------------------------------
-- 5-3. SAVEPOINT — 중간 저장
-- -------------------------------------------------------------
START TRANSACTION;
UPDATE menus SET price = 11000 WHERE menu_id = 1;
SAVEPOINT after_price;
UPDATE menus SET is_sold_out = TRUE WHERE menu_id = 1;
ROLLBACK TO SAVEPOINT after_price;
COMMIT;

SELECT menu_id, name, price, is_sold_out FROM menus WHERE menu_id = 1;

UPDATE menus SET price = 10000 WHERE menu_id = 1;


-- -------------------------------------------------------------
-- 6-1. 성공 시나리오
-- -------------------------------------------------------------
START TRANSACTION;

-- ① 주문 머리
INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, request_note, ordered_at)
VALUES (1, 1, '접수', '간편결제', 2500, 5000, '문 앞에 두고 벨 눌러주세요', '2026-06-30 19:05:00');

SET @order_id = LAST_INSERT_ID();

-- ② 주문 상세: 단가는 지금 메뉴 가격으로 (주문 당시 가격 보존)
INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, CASE menu_id WHEN 1 THEN 2 ELSE 1 END, price
FROM menus
WHERE menu_id IN (1, 4);

-- ③ 쿠폰 사용 표시 (아직 안 쓴 쿠폰만)
UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 1 AND coupon_id = 3 AND used_order_id IS NULL;

SELECT @order_id AS new_order_id, ROW_COUNT() AS coupon_rows_updated;

COMMIT;

SELECT o.order_id, c.name AS customer_name, r.name AS restaurant_name,
    m.name AS menu_name, oi.quantity, oi.unit_price,
    o.delivery_fee, o.discount_amount
FROM orders o
JOIN customers c    ON o.customer_id   = c.customer_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN menus m        ON oi.menu_id      = m.menu_id
WHERE o.order_id = (SELECT MAX(order_id) FROM orders)
ORDER BY oi.menu_id;

SELECT cc.customer_coupon_id, cp.code, cc.used_order_id
FROM customer_coupons cc
JOIN coupons cp ON cc.coupon_id = cp.coupon_id
WHERE cc.customer_id = 1;


-- -------------------------------------------------------------
-- 6-2. 실패 시나리오 ① — 이미 쓴 쿠폰
-- -------------------------------------------------------------
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, ordered_at)
VALUES (1, 6, '접수', '카드', 3000, 5000, '2026-06-30 19:20:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price FROM menus WHERE menu_id = 26;

UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 1 AND coupon_id = 3 AND used_order_id IS NULL;

SELECT ROW_COUNT() AS coupon_rows_updated;

ROLLBACK;
SELECT COUNT(*) AS orders_total FROM orders;


-- -------------------------------------------------------------
-- 6-3. 실패 시나리오 ② — 중간에 에러
-- -------------------------------------------------------------
START TRANSACTION;
INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
VALUES (2, 9, '접수', '카드', 2500, '2026-06-30 19:25:00');
SET @order_id = LAST_INSERT_ID();

-- ⚠ 에러 예제
INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
VALUES (@order_id, 999, 1, 5500);

ROLLBACK;
SELECT COUNT(*) AS orders_total FROM orders;

