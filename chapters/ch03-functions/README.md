# Ch03. 함수로 데이터 가공하기

> **PART 1 · 읽기** | 3시간 | 난이도 ★★
> 이전: [Ch02. SELECT 기본](../ch02-select-basics/README.md) | 다음: [Ch04. 집계와 그룹](../ch04-aggregation/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery03`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 지난 시간 hanip_delivery02 도 그대로 남아 있음
USE hanip_delivery03;
```

> 오늘 실습은 모두 `hanip_delivery03`에서 합니다. Workbench 왼쪽 SCHEMAS에서 **굵게 표시된 DB**가 `hanip_delivery03`인지 확인하고 시작하세요. 지난 챕터 DB에서 실행해도 결과는 같지만, 기록이 섞입니다.

## 오늘의 요청

> **From.** 마케팅팀 이 매니저
>
> 하반기 생일 쿠폰 문자를 준비하고 있어요. 고객 명단을 이렇게 만들어 주실 수 있나요?
> - 전화번호는 개인정보라서 **가운데 네 자리를 `****`로 가려** 주세요.
> - **만 나이**와 **나이대**(20대, 30대…)를 붙여 주세요. 생일을 안 적은 분은 "미입력"으로요.
> - **가입한 지 며칠 됐는지**도 같이 주세요. 오늘(6월 30일) 기준입니다.

`customers`에는 가려진 전화번호도, 나이도, 가입 경과일도 저장돼 있지 않습니다. 하지만 **재료**(`phone`, `birth_date`, `joined_at`)는 있습니다. 오늘은 재료를 **함수**로 가공해 새 값을 만듭니다. 완성 쿼리는 [8절](#8-오늘의-요청-해결).

## 학습 목표

1. 문자열 함수로 값을 **자르고·붙이고·바꾸고·채운다**.
2. 숫자 함수로 **반올림·버림·올림** 단위를 정확히 지정한다.
3. 날짜 함수로 **경과일·소요 시간·만 나이**를 계산하고, 원하는 형식으로 표시한다.
4. `CASE`·`IF`·`IFNULL`·`COALESCE`로 조건에 따라 다른 값을 만든다.
5. **NULL이 연산·함수에 섞일 때** 결과가 어떻게 되는지 예측한다.

---

## 0. 함수 사용의 기본

```
함수이름(입력값1, 입력값2, …)  →  결과값 하나
```

- 오늘 배우는 함수는 **행마다 하나씩** 계산합니다(단일행 함수). 30명 고객에 쓰면 30개의 결과가 나옵니다. 여러 행을 하나로 요약하는 `COUNT`·`SUM` 같은 집계 함수는 Ch04입니다.
- 함수는 **원본 데이터를 바꾸지 않습니다.** 결과 화면에서만 가공됩니다.
- 테이블 없이 `SELECT 함수(값);`만으로 동작을 바로 시험할 수 있습니다. 처음 쓰는 함수는 이렇게 먼저 확인하는 습관을 들이세요.

```sql
SELECT UPPER('hanip'), CHAR_LENGTH('한입배달'), 7 / 2;
```

<sub>▶ 실행 결과 · 1행</sub>

| UPPER('hanip') | CHAR_LENGTH('한입배달') | 7 / 2 |
|---|---|---|
| HANIP | 4 | 3.5000 |


### 이 챕터의 "오늘"

데이터는 **2026-06-30 19:00**에 떠 온 스냅숏입니다. `NOW()`·`CURDATE()`는 **실제 수업 날짜**를 돌려주기 때문에 날짜 계산 결과가 매일 달라집니다. 이 과정에서는 오늘 날짜 자리에 `'2026-06-30'`을 직접 씁니다.

```sql
SELECT NOW(), CURDATE();     -- 실제 현재 시각 (실행할 때마다 다름) — 개념 확인용
```

> 실무에서는 `CURDATE()`를 쓰는 게 맞습니다. 리포트를 **매일** 돌려야 하니까요. 교안에서 고정값을 쓰는 이유는 누가 언제 실행해도 결과가 같아야 하기 때문입니다.

---

## 1. 문자열 함수

| 함수 | 하는 일 | 예 | 결과 |
|---|---|---|---|
| `CONCAT(a, b, …)` | 이어 붙이기 | `CONCAT('[', '한식', ']')` | `[한식]` |
| `CONCAT_WS(구분자, a, b, …)` | 구분자를 끼워 이어 붙이기 (NULL은 건너뜀) | `CONCAT_WS('/', '부산', '서면')` | `부산/서면` |
| `CHAR_LENGTH(s)` | 글자 수 | `CHAR_LENGTH('돼지국밥')` | 4 |
| `LENGTH(s)` | **바이트** 수 (한글 1글자 = 3바이트) | `LENGTH('돼지국밥')` | 12 |
| `LEFT(s, n)` / `RIGHT(s, n)` | 왼쪽·오른쪽에서 n글자 | `LEFT('010-2841-5523', 3)` | `010` |
| `SUBSTRING(s, 시작, 길이)` | 중간 자르기 (위치는 **1부터**) | `SUBSTRING('010-2841-5523', 5, 4)` | `2841` |
| `SUBSTRING_INDEX(s, 구분자, n)` | 구분자 기준 앞(n>0)·뒤(n<0) 조각 | `SUBSTRING_INDEX('a@naver.com', '@', -1)` | `naver.com` |
| `REPLACE(s, 찾을것, 바꿀것)` | 바꾸기 | `REPLACE('010-1234-5678', '-', '')` | `01012345678` |
| `INSTR(s, 찾을것)` | 위치 찾기 (없으면 0) | `INSTR('후라이드 치킨', '치킨')` | 6 |
| `TRIM(s)` | 앞뒤 공백 제거 | `TRIM('  김밥 ')` | `김밥` |
| `LPAD(s, 길이, 채울문자)` | 왼쪽을 채워 길이 맞추기 | `LPAD(7, 5, '0')` | `00007` |
| `UPPER(s)` / `LOWER(s)` | 대·소문자 | `UPPER('bbq')` | `BBQ` |

### 1-1. 붙이기 — 앱 화면용 가게 이름

```sql
SELECT CONCAT('[', category, '] ', name) AS display_name,
    CONCAT_WS(' · ', district, category) AS tag
FROM restaurants
ORDER BY restaurant_id;
```

<sub>▶ 실행 결과 · 15행 (상위 5행 표시)</sub>

| display_name | tag |
|---|---|
| [한식] 서면옛날돼지국밥 | 부산진구 · 한식 |
| [일식] 전포카츠 | 부산진구 · 일식 |
| [한식] 해운대명가밀면 | 해운대구 · 한식 |
| [피자] 광안리화덕피자 | 수영구 · 피자 |
| [중식] 남천동마라공방 | 수영구 · 중식 |


### 1-2. 글자 수 vs 바이트 수

```sql
SELECT name,
    CHAR_LENGTH(name) AS char_count,
    LENGTH(name) AS byte_count
FROM menus
ORDER BY CHAR_LENGTH(name) DESC, menu_id;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| name | char_count | byte_count |
|---|---|---|
| 동래 막걸리 750ml | 12 | 22 |
| 모둠 초밥 (12pc) | 12 | 20 |
| 연어 초밥 (10pc) | 12 | 20 |
| 부산 어묵 (3꼬치) | 11 | 23 |
| 특선 오마카세 도시락 | 11 | 29 |


> "메뉴명은 20자 이내"라는 화면 규칙을 검사할 때 `LENGTH`를 쓰면 한글 메뉴가 전부 3배로 계산됩니다. **사람이 세는 글자 수는 `CHAR_LENGTH`**.

### 1-3. 자르기 — 이메일 도메인, 전화번호 가리기

```sql
SELECT email,
    SUBSTRING_INDEX(email, '@', 1)  AS account,
    SUBSTRING_INDEX(email, '@', -1) AS domain
FROM customers
WHERE email IS NOT NULL;
```

<sub>▶ 실행 결과 · 24행 (상위 6행 표시)</sub>

| email | account | domain |
|---|---|---|
| chaewon.hong@naver.com | chaewon.hong | naver.com |
| dain.jung@daum.net | dain.jung | daum.net |
| dohyun.lim@gmail.com | dohyun.lim | gmail.com |
| doyun.kang@gmail.com | doyun.kang | gmail.com |
| haeun.kang@naver.com | haeun.kang | naver.com |
| harin.moon@gmail.com | harin.moon | gmail.com |


```sql
SELECT name,
    phone,
    CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS masked_phone
FROM customers;
```

<sub>▶ 실행 결과 · 30행 (상위 5행 표시)</sub>

| name | phone | masked_phone |
|---|---|---|
| 김민준 | 010-2841-5523 | 010-****-5523 |
| 이서연 | 010-3392-1187 | 010-****-1187 |
| 박지훈 | 010-4410-7762 | 010-****-7762 |
| 최수아 | 010-5527-3018 | 010-****-3018 |
| 정우진 | 010-6631-9045 | 010-****-9045 |


> `010-2841-5523` → `LEFT 4글자`(`010-`) + `****` + `RIGHT 5글자`(`-5523`). 자리수가 고정(`CHAR(13)`)된 형식이라 가능한 방법입니다. 고정 형식을 DB가 보장하게 만드는 법은 Ch07에서 다룹니다.

### 1-4. 바꾸기·채우기 — 주소 줄이기, 주문 코드

```sql
SELECT name,
    address,
    REPLACE(address, '부산광역시 ', '') AS short_address
FROM restaurants;
```

<sub>▶ 실행 결과 · 15행 (상위 3행 표시)</sub>

| name | address | short_address |
|---|---|---|
| 서면옛날돼지국밥 | 부산광역시 부산진구 부전동 서면로 68 | 부산진구 부전동 서면로 68 |
| 전포카츠 | 부산광역시 부산진구 전포동 전포대로 199 | 부산진구 전포동 전포대로 199 |
| 해운대명가밀면 | 부산광역시 해운대구 중동 해운대로 570 | 해운대구 중동 해운대로 570 |


```sql
SELECT order_id,
    CONCAT('HD-', LPAD(order_id, 6, '0')) AS order_code
FROM orders
ORDER BY order_id DESC;
```

<sub>▶ 실행 결과 · 563행 (상위 3행 표시)</sub>

| order_id | order_code |
|---|---|
| 563 | HD-000563 |
| 562 | HD-000562 |
| 561 | HD-000561 |


> `LPAD`는 Ch01부터 봐 온 주문번호에 앞자리 0을 채워 **자릿수를 고정**합니다. 문자열로 정렬해도 `HD-000099`가 `HD-000100`보다 앞에 오게 하려는 목적입니다.

---

## 2. 숫자 함수

| 함수 | 하는 일 | 예 | 결과 |
|---|---|---|---|
| `ROUND(x, d)` | 반올림 (d: 남길 소수 자리, **음수면 정수 자리**) | `ROUND(13500, -3)` | 14000 |
| `TRUNCATE(x, d)` | 버림 (자릿수 지정 필수) | `TRUNCATE(12555, -2)` | 12500 |
| `CEIL(x)` / `FLOOR(x)` | 올림·내림 (정수로) | `CEIL(3.2)` / `FLOOR(3.8)` | 4 / 3 |
| `MOD(a, b)` | 나머지 | `MOD(7, 2)` | 1 |
| `ABS(x)` | 절댓값 | `ABS(-500)` | 500 |
| `a / b` · `a DIV b` | 나눗셈 · 몫(정수) | `7 / 2` · `7 DIV 2` | 3.5000 · 3 |

### 2-1. 할인가 계산 — 단위가 중요하다

> **정산팀 규칙**: 할인가는 **100원 단위 버림**입니다. (고객에게 유리하게)

```sql
SELECT name,
    price,
    price * 0.85                 AS raw_price,
    ROUND(price * 0.85, -2)      AS rounded,
    TRUNCATE(price * 0.85, -2)   AS truncated
FROM menus
WHERE restaurant_id = 12;
```

<sub>▶ 실행 결과 · 4행</sub>

| name | price | raw_price | rounded | truncated |
|---|---|---|---|---|
| 모둠 초밥 (12pc) | 22000 | 18700.00 | 18700 | 18700 |
| 미소 된장국 | 3000 | 2550.00 | 2600 | 2500 |
| 연어 초밥 (10pc) | 19000 | 16150.00 | 16200 | 16100 |
| 특선 오마카세 도시락 | 45000 | 38250.00 | 38300 | 38200 |


같은 15% 할인이어도 `ROUND`와 `TRUNCATE`가 100원씩 다른 행이 있습니다. 주문이 수천 건이면 정산 금액이 수십만 원 차이 납니다. 요청서에 **"반올림/버림/올림"과 "단위"**가 없으면 반드시 되물어야 합니다.

### 2-2. 1인분 가격 — 나눗셈과 올림

```sql
SELECT name,
    price,
    price / 2          AS per_person,
    CEIL(price / 2)    AS per_person_ceil,
    price DIV 2        AS per_person_div
FROM menus
WHERE name LIKE '%2인%';
```

<sub>▶ 실행 결과 · 1행</sub>

| name | price | per_person | per_person_ceil | per_person_div |
|---|---|---|---|---|
| 마라샹궈 (2인) | 27000 | 13500.0000 | 13500 | 13500 |


> MySQL에서 정수 ÷ 정수는 **소수 결과**를 냅니다(`/`). 몫만 원하면 `DIV`. Java의 `7 / 2 = 3`과 다르니 주의하세요.

---

## 3. 날짜·시간 함수

### 3-1. 꺼내기

| 함수 | 결과 (`'2026-06-30 18:47:07'` 기준) |
|---|---|
| `DATE(dt)` | `2026-06-30` (시각 제거) |
| `YEAR(dt)` · `MONTH(dt)` · `DAY(dt)` | 2026 · 6 · 30 |
| `HOUR(dt)` · `MINUTE(dt)` | 18 · 47 |
| `DAYOFWEEK(dt)` | 3 (**1=일요일** … 7=토요일) |
| `WEEKDAY(dt)` | 1 (**0=월요일** … 6=일요일) |
| `LAST_DAY(d)` | `2026-06-30` (그 달의 마지막 날) |

```sql
SELECT order_id,
    ordered_at,
    DATE(ordered_at)       AS order_date,
    HOUR(ordered_at)       AS order_hour,
    DAYOFWEEK(ordered_at)  AS dow
FROM orders
WHERE ordered_at >= '2026-06-30';
```

<sub>▶ 실행 결과 · 6행</sub>

| order_id | ordered_at | order_date | order_hour | dow |
|---|---|---|---|---|
| 558 | 2026-06-30 11:29:06 | 2026-06-30 | 11 | 3 |
| 559 | 2026-06-30 13:40:19 | 2026-06-30 | 13 | 3 |
| 560 | 2026-06-30 17:49:59 | 2026-06-30 | 17 | 3 |
| 561 | 2026-06-30 17:50:18 | 2026-06-30 | 17 | 3 |
| 562 | 2026-06-30 18:09:35 | 2026-06-30 | 18 | 3 |
| 563 | 2026-06-30 18:47:07 | 2026-06-30 | 18 | 3 |


> `DAYOFWEEK`(일=1)와 `WEEKDAY`(월=0)는 기준이 다릅니다. 헷갈리면 `SELECT DAYOFWEEK('2026-06-28');`(일요일)로 직접 확인하세요.

### 3-2. 형식 바꾸기 — DATE_FORMAT

| 기호 | 뜻 | 예 |
|---|---|---|
| `%Y` / `%y` | 연도 4자리 / 2자리 | 2026 / 26 |
| `%m` / `%c` | 월 2자리 / 앞 0 없이 | 06 / 6 |
| `%d` / `%e` | 일 2자리 / 앞 0 없이 | 30 / 30 |
| `%H` · `%i` · `%s` | 시(24h) · **분** · 초 | 18 · 47 · 07 |
| `%W` / `%a` | 요일 영문 / 약자 | Tuesday / Tue |

```sql
SELECT order_id,
    DATE_FORMAT(ordered_at, '%Y-%m-%d') AS order_date,
    DATE_FORMAT(ordered_at, '%c월 %e일 %H:%i') AS display_time,
    DATE_FORMAT(ordered_at, '%Y-%m') AS order_month
FROM orders
ORDER BY order_id DESC;
```

<sub>▶ 실행 결과 · 563행 (상위 3행 표시)</sub>

| order_id | order_date | display_time | order_month |
|---|---|---|---|
| 563 | 2026-06-30 | 6월 30일 18:47 | 2026-06 |
| 562 | 2026-06-30 | 6월 30일 18:09 | 2026-06 |
| 561 | 2026-06-30 | 6월 30일 17:50 | 2026-06 |


> 분은 `%M`이 아니라 **`%i`**입니다. `%M`은 월 이름(June)입니다. 가장 흔한 실수입니다.
> `DATE_FORMAT(…, '%Y-%m')`은 Ch04에서 **월별 집계**의 핵심 도구가 됩니다.

### 3-3. 차이 구하기 — DATEDIFF, TIMESTAMPDIFF

| 함수 | 결과 |
|---|---|
| `DATEDIFF(끝, 시작)` | 일수 차이 (시각 무시) |
| `TIMESTAMPDIFF(단위, 시작, 끝)` | 단위: `MINUTE` `HOUR` `DAY` `MONTH` `YEAR` … |

> ⚠️ 두 함수는 **인자 순서가 반대**입니다. `DATEDIFF`는 끝이 먼저, `TIMESTAMPDIFF`는 시작이 먼저.

**배달 소요 시간** (CS팀이 가장 자주 묻는 값)

```sql
SELECT order_id,
    ordered_at,
    delivered_at,
    TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS delivery_minutes
FROM orders
WHERE status = '배달완료'
ORDER BY delivery_minutes DESC, order_id;
```

<sub>▶ 실행 결과 · 511행 (상위 5행 표시)</sub>

| order_id | ordered_at | delivered_at | delivery_minutes |
|---|---|---|---|
| 42 | 2026-01-17 17:38:19 | 2026-01-17 18:55:08 | 76 |
| 414 | 2026-05-21 08:14:14 | 2026-05-21 09:31:02 | 76 |
| 191 | 2026-03-14 12:27:11 | 2026-03-14 13:39:17 | 72 |
| 337 | 2026-04-29 22:28:03 | 2026-04-29 23:38:44 | 70 |
| 469 | 2026-06-05 13:21:58 | 2026-06-05 14:31:06 | 69 |


**가입 경과일과 만 나이**

```sql
SELECT name,
    joined_at,
    DATEDIFF('2026-06-30', joined_at) AS days_since_join,
    birth_date,
    TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') AS age
FROM customers
ORDER BY customer_id;
```

<sub>▶ 실행 결과 · 30행 (상위 5행 표시)</sub>

| name | joined_at | days_since_join | birth_date | age |
|---|---|---|---|---|
| 김민준 | 2023-04-02 14:21:07 | 1185 | 1994-03-12 | 32 |
| 이서연 | 2023-06-18 09:47:51 | 1108 | 1998-07-25 | 27 |
| 박지훈 | 2023-08-29 20:13:40 | 1036 | 1989-11-03 | 36 |
| 최수아 | 2024-03-04 11:02:33 | 848 | 2001-02-14 | 25 |
| 정우진 | 2023-01-15 18:30:12 | 1262 | 1985-09-30 | 40 |


> `TIMESTAMPDIFF(YEAR, …)`는 **생일이 지났는지까지 따져** 만 나이를 계산합니다. `YEAR('2026-06-30') - YEAR(birth_date)`는 생일 전인 사람을 한 살 많게 계산합니다.

### 3-4. 더하고 빼기 — DATE_ADD, DATE_SUB

```sql
SELECT name,
    joined_at,
    DATE_ADD(joined_at, INTERVAL 30 DAY)  AS welcome_coupon_expires,
    DATE_SUB('2026-06-30', INTERVAL 3 MONTH) AS three_months_ago
FROM customers
WHERE joined_at >= '2026-01-01';
```

<sub>▶ 실행 결과 · 3행</sub>

| name | joined_at | welcome_coupon_expires | three_months_ago |
|---|---|---|---|
| 최예준 | 2026-02-14 21:14:52 | 2026-03-16 21:14:52 | 2026-03-30 |
| 정다인 | 2026-04-05 10:31:19 | 2026-05-05 10:31:19 | 2026-03-30 |
| 윤서아 | 2026-06-28 16:20:03 | 2026-07-28 16:20:03 | 2026-03-30 |


> `INTERVAL` 단위: `MINUTE` `HOUR` `DAY` `WEEK` `MONTH` `YEAR`. `'2026-06-30' + INTERVAL 1 DAY`처럼 연산자로도 쓸 수 있습니다.

---

## 4. 형 변환 — CAST

```sql
SELECT '10' + 5          AS implicit_num,
    CONCAT(10, '개')     AS implicit_str,
    CAST('2026-06-30' AS DATE) AS to_date,
    CAST(9900.0 AS SIGNED)     AS to_int;
```

<sub>▶ 실행 결과 · 1행</sub>

| implicit_num | implicit_str | to_date | to_int |
|---|---|---|---|
| 15 | 10개 | 2026-06-30 | 9900 |


> MySQL은 문자열과 숫자를 섞으면 **알아서 변환**(암묵적 변환)합니다. 편하지만, `'1만원' + 0`이 에러 대신 `1`이 되는 것처럼 조용히 틀린 값을 만들기도 합니다. 의도가 있으면 `CAST`로 명시하세요.

---

## 5. 조건 함수

### 5-1. IF — 둘 중 하나

```sql
SELECT name,
    price,
    IF(price >= 20000, '고가', '일반') AS price_level
FROM menus
WHERE restaurant_id = 6;
```

<sub>▶ 실행 결과 · 6행</sub>

| name | price | price_level |
|---|---|---|
| 감자튀김 | 4000 | 일반 |
| 반반 치킨 | 21000 | 고가 |
| 순살 간장 치킨 | 22000 | 고가 |
| 양념 치킨 | 21000 | 고가 |
| 치즈볼 (5개) | 5000 | 일반 |
| 후라이드 치킨 | 20000 | 고가 |


### 5-2. CASE — 여러 갈래

**검색형 CASE** — 조건을 위에서부터 차례로 검사해 **처음 참인 것** 하나만 적용합니다.

```sql
SELECT order_id,
    TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) AS minutes,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) <= 30 THEN '빠름'
        WHEN TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at) <= 60 THEN '보통'
        ELSE '지연'
    END AS speed
FROM orders
WHERE status = '배달완료'
    AND ordered_at >= '2026-06-29';
```

<sub>▶ 실행 결과 · 5행</sub>

| order_id | minutes | speed |
|---|---|---|
| 556 | 45 | 보통 |
| 557 | 25 | 빠름 |
| 558 | 40 | 보통 |
| 559 | 40 | 보통 |
| 560 | 31 | 보통 |


> 두 번째 조건에 `> 30 AND`를 쓰지 않아도 되는 이유: 30 이하는 이미 첫 번째 줄에서 걸러졌기 때문입니다. **조건의 순서가 곧 로직**입니다.

**단순형 CASE** — 한 값이 무엇과 같은지 비교할 때

```sql
SELECT DISTINCT payment_method,
    CASE payment_method
        WHEN '카드' THEN 'CARD'
        WHEN '간편결제' THEN 'EASY_PAY'
        WHEN '계좌이체' THEN 'TRANSFER'
        ELSE 'ON_SITE'
    END AS payment_code
FROM orders;
```

<sub>▶ 실행 결과 · 4행</sub>

| payment_method | payment_code |
|---|---|
| 간편결제 | EASY_PAY |
| 현장결제 | ON_SITE |
| 카드 | CARD |
| 계좌이체 | TRANSFER |


> `ELSE`를 빼면 어느 조건에도 안 맞는 값은 **NULL**이 됩니다. 의도한 게 아니라면 ELSE를 꼭 쓰세요.

### 5-3. NULL 처리 — IFNULL, COALESCE, NULLIF

| 함수 | 결과 |
|---|---|
| `IFNULL(a, b)` | a가 NULL이면 b, 아니면 a |
| `COALESCE(a, b, c, …)` | **처음으로 NULL이 아닌** 값 |
| `NULLIF(a, b)` | a와 b가 같으면 NULL, 다르면 a |

```sql
SELECT name,
    email,
    IFNULL(email, '(미등록)') AS email_display,
    COALESCE(email, phone) AS contact
FROM customers
ORDER BY email IS NULL DESC, customer_id;
```

<sub>▶ 실행 결과 · 30행 (상위 8행 표시)</sub>

| name | email | email_display | contact |
|---|---|---|---|
| 최수아 | NULL | (미등록) | 010-5527-3018 |
| 윤지아 | NULL | (미등록) | 010-9936-4407 |
| 신동욱 | NULL | (미등록) | 010-6481-7720 |
| 배수빈 | NULL | (미등록) | 010-3936-0058 |
| 김서준 | NULL | (미등록) | 010-8481-5579 |
| 조은서 | NULL | (미등록) | 010-6047-3589 |
| 김민준 | minjun.kim@gmail.com | minjun.kim@gmail.com | minjun.kim@gmail.com |
| 이서연 | seoyeon.lee@naver.com | seoyeon.lee@naver.com | seoyeon.lee@naver.com |


```sql
SELECT name,
    IFNULL(phone, '전화 없음 — 앱 채팅 문의') AS phone_display
FROM restaurants
ORDER BY phone IS NULL DESC, restaurant_id;
```

<sub>▶ 실행 결과 · 15행 (상위 5행 표시)</sub>

| name | phone_display |
|---|---|
| 남천동마라공방 | 전화 없음 — 앱 채팅 문의 |
| 장전동든든김밥 | 전화 없음 — 앱 채팅 문의 |
| 서면옛날돼지국밥 | 051-805-1124 |
| 전포카츠 | 051-816-3302 |
| 해운대명가밀면 | 051-742-5508 |


---

## 6. ⚠️ NULL이 섞이면 결과도 NULL

NULL은 "모르는 값"이라, 모르는 값과 계산하면 결과도 모릅니다.

```sql
SELECT 10000 + NULL               AS plus_null,
    CONCAT('메일: ', NULL)        AS concat_null,
    CONCAT_WS(' / ', '김민준', NULL, '부산진구') AS concat_ws_skip,
    CHAR_LENGTH(NULL)             AS len_null;
```

<sub>▶ 실행 결과 · 1행</sub>

| plus_null | concat_null | concat_ws_skip | len_null |
|---|---|---|---|
| NULL | NULL | 김민준 / 부산진구 | NULL |


실제 데이터에서 이 함정에 빠지는 예:

```sql
SELECT name,
    CONCAT(name, ' <', email, '>') AS mail_to
FROM customers
ORDER BY email IS NULL DESC, customer_id;
```

<sub>▶ 실행 결과 · 30행 (상위 5행 표시)</sub>

| name | mail_to |
|---|---|
| 최수아 | NULL |
| 윤지아 | NULL |
| 신동욱 | NULL |
| 배수빈 | NULL |
| 김서준 | NULL |


이메일이 없는 고객은 이름까지 통째로 NULL이 됐습니다. 이메일 발송 목록을 만들다 이런 일이 생기면 **아무 경고 없이** 6명이 사라집니다. `IFNULL`로 감싸거나 `CONCAT_WS`를 쓰세요.

### NULLIF — 0으로 나누기 방지

```sql
SELECT 10 / 0             AS divide_by_zero,
    10 / NULLIF(0, 0)     AS safe_divide;
```

<sub>▶ 실행 결과 · 1행</sub>

| divide_by_zero | safe_divide |
|---|---|
| NULL | NULL |


MySQL은 0으로 나누면 에러 대신 NULL을 돌려줍니다(엄격 모드에서 INSERT·UPDATE 중이면 에러). 분모가 0일 수 있는 비율 계산(Ch04: 취소율 = 취소 건수 / 전체 건수)에서는 `NULLIF(분모, 0)`으로 의도를 드러내는 습관을 들이세요.

---

## 7. WHERE와 ORDER BY에서도 함수를 쓸 수 있다

```sql
SELECT order_id, ordered_at, status
FROM orders
WHERE DAYOFWEEK(ordered_at) IN (1, 7)        -- 일요일, 토요일
    AND ordered_at >= '2026-06-27'
    AND ordered_at < '2026-06-29'
ORDER BY HOUR(ordered_at), order_id;
```

<sub>▶ 실행 결과 · 8행</sub>

| order_id | ordered_at | status |
|---|---|---|
| 548 | 2026-06-27 11:33:21 | 배달완료 |
| 549 | 2026-06-27 12:01:05 | 배달완료 |
| 552 | 2026-06-28 12:29:43 | 배달완료 |
| 550 | 2026-06-27 18:55:37 | 배달완료 |
| 553 | 2026-06-28 18:47:34 | 배달완료 |
| 551 | 2026-06-27 19:21:59 | 배달완료 |
| 554 | 2026-06-28 19:48:50 | 배달완료 |
| 555 | 2026-06-28 20:01:38 | 배달완료 |


> ⚠️ **성능 주의** — `WHERE MONTH(ordered_at) = 6`도 결과는 맞지만, 열에 함수를 씌우면 그 열의 **인덱스를 쓸 수 없어** 데이터가 많을 때 느립니다. 기간 조건은 Ch02처럼 `ordered_at >= '2026-06-01' AND ordered_at < '2026-07-01'`로 쓰는 것이 원칙입니다. 이유는 Ch10에서 EXPLAIN으로 확인합니다.

---

## 8. 오늘의 요청 해결

```sql
SELECT name,
    CONCAT(LEFT(phone, 4), '****', RIGHT(phone, 5)) AS masked_phone,
    birth_date,
    TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') AS age,
    CASE
        WHEN birth_date IS NULL THEN '미입력'
        ELSE CONCAT(FLOOR(TIMESTAMPDIFF(YEAR, birth_date, '2026-06-30') / 10) * 10, '대')
    END AS age_group,
    DATEDIFF('2026-06-30', joined_at) AS days_since_join
FROM customers
ORDER BY customer_id;
```

<sub>▶ 실행 결과 · 30행</sub>

| name | masked_phone | birth_date | age | age_group | days_since_join |
|---|---|---|---|---|---|
| 김민준 | 010-****-5523 | 1994-03-12 | 32 | 30대 | 1185 |
| 이서연 | 010-****-1187 | 1998-07-25 | 27 | 20대 | 1108 |
| 박지훈 | 010-****-7762 | 1989-11-03 | 36 | 30대 | 1036 |
| 최수아 | 010-****-3018 | 2001-02-14 | 25 | 20대 | 848 |
| 정우진 | 010-****-9045 | 1985-09-30 | 40 | 40대 | 1262 |
| 강하은 | 010-****-2290 | 1996-12-08 | 29 | 20대 | 709 |
| 조현우 | 010-****-6631 | 1992-05-19 | 34 | 30대 | 997 |
| 윤지아 | 010-****-4407 | NULL | NULL | 미입력 | 596 |
| 임도현 | 010-****-8813 | 1990-08-22 | 35 | 30대 | 1148 |
| 한예린 | 010-****-2276 | 2003-04-01 | 23 | 20대 | 485 |
| 오승민 | 010-****-5534 | 1987-01-27 | 39 | 30대 | 862 |
| 서지우 | 010-****-1149 | 1999-10-16 | 26 | 20대 | 660 |
| 신동욱 | 010-****-7720 | 1983-06-05 | 43 | 40대 | 1284 |
| 권나연 | 010-****-3365 | 1995-03-29 | 31 | 30대 | 540 |
| 황태민 | 010-****-8891 | 1991-11-11 | 34 | 30대 | 777 |
| 안소율 | 010-****-6602 | 2000-09-09 | 25 | 20대 | 346 |
| 송재원 | 010-****-4473 | NULL | NULL | 미입력 | 1031 |
| 배수빈 | 010-****-0058 | 1997-08-03 | 28 | 20대 | 549 |
| 유준호 | 010-****-9934 | 1986-04-17 | 40 | 40대 | 1235 |
| 문하린 | 010-****-3381 | 2002-01-23 | 24 | 20대 | 273 |
| 장민석 | 010-****-7716 | 1993-07-07 | 32 | 30대 | 799 |
| 홍채원 | 010-****-2245 | 1998-02-28 | 28 | 20대 | 409 |
| 김서준 | 010-****-5579 | NULL | NULL | 미입력 | 239 |
| 이하윤 | 010-****-8812 | 1990-12-31 | 35 | 30대 | 684 |
| 박시우 | 010-****-1167 | 1988-05-05 | 38 | 30대 | 192 |
| 최예준 | 010-****-4490 | 1995-10-10 | 30 | 30대 | 136 |
| 정다인 | 010-****-7723 | 2004-06-18 | 22 | 20대 | 86 |
| 강도윤 | 010-****-0156 | 1979-03-21 | 47 | 40대 | 1066 |
| 조은서 | 010-****-3589 | 1999-11-27 | 26 | 20대 | 629 |
| 윤서아 | 010-****-6812 | 2005-08-14 | 20 | 20대 | 2 |


> - 나이대: 만 나이 34 → `34 / 10 = 3.4` → `FLOOR` 3 → `× 10` = 30 → `'30대'`
> - `birth_date`가 NULL이면 `age`도 NULL입니다(6절). `CASE`의 첫 줄에서 NULL을 먼저 처리했기 때문에 `'미입력'`이 나옵니다. 순서를 바꾸면 어떻게 될까요? (실습 문제 7)
> - 30명 전원이 나와야 정답입니다. 생일·이메일이 없는 고객이 빠지지 않았는지 **행 수를 꼭 확인**하세요.

## 정리

| 분류 | 함수 | 기억할 점 |
|---|---|---|
| 문자열 | `CONCAT` `CONCAT_WS` `LEFT` `RIGHT` `SUBSTRING` `SUBSTRING_INDEX` `REPLACE` `LPAD` `CHAR_LENGTH` | 위치는 1부터, 글자 수는 `CHAR_LENGTH` |
| 숫자 | `ROUND` `TRUNCATE` `CEIL` `FLOOR` `MOD` `DIV` | 음수 자릿수 = 정수 단위. 반올림·버림·단위는 요청자에게 확인 |
| 날짜 | `DATE_FORMAT` `DATEDIFF` `TIMESTAMPDIFF` `DATE_ADD` | `%i`=분, 두 DIFF 함수는 인자 순서 반대 |
| 조건 | `IF` `CASE` `IFNULL` `COALESCE` `NULLIF` | CASE는 위에서부터 처음 참인 것, ELSE 빼면 NULL |
| NULL | — | NULL과 계산하면 NULL. `CONCAT`도 NULL |

## 다음 챕터 예고

> **From.** 정산팀 정 대리
> 상반기 결산입니다. **월별 주문 건수·취소율·배달팁 합계**와, **배달 완료 건수가 많은 가게 순위**를 주세요.

지금까지의 쿼리는 행 하나를 가공해 행 하나를 돌려줬습니다. 563건을 **6줄(월별)**로 요약하려면 행을 **묶어서** 계산해야 합니다 — Ch04, 집계와 GROUP BY.

<!-- lecture:auto -->
