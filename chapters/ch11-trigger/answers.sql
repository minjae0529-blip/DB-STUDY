-- Ch11 실습 — 자동으로 기록하고, 막고, 맞추기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery11)
USE hanip_delivery11;

-- 문제 1. 등급 변경 이력 ★
CREATE TABLE customer_grade_logs (
    log_id      INT          NOT NULL AUTO_INCREMENT,
    customer_id INT          NOT NULL,
    old_grade   VARCHAR(10)  NOT NULL,
    new_grade   VARCHAR(10)  NOT NULL,
    changed_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customer_grade_logs          PRIMARY KEY (log_id),
    CONSTRAINT fk_customer_grade_logs_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

DELIMITER $$
CREATE TRIGGER trg_customers_grade_log
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    IF OLD.grade <> NEW.grade THEN
        INSERT INTO customer_grade_logs (customer_id, old_grade, new_grade)
        VALUES (NEW.customer_id, OLD.grade, NEW.grade);
    END IF;
END $$
DELIMITER ;

UPDATE customers SET grade = '실버' WHERE customer_id = 30;
UPDATE customers SET name = name WHERE customer_id = 30;

SELECT log_id, customer_id, old_grade, new_grade FROM customer_grade_logs;

-- 문제 2. 리뷰 내용 정리 ★
DELIMITER $$
CREATE TRIGGER trg_reviews_clean_content
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    SET NEW.content = NULLIF(TRIM(NEW.content), '');
END $$
DELIMITER ;

INSERT INTO reviews (order_id, rating, content, created_at) VALUES
    (549, 5, '   ', '2026-06-30 18:50:00'),
    (531, 4, '  맛있어요  ', '2026-06-30 18:50:00');

SELECT order_id, rating, content, CHAR_LENGTH(content) AS content_length
FROM reviews
WHERE order_id IN (531, 549)
ORDER BY order_id;

-- 문제 3. 가격 급락 방지 ★★
DELIMITER $$
CREATE TRIGGER trg_menus_price_guard
BEFORE UPDATE ON menus
FOR EACH ROW
BEGIN
    IF NEW.price < OLD.price * 0.5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '가격을 절반 미만으로 내릴 수 없습니다. 운영팀에 문의하세요.';
    END IF;
END $$
DELIMITER ;

UPDATE menus SET price = 9000 WHERE menu_id = 1;

SELECT menu_id, name, price FROM menus WHERE menu_id = 1;

-- 문제 4. 트리거가 한 일도 ROLLBACK된다 ★★
START TRANSACTION;
UPDATE customers SET grade = 'VIP' WHERE customer_id = 5;
ROLLBACK;

SELECT (SELECT grade FROM customers WHERE customer_id = 5) AS grade,
       (SELECT COUNT(*) FROM customer_grade_logs)          AS log_count;

-- 문제 5. 기사 배달 건수 ★★
ALTER TABLE riders ADD COLUMN delivery_count INT NOT NULL DEFAULT 0;

UPDATE riders r
JOIN (
    SELECT rider_id, COUNT(*) AS cnt
    FROM orders
    WHERE status = '배달완료' AND rider_id IS NOT NULL
    GROUP BY rider_id
) t ON r.rider_id = t.rider_id
SET r.delivery_count = t.cnt
WHERE r.rider_id > 0;

DELIMITER $$
CREATE TRIGGER trg_orders_rider_count
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status = '배달완료' AND OLD.status <> '배달완료' AND NEW.rider_id IS NOT NULL THEN
        UPDATE riders SET delivery_count = delivery_count + 1
        WHERE rider_id = NEW.rider_id;
    END IF;
END $$
DELIMITER ;

UPDATE orders SET status = '배달완료', delivered_at = '2026-06-30 18:55:00' WHERE order_id = 561;

SELECT r.rider_id, r.name, r.delivery_count,
    (SELECT COUNT(*) FROM orders o WHERE o.rider_id = r.rider_id AND o.status = '배달완료') AS actual_count
FROM riders r
WHERE r.rider_id = 4;

-- 문제 6. 쿠폰 보호 ★★
DELIMITER $$
CREATE TRIGGER trg_customer_coupons_guard
BEFORE UPDATE ON customer_coupons
FOR EACH ROW
BEGIN
    IF OLD.used_order_id IS NOT NULL AND NEW.used_order_id IS NOT NULL
       AND NEW.used_order_id <> OLD.used_order_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 사용한 쿠폰입니다.';
    END IF;

    IF OLD.used_order_id IS NULL AND NEW.used_order_id IS NOT NULL
       AND (SELECT ordered_at FROM orders WHERE order_id = NEW.used_order_id) > OLD.expires_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '만료된 쿠폰입니다.';
    END IF;
END $$
DELIMITER ;

UPDATE customer_coupons SET used_order_id = 563
WHERE customer_id = 5 AND coupon_id = 2;

SELECT customer_id, coupon_id, expires_at, used_order_id
FROM customer_coupons
WHERE customer_id = 5;

-- 문제 7. 주문 취소하면 쿠폰 복구 ★★★
DELIMITER $$
CREATE TRIGGER trg_orders_restore_coupon
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status = '취소' AND OLD.status <> '취소' THEN
        UPDATE customer_coupons SET used_order_id = NULL
        WHERE used_order_id = NEW.order_id;
    END IF;
END $$
DELIMITER ;

START TRANSACTION;
INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, discount_amount, ordered_at)
VALUES (30, 14, '접수', '카드', 3000, 3000, '2026-06-30 19:10:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price FROM menus WHERE menu_id IN (63, 66);

UPDATE customer_coupons SET used_order_id = @order_id
WHERE customer_id = 30 AND coupon_id = 1 AND used_order_id IS NULL;
SELECT ROW_COUNT() AS coupon_rows;   -- 1 확인 후
COMMIT;

UPDATE orders SET status = '취소' WHERE order_id = @order_id;

SELECT customer_id, coupon_id, used_order_id
FROM customer_coupons
WHERE customer_id = 30;

-- 문제 8. 가게 리뷰 통계 완성판 ★★★
ALTER TABLE restaurants
    ADD COLUMN review_count INT NOT NULL DEFAULT 0,
    ADD COLUMN rating_sum   INT NOT NULL DEFAULT 0;

UPDATE restaurants r
JOIN (
    SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
    FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
    GROUP BY o.restaurant_id
) t ON r.restaurant_id = t.restaurant_id
SET r.review_count = t.cnt, r.rating_sum = t.total
WHERE r.restaurant_id > 0;

DELIMITER $$
CREATE TRIGGER trg_reviews_stats_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = NEW.order_id;
    UPDATE restaurants SET review_count = review_count + 1, rating_sum = rating_sum + NEW.rating
    WHERE restaurant_id = v_restaurant_id;
END $$

CREATE TRIGGER trg_reviews_stats_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    IF OLD.rating <> NEW.rating THEN
        SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = NEW.order_id;
        UPDATE restaurants SET rating_sum = rating_sum + (NEW.rating - OLD.rating)
        WHERE restaurant_id = v_restaurant_id;
    END IF;
END $$

CREATE TRIGGER trg_reviews_stats_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = OLD.order_id;
    UPDATE restaurants SET review_count = review_count - 1, rating_sum = rating_sum - OLD.rating
    WHERE restaurant_id = v_restaurant_id;
END $$
DELIMITER ;

UPDATE reviews SET rating = 1 WHERE order_id = 549;

SELECT restaurant_id, review_count, rating_sum,
    ROUND(rating_sum / review_count, 2) AS avg_rating
FROM restaurants
WHERE restaurant_id = 1;

-- 문제 9. 통계가 정말 맞는지 검증 ★★
INSERT INTO reviews (order_id, rating, content, created_at)
VALUES (486, 3, '보통이에요', '2026-06-30 18:55:00');
DELETE FROM reviews WHERE review_id = 1;

SELECT
    (SELECT COUNT(*)
     FROM restaurants r
     LEFT JOIN (
         SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
         FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
         GROUP BY o.restaurant_id
     ) t ON r.restaurant_id = t.restaurant_id
     WHERE r.review_count <> COALESCE(t.cnt, 0) OR r.rating_sum <> COALESCE(t.total, 0)) AS mismatched_restaurants,
    (SELECT COUNT(*) FROM reviews) AS total_reviews,
    (SELECT SUM(review_count) FROM restaurants) AS total_count;

-- 문제 10. 내가 만든 트리거 목록 ★
SELECT event_object_table AS table_name, event_manipulation AS event,
    action_timing AS timing, trigger_name AS trigger_name
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY table_name, event, timing, trigger_name;
