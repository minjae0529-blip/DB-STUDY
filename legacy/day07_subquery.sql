-- =============================================================
--  한입배달 MySQL 10일 완성 — Day 7
--  주제: 서브쿼리 — 쿼리 안의 쿼리
--  대상: 한국IT교육센터 부산점
--  작성일: 2026-04-29
-- =============================================================

USE hanip_delivery;

-- =============================================================
-- PART 0. 서브쿼리 개념 도입
-- =============================================================
-- 핵심 질문:
--   "가격이 평균보다 비싼 메뉴를 찾고 싶다"
--
-- 문제: 메뉴 평균 가격을 모르는 상태에서 어떻게 필터링할까?

-- [1단계] 먼저 평균 가격을 구한다
SELECT AVG(price) AS 평균가격
FROM menus;
-- 예상 결과: 약 12,500

-- [2단계] 그 값(12500)을 직접 WHERE에 넣어 필터링한다
SELECT menu_name, price
FROM menus
WHERE price > 12500;

-- [문제점] 평균이 바뀌면 매번 다시 확인하고 숫자를 수정해야 한다
-- [해결책] 두 쿼리를 하나로 합친다 — 서브쿼리!

-- [서브쿼리 버전] 괄호 안 쿼리가 먼저 실행되고, 그 결과를 바깥 쿼리가 사용한다
SELECT menu_name, price
FROM menus
WHERE price > (SELECT AVG(price) FROM menus);

-- ★ 핵심 포인트
--   · 괄호 안을 먼저 실행 → 그 결과를 바깥 WHERE 조건으로 사용
--   · 평균이 바뀌어도 쿼리를 수정할 필요 없음
--   · "쿼리 안의 쿼리" = 서브쿼리(Subquery) = 중첩 쿼리

-- =============================================================
-- PART 1. WHERE절 서브쿼리
-- =============================================================

-- -------------------------------------------------------
-- 1-1. 단일행 서브쿼리 (결과가 1행 1열인 경우)
--       비교 연산자: =, !=, >, <, >=, <=
-- -------------------------------------------------------

-- [예제 1-1-A] 가격이 전체 평균 이상인 메뉴 목록
SELECT menu_name, price
FROM menus
WHERE price >= (SELECT AVG(price) FROM menus)
ORDER BY price DESC;

-- [예제 1-1-B] 가장 비싼 메뉴와 동일한 가격을 가진 메뉴 모두 조회
--   · MAX()가 단일 값을 반환하므로 = 사용 가능
SELECT menu_name, price
FROM menus
WHERE price = (SELECT MAX(price) FROM menus);

-- [예제 1-1-C] 가장 저렴한 메뉴보다 2000원 이상 비싼 메뉴
SELECT menu_name, price
FROM menus
WHERE price >= (SELECT MIN(price) FROM menus) + 2000
ORDER BY price;

-- [예제 1-1-D] 평균 주문금액 이상인 주문만 조회
--   · orders.total_price 기준 (또는 menus.price * quantity)
SELECT o.id        AS 주문번호,
       c.name      AS 고객명,
       m.menu_name AS 메뉴명,
       m.price     AS 가격
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN menus    m ON o.menu_id      = m.id
WHERE m.price >= (SELECT AVG(price) FROM menus)
ORDER BY m.price DESC;

-- -------------------------------------------------------
-- 1-2. 다중행 서브쿼리 (결과가 여러 행인 경우)
--       연산자: IN, NOT IN, ANY, ALL
-- -------------------------------------------------------

-- [예제 1-2-A] IN — 치킨 카테고리 가게의 모든 메뉴 조회
--   · 서브쿼리가 여러 restaurant_id를 반환 → IN 사용
SELECT m.menu_name, m.price, r.name AS 가게명
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.restaurant_id IN (
    SELECT id
    FROM restaurants
    WHERE category = '치킨'
)
ORDER BY r.name, m.price;

-- [예제 1-2-B] NOT IN — 한 번도 주문받지 않은 메뉴
--   · orders 테이블에 존재하지 않는 menu_id 찾기
SELECT menu_name, price
FROM menus
WHERE id NOT IN (
    SELECT DISTINCT menu_id
    FROM orders
)
ORDER BY menu_name;

-- ★ NOT IN 주의사항: 서브쿼리 결과에 NULL이 있으면 NOT IN이 항상 빈 결과 반환!
--   안전한 방법: NOT EXISTS 사용 (PART 4 참고)

-- [예제 1-2-C] ANY — 어느 한 가게의 최고가 메뉴보다 비싼 것
--   · > ANY(서브쿼리): 서브쿼리 결과 중 어느 값보다도 크면 TRUE
--   · = ANY(서브쿼리)는 IN과 동일
SELECT menu_name, price
FROM menus
WHERE price > ANY (
    SELECT MAX(price)
    FROM menus
    GROUP BY restaurant_id
)
ORDER BY price;

-- [예제 1-2-D] ALL — 모든 가게의 최고가 메뉴보다 비싼 것
--   · > ALL(서브쿼리): 서브쿼리의 모든 값보다 크면 TRUE
--   · = > (SELECT MAX(전체))와 동일한 결과지만, GROUP BY와 조합 시 유용
SELECT menu_name, price
FROM menus
WHERE price > ALL (
    SELECT MAX(price)
    FROM menus
    GROUP BY restaurant_id
)
ORDER BY price;

-- ANY vs ALL 직관적 비교:
--   > ANY  → "가장 낮은 값보다 크면 OK" (관대한 조건)
--   > ALL  → "가장 높은 값보다도 커야 OK" (엄격한 조건)

-- =============================================================
-- PART 2. FROM절 서브쿼리 (인라인 뷰, Inline View)
-- =============================================================
-- 비유: 1차 집계표(임시 테이블)를 먼저 만들고, 그 표에서 다시 분석
-- ★ 반드시 AS로 별칭을 부여해야 한다 (없으면 에러!)

-- [예제 2-A] 가게별 주문수를 먼저 집계한 뒤, 5건 이상인 가게만 필터링
SELECT 가게별집계.restaurant_id,
       가게별집계.주문수
FROM (
    SELECT restaurant_id,
           COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
) AS 가게별집계
WHERE 가게별집계.주문수 >= 5
ORDER BY 가게별집계.주문수 DESC;

-- [예제 2-B] 가게 이름까지 함께 보기 (인라인 뷰 + JOIN)
SELECT r.name      AS 가게명,
       집계.주문수
FROM (
    SELECT restaurant_id,
           COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
) AS 집계
JOIN restaurants r ON 집계.restaurant_id = r.id
WHERE 집계.주문수 >= 5
ORDER BY 집계.주문수 DESC;

-- [예제 2-C] 카테고리별 가게 수 + 카테고리 평균 메뉴 수
SELECT 카테고리집계.category  AS 카테고리,
       카테고리집계.가게수,
       메뉴집계.카테고리평균메뉴수
FROM (
    SELECT category,
           COUNT(*) AS 가게수
    FROM restaurants
    GROUP BY category
) AS 카테고리집계
JOIN (
    SELECT r.category,
           ROUND(COUNT(m.id) / COUNT(DISTINCT r.id), 1) AS 카테고리평균메뉴수
    FROM restaurants r
    LEFT JOIN menus m ON r.id = m.restaurant_id
    GROUP BY r.category
) AS 메뉴집계 ON 카테고리집계.category = 메뉴집계.category
ORDER BY 카테고리집계.가게수 DESC;

-- [예제 2-D] 주문수 기준 상위 3개 가게의 메뉴 전체 조회
SELECT r.name      AS 가게명,
       m.menu_name AS 메뉴명,
       m.price     AS 가격
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.restaurant_id IN (
    SELECT restaurant_id
    FROM (
        SELECT restaurant_id,
               COUNT(*) AS cnt
        FROM orders
        GROUP BY restaurant_id
        ORDER BY cnt DESC
        LIMIT 3
    ) AS 상위3가게
)
ORDER BY r.name, m.price DESC;

-- =============================================================
-- PART 3. SELECT절 스칼라 서브쿼리 (Scalar Subquery)
-- =============================================================
-- 특징: 각 행마다 단일 값(1행 1열)을 반환하는 서브쿼리
--       컬럼처럼 사용하며, 반드시 1행 1열만 반환해야 함

-- [예제 3-A] 각 메뉴 옆에 전체 평균 가격 표시 + 평균과의 차이
SELECT menu_name                                          AS 메뉴명,
       price                                              AS 가격,
       (SELECT AVG(price) FROM menus)                    AS 전체평균,
       price - (SELECT AVG(price) FROM menus)            AS 평균과의_차이,
       CASE
           WHEN price > (SELECT AVG(price) FROM menus) THEN '평균초과'
           WHEN price = (SELECT AVG(price) FROM menus) THEN '평균일치'
           ELSE '평균미만'
       END                                               AS 평균비교
FROM menus
ORDER BY price DESC;

-- [예제 3-B] 각 주문 옆에 해당 가게의 총 주문수 함께 표시
SELECT o.id                              AS 주문번호,
       r.name                            AS 가게명,
       m.menu_name                       AS 메뉴명,
       (
           SELECT COUNT(*)
           FROM orders o2
           WHERE o2.restaurant_id = o.restaurant_id
       )                                 AS 해당가게_총주문수
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
JOIN menus      m ON o.menu_id        = m.id
ORDER BY 해당가게_총주문수 DESC, o.id;

-- [예제 3-C] 각 가게의 메뉴 수를 restaurants 옆에 표시
SELECT id    AS 가게번호,
       name  AS 가게명,
       (
           SELECT COUNT(*)
           FROM menus m
           WHERE m.restaurant_id = r.id
       )     AS 메뉴수
FROM restaurants r
ORDER BY 메뉴수 DESC;

-- ★ 성능 주의: 스칼라 서브쿼리는 행마다 한 번씩 실행됨
--   데이터가 많으면 JOIN으로 바꾸는 것이 빠를 수 있다

-- =============================================================
-- PART 4. EXISTS / NOT EXISTS
-- =============================================================
-- EXISTS: 서브쿼리 결과가 1건이라도 존재하면 TRUE
-- NOT EXISTS: 서브쿼리 결과가 0건이면 TRUE
-- · IN/NOT IN보다 NULL에 안전하고, 존재 여부만 확인하므로 빠름

-- [예제 4-A] EXISTS — 주문이 1건 이상 있는 가게만 조회
SELECT r.id, r.name, r.category
FROM restaurants r
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.restaurant_id = r.id
)
ORDER BY r.name;

-- [예제 4-B] NOT EXISTS — 주문이 한 건도 없는 가게 조회
SELECT r.id, r.name, r.category
FROM restaurants r
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.restaurant_id = r.id
)
ORDER BY r.name;

-- [비교] LEFT JOIN IS NULL 방법과 동일한 결과
SELECT r.id, r.name, r.category
FROM restaurants r
LEFT JOIN orders o ON r.id = o.restaurant_id
WHERE o.id IS NULL
ORDER BY r.name;

-- ★ NOT EXISTS vs LEFT JOIN IS NULL vs NOT IN 비교
-- ┌─────────────────┬──────────────┬─────────────────────────────┐
-- │ 방법            │ NULL 안전?   │ 특징                        │
-- ├─────────────────┼──────────────┼─────────────────────────────┤
-- │ NOT EXISTS      │ 안전         │ 존재 여부만 확인, 가독성 좋음│
-- │ LEFT JOIN IS NULL│ 안전        │ OUTER JOIN 개념 이해 필요    │
-- │ NOT IN          │ 위험(NULL시 │ 간단하지만 NULL 주의 필요    │
-- │                 │ 빈결과 반환) │                             │
-- └─────────────────┴──────────────┴─────────────────────────────┘

-- [예제 4-C] 주문한 적 없는 고객 찾기 (NOT EXISTS 버전)
SELECT c.id, c.name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);

-- [비교] LEFT JOIN IS NULL 버전
SELECT c.id, c.name
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.id IS NULL;

-- =============================================================
-- PART 5. UNION / UNION ALL
-- =============================================================
-- UNION    : 두 SELECT 결과를 합치되, 중복 행 제거
-- UNION ALL: 두 SELECT 결과를 합치고, 중복 행 포함
--
-- 규칙:
--   1) 두 SELECT의 컬럼 수가 같아야 한다
--   2) 대응하는 컬럼의 데이터 타입이 호환되어야 한다
--   3) 컬럼 이름은 첫 번째 SELECT의 이름을 따른다

-- [예제 5-A] 한식 가게명과 치킨 가게명을 구분 컬럼과 함께 합치기
SELECT name, '한식' AS 카테고리구분
FROM restaurants
WHERE category = '한식'
UNION
SELECT name, '치킨'
FROM restaurants
WHERE category = '치킨'
ORDER BY 카테고리구분, name;

-- [예제 5-B] UNION (중복 제거) vs UNION ALL (중복 포함) 직접 비교
-- 중복이 발생하는 상황: 동일한 SELECT를 두 번 합칠 때
SELECT name FROM restaurants WHERE category = '한식'
UNION
SELECT name FROM restaurants WHERE category = '한식';
-- → 중복 제거되어 원본과 동일한 결과

SELECT name FROM restaurants WHERE category = '한식'
UNION ALL
SELECT name FROM restaurants WHERE category = '한식';
-- → 행이 2배로 나옴

-- [예제 5-C] 고가 메뉴(20,000원 이상)와 저가 메뉴(5,000원 이하) 한번에 보기
SELECT menu_name, price, '고가메뉴' AS 구분
FROM menus
WHERE price >= 20000
UNION ALL
SELECT menu_name, price, '저가메뉴'
FROM menus
WHERE price <= 5000
ORDER BY price DESC;

-- [예제 5-D] 카테고리별 최고가 메뉴를 UNION으로 합치기
-- (GROUP BY를 사용할 수 없는 상황에서 UNION 활용 예시)
SELECT '한식' AS 카테고리, menu_name, price
FROM menus
WHERE restaurant_id IN (SELECT id FROM restaurants WHERE category = '한식')
  AND price = (
      SELECT MAX(m2.price)
      FROM menus m2
      WHERE m2.restaurant_id IN (SELECT id FROM restaurants WHERE category = '한식')
  )
UNION ALL
SELECT '치킨', menu_name, price
FROM menus
WHERE restaurant_id IN (SELECT id FROM restaurants WHERE category = '치킨')
  AND price = (
      SELECT MAX(m2.price)
      FROM menus m2
      WHERE m2.restaurant_id IN (SELECT id FROM restaurants WHERE category = '치킨')
  )
ORDER BY price DESC;

-- =============================================================
-- PART 6. 실전 시나리오 5개
-- =============================================================

-- -------------------------------------------------------
-- [시나리오 1] 사장님이 알고 싶어합니다:
--   "우리 가게 메뉴 중에 전체 평균 가격보다 비싼 메뉴가 몇 개나 있나요?"
-- -------------------------------------------------------
-- 특정 가게(예: id = 1)의 메뉴를 전체 평균과 비교
SELECT r.name                        AS 가게명,
       COUNT(*)                       AS 평균초과_메뉴수,
       (SELECT AVG(price) FROM menus) AS 전체평균가격
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.restaurant_id = 1
  AND m.price > (SELECT AVG(price) FROM menus)
GROUP BY r.name;

-- -------------------------------------------------------
-- [시나리오 2] 운영팀이 알고 싶어합니다:
--   "지난달 주문수가 가장 많았던 TOP 3 가게와 그 가게의 전체 메뉴를 보여주세요"
-- -------------------------------------------------------
SELECT r.name       AS 가게명,
       m.menu_name  AS 메뉴명,
       m.price      AS 가격,
       순위표.주문수
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
JOIN (
    SELECT restaurant_id,
           COUNT(*) AS 주문수,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS 순위
    FROM orders
    WHERE order_date >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01')
      AND order_date <  DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY restaurant_id
    HAVING 순위 <= 3
) AS 순위표 ON r.id = 순위표.restaurant_id
ORDER BY 순위표.주문수 DESC, r.name, m.price DESC;

-- -------------------------------------------------------
-- [시나리오 3] 운영팀이 알고 싶어합니다:
--   "한 번도 주문한 적 없는 고객에게 쿠폰을 발송하려 합니다. 대상자 명단을 뽑아주세요"
-- -------------------------------------------------------
SELECT c.id    AS 고객번호,
       c.name  AS 이름,
       c.phone AS 전화번호
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
)
ORDER BY c.id;

-- -------------------------------------------------------
-- [시나리오 4] 사장님이 알고 싶어합니다:
--   "우리 가게 메뉴별로, 그 메뉴를 주문한 고객이 몇 명인지 알고 싶어요.
--    한 번도 주문 안 된 메뉴도 포함해서요"
-- -------------------------------------------------------
SELECT m.menu_name                     AS 메뉴명,
       m.price                         AS 가격,
       IFNULL(주문집계.주문횟수, 0)    AS 총주문횟수
FROM menus m
LEFT JOIN (
    SELECT menu_id,
           COUNT(*) AS 주문횟수
    FROM orders
    GROUP BY menu_id
) AS 주문집계 ON m.id = 주문집계.menu_id
ORDER BY 총주문횟수 DESC, m.price DESC;

-- -------------------------------------------------------
-- [시나리오 5] 운영팀이 알고 싶어합니다:
--   "카테고리별로, 해당 카테고리 평균 주문금액 이상인 주문만 집계해서
--    카테고리별 '우수 주문' 건수를 보여주세요"
-- -------------------------------------------------------
SELECT r.category                AS 카테고리,
       COUNT(o.id)               AS 우수주문건수,
       카테고리평균.avg_price    AS 카테고리평균가격
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
JOIN menus       m ON o.menu_id       = m.id
JOIN (
    SELECT r2.category,
           AVG(m2.price) AS avg_price
    FROM orders o2
    JOIN restaurants r2 ON o2.restaurant_id = r2.id
    JOIN menus       m2 ON o2.menu_id       = m2.id
    GROUP BY r2.category
) AS 카테고리평균 ON r.category = 카테고리평균.category
WHERE m.price >= 카테고리평균.avg_price
GROUP BY r.category, 카테고리평균.avg_price
ORDER BY 우수주문건수 DESC;

-- =============================================================
-- END OF DAY 7
-- =============================================================
