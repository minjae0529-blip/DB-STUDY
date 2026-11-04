-- ============================================================
-- SECTION 1 : 정규화 실습용 비정규 테이블
--             (나쁜 설계 → 좋은 설계 비교 학습용)
-- ============================================================
 
-- ----------------------------------------------------------
-- 1-1. 비정규형 테이블 (Unnormalized / 이상 현상 학습)
--      핸드아웃 3-2 "이상 현상" 예시
-- ----------------------------------------------------------
CREATE TABLE order_details_raw (
    order_id          INT,
    customer_id       INT,
    customer_name     VARCHAR(50),
    restaurant_id     INT,
    restaurant_name   VARCHAR(100),
    restaurant_category VARCHAR(50),
    menu_name         VARCHAR(100),
    quantity          INT
) COMMENT '비정규형 — 삽입/갱신/삭제 이상 현상 학습용';
 
INSERT INTO order_details_raw VALUES
(1, 1, '김민준', 1, '부산치킨',   '치킨', '후라이드',  2),
(2, 1, '김민준', 2, '해운대짜장', '중식', '짜장면',    1),
(3, 2, '이수진', 1, '부산치킨',   '치킨', '양념치킨',  1),
(4, 3, '박지호', 3, '광안리버거', '버거', '불고기버거', 1),
(5, 2, '이수진', 3, '광안리버거', '버거', '치즈버거',  2),
(6, 4, '최유나', 2, '해운대짜장', '중식', '탕수육',    1);
 
-- 갱신 이상 확인용:
-- UPDATE order_details_raw SET restaurant_name = '부산1등치킨' WHERE restaurant_id = 1;
-- → restaurant_id=1 인 행(1,3번)을 모두 수정해야 함
 
-- ----------------------------------------------------------
-- 1-2. 1NF 위반 테이블 (한 셀에 여러 값)
--      핸드아웃 3-3 "1NF 위반 예시"
-- ----------------------------------------------------------
CREATE TABLE orders_bad (
    id          INT  NOT NULL AUTO_INCREMENT,
    customer_id INT  NOT NULL,
    menu_names  VARCHAR(300),   -- ← 1NF 위반: 쉼표로 여러 값
    PRIMARY KEY (id)
) COMMENT '1NF 위반 — 한 셀에 여러 메뉴 이름';
 
INSERT INTO orders_bad (customer_id, menu_names) VALUES
(1, '불고기버거,감자튀김,콜라'),
(2, '짜장면,탕수육'),
(3, '후라이드,양념치킨,뿌링클'),
(4, '비빔밥,된장찌개');
 
-- 1NF 위반 진단 쿼리 (치트시트 7-6):
-- SELECT id, menu_names FROM orders_bad WHERE menu_names LIKE '%,%';
 
-- ----------------------------------------------------------
-- 1-3. 2NF 위반 테이블 (부분 함수 종속)
--      핸드아웃 3-4 "2NF 위반 예시"
--      복합 PK (order_id, menu_id) 에서 일부 컬럼이 PK 전체가 아닌 일부에만 종속
-- ----------------------------------------------------------
CREATE TABLE order_menus_2nf_bad (
    order_id      INT          NOT NULL,
    menu_id       INT          NOT NULL,
    menu_name     VARCHAR(100) NOT NULL,   -- menu_id 에만 종속 → 2NF 위반
    price         INT          NOT NULL,   -- menu_id 에만 종속 → 2NF 위반
    customer_id   INT          NOT NULL,   -- order_id 에만 종속 → 2NF 위반
    customer_name VARCHAR(50)  NOT NULL,   -- order_id 에만 종속 → 2NF 위반
    quantity      INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (order_id, menu_id)
) COMMENT '2NF 위반 — 복합PK에서 부분 함수 종속';
 
INSERT INTO order_menus_2nf_bad VALUES
(1, 1, '후라이드',  15000, 1, '김민준', 2),
(1, 2, '양념치킨', 16000, 1, '김민준', 1),
(2, 3, '짜장면',   8000,  2, '이수진', 1),
(3, 4, '불고기버거',12000, 3, '박지호', 1),
(3, 5, '감자튀김', 3000,  3, '박지호', 2);
 
-- 2NF 위반 문제:
-- 김민준 → 이민준 으로 이름 바뀌면 order_id=1 인 행을 모두 수정해야 함
-- 후라이드 가격 바뀌면 menu_id=1 인 행을 모두 수정해야 함
 
-- ----------------------------------------------------------
-- 1-4. 3NF 위반 테이블 (이행 함수 종속)
--      핸드아웃 3-5 "3NF 위반 예시"
--      id → restaurant_id → restaurant_name (이행 종속)
-- ----------------------------------------------------------
CREATE TABLE menus_with_restaurant (
    id                  INT          NOT NULL AUTO_INCREMENT,
    menu_name           VARCHAR(100) NOT NULL,
    price               INT          NOT NULL,
    restaurant_id       INT          NOT NULL,
    restaurant_name     VARCHAR(100) NOT NULL,   -- restaurant_id 에 종속 → 3NF 위반
    restaurant_category VARCHAR(50)  NOT NULL,   -- restaurant_id 에 종속 → 3NF 위반
    PRIMARY KEY (id)
) COMMENT '3NF 위반 — 이행 함수 종속 (menu_id → restaurant_id → restaurant_name)';
 
INSERT INTO menus_with_restaurant VALUES
(1, '후라이드',   15000, 1, '부산치킨',   '치킨'),
(2, '양념치킨',  16000, 1, '부산치킨',   '치킨'),
(3, '뿌링클',    18000, 1, '부산치킨',   '치킨'),
(4, '짜장면',    8000,  2, '해운대짜장', '중식'),
(5, '짬뽕',      9000,  2, '해운대짜장', '중식'),
(6, '불고기버거', 12000, 3, '광안리버거', '버거');
 
-- 3NF 위반 문제:
-- '부산치킨' → '부산1등치킨' 변경 시 restaurant_id=1 인 행(1,2,3번) 모두 수정 필요
 
