# Ch10 실습 — 저장하고, 빠르게, 안전하게 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery10;` · **root로 접속** (계정 문제 9·10번)
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 7번은 6번의 인덱스를 씁니다.
> 수업 중 만든 뷰·인덱스와 이름이 겹치면 `1050`(이미 있음) 에러가 납니다. 그럴 땐 `setup.sql`의 DROP 줄 주석을 풀고 다시 실행한 뒤 시작하세요.

---

### 문제 1. 가게 평점 뷰 ★

> **마케팅팀** 가게별 리뷰 수와 평균 별점을 `v_restaurant_ratings` 뷰로 만들어 주세요. 그다음 뷰에서 **평균 별점 상위 3곳**을 조회합니다.
> - 뷰 열: `restaurant_id`, `restaurant_name`, `review_count`, `avg_rating` (소수 둘째 자리 반올림)
> - 리뷰가 없는 가게는 뷰에 나오지 않아도 됩니다.

- 조회 열: `restaurant_name`, `review_count`, `avg_rating`
- 순서: `avg_rating` 내림차순 → `review_count` 내림차순, 3행

**정답 SQL**

```sql
CREATE VIEW v_restaurant_ratings AS
SELECT r.restaurant_id, r.name AS restaurant_name,
    COUNT(*) AS review_count, ROUND(AVG(rv.rating), 2) AS avg_rating
FROM reviews rv
JOIN orders o      ON rv.order_id     = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name;

SELECT restaurant_name, review_count, avg_rating
FROM v_restaurant_ratings
ORDER BY avg_rating DESC, review_count DESC
LIMIT 3;
```

<sub>▶ 실행 결과 · 3행</sub>

| restaurant_name | review_count | avg_rating |
|---|---|---|
| 해운대스시하루 | 14 | 4.57 |
| 서면옛날돼지국밥 | 24 | 4.46 |
| 전포카츠 | 28 | 4.43 |


> **해설** 뷰 안에서 `ORDER BY`를 쓰지 않았습니다. 정렬은 뷰를 쓰는 쪽이 목적에 맞게 정하는 것이 원칙입니다. 리뷰 수가 적은 가게가 상위에 오르는 문제가 있다면 뷰를 쓰는 쪽에서 `WHERE review_count >= 10`을 붙이면 됩니다.

### 문제 2. 기사 공개 뷰 ★

> **CS팀** 고객 문의 응대용으로 기사 정보를 보여 주되, **이름은 가운데를 가리고**(`김민수` → `김*수`) 전화번호는 빼서 `v_riders_public` 뷰로 만들어 주세요.

- 뷰 열: `rider_id`, `name_masked`, `vehicle`, `district`, `is_active`
- 조회: 뷰 전체, `rider_id` 순

**정답 SQL**

```sql
CREATE VIEW v_riders_public AS
SELECT rider_id, CONCAT(LEFT(name, 1), '*', RIGHT(name, 1)) AS name_masked,
    vehicle, district, is_active
FROM riders;

SELECT * FROM v_riders_public ORDER BY rider_id;
```

<sub>▶ 실행 결과 · 8행</sub>

| rider_id | name_masked | vehicle | district | is_active |
|---|---|---|---|---|
| 1 | 배*진 | 오토바이 | 부산진구 | 1 |
| 2 | 노*환 | 오토바이 | 수영구 | 1 |
| 3 | 하*호 | 오토바이 | 해운대구 | 1 |
| 4 | 전*나 | 자전거 | 부산진구 | 1 |
| 5 | 곽*호 | 오토바이 | 남구 | 1 |
| 6 | 민*수 | 오토바이 | 연제구 | 0 |
| 7 | 엄*희 | 도보 | 중구 | 1 |
| 8 | 천*현 | 오토바이 | 사하구 | 1 |


> **해설** `LEFT`·`RIGHT`는 바이트가 아니라 **글자 수** 기준이라 한글도 그대로 됩니다(Ch03). 두 글자 이름이면 `이*이`처럼 보이니 실무에서는 `CHAR_LENGTH(name)`에 따라 `CASE`로 나누기도 합니다.

### 문제 3. 뷰 위에 쿼리 쌓기 ★★

> **정산팀** 수업에서 만든 것과 같은 `v_order_amounts` 뷰(주문별 `food_amount`, `delivery_fee`, `discount_amount`, `total_amount`)를 이 DB에 만들고, 그 뷰를 이용해 **6월 배달완료 결제 총액 상위 5명**을 뽑아 주세요.

- 열: `customer_name`, `orders`, `total_paid`
- 순서: `total_paid` 내림차순, 5행

**정답 SQL**

```sql
CREATE VIEW v_order_amounts AS
SELECT o.order_id, o.ordered_at, o.customer_id, o.restaurant_id, o.status,
    SUM(oi.quantity * oi.unit_price) AS food_amount,
    o.delivery_fee, o.discount_amount,
    SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS total_amount
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;

SELECT c.name AS customer_name, COUNT(*) AS orders, SUM(a.total_amount) AS total_paid
FROM v_order_amounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE a.status = '배달완료'
  AND a.ordered_at >= '2026-06-01' AND a.ordered_at < '2026-07-01'
GROUP BY c.customer_id, c.name
ORDER BY total_paid DESC
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| customer_name | orders | total_paid |
|---|---|---|
| 임도현 | 8 | 316000 |
| 배수빈 | 6 | 264000 |
| 김민준 | 8 | 262500 |
| 이서연 | 8 | 247500 |
| 박지훈 | 6 | 221500 |


> **해설** 금액 계산 규칙이 뷰 한 곳에 있으므로, 정산팀·마케팅팀이 각자 쿼리를 써도 금액이 어긋나지 않습니다. Ch05에서 같은 질문을 풀 때와 비교해 보세요.

### 문제 4. 조건을 지키는 뷰 ★★

> **운영팀** 판매 중인 메뉴만 보이는 `v_menus_on_sale` 뷰(`menu_id`, `restaurant_id`, `name`, `price`, `is_sold_out`, 조건 `is_sold_out = FALSE`)를 `WITH CHECK OPTION`으로 만드세요. 그다음 이 뷰를 통해 **장전동든든김밥 든든김밥**(`menu_id = 51`)의 가격을 4,500원으로 바꾸고, 원본 `menus`에서 확인합니다.

- 열: `menu_id`, `name`, `price`, `is_sold_out` (원본 `menus`에서)

**정답 SQL**

```sql
CREATE VIEW v_menus_on_sale AS
SELECT menu_id, restaurant_id, name, price, is_sold_out
FROM menus
WHERE is_sold_out = FALSE
WITH CHECK OPTION;

UPDATE v_menus_on_sale SET price = 4500 WHERE menu_id = 51;

SELECT menu_id, name, price, is_sold_out
FROM menus
WHERE menu_id = 51;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price | is_sold_out |
|---|---|---|---|
| 51 | 든든김밥 | 4500 | 0 |


> **해설** 같은 뷰로 `UPDATE v_menus_on_sale SET is_sold_out = TRUE WHERE menu_id = 51;`을 실행하면 `Error Code: 1369. CHECK OPTION failed`가 납니다. 바꾼 행이 뷰 조건을 벗어나기 때문입니다. 품절 처리는 원본 `menus`에서 하거나, 품절 관리용 뷰를 따로 둡니다.

### 문제 5. 이미 있는 인덱스 ★

> **개발팀** `order_items` 테이블에 어떤 인덱스가 있는지 `information_schema.statistics`에서 조회하고, 각 인덱스가 **왜 생겼는지**(PK / UNIQUE / FK) 설명해 주세요.

- 열: `index_name`, `column_name`, `seq_in_index`, `non_unique`
- 순서: `index_name` → `seq_in_index`

**정답 SQL**

```sql
SELECT index_name AS index_name, column_name AS column_name,
    seq_in_index AS seq_in_index, non_unique AS non_unique
FROM information_schema.statistics
WHERE table_schema = DATABASE() AND table_name = 'order_items'
ORDER BY index_name, seq_in_index;
```

<sub>▶ 실행 결과 · 4행</sub>

| index_name | column_name | seq_in_index | non_unique |
|---|---|---|---|
| fk_order_items_menu | menu_id | 1 | 1 |
| PRIMARY | order_item_id | 1 | 0 |
| uq_order_items | order_id | 1 | 0 |
| uq_order_items | menu_id | 2 | 0 |


> **해설** `PRIMARY`(PK), `uq_order_items`(UNIQUE, `order_id` + `menu_id` 복합), `fk_order_items_menu`(FK). `fk_order_items_order`는 보이지 않습니다. `order_id`로 시작하는 `uq_order_items`가 이미 있어서, MySQL이 FK용 인덱스를 따로 만들지 않고 그것을 함께 씁니다(최좌측 접두사 규칙).

### 문제 6. EXPLAIN 전후 비교 ★★

> **CS팀** "6월 이후 리뷰" 조회가 자주 쓰입니다. 먼저 아래 쿼리의 `EXPLAIN`을 확인한 뒤, `reviews.created_at`에 `idx_reviews_created_at` 인덱스를 만들고 다시 `EXPLAIN` 하세요.
> ```sql
> SELECT review_id, rating, created_at FROM reviews WHERE created_at >= '2026-06-01';
> ```

- 결과: 인덱스 생성 **후**의 `EXPLAIN` (`type`, `key`, `rows`를 확인)

**정답 SQL**

```sql
EXPLAIN
SELECT review_id, rating, created_at FROM reviews WHERE created_at >= '2026-06-01';

CREATE INDEX idx_reviews_created_at ON reviews (created_at);

EXPLAIN
SELECT review_id, rating, created_at FROM reviews WHERE created_at >= '2026-06-01';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | reviews | NULL | range | idx_reviews_created_at | idx_reviews_created_at | 5 | NULL | 49 | 100.00 | Using index condition |


> **해설** 인덱스 전에는 `type = ALL`(260행 전부), 후에는 `type = range`, `key = idx_reviews_created_at`, `rows`가 6월 리뷰 수 근처로 줄어듭니다.

### 문제 7. 인덱스를 살리는 쿼리 ★★

> **CS팀** 다른 직원이 같은 조회를 이렇게 썼습니다. 인덱스를 못 쓰는 이유를 설명하고, **결과는 같으면서 인덱스를 쓰도록** 고친 쿼리의 `EXPLAIN`을 보여 주세요.
> ```sql
> SELECT review_id, rating, created_at FROM reviews
> WHERE YEAR(created_at) = 2026 AND MONTH(created_at) = 6;
> ```

- 결과: 고친 쿼리의 `EXPLAIN`

**정답 SQL**

```sql
EXPLAIN
SELECT review_id, rating, created_at FROM reviews
WHERE created_at >= '2026-06-01' AND created_at < '2026-07-01';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | reviews | NULL | range | idx_reviews_created_at | idx_reviews_created_at | 5 | NULL | 49 | 100.00 | Using index condition |


> **해설** `YEAR(created_at)`처럼 열을 함수로 감싸면, 인덱스에 정렬된 값(`created_at`)과 비교하는 값(`YEAR(…)`)이 달라 인덱스를 탈 수 없습니다. 열은 그대로 두고 **반열린 구간** `>= 시작 AND < 다음 시작`으로 바꿉니다. `BETWEEN '2026-06-01' AND '2026-06-30'`은 6월 30일 0시 이후가 빠지므로 틀립니다(Ch03).

### 문제 8. 정렬까지 인덱스로 ★★★

> **개발팀** 앱의 "최근 주문 5건" 화면 쿼리입니다. `EXPLAIN`의 `Extra`를 보면 `Using filesort`(별도 정렬)가 있습니다. 조건 열과 정렬 열을 함께 담은 복합 인덱스 `idx_orders_customer_date`를 만들어 **정렬 작업을 없애고**, 다시 `EXPLAIN` 하세요.
> ```sql
> SELECT order_id, status, ordered_at FROM orders
> WHERE customer_id = 1 ORDER BY ordered_at DESC LIMIT 5;
> ```

- 결과: 인덱스 생성 **후**의 `EXPLAIN` (`key`, `Extra` 확인)

**정답 SQL**

```sql
CREATE INDEX idx_orders_customer_date ON orders (customer_id, ordered_at);

EXPLAIN
SELECT order_id, status, ordered_at FROM orders
WHERE customer_id = 1 ORDER BY ordered_at DESC LIMIT 5;
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | ref | idx_orders_customer_date | idx_orders_customer_date | 4 | const | 52 | 100.00 | Backward index scan |


> **해설** 복합 인덱스 `(customer_id, ordered_at)`에서는 1번 고객의 주문이 **이미 날짜순으로** 모여 있습니다. 그래서 MySQL은 따로 정렬하지 않고 인덱스를 뒤에서부터 5개만 읽습니다(`Backward index scan`). 인덱스는 WHERE뿐 아니라 **ORDER BY**도 빠르게 만듭니다. 이 인덱스가 생기면 `customer_id`로 시작하므로 FK용 인덱스 `fk_orders_customer`의 역할도 대신합니다.

### 문제 9. 읽기 전용 분석가 계정 ★★

> **데이터팀** 분석가용 계정 `hanip_analyst`@`localhost`(비밀번호 `Analyst!2026`)를 만들고, 이 DB의 **모든 테이블·뷰를 읽기만** 할 수 있게 해 주세요. 이미 있으면 지우고 새로 만듭니다.

- 결과: `SHOW GRANTS FOR 'hanip_analyst'@'localhost';`

**정답 SQL**

```sql
DROP USER IF EXISTS 'hanip_analyst'@'localhost';
CREATE USER 'hanip_analyst'@'localhost' IDENTIFIED BY 'Analyst!2026';
GRANT SELECT ON hanip_delivery10.* TO 'hanip_analyst'@'localhost';

SHOW GRANTS FOR 'hanip_analyst'@'localhost';
```

<sub>▶ 실행 결과 · 2행</sub>

| Grants for hanip_analyst@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_analyst`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.* TO `hanip_analyst`@`localhost` |


> **해설** `ON hanip_delivery10.*`는 지금 있는 테이블뿐 아니라 **앞으로 만들 테이블**에도 적용됩니다. 분석가라도 고객 개인정보를 볼 필요가 없다면 DB 전체 대신 테이블·뷰 단위로 주는 것이 최소 권한에 더 가깝습니다. 직접 이 계정으로 접속해 `DELETE FROM reviews WHERE review_id = 1;`이 1142로 막히는지 확인해 보세요.

### 문제 10. CS 상담원 역할 ★★★

> **CS팀** 상담원 여러 명이 같은 권한을 쓰도록 역할 `hanip_cs`를 만들어 주세요.
> - `orders` 테이블: 조회 가능, 단 수정은 **`status` 열만** (주문 취소 처리용)
> - 기사 정보는 2번에서 만든 `v_riders_public` 뷰만 조회
>
> 상담원 계정 `hanip_cs01`@`localhost`(비밀번호 `Cs01!2026`)에 역할을 주고 **기본 역할로 설정**한 뒤, 역할을 포함한 권한을 확인하세요. 역할·계정이 이미 있으면 지우고 새로 만듭니다.

- 결과: `SHOW GRANTS FOR 'hanip_cs01'@'localhost' USING 'hanip_cs';`

**정답 SQL**

```sql
DROP USER IF EXISTS 'hanip_cs01'@'localhost';
DROP ROLE IF EXISTS 'hanip_cs';

CREATE ROLE 'hanip_cs';
GRANT SELECT, UPDATE (status) ON hanip_delivery10.orders TO 'hanip_cs';
GRANT SELECT ON hanip_delivery10.v_riders_public TO 'hanip_cs';

CREATE USER 'hanip_cs01'@'localhost' IDENTIFIED BY 'Cs01!2026';
GRANT 'hanip_cs' TO 'hanip_cs01'@'localhost';
SET DEFAULT ROLE 'hanip_cs' TO 'hanip_cs01'@'localhost';

SHOW GRANTS FOR 'hanip_cs01'@'localhost' USING 'hanip_cs';
```

<sub>▶ 실행 결과 · 4행</sub>

| Grants for hanip_cs01@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_cs01`@`localhost` |
| GRANT SELECT, UPDATE (`status`) ON `hanip_delivery10`.`orders` TO `hanip_cs01`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_riders_public` TO `hanip_cs01`@`localhost` |
| GRANT `hanip_cs`@`%` TO `hanip_cs01`@`localhost` |


> **해설** `UPDATE (status)`는 **열 단위 권한**입니다. 상담원이 `UPDATE orders SET discount_amount = 0 …`을 시도하면 `1143 UPDATE command denied … for column 'discount_amount'`로 막힙니다. 상담원이 늘면 `CREATE USER` + `GRANT 'hanip_cs'` + `SET DEFAULT ROLE` 세 줄이면 끝이고, 권한 정책이 바뀌면 역할 하나만 고치면 됩니다.
