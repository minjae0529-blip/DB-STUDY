# Day 8 실습 문제 — 성능과 안전: 인덱스, 뷰, 트랜잭션

> 한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점

---

## 스키마 빠른 참조

```
orders      (id, customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee, status)
restaurants (id, name, category, address, rating)
customers   (id, name, phone, email, address, joined_at)
menus       (id, restaurant_id, menu_name, price, description, is_available)
```

- customers 9번, 10번: 주문 0건
- restaurants 10번: 주문 0건

---

## ⭐ 기초 문제 (INDEX · VIEW 기초)

---

### 문제 1. ⭐ — orders 테이블에 인덱스 추가하기

> 운영팀이 "주문 조회가 너무 느려졌다"고 합니다. 현재 `orders` 테이블에는 `customer_id`, `restaurant_id`, `order_date` 컬럼에 인덱스가 없습니다.
>
> 다음 세 가지 인덱스를 생성하세요.
> 1. `customer_id` 컬럼 인덱스: 이름은 `idx_orders_customer`
> 2. `restaurant_id` 컬럼 인덱스: 이름은 `idx_orders_restaurant`
> 3. `order_date` 컬럼 인덱스: 이름은 `idx_orders_date`
>
> 생성 후 `SHOW INDEX FROM orders`로 결과를 확인하세요.

**사용 테이블:** `orders`

**예상 결과 (SHOW INDEX 일부):**

| Table | Key_name | Column_name | Non_unique |
|---|---|---|:---:|
| orders | PRIMARY | id | 0 |
| orders | idx_orders_customer | customer_id | 1 |
| orders | idx_orders_restaurant | restaurant_id | 1 |
| orders | idx_orders_date | order_date | 1 |

<details>
<summary>정답 보기</summary>

```sql
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_date       ON orders(order_date);

SHOW INDEX FROM orders;
```

**핵심 포인트:**
- 인덱스 이름은 `idx_테이블명_컬럼명` 형태로 짓는 것이 일반적입니다.
- `Non_unique = 1`은 중복 허용 인덱스, `0`은 UNIQUE 인덱스입니다.
- `PRIMARY`는 PK에 자동으로 생성된 인덱스입니다.

</details>

---

### 문제 2. ⭐ — 가게별 통계 VIEW 만들기

> 마케팅팀이 매주 "가게 이름, 카테고리, 주문수, 총매출, 평균주문금액"을 요청합니다. 매번 복잡한 JOIN + GROUP BY 쿼리를 새로 작성하기 번거로우니, VIEW로 저장해 두겠습니다.
>
> `v_restaurant_stats`라는 이름으로 뷰를 생성하세요. 뷰에 포함될 컬럼:
> - 가게 id, name, category
> - 주문수 (주문 없는 가게는 0)
> - 총매출 (주문 없으면 0, `IFNULL` 사용)
> - 평균주문금액 (반올림, 주문 없으면 0, `IFNULL` + `ROUND` 사용)
>
> 생성 후 `SELECT * FROM v_restaurant_stats ORDER BY 총매출 DESC`로 조회하세요.

**사용 테이블:** `restaurants`, `orders`

**예상 결과 (일부):**

| id | name | category | 주문수 | 총매출 | 평균주문금액 |
|:--:|---|---|:--:|---:|---:|
| 3 | 부산치킨 | 치킨 | 12 | 245000 | 20417 |
| 1 | 명동칼국수 | 한식 | 9 | 198000 | 22000 |
| ... | ... | ... | ... | ... | ... |
| 10 | 부산돈까스 | 일식 | **0** | **0** | **0** |

<details>
<summary>정답 보기</summary>

```sql
CREATE VIEW v_restaurant_stats AS
SELECT
    r.id                                   AS id,
    r.name                                 AS name,
    r.category                             AS category,
    COUNT(o.id)                            AS 주문수,
    IFNULL(SUM(o.total_price), 0)          AS 총매출,
    IFNULL(ROUND(AVG(o.total_price)), 0)   AS 평균주문금액
FROM restaurants r
    LEFT JOIN orders o ON r.id = o.restaurant_id
GROUP BY r.id, r.name, r.category;

SELECT * FROM v_restaurant_stats ORDER BY 총매출 DESC;
```

**핵심 포인트:**
- `LEFT JOIN`을 써야 주문 0건인 가게(10번)도 포함됩니다.
- `COUNT(o.id)`: o.id가 NULL이면 COUNT에서 제외되어 자동으로 0이 됩니다.
- `IFNULL(SUM(...), 0)`: SUM의 결과가 NULL이면 0으로 치환합니다.

</details>

---

## ⭐⭐ 응용 문제 (EXPLAIN 해석 · VIEW 활용 · 트랜잭션 기본)

---

### 문제 3. ⭐⭐ — EXPLAIN으로 인덱스 효과 비교하기

> 개발팀이 쿼리 성능 점검을 요청했습니다. 다음 두 단계를 순서대로 실행하고, `EXPLAIN` 결과의 차이를 비교하세요.
>
> **Step 1.** 만약 `idx_orders_customer` 인덱스가 존재하면 먼저 삭제합니다.
> ```sql
> DROP INDEX idx_orders_customer ON orders;
> ```
>
> **Step 2.** 아래 쿼리의 실행 계획을 확인합니다.
> ```sql
> EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
> ```
> `type` 컬럼의 값은 무엇인가요? 이것이 의미하는 바를 설명하세요.
>
> **Step 3.** 인덱스를 다시 생성합니다.
> ```sql
> CREATE INDEX idx_orders_customer ON orders(customer_id);
> ```
>
> **Step 4.** 같은 쿼리를 다시 `EXPLAIN`으로 확인합니다.
> ```sql
> EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
> ```
> `type` 컬럼의 값이 어떻게 바뀌었나요? `key` 컬럼에는 무엇이 나타나나요?

**예상 결과 비교:**

| 단계 | type | key | rows | 의미 |
|---|---|---|:--:|---|
| 인덱스 없을 때 | **ALL** | NULL | 50 | 테이블 전체를 다 읽음 (풀스캔) |
| 인덱스 있을 때 | **ref** | idx_orders_customer | 6 | 인덱스로 매칭 행만 읽음 |

<details>
<summary>정답 보기 & 해설</summary>

```sql
-- Step 1: 인덱스 삭제 (없으면 에러 나므로 먼저 SHOW INDEX로 확인)
SHOW INDEX FROM orders;
DROP INDEX idx_orders_customer ON orders;

-- Step 2: 인덱스 없는 상태 확인
EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
-- type=ALL, key=NULL, rows=50 (전체 행 수)

-- Step 3: 인덱스 재생성
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- Step 4: 인덱스 있는 상태 확인
EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
-- type=ref, key=idx_orders_customer, rows=6 (실제 결과 수에 가까움)
```

**해설:**

`type=ALL`은 테이블의 모든 행을 처음부터 끝까지 읽는다는 뜻입니다. 데이터가 50건이면 50번 읽고, 50만 건이면 50만 번 읽습니다. 결과가 6건이어도 나머지 44건(또는 499,994건)을 불필요하게 읽습니다.

`type=ref`는 인덱스를 통해 `customer_id=3`에 해당하는 위치를 즉시 찾고, 그 행들만 읽습니다. `key` 컬럼에 `idx_orders_customer`가 표시되어 실제로 이 인덱스를 사용했음을 알 수 있습니다.

`rows` 값이 50에서 6으로 줄어든 것은, MySQL이 읽어야 하는 행이 그만큼 줄었다는 의미입니다.

</details>

---

### 문제 4. ⭐⭐ — VIEW를 활용한 다양한 조회

> 문제 2에서 만든 `v_restaurant_stats` 뷰를 활용하여 아래 4가지 조회를 각각 작성하세요.
>
> **(1)** 치킨 카테고리 가게만 조회 (총매출 내림차순)
>
> **(2)** 주문이 한 건도 없는 가게만 조회
>
> **(3)** 총매출이 50,000원을 초과하는 가게의 이름과 총매출만 조회 (총매출 내림차순)
>
> **(4)** 카테고리별 총주문수와 카테고리총매출을 집계 (카테고리총매출 내림차순)
>
> ※ 뷰가 없다면 문제 2의 정답으로 먼저 생성하세요.

**예상 결과 (4번 집계):**

| category | 카테고리주문수 | 카테고리총매출 |
|---|:--:|---:|
| 치킨 | 18 | 355000 |
| 한식 | 15 | 290000 |
| 피자 | 12 | 243000 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
-- (1) 치킨 카테고리
SELECT *
FROM v_restaurant_stats
WHERE category = '치킨'
ORDER BY 총매출 DESC;

-- (2) 주문 0건 가게
SELECT id, name, category
FROM v_restaurant_stats
WHERE 주문수 = 0;

-- (3) 총매출 5만원 초과
SELECT name, 총매출
FROM v_restaurant_stats
WHERE 총매출 > 50000
ORDER BY 총매출 DESC;

-- (4) 카테고리별 집계 (뷰 위에서 GROUP BY)
SELECT
    category            AS 카테고리,
    SUM(주문수)          AS 카테고리주문수,
    SUM(총매출)          AS 카테고리총매출
FROM v_restaurant_stats
GROUP BY category
ORDER BY 카테고리총매출 DESC;
```

**핵심 포인트:**
- 뷰는 일반 테이블처럼 WHERE, GROUP BY, ORDER BY를 그 위에서 자유롭게 추가할 수 있습니다.
- (4)는 이미 GROUP BY로 집계된 뷰를 다시 GROUP BY하는 "2단계 집계" 예시입니다.

</details>

---

### 문제 5. ⭐⭐ — 트랜잭션 기본: COMMIT와 ROLLBACK 비교

> 트랜잭션이 어떻게 동작하는지 직접 체험해 보겠습니다. 아래 두 시나리오를 순서대로 실행하고 결과를 비교하세요.
>
> **시나리오 A — ROLLBACK:**
> 1. `START TRANSACTION`으로 트랜잭션을 시작합니다.
> 2. 1번 가게의 모든 메뉴 가격을 10% 인상하는 UPDATE를 실행합니다.
> 3. `SELECT`로 가격이 바뀐 것을 확인합니다.
> 4. `ROLLBACK`으로 취소합니다.
> 5. 다시 `SELECT`로 가격이 원래대로 돌아왔는지 확인합니다.
>
> **시나리오 B — COMMIT:**
> 1. `START TRANSACTION`으로 트랜잭션을 시작합니다.
> 2. 같은 UPDATE를 실행합니다.
> 3. `SELECT`로 확인합니다.
> 4. `COMMIT`으로 확정합니다.
> 5. 다시 `SELECT`로 인상된 가격이 유지되는지 확인합니다.
> 6. 실습 마무리 후 UPDATE로 원래 가격(÷1.1 반올림)으로 복원합니다.

**핵심 확인 포인트:** ROLLBACK 후에는 가격이 원래대로 돌아오고, COMMIT 후에는 인상된 가격이 유지되어야 합니다.

<details>
<summary>정답 보기</summary>

```sql
-- 현재 가격 확인 (기준값)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

-- ===== 시나리오 A: ROLLBACK =====
START TRANSACTION;

UPDATE menus SET price = price * 1.1 WHERE restaurant_id = 1;

-- 트랜잭션 내 확인 (인상된 가격이 보임)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

ROLLBACK;  -- 취소!

-- ROLLBACK 후 확인 (원래 가격으로 돌아옴)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;


-- ===== 시나리오 B: COMMIT =====
START TRANSACTION;

UPDATE menus SET price = price * 1.1 WHERE restaurant_id = 1;

SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

COMMIT;  -- 확정!

-- COMMIT 후 확인 (인상된 가격 유지)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

-- 실습 복원 (10% 인상 전 가격으로 되돌리기)
UPDATE menus SET price = ROUND(price / 1.1) WHERE restaurant_id = 1;
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;
```

**해설:**
- `START TRANSACTION` 이후 변경은 `COMMIT` 전까지 내 세션에서만 보입니다.
- `ROLLBACK`은 트랜잭션 시작 이전 상태로 완전히 되돌립니다.
- `COMMIT`은 변경사항을 DB에 영구 저장합니다.

</details>

---

## ⭐⭐⭐ 도전 문제 (복합 인덱스 설계 · VIEW + WHERE 조합 · 주문 트랜잭션 시나리오)

---

### 문제 6. ⭐⭐⭐ — 복합 인덱스 설계 이유 설명하기

> 분석팀이 다음 쿼리를 자주 실행한다고 합니다.
>
> ```sql
> SELECT * FROM orders
> WHERE customer_id = 3 AND order_date >= '2024-01-01';
> ```
>
> 이 경우 단순 인덱스 두 개와 복합 인덱스 중 어떤 것이 더 적합한지 설명하고, 올바른 복합 인덱스를 생성하세요.
>
> **(1)** `customer_id` 단독 인덱스만 있을 때 EXPLAIN 결과를 확인합니다.
>
> **(2)** `(customer_id, order_date)` 복합 인덱스를 생성하고 EXPLAIN 결과를 다시 확인합니다.
>
> **(3)** 복합 인덱스에서 컬럼 **순서가 왜 중요한지** 설명하세요.
> 아래 두 인덱스 중 위 쿼리에 더 적합한 것과 그 이유를 서술하세요.
>
> ```sql
> -- 선택지 A
> CREATE INDEX idx_a ON orders(customer_id, order_date);
>
> -- 선택지 B
> CREATE INDEX idx_b ON orders(order_date, customer_id);
> ```

**힌트:** 복합 인덱스는 왼쪽 컬럼부터 순서대로 사용됩니다.

<details>
<summary>정답 보기 & 해설</summary>

```sql
-- (1) customer_id 단독 인덱스만 있을 때
-- 이미 문제 1에서 생성됨
EXPLAIN SELECT * FROM orders
WHERE customer_id = 3 AND order_date >= '2024-01-01';
-- type=ref, key=idx_orders_customer (customer_id만 인덱스 사용)
-- order_date 조건은 인덱스 없이 추가 필터링 → 여전히 모든 customer_id=3 행을 읽음

-- (2) 복합 인덱스 생성
CREATE INDEX idx_orders_cust_date ON orders(customer_id, order_date);

EXPLAIN SELECT * FROM orders
WHERE customer_id = 3 AND order_date >= '2024-01-01';
-- type=range, key=idx_orders_cust_date
-- 두 조건 모두 인덱스에서 처리 → rows가 더 줄어듦

-- 사용 후 정리
DROP INDEX idx_orders_cust_date ON orders;
```

**해설 — 복합 인덱스 순서가 중요한 이유:**

복합 인덱스 `(customer_id, order_date)`는 먼저 `customer_id`로 정렬되고, 같은 `customer_id` 안에서 `order_date`로 정렬된 구조입니다.

- **A: `(customer_id, order_date)`** → 이 쿼리에 최적
  - `WHERE customer_id = 3`: 첫 번째 컬럼 조건 → 인덱스로 즉시 범위 확정
  - `AND order_date >= '2024-01-01'`: 두 번째 컬럼 조건 → 이미 좁혀진 범위에서 추가 필터
  - `WHERE customer_id = 3` 단독 쿼리에도 사용 가능

- **B: `(order_date, customer_id)`** → 이 쿼리에 비효율
  - `WHERE customer_id = 3`: 두 번째 컬럼을 단독으로 조건 → 첫 번째 컬럼 없이는 인덱스 사용 불가
  - 결과적으로 `order_date` 조건에만 인덱스가 사용되고 `customer_id` 필터는 따로 처리됨

**규칙:** "단독 조건으로 자주 쓰이는 컬럼"을 복합 인덱스의 첫 번째에 배치하세요. `customer_id`만 조건으로 쓰는 경우가 많다면 A가 적합합니다.

</details>

---

### 문제 7. ⭐⭐⭐ — VIEW + 다단계 WHERE 조합

> 고객 관리팀에서 "자주 주문하는 충성 고객"을 분석하고 싶어합니다. 아래 단계를 순서대로 수행하세요.
>
> **Step 1.** `v_active_customers` 뷰를 생성하세요.
> 포함 내용: 고객 id, name, phone, 주문수(최소 1건 이상), 총결제금액, 마지막주문일
> (INNER JOIN 사용 — 주문 0건 고객 제외)
>
> **Step 2.** 뷰를 활용하여 다음 3가지를 각각 조회하세요.
> - **(a)** 전체 활성 고객 목록 (주문수 내림차순)
> - **(b)** 주문수가 5건 이상인 VIP 고객 (총결제금액 내림차순)
> - **(c)** 마지막 주문일이 '2024-02-01' 이후인 고객 (마지막주문일 내림차순)
>
> **Step 3.** 추가 분석: `v_active_customers`를 서브쿼리에서 활용하여, 평균 주문수보다 많이 주문한 고객만 조회하세요.
> (힌트: `WHERE 주문수 > (SELECT AVG(주문수) FROM v_active_customers)`)

**예상 결과 (Step 2-b, 일부):**

| id | name | phone | 주문수 | 총결제금액 | 마지막주문일 |
|:--:|---|---|:--:|---:|---|
| 1 | 김민준 | 010-1234-5678 | 12 | 198000 | 2024-03-15 19:22:00 |
| 2 | 이서연 | 010-9876-5432 | 9 | 153000 | 2024-03-10 14:30:00 |
| ... | ... | ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
-- Step 1: v_active_customers 뷰 생성
CREATE VIEW v_active_customers AS
SELECT
    c.id                  AS id,
    c.name                AS name,
    c.phone               AS phone,
    COUNT(o.id)           AS 주문수,
    SUM(o.total_price)    AS 총결제금액,
    MAX(o.order_date)     AS 마지막주문일
FROM customers c
    JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.phone;


-- Step 2-a: 전체 활성 고객 (주문수 내림차순)
SELECT *
FROM v_active_customers
ORDER BY 주문수 DESC;

-- Step 2-b: 주문수 5건 이상 VIP
SELECT *
FROM v_active_customers
WHERE 주문수 >= 5
ORDER BY 총결제금액 DESC;

-- Step 2-c: 2024-02-01 이후 주문
SELECT *
FROM v_active_customers
WHERE 마지막주문일 >= '2024-02-01'
ORDER BY 마지막주문일 DESC;


-- Step 3: 평균 주문수보다 많이 주문한 고객
SELECT *
FROM v_active_customers
WHERE 주문수 > (SELECT AVG(주문수) FROM v_active_customers)
ORDER BY 주문수 DESC;
```

**핵심 포인트:**
- `v_active_customers`는 INNER JOIN을 사용했으므로 주문 0건 고객(9번, 10번)은 포함되지 않습니다.
- 뷰를 서브쿼리 안에서 `FROM` 뒤에 쓸 수도 있습니다.
- Step 3에서 `AVG(주문수)`는 뷰의 집계 컬럼을 다시 집계하는 2단계 집계입니다.

</details>

---

### 문제 8. ⭐⭐⭐ — 주문 처리 트랜잭션 시나리오

> 배달앱 주문 처리 과정을 트랜잭션으로 구현합니다. 세 가지 시나리오를 직접 실행하고 결과를 확인하세요.
>
> **시나리오 1 — 정상 주문 처리:**
> 고객 1번이 가게 2번의 메뉴 4번을 2개, 총 24,000원에 주문합니다. (배달비 3,000원)
> 트랜잭션 안에서 INSERT 후 결과를 확인하고 COMMIT하세요.
>
> **시나리오 2 — 유효하지 않은 고객 주문 (FK 에러):**
> 존재하지 않는 customer_id 999로 주문을 시도합니다.
> 에러 메시지를 확인하고 ROLLBACK하세요.
> ROLLBACK 후 orders 테이블이 시나리오 1 이후 상태 그대로인지 확인하세요.
>
> **시나리오 3 — SAVEPOINT 활용:**
> 아래 순서로 실행하세요.
> 1. `START TRANSACTION`
> 2. 고객 3번, 가게 3번, 메뉴 7번, 수량 1개, 15,000원 주문 INSERT
> 3. `SAVEPOINT sp_first_order` 생성
> 4. 고객 999번(존재하지 않음)으로 두 번째 주문 INSERT 시도 → 에러 발생
> 5. `ROLLBACK TO sp_first_order`로 첫 번째 주문까지만 유지
> 6. `COMMIT`
> 7. orders 테이블에 첫 번째 주문만 저장되었는지 확인

**예상 결과 (시나리오 1 후 최근 3건):**

| id | customer_id | restaurant_id | menu_id | quantity | total_price | delivery_fee |
|:--:|:--:|:--:|:--:|:--:|---:|---:|
| (기존주문) | ... | ... | ... | ... | ... | ... |
| (기존주문) | ... | ... | ... | ... | ... | ... |
| **(신규)** | 1 | 2 | 4 | 2 | 24000 | 3000 |

<details>
<summary>정답 보기</summary>

```sql
-- ===== 시나리오 1: 정상 주문 처리 =====
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (1, 2, 4, 2, 24000, NOW(), 3000);

-- 삽입 확인
SELECT * FROM orders ORDER BY id DESC LIMIT 3;

COMMIT;

-- COMMIT 후 재확인 (주문이 저장됨)
SELECT * FROM orders ORDER BY id DESC LIMIT 3;


-- ===== 시나리오 2: FK 에러 + ROLLBACK =====
-- 시나리오 1 후 상태 기억 (마지막 id 메모)
SELECT MAX(id) AS 마지막주문id FROM orders;

START TRANSACTION;

-- customer_id 999 없음 → FK 에러 발생
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (999, 1, 1, 1, 10000, NOW(), 3000);
-- ERROR 1452: Cannot add or update a child row:
-- a foreign key constraint fails

ROLLBACK;

-- ROLLBACK 후 확인 (시나리오 1의 주문이 마지막으로 유지됨)
SELECT * FROM orders ORDER BY id DESC LIMIT 3;


-- ===== 시나리오 3: SAVEPOINT 활용 =====
START TRANSACTION;

-- 첫 번째 주문 (정상)
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (3, 3, 7, 1, 15000, NOW(), 3000);

-- 저장점 생성
SAVEPOINT sp_first_order;

-- 두 번째 주문 시도 (에러 예정)
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (999, 1, 1, 1, 10000, NOW(), 3000);
-- FK 에러 발생!

-- 저장점까지만 롤백 (첫 번째 주문은 유지)
ROLLBACK TO sp_first_order;

-- 나머지 처리 완료 후 커밋
COMMIT;

-- 최종 확인 (customer_id=3의 주문만 저장됨, customer_id=999는 없음)
SELECT * FROM orders ORDER BY id DESC LIMIT 5;
```

**핵심 포인트:**
- 시나리오 2에서 FK 에러가 나면 해당 INSERT는 취소되지만, 트랜잭션 자체는 아직 살아있습니다. 명시적으로 `ROLLBACK`을 해야 합니다.
- SAVEPOINT를 사용하면 트랜잭션 전체를 취소하지 않고 특정 지점까지만 되돌릴 수 있습니다.
- 시나리오 3에서 `ROLLBACK TO sp_first_order` 후 `COMMIT`하면, 첫 번째 주문만 최종 저장됩니다.

</details>

---

## ⭐⭐⭐⭐ 보너스 문제

---

### 보너스 1. ⭐⭐⭐⭐ — 인덱스 설계 리뷰

> 신입 개발자가 `orders` 테이블 조회 성능을 높이겠다며 아래 8개의 인덱스를 모두 생성했습니다.
>
> ```sql
> CREATE INDEX idx_orders_id           ON orders(id);
> CREATE INDEX idx_orders_customer     ON orders(customer_id);
> CREATE INDEX idx_orders_restaurant   ON orders(restaurant_id);
> CREATE INDEX idx_orders_menu         ON orders(menu_id);
> CREATE INDEX idx_orders_quantity     ON orders(quantity);
> CREATE INDEX idx_orders_price        ON orders(total_price);
> CREATE INDEX idx_orders_date         ON orders(order_date);
> CREATE INDEX idx_orders_status       ON orders(status);
> ```
>
> **질문:**
> 1. `idx_orders_id`는 왜 불필요한가요?
> 2. `idx_orders_quantity`와 `idx_orders_status`는 왜 거의 효과가 없나요?
> 3. 인덱스가 너무 많으면 어떤 부작용이 있나요?
> 4. 위 8개 중 실제로 필요한 것만 골라 최적 인덱스 세트를 제안하세요.

<details>
<summary>정답 보기 & 해설</summary>

**1. idx_orders_id가 불필요한 이유:**

`id`는 PRIMARY KEY입니다. MySQL은 PK에 자동으로 인덱스를 생성합니다. 중복으로 인덱스를 만들면 저장 공간만 낭비됩니다. `SHOW INDEX FROM orders`를 실행하면 Key_name=PRIMARY로 이미 인덱스가 있음을 확인할 수 있습니다.

**2. quantity와 status 인덱스가 거의 효과 없는 이유:**

인덱스는 **선택도(Selectivity)**가 높을수록 효과적입니다. 선택도란 "전체 데이터 중 조건으로 걸러지는 비율"입니다.

- `quantity`: 1~5 정도의 값만 존재하는 경우, `WHERE quantity = 2` 조건으로도 전체의 20~40%를 읽어야 합니다. 이 경우 MySQL 옵티마이저는 인덱스보다 풀스캔이 낫다고 판단할 수 있습니다.
- `status`: '배달완료', '취소', '배달중' 등 3~4개 값만 있으면 각 값이 전체의 25~33%를 차지합니다. 역시 선택도가 낮아 인덱스 효과가 미미합니다.

**3. 인덱스가 너무 많으면 생기는 부작용:**

| 부작용 | 설명 |
|---|---|
| INSERT/UPDATE/DELETE 느려짐 | 데이터 변경 시 모든 인덱스를 함께 수정해야 함 |
| 저장 공간 증가 | 인덱스 자체도 디스크 공간을 차지함 |
| 쿼리 계획 오판 가능성 | 인덱스가 너무 많으면 옵티마이저가 최적 인덱스를 고르기 어려워짐 |
| 유지보수 복잡성 증가 | 어떤 인덱스가 실제로 쓰이는지 파악하기 어려워짐 |

**4. 최적 인덱스 세트 제안:**

```sql
-- 실제로 필요한 인덱스 (3~4개가 적당)
CREATE INDEX idx_orders_customer   ON orders(customer_id);    -- WHERE/JOIN에 자주 사용
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);  -- JOIN에 필수
CREATE INDEX idx_orders_date       ON orders(order_date);     -- 날짜 범위 조회/정렬

-- 상황에 따라 추가 검토
-- CREATE INDEX idx_orders_menu ON orders(menu_id);           -- JOIN에 사용되지만 빈도 확인 필요
-- CREATE INDEX idx_orders_cust_date ON orders(customer_id, order_date); -- 두 조건 자주 함께 쓸 때

-- 불필요 또는 효과 없음 → 생성하지 않음
-- idx_orders_id       : PK 자동 인덱스 존재
-- idx_orders_quantity : 선택도 낮음
-- idx_orders_status   : 선택도 낮음 (값이 3~4개)
-- idx_orders_price    : WHERE total_price = ? 같은 조회는 드묾
```

**결론:** 인덱스는 "많을수록 좋다"가 아니라 "꼭 필요한 것만"이 원칙입니다. 일반적으로 테이블당 3~5개 이하를 유지하는 것이 좋습니다.

</details>

---

### 보너스 2. ⭐⭐⭐⭐ — SAVEPOINT를 활용한 배치 주문 처리

> 배달앱에서 "묶음 주문" 기능을 구현합니다. 고객 2번이 가게 3번에서 메뉴 3개를 한꺼번에 주문하는 상황입니다.
>
> 아래 요구사항을 트랜잭션과 SAVEPOINT를 활용하여 구현하세요.
>
> **요구사항:**
> - 첫 번째 메뉴(menu_id=7, 15,000원) 삽입 후 `SAVEPOINT sp1` 생성
> - 두 번째 메뉴(menu_id=8, 12,000원) 삽입 후 `SAVEPOINT sp2` 생성
> - 세 번째 메뉴(menu_id=99, 잘못된 ID) 삽입 시도 → 에러 발생
> - `ROLLBACK TO sp2`로 두 번째 메뉴까지만 유지
> - 올바른 세 번째 메뉴(menu_id=9, 9,000원)를 다시 삽입
> - `COMMIT`으로 확정
>
> 최종적으로 3건의 주문이 저장되어야 합니다. (menu_id: 7, 8, 9)

<details>
<summary>정답 보기</summary>

```sql
START TRANSACTION;

-- 첫 번째 주문
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (2, 3, 7, 1, 15000, NOW(), 3000);

SAVEPOINT sp1;  -- 첫 번째 주문 후 저장점

SELECT * FROM orders ORDER BY id DESC LIMIT 5;  -- 확인

-- 두 번째 주문
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (2, 3, 8, 1, 12000, NOW(), 0);  -- 묶음 주문이므로 두 번째부터 배달비 0

SAVEPOINT sp2;  -- 두 번째 주문 후 저장점

SELECT * FROM orders ORDER BY id DESC LIMIT 5;  -- 확인

-- 세 번째 주문 시도 (menu_id=99 없음 → FK 에러)
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (2, 3, 99, 1, 9000, NOW(), 0);
-- ERROR 1452: Foreign key constraint fails

-- 잘못된 세 번째 주문만 취소 (sp2까지 롤백 → sp1 이후 두 번째 주문은 유지)
ROLLBACK TO sp2;

-- 올바른 세 번째 주문 다시 삽입
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (2, 3, 9, 1, 9000, NOW(), 0);

SELECT * FROM orders ORDER BY id DESC LIMIT 5;  -- 최종 확인 (3건이어야 함)

COMMIT;

-- COMMIT 후 최종 확인
SELECT id, customer_id, restaurant_id, menu_id, total_price
FROM orders ORDER BY id DESC LIMIT 5;
```

**해설:**

SAVEPOINT는 트랜잭션을 "전부 취소"하지 않고 "중간 지점까지만 취소"할 때 유용합니다.

```
트랜잭션 흐름:
START TRANSACTION
  → INSERT menu_id=7 ✅
  → SAVEPOINT sp1
  → INSERT menu_id=8 ✅
  → SAVEPOINT sp2
  → INSERT menu_id=99 ❌ (에러)
  → ROLLBACK TO sp2  (menu_id=99 삽입만 취소, 7과 8은 유지)
  → INSERT menu_id=9 ✅
  → COMMIT  (7, 8, 9 모두 저장됨)
```

실무에서는 배치 처리나 여러 단계가 있는 복잡한 업무 처리에서 SAVEPOINT가 유용하게 쓰입니다.

</details>

---

## 셀프 체크리스트

오늘 실습을 마친 후 아래 항목을 체크해 보세요.

- [ ] `CREATE INDEX`로 인덱스를 생성하고 `SHOW INDEX`로 확인할 수 있다
- [ ] `EXPLAIN`의 `type` 컬럼에서 `ALL`과 `ref`의 차이를 설명할 수 있다
- [ ] 인덱스가 효과 있는 경우와 없는 경우를 구분할 수 있다
- [ ] `CREATE VIEW ... AS SELECT ...`로 뷰를 생성할 수 있다
- [ ] 생성된 뷰에 `WHERE`, `GROUP BY`, `ORDER BY`를 추가하여 조회할 수 있다
- [ ] `START TRANSACTION`, `COMMIT`, `ROLLBACK`의 역할을 설명할 수 있다
- [ ] AUTO COMMIT이 무엇인지 설명할 수 있다
- [ ] `SAVEPOINT`와 `ROLLBACK TO`를 활용하여 부분 롤백을 구현할 수 있다

---

> **한입배달 MySQL 10일 완성 | Day 8 실습 문제 | 한국IT교육센터 부산점**
