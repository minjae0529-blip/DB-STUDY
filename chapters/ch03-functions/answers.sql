-- Ch03 실습 — 데이터 가공하기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery03)
USE hanip_delivery03;

-- 문제 1. 이메일 도메인 현황 ★
SELECT DISTINCT SUBSTRING_INDEX(email, '@', -1) AS domain
FROM customers
WHERE email IS NOT NULL
ORDER BY domain;

-- 문제 2. 긴 메뉴명 점검 ★
SELECT menu_id,
    name,
    CHAR_LENGTH(name) AS name_length
FROM menus
WHERE CHAR_LENGTH(name) > 8
ORDER BY name_length DESC, menu_id;

-- 문제 3. 가게 카드 문구 ★
SELECT restaurant_id,
    CONCAT('[', category, '] ', name, ' (', district, ')') AS card_title
FROM restaurants
WHERE is_open = TRUE
ORDER BY restaurant_id;

-- 문제 4. 할인가 계산 ★
SELECT name,
    price,
    TRUNCATE(price * 0.85, -2) AS sale_price,
    price - TRUNCATE(price * 0.85, -2) AS discount
FROM menus
WHERE restaurant_id = 12
ORDER BY menu_id;

-- 문제 5. 주문 코드 만들기 ★★
SELECT order_id,
    CONCAT('HD-', DATE_FORMAT(ordered_at, '%y%m%d'), '-', LPAD(order_id, 5, '0')) AS order_code,
    status
FROM orders
WHERE ordered_at >= '2026-06-30'
ORDER BY order_id;

-- 문제 6. 지연 배달 리스트 ★★
SELECT order_id,
    ordered_at,
    TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS delivery_minutes
FROM orders
WHERE TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60
ORDER BY delivery_minutes DESC, order_id;

-- 문제 7. CASE 순서의 함정 ★★
SELECT name,
    CASE
        WHEN birth_date IS NULL THEN '미입력'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') < 30 THEN '20대 이하'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') < 40 THEN '30대'
        ELSE '40대 이상'
    END AS age_group
FROM customers
WHERE birth_date IS NULL;

-- 문제 8. 주말 주문 건수 ★★
SELECT COUNT(*) AS weekend_orders
FROM orders
WHERE status = '배달완료'
    AND ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01'
    AND DAYOFWEEK(ordered_at) IN (1, 7);

-- 문제 9. 가입 연차 구분 ★★
SELECT name,
    joined_at,
    DATEDIFF('2026-06-30', joined_at) AS days_since_join,
    CASE
        WHEN DATEDIFF('2026-06-30', joined_at) <= 90 THEN '신규'
        WHEN DATEDIFF('2026-06-30', joined_at) <= 365 THEN '1년 미만'
        ELSE '1년 이상'
    END AS member_type
FROM customers
ORDER BY joined_at DESC;

-- 문제 10. 낮은 별점 리뷰 ★★
SELECT review_id,
    order_id,
    REPEAT('★', rating) AS stars,
    IFNULL(content, '(별점만 남김)') AS content,
    created_at
FROM reviews
WHERE rating <= 2
ORDER BY created_at DESC;

-- 문제 11. 영업 상태 판정 ★★★
SELECT name,
    open_time,
    close_time,
    CASE
        WHEN is_open = FALSE THEN '폐업'
        WHEN close_time > open_time
            THEN IF('21:00:00' >= open_time AND '21:00:00' < close_time, '영업중', '영업종료')
        ELSE IF('21:00:00' >= open_time OR '21:00:00' < close_time, '영업중', '영업종료')
    END AS status_at_21
FROM restaurants
ORDER BY restaurant_id;

-- 문제 12. 웰컴 쿠폰 만료일 ★★★
SELECT name,
    DATE(joined_at) AS join_date,
    DATE_ADD(DATE(joined_at), INTERVAL 30 DAY) AS expires_on,
    IF(DATE_ADD(DATE(joined_at), INTERVAL 30 DAY) < '2026-06-30',
        '만료',
        CONCAT('D-', DATEDIFF(DATE_ADD(DATE(joined_at), INTERVAL 30 DAY), '2026-06-30'))
    ) AS coupon_status
FROM customers
WHERE joined_at >= '2026-01-01'
ORDER BY joined_at;
