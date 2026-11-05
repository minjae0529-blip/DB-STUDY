# DB-STUDY (MySQL & Java JDBC)

국비지원 과정(대한민국인공지능아카데미 11기)에서 진행한 MySQL 쿼리 실습(`Ch01` ~ `Ch07`)과 IntelliJ 기반 Java JDBC 연동 코드를 정리한 저장소입니다.

배달 플랫폼 예제 DB인 `hanip_delivery`(고객 30명, 가게 15곳, 메뉴 70개, 라이더 8명, 주문 563건, 주문상세 1,060건, 리뷰 260건)를 기반으로 테이블 조회, 집계, 조인, 서브쿼리, 윈도우 함수 실습을 진행했습니다.

---

## 개발 및 실습 환경

| 구분 | 사용 기술 | 비고 |
| :--- | :--- | :--- |
| DBMS | MySQL 8.0 / 9.x | `utf8mb4` |
| Tool | IntelliJ Database Tool, MySQL Workbench | 쿼리 작성 및 실행 계획/데이터 확인 |
| Language / Build | Java 21, Maven | JDBC 연동 실습 (`jdbc-practice`) |
| Library | `mysql-connector-j` (9.7.0), Lombok | `DriverManager`, `PreparedStatement`, `ResultSetMetaData` |

---

## 디렉토리 구조

```text
DBMS_STUDY/
├── database/                         # 한입배달 DB 스키마(schema.sql) 및 초기 데이터(seed.sql)
├── chapters/                         # 챕터별 교안, 문제(practice.md), 직접 작성한 쿼리(study01.sql)
│   ├── ch01-first-database/          # DB 기본 명령어 (SHOW, USE, DESC, LIMIT)
│   ├── ch02-select-basics/           # SELECT, WHERE 조건절, ORDER BY, LIMIT/OFFSET
│   ├── ch03-functions/               # 문자열·숫자·날짜 함수, CASE WHEN, IFNULL/COALESCE
│   ├── ch04-aggregation/             # 집계 함수, GROUP BY, HAVING, ROLLUP (study01.sql)
│   ├── ch05-join/                    # INNER JOIN, LEFT JOIN, 다중 조인 실습 (study01.sql)
│   ├── ch06-subquery-window/         # 서브쿼리, EXISTS, CTE(WITH), 윈도우 함수 실습 (study01.sql)
│   └── ch07-ddl-constraints/         # 테이블 설계(CREATE/ALTER) 및 제약조건(PK, FK, UNIQUE, CHECK)
└── jdbc-practice/                    # Java - MySQL JDBC 연동 및 공통 Repository 구현
    ├── pom.xml
    └── src/main/java/com/korai/dbstudy/
        ├── database/                 # DBConfig, DatabaseProvider(싱글톤), 연결 테스트
        ├── entity/                   # Menu, Customer 도메인 객체
        └── repository/               # ResultSetMetaData 기반 공통 Repository<T>
```

---

## 데이터베이스 구조 (ERD)

주문 데이터를 하나의 테이블에 몰아넣으면 데이터 중복과 수정 이상이 발생하므로, 역할에 따라 7개 테이블로 분리하고 PK-FK로 연결해 사용합니다.

```mermaid
erDiagram
    customers   ||--o{ orders       : "customer_id"
    restaurants ||--o{ orders       : "restaurant_id"
    riders      |o--o{ orders       : "rider_id"
    restaurants ||--o{ menus        : "restaurant_id"
    orders      ||--|{ order_items  : "order_id"
    menus       ||--o{ order_items  : "menu_id"
    orders      ||--o| reviews      : "order_id"
```

---

# Part 1. MySQL 챕터별 정리 및 실습 쿼리

---

## Ch01. 데이터베이스 기본 탐색 (`ch01-first-database`)

### 정리
- **PK (Primary Key)**: 행을 고유하게 식별하는 컬럼 (중복 불가, `NULL` 불가)
- **FK (Foreign Key)**: 다른 테이블의 PK를 참조해 테이블 간 관계를 맺는 컬럼
- **SQL 분류**:
  - DML/DQL: `SELECT`, `INSERT`, `UPDATE`, `DELETE`
  - DDL: `CREATE`, `ALTER`, `DROP`, `TRUNCATE`
  - TCL: `COMMIT`, `ROLLBACK`
  - DCL: `GRANT`, `REVOKE`

### 기본 쿼리
```sql
SHOW DATABASES LIKE 'hanip_delivery%';
USE hanip_delivery01;
SELECT DATABASE() AS current_db;

SHOW TABLES;
DESC restaurants;

SELECT name, category, district
FROM restaurants
LIMIT 5;
```

---

## Ch02. `SELECT`와 조건 필터링 (`ch02-select-basics`)

### 정리
- **쿼리 작성 순서와 실제 실행 순서**:
  - 작성: `SELECT` -> `FROM` -> `WHERE` -> `ORDER BY` -> `LIMIT`
  - 실행: `FROM` -> `WHERE` -> `SELECT` -> `ORDER BY` -> `LIMIT`
  - `SELECT` 절에서 정의한 별칭(`AS`)은 `WHERE` 절에서는 아직 생성되기 전이라 참조할 수 없고, `ORDER BY`에서는 사용할 수 있다.
- **조건절 작성 시 주의할 점**:
  1. `AND`가 `OR`보다 우선순위가 높기 때문에 두 연산자를 같이 쓸 때는 괄호로 먼저 묶어준다.
  2. `DATETIME` 컬럼을 날짜로 기간 조회할 때 `BETWEEN '2026-06-01' AND '2026-06-30'`으로 쓰면 `06-30 00:00:00`까지만 조회된다. `ordered_at >= '2026-06-01' AND ordered_at < '2026-07-01'` 형태로 작성하는 것이 안전하다.
  3. `NULL` 여부는 `=`이나 `!=`로 비교할 수 없으므로 `IS NULL`, `IS NOT NULL`을 사용한다.

### 예제 쿼리
```sql
-- 다중 조건 필터링 및 정렬
SELECT name, category, district, min_order_amount, delivery_fee
FROM restaurants
WHERE district IN ('부산진구', '수영구')
  AND is_open = TRUE
  AND min_order_amount <= 15000
ORDER BY delivery_fee ASC, min_order_amount ASC;

-- LIKE 패턴 검색과 NULL 체크
SELECT name, address FROM customers WHERE address LIKE '%전포동%';
SELECT name, phone, email FROM customers WHERE email IS NULL;

-- 페이징 (2페이지: 5개 건너뛰고 5개 조회)
SELECT menu_id, name, price
FROM menus
ORDER BY menu_id
LIMIT 5 OFFSET 5;
```

---

## Ch03. 내장 함수와 조건 분기 (`ch03-functions`)

### 정리
- **문자열 함수**:
  - `CONCAT`은 인자 중 하나라도 `NULL`이면 결과가 `NULL`이 된다. 구분자를 넣으면서 `NULL`을 무시하려면 `CONCAT_WS`를 사용한다.
  - 한글 글자 수를 셀 때는 바이트 수를 반환하는 `LENGTH()` 대신 `CHAR_LENGTH()`를 사용한다.
- **날짜 함수**:
  - `DATE_FORMAT(컬럼, '%Y-%m-%d %H:%i')`: 날짜 포맷 변환
  - `DATEDIFF(끝, 시작)`: 일수 차이 / `TIMESTAMPDIFF(단위, 시작, 끝)`: 분(`MINUTE`), 연도(`YEAR`) 등 지정 단위 차이 계산
- **NULL 처리 및 조건문**:
  - `IFNULL(컬럼, 대체값)`, `COALESCE(값1, 값2, ...)`, `NULLIF(값1, 값2)`
  - `IF(조건, 참, 거짓)`, `CASE WHEN ... THEN ... ELSE ... END`

### 예제 쿼리
```sql
-- 전화번호 마스킹 및 만 나이/연령대 계산
SELECT name,
       CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS masked_phone,
       birth_date,
       TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') AS age,
       CASE
           WHEN birth_date IS NULL THEN '미입력'
           ELSE CONCAT(FLOOR(TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') / 10) * 10, '대')
       END AS age_group
FROM customers;

-- 주문 시각과 배달 완료 시각의 차이(분)로 배달 상태 분류
SELECT order_id,
       TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS minutes,
       CASE
           WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) <= 30 THEN '빠름'
           WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) <= 60 THEN '보통'
           ELSE '지연'
       END AS speed
FROM orders
WHERE status = '배달완료';
```

---

## Ch04. 집계와 그룹화 (`ch04-aggregation`)

### 정리
- **`COUNT(*)` vs `COUNT(컬럼)`**: `COUNT(*)`는 `NULL`을 포함한 전체 행 수를 세고, `COUNT(컬럼)`을 쓰면 `NULL`을 제외한 행 수만 카운트한다.
- **`WHERE`와 `HAVING`의 차이**:
  - `WHERE`: `GROUP BY`로 묶기 전에 개별 행을 필터링 (집계 함수 사용 불가)
  - `HAVING`: `GROUP BY` 이후 그룹화된 결과에 대해 집계 조건으로 필터링
- **조건부 집계**: `COUNT(IF(조건, 1, NULL))` 또는 `COUNT(CASE WHEN 조건 THEN 1 END)`를 활용하면 `NULL`은 카운트되지 않는 성질을 이용해 특정 조건을 만족하는 행만 집계할 수 있다.

### 실습 및 연습문제 풀이 (`chapters/ch04-aggregation/study01.sql`)
```sql
-- 1. WITH ROLLUP과 UNION ALL을 이용한 합계 행 추가 비교
SELECT IFNULL(payment_method, '합계') AS payment_method,
       COUNT(*)                      AS delivery_orders,
       SUM(orders.delivery_fee)      AS fee_sum
FROM orders
WHERE status = '배달완료'
GROUP BY payment_method WITH ROLLUP
ORDER BY payment_method;

-- 2. [문제 3] 별점별 리뷰 수와 내용 없이 별점만 남긴 리뷰 수 집계
SELECT rating,
       COUNT(rating)                       AS review_count,
       COUNT(IF(content IS NULL, 1, NULL)) AS rating_only
FROM reviews
GROUP BY rating;

-- 3. [문제 8] 배달완료 30건 이상 단골 고객의 주문 수, 첫 주문일, 마지막 주문일
SELECT customer_id,
       COUNT(*)                                 AS order_count,
       DATE_FORMAT(MIN(ordered_at), '%Y-%m-%d') AS first_order,
       DATE_FORMAT(MAX(ordered_at), '%Y-%m-%d') AS last_order
FROM orders
WHERE status = '배달완료'
GROUP BY customer_id
HAVING COUNT(*) >= 30
ORDER BY order_count DESC, customer_id ASC
LIMIT 5;

-- 4. [문제 11] 라이더별 배달 완료 건수, 평균 배달 시간(분), 60분 초과 지연 건수 및 지연율(%)
SELECT rider_id,
       COUNT(delivered_at) AS deliveries,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_minute,
       COUNT(CASE WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60 THEN 1 END) AS late_count,
       ROUND(COUNT(CASE WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60 THEN 1 END) / COUNT(*) * 100, 1) AS late_rate
FROM orders
WHERE status = '배달완료'
GROUP BY rider_id
ORDER BY deliveries DESC;

-- 5. [문제 12] 월별 결제 수단 건수 피벗(Pivot) 테이블
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
       COUNT(CASE WHEN payment_method = '카드' THEN 1 END)     AS card,
       COUNT(CASE WHEN payment_method = '간편결제' THEN 1 END) AS easy_pay,
       COUNT(CASE WHEN payment_method = '계좌이체' THEN 1 END) AS transfer,
       COUNT(CASE WHEN payment_method = '현장결제' THEN 1 END) AS on_site,
       COUNT(*)                                                AS total
FROM orders
WHERE status = '배달완료'
GROUP BY DATE_FORMAT(ordered_at, '%Y-%m');
```

---

## Ch05. JOIN (`ch05-join`)

### 정리
- **`INNER JOIN`**: 양쪽 테이블에서 조인 조건(`ON`)이 일치하는 행만 결합한다.
- **`LEFT OUTER JOIN`**: 왼쪽 기준 테이블의 데이터는 모두 유지하고, 오른쪽 테이블에 매칭되는 값이 없으면 `NULL`로 채운다.
  - 오른쪽 테이블의 PK가 `NULL`인 조건(`WHERE oi.menu_id IS NULL`)을 걸면 **한 번도 주문되지 않은 메뉴**나 **리뷰가 작성되지 않은 주문**을 찾을 수 있다.
  - 기준 테이블의 전체 건수(0건 포함)를 유지하면서 조건을 걸어야 할 때는 `WHERE`가 아니라 `LEFT JOIN ... ON` 절 안에 `AND`로 조건을 작성해야 기준 행이 사라지지 않는다.
- **조인 시 중복 집계 주의**: `orders`(1)와 `order_items`(N)를 조인하면 주문 1건이 상세 품목 수만큼 여러 줄로 늘어나므로, 주문 건수를 셀 때는 `COUNT(DISTINCT o.order_id)`를 사용한다.

### 실습 및 연습문제 풀이 (`chapters/ch05-join/study01.sql`)
```sql
-- 1. 6개 테이블 다중 LEFT JOIN으로 특정 고객의 주문/메뉴/리뷰/가게/라이더 이력 한 번에 조회
SELECT *
FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    LEFT JOIN menus m        ON m.menu_id = oi.menu_id
    LEFT JOIN reviews rb     ON rb.order_id = o.order_id
    LEFT JOIN customers c    ON c.customer_id = o.customer_id
    LEFT JOIN restaurants rt ON rt.restaurant_id = o.restaurant_id
    LEFT JOIN riders rd      ON rd.rider_id = o.rider_id
WHERE c.name = '윤지아';

-- 2. [문제 7] 업종별 배달완료 주문 수(중복 제거)와 음식 매출 합계
SELECT rs.category,
       COUNT(DISTINCT oi.order_id)      AS delivered_orders,
       SUM(oi.quantity * oi.unit_price) AS food_sales
FROM orders o
    JOIN restaurants rs ON rs.restaurant_id = o.restaurant_id
    JOIN order_items oi ON oi.order_id = o.order_id
WHERE status = '배달완료'
GROUP BY rs.category
ORDER BY food_sales DESC;

-- 3. [문제 8] LEFT JOIN + IS NULL을 이용해 한 번도 주문된 적 없는 메뉴 조회
SELECT ms.menu_id,
       ms.name,
       rs.name
FROM menus ms
    JOIN restaurants rs      ON rs.restaurant_id = ms.restaurant_id
    LEFT JOIN order_items oi ON oi.menu_id = ms.menu_id
WHERE oi.menu_id IS NULL
ORDER BY menu_id ASC;

-- 4. [문제 9] 전체 고객별 배달완료 주문 수 (0건인 고객도 누락되지 않도록 ON 절에 조건 추가)
SELECT cs.name,
       cs.grade,
       COUNT(os.order_id) AS delivered_orders
FROM customers cs
    LEFT JOIN orders os
           ON os.customer_id = cs.customer_id
          AND os.status = '배달완료'
GROUP BY cs.customer_id, cs.name, cs.grade
ORDER BY delivered_orders, cs.name ASC;

-- 5. [문제 11] 현재 메뉴 가격과 주문 당시 단가가 다른 메뉴(가격 변동 이력) 집계
SELECT ms.name,
       oi.unit_price,
       ms.price          AS current_price,
       SUM(oi.quantity)  AS sold_qty
FROM menus ms
    JOIN order_items oi ON oi.menu_id = ms.menu_id
    JOIN orders os      ON os.order_id = oi.order_id
WHERE status = '배달완료'
  AND oi.unit_price != ms.price
GROUP BY ms.name, oi.unit_price, ms.price, ms.menu_id
ORDER BY SUM(oi.quantity) DESC;
```

---

## Ch06. 서브쿼리·집합·윈도우 함수 (`ch06-subquery-window`)

### 정리
- **위치에 따른 서브쿼리 형태**:
  - **인라인 뷰 (`FROM` 절)**: 여러 행과 열을 가진 표 형태의 결과를 가상 테이블처럼 사용 (`FROM (SELECT ...) m`)
  - **목록 서브쿼리 (`WHERE` 절)**: 1개 컬럼의 여러 행을 반환해 `IN`, `NOT IN`, `EXISTS`와 함께 사용
  - **스칼라 서브쿼리 (`SELECT` / `WHERE` 절)**: 단일 값(1행 1열)을 반환해 컬럼 값이나 비교 조건으로 사용 (2행 이상 반환 시 `Error 1242` 발생)
- **`NOT IN` 사용 시 `NULL` 주의점**:
  - 서브쿼리 결과에 `NULL`이 하나라도 포함되어 있으면 `NOT IN` 조건 전체가 `UNKNOWN`이 되어 결과가 0건으로 나온다.
  - 따라서 서브쿼리 안에 `IS NOT NULL` 조건을 명시하거나, **`NOT EXISTS (SELECT 1 ...)`**를 사용하는 것이 안전하다.
- **CTE (`WITH` 절) & `UNION` / `UNION ALL`**:
  - `WITH 테이블명 AS (SELECT ...)`: 복잡한 집계 쿼리나 임시 코드성 테이블(요일 매핑 등)을 단계별로 이름 붙여 정의하고 본 쿼리에서 재사용할 수 있다.
  - `UNION`은 중복 행을 제거(느림), `UNION ALL`은 중복 제거 없이 위아래 결과를 그대로 합친다(빠름).
- **윈도우 함수 (`함수() OVER (PARTITION BY 그룹 ORDER BY 순서)`)**:
  - `GROUP BY`는 그룹마다 1행으로 합치지만, 윈도우 함수는 **원래 행들을 그대로 유지한 채** 옆에 그룹별 순위나 누적 합계를 붙인다.
  - **순위 함수 3가지 (`ROW_NUMBER`, `RANK`, `DENSE_RANK`) 동점 처리 비교**:

| 함수 | 동점 처리 방식 | 예시 결과 (`22000, 22000, 21000, 21000, 20000`) |
| :--- | :--- | :--- |
| `ROW_NUMBER()` | 동점이어도 무조건 고유 번호 부여 | `1, 2, 3, 4, 5` |
| `RANK()` | 동점은 같은 순위, 다음 순위는 동점 수만큼 건너뜀 | `1, 1, 3, 3, 5` |
| `DENSE_RANK()` | 동점은 같은 순위, 다음 순위를 건너뛰지 않음 | `1, 1, 2, 2, 3` |

  - **그룹별 Top-N 필터링**: 윈도우 함수는 `SELECT` 단계에서 계산되므로 `WHERE` 절에서 바로 조건으로 쓸 수 없다. `WITH`(CTE)나 인라인 뷰로 먼저 감싼 뒤 바깥 쿼리에서 `WHERE rn = 1` 형태로 거른다.
  - **집계 함수 + `OVER`**:
    - `SUM(SUM(금액)) OVER (ORDER BY 월)`: 안쪽 `SUM`은 `GROUP BY` 월별 합계이고, 바깥 `SUM() OVER`는 그 월별 합계를 순서대로 누적한다.
    - `SUM(SUM(금액)) OVER ()`: `OVER ()` 괄호를 비우면 전체 합계가 되어 전체 대비 비율(`%`)을 구할 때 사용한다.

### 윈도우 함수 핵심 예제 (`chapters/ch06-subquery-window/lecture.sql`)
```sql
-- 1. 순위 함수 3종 비교 (ROW_NUMBER vs RANK vs DENSE_RANK)
SELECT name,
       price,
       ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
       RANK()       OVER (ORDER BY price DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rnk
FROM menus
WHERE restaurant_id IN (1, 6)
ORDER BY price DESC, name;

-- 2. PARTITION BY: 가게별로 1위부터 다시 순위 매기기
SELECT restaurant_id,
       name,
       price,
       RANK() OVER (PARTITION BY restaurant_id ORDER BY price DESC) AS price_rank
FROM menus
WHERE restaurant_id IN (1, 2)
ORDER BY restaurant_id, price_rank;

-- 3. 그룹별 Top-N: CTE로 감싼 뒤 가게마다 가장 비싼 메뉴 1개씩 뽑기 (ROW_NUMBER)
WITH ranked AS (
    SELECT restaurant_id,
           name,
           price,
           ROW_NUMBER() OVER (PARTITION BY restaurant_id ORDER BY price DESC, menu_id) AS rn
    FROM menus
)
SELECT restaurant_id, name, price
FROM ranked
WHERE rn = 1
ORDER BY restaurant_id;

-- 4. 집계 함수 + OVER: 월별 배달비 합계, 누적 합계(ORDER BY), 전체 대비 비중(OVER ())
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
       SUM(delivery_fee) AS fee_sum,
       SUM(SUM(delivery_fee)) OVER (ORDER BY DATE_FORMAT(ordered_at, '%Y-%m')) AS cumulative_fee,
       ROUND(SUM(delivery_fee) * 100 / SUM(SUM(delivery_fee)) OVER (), 1) AS share_pct
FROM orders
WHERE status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
```

### 실습 및 연습문제 풀이 (`chapters/ch06-subquery-window/study01.sql`)
```sql
-- 1. 인라인 뷰(FROM), 목록(IN), 스칼라(SELECT/WHERE) 서브쿼리 기본 형태
-- (1) FROM 절 인라인 뷰
SELECT *
FROM (SELECT menu_id, name AS menu_name FROM menus) m
WHERE menu_name LIKE '%국밥';

-- (2) WHERE 절 목록 서브쿼리
SELECT *
FROM order_items
WHERE menu_id IN (SELECT menu_id FROM menus WHERE menus.menu_id MOD 2 = 0);

-- (3) SELECT / WHERE 절 스칼라 서브쿼리
SELECT menu_id,
       name,
       (SELECT name FROM restaurants WHERE restaurants.restaurant_id = menus.restaurant_id) AS restaurant_name
FROM menus
WHERE restaurant_id = (SELECT restaurant_id FROM restaurants WHERE name = '장전동든든김밥');

-- 2. NOT IN의 NULL 문제 해결 vs NOT EXISTS 비교
-- (1) NOT IN 사용 시에는 서브쿼리에서 NULL을 반드시 제외해야 결과가 정상 출력됨
SELECT *
FROM riders
WHERE rider_id NOT IN (
    SELECT rider_id
    FROM orders
    WHERE ordered_at > '2026-06-30'
      AND orders.rider_id IS NOT NULL
);

-- (2) NOT EXISTS로 작성하면 NULL 신경 쓸 필요 없이 안전하게 동작
SELECT rd.name, rd.rider_id
FROM riders rd
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.rider_id = rd.rider_id
      AND o.ordered_at >= '2026-06-30'
);

-- 3. WITH(CTE)와 UNION ALL 활용
-- (1) 가게별/월별 평균 주문금액을 CTE로 정의한 뒤 restaurants와 LEFT JOIN
WITH ap_cte AS (
    SELECT od.restaurant_id,
           DATE_FORMAT(ordered_at, '%Y-%m')     AS order_month,
           ROUND(AVG(quantity * unit_price), 0) AS avg_price
    FROM orders od
        LEFT OUTER JOIN order_items oi ON oi.order_id = od.order_id
    GROUP BY od.restaurant_id, DATE_FORMAT(ordered_at, '%Y-%m')
)
SELECT *
FROM restaurants rt
    LEFT JOIN ap_cte ap ON ap.restaurant_id = rt.restaurant_id;

-- (2) UNION ALL로 요일 번호(1~7) 한글 변환용 CTE를 만들어 주문 요일 출력
WITH day_of_week_kor AS (
    SELECT 1 AS day_id, '일' AS kor_name
    UNION ALL SELECT 2, '월'
    UNION ALL SELECT 3, '화'
    UNION ALL SELECT 4, '수'
    UNION ALL SELECT 5, '목'
    UNION ALL SELECT 6, '금'
    UNION ALL SELECT 7, '토'
)
SELECT order_id,
       ordered_at,
       dowk.kor_name
FROM orders od
    LEFT OUTER JOIN day_of_week_kor dowk ON dowk.day_id = DAYOFWEEK(od.ordered_at);

-- 4. 윈도우 함수 실습 (RANK, ROW_NUMBER, 누적합 SUM OVER)
-- (1) 카테고리별 매출 기준 가게 순위 매기기 (RANK() OVER)
SELECT rs.category,
       RANK() OVER (PARTITION BY category ORDER BY SUM(quantity * price) DESC) AS restaurant_rank,
       rs.restaurant_id,
       rs.name,
       IFNULL(SUM(oi.quantity), 0) AS total_quantity
FROM menus ms
    LEFT OUTER JOIN order_items oi ON oi.menu_id = ms.menu_id
    LEFT OUTER JOIN restaurants rs ON rs.restaurant_id = ms.restaurant_id
GROUP BY rs.restaurant_id, rs.category, rs.name
ORDER BY category ASC;

-- (2) 월별 배달비 합계와 월별 누적 배달비(SUM OVER) 구하기
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
       SUM(IFNULL(delivery_fee, 0))     AS delivery_fee_sum,
       SUM(SUM(IFNULL(delivery_fee, 0))) OVER (ORDER BY DATE_FORMAT(ordered_at, '%Y-%m')) AS cumulative_fee
FROM orders
GROUP BY DATE_FORMAT(ordered_at, '%Y-%m');

-- 5. 연습문제 풀이 (study01.sql)
-- [문제 1] 전체 메뉴 중 최고가 메뉴 조회
SELECT restaurant_id, name, price
FROM menus
WHERE price = (SELECT MAX(price) FROM menus);

-- [문제 5] 6월 이전에 가입했지만 6월 한 달간 주문 이력이 없는 고객 조회 (NOT EXISTS)
SELECT cs.name, cs.joined_at
FROM customers cs
WHERE DATE(cs.joined_at) < '2026-06-01'
  AND NOT EXISTS (
      SELECT 1
      FROM orders o1
      WHERE o1.customer_id = cs.customer_id
        AND o1.ordered_at >= '2026-06-01'
        AND o1.ordered_at < '2026-07-01'
  )
ORDER BY cs.joined_at;

-- [문제 8] 마지막 주문 이후 30일 이상 경과한 고객 조회
SELECT cs.name,
       MAX(o.ordered_at) AS last_order_date,
       TIMESTAMPDIFF(DAY, MAX(o.ordered_at), '2026-07-01') AS day_since_last
FROM orders o
    JOIN customers cs ON cs.customer_id = o.customer_id
WHERE o.ordered_at < '2026-07-01'
GROUP BY cs.customer_id, cs.name
HAVING day_since_last > 29
ORDER BY day_since_last DESC;

-- [문제 11] 업종별 가게 음식 매출 및 ROW_NUMBER() 순번 부여
SELECT rs.category,
       ROW_NUMBER() OVER (PARTITION BY rs.category ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS category_rn,
       rs.name,
       SUM(oi.quantity * oi.unit_price) AS food_sales
FROM orders os
    INNER JOIN restaurants rs ON rs.restaurant_id = os.restaurant_id
    INNER JOIN order_items oi ON oi.order_id = os.order_id
WHERE status = '배달완료'
GROUP BY rs.category, rs.name, rs.restaurant_id
ORDER BY food_sales DESC;
```

---

## Ch07. 테이블 설계와 제약조건 (`ch07-ddl-constraints`)

### 정리
- **데이터 타입 선택**:
  - 금액이나 할인율처럼 정확도가 중요한 숫자에는 2진수 부동소수점 오차가 발생하는 `FLOAT`/`DOUBLE`을 쓰지 않고 `INT`(원 단위)나 `DECIMAL(p, s)`을 사용한다.
  - 전화번호처럼 길이가 일정하고 사칙연산을 하지 않는 값(맨 앞 `0` 유지 필요)은 `CHAR(n)`, 가변 길이 문자열은 `VARCHAR(n)`(글자 수 기준), 긴 본문은 `TEXT`를 사용한다.
- **제약조건 6종과 주요 에러 코드**:
  - `PRIMARY KEY`: 행 식별자 (`NOT NULL` + `UNIQUE`, 보통 `AUTO_INCREMENT`와 함께 사용)
  - `NOT NULL`: 빈 값 허용 안 함 (위반 시 `Error 1048`)
  - `UNIQUE`: 중복 값 허용 안 함 (`NULL`은 여러 개 가능, 두 컬럼 이상을 묶어 복합 `UNIQUE` 지정 가능 — 위반 시 `Error 1062`)
  - `DEFAULT`: 값 생략 시 자동으로 채워질 기본값 (`DEFAULT 0`, `DEFAULT CURRENT_TIMESTAMP` 등)
  - `CHECK`: 허용할 값의 범위나 여러 컬럼 간 조건식 지정 (위반 시 `Error 3819`)
  - `FOREIGN KEY`: 부모 테이블에 존재하는 값만 참조 가능 (없는 부모 참조 시 `Error 1452`, 자식이 참조 중인 부모 삭제 시 `Error 1451`)
    - `ON DELETE` 정책: `RESTRICT`(기본값, 삭제 차단), `CASCADE`(자식 행도 연쇄 삭제), `SET NULL`(자식의 FK 값을 `NULL`로 변경)
- **제약조건 작성 위치**:
  - 단일 컬럼에만 간단히 걸 때는 컬럼 옆에 적을 수 있지만, 복합 `UNIQUE`를 걸거나 에러 메시지에서 어떤 규칙을 어겼는지 바로 확인하려면 아래쪽에 `CONSTRAINT 제약조건이름 ...` 형태로 이름을 붙여 작성한다.
- **`DELETE` vs `TRUNCATE` vs `DROP`**:

| 구문 | 분류 | 동작 | 되돌리기(Rollback) | `AUTO_INCREMENT` |
| :--- | :--- | :--- | :--- | :--- |
| `DELETE FROM t WHERE ...` | DML | 조건에 맞는 행 삭제 | 트랜잭션 내 가능 | 기존 번호 유지 |
| `TRUNCATE TABLE t` | DDL | 테이블 구조는 남기고 모든 행 초기화 | 불가 | 1로 초기화 |
| `DROP TABLE t` | DDL | 테이블 자체를 삭제 | 불가 | - |

### 실습 및 연습문제 풀이 (`chapters/ch07-ddl-constraints/study01.sql`)
```sql
-- 1. 쿠폰 종류 테이블(coupons) 설계: 복합 CHECK 조건(정액/정률 구분) 적용
CREATE TABLE coupons (
    coupon_id        INT         NOT NULL AUTO_INCREMENT,
    code             VARCHAR(20) NOT NULL,
    name             VARCHAR(50) NOT NULL,
    discount_type    VARCHAR(10) NOT NULL,
    discount_value   INT         NOT NULL,
    min_order_amount INT         NOT NULL DEFAULT 0,
    vaild_days       INT         NOT NULL DEFAULT 30,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    create_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
    CONSTRAINT uq_coupons UNIQUE (code),
    CONSTRAINT ck_coupons_type CHECK (discount_type IN ('정액', '정률')),
    CONSTRAINT ck_coupons_value CHECK (
        (discount_type = '정액' AND discount_value > 0)
        OR
        (discount_type = '정률' AND discount_value BETWEEN 1 AND 50)
    ),
    CONSTRAINT ck_coupons_min CHECK (min_order_amount >= 0),
    CONSTRAINT ck_coupons_day CHECK (vaild_days > 0)
);

-- 2. 고객 보유 쿠폰 테이블(customer_coupons): M:N 연결 테이블 + 복합 UNIQUE(중복 지급 방지)
CREATE TABLE customer_coupons (
    customer_coupon_id INT      NOT NULL AUTO_INCREMENT,
    customer_id        INT      NOT NULL,
    coupon_id          INT      NOT NULL,
    issued_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at         DATETIME NOT NULL,
    used_order_id      INT      NULL,

    CONSTRAINT pk_customer_coupons PRIMARY KEY (customer_coupon_id),
    CONSTRAINT fk_cc_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_cc_coupon   FOREIGN KEY (coupon_id)   REFERENCES coupons (coupon_id),
    CONSTRAINT fk_cc_order    FOREIGN KEY (used_order_id) REFERENCES orders (order_id),
    CONSTRAINT uq_cc_customer_coupon UNIQUE (customer_id, coupon_id),
    CONSTRAINT uq_cc_used_order      UNIQUE (used_order_id),
    CONSTRAINT ck_cc_period          CHECK (expires_at > issued_at)
);

-- 3. information_schema를 이용해 현재 DB의 NULL 허용 컬럼 및 CHECK 제약조건 조회
SELECT COLUMN_NAME, DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'orders'
  AND IS_NULLABLE = 'yes'
GROUP BY COLUMN_NAME, DATA_TYPE;

SELECT CONSTRAINT_NAME
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'orders'
  AND CONSTRAINT_TYPE = 'CHECK';

-- 4. [문제 4] 공지사항 테이블(notices) 생성 및 데이터 등록
CREATE TABLE notices (
    notice_id INT          NOT NULL AUTO_INCREMENT,
    title     VARCHAR(100) NOT NULL,
    content   TEXT         NOT NULL,
    is_pinned BOOLEAN      NOT NULL DEFAULT FALSE,
    published DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_notice_id PRIMARY KEY (notice_id)
);

-- 5. [문제 5] 가게 휴무일 테이블(restaurant_holidays): 같은 가게에 같은 날짜 중복 등록 방지
DROP TABLE IF EXISTS restaurant_holidays;
CREATE TABLE restaurant_holidays (
    holiday_id    INT PRIMARY KEY AUTO_INCREMENT,
    restaurant_id INT         NOT NULL,
    hoilday_date  DATETIME    NOT NULL,
    reason        VARCHAR(50) NULL,

    CONSTRAINT fk_restaurant_id FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
    CONSTRAINT uq_holidays_date UNIQUE (hoilday_date, restaurant_id)
);

-- 6. [문제 6] 메뉴 옵션 테이블(menu_options): ON DELETE CASCADE 및 옵션 포함 가격 조회
DROP TABLE IF EXISTS menu_options;
CREATE TABLE menu_options (
    option_id         INT AUTO_INCREMENT,
    menu_id           INT         NOT NULL,
    option_name       VARCHAR(30) NOT NULL,
    price_with_option INT DEFAULT 0,

    CONSTRAINT pk_option_id     PRIMARY KEY (option_id),
    CONSTRAINT price_with_option CHECK (price_with_option >= 0),
    CONSTRAINT fk_option_name   FOREIGN KEY (menu_id) REFERENCES menus (menu_id) ON DELETE CASCADE,
    CONSTRAINT uq_option_name   UNIQUE (option_name, menu_id)
);

INSERT INTO menu_options (menu_id, option_name, price_with_option) VALUES
    (35, '곱배기', 1000),
    (35, '계란 프라이', 1500),
    (35, '면추가 없음', 0);

SELECT m.name AS menu_name,
       option_name,
       (mo.price_with_option + m.price) AS price_with_option
FROM menu_options mo
    INNER JOIN menus m ON m.menu_id = mo.menu_id
ORDER BY price_with_option;
```

---

# Part 2. Java JDBC 연동 실습 (`jdbc-practice`)

MySQL의 데이터를 Java 애플리케이션에서 조회하고 객체(`Menu`, `Customer`)로 변환하는 과정을 3단계로 나누어 작성했습니다.

### 1. 기본 `DriverManager` 연결 (`DBConnectionTest`, `DBConnectionTest2`)
- `try-with-resources` 구문을 사용해 쿼리 실행 후 `Connection`이 자동으로 반납되도록 처리
- `PreparedStatement`로 SQL을 실행하고 `ResultSet`의 커서를 `while (rs.next())`로 이동하며 `Customer`, `Menu` 객체 리스트 생성

### 2. 설정 분리 및 싱글톤 커넥션 (`DBConfig`, `DatabaseProvider`)
- 접속 정보(`URL`, `USERNAME`, `PASSWORD`)를 `DBConfig` 상수로 분리
- `DatabaseProvider`를 싱글톤 패턴으로 구성하여 필요할 때마다 `getConnection()`으로 커넥션 획득

### 3. `ResultSetMetaData`를 활용한 공통 `Repository<T>` 구현
- 테이블마다 반복되는 `ResultSet` 매핑 코드를 줄이기 위해, `Repository<T>` 인터페이스의 `default` 메서드(`select`, `selectOne`)에서 `ResultSetMetaData`로 컬럼명을 동적으로 읽어 `List<Map<String, Object>>` 형태로 반환하도록 작성
- 각 도메인 리포지토리(`MenuRepository`, `CustomerRepository`)에서는 반환된 `Map` 리스트를 Stream의 `.map(Menu::new)` 생성자 참조로 변환해 사용

```java
public interface Repository<T> {
    List<T> findAll();
    T findById(int id);

    default List<Map<String, Object>> select(Connection connection, String sql, List<Object> params) {
        try (Connection conn = connection;
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (params != null && !params.isEmpty()) {
                for (int i = 0; i < params.size(); i++) {
                    pstmt.setObject(i + 1, params.get(i));
                }
            }

            try (ResultSet rs = pstmt.executeQuery()) {
                List<Map<String, Object>> table = new ArrayList<>();
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 0; i < columnCount; i++) {
                        int index = i + 1;
                        row.put(metaData.getColumnLabel(index), rs.getObject(index));
                    }
                    table.add(row);
                }
                return table;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}
```
