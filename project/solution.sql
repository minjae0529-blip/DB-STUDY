-- =============================================================================
--  종합 프로젝트 "단골 리워드" — 강사용 예시 답안
--  전제: project/setup.sql 실행 완료 (hanip_delivery11)
--  ⚠ 학생 과제 마감 후 공개를 권장합니다. 정답은 하나가 아닙니다 — 설계 근거를 평가하세요.
-- =============================================================================
USE hanip_delivery11;

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
-- ④ 트랜잭션: 김민준 님(1번)이 1,000포인트를 쓰고 주문 (잔액이 모자라면 0행 → ROLLBACK)
-- -----------------------------------------------------------------------------
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, discount_amount, ordered_at)
VALUES (1, 1, '접수', '간편결제', 2500, 1000, '2026-06-30 19:10:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 2, price FROM menus WHERE menu_id = 1;

INSERT INTO point_ledger (customer_id, order_id, entry_type, points, created_at)
SELECT 1, @order_id, '사용', -1000, '2026-06-30 19:10:00'
FROM DUAL
WHERE (SELECT COALESCE(SUM(points), 0) FROM point_ledger WHERE customer_id = 1) >= 1000;

SELECT ROW_COUNT() AS point_rows;   -- 1이면 COMMIT, 0이면 ROLLBACK
COMMIT;

-- -----------------------------------------------------------------------------
-- ⑤ 분석 쿼리 예시
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

-- ⑥ 권한: CS팀은 잔액 뷰만 조회
DROP ROLE IF EXISTS 'hanip_reward_cs';
CREATE ROLE 'hanip_reward_cs';
GRANT SELECT ON hanip_delivery11.v_point_balances TO 'hanip_reward_cs';
SHOW GRANTS FOR 'hanip_reward_cs';
