-- =============================================================
--  Ch07. 테이블 설계와 제약조건 (DDL) — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery07)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery07;


-- -------------------------------------------------------------
-- 2-2. ⚠️ 돈에는 FLOAT를 쓰지 않는다
-- -------------------------------------------------------------
SELECT 0.1E0 + 0.2E0 AS float_sum,
    0.1 + 0.2 AS decimal_sum,
    (0.1E0 + 0.2E0 = 0.3E0) AS float_equal;


-- -------------------------------------------------------------
-- 2-3. 범위와 길이를 넘으면 — 에러가 우리를 지킨다
-- -------------------------------------------------------------
DROP TABLE IF EXISTS type_test;
CREATE TABLE type_test (
    score TINYINT,
    nickname VARCHAR(5)
);

-- ⚠ 에러 예제
INSERT INTO type_test (score, nickname) VALUES (300, '준일');

-- ⚠ 에러 예제
INSERT INTO type_test (score, nickname) VALUES (5, '부산광역시진구');

DROP TABLE type_test;


-- -------------------------------------------------------------
-- 3. CREATE TABLE — 규칙 없는 테이블의 최후
-- -------------------------------------------------------------
DROP TABLE IF EXISTS coupons_draft;
CREATE TABLE coupons_draft (
    coupon_id INT,
    code VARCHAR(20),
    name VARCHAR(50),
    discount_amount INT
);

INSERT INTO coupons_draft (coupon_id, code, name, discount_amount) VALUES
    (1, 'WELCOME3000', '첫 주문 3,000원 할인', 3000),
    (1, 'WELCOME3000', NULL, -5000),
    (NULL, NULL, '이름만 있는 쿠폰', NULL);

SELECT * FROM coupons_draft;

DROP TABLE coupons_draft;


-- -------------------------------------------------------------
-- 4-2. 쿠폰 종류 테이블
-- -------------------------------------------------------------
CREATE TABLE coupons (
    coupon_id        INT          NOT NULL AUTO_INCREMENT,
    code             VARCHAR(20)  NOT NULL,
    name             VARCHAR(50)  NOT NULL,
    discount_type    VARCHAR(10)  NOT NULL,
    discount_value   INT          NOT NULL,
    min_order_amount INT          NOT NULL DEFAULT 0,
    valid_days       INT          NOT NULL DEFAULT 30,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
    CONSTRAINT uq_coupons_code UNIQUE (code),
    CONSTRAINT ck_coupons_type CHECK (discount_type IN ('정액', '정률')),
    CONSTRAINT ck_coupons_value CHECK (
        (discount_type = '정액' AND discount_value > 0)
        OR (discount_type = '정률' AND discount_value BETWEEN 1 AND 50)
    ),
    CONSTRAINT ck_coupons_min CHECK (min_order_amount >= 0),
    CONSTRAINT ck_coupons_days CHECK (valid_days > 0)
);

INSERT INTO coupons (code, name, discount_type, discount_value, min_order_amount, valid_days) VALUES
    ('WELCOME3000', '첫 주문 3,000원 할인', '정액', 3000, 15000, 30),
    ('WEEKEND15',   '주말 15% 할인',         '정률', 15,   20000, 7),
    ('VIP5000',     'VIP 5,000원 할인',      '정액', 5000, 25000, 60);

SELECT coupon_id, code, name, discount_type, discount_value, min_order_amount, valid_days, is_active
FROM coupons;


-- -------------------------------------------------------------
-- 4-3. 규칙이 사고를 막는 장면
-- -------------------------------------------------------------
-- ⚠ 에러 예제
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('WELCOME3000', '중복 코드 쿠폰', '정액', 1000);

-- ⚠ 에러 예제
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('NONAME', NULL, '정액', 1000);

-- ⚠ 에러 예제
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('MINUS', '마이너스 쿠폰', '정액', -5000);

-- ⚠ 에러 예제
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('FREE', '전액 무료', '정률', 100);


-- -------------------------------------------------------------
-- 5-1. 고객 보유 쿠폰 테이블 (M : N 연결)
-- -------------------------------------------------------------
CREATE TABLE customer_coupons (
    customer_coupon_id INT       NOT NULL AUTO_INCREMENT,
    customer_id        INT       NOT NULL,
    coupon_id          INT       NOT NULL,
    issued_at          DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at         DATETIME  NOT NULL,
    used_order_id      INT           NULL,
    CONSTRAINT pk_customer_coupons PRIMARY KEY (customer_coupon_id),
    CONSTRAINT fk_cc_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_cc_coupon   FOREIGN KEY (coupon_id)   REFERENCES coupons (coupon_id),
    CONSTRAINT fk_cc_order    FOREIGN KEY (used_order_id) REFERENCES orders (order_id),
    CONSTRAINT uq_cc_customer_coupon UNIQUE (customer_id, coupon_id),
    CONSTRAINT uq_cc_used_order UNIQUE (used_order_id),
    CONSTRAINT ck_cc_period CHECK (expires_at > issued_at)
);

INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at) VALUES
    (30, 1, '2026-06-28 16:30:00', '2026-07-28 16:30:00'),   -- 신규 가입 윤서아 → 첫 주문 쿠폰
    (1,  3, '2026-06-30 09:00:00', '2026-08-29 09:00:00'),   -- VIP 김민준
    (2,  3, '2026-06-30 09:00:00', '2026-08-29 09:00:00');   -- VIP 이서연

SELECT c.name AS customer_name,
    cp.name AS coupon_name,
    cc.issued_at,
    cc.expires_at,
    cc.used_order_id
FROM customer_coupons cc
JOIN customers c ON cc.customer_id = c.customer_id
JOIN coupons cp  ON cc.coupon_id   = cp.coupon_id
ORDER BY cc.customer_coupon_id;


-- -------------------------------------------------------------
-- 5-2. FK가 막는 것 ① — 없는 대상을 가리키기 (1452)
-- -------------------------------------------------------------
-- ⚠ 에러 예제
INSERT INTO customer_coupons (customer_id, coupon_id, expires_at)
VALUES (999, 1, '2026-12-31 00:00:00');


-- -------------------------------------------------------------
-- 5-3. 두 열 UNIQUE — 같은 쿠폰 두 번 지급 (1062)
-- -------------------------------------------------------------
-- ⚠ 에러 예제
INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
VALUES (1, 3, '2026-06-30 10:00:00', '2026-08-29 10:00:00');


-- -------------------------------------------------------------
-- 5-4. FK가 막는 것 ② — 참조되고 있는 부모 지우기 (1451)
-- -------------------------------------------------------------
-- ⚠ 에러 예제
DELETE FROM coupons WHERE coupon_id = 3;


-- -------------------------------------------------------------
-- 6. ALTER TABLE — 운영 중인 테이블 고치기
-- -------------------------------------------------------------
ALTER TABLE coupons
    ADD COLUMN max_discount INT NULL AFTER discount_value;

ALTER TABLE coupons
    ADD CONSTRAINT ck_coupons_max CHECK (max_discount IS NULL OR max_discount > 0);

UPDATE coupons SET max_discount = 5000 WHERE code = 'WEEKEND15';

SELECT code, discount_type, discount_value, max_discount FROM coupons;


-- -------------------------------------------------------------
-- 제약조건 확인하기
-- -------------------------------------------------------------
SELECT constraint_name AS constraint_name,
    constraint_type AS constraint_type
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
    AND table_name = 'customer_coupons'
ORDER BY constraint_type, constraint_name;


-- -------------------------------------------------------------
-- 7. DROP · TRUNCATE · DELETE
-- -------------------------------------------------------------
-- ⚠ 에러 예제
DROP TABLE coupons;

