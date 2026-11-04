# Ch04. 집계와 그룹 — 563건을 한 장의 리포트로

> **PART 1 · 읽기** | 3시간 | 난이도 ★★
> 이전: [Ch03. 함수로 데이터 가공하기](../ch03-functions/README.md) | 다음: [Ch05. JOIN — 흩어진 데이터 잇기](../ch05-join/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`{{DB}}`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 지난 시간 hanip_delivery03 도 그대로 남아 있음
USE {{DB}};
```

> 오늘 실습은 모두 `{{DB}}`에서 합니다. SCHEMAS 패널에서 **굵게 표시된 DB**를 확인하고 시작하세요.

## 오늘의 요청

> **From.** 정산팀 정 대리
>
> 상반기 결산 회의 자료가 필요합니다. **월별로** 아래 숫자를 한 표로 주세요.
> - 전체 주문 수, 배달 완료 수, 취소 수, **취소율(%)**
> - 배달 완료 주문의 **배달팁 합계**와 **쿠폰 할인 합계**
> - 배달 완료 주문의 **평균 배달 시간(분)**
>
> 그리고 **배달 완료 건수가 많은 가게 Top 5**도 부탁해요.

지금까지의 SELECT는 **행 하나를 가공해 행 하나**를 돌려줬습니다. 563행에서 **6행(월별)**을 만들려면 여러 행을 **묶어서 하나로 요약**해야 합니다. 완성 쿼리는 [9절](#9-오늘의-요청-해결).

## 학습 목표

1. `COUNT`·`SUM`·`AVG`·`MIN`·`MAX`로 여러 행을 하나의 값으로 요약하고, **NULL이 어떻게 처리되는지** 설명한다.
2. `GROUP BY`로 그룹별 요약을 만들고, 열·**식**(월, 시간대)으로 그룹을 나눈다.
3. `WHERE`와 `HAVING`의 차이를 **실행 순서**로 설명하고 알맞게 쓴다.
4. `SUM(CASE …)`로 **조건부 집계**를 해 한 쿼리에서 여러 지표(취소율 등)를 만든다.
5. 1055(ONLY_FULL_GROUP_BY) 에러의 원인을 이해하고 고친다.

---

## 0. 단일행 함수 vs 집계 함수

| | 단일행 함수 (Ch03) | 집계 함수 (Ch04) |
|---|---|---|
| 동작 | 행마다 하나씩 계산 | 여러 행을 모아 **하나**로 |
| 예 | `CHAR_LENGTH(name)` | `COUNT(*)`, `SUM(price)` |
| 30행에 쓰면 | 30행 | **1행** (GROUP BY가 없을 때) |

```sql run
SELECT COUNT(*)      AS menu_count,
    MIN(price)       AS min_price,
    MAX(price)       AS max_price,
    SUM(price)       AS price_sum,
    AVG(price)       AS avg_price
FROM menus;
```

70개 메뉴가 **한 줄**이 됐습니다.

---

## 1. COUNT — 세 가지 얼굴

| 식 | 세는 것 |
|---|---|
| `COUNT(*)` | **행** 수 (NULL 여부 무관) |
| `COUNT(열)` | 그 열이 **NULL이 아닌** 행 수 |
| `COUNT(DISTINCT 열)` | NULL이 아닌 **서로 다른 값**의 수 |

```sql run
SELECT COUNT(*)                 AS customers,
    COUNT(email)                AS with_email,
    COUNT(birth_date)           AS with_birth,
    COUNT(DISTINCT district)    AS districts
FROM customers;
```

> "고객 수"를 `COUNT(email)`로 세면 24명이 됩니다. **행 수는 `COUNT(*)`**, 특정 값이 채워진 수는 `COUNT(열)` — 무엇을 세는지 이름(별칭)에 드러나게 쓰세요.

```sql run
SELECT COUNT(*)                     AS orders,
    COUNT(DISTINCT customer_id)     AS ordering_customers,
    COUNT(rider_id)                 AS rider_assigned
FROM orders;
```

> 563건의 주문을 낸 고객은 27명입니다(30명 중 3명은 주문 0건). 기사가 배정된 주문은 `COUNT(rider_id)`로 셉니다.

---

## 2. SUM · AVG · MIN · MAX와 NULL

### 2-1. 집계 함수는 NULL을 건너뛴다

`COUNT(*)`를 제외한 모든 집계 함수는 **NULL을 무시**합니다.

```sql run
SELECT COUNT(*) AS customers,
    COUNT(birth_date) AS with_birth,
    AVG(TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30')) AS avg_age
FROM customers;
```

평균 나이는 생년월일이 있는 **27명의 평균**입니다(30명으로 나눈 값이 아님). 대부분 원하는 동작이지만, "값이 없으면 0으로 쳐야 하는" 지표라면 `IFNULL(열, 0)`로 바꾼 뒤 집계해야 합니다.

배달 시간도 마찬가지입니다. 취소·진행 중 주문은 `delivered_at`이 NULL이므로 자동으로 빠집니다.

```sql run
SELECT COUNT(*) AS orders,
    COUNT(delivered_at) AS delivered,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_minutes,
    MAX(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)) AS max_minutes
FROM orders;
```

### 2-2. 대상이 0행이면?

입점한 지 6일 된 전포동오일파스타(`restaurant_id = 15`)는 주문이 없습니다.

```sql run
SELECT COUNT(*) AS orders,
    SUM(delivery_fee) AS fee_sum,
    IFNULL(SUM(delivery_fee), 0) AS fee_sum_safe
FROM orders
WHERE restaurant_id = 15;
```

> **`COUNT`는 0, `SUM`·`AVG`·`MIN`·`MAX`는 NULL**입니다. 리포트에 "NULL원"이 찍히지 않도록 `IFNULL(SUM(…), 0)`을 습관화하세요.

### 2-3. 문자·날짜에도 MIN·MAX

```sql run
SELECT MIN(ordered_at) AS first_order,
    MAX(ordered_at) AS last_order
FROM orders;
```

```sql run
SELECT MIN(name) AS first_name,
    MAX(name) AS last_name
FROM customers;
```

> 날짜의 `MIN`은 가장 이른 날, `MAX`는 가장 최근 날입니다. "마지막 주문일" 같은 지표에 자주 씁니다. 문자는 가나다순으로 비교합니다.

---

## 3. GROUP BY — 묶어서 요약하기

`GROUP BY 열`은 **그 열의 값이 같은 행끼리 묶고**, 묶음마다 집계 함수를 계산합니다.

```
 restaurants (15행)                         GROUP BY category
 ┌────────────────┬──────────┐              ┌──────────┬──────────┐
 │ 서면옛날돼지국밥 │ 한식     │ ─┐            │ category │ COUNT(*) │
 │ 해운대명가밀면   │ 한식     │ ─┼─ 한식 묶음 → │ 한식     │ 3        │
 │ 동래파전골목집   │ 한식     │ ─┘            │ 일식     │ 2        │
 │ 전포카츠        │ 일식     │ ─┬─ 일식 묶음 → │ …        │ …        │
 │ 해운대스시하루   │ 일식     │ ─┘            └──────────┴──────────┘
 │ …              │ …        │
```

```sql run
SELECT category,
    COUNT(*) AS restaurant_count
FROM restaurants
GROUP BY category
ORDER BY restaurant_count DESC, category;
```

```sql run
SELECT status,
    COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;
```

### 3-1. 여러 열로 묶기

두 열의 **조합**이 같은 행끼리 묶입니다.

```sql run
SELECT district,
    category,
    COUNT(*) AS restaurant_count
FROM restaurants
GROUP BY district, category
ORDER BY district, category;
```

### 3-2. 식으로 묶기 — 월별, 시간대별

Ch03의 함수가 여기서 빛납니다. **가공한 값으로 그룹을 나눌 수 있습니다.**

```sql run
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_month
ORDER BY order_month;
```

```sql run limit=20
SELECT HOUR(ordered_at) AS order_hour,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_hour
ORDER BY order_hour;
```

> 점심(11~13시)과 저녁(17~20시)에 몰리는 배달앱의 전형적인 패턴입니다. 운영팀은 이 표로 시간대별 기사 배치를 정합니다.
> MySQL은 GROUP BY에 SELECT의 **별칭**(`order_month`)을 쓸 수 있습니다. 표준 SQL과 다른 DBMS에서는 안 되는 경우가 있어, 그때는 식을 그대로 반복합니다.

---

## 4. ⚠️ GROUP BY의 규칙 — 1055 에러

"업종별 가게 수와 **가게 이름**도 같이 보고 싶어요."

```sql error
SELECT category,
    name,
    COUNT(*) AS restaurant_count
FROM restaurants
GROUP BY category;
```

한식 묶음에는 가게가 3개인데 결과는 **한 줄**입니다. `name` 자리에 셋 중 무엇을 보여 줘야 할까요? DB는 정할 수 없어서 거부합니다.

> **규칙: GROUP BY가 있으면 SELECT에는 ① GROUP BY에 쓴 열(식) 또는 ② 집계 함수만 올 수 있다.**

해결 방법은 의도에 따라 다릅니다.

```sql run
-- 의도 A: 묶음 안의 이름을 전부 보고 싶다 → GROUP_CONCAT
SELECT category,
    COUNT(*) AS restaurant_count,
    GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') AS restaurant_names
FROM restaurants
GROUP BY category
ORDER BY restaurant_count DESC, category;
```

> 의도 B: 가게마다 한 줄씩 보고 싶다 → 그건 그룹이 아니라 `GROUP BY` 없이 `ORDER BY category`로 정렬하면 됩니다.
>
> 옛날 MySQL(5.6 이하)은 이 에러를 내지 않고 **아무 이름이나 하나** 골라 보여 줬습니다. 인터넷의 오래된 예제가 MySQL 8에서 1055를 내는 이유입니다. 설정을 꺼서 피하지 말고, 쿼리를 고치세요.

---

## 5. WHERE vs HAVING

| | WHERE | HAVING |
|---|---|---|
| 거르는 대상 | **행** (묶기 전) | **그룹** (묶은 후) |
| 집계 함수 | 쓸 수 없음 | 쓸 수 있음 |
| 실행 시점 | ② | ④ |

Ch02의 실행 순서에 ③④가 채워집니다.

```
① FROM  →  ② WHERE  →  ③ GROUP BY  →  ④ HAVING  →  ⑤ SELECT  →  ⑥ ORDER BY  →  ⑦ LIMIT
            행 거르기      묶기            그룹 거르기
```

> **요청**: 배달 완료 주문이 **50건 이상**인 가게는?

```sql run
SELECT restaurant_id,
    COUNT(*) AS delivered_count
FROM orders
WHERE status = '배달완료'          -- ② 행 조건: 배달 완료된 주문만 남기고
GROUP BY restaurant_id             -- ③ 가게별로 묶은 뒤
HAVING COUNT(*) >= 50              -- ④ 그룹 조건: 50건 이상인 가게만
ORDER BY delivered_count DESC;
```

집계 함수를 WHERE에 쓰면:

```sql error
SELECT restaurant_id, COUNT(*) AS delivered_count
FROM orders
WHERE status = '배달완료' AND COUNT(*) >= 50
GROUP BY restaurant_id;
```

> WHERE(②)가 실행될 때는 아직 묶이지 않았으므로 "그룹의 개수"라는 게 존재하지 않습니다.
>
> **판단 기준**: 조건에 **집계 함수**가 들어가면 HAVING, 아니면 WHERE. `HAVING status = '배달완료'`처럼 행 조건을 HAVING에 쓰는 건 (동작하더라도) 잘못된 습관입니다. 거를 수 있는 행은 **최대한 일찍** WHERE에서 걸러야 묶을 양이 줄어듭니다.

---

## 6. 조건부 집계 — 한 쿼리로 여러 지표

"월별로 전체·완료·취소 건수를 **한 표에**" 보고 싶다면, `WHERE status = '취소'`로는 안 됩니다. 다른 지표의 행까지 사라지니까요. 대신 **집계 함수 안에 조건**을 넣습니다.

```sql run
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = '배달완료' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled
FROM orders
GROUP BY order_month
ORDER BY order_month;
```

`CASE`가 행마다 1 또는 0을 만들고 `SUM`이 그걸 더하니, 결국 **조건에 맞는 행의 개수**가 됩니다.

| 쓰는 법 | 비고 |
|---|---|
| `SUM(CASE WHEN 조건 THEN 1 ELSE 0 END)` | 표준 SQL, 어느 DBMS에서나 동작 |
| `COUNT(CASE WHEN 조건 THEN 1 END)` | ELSE가 없으면 NULL → COUNT가 안 셈 |
| `SUM(조건)` | MySQL 전용 축약 (참=1, 거짓=0) |

금액도 같은 방식으로 조건부로 더할 수 있습니다.

```sql run
SELECT payment_method,
    COUNT(*) AS orders,
    SUM(CASE WHEN status = '배달완료' THEN delivery_fee ELSE 0 END) AS delivered_fee_sum,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled
FROM orders
GROUP BY payment_method
ORDER BY orders DESC;
```

### 비율 계산

취소율 = 취소 건수 ÷ 전체 건수 × 100. 분모가 0일 수 있는 비율은 `NULLIF`로 보호합니다(Ch03).

```sql run limit=15
SELECT restaurant_id,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled,
    ROUND(SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) * 100 / NULLIF(COUNT(*), 0), 1) AS cancel_rate
FROM orders
GROUP BY restaurant_id
ORDER BY cancel_rate DESC, restaurant_id;
```

> 해운대스시하루(12번)의 취소율이 눈에 띕니다. 다만 **표본이 작을 때**(전체 25건) 비율은 크게 흔들립니다. 리포트에는 비율과 함께 **건수**를 꼭 같이 보여 주세요.

---

## 7. 주문 상세(order_items) 집계

주문의 **금액**은 `order_items`에 있습니다(`quantity × unit_price`). 주문 번호로 묶으면 **주문 1건의 음식 금액**이 나옵니다.

```sql run limit=5
SELECT order_id,
    COUNT(*) AS item_lines,
    SUM(quantity) AS total_quantity,
    SUM(quantity * unit_price) AS food_amount
FROM order_items
GROUP BY order_id
ORDER BY food_amount DESC, order_id;
```

메뉴 번호로 묶으면 메뉴별 판매량입니다.

```sql run limit=5
SELECT menu_id,
    SUM(quantity) AS sold_quantity,
    SUM(quantity * unit_price) AS sales_amount
FROM order_items
GROUP BY menu_id
ORDER BY sold_quantity DESC, menu_id;
```

> ⚠️ 이 두 결과에는 **취소된 주문의 상세도 섞여 있습니다.** 주문 상태(`status`)는 `orders`에, 금액은 `order_items`에 있기 때문에 `order_items`만으로는 취소 주문을 걸러 낼 수 없습니다. 그리고 메뉴 번호 대신 **메뉴 이름**을 보려면 `menus`가 필요합니다. 두 테이블을 이어 붙이는 방법이 다음 챕터의 JOIN입니다.

---

## 8. WITH ROLLUP — 소계와 합계

`GROUP BY … WITH ROLLUP`은 그룹별 결과 아래에 **전체 합계 행**을 붙여 줍니다. 합계 행의 그룹 열은 NULL로 표시됩니다.

```sql run
SELECT IFNULL(payment_method, '합계') AS payment_method,
    COUNT(*) AS delivered_orders,
    SUM(delivery_fee) AS fee_sum
FROM orders
WHERE status = '배달완료'
GROUP BY payment_method WITH ROLLUP;
```

> `WITH ROLLUP`을 쓰면 `ORDER BY`를 함께 쓸 수 없는 버전이 있고(8.0.12 이전), 정렬 결과도 직관적이지 않습니다. 리포트용 합계가 꼭 필요할 때만 쓰고, 보통은 합계를 별도 쿼리로 확인합니다.

---

## 9. 오늘의 요청 해결

### 월별 운영 리포트

```sql run
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = '배달완료' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) AS canceled,
    ROUND(SUM(CASE WHEN status = '취소' THEN 1 ELSE 0 END) * 100 / COUNT(*), 1) AS cancel_rate,
    SUM(CASE WHEN status = '배달완료' THEN delivery_fee ELSE 0 END) AS fee_sum,
    SUM(CASE WHEN status = '배달완료' THEN discount_amount ELSE 0 END) AS discount_sum,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_delivery_min
FROM orders
GROUP BY order_month
ORDER BY order_month;
```

> - 평균 배달 시간은 조건부로 쓰지 않았습니다. 배달 완료가 아닌 주문은 `delivered_at`이 NULL이라 **AVG가 알아서 건너뛰기** 때문입니다(2-1절).
> - 6월 합계(delivered + canceled)가 total_orders보다 3건 적습니다. 스냅숏 시점에 **진행 중인 주문 3건**이 있기 때문입니다. 숫자가 안 맞을 때 원인을 데이터에서 설명할 수 있어야 합니다.
> - **4월 취소율(14.2%)이 다른 달의 두 배 가까이 됩니다.** 회의에서 반드시 나올 질문입니다. "어느 가게에서, 어느 시간대에 취소가 몰렸나?"를 같은 방식(`WHERE` 4월 + `GROUP BY restaurant_id` / `HOUR`)으로 바로 쪼개 볼 수 있습니다. 리포트는 답이 아니라 **다음 질문의 출발점**입니다.

### 배달 완료 Top 5 가게

```sql run
SELECT restaurant_id,
    COUNT(*) AS delivered_count
FROM orders
WHERE status = '배달완료'
GROUP BY restaurant_id
ORDER BY delivered_count DESC, restaurant_id
LIMIT 5;
```

## 정리

| 문법 | 핵심 |
|---|---|
| `COUNT(*)` / `COUNT(열)` / `COUNT(DISTINCT 열)` | 행 수 / NULL 아닌 수 / 서로 다른 값 수 |
| `SUM` `AVG` `MIN` `MAX` | NULL은 건너뜀. 대상 0행이면 NULL → `IFNULL(…, 0)` |
| `GROUP BY` | 같은 값끼리 묶기. 열·여러 열·식(월, 시간대) |
| SELECT 규칙 | GROUP BY 열 또는 집계 함수만 (위반 시 1055) |
| `HAVING` | 그룹 조건. 집계 함수가 들어간 조건만 |
| 조건부 집계 | `SUM(CASE WHEN … THEN 1 ELSE 0 END)` |
| 실행 순서 | FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT |

## 다음 챕터 예고

> **From.** 정산팀 정 대리
> 리포트 잘 받았어요! 그런데 회의에서 **"5번 가게가 어디예요?"**라는 질문이 나왔어요. 가게 **번호 말고 이름으로**, 그리고 배달팁 말고 **음식 매출**(취소 제외)도 월별로 보고 싶다고 합니다.

가게 이름은 `restaurants`에, 주문 상태는 `orders`에, 금액은 `order_items`에 있습니다. 세 테이블에 흩어진 데이터를 하나로 잇는 방법 — Ch05, JOIN입니다.

<!-- lecture:auto -->
