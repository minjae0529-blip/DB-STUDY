# Day 8 핸드아웃 — 성능과 안전: 인덱스, 뷰, 트랜잭션

> 한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점

---

## 목차

1. [오늘의 3가지 불편함 해결](#1-오늘의-3가지-불편함-해결)
2. [인덱스 — 책의 목차](#2-인덱스--책의-목차)
   - 2-1. 인덱스란 무엇인가
   - 2-2. EXPLAIN으로 풀스캔 vs 인덱스 스캔 비교
   - 2-3. CREATE INDEX 문법
   - 2-4. EXPLAIN 결과 읽는 법
   - 2-5. 인덱스 설계 가이드
   - 2-6. 과유불급: 인덱스가 너무 많으면
   - 2-7. 복합 인덱스
3. [뷰 — 즐겨찾기](#3-뷰--즐겨찾기)
   - 3-1. 뷰란 무엇인가
   - 3-2. CREATE VIEW 문법
   - 3-3. 뷰 위에서 추가 WHERE / GROUP BY
   - 3-4. 보안 용도로 활용하기
   - 3-5. VIEW vs 서브쿼리
   - 3-6. 주의사항
4. [트랜잭션 — 올 오어 낫씽](#4-트랜잭션--올-오어-낫씽)
   - 4-1. 트랜잭션이란 무엇인가
   - 4-2. ACID 4가지 성질
   - 4-3. START TRANSACTION / COMMIT / ROLLBACK
   - 4-4. AUTO COMMIT 이해하기
   - 4-5. SAVEPOINT / ROLLBACK TO
   - 4-6. 주문 처리 실전 예제
5. [자주 발생하는 에러 3가지](#5-자주-발생하는-에러-3가지)
6. [오늘 배운 것 정리 — 키워드 요약표](#6-오늘-배운-것-정리--키워드-요약표)
7. [Day 9 예고](#7-day-9-예고)

---

## 1. 오늘의 3가지 불편함 해결

Day 7까지 우리는 꽤 복잡한 쿼리를 작성할 수 있게 됐습니다. JOIN으로 여러 테이블을 연결하고, 서브쿼리로 중간 결과를 활용했습니다. 그런데 실제로 이 쿼리들을 운영 환경에서 쓰다 보면 새로운 불편함이 세 가지 생깁니다.

**불편함 1 — 쿼리가 느려요.**

처음에는 빠르던 쿼리가 데이터가 쌓이면서 점점 느려집니다. 50건일 때는 즉각 응답하던 쿼리가, 50만 건이 되면 몇 초씩 기다려야 합니다. 이 문제의 해결책이 **인덱스**입니다.

**불편함 2 — 복잡한 쿼리를 매번 다시 쓰기 귀찮아요.**

Day 6에서 배운 JOIN + GROUP BY 조합은 10줄이 넘어갑니다. 이 쿼리를 사용할 때마다 처음부터 다시 쓰거나, 어딘가에 복사해 둬야 합니다. 이 문제의 해결책이 **뷰(VIEW)**입니다.

**불편함 3 — 주문 처리 도중 에러가 나면 어떡하죠?**

주문을 처리하는 과정에서 여러 SQL이 실행됩니다. 그 중간에 에러가 나면 일부 작업만 적용된 채로 남아 데이터가 엉망이 될 수 있습니다. 이 문제의 해결책이 **트랜잭션(TRANSACTION)**입니다.

오늘 수업에서 이 세 가지를 하나씩 해결합니다.

---

## 2. 인덱스 — 책의 목차

### 2-1. 인덱스란 무엇인가

> **비유:** 500페이지짜리 책에서 "김민준"이라는 이름을 찾는 두 가지 방법을 생각해 보세요.
>
> - **목차 없이:** 1페이지부터 500페이지까지 한 장 한 장 전부 뒤집습니다.
> - **목차 있으면:** 목차에서 'ㄱ' 항목을 찾아 해당 페이지로 바로 이동합니다.

MySQL에서도 똑같은 일이 벌어집니다. `orders` 테이블에 50만 건의 주문이 있을 때, `customer_id = 3`인 주문을 찾으려면:

- **인덱스 없음:** 50만 건을 처음부터 끝까지 전부 읽음 → **풀스캔(Full Scan)**
- **인덱스 있음:** 인덱스에서 customer_id=3의 위치를 즉시 찾아서 해당 행만 읽음 → **인덱스 스캔**

데이터가 적을 때는 차이가 없지만, 데이터가 수십만 건이 넘어가면 속도 차이가 수십 배에서 수백 배까지 벌어집니다.

**인덱스의 구조를 간단히 이해하면:**

MySQL 인덱스는 내부적으로 B-Tree(균형 이진 탐색 트리) 구조로 저장됩니다. 우리가 직접 구조를 외울 필요는 없지만, "정렬된 목차처럼 빠르게 찾는다"는 개념만 기억하면 됩니다.

```
인덱스 없이 조회:
orders 테이블 전체 (50만 행)
┌──────┬─────────────┬─────────────────┐
│  id  │ customer_id │ total_price ... │  ← 1번 행 확인: customer_id가 3인가?
├──────┼─────────────┼─────────────────┤
│  1   │      1      │   18000 ...     │  → 아니오
├──────┼─────────────┼─────────────────┤
│  2   │      4      │   12000 ...     │  → 아니오
├──────┼─────────────┼─────────────────┤
│  3   │      3      │   37000 ...     │  → 예! 포함
├──────┼─────────────┼─────────────────┤
│ ...  │     ...     │    ...          │  → 계속 50만 행 반복...
```

```
인덱스 사용:
customer_id 인덱스 (B-Tree)
┌─────────────┬────────────────┐
│ customer_id │ 해당 행의 위치  │
├─────────────┼────────────────┤
│      1      │  1번, 3번, ... │
│      2      │  2번, 7번, ... │
│      3      │  5번, 9번, ... │  ← customer_id=3 즉시 발견!
│      4      │  4번, 8번, ... │
│     ...     │      ...       │
└─────────────┴────────────────┘
→ customer_id=3인 행의 위치를 즉시 알고, 그 행들만 읽음
```

### 2-2. EXPLAIN으로 풀스캔 vs 인덱스 스캔 비교

MySQL은 쿼리를 **실행하기 전에** 어떤 방식으로 처리할지 계획을 세웁니다. `EXPLAIN` 키워드로 그 계획을 미리 볼 수 있습니다.

**인덱스 생성 전 — 풀스캔:**

```sql
-- 인덱스가 없는 상태에서 실행 계획 확인
EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
```

결과:

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | Extra |
|:--:|---|---|---|---|---|---|---|:--:|---|
| 1 | SIMPLE | orders | **ALL** | NULL | NULL | NULL | NULL | **50** | Using where |

- `type = ALL`: 테이블 전체를 스캔 → 풀스캔
- `key = NULL`: 사용된 인덱스 없음
- `rows = 50`: 50행을 모두 읽음 (결과가 6건이어도!)

**인덱스 생성 후 — 인덱스 스캔:**

```sql
-- 인덱스 생성
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- 같은 쿼리 다시 실행
EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
```

결과:

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | Extra |
|:--:|---|---|---|---|---|---|---|:--:|---|
| 1 | SIMPLE | orders | **ref** | idx_orders_customer | **idx_orders_customer** | 5 | const | **6** | NULL |

- `type = ref`: 인덱스를 통해 일치하는 행만 읽음
- `key = idx_orders_customer`: 실제로 이 인덱스를 사용함
- `rows = 6`: 실제 결과에 가까운 건수만 읽음

50건에서 6건으로 줄어든 것처럼 보이지만, 실제 운영 환경에서 50만 건이라면 50만 번 → 6번으로 줄어드는 효과입니다.

### 2-3. CREATE INDEX 문법

```sql
-- 기본 문법
CREATE INDEX 인덱스명 ON 테이블명(컬럼명);

-- 예시
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_date       ON orders(order_date);

-- 인덱스 목록 확인
SHOW INDEX FROM orders;

-- 인덱스 삭제
DROP INDEX idx_orders_customer ON orders;
```

인덱스 이름은 자유롭게 지을 수 있습니다. 팀 내에서 규칙을 정해 두면 좋습니다. 일반적으로 `idx_테이블명_컬럼명` 형태를 많이 사용합니다.

**SHOW INDEX 결과 읽는 법:**

| 컬럼 | 의미 |
|---|---|
| Key_name | 인덱스 이름 (PRIMARY는 기본 키) |
| Column_name | 인덱스가 걸린 컬럼명 |
| Non_unique | 0이면 UNIQUE 인덱스, 1이면 일반 인덱스 |
| Seq_in_index | 복합 인덱스에서 컬럼 순서 |

참고로 PRIMARY KEY를 지정하면 MySQL이 자동으로 인덱스를 만들어 줍니다. `SHOW INDEX` 결과에서 Key_name=PRIMARY인 항목이 그것입니다.

### 2-4. EXPLAIN 결과 읽는 법

`EXPLAIN`의 결과에서 가장 중요한 컬럼은 `type`과 `rows`입니다.

**type 컬럼 — 성능 순서 (왼쪽이 가장 빠름):**

```
const > eq_ref > ref > range > index > ALL
  ↑                                     ↑
가장 빠름                             가장 느림
```

| type | 의미 | 예시 상황 |
|---|---|---|
| `const` | PK나 UNIQUE 컬럼으로 단 1건 조회 | `WHERE id = 5` |
| `eq_ref` | JOIN 시 PK/UNIQUE 컬럼으로 정확히 매칭 | JOIN + PK 조건 |
| `ref` | 인덱스로 여러 행 매칭 | `WHERE customer_id = 3` |
| `range` | 인덱스 범위 스캔 | `WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31'` |
| `index` | 인덱스 전체 스캔 (ALL보다는 낫지만 비효율) | ORDER BY에 인덱스 사용 |
| `ALL` | 테이블 전체 스캔 (풀스캔) | 인덱스 없는 컬럼 조건 |

**실무 기준:** `ALL`이나 `index`가 나오면 인덱스 추가를 검토합니다. `ref`, `range`, `const`가 나오면 인덱스가 잘 사용되고 있는 것입니다.

**rows 컬럼:** MySQL이 예상하는 읽어야 할 행 수입니다. 실제 결과 행 수에 비해 이 값이 훨씬 크다면 인덱스가 없거나 비효율적으로 사용되고 있다는 신호입니다.

### 2-5. 인덱스 설계 가이드

인덱스를 어디에 걸어야 할지 판단하는 기준입니다.

**인덱스를 걸면 효과적인 경우:**

| 상황 | 이유 | 예시 |
|---|---|---|
| `WHERE`절에 자주 사용되는 컬럼 | 조건 검색 속도 향상 | `customer_id`, `status`, `order_date` |
| `JOIN`의 `ON` 조건에 사용되는 컬럼 | JOIN 매칭 속도 향상 | FK 컬럼들 (restaurant_id, menu_id 등) |
| `ORDER BY`에 자주 사용되는 컬럼 | 정렬 처리 속도 향상 | `order_date`, `total_price` |
| `GROUP BY`에 자주 사용되는 컬럼 | 집계 처리 속도 향상 | `customer_id`, `restaurant_id` |

**한입배달 DB에 적용하면:**

```sql
-- orders 테이블: WHERE/JOIN에 자주 쓰이는 FK 컬럼들
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_date       ON orders(order_date);

-- menus 테이블: restaurant_id로 가게별 메뉴 조회 자주 함
CREATE INDEX idx_menus_restaurant ON menus(restaurant_id);
```

### 2-6. 과유불급: 인덱스가 너무 많으면

> **비유:** 책에 목차가 50개라면 오히려 책이 더 두꺼워지고, 목차 찾는 데도 시간이 걸립니다.

인덱스는 SELECT를 빠르게 만들지만 반대로 INSERT, UPDATE, DELETE를 느리게 만듭니다. 이유는 데이터를 변경할 때마다 인덱스도 함께 수정해야 하기 때문입니다.

```
데이터 삽입 시 처리 과정:
데이터 없는 경우: orders 테이블에 1행 추가
데이터 있는 경우: orders 테이블에 1행 추가
                  + idx_orders_customer 인덱스 갱신
                  + idx_orders_restaurant 인덱스 갱신
                  + idx_orders_date 인덱스 갱신
                  + idx_orders_menu 인덱스 갱신
                  ...
```

**인덱스가 거의 효과 없는 경우:**

| 상황 | 이유 |
|---|---|
| 컬럼 값의 종류가 너무 적을 때 | 예: `status`가 '완료'/'취소' 2가지뿐이면 어차피 절반을 스캔 |
| 데이터 건수가 매우 적을 때 | 수백 건 이하는 풀스캔도 빠름 |
| `LIKE '%키워드%'` 앞에 % | 인덱스는 앞에서부터 찾으므로 앞에 %가 붙으면 효과 없음 |
| 인덱스 컬럼에 함수를 씌울 때 | `WHERE YEAR(order_date) = 2024` → 인덱스 사용 불가 |

**LIKE와 인덱스 주의사항:**

```sql
-- 인덱스 사용 가능 (앞에 고정값)
WHERE menu_name LIKE '후라이드%'   -- '후라이드'로 시작하는 것

-- 인덱스 사용 불가 (앞에 %)
WHERE menu_name LIKE '%치킨'       -- 어떤 글자든 앞에 올 수 있음
WHERE menu_name LIKE '%치킨%'      -- 앞뒤 모두 열려 있음
```

### 2-7. 복합 인덱스 (두 컬럼을 묶어 하나의 인덱스로)

두 가지 조건을 자주 함께 사용할 때, 두 컬럼을 묶은 복합 인덱스가 더 효율적입니다.

```sql
-- customer_id와 order_date를 함께 쓰는 쿼리가 많을 때
SELECT * FROM orders
WHERE customer_id = 3 AND order_date >= '2024-01-01';

-- 복합 인덱스 생성 (순서 중요!)
CREATE INDEX idx_orders_cust_date ON orders(customer_id, order_date);
```

**복합 인덱스의 순서는 중요합니다.**

복합 인덱스 `(customer_id, order_date)`는 아래 경우에 사용됩니다.
- `WHERE customer_id = 3` → 사용 가능 (첫 번째 컬럼만 조건)
- `WHERE customer_id = 3 AND order_date >= '2024-01-01'` → 사용 가능 (두 컬럼 모두)
- `WHERE order_date >= '2024-01-01'` → **사용 불가** (두 번째 컬럼만 단독으로는 안 됨)

> **규칙:** 복합 인덱스는 왼쪽 컬럼부터 순서대로 사용해야 합니다. 가장 자주 단독으로 쓰이는 컬럼을 첫 번째에 배치하세요.

---

## 3. 뷰 — 즐겨찾기

### 3-1. 뷰란 무엇인가

> **비유:** 자주 방문하는 웹사이트를 즐겨찾기에 등록해 두면, 매번 주소를 직접 입력하지 않고도 바로 접속할 수 있습니다. 뷰는 복잡한 SELECT 쿼리에 이름을 붙여 저장한 즐겨찾기입니다.

뷰는 **저장된 SELECT 쿼리**입니다. 실제 데이터를 저장하는 테이블과는 다르게, 뷰에는 쿼리 자체가 저장됩니다. 뷰를 조회할 때마다 그 쿼리가 실행되어 최신 데이터를 보여줍니다.

**뷰가 없을 때의 불편함:**

```sql
-- Day 6에서 배운 가게별 통계 쿼리 — 매번 이걸 전부 쳐야 합니다
SELECT
    r.id, r.name, r.category,
    COUNT(o.id)                            AS 주문수,
    IFNULL(SUM(o.total_price), 0)          AS 총매출,
    IFNULL(ROUND(AVG(o.total_price)), 0)   AS 평균주문금액
FROM restaurants r
    LEFT JOIN orders o ON r.id = o.restaurant_id
GROUP BY r.id, r.name, r.category;
-- 이 쿼리를 "치킨 카테고리만", "총매출 상위", "주문 0건인 가게만" 등으로
-- 변형할 때마다 6줄을 전부 다시 써야 합니다.
```

**뷰를 만들면:**

```sql
-- 한 번만 정의
CREATE VIEW v_restaurant_stats AS
SELECT
    r.id, r.name, r.category,
    COUNT(o.id) AS 주문수, ...
FROM restaurants r LEFT JOIN orders o ON r.id = o.restaurant_id
GROUP BY r.id, r.name, r.category;

-- 이후에는 이렇게만 쓰면 됩니다
SELECT * FROM v_restaurant_stats WHERE category = '치킨';
SELECT * FROM v_restaurant_stats ORDER BY 총매출 DESC;
SELECT * FROM v_restaurant_stats WHERE 주문수 = 0;
```

### 3-2. CREATE VIEW 문법

```sql
-- 기본 문법
CREATE VIEW 뷰이름 AS
SELECT 문;

-- 예시: 가게별 통계 뷰
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
```

**뷰 관련 명령어 정리:**

```sql
-- 뷰 목록 확인
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 뷰 정의 확인 (어떤 쿼리로 만들어졌는지)
SHOW CREATE VIEW v_restaurant_stats;

-- 뷰 삭제
DROP VIEW IF EXISTS v_restaurant_stats;

-- 뷰 수정 (기존 뷰를 새로운 쿼리로 교체)
CREATE OR REPLACE VIEW v_restaurant_stats AS
SELECT ...;  -- 새로운 쿼리
```

### 3-3. 뷰 위에서 추가 WHERE / GROUP BY

뷰는 완전히 일반 테이블처럼 사용할 수 있습니다. 뷰를 `FROM` 절에 쓰고, 그 위에 `WHERE`, `GROUP BY`, `ORDER BY`, `LIMIT`을 추가할 수 있습니다.

```sql
-- 기본 전체 조회
SELECT * FROM v_restaurant_stats;

-- WHERE 조건 추가 (치킨 카테고리만)
SELECT * FROM v_restaurant_stats
WHERE category = '치킨';

-- ORDER BY 추가 (총매출 내림차순)
SELECT * FROM v_restaurant_stats
ORDER BY 총매출 DESC;

-- 복합 조건 (총매출 5만원 초과인 가게 이름과 매출만)
SELECT name, 총매출
FROM v_restaurant_stats
WHERE 총매출 > 50000
ORDER BY 총매출 DESC;

-- 뷰 위에서 GROUP BY도 가능 (카테고리별 합산)
SELECT
    category,
    SUM(총매출) AS 카테고리총매출,
    SUM(주문수) AS 카테고리주문수
FROM v_restaurant_stats
GROUP BY category
ORDER BY 카테고리총매출 DESC;
```

이처럼 뷰를 베이스로 두고 그 위에서 다양한 조건을 붙여 쓸 수 있어 코드 재사용성이 크게 높아집니다.

### 3-4. 보안 용도로 활용하기

뷰는 특정 컬럼을 숨기는 용도로도 활용됩니다. 예를 들어 고객 정보를 외부 직원에게 공유할 때 전화번호나 이메일은 제외하고 싶을 수 있습니다.

```sql
-- 전체 고객 정보 테이블 (전화번호, 이메일 포함)
-- SELECT * FROM customers;  ← 민감 정보 노출

-- 이름과 가입일만 보이는 뷰 (민감 정보 제외)
CREATE VIEW v_customers_public AS
SELECT id, name, joined_at
FROM customers;

-- 이 뷰만 접근 권한 부여 → 전화번호 등은 보이지 않음
SELECT * FROM v_customers_public;
```

실무에서는 이런 방식으로 뷰를 만들어 두고, 외부 팀이나 협력사에는 원본 테이블 대신 뷰에만 접근 권한을 부여합니다.

### 3-5. VIEW vs 서브쿼리

Day 7에서 배운 서브쿼리와 뷰는 비슷하게 느껴질 수 있습니다. 차이점을 정리합니다.

| 비교 항목 | VIEW | FROM절 서브쿼리 |
|---|---|---|
| **저장 여부** | DB에 저장됨 (이름 있음) | 쿼리 실행 시에만 존재 |
| **재사용성** | 여러 쿼리에서 반복 사용 가능 | 해당 쿼리 안에서만 사용 |
| **유지보수** | 한 곳에서 수정하면 모두 반영 | 쿼리마다 각각 수정 필요 |
| **가독성** | 이름으로 의도를 파악하기 쉬움 | 길어지면 읽기 어려움 |
| **적합한 경우** | 자주 반복되는 복잡한 쿼리 | 일회성 복잡한 중간 단계 |

```sql
-- 서브쿼리 방식 (매번 전체를 써야 함)
SELECT name, 총매출
FROM (
    SELECT r.name, IFNULL(SUM(o.total_price), 0) AS 총매출
    FROM restaurants r LEFT JOIN orders o ON r.id = o.restaurant_id
    GROUP BY r.id, r.name
) AS stats
WHERE 총매출 > 50000;

-- 뷰 방식 (한번 만들어 두면 간단하게)
SELECT name, 총매출
FROM v_restaurant_stats
WHERE 총매출 > 50000;
```

### 3-6. 주의사항

**뷰는 저장된 데이터가 아니라 저장된 쿼리입니다.**

뷰를 조회할 때마다 원본 쿼리가 실행됩니다. 따라서:
- 조회할 때마다 최신 데이터가 반영됩니다 (실시간)
- 매우 복잡한 뷰는 조회할 때마다 무거운 쿼리가 실행되어 성능 저하 가능
- 단순히 "저장해 두면 빨라진다"고 오해하지 마세요 (빠른 건 인덱스의 역할)

**대부분의 뷰는 수정(INSERT/UPDATE)이 제한됩니다.**

GROUP BY, DISTINCT, 집계함수가 포함된 뷰는 수정이 불가능합니다. 뷰는 주로 읽기(SELECT) 전용으로 사용한다고 생각하면 됩니다.

---

## 4. 트랜잭션 — 올 오어 낫씽

### 4-1. 트랜잭션이란 무엇인가

> **비유:** 은행에서 A 계좌에서 B 계좌로 10만 원을 이체하는 과정을 생각해 봅시다.
>
> 1. A 계좌 잔액 -10만 원
> 2. B 계좌 잔액 +10만 원
>
> 만약 1번은 처리됐는데 2번에서 시스템 에러가 났다면? A 계좌에서 돈은 빠져나갔는데 B 계좌에는 입금이 안 된 상태가 됩니다. 이런 일이 절대 일어나서는 안 됩니다.
>
> **트랜잭션은 이 두 작업을 하나의 단위로 묶어, "둘 다 성공하거나, 둘 다 취소하거나"를 보장합니다.**

배달앱에서도 같은 상황이 생깁니다.

```
주문 처리 과정:
1. orders 테이블에 새 주문 INSERT
2. 결제 정보 업데이트
3. 재고(또는 가용 수량) 차감
```

이 중 1번만 되고 2번에서 에러가 나면? 주문은 들어왔는데 결제가 안 된 상태가 됩니다. 트랜잭션으로 세 작업을 묶으면, 하나라도 실패하면 전체가 취소됩니다.

### 4-2. ACID 4가지 성질

트랜잭션이 반드시 지켜야 하는 4가지 성질입니다. 각각 비유와 함께 이해합시다.

**A — Atomicity (원자성)**

> **비유: 코스요리**
> 코스요리를 주문하면 애피타이저, 메인, 디저트가 세트로 나옵니다. 메인 요리가 준비 안 됐다고 애피타이저만 가져오지는 않습니다. 전부 나오거나, 전부 취소됩니다.

트랜잭션 내의 여러 작업은 "전부 성공" 또는 "전부 취소" 둘 중 하나입니다. 일부만 적용되는 상황은 없습니다.

**C — Consistency (일관성)**

> **비유: 메뉴판**
> 메뉴판에 "치킨 18,000원"이라고 적혀 있으면, 주문서에도 18,000원이어야 합니다. 주문 처리 전후로 데이터가 서로 일치해야 합니다.

트랜잭션 실행 전후로 DB의 데이터 무결성 규칙(제약조건 등)이 일관되게 유지되어야 합니다.

**I — Isolation (격리성)**

> **비유: 옆 테이블**
> 내가 주문하는 도중에 옆 테이블 손님이 같은 음식을 주문해도 서로 영향을 주지 않습니다. 각자의 주문은 독립적으로 처리됩니다.

동시에 여러 트랜잭션이 실행돼도 서로 간섭하지 않습니다. 내 트랜잭션이 처리되는 중간 상태를 다른 사람이 볼 수 없습니다.

**D — Durability (지속성)**

> **비유: 영수증**
> 결제가 완료되고 영수증이 출력되면, 이후 서버가 재시작되거나 장애가 나도 그 결제 내역은 지워지지 않습니다.

COMMIT이 완료된 데이터는 장애가 발생해도 유지됩니다. 디스크에 영구적으로 기록됩니다.

### 4-3. START TRANSACTION / COMMIT / ROLLBACK

```sql
-- 기본 구조
START TRANSACTION;  -- 트랜잭션 시작 (AUTO COMMIT 일시 중단)

-- 여러 SQL 실행 (INSERT, UPDATE, DELETE)
INSERT INTO ...;
UPDATE ...;
DELETE FROM ...;

-- 중간 확인 (SELECT는 자유롭게)
SELECT * FROM ...;

-- 최종 결정
COMMIT;    -- 모든 변경사항을 DB에 영구 저장
-- 또는
ROLLBACK;  -- 모든 변경사항을 START TRANSACTION 이전으로 취소
```

**가격 인상 후 취소 예시:**

```sql
-- 실험: 1번 가게 메뉴 10% 인상 후 롤백
START TRANSACTION;

UPDATE menus SET price = price * 1.1 WHERE restaurant_id = 1;

-- 트랜잭션 내에서 확인 (인상된 가격이 보임)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;

-- "역시 인상하면 안 되겠다" → 취소
ROLLBACK;

-- 롤백 후 확인 (원래 가격으로 돌아옴)
SELECT id, menu_name, price FROM menus WHERE restaurant_id = 1;
```

**중요한 점:** `START TRANSACTION`을 시작한 이후의 변경은 `COMMIT`하기 전까지는 **본인의 세션에만 보입니다**. 다른 사용자 세션에서는 보이지 않습니다. `COMMIT`해야 비로소 다른 사람들에게도 보입니다.

### 4-4. AUTO COMMIT 이해하기

MySQL은 기본적으로 **AUTO COMMIT** 모드로 동작합니다. 이는 `START TRANSACTION` 없이 실행한 SQL 문장이 즉시 COMMIT된다는 의미입니다.

```sql
-- AUTO COMMIT 확인
SHOW VARIABLES LIKE 'autocommit';
-- Value = ON (기본값)

-- AUTO COMMIT이 ON인 상태에서:
UPDATE menus SET price = 19000 WHERE id = 1;
-- → 이 순간 즉시 COMMIT됨. ROLLBACK 불가!

-- START TRANSACTION을 쓰면 AUTO COMMIT을 일시적으로 중단
START TRANSACTION;
UPDATE menus SET price = 19000 WHERE id = 1;
-- → 아직 COMMIT되지 않음, ROLLBACK 가능
COMMIT;  -- 이제 확정
```

**자주 있는 실수:**

```sql
-- ❌ 실수: START TRANSACTION 없이 UPDATE 실행
UPDATE orders SET status = '취소' WHERE customer_id = 3;
-- → 즉시 COMMIT. 되돌릴 방법 없음!

-- ✅ 올바른 방법: 중요한 변경은 항상 트랜잭션으로 감싸기
START TRANSACTION;
UPDATE orders SET status = '취소' WHERE customer_id = 3;
SELECT * FROM orders WHERE customer_id = 3;  -- 확인
COMMIT;  -- 이상 없을 때만 확정
```

### 4-5. SAVEPOINT / ROLLBACK TO

트랜잭션 안에서 중간 저장점을 만들어 둘 수 있습니다. 이후 작업에 문제가 생기면 처음부터가 아니라 저장점까지만 롤백할 수 있습니다.

> **비유:** 게임의 세이브포인트. 보스 직전에 저장해 두면, 죽었을 때 처음 스테이지부터가 아니라 보스 직전부터 다시 시작할 수 있습니다.

```sql
START TRANSACTION;

-- 첫 번째 주문 삽입 (성공)
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (2, 2, 4, 1, 12000, NOW(), 3000);

-- 저장점 생성 (여기까지는 안전)
SAVEPOINT order_inserted;

-- 두 번째 작업 시도
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (999, 2, 4, 1, 12000, NOW(), 3000);  -- customer_id 999 없음 → 에러 예상

-- 에러가 났다면: 저장점까지만 롤백 (첫 번째 주문은 유지)
ROLLBACK TO order_inserted;

-- 이후 처리를 완료하고 커밋
COMMIT;
```

**SAVEPOINT 관련 명령어:**

```sql
SAVEPOINT 저장점이름;            -- 저장점 생성
ROLLBACK TO 저장점이름;          -- 저장점까지만 롤백 (트랜잭션은 유지)
RELEASE SAVEPOINT 저장점이름;   -- 저장점 삭제
```

### 4-6. 주문 처리 실전 예제

실제 배달앱에서 주문이 접수될 때 어떻게 트랜잭션을 활용하는지 예제로 살펴봅니다.

**시나리오: 고객 1번이 가게 1번의 메뉴 1번을 2개 주문**

```sql
START TRANSACTION;

-- 1. 주문 INSERT
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (1, 1, 1, 2, 20000, NOW(), 3000);

-- 2. 삽입 결과 확인 (id가 AUTO_INCREMENT로 생성됨)
SELECT * FROM orders ORDER BY id DESC LIMIT 3;

-- 3. 이상 없으면 COMMIT
COMMIT;
```

**시나리오: 존재하지 않는 고객으로 주문 시도 → ROLLBACK**

```sql
START TRANSACTION;

-- customer_id 999는 존재하지 않음 → FK 에러 발생 예정
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, total_price, order_date, delivery_fee)
VALUES (999, 1, 1, 1, 10000, NOW(), 3000);
-- ERROR 1452: Cannot add or update a child row:
-- a foreign key constraint fails

-- FK 에러가 났으므로 전체 취소
ROLLBACK;

-- ROLLBACK 후 확인 (마지막 주문이 이전 상태 그대로)
SELECT * FROM orders ORDER BY id DESC LIMIT 3;
```

**FK 에러 메시지 이해:**

```
ERROR 1452 (23000): Cannot add or update a child row:
a foreign key constraint fails
(`hanip_delivery`.`orders`,
 CONSTRAINT `orders_ibfk_1`
 FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`))
```

이 메시지는 "orders 테이블에 삽입하려는 customer_id 값이 customers 테이블에 없다"는 뜻입니다. FK 제약조건이 잘 작동하고 있다는 증거이기도 합니다.

**트랜잭션 사용 원칙 정리:**

```
✅ 트랜잭션을 써야 하는 상황:
   - 여러 테이블에 걸쳐 INSERT/UPDATE/DELETE가 연관되어 실행될 때
   - 실패 시 이전 상태로 되돌려야 할 때
   - 데이터 일관성이 중요한 처리 (결제, 주문, 재고 변경 등)

❌ 트랜잭션이 불필요한 상황:
   - 단순 SELECT 조회
   - 독립적인 단건 UPDATE (실패해도 다른 데이터에 영향 없음)
```

---

## 5. 자주 발생하는 에러 3가지

### 에러 1: EXPLAIN에서 type=ALL이 계속 나온다

**증상:**
```
EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
→ type=ALL, key=NULL
```

**원인:**
1. 해당 컬럼에 인덱스가 없음
2. 인덱스가 있어도 옵티마이저가 풀스캔이 더 낫다고 판단 (데이터가 너무 적을 때)

**해결:**
```sql
-- 인덱스 생성
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- 데이터가 너무 적으면 일부러 type=ALL이 나올 수 있음 (정상)
-- 수백만 건이 넘을 때 성능 차이가 크게 나타남
```

---

### 에러 2: DROP VIEW / DROP INDEX 시 오타 에러

**증상:**
```
ERROR 1051 (42S02): Unknown table 'hanip_delivery.v_restaurant_stat'
```
또는
```
ERROR 1091 (42000): Can't DROP 'idx_orders_custmer'; check that column/key exists
```

**원인:** 뷰 이름 또는 인덱스 이름의 오타

**해결:**
```sql
-- 뷰 이름 먼저 확인
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 인덱스 이름 먼저 확인
SHOW INDEX FROM orders;

-- 이름 확인 후 정확하게 삭제
DROP VIEW IF EXISTS v_restaurant_stats;      -- IF EXISTS로 에러 방지
DROP INDEX idx_orders_customer ON orders;
```

---

### 에러 3: ROLLBACK이 안 된다 (AUTO COMMIT 상태)

**증상:** `START TRANSACTION` 없이 UPDATE나 DELETE를 실행한 후 ROLLBACK을 입력했지만 데이터가 돌아오지 않음

**원인:** AUTO COMMIT이 켜진 상태에서 실행된 SQL은 즉시 커밋되므로 ROLLBACK 불가

**해결 및 예방:**
```sql
-- 현재 AUTO COMMIT 상태 확인
SHOW VARIABLES LIKE 'autocommit';

-- 중요한 변경 전에는 반드시 START TRANSACTION 사용
START TRANSACTION;
UPDATE orders SET status = '취소' WHERE id = 5;
SELECT * FROM orders WHERE id = 5;  -- 확인 후
COMMIT;  -- 이상 없으면 확정

-- ⚠️ 실수로 이미 AUTO COMMIT으로 실행했다면?
-- → 백업에서 복구하거나, 수동으로 반대 작업을 해야 합니다.
-- → 그래서 중요한 변경은 항상 START TRANSACTION부터 시작합니다.
```

---

## 6. 오늘 배운 것 정리 — 키워드 요약표

### 인덱스 관련 명령어

| 명령어 | 역할 | 예시 |
|---|---|---|
| `CREATE INDEX` | 인덱스 생성 | `CREATE INDEX idx_name ON orders(customer_id)` |
| `DROP INDEX` | 인덱스 삭제 | `DROP INDEX idx_name ON orders` |
| `SHOW INDEX FROM` | 인덱스 목록 조회 | `SHOW INDEX FROM orders` |
| `EXPLAIN` | 쿼리 실행 계획 조회 | `EXPLAIN SELECT ...` |

### EXPLAIN type 컬럼 해석

| type | 의미 | 성능 |
|---|---|---|
| `ALL` | 풀스캔 (전체 읽기) | 나쁨 (인덱스 검토 필요) |
| `index` | 인덱스 전체 스캔 | 보통 |
| `range` | 인덱스 범위 스캔 | 양호 |
| `ref` | 인덱스 매칭 스캔 | 좋음 |
| `const` | 단 1건 (PK/UNIQUE) | 최고 |

### 뷰 관련 명령어

| 명령어 | 역할 | 예시 |
|---|---|---|
| `CREATE VIEW ... AS SELECT` | 뷰 생성 | `CREATE VIEW v_stats AS SELECT ...` |
| `CREATE OR REPLACE VIEW` | 뷰 생성 또는 덮어쓰기 | `CREATE OR REPLACE VIEW v_stats AS SELECT ...` |
| `DROP VIEW IF EXISTS` | 뷰 삭제 | `DROP VIEW IF EXISTS v_stats` |
| `SHOW FULL TABLES WHERE Table_type = 'VIEW'` | 뷰 목록 | |

### 트랜잭션 관련 명령어

| 명령어 | 역할 |
|---|---|
| `START TRANSACTION` | 트랜잭션 시작 |
| `COMMIT` | 변경사항 영구 저장 |
| `ROLLBACK` | 변경사항 전체 취소 |
| `SAVEPOINT 이름` | 중간 저장점 생성 |
| `ROLLBACK TO 이름` | 저장점까지만 롤백 |
| `SHOW VARIABLES LIKE 'autocommit'` | AUTO COMMIT 상태 확인 |

### 오늘 배운 핵심 패턴

```sql
-- 패턴 1: EXPLAIN으로 인덱스 효과 확인
EXPLAIN SELECT * FROM orders WHERE customer_id = 3;
-- type=ALL → 인덱스 없음
-- type=ref  → 인덱스 있음

-- 패턴 2: 복합 인덱스 (자주 함께 쓰는 컬럼)
CREATE INDEX idx_orders_cust_date ON orders(customer_id, order_date);

-- 패턴 3: 뷰 생성 + 활용
CREATE VIEW v_restaurant_stats AS SELECT ... FROM restaurants LEFT JOIN orders ...;
SELECT * FROM v_restaurant_stats WHERE category = '치킨';

-- 패턴 4: 트랜잭션 기본 패턴
START TRANSACTION;
INSERT INTO orders (...) VALUES (...);
SELECT * FROM orders ORDER BY id DESC LIMIT 3;  -- 확인
COMMIT;  -- 또는 ROLLBACK

-- 패턴 5: SAVEPOINT를 활용한 부분 롤백
START TRANSACTION;
INSERT INTO orders (...) VALUES (...);
SAVEPOINT sp1;
-- 추가 작업 ...
ROLLBACK TO sp1;  -- 추가 작업만 취소
COMMIT;
```

---

## 7. Day 9 예고

오늘 우리는 만들어져 있는 테이블을 더 잘 활용하는 방법을 배웠습니다. 그런데 여기서 한 가지 중요한 질문이 남습니다.

> **"지금까지 만든 테이블, 처음부터 잘 설계된 건가요?"**

Day 1부터 Day 8까지 `restaurants`, `customers`, `menus`, `orders` 테이블을 만들어 왔습니다. 그런데 이 구조가 정말 올바른 설계인지 점검해 본 적이 없습니다.

Day 9에서는 **설계의 정석**을 배웁니다.

- **ERD (Entity-Relationship Diagram):** 테이블 간의 관계를 시각적으로 그리는 "건물 설계도"
- **FOREIGN KEY:** 테이블 간의 공식 연결 고리와 무결성 규칙
- **정규화:** "같은 정보가 여러 곳에 중복 저장되지 않도록 방 정리하기"
  - 비정규화 → 1NF → 2NF → 3NF 단계별 정리
- **팀 실습:** 한입배달 DB에 `riders`(배달기사), `reviews`(후기), `coupons`(쿠폰) 테이블을 추가하는 ERD 설계

Day 9에서는 오늘까지 배운 내용을 모두 활용하여 처음부터 제대로 설계된 DB를 만드는 과정을 경험합니다.

오늘 배운 인덱스, 뷰, 트랜잭션은 그 때 직접 활용하게 됩니다. 충분히 복습해 오세요!

---

> **한입배달 MySQL 10일 완성 | Day 8 | 한국IT교육센터 부산점**
