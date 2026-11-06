-- =============================================================================
--  종합 프로젝트 "단골 리워드" — 강사용 예시 답안
--  전제: project/setup.sql 실행 완료 (hanip_delivery13)
--  ⚠ 학생 과제 마감 후 공개를 권장합니다. 정답은 하나가 아닙니다 — 설계 근거를 평가하세요.
-- =============================================================================
USE hanip_delivery13;

-- -----------------------------------------------------------------------------
-- ① DDL
-- -----------------------------------------------------------------------------
CREATE TABLE reward_policies (
    grade         VARCHAR(10)  NOT NULL                 COMMENT '고객 등급',
    earn_percent  TINYINT      NOT NULL                 COMMENT '적립률(%)',
    CONSTRAINT pk_reward_policies       PRIMARY KEY (grade),
    CONSTRAINT ck_reward_policies_grade CHECK (grade IN ('일반', '실버', '골드', 'VIP')),
    CONSTRAINT ck_reward_policies_rate  CHECK (earn_percent BETWEEN 0 AND 10)
) COMMENT '등급별 적립 정책';

CREATE TABLE point_ledger (
    ledger_id    INT          NOT NULL AUTO_INCREMENT  COMMENT '원장 번호',
    customer_id  INT          NOT NULL                 COMMENT '고객',
    order_id     INT              NULL                 COMMENT '관련 주문 (조정·소멸은 NULL)',
    entry_type   VARCHAR(10)  NOT NULL                 COMMENT '적립 / 사용 / 소멸 / 조정',
    points       INT          NOT NULL                 COMMENT '+ 적립, - 사용·소멸',
    created_at   DATETIME     NOT NULL                 COMMENT '발생 일시',
    expires_at   DATETIME         NULL                 COMMENT '소멸 예정 일시 (적립만)',
    CONSTRAINT pk_point_ledger          PRIMARY KEY (ledger_id),
    CONSTRAINT fk_point_ledger_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_point_ledger_order    FOREIGN KEY (order_id)    REFERENCES orders (order_id),
    CONSTRAINT uq_point_ledger_order    UNIQUE (order_id, entry_type),          -- 주문당 적립 1번, 사용 1번
    CONSTRAINT ck_point_ledger_type     CHECK (entry_type IN ('적립', '사용', '소멸', '조정')),
    CONSTRAINT ck_point_ledger_sign     CHECK (
        (entry_type = '적립' AND points > 0 AND expires_at IS NOT NULL)
        OR (entry_type IN ('사용', '소멸') AND points < 0 AND expires_at IS NULL)
        OR (entry_type = '조정' AND points <> 0))
) COMMENT '포인트 원장 — 잔액은 저장하지 않고 SUM으로 계산';

-- -----------------------------------------------------------------------------
-- ② 데이터: 정책 + 2026년 배달완료 주문 적립 (적립률은 현재 등급 기준, 유효기간 6개월)
-- -----------------------------------------------------------------------------
INSERT INTO reward_policies (grade, earn_percent) VALUES
    ('일반', 1), ('실버', 2), ('골드', 3), ('VIP', 5);

INSERT INTO point_ledger (customer_id, order_id, entry_type, points, created_at, expires_at)
SELECT o.customer_id, o.order_id, '적립',
    FLOOR((SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount) * p.earn_percent / 100),
    o.delivered_at, o.delivered_at + INTERVAL 6 MONTH
FROM orders o
JOIN order_items oi    ON o.order_id    = oi.order_id
JOIN customers c       ON o.customer_id = c.customer_id
JOIN reward_policies p ON c.grade       = p.grade
WHERE o.status = '배달완료'
GROUP BY o.order_id, o.customer_id, o.delivery_fee, o.discount_amount, o.delivered_at, p.earn_percent;

-- -----------------------------------------------------------------------------
-- ③ 뷰 · 인덱스
-- -----------------------------------------------------------------------------
CREATE VIEW v_point_balances AS
SELECT c.customer_id, c.name, c.grade,
    COALESCE(SUM(l.points), 0) AS balance,
    COALESCE(SUM(CASE WHEN l.entry_type = '적립' THEN l.points END), 0) AS total_earned,
    COALESCE(-SUM(CASE WHEN l.entry_type = '사용' THEN l.points END), 0) AS total_used
FROM customers c
LEFT JOIN point_ledger l ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.name, c.grade;

CREATE INDEX idx_point_ledger_customer_date ON point_ledger (customer_id, created_at);
CREATE INDEX idx_point_ledger_expires       ON point_ledger (expires_at);

-- -----------------------------------------------------------------------------
-- ④ 자동화 1 — 트리거: 주문이 '배달완료'로 바뀌는 순간 자동 적립 (Ch11)
-- -----------------------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_orders_earn_points
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE v_amount INT;
    DECLARE v_percent INT;

    IF NEW.status = '배달완료' AND OLD.status <> '배달완료' THEN
        SELECT SUM(quantity * unit_price) + NEW.delivery_fee - NEW.discount_amount INTO v_amount
        FROM order_items WHERE order_id = NEW.order_id;

        SELECT p.earn_percent INTO v_percent
        FROM customers c JOIN reward_policies p ON c.grade = p.grade
        WHERE c.customer_id = NEW.customer_id;

        IF FLOOR(v_amount * v_percent / 100) > 0 THEN
            INSERT INTO point_ledger (customer_id, order_id, entry_type, points, created_at, expires_at)
            VALUES (NEW.customer_id, NEW.order_id, '적립', FLOOR(v_amount * v_percent / 100),
                    COALESCE(NEW.delivered_at, NOW()), COALESCE(NEW.delivered_at, NOW()) + INTERVAL 6 MONTH);
        END IF;
    END IF;
END $$
DELIMITER ;

-- 확인: 배달중인 561번 주문(김민준, VIP 5%) 완료 → 적립 1행
UPDATE orders SET status = '배달완료', delivered_at = '2026-06-30 18:55:00' WHERE order_id = 561;
SELECT order_id, entry_type, points FROM point_ledger WHERE order_id = 561;

-- -----------------------------------------------------------------------------
-- ⑤ 자동화 2 — 프로시저: 포인트 사용 주문 (Ch12: 검증 · 트랜잭션 · 예외 처리 · 실패 기록)
-- -----------------------------------------------------------------------------
CREATE TABLE error_logs (
    log_id        INT           NOT NULL AUTO_INCREMENT,
    proc_name     VARCHAR(64)   NOT NULL,
    error_code    INT           NOT NULL,
    error_message VARCHAR(500)  NOT NULL,
    logged_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_error_logs PRIMARY KEY (log_id)
);

DELIMITER $$
CREATE PROCEDURE sp_order_with_points(
    IN  p_customer_id   INT,
    IN  p_restaurant_id INT,
    IN  p_menu_id       INT,
    IN  p_quantity      INT,
    IN  p_use_points    INT,
    IN  p_ordered_at    DATETIME,
    OUT p_order_id      INT,
    OUT p_result        VARCHAR(200)
)
BEGIN
    DECLARE v_price   INT;
    DECLARE v_fee     INT;
    DECLARE v_balance INT;
    DECLARE v_code    INT;
    DECLARE v_msg     VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_code = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO error_logs (proc_name, error_code, error_message)
        VALUES ('sp_order_with_points', v_code, v_msg);
        SET p_order_id = NULL;
        SET p_result = CONCAT('실패: ', v_msg);
    END;

    SELECT m.price, r.delivery_fee INTO v_price, v_fee
    FROM menus m JOIN restaurants r ON m.restaurant_id = r.restaurant_id
    WHERE m.menu_id = p_menu_id AND m.restaurant_id = p_restaurant_id AND NOT m.is_sold_out AND r.is_open;
    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '주문할 수 없는 메뉴입니다.', MYSQL_ERRNO = 6001;
    END IF;
    IF p_use_points > v_price * p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '음식값보다 많은 포인트는 쓸 수 없습니다.', MYSQL_ERRNO = 6002;
    END IF;

    START TRANSACTION;

    -- 잔액 확인: 이 고객의 원장 행을 잠가 동시에 두 주문이 같은 포인트를 쓰지 못하게
    SELECT COALESCE(SUM(points), 0) INTO v_balance
    FROM point_ledger WHERE customer_id = p_customer_id
    FOR UPDATE;
    IF v_balance < p_use_points THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '포인트 잔액이 부족합니다.', MYSQL_ERRNO = 6003;
    END IF;

    INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, discount_amount, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', '간편결제', v_fee, p_use_points, p_ordered_at);
    SET p_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (p_order_id, p_menu_id, p_quantity, v_price);

    IF p_use_points > 0 THEN
        INSERT INTO point_ledger (customer_id, order_id, entry_type, points, created_at)
        VALUES (p_customer_id, p_order_id, '사용', -p_use_points, p_ordered_at);
    END IF;

    COMMIT;
    SET p_result = CONCAT('성공: 포인트 ', p_use_points, '점 사용');
END $$
DELIMITER ;

-- 성공: 김민준 님 1,000포인트 사용 / 실패: 윤서아 님(적립 0) 1,000포인트 사용 시도
CALL sp_order_with_points(1, 1, 1, 2, 1000, '2026-06-30 19:10:00', @o1, @r1);
CALL sp_order_with_points(30, 1, 1, 2, 1000, '2026-06-30 19:12:00', @o2, @r2);
SELECT @o1, @r1, @o2, @r2, (SELECT COUNT(*) FROM error_logs) AS errors;

-- 앱 계정은 프로시저 실행 권한만
DROP USER IF EXISTS 'hanip_reward_app'@'localhost';
CREATE USER 'hanip_reward_app'@'localhost' IDENTIFIED BY 'Reward!2026';
GRANT EXECUTE ON PROCEDURE hanip_delivery13.sp_order_with_points TO 'hanip_reward_app'@'localhost';

-- -----------------------------------------------------------------------------
-- ⑥ 분석 쿼리 예시
-- -----------------------------------------------------------------------------
-- Q1. 포인트 잔액 상위 5명
SELECT name, grade, balance, total_earned, total_used
FROM v_point_balances
ORDER BY balance DESC
LIMIT 5;

-- Q2. 월별 적립 포인트와 적립 건수
SELECT DATE_FORMAT(created_at, '%Y-%m') AS ym, COUNT(*) AS entries, SUM(points) AS earned
FROM point_ledger
WHERE entry_type = '적립'
GROUP BY ym
ORDER BY ym;

-- Q3. 7월에 소멸 예정인 포인트가 있는 고객 (알림 대상)
SELECT c.name, SUM(l.points) AS expiring_points, MIN(l.expires_at) AS first_expiry
FROM point_ledger l
JOIN customers c ON l.customer_id = c.customer_id
WHERE l.entry_type = '적립'
  AND l.expires_at >= '2026-07-01' AND l.expires_at < '2026-08-01'
GROUP BY c.customer_id, c.name
ORDER BY expiring_points DESC
LIMIT 5;

-- Q4. 등급별 평균 잔액 (등급 정책의 효과)
SELECT grade, COUNT(*) AS customers, ROUND(AVG(balance)) AS avg_balance
FROM v_point_balances
GROUP BY grade
ORDER BY avg_balance DESC;

-- Q5. 포인트가 한 번도 적립되지 않은 고객 (첫 주문 유도 대상)
SELECT customer_id, name, grade
FROM v_point_balances
WHERE total_earned = 0
ORDER BY customer_id;

-- ⑦ 권한: CS팀은 잔액 뷰만 조회
DROP ROLE IF EXISTS 'hanip_reward_cs';
CREATE ROLE 'hanip_reward_cs';
GRANT SELECT ON hanip_delivery13.v_point_balances TO 'hanip_reward_cs';
SHOW GRANTS FOR 'hanip_reward_cs';
