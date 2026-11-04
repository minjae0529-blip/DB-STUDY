# Day 9 연습문제 — ERD & 정규화: FK 설계, 참조무결성, 정규화(1NF~3NF)

> **한국IT교육센터 부산점 | MySQL 10일 완성 | 배달앱 "한입배달" DB 시나리오**

---

## 오늘 사용하는 테이블 구조

```sql
-- ① restaurants (가게)
-- id (PK AI), name, category, address, rating

-- ② customers (고객)
-- id (PK AI), name, phone, address

-- ③ menus (메뉴)
-- id (PK AI), restaurant_id (FK → restaurants.id), menu_name, price

-- ④ orders (주문)
-- id (PK AI), customer_id (FK → customers.id),
-- restaurant_id (FK → restaurants.id),
-- menu_id (FK → menus.id),
-- quantity, total_price, order_date, delivery_fee, status

-- ⑤ riders (배달원)
-- id (PK AI), name, phone, region, is_active

-- ⑥ reviews (리뷰)
-- id (PK AI), order_id (FK → orders.id),
-- customer_id (FK → customers.id),
-- rating (1~5), content, created_at

-- ⑦ coupons (쿠폰)
-- id (PK AI), coupon_name, discount_type ('정액'/'정률'),
-- discount_value, min_order_amount

-- ⑧ customer_coupons (고객-쿠폰 중간 테이블)
-- id (PK AI), customer_id (FK → customers.id),
-- coupon_id (FK → coupons.id),
-- issued_at, used_at, is_used
```

---

## 난이도 안내

| 표시 | 난이도 | 설명 |
|------|--------|------|
| ⭐ | 기초 | 핸드아웃 내용을 이해했다면 풀 수 있는 문제 |
| ⭐⭐ | 응용 | 개념을 응용하거나 여러 개념을 조합하는 문제 |
| ⭐⭐⭐ | 도전 | 여러 테이블과 개념을 종합하는 문제 |
| 💎 | 보너스 | 시간 여유가 있을 때 도전하는 심화 문제 |

---

## ⭐ 기초 문제

---

### 문제 1. FK 추가 — menus 테이블

> 개발팀에서 요청이 들어왔습니다.
> "현재 menus 테이블에 restaurant_id 컬럼은 있지만 FK 제약조건이 없습니다.
> restaurants 테이블의 id를 참조하는 FK를 추가해주세요.
> 가게가 폐업(삭제)되면 해당 가게의 메뉴들도 자동으로 삭제되어야 합니다."

**요구사항**:
- menus 테이블의 restaurant_id 컬럼에 FK를 추가하세요
- 제약조건 이름: `fk_menus_restaurant`
- 참조 테이블: `restaurants(id)`
- 옵션: 가게 삭제 시 메뉴도 자동 삭제

**예상 결과** (SHOW CREATE TABLE menus 일부):
```
CONSTRAINT `fk_menus_restaurant`
    FOREIGN KEY (`restaurant_id`)
    REFERENCES `restaurants` (`id`)
    ON DELETE CASCADE
```

**힌트**: `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ... REFERENCES ... ON DELETE CASCADE`

<details>
<summary>✅ 정답 보기</summary>

```sql
ALTER TABLE menus
ADD CONSTRAINT fk_menus_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(id)
ON DELETE CASCADE;
```

**해설**:
- `ALTER TABLE menus`: menus 테이블을 수정
- `ADD CONSTRAINT fk_menus_restaurant`: 제약조건 이름 지정 (추후 삭제/확인 시 사용)
- `FOREIGN KEY (restaurant_id)`: FK로 사용할 컬럼
- `REFERENCES restaurants(id)`: 참조할 부모 테이블과 컬럼
- `ON DELETE CASCADE`: 부모(restaurants) 행 삭제 시 자식(menus) 행도 자동 삭제

</details>

---

### 문제 2. 1NF 위반 찾기

> 신입 개발자가 "임시 주문 테이블"을 만들었습니다. 팀장이 "이 테이블은 정규화 규칙을 위반했어요. 어디가 문제인지 찾아서 고쳐주세요"라고 요청했습니다.

**문제의 테이블 구조 및 데이터**:

```
orders_temp 테이블:
┌──────┬─────────────┬─────────────────────────────┬─────────────┬───────────────────────┐
│ id   │ customer_id │ ordered_menus               │ total_price │ order_date            │
├──────┼─────────────┼─────────────────────────────┼─────────────┼───────────────────────┤
│ 1    │ 1           │ 후라이드치킨:1,감자튀김:2    │ 19000       │ 2024-03-01 12:00:00   │
│ 2    │ 2           │ 짜장면:1,탕수육:1,군만두:2   │ 22000       │ 2024-03-02 18:30:00   │
│ 3    │ 3           │ 마라탕:1                     │ 14000       │ 2024-03-03 19:00:00   │
└──────┴─────────────┴─────────────────────────────┴─────────────┴───────────────────────┘
```

다음 질문에 답하세요:
1. 1NF를 위반하는 컬럼은 무엇인가요?
2. 왜 위반인지 설명하세요.
3. 어떻게 해결해야 하는지 수정된 테이블 구조를 제시하세요.

<details>
<summary>✅ 정답 보기</summary>

**1. 1NF 위반 컬럼**: `ordered_menus`

**2. 위반 이유**:
`ordered_menus` 컬럼에 여러 개의 값(메뉴명:수량 쌍)이 쉼표로 구분되어 하나의 셀에 저장되어 있습니다.
1NF 규칙은 "각 셀(컬럼)은 하나의 값(원자값)만 가져야 한다"입니다.
- 특정 메뉴를 주문한 주문만 조회하려면? → `LIKE '%메뉴명%'` 로 비효율적 검색
- 수량을 수정하려면? → 문자열 파싱이 필요
- 각 메뉴의 가격을 menus 테이블과 JOIN하려면? → 사실상 불가능

**3. 해결 방법 — 행 분리 (order_items 테이블 생성)**:

```sql
-- orders 테이블 (주문 헤더)
CREATE TABLE orders (
    id          INT      NOT NULL AUTO_INCREMENT,
    customer_id INT      NOT NULL,
    total_price INT      NOT NULL,
    order_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- order_items 테이블 (주문 상세 — 1NF 만족)
CREATE TABLE order_items (
    id        INT NOT NULL AUTO_INCREMENT,
    order_id  INT NOT NULL,
    menu_id   INT NOT NULL,
    menu_name VARCHAR(100) NOT NULL,
    quantity  INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- 수정된 데이터:
-- order_items:
-- id | order_id | menu_name  | quantity
-- 1  | 1        | 후라이드치킨 | 1
-- 2  | 1        | 감자튀김    | 2
-- 3  | 2        | 짜장면      | 1
-- 4  | 2        | 탕수육      | 1
-- 5  | 2        | 군만두      | 2
-- 6  | 3        | 마라탕      | 1
```

</details>

---

### 문제 3. orders 테이블 FK 전체 작성

> 개발팀이 orders 테이블을 재설계하면서 FK 제약조건을 모두 추가해야 합니다.
> "orders 테이블은 customers, restaurants, menus 테이블을 참조합니다.
> 어떤 상황에서도 주문 내역은 지워지면 안 되므로, 부모 테이블의 행을 함부로 삭제할 수 없도록 설정해야 합니다."

**요구사항**:
- `customer_id`: customers.id 참조, 제약조건명 `fk_orders_customer`
- `restaurant_id`: restaurants.id 참조, 제약조건명 `fk_orders_restaurant`
- `menu_id`: menus.id 참조, 제약조건명 `fk_orders_menu`
- 세 FK 모두 부모 행 삭제를 막아야 합니다 (RESTRICT)

**예상 결과** (FK 목록 조회 시):
```
자식 테이블 | FK 컬럼        | 제약조건 이름          | 부모 테이블
orders      | customer_id   | fk_orders_customer    | customers
orders      | restaurant_id | fk_orders_restaurant  | restaurants
orders      | menu_id       | fk_orders_menu        | menus
```

<details>
<summary>✅ 정답 보기</summary>

```sql
-- customer_id FK
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE RESTRICT;

-- restaurant_id FK
ALTER TABLE orders
ADD CONSTRAINT fk_orders_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(id)
ON DELETE RESTRICT;

-- menu_id FK
ALTER TABLE orders
ADD CONSTRAINT fk_orders_menu
FOREIGN KEY (menu_id)
REFERENCES menus(id)
ON DELETE RESTRICT;
```

**해설**:
- 주문 내역은 고객이 탈퇴해도, 가게가 폐업해도, 메뉴가 삭제되어도 보존해야 하는 비즈니스 데이터입니다.
- ON DELETE RESTRICT 옵션은 주문이 있는 고객/가게/메뉴를 실수로 삭제하는 것을 방지합니다.
- 만약 고객을 삭제해야 한다면, 주문 내역을 먼저 처리(아카이빙 등)한 후에만 삭제할 수 있습니다.

**확인 쿼리**:
```sql
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'orders'
  AND REFERENCED_TABLE_NAME IS NOT NULL
  AND TABLE_SCHEMA = DATABASE();
```

</details>

---

## ⭐⭐ 응용 문제

---

### 문제 4. ON DELETE 옵션 선택

> 한입배달 서비스 기획팀에서 DB 정책을 정의해달라고 요청했습니다.
> 다음 세 가지 상황에서 각각 어떤 ON DELETE 옵션을 사용해야 하는지 이유와 함께 설명하고,
> 실제 FK를 추가하는 SQL도 작성하세요.

**상황 A**: 가게(restaurants)가 폐업하여 삭제될 때, 해당 가게의 메뉴(menus)는 어떻게 처리해야 할까요?

**상황 B**: 고객(customers)이 탈퇴할 때, 해당 고객의 주문(orders)은 어떻게 처리해야 할까요?
(단: 주문 내역은 정산, 배달 기록 등 비즈니스 상 보존이 필요합니다)

**상황 C**: 주문(orders)이 삭제될 때, 해당 주문의 리뷰(reviews)는 어떻게 처리해야 할까요?
(단: 주문 없는 리뷰는 의미가 없습니다)

<details>
<summary>✅ 정답 보기</summary>

#### 상황 A: restaurants → menus

**선택 옵션**: `ON DELETE CASCADE`

**이유**:
- 가게가 폐업하면 해당 가게의 메뉴는 더 이상 존재할 필요가 없습니다
- 메뉴는 가게 없이 독립적으로 존재할 수 없습니다 (어떤 가게의 메뉴인지 알 수 없음)
- 가게를 삭제할 때마다 메뉴를 먼저 지우는 번거로움을 없앨 수 있습니다

```sql
ALTER TABLE menus
ADD CONSTRAINT fk_menus_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(id)
ON DELETE CASCADE;  -- 가게 삭제 → 메뉴 자동 삭제
```

#### 상황 B: customers → orders

**선택 옵션**: `ON DELETE RESTRICT`

**이유**:
- 주문 내역은 가게 정산, 배달 기록, 분쟁 해결 등을 위해 고객 탈퇴 후에도 보존해야 합니다
- 고객을 삭제하면 안 된다는 것을 시스템이 강제로 막아줌으로써 실수를 방지합니다
- 실무에서는 고객 탈퇴 시 실제 삭제 대신 `is_deleted = 1` 같은 논리 삭제를 씁니다

```sql
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE RESTRICT;  -- 주문 있는 고객은 삭제 불가

-- (실무 참고) 고객 탈퇴 처리는 삭제 대신:
-- ALTER TABLE customers ADD COLUMN is_deleted TINYINT(1) DEFAULT 0;
-- UPDATE customers SET is_deleted = 1 WHERE id = ?;
```

#### 상황 C: orders → reviews

**선택 옵션**: `ON DELETE CASCADE`

**이유**:
- 리뷰는 반드시 특정 주문에 대한 평가이므로, 주문이 없으면 리뷰도 의미가 없습니다
- 주문이 삭제되면 해당 리뷰도 같이 삭제되는 것이 자연스럽습니다
- 단, orders에 ON DELETE RESTRICT가 있으므로 실제로 주문이 삭제되는 경우는 드물지만,
  혹시 삭제되더라도 리뷰도 같이 지워지는 것이 안전합니다

```sql
ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_order
FOREIGN KEY (order_id)
REFERENCES orders(id)
ON DELETE CASCADE;  -- 주문 삭제 → 리뷰 자동 삭제
```

#### 정리

| 상황 | FK | 옵션 | 이유 |
|------|-----|------|------|
| 가게 삭제 → 메뉴 | menus.restaurant_id | CASCADE | 부모 없는 자식은 의미 없음 |
| 고객 탈퇴 → 주문 | orders.customer_id | RESTRICT | 주문 내역 보존 필요 |
| 주문 삭제 → 리뷰 | reviews.order_id | CASCADE | 주문 없는 리뷰는 의미 없음 |

</details>

---

### 문제 5. 2NF 위반 분석 및 해결

> 데이터베이스 팀에서 다음 테이블 구조를 발견했습니다.
> "이 테이블이 2NF를 만족하지 않는다는 것 같은데, 왜 그런지 분석하고 올바르게 분리해주세요."

**문제의 테이블**:

```
order_details 테이블 (PK는 복합키: order_id + menu_id):

┌──────────┬─────────┬───────────────┬────────┬──────────┬───────────────┬────────────────┐
│ order_id │ menu_id │ menu_name     │ price  │ quantity │ customer_name │ order_date     │
│ (PK)     │ (PK)    │               │        │          │               │                │
├──────────┼─────────┼───────────────┼────────┼──────────┼───────────────┼────────────────┤
│ 1        │ 1       │ 후라이드치킨   │ 15000  │ 2        │ 김민준        │ 2024-03-01     │
│ 1        │ 3       │ 감자튀김       │ 3000   │ 3        │ 김민준        │ 2024-03-01     │
│ 2        │ 2       │ 양념치킨       │ 16000  │ 1        │ 이수진        │ 2024-03-05     │
│ 3        │ 5       │ 짜장면         │ 8000   │ 2        │ 박지호        │ 2024-03-07     │
└──────────┴─────────┴───────────────┴────────┴──────────┴───────────────┴────────────────┘
```

1. 이 테이블에서 부분 함수 종속이 발생하는 컬럼을 모두 찾으세요.
2. 어떻게 테이블을 분리해야 하는지 설명하고, 분리된 테이블 구조를 작성하세요.

<details>
<summary>✅ 정답 보기</summary>

**1. 부분 함수 종속 분석**

이 테이블의 복합 PK는 `(order_id, menu_id)`다.

각 컬럼의 종속 관계를 분석하면:

| 컬럼 | 종속 대상 | 종류 |
|------|----------|------|
| `quantity` | `(order_id, menu_id)` 모두 | 완전 함수 종속 ✅ |
| `menu_name` | `menu_id`에만 종속 | **부분 함수 종속** ❌ |
| `price` | `menu_id`에만 종속 | **부분 함수 종속** ❌ |
| `customer_name` | `order_id`에만 종속 | **부분 함수 종속** ❌ |
| `order_date` | `order_id`에만 종속 | **부분 함수 종속** ❌ |

**2. 테이블 분리 (2NF 적용)**

```sql
-- ① orders 테이블 (order_id에만 종속되는 컬럼)
-- customer_name은 사실 customer_id FK로 처리해야 하므로 customer_id로 대체
CREATE TABLE orders (
    id          INT      NOT NULL AUTO_INCREMENT,
    customer_id INT      NOT NULL,
    order_date  DATE     NOT NULL,
    PRIMARY KEY (id)
    -- FK는 별도로 추가
);

-- orders 데이터:
-- id | customer_id | order_date
-- 1  | 1           | 2024-03-01  (김민준 → customer_id=1)
-- 2  | 2           | 2024-03-05  (이수진 → customer_id=2)
-- 3  | 3           | 2024-03-07  (박지호 → customer_id=3)

-- ② menus 테이블 (menu_id에만 종속되는 컬럼)
CREATE TABLE menus (
    id        INT          NOT NULL AUTO_INCREMENT,
    menu_name VARCHAR(100) NOT NULL,
    price     INT          NOT NULL,
    PRIMARY KEY (id)
);

-- menus 데이터:
-- id | menu_name   | price
-- 1  | 후라이드치킨 | 15000
-- 2  | 양념치킨     | 16000
-- 3  | 감자튀김     | 3000
-- 5  | 짜장면       | 8000

-- ③ order_items 테이블 (복합 PK에 완전 함수 종속되는 컬럼만)
CREATE TABLE order_items (
    id       INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    menu_id  INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (menu_id)  REFERENCES menus(id)  ON DELETE RESTRICT
);

-- order_items 데이터:
-- id | order_id | menu_id | quantity
-- 1  | 1        | 1       | 2
-- 2  | 1        | 3       | 3
-- 3  | 2        | 2       | 1
-- 4  | 3        | 5       | 2
```

**핵심 포인트**:
- 원래 하나의 테이블이 3개로 분리되었다
- 이제 menu_name이나 price가 변경되면 menus 테이블 1곳만 수정하면 된다
- 갱신 이상이 해결되었다

</details>

---

### 문제 6. LEFT JOIN + IFNULL — 고객별 평균 평점 조회

> 마케팅팀에서 "고객별로 리뷰를 몇 개 남겼고 평균 평점은 어떻게 되는지 알고 싶습니다.
> 리뷰를 한 번도 쓰지 않은 고객도 목록에 포함해주세요. 이 고객들의 평균 평점은 0으로 표시해주세요."

**요구사항**:
- 모든 고객(customers)을 기준으로 조회 (리뷰 없는 고객 포함)
- 출력 컬럼: 고객명, 리뷰 수, 평균 평점 (소수점 1자리)
- 리뷰가 없는 고객의 평균 평점은 0으로 표시
- 평균 평점 높은 순으로 정렬, 같으면 리뷰 수 많은 순

**예상 결과**:
```
고객명   | 리뷰수 | 평균평점
김민준   | 5     | 4.6
이수진   | 3     | 4.3
박지호   | 2     | 4.0
최현우   | 0     | 0.0     ← 리뷰 없는 고객
강서연   | 0     | 0.0
```

**힌트**: `LEFT JOIN`, `COUNT`, `AVG`, `IFNULL`, `ROUND`, `GROUP BY`, `ORDER BY`

<details>
<summary>✅ 정답 보기</summary>

```sql
SELECT
    c.name                              AS 고객명,
    COUNT(r.id)                         AS 리뷰수,
    ROUND(IFNULL(AVG(r.rating), 0), 1) AS 평균평점
FROM customers c
LEFT JOIN reviews r ON c.id = r.customer_id
GROUP BY c.id, c.name
ORDER BY 평균평점 DESC, 리뷰수 DESC;
```

**해설**:
1. `FROM customers c` → customers가 기준 테이블 (모든 고객 포함)
2. `LEFT JOIN reviews r ON c.id = r.customer_id`
   → 리뷰 없는 고객도 포함 (reviews.customer_id가 NULL인 행으로 결합)
3. `COUNT(r.id)` → r.id가 NULL인 경우(리뷰 없는 고객)는 0으로 카운트
4. `IFNULL(AVG(r.rating), 0)` → AVG는 값이 없으면 NULL 반환 → IFNULL로 0 처리
5. `ROUND(..., 1)` → 소수점 1자리 반올림
6. `GROUP BY c.id, c.name` → 고객별 집계
7. `ORDER BY 평균평점 DESC, 리뷰수 DESC` → 평점 높은 순, 같으면 리뷰 수 많은 순

**주의사항**:
- `COUNT(*)` 대신 `COUNT(r.id)`를 사용해야 한다. `COUNT(*)`는 NULL도 세지만, `COUNT(r.id)`는 r.id가 NULL인 행을 세지 않는다.
- `AVG(r.rating)`은 리뷰가 없는 고객의 경우 NULL을 반환하므로 반드시 IFNULL 처리가 필요하다.

</details>

---

## ⭐⭐⭐ 도전 문제

---

### 문제 7. 쿠폰별 발급/사용 통계 조회

> 마케팅팀에서 쿠폰 효과를 분석하려고 합니다.
> "쿠폰별로 총 발급 수, 총 사용 수, 사용률(%)을 알고 싶습니다.
> 쿠폰명도 같이 표시해주세요. 사용률이 높은 순으로 정렬해 주세요."

**요구사항**:
- `coupons` 테이블과 `customer_coupons` 테이블을 JOIN
- 출력 컬럼: 쿠폰명, 발급수, 사용수, 사용률(%)
- 사용률 = (사용수 / 발급수) × 100
- 사용률은 소수점 2자리까지 표시 (`ROUND`)
- 발급된 적 없는 쿠폰도 포함 (발급수=0, 사용수=0, 사용률=0)
- 사용률 높은 순 정렬, 같으면 발급수 많은 순

**예상 결과**:
```
쿠폰명         | 발급수 | 사용수 | 사용률(%)
첫주문 할인쿠폰  | 8     | 7     | 87.50
치킨배달 쿠폰   | 10    | 6     | 60.00
배달비 무료쿠폰  | 5     | 2     | 40.00
신규가입 쿠폰   | 0     | 0     | 0.00
```

**힌트**:
- `LEFT JOIN` 방향 주의 (발급 0인 쿠폰도 포함해야 함)
- `SUM(cc.is_used)` 로 사용 수 집계 가능
- 발급수가 0인 경우 나눗셈 오류 방지 → `NULLIF(발급수, 0)` 또는 `IF(발급수 = 0, 0, ...)`

<details>
<summary>✅ 정답 보기</summary>

```sql
SELECT
    co.coupon_name                                          AS 쿠폰명,
    COUNT(cc.id)                                            AS 발급수,
    SUM(IFNULL(cc.is_used, 0))                             AS 사용수,
    ROUND(
        IF(COUNT(cc.id) = 0,
           0,
           SUM(IFNULL(cc.is_used, 0)) / COUNT(cc.id) * 100
        ), 2
    )                                                       AS '사용률(%)'
FROM coupons co
LEFT JOIN customer_coupons cc ON co.id = cc.coupon_id
GROUP BY co.id, co.coupon_name
ORDER BY `사용률(%)` DESC, 발급수 DESC;
```

**또는 NULLIF를 활용한 버전**:

```sql
SELECT
    co.coupon_name                                              AS 쿠폰명,
    COUNT(cc.id)                                                AS 발급수,
    IFNULL(SUM(cc.is_used), 0)                                 AS 사용수,
    ROUND(
        IFNULL(SUM(cc.is_used), 0) / NULLIF(COUNT(cc.id), 0) * 100,
        2
    )                                                           AS '사용률(%)'
FROM coupons co
LEFT JOIN customer_coupons cc ON co.id = cc.coupon_id
GROUP BY co.id, co.coupon_name
ORDER BY `사용률(%)` DESC, 발급수 DESC;
```

**해설**:
1. `FROM coupons co` + `LEFT JOIN customer_coupons cc`
   → coupons가 기준 (발급 0인 쿠폰도 포함)
2. `COUNT(cc.id)` → cc.id가 NULL인 경우(발급 없음)는 0으로 카운트 → 발급수
3. `SUM(IFNULL(cc.is_used, 0))` → is_used가 NULL(발급 없음)이면 0으로 처리 후 합산 → 사용수
4. `NULLIF(COUNT(cc.id), 0)` → 발급수가 0이면 NULL 반환 → 0으로 나누는 것 방지
5. `IF(COUNT(cc.id) = 0, 0, ...)` → 발급수가 0이면 사용률도 0

**is_used 컬럼이 TINYINT(1) 타입**이라 SUM으로 합산하면 1인 행의 개수가 나온다.

</details>

---

### 문제 8. 비정규 테이블 → 3NF 정규화

> 개발팀이 레거시 시스템에서 데이터를 가져왔습니다. 다음 비정규 테이블을 3NF까지 정규화해야 합니다.
> 각 단계(비정규 → 1NF → 2NF → 3NF)를 설명하고, 최종 테이블들의 CREATE TABLE SQL을 작성하세요.

**비정규 테이블** `order_details_raw`:

```
order_details_raw:
┌──────────┬─────────────┬───────────────┬──────────────┬───────────────────┬───────────────┬──────────────────┬─────────────────────┬──────────────────┬──────────┐
│ order_id │ customer_id │ customer_name │ customer_    │ restaurant_id     │ restaurant_   │ restaurant_      │ menu_id             │ menu_name        │ quantity │
│          │             │               │ phone        │                   │ name          │ category         │                     │                  │          │
├──────────┼─────────────┼───────────────┼──────────────┼───────────────────┼───────────────┼──────────────────┼─────────────────────┼──────────────────┼──────────┤
│ 1        │ 1           │ 김민준        │ 010-1111-    │ 1                 │ 부산치킨      │ 치킨             │ 1,2,3              │ 후라이드,양념,뿌링│ 2,1,1    │
│          │             │               │ 2222         │                   │               │                  │                     │                  │          │
│ 2        │ 1           │ 김민준        │ 010-1111-    │ 2                 │ 해운대짜장    │ 중식             │ 4                   │ 짜장면           │ 2        │
│          │             │               │ 2222         │                   │               │                  │                     │                  │          │
│ 3        │ 2           │ 이수진        │ 010-3333-    │ 1                 │ 부산치킨      │ 치킨             │ 2                   │ 양념치킨         │ 1        │
│          │             │               │ 4444         │                   │               │                  │                     │                  │          │
└──────────┴─────────────┴───────────────┴──────────────┴───────────────────┴───────────────┴──────────────────┴─────────────────────┴──────────────────┴──────────┘

주의: order_id=1의 menu_id, menu_name, quantity 컬럼에 쉼표로 구분된 여러 값이 있음
```

**요구사항**:
1. 비정규 상태의 문제점을 설명하세요
2. 1NF로 변환하고 무엇이 달라졌는지 설명하세요
3. 2NF로 변환하고 무엇이 달라졌는지 설명하세요
4. 3NF로 변환하고 무엇이 달라졌는지 설명하세요
5. 최종 테이블들의 CREATE TABLE SQL을 작성하세요 (FK 포함)

<details>
<summary>✅ 정답 보기</summary>

---

#### 1단계: 비정규 상태 문제점 분석

```
비정규 문제:
① menu_id, menu_name, quantity 컬럼에 여러 값이 쉼표로 구분 → 1NF 위반
② customer_name, customer_phone이 orders마다 중복 저장 → 갱신 이상 가능
③ restaurant_name, restaurant_category가 중복 저장 → 갱신 이상 가능
④ 가게 정보만 넣으려면 주문도 같이 만들어야 함 → 삽입 이상
```

---

#### 2단계: 1NF 적용

**변환 방법**: 쉼표로 구분된 menu_id/menu_name/quantity를 행으로 분리

```
1NF 적용 후 (order_details_1nf):
order_id | customer_id | customer_name | customer_phone | restaurant_id | restaurant_name | restaurant_category | menu_id | menu_name | quantity
1        | 1           | 김민준        | 010-1111-2222  | 1             | 부산치킨        | 치킨                | 1       | 후라이드   | 2
1        | 1           | 김민준        | 010-1111-2222  | 1             | 부산치킨        | 치킨                | 2       | 양념치킨   | 1
1        | 1           | 김민준        | 010-1111-2222  | 1             | 부산치킨        | 치킨                | 3       | 뿌링클     | 1
2        | 1           | 김민준        | 010-1111-2222  | 2             | 해운대짜장      | 중식                | 4       | 짜장면     | 2
3        | 2           | 이수진        | 010-3333-4444  | 1             | 부산치킨        | 치킨                | 2       | 양념치킨   | 1

PK: (order_id, menu_id)
변화: 복합키 PK 확립, 멀티값 컬럼 제거 → 1NF 만족
```

---

#### 3단계: 2NF 적용

**분석**: PK가 `(order_id, menu_id)`인데 부분 함수 종속 확인

```
부분 함수 종속 발견:
- customer_id, customer_name, customer_phone, restaurant_id,
  restaurant_name, restaurant_category → order_id에만 종속 (부분 종속!)
- menu_name → menu_id에만 종속 (부분 종속!)
- quantity → (order_id, menu_id) 모두에 종속 (완전 종속 ✅)
```

**변환 방법**: 부분 종속 컬럼들을 별도 테이블로 분리

```
2NF 적용 후:

orders_2nf (order_id에 종속):
order_id | customer_id | restaurant_id
1        | 1           | 1
2        | 1           | 2
3        | 2           | 1

customers_2nf (customer_id에 종속):
customer_id | customer_name | customer_phone
1           | 김민준        | 010-1111-2222
2           | 이수진        | 010-3333-4444

restaurants_2nf (restaurant_id에 종속):
restaurant_id | restaurant_name | restaurant_category
1             | 부산치킨        | 치킨
2             | 해운대짜장      | 중식

menus_2nf (menu_id에 종속):
menu_id | menu_name
1       | 후라이드
2       | 양념치킨
3       | 뿌링클
4       | 짜장면

order_items_2nf ((order_id, menu_id) 모두에 종속):
order_id | menu_id | quantity
1        | 1       | 2
1        | 2       | 1
1        | 3       | 1
2        | 4       | 2
3        | 2       | 1
```

---

#### 4단계: 3NF 적용

**분석**: 2NF 후 이행 함수 종속 확인

```
이행 함수 종속 확인:
- restaurants_2nf 테이블:
  restaurant_id → restaurant_name → restaurant_category?
  → restaurant_category는 restaurant_id에 직접 종속 (같은 가게가 여러 카테고리 없음)
  → 이 경우는 restaurant_id → (restaurant_name, restaurant_category) 이므로 3NF 만족

- menus_2nf 테이블:
  menu_id → menu_name (이미 분리 완료, 문제없음)

⇒ 2NF 결과가 이미 3NF를 만족!

* 만약 restaurant_category 테이블이 따로 있고
  restaurant_category_id → category_name 관계라면 이행 종속 발생.
  예:
  restaurants: restaurant_id → category_id → category_name (이행 종속!)
  이 경우: categories 테이블 분리 필요
```

---

#### 5단계: 최종 CREATE TABLE SQL (3NF 완성)

```sql
-- ① customers
CREATE TABLE customers (
    id    INT          NOT NULL AUTO_INCREMENT,
    name  VARCHAR(50)  NOT NULL,
    phone VARCHAR(20)  UNIQUE,
    PRIMARY KEY (id)
);

-- ② restaurants
CREATE TABLE restaurants (
    id       INT          NOT NULL AUTO_INCREMENT,
    name     VARCHAR(100) NOT NULL,
    category VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id)
);

-- ③ menus (restaurant_id FK 포함 — 어느 가게 메뉴인지 필요)
CREATE TABLE menus (
    id            INT          NOT NULL AUTO_INCREMENT,
    restaurant_id INT          NOT NULL,
    menu_name     VARCHAR(100) NOT NULL,
    price         INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    CONSTRAINT fk_menus_rest
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(id)
        ON DELETE CASCADE
);

-- ④ orders (주문 헤더)
CREATE TABLE orders (
    id            INT      NOT NULL AUTO_INCREMENT,
    customer_id   INT      NOT NULL,
    restaurant_id INT      NOT NULL,
    order_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_orders_cust
        FOREIGN KEY (customer_id)   REFERENCES customers(id)    ON DELETE RESTRICT,
    CONSTRAINT fk_orders_rest
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)  ON DELETE RESTRICT
);

-- ⑤ order_items (주문 상세, M:N 구현)
CREATE TABLE order_items (
    id       INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    menu_id  INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_oi_menu
        FOREIGN KEY (menu_id)  REFERENCES menus(id)  ON DELETE RESTRICT
);
```

**최종 관계**:
```
customers (1) ──► orders (N) ◄── (1) restaurants
                    │
                    └──► order_items (N) ◄── (1) menus
```

**달라진 점 요약**:
| 단계 | 변환 내용 |
|------|----------|
| 비정규 → 1NF | 멀티값 컬럼(menu_id, menu_name, quantity) 행 분리 |
| 1NF → 2NF | 부분 함수 종속 컬럼을 customers, restaurants, menus, order_items로 분리 |
| 2NF → 3NF | 이미 3NF 만족 (이행 종속 없음) |

</details>

---

## 💎 보너스 문제

---

### 보너스 문제 1. 온라인 서점 DB ERD 설계

> 팀 프로젝트 설계 과제입니다.
> 다음 요구사항을 바탕으로 "온라인 서점" DB의 ERD를 텍스트로 설계하고,
> CREATE TABLE SQL을 FK 포함하여 작성하세요.

**요구사항**:
- 최소 5개 테이블 포함: `books`, `authors`, `customers`, `orders`, `order_items`
- 각 테이블은 PK(AI), 최소 3개 이상의 컬럼 보유
- 테이블 간 FK 관계를 모두 정의
- 책 1권은 여러 저자가 공동 집필할 수 있고, 저자 1명이 여러 책을 쓸 수 있음 (M:N)
- 하나의 주문에 여러 책이 포함될 수 있음 (M:N)
- ON DELETE 옵션을 각 관계에 맞게 설정하고 이유 설명

**힌트**:
- books ↔ authors: M:N → `book_authors` 중간 테이블 필요
- orders ↔ books: M:N → `order_items` 중간 테이블 사용

<details>
<summary>✅ 정답 예시 보기</summary>

#### 텍스트 ERD

```
┌─────────────┐           ┌──────────────────────┐
│   authors   │           │       books          │
├─────────────┤  M     N  ├──────────────────────┤
│ PK id       │◄─────────►│ PK id                │
│    name     │           │    title             │
│    email    │           │    isbn              │
│    bio      │  [book_authors 중간 테이블]        │
└─────────────┘           │    price             │
                          │    stock             │
                          └──────────┬───────────┘
                                     │ 1
                                     │ N
┌─────────────┐           ┌──────────▼───────────┐
│  customers  │           │     order_items      │
├─────────────┤  N     1  ├──────────────────────┤
│ PK id       │◄──────────┤ FK order_id          │
│    name     │           │ FK book_id           │
│    email    │           │    quantity          │
│    address  │  1     N  │    unit_price        │
└──────┬──────┘  ◄────────┴──────────────────────┘
       │                            ▲
       │ 1                          │ N
       ▼ N                          │ 1
┌──────────────┐           ┌────────┴─────────────┐
│   orders     │───────────►     book_authors     │
├──────────────┤           ├──────────────────────┤
│ PK id        │           │ PK id                │
│ FK customer_id│          │ FK book_id           │
│    order_date│           │ FK author_id         │
│    total_    │           │    role              │
│    price     │           └──────────────────────┘
│    status    │
└──────────────┘
```

#### CREATE TABLE SQL

```sql
-- ① authors
CREATE TABLE authors (
    id    INT          NOT NULL AUTO_INCREMENT,
    name  VARCHAR(100) NOT NULL,
    email VARCHAR(200) UNIQUE,
    bio   TEXT,
    PRIMARY KEY (id)
);

-- ② books
CREATE TABLE books (
    id    INT           NOT NULL AUTO_INCREMENT,
    title VARCHAR(200)  NOT NULL,
    isbn  VARCHAR(20)   UNIQUE NOT NULL,
    price INT           NOT NULL,
    stock INT           DEFAULT 0,
    PRIMARY KEY (id)
);

-- ③ book_authors (books ↔ authors M:N 중간 테이블)
CREATE TABLE book_authors (
    id        INT         NOT NULL AUTO_INCREMENT,
    book_id   INT         NOT NULL,
    author_id INT         NOT NULL,
    role      VARCHAR(50) DEFAULT '저자',  -- 저자, 역자, 편집 등
    PRIMARY KEY (id),
    CONSTRAINT fk_ba_book
        FOREIGN KEY (book_id)   REFERENCES books(id)   ON DELETE CASCADE,
        -- 책 삭제 시 저자 연결도 삭제 (책 없는 book_authors는 의미 없음)
    CONSTRAINT fk_ba_author
        FOREIGN KEY (author_id) REFERENCES authors(id) ON DELETE RESTRICT
        -- 책이 있는 저자는 함부로 삭제 불가
);

-- ④ customers
CREATE TABLE customers (
    id      INT          NOT NULL AUTO_INCREMENT,
    name    VARCHAR(50)  NOT NULL,
    email   VARCHAR(200) UNIQUE NOT NULL,
    address VARCHAR(300),
    PRIMARY KEY (id)
);

-- ⑤ orders
CREATE TABLE orders (
    id          INT      NOT NULL AUTO_INCREMENT,
    customer_id INT      NOT NULL,
    order_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_price INT      NOT NULL DEFAULT 0,
    status      VARCHAR(20) DEFAULT '주문완료',
    PRIMARY KEY (id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE RESTRICT
        -- 주문 있는 고객은 삭제 불가 (구매 이력 보존)
);

-- ⑥ order_items (orders ↔ books M:N 중간 테이블)
CREATE TABLE order_items (
    id         INT NOT NULL AUTO_INCREMENT,
    order_id   INT NOT NULL,
    book_id    INT NOT NULL,
    quantity   INT NOT NULL DEFAULT 1,
    unit_price INT NOT NULL,  -- 구매 시점 가격 (반정규화: 나중에 책 가격 변경되어도 기록)
    PRIMARY KEY (id),
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        -- 주문 삭제 시 주문 항목도 삭제
    CONSTRAINT fk_oi_book
        FOREIGN KEY (book_id)  REFERENCES books(id)  ON DELETE RESTRICT
        -- 주문된 책은 삭제 불가
);
```

**포인트**: `unit_price`는 반정규화 예시다. books.price가 나중에 바뀌어도 구매 당시 금액을 보존하기 위해 의도적으로 중복 저장한다.

</details>

---

### 보너스 문제 2. information_schema FK 조회

> 시스템 운영팀에서 현재 DB에 어떤 FK 관계가 있는지 전체 목록을 뽑아달라고 합니다.
> `information_schema`를 활용하여 현재 DB(`hanip_delivery`)의 모든 FK 관계를 조회하는 쿼리를 작성하세요.

**요구사항**:
- 출력 컬럼: 자식 테이블, FK 컬럼, 제약조건 이름, 부모 테이블, 참조 컬럼
- 현재 DB(`hanip_delivery`)에 속한 FK만 조회
- 자식 테이블명 → FK 컬럼명 순으로 정렬

**예상 결과**:
```
자식 테이블          | FK 컬럼        | 제약조건 이름            | 부모 테이블  | 참조 컬럼
customer_coupons    | coupon_id     | fk_cc_coupon            | coupons      | id
customer_coupons    | customer_id   | fk_cc_customer          | customers    | id
menus               | restaurant_id | fk_menus_restaurant     | restaurants  | id
orders              | customer_id   | fk_orders_customer      | customers    | id
orders              | menu_id       | fk_orders_menu          | menus        | id
orders              | restaurant_id | fk_orders_restaurant    | restaurants  | id
orders              | rider_id      | fk_orders_rider         | riders       | id
reviews             | customer_id   | fk_reviews_customer     | customers    | id
reviews             | order_id      | fk_reviews_order        | orders       | id
```

**힌트**: `information_schema.KEY_COLUMN_USAGE` 테이블 사용

<details>
<summary>✅ 정답 보기</summary>

```sql
SELECT
    kcu.TABLE_NAME             AS '자식 테이블',
    kcu.COLUMN_NAME            AS 'FK 컬럼',
    kcu.CONSTRAINT_NAME        AS '제약조건 이름',
    kcu.REFERENCED_TABLE_NAME  AS '부모 테이블',
    kcu.REFERENCED_COLUMN_NAME AS '참조 컬럼'
FROM
    information_schema.KEY_COLUMN_USAGE kcu
WHERE
    kcu.REFERENCED_TABLE_NAME IS NOT NULL   -- FK인 것만 (PK, UNIQUE는 NULL)
    AND kcu.TABLE_SCHEMA = 'hanip_delivery'  -- 현재 DB 필터
ORDER BY
    kcu.TABLE_NAME,
    kcu.COLUMN_NAME;
```

**또는 `DATABASE()` 함수 활용 (현재 USE 중인 DB 기준)**:

```sql
SELECT
    kcu.TABLE_NAME             AS '자식 테이블',
    kcu.COLUMN_NAME            AS 'FK 컬럼',
    kcu.CONSTRAINT_NAME        AS '제약조건 이름',
    kcu.REFERENCED_TABLE_NAME  AS '부모 테이블',
    kcu.REFERENCED_COLUMN_NAME AS '참조 컬럼'
FROM
    information_schema.KEY_COLUMN_USAGE kcu
INNER JOIN
    information_schema.TABLE_CONSTRAINTS tc
    ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
    AND kcu.TABLE_SCHEMA = tc.TABLE_SCHEMA
    AND kcu.TABLE_NAME = tc.TABLE_NAME
WHERE
    tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
    AND kcu.TABLE_SCHEMA = DATABASE()
ORDER BY
    kcu.TABLE_NAME,
    kcu.COLUMN_NAME;
```

**해설**:
- `information_schema.KEY_COLUMN_USAGE`: 모든 키(PK, FK, UNIQUE) 정보를 담은 시스템 테이블
- `REFERENCED_TABLE_NAME IS NOT NULL`: FK인 경우에만 참조 테이블이 존재
- `TABLE_SCHEMA = DATABASE()`: 현재 선택된 DB의 테이블만 필터링
- 두 번째 쿼리는 `TABLE_CONSTRAINTS` 테이블과 JOIN하여 `CONSTRAINT_TYPE = 'FOREIGN KEY'`로 명시적 필터링

**추가 유용한 조회**:
```sql
-- CASCADE/SET NULL/RESTRICT 옵션도 함께 확인
SELECT
    rc.TABLE_NAME              AS '자식 테이블',
    rc.CONSTRAINT_NAME         AS '제약조건 이름',
    rc.DELETE_RULE             AS 'ON DELETE 옵션',
    rc.UPDATE_RULE             AS 'ON UPDATE 옵션'
FROM
    information_schema.REFERENTIAL_CONSTRAINTS rc
WHERE
    rc.CONSTRAINT_SCHEMA = DATABASE()
ORDER BY
    rc.TABLE_NAME;
```

</details>

---

## 오늘의 핵심 정리

| 문제 | 핵심 개념 | 확인 포인트 |
|------|----------|------------|
| 1 | ALTER TABLE + FK 추가 | ON DELETE CASCADE 사용 시점 |
| 2 | 1NF 위반 인식 | 하나의 셀에 여러 값이 있는지 확인 |
| 3 | orders FK 3개 | ON DELETE RESTRICT로 주문 보호 |
| 4 | ON DELETE 옵션 선택 | 비즈니스 요구사항 → 옵션 매핑 |
| 5 | 2NF 위반 분석 | 복합 PK에서 부분 함수 종속 찾기 |
| 6 | LEFT JOIN + IFNULL | 리뷰 없는 고객도 포함 |
| 7 | 쿠폰 통계 | SUM + COUNT + 나눗셈 주의 |
| 8 | 3단계 정규화 | 비정규 → 1NF → 2NF → 3NF |
| B1 | ERD 직접 설계 | M:N 중간 테이블, ON DELETE 이유 |
| B2 | information_schema | FK 전체 목록 시스템 조회 |

> **Day 10 미리보기**: 내일은 오늘까지 배운 모든 내용(ERD + FK + 정규화 + JOIN + 집계 + 서브쿼리 + 뷰 + 트랜잭션 + 인덱스)을 한 번에 사용하는 미니 프로젝트를 진행합니다!
