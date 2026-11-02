-- =============================================================================
--  한입배달 — 표준 스키마 (원본 템플릿)
--  MySQL 8.0 이상 | 문자셋 utf8mb4
--
--  ※ 이 파일은 직접 실행하지 않습니다.
--    수업에서는 각 챕터 폴더의 setup.sql 을 실행하세요.
--    setup.sql = CREATE DATABASE hanip_deliveryNN + 이 파일(테이블) + seed.sql(데이터)
--    (tools/build.py 가 자동으로 합쳐 만듭니다)
--
--  관계 요약 (1:N)
--   customers   1 ── N orders        고객 한 명은 여러 번 주문한다
--   restaurants 1 ── N orders        가게 하나는 여러 주문을 받는다
--   riders      1 ── N orders        기사 한 명은 여러 건을 배달한다 (미배정 = NULL)
--   restaurants 1 ── N menus         가게 하나는 여러 메뉴를 판다
--   orders      1 ── N order_items   주문 1건에 메뉴 여러 줄
--   menus       1 ── N order_items   메뉴 하나는 여러 주문에 담긴다
--   orders      1 ── 0..1 reviews    배달 완료 주문 1건당 리뷰는 최대 1개
--
--  명명 규칙
--   · 테이블명: 복수형 snake_case        (customers, order_items)
--   · PK      : <단수형>_id               (customer_id, order_id)
--   · FK      : 참조하는 PK와 같은 이름   (orders.customer_id → customers.customer_id)
--   · 시각    : *_at (DATETIME) / 날짜: *_date 또는 opened_at 처럼 의미가 드러나게
--   · 여부    : is_* (BOOLEAN)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. customers : 고객
-- -----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id       INT           NOT NULL AUTO_INCREMENT  COMMENT '고객 번호',
    name              VARCHAR(20)   NOT NULL                 COMMENT '이름',
    phone             CHAR(13)      NOT NULL                 COMMENT '휴대전화 (010-0000-0000)',
    email             VARCHAR(100)      NULL                 COMMENT '이메일 (선택)',
    birth_date        DATE              NULL                 COMMENT '생년월일 (선택)',
    district          VARCHAR(10)   NOT NULL                 COMMENT '거주 구 (예: 부산진구)',
    address           VARCHAR(100)  NOT NULL                 COMMENT '상세 주소',
    grade             VARCHAR(10)   NOT NULL DEFAULT '일반'   COMMENT '회원 등급',
    marketing_agreed  BOOLEAN       NOT NULL DEFAULT FALSE   COMMENT '마케팅 수신 동의',
    joined_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '가입 일시',
    CONSTRAINT pk_customers        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_phone  UNIQUE (phone),
    CONSTRAINT uq_customers_email  UNIQUE (email),
    CONSTRAINT ck_customers_grade  CHECK (grade IN ('일반', '실버', '골드', 'VIP'))
) COMMENT '고객';

-- -----------------------------------------------------------------------------
-- 2. restaurants : 가게
-- -----------------------------------------------------------------------------
CREATE TABLE restaurants (
    restaurant_id     INT           NOT NULL AUTO_INCREMENT  COMMENT '가게 번호',
    name              VARCHAR(50)   NOT NULL                 COMMENT '상호',
    category          VARCHAR(10)   NOT NULL                 COMMENT '업종',
    district          VARCHAR(10)   NOT NULL                 COMMENT '소재 구',
    address           VARCHAR(100)  NOT NULL                 COMMENT '상세 주소',
    phone             VARCHAR(13)       NULL                 COMMENT '가게 전화 (선택)',
    min_order_amount  INT           NOT NULL DEFAULT 0       COMMENT '최소 주문 금액(원)',
    delivery_fee      INT           NOT NULL DEFAULT 3000    COMMENT '기본 배달팁(원)',
    open_time         TIME          NOT NULL                 COMMENT '영업 시작',
    close_time        TIME          NOT NULL                 COMMENT '영업 종료 (자정 넘기면 다음날 시각)',
    opened_at         DATE          NOT NULL                 COMMENT '입점일',
    is_open           BOOLEAN       NOT NULL DEFAULT TRUE    COMMENT '영업 중 여부 (폐업 시 FALSE)',
    CONSTRAINT pk_restaurants          PRIMARY KEY (restaurant_id),
    CONSTRAINT ck_restaurants_category CHECK (category IN ('한식', '중식', '일식', '양식', '치킨', '피자', '분식', '카페·디저트')),
    CONSTRAINT ck_restaurants_min      CHECK (min_order_amount >= 0),
    CONSTRAINT ck_restaurants_fee      CHECK (delivery_fee >= 0)
) COMMENT '가게';

-- -----------------------------------------------------------------------------
-- 3. menus : 메뉴 (가게 1 : 메뉴 N)
-- -----------------------------------------------------------------------------
CREATE TABLE menus (
    menu_id           INT           NOT NULL AUTO_INCREMENT  COMMENT '메뉴 번호',
    restaurant_id     INT           NOT NULL                 COMMENT '가게 번호',
    name              VARCHAR(50)   NOT NULL                 COMMENT '메뉴명',
    price             INT           NOT NULL                 COMMENT '현재 판매가(원)',
    description       VARCHAR(200)      NULL                 COMMENT '메뉴 설명 (선택)',
    is_signature      BOOLEAN       NOT NULL DEFAULT FALSE   COMMENT '대표 메뉴 여부',
    is_sold_out       BOOLEAN       NOT NULL DEFAULT FALSE   COMMENT '품절 여부',
    CONSTRAINT pk_menus             PRIMARY KEY (menu_id),
    CONSTRAINT fk_menus_restaurant  FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
    CONSTRAINT uq_menus_name        UNIQUE (restaurant_id, name),
    CONSTRAINT ck_menus_price       CHECK (price > 0)
) COMMENT '메뉴';

-- -----------------------------------------------------------------------------
-- 4. riders : 배달 기사
-- -----------------------------------------------------------------------------
CREATE TABLE riders (
    rider_id          INT           NOT NULL AUTO_INCREMENT  COMMENT '기사 번호',
    name              VARCHAR(20)   NOT NULL                 COMMENT '이름',
    phone             CHAR(13)      NOT NULL                 COMMENT '휴대전화',
    vehicle           VARCHAR(10)   NOT NULL                 COMMENT '운송 수단',
    district          VARCHAR(10)   NOT NULL                 COMMENT '주 활동 구',
    hired_at          DATE          NOT NULL                 COMMENT '계약 시작일',
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE    COMMENT '활동 중 여부',
    CONSTRAINT pk_riders          PRIMARY KEY (rider_id),
    CONSTRAINT uq_riders_phone    UNIQUE (phone),
    CONSTRAINT ck_riders_vehicle  CHECK (vehicle IN ('오토바이', '자전거', '도보'))
) COMMENT '배달 기사';

-- -----------------------------------------------------------------------------
-- 5. orders : 주문 (주문서의 "머리" — 누가, 어디서, 언제, 어떻게)
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id          INT           NOT NULL AUTO_INCREMENT  COMMENT '주문 번호',
    customer_id       INT           NOT NULL                 COMMENT '주문 고객',
    restaurant_id     INT           NOT NULL                 COMMENT '주문 가게',
    rider_id          INT               NULL                 COMMENT '배달 기사 (취소·조리중이면 NULL)',
    status            VARCHAR(10)   NOT NULL DEFAULT '접수'   COMMENT '주문 상태',
    payment_method    VARCHAR(10)   NOT NULL                 COMMENT '결제 수단',
    delivery_fee      INT           NOT NULL DEFAULT 0       COMMENT '실제 부과된 배달팁(원)',
    discount_amount   INT           NOT NULL DEFAULT 0       COMMENT '쿠폰 할인액(원)',
    request_note      VARCHAR(100)      NULL                 COMMENT '요청사항 (선택)',
    ordered_at        DATETIME      NOT NULL                 COMMENT '주문 일시',
    delivered_at      DATETIME          NULL                 COMMENT '배달 완료 일시',
    CONSTRAINT pk_orders             PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer    FOREIGN KEY (customer_id)   REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_restaurant  FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
    CONSTRAINT fk_orders_rider       FOREIGN KEY (rider_id)      REFERENCES riders (rider_id),
    CONSTRAINT ck_orders_status      CHECK (status IN ('접수', '조리중', '배달중', '배달완료', '취소')),
    CONSTRAINT ck_orders_payment     CHECK (payment_method IN ('카드', '간편결제', '계좌이체', '현장결제')),
    CONSTRAINT ck_orders_fee         CHECK (delivery_fee >= 0),
    CONSTRAINT ck_orders_discount    CHECK (discount_amount >= 0)
) COMMENT '주문';

-- -----------------------------------------------------------------------------
-- 6. order_items : 주문 상세 (주문서의 "몸통" — 무엇을 몇 개, 얼마에)
--    unit_price 는 "주문 당시 가격"입니다. 메뉴 가격이 나중에 올라도
--    과거 주문 금액은 바뀌면 안 되므로 별도로 저장합니다.
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id     INT           NOT NULL AUTO_INCREMENT  COMMENT '주문 상세 번호',
    order_id          INT           NOT NULL                 COMMENT '주문 번호',
    menu_id           INT           NOT NULL                 COMMENT '메뉴 번호',
    quantity          INT           NOT NULL DEFAULT 1       COMMENT '수량',
    unit_price        INT           NOT NULL                 COMMENT '주문 당시 단가(원)',
    CONSTRAINT pk_order_items        PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_items_order  FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_order_items_menu   FOREIGN KEY (menu_id)  REFERENCES menus (menu_id),
    CONSTRAINT uq_order_items        UNIQUE (order_id, menu_id),
    CONSTRAINT ck_order_items_qty    CHECK (quantity > 0),
    CONSTRAINT ck_order_items_price  CHECK (unit_price > 0)
) COMMENT '주문 상세';

-- -----------------------------------------------------------------------------
-- 7. reviews : 리뷰 (배달 완료된 주문 1건당 최대 1개)
-- -----------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id         INT           NOT NULL AUTO_INCREMENT  COMMENT '리뷰 번호',
    order_id          INT           NOT NULL                 COMMENT '주문 번호',
    rating            TINYINT       NOT NULL                 COMMENT '별점 1~5',
    content           VARCHAR(500)      NULL                 COMMENT '리뷰 내용 (별점만 남기면 NULL)',
    created_at        DATETIME      NOT NULL                 COMMENT '작성 일시',
    CONSTRAINT pk_reviews         PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_order   FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT uq_reviews_order   UNIQUE (order_id),
    CONSTRAINT ck_reviews_rating  CHECK (rating BETWEEN 1 AND 5)
) COMMENT '리뷰';
