-- =============================================================
--  Ch02. SELECT 기본 — 원하는 행과 열만 정확하게 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery02)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery02;


-- -------------------------------------------------------------
-- 1-1. 필요한 열만, 원하는 순서로
-- -------------------------------------------------------------
SELECT name, price, restaurant_id
FROM menus;


-- -------------------------------------------------------------
-- 1-2. 계산식
-- -------------------------------------------------------------
SELECT name,
    price,
    price * 1.1,
    price - 1000
FROM menus;


-- -------------------------------------------------------------
-- 1-3. 별칭 (AS)
-- -------------------------------------------------------------
SELECT name AS menu_name,
    price AS current_price,
    price + 500 AS price_after_raise
FROM menus;


-- -------------------------------------------------------------
-- 1-4. DISTINCT — 중복 제거
-- -------------------------------------------------------------
SELECT category FROM restaurants;

SELECT DISTINCT category FROM restaurants;

SELECT DISTINCT district, category
FROM restaurants;


-- -------------------------------------------------------------
-- 2-1. 비교 연산자
-- -------------------------------------------------------------
SELECT name, district, delivery_fee
FROM restaurants
WHERE category = '치킨';

SELECT name, price
FROM menus
WHERE price >= 20000;

SELECT name, opened_at
FROM restaurants
WHERE opened_at >= '2025-01-01';

SELECT name, restaurant_id
FROM menus
WHERE is_sold_out = TRUE;


-- -------------------------------------------------------------
-- 2-2. 논리 연산자 — AND, OR, NOT
-- -------------------------------------------------------------
SELECT name, category, district
FROM restaurants
WHERE district = '수영구'
    AND category <> '카페·디저트';


-- -------------------------------------------------------------
-- 2-3. ⚠️ AND와 OR가 섞이면 — 괄호!
-- -------------------------------------------------------------
SELECT name, category, district
FROM restaurants
WHERE district = '부산진구' OR district = '수영구' AND category = '한식';

SELECT name, category, district
FROM restaurants
WHERE (district = '부산진구' OR district = '수영구')
    AND category = '한식';


-- -------------------------------------------------------------
-- 2-4. BETWEEN — 범위
-- -------------------------------------------------------------
SELECT name, price
FROM menus
WHERE price BETWEEN 10000 AND 12000;


-- -------------------------------------------------------------
-- ⚠️ 날짜·시각 범위의 함정
-- -------------------------------------------------------------
SELECT COUNT(*) AS june_orders
FROM orders
WHERE ordered_at BETWEEN '2026-06-01' AND '2026-06-30';

SELECT COUNT(*) AS june_orders
FROM orders
WHERE ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01';

SELECT order_id, ordered_at, status
FROM orders
WHERE ordered_at >= '2026-06-30';


-- -------------------------------------------------------------
-- 2-5. IN — 목록 중 하나
-- -------------------------------------------------------------
SELECT name, category, district
FROM restaurants
WHERE category IN ('치킨', '피자', '분식');

SELECT order_id, status, ordered_at
FROM orders
WHERE status NOT IN ('배달완료', '취소');


-- -------------------------------------------------------------
-- 2-6. LIKE — 문자열 패턴
-- -------------------------------------------------------------
SELECT name, price, restaurant_id
FROM menus
WHERE name LIKE '%치킨%';

SELECT name
FROM menus
WHERE name LIKE '_밀면';

SELECT name, address
FROM customers
WHERE address LIKE '%전포동%';


-- -------------------------------------------------------------
-- 2-7. NULL — "값이 없음"
-- -------------------------------------------------------------
SELECT name, email
FROM customers
WHERE email = NULL;

SELECT name, phone, email
FROM customers
WHERE email IS NULL;

SELECT order_id, status, rider_id, delivered_at
FROM orders
WHERE rider_id IS NULL
LIMIT 5;


-- -------------------------------------------------------------
-- NULL은 `<>`에도 걸리지 않는다
-- -------------------------------------------------------------
SELECT COUNT(*) AS not_naver
FROM customers
WHERE email NOT LIKE '%@naver.com';

SELECT COUNT(*) AS not_naver_or_unknown
FROM customers
WHERE email NOT LIKE '%@naver.com'
    OR email IS NULL;


-- -------------------------------------------------------------
-- 3. ORDER BY — 정렬
-- -------------------------------------------------------------
SELECT name, price
FROM menus
ORDER BY price DESC;


-- -------------------------------------------------------------
-- 여러 기준으로 정렬
-- -------------------------------------------------------------
SELECT name, delivery_fee, min_order_amount
FROM restaurants
WHERE is_open = TRUE
ORDER BY delivery_fee ASC, min_order_amount ASC;


-- -------------------------------------------------------------
-- 별칭으로 정렬
-- -------------------------------------------------------------
SELECT name,
    price,
    price * 1.1 AS price_with_vat
FROM menus
ORDER BY price_with_vat DESC;


-- -------------------------------------------------------------
-- NULL의 정렬 위치
-- -------------------------------------------------------------
SELECT name, birth_date
FROM customers
ORDER BY birth_date;


-- -------------------------------------------------------------
-- Top-N
-- -------------------------------------------------------------
SELECT name, price
FROM menus
ORDER BY price DESC
LIMIT 3;


-- -------------------------------------------------------------
-- 페이지 나누기
-- -------------------------------------------------------------
SELECT menu_id, name, price
FROM menus
ORDER BY menu_id
LIMIT 5 OFFSET 5;    -- 2페이지: 앞의 5개를 건너뛰고 5개


-- -------------------------------------------------------------
-- ⚠️ 동점이 있는 Top-N
-- -------------------------------------------------------------
SELECT name, price
FROM menus
ORDER BY price DESC
LIMIT 5;

SELECT menu_id, name, price
FROM menus
ORDER BY price DESC, menu_id
LIMIT 5;


-- -------------------------------------------------------------
-- 6. 논리적 실행 순서
-- -------------------------------------------------------------
-- ⚠ 에러 예제
SELECT name, price * 1.1 AS price_with_vat
FROM menus
WHERE price_with_vat > 20000;

SELECT name, price * 1.1 AS price_with_vat
FROM menus
WHERE price * 1.1 > 20000
ORDER BY price_with_vat DESC;


-- -------------------------------------------------------------
-- 8. 오늘의 요청 해결
-- -------------------------------------------------------------
SELECT name,
    district,
    category,
    min_order_amount,
    delivery_fee
FROM restaurants
WHERE district IN ('부산진구', '수영구')
    AND is_open = TRUE
    AND min_order_amount <= 15000
ORDER BY delivery_fee, min_order_amount;

