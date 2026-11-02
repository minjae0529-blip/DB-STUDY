-- =============================================================
--  Ch03. 함수로 데이터 가공하기 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery03)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery03;


-- -------------------------------------------------------------
-- 0. 함수 사용의 기본
-- -------------------------------------------------------------
SELECT UPPER('hanip'), CHAR_LENGTH('한입배달'), 7 / 2;


-- -------------------------------------------------------------
-- 1-1. 붙이기 — 앱 화면용 가게 이름
-- -------------------------------------------------------------
SELECT CONCAT('[', category, '] ', name) AS display_name,
    CONCAT_WS(' · ', district, category) AS tag
FROM restaurants
ORDER BY restaurant_id;


-- -------------------------------------------------------------
-- 1-2. 글자 수 vs 바이트 수
-- -------------------------------------------------------------
SELECT name,
    CHAR_LENGTH(name) AS char_count,
    LENGTH(name) AS byte_count
FROM menus
ORDER BY CHAR_LENGTH(name) DESC, menu_id;


-- -------------------------------------------------------------
-- 1-3. 자르기 — 이메일 도메인, 전화번호 가리기
-- -------------------------------------------------------------
SELECT email,
    SUBSTRING_INDEX(email, '@', 1)  AS account,
    SUBSTRING_INDEX(email, '@', -1) AS domain
FROM customers
WHERE email IS NOT NULL;

SELECT name,
    phone,
    CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS masked_phone
FROM customers;


-- -------------------------------------------------------------
-- 1-4. 바꾸기·채우기 — 주소 줄이기, 주문 코드
-- -------------------------------------------------------------
SELECT name,
    address,
    REPLACE(address, '부산광역시 ', '') AS short_address
FROM restaurants;

SELECT order_id,
    CONCAT('HD-', LPAD(order_id, 6, '0')) AS order_code
FROM orders
ORDER BY order_id DESC;


-- -------------------------------------------------------------
-- 2-1. 할인가 계산 — 단위가 중요하다
-- -------------------------------------------------------------
SELECT name,
    price,
    price * 0.85                 AS raw_price,
    ROUND(price * 0.85, -2)      AS rounded,
    TRUNCATE(price * 0.85, -2)   AS truncated
FROM menus
WHERE restaurant_id = 12;


-- -------------------------------------------------------------
-- 2-2. 1인분 가격 — 나눗셈과 올림
-- -------------------------------------------------------------
SELECT name,
    price,
    price / 2          AS per_person,
    CEIL(price / 2)    AS per_person_ceil,
    price DIV 2        AS per_person_div
FROM menus
WHERE name LIKE '%2인%';


-- -------------------------------------------------------------
-- 3-1. 꺼내기
-- -------------------------------------------------------------
SELECT order_id,
    ordered_at,
    DATE(ordered_at)       AS order_date,
    HOUR(ordered_at)       AS order_hour,
    DAYOFWEEK(ordered_at)  AS dow
FROM orders
WHERE ordered_at >= '2026-06-30';


-- -------------------------------------------------------------
-- 3-2. 형식 바꾸기 — DATE_FORMAT
-- -------------------------------------------------------------
SELECT order_id,
    DATE_FORMAT(ordered_at, '%Y-%m-%d') AS order_date,
    DATE_FORMAT(ordered_at, '%c월 %e일 %H:%i') AS display_time,
    DATE_FORMAT(ordered_at, '%Y-%m') AS order_month
FROM orders
ORDER BY order_id DESC;


-- -------------------------------------------------------------
-- 3-3. 차이 구하기 — DATEDIFF, TIMESTAMPDIFF
-- -------------------------------------------------------------
SELECT order_id,
    ordered_at,
    delivered_at,
    TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS delivery_minutes
FROM orders
WHERE status = '배달완료'
ORDER BY delivery_minutes DESC, order_id;

SELECT name,
    joined_at,
    DATEDIFF('2026-06-30', joined_at) AS days_since_join,
    birth_date,
    TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') AS age
FROM customers
ORDER BY customer_id;


-- -------------------------------------------------------------
-- 3-4. 더하고 빼기 — DATE_ADD, DATE_SUB
-- -------------------------------------------------------------
SELECT name,
    joined_at,
    DATE_ADD(joined_at, INTERVAL 30 DAY)  AS welcome_coupon_expires,
    DATE_SUB('2026-06-30', INTERVAL 3 MONTH) AS three_months_ago
FROM customers
WHERE joined_at >= '2026-01-01';


-- -------------------------------------------------------------
-- 4. 형 변환 — CAST
-- -------------------------------------------------------------
SELECT '10' + 5          AS implicit_num,
    CONCAT(10, '개')     AS implicit_str,
    CAST('2026-06-30' AS DATE) AS to_date,
    CAST(9900.0 AS SIGNED)     AS to_int;


-- -------------------------------------------------------------
-- 5-1. IF — 둘 중 하나
-- -------------------------------------------------------------
SELECT name,
    price,
    IF(price >= 20000, '고가', '일반') AS price_level
FROM menus
WHERE restaurant_id = 6;


-- -------------------------------------------------------------
-- 5-2. CASE — 여러 갈래
-- -------------------------------------------------------------
SELECT order_id,
    TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS minutes,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) <= 30 THEN '빠름'
        WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) <= 60 THEN '보통'
        ELSE '지연'
    END AS speed
FROM orders
WHERE status = '배달완료'
    AND ordered_at >= '2026-06-29';

SELECT DISTINCT payment_method,
    CASE payment_method
        WHEN '카드' THEN 'CARD'
        WHEN '간편결제' THEN 'EASY_PAY'
        WHEN '계좌이체' THEN 'TRANSFER'
        ELSE 'ON_SITE'
    END AS payment_code
FROM orders;


-- -------------------------------------------------------------
-- 5-3. NULL 처리 — IFNULL, COALESCE, NULLIF
-- -------------------------------------------------------------
SELECT name,
    email,
    IFNULL(email, '(미등록)') AS email_display,
    COALESCE(email, phone) AS contact
FROM customers
ORDER BY email IS NULL DESC, customer_id;

SELECT name,
    IFNULL(phone, '전화 없음 — 앱 채팅 문의') AS phone_display
FROM restaurants
ORDER BY phone IS NULL DESC, restaurant_id;


-- -------------------------------------------------------------
-- 6. ⚠️ NULL이 섞이면 결과도 NULL
-- -------------------------------------------------------------
SELECT 10000 + NULL               AS plus_null,
    CONCAT('메일: ', NULL)        AS concat_null,
    CONCAT_WS(' / ', '김민준', NULL, '부산진구') AS concat_ws_skip,
    CHAR_LENGTH(NULL)             AS len_null;

SELECT name,
    CONCAT(name, ' <', email, '>') AS mail_to
FROM customers
ORDER BY email IS NULL DESC, customer_id;


-- -------------------------------------------------------------
-- NULLIF — 0으로 나누기 방지
-- -------------------------------------------------------------
SELECT 10 / 0             AS divide_by_zero,
    10 / NULLIF(0, 0)     AS safe_divide;


-- -------------------------------------------------------------
-- 7. WHERE와 ORDER BY에서도 함수를 쓸 수 있다
-- -------------------------------------------------------------
SELECT order_id, ordered_at, status
FROM orders
WHERE DAYOFWEEK(ordered_at) IN (1, 7)        -- 일요일, 토요일
    AND ordered_at >= '2026-06-27'
    AND ordered_at < '2026-06-29'
ORDER BY HOUR(ordered_at), order_id;


-- -------------------------------------------------------------
-- 8. 오늘의 요청 해결
-- -------------------------------------------------------------
SELECT name,
    CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS masked_phone,
    birth_date,
    TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') AS age,
    CASE
        WHEN birth_date IS NULL THEN '미입력'
        ELSE CONCAT(FLOOR(TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') / 10) * 10, '대')
    END AS age_group,
    DATEDIFF('2026-06-30', joined_at) AS days_since_join
FROM customers
ORDER BY customer_id;

