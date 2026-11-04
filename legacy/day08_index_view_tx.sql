-- =============================================================
--  한입배달 MySQL 10일 완성 — Day 8
--  성능과 안전: 인덱스, 뷰, 트랜잭션
--  한국IT교육센터 부산점
-- =============================================================

USE hanip_delivery;

-- =============================================================
-- PART 0: 오늘의 3가지 불편함
-- =============================================================
-- Day 7까지 배운 쿼리들을 실제로 운영하다 보면 3가지 불편함이 생깁니다.
--
-- 1. 데이터가 늘어날수록 쿼리가 느려요
--    → 해결책: INDEX (인덱스)
--
-- 2. 복잡한 쿼리를 매번 다시 쓰기 귀찮아요
--    → 해결책: VIEW (뷰)
--
-- 3. 주문 처리 도중 에러가 나면 어떡하죠?
--    → 해결책: TRANSACTION (트랜잭션)
--
-- 오늘 수업에서 이 세 가지를 순서대로 해결합니다.


-- =============================================================
-- PART 1: INDEX (인덱스)
-- =============================================================
-- 비유: 500페이지짜리 책에서 "김민준"을 찾을 때
--   목차 없이 → 1페이지부터 500페이지까지 전부 뒤짐 (풀스캔)
--   목차 있으면 → 목차에서 "ㄱ" 항목 찾아서 바로 이동 (인덱스 스캔)

-- ---------------------------------------------------------------
-- 1-1. EXPLAIN: 인덱스 없을 때 (풀스캔 확인)
-- ---------------------------------------------------------------
-- customer_id = 3인 주문을 찾는 쿼리를 실행 계획으로 확인합니다.
-- type 컬럼에 "ALL"이 나타나면 테이블 전체를 읽는 풀스캔입니다.

EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
-- 결과 예시:
-- +----+-------------+--------+------+---------------+------+---------+------+------+-------------+
-- | id | select_type | table  | type | possible_keys | key  | key_len | ref  | rows | Extra       |
-- +----+-------------+--------+------+---------------+------+---------+------+------+-------------+
-- |  1 | SIMPLE      | orders | ALL  | NULL          | NULL | NULL    | NULL |   50 | Using where |
-- +----+-------------+--------+------+---------------+------+---------+------+------+-------------+
--
-- type=ALL: "모든 행을 다 읽겠다" → 느림
-- rows=50: 50건 전체를 스캔 (실제로 찾는 건 몇 건인데도!)

-- ---------------------------------------------------------------
-- 1-2. 인덱스 생성
-- ---------------------------------------------------------------
-- 문법: CREATE INDEX 인덱스명 ON 테이블명(컬럼명);

-- orders 테이블에서 자주 WHERE 조건으로 쓰이는 컬럼에 인덱스 추가
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_date       ON orders(order_date);

-- ---------------------------------------------------------------
-- 1-3. EXPLAIN: 인덱스 있을 때 (인덱스 스캔 확인)
-- ---------------------------------------------------------------
-- 같은 쿼리를 다시 실행하면 type이 달라집니다.

EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
-- 결과 예시:
-- +----+-------------+--------+------+-------------------------+----------------------+---------+-------+------+-------+
-- | id | select_type | table  | type | possible_keys           | key                  | key_len | ref   | rows | Extra |
-- +----+-------------+--------+------+-------------------------+----------------------+---------+-------+------+-------+
-- |  1 | SIMPLE      | orders | ref  | idx_orders_customer     | idx_orders_customer  |       5 | const |    6 | NULL  |
-- +----+-------------+--------+------+-------------------------+----------------------+---------+-------+------+-------+
--
-- type=ref: 인덱스를 통해 매칭되는 행만 읽음 → 빠름
-- rows=6: 50건 대신 6건만 읽음!
-- key=idx_orders_customer: 실제로 사용된 인덱스 이름

-- EXPLAIN의 type 컬럼 의미 요약:
-- ALL   → 풀스캔 (가장 느림, 개선 필요)
-- index → 인덱스 전체 스캔 (ALL보다 낫지만 비효율)
-- range → 인덱스 범위 스캔 (BETWEEN, > 등)
-- ref   → 인덱스로 매칭 (단일 값 조건, 효율적)
-- const → 단 1건으로 확정 (PK나 UNIQUE, 가장 빠름)

-- ---------------------------------------------------------------
-- 1-4. 인덱스 확인 / 삭제
-- ---------------------------------------------------------------

-- 현재 orders 테이블의 인덱스 목록 조회
SHOW INDEX FROM orders;
-- Non_unique=0이면 UNIQUE 인덱스
-- Non_unique=1이면 일반 인덱스
-- Key_name=PRIMARY가 기본 키 (PK는 자동으로 인덱스가 만들어짐)

-- ---------------------------------------------------------------
-- 1-5. 복합 인덱스 (두 컬럼을 함께 인덱스로 묶기)
-- ---------------------------------------------------------------
-- WHERE customer_id = ? AND order_date >= ? 처럼
-- 두 컬럼을 동시에 조건으로 쓸 때 복합 인덱스가 효과적입니다.
-- 순서 중요: 자주 단독으로 쓰이는 컬럼을 앞에!

CREATE INDEX idx_orders_cust_date ON orders(customer_id, order_date);

-- 복합 인덱스 사용 확인
EXPLAIN SELECT * FROM orders WHERE customer_id = 3 AND order_date >= '2024-01-01';

-- ---------------------------------------------------------------
-- 1-6. 인덱스 삭제
-- ---------------------------------------------------------------

DROP INDEX idx_orders_cust_date ON orders;

-- ---------------------------------------------------------------
-- 1-7. 인덱스 설계 가이드
-- ---------------------------------------------------------------
-- [걸면 좋은 경우]
--   ① WHERE 절에 자주 등장하는 컬럼           (예: customer_id, status)
--   ② JOIN의 ON 조건에 사용되는 컬럼          (FK 컬럼: restaurant_id 등)
--   ③ ORDER BY, GROUP BY에 자주 쓰이는 컬럼   (예: order_date)
--
-- [주의: 과유불급]
--   인덱스는 SELECT를 빠르게 하지만,
--   INSERT/UPDATE/DELETE는 인덱스도 함께 수정해야 해서 느려집니다.
--   "목차가 50개면 책이 오히려 더 두꺼워집니다."
--
-- [거의 효과 없는 경우]
--   - 컬럼 값의 종류가 너무 적을 때 (예: status가 '완료'/'취소' 2가지뿐)
--   - 데이터 건수가 매우 적을 때 (수백 건 이하)
--   - LIKE '%키워드%' 같은 앞에 %가 붙은 검색


-- =============================================================
-- PART 2: VIEW (뷰)
-- =============================================================
-- 비유: 즐겨찾기 (복잡한 쿼리를 저장해 두고 간단히 호출)
-- "저장된 SELECT 쿼리"라고 생각하면 됩니다.
-- 실행할 때마다 최신 데이터를 반영합니다. (스냅샷이 아님!)

-- ---------------------------------------------------------------
-- 2-1. 복잡한 JOIN+GROUP BY 쿼리를 VIEW로 저장
-- ---------------------------------------------------------------
-- 이 쿼리를 매번 쓰기는 너무 길고 힘듭니다.
-- VIEW로 저장하면 테이블처럼 간단히 조회할 수 있습니다.

CREATE VIEW v_restaurant_stats AS
SELECT
    r.id                                   AS id,
    r.name                                 AS name,
    r.category                             AS category,
    COUNT(o.id)                            AS 주문수,
    IFNULL(SUM(o.total_price), 0)          AS 총매출,
    IFNULL(ROUND(AVG(o.total_price)), 0)   AS 평균주문금액
FROM restaurants r
    LEFT JOIN orders o ON r.id = o.restaurant_id
GROUP BY r.id, r.name, r.category;

-- ---------------------------------------------------------------
-- 2-2. VIEW 사용 — 일반 테이블처럼 SELECT
-- ---------------------------------------------------------------

-- 전체 조회 (일반 테이블과 동일한 문법)
SELECT * FROM v_restaurant_stats ORDER BY 총매출 DESC;

-- WHERE 조건 추가
SELECT * FROM v_restaurant_stats WHERE category = '치킨';

-- 주문이 한 건도 없는 가게만 보기
SELECT * FROM v_restaurant_stats WHERE 주문수 = 0;

-- VIEW에 또 WHERE 추가 — 완전히 일반 테이블처럼 사용
SELECT name, 총매출
FROM v_restaurant_stats
WHERE 총매출 > 50000
ORDER BY 총매출 DESC;

-- VIEW + GROUP BY도 가능 (카테고리별 통계 재집계)
SELECT category, SUM(총매출) AS 카테고리총매출, SUM(주문수) AS 카테고리주문수
FROM v_restaurant_stats
GROUP BY category
ORDER BY 카테고리총매출 DESC;

-- ---------------------------------------------------------------
-- 2-3. 두 번째 VIEW: 활성 고객 (최소 1건 이상 주문한 고객)
-- ---------------------------------------------------------------

CREATE VIEW v_active_customers AS
SELECT
    c.id                  AS id,
    c.name                AS name,
    c.phone               AS phone,
    COUNT(o.id)           AS 주문수,
    SUM(o.total_price)    AS 총결제금액,
    MAX(o.order_date)     AS 마지막주문일
FROM customers c
    JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.phone;

-- 사용 예시
SELECT * FROM v_active_customers ORDER BY 총결제금액 DESC;
SELECT * FROM v_active_customers WHERE 주문수 >= 5;

-- ---------------------------------------------------------------
-- 2-4. VIEW 목록 확인
-- ---------------------------------------------------------------

SHOW FULL TABLES WHERE Table_type = 'VIEW';
-- Table_type 컬럼이 'VIEW'인 항목만 표시됩니다.

-- ---------------------------------------------------------------
-- 2-5. VIEW 삭제
-- ---------------------------------------------------------------

DROP VIEW IF EXISTS v_restaurant_stats;
DROP VIEW IF EXISTS v_active_customers;

-- ※ 삭제 후 다시 실습하려면 2-1과 2-3의 CREATE VIEW를 재실행하세요.

-- ---------------------------------------------------------------
-- 2-6. VIEW의 주요 특징 정리 (주석으로 확인)
-- ---------------------------------------------------------------
-- [VIEW가 편리한 이유]
--   - 복잡한 쿼리에 이름을 붙여 재사용 가능
--   - 쿼리 실수를 줄임 (한 번 잘 만들어 두면 계속 쓰면 됨)
--   - 보안: 특정 컬럼(예: 고객 주민번호, 비밀번호)을 제외한 뷰를 만들어 공유
--
-- [VIEW의 한계]
--   - 저장된 데이터가 아닌 저장된 쿼리 → 조회할 때마다 쿼리가 실행됨
--   - 매우 복잡한 VIEW는 오히려 성능이 나빠질 수 있음
--   - 대부분의 경우 INSERT/UPDATE는 제한됨 (읽기 전용으로 사용 권장)


-- =============================================================
-- PART 3: TRANSACTION (트랜잭션)
-- =============================================================
-- 비유: 계좌이체 — "올 오어 낫씽(All or Nothing)"
--
-- A 계좌 -10만원 + B 계좌 +10만원 이 동시에 완료되어야 합니다.
-- A 계좌에서만 돈이 빠지고 B 계좌에 넣기 전에 에러가 나면?
-- → 두 작업을 하나의 트랜잭션으로 묶으면, 에러 시 A 차감도 취소됩니다.
--
-- 트랜잭션의 4가지 성질 (ACID):
--   A - Atomicity  (원자성): 전부 성공 또는 전부 취소
--   C - Consistency(일관성): 트랜잭션 전후 데이터 규칙이 일관되게 유지
--   I - Isolation  (격리성): 동시에 여러 트랜잭션이 실행돼도 서로 간섭 안 함
--   D - Durability (지속성): COMMIT된 데이터는 장애가 나도 유지됨

-- ---------------------------------------------------------------
-- 3-1. 기본 COMMIT / ROLLBACK
-- ---------------------------------------------------------------
-- START TRANSACTION: 트랜잭션 시작 (AUTO COMMIT 잠시 비활성화)
-- COMMIT:            변경사항을 확정하여 DB에 영구 저장
-- ROLLBACK:          변경사항을 취소하고 트랜잭션 시작 이전으로 되돌림

-- [실습 A] 가격 일괄 인상 후 ROLLBACK 해보기
START TRANSACTION;

-- 1번 가게 메뉴 전체 10% 가격 인상
UPDATE menus SET price = price * 1.1 WHERE restaurant_id = 1;

-- 결과 확인 (트랜잭션 내에서는 변경이 보임)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

-- "이 가격 인상은 취소하겠습니다"
ROLLBACK;

-- ROLLBACK 후 다시 확인 (원래 가격으로 돌아옴)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;


-- [실습 B] 가격 인상 후 COMMIT 해보기
START TRANSACTION;

UPDATE menus SET price = price * 1.1 WHERE restaurant_id = 1;

SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

-- "이 가격 인상을 확정하겠습니다"
COMMIT;

-- COMMIT 후 다시 확인 (인상된 가격이 유지됨)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

-- 실습용 원복 (실습 마치면 원래 가격으로 되돌리기)
UPDATE menus SET price = ROUND(price / 1.1) WHERE restaurant_id = 1;

-- ---------------------------------------------------------------
-- 3-2. 주문 처리 트랜잭션 실습 — 정상 케이스
-- ---------------------------------------------------------------
-- 시나리오: 고객 1번이 가게 1번의 메뉴 1번을 2개 주문
-- 주문 INSERT가 성공하면 COMMIT, 실패하면 ROLLBACK

START TRANSACTION;

-- 주문 데이터 삽입
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (1, 1, 1, 2, 20000, NOW(), 3000);

-- 삽입된 주문 확인
SELECT * FROM orders ORDER BY id DESC LIMIT 3;

-- 이상 없으면 COMMIT
COMMIT;

-- COMMIT 후 최종 확인
SELECT * FROM orders ORDER BY id DESC LIMIT 3;

-- ---------------------------------------------------------------
-- 3-3. 주문 처리 트랜잭션 실습 — ROLLBACK 케이스 (FK 에러)
-- ---------------------------------------------------------------
-- 시나리오: 존재하지 않는 customer_id 999로 주문 시도
-- → FK 제약조건 위반 에러 → ROLLBACK

START TRANSACTION;

-- customer_id 999번 고객은 존재하지 않음 → FK 에러 예정
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (999, 1, 1, 1, 10000, NOW(), 3000);
-- ERROR 1452: Cannot add or update a child row: a foreign key constraint fails

-- FK 에러가 났으니 이 트랜잭션 전체를 취소
ROLLBACK;

-- ROLLBACK 후 확인 (마지막 주문이 이전 실습에서 추가한 것 그대로)
SELECT * FROM orders ORDER BY id DESC LIMIT 3;

-- ---------------------------------------------------------------
-- 3-4. SAVEPOINT — 부분 롤백
-- ---------------------------------------------------------------
-- 트랜잭션 내에서 중간 저장점을 만들어 두고,
-- 이후 작업이 실패하면 처음부터가 아니라 저장점까지만 되돌릴 수 있습니다.
-- 비유: 게임 세이브포인트

START TRANSACTION;

-- 첫 번째 주문 삽입 (성공)
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (2, 2, 4, 1, 12000, NOW(), 3000);

-- 첫 번째 삽입 직후 저장점 생성
SAVEPOINT order_inserted;

-- 두 번째 작업 시도 (여기서 에러가 났다고 가정)
-- INSERT INTO orders (...) VALUES (999, 2, 4, 1, 12000, NOW(), 3000);  -- 에러!

-- 에러 발생 시 저장점까지만 롤백 (첫 번째 삽입은 유지)
-- ROLLBACK TO order_inserted;

-- 이후 처리가 정상이면 전체 COMMIT
COMMIT;

-- COMMIT 후 확인 (두 번째 주문까지 저장됨)
SELECT * FROM orders ORDER BY id DESC LIMIT 5;

-- ---------------------------------------------------------------
-- 3-5. AUTO COMMIT 확인
-- ---------------------------------------------------------------
-- MySQL은 기본적으로 AUTO COMMIT이 켜져 있습니다.
-- START TRANSACTION 없이 실행한 SQL은 즉시 COMMIT됩니다.

-- AUTO COMMIT 현재 설정 확인
SHOW VARIABLES LIKE 'autocommit';
-- Value=ON: 켜져 있음 (기본값)

-- AUTO COMMIT 끄기 (세션 단위, 재접속하면 다시 ON)
-- SET autocommit = 0;

-- AUTO COMMIT 다시 켜기
-- SET autocommit = 1;

-- ※ 실무에서는 AUTO COMMIT을 끄기보다
--   필요한 경우에만 START TRANSACTION ~ COMMIT/ROLLBACK 패턴을 쓰는 것을 권장합니다.

-- ---------------------------------------------------------------
-- 3-6. 트랜잭션 요약 패턴
-- ---------------------------------------------------------------
-- [기본 패턴]
--
--   START TRANSACTION;
--   -- 여러 DML 실행 (INSERT, UPDATE, DELETE)
--   -- 중간 확인 (SELECT)
--   COMMIT;      ← 이상 없으면
--   -- 또는
--   ROLLBACK;    ← 문제 있으면
--
-- [SAVEPOINT 패턴]
--
--   START TRANSACTION;
--   -- 작업1
--   SAVEPOINT sp1;
--   -- 작업2 (실패 가능성)
--   ROLLBACK TO sp1;  ← 작업2만 취소, 작업1은 유지
--   COMMIT;

-- =============================================================
-- End of day08_index_view_tx.sql
-- =============================================================
