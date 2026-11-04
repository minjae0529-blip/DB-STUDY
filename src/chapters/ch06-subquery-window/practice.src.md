# Ch06 실습 — 쿼리 안의 쿼리, 그리고 순위

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE {{DB}};` · 기준일 `'2026-06-30'`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전 · 열 이름은 문제에 지정된 별칭을 쓰세요.
> "매출"은 배달 완료 주문의 음식 금액(`quantity × unit_price`) 합계입니다.
> **숫자를 직접 타이핑하지 마세요.** 평균·최댓값·건수 같은 기준값은 서브쿼리로 구합니다.

---

### 문제 1. 최고가 메뉴 ★

> **운영팀** 가장 비싼 메뉴와 **같은 가격**인 메뉴를 가게 번호와 함께 주세요.

- 열: `restaurant_id`, `name`, `price`

```sql answer
SELECT restaurant_id, name, price
FROM menus
WHERE price = (SELECT MAX(price) FROM menus);
```

<!-- a:start -->
> **해설** `ORDER BY price DESC LIMIT 1`은 최고가가 여러 개일 때 하나만 보여 줍니다. "최댓값과 같은 것 전부"는 서브쿼리가 정확합니다.
<!-- a:end -->

### 문제 2. 리뷰가 있는 가게 ★

> **CS팀** 리뷰가 **하나라도** 달린 가게의 이름을 가게 번호 순으로 주세요. (리뷰는 주문을 거쳐 가게와 연결됩니다)

- 열: `restaurant_id`, `name`

```sql answer limit=15
SELECT r.restaurant_id, r.name
FROM restaurants r
WHERE EXISTS (
    SELECT 1
    FROM reviews rv
    JOIN orders o ON rv.order_id = o.order_id
    WHERE o.restaurant_id = r.restaurant_id
)
ORDER BY r.restaurant_id;
```

<!-- a:start -->
> **해설** JOIN으로 쓰면 리뷰 수만큼 가게가 반복되므로 `DISTINCT`가 필요합니다. "있나 없나"만 궁금할 때는 EXISTS가 의도를 가장 잘 드러냅니다. 리뷰가 없는 가게는 신규 입점한 전포동오일파스타 한 곳입니다.
<!-- a:end -->

### 문제 3. 가장 최근 주문 ★

> **CS팀** 가장 최근에 들어온 주문의 주문번호, 주문 시각, 고객 이름, 상태를 주세요.

- 열: `order_id`, `ordered_at`, `customer_name`, `status`

```sql answer
SELECT o.order_id, o.ordered_at, c.name AS customer_name, o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.ordered_at = (SELECT MAX(ordered_at) FROM orders);
```

### 문제 4. 리뷰 작성률, 이번엔 제대로 ★

> **CS팀** Ch04 실습 4번에서 배달 완료 주문 수 `511`을 직접 타이핑했습니다. 서브쿼리로 바꿔 리뷰 수와 리뷰 작성률(%, 소수 첫째 자리)을 다시 구하세요.

- 열: `review_count`, `delivered_orders`, `review_rate`

```sql answer
SELECT COUNT(*) AS review_count,
    (SELECT COUNT(*) FROM orders WHERE status = '배달완료') AS delivered_orders,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM orders WHERE status = '배달완료'), 1) AS review_rate
FROM reviews;
```

### 문제 5. 6월에 사라진 고객 ★★

> **마케팅팀** **6월 1일 이전에 가입**했지만 **6월에는 주문이 한 건도 없는** 고객을 가입일 순으로 주세요. (주문 상태 무관)

- 열: `name`, `joined_at`

```sql answer
SELECT c.name, c.joined_at
FROM customers c
WHERE c.joined_at < '2026-06-01'
    AND NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = c.customer_id
            AND o.ordered_at >= '2026-06-01'
            AND o.ordered_at <  '2026-07-01'
    )
ORDER BY c.joined_at;
```

<!-- a:start -->
> **해설** 상관 서브쿼리 안에서 기간 조건도 함께 겁니다. `NOT IN (SELECT customer_id FROM orders WHERE …)`도 이 경우엔 동작합니다(`customer_id`는 NOT NULL). 하지만 습관적으로 NOT EXISTS를 쓰면 NULL 함정을 걱정할 필요가 없습니다.
<!-- a:end -->

### 문제 6. 업종 평균보다 문턱이 높은 가게 ★★

> **운영팀** **같은 업종의 평균** 최소 주문 금액보다 최소 주문 금액이 **높은** 가게를 주세요. 업종 평균도 함께 보여 주세요. (원 단위 반올림)

- 열: `name`, `category`, `min_order_amount`, `category_avg`

```sql answer
SELECT r.name,
    r.category,
    r.min_order_amount,
    (SELECT ROUND(AVG(r2.min_order_amount)) FROM restaurants r2 WHERE r2.category = r.category) AS category_avg
FROM restaurants r
WHERE r.min_order_amount > (
    SELECT AVG(r2.min_order_amount)
    FROM restaurants r2
    WHERE r2.category = r.category
)
ORDER BY r.category, r.name;
```

<!-- a:start -->
> **해설** 같은 상관 서브쿼리를 SELECT와 WHERE에 두 번 썼습니다. CTE로 업종별 평균을 먼저 구해 JOIN하면 한 번만 쓸 수 있습니다. 가게가 한 곳뿐인 업종(피자 등)은 자기 자신이 평균이라 나올 수 없습니다.
<!-- a:end -->

### 문제 7. 결제 금액 Top 5 ★★

> **정산팀** 배달 완료 주문 중 **결제 금액**(음식 금액 + 배달팁 − 할인액)이 가장 큰 5건을 주세요. 같으면 주문번호 순입니다.

- 열: `order_id`, `food_amount`, `delivery_fee`, `discount_amount`, `paid_amount`

```sql answer
WITH order_food AS (
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
)
SELECT o.order_id,
    f.food_amount,
    o.delivery_fee,
    o.discount_amount,
    f.food_amount + o.delivery_fee - o.discount_amount AS paid_amount
FROM orders o
JOIN order_food f ON o.order_id = f.order_id
WHERE o.status = '배달완료'
ORDER BY paid_amount DESC, o.order_id
LIMIT 5;
```

<!-- a:start -->
> **해설** 음식 금액이 5만 원 이상이면 배달팁이 0원(무료 배달)이라는 정책이 결과에 보입니다. 주문 상세를 먼저 주문 단위로 묶었기 때문에 배달팁·할인액이 부풀지 않습니다.
<!-- a:end -->

### 문제 8. 휴면 위험 고객 ★★

> **마케팅팀** 고객별 **마지막 주문일**과 6월 30일까지 **경과일**을 구하고, 경과일이 **30일 이상**인 고객만 경과일이 긴 순으로 주세요. 주문 이력이 있는 고객만 대상입니다.

- 열: `name`, `last_order_date`, `days_since_last`

```sql answer
WITH last_order AS (
    SELECT customer_id, MAX(ordered_at) AS last_ordered_at
    FROM orders
    GROUP BY customer_id
)
SELECT c.name,
    DATE(lo.last_ordered_at) AS last_order_date,
    DATEDIFF('2026-06-30', lo.last_ordered_at) AS days_since_last
FROM last_order lo
JOIN customers c ON lo.customer_id = c.customer_id
WHERE DATEDIFF('2026-06-30', lo.last_ordered_at) >= 30
ORDER BY days_since_last DESC;
```

<!-- a:start -->
> **해설** 신동욱 님은 2월 이후 주문이 없습니다. 실무의 휴면 고객 관리 쿼리가 이런 모양입니다. 주문 0건 고객까지 포함하려면 `customers`를 기준으로 LEFT JOIN하면 됩니다.
<!-- a:end -->

### 문제 9. 가게 매출 순위와 점유율 ★★

> **정산팀** 가게별 매출에 **순위**와 **전체 매출 대비 비율**(%, 소수 첫째 자리)을 붙여 주세요. 매출이 있는 가게만, 순위 순입니다.

- 열: `sales_rank`, `restaurant_name`, `food_sales`, `share_pct`

```sql answer limit=15
WITH store_sales AS (
    SELECT o.restaurant_id,
        SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.restaurant_id
)
SELECT RANK() OVER (ORDER BY ss.food_sales DESC) AS sales_rank,
    r.name AS restaurant_name,
    ss.food_sales,
    ROUND(ss.food_sales * 100 / SUM(ss.food_sales) OVER (), 1) AS share_pct
FROM store_sales ss
JOIN restaurants r ON ss.restaurant_id = r.restaurant_id
ORDER BY sales_rank;
```

<!-- a:start -->
> **해설** `SUM(…) OVER ()`는 전체 합계를 모든 행 옆에 붙여 줍니다. 서브쿼리 `(SELECT SUM(food_sales) FROM store_sales)`로 나눠도 같은 결과입니다. 상위 3개 가게가 전체 매출의 약 40%를 차지합니다.
<!-- a:end -->

### 문제 10. 고객의 첫 주문 가게 ★★★

> **마케팅팀** 고객마다 **가장 처음 주문한 가게**를 알려 주세요. (주문 상태 무관, 고객 번호 순)

- 열: `customer_name`, `first_ordered_at`, `restaurant_name`

```sql answer limit=27
WITH numbered AS (
    SELECT o.customer_id,
        o.restaurant_id,
        o.ordered_at,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.ordered_at, o.order_id) AS rn
    FROM orders o
)
SELECT c.name AS customer_name,
    n.ordered_at AS first_ordered_at,
    r.name AS restaurant_name
FROM numbered n
JOIN customers c   ON n.customer_id   = c.customer_id
JOIN restaurants r ON n.restaurant_id = r.restaurant_id
WHERE n.rn = 1
ORDER BY c.customer_id;
```

<!-- a:start -->
> **해설** "그룹마다 첫 번째 행"은 `ROW_NUMBER() … PARTITION BY 그룹 ORDER BY 기준` 후 `rn = 1`이 정석입니다. `GROUP BY customer_id`와 `MIN(ordered_at)`으로는 시각은 구해도 **가게 이름**은 못 구합니다(1055).
<!-- a:end -->

### 문제 11. 업종별 Top 2 가게 ★★★

> **운영팀** 업종마다 매출 **상위 2개** 가게를 주세요. 가게가 하나뿐인 업종은 1개만 나옵니다. 업종명 가나다순, 업종 안에서는 순위 순입니다.

- 열: `category`, `category_rank`, `restaurant_name`, `food_sales`

```sql answer limit=15
WITH store_sales AS (
    SELECT r.category,
        r.restaurant_id,
        r.name AS restaurant_name,
        SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
    JOIN order_items oi ON o.order_id      = oi.order_id
    JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
    WHERE o.status = '배달완료'
    GROUP BY r.category, r.restaurant_id, r.name
),
ranked AS (
    SELECT ss.*,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY food_sales DESC, restaurant_id) AS category_rank
    FROM store_sales ss
)
SELECT category, category_rank, restaurant_name, food_sales
FROM ranked
WHERE category_rank <= 2
ORDER BY category, category_rank;
```

### 문제 12. 빈칸 없는 월별 매출표 ★★★

> **정산팀** 치킨 업종 두 가게(**대연동크런치치킨**, **서면야식치킨**)의 월별 매출을 주세요. **주문이 없는 달도 0으로** 나와야 합니다. (1~6월 × 2곳 = 12행)
> 힌트: `CROSS JOIN`으로 "월 × 가게" 뼈대를 만든 뒤 매출을 LEFT JOIN 하세요. 월 목록은 주문 데이터에서 `DISTINCT`로 뽑을 수 있습니다.

- 열: `order_month`, `restaurant_name`, `food_sales`

```sql answer limit=12
WITH months AS (
    SELECT DISTINCT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month
    FROM orders
),
stores AS (
    SELECT restaurant_id, name
    FROM restaurants
    WHERE category = '치킨'
),
sales AS (
    SELECT o.restaurant_id,
        DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.restaurant_id, order_month
)
SELECT m.order_month,
    s.name AS restaurant_name,
    IFNULL(sa.food_sales, 0) AS food_sales
FROM months m
CROSS JOIN stores s
LEFT JOIN sales sa
    ON sa.restaurant_id = s.restaurant_id
    AND sa.order_month = m.order_month
ORDER BY s.restaurant_id, m.order_month;
```

<!-- a:start -->
> **해설** 매출 테이블만 GROUP BY하면 서면야식치킨의 4~6월은 **행 자체가 없습니다.** 차트로 그리면 3월에서 선이 끊기는 게 아니라 "데이터가 없다"는 사실이 숨겨집니다. 뼈대(CROSS JOIN) + LEFT JOIN + `IFNULL(…, 0)`은 리포트에서 빈 칸을 0으로 채우는 표준 기법입니다.
<!-- a:end -->
