# Ch08. 데이터 변경과 트랜잭션 (DML · TCL)

> **PART 2 · 쓰기** | 3시간 | 난이도 ★★
> 이전: [Ch07. 테이블 설계와 제약조건](../ch07-ddl-constraints/README.md) | 다음: [Ch09. 데이터 모델링과 정규화](../ch09-modeling-normalization/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery08`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';
USE hanip_delivery08;
```

> 이번 챕터의 setup.sql에는 Ch07에서 설계한 **쿠폰 테이블 두 개**(`coupons`, `customer_coupons`)가 6월 말 발급 데이터와 함께 들어 있습니다.

```sql
SELECT cc.customer_coupon_id, c.name AS customer_name, cp.code, cc.expires_at, cc.used_order_id
FROM customer_coupons cc
JOIN customers c ON cc.customer_id = c.customer_id
JOIN coupons cp  ON cc.coupon_id   = cp.coupon_id
ORDER BY cc.customer_coupon_id;
```

<sub>▶ 실행 결과 · 8행</sub>

| customer_coupon_id | customer_name | code | expires_at | used_order_id |
|---|---|---|---|---|
| 1 | 윤서아 | WELCOME3000 | 2026-07-28 16:30:00 | NULL |
| 2 | 강도윤 | WELCOME3000 | 2026-07-29 09:00:00 | NULL |
| 3 | 조은서 | WELCOME3000 | 2026-07-29 09:00:00 | NULL |
| 4 | 김민준 | VIP5000 | 2026-08-29 09:00:00 | NULL |
| 5 | 이서연 | VIP5000 | 2026-08-29 09:00:00 | NULL |
| 6 | 박지훈 | VIP5000 | 2026-08-29 09:00:00 | NULL |
| 7 | 정우진 | WEEKEND15 | 2026-07-04 00:00:00 | NULL |
| 8 | 강하은 | WEEKEND15 | 2026-07-04 00:00:00 | NULL |


## 오늘의 요청

> **From.** 개발팀 한 팀장
>
> 주문 접수 로직을 SQL로 짜 주세요. 고객이 "주문하기"를 누르면 이 일들이 **한꺼번에** 일어나야 합니다.
> 1. `orders`에 주문 1행
> 2. `order_items`에 메뉴 줄 여러 행 (**주문 당시 가격**으로)
> 3. 쿠폰을 썼다면 `customer_coupons`에 **사용 표시**
>
> **중간에 하나라도 실패하면 전부 없던 일**이 돼야 합니다. 주문은 들어갔는데 메뉴가 빠졌거나, 쿠폰만 써 버린 상태가 되면 고객센터에 불이 납니다.
>
> 첫 테스트 주문은 VIP 김민준 님입니다: 서면옛날돼지국밥에서 **돼지국밥 2개 + 수육 백반 1개**, **VIP 5,000원 쿠폰** 사용, 간편결제.

지금까지는 데이터를 읽고(Ch01~06) 그릇을 만들었습니다(Ch07). 오늘은 데이터를 **넣고, 고치고, 지우고**, 그 작업들을 **하나로 묶는** 법을 배웁니다. 완성 스크립트는 [8절](#8-오늘의-요청-해결).

## 학습 목표

1. `INSERT`(단건·다건·`INSERT … SELECT`)로 데이터를 넣고 `LAST_INSERT_ID()`로 새 번호를 받는다.
2. `UPDATE`·`DELETE`를 **WHERE와 함께** 쓰고, 실행 전에 같은 조건으로 SELECT해 대상을 확인한다.
3. 안전 업데이트 모드(1175)와 FK(1451)가 막아 주는 사고를 설명한다.
4. 트랜잭션과 ACID를 설명하고 `START TRANSACTION`·`COMMIT`·`ROLLBACK`·`SAVEPOINT`를 쓴다.
5. 여러 테이블에 걸친 작업을 **원자적으로** 처리하는 스크립트를 작성한다.

---

## 1. INSERT — 데이터 넣기

### 1-1. 열을 지정해서 넣기

```sql
INSERT INTO 테이블 (열1, 열2, …) VALUES (값1, 값2, …);
```

6월 24일 입점한 전포동오일파스타에 새 메뉴를 추가합니다.

```sql
INSERT INTO menus (restaurant_id, name, price, description)
VALUES (15, '명란 크림 파스타', 15000, '저염 명란과 생크림');
```


```sql
SELECT menu_id, restaurant_id, name, price, is_signature, is_sold_out
FROM menus
WHERE restaurant_id = 15;
```

<sub>▶ 실행 결과 · 4행</sub>

| menu_id | restaurant_id | name | price | is_signature | is_sold_out |
|---|---|---|---|---|---|
| 70 | 15 | 감바스 알 아히요 | 17000 | 0 | 0 |
| 71 | 15 | 명란 크림 파스타 | 15000 | 0 | 0 |
| 69 | 15 | 쉬림프 오일 파스타 | 16000 | 0 | 0 |
| 68 | 15 | 알리오 올리오 | 13000 | 1 | 0 |


> - `menu_id`는 `AUTO_INCREMENT`라 생략하면 다음 번호(71)가 자동으로 붙습니다.
> - `is_signature`, `is_sold_out`은 `DEFAULT FALSE`라 생략하면 0이 들어갑니다.
> - **열 목록을 꼭 쓰세요.** `INSERT INTO menus VALUES (…)`처럼 열을 생략하면 테이블의 **모든 열을 정의된 순서대로** 줘야 하고, 나중에 열이 추가되면 쿼리가 깨지거나 엉뚱한 열에 값이 들어갑니다.

### 1-2. 여러 행 한 번에

```sql
INSERT INTO menus (restaurant_id, name, price) VALUES
    (15, '봉골레 파스타', 16000),
    (15, '레몬 에이드',   4500);
```


> 한 문장으로 여러 행을 넣으면 서버 왕복이 한 번이라 빠르고, 한 행이라도 실패하면 **문장 전체가 실패**합니다(일부만 들어가지 않음).

### 1-3. 방금 넣은 번호 받기 — LAST_INSERT_ID()

주문을 넣은 뒤 주문 상세를 넣으려면 **방금 생긴 주문 번호**를 알아야 합니다. 바로 앞의 다건 INSERT가 만든 번호를 확인해 봅니다.

```sql
SELECT LAST_INSERT_ID() AS last_id;
```

<sub>▶ 실행 결과 · 1행</sub>

| last_id |
|---|
| 72 |


> `LAST_INSERT_ID()`는 **이 접속(세션)에서** 마지막으로 AUTO_INCREMENT가 만든 번호입니다. 다른 사람이 동시에 주문을 넣어도 섞이지 않습니다. `SELECT MAX(order_id) FROM orders`로 대신하면 **동시 주문이 있을 때 남의 주문 번호**를 가져오는 버그가 생깁니다.
> 다건 INSERT 후에는 **첫 번째 행**의 번호를 돌려줍니다.

### 1-4. INSERT … SELECT — 조회 결과를 그대로 넣기

정산팀이 매일 보는 **월별 가게 매출 요약표**를 만들어 둡니다.

```sql
CREATE TABLE monthly_store_sales (
    sales_month   CHAR(7)  NOT NULL,
    restaurant_id INT      NOT NULL,
    orders        INT      NOT NULL,
    food_sales    INT      NOT NULL,
    CONSTRAINT pk_monthly_store_sales PRIMARY KEY (sales_month, restaurant_id),
    CONSTRAINT fk_mss_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)
);
```


```sql
INSERT INTO monthly_store_sales (sales_month, restaurant_id, orders, food_sales)
SELECT DATE_FORMAT(o.ordered_at, '%Y-%m'),
    o.restaurant_id,
    COUNT(DISTINCT o.order_id),
    SUM(oi.quantity * oi.unit_price)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
GROUP BY DATE_FORMAT(o.ordered_at, '%Y-%m'), o.restaurant_id;
```


```sql
SELECT COUNT(*) AS rows_inserted, SUM(food_sales) AS total_sales
FROM monthly_store_sales;
```

<sub>▶ 실행 결과 · 1행</sub>

| rows_inserted | total_sales |
|---|---|
| 80 | 15676900 |


> `VALUES` 자리에 SELECT가 옵니다. 열 개수와 순서만 맞으면 Ch02~06에서 배운 어떤 SELECT든 쓸 수 있습니다. 요약표(집계 테이블)를 만들어 두면 매번 563건을 다시 계산하지 않아도 됩니다 — 이런 판단을 Ch09에서 **반정규화**라고 부릅니다.

---

## 2. UPDATE — 고치기

```sql
UPDATE 테이블
SET 열1 = 값1, 열2 = 값2
WHERE 조건;          -- ← 없으면 모든 행
```

### 2-1. WHERE가 안전핀이다

```sql
SET SQL_SAFE_UPDATES = 1;
UPDATE menus SET price = price + 500;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1175. You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column. 
```


> MySQL Workbench는 기본으로 **안전 업데이트 모드**(`SQL_SAFE_UPDATES = 1`)가 켜져 있어서, WHERE가 없거나 WHERE에 **키(PK·인덱스) 열**을 쓰지 않은 UPDATE·DELETE를 막습니다. 위 문장이 실행됐다면 70개 메뉴 가격이 전부 500원씩 올랐을 겁니다.
> 안전 모드는 끄지 마세요. 꺼야 할 만큼 큰 작업이라면 WHERE에 키 조건을 넣어 범위를 좁히는 게 맞습니다.

### 2-2. 바꾸기 전에 SELECT

**같은 WHERE로 먼저 SELECT**해서 바뀔 행을 눈으로 확인하는 습관이 사고를 막습니다.

```sql
SELECT menu_id, name, price
FROM menus
WHERE restaurant_id = 3 AND is_signature = TRUE;
```

<sub>▶ 실행 결과 · 2행</sub>

| menu_id | name | price |
|---|---|---|
| 11 | 물밀면 | 9000 |
| 12 | 비빔밀면 | 9000 |


```sql
UPDATE menus
SET price = price + 500
WHERE restaurant_id = 3 AND is_signature = TRUE;
```


```sql
SELECT menu_id, name, price
FROM menus
WHERE restaurant_id = 3 AND is_signature = TRUE;
```

<sub>▶ 실행 결과 · 2행</sub>

| menu_id | name | price |
|---|---|---|
| 11 | 물밀면 | 9500 |
| 12 | 비빔밀면 | 9500 |


> - `SET price = price + 500`처럼 **현재 값을 이용한 계산**도 됩니다.
> - Workbench 출력 창의 `2 row(s) affected`가 예상한 행 수와 같은지 확인하세요. SQL로는 `SELECT ROW_COUNT();`로 직전 문장이 바꾼 행 수를 볼 수 있습니다.
> - `restaurant_id`는 FK라 인덱스가 있으므로 안전 모드에서도 실행됩니다.

### 2-3. 여러 열 한 번에

```sql
UPDATE menus
SET is_sold_out = FALSE,
    description = '딸기 시즌 재입고'
WHERE menu_id = 67;
```


```sql
SELECT menu_id, name, is_sold_out, description FROM menus WHERE menu_id = 67;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | is_sold_out | description |
|---|---|---|---|
| 67 | 딸기 크로플 | 0 | 딸기 시즌 재입고 |


---

## 3. DELETE — 지우기

```sql
DELETE FROM 테이블 WHERE 조건;
```

### 3-1. 지울 수 있는 것

고객이 신고한 부적절한 리뷰 하나를 지웁니다.

```sql
SELECT review_id, order_id, rating, content FROM reviews WHERE review_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| review_id | order_id | rating | content |
|---|---|---|---|
| 1 | 4 | 5 | 배달 빠르고 맛은 최고 |


```sql
DELETE FROM reviews WHERE review_id = 1;
```


```sql
SELECT COUNT(*) AS reviews_left FROM reviews;
```

<sub>▶ 실행 결과 · 1행</sub>

| reviews_left |
|---|
| 259 |


### 3-2. FK가 막는 삭제

```sql
DELETE FROM restaurants WHERE restaurant_id = 13;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1451. Cannot delete or update a parent row: a foreign key constraint fails (`hanip_delivery08`.`menus`, CONSTRAINT `fk_menus_restaurant` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`))
```


> 폐업한 서면야식치킨에는 메뉴와 주문이 연결되어 있어 지울 수 없습니다(Ch07 5-4절). 실제로 지워서도 안 됩니다 — 과거 주문과 정산 기록이 남아야 하니까요. 그래서 이 DB는 `is_open = FALSE`로 **논리 삭제**합니다.

### 3-3. 무엇을 지울 수 있고, 무엇은 지우면 안 되나

| 데이터 | 처리 | 이유 |
|---|---|---|
| 리뷰, 공지, 임시 데이터 | `DELETE` | 다른 데이터가 참조하지 않음 |
| 가게, 기사, 메뉴 | `UPDATE … SET is_open/is_active/is_sold_out` | 과거 주문이 참조 |
| 고객 | 탈퇴 처리 + 개인정보 마스킹(`UPDATE`) | 주문·결제 기록 보관 의무 |
| 주문, 결제 | **지우지 않음.** 상태를 `'취소'`로 | 회계·법적 기록 |

---

## 4. 트랜잭션 — 전부 아니면 전무

### 4-1. 왜 필요한가

주문 접수는 세 문장입니다. 두 번째 문장 직후 서버가 죽으면?

```
 ① INSERT INTO orders …            ✔ 저장됨
 ② INSERT INTO order_items …       ✘ 서버 다운
 ③ UPDATE customer_coupons …       — 실행 안 됨
 ─────────────────────────────────────────────
 결과: 메뉴가 하나도 없는 "빈 주문"이 DB에 남음
```

**트랜잭션**은 여러 문장을 **하나의 작업 단위**로 묶어, 전부 반영되거나(COMMIT) 전부 취소되게(ROLLBACK) 합니다. 계좌이체에서 "내 계좌 출금"과 "상대 계좌 입금"이 반드시 함께 일어나야 하는 것과 같습니다.

### 4-2. ACID

| 성질 | 뜻 | 한입배달에서 |
|---|---|---|
| **A**tomicity 원자성 | 전부 반영되거나 전부 취소 | 주문·상세·쿠폰 중 일부만 저장되는 일 없음 |
| **C**onsistency 일관성 | 트랜잭션 전후 모든 제약조건 만족 | 쿠폰 중복 사용(UNIQUE), 없는 메뉴(FK) 불가 |
| **I**solation 격리성 | 동시에 실행돼도 서로 간섭하지 않는 것처럼 | 두 상담원이 같은 쿠폰을 동시에 써도 한 명만 성공 |
| **D**urability 지속성 | COMMIT된 결과는 서버가 꺼져도 남음 | 결제 완료된 주문은 사라지지 않음 |

### 4-3. 자동 커밋(autocommit)

MySQL은 기본적으로 **문장 하나하나가 자동으로 COMMIT**됩니다(autocommit = 1). 지금까지 INSERT·UPDATE가 바로 저장된 이유입니다. 여러 문장을 묶으려면 `START TRANSACTION`으로 명시적으로 시작합니다.

```sql
SELECT @@autocommit;
```

<sub>▶ 실행 결과 · 1행</sub>

| @@autocommit |
|---|
| 1 |


---

## 5. COMMIT과 ROLLBACK

### 5-1. ROLLBACK — 없던 일로

**실수 체험**: 리뷰를 "정리"하려다 WHERE를 잘못 써서 별점 4점 이상 리뷰를 몽땅 지웠습니다.

```sql
START TRANSACTION;
DELETE FROM reviews WHERE rating >= 4 AND review_id > 0;
SELECT COUNT(*) AS reviews_after_delete FROM reviews;
```

<sub>▶ 실행 결과 · 1행</sub>

| reviews_after_delete |
|---|
| 54 |


```sql
ROLLBACK;
SELECT COUNT(*) AS reviews_after_rollback FROM reviews;
```

<sub>▶ 실행 결과 · 1행</sub>

| reviews_after_rollback |
|---|
| 259 |


> `START TRANSACTION` 이후의 변경은 **COMMIT 전까지 임시 상태**입니다. ROLLBACK하면 트랜잭션 시작 시점으로 돌아갑니다. 운영 DB에서 위험한 UPDATE·DELETE를 할 때는 **트랜잭션 안에서 실행 → 결과 확인 → COMMIT 또는 ROLLBACK**을 습관으로 삼으세요.
> (`review_id > 0`은 안전 모드에서 키 조건을 주기 위해 붙였습니다.)

### 5-2. COMMIT — 확정

```sql
START TRANSACTION;
UPDATE coupons SET is_active = FALSE WHERE coupon_id = 2;
COMMIT;
```


```sql
SELECT code, is_active FROM coupons ORDER BY coupon_id;
```

<sub>▶ 실행 결과 · 4행</sub>

| code | is_active |
|---|---|
| WELCOME3000 | 1 |
| WEEKEND15 | 0 |
| VIP5000 | 1 |
| SORRY2000 | 1 |


> COMMIT 이후에는 ROLLBACK해도 돌아오지 않습니다. 확정된 변경을 되돌리려면 반대 작업(`UPDATE … SET is_active = TRUE`)을 새로 해야 합니다.

### 5-3. SAVEPOINT — 중간 저장

긴 트랜잭션 안에서 **일부만** 되돌리고 싶을 때 씁니다.

```sql
START TRANSACTION;
UPDATE menus SET price = 11000 WHERE menu_id = 1;
SAVEPOINT after_price;
UPDATE menus SET is_sold_out = TRUE WHERE menu_id = 1;
ROLLBACK TO SAVEPOINT after_price;
COMMIT;
```


```sql
SELECT menu_id, name, price, is_sold_out FROM menus WHERE menu_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price | is_sold_out |
|---|---|---|---|
| 1 | 돼지국밥 | 11000 | 0 |


> 가격 인상은 남고, 품절 처리만 취소됐습니다.

```sql
UPDATE menus SET price = 10000 WHERE menu_id = 1;
```


> (다음 실습을 위해 가격을 원래대로 되돌렸습니다.)

### 5-4. ⚠️ DDL은 트랜잭션을 끝낸다

`CREATE`, `ALTER`, `DROP`, `TRUNCATE`는 실행되는 순간 **그 전까지의 트랜잭션을 자동으로 COMMIT**합니다(암묵적 커밋). 트랜잭션 안에 DDL을 섞지 마세요. `TRUNCATE`가 ROLLBACK되지 않는 이유도 이것입니다(Ch07 7절).

---

## 6. 주문 접수 트랜잭션

### 6-1. 성공 시나리오

```sql
START TRANSACTION;

-- ① 주문 머리
INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, request_note, ordered_at)
VALUES (1, 1, '접수', '간편결제', 2500, 5000, '문 앞에 두고 벨 눌러주세요', '2026-06-30 19:05:00');

SET @order_id = LAST_INSERT_ID();

-- ② 주문 상세: 단가는 지금 메뉴 가격으로 (주문 당시 가격 보존)
INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, CASE menu_id WHEN 1 THEN 2 ELSE 1 END, price
FROM menus
WHERE menu_id IN (1, 4);

-- ③ 쿠폰 사용 표시 (아직 안 쓴 쿠폰만)
UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 1 AND coupon_id = 3 AND used_order_id IS NULL;

SELECT @order_id AS new_order_id, ROW_COUNT() AS coupon_rows_updated;
```

<sub>▶ 실행 결과 · 1행</sub>

| new_order_id | coupon_rows_updated |
|---|---|
| 564 | 1 |


```sql
COMMIT;
```


> - `SET @order_id = …`는 **사용자 변수**입니다. 이 접속이 끊길 때까지 값을 기억합니다.
> - `unit_price`를 `menus.price`에서 복사해 두기 때문에, 나중에 메뉴 가격이 바뀌어도 이 주문의 금액은 그대로입니다.
> - `coupon_rows_updated = 1`을 확인한 뒤 COMMIT했습니다. 실제 애플리케이션 코드도 똑같이 "영향받은 행 수"를 보고 COMMIT/ROLLBACK을 결정합니다.

결과 확인 — Ch05의 JOIN으로 주문서를 다시 조립합니다.

```sql
SELECT o.order_id, c.name AS customer_name, r.name AS restaurant_name,
    m.name AS menu_name, oi.quantity, oi.unit_price,
    o.delivery_fee, o.discount_amount
FROM orders o
JOIN customers c    ON o.customer_id   = c.customer_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN menus m        ON oi.menu_id      = m.menu_id
WHERE o.order_id = (SELECT MAX(order_id) FROM orders)
ORDER BY oi.menu_id;
```

<sub>▶ 실행 결과 · 2행</sub>

| order_id | customer_name | restaurant_name | menu_name | quantity | unit_price | delivery_fee | discount_amount |
|---|---|---|---|---|---|---|---|
| 564 | 김민준 | 서면옛날돼지국밥 | 돼지국밥 | 2 | 10000 | 2500 | 5000 |
| 564 | 김민준 | 서면옛날돼지국밥 | 수육 백반 | 1 | 13000 | 2500 | 5000 |


```sql
SELECT cc.customer_coupon_id, cp.code, cc.used_order_id
FROM customer_coupons cc
JOIN coupons cp ON cc.coupon_id = cp.coupon_id
WHERE cc.customer_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| customer_coupon_id | code | used_order_id |
|---|---|---|
| 4 | VIP5000 | 564 |


> 결제 금액: 음식 33,000원 + 배달팁 2,500원 − 쿠폰 5,000원 = **30,500원**.
> (확인용 쿼리라 `MAX(order_id)`를 썼지만, 주문 로직 안에서는 반드시 `LAST_INSERT_ID()`를 씁니다.)

### 6-2. 실패 시나리오 ① — 이미 쓴 쿠폰

김민준 님이 같은 VIP 쿠폰으로 **한 번 더** 주문을 시도합니다.

```sql
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, ordered_at)
VALUES (1, 6, '접수', '카드', 3000, 5000, '2026-06-30 19:20:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price FROM menus WHERE menu_id = 26;

UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 1 AND coupon_id = 3 AND used_order_id IS NULL;

SELECT ROW_COUNT() AS coupon_rows_updated;
```

<sub>▶ 실행 결과 · 1행</sub>

| coupon_rows_updated |
|---|
| 0 |


에러는 없지만 **쿠폰 표시가 0행**입니다. 이미 쓴 쿠폰이라 `used_order_id IS NULL` 조건에 걸리지 않았습니다. 이대로 COMMIT하면 **5,000원 할인을 받은 주문**이 쿠폰 없이 저장됩니다. ROLLBACK합니다.

```sql
ROLLBACK;
SELECT COUNT(*) AS orders_total FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_total |
|---|
| 564 |


> 주문 수가 그대로(564)입니다. 들어갔던 주문 머리와 상세가 **함께** 취소됐습니다.

### 6-3. 실패 시나리오 ② — 중간에 에러

메뉴 번호를 잘못 넣어 주문 상세 INSERT가 FK 에러로 실패합니다.

```sql
START TRANSACTION;
INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
VALUES (2, 9, '접수', '카드', 2500, '2026-06-30 19:25:00');
SET @order_id = LAST_INSERT_ID();
```


```sql
INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
VALUES (@order_id, 999, 1, 5500);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`hanip_delivery08`.`order_items`, CONSTRAINT `fk_order_items_menu` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`menu_id`))
```


```sql
ROLLBACK;
SELECT COUNT(*) AS orders_total FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_total |
|---|
| 564 |


> ⚠️ **에러가 났다고 트랜잭션이 자동으로 취소되지는 않습니다.** 실패한 문장만 무효가 되고, 앞의 `INSERT INTO orders`는 트랜잭션 안에 그대로 남아 있습니다. 그 상태로 COMMIT하면 빈 주문이 저장됩니다. **에러가 나면 반드시 ROLLBACK** — 애플리케이션에서는 `try { … commit } catch { rollback }` 구조로 씁니다(Spring의 `@Transactional`이 이 일을 대신 해 줍니다).

---

## 7. 동시성과 격리 수준 (개념)

두 상담원이 **같은 순간** 같은 고객의 같은 쿠폰을 쓰려고 하면?

```
 시간   세션 A (상담원 1)                       세션 B (상담원 2)
 t1    START TRANSACTION;
 t2    UPDATE customer_coupons SET used… 
       WHERE customer_coupon_id = 5
         AND used_order_id IS NULL;   → 1행
 t3                                           START TRANSACTION;
 t4                                           UPDATE … WHERE customer_coupon_id = 5
                                                AND used_order_id IS NULL;
                                              ⏳ A가 끝날 때까지 대기 (행 잠금)
 t5    COMMIT;
 t6                                           → 0행 (이미 사용됨) → ROLLBACK
```

InnoDB는 UPDATE하는 행에 **잠금(lock)**을 걸어 동시 수정을 줄 세웁니다. 그래서 `… AND used_order_id IS NULL` 조건 + "영향받은 행 수 확인" 패턴만으로도 쿠폰 이중 사용을 막을 수 있습니다.

| 격리 수준 | 다른 트랜잭션의 미확정 변경을 읽나 | 비고 |
|---|---|---|
| READ UNCOMMITTED | 읽음 (Dirty Read) | 거의 안 씀 |
| READ COMMITTED | COMMIT된 것만 | Oracle·PostgreSQL 기본 |
| **REPEATABLE READ** | 트랜잭션 시작 시점 기준으로 일관되게 | **MySQL 기본** |
| SERIALIZABLE | 완전히 순서대로 | 가장 안전, 가장 느림 |

> 직접 체험하려면 Workbench에서 **SQL 탭을 두 개** 열고(각각 별도 접속), 위 표의 시간 순서대로 번갈아 실행해 보세요. 세션 B가 멈춰 있다가 A의 COMMIT 직후 풀리는 것을 볼 수 있습니다. 오래 기다리면 `1205 Lock wait timeout exceeded`가 납니다.

---

## 8. 오늘의 요청 해결

6-1절이 개발팀에 넘길 주문 접수 스크립트입니다. 정리하면:

```sql
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, request_note, ordered_at)
VALUES (?, ?, '접수', ?, ?, ?, ?, NOW());
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, ?, price
FROM menus
WHERE menu_id = ? AND is_sold_out = FALSE;      -- 품절이면 0행 → 확인 후 ROLLBACK

UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_coupon_id = ? AND used_order_id IS NULL AND expires_at > NOW();
-- ROW_COUNT() = 1 이 아니면 ROLLBACK

COMMIT;
```

> `?`는 애플리케이션이 채워 넣는 값 자리(PreparedStatement 파라미터)입니다. 실제 서비스에서는 이 스크립트가 Java·Python 코드 안에서 실행되고, 각 단계의 영향받은 행 수를 확인해 COMMIT 또는 ROLLBACK을 결정합니다.

| 요청서 | 해결 |
|---|---|
| 세 테이블에 한꺼번에 | `START TRANSACTION … COMMIT` |
| 주문 당시 가격 | `INSERT … SELECT price FROM menus` |
| 쿠폰 사용 표시 | `UPDATE … WHERE used_order_id IS NULL` + 행 수 확인 |
| 하나라도 실패하면 전부 취소 | 에러·0행이면 `ROLLBACK` |

## 정리

| 문법 | 핵심 |
|---|---|
| `INSERT INTO t (열…) VALUES (…), (…)` | 열 목록 필수, 다건 가능 |
| `INSERT … SELECT` | 조회 결과를 그대로 넣기 |
| `LAST_INSERT_ID()` | 이 세션이 마지막으로 만든 번호. `MAX()`로 대신하지 않기 |
| `UPDATE … SET … WHERE` | WHERE는 안전핀. 먼저 같은 조건으로 SELECT |
| `DELETE FROM … WHERE` | FK가 막는 삭제(1451)는 논리 삭제로 |
| 안전 업데이트 모드 | 키 조건 없는 UPDATE·DELETE 차단(1175) |
| `START TRANSACTION` / `COMMIT` / `ROLLBACK` | 묶기 / 확정 / 취소. **에러가 나도 자동 ROLLBACK 아님** |
| `SAVEPOINT` | 일부만 되돌리기 |
| ACID | 원자성 · 일관성 · 격리성 · 지속성 |

## 다음 챕터 예고

> **From.** 데이터팀 김 팀장
> 지난 두 달 동안 우리 DB를 정말 많이 썼죠. 그런데 신입분들이 자주 묻더라고요. **"주문 금액은 왜 orders에 안 넣어요?"**, **"order_items에 가격이 또 있는 건 중복 아니에요?"**
> 다음 주에는 **리뷰 사진**과 **가게 사장님 답글** 기능이 추가됩니다. 테이블을 어떻게 나눌지 **설계도(ERD)부터** 그려 주세요.

이미 써 온 스키마가 **왜 이렇게 나뉘었는지**, 그리고 새 기능을 어떻게 설계하는지 — Ch09, 데이터 모델링과 정규화입니다.

<!-- lecture:auto -->
