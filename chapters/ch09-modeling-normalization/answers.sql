-- Ch09 실습 — 나누고, 검증하고, 설계하기 — 정답 SQL
-- 전제: 이 챕터의 setup.sql 실행 완료 (hanip_delivery09)
USE hanip_delivery09;

-- 문제 1. 카디널리티 확인 ★
SELECT
    (SELECT COUNT(*) FROM orders WHERE rider_id IS NULL) AS orders_without_rider,
    (SELECT COUNT(*) FROM menus m
     WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.menu_id = m.menu_id)) AS menus_never_ordered;

-- 문제 2. 1NF의 힘 ★
SELECT restaurant_name, menu_name, SUM(quantity) AS total_qty
FROM order_flat
GROUP BY restaurant_name, menu_name
ORDER BY total_qty DESC, restaurant_name, menu_name
LIMIT 5;

-- 문제 3. 함수 종속 검증 ★★
SELECT
    (SELECT COUNT(*) FROM (SELECT restaurant_name, menu_name FROM order_flat
                           GROUP BY restaurant_name, menu_name
                           HAVING COUNT(DISTINCT unit_price) > 1) t) AS june_violations,
    (SELECT COUNT(*) FROM (SELECT menu_id FROM order_items
                           GROUP BY menu_id
                           HAVING COUNT(DISTINCT unit_price) > 1) t) AS all_time_violations;

-- 문제 4. 갱신 이상 재현 ★★
START TRANSACTION;
UPDATE order_flat SET customer_phone = '010-2841-0000'
WHERE order_id = 457;

SELECT customer_phone, COUNT(*) AS line_count
FROM order_flat
WHERE customer_name = '김민준'
GROUP BY customer_phone
ORDER BY customer_phone;
ROLLBACK;

-- 문제 5. 삭제 이상 후보 찾기 ★★
SELECT '가게' AS kind, restaurant_name AS name
FROM order_flat
GROUP BY restaurant_name
HAVING COUNT(DISTINCT order_id) = 1
UNION ALL
SELECT '고객', customer_name
FROM order_flat
GROUP BY customer_name
HAVING COUNT(DISTINCT order_id) = 1
ORDER BY kind, name;

-- 문제 6. 2NF로 분해 ★★
CREATE TABLE p_orders AS
SELECT DISTINCT order_id, ordered_at, customer_phone, customer_name, customer_grade,
    restaurant_name, restaurant_phone, delivery_fee
FROM order_flat;

CREATE TABLE p_order_items AS
SELECT order_id, menu_name, quantity, unit_price
FROM order_flat;

ALTER TABLE p_orders      ADD CONSTRAINT pk_p_orders      PRIMARY KEY (order_id);
ALTER TABLE p_order_items ADD CONSTRAINT pk_p_order_items PRIMARY KEY (order_id, menu_name);

SELECT (SELECT COUNT(*) FROM p_orders) AS orders_rows,
       (SELECT COUNT(*) FROM p_order_items) AS items_rows;

-- 문제 7. 3NF로 분해 ★★
CREATE TABLE p_customers AS
SELECT DISTINCT customer_phone, customer_name, customer_grade FROM p_orders;

CREATE TABLE p_restaurants AS
SELECT DISTINCT restaurant_name, restaurant_phone FROM p_orders;

ALTER TABLE p_customers   ADD CONSTRAINT pk_p_customers   PRIMARY KEY (customer_phone);
ALTER TABLE p_restaurants ADD CONSTRAINT pk_p_restaurants PRIMARY KEY (restaurant_name);
ALTER TABLE p_orders DROP COLUMN customer_name, DROP COLUMN customer_grade, DROP COLUMN restaurant_phone;

SELECT (SELECT COUNT(*) FROM p_customers) AS customers_rows,
       (SELECT COUNT(*) FROM p_restaurants) AS restaurants_rows,
       (SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'p_orders') AS orders_columns;

-- 문제 8. 무손실 분해 검증 ★★★
WITH rebuilt AS (
    SELECT o.order_id, i.menu_name, c.customer_name, c.customer_grade,
        r.restaurant_phone, i.quantity, i.unit_price
    FROM p_orders o
    JOIN p_order_items i ON o.order_id        = i.order_id
    JOIN p_customers   c ON o.customer_phone  = c.customer_phone
    JOIN p_restaurants r ON o.restaurant_name = r.restaurant_name
), flat AS (
    SELECT order_id, menu_name, customer_name, customer_grade,
        restaurant_phone, quantity, unit_price
    FROM order_flat
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM flat EXCEPT SELECT * FROM rebuilt) a) AS lost_rows,
    (SELECT COUNT(*) FROM (SELECT * FROM rebuilt EXCEPT SELECT * FROM flat) b) AS extra_rows;

-- 문제 9. 반정규화가 필요한 이유 ★★
SELECT oi.unit_price, COUNT(*) AS line_count,
    SUM(oi.quantity * oi.unit_price) AS real_sales,
    SUM(oi.quantity * m.price)       AS sales_by_current_price
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN menus  m ON oi.menu_id  = m.menu_id
WHERE oi.menu_id = 11
  AND o.status = '배달완료'
GROUP BY oi.unit_price
ORDER BY oi.unit_price;

-- 문제 10. 메뉴 옵션 설계 ★★★
CREATE TABLE menu_options (
    option_id   INT          NOT NULL AUTO_INCREMENT,
    menu_id     INT          NOT NULL,
    name        VARCHAR(30)  NOT NULL,
    extra_price INT          NOT NULL DEFAULT 0,
    CONSTRAINT pk_menu_options      PRIMARY KEY (option_id),
    CONSTRAINT fk_menu_options_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id),
    CONSTRAINT uq_menu_options_name UNIQUE (menu_id, name),
    CONSTRAINT ck_menu_options_price CHECK (extra_price >= 0)
);

CREATE TABLE order_item_options (
    order_item_id INT NOT NULL,
    option_id     INT NOT NULL,
    CONSTRAINT pk_order_item_options PRIMARY KEY (order_item_id, option_id),
    CONSTRAINT fk_oio_item   FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id),
    CONSTRAINT fk_oio_option FOREIGN KEY (option_id)     REFERENCES menu_options (option_id)
);

INSERT INTO menu_options (menu_id, name, extra_price) VALUES
    (1, '밥 추가', 1000),
    (1, '고기 추가', 3000),
    (1, '다대기 빼기', 0);

INSERT INTO order_item_options (order_item_id, option_id)
SELECT oi.order_item_id, mo.option_id
FROM order_items oi
JOIN menu_options mo ON oi.menu_id = mo.menu_id
WHERE oi.order_id = 457
  AND mo.name IN ('밥 추가', '고기 추가');

SELECT m.name AS menu_name, oi.quantity, oi.unit_price,
    GROUP_CONCAT(mo.name ORDER BY mo.option_id SEPARATOR ', ') AS option_names,
    SUM(mo.extra_price) AS option_price,
    (oi.unit_price + SUM(mo.extra_price)) * oi.quantity AS line_total
FROM order_items oi
JOIN menus m               ON oi.menu_id       = m.menu_id
JOIN order_item_options oo ON oi.order_item_id = oo.order_item_id
JOIN menu_options mo       ON oo.option_id     = mo.option_id
WHERE oi.order_id = 457
GROUP BY oi.order_item_id, m.name, oi.quantity, oi.unit_price;
