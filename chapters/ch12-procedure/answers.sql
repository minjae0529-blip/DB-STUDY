-- Ch12 실습 — 조건, 반복, 예외, 트랜잭션 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery12)
USE hanip_delivery12;

-- 문제 1. 가게 메뉴판 ★
DELIMITER $$
CREATE PROCEDURE sp_menu_list(IN p_restaurant_id INT)
BEGIN
    SELECT menu_id, name, price, is_sold_out
    FROM menus
    WHERE restaurant_id = p_restaurant_id
    ORDER BY price DESC, menu_id;
END $$
DELIMITER ;

CALL sp_menu_list(3);

-- 문제 2. OUT 파라미터 ★
DELIMITER $$
CREATE PROCEDURE sp_restaurant_june(
    IN  p_restaurant_id INT,
    OUT p_orders        INT,
    OUT p_food_sales    INT
)
BEGIN
    SELECT COUNT(DISTINCT o.order_id), COALESCE(SUM(oi.quantity * oi.unit_price), 0)
    INTO p_orders, p_food_sales
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.restaurant_id = p_restaurant_id AND o.status = '배달완료'
      AND o.ordered_at >= '2026-06-01' AND o.ordered_at < '2026-07-01';
END $$
DELIMITER ;

CALL sp_restaurant_june(1, @orders, @sales);
SELECT @orders AS orders, @sales AS food_sales;

-- 문제 3. 배달팁 함수 ★★
DELIMITER $$
CREATE FUNCTION fn_delivery_fee(p_restaurant_id INT, p_food_amount INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_fee INT;
    SELECT delivery_fee INTO v_fee FROM restaurants WHERE restaurant_id = p_restaurant_id;

    IF p_food_amount >= 30000 THEN
        RETURN 0;
    ELSEIF p_food_amount >= 20000 THEN
        RETURN GREATEST(v_fee - 1000, 0);
    ELSE
        RETURN v_fee;
    END IF;
END $$
DELIMITER ;

SELECT fn_delivery_fee(4, 15000) AS fee_15000,
       fn_delivery_fee(4, 25000) AS fee_25000,
       fn_delivery_fee(4, 35000) AS fee_35000;

-- 문제 4. 다음 상태 — CASE 문 ★★
DELIMITER $$
CREATE PROCEDURE sp_next_status(IN p_order_id INT, OUT p_next VARCHAR(10))
BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status FROM orders WHERE order_id = p_order_id;

    CASE v_status
        WHEN '접수'   THEN SET p_next = '조리중';
        WHEN '조리중' THEN SET p_next = '배달중';
        WHEN '배달중' THEN SET p_next = '배달완료';
        WHEN '배달완료' THEN SET p_next = '변경 불가';
        WHEN '취소'   THEN SET p_next = '변경 불가';
        ELSE SET p_next = '없는 주문';
    END CASE;
END $$
DELIMITER ;

CALL sp_next_status(563, @a);
CALL sp_next_status(561, @b);
CALL sp_next_status(1, @c);
CALL sp_next_status(9999, @d);
SELECT @a AS order_563, @b AS order_561, @c AS order_1, @d AS order_9999;

-- 문제 5. 월별 매출표 — WHILE ★★
CREATE TABLE month_sales (
    sales_month CHAR(7) NOT NULL,
    orders      INT     NOT NULL,
    food_sales  INT     NOT NULL,
    CONSTRAINT pk_month_sales PRIMARY KEY (sales_month)
);

DELIMITER $$
CREATE PROCEDURE sp_fill_month_sales(IN p_year INT, IN p_from_month INT, IN p_to_month INT)
BEGIN
    DECLARE v_month INT DEFAULT p_from_month;
    DECLARE v_start DATE;

    WHILE v_month <= p_to_month DO
        SET v_start = MAKEDATE(p_year, 1) + INTERVAL (v_month - 1) MONTH;

        DELETE FROM month_sales WHERE sales_month = DATE_FORMAT(v_start, '%Y-%m');
        INSERT INTO month_sales (sales_month, orders, food_sales)
        SELECT DATE_FORMAT(v_start, '%Y-%m'), COUNT(DISTINCT o.order_id),
            COALESCE(SUM(oi.quantity * oi.unit_price), 0)
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.status = '배달완료'
          AND o.ordered_at >= v_start AND o.ordered_at < v_start + INTERVAL 1 MONTH;

        SET v_month = v_month + 1;
    END WHILE;
END $$
DELIMITER ;

CALL sp_fill_month_sales(2026, 1, 6);
SELECT sales_month, orders, food_sales FROM month_sales ORDER BY sales_month;

-- 문제 6. 나눠서 지우기 — REPEAT ★★
CREATE TABLE reviews_archive AS SELECT * FROM reviews;

DELIMITER $$
CREATE PROCEDURE sp_purge_reviews_archive(IN p_batch INT, OUT p_rounds INT)
BEGIN
    DECLARE v_deleted INT;
    SET p_rounds = 0;

    REPEAT
        DELETE FROM reviews_archive LIMIT p_batch;
        SET v_deleted = ROW_COUNT();
        SET p_rounds = p_rounds + 1;
    UNTIL v_deleted = 0 END REPEAT;
END $$
DELIMITER ;

CALL sp_purge_reviews_archive(100, @rounds);
SELECT @rounds AS rounds, (SELECT COUNT(*) FROM reviews_archive) AS remaining;

-- 문제 7. 중복 발급은 표시만 — CONTINUE HANDLER ★★
DELIMITER $$
CREATE PROCEDURE sp_issue_coupon(
    IN  p_customer_id INT,
    IN  p_coupon_id   INT,
    IN  p_issued_at   DATETIME,
    OUT p_result      VARCHAR(50)
)
BEGIN
    DECLARE v_duplicate BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR 1062 SET v_duplicate = TRUE;

    INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
    SELECT p_customer_id, coupon_id, p_issued_at, p_issued_at + INTERVAL valid_days DAY
    FROM coupons WHERE coupon_id = p_coupon_id;

    IF v_duplicate THEN
        SET p_result = '이미 보유한 쿠폰';
    ELSE
        SET p_result = '발급 완료';
    END IF;
END $$
DELIMITER ;

CALL sp_issue_coupon(7, 4, '2026-06-30 10:00:00', @r1);
CALL sp_issue_coupon(7, 4, '2026-06-30 10:00:00', @r2);
SELECT @r1 AS first_try, @r2 AS second_try,
    (SELECT COUNT(*) FROM customer_coupons WHERE customer_id = 7 AND coupon_id = 4) AS coupon_rows;

-- 문제 8. 가격 변경 검증 — SIGNAL ★★★
DELIMITER $$
CREATE PROCEDURE sp_change_price(IN p_menu_id INT, IN p_new_price INT)
BEGIN
    DECLARE v_old INT;
    SELECT price INTO v_old FROM menus WHERE menu_id = p_menu_id;

    IF v_old IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '없는 메뉴입니다.', MYSQL_ERRNO = 5101;
    ELSEIF p_new_price <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '가격은 0원보다 커야 합니다.', MYSQL_ERRNO = 5102;
    ELSEIF ABS(p_new_price - v_old) > v_old * 0.3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '한 번에 30% 넘게 바꿀 수 없습니다.', MYSQL_ERRNO = 5103;
    END IF;

    UPDATE menus SET price = p_new_price WHERE menu_id = p_menu_id;
END $$
DELIMITER ;

CALL sp_change_price(11, 10000);
SELECT menu_id, name, price FROM menus WHERE menu_id = 11;

-- 문제 9. 주문 취소 — 트랜잭션 + EXIT HANDLER + 기록 ★★★
CREATE TABLE error_logs (
    log_id        INT           NOT NULL AUTO_INCREMENT,
    proc_name     VARCHAR(64)   NOT NULL,
    error_code    INT           NOT NULL,
    error_message VARCHAR(500)  NOT NULL,
    logged_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_error_logs PRIMARY KEY (log_id)
);

DELIMITER $$
CREATE PROCEDURE sp_cancel_order(IN p_order_id INT, OUT p_result VARCHAR(200))
BEGIN
    DECLARE v_status      VARCHAR(10);
    DECLARE v_customer_id INT;
    DECLARE v_code        INT;
    DECLARE v_msg         VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_code = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO error_logs (proc_name, error_code, error_message)
        VALUES ('sp_cancel_order', v_code, v_msg);
        SET p_result = CONCAT('실패: ', v_msg);
    END;

    START TRANSACTION;

    SELECT status, customer_id INTO v_status, v_customer_id
    FROM orders WHERE order_id = p_order_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '없는 주문입니다.', MYSQL_ERRNO = 5201;
    ELSEIF v_status NOT IN ('접수', '조리중') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 조리가 끝나 취소할 수 없습니다.', MYSQL_ERRNO = 5202;
    END IF;

    UPDATE orders SET status = '취소' WHERE order_id = p_order_id;
    UPDATE customer_coupons SET used_order_id = NULL WHERE used_order_id = p_order_id;

    INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
    VALUES (v_customer_id, 4, '2026-06-30 19:30:00', '2026-06-30 19:30:00' + INTERVAL 30 DAY);

    COMMIT;
    SET p_result = '취소 완료';
END $$
DELIMITER ;

CALL sp_cancel_order(563, @r1);
CALL sp_cancel_order(561, @r2);
CALL sp_cancel_order(9999, @r3);
SELECT @r1 AS result_563, @r2 AS result_561, @r3 AS result_9999,
    (SELECT status FROM orders WHERE order_id = 563) AS status_563,
    (SELECT COUNT(*) FROM error_logs) AS error_count;

-- 문제 10. 평점 낮은 가게 찾기 — 커서 + LOOP ★★★
CREATE TABLE restaurant_alerts (
    restaurant_id INT           NOT NULL,
    review_count  INT           NOT NULL,
    avg_rating    DECIMAL(3,2)  NOT NULL,
    message       VARCHAR(100)  NOT NULL,
    CONSTRAINT pk_restaurant_alerts PRIMARY KEY (restaurant_id)
);

DELIMITER $$
CREATE PROCEDURE sp_flag_low_rating(IN p_min_reviews INT, IN p_threshold DECIMAL(3,2), OUT p_flagged INT)
BEGIN
    DECLARE v_done          BOOLEAN DEFAULT FALSE;
    DECLARE v_restaurant_id INT;
    DECLARE v_is_open       BOOLEAN;
    DECLARE v_count         INT;
    DECLARE v_avg           DECIMAL(3,2);

    DECLARE cur_restaurants CURSOR FOR
        SELECT restaurant_id, is_open FROM restaurants ORDER BY restaurant_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_flagged = 0;
    DELETE FROM restaurant_alerts WHERE restaurant_id > 0;
    OPEN cur_restaurants;

    shop_loop: LOOP
        FETCH cur_restaurants INTO v_restaurant_id, v_is_open;
        IF v_done THEN
            LEAVE shop_loop;
        END IF;
        IF NOT v_is_open THEN
            ITERATE shop_loop;
        END IF;

        SELECT COUNT(*), AVG(rv.rating) INTO v_count, v_avg
        FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
        WHERE o.restaurant_id = v_restaurant_id;

        IF v_count >= p_min_reviews AND v_avg < p_threshold THEN
            INSERT INTO restaurant_alerts (restaurant_id, review_count, avg_rating, message)
            VALUES (v_restaurant_id, v_count, v_avg, CONCAT('평균 ', v_avg, '점 — 품질 점검 필요'));
            SET p_flagged = p_flagged + 1;
        END IF;
    END LOOP shop_loop;

    CLOSE cur_restaurants;
END $$
DELIMITER ;

CALL sp_flag_low_rating(5, 3.5, @flagged);
SELECT a.restaurant_id, r.name, a.review_count, a.avg_rating, a.message
FROM restaurant_alerts a JOIN restaurants r ON a.restaurant_id = r.restaurant_id
ORDER BY a.restaurant_id;
