-- =============================================================================
-- 한입배달 (Hanip Delivery) MySQL 10일 완성
-- Day 2 — 테이블을 제대로 만들자: 제약조건
-- =============================================================================
-- 실행 전 확인:
--   MySQL 버전 8.x 이상 권장
--   Day 1에서 hanip_delivery 데이터베이스가 생성되어 있어야 합니다
-- =============================================================================


USE hanip_delivery;


-- =============================================================================
-- 파트 1: Day 1 테이블의 문제점 시연
-- "자물쇠 없는 창고에 아무 물건이나 들어간다"
-- =============================================================================

-- Day 1에서 만든 허술한 테이블을 확인해봅니다
-- (Day 1 테이블이 없다면 아래 CREATE로 먼저 만들어 두세요)

-- -----------------------------------------------
-- Day 1 허술한 테이블 (제약조건 없는 버전)
-- -----------------------------------------------
DROP TABLE IF EXISTS restaurants_v1;
CREATE TABLE restaurants_v1 (
    id   INT,
    name VARCHAR(100),
    category VARCHAR(50)
    -- 제약조건이 전혀 없습니다 — 아무 데이터나 들어갑니다!
);

-- 문제 1: id에 NULL이 들어갑니다
INSERT INTO restaurants_v1 (id, name, category) VALUES (NULL, '테스트가게', '한식');

-- 문제 2: 같은 id가 중복으로 들어갑니다
INSERT INTO restaurants_v1 (id, name, category) VALUES (1, '부산맛집A', '한식');
INSERT INTO restaurants_v1 (id, name, category) VALUES (1, '부산맛집B', '치킨');  -- id 1이 또!

-- 문제 3: name이 NULL로 들어갑니다
INSERT INTO restaurants_v1 (id, name, category) VALUES (2, NULL, '피자');

-- 문제 4: 아무 값도 없이 들어갑니다
INSERT INTO restaurants_v1 (id, name, category) VALUES (NULL, NULL, NULL);

-- 결과를 확인해보세요 — 데이터베이스가 이래도 되나요?
SELECT * FROM restaurants_v1;

-- 예상 결과:
-- +------+----------+----------+
-- | id   | name     | category |
-- +------+----------+----------+
-- | NULL | 테스트가게 | 한식     |
-- |    1 | 부산맛집A | 한식     |
-- |    1 | 부산맛집B | 치킨     |  <-- id 중복!
-- |    2 | NULL     | 피자     |  <-- 이름이 없는 가게?
-- | NULL | NULL     | NULL     |  <-- 아무것도 없는 행!
-- +------+----------+----------+

-- 🔐 결론: 제약조건(자물쇠)이 없으면 쓰레기 데이터가 쌓입니다.
--    오늘은 이 문제를 해결하는 6가지 자물쇠를 배웁니다!

-- 실습이 끝난 더미 테이블 제거
DROP TABLE IF EXISTS restaurants_v1;


-- =============================================================================
-- 파트 2: 한입배달 테이블 리뉴얼 (DROP & 재생성)
-- 제약조건을 하나씩 달아서 "완전한 테이블"을 만들어봅니다
-- =============================================================================

-- 기존 테이블 삭제 (순서 중요: 참조하는 테이블부터 먼저 삭제)
DROP TABLE IF EXISTS menus;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;


-- -----------------------------------------------
-- restaurants 테이블 (식당)
-- -----------------------------------------------
-- PRIMARY KEY     : id — 각 가게를 구분하는 고유 번호 (주민등록번호 역할)
-- AUTO_INCREMENT  : id — 번호를 직접 입력할 필요 없이 자동으로 증가
-- NOT NULL        : name, category — 가게 이름과 카테고리는 반드시 있어야 함
-- DEFAULT 0.0     : rating — 신규 등록 시 기본 평점은 0.0
-- DEFAULT NOW()   : created_at — 등록 시각은 자동으로 현재 시간
-- -----------------------------------------------
CREATE TABLE restaurants (
    id               INT             PRIMARY KEY AUTO_INCREMENT,  -- PK + 자동증가
    name             VARCHAR(50)     NOT NULL,                    -- 가게 이름 (필수)
    category         VARCHAR(20)     NOT NULL,                    -- 카테고리 (필수)
    address          VARCHAR(100),                                -- 주소 (선택)
    rating           DECIMAL(2,1)    DEFAULT 0.0,                -- 평점 (기본값 0.0)
    created_at       TIMESTAMP       DEFAULT CURRENT_TIMESTAMP   -- 등록일시 (자동)
);


-- -----------------------------------------------
-- customers 테이블 (고객)
-- -----------------------------------------------
-- UNIQUE NOT NULL : phone — 전화번호는 사람마다 달라야 하고, 반드시 있어야 함
-- UNIQUE          : email — 이메일도 중복 불가 (단, NULL은 허용 — 선택 항목)
-- -----------------------------------------------
CREATE TABLE customers (
    id               INT             PRIMARY KEY AUTO_INCREMENT,
    name             VARCHAR(30)     NOT NULL,                    -- 이름 (필수)
    phone            VARCHAR(20)     UNIQUE NOT NULL,             -- 전화번호 (유일 + 필수)
    email            VARCHAR(100)    UNIQUE,                      -- 이메일 (유일, 선택)
    address          VARCHAR(100),                                -- 주소 (선택)
    joined_at        TIMESTAMP       DEFAULT CURRENT_TIMESTAMP   -- 가입일시 (자동)
);


-- -----------------------------------------------
-- menus 테이블 (메뉴)
-- -----------------------------------------------
-- NOT NULL        : restaurant_id, menu_name, price — 핵심 필드는 모두 필수
-- CHECK(price>0)  : 가격은 반드시 0보다 커야 함 (음수 가격은 불가!)
-- DEFAULT TRUE    : is_available — 신규 메뉴는 기본적으로 판매 중
-- -----------------------------------------------
CREATE TABLE menus (
    id               INT             PRIMARY KEY AUTO_INCREMENT,
    restaurant_id    INT             NOT NULL,                    -- 어느 가게의 메뉴인지 (필수)
    menu_name        VARCHAR(50)     NOT NULL,                    -- 메뉴명 (필수)
    price            INT             NOT NULL CHECK (price > 0), -- 가격 (필수 + 양수 검증)
    menu_description VARCHAR(200),                                -- 설명 (선택)
    is_available     BOOLEAN         DEFAULT TRUE                 -- 판매 여부 (기본: 판매중)
);

-- 테이블이 제대로 만들어졌는지 구조 확인
DESC restaurants;
DESC customers;
DESC menus;


-- =============================================================================
-- 파트 3: 더미 데이터 INSERT
-- 실제 부산 지역 기반의 현실적인 샘플 데이터
-- =============================================================================

-- -----------------------------------------------
-- 3-1. restaurants 데이터 (10건)
--   한식 3, 치킨 2, 피자 2, 중식 2, 분식 1
--   부산 지역: 해운대, 서면, 광안리, 동래, 남포동, 사직, 연산동 등
-- -----------------------------------------------
INSERT INTO restaurants (name, category, address, rating) VALUES
-- 한식 (3건)
('부산명가갈비',   '한식', '부산시 동래구 동래로 102',      4.5),
('해운대순대국',   '한식', '부산시 해운대구 해운대로 234',   4.2),
('남포동비빔밥',   '한식', '부산시 중구 남포동 광복로 55',   4.7),
-- 치킨 (2건)
('해운대통닭',     '치킨', '부산시 해운대구 달맞이길 88',    4.4),
('서면바삭치킨',   '치킨', '부산시 부산진구 서면로 301',     3.9),
-- 피자 (2건)
('광안리피자랩',   '피자', '부산시 수영구 광안해변로 77',    4.1),
('사직피자하우스', '피자', '부산시 동래구 사직로 45',        3.8),
-- 중식 (2건)
('연산동짬뽕왕',   '중식', '부산시 연제구 연산로 66',        4.3),
('서면차이나팰리스','중식', '부산시 부산진구 중앙대로 189',   4.0),
-- 분식 (1건)
('광안리떡볶이집', '분식', '부산시 수영구 광안리해변로 12',  4.6);

-- 확인
SELECT * FROM restaurants;


-- -----------------------------------------------
-- 3-2. customers 데이터 (10건)
--   한국 이름, 부산 주소, 010-XXXX-XXXX 형식
--   이메일 일부 NULL (선택 항목 — 나중에 IFNULL 실습용)
--   고객 9번, 10번: 주문 0건 예정 (Day 6 LEFT JOIN 실습용)
-- -----------------------------------------------
INSERT INTO customers (name, phone, email, address) VALUES
('김민준', '010-1234-5678', 'minjun.kim@gmail.com',   '부산시 해운대구 우동 101'),
('이서연', '010-2345-6789', 'seoyeon.lee@naver.com',  '부산시 수영구 광안동 202'),
('박지훈', '010-3456-7890', 'jihoon.park@kakao.com',  '부산시 부산진구 전포동 303'),
('최수아', '010-4567-8901', NULL,                     '부산시 동래구 온천동 404'),   -- 이메일 없음
('정태영', '010-5678-9012', 'taeyoung.j@gmail.com',   '부산시 남구 대연동 505'),
('한유진', '010-6789-0123', NULL,                     '부산시 연제구 거제동 606'),   -- 이메일 없음
('오다은', '010-7890-1234', 'daeun.oh@naver.com',     '부산시 중구 남포동 707'),
('임재현', '010-8901-2345', 'jaehyun.lim@daum.net',   '부산시 사하구 다대동 808'),
-- 아래 2명은 주문 이력 없는 고객 (Day 6 LEFT JOIN 실습용으로 의도적 설정)
('강보라', '010-9012-3456', 'bora.kang@gmail.com',    '부산시 북구 화명동 909'),
('윤성호', '010-0123-4567', NULL,                     '부산시 기장군 기장읍 10-1');  -- 이메일 없음

-- 확인
SELECT * FROM customers;


-- -----------------------------------------------
-- 3-3. menus 데이터 (30건 — 가게당 3개)
--   가격 범위: 5,000 ~ 25,000원
--   실제 한국 음식 메뉴명 사용
--   menu_description 일부 NULL (선택 항목)
-- -----------------------------------------------

-- 1번 가게: 부산명가갈비 (한식)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(1, '갈비탕',     13000, '24시간 우려낸 진한 사골 베이스에 부드러운 갈비가 듬뿍'),
(1, '소갈비구이', 25000, '국내산 한우 소갈비를 숯불에 직접 구워드립니다'),
(1, '된장찌개',    9000, NULL);

-- 2번 가게: 해운대순대국 (한식)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(2, '순대국밥',    9000, '매콤하고 구수한 부산식 순대국밥'),
(2, '내장탕',     10000, NULL),
(2, '수육정식',   14000, '보쌈수육 + 국밥 + 반찬 세트');

-- 3번 가게: 남포동비빔밥 (한식)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(3, '돌솥비빔밥',  11000, '돌솥에 바삭하게 눌린 누룽지까지 즐길 수 있는 비빔밥'),
(3, '산채비빔밥',   9000, '각종 나물을 듬뿍 올린 건강한 비빔밥'),
(3, '육회비빔밥',  14000, NULL);

-- 4번 가게: 해운대통닭 (치킨)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(4, '후라이드치킨', 18000, '바삭한 황금빛 후라이드, 1마리 기준'),
(4, '양념치킨',    19000, '달콤매콤한 양념 소스 치킨'),
(4, '반반치킨',    20000, '후라이드 반 + 양념 반 구성');

-- 5번 가게: 서면바삭치킨 (치킨)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(5, '간장치킨',    19000, '달콤한 간장 소스로 버무린 인기 메뉴'),
(5, '파닭',        20000, NULL),
(5, '치킨무세트',   5000, '치킨 주문 시 추가 가능한 치킨무 세트');

-- 6번 가게: 광안리피자랩 (피자)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(6, '마르게리따피자', 18000, '토마토소스, 모짜렐라, 바질의 정통 이탈리안'),
(6, '불고기피자',   20000, '국내산 불고기와 각종 야채가 올라간 인기 피자'),
(6, '고구마무스피자',19000, NULL);

-- 7번 가게: 사직피자하우스 (피자)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(7, '콤비네이션피자', 22000, '페퍼로니, 피망, 올리브, 버섯이 가득'),
(7, '포테이토피자',  19000, '부드러운 크림소스 베이스의 감자 피자'),
(7, '치즈크러스트피자',23000, NULL);

-- 8번 가게: 연산동짬뽕왕 (중식)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(8, '짬뽕',        11000, '불맛 가득한 얼큰한 해물짬뽕'),
(8, '짜장면',       9000, '춘장을 오래 볶아 깊은 풍미의 정통 짜장면'),
(8, '탕수육',      18000, '바삭한 튀김에 새콤달콤 소스, 부먹/찍먹 선택 가능');

-- 9번 가게: 서면차이나팰리스 (중식)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(9, '마파두부',     12000, '얼얼하고 매콤한 사천식 마파두부'),
(9, '군만두',        8000, NULL),
(9, '볶음밥',       10000, '각종 재료를 넣어 센 불에 볶아낸 중화식 볶음밥');

-- 10번 가게: 광안리떡볶이집 (분식)
INSERT INTO menus (restaurant_id, menu_name, price, menu_description) VALUES
(10, '국물떡볶이',   7000, '쌀떡과 어묵이 들어간 부드러운 국물 떡볶이'),
(10, '라볶이',       8000, '떡볶이 + 라면 사리의 환상 조합'),
(10, '분식세트',    12000, '떡볶이 + 순대 + 튀김 3종 세트');

-- 확인
SELECT * FROM menus ORDER BY restaurant_id, id;

-- 메뉴 수 확인 (30건이어야 합니다)
SELECT COUNT(*) AS total_menus FROM menus;


-- =============================================================================
-- 파트 4: ALTER TABLE 실습
-- "이미 완공된 건물을 리모델링하는 것" — 구조를 바꿀 수 있습니다
-- =============================================================================

-- -----------------------------------------------
-- 4-1. ADD COLUMN — 컬럼 추가
-- restaurants에 최소주문금액 컬럼을 추가합니다
-- -----------------------------------------------
-- 건물에 방을 하나 더 만드는 것과 같습니다
ALTER TABLE restaurants
    ADD COLUMN min_order_amount INT DEFAULT 0;

-- 추가된 것을 확인
DESC restaurants;

-- 실제로 적용해봅니다 (일부 가게 최소주문금액 설정)
UPDATE restaurants SET min_order_amount = 10000 WHERE id IN (1, 2, 3);
UPDATE restaurants SET min_order_amount = 12000 WHERE id IN (4, 5);
UPDATE restaurants SET min_order_amount =  8000 WHERE id IN (6, 7);
UPDATE restaurants SET min_order_amount = 11000 WHERE id IN (8, 9);
UPDATE restaurants SET min_order_amount =  7000 WHERE id = 10;

SELECT id, name, min_order_amount FROM restaurants;


-- -----------------------------------------------
-- 4-2. MODIFY COLUMN — 컬럼 타입/속성 수정
-- customers의 name 컬럼을 VARCHAR(30)에서 VARCHAR(50)으로 넓힙니다
-- -----------------------------------------------
-- 방의 크기를 넓히는 리모델링입니다
ALTER TABLE customers
    MODIFY COLUMN name VARCHAR(50) NOT NULL;

-- 변경 확인
DESC customers;


-- -----------------------------------------------
-- 4-3. RENAME COLUMN — 컬럼명 변경
-- menus의 description → menu_description (이미 파트2에서 생성 시 menu_description으로 했으므로
-- 여기서는 menu_description → dish_description으로 했다가 다시 되돌리는 예제)
-- -----------------------------------------------
-- 방의 이름표를 바꾸는 것과 같습니다
ALTER TABLE menus
    RENAME COLUMN menu_description TO dish_description;

-- 확인
DESC menus;

-- 다시 원래 이름으로 (실습 후 복원)
ALTER TABLE menus
    RENAME COLUMN dish_description TO menu_description;

DESC menus;


-- -----------------------------------------------
-- 4-4. DROP COLUMN — 컬럼 삭제 (주의!)
-- 실습용 임시 컬럼을 추가했다가 삭제해봅니다
-- -----------------------------------------------
-- 방을 허무는 것 — 되돌릴 수 없습니다!
ALTER TABLE menus
    ADD COLUMN temp_column VARCHAR(10);

DESC menus;  -- temp_column이 추가됨

ALTER TABLE menus
    DROP COLUMN temp_column;

DESC menus;  -- temp_column이 사라짐


-- =============================================================================
-- 데이터 확인 SELECT 쿼리
-- =============================================================================

-- 전체 가게 목록 (최신 등록 순)
SELECT
    id,
    name,
    category,
    rating,
    min_order_amount,
    created_at
FROM restaurants
ORDER BY created_at DESC;

-- 전체 고객 목록 (이메일 없는 고객 표시 포함)
SELECT
    id,
    name,
    phone,
    IFNULL(email, '(이메일 없음)') AS email,
    address
FROM customers;

-- 가게별 메뉴 개수
SELECT
    r.id,
    r.name        AS restaurant_name,
    COUNT(m.id)   AS menu_count
FROM restaurants r
    LEFT JOIN menus m ON r.id = m.restaurant_id
GROUP BY r.id, r.name
ORDER BY r.id;

-- 가격이 10,000원 이상인 메뉴 목록
SELECT
    m.id,
    r.name        AS restaurant_name,
    m.menu_name,
    m.price
FROM menus m
    JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.price >= 10000
ORDER BY m.price DESC;

-- 카테고리별 평균 평점
SELECT
    category,
    ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(*)              AS store_count
FROM restaurants
GROUP BY category
ORDER BY avg_rating DESC;

-- 설명(menu_description)이 없는 메뉴 목록
SELECT
    m.id,
    r.name     AS restaurant_name,
    m.menu_name
FROM menus m
    JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.menu_description IS NULL;

-- =============================================================================
-- Day 2 스크립트 완료
-- 다음 시간(Day 3): INSERT/SELECT/UPDATE/DELETE — CRUD 완전정복!
-- =============================================================================
