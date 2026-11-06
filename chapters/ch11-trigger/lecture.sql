-- =============================================================
--  Ch11. 트리거 — 데이터가 바뀌면 자동으로 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery11)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery11;


-- -------------------------------------------------------------
-- 2-1. 이력 테이블
-- -------------------------------------------------------------
CREATE TABLE menu_price_history (
    history_id  INT      NOT NULL AUTO_INCREMENT,
    menu_id     INT      NOT NULL,
    old_price   INT      NOT NULL,
    new_price   INT      NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_menu_price_history      PRIMARY KEY (history_id),
    CONSTRAINT fk_menu_price_history_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id)
) COMMENT '메뉴 가격 변경 이력';


-- -------------------------------------------------------------
-- 2-3. CREATE TRIGGER
-- -------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_menus_price_history
AFTER UPDATE ON menus
FOR EACH ROW
BEGIN
    IF OLD.price <> NEW.price THEN
        INSERT INTO menu_price_history (menu_id, old_price, new_price)
        VALUES (NEW.menu_id, OLD.price, NEW.price);
    END IF;
END $$
DELIMITER ;


-- -------------------------------------------------------------
-- 2-4. 동작 확인
-- -------------------------------------------------------------
UPDATE menus SET price = 10500 WHERE menu_id = 1;
UPDATE menus SET description = '토렴한 순대국밥' WHERE menu_id = 2;

SELECT history_id, menu_id, old_price, new_price
FROM menu_price_history;

UPDATE menus SET price = price + 500 WHERE restaurant_id = 3;

SELECT menu_id, old_price, new_price
FROM menu_price_history
WHERE history_id > 1
ORDER BY menu_id;


-- -------------------------------------------------------------
-- 3-1. NEW를 고칠 수 있는 건 BEFORE뿐
-- -------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_order_items_fill_price
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    IF NEW.unit_price IS NULL OR NEW.unit_price = 0 THEN
        SET NEW.unit_price = (SELECT price FROM menus WHERE menu_id = NEW.menu_id);
    END IF;
END $$
DELIMITER ;

-- ⚠ 에러 예제
DELIMITER $$
CREATE TRIGGER trg_bad_after
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    SET NEW.unit_price = 0;
END $$
DELIMITER ;


-- -------------------------------------------------------------
-- 4-1. 주문 상태 이력과 잘못된 상태 변경
-- -------------------------------------------------------------
CREATE TABLE order_status_logs (
    log_id       INT          NOT NULL AUTO_INCREMENT,
    order_id     INT          NOT NULL,
    from_status  VARCHAR(10)  NOT NULL,
    to_status    VARCHAR(10)  NOT NULL,
    changed_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_order_status_logs       PRIMARY KEY (log_id),
    CONSTRAINT fk_order_status_logs_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
) COMMENT '주문 상태 변경 이력';

DELIMITER $$
CREATE TRIGGER trg_orders_status_check
BEFORE UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status IN ('배달완료', '취소') AND NEW.status <> OLD.status THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '배달완료 또는 취소된 주문은 상태를 바꿀 수 없습니다.';
    END IF;

    IF NEW.status = '배달완료' AND NEW.delivered_at IS NULL THEN
        SET NEW.delivered_at = NOW();
    END IF;
END $$

CREATE TRIGGER trg_orders_status_log
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO order_status_logs (order_id, from_status, to_status)
        VALUES (NEW.order_id, OLD.status, NEW.status);
    END IF;
END $$
DELIMITER ;


-- -------------------------------------------------------------
-- 4-2. 정상 흐름
-- -------------------------------------------------------------
UPDATE orders SET status = '조리중' WHERE order_id = 563;
UPDATE orders SET status = '배달중', rider_id = 2 WHERE order_id = 563;
UPDATE orders SET status = '배달완료' WHERE order_id = 563;

SELECT log_id, order_id, from_status, to_status FROM order_status_logs;

SELECT order_id, status, rider_id, delivered_at IS NOT NULL AS has_delivered_at
FROM orders WHERE order_id = 563;


-- -------------------------------------------------------------
-- 4-3. 규칙 위반
-- -------------------------------------------------------------
-- ⚠ 에러 예제
UPDATE orders SET status = '접수' WHERE order_id = 563;

SELECT order_id, status FROM orders WHERE order_id = 563;


-- -------------------------------------------------------------
-- 5-1. 열 추가와 초기값
-- -------------------------------------------------------------
ALTER TABLE restaurants
    ADD COLUMN review_count INT NOT NULL DEFAULT 0 COMMENT '리뷰 수 (트리거로 유지)',
    ADD COLUMN rating_sum   INT NOT NULL DEFAULT 0 COMMENT '별점 합계 (트리거로 유지)';

UPDATE restaurants r
JOIN (
    SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
    FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
    GROUP BY o.restaurant_id
) t ON r.restaurant_id = t.restaurant_id
SET r.review_count = t.cnt, r.rating_sum = t.total
WHERE r.restaurant_id > 0;   -- 안전 업데이트 모드: 키 열 조건 (전체 가게가 대상)

SELECT restaurant_id, name, review_count, rating_sum,
    ROUND(rating_sum / NULLIF(review_count, 0), 2) AS avg_rating
FROM restaurants
WHERE restaurant_id IN (1, 15);


-- -------------------------------------------------------------
-- 5-2. INSERT · DELETE 트리거
-- -------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_reviews_stats_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = NEW.order_id;

    UPDATE restaurants
    SET review_count = review_count + 1,
        rating_sum   = rating_sum + NEW.rating
    WHERE restaurant_id = v_restaurant_id;
END $$

CREATE TRIGGER trg_reviews_stats_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = OLD.order_id;

    UPDATE restaurants
    SET review_count = review_count - 1,
        rating_sum   = rating_sum - OLD.rating
    WHERE restaurant_id = v_restaurant_id;
END $$
DELIMITER ;


-- -------------------------------------------------------------
-- 5-3. 확인
-- -------------------------------------------------------------
INSERT INTO reviews (order_id, rating, content, created_at)
VALUES (549, 5, '국물이 진하고 고기가 많아요', '2026-06-30 18:58:00');

SELECT restaurant_id, review_count, rating_sum,
    ROUND(rating_sum / review_count, 2) AS avg_rating
FROM restaurants WHERE restaurant_id = 1;

DELETE FROM reviews WHERE order_id = 549;

SELECT restaurant_id, review_count, rating_sum,
    ROUND(rating_sum / review_count, 2) AS avg_rating
FROM restaurants WHERE restaurant_id = 1;

SELECT COUNT(*) AS mismatched_restaurants
FROM restaurants r
LEFT JOIN (
    SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
    FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
    GROUP BY o.restaurant_id
) t ON r.restaurant_id = t.restaurant_id
WHERE r.review_count <> COALESCE(t.cnt, 0)
   OR r.rating_sum   <> COALESCE(t.total, 0);


-- -------------------------------------------------------------
-- 6-1. 트리거는 같은 트랜잭션 안에서 실행된다
-- -------------------------------------------------------------
START TRANSACTION;

UPDATE menus SET price = 11000 WHERE menu_id = 2;

SELECT (SELECT price FROM menus WHERE menu_id = 2) AS price_in_tx,
       (SELECT COUNT(*) FROM menu_price_history)    AS history_in_tx;

ROLLBACK;

SELECT (SELECT price FROM menus WHERE menu_id = 2) AS price_after_rollback,
       (SELECT COUNT(*) FROM menu_price_history)    AS history_after_rollback;


-- -------------------------------------------------------------
-- 6-2. 트리거가 실패하면 문장 전체가 실패한다
-- -------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_order_items_check_sold_out
BEFORE INSERT ON order_items
FOR EACH ROW
FOLLOWS trg_order_items_fill_price
BEGIN
    IF (SELECT is_sold_out FROM menus WHERE menu_id = NEW.menu_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '품절된 메뉴는 주문할 수 없습니다.';
    END IF;
END $$
DELIMITER ;

UPDATE menus SET is_sold_out = TRUE WHERE menu_id = 2;

SELECT menu_id, name, price, is_sold_out FROM menus WHERE menu_id IN (2, 4, 5);

-- ⚠ 에러 예제
INSERT INTO order_items (order_id, menu_id, quantity, unit_price) VALUES
    (562, 4, 1, 0),
    (562, 2, 1, 0),
    (562, 5, 1, 0);

SELECT COUNT(*) AS items_of_order_562 FROM order_items WHERE order_id = 562;


-- -------------------------------------------------------------
-- 6-3. 주문 접수 트랜잭션에 적용
-- -------------------------------------------------------------
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
VALUES (4, 5, '접수', '카드', 3000, '2026-06-30 19:05:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price) VALUES (@order_id, 21, 1, 0);

SELECT order_id, menu_id, quantity, unit_price FROM order_items WHERE order_id = @order_id;

-- ⚠ 에러 예제
INSERT INTO order_items (order_id, menu_id, quantity, unit_price) VALUES (@order_id, 24, 1, 0);

ROLLBACK;

SELECT COUNT(*) AS orders_total,
       (SELECT COUNT(*) FROM order_items WHERE order_id = @order_id) AS items_of_failed_order
FROM orders;


-- -------------------------------------------------------------
-- 6-4. 트리거 안에서 하면 안 되는 것
-- -------------------------------------------------------------
-- ⚠ 에러 예제
DELIMITER $$
CREATE TRIGGER trg_bad_commit
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    COMMIT;
END $$
DELIMITER ;


-- -------------------------------------------------------------
-- 7. 트리거 관리
-- -------------------------------------------------------------
SELECT trigger_name AS trigger_name, event_object_table AS table_name,
    action_timing AS timing, event_manipulation AS event, action_order AS action_order
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY event_object_table, event_manipulation, action_timing, action_order;

