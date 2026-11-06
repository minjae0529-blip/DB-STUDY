# Ch10. 뷰·인덱스·사용자 관리

> **PART 3 · 설계와 운영** | 3시간 | 난이도 ★★
> 이전: [Ch09. 데이터 모델링과 정규화](../ch09-modeling-normalization/README.md) | 다음: [Ch11. 트리거](../ch11-trigger/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery10`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 01부터 10까지, 지난 10번의 수업 기록
USE hanip_delivery10;
```

> 오늘은 **사용자 계정**을 만듭니다. 계정은 DB 하나가 아니라 **MySQL 서버 전체**에 속하므로, 반드시 `root`(또는 계정 생성 권한이 있는 계정)로 접속해 실습하세요.

## 오늘의 요청

> **From.** 데이터팀 김 팀장
>
> 운영 이야기 세 가지입니다.
> 1. 매주 뽑는 **가게별 매출 리포트**, 쿼리가 40줄이라 다들 복사해 쓰다가 조건 하나씩 틀려요. 이름 붙여서 **저장**해 두고 `SELECT * FROM …`으로 끝내고 싶어요.
> 2. 개발팀이 그러는데 주문이 수백만 건이 되면 **"오늘 주문" 화면이 느려진대요.** 지금 대비할 수 있는 게 있나요?
> 3. 다음 주 인턴이 옵니다. 리포트는 볼 수 있게, 하지만 **고객 전화번호는 못 보게**, 그리고 **아무것도 못 바꾸게** 계정을 만들어 주세요.

세 요청은 각각 **뷰**, **인덱스**, **사용자와 권한**입니다. 완성 스크립트는 [6절](#6-오늘의-요청-해결).

## 학습 목표

1. `CREATE VIEW`로 자주 쓰는 쿼리를 저장하고, 뷰 위에 다시 쿼리를 쌓는다.
2. 뷰로 **보여 줄 열만** 공개하는 보안 설계를 한다. 갱신 가능한 뷰의 조건을 설명한다.
3. 인덱스의 원리를 설명하고, `EXPLAIN`으로 실행 계획(`type`, `key`, `rows`)을 읽는다.
4. 인덱스를 **못 쓰게 되는** 조건(열 가공)과 복합 인덱스의 **열 순서**를 판단한다.
5. `CREATE USER` · `GRANT` · `REVOKE` · `ROLE`로 **최소 권한** 계정을 만든다.
6. `mysqldump`로 백업하고 복원한다.

---

## 1. 뷰 — 쿼리에 이름 붙이기

### 1-1. 주문 금액 뷰

주문 금액(음식값 + 배달팁 − 할인)은 Ch05부터 매번 JOIN과 GROUP BY로 계산했습니다. 이 계산을 **뷰(VIEW)**로 저장합니다.

```sql
CREATE VIEW v_order_amounts AS
SELECT o.order_id, o.ordered_at, o.customer_id, o.restaurant_id, o.status,
    SUM(oi.quantity * oi.unit_price) AS food_amount,
    o.delivery_fee, o.discount_amount,
    SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS total_amount
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;
```


뷰는 **테이블처럼** 조회합니다.

```sql
SELECT order_id, status, food_amount, delivery_fee, discount_amount, total_amount
FROM v_order_amounts
WHERE ordered_at >= '2026-06-30'
ORDER BY order_id;
```

<sub>▶ 실행 결과 · 6행</sub>

| order_id | status | food_amount | delivery_fee | discount_amount | total_amount |
|---|---|---|---|---|---|
| 558 | 배달완료 | 9000 | 2000 | 2000 | 9000 |
| 559 | 배달완료 | 41000 | 3500 | 0 | 44500 |
| 560 | 배달완료 | 17800 | 3000 | 0 | 20800 |
| 561 | 배달중 | 36000 | 2500 | 0 | 38500 |
| 562 | 조리중 | 20500 | 2500 | 0 | 23000 |
| 563 | 접수 | 29000 | 2000 | 0 | 31000 |


> **뷰는 데이터를 저장하지 않습니다.** 저장되는 것은 SELECT문뿐이고, 뷰를 조회할 때마다 그 SELECT가 실행됩니다. 그래서 원본 테이블이 바뀌면 뷰 결과도 즉시 바뀝니다. "가상 테이블"이라고 부르는 이유입니다.

### 1-2. 뷰 위에 뷰 — 가게별 월 매출 리포트

김 팀장의 첫 번째 요청입니다. 금액 계산은 이미 `v_order_amounts`가 하므로, 리포트 뷰는 그 위에 짧게 쌓습니다.

```sql
CREATE VIEW v_store_monthly_sales AS
SELECT DATE_FORMAT(a.ordered_at, '%Y-%m') AS sales_month,
    r.restaurant_id, r.name AS restaurant_name, r.category,
    COUNT(*) AS orders, SUM(a.total_amount) AS sales
FROM v_order_amounts a
JOIN restaurants r ON a.restaurant_id = r.restaurant_id
WHERE a.status = '배달완료'
GROUP BY DATE_FORMAT(a.ordered_at, '%Y-%m'), r.restaurant_id, r.name, r.category;
```


이제 40줄짜리 리포트가 한 줄입니다.

```sql
SELECT restaurant_name, category, orders, sales
FROM v_store_monthly_sales
WHERE sales_month = '2026-06'
ORDER BY sales DESC;
```

<sub>▶ 실행 결과 · 13행 (상위 5행 표시)</sub>

| restaurant_name | category | orders | sales |
|---|---|---|---|
| 광안리화덕피자 | 피자 | 12 | 544000 |
| 남천동마라공방 | 중식 | 10 | 473000 |
| 대연동크런치치킨 | 치킨 | 10 | 406000 |
| 동래파전골목집 | 한식 | 6 | 269000 |
| 서면옛날돼지국밥 | 한식 | 7 | 255000 |


| 뷰의 장점 | 설명 |
|---|---|
| **단순화** | 복잡한 JOIN·집계를 이름 하나로. 쓰는 사람은 내부를 몰라도 됨 |
| **일관성** | "배달완료만 매출"이라는 규칙이 뷰 한 곳에. 복사하다 조건을 빠뜨릴 일이 없음 |
| **보안** | 보여 줄 열·행만 담은 뷰를 만들어 그 뷰만 권한 부여 (1-4절, 5절) |
| **독립성** | 테이블 구조가 바뀌어도 뷰 정의만 고치면 뷰를 쓰는 쿼리는 그대로 |

뷰 목록과 정의는 이렇게 확인합니다.

```sql
SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema = DATABASE()
ORDER BY table_name;
```

<sub>▶ 실행 결과 · 2행</sub>

| view_name |
|---|
| v_order_amounts |
| v_store_monthly_sales |


```sql
SHOW CREATE VIEW v_store_monthly_sales;            -- 저장된 SELECT문 확인
CREATE OR REPLACE VIEW v_store_monthly_sales AS …;  -- 정의 바꾸기
DROP VIEW v_store_monthly_sales;                    -- 삭제 (원본 데이터는 그대로)
```

### 1-3. 뷰로 데이터를 바꿀 수 있나

**단순한 뷰**(테이블 하나, 집계·DISTINCT·GROUP BY 없음)는 뷰를 통해 UPDATE할 수 있습니다. 바뀌는 것은 원본 테이블입니다.

```sql
CREATE VIEW v_open_restaurants AS
SELECT restaurant_id, name, category, delivery_fee, is_open
FROM restaurants
WHERE is_open = TRUE
WITH CHECK OPTION;

UPDATE v_open_restaurants SET delivery_fee = 2500 WHERE restaurant_id = 4;

SELECT restaurant_id, name, delivery_fee FROM restaurants WHERE restaurant_id = 4;
```

<sub>▶ 실행 결과 · 1행</sub>

| restaurant_id | name | delivery_fee |
|---|---|---|
| 4 | 광안리화덕피자 | 2500 |


`WITH CHECK OPTION`은 **뷰의 WHERE 조건을 벗어나는 변경**을 막습니다. 영업 중인 가게 뷰로 가게를 휴업 처리하면, 그 행은 뷰에서 사라져 버리기 때문입니다.

```sql
UPDATE v_open_restaurants SET is_open = FALSE WHERE restaurant_id = 4;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1369. CHECK OPTION failed 'hanip_delivery10.v_open_restaurants'
```


집계한 뷰는 한 행이 원본의 여러 행이므로 바꿀 수 없습니다.

```sql
UPDATE v_store_monthly_sales SET sales = 0 WHERE restaurant_id = 1;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1288. The target table v_store_monthly_sales of the UPDATE is not updatable
```


> 실무에서 뷰는 대부분 **읽기 전용**으로 씁니다. 데이터 변경은 원본 테이블에 직접, 트랜잭션으로(Ch08).

### 1-4. 보안 뷰 — 전화번호 가리기

세 번째 요청의 준비입니다. 인턴에게 보여 줄 고객 뷰는 전화번호 가운데를 가리고, 이메일·주소·생일은 아예 빼고 만듭니다.

```sql
CREATE VIEW v_customers_masked AS
SELECT customer_id, name, CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS phone_masked,
    district, grade, joined_at
FROM customers;

SELECT * FROM v_customers_masked ORDER BY customer_id;
```

<sub>▶ 실행 결과 · 30행 (상위 3행 표시)</sub>

| customer_id | name | phone_masked | district | grade | joined_at |
|---|---|---|---|---|---|
| 1 | 김민준 | 010-****-5523 | 부산진구 | VIP | 2023-04-02 14:21:07 |
| 2 | 이서연 | 010-****-1187 | 수영구 | VIP | 2023-06-18 09:47:51 |
| 3 | 박지훈 | 010-****-7762 | 남구 | VIP | 2023-08-29 20:13:40 |


이 뷰에만 SELECT 권한을 주면 인턴은 **원본 `customers` 테이블 없이도** 뷰를 조회할 수 있습니다. 뷰는 기본적으로 **뷰를 만든 사람(DEFINER)의 권한**으로 실행되기 때문입니다(5절에서 확인).

## 2. 인덱스 — 찾아보기 페이지

### 2-1. 왜 필요한가

책에서 "트랜잭션"이 나오는 쪽을 찾는다고 해 봅시다.

| 방법 | 책에서 | DB에서 |
|---|---|---|
| 처음부터 끝까지 넘겨 보기 | 500쪽 전부 | **풀 테이블 스캔** — 모든 행을 읽음 |
| 맨 뒤 **찾아보기**(색인)에서 가나다순으로 찾기 | 몇 쪽만 | **인덱스 탐색** — 정렬된 목록에서 바로 찾아감 |

인덱스는 특정 열의 값을 **정렬해 둔 별도의 자료구조**(MySQL은 **B-Tree**)입니다. 정렬돼 있으니 사전 찾듯 범위를 반씩 좁혀 가며 몇 번 만에 찾습니다. 100만 행이면 풀 스캔은 100만 번, B-Tree는 대략 3~4단계면 됩니다.

### 2-2. 이미 있는 인덱스

PK, UNIQUE, FK에는 MySQL이 **자동으로** 인덱스를 만듭니다.

```sql
SELECT index_name AS index_name, column_name AS column_name,
    seq_in_index AS seq_in_index, non_unique AS non_unique
FROM information_schema.statistics
WHERE table_schema = DATABASE() AND table_name = 'orders'
ORDER BY index_name, seq_in_index;
```

<sub>▶ 실행 결과 · 4행</sub>

| index_name | column_name | seq_in_index | non_unique |
|---|---|---|---|
| fk_orders_customer | customer_id | 1 | 1 |
| fk_orders_restaurant | restaurant_id | 1 | 1 |
| fk_orders_rider | rider_id | 1 | 1 |
| PRIMARY | order_id | 1 | 0 |


`customer_id`, `restaurant_id`, `rider_id`에는 FK를 걸 때 인덱스가 생겼습니다. 그래서 "고객별 주문", "가게별 주문" 조회와 JOIN은 이미 빠릅니다. **주문 일시(`ordered_at`)에는 인덱스가 없습니다.**

### 2-3. EXPLAIN — 실행 계획 읽기

쿼리 앞에 `EXPLAIN`을 붙이면 실행하지 않고 **어떻게 실행할지**를 보여 줍니다. "오늘 주문" 화면의 쿼리입니다.

```sql
EXPLAIN
SELECT order_id, customer_id, status, ordered_at
FROM orders
WHERE ordered_at >= '2026-06-30';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | ALL | NULL | NULL | NULL | NULL | 563 | 33.33 | Using where |


| 열 | 뜻 | 지금 값 |
|---|---|---|
| `type` | 접근 방식. **`ALL` = 풀 테이블 스캔** (나쁨) → `range` · `ref` · `const` (좋음) | `ALL` |
| `possible_keys` | 쓸 수 있는 인덱스 후보 | 없음 |
| `key` | 실제로 고른 인덱스 | 없음 |
| `rows` | 읽을 것으로 예상한 행 수 | 563 = 전부 |

6건을 찾으려고 563행을 다 읽습니다. 주문이 500만 건이면 500만 행을 읽습니다.

### 2-4. CREATE INDEX

```sql
CREATE INDEX idx_orders_ordered_at ON orders (ordered_at);

EXPLAIN
SELECT order_id, customer_id, status, ordered_at
FROM orders
WHERE ordered_at >= '2026-06-30';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | range | idx_orders_ordered_at | idx_orders_ordered_at | 5 | NULL | 6 | 100.00 | Using index condition |


`type`이 `range`(인덱스로 범위 탐색), `key`가 새 인덱스, `rows`가 563 → 6으로 줄었습니다. 데이터가 커질수록 차이는 수천, 수만 배가 됩니다.

> 지금 데이터는 563행이라 실행 시간 차이는 체감되지 않습니다. 성능은 **시간이 아니라 `EXPLAIN`의 `type`과 `rows`로** 판단하는 습관을 들이세요. 운영 DB에서 시간으로 체감할 때는 이미 늦습니다.

### 2-5. 인덱스를 못 쓰게 만드는 쿼리

같은 "6월 30일 주문"을 이렇게 쓰면?

```sql
EXPLAIN
SELECT order_id, customer_id, status, ordered_at
FROM orders
WHERE DATE(ordered_at) = '2026-06-30';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | ALL | NULL | NULL | NULL | NULL | 563 | 100.00 | Using where |


다시 `ALL`입니다. 인덱스에는 `ordered_at` 값이 정렬돼 있지, `DATE(ordered_at)` 값이 정렬돼 있지 않습니다. **인덱스 열을 함수·연산으로 가공하면 인덱스를 쓸 수 없습니다.** 열은 그대로 두고 값 쪽을 범위로 바꿉니다.

| ✗ 인덱스 못 씀 | ✓ 인덱스 사용 |
|---|---|
| `WHERE DATE(ordered_at) = '2026-06-30'` | `WHERE ordered_at >= '2026-06-30' AND ordered_at < '2026-07-01'` |
| `WHERE YEAR(ordered_at) = 2026` | `WHERE ordered_at >= '2026-01-01' AND ordered_at < '2027-01-01'` |
| `WHERE price + 500 > 10000` | `WHERE price > 9500` |
| `WHERE name LIKE '%국밥'` (앞이 %) | `WHERE name LIKE '돼지%'` (앞이 고정) |

### 2-6. 복합 인덱스 — 열 순서가 중요하다

가게 사장님 앱의 "우리 가게 이번 달 주문" 쿼리입니다.

```sql
EXPLAIN
SELECT order_id, status, ordered_at
FROM orders
WHERE restaurant_id = 4 AND ordered_at >= '2026-06-01';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | ref | fk_orders_restaurant,idx_orders_ordered_at | fk_orders_restaurant | 4 | const | 56 | 19.36 | Using where |


FK 인덱스로 4번 가게 주문 56건을 찾은 뒤, 그중 6월 것을 하나씩 걸러 냅니다(`filtered` = 걸러진 뒤 남는 비율 예상). 두 조건을 **한 인덱스로** 처리하려면 두 열을 묶은 **복합 인덱스**를 만듭니다.

```sql
CREATE INDEX idx_orders_restaurant_date ON orders (restaurant_id, ordered_at);

EXPLAIN
SELECT order_id, status, ordered_at
FROM orders
WHERE restaurant_id = 4 AND ordered_at >= '2026-06-01';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | range | idx_orders_ordered_at,idx_orders_restaurant_date | idx_orders_restaurant_date | 9 | NULL | 13 | 100.00 | Using index condition |


`rows`가 56 → 13. 복합 인덱스는 **전화번호부**처럼 정렬됩니다. 먼저 `restaurant_id`로, 같은 가게 안에서 `ordered_at`으로. 그래서 "4번 가게의 6월 이후"를 한 번에 잘라 낼 수 있습니다.

그럼 이 인덱스로 **날짜만** 조건인 쿼리도 빠를까요? 단일 인덱스 `idx_orders_ordered_at`을 잠시 **안 보이게(INVISIBLE)** 하고 확인합니다.

```sql
ALTER TABLE orders ALTER INDEX idx_orders_ordered_at INVISIBLE;

EXPLAIN
SELECT order_id, status, ordered_at
FROM orders
WHERE ordered_at >= '2026-06-30';
```

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | ALL | NULL | NULL | NULL | NULL | 563 | 33.33 | Using where |


`ALL`입니다. 전화번호부가 성(姓) 순이면 이름만으로는 찾을 수 없는 것과 같습니다. 복합 인덱스는 **왼쪽 열부터** 써야 합니다(**최좌측 접두사 규칙**).

```sql
ALTER TABLE orders ALTER INDEX idx_orders_ordered_at VISIBLE;
```


> `INVISIBLE`은 인덱스를 지우지 않고 옵티마이저에게만 숨기는 MySQL 8 기능입니다. "이 인덱스 지워도 될까?"를 운영 중에 안전하게 시험해 볼 때 씁니다.

| 복합 인덱스 (A, B) | 사용 가능? |
|---|---|
| `WHERE A = ?` | ✓ |
| `WHERE A = ? AND B >= ?` | ✓ (가장 효과적) |
| `WHERE B >= ?` | ✗ (A를 건너뜀) |

열 순서는 **같다(=) 조건 열을 앞에, 범위(>=, BETWEEN) 조건 열을 뒤에** 두는 것이 기본입니다.

### 2-7. 인덱스는 공짜가 아니다

| 비용 | 설명 |
|---|---|
| 쓰기가 느려짐 | INSERT·UPDATE·DELETE마다 인덱스도 함께 고쳐야 함. 인덱스 5개 = 5곳 수정 |
| 저장 공간 | 인덱스는 별도의 자료구조 |
| 옵티마이저 혼란 | 비슷한 인덱스가 많으면 엉뚱한 것을 고르기도 함 |

**인덱스를 만들 열**: WHERE·JOIN·ORDER BY에 **자주** 나오고, 값의 종류가 많은(선택도가 높은) 열.
**만들지 않을 열**: 거의 조회하지 않는 열, `is_open`처럼 값이 두세 종류뿐인 열(절반을 읽을 거면 풀 스캔이 나음), 자주 바뀌는 열.

인덱스 삭제는 `DROP INDEX 인덱스명 ON 테이블명;`입니다.

## 3. 사용자와 권한

### 3-1. 계정은 '이름'@'접속 위치'

지금까지 우리는 모든 권한을 가진 `root`로 일했습니다. 운영에서 모든 사람이 root를 쓰면, 인턴의 실수 하나로 `DROP DATABASE`가 실행될 수 있습니다. **각자 필요한 만큼만** — **최소 권한 원칙**입니다.

MySQL 계정은 **`'사용자명'@'호스트'`** 한 쌍입니다. 같은 이름이라도 접속 위치가 다르면 다른 계정입니다.

| 호스트 | 뜻 |
|---|---|
| `'localhost'` | 이 컴퓨터에서만 접속 |
| `'192.168.0.%'` | 사내망에서만 |
| `'%'` | 어디서든 (운영에서는 주의) |

### 3-2. CREATE USER · GRANT

인턴 계정을 만들고, 리포트 뷰와 마스킹 뷰만 **읽을** 수 있게 합니다.

```sql
DROP USER IF EXISTS 'hanip_intern'@'localhost';
CREATE USER 'hanip_intern'@'localhost' IDENTIFIED BY 'Intern!2026';

GRANT SELECT ON hanip_delivery10.v_store_monthly_sales TO 'hanip_intern'@'localhost';
GRANT SELECT ON hanip_delivery10.v_customers_masked    TO 'hanip_intern'@'localhost';

SHOW GRANTS FOR 'hanip_intern'@'localhost';
```

<sub>▶ 실행 결과 · 3행</sub>

| Grants for hanip_intern@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_intern`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_customers_masked` TO `hanip_intern`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_store_monthly_sales` TO `hanip_intern`@`localhost` |


| GRANT 범위 | 문법 |
|---|---|
| 서버 전체 | `ON *.*` |
| DB 하나 | `ON hanip_delivery10.*` |
| 테이블·뷰 하나 | `ON hanip_delivery10.v_customers_masked` |
| 특정 열만 | `GRANT SELECT (customer_id, name, grade) ON hanip_delivery10.customers` |

`USAGE`는 "접속만 가능, 권한 없음"이라는 뜻입니다.

### 3-3. 인턴으로 접속해 보기

Workbench 첫 화면에서 **MySQL Connections ⊕** → Username `hanip_intern`, Password `Intern!2026`으로 새 접속을 만들어 들어갑니다.

```sql
USE hanip_delivery10;
SHOW TABLES;                                   -- 권한 있는 뷰 2개만 보인다
SELECT * FROM v_customers_masked LIMIT 3;      -- ✓ 010-****-5523 형태
SELECT phone FROM customers LIMIT 1;           -- ✗ 아래 에러
DELETE FROM v_customers_masked WHERE customer_id = 1;   -- ✗
```

```
Error Code: 1142. SELECT command denied to user 'hanip_intern'@'localhost' for table 'customers'
Error Code: 1142. DELETE command denied to user 'hanip_intern'@'localhost' for table 'v_customers_masked'
```

인턴은 `customers` 테이블에 권한이 없지만 `v_customers_masked`는 조회됩니다. 뷰가 **만든 사람의 권한**으로 원본을 읽기 때문입니다. 요청 3번(전화번호 못 보게, 아무것도 못 바꾸게)이 해결됐습니다.

### 3-4. REVOKE — 권한 회수

```sql
REVOKE SELECT ON hanip_delivery10.v_customers_masked FROM 'hanip_intern'@'localhost';

SHOW GRANTS FOR 'hanip_intern'@'localhost';
```

<sub>▶ 실행 결과 · 2행</sub>

| Grants for hanip_intern@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_intern`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_store_monthly_sales` TO `hanip_intern`@`localhost` |


> 퇴사·계약 종료 시에는 `DROP USER`로 계정 자체를 지웁니다. 비밀번호 변경은 `ALTER USER '…'@'…' IDENTIFIED BY '새비밀번호';`

### 3-5. 역할(ROLE) — 권한 묶음

인턴이 다섯 명이면 GRANT를 다섯 번씩 해야 할까요? **역할**에 권한을 모아 두고, 사람에게는 역할을 줍니다.

```sql
DROP ROLE IF EXISTS 'hanip_report_reader';
CREATE ROLE 'hanip_report_reader';
GRANT SELECT ON hanip_delivery10.v_store_monthly_sales TO 'hanip_report_reader';
GRANT SELECT ON hanip_delivery10.v_customers_masked    TO 'hanip_report_reader';

GRANT 'hanip_report_reader' TO 'hanip_intern'@'localhost';
SET DEFAULT ROLE 'hanip_report_reader' TO 'hanip_intern'@'localhost';

SHOW GRANTS FOR 'hanip_intern'@'localhost' USING 'hanip_report_reader';
```

<sub>▶ 실행 결과 · 4행</sub>

| Grants for hanip_intern@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_intern`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_customers_masked` TO `hanip_intern`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_store_monthly_sales` TO `hanip_intern`@`localhost` |
| GRANT `hanip_report_reader`@`%` TO `hanip_intern`@`localhost` |


> `SET DEFAULT ROLE`을 빼먹으면 역할을 받아도 접속할 때 **활성화되지 않아** 권한이 없는 것처럼 보입니다. 가장 흔한 실수입니다.

### 3-6. 누구에게 무엇을

| 계정 | 권한 | 이유 |
|---|---|---|
| 웹 애플리케이션 서버 | `SELECT, INSERT, UPDATE, DELETE ON hanip_delivery10.*` | 데이터 처리만. DDL(DROP·ALTER) 불가 |
| 데이터 분석가 | `SELECT ON hanip_delivery10.*` | 읽기 전용 |
| 인턴 · 외부 협력사 | 마스킹 뷰에만 `SELECT` (역할로) | 개인정보 보호 |
| DBA | 전체 (`root`) | 사람 수를 최소로, 일상 업무에는 쓰지 않기 |

## 4. 백업과 복원 — mysqldump

`mysqldump`는 DB를 **SQL 파일**(CREATE TABLE + INSERT문)로 내보냅니다. 명령 프롬프트(터미널)에서 실행합니다.

```bash
# 오늘 DB 백업
mysqldump -u root -p --routines --triggers hanip_delivery10 > hanip_delivery10_backup.sql

# 지금까지의 수업 기록 01~10 전부를 한 파일로
mysqldump -u root -p --databases hanip_delivery01 hanip_delivery02 hanip_delivery03 hanip_delivery04 hanip_delivery05 hanip_delivery06 hanip_delivery07 hanip_delivery08 hanip_delivery09 hanip_delivery10 > hanip_all_chapters.sql

# 복원: 빈 DB를 만들고 그 안으로
mysql -u root -p -e "CREATE DATABASE hanip_delivery10_restore"
mysql -u root -p hanip_delivery10_restore < hanip_delivery10_backup.sql
```

Workbench에서는 **Server → Data Export**(백업) / **Data Import/Restore**(복원)가 같은 일을 합니다.

| 주의 | 설명 |
|---|---|
| 백업은 **복원해 봐야** 백업 | 정기적으로 다른 DB에 복원해 행 수를 확인 |
| 비밀번호를 명령에 쓰지 않기 | `-p`만 쓰고 입력 받기. 스크립트는 설정 파일 사용 |
| 계정은 포함되지 않음 | 사용자·권한은 `mysql` 시스템 DB에 있음. 별도로 관리 |

## 5. SQL 총정리 — 명령어 분류와 시험 포인트

10챕터 동안 배운 SQL을 한 장에 정리합니다. 정보처리기사 필기·실기의 단골 분류입니다.

| 분류 | 명령어 | 챕터 |
|---|---|---|
| **DDL** 데이터 정의어 | `CREATE` · `ALTER` · `DROP` · `TRUNCATE` | 07, 09, 10 |
| **DML** 데이터 조작어 | `SELECT` · `INSERT` · `UPDATE` · `DELETE` | 02~06, 08 |
| **DCL** 데이터 제어어 | `GRANT` · `REVOKE` | 10 |
| **TCL** 트랜잭션 제어어 | `COMMIT` · `ROLLBACK` · `SAVEPOINT` | 08 |

| 단골 문제 | 핵심 |
|---|---|
| SELECT 실행 순서 | FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY (Ch04) |
| 집계와 NULL | `COUNT(*)`는 NULL 포함, `COUNT(열)`·`AVG`는 NULL 제외 (Ch04) |
| JOIN 결과 행 수 | INNER는 짝 있는 행만, LEFT는 왼쪽 전부 (Ch05) |
| 뷰의 특징 | 논리적 독립성·보안·단순화 / 인덱스 불가, 정의 변경은 삭제 후 재생성(표준), 집계 뷰는 갱신 불가 |
| `GRANT … WITH GRANT OPTION` | 받은 권한을 **남에게 다시 줄 수 있는** 권한 |
| `REVOKE … CASCADE` | (표준·Oracle) 그 사람이 남에게 준 권한까지 연쇄 회수 |
| 정규화 | 원자값 → 부분 종속 → 이행 종속 → 결정자 (Ch09) |
| ACID | 원자성 · 일관성 · 격리성 · 지속성 (Ch08) |

## 6. 오늘의 요청 해결

> **To.** 데이터팀 김 팀장
>
> 1. **리포트**: `SELECT * FROM v_store_monthly_sales WHERE sales_month = '2026-06';` 한 줄이면 됩니다. "배달완료만 매출" 규칙은 뷰 안에 고정했습니다.
> 2. **"오늘 주문" 속도**: `ordered_at` 인덱스를 추가해 풀 스캔(563행)을 범위 탐색(6행)으로 바꿨습니다. 가게 앱용으로 `(restaurant_id, ordered_at)` 복합 인덱스도 추가했습니다. 개발팀에는 `DATE(ordered_at) = …`처럼 **열을 가공하지 말라**고 전해 주세요.
> 3. **인턴 계정**: `hanip_intern`은 `hanip_report_reader` 역할로 리포트 뷰와 전화번호를 가린 고객 뷰만 **읽을** 수 있습니다. 원본 테이블은 볼 수도, 바꿀 수도 없습니다.

```sql
-- ① 뷰
CREATE VIEW v_order_amounts AS …;          -- 주문 금액 계산
CREATE VIEW v_store_monthly_sales AS …;    -- 가게별 월 매출 (배달완료만)
CREATE VIEW v_customers_masked AS …;       -- 전화번호 마스킹

-- ② 인덱스
CREATE INDEX idx_orders_ordered_at      ON orders (ordered_at);
CREATE INDEX idx_orders_restaurant_date ON orders (restaurant_id, ordered_at);

-- ③ 계정
CREATE USER 'hanip_intern'@'localhost' IDENTIFIED BY 'Intern!2026';
CREATE ROLE 'hanip_report_reader';
GRANT SELECT ON hanip_delivery10.v_store_monthly_sales TO 'hanip_report_reader';
GRANT SELECT ON hanip_delivery10.v_customers_masked    TO 'hanip_report_reader';
GRANT 'hanip_report_reader' TO 'hanip_intern'@'localhost';
SET DEFAULT ROLE 'hanip_report_reader' TO 'hanip_intern'@'localhost';
```

## 정리

| 개념 | 핵심 |
|---|---|
| `CREATE VIEW` | SELECT에 이름 붙이기. 데이터는 저장 안 함. 뷰 위에 뷰 가능 |
| 갱신 가능한 뷰 | 단일 테이블·집계 없음. `WITH CHECK OPTION`으로 조건 이탈 방지. 집계 뷰는 1288 |
| 보안 뷰 | 보여 줄 열만 + 그 뷰에만 GRANT. DEFINER 권한으로 실행 |
| 인덱스 | 정렬된 찾아보기(B-Tree). PK·UNIQUE·FK는 자동 생성 |
| `EXPLAIN` | `type` ALL(풀 스캔) vs range/ref, `key`, `rows` |
| 인덱스 못 쓰는 쿼리 | 열 가공(`DATE(열)`, `열 + 1`), 앞 `%` LIKE |
| 복합 인덱스 | 왼쪽 열부터. = 조건 앞, 범위 조건 뒤 |
| 계정 · 권한 | `'user'@'host'`, `GRANT … ON … TO`, `REVOKE … ON … FROM`, `SHOW GRANTS` |
| ROLE | 권한 묶음. `SET DEFAULT ROLE` 잊지 말기 |
| 백업 | `mysqldump` → SQL 파일, 복원은 `mysql <`. 복원해 봐야 백업 |

## 다음 챕터 예고

> **From.** 운영팀 박 팀장 · 정산팀 정 대리
> 사장님이 메뉴 가격을 바꿔도 **언제, 얼마에서 얼마로** 바꿨는지 기록이 안 남아요. 배달완료된 주문이 다시 '접수'로 돌아가는 버그도 있었고요. 개발자들에게 쿼리마다 챙기라고 하면 꼭 누군가 빠뜨립니다. **누가 어떤 경로로 데이터를 바꾸든** 자동으로 기록하고, 잘못된 변경은 막아 주세요.

데이터가 바뀌는 순간 자동으로 실행되는 SQL, **트리거** — PART 4 서버 프로그래밍의 시작, Ch11입니다.

<!-- lecture:auto -->
