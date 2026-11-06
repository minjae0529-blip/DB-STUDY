-- =============================================================
--  Ch12. 저장 프로시저와 함수 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery12)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery12;


-- -------------------------------------------------------------
-- 1-1. 첫 프로시저
-- -------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_restaurant_summary(IN p_restaurant_id INT)
BEGIN
    SELECT r.name, r.category, COUNT(o.order_id) AS delivered_orders,
        MAX(o.ordered_at) AS last_order
    FROM restaurants r
    LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id AND o.status = '배달완료'
    WHERE r.restaurant_id = p_restaurant_id
    GROUP BY r.restaurant_id, r.name, r.category;
END $$
DELIMITER ;

CALL sp_restaurant_summary(1);


-- -------------------------------------------------------------
-- 2-2. OUT 파라미터 — 값을 돌려받기
-- -------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_customer_stats(
    IN  p_customer_id INT,
    OUT p_orders      INT,
    OUT p_total_paid  INT
)
BEGIN
    SELECT COUNT(*), COALESCE(SUM(t.amount), 0)
    INTO p_orders, p_total_paid
    FROM (
        SELECT o.order_id,
            SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS amount
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.customer_id = p_customer_id AND o.status = '배달완료'
        GROUP BY o.order_id
    ) t;
END $$
DELIMITER ;

CALL sp_customer_stats(1, @orders, @total);
SELECT @orders AS orders, @total AS total_paid;


-- -------------------------------------------------------------
-- 3-1. IF · ELSEIF · ELSE — 등급 판정
-- -------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_check_grade(IN p_customer_id INT, IN p_base_date DATE)
BEGIN
    DECLARE v_spend INT DEFAULT 0;
    DECLARE v_grade VARCHAR(10);

    SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0)
         + COALESCE((SELECT SUM(delivery_fee - discount_amount) FROM orders
                     WHERE customer_id = p_customer_id AND status = '배달완료'
                       AND ordered_at >= p_base_date - INTERVAL 3 MONTH AND ordered_at < p_base_date), 0)
    INTO v_spend
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id AND o.status = '배달완료'
      AND o.ordered_at >= p_base_date - INTERVAL 3 MONTH AND o.ordered_at < p_base_date;

    IF v_spend >= 600000 THEN
        SET v_grade = 'VIP';
    ELSEIF v_spend >= 400000 THEN
        SET v_grade = '골드';
    ELSEIF v_spend >= 200000 THEN
        SET v_grade = '실버';
    ELSE
        SET v_grade = '일반';
    END IF;

    SELECT name, grade AS current_grade, v_spend AS spend_3m, v_grade AS new_grade
    FROM customers WHERE customer_id = p_customer_id;
END $$
DELIMITER ;

CALL sp_check_grade(5, '2026-07-01');


-- -------------------------------------------------------------
-- 3-2. CASE 문 — 쿠폰 할인액 계산
-- -------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_calc_discount(
    IN  p_coupon_id   INT,
    IN  p_food_amount INT,
    OUT p_discount    INT
)
BEGIN
    DECLARE v_type  VARCHAR(10);
    DECLARE v_value INT;
    DECLARE v_max   INT;
    DECLARE v_min   INT;

    SELECT discount_type, discount_value, max_discount, min_order_amount
    INTO v_type, v_value, v_max, v_min
    FROM coupons WHERE coupon_id = p_coupon_id;

    IF p_food_amount < v_min THEN
        SET p_discount = 0;                                  -- 최소 주문 금액 미달
    ELSE
        CASE v_type
            WHEN '정액' THEN
                SET p_discount = LEAST(v_value, p_food_amount);
            WHEN '정률' THEN
                SET p_discount = FLOOR(p_food_amount * v_value / 100);
                IF v_max IS NOT NULL AND p_discount > v_max THEN
                    SET p_discount = v_max;                  -- 최대 할인액 제한
                END IF;
        END CASE;
    END IF;
END $$
DELIMITER ;

CALL sp_calc_discount(2, 40000, @d1);   -- 주말 15%, 최대 5,000원
CALL sp_calc_discount(2, 25000, @d2);
CALL sp_calc_discount(2, 18000, @d3);   -- 최소 주문 20,000원 미달
CALL sp_calc_discount(3, 30000, @d4);   -- VIP 정액 5,000원
SELECT @d1 AS weekend_40000, @d2 AS weekend_25000, @d3 AS weekend_18000, @d4 AS vip_30000;


-- -------------------------------------------------------------
-- 4-1. WHILE — 빈 날짜까지 채운 일별 매출표
-- -------------------------------------------------------------
SELECT DATE(ordered_at) AS sales_date, COUNT(*) AS orders
FROM orders
WHERE restaurant_id = 7 AND status = '배달완료'
  AND ordered_at >= '2026-06-21' AND ordered_at < '2026-07-01'
GROUP BY DATE(ordered_at);

CREATE TABLE daily_sales_report (
    restaurant_id INT  NOT NULL,
    sales_date    DATE NOT NULL,
    orders        INT  NOT NULL,
    food_sales    INT  NOT NULL,
    CONSTRAINT pk_daily_sales_report PRIMARY KEY (restaurant_id, sales_date)
);

DELIMITER $$
CREATE PROCEDURE sp_daily_sales(IN p_restaurant_id INT, IN p_from DATE, IN p_to DATE)
BEGIN
    DECLARE v_day DATE DEFAULT p_from;

    DELETE FROM daily_sales_report
    WHERE restaurant_id = p_restaurant_id AND sales_date BETWEEN p_from AND p_to;

    WHILE v_day <= p_to DO
        INSERT INTO daily_sales_report (restaurant_id, sales_date, orders, food_sales)
        SELECT p_restaurant_id, v_day, COUNT(DISTINCT o.order_id),
            COALESCE(SUM(oi.quantity * oi.unit_price), 0)
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.restaurant_id = p_restaurant_id AND o.status = '배달완료'
          AND o.ordered_at >= v_day AND o.ordered_at < v_day + INTERVAL 1 DAY;

        SET v_day = v_day + INTERVAL 1 DAY;
    END WHILE;

    SELECT sales_date, orders, food_sales FROM daily_sales_report
    WHERE restaurant_id = p_restaurant_id AND sales_date BETWEEN p_from AND p_to
    ORDER BY sales_date;
END $$
DELIMITER ;

CALL sp_daily_sales(7, '2026-06-21', '2026-06-30');


-- -------------------------------------------------------------
-- 4-2. REPEAT — 나눠서 지우기
-- -------------------------------------------------------------
CREATE TABLE order_items_archive AS SELECT * FROM order_items;

DELIMITER $$
CREATE PROCEDURE sp_purge_archive(IN p_batch INT, OUT p_rounds INT)
BEGIN
    DECLARE v_deleted INT;
    SET p_rounds = 0;

    REPEAT
        DELETE FROM order_items_archive LIMIT p_batch;
        SET v_deleted = ROW_COUNT();          -- 바로 다음 문장에서 받아 둔다
        SET p_rounds = p_rounds + 1;
    UNTIL v_deleted = 0 END REPEAT;
END $$
DELIMITER ;

CALL sp_purge_archive(300, @rounds);
SELECT @rounds AS rounds, (SELECT COUNT(*) FROM order_items_archive) AS remaining;


-- -------------------------------------------------------------
-- 4-3. LOOP + 커서 — 등급 재산정
-- -------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_recalc_grades(IN p_base_date DATE, OUT p_changed INT, OUT p_skipped INT)
BEGIN
    DECLARE v_done        BOOLEAN DEFAULT FALSE;
    DECLARE v_customer_id INT;
    DECLARE v_old_grade   VARCHAR(10);
    DECLARE v_joined_at   DATETIME;
    DECLARE v_spend       INT;
    DECLARE v_new_grade   VARCHAR(10);

    -- ① 커서: 처리할 대상 (변수 다음, 핸들러 전에 선언)
    DECLARE cur_customers CURSOR FOR
        SELECT customer_id, grade, joined_at FROM customers ORDER BY customer_id;
    -- ② 더 꺼낼 행이 없으면(NOT FOUND) 표시만 하고 계속
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_changed = 0, p_skipped = 0;
    OPEN cur_customers;

    read_loop: LOOP
        FETCH cur_customers INTO v_customer_id, v_old_grade, v_joined_at;
        IF v_done THEN
            LEAVE read_loop;                                -- ③ 다 읽었으면 탈출
        END IF;

        IF v_joined_at >= p_base_date - INTERVAL 1 MONTH THEN
            SET p_skipped = p_skipped + 1;
            ITERATE read_loop;                              -- ④ 신규 고객은 건너뛰고 다음 회차
        END IF;

        SELECT COALESCE(SUM(t.amount), 0) INTO v_spend
        FROM (
            SELECT SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS amount
            FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
            WHERE o.customer_id = v_customer_id AND o.status = '배달완료'
              AND o.ordered_at >= p_base_date - INTERVAL 3 MONTH AND o.ordered_at < p_base_date
            GROUP BY o.order_id
        ) t;

        SET v_new_grade = CASE
            WHEN v_spend >= 600000 THEN 'VIP'
            WHEN v_spend >= 400000 THEN '골드'
            WHEN v_spend >= 200000 THEN '실버'
            ELSE '일반'
        END;

        IF v_new_grade <> v_old_grade THEN
            UPDATE customers SET grade = v_new_grade WHERE customer_id = v_customer_id;
            SET p_changed = p_changed + 1;
        END IF;
    END LOOP read_loop;

    CLOSE cur_customers;
END $$
DELIMITER ;

CALL sp_recalc_grades('2026-07-01', @changed, @skipped);
SELECT @changed AS changed, @skipped AS skipped_new_customers;

SELECT grade, COUNT(*) AS customers
FROM customers
GROUP BY grade
ORDER BY FIELD(grade, 'VIP', '골드', '실버', '일반');


-- -------------------------------------------------------------
-- 5-1. 처리하지 않으면: 트랜잭션이 열린 채 멈춘다
-- -------------------------------------------------------------
CREATE TABLE error_logs (
    log_id        INT           NOT NULL AUTO_INCREMENT,
    proc_name     VARCHAR(64)   NOT NULL,
    error_code    INT           NOT NULL,
    error_message VARCHAR(500)  NOT NULL,
    params        VARCHAR(200)      NULL,
    logged_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_error_logs PRIMARY KEY (log_id)
) COMMENT '프로시저 실패 기록';

DELIMITER $$
CREATE PROCEDURE sp_order_naive(IN p_customer_id INT, IN p_restaurant_id INT, IN p_menu_id INT)
BEGIN
    START TRANSACTION;
    INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', '카드', 0, '2026-06-30 19:00:00');
    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (LAST_INSERT_ID(), p_menu_id, 1, 1000);
    COMMIT;
END $$
DELIMITER ;

-- ⚠ 에러 예제
CALL sp_order_naive(2, 1, 999);

SELECT COUNT(*) AS orders_in_open_tx FROM orders;

ROLLBACK;
SELECT COUNT(*) AS orders_after_rollback FROM orders;


-- -------------------------------------------------------------
-- 5-3. EXIT HANDLER + ROLLBACK + RESIGNAL — 되돌리고 다시 던진다
-- -------------------------------------------------------------
DROP PROCEDURE sp_order_naive;

DELIMITER $$
CREATE PROCEDURE sp_order_safe(IN p_customer_id INT, IN p_restaurant_id INT, IN p_menu_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', '카드', 0, '2026-06-30 19:00:00');
    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (LAST_INSERT_ID(), p_menu_id, 1, 1000);
    COMMIT;
END $$
DELIMITER ;

-- ⚠ 에러 예제
CALL sp_order_safe(2, 1, 999);

SELECT COUNT(*) AS orders_total FROM orders;


-- -------------------------------------------------------------
-- 6. 종합 — 주문 접수 프로시저
-- -------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_place_order(
    IN  p_customer_id        INT,
    IN  p_restaurant_id      INT,
    IN  p_menu_id            INT,
    IN  p_quantity           INT,
    IN  p_customer_coupon_id INT,        -- 쿠폰 없으면 NULL
    IN  p_payment_method     VARCHAR(10),
    IN  p_ordered_at         DATETIME,   -- NULL이면 지금
    OUT p_order_id           INT,
    OUT p_result             VARCHAR(200)
)
BEGIN
    DECLARE v_price       INT;
    DECLARE v_sold_out    BOOLEAN;
    DECLARE v_is_open     BOOLEAN;
    DECLARE v_min_order   INT;
    DECLARE v_fee         INT;
    DECLARE v_food        INT;
    DECLARE v_coupon_id   INT;
    DECLARE v_discount    INT DEFAULT 0;
    DECLARE v_code        INT;
    DECLARE v_msg         VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_code = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO error_logs (proc_name, error_code, error_message, params)
        VALUES ('sp_place_order', v_code, v_msg,
                CONCAT_WS(',', p_customer_id, p_restaurant_id, p_menu_id, p_quantity, p_customer_coupon_id));
        SET p_order_id = NULL;
        SET p_result = CONCAT('실패: ', v_msg);
    END;

    SET p_ordered_at = COALESCE(p_ordered_at, NOW());

    -- ① 검증: 가게
    SELECT is_open, min_order_amount, delivery_fee INTO v_is_open, v_min_order, v_fee
    FROM restaurants WHERE restaurant_id = p_restaurant_id;
    IF v_is_open IS NULL OR NOT v_is_open THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '주문할 수 없는 가게입니다.', MYSQL_ERRNO = 5001;
    END IF;

    -- ② 검증: 메뉴 (그 가게의 메뉴인지, 품절인지)
    SELECT price, is_sold_out INTO v_price, v_sold_out
    FROM menus WHERE menu_id = p_menu_id AND restaurant_id = p_restaurant_id;
    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이 가게의 메뉴가 아닙니다.', MYSQL_ERRNO = 5002;
    ELSEIF v_sold_out THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '품절된 메뉴입니다.', MYSQL_ERRNO = 5003;
    END IF;

    -- ③ 검증: 최소 주문 금액
    SET v_food = v_price * p_quantity;
    IF v_food < v_min_order THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '최소 주문 금액에 못 미칩니다.', MYSQL_ERRNO = 5004;
    END IF;

    -- ④ 쿠폰 할인액 (3-2절 프로시저 재사용)
    IF p_customer_coupon_id IS NOT NULL THEN
        SELECT coupon_id INTO v_coupon_id FROM customer_coupons
        WHERE customer_coupon_id = p_customer_coupon_id AND customer_id = p_customer_id;
        IF v_coupon_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '고객의 쿠폰이 아닙니다.', MYSQL_ERRNO = 5005;
        END IF;
        CALL sp_calc_discount(v_coupon_id, v_food, v_discount);
    END IF;

    -- ⑤ 트랜잭션: 주문 머리 → 주문 상세 → 쿠폰 사용
    START TRANSACTION;

    INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                        delivery_fee, discount_amount, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', p_payment_method, v_fee, v_discount, p_ordered_at);
    SET p_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (p_order_id, p_menu_id, p_quantity, v_price);

    IF p_customer_coupon_id IS NOT NULL THEN
        UPDATE customer_coupons SET used_order_id = p_order_id
        WHERE customer_coupon_id = p_customer_coupon_id
          AND used_order_id IS NULL AND expires_at > p_ordered_at;
        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 사용했거나 만료된 쿠폰입니다.', MYSQL_ERRNO = 5006;
        END IF;
    END IF;

    COMMIT;
    SET p_result = CONCAT('성공: 결제 금액 ', FORMAT(v_food + v_fee - v_discount, 0), '원');
END $$
DELIMITER ;


-- -------------------------------------------------------------
-- 6-1. 성공
-- -------------------------------------------------------------
CALL sp_place_order(1, 1, 1, 3, 4, '간편결제', '2026-06-30 19:05:00', @order_id, @result);
SELECT @order_id AS order_id, @result AS result;

SELECT o.order_id, o.delivery_fee, o.discount_amount, oi.menu_id, oi.quantity, oi.unit_price,
    cc.used_order_id AS coupon_used_by
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN customer_coupons cc ON cc.used_order_id = o.order_id
WHERE o.order_id = @order_id;


-- -------------------------------------------------------------
-- 6-2. 실패 세 가지
-- -------------------------------------------------------------
CALL sp_place_order(1, 1, 1, 2, 4, '카드', '2026-06-30 19:20:00', @o1, @r1);   -- 같은 쿠폰 또 사용
CALL sp_place_order(4, 5, 24, 1, NULL, '카드', '2026-06-30 19:21:00', @o2, @r2); -- 품절 메뉴
CALL sp_place_order(7, 12, 59, 1, NULL, '카드', '2026-06-30 19:22:00', @o3, @r3); -- 최소 주문 금액 미달
SELECT @o1 AS order_1, @r1 AS result_1;

SELECT @r2 AS result_2, @r3 AS result_3;

SELECT log_id, proc_name, error_code, error_message, params FROM error_logs ORDER BY log_id;

SELECT COUNT(*) AS orders_total,
    (SELECT COUNT(*) FROM orders WHERE ordered_at >= '2026-06-30 19:20:00') AS failed_orders_left
FROM orders;


-- -------------------------------------------------------------
-- 7-1. 함수는 SELECT 안에서 쓴다
-- -------------------------------------------------------------
-- ⚠ 에러 예제
DELIMITER $$
CREATE FUNCTION fn_order_total(p_order_id INT)
RETURNS INT
BEGIN
    RETURN (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = p_order_id)
         + (SELECT delivery_fee - discount_amount FROM orders WHERE order_id = p_order_id);
END $$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION fn_order_total(p_order_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = p_order_id)
         + (SELECT delivery_fee - discount_amount FROM orders WHERE order_id = p_order_id);
END $$

CREATE FUNCTION fn_grade_by_amount(p_amount INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    RETURN CASE
        WHEN p_amount >= 600000 THEN 'VIP'
        WHEN p_amount >= 400000 THEN '골드'
        WHEN p_amount >= 200000 THEN '실버'
        ELSE '일반'
    END;
END $$
DELIMITER ;

SELECT order_id, status, fn_order_total(order_id) AS total
FROM orders
WHERE ordered_at >= '2026-06-30 18:00:00'
ORDER BY order_id;


-- -------------------------------------------------------------
-- 7-2. 함수로 집합 단위 처리
-- -------------------------------------------------------------
SELECT c.name, c.grade, t.spend_3m, fn_grade_by_amount(t.spend_3m) AS by_function
FROM customers c
JOIN (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS spend_3m
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료' AND o.ordered_at >= '2026-04-01' AND o.ordered_at < '2026-07-01'
    GROUP BY o.customer_id
) t ON c.customer_id = t.customer_id
ORDER BY t.spend_3m DESC;


-- -------------------------------------------------------------
-- 9. 관리와 권한
-- -------------------------------------------------------------
SELECT routine_name AS routine_name, routine_type AS routine_type, sql_data_access AS data_access
FROM information_schema.routines
WHERE routine_schema = DATABASE()
ORDER BY routine_type DESC, routine_name;


-- -------------------------------------------------------------
-- 9-1. EXECUTE 권한 — 테이블 대신 프로시저를 열어 준다
-- -------------------------------------------------------------
DROP USER IF EXISTS 'hanip_app'@'localhost';
CREATE USER 'hanip_app'@'localhost' IDENTIFIED BY 'App!2026';
GRANT EXECUTE ON PROCEDURE hanip_delivery12.sp_place_order TO 'hanip_app'@'localhost';

SHOW GRANTS FOR 'hanip_app'@'localhost';

