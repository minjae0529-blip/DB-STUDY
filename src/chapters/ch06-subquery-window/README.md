# Ch06. 서브쿼리·집합·윈도우 함수 — 쿼리 안의 쿼리, 그리고 순위

> **PART 1 · 읽기** | 3시간 | 난이도 ★★★
> 이전: [Ch05. JOIN](../ch05-join/README.md) | 다음: [Ch07. 테이블 설계와 제약조건](../ch07-ddl-constraints/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`{{DB}}`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 지난 시간 hanip_delivery05 도 그대로 남아 있음
USE {{DB}};
```

## 오늘의 요청

> **From.** 마케팅팀 이 매니저
>
> 이번 달 VIP 혜택 대상을 정하려고 해요.
> - **주문 1건당 평균 음식 금액(객단가)이 전체 평균보다 높은** 고객을 주세요. 우연히 몇 번 크게 시킨 분은 빼고 싶으니 **배달 완료 10건 이상**인 분만요.
> - 그리고 메뉴판 개편 회의용으로 **가게마다 가장 많이 팔린 메뉴 1등**도 부탁해요.

첫 번째는 "전체 평균"을 **먼저** 구해야 비교할 수 있고, 두 번째는 Ch04에서 본 1055 에러 때문에 GROUP BY만으로는 메뉴 이름을 뽑을 수 없습니다. 오늘은 **쿼리 안에 쿼리**를 넣는 법과 **순위를 매기는 법**을 배웁니다. 완성 쿼리는 [8절](#8-오늘의-요청-해결).

## 학습 목표

1. WHERE·SELECT·FROM 절에 서브쿼리를 넣고, 서브쿼리가 돌려주는 값의 **모양**(값 하나 / 목록 / 표)을 구분한다.
2. `IN`·`EXISTS`·`NOT EXISTS`를 쓰고, **`NOT IN`과 NULL의 함정**을 설명한다.
3. `WITH`(CTE)로 복잡한 쿼리를 **단계별로 이름 붙여** 쓴다.
4. `UNION`과 `UNION ALL`의 차이를 알고 결과를 위아래로 합친다.
5. `ROW_NUMBER`·`RANK`·`DENSE_RANK`·`SUM OVER`로 **그룹 안 순위**와 **누적 합계**를 만든다.

---

## 1. 서브쿼리 — 먼저 구해야 하는 값이 있을 때

> **요청**: 평균보다 비싼 메뉴는?

평균을 모르면 비교할 수 없습니다. 지금까지는 두 번 실행했습니다.

```sql run
SELECT AVG(price) FROM menus;
```

```sql
SELECT name, price FROM menus WHERE price > 11840;   -- 손으로 옮겨 적은 숫자
```

손으로 옮긴 `11840`은 메뉴가 하나만 추가돼도 틀린 값이 됩니다. **괄호 안에 쿼리를 넣으면** DB가 먼저 계산해서 그 자리에 채웁니다.

```sql run limit=8
SELECT name, price
FROM menus
WHERE price > (SELECT AVG(price) FROM menus)
ORDER BY price DESC;
```

> 괄호 안의 쿼리를 **서브쿼리**(subquery, 내부 쿼리), 바깥을 **메인 쿼리**(외부 쿼리)라고 합니다.
> Ch04 실습 4번에서 배달 완료 건수 `511`을 직접 타이핑했던 것도 이제 `(SELECT COUNT(*) FROM orders WHERE status = '배달완료')`로 바꿀 수 있습니다.

### 서브쿼리가 돌려주는 세 가지 모양

| 모양 | 예 | 쓰는 곳 | 비교 방법 |
|---|---|---|---|
| **값 하나** (1행 1열, 스칼라) | `(SELECT AVG(price) FROM menus)` | WHERE, SELECT | `=` `>` `<` … |
| **목록** (N행 1열) | `(SELECT restaurant_id FROM restaurants WHERE category = '치킨')` | WHERE | `IN` `NOT IN` |
| **표** (N행 M열) | `(SELECT … GROUP BY …)` | FROM | 테이블처럼 JOIN |

값 하나가 와야 할 자리에 여러 행이 오면:

```sql error
SELECT name, price
FROM menus
WHERE price > (SELECT price FROM menus WHERE restaurant_id = 6);
```

---

## 2. 목록 서브쿼리 — IN

> **요청**: 치킨 가게들의 6월 마지막 주 주문

```sql run
SELECT order_id, restaurant_id, ordered_at, status
FROM orders
WHERE restaurant_id IN (SELECT restaurant_id FROM restaurants WHERE category = '치킨')
    AND ordered_at >= '2026-06-24'
ORDER BY ordered_at;
```

> 같은 결과를 Ch05의 JOIN으로도 만들 수 있습니다. **결과에 가게 열이 필요하면 JOIN, 걸러내기만 하면 IN**이 읽기 쉽습니다.

### ⚠️ NOT IN과 NULL

> **요청**: 오늘(6/30) 아직 **배달을 맡지 않은** 기사는?

```sql run
SELECT name
FROM riders
WHERE rider_id NOT IN (SELECT rider_id FROM orders WHERE ordered_at >= '2026-06-30');
```

**0행**입니다. 그런데 오늘 배달한 기사는 4명뿐이라 나머지 4명이 나와야 합니다. 서브쿼리 결과를 직접 보면:

```sql run
SELECT rider_id FROM orders WHERE ordered_at >= '2026-06-30';
```

목록에 **NULL**(조리중·접수 주문)이 섞여 있습니다. `x NOT IN (1, 3, NULL)`은 `x <> 1 AND x <> 3 AND x <> NULL`이고, `x <> NULL`은 Ch02에서 본 대로 항상 "모름"입니다. 하나라도 "모름"이면 전체가 참이 될 수 없어서 **모든 행이 빠집니다.**

> **규칙: NOT IN의 서브쿼리에 NULL이 나올 수 있으면 `NOT EXISTS`를 쓴다.** (다음 절) 또는 서브쿼리에 `WHERE rider_id IS NOT NULL`을 붙입니다.

---

## 3. 상관 서브쿼리와 EXISTS

지금까지의 서브쿼리는 **혼자 실행해도** 결과가 나왔습니다. 서브쿼리가 **바깥 쿼리의 행을 참조**하면 행마다 다시 계산되는데, 이를 **상관 서브쿼리**라고 합니다.

### 3-1. EXISTS — "그런 행이 하나라도 있나?"

```sql run
SELECT rd.name
FROM riders rd
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.rider_id = rd.rider_id          -- 바깥 행(rd)을 참조
        AND o.ordered_at >= '2026-06-30'
);
```

`EXISTS`는 서브쿼리가 **한 행이라도 돌려주면 참**입니다. 값을 비교하지 않으므로 NULL 문제가 없고, `SELECT 1`처럼 무엇을 SELECT하든 상관없습니다.

Ch05의 "주문 0건 고객"도 NOT EXISTS로 쓸 수 있습니다.

```sql run
SELECT c.name, c.joined_at
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
ORDER BY c.customer_id;
```

| 방법 | 장점 | 주의 |
|---|---|---|
| `LEFT JOIN … IS NULL` | 오른쪽 열도 함께 볼 수 있음 | 1:N이면 행이 불어날 수 있음 |
| `NOT EXISTS` | 의도가 문장 그대로 읽힘, NULL 안전 | 오른쪽 열은 못 봄 |
| `NOT IN` | 짧다 | **NULL이 섞이면 0행** |

### 3-2. 상관 서브쿼리로 그룹별 비교

> **요청**: **자기 가게 평균가보다** 비싼 메뉴

전체 평균이 아니라 **행마다 다른 기준**과 비교합니다.

```sql run limit=8
SELECT m.restaurant_id, m.name, m.price
FROM menus m
WHERE m.price > (
    SELECT AVG(m2.price)
    FROM menus m2
    WHERE m2.restaurant_id = m.restaurant_id    -- 바깥 메뉴의 가게
)
ORDER BY m.restaurant_id, m.price DESC;
```

> 같은 테이블을 안팎에서 쓰므로 별칭(`m`, `m2`)으로 구분해야 합니다.

---

## 4. SELECT 절 서브쿼리 — 행 옆에 기준값 붙이기

```sql run limit=6
SELECT m.name,
    m.price,
    (SELECT ROUND(AVG(price)) FROM menus) AS overall_avg,
    m.price - (SELECT ROUND(AVG(price)) FROM menus) AS diff
FROM menus m
WHERE m.restaurant_id = 2
ORDER BY m.menu_id;
```

> SELECT 절 서브쿼리는 반드시 **값 하나**를 돌려줘야 합니다. 상관 서브쿼리로 쓰면 행마다 실행되므로 데이터가 많을 때는 느립니다. 그럴 때는 다음 절의 FROM절 서브쿼리 + JOIN이 낫습니다.

---

## 5. FROM 절 서브쿼리와 WITH(CTE) — 단계별로 쌓기

### 5-1. 쿼리 결과를 표처럼 쓰기

쿼리 결과도 표입니다. FROM 절에 넣고 **이름(별칭)을 붙이면** 테이블처럼 씁니다.

Ch05 7절의 fan-out 문제를 기억하나요? 주문 상세를 JOIN하면 배달팁이 부풀었습니다. **주문 상세를 먼저 주문 단위로 묶은 뒤** JOIN하면 해결됩니다.

```sql run limit=5
SELECT r.name AS restaurant_name,
    COUNT(*) AS delivered_orders,
    SUM(f.food_amount) AS food_sales,
    SUM(o.delivery_fee) AS fee_sum
FROM orders o
JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
) f ON o.order_id = f.order_id                 -- 주문 1건 = f 1행 → 불어나지 않음
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY food_sales DESC;
```

> FROM 절 서브쿼리(인라인 뷰)에는 **반드시 별칭**(`f`)이 필요합니다. 빠뜨리면 1248 에러.

### 5-2. WITH — 서브쿼리에 이름 붙이기

FROM 절에 괄호가 겹겹이 쌓이면 읽기 어렵습니다. `WITH 이름 AS ( … )`로 **먼저 정의하고 아래에서 테이블처럼** 씁니다. 이것을 **CTE**(Common Table Expression)라고 합니다.

```sql run limit=5
WITH order_food AS (                       -- ① 주문별 음식 금액
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
)
SELECT r.name AS restaurant_name,          -- ② 가게별로 집계
    COUNT(*) AS delivered_orders,
    SUM(f.food_amount) AS food_sales,
    SUM(o.delivery_fee) AS fee_sum
FROM orders o
JOIN order_food f  ON o.order_id = f.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY food_sales DESC;
```

결과는 5-1과 같습니다. CTE는 **쉼표로 여러 개** 정의할 수 있고, 뒤의 CTE가 앞의 CTE를 참조할 수 있습니다.

```sql
WITH a AS ( … ),
     b AS ( SELECT … FROM a … )
SELECT … FROM b;
```

> **실무 습관**: 복잡한 리포트는 CTE로 "① 재료 만들기 → ② 묶기 → ③ 비교하기" 단계를 나눠 씁니다. 단계마다 `SELECT * FROM 단계이름`으로 중간 결과를 확인할 수 있어 디버깅이 쉽습니다. MySQL 8.0부터 지원합니다.

---

## 6. UNION — 결과를 위아래로 합치기

JOIN이 표를 **옆으로** 붙인다면, UNION은 **아래로** 붙입니다.

> **요청**: 중구 비상연락망 — 그 지역의 고객과 기사를 한 목록으로

```sql run
SELECT '고객' AS kind, name, phone
FROM customers
WHERE district = '중구'
UNION ALL
SELECT '기사', name, phone
FROM riders
WHERE district = '중구'
ORDER BY kind, name;
```

| | `UNION` | `UNION ALL` |
|---|---|---|
| 중복 행 | 제거 | 그대로 |
| 속도 | 중복 확인 때문에 느림 | 빠름 |
| 언제 | 중복이 생기면 안 될 때 | 대부분 (중복이 없거나 있어도 될 때) |

> 규칙: 위아래 쿼리의 **열 개수가 같아야** 하고, 열 이름은 **첫 번째 쿼리**를 따릅니다. `ORDER BY`는 맨 끝에 한 번만 씁니다.

---

## 7. 윈도우 함수 — 행을 유지한 채 그룹 계산

GROUP BY는 그룹마다 **1행으로 줄입니다.** 윈도우 함수는 **행을 그대로 둔 채** 옆에 그룹 계산 결과를 붙입니다.

```
 함수() OVER (PARTITION BY 그룹 ORDER BY 순서)
              └ 어디서 나눌지   └ 그룹 안에서 어떤 순서로
```

### 7-1. 순위 함수 세 가지

```sql run
SELECT name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
    RANK()       OVER (ORDER BY price DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rnk
FROM menus
WHERE restaurant_id IN (1, 6)
ORDER BY price DESC, name;
```

| 함수 | 동점 처리 | 위 결과 (22000, 22000, 21000, 21000, 20000) |
|---|---|---|
| `ROW_NUMBER()` | 무조건 1, 2, 3… (동점도 다른 번호) | 1, 2, 3, 4, 5 |
| `RANK()` | 동점은 같은 순위, **다음 순위를 건너뜀** | 1, 1, 3, 3, 5 |
| `DENSE_RANK()` | 동점은 같은 순위, 건너뛰지 않음 | 1, 1, 2, 2, 3 |

> `ROW_NUMBER`는 동점(수육 (중)과 순살 간장 치킨)에도 1, 2를 **임의로** 매깁니다. 결과를 고정하려면 `ORDER BY price DESC, menu_id`처럼 동점 기준을 추가하세요(Ch02 Top-N과 같은 원리).

### 7-2. PARTITION BY — 그룹 안에서 순위

가게마다 1위부터 다시 셉니다.

```sql run limit=10
SELECT restaurant_id,
    name,
    price,
    RANK() OVER (PARTITION BY restaurant_id ORDER BY price DESC) AS price_rank
FROM menus
WHERE restaurant_id IN (1, 2)
ORDER BY restaurant_id, price_rank;
```

### 7-3. 그룹별 Top-N — 윈도우 결과로 거르기

윈도우 함수는 SELECT(⑤) 단계에서 계산되므로 **WHERE에서 바로 쓸 수 없습니다.** CTE로 한 번 감싼 뒤 거릅니다.

```sql run
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
```

> "가게별 가장 비싼 메뉴" — GROUP BY로는 메뉴 이름을 뽑을 수 없던(1055) 문제가 풀렸습니다.

### 7-4. 집계 함수 + OVER — 누적 합계와 비율

`SUM`·`AVG`·`COUNT`도 `OVER`를 붙이면 윈도우 함수가 됩니다.

```sql run
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    SUM(delivery_fee) AS fee_sum,
    SUM(SUM(delivery_fee)) OVER (ORDER BY DATE_FORMAT(ordered_at, '%Y-%m')) AS cumulative_fee,
    ROUND(SUM(delivery_fee) * 100 / SUM(SUM(delivery_fee)) OVER (), 1) AS share_pct
FROM orders
WHERE status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
```

> - `SUM(SUM(delivery_fee)) OVER (…)`: 안쪽 SUM은 GROUP BY 집계(월별 합계), 바깥 SUM OVER는 그 결과들을 누적합니다.
> - `OVER ()` — 괄호가 비어 있으면 **전체**가 하나의 창입니다. 전체 대비 비율을 구할 때 씁니다.

---

## 8. 오늘의 요청 해결

### ① 객단가가 평균보다 높은 단골 고객

CTE로 단계를 나눕니다: **주문별 음식 금액 → 고객별 객단가 → 전체 평균과 비교**.

```sql run limit=15
WITH order_food AS (                                   -- ① 배달 완료 주문별 음식 금액
    SELECT o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS food_amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.order_id, o.customer_id
),
customer_avg AS (                                      -- ② 고객별 주문 수·객단가
    SELECT customer_id,
        COUNT(*) AS orders,
        ROUND(AVG(food_amount)) AS avg_food
    FROM order_food
    GROUP BY customer_id
)
SELECT c.name,
    c.grade,
    ca.orders,
    ca.avg_food,
    (SELECT ROUND(AVG(food_amount)) FROM order_food) AS overall_avg   -- ③ 전체 평균
FROM customer_avg ca
JOIN customers c ON ca.customer_id = c.customer_id
WHERE ca.avg_food > (SELECT AVG(food_amount) FROM order_food)
    AND ca.orders >= 10
ORDER BY ca.avg_food DESC;
```

> - `ca.orders >= 10` 조건을 빼면 9건 주문한 일반 등급 고객이 1위로 올라옵니다. **표본이 작은 평균은 믿기 어렵다**(Ch04)는 원칙이 여기서도 적용됩니다.
> - 등급(grade)은 **총 결제 금액** 기준이라, 객단가 기준과 순서가 다릅니다. VIP 기준을 무엇으로 할지는 마케팅팀이 정할 일이지만, 두 기준의 차이를 **데이터로 보여 주는 것**은 데이터팀의 일입니다.

### ② 가게별 판매 1위 메뉴

```sql run limit=16
WITH menu_sales AS (
    SELECT m.restaurant_id,
        m.menu_id,
        m.name AS menu_name,
        SUM(oi.quantity) AS sold_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN menus m  ON oi.menu_id  = m.menu_id
    WHERE o.status = '배달완료'
    GROUP BY m.restaurant_id, m.menu_id, m.name
),
ranked AS (
    SELECT ms.*,
        RANK() OVER (PARTITION BY restaurant_id ORDER BY sold_quantity DESC) AS rnk
    FROM menu_sales ms
)
SELECT r.name AS restaurant_name,
    rk.menu_name,
    rk.sold_quantity
FROM ranked rk
JOIN restaurants r ON rk.restaurant_id = r.restaurant_id
WHERE rk.rnk = 1
ORDER BY r.restaurant_id, rk.menu_name;
```

> 남포동떡볶이연구소는 **두 메뉴가 공동 1위**(18개)라 2행이 나옵니다. `RANK`를 썼기 때문입니다. 반드시 가게당 1행이어야 한다면 `ROW_NUMBER`와 동점 처리 기준(`ORDER BY sold_quantity DESC, menu_id`)을 쓰면 되지만, 그러면 공동 1위 중 하나가 **임의의 기준으로 탈락**합니다. 어느 쪽이 맞는지는 요청자에게 물어야 합니다.

## 정리

| 문법 | 핵심 |
|---|---|
| 스칼라 서브쿼리 | 값 하나. `WHERE price > (SELECT AVG …)`, 여러 행이면 1242 |
| `IN (서브쿼리)` | 목록 중 하나. `NOT IN`에 NULL이 섞이면 **0행** |
| `EXISTS` / `NOT EXISTS` | 그런 행이 있나. 상관 서브쿼리, NULL 안전 |
| FROM절 서브쿼리 | 결과를 표처럼. 별칭 필수. fan-out 해결 |
| `WITH` (CTE) | 서브쿼리에 이름 붙여 단계별로 |
| `UNION` / `UNION ALL` | 아래로 합치기. 중복 제거 여부 |
| `ROW_NUMBER` `RANK` `DENSE_RANK` | 동점 처리 방식이 다름 |
| `OVER (PARTITION BY … ORDER BY …)` | 행을 유지한 채 그룹 계산. 거르려면 CTE로 감싸기 |

## 다음 챕터 예고

> **From.** 개발팀 한 팀장
> 다음 달에 **쿠폰 기능**이 나갑니다. 쿠폰 종류와, 고객에게 지급된 쿠폰을 저장할 **테이블을 설계해서 만들어** 주세요. 같은 쿠폰이 한 사람에게 두 번 지급되거나, 할인액이 음수인 쿠폰이 들어오면 절대 안 됩니다.

지금까지는 이미 있는 테이블을 **읽기만** 했습니다. 이제 테이블을 **만드는** 차례입니다. 그 전에 우리 DB의 테이블들이 왜 지금 모양인지부터 해부합니다 — Ch07.

<!-- lecture:auto -->
