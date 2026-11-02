-- Ch04 실습 — 숫자로 요약하기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery04)
USE hanip_delivery04;

-- 문제 1. 메뉴 가격 요약 ★
SELECT COUNT(*) AS menu_count,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price)) AS avg_price
FROM menus;

-- 문제 2. 업종별 가게 수 ★
SELECT category,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE is_open = TRUE
GROUP BY category
ORDER BY restaurant_count DESC, category;

-- 문제 3. 별점 분포 ★
SELECT rating,
    COUNT(*) AS review_count,
    COUNT(*) - COUNT(content) AS rating_only
FROM reviews
GROUP BY rating
ORDER BY rating DESC;

-- 문제 4. 리뷰 평균 별점 ★
SELECT ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100 / 511, 1) AS review_rate
FROM reviews;

-- 문제 5. 등급별 고객 현황 ★★
SELECT grade,
    COUNT(*) AS members,
    SUM(marketing_agreed) AS marketing_agreed,
    COUNT(email) AS with_email
FROM customers
GROUP BY grade
ORDER BY CASE grade
        WHEN 'VIP' THEN 1
        WHEN '골드' THEN 2
        WHEN '실버' THEN 3
        ELSE 4
    END;

-- 문제 6. 결제 수단별 실적 ★★
SELECT payment_method,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(discount_amount)) AS avg_discount,
    SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END) AS discounted_orders
FROM orders
WHERE status = '배달완료'
GROUP BY payment_method
ORDER BY delivered_orders DESC;

-- 문제 7. 피크 시간대 ★★
SELECT HOUR(ordered_at) AS order_hour,
    COUNT(*) AS delivered_orders
FROM orders
WHERE status = '배달완료'
GROUP BY order_hour
ORDER BY delivered_orders DESC, order_hour
LIMIT 5;

-- 문제 8. 단골 고객 ★★
SELECT customer_id,
    COUNT(*) AS order_count,
    DATE_FORMAT(MIN(ordered_at), '%Y-%m-%d') AS first_order,
    DATE_FORMAT(MAX(ordered_at), '%Y-%m-%d') AS last_order
FROM orders
WHERE status = '배달완료'
GROUP BY customer_id
HAVING COUNT(*) >= 30
ORDER BY order_count DESC, customer_id;

-- 문제 9. 큰 주문 ★★
SELECT order_id,
    COUNT(*) AS item_lines,
    SUM(quantity * unit_price) AS food_amount
FROM order_items
GROUP BY order_id
ORDER BY food_amount DESC, order_id
LIMIT 5;

-- 문제 10. 가격 인상 효과 ★★
SELECT unit_price,
    SUM(quantity) AS sold_quantity,
    SUM(quantity * unit_price) AS sales_amount
FROM order_items
WHERE menu_id = 1
GROUP BY unit_price
ORDER BY unit_price;

-- 문제 11. 기사별 배달 실적 ★★★
SELECT rider_id,
    COUNT(*) AS deliveries,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_minutes,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60 THEN 1 ELSE 0 END) AS late_count,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60 THEN 1 ELSE 0 END) * 100 / COUNT(*), 1) AS late_rate
FROM orders
WHERE status = '배달완료'
GROUP BY rider_id
ORDER BY deliveries DESC, rider_id;

-- 문제 12. 월 × 결제 수단 피벗 ★★★
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    SUM(CASE WHEN payment_method = '카드' THEN 1 ELSE 0 END) AS card,
    SUM(CASE WHEN payment_method = '간편결제' THEN 1 ELSE 0 END) AS easy_pay,
    SUM(CASE WHEN payment_method = '계좌이체' THEN 1 ELSE 0 END) AS transfer,
    SUM(CASE WHEN payment_method = '현장결제' THEN 1 ELSE 0 END) AS on_site,
    COUNT(*) AS total
FROM orders
WHERE status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
