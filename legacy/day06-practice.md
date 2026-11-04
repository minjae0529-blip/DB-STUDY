# Day 6 실습 문제 — JOIN: 흩어진 퍼즐 맞추기

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

## ⭐ 기초 문제 (INNER JOIN 2테이블)

---

### 문제 1. ⭐ — 주문 목록에 가게 이름 붙이기

> 운영팀이 "주문 ID, 가게 이름, 주문금액, 주문일시"를 함께 보여 달라고 요청했습니다.
> `orders` 테이블에는 `restaurant_id`(숫자)만 있으므로 `restaurants` 테이블과 JOIN하세요.
> 주문일시 기준 최신순으로 정렬하고, 상위 10건만 출력합니다.

**사용 테이블:** `orders`, `restaurants`

**예상 결과:**

| 주문번호 | 가게이름 | 주문금액 | 주문일시 |
|:---:|---|---:|---|
| 48 | 부산치킨 | 37000 | 2024-03-15 19:22:00 |
| 47 | 명동칼국수 | 12000 | 2024-03-14 12:05:00 |
| 46 | 해운대피자 | 23000 | 2024-03-13 18:44:00 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    o.id          AS 주문번호,
    r.name        AS 가게이름,
    o.total_price AS 주문금액,
    o.order_date  AS 주문일시
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
ORDER BY o.order_date DESC
LIMIT 10;
```

</details>

---

### 문제 2. ⭐ — 주문 목록에 고객 이름 붙이기

> 배달팀이 "주문 ID, 고객 이름, 연락처, 배달 상태"가 포함된 배달 목록이 필요하다고 했습니다.
> `orders`와 `customers` 테이블을 JOIN하여 출력하세요.
> 주문번호 오름차순으로 정렬합니다.

**사용 테이블:** `orders`, `customers`

**예상 결과:**

| 주문번호 | 고객이름 | 연락처 | 배달상태 |
|:---:|---|---|---|
| 1 | 김민준 | 010-1234-5678 | 배달완료 |
| 2 | 이서연 | 010-9876-5432 | 배달완료 |
| 3 | 김민준 | 010-1234-5678 | 배달완료 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    o.id     AS 주문번호,
    c.name   AS 고객이름,
    c.phone  AS 연락처,
    o.status AS 배달상태
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
ORDER BY o.id;
```

</details>

---

### 문제 3. ⭐ — 메뉴 목록에 가게 이름 붙이기

> 메뉴 관리팀이 "메뉴명, 가게 이름, 카테고리, 가격"을 한눈에 볼 수 있는 목록을 요청했습니다.
> `menus`와 `restaurants` 테이블을 JOIN하세요.
> 카테고리 오름차순, 가격 내림차순으로 정렬합니다.

**사용 테이블:** `menus`, `restaurants`

**예상 결과:**

| 메뉴명 | 가게이름 | 카테고리 | 가격 |
|---|---|---|---:|
| 양념치킨 | 부산치킨 | 치킨 | 19000 |
| 후라이드치킨 | 부산치킨 | 치킨 | 18000 |
| 콤보피자 | 해운대피자 | 피자 | 24000 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    m.menu_name AS 메뉴명,
    r.name      AS 가게이름,
    r.category  AS 카테고리,
    m.price     AS 가격
FROM menus AS m
    INNER JOIN restaurants AS r ON m.restaurant_id = r.id
ORDER BY r.category ASC, m.price DESC;
```

</details>

---

### 문제 4. ⭐ — 특정 카테고리 가게의 주문만 보기

> 운영팀이 "한식 카테고리 가게에서 발생한 주문 ID, 가게 이름, 주문금액"을 뽑아 달라고 했습니다.
> INNER JOIN 후 WHERE로 카테고리를 필터링하세요.
> 주문금액 내림차순으로 정렬합니다.

**사용 테이블:** `orders`, `restaurants`

**예상 결과:**

| 주문번호 | 가게이름 | 주문금액 |
|:---:|---|---:|
| 15 | 명동칼국수 | 24000 |
| 22 | 해운대설렁탕 | 22000 |
| 7 | 명동칼국수 | 18000 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    o.id          AS 주문번호,
    r.name        AS 가게이름,
    o.total_price AS 주문금액
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
WHERE r.category = '한식'
ORDER BY o.total_price DESC;
```

</details>

---

## ⭐⭐ 응용 문제 (LEFT JOIN / 3테이블 JOIN / JOIN + WHERE)

---

### 문제 5. ⭐⭐ — 주문 없는 고객 찾기

> 마케팅팀이 "지금까지 한 번도 주문하지 않은 고객의 이름, 연락처, 이메일을 알려달라"고 했습니다.
> 웰컴 쿠폰을 보내서 첫 주문을 유도할 계획입니다.
> LEFT JOIN과 `WHERE IS NULL`을 활용하세요.

**사용 테이블:** `customers`, `orders`

**힌트:** LEFT JOIN 후 orders 쪽이 NULL인 행을 필터링하면 됩니다.

**예상 결과:**

| 고객번호 | 고객이름 | 연락처 | 이메일 |
|:---:|---|---|---|
| 9 | 최태양 | 010-3333-4444 | taesun@email.com |
| 10 | 강나래 | 010-5678-9012 | nara@email.com |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    c.id    AS 고객번호,
    c.name  AS 고객이름,
    c.phone AS 연락처,
    c.email AS 이메일
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
WHERE o.id IS NULL
ORDER BY c.id;
```

</details>

---

### 문제 6. ⭐⭐ — 모든 고객과 주문 건수 조회 (주문 없는 고객 포함)

> 분석팀이 "모든 고객의 이름과 총 주문 건수를 보고 싶다. 주문이 없는 고객은 0으로 표시해 달라"고 요청했습니다.
> `COUNT`와 LEFT JOIN을 조합하세요. 주문건수 내림차순으로 정렬합니다.

**사용 테이블:** `customers`, `orders`

**힌트:** COUNT(o.id)는 o.id가 NULL이면 0으로 계산됩니다.

**예상 결과:**

| 고객이름 | 주문건수 |
|---|:---:|
| 김민준 | 12 |
| 이서연 | 9 |
| 박지훈 | 7 |
| ... | ... |
| 최태양 | 0 |
| 강나래 | 0 |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    c.name       AS 고객이름,
    COUNT(o.id)  AS 주문건수
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
GROUP BY c.id, c.name
ORDER BY 주문건수 DESC;
```

</details>

---

### 문제 7. ⭐⭐ — 3테이블 JOIN: 주문번호, 고객명, 가게명

> 고객센터가 "주문 ID, 고객 이름, 가게 이름, 주문금액, 주문일시"를 한 번에 보여 달라고 했습니다.
> orders, restaurants, customers 세 테이블을 JOIN하세요.
> 주문일시 최신순으로 정렬하고 상위 15건만 출력합니다.

**사용 테이블:** `orders`, `restaurants`, `customers`

**예상 결과:**

| 주문번호 | 고객이름 | 가게이름 | 주문금액 | 주문일시 |
|:---:|---|---|---:|---|
| 48 | 이서연 | 부산치킨 | 37000 | 2024-03-15 19:22:00 |
| 47 | 정하은 | 명동칼국수 | 12000 | 2024-03-14 12:05:00 |
| ... | ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    o.id          AS 주문번호,
    c.name        AS 고객이름,
    r.name        AS 가게이름,
    o.total_price AS 주문금액,
    o.order_date  AS 주문일시
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
    INNER JOIN customers   AS c ON o.customer_id   = c.id
ORDER BY o.order_date DESC
LIMIT 15;
```

</details>

---

### 문제 8. ⭐⭐ — 모든 가게와 주문 건수 (주문 없는 가게 포함, IFNULL 사용)

> 대표님이 "모든 가게의 이름, 카테고리, 주문 건수를 보고 싶다. 주문이 없는 가게도 0으로 표시해 달라"고 했습니다.
> LEFT JOIN과 IFNULL을 사용하고, 주문건수 내림차순으로 정렬하세요.

**사용 테이블:** `restaurants`, `orders`

**예상 결과:**

| 가게이름 | 카테고리 | 주문건수 |
|---|---|:---:|
| 부산치킨 | 치킨 | 12 |
| 명동칼국수 | 한식 | 9 |
| ... | ... | ... |
| 부산돈까스 | 일식 | 0 |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    r.name                 AS 가게이름,
    r.category             AS 카테고리,
    IFNULL(COUNT(o.id), 0) AS 주문건수
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
GROUP BY r.id, r.name, r.category
ORDER BY 주문건수 DESC;
```

</details>

---

## ⭐⭐⭐ 도전 문제 (JOIN + GROUP BY + HAVING / 복합 조건)

---

### 문제 9. ⭐⭐⭐ — 가게별 총매출 랭킹 (HAVING으로 필터)

> 재무팀이 "총 매출이 100,000원을 초과하는 가게의 이름, 카테고리, 주문건수, 총매출, 평균주문금액을 내림차순으로 보여 달라"고 했습니다.
> JOIN + GROUP BY + HAVING을 모두 사용하세요.

**사용 테이블:** `orders`, `restaurants`

**예상 결과:**

| 가게이름 | 카테고리 | 주문건수 | 총매출 | 평균주문금액 |
|---|---|:---:|---:|---:|
| 부산치킨 | 치킨 | 12 | 245000 | 20417 |
| 명동칼국수 | 한식 | 9 | 198000 | 22000 |
| 해운대피자 | 피자 | 8 | 176000 | 22000 |
| ... | ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    r.name                       AS 가게이름,
    r.category                   AS 카테고리,
    COUNT(o.id)                  AS 주문건수,
    SUM(o.total_price)           AS 총매출,
    ROUND(AVG(o.total_price), 0) AS 평균주문금액
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name, r.category
HAVING SUM(o.total_price) > 100000
ORDER BY 총매출 DESC;
```

</details>

---

### 문제 10. ⭐⭐⭐ — 인기 메뉴 TOP 5

> 메뉴 기획팀이 "전체 주문 중 가장 많이 팔린 메뉴 TOP 5를 알고 싶다. 메뉴명, 소속 가게 이름, 주문횟수, 총판매금액을 보여 달라"고 했습니다.
> orders, menus, restaurants 세 테이블을 JOIN하고 주문횟수 내림차순으로 정렬하세요.

**사용 테이블:** `orders`, `menus`, `restaurants`

**예상 결과:**

| 메뉴이름 | 가게이름 | 주문횟수 | 총매출 |
|---|---|:---:|---:|
| 후라이드치킨 | 부산치킨 | 7 | 126000 |
| 마라탕 | 서면마라탕 | 6 | 108000 |
| 페퍼로니피자 | 해운대피자 | 5 | 115000 |
| 칼국수 | 명동칼국수 | 5 | 60000 |
| 떡볶이 | 서면분식 | 4 | 34000 |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    m.menu_name        AS 메뉴이름,
    r.name             AS 가게이름,
    COUNT(o.id)        AS 주문횟수,
    SUM(o.total_price) AS 총매출
FROM orders AS o
    INNER JOIN menus       AS m ON o.menu_id       = m.id
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY m.id, m.menu_name, r.name
ORDER BY 주문횟수 DESC
LIMIT 5;
```

</details>

---

### 문제 11. ⭐⭐⭐ — VIP 고객 선별 (누적 결제금액 기준)

> VIP 팀이 "총 결제금액이 50,000원 이상인 고객의 이름, 연락처, 총주문건수, 누적결제금액을 내림차순으로 보여 달라"고 했습니다.
> INNER JOIN + GROUP BY + HAVING을 사용하세요.

**사용 테이블:** `orders`, `customers`

**예상 결과:**

| 고객이름 | 연락처 | 총주문건수 | 누적결제금액 |
|---|---|:---:|---:|
| 김민준 | 010-1234-5678 | 12 | 198000 |
| 이서연 | 010-9876-5432 | 9 | 153000 |
| 박지훈 | 010-5555-1234 | 7 | 119000 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    c.name              AS 고객이름,
    c.phone             AS 연락처,
    COUNT(o.id)         AS 총주문건수,
    SUM(o.total_price)  AS 누적결제금액
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
GROUP BY c.id, c.name, c.phone
HAVING SUM(o.total_price) >= 50000
ORDER BY 누적결제금액 DESC;
```

</details>

---

### 문제 12. ⭐⭐⭐ — 월별 × 카테고리별 매출 현황

> 분석팀이 "월별로 각 카테고리의 주문건수와 총매출을 보고 싶다. 월 기준 내림차순, 같은 달이면 총매출 내림차순으로 정렬해 달라"고 했습니다.
> `DATE_FORMAT`으로 월을 추출하고, JOIN + GROUP BY로 집계하세요.

**사용 테이블:** `orders`, `restaurants`

**예상 결과:**

| 월 | 카테고리 | 주문건수 | 월매출 |
|---|---|:---:|---:|
| 2024-03 | 치킨 | 5 | 98000 |
| 2024-03 | 피자 | 3 | 69000 |
| 2024-03 | 한식 | 4 | 52000 |
| 2024-02 | 치킨 | 7 | 130000 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS 월,
    r.category                          AS 카테고리,
    COUNT(o.id)                         AS 주문건수,
    SUM(o.total_price)                  AS 월매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY 월, r.category
ORDER BY 월 DESC, 월매출 DESC;
```

</details>

---

## ⭐⭐⭐⭐ 보너스 도전 문제

> 아래 두 문제는 서브쿼리 맛보기를 포함한 고난도 문제입니다. Day 7에서 배울 서브쿼리가 등장하지만, JOIN만으로 접근해 보아도 좋습니다.

---

### 보너스 문제 1. ⭐⭐⭐⭐ — 각 가게에서 가장 비싼 메뉴와 그 메뉴의 주문 횟수

> 분석팀이 "각 가게의 대표 메뉴(가장 비싼 메뉴)가 실제로 얼마나 팔렸는지 알고 싶다. 가게이름, 메뉴명, 단가, 주문횟수를 보여 달라"고 했습니다.
>
> **접근 방법 힌트:**
> 1. 먼저 각 가게의 최고가 메뉴를 서브쿼리로 구합니다.
> 2. 그 메뉴와 orders를 JOIN해서 주문 횟수를 집계합니다.

**사용 테이블:** `menus`, `orders`, `restaurants`

**예상 결과 (예시):**

| 가게이름 | 메뉴명 | 단가 | 주문횟수 |
|---|---|---:|:---:|
| 부산치킨 | 양념치킨 | 19000 | 4 |
| 해운대피자 | 콤보피자 | 24000 | 3 |
| 명동칼국수 | 전복칼국수 | 18000 | 2 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
-- 방법 1: 서브쿼리 활용 (Day 7에서 자세히 배웁니다)
SELECT
    r.name        AS 가게이름,
    m.menu_name   AS 메뉴명,
    m.price       AS 단가,
    COUNT(o.id)   AS 주문횟수
FROM menus AS m
    INNER JOIN restaurants AS r
        ON m.restaurant_id = r.id
    LEFT JOIN orders AS o
        ON o.menu_id = m.id
WHERE m.price = (
    -- 같은 가게 내 최고가 메뉴 가격 구하기
    SELECT MAX(m2.price)
    FROM menus AS m2
    WHERE m2.restaurant_id = m.restaurant_id
)
GROUP BY r.id, r.name, m.id, m.menu_name, m.price
ORDER BY 주문횟수 DESC;

-- 방법 2: 서브쿼리 없이 접근 (가게별 최고가를 FROM절 서브쿼리로)
SELECT
    r.name        AS 가게이름,
    m.menu_name   AS 메뉴명,
    m.price       AS 단가,
    COUNT(o.id)   AS 주문횟수
FROM menus AS m
    INNER JOIN restaurants AS r ON m.restaurant_id = r.id
    INNER JOIN (
        SELECT restaurant_id, MAX(price) AS max_price
        FROM menus
        GROUP BY restaurant_id
    ) AS top_price
        ON m.restaurant_id = top_price.restaurant_id
        AND m.price = top_price.max_price
    LEFT JOIN orders AS o ON o.menu_id = m.id
GROUP BY r.id, r.name, m.id, m.menu_name, m.price
ORDER BY 주문횟수 DESC;
```

</details>

---

### 보너스 문제 2. ⭐⭐⭐⭐ — 고객별 가장 자주 주문한 카테고리

> CRM팀이 "각 고객이 가장 많이 주문한 카테고리를 알고 싶다. 고객 이름, 선호 카테고리, 해당 카테고리 주문 건수를 보여 달라"고 했습니다.
> 고객 9번, 10번처럼 주문 이력이 없는 고객은 제외합니다.
>
> **접근 방법 힌트:**
> 1. orders + restaurants JOIN → 고객별 + 카테고리별 주문건수 집계
> 2. 그 결과에서 고객별 최대 주문건수를 다시 조회
> 3. 최대값인 카테고리만 필터링

**사용 테이블:** `orders`, `customers`, `restaurants`

**예상 결과 (예시):**

| 고객이름 | 선호카테고리 | 해당카테고리주문건수 |
|---|---|:---:|
| 김민준 | 치킨 | 5 |
| 이서연 | 한식 | 4 |
| 박지훈 | 피자 | 3 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
-- Step 1: 고객별 + 카테고리별 주문건수 집계 (인라인 뷰)
-- Step 2: 고객별 최대 주문건수 구하기
-- Step 3: 최대 주문건수와 일치하는 행만 필터링

SELECT
    c.name          AS 고객이름,
    cat_cnt.category AS 선호카테고리,
    cat_cnt.cnt     AS 해당카테고리주문건수
FROM (
    -- 고객별 + 카테고리별 주문건수
    SELECT
        o.customer_id,
        r.category,
        COUNT(o.id) AS cnt
    FROM orders AS o
        INNER JOIN restaurants AS r ON o.restaurant_id = r.id
    GROUP BY o.customer_id, r.category
) AS cat_cnt
INNER JOIN (
    -- 고객별 최대 주문건수
    SELECT customer_id, MAX(cnt) AS max_cnt
    FROM (
        SELECT o.customer_id, r.category, COUNT(o.id) AS cnt
        FROM orders AS o
            INNER JOIN restaurants AS r ON o.restaurant_id = r.id
        GROUP BY o.customer_id, r.category
    ) AS sub
    GROUP BY customer_id
) AS max_cnt
    ON cat_cnt.customer_id = max_cnt.customer_id
    AND cat_cnt.cnt = max_cnt.max_cnt
INNER JOIN customers AS c ON cat_cnt.customer_id = c.id
ORDER BY c.id;
```

> **강사 노트:** 이 문제는 FROM절 서브쿼리(인라인 뷰)를 두 번 사용합니다. Day 7에서 서브쿼리를 배우고 나면 훨씬 자연스럽게 접근할 수 있습니다. 지금 당장 완벽히 이해하지 못해도 괜찮습니다.

</details>

---

## 셀프 체크리스트

오늘 실습을 마친 후 아래 항목을 체크해 보세요.

- [ ] INNER JOIN으로 두 테이블을 연결하고 원하는 컬럼을 출력할 수 있다
- [ ] INNER JOIN으로 세 테이블을 연결할 수 있다
- [ ] LEFT JOIN으로 주문 없는 고객/가게를 포함한 결과를 출력할 수 있다
- [ ] LEFT JOIN + WHERE IS NULL로 "없는 것"만 필터링할 수 있다
- [ ] JOIN + GROUP BY + HAVING을 조합하여 조건부 통계를 낼 수 있다
- [ ] 컬럼 충돌 시 별칭(AS)으로 해결할 수 있다
- [ ] IFNULL로 NULL을 0으로 치환할 수 있다

---

> **한입배달 MySQL 10일 완성 | Day 6 실습 문제 | 한국IT교육센터 부산점**
