-- 한입마켓 연습문제 20 — JOIN · GROUP BY · 서브쿼리 · 윈도우 함수 · UNION — 정답 SQL
-- 전제: 이 폴더의 setup.sql 실행 완료 (hanip_market)
USE hanip_market;

-- 문제 1. 대분류별 매출 ★
SELECT main.name AS main_category,
    COUNT(DISTINCT o.order_id)         AS orders,
    SUM(oi.quantity)                   AS quantity,
    SUM(oi.quantity * oi.unit_price)   AS sales
FROM orders o
JOIN order_items oi ON o.order_id     = oi.order_id
JOIN products p     ON oi.product_id  = p.product_id
JOIN categories sub  ON p.category_id = sub.category_id
JOIN categories main ON sub.parent_id = main.category_id
WHERE o.status = '배송완료'
GROUP BY main.category_id, main.name
ORDER BY sales DESC;

-- 문제 2. 지역별 구매 전환율 ★★
SELECT m.region,
    COUNT(DISTINCT m.member_id) AS members,
    COUNT(DISTINCT o.member_id) AS buyers,
    ROUND(COUNT(DISTINCT o.member_id) / COUNT(DISTINCT m.member_id) * 100, 1) AS conversion_rate
FROM members m
LEFT JOIN orders o ON o.member_id = m.member_id AND o.status = '배송완료'
GROUP BY m.region
ORDER BY conversion_rate DESC, m.region;

-- 문제 3. 리뷰로 본 브랜드 품질 ★★
SELECT p.brand,
    COUNT(*) AS reviews,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    ROUND(SUM(r.rating <= 2) / COUNT(*) * 100, 1) AS low_rating_pct
FROM reviews r
JOIN products p ON r.product_id = p.product_id
GROUP BY p.brand
HAVING COUNT(*) >= 10
ORDER BY avg_rating, p.brand;

-- 문제 4. 월별 × 결제수단 피벗 ★★
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS ym,
    SUM(payment_method = '카드')     AS card,
    SUM(payment_method = '간편결제') AS easy_pay,
    SUM(payment_method = '계좌이체') AS bank_transfer,
    COUNT(*)                         AS total
FROM orders
WHERE status NOT IN ('취소', '반품')
GROUP BY ym
ORDER BY ym;

-- 문제 5. 팔리지 않은 상품 ★★
SELECT p.product_id, p.name, p.is_active, p.stock,
    COALESCE(SUM(oi.quantity), 0) AS ordered_qty,
    COALESCE(SUM(CASE WHEN o.status = '배송완료' THEN oi.quantity END), 0) AS sold_qty
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o       ON o.order_id    = oi.order_id
GROUP BY p.product_id, p.name, p.is_active, p.stock
HAVING sold_qty = 0
ORDER BY p.product_id;

-- 문제 6. 단골 회원 요약 ★★★
SELECT m.name, COUNT(*) AS orders,
    DATE(MIN(t.ordered_at)) AS first_order,
    DATE(MAX(t.ordered_at)) AS last_order,
    ROUND(AVG(t.amount)) AS avg_amount
FROM (
    SELECT o.order_id, o.member_id, o.ordered_at,
        SUM(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount AS amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배송완료'
    GROUP BY o.order_id, o.member_id, o.ordered_at, o.shipping_fee, o.coupon_discount
) t
JOIN members m ON t.member_id = m.member_id
GROUP BY m.member_id, m.name
HAVING COUNT(*) >= 10
ORDER BY orders DESC, avg_amount DESC;

-- 문제 7. 우리 카테고리 평균보다 비싼 상품 ★
SELECT c.name AS category, p.name, p.price,
    (SELECT ROUND(AVG(p2.price)) FROM products p2
     WHERE p2.category_id = p.category_id AND p2.is_active) AS category_avg
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.is_active
  AND p.price > (SELECT AVG(p2.price) FROM products p2
                 WHERE p2.category_id = p.category_id AND p2.is_active)
ORDER BY p.category_id, p.price DESC;

-- 문제 8. 찜만 하고 사지 않은 상품 ★★
SELECT m.name AS member_name, p.name AS product_name, p.price, DATE(w.added_at) AS added_at
FROM wishlists w
JOIN members m  ON w.member_id  = m.member_id
JOIN products p ON w.product_id = p.product_id
WHERE p.is_active
  AND NOT EXISTS (
        SELECT 1
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.member_id = w.member_id
          AND oi.product_id = w.product_id
          AND o.status = '배송완료')
ORDER BY w.added_at, m.name;

-- 문제 9. 평균의 두 배가 넘는 큰 주문 ★★
WITH order_amounts AS (
    SELECT o.order_id, o.member_id, o.ordered_at,
        SUM(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount AS amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배송완료'
    GROUP BY o.order_id, o.member_id, o.ordered_at, o.shipping_fee, o.coupon_discount
)
SELECT a.order_id, m.name AS member_name, DATE(a.ordered_at) AS ordered_at, a.amount
FROM order_amounts a
JOIN members m ON a.member_id = m.member_id
WHERE a.amount >= 2 * (SELECT AVG(amount) FROM order_amounts)
ORDER BY a.amount DESC;

-- 문제 10. 소분류별 최고가 상품 ★★
SELECT c.name AS category, p.name, p.brand, p.price
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE (p.category_id, p.price) IN (
        SELECT category_id, MAX(price)
        FROM products
        GROUP BY category_id)
ORDER BY p.category_id;

-- 문제 11. 베스트셀러를 산 회원 ★★★
SELECT p.name AS product_name, m.name AS member_name, m.region, COUNT(*) AS times
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN members m      ON o.member_id = m.member_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.status = '배송완료'
  AND oi.product_id IN (
        SELECT oi2.product_id
        FROM order_items oi2 JOIN orders o2 ON oi2.order_id = o2.order_id
        WHERE o2.status = '배송완료'
        GROUP BY oi2.product_id
        HAVING SUM(oi2.quantity) = (
            SELECT MAX(total_qty) FROM (
                SELECT SUM(oi3.quantity) AS total_qty
                FROM order_items oi3 JOIN orders o3 ON oi3.order_id = o3.order_id
                WHERE o3.status = '배송완료'
                GROUP BY oi3.product_id) best))
GROUP BY p.product_id, p.name, m.member_id, m.name, m.region
ORDER BY times DESC, member_name;

-- 문제 12. 대분류 안 매출 TOP 2 ★★
WITH product_sales AS (
    SELECT main.name AS main_category, p.name AS product_name,
        SUM(oi.quantity * oi.unit_price) AS sales
    FROM orders o
    JOIN order_items oi  ON o.order_id     = oi.order_id
    JOIN products p      ON oi.product_id  = p.product_id
    JOIN categories sub  ON p.category_id  = sub.category_id
    JOIN categories main ON sub.parent_id  = main.category_id
    WHERE o.status = '배송완료'
    GROUP BY main.name, p.product_id, p.name
), ranked AS (
    SELECT main_category, product_name, sales,
        RANK() OVER (PARTITION BY main_category ORDER BY sales DESC) AS rnk
    FROM product_sales
)
SELECT main_category, rnk, product_name, sales
FROM ranked
WHERE rnk <= 2
ORDER BY main_category, rnk, product_name;

-- 문제 13. 전월 대비 매출 증감 ★★
WITH monthly AS (
    SELECT DATE_FORMAT(o.ordered_at, '%Y-%m') AS ym,
        SUM(oi.quantity * oi.unit_price) AS sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배송완료'
    GROUP BY ym
)
SELECT ym, sales,
    LAG(sales) OVER (ORDER BY ym) AS prev_sales,
    sales - LAG(sales) OVER (ORDER BY ym) AS diff,
    ROUND((sales - LAG(sales) OVER (ORDER BY ym)) / LAG(sales) OVER (ORDER BY ym) * 100, 1) AS growth_pct
FROM monthly
ORDER BY ym;

-- 문제 14. 누적 구매액과 VIP 도달 시점 ★★
WITH amounts AS (
    SELECT o.order_id, o.ordered_at,
        SUM(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount AS amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배송완료' AND o.member_id = 1
    GROUP BY o.order_id, o.ordered_at, o.shipping_fee, o.coupon_discount
), running AS (
    SELECT ROW_NUMBER() OVER (ORDER BY ordered_at) AS order_seq,
        order_id, ordered_at, amount,
        SUM(amount) OVER (ORDER BY ordered_at) AS running_total
    FROM amounts
)
SELECT order_seq, order_id, DATE(ordered_at) AS ordered_at, amount, running_total,
    CASE WHEN running_total >= 500000 AND running_total - amount < 500000 THEN 'VIP 달성' END AS vip_reached
FROM running
ORDER BY order_seq;

-- 문제 15. 첫 구매는 어떤 카테고리였나 ★★★
WITH firsts AS (
    SELECT o.member_id, main.name AS main_category,
        ROW_NUMBER() OVER (PARTITION BY o.member_id ORDER BY o.ordered_at, oi.order_item_id) AS rn
    FROM orders o
    JOIN order_items oi  ON o.order_id     = oi.order_id
    JOIN products p      ON oi.product_id  = p.product_id
    JOIN categories sub  ON p.category_id  = sub.category_id
    JOIN categories main ON sub.parent_id  = main.category_id
    WHERE o.status = '배송완료'
)
SELECT main_category AS first_main_category, COUNT(*) AS members,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM firsts
WHERE rn = 1
GROUP BY main_category
ORDER BY members DESC, first_main_category;

-- 문제 16. 가격대 4구간 ★★
WITH banded AS (
    SELECT product_id, price,
        NTILE(4) OVER (ORDER BY price, product_id) AS price_band
    FROM products
), sold AS (
    SELECT oi.product_id, SUM(oi.quantity) AS qty
    FROM order_items oi JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = '배송완료'
    GROUP BY oi.product_id
)
SELECT b.price_band, COUNT(*) AS products,
    MIN(b.price) AS min_price, MAX(b.price) AS max_price,
    COALESCE(SUM(s.qty), 0) AS sold_qty
FROM banded b
LEFT JOIN sold s ON b.product_id = s.product_id
GROUP BY b.price_band
ORDER BY b.price_band;

-- 문제 17. 탈퇴 회원까지 포함한 분기별 가입자 ★
SELECT CONCAT(YEAR(joined_at), '-Q', QUARTER(joined_at)) AS join_quarter,
    COUNT(*) AS joined,
    SUM(is_withdrawn) AS withdrawn
FROM (
    SELECT joined_at, 0 AS is_withdrawn FROM members
    UNION ALL
    SELECT joined_at, 1 FROM withdrawn_members
) all_members
GROUP BY join_quarter
ORDER BY join_quarter;

-- 문제 18. 회원 활동 타임라인 ★★
SELECT ordered_at AS activity_at, '주문' AS activity,
    CONCAT('주문 #', order_id, ' (', status, ')') AS detail
FROM orders
WHERE member_id = 33 AND ordered_at >= '2026-06-01'
UNION ALL
SELECT r.created_at, '리뷰', CONCAT(p.name, ' ★', r.rating)
FROM reviews r JOIN products p ON r.product_id = p.product_id
WHERE r.member_id = 33 AND r.created_at >= '2026-06-01'
UNION ALL
SELECT w.added_at, '찜', p.name
FROM wishlists w JOIN products p ON w.product_id = p.product_id
WHERE w.member_id = 33 AND w.added_at >= '2026-06-01'
UNION ALL
SELECT c.added_at, '장바구니', p.name
FROM carts c JOIN products p ON c.product_id = p.product_id
WHERE c.member_id = 33 AND c.added_at >= '2026-06-01'
ORDER BY activity_at;

-- 문제 19. 관심 상품 — UNION vs UNION ALL ★★
SELECT
    (SELECT COUNT(*) FROM (
        SELECT member_id, product_id FROM wishlists
        UNION ALL
        SELECT member_id, product_id FROM carts) a) AS union_all_rows,
    (SELECT COUNT(*) FROM (
        SELECT member_id, product_id FROM wishlists
        UNION
        SELECT member_id, product_id FROM carts) u) AS union_rows,
    (SELECT COUNT(*) FROM wishlists w
     WHERE EXISTS (SELECT 1 FROM carts c
                   WHERE c.member_id = w.member_id AND c.product_id = w.product_id)) AS in_both;

-- 문제 20. 지역별 매출 리포트 + 합계 행 ★★★
WITH order_amounts AS (
    SELECT o.order_id, m.region,
        SUM(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount AS amount
    FROM orders o
    JOIN order_items oi ON o.order_id  = oi.order_id
    JOIN members m      ON o.member_id = m.member_id
    WHERE o.status = '배송완료'
    GROUP BY o.order_id, m.region, o.shipping_fee, o.coupon_discount
), by_region AS (
    SELECT region, COUNT(*) AS orders, SUM(amount) AS revenue
    FROM order_amounts
    GROUP BY region
)
SELECT region, orders, revenue, avg_order, share_pct
FROM (
    SELECT 1 AS sort_key, region, orders, revenue,
        ROUND(revenue / orders) AS avg_order,
        ROUND(revenue / SUM(revenue) OVER () * 100, 1) AS share_pct
    FROM by_region
    UNION ALL
    SELECT 2, '합계', SUM(orders), SUM(revenue), ROUND(SUM(revenue) / SUM(orders)), 100.0
    FROM by_region
) report
ORDER BY sort_key, revenue DESC;
