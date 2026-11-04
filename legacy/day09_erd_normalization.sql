-- ============================================================
--  한국IT교육센터 부산점 | MySQL 10일 완성 과정
--  Day 9 — 설계의 정석: ERD & 정규화
--  주제 : FK 설계, 참조무결성, 1NF → 2NF → 3NF
--  시나리오 : 배달앱 "한입배달" DB
-- ------------------------------------------------------------
--  [다루는 테이블]
--    기존(Day 1~8): restaurants, customers, menus, orders
--    신규(Day 9)  : riders, reviews, coupons, customer_coupons
--    실습용       : orders_unnormalized
-- ------------------------------------------------------------
--  실행 순서
--    1. 섹션 1 — 현재 구조 검토
--    2. 섹션 2 — FK 추가 (기존 테이블)
--    3. 섹션 3 — 새 테이블 생성
--    4. 섹션 4 — 샘플 데이터 INSERT
--    5. 섹션 5 — 정규화 실습용 비정규 테이블
--    6. 섹션 6 — FK 참조무결성 테스트
--    7. 섹션 7 — 완성된 ERD 구조 확인 쿼리
-- ============================================================

USE hanibbaldal;   -- 한입배달 데이터베이스 선택 (Day 1에서 생성)


-- ════════════════════ 섹션 1: 현재 구조 검토 ════════════════════
-- 지금까지 만든 테이블의 구조를 다시 살펴본다.
-- "건물을 지어왔는데, 설계도가 맞는지 확인하는 것"

-- ──────────────────────────────────────────
-- 1-1. 테이블 목록 확인
-- ──────────────────────────────────────────
SHOW TABLES;
-- 예상 결과: restaurants, customers, menus, orders (Day 1~8에서 생성)

-- ──────────────────────────────────────────
-- 1-2. 각 테이블 구조 확인 (DDL 전체 출력)
--      FK가 있는지, 제약조건은 어떤지 확인하는 방법
-- ──────────────────────────────────────────
SHOW CREATE TABLE restaurants\G
SHOW CREATE TABLE customers\G
SHOW CREATE TABLE menus\G
SHOW CREATE TABLE orders\G
-- \G 는 Workbench에서 사용 시 세로 출력. 터미널 전용.
-- Workbench에서는 그냥 세미콜론으로 실행하면 됨.

-- ──────────────────────────────────────────
-- 1-3. 문제 시연 — FK 없이 고아(orphan) 데이터가 생기는 상황
--      아래 INSERT는 실제로 존재하지 않는 restaurant_id를 참조한다.
--      FK가 없으면 MySQL이 이를 허용한다 → 데이터 무결성 깨짐!
-- ──────────────────────────────────────────

-- 현재는 menus에 restaurant_id 컬럼이 있어도 FK가 없으므로
-- 존재하지 않는 가게 id(999번)를 참조하는 메뉴를 넣을 수 있다.
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (999, '유령메뉴', 10000);
-- 결과: 오류 없이 INSERT 성공 → 999번 가게는 없는데 메뉴가 생긴다 = "고아 데이터"

-- 지금 넣은 고아 데이터를 확인해보자
SELECT *
FROM menus
WHERE restaurant_id = 999;
-- 예상 결과: id=?, restaurant_id=999, menu_name='유령메뉴', price=10000

-- FK 추가 전에 반드시 이런 고아 데이터를 정리해야 한다!
-- 이제 삭제하고 FK를 추가할 준비를 한다.
DELETE FROM menus
WHERE restaurant_id = 999;
-- 결과: 고아 데이터 삭제 완료

-- ──────────────────────────────────────────
-- 1-4. 고아 데이터 현황 점검 쿼리
--      FK 추가 전 반드시 실행해서 무결성을 확인해야 한다.
-- ──────────────────────────────────────────

-- menus 중 실제로 존재하지 않는 가게를 참조하는 항목 찾기
SELECT m.id,
       m.restaurant_id,
       m.menu_name,
       r.id AS actual_restaurant_id
FROM menus m
LEFT JOIN restaurants r ON m.restaurant_id = r.id
WHERE r.id IS NULL;
-- 예상 결과: 빈 테이블 (고아 데이터 없음)
-- 만약 rows가 나오면 DELETE 후 FK 추가해야 함

-- orders 중 존재하지 않는 고객, 가게, 메뉴를 참조하는 항목 찾기
SELECT o.id,
       o.customer_id,
       o.restaurant_id,
       o.menu_id
FROM orders o
LEFT JOIN customers  c  ON o.customer_id  = c.id
LEFT JOIN restaurants r ON o.restaurant_id = r.id
LEFT JOIN menus      m  ON o.menu_id       = m.id
WHERE c.id IS NULL
   OR r.id IS NULL
   OR m.id IS NULL;
-- 예상 결과: 빈 테이블 (모든 FK 컬럼이 유효한 값을 가짐)


-- ════════════════════ 섹션 2: FK 추가 — 기존 테이블 ════════════════════
-- ERD 비유: "건물 각 방 사이에 연결 복도를 만드는 것"
-- FK를 추가하면 MySQL이 참조 무결성을 자동으로 지켜준다.
--
-- [ON DELETE 옵션 요약]
--   CASCADE   : 부모 삭제 → 자식도 자동 삭제 (가게 폐업 → 메뉴 삭제)
--   RESTRICT  : 부모 삭제 시 에러 발생 (자식이 있으면 삭제 불가)
--   SET NULL  : 부모 삭제 → 자식의 FK 컬럼을 NULL로 변경
--   NO ACTION : RESTRICT와 동일 (MySQL 기본값)

-- ──────────────────────────────────────────
-- 2-1. menus.restaurant_id → restaurants.id (ON DELETE CASCADE)
--      이유: 가게가 폐업(삭제)되면 그 가게의 메뉴도 자동 삭제
--            "가게 없는 메뉴"는 존재할 이유가 없음
-- ──────────────────────────────────────────
ALTER TABLE menus
  ADD CONSTRAINT fk_menus_restaurant
      FOREIGN KEY (restaurant_id)
      REFERENCES restaurants(id)
      ON DELETE CASCADE
      ON UPDATE CASCADE;
-- 결과: Query OK (FK 추가 성공)
-- 에러가 난다면? → 고아 데이터가 남아 있는 것
-- 예상 에러: ERROR 1452 — Cannot add or update a child row: a foreign key constraint fails

-- ──────────────────────────────────────────
-- 2-2. orders.customer_id → customers.id (ON DELETE RESTRICT)
--      이유: 고객 정보 삭제 시 주문 내역이 사라지면 안 됨 (거래 기록 보존)
-- ──────────────────────────────────────────
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_customer
      FOREIGN KEY (customer_id)
      REFERENCES customers(id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE;

-- ──────────────────────────────────────────
-- 2-3. orders.restaurant_id → restaurants.id (ON DELETE RESTRICT)
--      이유: 가게 삭제 시 관련 주문 기록을 보존해야 함
-- ──────────────────────────────────────────
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_restaurant
      FOREIGN KEY (restaurant_id)
      REFERENCES restaurants(id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE;

-- ──────────────────────────────────────────
-- 2-4. orders.menu_id → menus.id (ON DELETE RESTRICT)
--      이유: 메뉴 삭제 시에도 해당 메뉴로 된 주문 기록은 보존
-- ──────────────────────────────────────────
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_menu
      FOREIGN KEY (menu_id)
      REFERENCES menus(id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE;

-- ──────────────────────────────────────────
-- 2-5. FK 추가 결과 확인
-- ──────────────────────────────────────────
-- INFORMATION_SCHEMA로 현재 FK 목록을 조회한다
SELECT TABLE_NAME,
       CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME,
       REFERENCED_COLUMN_NAME
FROM   INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE  TABLE_SCHEMA   = 'hanibbaldal'
  AND  REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
-- 예상 결과: fk_menus_restaurant, fk_orders_customer 등 4개 FK가 보인다


-- ════════════════════ 섹션 3: 새 테이블 생성 ════════════════════
-- Day 9에 추가되는 테이블: riders, reviews, coupons, customer_coupons
-- "한입배달" 서비스 확장 — 배달원 관리, 리뷰 시스템, 쿠폰 시스템

-- ──────────────────────────────────────────
-- 3-1. riders (배달원) 테이블
--      restaurants와 1:N 관계 (1명 배달원이 여러 주문 배달)
--      현재는 독립 테이블로 먼저 생성
-- ──────────────────────────────────────────
CREATE TABLE riders (
  id        INT          NOT NULL AUTO_INCREMENT,   -- 배달원 고유 ID
  name      VARCHAR(30)  NOT NULL,                  -- 배달원 이름
  phone     VARCHAR(15)  UNIQUE,                    -- 전화번호 (중복 불가)
  region    VARCHAR(30),                            -- 담당 지역 (예: 해운대구)
  is_active TINYINT(1)   NOT NULL DEFAULT 1,        -- 활동 여부 (1=활동중, 0=비활동)
  PRIMARY KEY (id)
);

-- ──────────────────────────────────────────
-- 3-2. reviews (리뷰) 테이블
--      orders와 1:1 관계 (주문 1건당 리뷰 1개)
--      customers와 1:N 관계 (고객 1명이 여러 리뷰 작성 가능)
-- ──────────────────────────────────────────
CREATE TABLE reviews (
  id          INT      NOT NULL AUTO_INCREMENT,         -- 리뷰 고유 ID
  order_id    INT      NOT NULL,                        -- 어떤 주문에 대한 리뷰?
  customer_id INT      NOT NULL,                        -- 리뷰 작성 고객
  rating      INT      NOT NULL CHECK (rating BETWEEN 1 AND 5),  -- 별점 (1~5)
  content     TEXT,                                     -- 리뷰 내용 (선택)
  created_at  DATETIME NOT NULL DEFAULT NOW(),          -- 리뷰 작성 일시
  PRIMARY KEY (id),
  CONSTRAINT fk_reviews_order
      FOREIGN KEY (order_id)
      REFERENCES orders(id)
      ON DELETE CASCADE,   -- 주문이 삭제되면 리뷰도 같이 삭제
  CONSTRAINT fk_reviews_customer
      FOREIGN KEY (customer_id)
      REFERENCES customers(id)
      ON DELETE CASCADE    -- 고객 탈퇴 시 해당 리뷰도 삭제
);

-- ──────────────────────────────────────────
-- 3-3. coupons (쿠폰) 테이블
--      독립 테이블 (쿠폰 마스터 목록)
-- ──────────────────────────────────────────
CREATE TABLE coupons (
  id                INT           NOT NULL AUTO_INCREMENT,  -- 쿠폰 고유 ID
  coupon_name       VARCHAR(50)   NOT NULL,                  -- 쿠폰명
  discount_type     ENUM('정액', '정률') NOT NULL,          -- 할인 방식
  discount_value    INT           NOT NULL,                  -- 할인 금액 또는 %
  min_order_amount  INT           NOT NULL DEFAULT 0,        -- 최소 주문 금액
  PRIMARY KEY (id)
);

-- ──────────────────────────────────────────
-- 3-4. customer_coupons (고객-쿠폰 중간 테이블) — M:N 관계 해소
--      ERD 핵심 개념: M:N 관계는 직접 연결 불가 → 중간 테이블로 분리!
--      "고객 1명이 쿠폰 여러 장 보유, 같은 쿠폰을 여러 고객이 보유"
-- ──────────────────────────────────────────
CREATE TABLE customer_coupons (
  id          INT      NOT NULL AUTO_INCREMENT,       -- 지급 이력 고유 ID
  customer_id INT      NOT NULL,                      -- 어느 고객에게?
  coupon_id   INT      NOT NULL,                      -- 어떤 쿠폰을?
  issued_at   DATETIME NOT NULL DEFAULT NOW(),        -- 지급 일시
  used_at     DATETIME     NULL DEFAULT NULL,         -- 사용 일시 (미사용이면 NULL)
  is_used     TINYINT(1) NOT NULL DEFAULT 0,          -- 사용 여부 (0=미사용, 1=사용완료)
  PRIMARY KEY (id),
  CONSTRAINT fk_cc_customer
      FOREIGN KEY (customer_id)
      REFERENCES customers(id)
      ON DELETE CASCADE,   -- 고객 탈퇴 시 쿠폰 이력도 삭제
  CONSTRAINT fk_cc_coupon
      FOREIGN KEY (coupon_id)
      REFERENCES coupons(id)
      ON DELETE CASCADE    -- 쿠폰 삭제 시 지급 이력도 삭제
);

-- 생성된 테이블 목록 최종 확인
SHOW TABLES;
-- 예상 결과: coupons, customer_coupons, customers, menus,
--            orders, restaurants, reviews, riders


-- ════════════════════ 섹션 4: 샘플 데이터 INSERT ════════════════════
-- 주의: reviews는 실제 orders 테이블에 존재하는 id를 참조해야 한다.
--       FK 제약조건이 있으므로 없는 id 참조 시 에러 발생!

-- ──────────────────────────────────────────
-- 4-1. riders (배달원) 5건 — 부산 각 지역 담당
-- ──────────────────────────────────────────
INSERT INTO riders (name, phone, region, is_active) VALUES
  ('박지훈', '010-9101-1122', '해운대구', 1),  -- 해운대 담당 활동 중
  ('최수민', '010-9202-2233', '수영구',   1),  -- 수영구 담당 활동 중
  ('윤태양', '010-9303-3344', '남구',     1),  -- 남구 담당 활동 중
  ('강민서', '010-9404-4455', '동래구',   1),  -- 동래구 담당 활동 중
  ('임하늘', '010-9505-5566', '사상구',   0);  -- 사상구 담당 비활동 (휴가 중)

-- 확인
SELECT * FROM riders;
-- 예상 결과: 5건, id 1~5, 각 부산 지역 배달원

-- ──────────────────────────────────────────
-- 4-2. coupons (쿠폰) 5건
-- ──────────────────────────────────────────
INSERT INTO coupons (coupon_name, discount_type, discount_value, min_order_amount) VALUES
  ('신규가입쿠폰',   '정액', 3000,  0    ),  -- 3000원 할인, 최소 주문 없음
  ('첫주문10%할인',  '정률',   10, 15000),  -- 10% 할인, 최소 15,000원 이상
  ('배달비면제쿠폰', '정액', 3000,  5000),  -- 3000원 (배달비) 할인, 최소 5,000원
  ('5천원할인쿠폰',  '정액', 5000, 25000),  -- 5000원 할인, 최소 25,000원 이상
  ('VIP20%할인',     '정률',   20, 30000); -- 20% 할인, 최소 30,000원 이상

-- 확인
SELECT * FROM coupons;
-- 예상 결과: 5건, id 1~5

-- ──────────────────────────────────────────
-- 4-3. reviews (리뷰) 10건 — orders 테이블의 실존 id 참조
--      orders id 1~10을 참조한다고 가정 (Day 5에서 50건 INSERT)
--      customer_id도 orders와 동일한 고객으로 맞춰야 함
--      별점을 1~5 다양하게 배분
-- ──────────────────────────────────────────
INSERT INTO reviews (order_id, customer_id, rating, content) VALUES
  (1,  1, 5, '너무 맛있어요! 다음에도 꼭 시킬게요 :)'),
  (2,  2, 4, '맛은 좋은데 포장이 조금 아쉬웠어요.'),
  (3,  3, 5, '배달이 엄청 빨랐어요. 강추!'),
  (4,  1, 3, '보통이에요. 가격 대비 평범한 것 같아요.'),
  (5,  4, 2, '음식이 미지근하게 왔어요. 개선 부탁드려요.'),
  (6,  5, 5, '사장님이 손편지도 넣어주셨어요! 감동 ㅠㅠ'),
  (7,  2, 4, '양이 많아서 좋았어요. 다음에 또 올게요.'),
  (8,  6, 1, '주문한 것과 다른 메뉴가 왔어요. 실망이에요.'),
  (9,  3, 5, '국물이 진짜 끝내줘요. 자주 시켜 먹을 것 같아요.'),
  (10, 7, 4, '깔끔하고 맛있었습니다. 재방문 의사 있어요.');
-- 주의: orders 테이블에 id 1~10이 없으면 FK 에러 발생
-- 에러 예상: ERROR 1452 — Cannot add or update a child row: a foreign key constraint fails

-- 확인
SELECT r.id,
       r.order_id,
       r.rating,
       LEFT(r.content, 20) AS content_preview,
       r.created_at
FROM reviews r
ORDER BY r.id;

-- ──────────────────────────────────────────
-- 4-4. customer_coupons (고객-쿠폰) 8건
--      일부는 사용 완료(is_used=1), 일부는 미사용(is_used=0)
-- ──────────────────────────────────────────
INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, used_at, is_used) VALUES
  (1, 1, '2025-03-01 10:00:00', '2025-03-05 18:30:00', 1),  -- 고객1 신규쿠폰 사용 완료
  (1, 3, '2025-03-01 10:00:00', NULL,                  0),  -- 고객1 배달비쿠폰 미사용
  (2, 1, '2025-03-10 09:00:00', '2025-03-12 20:00:00', 1),  -- 고객2 신규쿠폰 사용 완료
  (2, 2, '2025-03-10 09:00:00', NULL,                  0),  -- 고객2 첫주문쿠폰 미사용
  (3, 3, '2025-03-15 14:00:00', NULL,                  0),  -- 고객3 배달비쿠폰 미사용
  (4, 4, '2025-04-01 11:00:00', '2025-04-03 19:00:00', 1),  -- 고객4 5천원쿠폰 사용 완료
  (5, 5, '2025-04-10 10:00:00', NULL,                  0),  -- 고객5 VIP쿠폰 미사용
  (6, 1, '2025-04-20 16:00:00', NULL,                  0);  -- 고객6 신규쿠폰 미사용

-- 확인
SELECT cc.id,
       c.name  AS customer_name,
       cp.coupon_name,
       cc.issued_at,
       cc.used_at,
       CASE cc.is_used WHEN 1 THEN '사용완료' ELSE '미사용' END AS status
FROM   customer_coupons cc
JOIN   customers c  ON cc.customer_id = c.id
JOIN   coupons   cp ON cc.coupon_id   = cp.id
ORDER BY cc.id;
-- 예상 결과: 8건, 사용완료 3건 / 미사용 5건


-- ════════════════════ 섹션 5: 정규화 실습용 비정규 테이블 ════════════════════
-- [정규화란?]
--   "하나의 사실은 한 곳에만" — 데이터 중복을 없애고 이상(Anomaly) 현상을 제거
--   비유: "방 정리 — 같은 종류 옷이 서랍 3개에 흩어져 있으면 불편하다"
--
--   [이상(Anomaly) 3종류]
--   1. 삽입 이상 : 필요한 데이터를 넣으려면 원하지 않는 데이터도 함께 넣어야 하는 상황
--   2. 수정 이상 : 같은 데이터가 여러 곳에 있어, 하나만 바꾸면 불일치 발생
--   3. 삭제 이상 : 특정 데이터를 삭제하면 필요한 다른 데이터까지 같이 삭제되는 상황

-- ──────────────────────────────────────────
-- 5-1. 0NF (비정규형) — 한 셀에 여러 값이 들어있는 상태
--      "다 때려 넣은 표" — 제일 나쁜 상태
-- ──────────────────────────────────────────
CREATE TABLE orders_unnormalized (
  order_id            INT,
  customer_name       VARCHAR(30),
  customer_phone      VARCHAR(15),
  menu_names          VARCHAR(200),   -- 주의: 여러 메뉴를 콤마로 구분해서 한 셀에 넣음
  restaurant_name     VARCHAR(50),
  restaurant_category VARCHAR(20),
  total_price         INT
);

INSERT INTO orders_unnormalized VALUES
  (1, '김민준', '010-1234-5678', '불고기버거,감자튀김',   '버거킹부산점',   '패스트푸드', 18000),
  (2, '이서연', '010-2345-6789', '양념치킨',              'BBQ치킨해운대', '치킨',       20000),
  (3, '김민준', '010-1234-5678', '짜장면,짬뽕',           '차이나타운',     '중식',       15000);

-- 0NF의 문제점:
-- (1) menu_names 컬럼에 '불고기버거,감자튀김' → 검색 불가, 집계 불가
--     ("감자튀김 주문 건수"를 구하려면 LIKE '%감자튀김%' 같은 불완전한 쿼리 사용해야 함)
-- (2) 같은 고객(김민준)의 정보(phone)가 여러 행에 중복 저장됨

SELECT * FROM orders_unnormalized;

-- ──────────────────────────────────────────
-- 5-2. 1NF (제1정규형) — 원자값 원칙: 각 컬럼에 값 1개만!
--      "한 셀에 값 한 개" 규칙으로 분리
-- ──────────────────────────────────────────
-- [1NF로 변환]
--   menu_names를 분리 → 각 주문-메뉴 조합이 한 행이 됨

-- 1NF 결과 테이블 구조:
-- order_id | customer_name | customer_phone | menu_name | restaurant_name | restaurant_category | total_price
--   1      | 김민준        | 010-1234-5678  | 불고기버거 | 버거킹부산점    | 패스트푸드          | 18000
--   1      | 김민준        | 010-1234-5678  | 감자튀김  | 버거킹부산점    | 패스트푸드          | 18000
--   2      | 이서연        | 010-2345-6789  | 양념치킨  | BBQ치킨해운대  | 치킨                | 20000
--   3      | 김민준        | 010-1234-5678  | 짜장면    | 차이나타운      | 중식                | 15000
--   3      | 김민준        | 010-1234-5678  | 짬뽕      | 차이나타운      | 중식                | 15000

CREATE TABLE orders_1nf (
  order_id            INT,
  customer_name       VARCHAR(30),
  customer_phone      VARCHAR(15),
  menu_name           VARCHAR(50),   -- 수정: 메뉴 1개씩
  restaurant_name     VARCHAR(50),
  restaurant_category VARCHAR(20),
  total_price         INT
);

INSERT INTO orders_1nf VALUES
  (1, '김민준', '010-1234-5678', '불고기버거', '버거킹부산점',   '패스트푸드', 18000),
  (1, '김민준', '010-1234-5678', '감자튀김',  '버거킹부산점',   '패스트푸드', 18000),
  (2, '이서연', '010-2345-6789', '양념치킨',  'BBQ치킨해운대', '치킨',       20000),
  (3, '김민준', '010-1234-5678', '짜장면',    '차이나타운',     '중식',       15000),
  (3, '김민준', '010-1234-5678', '짬뽕',      '차이나타운',     '중식',       15000);

-- 1NF에서 남은 문제점:
-- (1) 기본키가 (order_id, menu_name) 복합키여야 하는데
--     customer_name은 order_id에만 의존, menu_name에는 의존하지 않음 → 부분 함수 종속
-- (2) 김민준의 phone이 3행에 중복 → 번호 바뀌면 3곳 모두 UPDATE 해야 함 (수정 이상)
-- (3) restaurant_category는 restaurant_name에만 종속 (이행 함수 종속)

SELECT * FROM orders_1nf;

-- ──────────────────────────────────────────
-- 5-3. 2NF (제2정규형) — 부분 함수 종속 제거
--      "기본키 전체에 종속되지 않는 컬럼은 분리"
--      복합키 (order_id, menu_name)에서 order_id에만 종속되는 컬럼을 별도 테이블로 이동
-- ──────────────────────────────────────────
-- [2NF로 변환] — 3개 테이블로 분리

-- ① 주문 정보 (order_id에만 의존하는 것들)
CREATE TABLE orders_2nf (
  order_id         INT PRIMARY KEY,
  customer_name    VARCHAR(30),
  customer_phone   VARCHAR(15),
  restaurant_name  VARCHAR(50),
  restaurant_category VARCHAR(20),
  total_price      INT
);

-- ② 주문-메뉴 관계 (order_id + menu_name 복합키 의존)
CREATE TABLE order_menus_2nf (
  order_id  INT,
  menu_name VARCHAR(50),
  PRIMARY KEY (order_id, menu_name)
);

INSERT INTO orders_2nf VALUES
  (1, '김민준', '010-1234-5678', '버거킹부산점',   '패스트푸드', 18000),
  (2, '이서연', '010-2345-6789', 'BBQ치킨해운대', '치킨',       20000),
  (3, '김민준', '010-1234-5678', '차이나타운',     '중식',       15000);

INSERT INTO order_menus_2nf VALUES
  (1, '불고기버거'),
  (1, '감자튀김'),
  (2, '양념치킨'),
  (3, '짜장면'),
  (3, '짬뽕');

-- 2NF에서 남은 문제점:
-- orders_2nf에서 restaurant_category는 restaurant_name에만 종속
-- = "이행 함수 종속": order_id → restaurant_name → restaurant_category
-- 만약 '버거킹부산점' 카테고리가 바뀌면 여러 행을 모두 UPDATE해야 함 (수정 이상)

SELECT * FROM orders_2nf;
SELECT * FROM order_menus_2nf;

-- ──────────────────────────────────────────
-- 5-4. 3NF (제3정규형) — 이행 함수 종속 제거
--      "기본키가 아닌 컬럼이 다른 기본키가 아닌 컬럼에 종속되면 분리"
-- ──────────────────────────────────────────
-- [3NF로 변환] — restaurant 정보를 별도 테이블로 분리

-- ① 주문 정보 (restaurant_category 제거)
CREATE TABLE orders_3nf (
  order_id        INT PRIMARY KEY,
  customer_name   VARCHAR(30),
  customer_phone  VARCHAR(15),
  restaurant_name VARCHAR(50),   -- 가게 이름만 남기고 (FK 역할)
  total_price     INT
);

-- ② 가게 정보 (restaurant_name → category 종속 분리)
CREATE TABLE restaurants_3nf (
  restaurant_name     VARCHAR(50) PRIMARY KEY,
  restaurant_category VARCHAR(20)
);

INSERT INTO restaurants_3nf VALUES
  ('버거킹부산점',   '패스트푸드'),
  ('BBQ치킨해운대', '치킨'),
  ('차이나타운',     '중식');

INSERT INTO orders_3nf VALUES
  (1, '김민준', '010-1234-5678', '버거킹부산점',   18000),
  (2, '이서연', '010-2345-6789', 'BBQ치킨해운대', 20000),
  (3, '김민준', '010-1234-5678', '차이나타운',     15000);

-- 3NF 달성! 이제 이상 현상이 사라진다.
-- 버거킹부산점의 카테고리가 바뀌어도 restaurants_3nf에서 1건만 UPDATE하면 됨
-- 같은 고객 정보 중복 문제는? → 실무에서는 customers 테이블을 따로 두어 id로 참조

-- [3NF 최종 요약]
-- 0NF: 한 셀에 여러 값 → 1NF: 원자값 보장 (셀당 1값)
-- 1NF: 부분 함수 종속 → 2NF: 복합키 전체에 종속되도록 분리
-- 2NF: 이행 함수 종속 → 3NF: 기본키가 아닌 컬럼 간 종속 제거

SELECT o.order_id,
       o.customer_name,
       o.total_price,
       r.restaurant_name,
       r.restaurant_category
FROM   orders_3nf o
JOIN   restaurants_3nf r ON o.restaurant_name = r.restaurant_name;

-- ──────────────────────────────────────────
-- 5-5. [심화] 반정규화(De-normalization) 개념 주석
-- ──────────────────────────────────────────
-- 정규화의 역설: 정규화를 완벽히 하면 JOIN이 너무 많아진다 → 조회 속도 저하
-- 반정규화: 성능을 위해 의도적으로 중복을 허용하는 설계
--
-- 예시: orders 테이블에 restaurant_name을 직접 저장
--       (JOIN 없이도 주문 내역에서 가게 이름 바로 확인 가능)
--
-- 실무 판단 기준:
--   조회가 많고 수정이 적은 컬럼 → 반정규화 고려
--   수정이 잦은 컬럼 → 정규화 유지
--
-- "한입배달" orders 테이블의 total_price 컬럼이 바로 반정규화의 예시:
--   원래는 price * quantity로 계산하면 되지만,
--   매번 JOIN+계산하는 비용을 줄이기 위해 미리 저장해 둠


-- ════════════════════ 섹션 6: FK 참조무결성 테스트 ════════════════════
-- SAVEPOINT를 사용해 테스트 후 롤백하므로 실제 데이터는 변경되지 않는다.
-- 학생들이 직접 실행하며 에러 메시지를 체험하는 섹션

START TRANSACTION;  -- 트랜잭션 시작 (Day 8에서 배운 내용!)
SAVEPOINT before_cascade_test;  -- 테스트 시작 전 저장점

-- ──────────────────────────────────────────
-- 6-1. ON DELETE CASCADE 테스트
--      restaurants 행 삭제 → menus가 자동 삭제되는지 확인
-- ──────────────────────────────────────────

-- 테스트용 가게와 메뉴 데이터 임시 삽입
INSERT INTO restaurants (name, category, address, rating)
VALUES ('테스트분식집', '분식', '부산시 테스트구 1번길', 4.0);

-- 방금 넣은 가게의 id 확인
SET @test_restaurant_id = LAST_INSERT_ID();  -- 마지막 INSERT된 id를 변수에 저장
SELECT @test_restaurant_id AS test_restaurant_id;

-- 해당 가게의 메뉴 2개 삽입
INSERT INTO menus (restaurant_id, menu_name, price) VALUES
  (@test_restaurant_id, '테스트김밥', 3000),
  (@test_restaurant_id, '테스트라면', 4000);

-- 메뉴 확인
SELECT * FROM menus WHERE restaurant_id = @test_restaurant_id;
-- 예상 결과: 2건 (테스트김밥, 테스트라면)

-- 이제 가게를 삭제해보자 — CASCADE이므로 메뉴도 자동 삭제되어야 함
DELETE FROM restaurants WHERE id = @test_restaurant_id;
-- 결과: Query OK (가게 삭제 성공)

-- 메뉴가 자동으로 삭제되었는지 확인
SELECT * FROM menus WHERE restaurant_id = @test_restaurant_id;
-- 예상 결과: 빈 결과 (0 rows)
-- → ON DELETE CASCADE 동작 확인 완료!

SAVEPOINT after_cascade_test;  -- CASCADE 테스트 후 저장점

-- ──────────────────────────────────────────
-- 6-2. ON DELETE RESTRICT 테스트
--      주문이 있는 고객을 삭제하면 에러가 나야 한다
-- ──────────────────────────────────────────

-- 고객 1번(id=1)에게 주문이 있는지 확인
SELECT COUNT(*) AS order_count
FROM orders
WHERE customer_id = 1;
-- 예상 결과: 1 이상 (주문 있음)

-- 주문이 있는 고객 삭제 시도 → RESTRICT이므로 에러 발생 예상
DELETE FROM customers WHERE id = 1;
-- 예상 에러:
-- ERROR 1451 (23000): Cannot delete or update a parent row:
-- a foreign key constraint fails
-- (`hanibbaldal`.`orders`, CONSTRAINT `fk_orders_customer`
-- FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`))
--
-- → "주문 내역이 있는 고객은 삭제할 수 없다" — 의도된 보호 동작!

-- ──────────────────────────────────────────
-- 6-3. 존재하지 않는 FK 값 INSERT 테스트
--      없는 restaurant_id로 메뉴를 넣으면 에러가 나야 한다
-- ──────────────────────────────────────────
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (9999, '고아메뉴', 5000);
-- 예상 에러:
-- ERROR 1452 (23000): Cannot add or update a child row:
-- a foreign key constraint fails
-- (`hanibbaldal`.`menus`, CONSTRAINT `fk_menus_restaurant`
-- FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`id`))
--
-- → 섹션 1에서 시연했던 "고아 데이터" 문제가 이제 FK로 차단됨!

-- ──────────────────────────────────────────
-- 6-4. 모든 테스트 롤백
--      (트랜잭션 덕분에 위 테스트들이 실제 DB에 영향을 주지 않음)
-- ──────────────────────────────────────────
ROLLBACK TO SAVEPOINT before_cascade_test;
-- 아니면 전체 롤백: ROLLBACK;
ROLLBACK;

-- 롤백 후 원래 상태 확인
SELECT COUNT(*) AS restaurant_count FROM restaurants;
SELECT COUNT(*) AS menu_count       FROM menus;
SELECT COUNT(*) AS customer_count   FROM customers;
-- 예상 결과: 각각 원래 개수 (테스트 데이터가 사라짐)


-- ════════════════════ 섹션 7: 완성된 ERD 구조 확인 쿼리 ════════════════════
-- Day 9 최종 "한입배달" DB의 전체 테이블 관계를 보여주는 JOIN 쿼리

-- ──────────────────────────────────────────
-- 7-1. 주문 + 고객 + 가게 + 메뉴 전체 조회 (4-way JOIN)
--      "사장님, 오늘 주문 현황 전체 보여주세요!"
-- ──────────────────────────────────────────
SELECT
    o.id           AS 주문번호,
    o.order_date   AS 주문일시,
    c.name         AS 고객명,
    r.name         AS 가게명,
    r.category     AS 카테고리,
    m.menu_name    AS 메뉴명,
    o.quantity     AS 수량,
    m.price        AS 단가,
    o.total_price  AS 결제금액,
    o.status       AS 주문상태
FROM   orders      o
JOIN   customers   c ON o.customer_id   = c.id
JOIN   restaurants r ON o.restaurant_id = r.id
JOIN   menus       m ON o.menu_id       = m.id
ORDER BY o.order_date DESC
LIMIT 20;
-- JOIN 체인: orders → customers (누가 시켰나?)
--                   → restaurants (어느 가게?)
--                   → menus (어떤 메뉴?)

-- ──────────────────────────────────────────
-- 7-2. 리뷰가 있는 주문만 조회 (INNER JOIN으로 필터 효과)
--      + 별점이 4점 이상인 리뷰만 표시
--      "좋은 리뷰 달린 주문들을 확인하자"
-- ──────────────────────────────────────────
SELECT
    o.id              AS 주문번호,
    c.name            AS 고객명,
    r.name            AS 가게명,
    m.menu_name       AS 메뉴명,
    rv.rating         AS 별점,
    LEFT(rv.content, 30) AS 리뷰미리보기,
    rv.created_at     AS 리뷰작성일
FROM   orders      o
JOIN   customers   c  ON o.customer_id   = c.id
JOIN   restaurants r  ON o.restaurant_id = r.id
JOIN   menus       m  ON o.menu_id       = m.id
JOIN   reviews     rv ON o.id            = rv.order_id   -- INNER JOIN: 리뷰 있는 주문만
WHERE  rv.rating >= 4                                    -- 별점 4 이상만
ORDER BY rv.rating DESC, rv.created_at DESC;
-- JOIN 체인: orders → reviews (리뷰 있는 주문만 남음)
--                   → customers, restaurants, menus (상세 정보 붙임)

-- ──────────────────────────────────────────
-- 7-3. 쿠폰 보유 고객과 사용 현황
--      "쿠폰 발급 현황과 사용률을 확인하자"
-- ──────────────────────────────────────────
SELECT
    c.name                                            AS 고객명,
    cp.coupon_name                                    AS 쿠폰명,
    cp.discount_type                                  AS 할인방식,
    CONCAT(cp.discount_value,
           CASE cp.discount_type WHEN '정률' THEN '%' ELSE '원' END
    )                                                 AS 할인혜택,
    cc.issued_at                                      AS 발급일,
    cc.used_at                                        AS 사용일,
    CASE cc.is_used WHEN 1 THEN '사용완료' ELSE '미사용' END AS 사용여부
FROM   customer_coupons cc
JOIN   customers c   ON cc.customer_id = c.id
JOIN   coupons   cp  ON cc.coupon_id   = cp.id
ORDER BY c.name, cc.issued_at;
-- M:N 중간 테이블 활용: customer_coupons → customers, coupons 양방향 JOIN

-- [보너스] 쿠폰별 발급/사용 통계
SELECT
    cp.coupon_name                                AS 쿠폰명,
    COUNT(cc.id)                                  AS 총발급수,
    SUM(cc.is_used)                               AS 사용완료수,
    COUNT(cc.id) - SUM(cc.is_used)                AS 미사용수,
    ROUND(SUM(cc.is_used) / COUNT(cc.id) * 100, 1) AS 사용률_퍼센트
FROM   coupons          cp
LEFT JOIN customer_coupons cc ON cp.id = cc.coupon_id  -- LEFT JOIN: 발급 안 된 쿠폰도 포함
GROUP BY cp.id, cp.coupon_name
ORDER BY 사용률_퍼센트 DESC;
-- 예상 결과: 5개 쿠폰, 각 사용률 표시


-- ════════════════════ 섹션 8: 최종 ERD 텍스트 다이어그램 (주석) ════════════════════
-- Workbench의 [Database → Reverse Engineer] 또는 [EER Diagram] 기능으로
-- 아래 구조를 시각적 ERD로 확인할 수 있다.
--
-- ┌──────────────┐        ┌──────────────┐
-- │  customers   │        │  restaurants │
-- │──────────────│        │──────────────│
-- │ id (PK)      │        │ id (PK)      │
-- │ name         │        │ name         │
-- │ phone        │        │ category     │
-- │ address      │        │ address      │
-- └──────┬───────┘        │ rating       │
--        │                └──────┬───────┘
--        │ 1:N                   │ 1:N (CASCADE)
--        │                       │
-- ┌──────▼───────────────────────▼───────┐     ┌─────────────────┐
-- │               orders                 │     │      menus      │
-- │──────────────────────────────────────│     │─────────────────│
-- │ id (PK)                              │     │ id (PK)         │
-- │ customer_id (FK → customers)         │     │ restaurant_id   │
-- │ restaurant_id (FK → restaurants)     │     │   (FK → restaurants, CASCADE) │
-- │ menu_id (FK → menus)         ◄───────┼──── │ menu_name       │
-- │ quantity                             │     │ price           │
-- │ total_price                          │     └─────────────────┘
-- │ order_date                           │
-- │ delivery_fee                         │
-- │ status                               │
-- └──────┬───────────────────────────────┘
--        │ 1:1 (CASCADE)
--        │
-- ┌──────▼───────┐     ┌──────────────┐     ┌──────────────────────┐
-- │   reviews    │     │    riders    │     │  customer_coupons    │
-- │──────────────│     │──────────────│     │──────────────────────│
-- │ id (PK)      │     │ id (PK)      │     │ id (PK)              │
-- │ order_id FK  │     │ name         │     │ customer_id FK       │
-- │ customer_id FK│    │ phone        │     │ coupon_id FK         │
-- │ rating       │     │ region       │     │ issued_at            │
-- │ content      │     │ is_active    │     │ used_at              │
-- │ created_at   │     └──────────────┘     │ is_used              │
-- └──────────────┘                          └──────┬───────────────┘
--                                                   │ N:1
--                                            ┌──────▼───────┐
--                                            │   coupons    │
--                                            │──────────────│
--                                            │ id (PK)      │
--                                            │ coupon_name  │
--                                            │ discount_type│
--                                            │ discount_value│
--                                            │ min_order_amt│
--                                            └──────────────┘
--
-- [관계 요약]
--   customers   : orders   = 1:N  (고객 1명이 주문 여러 건)
--   restaurants : orders   = 1:N  (가게 1곳에 주문 여러 건)
--   restaurants : menus    = 1:N  (가게 1곳에 메뉴 여러 개, CASCADE)
--   menus       : orders   = 1:N  (메뉴 1개가 주문 여러 건)
--   orders      : reviews  = 1:1  (주문 1건당 리뷰 1개)
--   customers   : coupons  = M:N  (중간 테이블: customer_coupons)
--   riders      : (독립)         (향후 orders와 연결 예정)


-- ════════════════════ [Day 9 마무리] ════════════════════
-- 오늘 배운 키워드:
--   ERD, 엔티티, 속성, 관계 (1:1 / 1:N / M:N)
--   FOREIGN KEY, REFERENCES, ON DELETE CASCADE / RESTRICT
--   참조 무결성, 고아 데이터
--   ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY
--   정규화: 0NF → 1NF → 2NF → 3NF
--   부분 함수 종속, 이행 함수 종속
--   반정규화 (De-normalization)
--   INFORMATION_SCHEMA.KEY_COLUMN_USAGE
--   SAVEPOINT, ROLLBACK TO SAVEPOINT
--
-- 다음 시간 (Day 10) 예고:
--   "10일간 배운 걸 한번에 써먹어 봅시다!"
--   CREATE USER, GRANT, REVOKE (사용자 권한 관리)
--   mysqldump (백업 & 복원)
--   미니 프로젝트: ERD → 테이블 → 데이터 → 쿼리 10개 → 발표
--   정보처리기사 SQL 기출 5문제
-- ============================================================
