# Ch05 실습 — 흩어진 데이터 잇기

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE {{DB}};`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전 · 열 이름은 문제에 지정된 별칭을 쓰세요.
> "매출·판매량"은 특별한 말이 없으면 **배달 완료 주문만**, 음식 금액 = `quantity × unit_price`.
> JOIN 문제는 **결과 행 수**까지 기대 결과와 맞춰 보세요. 행 수가 다르면 ON 조건이나 JOIN 종류를 의심합니다.

---

### 문제 1. 치킨집 메뉴판 ★

> **운영팀** 업종이 **치킨**인 가게의 메뉴를 가게 이름, 메뉴명, 가격으로 주세요. 가게 번호 순, 같은 가게 안에서는 가격 높은 순입니다.

- 열: `restaurant_name`, `menu_name`, `price`

```sql answer
SELECT r.name AS restaurant_name,
    m.name AS menu_name,
    m.price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
WHERE r.category = '치킨'
ORDER BY r.restaurant_id, m.price DESC;
```

### 문제 2. 기사별 배달 실적 ★

> **운영팀** 기사 **이름**과 **운송 수단**별 배달 완료 건수를 많은 순으로 주세요. (Ch04 실습 11번은 기사 번호만 나왔습니다)

- 열: `rider_name`, `vehicle`, `deliveries`

```sql answer
SELECT rd.name AS rider_name,
    rd.vehicle,
    COUNT(*) AS deliveries
FROM orders o
JOIN riders rd ON o.rider_id = rd.rider_id
WHERE o.status = '배달완료'
GROUP BY rd.rider_id, rd.name, rd.vehicle
ORDER BY deliveries DESC;
```

### 문제 3. 낮은 별점 리뷰 추적 ★

> **CS팀** 별점 **2점 이하** 리뷰를 최신순으로, 어느 가게의 어떤 고객 주문인지 함께 주세요.

- 열: `review_id`, `rating`, `restaurant_name`, `customer_name`, `content`

```sql answer
SELECT rv.review_id,
    rv.rating,
    r.name AS restaurant_name,
    c.name AS customer_name,
    rv.content
FROM reviews rv
JOIN orders o      ON rv.order_id     = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
JOIN customers c   ON o.customer_id   = c.customer_id
WHERE rv.rating <= 2
ORDER BY rv.created_at DESC;
```

<!-- a:start -->
> **해설** 리뷰에는 `order_id`만 있습니다. 가게와 고객은 **주문을 거쳐서** 찾아야 합니다. 리뷰 → 주문 → 가게 / 고객처럼 중간 테이블을 다리로 쓰는 JOIN이 실무에서 가장 흔합니다.
<!-- a:end -->

### 문제 4. 진행 중 주문 현황판 ★

> **CS팀** 지금(6월 30일 19시) **진행 중인 주문**(접수·조리중·배달중)을 주문번호, 상태, 고객 이름, 가게 이름, 담당 기사 이름으로 주세요. 기사가 아직 없으면 비어 있어도 주문은 나와야 합니다.

- 열: `order_id`, `status`, `customer_name`, `restaurant_name`, `rider_name`

```sql answer
SELECT o.order_id,
    o.status,
    c.name AS customer_name,
    r.name AS restaurant_name,
    rd.name AS rider_name
FROM orders o
JOIN customers c   ON o.customer_id   = c.customer_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN riders rd ON o.rider_id     = rd.rider_id
WHERE o.status IN ('접수', '조리중', '배달중')
ORDER BY o.order_id;
```

<!-- a:start -->
> **해설** 고객·가게는 모든 주문에 반드시 있으므로 INNER, 기사는 없을 수 있으므로 LEFT. **필수 관계는 INNER, 선택 관계는 LEFT**가 기본 판단 기준입니다. 기사까지 INNER JOIN하면 1행만 나옵니다.
<!-- a:end -->

### 문제 5. 가게별 평균 별점 ★★

> **운영팀** 리뷰가 **10개 이상**인 가게의 평균 별점(소수 둘째 자리)과 리뷰 수를 평균 별점 높은 순으로 주세요.

- 열: `restaurant_name`, `avg_rating`, `review_count`

```sql answer
SELECT r.name AS restaurant_name,
    ROUND(AVG(rv.rating), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM reviews rv
JOIN orders o      ON rv.order_id     = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC;
```

### 문제 6. 메뉴 판매량 Top 5 ★★

> **운영팀** 상반기에 가장 많이 팔린 메뉴 5개를 가게 이름과 함께 주세요. 판매량 = 수량 합계, 같으면 `menu_id` 순입니다.

- 열: `restaurant_name`, `menu_name`, `sold_quantity`

```sql answer
SELECT r.name AS restaurant_name,
    m.name AS menu_name,
    SUM(oi.quantity) AS sold_quantity
FROM order_items oi
JOIN orders o      ON oi.order_id     = o.order_id
JOIN menus m       ON oi.menu_id      = m.menu_id
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY m.menu_id, m.name, r.name
ORDER BY sold_quantity DESC, m.menu_id
LIMIT 5;
```

<!-- a:start -->
> **해설** Ch04 7절의 메뉴별 판매량에는 취소 주문이 섞여 있었습니다. `orders`를 이어야 `status`로 거를 수 있습니다. 가게 이름은 메뉴를 거쳐(`m.restaurant_id`) 가져와도, 주문을 거쳐(`o.restaurant_id`) 가져와도 같습니다.
<!-- a:end -->

### 문제 7. 업종별 음식 매출 ★★

> **정산팀** 업종별 음식 매출과 배달 완료 주문 수를 매출 높은 순으로 주세요.

- 열: `category`, `delivered_orders`, `food_sales`

```sql answer
SELECT r.category,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity * oi.unit_price) AS food_sales
FROM orders o
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY r.category
ORDER BY food_sales DESC;
```

<!-- a:start -->
> **해설** 주문 수를 `COUNT(*)`로 세면 주문 상세 줄 수가 나옵니다(fan-out). 주문 수의 합계가 511이 되는지 확인해 보세요.
<!-- a:end -->

### 문제 8. 한 번도 안 팔린 메뉴 ★★

> **운영팀** 주문 상세에 **한 번도 등장하지 않은** 메뉴를 가게 이름과 함께 주세요. `menu_id` 순입니다.

- 열: `menu_id`, `menu_name`, `restaurant_name`

```sql answer
SELECT m.menu_id,
    m.name AS menu_name,
    r.name AS restaurant_name
FROM menus m
JOIN restaurants r      ON m.restaurant_id = r.restaurant_id
LEFT JOIN order_items oi ON m.menu_id      = oi.menu_id
WHERE oi.order_item_id IS NULL
ORDER BY m.menu_id;
```

<!-- a:start -->
> **해설** 오마카세 도시락(45,000원)은 입점 이래 한 번도 팔리지 않았고, 나머지 3개는 6월 24일 입점한 신규 가게 메뉴입니다. 같은 "판매 0"이라도 원인이 다릅니다. 가게의 입점일(`opened_at`)을 함께 보면 구분할 수 있습니다.
<!-- a:end -->

### 문제 9. 고객별 주문 수 (0건 포함) ★★

> **마케팅팀** **전체 고객 30명**의 배달 완료 주문 수를 주세요. 주문이 없는 고객도 0으로 나와야 합니다. 주문 수 적은 순, 같으면 `customer_id` 순입니다.

- 열: `customer_name`, `grade`, `delivered_orders`

```sql answer limit=30
SELECT c.name AS customer_name,
    c.grade,
    COUNT(o.order_id) AS delivered_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.status = '배달완료'
GROUP BY c.customer_id, c.name, c.grade
ORDER BY delivered_orders, c.customer_id;
```

<!-- a:start -->
> **해설** 두 가지가 핵심입니다.
> 1. `o.status = '배달완료'`를 **ON에** 넣어야 주문 0건 고객이 남습니다(WHERE에 넣으면 27명).
> 2. `COUNT(*)`가 아니라 `COUNT(o.order_id)`. 짝이 없는 고객도 LEFT JOIN 결과에 1행이 있으므로 `COUNT(*)`는 1을 셉니다. NULL을 세지 않는 `COUNT(열)`이 필요합니다.
<!-- a:end -->

### 문제 10. 활동 종료 기사의 마지막 배달 ★★

> **운영팀** 현재 **활동 중이 아닌** 기사의 이름, 계약 시작일, 배달 완료 건수, **마지막 배달 완료 시각**을 주세요.

- 열: `rider_name`, `hired_at`, `deliveries`, `last_delivered_at`

```sql answer
SELECT rd.name AS rider_name,
    rd.hired_at,
    COUNT(o.order_id) AS deliveries,
    MAX(o.delivered_at) AS last_delivered_at
FROM riders rd
LEFT JOIN orders o
    ON rd.rider_id = o.rider_id
    AND o.status = '배달완료'
WHERE rd.is_active = FALSE
GROUP BY rd.rider_id, rd.name, rd.hired_at;
```

<!-- a:start -->
> **해설** `rd.is_active = FALSE`는 **왼쪽 테이블**을 거르는 조건이라 WHERE에, `o.status`는 **오른쪽**을 거르는 조건이라 ON에 넣었습니다. 6절의 규칙 그대로입니다.
<!-- a:end -->

### 문제 11. 인상 전 가격으로 팔린 메뉴 ★★

> **정산팀** 주문 당시 단가(`unit_price`)가 **현재 메뉴 가격과 다른** 판매 기록을 메뉴·단가별로 묶어 주세요. 배달 완료 주문만, `menu_id` 순입니다.

- 열: `menu_name`, `unit_price`, `current_price`, `sold_quantity`

```sql answer
SELECT m.name AS menu_name,
    oi.unit_price,
    m.price AS current_price,
    SUM(oi.quantity) AS sold_quantity
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN menus m  ON oi.menu_id  = m.menu_id
WHERE o.status = '배달완료'
    AND oi.unit_price <> m.price
GROUP BY m.menu_id, m.name, oi.unit_price, m.price
ORDER BY m.menu_id;
```

<!-- a:start -->
> **해설** JOIN하면 **두 테이블의 열끼리 비교**할 수 있습니다. 4~5월 가격 인상 전에 팔린 6개 메뉴가 나옵니다. 만약 매출을 `oi.quantity * m.price`(현재가)로 계산했다면 이만큼 매출이 부풀려졌을 겁니다.
<!-- a:end -->

### 문제 12. 다른 구에서 시킨 주문 ★★★

> **운영팀** 배달 반경 정책을 검토 중입니다. 배달 완료 주문 중 **고객의 거주 구와 가게의 구가 다른** 주문이 몇 건이고 전체의 몇 %인지 주세요. (소수 첫째 자리)

- 열: `delivered_orders`, `cross_district`, `cross_rate`

```sql answer
SELECT COUNT(*) AS delivered_orders,
    SUM(CASE WHEN c.district <> r.district THEN 1 ELSE 0 END) AS cross_district,
    ROUND(SUM(CASE WHEN c.district <> r.district THEN 1 ELSE 0 END) * 100 / COUNT(*), 1) AS cross_rate
FROM orders o
JOIN customers c   ON o.customer_id   = c.customer_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료';
```

<!-- a:start -->
> **해설** 고객과 가게 두 테이블 모두에 `district` 열이 있으므로 반드시 `c.district`, `r.district`처럼 구분해야 합니다. 조건부 집계(Ch04)와 JOIN의 조합입니다. 이 쿼리는 `orders`와 1:1 관계인 테이블만 이었기 때문에 `COUNT(*)`가 주문 수와 같습니다. `order_items`를 붙였다면 `COUNT(DISTINCT o.order_id)`가 필요합니다.
<!-- a:end -->

### 문제 13. 리뷰 작성률 ★★★

> **CS팀** 가게별 배달 완료 주문 중 **리뷰가 달린 비율**(%, 소수 첫째 자리)을 높은 순으로 주세요.

- 열: `restaurant_name`, `delivered_orders`, `reviewed`, `review_rate`

```sql answer limit=15
SELECT r.name AS restaurant_name,
    COUNT(*) AS delivered_orders,
    COUNT(rv.review_id) AS reviewed,
    ROUND(COUNT(rv.review_id) * 100 / COUNT(*), 1) AS review_rate
FROM orders o
JOIN restaurants r   ON o.restaurant_id = r.restaurant_id
LEFT JOIN reviews rv ON o.order_id      = rv.order_id
WHERE o.status = '배달완료'
GROUP BY r.restaurant_id, r.name
ORDER BY review_rate DESC;
```

<!-- a:start -->
> **해설** 리뷰가 없는 주문도 분모에 있어야 하므로 리뷰는 LEFT JOIN, 분자는 `COUNT(rv.review_id)`. 주문과 리뷰는 1 : 0..1 관계(`reviews.order_id`가 UNIQUE)라서 행이 불어나지 않습니다. 만약 리뷰가 주문당 여러 개일 수 있었다면 분모가 부풀었을 겁니다 — **관계의 카디널리티를 알아야 JOIN 결과를 믿을 수 있습니다.**
<!-- a:end -->

### 문제 14. 월 × 업종 매출 피벗 ★★★

> **정산팀** 월별로 **한식·중식·치킨·피자** 음식 매출을 가로로 펼쳐 주세요. 마지막 열은 네 업종을 포함한 **전체 업종** 합계입니다.

- 열: `order_month`, `korean`, `chinese`, `chicken`, `pizza`, `all_categories`

```sql answer
SELECT DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
    SUM(CASE WHEN r.category = '한식' THEN oi.quantity * oi.unit_price ELSE 0 END) AS korean,
    SUM(CASE WHEN r.category = '중식' THEN oi.quantity * oi.unit_price ELSE 0 END) AS chinese,
    SUM(CASE WHEN r.category = '치킨' THEN oi.quantity * oi.unit_price ELSE 0 END) AS chicken,
    SUM(CASE WHEN r.category = '피자' THEN oi.quantity * oi.unit_price ELSE 0 END) AS pizza,
    SUM(oi.quantity * oi.unit_price) AS all_categories
FROM orders o
JOIN order_items oi ON o.order_id      = oi.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
WHERE o.status = '배달완료'
GROUP BY order_month
ORDER BY order_month;
```

<!-- a:start -->
> **해설** Ch04의 피벗 + 오늘의 JOIN. `all_categories`가 9절의 월별 음식 매출과 같으면 정답입니다. 피자 매출이 달마다 크게 출렁이는 것도 보이나요? 피자 가게는 한 곳뿐이라 큰 주문 몇 건에도 월 매출이 크게 흔들립니다. **업종 비교를 할 때는 가게 수부터 확인**하세요.
<!-- a:end -->
