# Ch04 실습 — 숫자로 요약하기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery04;` · 기준일 `'2026-06-30'`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전 · 열 이름은 문제에 지정된 별칭을 쓰세요.
> "매출·완료 건수"처럼 실적을 묻는 문제는 특별한 말이 없으면 **배달 완료(`status = '배달완료'`) 주문만** 셉니다.

---

### 문제 1. 메뉴 가격 요약 ★

> **운영팀** 전체 메뉴의 개수, 최저가, 최고가, 평균가를 주세요. 평균가는 **원 단위 반올림**입니다.

- 열: `menu_count`, `min_price`, `max_price`, `avg_price`

**정답 SQL**

```sql
SELECT COUNT(*) AS menu_count,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price)) AS avg_price
FROM menus;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_count | min_price | max_price | avg_price |
|---|---|---|---|
| 70 | 3000 | 45000 | 11840 |


### 문제 2. 업종별 가게 수 ★

> **운영팀** 업종별 **영업 중인** 가게 수를 많은 순으로 주세요. 같으면 업종명 가나다순입니다.

- 열: `category`, `restaurant_count`

**정답 SQL**

```sql
SELECT category,
    COUNT(*) AS restaurant_count
FROM restaurants
WHERE is_open = TRUE
GROUP BY category
ORDER BY restaurant_count DESC, category;
```

<sub>▶ 실행 결과 · 8행</sub>

| category | restaurant_count |
|---|---|
| 한식 | 3 |
| 분식 | 2 |
| 양식 | 2 |
| 일식 | 2 |
| 중식 | 2 |
| 치킨 | 1 |
| 카페·디저트 | 1 |
| 피자 | 1 |


> **해설** 폐업한 서면야식치킨은 WHERE에서 먼저 빠졌기 때문에 치킨 업종이 1곳으로 집계됩니다.

### 문제 3. 별점 분포 ★

> **CS팀** 별점별 리뷰 수를 5점부터 1점 순으로 주세요. 내용 없이 별점만 남긴 리뷰가 몇 개인지도 같이 주세요.

- 열: `rating`, `review_count`, `rating_only`

**정답 SQL**

```sql
SELECT rating,
    COUNT(*) AS review_count,
    COUNT(*) - COUNT(content) AS rating_only
FROM reviews
GROUP BY rating
ORDER BY rating DESC;
```

<sub>▶ 실행 결과 · 5행</sub>

| rating | review_count | rating_only |
|---|---|---|
| 5 | 94 | 11 |
| 4 | 112 | 29 |
| 3 | 40 | 8 |
| 2 | 12 | 1 |
| 1 | 2 | 1 |


> **해설** `COUNT(*)`는 행 수, `COUNT(content)`는 내용이 있는 행 수이므로 둘의 차이가 내용이 NULL인 리뷰 수입니다. `SUM(CASE WHEN content IS NULL THEN 1 ELSE 0 END)`로도 같은 결과입니다.

### 문제 4. 리뷰 평균 별점 ★

> **CS팀** 전체 리뷰의 평균 별점(소수 둘째 자리 반올림), 리뷰 수, 리뷰가 달린 주문의 비율을 알고 싶어요. 비율은 **배달 완료 주문 대비 %**(소수 첫째 자리)이고, 배달 완료 주문 수는 511건입니다.

- 열: `avg_rating`, `review_count`, `review_rate`

**정답 SQL**

```sql
SELECT ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100 / 511, 1) AS review_rate
FROM reviews;
```

<sub>▶ 실행 결과 · 1행</sub>

| avg_rating | review_count | review_rate |
|---|---|---|
| 4.09 | 260 | 50.9 |


> **해설** 511이라는 숫자를 직접 쓴 것이 마음에 걸린다면 좋은 감각입니다. 데이터가 바뀌면 틀린 값이 되니까요. 다른 테이블의 집계값을 쿼리 안에서 가져오는 방법(서브쿼리)은 Ch06에서 배웁니다.

### 문제 5. 등급별 고객 현황 ★★

> **마케팅팀** 회원 등급별 인원과 그중 **마케팅 수신 동의** 인원, **이메일 등록** 인원을 주세요. 등급은 VIP → 골드 → 실버 → 일반 순입니다.
> 힌트: 등급 순서는 가나다순이 아니므로 `CASE`로 정렬 순서를 만드세요.

- 열: `grade`, `members`, `marketing_agreed`, `with_email`

**정답 SQL**

```sql
SELECT grade,
    COUNT(*) AS members,
    SUM(marketing_agreed) AS marketing_agreed,
    COUNT(email) AS with_email
FROM customers
GROUP BY grade
ORDER BY CASE grade
        WHEN 'VIP' THEN 1
        WHEN '골드' THEN 2
        WHEN '실버' THEN 3
        ELSE 4
    END;
```

<sub>▶ 실행 결과 · 4행</sub>

| grade | members | marketing_agreed | with_email |
|---|---|---|---|
| VIP | 3 | 2 | 3 |
| 골드 | 5 | 3 | 5 |
| 실버 | 7 | 4 | 5 |
| 일반 | 15 | 7 | 11 |


> **해설** `marketing_agreed`는 1/0으로 저장된 BOOLEAN이라 `SUM`하면 동의한 인원이 됩니다. ORDER BY에도 CASE 같은 식을 쓸 수 있습니다. 같은 결과를 `FIELD(grade, 'VIP', '골드', '실버', '일반')`(MySQL 전용)으로도 만들 수 있습니다.

### 문제 6. 결제 수단별 실적 ★★

> **정산팀** 결제 수단별 배달 완료 건수와 **평균 할인액**(원 단위 반올림), **할인받은 주문 수**를 주세요. 건수가 많은 순입니다.

- 열: `payment_method`, `delivered_orders`, `avg_discount`, `discounted_orders`

**정답 SQL**

```sql
SELECT payment_method,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(discount_amount)) AS avg_discount,
    SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END) AS discounted_orders
FROM orders
WHERE status = '배달완료'
GROUP BY payment_method
ORDER BY delivered_orders DESC;
```

<sub>▶ 실행 결과 · 4행</sub>

| payment_method | delivered_orders | avg_discount | discounted_orders |
|---|---|---|---|
| 카드 | 229 | 406 | 45 |
| 간편결제 | 171 | 439 | 37 |
| 계좌이체 | 59 | 458 | 13 |
| 현장결제 | 52 | 385 | 11 |


### 문제 7. 피크 시간대 ★★

> **운영팀** 기사 배치를 위해 배달 완료 주문이 가장 많은 **시간대 Top 5**를 주세요. 시간대는 주문 시각의 '시'입니다.

- 열: `order_hour`, `delivered_orders`

**정답 SQL**

```sql
SELECT HOUR(ordered_at) AS order_hour,
    COUNT(*) AS delivered_orders
FROM orders
WHERE status = '배달완료'
GROUP BY order_hour
ORDER BY delivered_orders DESC, order_hour
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| order_hour | delivered_orders |
|---|---|
| 18 | 100 |
| 19 | 92 |
| 12 | 65 |
| 20 | 57 |
| 11 | 54 |


### 문제 8. 단골 고객 ★★

> **마케팅팀** 상반기에 배달 완료 주문이 **30건 이상**인 고객의 고객번호, 주문 수, 첫 주문일, 마지막 주문일을 주문 수가 많은 순으로 주세요. 날짜는 `YYYY-MM-DD` 형식입니다.

- 열: `customer_id`, `order_count`, `first_order`, `last_order`

**정답 SQL**

```sql
SELECT customer_id,
    COUNT(*) AS order_count,
    DATE_FORMAT(MIN(ordered_at), '%Y-%m-%d') AS first_order,
    DATE_FORMAT(MAX(ordered_at), '%Y-%m-%d') AS last_order
FROM orders
WHERE status = '배달완료'
GROUP BY customer_id
HAVING COUNT(*) >= 30
ORDER BY order_count DESC, customer_id;
```

<sub>▶ 실행 결과 · 5행</sub>

| customer_id | order_count | first_order | last_order |
|---|---|---|---|
| 1 | 47 | 2026-01-03 | 2026-06-29 |
| 2 | 43 | 2026-01-02 | 2026-06-27 |
| 3 | 32 | 2026-01-02 | 2026-06-21 |
| 5 | 30 | 2026-01-03 | 2026-06-28 |
| 9 | 30 | 2026-01-14 | 2026-06-28 |


> **해설** "배달 완료"는 행 조건이라 WHERE, "30건 이상"은 집계 조건이라 HAVING. 집계 결과에 함수를 씌울 수도 있습니다(`DATE_FORMAT(MIN(…))`).

### 문제 9. 큰 주문 ★★

> **정산팀** 음식 금액(주문 상세의 수량 × 단가 합계)이 가장 큰 주문 5건의 주문번호, 메뉴 줄 수, 음식 금액을 주세요. 금액이 같으면 주문번호 순입니다. (주문 상태는 따지지 않습니다)

- 열: `order_id`, `item_lines`, `food_amount`

**정답 SQL**

```sql
SELECT order_id,
    COUNT(*) AS item_lines,
    SUM(quantity * unit_price) AS food_amount
FROM order_items
GROUP BY order_id
ORDER BY food_amount DESC, order_id
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| order_id | item_lines | food_amount |
|---|---|---|
| 395 | 3 | 85000 |
| 285 | 3 | 83000 |
| 24 | 2 | 82000 |
| 47 | 2 | 82000 |
| 74 | 2 | 82000 |


### 문제 10. 가격 인상 효과 ★★

> **정산팀** 4월 1일에 돼지국밥(`menu_id = 1`) 가격이 9,000원에서 10,000원으로 올랐습니다. 주문 상세에서 돼지국밥이 **단가별로** 몇 개 팔렸는지(수량 합계), 금액은 얼마인지 주세요.

- 열: `unit_price`, `sold_quantity`, `sales_amount`

**정답 SQL**

```sql
SELECT unit_price,
    SUM(quantity) AS sold_quantity,
    SUM(quantity * unit_price) AS sales_amount
FROM order_items
WHERE menu_id = 1
GROUP BY unit_price
ORDER BY unit_price;
```

<sub>▶ 실행 결과 · 2행</sub>

| unit_price | sold_quantity | sales_amount |
|---|---|---|
| 9000 | 43 | 387000 |
| 10000 | 38 | 380000 |


> **해설** `order_items.unit_price`가 **주문 당시 가격**이기 때문에 가능한 분석입니다. 만약 주문 상세에 단가를 저장하지 않고 `menus.price`만 썼다면, 4월 이전 주문까지 전부 10,000원으로 계산되어 과거 매출이 부풀려집니다. 이 설계 판단은 Ch09에서 다시 다룹니다. (취소 주문 상세도 포함된 수치입니다 — 걸러 내려면 Ch05의 JOIN이 필요합니다)

### 문제 11. 기사별 배달 실적 ★★★

> **운영팀** 기사별 배달 완료 건수, 평균 배달 시간(분, 소수 첫째 자리), **60분 초과 지연 건수**, 지연율(%, 소수 첫째 자리)을 주세요. 건수가 많은 순입니다.

- 열: `rider_id`, `deliveries`, `avg_minutes`, `late_count`, `late_rate`

**정답 SQL**

```sql
SELECT rider_id,
    COUNT(*) AS deliveries,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)), 1) AS avg_minutes,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60 THEN 1 ELSE 0 END) AS late_count,
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60 THEN 1 ELSE 0 END) * 100 / COUNT(*), 1) AS late_rate
FROM orders
WHERE status = '배달완료'
GROUP BY rider_id
ORDER BY deliveries DESC, rider_id;
```

<sub>▶ 실행 결과 · 8행</sub>

| rider_id | deliveries | avg_minutes | late_count | late_rate |
|---|---|---|---|---|
| 1 | 161 | 32.3 | 4 | 2.5 |
| 2 | 112 | 32.8 | 2 | 1.8 |
| 3 | 85 | 31.7 | 1 | 1.2 |
| 4 | 50 | 40.1 | 0 | 0.0 |
| 8 | 41 | 33.4 | 2 | 4.9 |
| 6 | 32 | 34.1 | 2 | 6.3 |
| 5 | 22 | 34.3 | 1 | 4.5 |
| 7 | 8 | 51.0 | 0 | 0.0 |


> **해설** 7번 기사(도보)는 평균 배달 시간이 길지만 건수가 적습니다. 운송 수단이 다르니 오토바이 기사와 단순 비교하면 안 됩니다 — 숫자를 해석할 때는 **비교 대상이 같은 조건인지** 먼저 확인하세요. 기사 이름과 운송 수단을 함께 보려면 `riders`와 JOIN해야 합니다(Ch05).

### 문제 12. 월 × 결제 수단 피벗 ★★★

> **정산팀** 월별로 결제 수단별 배달 완료 건수를 **가로로 펼친 표**로 주세요. 마지막 열은 그 달의 합계입니다.

- 열: `order_month`, `card`, `easy_pay`, `transfer`, `on_site`, `total`

**정답 SQL**

```sql
SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,
    SUM(CASE WHEN payment_method = '카드' THEN 1 ELSE 0 END) AS card,
    SUM(CASE WHEN payment_method = '간편결제' THEN 1 ELSE 0 END) AS easy_pay,
    SUM(CASE WHEN payment_method = '계좌이체' THEN 1 ELSE 0 END) AS transfer,
    SUM(CASE WHEN payment_method = '현장결제' THEN 1 ELSE 0 END) AS on_site,
    COUNT(*) AS total
FROM orders
WHERE status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
```

<sub>▶ 실행 결과 · 6행</sub>

| order_month | card | easy_pay | transfer | on_site | total |
|---|---|---|---|---|---|
| 2026-01 | 27 | 26 | 8 | 13 | 74 |
| 2026-02 | 34 | 26 | 6 | 4 | 70 |
| 2026-03 | 33 | 19 | 15 | 6 | 73 |
| 2026-04 | 40 | 30 | 13 | 8 | 91 |
| 2026-05 | 47 | 35 | 13 | 11 | 106 |
| 2026-06 | 48 | 35 | 4 | 10 | 97 |


> **해설** 세로로 길게 나오는 `GROUP BY 월, 결제수단` 결과(24행)를 조건부 집계로 **가로로 펼치는** 기법을 피벗(pivot)이라고 합니다. 엑셀 피벗 테이블과 같은 모양을 SQL로 만드는 방법이고, 실무 리포트 쿼리에서 매우 자주 씁니다. 4월부터 전체 주문이 늘면서 카드·간편결제가 함께 늘어난 것이 한눈에 보이나요? 이렇게 펼쳐야 추세가 읽힙니다.
