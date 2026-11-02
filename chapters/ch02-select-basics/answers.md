# Ch02 실습 — 부서 요청 처리하기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery02;` · 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> 기대 결과와 **열 이름·행 순서·값**이 모두 같으면 정답입니다. 열 이름은 문제에 지정된 별칭을 쓰세요.
> 결과가 10행을 넘으면 상위 10행만 보여 줍니다. 전체 행 수(`▶ 실행 결과 · N행`)도 맞춰 보세요.

---

### 문제 1. 메뉴판 할인가 ★

> **운영팀** 전포카츠(`restaurant_id = 2`)가 이번 주 전 메뉴 10% 할인 행사를 합니다. 메뉴명, 정가, 할인가를 보여 주세요.

- 열: `name`, `price`, `sale_price` (정가 × 0.9)
- 순서: `menu_id` 순

**정답 SQL**

```sql
SELECT name,
    price,
    price * 0.9 AS sale_price
FROM menus
WHERE restaurant_id = 2
ORDER BY menu_id;
```

<sub>▶ 실행 결과 · 5행</sub>

| name | price | sale_price |
|---|---|---|
| 등심카츠 | 11000 | 9900.0 |
| 안심카츠 | 12500 | 11250.0 |
| 치즈카츠 | 13000 | 11700.0 |
| 카레우동 | 9000 | 8100.0 |
| 새우튀김 (3pc) | 6000 | 5400.0 |


> **해설** `price * 0.9`의 결과는 소수점이 붙은 값(`9900.0`)이 됩니다. 정수 원 단위로 정리하는 `ROUND`·`TRUNCATE`는 Ch03에서 배웁니다.

### 문제 2. 입점 업종 ★

> **운영팀** 우리 플랫폼에 입점한 업종 목록을 **중복 없이 가나다순**으로 주세요.

**정답 SQL**

```sql
SELECT DISTINCT category
FROM restaurants
ORDER BY category;
```

<sub>▶ 실행 결과 · 8행</sub>

| category |
|---|
| 분식 |
| 양식 |
| 일식 |
| 중식 |
| 치킨 |
| 카페·디저트 |
| 피자 |
| 한식 |


### 문제 3. 최근 취소 주문 ★

> **CS팀** 가장 최근에 **취소된** 주문 5건의 주문번호, 고객번호, 가게번호, 주문일시를 최신순으로 주세요.

**정답 SQL**

```sql
SELECT order_id,
    customer_id,
    restaurant_id,
    ordered_at
FROM orders
WHERE status = '취소'
ORDER BY ordered_at DESC
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| order_id | customer_id | restaurant_id | ordered_at |
|---|---|---|---|
| 545 | 19 | 2 | 2026-06-26 17:59:53 |
| 523 | 10 | 11 | 2026-06-20 13:19:10 |
| 497 | 19 | 4 | 2026-06-13 13:08:02 |
| 481 | 7 | 8 | 2026-06-07 20:54:23 |
| 480 | 1 | 8 | 2026-06-07 19:09:09 |


### 문제 4. 프리미엄 대표 메뉴 ★

> **운영팀** **품절이 아닌 대표 메뉴** 중 가격이 **15,000원 이상**인 메뉴를 가격 높은 순으로 주세요. 가격이 같으면 `menu_id` 순입니다.

- 열: `menu_id`, `restaurant_id`, `name`, `price`

**정답 SQL**

```sql
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

<sub>▶ 실행 결과 · 9행</sub>

| menu_id | restaurant_id | name | price |
|---|---|---|---|
| 22 | 5 | 마라샹궈 (2인) | 27000 |
| 18 | 4 | 트러플 머쉬룸 | 23000 |
| 56 | 12 | 모둠 초밥 (12pc) | 22000 |
| 26 | 6 | 양념 치킨 | 21000 |
| 25 | 6 | 후라이드 치킨 | 20000 |
| 31 | 7 | 해물파전 | 18000 |
| 15 | 4 | 마르게리타 | 17000 |
| 60 | 13 | 후라이드 치킨 | 17000 |
| 38 | 8 | 탕수육 (소) | 16000 |


### 문제 5. 프로모션 문자 대상 ★★

> **마케팅팀** 신메뉴 안내 문자를 보내려고 합니다. **마케팅 수신에 동의**했고 등급이 **골드 또는 VIP**인 고객의 이름, 등급, 전화번호를 `customer_id` 순으로 주세요.

**정답 SQL**

```sql
SELECT name,
    grade,
    phone
FROM customers
WHERE marketing_agreed = TRUE
    AND grade IN ('골드', 'VIP')
ORDER BY customer_id;
```

<sub>▶ 실행 결과 · 5행</sub>

| name | grade | phone |
|---|---|---|
| 김민준 | VIP | 010-2841-5523 |
| 이서연 | VIP | 010-3392-1187 |
| 강하은 | 골드 | 010-7714-2290 |
| 임도현 | 골드 | 010-2047-8813 |
| 서지우 | 골드 | 010-5370-1149 |


> **해설** `grade = '골드' OR grade = 'VIP'`로 쓴다면 반드시 괄호로 묶어야 합니다: `marketing_agreed = TRUE AND (grade = '골드' OR grade = 'VIP')`. 괄호가 없으면 수신 거부한 VIP 고객에게도 문자가 나갑니다 — **법적 문제가 되는 버그**입니다.

### 문제 6. 이메일 미등록 고객 ★★

> **마케팅팀** 이메일 영수증을 못 받는 고객, 즉 **이메일이 등록되지 않은** 고객의 이름과 전화번호를 주세요. 가입일 순입니다.

**정답 SQL**

```sql
SELECT name,
    phone
FROM customers
WHERE email IS NULL
ORDER BY joined_at;
```

<sub>▶ 실행 결과 · 6행</sub>

| name | phone |
|---|---|
| 신동욱 | 010-6481-7720 |
| 최수아 | 010-5527-3018 |
| 조은서 | 010-6047-3589 |
| 윤지아 | 010-9936-4407 |
| 배수빈 | 010-3936-0058 |
| 김서준 | 010-8481-5579 |


### 문제 7. 분식 메뉴 찾기 ★★

> **운영팀** 메뉴명에 **'떡볶이' 또는 '김밥'**이 들어간 메뉴를 가격 낮은 순으로 주세요. 가격이 같으면 `menu_id` 순입니다.

- 열: `menu_id`, `name`, `price`

**정답 SQL**

```sql
SELECT menu_id,
    name,
    price
FROM menus
WHERE name LIKE '%떡볶이%'
    OR name LIKE '%김밥%'
ORDER BY price, menu_id;
```

<sub>▶ 실행 결과 · 5행</sub>

| menu_id | name | price |
|---|---|---|
| 51 | 든든김밥 | 4000 |
| 52 | 참치김밥 | 5000 |
| 41 | 국물떡볶이 | 5500 |
| 54 | 돈가스 김밥 | 5500 |
| 42 | 로제떡볶이 | 8000 |


> **해설** `LIKE`는 `IN`처럼 목록을 받을 수 없으므로 `OR`로 잇습니다. '라볶이'는 '떡볶이'를 포함하지 않으므로 나오지 않습니다.

### 문제 8. 3월 현장결제 ★★

> **정산팀** **2026년 3월** 한 달 동안 **현장결제**로 **배달 완료**된 주문은 몇 건인가요?

- 열: `cnt`

**정답 SQL**

```sql
SELECT COUNT(*) AS cnt
FROM orders
WHERE payment_method = '현장결제'
    AND status = '배달완료'
    AND ordered_at >= '2026-03-01'
    AND ordered_at < '2026-04-01';
```

<sub>▶ 실행 결과 · 1행</sub>

| cnt |
|---|
| 6 |


> **해설** `BETWEEN '2026-03-01' AND '2026-03-31'`로 쓰면 3월 31일 주문이 빠질 수 있습니다. 기간 조건은 `>= 시작 AND < 다음 시작`.

### 문제 9. 심야 영업 가게 ★★

> **운영팀** 심야 배달 기획전 후보로, **영업이 자정을 넘겨 끝나는** 가게 목록을 주세요. (영업 종료 시각이 시작 시각보다 이른 가게)

- 열: `name`, `open_time`, `close_time`, `is_open`

**정답 SQL**

```sql
SELECT name,
    open_time,
    close_time,
    is_open
FROM restaurants
WHERE close_time < open_time;
```

<sub>▶ 실행 결과 · 2행</sub>

| name | open_time | close_time | is_open |
|---|---|---|---|
| 대연동크런치치킨 | 15:00:00 | 02:00:00 | 1 |
| 서면야식치킨 | 17:00:00 | 03:00:00 | 0 |


> **해설** WHERE 조건은 **열과 값**뿐 아니라 **열과 열**을 비교할 수도 있습니다. 서면야식치킨은 폐업(`is_open = 0`)이므로 실제 기획전에서는 `AND is_open = TRUE`를 추가해야 합니다. 문제의 요구사항을 넘어서는 데이터 특이점을 발견하면 요청자에게 알려 주는 것도 데이터팀의 일입니다.

### 문제 10. 전화 요청 주문 ★★

> **CS팀** 6월 주문 중 요청사항에 **'전화'**가 들어간 주문의 주문번호, 요청사항, 주문일시를 최신순으로 주세요.

**정답 SQL**

```sql
SELECT order_id,
    request_note,
    ordered_at
FROM orders
WHERE request_note LIKE '%전화%'
    AND ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01'
ORDER BY ordered_at DESC;
```

<sub>▶ 실행 결과 · 4행</sub>

| order_id | request_note | ordered_at |
|---|---|---|
| 553 | 도착하면 전화 주세요 | 2026-06-28 18:47:34 |
| 537 | 도착하면 전화 주세요 | 2026-06-24 10:56:21 |
| 504 | 도착하면 전화 주세요 | 2026-06-14 19:16:57 |
| 479 | 도착하면 전화 주세요 | 2026-06-07 14:03:05 |


### 문제 11. 메뉴 페이징 ★★★

> **앱 개발팀** "가격 낮은 순" 메뉴 목록을 한 화면에 **8개씩** 보여 줍니다. 사용자가 **3페이지**를 열었을 때 나올 메뉴를 주세요. 가격이 같으면 `menu_id` 순이고, 품절 메뉴도 포함합니다.

- 열: `menu_id`, `name`, `price`

**정답 SQL**

```sql
SELECT menu_id,
    name,
    price
FROM menus
ORDER BY price, menu_id
LIMIT 8 OFFSET 16;
```

<sub>▶ 실행 결과 · 8행</sub>

| menu_id | name | price |
|---|---|---|
| 40 | 군만두 (8개) | 6000 |
| 43 | 모둠튀김 (5종) | 6000 |
| 14 | 왕만두 (6개) | 7000 |
| 35 | 짜장면 | 7000 |
| 53 | 라볶이 | 7000 |
| 55 | 쫄면 | 7000 |
| 42 | 로제떡볶이 | 8000 |
| 37 | 간짜장 | 8500 |


> **해설** OFFSET = (3 − 1) × 8 = 16. `menu_id`를 두 번째 정렬 기준으로 두지 않으면 같은 가격의 메뉴가 페이지를 넘길 때 **중복되거나 누락될 수 있습니다.** 실제 앱에서 "다음 페이지에 같은 메뉴가 또 나와요"라는 버그의 흔한 원인입니다.

### 문제 12. 데이터 품질 점검 ★★★

> **CS팀** 배달 완료로 표시됐는데 **기사가 비어 있거나 배달 완료 시각이 비어 있는** 이상한 주문이 있는지 확인해 주세요.

- 열: `order_id`, `status`, `rider_id`, `delivered_at`

**정답 SQL**

```sql
SELECT order_id,
    status,
    rider_id,
    delivered_at
FROM orders
WHERE status = '배달완료'
    AND (rider_id IS NULL OR delivered_at IS NULL);
```

<sub>▶ 실행 결과 · 0행 — 조건에 맞는 데이터 없음</sub>




> **해설** 결과가 **0행이면 정답**입니다 — 이상 주문이 없다는 뜻이니까요. 데이터 품질 점검 쿼리는 "아무것도 안 나오길 바라는" 쿼리입니다. 괄호를 빼면 `(status = '배달완료' AND rider_id IS NULL) OR delivered_at IS NULL`로 해석되어, 배달 시각이 비어 있는 취소·진행 중 주문 52건이 "이상 주문"으로 쏟아집니다. 잘못된 경보입니다.
