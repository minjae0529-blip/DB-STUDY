-- Ch08 실습 — 데이터 바꾸고 묶기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery08)
USE hanip_delivery08;

-- 문제 1. 신메뉴 등록 ★
INSERT INTO menus (restaurant_id, name, price, description, is_signature)
VALUES (9, '치즈 떡볶이', 7500, '모차렐라 듬뿍', TRUE);

SELECT name, price, description, is_signature
FROM menus
WHERE restaurant_id = 9 AND is_signature = TRUE
ORDER BY price;

-- 문제 2. 음료 메뉴 한 번에 ★
INSERT INTO menus (restaurant_id, name, price) VALUES
    (10, '콜라', 2000),
    (10, '사이다', 2000),
    (10, '아이스티', 2500);

SELECT name, price
FROM menus
WHERE restaurant_id = 10 AND price < 3000
ORDER BY price, name;

-- 문제 3. 가격 조정 ★
SELECT name, price FROM menus WHERE restaurant_id = 8 AND price <= 6000;

UPDATE menus
SET price = price + 500
WHERE restaurant_id = 8 AND price <= 6000;

SELECT name, price
FROM menus
WHERE restaurant_id = 8
ORDER BY menu_id;

-- 문제 4. 리뷰 신고 처리 ★
SELECT review_id, content FROM reviews WHERE rating = 1;

DELETE FROM reviews
WHERE review_id IN (SELECT review_id FROM (
    SELECT review_id FROM reviews WHERE rating = 1 AND content = '다시는 안 시킬 것 같아요'
) t);

SELECT COUNT(*) AS one_star_reviews FROM reviews WHERE rating = 1;

-- 문제 5. 일 매출 요약표 ★★
CREATE TABLE daily_sales (
    sales_date DATE NOT NULL,
    orders     INT  NOT NULL,
    food_sales INT  NOT NULL,
    CONSTRAINT pk_daily_sales PRIMARY KEY (sales_date)
);

INSERT INTO daily_sales (sales_date, orders, food_sales)
SELECT DATE(o.ordered_at),
    COUNT(DISTINCT o.order_id),
    SUM(oi.quantity * oi.unit_price)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
    AND o.ordered_at >= '2026-06-24'
    AND o.ordered_at <  '2026-07-01'
GROUP BY DATE(o.ordered_at);

SELECT sales_date, orders, food_sales
FROM daily_sales
ORDER BY sales_date;

-- 문제 6. 등급 승급 ★★
SELECT c.customer_id, c.name, c.grade, COUNT(*) AS june_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = '배달완료'
    AND o.ordered_at >= '2026-06-01' AND o.ordered_at < '2026-07-01'
    AND c.grade = '일반'
GROUP BY c.customer_id, c.name, c.grade
HAVING COUNT(*) >= 4;

UPDATE customers c
JOIN (
    SELECT customer_id
    FROM orders
    WHERE status = '배달완료'
        AND ordered_at >= '2026-06-01' AND ordered_at < '2026-07-01'
    GROUP BY customer_id
    HAVING COUNT(*) >= 4
) t ON c.customer_id = t.customer_id
SET c.grade = '실버'
WHERE c.grade = '일반';

SELECT name, grade
FROM customers
WHERE grade = '실버'
ORDER BY customer_id;

-- 문제 7. 실수 되돌리기 ★★
START TRANSACTION;
UPDATE coupons SET is_active = FALSE WHERE coupon_id > 0;
SELECT COUNT(*) AS active_coupons FROM coupons WHERE is_active = TRUE;
ROLLBACK;

SELECT COUNT(*) AS active_coupons FROM coupons WHERE is_active = TRUE;

-- 문제 8. SAVEPOINT ★★
START TRANSACTION;
UPDATE restaurants SET delivery_fee = 3000 WHERE restaurant_id = 4;
SAVEPOINT fee_done;
UPDATE restaurants SET min_order_amount = 0 WHERE restaurant_id = 4;
ROLLBACK TO SAVEPOINT fee_done;
COMMIT;

SELECT name, delivery_fee, min_order_amount
FROM restaurants
WHERE restaurant_id = 4;

-- 문제 9. 주문 접수 ★★★
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, ordered_at)
VALUES (30, 2, '접수', '카드', 3000, 3000, '2026-06-30 19:30:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price
FROM menus
WHERE restaurant_id = 2 AND name IN ('등심카츠', '치즈카츠');

UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 30
    AND coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'WELCOME3000')
    AND used_order_id IS NULL;
SELECT ROW_COUNT() AS coupon_rows_updated;

COMMIT;

SELECT c.name AS customer_name,
    m.name AS menu_name,
    oi.quantity,
    oi.unit_price,
    o.discount_amount,
    cp.code AS coupon_code
FROM orders o
JOIN customers c         ON o.customer_id = c.customer_id
JOIN order_items oi      ON o.order_id    = oi.order_id
JOIN menus m             ON oi.menu_id    = m.menu_id
JOIN customer_coupons cc ON cc.used_order_id = o.order_id
JOIN coupons cp          ON cc.coupon_id  = cp.coupon_id
WHERE o.order_id = @order_id
ORDER BY m.menu_id;

-- 문제 10. 주문 취소와 보상 쿠폰 ★★★
START TRANSACTION;

UPDATE orders SET status = '취소' WHERE order_id = 563 AND status = '접수';

INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
SELECT o.customer_id,
    cp.coupon_id,
    '2026-06-30 19:40:00',
    DATE_ADD('2026-06-30 19:40:00', INTERVAL cp.valid_days DAY)
FROM orders o
CROSS JOIN coupons cp
WHERE o.order_id = 563 AND cp.code = 'SORRY2000';

COMMIT;

SELECT o.order_id,
    o.status,
    c.name AS customer_name,
    cp.code AS coupon_code,
    cc.expires_at
FROM orders o
JOIN customers c         ON o.customer_id  = c.customer_id
JOIN customer_coupons cc ON cc.customer_id = c.customer_id
JOIN coupons cp          ON cc.coupon_id   = cp.coupon_id
WHERE o.order_id = 563
ORDER BY cc.customer_coupon_id;
