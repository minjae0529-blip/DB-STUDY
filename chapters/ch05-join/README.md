# Ch05. JOIN — 흩어진 데이터 잇기

> **PART 1 · 읽기** | 3시간 | 난이도 ★★★
> 이전: [Ch04. 집계와 그룹](../ch04-aggregation/README.md) | 다음: [Ch06. 서브쿼리·집합·윈도우 함수](../ch06-subquery-window/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery05`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 지난 시간 hanip_delivery04 도 그대로 남아 있음
USE hanip_delivery05;
```

## 오늘의 요청

> **From.** 정산팀 정 대리
>
> 지난주 리포트 잘 받았어요. 그런데 회의에서 **"1번 가게가 어디예요?"**라는 질문이 나왔어요.
> - **가게 이름**으로 상반기 **음식 매출** 순위를 주세요. (배달 완료 주문만, 음식 금액 = 수량 × 단가)
> - 월별 음식 매출도 같이요.
> - 그리고 **한 번도 주문하지 않은 고객** 명단도요. 마케팅팀이 첫 주문 쿠폰을 보낸대요.

필요한 데이터가 세 테이블에 흩어져 있습니다. 가게 **이름**은 `restaurants`에, 주문 **상태**는 `orders`에, **금액**은 `order_items`에. 오늘은 이 조각들을 하나로 잇습니다. 완성 쿼리는 [9절](#9-오늘의-요청-해결).

## 학습 목표

1. 두 테이블의 **기본키–외래키 관계**를 읽고 `JOIN … ON` 조건을 쓴다.
2. 테이블 별칭을 쓰고, 이름이 겹치는 열(1052 에러)을 정확히 지정한다.
3. 3~5개 테이블을 차례로 이어 원하는 정보를 한 행에 모은다.
4. `LEFT JOIN`으로 **짝이 없는 행**(주문 0건 고객·가게)을 찾고, **ON과 WHERE 조건의 차이**를 설명한다.
5. JOIN 뒤 집계할 때 **행이 불어나는 문제**(fan-out)를 알아채고 피한다.

---

## 1. 왜 테이블을 나눴을까 — 다시 보는 주문 7번

Ch01에서 주문 한 건이 다섯 테이블에 나뉘어 저장된다는 걸 봤습니다. 나눠서 저장하면 고객 정보가 한 곳에만 있어 고치기 쉽지만, **볼 때는 다시 합쳐야** 합니다.

```sql
SELECT order_id, customer_id, restaurant_id, status
FROM orders
WHERE order_id = 7;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | customer_id | restaurant_id | status |
|---|---|---|---|
| 7 | 1 | 8 | 배달완료 |


번호만 있습니다. 1번 고객이 누구고 8번 가게가 어디인지 보려면 `customers`와 `restaurants`를 따로 찾아봐야 합니다. JOIN은 이 "찾아보기"를 DB가 대신 해 주는 문법입니다.

### JOIN은 "짝 맞추기"다

```
 orders                               restaurants
 ┌──────────┬───────────────┐         ┌───────────────┬────────────────┐
 │ order_id │ restaurant_id │         │ restaurant_id │ name           │
 │ 7        │ 8             │ ──┐     │ 1             │ 서면옛날돼지국밥 │
 │ 17       │ 6             │ ─┐│     │ …             │ …              │
 └──────────┴───────────────┘  │└──▶  │ 8             │ 연산동짬뽕반점   │
                               └───▶  │ 6             │ 대연동크런치치킨 │
                                      └───────────────┴────────────────┘
 ON orders.restaurant_id = restaurants.restaurant_id  ← 이 조건이 참인 짝끼리 한 행으로
```

---

## 2. INNER JOIN — 짝이 있는 행만

```sql
SELECT 열 목록
FROM 테이블A
JOIN 테이블B ON A.키 = B.키;      -- JOIN = INNER JOIN
```

```sql
SELECT orders.order_id,
    orders.status,
    restaurants.name
FROM orders
JOIN restaurants ON orders.restaurant_id = restaurants.restaurant_id
ORDER BY orders.order_id;
```

<sub>▶ 실행 결과 · 563행 (상위 5행 표시)</sub>

| order_id | status | name |
|---|---|---|
| 1 | 배달완료 | 장전동든든김밥 |
| 2 | 배달완료 | 해운대명가밀면 |
| 3 | 배달완료 | 광안리브런치카페 |
| 4 | 배달완료 | 서면옛날돼지국밥 |
| 5 | 배달완료 | 해운대명가밀면 |


### 2-1. 테이블 별칭

테이블 이름을 매번 쓰면 길어집니다. `FROM orders o`처럼 **짧은 별칭**을 붙이고 `o.열`로 씁니다.

```sql
SELECT o.order_id,
    o.status,
    r.name AS restaurant_name
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
ORDER BY o.order_id;
```

<sub>▶ 실행 결과 · 563행 (상위 5행 표시)</sub>

| order_id | status | restaurant_name |
|---|---|---|
| 1 | 배달완료 | 장전동든든김밥 |
| 2 | 배달완료 | 해운대명가밀면 |
| 3 | 배달완료 | 광안리브런치카페 |
| 4 | 배달완료 | 서면옛날돼지국밥 |
| 5 | 배달완료 | 해운대명가밀면 |


> 별칭은 의미가 보이는 한두 글자로: `orders o`, `order_items oi`, `restaurants r`, `customers c`, `menus m`, `riders rd`.
> 테이블에 별칭을 붙였으면 그 쿼리 안에서는 **별칭으로만** 불러야 합니다. `orders.order_id`라고 쓰면 1054 에러.

### 2-2. ⚠️ 1052 — 이름이 겹치는 열

`restaurants`에도 `name`, `menus`에도 `name`이 있습니다. 어느 쪽인지 말하지 않으면:

```sql
SELECT name, price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1052. Column 'name' in field list is ambiguous
```


```sql
SELECT r.name AS restaurant_name,
    m.name AS menu_name,
    m.price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
ORDER BY m.menu_id;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| restaurant_name | menu_name | price |
|---|---|---|
| 서면옛날돼지국밥 | 돼지국밥 | 10000 |
| 서면옛날돼지국밥 | 순대국밥 | 10000 |
| 서면옛날돼지국밥 | 섞어국밥 | 10500 |
| 서면옛날돼지국밥 | 수육 백반 | 13000 |
| 서면옛날돼지국밥 | 수육 (중) | 22000 |


> **규칙: JOIN 쿼리에서는 모든 열 앞에 별칭을 붙인다.** 지금은 겹치지 않는 열이라도, 나중에 테이블에 같은 이름의 열이 추가되면 갑자기 1052가 납니다. 결과 열에도 `restaurant_name`, `menu_name`처럼 **별칭을 붙여** 구분하세요.

### 2-3. INNER JOIN은 짝이 없는 행을 버린다

```sql
SELECT COUNT(*) AS all_orders FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| all_orders |
|---|
| 563 |


```sql
SELECT COUNT(*) AS orders_with_rider
FROM orders o
JOIN riders rd ON o.rider_id = rd.rider_id;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_with_rider |
|---|
| 512 |


51건이 사라졌습니다. `rider_id`가 NULL인 주문(취소·조리중·접수)은 `riders`에 짝이 없으니 INNER JOIN 결과에서 빠집니다. **"모든 주문"을 보고 싶은데 INNER JOIN을 쓰면 조용히 행이 줄어듭니다.** 해결책은 5절의 LEFT JOIN입니다.

---

## 3. 여러 테이블 잇기

JOIN은 사슬처럼 이어 붙입니다. **앞에서 만든 결과에 다음 테이블을 붙인다**고 생각하세요.

```
 customers ◀─ orders ─▶ restaurants
                 │
                 ▼
            order_items ─▶ menus
```

### 3-1. 주문 7번을 한 화면에

```sql
SELECT o.order_id,
    o.ordered_at,
    c.name AS customer_name,
    r.name AS restaurant_name,
    m.name AS menu_name,
    oi.quantity,
    oi.unit_price
FROM orders o
JOIN customers c    ON o.customer_id   = c.customer_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN menus m        ON oi.menu_id      = m.menu_id
WHERE o.order_id = 7
ORDER BY oi.order_item_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| order_id | ordered_at | customer_name | restaurant_name | menu_name | quantity | unit_price |
|---|---|---|---|---|---|---|
| 7 | 2026-01-03 11:32:53 | 김민준 | 연산동짬뽕반점 | 탕수육 (소) | 1 | 16000 |
| 7 | 2026-01-03 11:32:53 | 김민준 | 연산동짬뽕반점 | 군만두 (8개) | 1 | 6000 |
| 7 | 2026-01-03 11:32:53 | 김민준 | 연산동짬뽕반점 | 짜장면 | 1 | 7000 |


Ch01 1절의 스프레드시트 한 줄이 다섯 테이블에서 다시 조립됐습니다. **주문 1건이 3행**이 된 이유는 주문 상세가 3줄이기 때문입니다. 이 사실이 7절의 함정으로 이어집니다.

### 3-2. ON 조건을 쓰는 순서

1. 무엇을 보고 싶은지 **결과 열**을 정한다 (고객 이름, 가게 이름, 메뉴명…)
2. 그 열이 있는 **테이블**을 모은다
3. 테이블 사이의 **다리**(기본키–외래키)를 ERD에서 찾는다 → [database/README.md](../../database/README.md)
4. `FROM`은 중심 테이블(보통 `orders`)부터, 다리를 하나씩 `JOIN … ON`

> ON 조건을 빠뜨리면 MySQL은 에러 대신 **모든 조합**(15곳 × 563건 = 8,445행)을 만듭니다. 결과 행 수가 이상하게 많으면 ON부터 확인하세요.

### 3-3. USING — 열 이름이 같을 때의 축약

양쪽 키 이름이 똑같으면 `ON a.x = b.x` 대신 `USING (x)`로 쓸 수 있습니다. 이 DB는 외래키 이름을 참조하는 기본키와 같게 지어서(`orders.customer_id` → `customers.customer_id`) `USING`을 쓸 수 있습니다.

```sql
SELECT o.order_id, c.name AS customer_name
FROM orders o
JOIN customers c USING (customer_id)
ORDER BY o.order_id;
```

<sub>▶ 실행 결과 · 563행 (상위 3행 표시)</sub>

| order_id | customer_name |
|---|---|
| 1 | 윤지아 |
| 2 | 서지우 |
| 3 | 이서연 |


> 이 과정은 조건이 눈에 보이는 `ON`을 기본으로 씁니다. 회사 DB는 키 이름이 다른 경우(`orders.cust_no` ↔ `customer.id`)가 많기 때문입니다.

---

## 4. JOIN과 WHERE·ORDER BY

JOIN 결과는 하나의 큰 표입니다. 그 뒤는 지금까지 배운 것과 똑같습니다.

```sql
SELECT o.order_id,
    o.ordered_at,
    c.name AS customer_name,
    r.name AS restaurant_name,
    o.status
FROM orders o
JOIN customers c   ON o.customer_id   = c.customer_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE r.category = '치킨'
    AND o.ordered_at >= '2026-06-27'
ORDER BY o.ordered_at;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | ordered_at | customer_name | restaurant_name | status |
|---|---|---|---|---|
| 551 | 2026-06-27 19:21:59 | 정다인 | 대연동크런치치킨 | 배달완료 |


> 조건에 다른 테이블의 열(`r.category`)을 쓸 수 있는 것도 JOIN 덕분입니다. "치킨 가게의 주문"을 `orders`만으로는 고를 수 없었습니다.

---

## 5. LEFT JOIN — 짝이 없어도 왼쪽은 남긴다

```sql
FROM 왼쪽 LEFT JOIN 오른쪽 ON …
```

- 왼쪽 테이블의 행은 **전부** 남깁니다.
- 오른쪽에 짝이 없으면 오른쪽 열을 **NULL**로 채웁니다.

```
 INNER JOIN                       LEFT JOIN
 고객 ──짝── 주문   → 남김          고객 ──짝── 주문   → 남김
 고객 ──(없음)      → 버림          고객 ──(없음)      → 남김, 주문 열은 NULL
```

### 5-1. 모든 주문과 담당 기사

```sql
SELECT o.order_id,
    o.status,
    rd.name AS rider_name
FROM orders o
LEFT JOIN riders rd ON o.rider_id = rd.rider_id
WHERE o.ordered_at >= '2026-06-30'
ORDER BY o.order_id;
```

<sub>▶ 실행 결과 · 6행</sub>

| order_id | status | rider_name |
|---|---|---|
| 558 | 배달완료 | 배성진 |
| 559 | 배달완료 | 하민호 |
| 560 | 배달완료 | 천동현 |
| 561 | 배달중 | 전유나 |
| 562 | 조리중 | NULL |
| 563 | 접수 | NULL |


2-3절에서 INNER JOIN으로 사라졌던 조리중·접수 주문이 `rider_name = NULL`로 남았습니다.

### 5-2. 짝이 없는 행 찾기 — LEFT JOIN + IS NULL

"한 번도 주문하지 않은 고객"은 **주문 쪽 짝이 없는 고객**입니다.

```sql
SELECT c.customer_id,
    c.name,
    c.joined_at
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| customer_id | name | joined_at |
|---|---|---|
| 28 | 강도윤 | 2023-07-30 22:05:41 |
| 29 | 조은서 | 2024-10-09 14:47:26 |
| 30 | 윤서아 | 2026-06-28 16:20:03 |


> 짝이 없으면 오른쪽의 **모든 열이 NULL**이 됩니다. 그중 원래 NULL일 수 없는 열(기본키 `o.order_id`)로 검사하는 게 정석입니다. `o.rider_id IS NULL`로 검사하면 기사가 없는 정상 주문까지 걸립니다.
>
> 윤서아 님은 6월 28일 가입한 신규 고객, 강도윤·조은서 님은 가입한 지 오래됐는데 주문이 없는 고객입니다. 같은 "0건"이라도 마케팅 메시지가 달라야겠죠.

입점 후 주문이 없는 가게도 같은 방법으로 찾습니다.

```sql
SELECT r.name, r.opened_at
FROM restaurants r
LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
WHERE o.order_id IS NULL;
```

<sub>▶ 실행 결과 · 1행</sub>

| name | opened_at |
|---|---|
| 전포동오일파스타 | 2026-06-24 |


### 5-3. RIGHT JOIN

`A RIGHT JOIN B`는 `B LEFT JOIN A`와 같습니다. 방향만 반대라 실무에서는 **LEFT JOIN으로 통일**하고 테이블 순서를 바꿔 씁니다. 정보처리기사에는 나오니 이름만 기억해 두세요.

---

## 6. ⚠️ LEFT JOIN에서 ON과 WHERE는 다르다

> **요청**: 고객별 **취소 주문 수**를 주세요. 취소가 없는 고객도 0으로 나와야 합니다.

조건을 WHERE에 쓰면:

```sql
SELECT c.name,
    COUNT(o.order_id) AS canceled
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = '취소'
GROUP BY c.customer_id, c.name
ORDER BY canceled, c.customer_id;
```

<sub>▶ 실행 결과 · 22행 (상위 5행 표시)</sub>

| name | canceled |
|---|---|
| 최수아 | 1 |
| 윤지아 | 1 |
| 한예린 | 1 |
| 서지우 | 1 |
| 안소율 | 1 |


0건인 고객이 하나도 없습니다. 실행 순서를 따라가 보면:

1. LEFT JOIN으로 **모든 고객**이 남음 (짝 없는 고객은 `o.status = NULL`)
2. `WHERE o.status = '취소'`가 **취소 주문이 있는 행만** 남김 → NULL인 행도, 배달완료 행도 사라짐
3. 결국 INNER JOIN과 같은 결과

조건을 **ON에** 넣으면 "짝을 맞출 때 취소 주문만 짝으로 인정"한다는 뜻이 됩니다.

```sql
SELECT c.name,
    COUNT(o.order_id) AS canceled
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.status = '취소'
GROUP BY c.customer_id, c.name
ORDER BY canceled, c.customer_id;
```

<sub>▶ 실행 결과 · 30행 (상위 5행 표시)</sub>

| name | canceled |
|---|---|
| 신동욱 | 0 |
| 권나연 | 0 |
| 홍채원 | 0 |
| 김서준 | 0 |
| 정다인 | 0 |


```sql
SELECT COUNT(*) AS customers_total,
    SUM(CASE WHEN canceled = 0 THEN 1 ELSE 0 END) AS never_canceled
FROM (
    SELECT c.customer_id, COUNT(o.order_id) AS canceled
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = '취소'
    GROUP BY c.customer_id
) t;
```

<sub>▶ 실행 결과 · 1행</sub>

| customers_total | never_canceled |
|---|---|
| 30 | 8 |


> **규칙**
> - **오른쪽 테이블**을 거르는 조건 → `ON`에 (왼쪽 행은 그대로 남음)
> - **왼쪽 테이블**을 거르거나, 최종 결과를 거르는 조건 → `WHERE`에
> - INNER JOIN에서는 ON이든 WHERE든 결과가 같습니다. 차이는 LEFT JOIN에서만 생깁니다.
>
> 마지막 쿼리의 `FROM ( … ) t`는 쿼리 결과를 표처럼 쓰는 **FROM절 서브쿼리**입니다. Ch06에서 자세히 배웁니다.

---

## 7. JOIN + GROUP BY — 그리고 행이 불어나는 함정

### 7-1. 가게 이름으로 매출 순위

Ch04에서 못 했던 것을 드디어 합니다. 주문(상태) – 주문 상세(금액) – 가게(이름)를 잇고 가게별로 묶습니다.

```sql
SELECT r.name AS restaurant_name,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity * oi.unit_price) AS food_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY food_sales DESC;
```

<sub>▶ 실행 결과 · 14행</sub>

| restaurant_name | delivered_orders | food_sales |
|---|---|---|
| 대연동크런치치킨 | 50 | 2131000 |
| 광안리화덕피자 | 51 | 2097000 |
| 서면옛날돼지국밥 | 65 | 1875500 |
| 남천동마라공방 | 37 | 1616000 |
| 전포카츠 | 53 | 1490000 |
| 광안리브런치카페 | 34 | 1041500 |
| 연산동짬뽕반점 | 41 | 1006000 |
| 장전동든든김밥 | 55 | 840000 |
| 해운대스시하루 | 19 | 811000 |
| 해운대명가밀면 | 28 | 720000 |
| 동래파전골목집 | 20 | 720000 |
| 하단버거스탠드 | 29 | 596900 |
| 남포동떡볶이연구소 | 20 | 381000 |
| 서면야식치킨 | 9 | 351000 |


> `GROUP BY r.restaurant_id, r.name` — 이름이 같은 가게가 생겨도 섞이지 않도록 **기본키로 묶고**, 보여 줄 이름도 함께 GROUP BY에 넣습니다.
> 주문 수를 `COUNT(*)`가 아니라 `COUNT(DISTINCT o.order_id)`로 센 이유가 다음 절입니다.

### 7-2. ⚠️ fan-out — JOIN하면 행이 불어난다

배달팁 합계를 같이 보려고 위 쿼리에 `SUM(o.delivery_fee)`를 추가하면?

```sql
SELECT COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.delivery_fee) AS fee_sum_wrong
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료';
```

<sub>▶ 실행 결과 · 1행</sub>

| joined_rows | orders | fee_sum_wrong |
|---|---|---|
| 961 | 511 | 2195000 |


```sql
SELECT COUNT(*) AS orders,
    SUM(delivery_fee) AS fee_sum_right
FROM orders
WHERE status = '배달완료';
```

<sub>▶ 실행 결과 · 1행</sub>

| orders | fee_sum_right |
|---|---|
| 511 | 1222500 |


배달팁이 **거의 두 배**로 부풀었습니다. 주문 7번처럼 메뉴가 3줄인 주문은 JOIN 후 3행이 되고, 주문에 하나뿐인 배달팁이 **3번 더해졌기** 때문입니다.

```
 orders (1행)              JOIN order_items (3줄)        → 3행
 order_id │ delivery_fee     order_id │ delivery_fee │ menu
 7        │ 2000             7        │ 2000         │ 짜장면
                             7        │ 2000         │ 탕수육   ← 같은 2000이
                             7        │ 2000         │ 군만두   ← 세 번
```

> **규칙: "1 : N"으로 JOIN한 뒤에는 "1" 쪽의 값을 SUM하지 않는다.**
> - 건수는 `COUNT(DISTINCT 기본키)`
> - "1" 쪽 금액(배달팁·할인)은 JOIN 없이 따로 집계하거나, N 쪽을 먼저 주문 단위로 묶은 뒤 JOIN (Ch06 FROM절 서브쿼리)
> - 이 실수는 에러가 나지 않습니다. **결과 행 수와 합계를 원본과 대조하는 습관**만이 막아 줍니다.

---

## 8. SELF JOIN · CROSS JOIN

### 8-1. SELF JOIN — 같은 테이블끼리

같은 테이블을 별칭 두 개로 불러 서로 짝을 맞춥니다. "같은 구에 사는 고객 쌍"(동네 공동 주문 이벤트 후보):

```sql
SELECT a.name AS customer_a,
    b.name AS customer_b,
    a.district
FROM customers a
JOIN customers b
    ON a.district = b.district
    AND a.customer_id < b.customer_id
WHERE a.district = '금정구'
ORDER BY a.customer_id, b.customer_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| customer_a | customer_b | district |
|---|---|---|
| 최수아 | 한예린 | 금정구 |
| 최수아 | 김서준 | 금정구 |
| 한예린 | 김서준 | 금정구 |


> `a.customer_id < b.customer_id`가 없으면 (최수아, 최수아) 같은 자기 자신과의 쌍과, (A, B)·(B, A) 중복 쌍이 모두 나옵니다.

### 8-2. CROSS JOIN — 모든 조합

ON 없이 모든 행끼리 짝을 지어 **행 수 × 행 수**를 만듭니다. 실수로 만들면 재앙이지만, 의도적으로 쓰면 "빈칸까지 있는 표의 뼈대"가 됩니다.

```sql
SELECT COUNT(*) AS combinations
FROM restaurants r
CROSS JOIN riders rd;
```

<sub>▶ 실행 결과 · 1행</sub>

| combinations |
|---|
| 120 |


> 15곳 × 8명 = 120. "월 × 가게" 뼈대를 만들고 매출을 LEFT JOIN하면 **주문이 없던 달도 0으로 표시**되는 리포트를 만들 수 있습니다(Ch06 실습).

### JOIN 종류 한눈에

| 종류 | 결과에 남는 행 | 주 용도 |
|---|---|---|
| `INNER JOIN` | 양쪽 모두 짝이 있는 행 | 일반적인 조회 |
| `LEFT JOIN` | 왼쪽 전부 + 오른쪽 짝(없으면 NULL) | "없는 것" 찾기, 0건 포함 집계 |
| `RIGHT JOIN` | 오른쪽 전부 | LEFT로 바꿔 쓰기 |
| `CROSS JOIN` | 모든 조합 | 뼈대 만들기 |
| SELF JOIN | 같은 테이블끼리 | 같은 구 고객, 계층 구조 |

> MySQL에는 `FULL OUTER JOIN`이 없습니다. 필요하면 LEFT JOIN과 RIGHT JOIN 결과를 `UNION`으로 합칩니다(Ch06).

---

## 9. 오늘의 요청 해결

### ① 가게 이름으로 음식 매출 순위 — 7-1절

### ② 월별 음식 매출

```sql
SELECT DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity * oi.unit_price) AS food_sales,
    ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id)) AS avg_food_per_order
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
```

<sub>▶ 실행 결과 · 6행</sub>

| order_month | delivered_orders | food_sales | avg_food_per_order |
|---|---|---|---|
| 2026-01 | 74 | 2523400 | 34100 |
| 2026-02 | 70 | 2079100 | 29701 |
| 2026-03 | 73 | 2116800 | 28997 |
| 2026-04 | 91 | 2879800 | 31646 |
| 2026-05 | 106 | 3157700 | 29790 |
| 2026-06 | 97 | 2920100 | 30104 |


> - 주문 건수는 Ch04 리포트의 `delivered`와 일치해야 합니다(74, 70, 73, 91, 106, 97). **다른 리포트와 숫자를 맞춰 보는 것**이 fan-out을 잡는 가장 확실한 방법입니다.
> - 객단가(주문 1건당 음식 금액)도 `SUM ÷ COUNT(DISTINCT)`로 만들었습니다. `AVG(oi.quantity * oi.unit_price)`는 **주문 상세 1줄의 평균**이라 다른 값입니다.

### ③ 주문 0건 고객 — 5-2절

## 정리

| 문법 | 핵심 |
|---|---|
| `JOIN … ON A.키 = B.키` | 조건이 참인 짝끼리 한 행으로. 기본은 INNER |
| 테이블 별칭 | `orders o` → `o.열`. 겹치는 열은 1052 |
| 여러 테이블 | 중심 테이블부터 다리를 하나씩. ON 빠뜨리면 모든 조합 |
| `LEFT JOIN` | 왼쪽 전부 유지, 짝 없으면 NULL. `오른쪽.기본키 IS NULL`로 "없는 것" 찾기 |
| ON vs WHERE | 오른쪽 거르는 조건은 ON, WHERE에 쓰면 INNER처럼 동작 |
| fan-out | 1:N JOIN 후 "1" 쪽 값을 SUM하면 부풀어 오름. `COUNT(DISTINCT)`·원본 대조 |
| SELF · CROSS | 같은 테이블끼리 · 모든 조합 |

## 다음 챕터 예고

> **From.** 마케팅팀 이 매니저
> 이번 달 VIP 혜택 대상은 **"평균 객단가보다 많이 쓰는 고객"**으로 하자는 의견이 나왔어요. 그리고 **가게마다 가장 많이 팔린 메뉴 1등**도 알고 싶어요.

"평균보다 큰"을 쓰려면 평균을 **먼저** 구해야 하고, "가게마다 1등"은 GROUP BY만으로는 메뉴 이름을 뽑을 수 없습니다(1055). 쿼리 안에 쿼리를 넣는 법, 그리고 순위를 매기는 법 — Ch06입니다.

<!-- lecture:auto -->
