-- Ch05 실습 — 흩어진 데이터 잇기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery05)
USE hanip_delivery05;

-- 문제 1. 치킨집 메뉴판 ★
SELECT r.name AS restaurant_name,
    m.name AS menu_name,
    m.price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
WHERE r.category = '치킨'
ORDER BY r.restaurant_id, m.price DESC;

-- 문제 2. 기사별 배달 실적 ★
SELECT rd.name AS rider_name,
    rd.vehicle,
    COUNT(*) AS deliveries
FROM orders o
JOIN riders rd ON o.rider_id = rd.rider_id
WHERE o.status = '배달완료'
GROUP BY rd.rider_id, rd.name, rd.vehicle
ORDER BY deliveries DESC;

-- 문제 3. 낮은 별점 리뷰 추적 ★
SELECT rv.review_id,
    rv.rating,
    r.name AS restaurant_name,
    c.name AS customer_name,
    rv.content
FROM reviews rv
JOIN orders o      ON rv.order_id     = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
JOIN customers c   ON o.customer_id   = c.customer_id
WHERE rv.rating <= 2
ORDER BY rv.created_at DESC;

-- 문제 4. 진행 중 주문 현황판 ★
SELECT o.order_id,
    o.status,
    c.name AS customer_name,
    r.name AS restaurant_name,
    rd.name AS rider_name
FROM orders o
JOIN customers c   ON o.customer_id   = c.customer_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN riders rd ON o.rider_id     = rd.rider_id
WHERE o.status IN ('접수', '조리중', '배달중')
ORDER BY o.order_id;

-- 문제 5. 가게별 평균 별점 ★★
SELECT r.name AS restaurant_name,
    ROUND(AVG(rv.rating), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM reviews rv
JOIN orders o      ON rv.order_id     = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC;

-- 문제 6. 메뉴 판매량 Top 5 ★★
SELECT r.name AS restaurant_name,
    m.name AS menu_name,
    SUM(oi.quantity) AS sold_quantity
FROM order_items oi
JOIN orders o      ON oi.order_id     = o.order_id
JOIN menus m       ON oi.menu_id      = m.menu_id
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY m.menu_id, m.name, r.name
ORDER BY sold_quantity DESC, m.menu_id
LIMIT 5;

-- 문제 7. 업종별 음식 매출 ★★
SELECT r.category,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity * oi.unit_price) AS food_sales
FROM orders o
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.category
ORDER BY food_sales DESC;

-- 문제 8. 한 번도 안 팔린 메뉴 ★★
SELECT m.menu_id,
    m.name AS menu_name,
    r.name AS restaurant_name
FROM menus m
JOIN restaurants r      ON m.restaurant_id = r.restaurant_id
LEFT JOIN order_items oi ON m.menu_id      = oi.menu_id
WHERE oi.order_item_id IS NULL
ORDER BY m.menu_id;

-- 문제 9. 고객별 주문 수 (0건 포함) ★★
SELECT c.name AS customer_name,
    c.grade,
    COUNT(o.order_id) AS delivered_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.status = '배달완료'
GROUP BY c.customer_id, c.name, c.grade
ORDER BY delivered_orders, c.customer_id;

-- 문제 10. 활동 종료 기사의 마지막 배달 ★★
SELECT rd.name AS rider_name,
    rd.hired_at,
    COUNT(o.order_id) AS deliveries,
    MAX(o.delivered_at) AS last_delivered_at
FROM riders rd
LEFT JOIN orders o
    ON rd.rider_id = o.rider_id
    AND o.status = '배달완료'
WHERE rd.is_active = FALSE
GROUP BY rd.rider_id, rd.name, rd.hired_at;

-- 문제 11. 인상 전 가격으로 팔린 메뉴 ★★
SELECT m.name AS menu_name,
    oi.unit_price,
    m.price AS current_price,
    SUM(oi.quantity) AS sold_quantity
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN menus m  ON oi.menu_id  = m.menu_id
WHERE o.status = '배달완료'
    AND oi.unit_price <> m.price
GROUP BY m.menu_id, m.name, oi.unit_price, m.price
ORDER BY m.menu_id;

-- 문제 12. 다른 구에서 시킨 주문 ★★★
SELECT COUNT(*) AS delivered_orders,
    SUM(CASE WHEN c.district <> r.district THEN 1 ELSE 0 END) AS cross_district,
    ROUND(SUM(CASE WHEN c.district <> r.district THEN 1 ELSE 0 END) * 100 / COUNT(*), 1) AS cross_rate
FROM orders o
JOIN customers c   ON o.customer_id   = c.customer_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료';

-- 문제 13. 리뷰 작성률 ★★★
SELECT r.name AS restaurant_name,
    COUNT(*) AS delivered_orders,
    COUNT(rv.review_id) AS reviewed,
    ROUND(COUNT(rv.review_id) * 100 / COUNT(*), 1) AS review_rate
FROM orders o
JOIN restaurants r   ON o.restaurant_id = r.restaurant_id
LEFT JOIN reviews rv ON o.order_id      = rv.order_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY review_rate DESC;

-- 문제 14. 월 × 업종 매출 피벗 ★★★
SELECT DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
    SUM(CASE WHEN r.category = '한식' THEN oi.quantity * oi.unit_price ELSE 0 END) AS korean,
    SUM(CASE WHEN r.category = '중식' THEN oi.quantity * oi.unit_price ELSE 0 END) AS chinese,
    SUM(CASE WHEN r.category = '치킨' THEN oi.quantity * oi.unit_price ELSE 0 END) AS chicken,
    SUM(CASE WHEN r.category = '피자' THEN oi.quantity * oi.unit_price ELSE 0 END) AS pizza,
    SUM(oi.quantity * oi.unit_price) AS all_categories
FROM orders o
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
