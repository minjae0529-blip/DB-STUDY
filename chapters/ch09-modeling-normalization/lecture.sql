-- =============================================================
--  Ch09. 데이터 모델링과 정규화 — 강사 시연 스크립트 (README 예제 순서)
--  전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery09)
--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제
-- =============================================================
USE hanip_delivery09;


-- -------------------------------------------------------------
-- 수업 준비
-- -------------------------------------------------------------
SELECT 'order_sheet' AS table_name, COUNT(*) AS row_count FROM order_sheet
UNION ALL SELECT 'order_flat', COUNT(*) FROM order_flat;


-- -------------------------------------------------------------
-- 2-3. 카디널리티를 데이터로 확인하기
-- -------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM customers c
     WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)) AS customers_without_order,
    (SELECT MIN(cnt) FROM (SELECT COUNT(*) AS cnt FROM order_items GROUP BY order_id) t) AS min_items_per_order,
    (SELECT MAX(cnt) FROM (SELECT COUNT(*) AS cnt FROM reviews GROUP BY order_id) t) AS max_reviews_per_order;


-- -------------------------------------------------------------
-- 3-1. 한 칸에 메뉴를 몰아 쓴 주문장
-- -------------------------------------------------------------
SELECT order_id, ordered_at, customer_name, restaurant_name, menu_list, delivery_fee
FROM order_sheet
ORDER BY order_id;

SELECT order_id, menu_list
FROM order_sheet
WHERE menu_list LIKE '%밀면%'
ORDER BY order_id;


-- -------------------------------------------------------------
-- 3-2. 메뉴 한 줄 = 한 행으로 편 주문장
-- -------------------------------------------------------------
SELECT order_id, menu_name, customer_name, customer_grade, restaurant_name, quantity, unit_price
FROM order_flat
ORDER BY order_id, menu_name;

SELECT SUM(quantity) AS mul_milmyeon_sold
FROM order_flat
WHERE menu_name = '물밀면';


-- -------------------------------------------------------------
-- 3-3. 갱신 이상 — 고친 곳만 고쳐진다
-- -------------------------------------------------------------
START TRANSACTION;

UPDATE order_flat SET customer_grade = '골드'
WHERE order_id = 557;

SELECT customer_name, customer_grade, COUNT(*) AS line_count
FROM order_flat
WHERE customer_name = '최수아'
GROUP BY customer_name, customer_grade;

ROLLBACK;


-- -------------------------------------------------------------
-- 3-4. 삽입 이상 — 주문이 없으면 메뉴도 못 넣는다
-- -------------------------------------------------------------
-- ⚠ 에러 예제
INSERT INTO order_flat (order_id, menu_name, ordered_at, customer_name, customer_phone,
                        customer_grade, restaurant_name, quantity, unit_price, delivery_fee)
VALUES (NULL, '고르곤졸라 피자', NOW(), '?', '?', '?', '광안리화덕피자', 0, 18000, 0);


-- -------------------------------------------------------------
-- 3-5. 삭제 이상 — 주문 하나 지웠더니 가게가 사라진다
-- -------------------------------------------------------------
START TRANSACTION;

DELETE FROM order_flat WHERE order_id = 501;

SELECT COUNT(*) AS rows_about_sushi_haru
FROM order_flat
WHERE restaurant_name = '해운대스시하루';

ROLLBACK;


-- -------------------------------------------------------------
-- 4. 함수 종속 — 무엇이 무엇을 결정하나
-- -------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM (SELECT order_id FROM order_flat GROUP BY order_id
                           HAVING COUNT(DISTINCT customer_phone) > 1) t) AS order_to_phone_violations,
    (SELECT COUNT(*) FROM (SELECT customer_phone FROM order_flat GROUP BY customer_phone
                           HAVING COUNT(DISTINCT customer_name) > 1) t) AS phone_to_name_violations,
    (SELECT COUNT(*) FROM (SELECT order_id FROM order_flat GROUP BY order_id
                           HAVING COUNT(DISTINCT restaurant_name) > 1) t) AS order_to_restaurant_violations;

SELECT name AS menu_name, COUNT(*) AS restaurant_count
FROM menus
GROUP BY name
HAVING COUNT(*) > 1;


-- -------------------------------------------------------------
-- 5-2. 제2정규형(2NF): 부분 종속 제거
-- -------------------------------------------------------------
CREATE TABLE nf_orders AS
SELECT DISTINCT order_id, ordered_at, customer_phone, customer_name, customer_grade,
    restaurant_name, restaurant_phone, delivery_fee
FROM order_flat;

CREATE TABLE nf_order_items AS
SELECT order_id, menu_name, quantity, unit_price
FROM order_flat;

SELECT (SELECT COUNT(*) FROM nf_orders) AS orders_rows,
       (SELECT COUNT(*) FROM nf_order_items) AS items_rows;


-- -------------------------------------------------------------
-- 5-3. 제3정규형(3NF): 이행 종속 제거
-- -------------------------------------------------------------
CREATE TABLE nf_customers AS
SELECT DISTINCT customer_phone, customer_name, customer_grade FROM nf_orders;

CREATE TABLE nf_restaurants AS
SELECT DISTINCT restaurant_name, restaurant_phone FROM nf_orders;

ALTER TABLE nf_customers   ADD CONSTRAINT pk_nf_customers   PRIMARY KEY (customer_phone);
ALTER TABLE nf_restaurants ADD CONSTRAINT pk_nf_restaurants PRIMARY KEY (restaurant_name);
ALTER TABLE nf_orders DROP COLUMN customer_name, DROP COLUMN customer_grade, DROP COLUMN restaurant_phone;

SELECT (SELECT COUNT(*) FROM nf_customers) AS customers_rows,
       (SELECT COUNT(*) FROM nf_restaurants) AS restaurants_rows;


-- -------------------------------------------------------------
-- 5-4. 다시 조립해도 같은가 — 무손실 분해
-- -------------------------------------------------------------
SELECT COUNT(*) AS lost_rows
FROM (
    SELECT order_id, menu_name, customer_name, restaurant_phone, quantity
    FROM order_flat
    EXCEPT
    SELECT o.order_id, i.menu_name, c.customer_name, r.restaurant_phone, i.quantity
    FROM nf_orders o
    JOIN nf_order_items i ON o.order_id        = i.order_id
    JOIN nf_customers   c ON o.customer_phone  = c.customer_phone
    JOIN nf_restaurants r ON o.restaurant_name = r.restaurant_name
) diff;


-- -------------------------------------------------------------
-- 6-1. `order_items.unit_price` — 사실 중복이 아니다
-- -------------------------------------------------------------
SELECT oi.unit_price, m.price AS current_price,
    COUNT(*) AS line_count, MIN(o.ordered_at) AS first_order, MAX(o.ordered_at) AS last_order
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN menus  m ON oi.menu_id  = m.menu_id
WHERE oi.menu_id = 1
GROUP BY oi.unit_price, m.price
ORDER BY first_order;

SELECT
    SUM(oi.quantity * oi.unit_price) AS real_sales,
    SUM(oi.quantity * m.price)       AS sales_by_current_price,
    SUM(oi.quantity * m.price) - SUM(oi.quantity * oi.unit_price) AS overstated
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN menus  m ON oi.menu_id  = m.menu_id
WHERE o.status = '배달완료'
  AND o.ordered_at < '2026-04-01';


-- -------------------------------------------------------------
-- 6-2. `orders.restaurant_id` — 계산할 수 있지만 남겼다
-- -------------------------------------------------------------
SELECT COUNT(*) AS mismatched_lines
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN menus m        ON oi.menu_id = m.menu_id
WHERE m.restaurant_id <> o.restaurant_id;


-- -------------------------------------------------------------
-- 7-4. DDL
-- -------------------------------------------------------------
CREATE TABLE review_photos (
    photo_id    INT           NOT NULL AUTO_INCREMENT  COMMENT '사진 번호',
    review_id   INT           NOT NULL                 COMMENT '리뷰 번호',
    sort_order  TINYINT       NOT NULL                 COMMENT '표시 순서 1~5',
    image_url   VARCHAR(300)  NOT NULL                 COMMENT '이미지 주소',
    uploaded_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_review_photos       PRIMARY KEY (photo_id),
    CONSTRAINT fk_review_photos_review FOREIGN KEY (review_id) REFERENCES reviews (review_id),
    CONSTRAINT uq_review_photos_order UNIQUE (review_id, sort_order),
    CONSTRAINT ck_review_photos_order CHECK (sort_order BETWEEN 1 AND 5)
) COMMENT '리뷰 사진';

CREATE TABLE review_replies (
    review_id   INT           NOT NULL                 COMMENT '리뷰 번호 (PK이자 FK)',
    content     VARCHAR(500)  NOT NULL                 COMMENT '답글 내용',
    replied_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_review_replies        PRIMARY KEY (review_id),
    CONSTRAINT fk_review_replies_review FOREIGN KEY (review_id) REFERENCES reviews (review_id)
) COMMENT '사장님 답글';


-- -------------------------------------------------------------
-- 7-5. 넣어 보고 규칙 확인하기
-- -------------------------------------------------------------
INSERT INTO review_photos (review_id, sort_order, image_url, uploaded_at) VALUES
    (256, 1, 'https://img.hanip.example/reviews/256/1.jpg', '2026-06-29 06:35:55'),
    (256, 2, 'https://img.hanip.example/reviews/256/2.jpg', '2026-06-29 06:35:55');

INSERT INTO review_replies (review_id, content, replied_at)
VALUES (256, '늦어서 죄송합니다. 다음엔 더 빠르게 보내드릴게요!', '2026-06-29 10:12:00');

SELECT r.review_id, r.rating, r.content,
    (SELECT COUNT(*) FROM review_photos p WHERE p.review_id = r.review_id) AS photo_count,
    rr.content AS owner_reply
FROM reviews r
LEFT JOIN review_replies rr ON r.review_id = rr.review_id
WHERE r.review_id = 256;

-- ⚠ 에러 예제
INSERT INTO review_replies (review_id, content) VALUES (256, '감사합니다!');

-- ⚠ 에러 예제
INSERT INTO review_photos (review_id, sort_order, image_url)
VALUES (256, 6, 'https://img.hanip.example/reviews/256/6.jpg');

SELECT r.review_id, r.rating, rr.content AS owner_reply
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
LEFT JOIN review_replies rr ON r.review_id = rr.review_id
WHERE o.restaurant_id = 1
ORDER BY r.created_at DESC;

