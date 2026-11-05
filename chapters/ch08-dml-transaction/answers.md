# Ch08 실습 — 데이터 바꾸고 묶기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery08;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 앞 문제의 변경이 뒤 문제 결과에 영향을 줍니다.
> 기대 결과는 각 문제 끝의 **확인용 SELECT** 결과입니다. 처음부터 다시 하려면 setup.sql의 DROP 줄 주석을 풀고 다시 실행하세요.
> Workbench의 안전 업데이트 모드를 켠 채로 푸세요(기본값). UPDATE·DELETE의 WHERE에는 키 열이 들어가야 합니다.

---

### 문제 1. 신메뉴 등록 ★

> **운영팀** 남포동떡볶이연구소(`restaurant_id = 9`)에 신메뉴 **'치즈 떡볶이' 7,500원**(설명: '모차렐라 듬뿍')을 대표 메뉴로 등록해 주세요.

- 확인 열: `name`, `price`, `description`, `is_signature` (이 가게의 대표 메뉴, 가격 순)

**정답 SQL**

```sql
INSERT INTO menus (restaurant_id, name, price, description, is_signature)
VALUES (9, '치즈 떡볶이', 7500, '모차렐라 듬뿍', TRUE);

SELECT name, price, description, is_signature
FROM menus
WHERE restaurant_id = 9 AND is_signature = TRUE
ORDER BY price;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | price | description | is_signature |
|---|---|---|---|
| 국물떡볶이 | 5500 | 부산식 어묵 국물 떡볶이 | 1 |
| 치즈 떡볶이 | 7500 | 모차렐라 듬뿍 | 1 |
| 로제떡볶이 | 8000 | NULL | 1 |


### 문제 2. 음료 메뉴 한 번에 ★

> **운영팀** 하단버거스탠드(`restaurant_id = 10`)에 음료 세 가지를 **한 문장으로** 등록하세요: 콜라 2,000원, 사이다 2,000원, 아이스티 2,500원.

- 확인 열: `name`, `price` (이 가게 메뉴 중 3,000원 미만, 가격·이름 순)

**정답 SQL**

```sql
INSERT INTO menus (restaurant_id, name, price) VALUES
    (10, '콜라', 2000),
    (10, '사이다', 2000),
    (10, '아이스티', 2500);

SELECT name, price
FROM menus
WHERE restaurant_id = 10 AND price < 3000
ORDER BY price, name;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | price |
|---|---|
| 사이다 | 2000 |
| 콜라 | 2000 |
| 아이스티 | 2500 |


### 문제 3. 가격 조정 ★

> **운영팀** 연산동짬뽕반점(`restaurant_id = 8`)이 **6,000원 이하** 메뉴만 500원 올린다고 합니다. 바꾸기 전에 같은 조건으로 SELECT해서 대상을 확인한 뒤 UPDATE하세요.

- 확인 열: `name`, `price` (이 가게 전체 메뉴, `menu_id` 순)

**정답 SQL**

```sql
SELECT name, price FROM menus WHERE restaurant_id = 8 AND price <= 6000;

UPDATE menus
SET price = price + 500
WHERE restaurant_id = 8 AND price <= 6000;

SELECT name, price
FROM menus
WHERE restaurant_id = 8
ORDER BY menu_id;
```

<sub>▶ 실행 결과 · 6행</sub>

| name | price |
|---|---|
| 짜장면 | 7000 |
| 짬뽕 | 9000 |
| 간짜장 | 8500 |
| 탕수육 (소) | 16000 |
| 볶음밥 | 8500 |
| 군만두 (8개) | 6500 |


> **해설** 군만두(6,000원)만 6,500원이 됩니다. 짜장면(7,000원)은 대상이 아닙니다. 확인용 SELECT를 먼저 해 보면 "1행이 바뀌어야 한다"를 알고 UPDATE의 `1 row(s) affected`와 대조할 수 있습니다.

### 문제 4. 리뷰 신고 처리 ★

> **CS팀** 별점 1점이면서 내용이 **'다시는 안 시킬 것 같아요'**인 리뷰가 욕설 포함으로 신고됐습니다. 해당 리뷰를 삭제하고 남은 1점 리뷰 수를 확인하세요.
> 힌트: 먼저 SELECT로 `review_id`를 찾은 뒤, **`review_id`로** 지우세요.

- 확인 열: `one_star_reviews`

**정답 SQL**

```sql
SELECT review_id, content FROM reviews WHERE rating = 1;

DELETE FROM reviews
WHERE review_id IN (SELECT review_id FROM (
    SELECT review_id FROM reviews WHERE rating = 1 AND content = '다시는 안 시킬 것 같아요'
) t);

SELECT COUNT(*) AS one_star_reviews FROM reviews WHERE rating = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| one_star_reviews |
|---|
| 2 |


> **해설** 실무에서는 SELECT로 찾은 번호를 그대로 적어 `DELETE FROM reviews WHERE review_id = 번호;`로 지우는 게 가장 안전합니다. 정답의 `FROM (SELECT …) t`는 MySQL이 "지우는 테이블을 같은 문장의 서브쿼리에서 직접 읽는 것"을 막기 때문에(1093 에러) 한 번 감싼 것입니다.

### 문제 5. 일 매출 요약표 ★★

> **정산팀** 6월 마지막 주(6/24~6/30) **일별** 배달 완료 주문 수와 음식 매출을 저장할 표 `daily_sales`를 만들고 `INSERT … SELECT`로 채우세요.
> - 열: `sales_date DATE` (PK), `orders INT`, `food_sales INT` — 모두 NOT NULL

- 확인 열: `sales_date`, `orders`, `food_sales` (날짜 순)

**정답 SQL**

```sql
CREATE TABLE daily_sales (
    sales_date DATE NOT NULL,
    orders     INT  NOT NULL,
    food_sales INT  NOT NULL,
    CONSTRAINT pk_daily_sales PRIMARY KEY (sales_date)
);

INSERT INTO daily_sales (sales_date, orders, food_sales)
SELECT DATE(o.ordered_at),
    COUNT(DISTINCT o.order_id),
    SUM(oi.quantity * oi.unit_price)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
    AND o.ordered_at >= '2026-06-24'
    AND o.ordered_at <  '2026-07-01'
GROUP BY DATE(o.ordered_at);

SELECT sales_date, orders, food_sales
FROM daily_sales
ORDER BY sales_date;
```

<sub>▶ 실행 결과 · 7행</sub>

| sales_date | orders | food_sales |
|---|---|---|
| 2026-06-24 | 3 | 62500 |
| 2026-06-25 | 4 | 81800 |
| 2026-06-26 | 3 | 99000 |
| 2026-06-27 | 4 | 82500 |
| 2026-06-28 | 4 | 145000 |
| 2026-06-29 | 2 | 29000 |
| 2026-06-30 | 3 | 67800 |


### 문제 6. 등급 승급 ★★

> **마케팅팀** 6월에 배달 완료 주문이 **4건 이상**인데 등급이 **'일반'**인 고객을 **'실버'**로 올려 주세요.

- 확인 열: `name`, `grade` (등급이 '실버'인 고객, `customer_id` 순)

**정답 SQL**

```sql
SELECT c.customer_id, c.name, c.grade, COUNT(*) AS june_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = '배달완료'
    AND o.ordered_at >= '2026-06-01' AND o.ordered_at < '2026-07-01'
    AND c.grade = '일반'
GROUP BY c.customer_id, c.name, c.grade
HAVING COUNT(*) >= 4;

UPDATE customers c
JOIN (
    SELECT customer_id
    FROM orders
    WHERE status = '배달완료'
        AND ordered_at >= '2026-06-01' AND ordered_at < '2026-07-01'
    GROUP BY customer_id
    HAVING COUNT(*) >= 4
) t ON c.customer_id = t.customer_id
SET c.grade = '실버'
WHERE c.grade = '일반';

SELECT name, grade
FROM customers
WHERE grade = '실버'
ORDER BY customer_id;
```

<sub>▶ 실행 결과 · 10행</sub>

| name | grade |
|---|---|
| 최수아 | 실버 |
| 조현우 | 실버 |
| 한예린 | 실버 |
| 오승민 | 실버 |
| 권나연 | 실버 |
| 황태민 | 실버 |
| 안소율 | 실버 |
| 배수빈 | 실버 |
| 장민석 | 실버 |
| 정다인 | 실버 |


> **해설** MySQL은 **UPDATE에도 JOIN**을 쓸 수 있습니다. 6월 실적을 FROM절 서브쿼리(Ch06)로 먼저 만들고, 고객과 PK로 이어서 바꿨습니다.
>
> `WHERE customer_id IN (SELECT … FROM orders …)`로 써도 결과는 같지만, Workbench 기본값인 **안전 업데이트 모드에서는 1175 에러**가 납니다. 안전 모드는 IN 서브쿼리를 "키 조건"으로 인정하지 않기 때문입니다. 대상 확인용 SELECT와 UPDATE의 행 수(3)가 같은지 꼭 대조하세요.

### 문제 7. 실수 되돌리기 ★★

> 트랜잭션 안에서 **모든 쿠폰을 비활성화**(`is_active = FALSE`)한 뒤, 활성 쿠폰 수를 확인하고 **ROLLBACK**하세요. 마지막에 활성 쿠폰 수를 다시 확인합니다.
> 힌트: 안전 모드에서는 `WHERE coupon_id > 0`처럼 키 조건을 붙입니다.

- 확인 열: `active_coupons` (ROLLBACK 후)

**정답 SQL**

```sql
START TRANSACTION;
UPDATE coupons SET is_active = FALSE WHERE coupon_id > 0;
SELECT COUNT(*) AS active_coupons FROM coupons WHERE is_active = TRUE;
ROLLBACK;

SELECT COUNT(*) AS active_coupons FROM coupons WHERE is_active = TRUE;
```

<sub>▶ 실행 결과 · 1행</sub>

| active_coupons |
|---|
| 4 |


> **해설** ROLLBACK 전 SELECT는 0, 후에는 4입니다. **같은 세션 안에서는** COMMIT 전에도 자기 변경이 보입니다. 다른 세션(다른 SQL 탭)에서는 COMMIT 전까지 바뀌기 전 값이 보입니다 — 직접 두 탭을 열어 확인해 보세요.

### 문제 8. SAVEPOINT ★★

> 한 트랜잭션 안에서 ① 광안리화덕피자(`restaurant_id = 4`)의 배달팁을 3,000원으로 내리고 → `SAVEPOINT fee_done` → ② 최소 주문 금액을 0원으로 바꿨다가 → ② 만 되돌린 뒤 COMMIT하세요.

- 확인 열: `name`, `delivery_fee`, `min_order_amount`

**정답 SQL**

```sql
START TRANSACTION;
UPDATE restaurants SET delivery_fee = 3000 WHERE restaurant_id = 4;
SAVEPOINT fee_done;
UPDATE restaurants SET min_order_amount = 0 WHERE restaurant_id = 4;
ROLLBACK TO SAVEPOINT fee_done;
COMMIT;

SELECT name, delivery_fee, min_order_amount
FROM restaurants
WHERE restaurant_id = 4;
```

<sub>▶ 실행 결과 · 1행</sub>

| name | delivery_fee | min_order_amount |
|---|---|---|
| 광안리화덕피자 | 3000 | 18000 |


### 문제 9. 주문 접수 ★★★

> **개발팀** 신규 고객 **윤서아**(`customer_id = 30`) 님의 첫 주문을 트랜잭션으로 처리하세요.
> - 가게: 전포카츠(`restaurant_id = 2`), 메뉴: **등심카츠 1개 + 치즈카츠 1개** (단가는 메뉴의 현재 가격)
> - 결제: 카드, 배달팁 3,000원, 주문 일시 `'2026-06-30 19:30:00'`
> - 쿠폰: 보유한 **WELCOME3000** 사용 → 할인액 3,000원, 쿠폰에 사용 표시
>
> 쿠폰 표시가 1행 바뀐 것을 확인한 뒤 COMMIT하고, 주문서를 조회하세요.

- 확인 열: `customer_name`, `menu_name`, `quantity`, `unit_price`, `discount_amount`, `coupon_code`

**정답 SQL**

```sql
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, ordered_at)
VALUES (30, 2, '접수', '카드', 3000, 3000, '2026-06-30 19:30:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price
FROM menus
WHERE restaurant_id = 2 AND name IN ('등심카츠', '치즈카츠');

UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 30
    AND coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'WELCOME3000')
    AND used_order_id IS NULL;
SELECT ROW_COUNT() AS coupon_rows_updated;

COMMIT;

SELECT c.name AS customer_name,
    m.name AS menu_name,
    oi.quantity,
    oi.unit_price,
    o.discount_amount,
    cp.code AS coupon_code
FROM orders o
JOIN customers c         ON o.customer_id = c.customer_id
JOIN order_items oi      ON o.order_id    = oi.order_id
JOIN menus m             ON oi.menu_id    = m.menu_id
JOIN customer_coupons cc ON cc.used_order_id = o.order_id
JOIN coupons cp          ON cc.coupon_id  = cp.coupon_id
WHERE o.order_id = @order_id
ORDER BY m.menu_id;
```

<sub>▶ 실행 결과 · 2행</sub>

| customer_name | menu_name | quantity | unit_price | discount_amount | coupon_code |
|---|---|---|---|---|---|
| 윤서아 | 등심카츠 | 1 | 11000 | 3000 | WELCOME3000 |
| 윤서아 | 치즈카츠 | 1 | 13000 | 3000 | WELCOME3000 |


> **해설** 쿠폰 번호를 직접 쓰지 않고 `code`로 찾았습니다(Ch06 서브쿼리). 메뉴도 이름으로 찾았지만, 실제 서비스에서는 화면에서 넘어온 **menu_id**를 씁니다 — 같은 이름의 메뉴가 다른 가게에도 있을 수 있기 때문입니다(이 쿼리는 `restaurant_id = 2` 조건으로 막았습니다).

### 문제 10. 주문 취소와 보상 쿠폰 ★★★

> **CS팀** 스냅숏 시점에 **접수** 상태로 오래 대기 중인 주문(`order_id = 563`)을 가게 사정으로 취소합니다. 아래 두 작업을 **하나의 트랜잭션**으로 처리하세요.
> 1. 주문 상태를 `'취소'`로
> 2. 해당 고객에게 **SORRY2000** 쿠폰 지급 (지급 `'2026-06-30 19:40:00'`, 만료 30일 후)
>
> 처리 후 주문 상태와 고객의 보유 쿠폰을 확인하세요.

- 확인 열: `order_id`, `status`, `customer_name`, `coupon_code`, `expires_at`

**정답 SQL**

```sql
START TRANSACTION;

UPDATE orders SET status = '취소' WHERE order_id = 563 AND status = '접수';

INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
SELECT o.customer_id,
    cp.coupon_id,
    '2026-06-30 19:40:00',
    DATE_ADD('2026-06-30 19:40:00', INTERVAL cp.valid_days DAY)
FROM orders o
CROSS JOIN coupons cp
WHERE o.order_id = 563 AND cp.code = 'SORRY2000';

COMMIT;

SELECT o.order_id,
    o.status,
    c.name AS customer_name,
    cp.code AS coupon_code,
    cc.expires_at
FROM orders o
JOIN customers c         ON o.customer_id  = c.customer_id
JOIN customer_coupons cc ON cc.customer_id = c.customer_id
JOIN coupons cp          ON cc.coupon_id   = cp.coupon_id
WHERE o.order_id = 563
ORDER BY cc.customer_coupon_id;
```

<sub>▶ 실행 결과 · 2행</sub>

| order_id | status | customer_name | coupon_code | expires_at |
|---|---|---|---|---|
| 563 | 취소 | 정우진 | WEEKEND15 | 2026-07-04 00:00:00 |
| 563 | 취소 | 정우진 | SORRY2000 | 2026-07-30 19:40:00 |


> **해설**
> - `WHERE order_id = 563 AND status = '접수'` — 이미 조리가 시작된 주문이면 0행이 바뀝니다. 그 경우 ROLLBACK해야 보상 쿠폰만 지급되는 일을 막을 수 있습니다. 상태 조건을 함께 거는 것이 **"확인하고 바꾸기"**를 한 문장으로 하는 방법입니다.
> - 만료일은 쿠폰의 `valid_days`(30일)로 계산했습니다. 숫자 30을 직접 쓰면 쿠폰 정책이 바뀌었을 때 틀린 값이 됩니다.
> - 정우진 님은 원래 주말 15% 쿠폰을 갖고 있어서 결과가 2행입니다.
