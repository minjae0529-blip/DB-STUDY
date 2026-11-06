# Ch11 실습 — 자동으로 기록하고, 막고, 맞추기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery11;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 뒤 문제가 앞에서 만든 트리거와 데이터를 씁니다.
> 트리거 본문은 `DELIMITER $$ … END $$ DELIMITER ;`로 감싸야 합니다.
> 수업 중 만든 트리거와 이름이 겹치거나 데이터가 꼬였다면 `setup.sql`의 DROP 줄 주석을 풀고 다시 실행한 뒤 시작하세요.

---

### 문제 1. 등급 변경 이력 ★

> **마케팅팀** 고객 등급이 바뀔 때마다 기록을 남겨 주세요.
> - 테이블 `customer_grade_logs`: `log_id` (PK, AUTO_INCREMENT), `customer_id` (FK), `old_grade`, `new_grade` (VARCHAR(10)), `changed_at` (DATETIME, 기본값 현재 시각)
> - 트리거 `trg_customers_grade_log`: 등급이 **실제로 바뀐 경우만** 기록
>
> 윤서아 님(30번)을 '실버'로 올리고, 이름만 바꾼 경우(30번 이름을 그대로 다시 저장)에는 기록되지 않는지 확인하세요.

- 열: `log_id`, `customer_id`, `old_grade`, `new_grade`

**정답 SQL**

```sql
CREATE TABLE customer_grade_logs (
    log_id      INT          NOT NULL AUTO_INCREMENT,
    customer_id INT          NOT NULL,
    old_grade   VARCHAR(10)  NOT NULL,
    new_grade   VARCHAR(10)  NOT NULL,
    changed_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customer_grade_logs          PRIMARY KEY (log_id),
    CONSTRAINT fk_customer_grade_logs_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

DELIMITER $$
CREATE TRIGGER trg_customers_grade_log
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    IF OLD.grade <> NEW.grade THEN
        INSERT INTO customer_grade_logs (customer_id, old_grade, new_grade)
        VALUES (NEW.customer_id, OLD.grade, NEW.grade);
    END IF;
END $$
DELIMITER ;

UPDATE customers SET grade = '실버' WHERE customer_id = 30;
UPDATE customers SET name = name WHERE customer_id = 30;

SELECT log_id, customer_id, old_grade, new_grade FROM customer_grade_logs;
```

<sub>▶ 실행 결과 · 1행</sub>

| log_id | customer_id | old_grade | new_grade |
|---|---|---|---|
| 1 | 30 | 일반 | 실버 |


> **해설** 기록은 1행입니다. `UPDATE … SET name = name`도 트리거는 **실행됩니다**(행이 UPDATE 대상이 됐으므로). 다만 `IF OLD.grade <> NEW.grade` 조건에서 걸러져 기록되지 않습니다. 이력 트리거에는 항상 "실제로 바뀌었는가" 조건을 넣으세요.

### 문제 2. 리뷰 내용 정리 ★

> **CS팀** 앱에서 공백만 있는 리뷰(`'   '`)가 들어오거나, 앞뒤에 공백이 붙어 들어옵니다. 리뷰가 저장되기 **전에** 앞뒤 공백을 지우고, 지운 결과가 빈 문자열이면 NULL(별점만 남긴 리뷰)로 바꾸는 트리거 `trg_reviews_clean_content`를 만드세요.
>
> 549번 주문에 `'   '`(5점), 531번 주문에 `'  맛있어요  '`(4점) 리뷰를 넣고 확인합니다. 작성 일시는 둘 다 `'2026-06-30 18:50:00'`.

- 열: `order_id`, `rating`, `content`, `content_length` (`CHAR_LENGTH(content)`)
- 순서: `order_id`

**정답 SQL**

```sql
DELIMITER $$
CREATE TRIGGER trg_reviews_clean_content
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    SET NEW.content = NULLIF(TRIM(NEW.content), '');
END $$
DELIMITER ;

INSERT INTO reviews (order_id, rating, content, created_at) VALUES
    (549, 5, '   ', '2026-06-30 18:50:00'),
    (531, 4, '  맛있어요  ', '2026-06-30 18:50:00');

SELECT order_id, rating, content, CHAR_LENGTH(content) AS content_length
FROM reviews
WHERE order_id IN (531, 549)
ORDER BY order_id;
```

<sub>▶ 실행 결과 · 2행</sub>

| order_id | rating | content | content_length |
|---|---|---|---|
| 531 | 4 | 맛있어요 | 4 |
| 549 | 5 | NULL | NULL |


> **해설** 값을 **고쳐서** 넣는 일은 BEFORE 트리거의 `SET NEW.열`만 할 수 있습니다. `NULLIF(a, b)`는 a와 b가 같으면 NULL(Ch03). 이런 정리는 앱에서도 하지만, Workbench로 직접 넣는 데이터까지 한 곳에서 지키는 게 트리거의 장점입니다.

### 문제 3. 가격 급락 방지 ★★

> **운영팀** 사장님이 가격을 실수로 0 하나 빼고 입력하는 사고(13,000 → 1,300)가 있었습니다. 메뉴 가격을 **기존 가격의 절반 미만**으로 내리려 하면 `'가격을 절반 미만으로 내릴 수 없습니다. 운영팀에 문의하세요.'` 에러를 내는 트리거 `trg_menus_price_guard`를 만드세요.
>
> 정상적인 인하(돼지국밥 10,000 → 9,000)는 통과하는지 확인합니다.

- 열: `menu_id`, `name`, `price`

**정답 SQL**

```sql
DELIMITER $$
CREATE TRIGGER trg_menus_price_guard
BEFORE UPDATE ON menus
FOR EACH ROW
BEGIN
    IF NEW.price < OLD.price * 0.5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '가격을 절반 미만으로 내릴 수 없습니다. 운영팀에 문의하세요.';
    END IF;
END $$
DELIMITER ;

UPDATE menus SET price = 9000 WHERE menu_id = 1;

SELECT menu_id, name, price FROM menus WHERE menu_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price |
|---|---|---|
| 1 | 돼지국밥 | 9000 |


> **해설** `UPDATE menus SET price = 1300 WHERE menu_id = 4;`를 실행하면 `Error Code: 1644. 가격을 절반 미만으로 내릴 수 없습니다. …`로 막힙니다. "이전 값과 비교하는 규칙"은 CHECK 제약조건(한 행의 현재 값만 검사)으로는 만들 수 없고, `OLD`를 볼 수 있는 트리거의 몫입니다. 막는 트리거는 **BEFORE**입니다.

### 문제 4. 트리거가 한 일도 ROLLBACK된다 ★★

> **마케팅팀** 정우진 님(5번)을 'VIP'로 올렸다가 착오임을 알고 되돌립니다. 트랜잭션 안에서 등급을 바꾼 뒤 ROLLBACK하고, 등급과 **1번의 이력 테이블 행 수**가 모두 원래대로인지 확인하세요.

- 열: `grade`, `log_count`

**정답 SQL**

```sql
START TRANSACTION;
UPDATE customers SET grade = 'VIP' WHERE customer_id = 5;
ROLLBACK;

SELECT (SELECT grade FROM customers WHERE customer_id = 5) AS grade,
       (SELECT COUNT(*) FROM customer_grade_logs)          AS log_count;
```

<sub>▶ 실행 결과 · 1행</sub>

| grade | log_count |
|---|---|
| 골드 | 1 |


> **해설** 등급은 '골드' 그대로, 이력은 1번 문제의 1행 그대로입니다. 트리거가 넣은 이력은 UPDATE문과 **같은 트랜잭션**에 속하므로 함께 취소됩니다. 그래서 "데이터는 안 바뀌었는데 이력만 남는" 모순이 생기지 않습니다. ROLLBACK 전에 `SELECT`로 확인하면 이력 2행이 보입니다.

### 문제 5. 기사 배달 건수 ★★

> **정산팀** 기사별 배달 완료 건수를 `riders.delivery_count`에 저장하고 트리거로 유지해 주세요.
> 1. `delivery_count INT NOT NULL DEFAULT 0` 열 추가, 지금까지의 배달완료 건수로 초기값 채우기
> 2. 트리거 `trg_orders_rider_count`: 주문 상태가 **'배달완료'로 바뀌는 순간** 그 주문의 기사 건수 +1
>
> 배달중인 561번 주문(4번 기사)을 배달완료로 바꾸고 확인하세요.

- 열: `rider_id`, `name`, `delivery_count`, `actual_count` (orders에서 직접 센 배달완료 건수)

**정답 SQL**

```sql
ALTER TABLE riders ADD COLUMN delivery_count INT NOT NULL DEFAULT 0;

UPDATE riders r
JOIN (
    SELECT rider_id, COUNT(*) AS cnt
    FROM orders
    WHERE status = '배달완료' AND rider_id IS NOT NULL
    GROUP BY rider_id
) t ON r.rider_id = t.rider_id
SET r.delivery_count = t.cnt
WHERE r.rider_id > 0;

DELIMITER $$
CREATE TRIGGER trg_orders_rider_count
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status = '배달완료' AND OLD.status <> '배달완료' AND NEW.rider_id IS NOT NULL THEN
        UPDATE riders SET delivery_count = delivery_count + 1
        WHERE rider_id = NEW.rider_id;
    END IF;
END $$
DELIMITER ;

UPDATE orders SET status = '배달완료', delivered_at = '2026-06-30 18:55:00' WHERE order_id = 561;

SELECT r.rider_id, r.name, r.delivery_count,
    (SELECT COUNT(*) FROM orders o WHERE o.rider_id = r.rider_id AND o.status = '배달완료') AS actual_count
FROM riders r
WHERE r.rider_id = 4;
```

<sub>▶ 실행 결과 · 1행</sub>

| rider_id | name | delivery_count | actual_count |
|---|---|---|---|
| 4 | 전유나 | 51 | 51 |


> **해설** 트리거 조건에 `OLD.status <> '배달완료'`가 없으면, 이미 배달완료된 주문의 요청사항만 고쳐도 건수가 또 올라갑니다. "상태가 **바뀌는 순간**"은 항상 `OLD`와 `NEW`를 함께 봐야 합니다. 초기값 UPDATE의 `WHERE r.rider_id > 0`은 안전 업데이트 모드를 통과하기 위한 키 조건입니다.

### 문제 6. 쿠폰 보호 ★★

> **개발팀** 쿠폰 사용 표시(`customer_coupons.used_order_id`)에 두 가지 규칙을 걸어 주세요. 트리거 이름은 `trg_customer_coupons_guard`.
> - 이미 사용한 쿠폰을 **다른 주문으로** 바꾸면 `'이미 사용한 쿠폰입니다.'` (사용 취소, 즉 NULL로 되돌리는 것은 허용)
> - 쿠폰 만료 시각(`expires_at`)보다 **나중에 주문한** 주문에 쓰려 하면 `'만료된 쿠폰입니다.'`
>
> 정우진 님(5번)의 주말 쿠폰(2번)을 그의 563번 주문(6월 30일 18:47)에 사용 처리하고 확인하세요.

- 열: `customer_id`, `coupon_id`, `expires_at`, `used_order_id`

**정답 SQL**

```sql
DELIMITER $$
CREATE TRIGGER trg_customer_coupons_guard
BEFORE UPDATE ON customer_coupons
FOR EACH ROW
BEGIN
    IF OLD.used_order_id IS NOT NULL AND NEW.used_order_id IS NOT NULL
       AND NEW.used_order_id <> OLD.used_order_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 사용한 쿠폰입니다.';
    END IF;

    IF OLD.used_order_id IS NULL AND NEW.used_order_id IS NOT NULL
       AND (SELECT ordered_at FROM orders WHERE order_id = NEW.used_order_id) > OLD.expires_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '만료된 쿠폰입니다.';
    END IF;
END $$
DELIMITER ;

UPDATE customer_coupons SET used_order_id = 563
WHERE customer_id = 5 AND coupon_id = 2;

SELECT customer_id, coupon_id, expires_at, used_order_id
FROM customer_coupons
WHERE customer_id = 5;
```

<sub>▶ 실행 결과 · 1행</sub>

| customer_id | coupon_id | expires_at | used_order_id |
|---|---|---|---|
| 5 | 2 | 2026-07-04 00:00:00 | 563 |


> **해설** 이어서 `UPDATE customer_coupons SET used_order_id = 560 WHERE customer_id = 5 AND coupon_id = 2;`를 실행하면 `1644 이미 사용한 쿠폰입니다.`로 막힙니다. 만료 검사에 `NOW()`가 아니라 **주문 시각**을 쓴 이유: 주문을 넣고 쿠폰 표시를 하기까지 몇 초가 걸려도 판단이 흔들리지 않고, 과거 데이터를 보정할 때도 같은 규칙이 적용됩니다. Ch08의 `WHERE … AND used_order_id IS NULL` + 행 수 확인 방식과 함께 쓰면 이중 방어가 됩니다.

### 문제 7. 주문 취소하면 쿠폰 복구 ★★★

> **CS팀** 쿠폰을 쓴 주문이 **취소되면 쿠폰을 자동으로 돌려주는** 트리거 `trg_orders_restore_coupon`을 만드세요.
>
> 그다음 윤서아 님(30번)의 첫 주문을 Ch08처럼 **트랜잭션**으로 접수합니다: 광안리브런치카페(14번 가게)에서 에그 베네딕트(63번) 1개 + 아메리카노(66번) 1개, 배달팁 3,000원, 신규 쿠폰(1번, 3,000원 할인), 카드, 주문 시각 `'2026-06-30 19:10:00'`. 쿠폰 표시가 1행 바뀌면 COMMIT합니다. 이후 고객이 주문을 취소하면 쿠폰이 돌아오는지 확인하세요.

- 결과: 취소 후 윤서아 님의 쿠폰 행 (`customer_id`, `coupon_id`, `used_order_id`)

**정답 SQL**

```sql
DELIMITER $$
CREATE TRIGGER trg_orders_restore_coupon
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status = '취소' AND OLD.status <> '취소' THEN
        UPDATE customer_coupons SET used_order_id = NULL
        WHERE used_order_id = NEW.order_id;
    END IF;
END $$
DELIMITER ;

START TRANSACTION;
INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, discount_amount, ordered_at)
VALUES (30, 14, '접수', '카드', 3000, 3000, '2026-06-30 19:10:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price FROM menus WHERE menu_id IN (63, 66);

UPDATE customer_coupons SET used_order_id = @order_id
WHERE customer_id = 30 AND coupon_id = 1 AND used_order_id IS NULL;
SELECT ROW_COUNT() AS coupon_rows;   -- 1 확인 후
COMMIT;

UPDATE orders SET status = '취소' WHERE order_id = @order_id;

SELECT customer_id, coupon_id, used_order_id
FROM customer_coupons
WHERE customer_id = 30;
```

<sub>▶ 실행 결과 · 1행</sub>

| customer_id | coupon_id | used_order_id |
|---|---|---|
| 30 | 1 | NULL |


> **해설** 취소 UPDATE 한 줄에 쿠폰 복구가 따라왔습니다. 이때 6번의 보호 트리거도 실행되지만, "사용 → NULL"은 허용했으므로 통과합니다. 트리거가 다른 테이블의 트리거를 부르는 **연쇄**가 생긴 것입니다(orders → customer_coupons). 두세 단계까지는 괜찮지만, 그 이상 이어지면 무슨 일이 일어나는지 추적하기 어려워지니 문서로 남기세요.

### 문제 8. 가게 리뷰 통계 완성판 ★★★

> **운영팀** 수업에서 만든 가게 리뷰 통계를 **INSERT · UPDATE · DELETE 세 경우 모두** 맞도록 완성하세요.
> 1. `restaurants`에 `review_count`, `rating_sum` 열 추가 (INT, NOT NULL, 기본 0) 후 현재 리뷰로 초기값 채우기
> 2. 트리거 세 개: `trg_reviews_stats_insert` · `trg_reviews_stats_update` · `trg_reviews_stats_delete`
> 3. UPDATE 트리거는 별점이 바뀐 경우 차이만큼 `rating_sum`을 조정
>
> 2번 문제에서 549번 주문에 단 리뷰(5점)를 고객 요청으로 **1점**으로 수정하고, 서면옛날돼지국밥(1번 가게)의 통계를 확인하세요.

- 열: `restaurant_id`, `review_count`, `rating_sum`, `avg_rating` (소수 둘째 자리)

**정답 SQL**

```sql
ALTER TABLE restaurants
    ADD COLUMN review_count INT NOT NULL DEFAULT 0,
    ADD COLUMN rating_sum   INT NOT NULL DEFAULT 0;

UPDATE restaurants r
JOIN (
    SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
    FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
    GROUP BY o.restaurant_id
) t ON r.restaurant_id = t.restaurant_id
SET r.review_count = t.cnt, r.rating_sum = t.total
WHERE r.restaurant_id > 0;

DELIMITER $$
CREATE TRIGGER trg_reviews_stats_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = NEW.order_id;
    UPDATE restaurants SET review_count = review_count + 1, rating_sum = rating_sum + NEW.rating
    WHERE restaurant_id = v_restaurant_id;
END $$

CREATE TRIGGER trg_reviews_stats_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    IF OLD.rating <> NEW.rating THEN
        SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = NEW.order_id;
        UPDATE restaurants SET rating_sum = rating_sum + (NEW.rating - OLD.rating)
        WHERE restaurant_id = v_restaurant_id;
    END IF;
END $$

CREATE TRIGGER trg_reviews_stats_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = OLD.order_id;
    UPDATE restaurants SET review_count = review_count - 1, rating_sum = rating_sum - OLD.rating
    WHERE restaurant_id = v_restaurant_id;
END $$
DELIMITER ;

UPDATE reviews SET rating = 1 WHERE order_id = 549;

SELECT restaurant_id, review_count, rating_sum,
    ROUND(rating_sum / review_count, 2) AS avg_rating
FROM restaurants
WHERE restaurant_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| restaurant_id | review_count | rating_sum | avg_rating |
|---|---|---|---|
| 1 | 26 | 112 | 4.31 |


> **해설** 별점 수정은 리뷰 수는 그대로, 합계만 `NEW − OLD`(1 − 5 = −4)만큼 바뀝니다. `DECLARE`는 `BEGIN` 바로 뒤, 다른 문장보다 **먼저** 와야 합니다(UPDATE 트리거에서 `IF` 앞에 둔 이유). 평균 대신 합계를 저장했기 때문에 더하기·빼기만으로 언제나 정확합니다.

### 문제 9. 통계가 정말 맞는지 검증 ★★

> **데이터팀** 리뷰를 하나 더 넣고(486번 주문, 3점, 내용 `'보통이에요'`, `'2026-06-30 18:55:00'`), 리뷰 1번을 삭제한 뒤, 모든 가게의 `review_count` · `rating_sum`이 실제 리뷰와 일치하는지 검증하세요.

- 열: `mismatched_restaurants`, `total_reviews` (reviews 행 수), `total_count` (restaurants.review_count 합계)

**정답 SQL**

```sql
INSERT INTO reviews (order_id, rating, content, created_at)
VALUES (486, 3, '보통이에요', '2026-06-30 18:55:00');
DELETE FROM reviews WHERE review_id = 1;

SELECT
    (SELECT COUNT(*)
     FROM restaurants r
     LEFT JOIN (
         SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
         FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
         GROUP BY o.restaurant_id
     ) t ON r.restaurant_id = t.restaurant_id
     WHERE r.review_count <> COALESCE(t.cnt, 0) OR r.rating_sum <> COALESCE(t.total, 0)) AS mismatched_restaurants,
    (SELECT COUNT(*) FROM reviews) AS total_reviews,
    (SELECT SUM(review_count) FROM restaurants) AS total_count;
```

<sub>▶ 실행 결과 · 1행</sub>

| mismatched_restaurants | total_reviews | total_count |
|---|---|---|
| 0 | 262 | 262 |


> **해설** 불일치 0건, 리뷰 수 합계도 일치합니다. 트리거가 있어도 이 검증 쿼리는 버리지 마세요. 트리거를 잠깐 지웠다 다시 만든 사이에 들어온 데이터, `TRUNCATE`(트리거가 실행되지 않음), 다른 경로의 대량 적재 등으로 어긋날 수 있습니다. 정기적으로 돌리는 **감시**와 실시간으로 맞추는 **트리거**는 함께 씁니다.

### 문제 10. 내가 만든 트리거 목록 ★

> **개발팀** 지금 DB에 있는 트리거 전체를 테이블 · 이벤트 · 시점 순으로 정리해 주세요. 새로 온 개발자에게 넘길 문서의 재료입니다.

- 열: `table_name`, `event`, `timing`, `trigger_name`
- 순서: `table_name` → `event` → `timing` → `trigger_name`

**정답 SQL**

```sql
SELECT event_object_table AS table_name, event_manipulation AS event,
    action_timing AS timing, trigger_name AS trigger_name
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY table_name, event, timing, trigger_name;
```

<sub>▶ 실행 결과 · 9행</sub>

| table_name | event | timing | trigger_name |
|---|---|---|---|
| customer_coupons | UPDATE | BEFORE | trg_customer_coupons_guard |
| customers | UPDATE | AFTER | trg_customers_grade_log |
| menus | UPDATE | BEFORE | trg_menus_price_guard |
| orders | UPDATE | AFTER | trg_orders_restore_coupon |
| orders | UPDATE | AFTER | trg_orders_rider_count |
| reviews | INSERT | BEFORE | trg_reviews_clean_content |
| reviews | INSERT | AFTER | trg_reviews_stats_insert |
| reviews | UPDATE | AFTER | trg_reviews_stats_update |
| reviews | DELETE | AFTER | trg_reviews_stats_delete |


> **해설** `orders` 테이블에는 AFTER UPDATE 트리거가 두 개(5번 기사 건수, 7번 쿠폰 복구) 있습니다. `UPDATE orders …` 한 줄이 riders와 customer_coupons까지 바꿀 수 있다는 뜻입니다. 이 목록을 README에 붙여 두는 것만으로도 "보이지 않는 코드"의 위험이 크게 줄어듭니다.
