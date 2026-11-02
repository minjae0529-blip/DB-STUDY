-- =============================================================
--  Ch06. 서브쿼리·집합·윈도우 함수 — 쿼리 안의 쿼리, 그리고 순위 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery06)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery06;


-- -------------------------------------------------------------
-- 1. 서브쿼리 — 먼저 구해야 하는 값이 있을 때
-- -------------------------------------------------------------
SELECT AVG(price) FROM menus;

SELECT name, price
FROM menus
WHERE price > (SELECT AVG(price) FROM menus)
ORDER BY price DESC;


-- -------------------------------------------------------------
-- 서브쿼리가 돌려주는 세 가지 모양
-- -------------------------------------------------------------
-- ⚠ 에러 예제
SELECT name, price
FROM menus
WHERE price > (SELECT price FROM menus WHERE restaurant_id = 6);


-- -------------------------------------------------------------
-- 2. 목록 서브쿼리 — IN
-- -------------------------------------------------------------
SELECT order_id, restaurant_id, ordered_at, status
FROM orders
WHERE restaurant_id IN (SELECT restaurant_id FROM restaurants WHERE category = '치킨')
    AND ordered_at >= '2026-06-24'
ORDER BY ordered_at;


-- -------------------------------------------------------------
-- ⚠️ NOT IN과 NULL
-- -------------------------------------------------------------
SELECT name
FROM riders
WHERE rider_id NOT IN (SELECT rider_id FROM orders WHERE ordered_at >= '2026-06-30');

SELECT rider_id FROM orders WHERE ordered_at >= '2026-06-30';


-- -------------------------------------------------------------
-- 3-1. EXISTS — "그런 행이 하나라도 있나?"
-- -------------------------------------------------------------
SELECT rd.name
FROM riders rd
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.rider_id = rd.rider_id          -- 바깥 행(rd)을 참조
        AND o.ordered_at >= '2026-06-30'
);

SELECT c.name, c.joined_at
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
ORDER BY c.customer_id;


-- -------------------------------------------------------------
-- 3-2. 상관 서브쿼리로 그룹별 비교
-- -------------------------------------------------------------
SELECT m.restaurant_id, m.name, m.price
FROM menus m
WHERE m.price > (
    SELECT AVG(m2.price)
    FROM menus m2
    WHERE m2.restaurant_id = m.restaurant_id    -- 바깥 메뉴의 가게
)
ORDER BY m.restaurant_id, m.price DESC;


-- -------------------------------------------------------------
-- 4. SELECT 절 서브쿼리 — 행 옆에 기준값 붙이기
-- -------------------------------------------------------------
SELECT m.name,
    m.price,
    (SELECT ROUND(AVG(price)) FROM menus) AS overall_avg,
    m.price - (SELECT ROUND(AVG(price)) FROM menus) AS diff
FROM menus m
WHERE m.restaurant_id = 2
ORDER BY m.menu_id;


-- -------------------------------------------------------------
-- 5-1. 쿼리 결과를 표처럼 쓰기
-- -------------------------------------------------------------
SELECT r.name AS restaurant_name,
    COUNT(*) AS delivered_orders,
    SUM(f.food_amount) AS food_sales,
    SUM(o.delivery_fee) AS fee_sum
FROM orders o
JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
) f ON o.order_id = f.order_id                 -- 주문 1건 = f 1행 → 불어나지 않음
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY food_sales DESC;


-- -------------------------------------------------------------
-- 5-2. WITH — 서브쿼리에 이름 붙이기
-- -------------------------------------------------------------
WITH order_food AS (                       -- ① 주문별 음식 금액
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
)
SELECT r.name AS restaurant_name,          -- ② 가게별로 집계
    COUNT(*) AS delivered_orders,
    SUM(f.food_amount) AS food_sales,
    SUM(o.delivery_fee) AS fee_sum
FROM orders o
JOIN order_food f  ON o.order_id = f.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY food_sales DESC;


-- -------------------------------------------------------------
-- 6. UNION — 결과를 위아래로 합치기
-- -------------------------------------------------------------
SELECT '고객' AS kind, name, phone
FROM customers
WHERE district = '중구'
UNION ALL
SELECT '기사', name, phone
FROM riders
WHERE district = '중구'
ORDER BY kind, name;


-- -------------------------------------------------------------
-- 7-1. 순위 함수 세 가지
-- -------------------------------------------------------------
SELECT name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
    RANK()       OVER (ORDER BY price DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rnk
FROM menus
WHERE restaurant_id IN (1, 6)
ORDER BY price DESC, name;


-- -------------------------------------------------------------
-- 7-2. PARTITION BY — 그룹 안에서 순위
-- -------------------------------------------------------------
SELECT restaurant_id,
    name,
    price,
    RANK() OVER (PARTITION BY restaurant_id ORDER BY price DESC) AS price_rank
FROM menus
WHERE restaurant_id IN (1, 2)
ORDER BY restaurant_id, price_rank;


-- -------------------------------------------------------------
-- 7-3. 그룹별 Top-N — 윈도우 결과로 거르기
-- -------------------------------------------------------------
WITH ranked AS (
    SELECT restaurant_id,
        name,
        price,
        ROW_NUMBER() OVER (PARTITION BY restaurant_id ORDER BY price DESC, menu_id) AS rn
    FROM menus
)
SELECT restaurant_id, name, price
FROM ranked
WHERE rn = 1
ORDER BY restaurant_id;


-- -------------------------------------------------------------
-- 7-4. 집계 함수 + OVER — 누적 합계와 비율
-- -------------------------------------------------------------
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    SUM(delivery_fee) AS fee_sum,
    SUM(SUM(delivery_fee)) OVER (ORDER BY DATE_FORMAT(ordered_at, '%Y-%m')) AS cumulative_fee,
    ROUND(SUM(delivery_fee) * 100 / SUM(SUM(delivery_fee)) OVER (), 1) AS share_pct
FROM orders
WHERE status = '배달완료'
GROUP BY order_month
ORDER BY order_month;


-- -------------------------------------------------------------
-- ① 객단가가 평균보다 높은 단골 고객
-- -------------------------------------------------------------
WITH order_food AS (                                   -- ① 배달 완료 주문별 음식 금액
    SELECT o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS food_amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.order_id, o.customer_id
),
customer_avg AS (                                      -- ② 고객별 주문 수·객단가
    SELECT customer_id,
        COUNT(*) AS orders,
        ROUND(AVG(food_amount)) AS avg_food
    FROM order_food
    GROUP BY customer_id
)
SELECT c.name,
    c.grade,
    ca.orders,
    ca.avg_food,
    (SELECT ROUND(AVG(food_amount)) FROM order_food) AS overall_avg   -- ③ 전체 평균
FROM customer_avg ca
JOIN customers c ON ca.customer_id = c.customer_id
WHERE ca.avg_food > (SELECT AVG(food_amount) FROM order_food)
    AND ca.orders >= 10
ORDER BY ca.avg_food DESC;


-- -------------------------------------------------------------
-- ② 가게별 판매 1위 메뉴
-- -------------------------------------------------------------
WITH menu_sales AS (
    SELECT m.restaurant_id,
        m.menu_id,
        m.name AS menu_name,
        SUM(oi.quantity) AS sold_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN menus m  ON oi.menu_id  = m.menu_id
    WHERE o.status = '배달완료'
    GROUP BY m.restaurant_id, m.menu_id, m.name
),
ranked AS (
    SELECT ms.*,
        RANK() OVER (PARTITION BY restaurant_id ORDER BY sold_quantity DESC) AS rnk
    FROM menu_sales ms
)
SELECT r.name AS restaurant_name,
    rk.menu_name,
    rk.sold_quantity
FROM ranked rk
JOIN restaurants r ON rk.restaurant_id = r.restaurant_id
WHERE rk.rnk = 1
ORDER BY r.restaurant_id, rk.menu_name;

