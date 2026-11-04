-- =============================================================
--  한입배달 MySQL 10일 완성 — Day 6
--  JOIN: 흩어진 퍼즐 맞추기
--  한국IT교육센터 부산점
-- =============================================================

USE hanip_delivery;

-- =============================================================
-- PART 0: 왜 JOIN이 필요한가?
-- =============================================================
-- Day 5에서 배운 GROUP BY 결과를 다시 봅시다.
-- 아래 쿼리를 실행하면 restaurant_id(숫자)만 나옵니다.

SELECT restaurant_id, SUM(total_price) AS 총매출
FROM orders
GROUP BY restaurant_id
ORDER BY 총매출 DESC;

-- 결과 예시:
-- +---------------+----------+
-- | restaurant_id | 총매출    |
-- +---------------+----------+
-- |             3 |   245000 |
-- |             1 |   198000 |
-- |             7 |   176000 |
-- +---------------+----------+
-- "3번 가게가 어디야? 이름이 뭐야?" — 숫자만으로는 의미를 알 수 없습니다.
-- 해결책: restaurants 테이블과 연결해서 이름을 함께 보여줘야 합니다.
-- 그것이 바로 JOIN입니다!


-- =============================================================
-- PART 1: INNER JOIN — "양쪽 모두 매칭되는 것만"
-- =============================================================

-- [ 기본 문법 ]
-- SELECT 컬럼들
-- FROM   테이블A
--   INNER JOIN 테이블B  ON  테이블A.공통키 = 테이블B.공통키
-- WHERE  조건 (선택)
--
-- 핵심 포인트:
--   1. ON 뒤에 어떤 컬럼끼리 연결할지 지정
--   2. 두 테이블 모두에 일치하는 행만 결과에 포함
--   3. 어느 한 쪽에만 있으면 결과에서 빠짐

-- ---------------------------------------------------------------
-- 1-1. orders ↔ restaurants JOIN (restaurant_id 기준)
-- ---------------------------------------------------------------
-- "주문 내역에 가게 이름을 같이 보여줘"

SELECT
    o.id          AS 주문번호,
    r.name        AS 가게이름,
    r.category    AS 카테고리,
    o.total_price AS 주문금액,
    o.order_date  AS 주문일시
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
ORDER BY o.order_date DESC
LIMIT 10;

-- ---------------------------------------------------------------
-- 1-2. orders ↔ customers JOIN (customer_id 기준)
-- ---------------------------------------------------------------
-- "어떤 고객이 주문했는지 이름을 같이 보여줘"

SELECT
    o.id          AS 주문번호,
    c.name        AS 고객이름,
    c.phone       AS 연락처,
    o.total_price AS 주문금액,
    o.status      AS 배달상태
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
ORDER BY o.id DESC
LIMIT 10;

-- ---------------------------------------------------------------
-- 1-3. orders ↔ menus JOIN (menu_id 기준)
-- ---------------------------------------------------------------
-- "어떤 메뉴를 주문했는지 메뉴 이름을 같이 보여줘"

SELECT
    o.id          AS 주문번호,
    m.menu_name   AS 메뉴명,
    m.price       AS 단가,
    o.quantity    AS 수량,
    o.total_price AS 주문금액
FROM orders AS o
    INNER JOIN menus AS m ON o.menu_id = m.id
ORDER BY o.id;

-- ---------------------------------------------------------------
-- 1-4. 3테이블 JOIN: orders + restaurants + customers
-- ---------------------------------------------------------------
-- "주문번호, 고객명, 가게명, 주문금액을 한번에 보고 싶어"

SELECT
    o.id          AS 주문번호,
    c.name        AS 고객이름,
    r.name        AS 가게이름,
    o.total_price AS 주문금액,
    o.order_date  AS 주문일시
FROM orders AS o
    INNER JOIN restaurants AS r  ON o.restaurant_id = r.id
    INNER JOIN customers   AS c  ON o.customer_id   = c.id
ORDER BY o.order_date DESC;

-- ---------------------------------------------------------------
-- 1-5. 4테이블 JOIN: orders + restaurants + customers + menus
-- ---------------------------------------------------------------
-- "주문의 모든 정보를 한 화면에"

SELECT
    o.id          AS 주문번호,
    c.name        AS 고객이름,
    r.name        AS 가게이름,
    m.menu_name   AS 메뉴명,
    o.quantity    AS 수량,
    o.total_price AS 주문금액,
    o.delivery_fee AS 배달비,
    o.order_date  AS 주문일시,
    o.status      AS 상태
FROM orders AS o
    INNER JOIN restaurants AS r  ON o.restaurant_id = r.id
    INNER JOIN customers   AS c  ON o.customer_id   = c.id
    INNER JOIN menus       AS m  ON o.menu_id        = m.id
ORDER BY o.id;

-- ---------------------------------------------------------------
-- 1-6. 별칭(AS) 없이 쓰면 어떻게 될까? — 비교 예시
-- ---------------------------------------------------------------
-- 컬럼명이 충돌하면 에러 발생 → 별칭을 꼭 써야 합니다.

-- 아래는 name이 여러 테이블에 있어 에러 납니다:
-- SELECT id, name FROM orders INNER JOIN customers ON orders.customer_id = customers.id;
-- Error: Column 'id' in field list is ambiguous

-- 올바른 작성 (테이블명.컬럼명 또는 별칭 사용):
SELECT
    o.id       AS 주문번호,
    c.name     AS 고객이름
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
LIMIT 5;


-- =============================================================
-- PART 2: LEFT JOIN — "출석부 (결석자도 이름이 있어야 함)"
-- =============================================================

-- [ 개념 ]
-- INNER JOIN: 양쪽 모두 일치하는 행만 반환
-- LEFT  JOIN: 왼쪽(FROM) 테이블의 행은 모두 반환,
--             오른쪽에 없으면 NULL로 채움
--
-- 비유: 출석부에는 결석한 학생 이름도 남아 있어야 합니다.

-- ---------------------------------------------------------------
-- 2-1. 주문 0건인 고객도 포함해서 조회 (customers 9, 10번 확인)
-- ---------------------------------------------------------------

SELECT
    c.id          AS 고객번호,
    c.name        AS 고객이름,
    c.phone       AS 연락처,
    o.id          AS 주문번호,   -- 주문 없으면 NULL
    o.total_price AS 주문금액    -- 주문 없으면 NULL
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
ORDER BY c.id;

-- 결과를 보면 9번, 10번 고객 행의 주문번호와 주문금액이 NULL입니다.

-- ---------------------------------------------------------------
-- 2-2. 주문 0건인 고객만 필터링 (WHERE o.id IS NULL)
-- ---------------------------------------------------------------
-- 비즈니스 맥락: "한 번도 주문 안 한 고객에게 쿠폰을 보내면 매출 UP!"

SELECT
    c.id       AS 고객번호,
    c.name     AS 고객이름,
    c.phone    AS 연락처,
    c.email    AS 이메일
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
WHERE o.id IS NULL   -- 오른쪽 테이블의 값이 NULL = 조인 실패 = 주문 없음
ORDER BY c.id;

-- ---------------------------------------------------------------
-- 2-3. 주문 0건인 가게 찾기 (restaurants 10번 확인)
-- ---------------------------------------------------------------

SELECT
    r.id       AS 가게번호,
    r.name     AS 가게이름,
    r.category AS 카테고리,
    o.id       AS 주문번호    -- 주문 없으면 NULL
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
WHERE o.id IS NULL
ORDER BY r.id;

-- ---------------------------------------------------------------
-- 2-4. 전체 고객 + 주문 건수 (주문 0건 고객도 포함)
-- ---------------------------------------------------------------

SELECT
    c.id         AS 고객번호,
    c.name       AS 고객이름,
    COUNT(o.id)  AS 주문건수   -- NULL은 COUNT에서 무시 → 0으로 집계됨
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
GROUP BY c.id, c.name
ORDER BY 주문건수 DESC;


-- =============================================================
-- PART 3: RIGHT JOIN — "방향만 반대"
-- =============================================================

-- LEFT JOIN의 오른쪽 ↔ 왼쪽을 뒤집은 것.
-- 실무에서는 LEFT JOIN으로 대체 가능하므로 간단히만 봅니다.

-- ---------------------------------------------------------------
-- 3-1. restaurants 기준 → 모든 가게 + 주문 건수 (없으면 NULL → 0)
-- ---------------------------------------------------------------

SELECT
    r.id                     AS 가게번호,
    r.name                   AS 가게이름,
    IFNULL(COUNT(o.id), 0)   AS 주문건수   -- NULL이면 0으로 표시
FROM orders AS o
    RIGHT JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name
ORDER BY 주문건수 DESC;

-- ※ 위와 동일한 결과를 LEFT JOIN으로 표현하면:
SELECT
    r.id                     AS 가게번호,
    r.name                   AS 가게이름,
    IFNULL(COUNT(o.id), 0)   AS 주문건수
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
GROUP BY r.id, r.name
ORDER BY 주문건수 DESC;


-- =============================================================
-- PART 4: CROSS JOIN & SELF JOIN
-- =============================================================

-- ---------------------------------------------------------------
-- 4-1. CROSS JOIN — 두 테이블의 모든 조합 생성 (학습 목적)
-- ---------------------------------------------------------------
-- ON 조건 없이 모든 행 × 모든 행 = 카테시안 곱
-- 메뉴(30행) × 고객(10행) = 300행

-- 실제로 실행하면 300행이 나옵니다. 학습 목적으로만 사용.
SELECT
    c.name      AS 고객이름,
    m.menu_name AS 메뉴이름,
    m.price     AS 가격
FROM customers AS c
    CROSS JOIN menus AS m
LIMIT 20;  -- 전체 300행 중 20개만 확인

-- ---------------------------------------------------------------
-- 4-2. SELF JOIN — 같은 테이블을 두 번 참조
-- ---------------------------------------------------------------
-- 같은 카테고리를 가진 가게끼리 조합 찾기

SELECT
    r1.name     AS 가게A,
    r2.name     AS 가게B,
    r1.category AS 공통카테고리
FROM restaurants AS r1
    INNER JOIN restaurants AS r2
        ON  r1.category = r2.category
        AND r1.id < r2.id   -- 중복 쌍 제거 (A-B, B-A 방지)
ORDER BY r1.category, r1.name;


-- =============================================================
-- PART 5: JOIN + GROUP BY 조합 (실전 핵심)
-- =============================================================
-- 이 파트가 이 수업의 클라이맥스입니다!
-- JOIN으로 테이블을 연결한 뒤 GROUP BY로 요약하면
-- 숫자 ID가 아닌 실제 이름으로 통계를 볼 수 있습니다.

-- ---------------------------------------------------------------
-- 5-1. 가게 이름별 총 매출 랭킹
-- ---------------------------------------------------------------

SELECT
    r.name        AS 가게이름,
    r.category    AS 카테고리,
    COUNT(o.id)   AS 주문건수,
    SUM(o.total_price) AS 총매출,
    AVG(o.total_price) AS 평균주문금액
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name, r.category
ORDER BY 총매출 DESC;

-- ---------------------------------------------------------------
-- 5-2. 카테고리별 평균 주문금액
-- ---------------------------------------------------------------

SELECT
    r.category         AS 카테고리,
    COUNT(o.id)        AS 주문건수,
    ROUND(AVG(o.total_price), 0) AS 평균주문금액,
    SUM(o.total_price) AS 카테고리총매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.category
ORDER BY 평균주문금액 DESC;

-- ---------------------------------------------------------------
-- 5-3. 고객 이름별 주문 내역 요약
-- ---------------------------------------------------------------

SELECT
    c.name             AS 고객이름,
    COUNT(o.id)        AS 총주문건수,
    SUM(o.total_price) AS 총결제금액,
    MAX(o.order_date)  AS 마지막주문일
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY 총결제금액 DESC;

-- ---------------------------------------------------------------
-- 5-4. 월별 + 카테고리별 매출
-- ---------------------------------------------------------------

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS 월,
    r.category                          AS 카테고리,
    COUNT(o.id)                         AS 주문건수,
    SUM(o.total_price)                  AS 월매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY 월, r.category
ORDER BY 월 DESC, 월매출 DESC;

-- ---------------------------------------------------------------
-- 5-5. 인기 메뉴 TOP 5 (주문 횟수 기준)
-- ---------------------------------------------------------------

SELECT
    m.menu_name        AS 메뉴이름,
    r.name             AS 가게이름,
    COUNT(o.id)        AS 주문횟수,
    SUM(o.total_price) AS 총매출
FROM orders AS o
    INNER JOIN menus       AS m ON o.menu_id        = m.id
    INNER JOIN restaurants AS r ON o.restaurant_id  = r.id
GROUP BY m.id, m.menu_name, r.name
ORDER BY 주문횟수 DESC
LIMIT 5;


-- =============================================================
-- PART 6: 실전 시나리오 쿼리 (복잡도 낮 → 높)
-- =============================================================

-- ---------------------------------------------------------------
-- 시나리오 1 [쉬움]: 각 주문의 가게 이름과 주문금액만 보기
-- ---------------------------------------------------------------
-- 운영팀: "주문 목록을 가게 이름과 함께 출력해 주세요."

SELECT
    o.id          AS 주문번호,
    r.name        AS 가게이름,
    o.total_price AS 주문금액
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
ORDER BY o.id;

-- ---------------------------------------------------------------
-- 시나리오 2 [쉬움]: 치킨 카테고리 가게에서 발생한 주문만 보기
-- ---------------------------------------------------------------
-- 운영팀: "치킨 카테고리 주문 내역만 뽑아 주세요."

SELECT
    o.id          AS 주문번호,
    r.name        AS 가게이름,
    c.name        AS 고객이름,
    o.total_price AS 주문금액,
    o.order_date  AS 주문일시
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
    INNER JOIN customers   AS c ON o.customer_id   = c.id
WHERE r.category = '치킨'
ORDER BY o.order_date DESC;

-- ---------------------------------------------------------------
-- 시나리오 3 [중간]: 가게별 주문 건수 & 총매출 (주문 없는 가게 포함)
-- ---------------------------------------------------------------
-- 대표님: "모든 가게의 실적을 보고 싶습니다. 주문 없는 가게도요."

SELECT
    r.name               AS 가게이름,
    r.category           AS 카테고리,
    COUNT(o.id)          AS 주문건수,
    IFNULL(SUM(o.total_price), 0) AS 총매출
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
GROUP BY r.id, r.name, r.category
ORDER BY 총매출 DESC;

-- ---------------------------------------------------------------
-- 시나리오 4 [중간]: 한 번도 주문하지 않은 고객 리스트
-- ---------------------------------------------------------------
-- 마케팅팀: "아직 첫 주문을 안 한 고객에게 웰컴 쿠폰을 보내려 합니다."

SELECT
    c.id    AS 고객번호,
    c.name  AS 고객이름,
    c.phone AS 연락처,
    c.email AS 이메일
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
WHERE o.id IS NULL
ORDER BY c.id;

-- ---------------------------------------------------------------
-- 시나리오 5 [높음]: 주문금액 합계가 50,000원 이상인 고객 랭킹
-- ---------------------------------------------------------------
-- VIP 팀: "누적 결제금액이 5만 원 이상인 고객을 내림차순으로 보여 주세요."

SELECT
    c.name              AS 고객이름,
    c.phone             AS 연락처,
    COUNT(o.id)         AS 총주문건수,
    SUM(o.total_price)  AS 누적결제금액
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
GROUP BY c.id, c.name, c.phone
HAVING SUM(o.total_price) >= 50000
ORDER BY 누적결제금액 DESC;

-- ---------------------------------------------------------------
-- 시나리오 6 [높음]: 최근 한 달 가게별 메뉴 판매 현황 (4테이블 JOIN)
-- ---------------------------------------------------------------
-- 분석팀: "이번 달 가게별 메뉴 판매 현황을 메뉴명 수준으로 집계해 주세요."

SELECT
    r.name             AS 가게이름,
    m.menu_name        AS 메뉴명,
    COUNT(o.id)        AS 판매횟수,
    SUM(o.quantity)    AS 총판매수량,
    SUM(o.total_price) AS 메뉴별매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
    INNER JOIN menus       AS m ON o.menu_id        = m.id
WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY r.id, r.name, m.id, m.menu_name
ORDER BY r.name, 판매횟수 DESC;

-- =============================================================
-- End of day06_join.sql
-- =============================================================
