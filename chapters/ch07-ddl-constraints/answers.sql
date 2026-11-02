-- Ch07 실습 — 테이블 설계하고 만들기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery07)
USE hanip_delivery07;

-- 문제 1. NULL을 허용하는 열 ★
SELECT column_name AS column_name,
    data_type AS data_type
FROM information_schema.columns
WHERE table_schema = DATABASE()
    AND table_name = 'orders'
    AND is_nullable = 'YES'
ORDER BY ordinal_position;

-- 문제 2. CHECK 제약조건 읽기 ★
SELECT constraint_name AS constraint_name
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
    AND table_name = 'orders'
    AND constraint_type = 'CHECK'
ORDER BY constraint_name;

-- 문제 4. 공지사항 테이블 ★★
CREATE TABLE notices (
    notice_id    INT          NOT NULL AUTO_INCREMENT,
    title        VARCHAR(100) NOT NULL,
    content      TEXT         NOT NULL,
    is_pinned    BOOLEAN      NOT NULL DEFAULT FALSE,
    published_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_notices PRIMARY KEY (notice_id)
);

INSERT INTO notices (title, content, is_pinned) VALUES
    ('7월 정산일 안내', '7월 정산은 10일에 진행됩니다.', TRUE);
INSERT INTO notices (title, content) VALUES
    ('배달팁 정책 변경', '8월부터 5만 원 이상 무료 배달 기준이 4만 원으로 바뀝니다.');

SELECT notice_id, title, is_pinned
FROM notices
ORDER BY notice_id;

-- 문제 5. 휴무일 테이블 ★★
CREATE TABLE restaurant_holidays (
    holiday_id    INT         NOT NULL AUTO_INCREMENT,
    restaurant_id INT         NOT NULL,
    holiday_date  DATE        NOT NULL,
    reason        VARCHAR(50)     NULL,
    CONSTRAINT pk_restaurant_holidays PRIMARY KEY (holiday_id),
    CONSTRAINT fk_holidays_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
    CONSTRAINT uq_holidays_date UNIQUE (restaurant_id, holiday_date)
);

INSERT INTO restaurant_holidays (restaurant_id, holiday_date, reason) VALUES
    (1, '2026-07-15', '내부 수리'),
    (6, '2026-07-15', NULL),
    (1, '2026-07-16', '내부 수리');

SELECT h.holiday_date,
    r.name AS restaurant_name,
    h.reason
FROM restaurant_holidays h
JOIN restaurants r ON h.restaurant_id = r.restaurant_id
ORDER BY h.holiday_date, r.restaurant_id;

-- 문제 7. 메뉴 옵션 테이블 ★★★
CREATE TABLE menu_options (
    option_id    INT         NOT NULL AUTO_INCREMENT,
    menu_id      INT         NOT NULL,
    name         VARCHAR(30) NOT NULL,
    extra_price  INT         NOT NULL DEFAULT 0,
    CONSTRAINT pk_menu_options PRIMARY KEY (option_id),
    CONSTRAINT fk_options_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id) ON DELETE CASCADE,
    CONSTRAINT uq_options_name UNIQUE (menu_id, name),
    CONSTRAINT ck_options_price CHECK (extra_price >= 0)
);

INSERT INTO menu_options (menu_id, name, extra_price) VALUES
    (35, '곱빼기', 1000),
    (35, '계란 프라이', 1500),
    (35, '면 추가 없음', 0);

SELECT m.name AS menu_name,
    mo.name AS option_name,
    m.price + mo.extra_price AS price_with_option
FROM menu_options mo
JOIN menus m ON mo.menu_id = m.menu_id
ORDER BY price_with_option, mo.option_id;

-- 문제 8. 기사 월 정산 테이블 ★★★
CREATE TABLE rider_settlements (
    settlement_id   INT       NOT NULL AUTO_INCREMENT,
    rider_id        INT       NOT NULL,
    settle_month    CHAR(7)   NOT NULL,
    delivery_count  INT       NOT NULL DEFAULT 0,
    amount          INT       NOT NULL DEFAULT 0,
    is_paid         BOOLEAN   NOT NULL DEFAULT FALSE,
    paid_at         DATETIME      NULL,
    CONSTRAINT pk_rider_settlements PRIMARY KEY (settlement_id),
    CONSTRAINT fk_settlements_rider FOREIGN KEY (rider_id) REFERENCES riders (rider_id),
    CONSTRAINT uq_settlements_month UNIQUE (rider_id, settle_month),
    CONSTRAINT ck_settlements_month CHECK (settle_month REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_settlements_count CHECK (delivery_count >= 0),
    CONSTRAINT ck_settlements_amount CHECK (amount >= 0),
    CONSTRAINT ck_settlements_paid CHECK (
        (is_paid = TRUE AND paid_at IS NOT NULL)
        OR (is_paid = FALSE AND paid_at IS NULL))
);

SELECT constraint_name AS constraint_name,
    constraint_type AS constraint_type
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
    AND table_name = 'rider_settlements'
ORDER BY constraint_type, constraint_name;
