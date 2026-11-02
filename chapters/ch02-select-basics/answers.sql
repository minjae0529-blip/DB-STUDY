-- Ch02 실습 — 부서 요청 처리하기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery02)
USE hanip_delivery02;

-- 문제 1. 메뉴판 할인가 ★
SELECT name,
    price,
    price * 0.9 AS sale_price
FROM menus
WHERE restaurant_id = 2
ORDER BY menu_id;

-- 문제 2. 입점 업종 ★
SELECT DISTINCT category
FROM restaurants
ORDER BY category;

-- 문제 3. 최근 취소 주문 ★
SELECT order_id,
    customer_id,
    restaurant_id,
    ordered_at
FROM orders
WHERE status = '취소'
ORDER BY ordered_at DESC
LIMIT 5;

-- 문제 4. 프리미엄 대표 메뉴 ★
SELECT menu_id,
    restaurant_id,
    name,
    price
FROM menus
WHERE is_signature = TRUE
    AND is_sold_out = FALSE
    AND price >= 15000
ORDER BY price DESC, menu_id;

-- 문제 5. 프로모션 문자 대상 ★★
SELECT name,
    grade,
    phone
FROM customers
WHERE marketing_agreed = TRUE
    AND grade IN ('골드', 'VIP')
ORDER BY customer_id;

-- 문제 6. 이메일 미등록 고객 ★★
SELECT name,
    phone
FROM customers
WHERE email IS NULL
ORDER BY joined_at;

-- 문제 7. 분식 메뉴 찾기 ★★
SELECT menu_id,
    name,
    price
FROM menus
WHERE name LIKE '%떡볶이%'
    OR name LIKE '%김밥%'
ORDER BY price, menu_id;

-- 문제 8. 3월 현장결제 ★★
SELECT COUNT(*) AS cnt
FROM orders
WHERE payment_method = '현장결제'
    AND status = '배달완료'
    AND ordered_at >= '2026-03-01'
    AND ordered_at < '2026-04-01';

-- 문제 9. 심야 영업 가게 ★★
SELECT name,
    open_time,
    close_time,
    is_open
FROM restaurants
WHERE close_time < open_time;

-- 문제 10. 전화 요청 주문 ★★
SELECT order_id,
    request_note,
    ordered_at
FROM orders
WHERE request_note LIKE '%전화%'
    AND ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01'
ORDER BY ordered_at DESC;

-- 문제 11. 메뉴 페이징 ★★★
SELECT menu_id,
    name,
    price
FROM menus
ORDER BY price, menu_id
LIMIT 8 OFFSET 16;

-- 문제 12. 데이터 품질 점검 ★★★
SELECT order_id,
    status,
    rider_id,
    delivered_at
FROM orders
WHERE status = '배달완료'
    AND (rider_id IS NULL OR delivered_at IS NULL);
