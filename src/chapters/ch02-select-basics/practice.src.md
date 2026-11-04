# Ch02 실습 — 부서 요청 처리하기

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE {{DB}};` · 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> 기대 결과와 **열 이름·행 순서·값**이 모두 같으면 정답입니다. 열 이름은 문제에 지정된 별칭을 쓰세요.
> 결과가 10행을 넘으면 상위 10행만 보여 줍니다. 전체 행 수(`▶ 실행 결과 · N행`)도 맞춰 보세요.

---

### 문제 1. 메뉴판 할인가 ★

> **운영팀** 전포카츠(`restaurant_id = 2`)가 이번 주 전 메뉴 10% 할인 행사를 합니다. 메뉴명, 정가, 할인가를 보여 주세요.

- 열: `name`, `price`, `sale_price` (정가 × 0.9)
- 순서: `menu_id` 순

```sql answer
SELECT name,
    price,
    price * 0.9 AS sale_price
FROM menus
WHERE restaurant_id = 2
ORDER BY menu_id;
```

<!-- a:start -->
> **해설** `price * 0.9`의 결과는 소수점이 붙은 값(`9900.0`)이 됩니다. 정수 원 단위로 정리하는 `ROUND`·`TRUNCATE`는 Ch03에서 배웁니다.
<!-- a:end -->

### 문제 2. 입점 업종 ★

> **운영팀** 우리 플랫폼에 입점한 업종 목록을 **중복 없이 가나다순**으로 주세요.

```sql answer
SELECT DISTINCT category
FROM restaurants
ORDER BY category;
```

### 문제 3. 최근 취소 주문 ★

> **CS팀** 가장 최근에 **취소된** 주문 5건의 주문번호, 고객번호, 가게번호, 주문일시를 최신순으로 주세요.

```sql answer
SELECT order_id,
    customer_id,
    restaurant_id,
    ordered_at
FROM orders
WHERE status = '취소'
ORDER BY ordered_at DESC
LIMIT 5;
```

### 문제 4. 프리미엄 대표 메뉴 ★

> **운영팀** **품절이 아닌 대표 메뉴** 중 가격이 **15,000원 이상**인 메뉴를 가격 높은 순으로 주세요. 가격이 같으면 `menu_id` 순입니다.

- 열: `menu_id`, `restaurant_id`, `name`, `price`

```sql answer
SELECT menu_id,
    restaurant_id,
    name,
    price
FROM menus
WHERE is_signature = TRUE
    AND is_sold_out = FALSE
    AND price >= 15000
ORDER BY price DESC, menu_id;
```

### 문제 5. 프로모션 문자 대상 ★★

> **마케팅팀** 신메뉴 안내 문자를 보내려고 합니다. **마케팅 수신에 동의**했고 등급이 **골드 또는 VIP**인 고객의 이름, 등급, 전화번호를 `customer_id` 순으로 주세요.

```sql answer
SELECT name,
    grade,
    phone
FROM customers
WHERE marketing_agreed = TRUE
    AND grade IN ('골드', 'VIP')
ORDER BY customer_id;
```

<!-- a:start -->
> **해설** `grade = '골드' OR grade = 'VIP'`로 쓴다면 반드시 괄호로 묶어야 합니다: `marketing_agreed = TRUE AND (grade = '골드' OR grade = 'VIP')`. 괄호가 없으면 수신 거부한 VIP 고객에게도 문자가 나갑니다 — **법적 문제가 되는 버그**입니다.
<!-- a:end -->

### 문제 6. 이메일 미등록 고객 ★★

> **마케팅팀** 이메일 영수증을 못 받는 고객, 즉 **이메일이 등록되지 않은** 고객의 이름과 전화번호를 주세요. 가입일 순입니다.

```sql answer
SELECT name,
    phone
FROM customers
WHERE email IS NULL
ORDER BY joined_at;
```

### 문제 7. 분식 메뉴 찾기 ★★

> **운영팀** 메뉴명에 **'떡볶이' 또는 '김밥'**이 들어간 메뉴를 가격 낮은 순으로 주세요. 가격이 같으면 `menu_id` 순입니다.

- 열: `menu_id`, `name`, `price`

```sql answer
SELECT menu_id,
    name,
    price
FROM menus
WHERE name LIKE '%떡볶이%'
    OR name LIKE '%김밥%'
ORDER BY price, menu_id;
```

<!-- a:start -->
> **해설** `LIKE`는 `IN`처럼 목록을 받을 수 없으므로 `OR`로 잇습니다. '라볶이'는 '떡볶이'를 포함하지 않으므로 나오지 않습니다.
<!-- a:end -->

### 문제 8. 3월 현장결제 ★★

> **정산팀** **2026년 3월** 한 달 동안 **현장결제**로 **배달 완료**된 주문은 몇 건인가요?

- 열: `cnt`

```sql answer
SELECT COUNT(*) AS cnt
FROM orders
WHERE payment_method = '현장결제'
    AND status = '배달완료'
    AND ordered_at >= '2026-03-01'
    AND ordered_at < '2026-04-01';
```

<!-- a:start -->
> **해설** `BETWEEN '2026-03-01' AND '2026-03-31'`로 쓰면 3월 31일 주문이 빠질 수 있습니다. 기간 조건은 `>= 시작 AND < 다음 시작`.
<!-- a:end -->

### 문제 9. 심야 영업 가게 ★★

> **운영팀** 심야 배달 기획전 후보로, **영업이 자정을 넘겨 끝나는** 가게 목록을 주세요. (영업 종료 시각이 시작 시각보다 이른 가게)

- 열: `name`, `open_time`, `close_time`, `is_open`

```sql answer
SELECT name,
    open_time,
    close_time,
    is_open
FROM restaurants
WHERE close_time < open_time;
```

<!-- a:start -->
> **해설** WHERE 조건은 **열과 값**뿐 아니라 **열과 열**을 비교할 수도 있습니다. 서면야식치킨은 폐업(`is_open = 0`)이므로 실제 기획전에서는 `AND is_open = TRUE`를 추가해야 합니다. 문제의 요구사항을 넘어서는 데이터 특이점을 발견하면 요청자에게 알려 주는 것도 데이터팀의 일입니다.
<!-- a:end -->

### 문제 10. 전화 요청 주문 ★★

> **CS팀** 6월 주문 중 요청사항에 **'전화'**가 들어간 주문의 주문번호, 요청사항, 주문일시를 최신순으로 주세요.

```sql answer
SELECT order_id,
    request_note,
    ordered_at
FROM orders
WHERE request_note LIKE '%전화%'
    AND ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01'
ORDER BY ordered_at DESC;
```

### 문제 11. 메뉴 페이징 ★★★

> **앱 개발팀** "가격 낮은 순" 메뉴 목록을 한 화면에 **8개씩** 보여 줍니다. 사용자가 **3페이지**를 열었을 때 나올 메뉴를 주세요. 가격이 같으면 `menu_id` 순이고, 품절 메뉴도 포함합니다.

- 열: `menu_id`, `name`, `price`

```sql answer
SELECT menu_id,
    name,
    price
FROM menus
ORDER BY price, menu_id
LIMIT 8 OFFSET 16;
```

<!-- a:start -->
> **해설** OFFSET = (3 − 1) × 8 = 16. `menu_id`를 두 번째 정렬 기준으로 두지 않으면 같은 가격의 메뉴가 페이지를 넘길 때 **중복되거나 누락될 수 있습니다.** 실제 앱에서 "다음 페이지에 같은 메뉴가 또 나와요"라는 버그의 흔한 원인입니다.
<!-- a:end -->

### 문제 12. 데이터 품질 점검 ★★★

> **CS팀** 배달 완료로 표시됐는데 **기사가 비어 있거나 배달 완료 시각이 비어 있는** 이상한 주문이 있는지 확인해 주세요.

- 열: `order_id`, `status`, `rider_id`, `delivered_at`

```sql answer
SELECT order_id,
    status,
    rider_id,
    delivered_at
FROM orders
WHERE status = '배달완료'
    AND (rider_id IS NULL OR delivered_at IS NULL);
```

<!-- a:start -->
> **해설** 결과가 **0행이면 정답**입니다 — 이상 주문이 없다는 뜻이니까요. 데이터 품질 점검 쿼리는 "아무것도 안 나오길 바라는" 쿼리입니다. 괄호를 빼면 `(status = '배달완료' AND rider_id IS NULL) OR delivered_at IS NULL`로 해석되어, 배달 시각이 비어 있는 취소·진행 중 주문 52건이 "이상 주문"으로 쏟아집니다. 잘못된 경보입니다.
<!-- a:end -->
