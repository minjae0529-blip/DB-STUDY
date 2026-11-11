-- Ch09 실습 — 정규화 집중 훈련 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery09)
USE hanip_delivery09;

-- 문제 1. 한 칸에 구역 여러 개 — 1NF ★
CREATE TABLE p_rider_zones AS
SELECT r.rider_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(r.zones, ', ', seq.n), ', ', -1) AS zone
FROM ex_rider_sheet r
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5) seq
  ON seq.n <= (CHAR_LENGTH(r.zones) - CHAR_LENGTH(REPLACE(r.zones, ', ', ''))) / 2 + 1;

ALTER TABLE p_rider_zones ADD CONSTRAINT pk_p_rider_zones PRIMARY KEY (rider_name, zone);

SELECT zone, COUNT(*) AS rider_count,
    GROUP_CONCAT(rider_name ORDER BY rider_name SEPARATOR ', ') AS riders
FROM p_rider_zones
GROUP BY zone
HAVING COUNT(*) >= 2
ORDER BY zone;

-- 문제 2. 사진 1 · 사진 2 · 사진 3 — 반복 열과 1NF ★
CREATE TABLE p_review_photos AS
SELECT review_id, 1 AS sort_order, photo1 AS photo_url FROM ex_review_sheet WHERE photo1 IS NOT NULL
UNION ALL
SELECT review_id, 2, photo2 FROM ex_review_sheet WHERE photo2 IS NOT NULL
UNION ALL
SELECT review_id, 3, photo3 FROM ex_review_sheet WHERE photo3 IS NOT NULL;

ALTER TABLE p_review_photos ADD CONSTRAINT pk_p_review_photos PRIMARY KEY (review_id, sort_order);

SELECT r.review_id, r.customer_name, COUNT(p.photo_url) AS photo_count
FROM ex_review_sheet r
LEFT JOIN p_review_photos p ON r.review_id = p.review_id
GROUP BY r.review_id, r.customer_name
ORDER BY r.review_id;

-- 문제 3. 함수 종속 검증 ★★
SELECT
    (SELECT COUNT(*) FROM (SELECT coupon_code FROM ex_coupon_sheet GROUP BY coupon_code
                           HAVING COUNT(DISTINCT discount_amount) > 1) t) AS code_to_discount,
    (SELECT COUNT(*) FROM (SELECT customer_phone FROM ex_coupon_sheet GROUP BY customer_phone
                           HAVING COUNT(DISTINCT customer_name) > 1) t) AS phone_to_name,
    (SELECT COUNT(*) FROM (SELECT coupon_name FROM ex_coupon_sheet GROUP BY coupon_name
                           HAVING COUNT(DISTINCT discount_amount) > 1) t) AS name_to_discount;

-- 문제 4. 후보키 찾기 ★★
SELECT COUNT(*) AS total_rows,
    COUNT(DISTINCT coupon_code)               AS by_code,
    COUNT(DISTINCT customer_phone)            AS by_phone,
    COUNT(DISTINCT coupon_code, customer_phone) AS by_code_phone,
    COUNT(DISTINCT customer_phone, used_at)   AS by_phone_used_at
FROM ex_coupon_sheet;

-- 문제 5. 부분 종속 제거 — 2NF ★★
CREATE TABLE p_coupons AS
SELECT DISTINCT coupon_code, coupon_name, discount_amount FROM ex_coupon_sheet;

CREATE TABLE p_coupon_customers AS
SELECT DISTINCT customer_phone, customer_name FROM ex_coupon_sheet;

CREATE TABLE p_coupon_uses AS
SELECT coupon_code, customer_phone, used_at FROM ex_coupon_sheet;

ALTER TABLE p_coupons          ADD CONSTRAINT pk_p_coupons          PRIMARY KEY (coupon_code);
ALTER TABLE p_coupon_customers ADD CONSTRAINT pk_p_coupon_customers PRIMARY KEY (customer_phone);
ALTER TABLE p_coupon_uses
    ADD CONSTRAINT pk_p_coupon_uses          PRIMARY KEY (coupon_code, customer_phone),
    ADD CONSTRAINT fk_p_coupon_uses_coupon   FOREIGN KEY (coupon_code)    REFERENCES p_coupons (coupon_code),
    ADD CONSTRAINT fk_p_coupon_uses_customer FOREIGN KEY (customer_phone) REFERENCES p_coupon_customers (customer_phone);

SELECT (SELECT COUNT(*) FROM p_coupons)          AS coupons_rows,
       (SELECT COUNT(*) FROM p_coupon_customers) AS customers_rows,
       (SELECT COUNT(*) FROM p_coupon_uses)      AS uses_rows;

-- 문제 6. 메뉴 하나 지웠더니 — 이상 현상 ★★
SELECT '가게' AS kind, restaurant_name AS name, COUNT(*) AS menu_count
FROM ex_menu_sheet
GROUP BY restaurant_name
HAVING COUNT(*) = 1
UNION ALL
SELECT '분류', category_name, COUNT(*)
FROM ex_menu_sheet
GROUP BY category_name
HAVING COUNT(*) = 1
ORDER BY kind, name;

-- 문제 7. 이행 종속 제거 — 3NF ★★
CREATE TABLE p_menu_categories AS
SELECT DISTINCT category_code, category_name FROM ex_menu_sheet;

CREATE TABLE p_menu_restaurants AS
SELECT DISTINCT restaurant_code, restaurant_name, owner_name, category_code FROM ex_menu_sheet;

CREATE TABLE p_menus AS
SELECT menu_code, menu_name, price, restaurant_code FROM ex_menu_sheet;

ALTER TABLE p_menu_categories  ADD CONSTRAINT pk_p_menu_categories PRIMARY KEY (category_code);
ALTER TABLE p_menu_restaurants
    ADD CONSTRAINT pk_p_menu_restaurants          PRIMARY KEY (restaurant_code),
    ADD CONSTRAINT fk_p_menu_restaurants_category FOREIGN KEY (category_code) REFERENCES p_menu_categories (category_code);
ALTER TABLE p_menus
    ADD CONSTRAINT pk_p_menus            PRIMARY KEY (menu_code),
    ADD CONSTRAINT fk_p_menus_restaurant FOREIGN KEY (restaurant_code) REFERENCES p_menu_restaurants (restaurant_code);

INSERT INTO p_menu_categories VALUES ('C04', '분식');

SELECT c.category_code, c.category_name, COUNT(m.menu_code) AS menu_count
FROM p_menu_categories c
LEFT JOIN p_menu_restaurants r ON c.category_code   = r.category_code
LEFT JOIN p_menus            m ON r.restaurant_code = m.restaurant_code
GROUP BY c.category_code, c.category_name
ORDER BY c.category_code;

-- 문제 8. 결정자가 후보키가 아니다 — BCNF ★★
CREATE TABLE p_inspectors AS
SELECT DISTINCT inspector_name, inspection_type FROM ex_inspection_sheet;

CREATE TABLE p_restaurant_inspectors AS
SELECT restaurant_name, inspector_name FROM ex_inspection_sheet;

ALTER TABLE p_inspectors ADD CONSTRAINT pk_p_inspectors PRIMARY KEY (inspector_name);
ALTER TABLE p_restaurant_inspectors
    ADD CONSTRAINT pk_p_restaurant_inspectors   PRIMARY KEY (restaurant_name, inspector_name),
    ADD CONSTRAINT fk_p_restaurant_inspectors_i FOREIGN KEY (inspector_name) REFERENCES p_inspectors (inspector_name);

SELECT
    (SELECT COUNT(*) FROM (SELECT inspector_name FROM ex_inspection_sheet GROUP BY inspector_name
                           HAVING COUNT(DISTINCT inspection_type) > 1) t) AS violations,
    (SELECT COUNT(*) FROM p_inspectors)            AS inspectors_rows,
    (SELECT COUNT(*) FROM p_restaurant_inspectors) AS assignments_rows;

-- 문제 9. 무손실 분해 vs 가짜 튜플 ★★★
WITH good AS (
    SELECT ri.restaurant_name, i.inspection_type, ri.inspector_name
    FROM p_restaurant_inspectors ri
    JOIN p_inspectors i ON ri.inspector_name = i.inspector_name
), part_a AS (
    SELECT DISTINCT restaurant_name, inspection_type FROM ex_inspection_sheet
), part_b AS (
    SELECT DISTINCT inspection_type, inspector_name FROM ex_inspection_sheet
), bad AS (
    SELECT a.restaurant_name, a.inspection_type, b.inspector_name
    FROM part_a a
    JOIN part_b b ON a.inspection_type = b.inspection_type
), orig AS (
    SELECT restaurant_name, inspection_type, inspector_name FROM ex_inspection_sheet
)
SELECT '올바른 분해' AS method, (SELECT COUNT(*) FROM good) AS rebuilt_rows,
    (SELECT COUNT(*) FROM (SELECT * FROM good EXCEPT SELECT * FROM orig) x) AS extra_rows
UNION ALL
SELECT '잘못된 분해', (SELECT COUNT(*) FROM bad),
    (SELECT COUNT(*) FROM (SELECT * FROM bad EXCEPT SELECT * FROM orig) y);

-- 문제 11. 비정규형 시트 하나를 끝까지 — 종합 ★★★
CREATE TABLE p_events AS
SELECT DISTINCT event_code, event_name, discount_rate FROM ex_event_sheet;

CREATE TABLE p_event_shops AS
SELECT DISTINCT restaurant_name, restaurant_phone FROM ex_event_sheet;

CREATE TABLE p_event_joins AS
SELECT event_code, restaurant_name, joined_at FROM ex_event_sheet;

CREATE TABLE p_event_menus AS
SELECT e.event_code, e.restaurant_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(e.menu_list, ', ', seq.n), ', ', -1) AS menu_name
FROM ex_event_sheet e
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) seq
  ON seq.n <= (CHAR_LENGTH(e.menu_list) - CHAR_LENGTH(REPLACE(e.menu_list, ', ', ''))) / 2 + 1;

ALTER TABLE p_events      ADD CONSTRAINT pk_p_events      PRIMARY KEY (event_code);
ALTER TABLE p_event_shops ADD CONSTRAINT pk_p_event_shops PRIMARY KEY (restaurant_name);
ALTER TABLE p_event_joins
    ADD CONSTRAINT pk_p_event_joins       PRIMARY KEY (event_code, restaurant_name),
    ADD CONSTRAINT fk_p_event_joins_event FOREIGN KEY (event_code)      REFERENCES p_events (event_code),
    ADD CONSTRAINT fk_p_event_joins_shop  FOREIGN KEY (restaurant_name) REFERENCES p_event_shops (restaurant_name);
ALTER TABLE p_event_menus
    ADD CONSTRAINT pk_p_event_menus      PRIMARY KEY (event_code, restaurant_name, menu_name),
    ADD CONSTRAINT fk_p_event_menus_join FOREIGN KEY (event_code, restaurant_name)
        REFERENCES p_event_joins (event_code, restaurant_name);

SELECT e.event_code, e.event_name, e.discount_rate,
    COUNT(DISTINCT j.restaurant_name) AS shop_count,
    COUNT(m.menu_name)                AS menu_count
FROM p_events e
JOIN p_event_joins j      ON e.event_code = j.event_code
LEFT JOIN p_event_menus m ON j.event_code = m.event_code AND j.restaurant_name = m.restaurant_name
GROUP BY e.event_code, e.event_name, e.discount_rate
ORDER BY e.event_code;
