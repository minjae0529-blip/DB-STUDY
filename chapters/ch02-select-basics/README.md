# Ch02. SELECT 기본 — 원하는 행과 열만 정확하게

> **PART 1 · 읽기** | 3시간 | 난이도 ★
> 이전: [Ch01. 데이터베이스와 첫 만남](../ch01-first-database/README.md) | 다음: [Ch03. 함수로 데이터 가공하기](../ch03-functions/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery02`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 지난 시간 hanip_delivery01 도 그대로 남아 있음
USE hanip_delivery02;
```

> 오늘 실습은 모두 `hanip_delivery02`에서 합니다. Workbench 왼쪽 SCHEMAS에서 **굵게 표시된 DB**가 `hanip_delivery02`인지 확인하고 시작하세요. 지난 챕터 DB에서 실행해도 결과는 같지만, 기록이 섞입니다.

## 오늘의 요청

> **From.** 운영팀 박 팀장
>
> 이번 주에 **부산진구·수영구** 고객 대상으로 "최소주문 부담 없는 가게" 배너를 띄우려고 합니다.
> 두 구에 있는 **영업 중인** 가게 중 **최소 주문 금액이 15,000원 이하**인 곳을 **배달팁이 싼 순서로** 뽑아 주세요.
> 배달팁이 같으면 최소 주문 금액이 낮은 가게가 먼저 나오게 해 주시고요.

Ch01에서 배운 `SELECT * FROM restaurants`는 15곳을 전부, 정해지지 않은 순서로 보여 줍니다. 오늘은 **열 고르기 → 행 거르기 → 정렬 → 개수 자르기**를 배워 이 요청을 한 문장으로 처리합니다. 완성된 쿼리는 [8절](#8-오늘의-요청-해결)에 있습니다.

## 학습 목표

1. `SELECT` 절에 열, 계산식, 별칭을 써서 **결과의 모양**을 정한다.
2. `WHERE` 절에 비교·논리·범위·목록·패턴·NULL 조건을 써서 **원하는 행만** 고른다.
3. `AND`와 `OR`가 섞인 조건에서 **괄호**가 필요한 이유를 설명한다.
4. `ORDER BY`로 여러 기준 정렬을, `LIMIT`/`OFFSET`으로 상위 N개와 페이지를 만든다.
5. SELECT 문의 **논리적 실행 순서**를 말하고, 그로 인한 에러를 설명한다.

---

## 1. SELECT 절 — 결과의 모양 정하기

### 1-1. 필요한 열만, 원하는 순서로

```sql
SELECT name, price, restaurant_id
FROM menus;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| name | price | restaurant_id |
|---|---|---|
| 돼지국밥 | 10000 | 1 |
| 순대국밥 | 10000 | 1 |
| 섞어국밥 | 10500 | 1 |
| 수육 백반 | 13000 | 1 |
| 수육 (중) | 22000 | 1 |


열 순서는 테이블 정의와 상관없이 **SELECT에 적은 순서**대로 나옵니다.

### 1-2. 계산식

SELECT 절에는 열뿐 아니라 **식**을 쓸 수 있습니다. 원본 데이터는 바뀌지 않고, 결과 화면에서만 계산됩니다.

```sql
SELECT name,
    price,
    price * 1.1,
    price - 1000
FROM menus;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| name | price | price * 1.1 | price - 1000 |
|---|---|---|---|
| 돼지국밥 | 10000 | 11000.0 | 9000 |
| 순대국밥 | 10000 | 11000.0 | 9000 |
| 섞어국밥 | 10500 | 11550.0 | 9500 |
| 수육 백반 | 13000 | 14300.0 | 12000 |
| 수육 (중) | 22000 | 24200.0 | 21000 |


### 1-3. 별칭 (AS)

계산식의 열 이름(`price * 1.1`)은 읽기 어렵습니다. `AS`로 이름을 붙입니다.

```sql
SELECT name AS menu_name,
    price AS current_price,
    price + 500 AS price_after_raise
FROM menus;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| menu_name | current_price | price_after_raise |
|---|---|---|
| 돼지국밥 | 10000 | 10500 |
| 순대국밥 | 10000 | 10500 |
| 섞어국밥 | 10500 | 11000 |
| 수육 백반 | 13000 | 13500 |
| 수육 (중) | 22000 | 22500 |


> - 별칭은 **결과에서만** 쓰는 이름입니다. 테이블의 열 이름은 바뀌지 않습니다.
> - `AS`는 생략할 수 있지만(`price new_price`), Ch01 문제 7처럼 쉼표 실수와 구별이 안 되므로 **항상 씁니다.**
> - 한글 별칭은 백틱으로 감쌉니다: ``price AS `현재가` ``. 실무 코드에서는 영문 snake_case를 씁니다.

### 1-4. DISTINCT — 중복 제거

우리 플랫폼에 입점한 가게들은 어떤 업종들일까요?

```sql
SELECT category FROM restaurants;
```

<sub>▶ 실행 결과 · 15행 (상위 10행 표시)</sub>

| category |
|---|
| 한식 |
| 일식 |
| 한식 |
| 피자 |
| 중식 |
| 치킨 |
| 한식 |
| 중식 |
| 분식 |
| 양식 |


```sql
SELECT DISTINCT category FROM restaurants;
```

<sub>▶ 실행 결과 · 8행</sub>

| category |
|---|
| 한식 |
| 일식 |
| 피자 |
| 중식 |
| 치킨 |
| 분식 |
| 양식 |
| 카페·디저트 |


`DISTINCT`는 **결과 행 전체**를 기준으로 중복을 제거합니다. 열이 둘이면 두 값의 **조합**이 같아야 중복입니다.

```sql
SELECT DISTINCT district, category
FROM restaurants;
```

<sub>▶ 실행 결과 · 15행 (상위 10행 표시)</sub>

| district | category |
|---|---|
| 부산진구 | 한식 |
| 부산진구 | 일식 |
| 해운대구 | 한식 |
| 수영구 | 피자 |
| 수영구 | 중식 |
| 남구 | 치킨 |
| 동래구 | 한식 |
| 연제구 | 중식 |
| 중구 | 분식 |
| 사하구 | 양식 |


> `DISTINCT district, category`는 "district만 중복 제거"가 아닙니다. `(부산진구, 한식)`과 `(부산진구, 일식)`은 다른 행입니다.

---

## 2. WHERE 절 — 원하는 행만 고르기

`WHERE` 뒤의 조건이 **참(TRUE)인 행만** 결과에 남습니다.

### 2-1. 비교 연산자

| 연산자 | 뜻 | 예 |
|---|---|---|
| `=` | 같다 | `category = '치킨'` |
| `<>` 또는 `!=` | 다르다 | `status <> '취소'` |
| `>` `>=` `<` `<=` | 크다·작다 | `price >= 20000` |

```sql
SELECT name, district, delivery_fee
FROM restaurants
WHERE category = '치킨';
```

<sub>▶ 실행 결과 · 2행</sub>

| name | district | delivery_fee |
|---|---|---|
| 대연동크런치치킨 | 남구 | 3000 |
| 서면야식치킨 | 부산진구 | 2000 |


```sql
SELECT name, price
FROM menus
WHERE price >= 20000;
```

<sub>▶ 실행 결과 · 9행</sub>

| name | price |
|---|---|
| 수육 (중) | 22000 |
| 트러플 머쉬룸 | 23000 |
| 마라샹궈 (2인) | 27000 |
| 후라이드 치킨 | 20000 |
| 양념 치킨 | 21000 |
| 반반 치킨 | 21000 |
| 순살 간장 치킨 | 22000 |
| 모둠 초밥 (12pc) | 22000 |
| 특선 오마카세 도시락 | 45000 |


**문자열과 날짜**도 비교할 수 있습니다. 날짜는 문자열처럼 작은따옴표로 씁니다.

```sql
SELECT name, opened_at
FROM restaurants
WHERE opened_at >= '2025-01-01';
```

<sub>▶ 실행 결과 · 3행</sub>

| name | opened_at |
|---|---|
| 남천동마라공방 | 2025-02-10 |
| 해운대스시하루 | 2025-06-12 |
| 전포동오일파스타 | 2026-06-24 |


**BOOLEAN 열**은 `TRUE`/`FALSE`와 비교합니다.

```sql
SELECT name, restaurant_id
FROM menus
WHERE is_sold_out = TRUE;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | restaurant_id |
|---|---|
| 마라 볶음면 | 5 |
| 밀크쉐이크 | 10 |
| 딸기 크로플 | 14 |


> `WHERE is_sold_out = 1`, `WHERE is_sold_out`도 같은 결과입니다. 이 과정에서는 의도가 가장 잘 보이는 `= TRUE`를 씁니다.

### 2-2. 논리 연산자 — AND, OR, NOT

| 연산자 | 결과가 참이 되는 경우 |
|---|---|
| `A AND B` | A와 B가 **모두** 참 |
| `A OR B` | A와 B 중 **하나라도** 참 |
| `NOT A` | A가 거짓 |

```sql
SELECT name, category, district
FROM restaurants
WHERE district = '수영구'
    AND category <> '카페·디저트';
```

<sub>▶ 실행 결과 · 2행</sub>

| name | category | district |
|---|---|---|
| 광안리화덕피자 | 피자 | 수영구 |
| 남천동마라공방 | 중식 | 수영구 |


### 2-3. ⚠️ AND와 OR가 섞이면 — 괄호!

> **요청**: 부산진구나 수영구에 있는 **한식** 가게를 찾아 주세요.

언뜻 맞아 보이는 쿼리:

```sql
SELECT name, category, district
FROM restaurants
WHERE district = '부산진구' OR district = '수영구' AND category = '한식';
```

<sub>▶ 실행 결과 · 4행</sub>

| name | category | district |
|---|---|---|
| 서면옛날돼지국밥 | 한식 | 부산진구 |
| 전포카츠 | 일식 | 부산진구 |
| 서면야식치킨 | 치킨 | 부산진구 |
| 전포동오일파스타 | 양식 | 부산진구 |


수영구에는 한식 가게가 없는데, 부산진구의 **일식·치킨·양식** 가게가 전부 나왔습니다. **`AND`가 `OR`보다 먼저 계산**되기 때문입니다. MySQL은 위 조건을 이렇게 읽었습니다.

```
district = '부산진구'  OR  (district = '수영구' AND category = '한식')
```

의도대로 하려면 **괄호**로 묶습니다.

```sql
SELECT name, category, district
FROM restaurants
WHERE (district = '부산진구' OR district = '수영구')
    AND category = '한식';
```

<sub>▶ 실행 결과 · 1행</sub>

| name | category | district |
|---|---|---|
| 서면옛날돼지국밥 | 한식 | 부산진구 |


> **규칙: AND와 OR를 한 WHERE에 섞을 때는 우선순위를 외우지 말고 항상 괄호를 쓴다.** 실무 코드 리뷰에서 괄호 없는 AND/OR 혼용은 그 자체로 지적 대상입니다.

### 2-4. BETWEEN — 범위

`A BETWEEN x AND y`는 `A >= x AND A <= y`와 같습니다. **양 끝을 포함**합니다.

```sql
SELECT name, price
FROM menus
WHERE price BETWEEN 10000 AND 12000;
```

<sub>▶ 실행 결과 · 11행 (상위 10행 표시)</sub>

| name | price |
|---|---|
| 돼지국밥 | 10000 |
| 순대국밥 | 10000 |
| 섞어국밥 | 10500 |
| 등심카츠 | 11000 |
| 회밀면 | 11000 |
| 마라 볶음면 | 11000 |
| 도토리묵무침 | 12000 |
| 베이컨 BBQ 버거 | 10900 |
| 닭똥집 튀김 | 12000 |
| 프렌치 토스트 | 12000 |


#### ⚠️ 날짜·시각 범위의 함정

CS팀이 **6월 한 달**의 주문 건수를 물었습니다.

```sql
SELECT COUNT(*) AS june_orders
FROM orders
WHERE ordered_at BETWEEN '2026-06-01' AND '2026-06-30';
```

<sub>▶ 실행 결과 · 1행</sub>

| june_orders |
|---|
| 103 |


```sql
SELECT COUNT(*) AS june_orders
FROM orders
WHERE ordered_at >= '2026-06-01'
    AND ordered_at < '2026-07-01';
```

<sub>▶ 실행 결과 · 1행</sub>

| june_orders |
|---|
| 109 |


6건이 차이 납니다. `ordered_at`은 **DATETIME**(날짜+시각)입니다. `'2026-06-30'`은 `'2026-06-30 00:00:00'`, 즉 **6월 30일 0시 정각**으로 해석되므로, 6월 30일 하루치 주문이 통째로 빠졌습니다.

```sql
SELECT order_id, ordered_at, status
FROM orders
WHERE ordered_at >= '2026-06-30';
```

<sub>▶ 실행 결과 · 6행</sub>

| order_id | ordered_at | status |
|---|---|---|
| 558 | 2026-06-30 11:29:06 | 배달완료 |
| 559 | 2026-06-30 13:40:19 | 배달완료 |
| 560 | 2026-06-30 17:49:59 | 배달완료 |
| 561 | 2026-06-30 17:50:18 | 배달중 |
| 562 | 2026-06-30 18:09:35 | 조리중 |
| 563 | 2026-06-30 18:47:07 | 접수 |


> **규칙: DATETIME 열의 기간 조건은 `>= 시작일 AND < 다음날`(반열린 구간)로 쓴다.** 월말이 28·30·31일인지 신경 쓸 필요도 없어집니다. 실무에서 가장 흔한 집계 버그 중 하나입니다.

### 2-5. IN — 목록 중 하나

`OR`를 여러 번 쓰는 대신 목록으로 씁니다.

```sql
SELECT name, category, district
FROM restaurants
WHERE category IN ('치킨', '피자', '분식');
```

<sub>▶ 실행 결과 · 5행</sub>

| name | category | district |
|---|---|---|
| 광안리화덕피자 | 피자 | 수영구 |
| 대연동크런치치킨 | 치킨 | 남구 |
| 남포동떡볶이연구소 | 분식 | 중구 |
| 장전동든든김밥 | 분식 | 금정구 |
| 서면야식치킨 | 치킨 | 부산진구 |


```sql
SELECT order_id, status, ordered_at
FROM orders
WHERE status NOT IN ('배달완료', '취소');
```

<sub>▶ 실행 결과 · 3행</sub>

| order_id | status | ordered_at |
|---|---|---|
| 561 | 배달중 | 2026-06-30 17:50:18 |
| 562 | 조리중 | 2026-06-30 18:09:35 |
| 563 | 접수 | 2026-06-30 18:47:07 |


> 위 결과가 **지금 진행 중인 주문**입니다 (스냅숏 시각 2026-06-30 19:00 기준).

### 2-6. LIKE — 문자열 패턴

| 기호 | 뜻 | 예 | 일치하는 값 |
|---|---|---|---|
| `%` | 0글자 이상 아무거나 | `'%치킨'` | 치킨, 후라이드 치킨, 양념 치킨 |
| `_` | 정확히 1글자 | `'_밀면'` | 물밀면 (회밀면, 비빔밀면 ✗) |

```sql
SELECT name, price, restaurant_id
FROM menus
WHERE name LIKE '%치킨%';
```

<sub>▶ 실행 결과 · 6행</sub>

| name | price | restaurant_id |
|---|---|---|
| 후라이드 치킨 | 20000 | 6 |
| 양념 치킨 | 21000 | 6 |
| 반반 치킨 | 21000 | 6 |
| 순살 간장 치킨 | 22000 | 6 |
| 후라이드 치킨 | 17000 | 13 |
| 양념 치킨 | 18000 | 13 |


```sql
SELECT name
FROM menus
WHERE name LIKE '_밀면';
```

<sub>▶ 실행 결과 · 2행</sub>

| name |
|---|
| 물밀면 |
| 회밀면 |


```sql
SELECT name, address
FROM customers
WHERE address LIKE '%전포동%';
```

<sub>▶ 실행 결과 · 2행</sub>

| name | address |
|---|---|
| 김민준 | 부산광역시 부산진구 전포동 서전로 23, 302호 |
| 최예준 | 부산광역시 부산진구 전포동 동천로 109, 1403호 |


> - `LIKE '%검색어%'`처럼 **앞에 `%`가 붙으면** 인덱스를 쓸 수 없어 데이터가 많을 때 느립니다 (Ch10).
> - 이 DB의 기본 정렬 규칙(`utf8mb4_0900_ai_ci`)은 대소문자를 구분하지 않습니다. `LIKE '%bbq%'`도 'BBQ'를 찾습니다.

### 2-7. NULL — "값이 없음"

`NULL`은 0도, 빈 문자열(`''`)도 아닌 **"모름·해당 없음"**입니다. 그래서 `=`로 비교할 수 없습니다.

```sql
SELECT name, email
FROM customers
WHERE email = NULL;
```

<sub>▶ 실행 결과 · 0행 — 조건에 맞는 데이터 없음</sub>




에러는 없지만 **0행**입니다. `NULL = NULL`의 결과조차 참이 아니라 "모름(NULL)"이기 때문입니다. NULL은 반드시 `IS NULL` / `IS NOT NULL`로 확인합니다.

```sql
SELECT name, phone, email
FROM customers
WHERE email IS NULL;
```

<sub>▶ 실행 결과 · 6행</sub>

| name | phone | email |
|---|---|---|
| 최수아 | 010-5527-3018 | NULL |
| 윤지아 | 010-9936-4407 | NULL |
| 신동욱 | 010-6481-7720 | NULL |
| 배수빈 | 010-3936-0058 | NULL |
| 김서준 | 010-8481-5579 | NULL |
| 조은서 | 010-6047-3589 | NULL |


Ch01 문제 8에서 추측했던 "기사가 없는 주문"을 확인해 봅시다.

```sql
SELECT order_id, status, rider_id, delivered_at
FROM orders
WHERE rider_id IS NULL
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| order_id | status | rider_id | delivered_at |
|---|---|---|---|
| 16 | 취소 | NULL | NULL |
| 25 | 취소 | NULL | NULL |
| 38 | 취소 | NULL | NULL |
| 39 | 취소 | NULL | NULL |
| 55 | 취소 | NULL | NULL |


> 취소된 주문과, 아직 기사가 배정되지 않은 주문(접수·조리중)입니다. 데이터의 NULL에는 대부분 **업무적 이유**가 있습니다.

#### NULL은 `<>`에도 걸리지 않는다

```sql
SELECT COUNT(*) AS not_naver
FROM customers
WHERE email NOT LIKE '%@naver.com';
```

<sub>▶ 실행 결과 · 1행</sub>

| not_naver |
|---|
| 16 |


전체 고객 30명 중 네이버 메일이 아닌 사람은 몇 명일까요? 네이버 메일 사용자는 8명인데, 8 + 16 = 24로 30이 안 됩니다. 이메일이 **NULL인 6명**은 `NOT LIKE`에서도 참이 아니라 "모름"이 되어 빠졌습니다. NULL까지 포함하려면 명시해야 합니다.

```sql
SELECT COUNT(*) AS not_naver_or_unknown
FROM customers
WHERE email NOT LIKE '%@naver.com'
    OR email IS NULL;
```

<sub>▶ 실행 결과 · 1행</sub>

| not_naver_or_unknown |
|---|
| 22 |


---

## 3. ORDER BY — 정렬

| 키워드 | 뜻 |
|---|---|
| `ASC` | 오름차순 (작은 값 → 큰 값, 가 → 하, 과거 → 최근). **기본값** |
| `DESC` | 내림차순 |

```sql
SELECT name, price
FROM menus
ORDER BY price DESC;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| name | price |
|---|---|
| 특선 오마카세 도시락 | 45000 |
| 마라샹궈 (2인) | 27000 |
| 트러플 머쉬룸 | 23000 |
| 모둠 초밥 (12pc) | 22000 |
| 수육 (중) | 22000 |


### 여러 기준으로 정렬

첫 번째 기준이 **같을 때만** 두 번째 기준을 봅니다.

```sql
SELECT name, delivery_fee, min_order_amount
FROM restaurants
WHERE is_open = TRUE
ORDER BY delivery_fee ASC, min_order_amount ASC;
```

<sub>▶ 실행 결과 · 14행 (상위 10행 표시)</sub>

| name | delivery_fee | min_order_amount |
|---|---|---|
| 연산동짬뽕반점 | 2000 | 8000 |
| 장전동든든김밥 | 2000 | 8000 |
| 해운대명가밀면 | 2000 | 9000 |
| 서면옛날돼지국밥 | 2500 | 10000 |
| 남포동떡볶이연구소 | 2500 | 10000 |
| 전포카츠 | 3000 | 12000 |
| 하단버거스탠드 | 3000 | 12000 |
| 남천동마라공방 | 3000 | 13000 |
| 동래파전골목집 | 3000 | 15000 |
| 전포동오일파스타 | 3000 | 15000 |


### 별칭으로 정렬

ORDER BY는 SELECT보다 **나중에** 실행되므로(6절) 별칭을 쓸 수 있습니다.

```sql
SELECT name,
    price,
    price * 1.1 AS price_with_vat
FROM menus
ORDER BY price_with_vat DESC;
```

<sub>▶ 실행 결과 · 70행 (상위 5행 표시)</sub>

| name | price | price_with_vat |
|---|---|---|
| 특선 오마카세 도시락 | 45000 | 49500.0 |
| 마라샹궈 (2인) | 27000 | 29700.0 |
| 트러플 머쉬룸 | 23000 | 25300.0 |
| 모둠 초밥 (12pc) | 22000 | 24200.0 |
| 수육 (중) | 22000 | 24200.0 |


### NULL의 정렬 위치

MySQL은 오름차순에서 **NULL을 맨 앞**에 둡니다.

```sql
SELECT name, birth_date
FROM customers
ORDER BY birth_date;
```

<sub>▶ 실행 결과 · 30행 (상위 5행 표시)</sub>

| name | birth_date |
|---|---|
| 김서준 | NULL |
| 송재원 | NULL |
| 윤지아 | NULL |
| 강도윤 | 1979-03-21 |
| 신동욱 | 1983-06-05 |


> NULL을 뒤로 보내고 싶으면 `ORDER BY birth_date IS NULL, birth_date` — `IS NULL`의 결과(0 또는 1)로 먼저 정렬하는 기법입니다.

---

## 4. LIMIT과 OFFSET — 상위 N개, 페이지

### Top-N

정렬과 함께 써야 의미가 있습니다. **ORDER BY 없는 LIMIT은 "아무 N개"**입니다.

```sql
SELECT name, price
FROM menus
ORDER BY price DESC
LIMIT 3;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | price |
|---|---|
| 특선 오마카세 도시락 | 45000 |
| 마라샹궈 (2인) | 27000 |
| 트러플 머쉬룸 | 23000 |


### 페이지 나누기

앱에서 메뉴를 한 화면에 5개씩 보여 준다면:

```sql
SELECT menu_id, name, price
FROM menus
ORDER BY menu_id
LIMIT 5 OFFSET 5;    -- 2페이지: 앞의 5개를 건너뛰고 5개
```

<sub>▶ 실행 결과 · 5행</sub>

| menu_id | name | price |
|---|---|---|
| 6 | 등심카츠 | 11000 |
| 7 | 안심카츠 | 12500 |
| 8 | 치즈카츠 | 13000 |
| 9 | 카레우동 | 9000 |
| 10 | 새우튀김 (3pc) | 6000 |


> **공식**: `LIMIT 페이지크기 OFFSET (페이지번호 - 1) × 페이지크기`
> `LIMIT 5, 5`(= `LIMIT 건너뛸수, 가져올수`)도 같은 뜻인데 순서가 헷갈려서 이 과정에서는 `OFFSET`을 명시합니다.

### ⚠️ 동점이 있는 Top-N

```sql
SELECT name, price
FROM menus
ORDER BY price DESC
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| name | price |
|---|---|
| 특선 오마카세 도시락 | 45000 |
| 마라샹궈 (2인) | 27000 |
| 트러플 머쉬룸 | 23000 |
| 순살 간장 치킨 | 22000 |
| 수육 (중) | 22000 |


22,000원 메뉴가 세 개(수육 (중), 순살 간장 치킨, 모둠 초밥 (12pc))인데 5위 안에는 두 개만 들어갔습니다. **어느 쪽이 들어갈지는 보장되지 않습니다.** 결과를 항상 같게 하려면 유일한 열(보통 기본키)을 마지막 정렬 기준으로 추가합니다.

```sql
SELECT menu_id, name, price
FROM menus
ORDER BY price DESC, menu_id
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| menu_id | name | price |
|---|---|---|
| 58 | 특선 오마카세 도시락 | 45000 |
| 22 | 마라샹궈 (2인) | 27000 |
| 18 | 트러플 머쉬룸 | 23000 |
| 5 | 수육 (중) | 22000 |
| 28 | 순살 간장 치킨 | 22000 |


---

## 5. 지금까지의 SELECT 문 형태

```sql
SELECT   열, 계산식 AS 별칭        -- ⑤ 무엇을 보여 줄까
FROM     테이블                     -- ① 어디서
WHERE    행 조건                    -- ② 어떤 행을
ORDER BY 정렬 기준                  -- ⑥ 어떤 순서로
LIMIT    개수 OFFSET 건너뛸 수;     -- ⑦ 몇 개
```

**작성 순서는 위에서 아래로 고정**입니다. `WHERE`를 `ORDER BY` 뒤에 쓰면 1064 에러입니다. (③④는 Ch04의 GROUP BY·HAVING 자리)

---

## 6. 논리적 실행 순서

DB는 적힌 순서가 아니라 아래 순서로 처리합니다.

```
① FROM  →  ② WHERE  →  (③ GROUP BY → ④ HAVING)  →  ⑤ SELECT  →  ⑥ ORDER BY  →  ⑦ LIMIT
   표 고르기   행 거르기       Ch04                      열 만들기     정렬          자르기
```

이 순서를 알면 다음 에러가 설명됩니다.

```sql
SELECT name, price * 1.1 AS price_with_vat
FROM menus
WHERE price_with_vat > 20000;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1054. Unknown column 'price_with_vat' in 'where clause'
```


`WHERE`(②)가 실행될 때 `SELECT`(⑤)의 별칭 `price_with_vat`은 **아직 만들어지지 않았습니다.** WHERE에는 원래 식을 씁니다.

```sql
SELECT name, price * 1.1 AS price_with_vat
FROM menus
WHERE price * 1.1 > 20000
ORDER BY price_with_vat DESC;
```

<sub>▶ 실행 결과 · 11행 (상위 10행 표시)</sub>

| name | price_with_vat |
|---|---|
| 특선 오마카세 도시락 | 49500.0 |
| 마라샹궈 (2인) | 29700.0 |
| 트러플 머쉬룸 | 25300.0 |
| 수육 (중) | 24200.0 |
| 순살 간장 치킨 | 24200.0 |
| 모둠 초밥 (12pc) | 24200.0 |
| 양념 치킨 | 23100.0 |
| 반반 치킨 | 23100.0 |
| 후라이드 치킨 | 22000.0 |
| 페퍼로니 | 20900.0 |


반대로 `ORDER BY`(⑥)는 SELECT 다음이라 별칭을 쓸 수 있었습니다(3절).

---

## 7. 자주 하는 실수 모음

| 실수 | 결과 | 바른 쓰기 |
|---|---|---|
| `WHERE email = NULL` | 0행 (에러 없음) | `WHERE email IS NULL` |
| `WHERE category = 치킨` | 1054 Unknown column '치킨' | `'치킨'` (따옴표) |
| `WHERE a = 1 OR b = 2 AND c = 3` | 의도와 다른 행 | 괄호로 묶기 |
| `ordered_at BETWEEN '…-01' AND '…-30'` | 마지막 날 누락 | `>= '…-01' AND < '다음달-01'` |
| `WHERE 별칭 > …` | 1054 Unknown column | 원래 식 반복 |
| `ORDER BY` 없이 `LIMIT` | 매번 다를 수 있는 결과 | 정렬 기준 + 기본키 |
| `SELECT DISTINCT a, b`로 a만 중복 제거 기대 | 조합 기준 중복 제거 | 의도에 맞는 열만 선택 |

---

## 8. 오늘의 요청 해결

> 부산진구·수영구 / 영업 중 / 최소주문 15,000원 이하 / 배달팁 오름차순, 같으면 최소주문 오름차순

```sql
SELECT name,
    district,
    category,
    min_order_amount,
    delivery_fee
FROM restaurants
WHERE district IN ('부산진구', '수영구')
    AND is_open = TRUE
    AND min_order_amount <= 15000
ORDER BY delivery_fee, min_order_amount;
```

<sub>▶ 실행 결과 · 5행</sub>

| name | district | category | min_order_amount | delivery_fee |
|---|---|---|---|---|
| 서면옛날돼지국밥 | 부산진구 | 한식 | 10000 | 2500 |
| 전포카츠 | 부산진구 | 일식 | 12000 | 3000 |
| 남천동마라공방 | 수영구 | 중식 | 13000 | 3000 |
| 전포동오일파스타 | 부산진구 | 양식 | 15000 | 3000 |
| 광안리브런치카페 | 수영구 | 카페·디저트 | 15000 | 3500 |


> - `IN`을 썼기 때문에 AND/OR 우선순위 문제가 생기지 않았습니다. `OR`로 쓴다면 괄호가 필수입니다.
> - 폐업한 서면야식치킨은 `is_open = TRUE` 조건으로, 최소주문 18,000원인 광안리화덕피자는 금액 조건으로 빠졌습니다.

## 정리

| 문법 | 핵심 |
|---|---|
| `SELECT 식 AS 별칭` | 결과의 모양. 원본은 안 바뀜 |
| `DISTINCT` | 결과 **행 전체** 기준 중복 제거 |
| `WHERE` | 조건이 참인 행만. AND·OR 섞으면 괄호 |
| `BETWEEN` | 양 끝 포함. DATETIME 기간은 `>= AND <` |
| `IN` / `LIKE` | 목록 중 하나 / 패턴 (`%` 여러 글자, `_` 한 글자) |
| `IS NULL` | NULL은 `=`·`<>`로 잡히지 않음 |
| `ORDER BY` | 기본 ASC, 여러 기준, 별칭 가능, 마지막에 기본키 |
| `LIMIT … OFFSET` | Top-N, 페이징 |
| 실행 순서 | FROM → WHERE → SELECT → ORDER BY → LIMIT |

## 다음 챕터 예고

> **From.** 마케팅팀 이 매니저
> 생일 쿠폰 문자를 보내려고 합니다. 고객 명단을 주시되 **전화번호 가운데 네 자리는 `****`로 가리고**, **나이**와 **가입한 지 며칠 됐는지**도 붙여 주세요.

`customers`에는 나이 열도, 가입 경과일 열도 없습니다. 있는 값을 **가공**해서 새 값을 만드는 방법 — Ch03의 함수입니다.

<!-- lecture:auto -->
