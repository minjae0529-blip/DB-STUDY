-- Ch06 실습 — 쿼리 안의 쿼리, 그리고 순위 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery06)
USE hanip_delivery06;

-- 문제 1. 최고가 메뉴 ★
SELECT restaurant_id, name, price
FROM menus
WHERE price = (SELECT MAX(price) FROM menus);

-- 문제 2. 리뷰가 있는 가게 ★
SELECT r.restaurant_id, r.name
FROM restaurants r
WHERE EXISTS (
    SELECT 1
    FROM reviews rv
    JOIN orders o ON rv.order_id = o.order_id
    WHERE o.restaurant_id = r.restaurant_id
)
ORDER BY r.restaurant_id;

-- 문제 3. 가장 최근 주문 ★
SELECT o.order_id, o.ordered_at, c.name AS customer_name, o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.ordered_at = (SELECT MAX(ordered_at) FROM orders);

-- 문제 4. 리뷰 작성률, 이번엔 제대로 ★
SELECT COUNT(*) AS review_count,
    (SELECT COUNT(*) FROM orders WHERE status = '배달완료') AS delivered_orders,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM orders WHERE status = '배달완료'), 1) AS review_rate
FROM reviews;

-- 문제 5. 6월에 사라진 고객 ★★
SELECT c.name, c.joined_at
FROM customers c
WHERE c.joined_at < '2026-06-01'
    AND NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = c.customer_id
            AND o.ordered_at >= '2026-06-01'
            AND o.ordered_at <  '2026-07-01'
    )
ORDER BY c.joined_at;

-- 문제 6. 업종 평균보다 문턱이 높은 가게 ★★
SELECT r.name,
    r.category,
    r.min_order_amount,
    (SELECT ROUND(AVG(r2.min_order_amount)) FROM restaurants r2 WHERE r2.category = r.category) AS category_avg
FROM restaurants r
WHERE r.min_order_amount > (
    SELECT AVG(r2.min_order_amount)
    FROM restaurants r2
    WHERE r2.category = r.category
)
ORDER BY r.category, r.name;

-- 문제 7. 결제 금액 Top 5 ★★
WITH order_food AS (
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
)
SELECT o.order_id,
    f.food_amount,
    o.delivery_fee,
    o.discount_amount,
    f.food_amount + o.delivery_fee - o.discount_amount AS paid_amount
FROM orders o
JOIN order_food f ON o.order_id = f.order_id
WHERE o.status = '배달완료'
ORDER BY paid_amount DESC, o.order_id
LIMIT 5;

-- 문제 8. 휴면 위험 고객 ★★
WITH last_order AS (
    SELECT customer_id, MAX(ordered_at) AS last_ordered_at
    FROM orders
    GROUP BY customer_id
)
SELECT c.name,
    DATE(lo.last_ordered_at) AS last_order_date,
    DATEDIFF('2026-06-30', lo.last_ordered_at) AS days_since_last
FROM last_order lo
JOIN customers c ON lo.customer_id = c.customer_id
WHERE DATEDIFF('2026-06-30', lo.last_ordered_at) >= 30
ORDER BY days_since_last DESC;

-- 문제 9. 가게 매출 순위와 점유율 ★★
WITH store_sales AS (
    SELECT o.restaurant_id,
        SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.restaurant_id
)
SELECT RANK() OVER (ORDER BY ss.food_sales DESC) AS sales_rank,
    r.name AS restaurant_name,
    ss.food_sales,
    ROUND(ss.food_sales * 100 / SUM(ss.food_sales) OVER (), 1) AS share_pct
FROM store_sales ss
JOIN restaurants r ON ss.restaurant_id = r.restaurant_id
ORDER BY sales_rank;

-- 문제 10. 고객의 첫 주문 가게 ★★★
WITH numbered AS (
    SELECT o.customer_id,
        o.restaurant_id,
        o.ordered_at,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.ordered_at, o.order_id) AS rn
    FROM orders o
)
SELECT c.name AS customer_name,
    n.ordered_at AS first_ordered_at,
    r.name AS restaurant_name
FROM numbered n
JOIN customers c   ON n.customer_id   = c.customer_id
JOIN restaurants r ON n.restaurant_id = r.restaurant_id
WHERE n.rn = 1
ORDER BY c.customer_id;

-- 문제 11. 업종별 Top 2 가게 ★★★
WITH store_sales AS (
    SELECT r.category,
        r.restaurant_id,
        r.name AS restaurant_name,
        SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
    JOIN order_items oi ON o.order_id      = oi.order_id
    JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
    WHERE o.status = '배달완료'
    GROUP BY r.category, r.restaurant_id, r.name
),
ranked AS (
    SELECT ss.*,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY food_sales DESC, restaurant_id) AS category_rank
    FROM store_sales ss
)
SELECT category, category_rank, restaurant_name, food_sales
FROM ranked
WHERE category_rank <= 2
ORDER BY category, category_rank;

-- 문제 12. 빈칸 없는 월별 매출표 ★★★
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month
    FROM orders
),
stores AS (
    SELECT restaurant_id, name
    FROM restaurants
    WHERE category = '치킨'
),
sales AS (
    SELECT o.restaurant_id,
        DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.restaurant_id, order_month
)
SELECT m.order_month,
    s.name AS restaurant_name,
    IFNULL(sa.food_sales, 0) AS food_sales
FROM months m
CROSS JOIN stores s
LEFT JOIN sales sa
    ON sa.restaurant_id = s.restaurant_id
    AND sa.order_month = m.order_month
ORDER BY s.restaurant_id, m.order_month;
