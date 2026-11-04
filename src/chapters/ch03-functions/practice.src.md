# Ch03 실습 — 데이터 가공하기

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE {{DB}};` · 오늘 날짜는 `'2026-06-30'`으로 씁니다 (`NOW()`·`CURDATE()` 사용 금지)
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전 · 열 이름은 문제에 지정된 별칭을 쓰세요.

---

### 문제 1. 이메일 도메인 현황 ★

> **마케팅팀** 고객들이 어떤 메일 서비스를 쓰는지 알고 싶어요. 이메일 **도메인**(`@` 뒤)을 중복 없이 가나다순으로 주세요.

- 열: `domain`

```sql answer
SELECT DISTINCT SUBSTRING_INDEX(email, '@', -1) AS domain
FROM customers
WHERE email IS NOT NULL
ORDER BY domain;
```

<!-- a:start -->
> **해설** `WHERE email IS NOT NULL`을 빼면 결과에 `NULL` 행이 하나 더 생깁니다. "도메인 목록"에 NULL이 들어가는 게 맞는지는 요청 의도에 따라 다르지만, 대개는 빼는 게 맞습니다.
<!-- a:end -->

### 문제 2. 긴 메뉴명 점검 ★

> **앱 개발팀** 메뉴 카드에 이름이 **8글자**까지만 한 줄에 들어갑니다. 8글자를 **넘는** 메뉴를 글자 수가 긴 순으로 주세요. 글자 수가 같으면 `menu_id` 순입니다. (공백·괄호도 한 글자)

- 열: `menu_id`, `name`, `name_length`

```sql answer
SELECT menu_id,
    name,
    CHAR_LENGTH(name) AS name_length
FROM menus
WHERE CHAR_LENGTH(name) > 8
ORDER BY name_length DESC, menu_id;
```

<!-- a:start -->
> **해설** `LENGTH`를 쓰면 한글 메뉴가 전부 3배로 계산되어 거의 모든 메뉴가 나옵니다.
<!-- a:end -->

### 문제 3. 가게 카드 문구 ★

> **운영팀** 앱 검색 결과에 `[업종] 가게명 (구)` 형태로 표시하려고 합니다. 영업 중인 가게만 `restaurant_id` 순으로 주세요.
> 예: `[한식] 서면옛날돼지국밥 (부산진구)`

- 열: `restaurant_id`, `card_title`

```sql answer
SELECT restaurant_id,
    CONCAT('[', category, '] ', name, ' (', district, ')') AS card_title
FROM restaurants
WHERE is_open = TRUE
ORDER BY restaurant_id;
```

### 문제 4. 할인가 계산 ★

> **정산팀** 해운대스시하루(`restaurant_id = 12`)가 **15% 할인** 행사를 합니다. 할인가는 **100원 단위 버림**, 할인액은 정가 − 할인가입니다.

- 열: `name`, `price`, `sale_price`, `discount`

```sql answer
SELECT name,
    price,
    TRUNCATE(price * 0.85, -2) AS sale_price,
    price - TRUNCATE(price * 0.85, -2) AS discount
FROM menus
WHERE restaurant_id = 12
ORDER BY menu_id;
```

<!-- a:start -->
> **해설** 할인액 열에서 `price - sale_price`라고 쓰면 1054 에러입니다. 별칭은 **같은 SELECT 절 안에서도** 재사용할 수 없어서 식을 다시 썼습니다. 미소 된장국은 3,000 × 0.85 = 2,550 → 버림 2,500원으로, 할인율이 실제로는 약 16.7%가 됩니다. 단가가 낮은 메뉴일수록 단위 처리의 영향이 커집니다.
<!-- a:end -->

### 문제 5. 주문 코드 만들기 ★★

> **CS팀** 고객 문의용 주문 코드를 `HD-연월일6자리-주문번호5자리` 형식으로 만들어 주세요. 6월 30일 주문만, 주문번호 순입니다.
> 예: 주문번호 563, 2026-06-30 주문 → `HD-260630-00563`

- 열: `order_id`, `order_code`, `status`

```sql answer
SELECT order_id,
    CONCAT('HD-', DATE_FORMAT(ordered_at, '%y%m%d'), '-', LPAD(order_id, 5, '0')) AS order_code,
    status
FROM orders
WHERE ordered_at >= '2026-06-30'
ORDER BY order_id;
```

### 문제 6. 지연 배달 리스트 ★★

> **CS팀** 배달에 **60분을 초과**한 주문의 주문번호, 주문 시각, 소요 시간(분)을 소요 시간이 긴 순으로 주세요. 같으면 주문번호 순입니다.

- 열: `order_id`, `ordered_at`, `delivery_minutes`

```sql answer
SELECT order_id,
    ordered_at,
    TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS delivery_minutes
FROM orders
WHERE TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) > 60
ORDER BY delivery_minutes DESC, order_id;
```

<!-- a:start -->
> **해설** WHERE에서 별칭 `delivery_minutes`를 쓸 수 없으므로(Ch02 실행 순서) 식을 반복했습니다. 취소·진행 중 주문은 `delivered_at`이 NULL → 소요 시간도 NULL → `> 60`이 참이 아니므로 자동으로 빠집니다. 그래도 의도를 분명히 하려면 `status = '배달완료'` 조건을 추가하는 편이 좋습니다.
<!-- a:end -->

### 문제 7. CASE 순서의 함정 ★★

> **마케팅팀** 아래 쿼리로 나이대를 만들었더니 생년월일이 없는 고객이 `'미입력'`이 아니라 다른 값으로 나온다고 합니다. 이유를 설명하고, 생년월일이 없는 고객만 대상으로 고친 쿼리를 작성하세요.

```sql
SELECT name,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') < 30 THEN '20대 이하'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') < 40 THEN '30대'
        ELSE '40대 이상'
    END AS age_group
FROM customers
WHERE birth_date IS NULL;
```

- 열: `name`, `age_group`

```sql answer
SELECT name,
    CASE
        WHEN birth_date IS NULL THEN '미입력'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') < 30 THEN '20대 이하'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') < 40 THEN '30대'
        ELSE '40대 이상'
    END AS age_group
FROM customers
WHERE birth_date IS NULL;
```

<!-- a:start -->
> **해설** `birth_date`가 NULL이면 나이도 NULL이고, `NULL < 30`은 참이 아니므로 첫 두 조건을 모두 통과해 **ELSE(`'40대 이상'`)**에 떨어집니다. 생년월일 미입력 고객 3명이 40대 이상 쿠폰을 받게 되는 버그입니다. NULL 처리는 CASE의 **맨 위**에.
<!-- a:end -->

### 문제 8. 주말 주문 건수 ★★

> **정산팀** 6월 **토·일요일**에 **배달 완료**된 주문은 몇 건인가요?

- 열: `weekend_orders`

```sql answer
SELECT COUNT(*) AS weekend_orders
FROM orders
WHERE status = '배달완료'
    AND ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01'
    AND DAYOFWEEK(ordered_at) IN (1, 7);
```

<!-- a:start -->
> **해설** `DAYOFWEEK`: 1=일, 7=토. `WEEKDAY`로 쓰면 `WEEKDAY(ordered_at) IN (5, 6)`. 기간 조건은 함수 없이 범위로, 요일 조건만 함수로 썼습니다.
<!-- a:end -->

### 문제 9. 가입 연차 구분 ★★

> **마케팅팀** 고객을 가입 경과일로 나눠 주세요. 기준일은 6월 30일입니다.
> - 90일 이내: `신규` / 365일 이내: `1년 미만` / 그 이상: `1년 이상`

- 열: `name`, `joined_at`, `days_since_join`, `member_type`
- 순서: 가입일 최신순

```sql answer
SELECT name,
    joined_at,
    DATEDIFF('2026-06-30', joined_at) AS days_since_join,
    CASE
        WHEN DATEDIFF('2026-06-30', joined_at) <= 90 THEN '신규'
        WHEN DATEDIFF('2026-06-30', joined_at) <= 365 THEN '1년 미만'
        ELSE '1년 이상'
    END AS member_type
FROM customers
ORDER BY joined_at DESC;
```

### 문제 10. 낮은 별점 리뷰 ★★

> **CS팀** 별점 **2점 이하** 리뷰를 최신순으로 주세요. 별점은 `★` 문자를 별점만큼 반복해서, 내용이 없는 리뷰는 `(별점만 남김)`으로 보여 주세요.
> 힌트: `REPEAT('★', 3)` → `★★★`

- 열: `review_id`, `order_id`, `stars`, `content`, `created_at`

```sql answer
SELECT review_id,
    order_id,
    REPEAT('★', rating) AS stars,
    IFNULL(content, '(별점만 남김)') AS content,
    created_at
FROM reviews
WHERE rating <= 2
ORDER BY created_at DESC;
```

### 문제 11. 영업 상태 판정 ★★★

> **앱 개발팀** 오늘 **밤 9시(21:00)** 기준으로 각 가게의 영업 상태를 표시하려고 합니다.
> - 폐업한 가게(`is_open = FALSE`): `폐업`
> - 21:00이 영업시간 안이면 `영업중`, 아니면 `영업종료`
> - 영업시간은 **시작 시각 포함, 종료 시각 미포함**입니다. (21:00 종료 가게는 21:00에 `영업종료`)
> - 자정을 넘겨 끝나는 가게(종료 < 시작)를 주의하세요.

- 열: `name`, `open_time`, `close_time`, `status_at_21`
- 순서: `restaurant_id`

```sql answer limit=15
SELECT name,
    open_time,
    close_time,
    CASE
        WHEN is_open = FALSE THEN '폐업'
        WHEN close_time > open_time
            THEN IF('21:00:00' >= open_time AND '21:00:00' < close_time, '영업중', '영업종료')
        ELSE IF('21:00:00' >= open_time OR '21:00:00' < close_time, '영업중', '영업종료')
    END AS status_at_21
FROM restaurants
ORDER BY restaurant_id;
```

<!-- a:start -->
> **해설** 자정을 넘기는 가게(예: 15:00~02:00)는 영업시간이 **[15:00, 24:00) 또는 [00:00, 02:00)** 두 구간이므로 `AND`가 아니라 `OR`로 판정합니다. 경계값(21:00 종료인 남포동떡볶이연구소)이 `영업종료`로 나오는지 꼭 확인하세요. 이런 "경계 + 예외" 처리는 실제 서비스 코드에서 버그가 가장 많이 나는 곳입니다.
<!-- a:end -->

### 문제 12. 웰컴 쿠폰 만료일 ★★★

> **마케팅팀** 올해(2026년) 가입한 고객에게는 **가입일로부터 30일 뒤**에 만료되는 웰컴 쿠폰이 지급됐습니다. 6월 30일 기준으로 쿠폰 상태를 알려 주세요.
> - 만료일: 가입 **날짜** + 30일 (시각은 버림)
> - 상태: 만료일이 6월 30일보다 이전이면 `만료`, 아니면 `D-남은일수` (만료일 당일은 `D-0`)

- 열: `name`, `join_date`, `expires_on`, `coupon_status`
- 순서: 가입일 순

```sql answer
SELECT name,
    DATE(joined_at) AS join_date,
    DATE_ADD(DATE(joined_at), INTERVAL 30 DAY) AS expires_on,
    IF(DATE_ADD(DATE(joined_at), INTERVAL 30 DAY) < '2026-06-30',
        '만료',
        CONCAT('D-', DATEDIFF(DATE_ADD(DATE(joined_at), INTERVAL 30 DAY), '2026-06-30'))
    ) AS coupon_status
FROM customers
WHERE joined_at >= '2026-01-01'
ORDER BY joined_at;
```

<!-- a:start -->
> **해설** 같은 식(`DATE_ADD(…)`)을 세 번 반복했습니다. 읽기도 고치기도 불편하죠. Ch06에서 배우는 **CTE(WITH)**나 서브쿼리를 쓰면 한 번 계산한 값을 이름 붙여 재사용할 수 있습니다.
<!-- a:end -->
