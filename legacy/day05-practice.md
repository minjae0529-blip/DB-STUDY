# Day 5 실습 문제
# 데이터 요약의 기술 — 집계함수 & GROUP BY

**과정명:** 한입배달 MySQL 10일 완성  
**교육기관:** 한국IT교육센터 부산점  
**사용 DB:** hanip_delivery  
**사용 테이블:** orders, customers, restaurants

---

## 풀기 전에 확인하세요

```sql
USE hanip_delivery;

-- 데이터 확인
SELECT COUNT(*) FROM orders;          -- 50건
SELECT COUNT(*) FROM customers;       -- 10건
SELECT COUNT(*) FROM restaurants;     -- 10건
```

---

## 문제 목록

| 번호 | 난이도 | 주제 |
|------|--------|------|
| 1 | ⭐ | COUNT(*) 기본 |
| 2 | ⭐ | SUM, AVG, MAX, MIN |
| 3 | ⭐ | COUNT(*) vs COUNT(컬럼) |
| 4 | ⭐⭐ | GROUP BY 기본 |
| 5 | ⭐⭐ | HAVING 조건 |
| 6 | ⭐⭐ | 날짜 + GROUP BY |
| 7 | ⭐⭐⭐ | 다중 GROUP BY |
| 8 | ⭐⭐⭐ | WHERE + GROUP BY + HAVING 복합 |
| 보너스 1 | ⭐⭐⭐⭐ | GROUP BY + CASE WHEN |
| 보너스 2 | ⭐⭐⭐⭐ | 누적 분석 |

---

## ⭐ 문제 1

**운영팀이 알고 싶어합니다:**  
"지금까지 우리 플랫폼에서 총 몇 건의 주문이 들어왔나요?"

**사용할 테이블:** `orders`

**예상 결과:**

| 총주문건수 |
|-----------|
| 50 |

<details>
<summary>정답 보기</summary>

```sql
SELECT COUNT(*) AS 총주문건수
FROM orders;
```

**설명:**  
`COUNT(*)`는 NULL을 포함한 모든 행의 수를 셉니다.  
orders 테이블 전체 행이 50건이므로 50이 반환됩니다.

</details>

---

## ⭐ 문제 2

**사장님이 알고 싶어합니다:**  
"지금까지 전체 매출은 얼마야? 평균 주문금액은? 가장 비싼 주문과 가장 저렴한 주문은?"

**사용할 테이블:** `orders`

**예상 결과:**

| 총매출 | 평균주문금액 | 최고주문금액 | 최저주문금액 |
|--------|-------------|-------------|-------------|
| (숫자) | (숫자) | 32000 | 7000 |

> 총매출과 평균주문금액은 여러분의 INSERT 데이터에 따라 다를 수 있습니다.  
> 최고 32000, 최저 7000은 샘플 데이터 기준입니다.

<details>
<summary>정답 보기</summary>

```sql
SELECT
  SUM(total_price)            AS 총매출,
  ROUND(AVG(total_price))     AS 평균주문금액,
  MAX(total_price)            AS 최고주문금액,
  MIN(total_price)            AS 최저주문금액
FROM orders;
```

**설명:**  
- `SUM(total_price)` — 모든 주문금액을 더합니다.
- `ROUND(AVG(total_price))` — 평균을 구한 뒤 소수점을 반올림합니다.
- `MAX` / `MIN` — 가장 크고 작은 값을 찾습니다.

하나의 SELECT 안에 집계함수를 여러 개 사용하면 한 번에 결과를 볼 수 있습니다.

</details>

---

## ⭐ 문제 3

**데이터 품질팀이 알고 싶어합니다:**  
"우리 고객 중 이메일을 등록하지 않은 사람이 몇 명이나 돼요?"

**힌트:** `COUNT(*)`와 `COUNT(email)`의 차이를 이용하세요.

**사용할 테이블:** `customers`

**예상 결과:**

| 전체고객수 | 이메일등록수 | 미등록수 |
|-----------|-------------|---------|
| 10 | (숫자) | (숫자) |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  COUNT(*)                        AS 전체고객수,
  COUNT(email)                    AS 이메일등록수,
  COUNT(*) - COUNT(email)         AS 미등록수
FROM customers;
```

**설명:**  
- `COUNT(*)` — NULL 포함 전체 행 수 → 10
- `COUNT(email)` — email이 NULL이 아닌 행 수만 셈
- `COUNT(*) - COUNT(email)` — 두 값의 차이 = email이 NULL인 행 수

이 방법으로 특정 컬럼에 NULL이 몇 개 있는지 파악할 수 있습니다.

</details>

---

## ⭐⭐ 문제 4

**사장님이 알고 싶어합니다:**  
"가게별로 총 몇 건 주문받았고, 총 매출은 얼마야?  
매출이 높은 순서로 보여줘."

**사용할 테이블:** `orders`

**예상 결과 (상위 3개 샘플):**

| restaurant_id | 주문건수 | 총매출 |
|--------------|---------|--------|
| 8 | 5 | 98000 |
| 6 | 5 | 97000 |
| 1 | 7 | 84000 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  restaurant_id,
  COUNT(*)         AS 주문건수,
  SUM(total_price) AS 총매출
FROM orders
GROUP BY restaurant_id
ORDER BY 총매출 DESC;
```

**설명:**  
- `GROUP BY restaurant_id` — 가게 번호별로 행을 묶습니다.
- `COUNT(*)` — 각 그룹(가게)의 주문 건수를 셉니다.
- `SUM(total_price)` — 각 그룹의 주문금액을 합산합니다.
- `ORDER BY 총매출 DESC` — 집계 결과 컬럼의 별칭으로 정렬할 수 있습니다.

</details>

---

## ⭐⭐ 문제 5

**운영팀이 알고 싶어합니다:**  
"총 주문금액이 50,000원 이상인 단골 고객이 누구누구야?  
총 지출이 많은 순서로 보여줘."

**사용할 테이블:** `orders`

**예상 결과 (샘플):**

| customer_id | 주문횟수 | 총지출 |
|------------|---------|--------|
| 1 | 8 | 110000 |
| 2 | 7 | 94000 |
| 3 | 7 | 89000 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  customer_id,
  COUNT(*)         AS 주문횟수,
  SUM(total_price) AS 총지출
FROM orders
GROUP BY customer_id
HAVING 총지출 >= 50000
ORDER BY 총지출 DESC;
```

**설명:**  
- `HAVING 총지출 >= 50000` — GROUP BY 이후, 그룹별 집계 결과가 50,000 이상인 그룹만 남깁니다.
- WHERE가 아닌 HAVING을 써야 합니다. `SUM(total_price)`는 집계 후 결과이므로 WHERE에서는 사용할 수 없습니다.
- `HAVING` 절에서는 SELECT에서 지정한 별칭(총지출)을 사용할 수 있습니다.

</details>

---

## ⭐⭐ 문제 6

**마케팅팀이 알고 싶어합니다:**  
"월별로 주문 건수와 총 매출을 보여줘.  
어느 달이 가장 바빴는지 알고 싶어."

**사용할 테이블:** `orders`  
**힌트:** `DATE_FORMAT(order_date, '%Y-%m')`을 사용하세요.

**예상 결과:**

| 월 | 주문건수 | 총매출 | 평균주문금액 |
|----|---------|--------|-------------|
| 2024-11 | 16 | 247000 | 15438 |
| 2024-12 | 21 | 335000 | 15952 |
| 2025-01 | 13 | 208000 | 16000 |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  COUNT(*)                          AS 주문건수,
  SUM(total_price)                  AS 총매출,
  ROUND(AVG(total_price))           AS 평균주문금액
FROM orders
GROUP BY 월
ORDER BY 월;
```

**설명:**  
- `DATE_FORMAT(order_date, '%Y-%m')` — `2024-11-01 12:10:00`과 같은 DATETIME 값을 `2024-11` 형태의 문자열로 변환합니다.
- 변환된 문자열을 GROUP BY의 기준으로 사용하면 같은 연-월을 가진 행들이 하나의 그룹이 됩니다.
- GROUP BY 절에서 SELECT 별칭(월)을 사용할 수 있습니다.

</details>

---

## ⭐⭐⭐ 문제 7

**경영진이 알고 싶어합니다:**  
"월별로, 그리고 가게별로 주문 수와 매출을 한눈에 보고 싶어.  
같은 달 안에서는 매출 높은 가게가 위에 나오게 해줘."

**사용할 테이블:** `orders`

**예상 결과 (일부 샘플):**

| 월 | restaurant_id | 주문수 | 매출 |
|----|--------------|--------|------|
| 2024-11 | 8 | 2 | 39000 |
| 2024-11 | 7 | 2 | 31000 |
| 2024-11 | 6 | 2 | 30000 |
| 2024-11 | 5 | 2 | 27000 |
| ... | ... | ... | ... |
| 2024-12 | 8 | 3 | 68000 |
| ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  restaurant_id,
  COUNT(*)                          AS 주문수,
  SUM(total_price)                  AS 매출
FROM orders
GROUP BY 월, restaurant_id
ORDER BY 월 ASC, 매출 DESC;
```

**설명:**  
- `GROUP BY 월, restaurant_id` — 연-월과 가게 번호의 **조합**으로 그룹을 나눕니다.
  - 예: '2024-11' + restaurant_id 1 → 1개 그룹, '2024-11' + restaurant_id 2 → 1개 그룹
- `ORDER BY 월 ASC, 매출 DESC` — 먼저 월 기준 오름차순, 같은 달 안에서는 매출 기준 내림차순으로 정렬합니다.
- 다중 ORDER BY는 쉼표로 구분하며, 왼쪽에서 오른쪽 순서로 우선순위가 적용됩니다.

</details>

---

## ⭐⭐⭐ 문제 8

**사장님이 알고 싶어합니다:**  
"2024년 12월에, 평균 주문금액이 15,000원 이상이면서 주문이 3건 이상인 가게를 찾아줘.  
평균 주문금액이 높은 순서로 보여줘."

**사용할 테이블:** `orders`  
**조건 정리:**
- 주문 기간: 2024년 12월 (`order_date`에 WHERE 조건)
- 주문 건수: 3건 이상 (HAVING)
- 평균 주문금액: 15,000원 이상 (HAVING)

**예상 결과 (샘플):**

| restaurant_id | 주문건수 | 평균주문금액 |
|--------------|---------|-------------|
| 8 | 3 | 22667 |
| 6 | 3 | 19000 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  restaurant_id,
  COUNT(*)                    AS 주문건수,
  ROUND(AVG(total_price))     AS 평균주문금액
FROM orders
WHERE DATE_FORMAT(order_date, '%Y-%m') = '2024-12'
GROUP BY restaurant_id
HAVING 주문건수 >= 3
  AND 평균주문금액 >= 15000
ORDER BY 평균주문금액 DESC;
```

**설명:**  
이 문제는 WHERE, GROUP BY, HAVING을 모두 사용하는 복합 쿼리입니다. 실행 순서를 따라가면 쉽게 이해됩니다.

1. `FROM orders` — orders 테이블을 가져옵니다.
2. `WHERE DATE_FORMAT(order_date, '%Y-%m') = '2024-12'` — 12월 데이터만 남깁니다. (집계 전 필터)
3. `GROUP BY restaurant_id` — 가게별로 묶습니다.
4. `HAVING 주문건수 >= 3 AND 평균주문금액 >= 15000` — 집계 후, 두 조건을 모두 만족하는 그룹만 남깁니다.
5. `ORDER BY 평균주문금액 DESC` — 평균 주문금액 내림차순 정렬

**핵심 포인트:**
- 12월 필터는 GROUP BY **이전** 조건 → WHERE
- 주문건수, 평균주문금액 조건은 GROUP BY **이후** 조건 → HAVING

</details>

---

## 보너스 도전 문제

> 아래 두 문제는 오늘 배운 내용을 넘어서는 응용 문제입니다.  
> 시간이 남거나 더 배우고 싶을 때 도전해 보세요!

---

## ⭐⭐⭐⭐ 보너스 1 — GROUP BY + CASE WHEN 조합

**운영팀이 알고 싶어합니다:**  
"가게별로 총 매출을 계산하고, 매출 등급을 표시해줘.  
- 총매출 80,000원 이상 → '우수'
- 총매출 50,000원 이상 80,000원 미만 → '보통'
- 총매출 50,000원 미만 → '관리 필요'

매출이 높은 순서로 보여줘."

**사용할 테이블:** `orders`

**예상 결과 (샘플):**

| restaurant_id | 총매출 | 매출등급 |
|--------------|--------|---------|
| 8 | 98000 | 우수 |
| 6 | 97000 | 우수 |
| 1 | 84000 | 우수 |
| 5 | 76000 | 보통 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
  restaurant_id,
  SUM(total_price) AS 총매출,
  CASE
    WHEN SUM(total_price) >= 80000 THEN '우수'
    WHEN SUM(total_price) >= 50000 THEN '보통'
    ELSE '관리 필요'
  END AS 매출등급
FROM orders
GROUP BY restaurant_id
ORDER BY 총매출 DESC;
```

**설명:**  
`CASE WHEN ... THEN ... END`는 조건에 따라 다른 값을 반환하는 표현식입니다.  
GROUP BY와 함께 사용할 때는 집계함수(`SUM`, `COUNT` 등)의 결과값으로 CASE 조건을 작성합니다.

**실행 순서:**
1. GROUP BY로 가게별로 묶기
2. 각 그룹의 SUM(total_price) 계산
3. CASE WHEN으로 해당 그룹의 합산값에 따라 등급 부여

**주의:** `HAVING`과 달리 `CASE WHEN`은 SELECT 절에서 집계 결과를 직접 참조하므로 `SUM(total_price)`를 다시 써야 합니다. 별칭(총매출)은 SELECT 실행 후에 확정되기 때문에 CASE WHEN 안에서는 사용할 수 없습니다.

</details>

---

## ⭐⭐⭐⭐ 보너스 2 — 월별 누적 분석

**경영진이 알고 싶어합니다:**  
"월별 매출 현황과 함께, 전달 대비 이번 달 주문 건수 증가율을 계산해줘."

**사용할 테이블:** `orders`

**예상 결과 (샘플):**

| 월 | 주문건수 | 총매출 | 전월주문건수 | 주문건수증감 |
|----|---------|--------|------------|------------|
| 2024-11 | 16 | 247000 | NULL | NULL |
| 2024-12 | 21 | 335000 | 16 | +5 |
| 2025-01 | 13 | 208000 | 21 | -8 |

<details>
<summary>정답 보기</summary>

```sql
-- 방법 1: 서브쿼리를 이용한 셀프 JOIN
SELECT
  t1.월,
  t1.주문건수,
  t1.총매출,
  t2.주문건수                        AS 전월주문건수,
  t1.주문건수 - t2.주문건수           AS 주문건수증감
FROM (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS 월,
    COUNT(*)                          AS 주문건수,
    SUM(total_price)                  AS 총매출
  FROM orders
  GROUP BY 월
) AS t1
LEFT JOIN (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS 월,
    COUNT(*)                          AS 주문건수
  FROM orders
  GROUP BY 월
) AS t2
  ON DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(t1.월, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m') = t2.월
ORDER BY t1.월;
```

**설명:**  
이 쿼리는 **서브쿼리 + LEFT JOIN** 패턴을 사용합니다.

1. **내부 서브쿼리 t1** — 월별 주문건수와 총매출을 집계합니다.
2. **내부 서브쿼리 t2** — 동일한 집계를 별도로 만듭니다.
3. **LEFT JOIN 조건** — t1의 월에서 1개월을 빼서 t2의 월과 연결합니다.
   - `STR_TO_DATE(CONCAT(t1.월, '-01'), '%Y-%m-%d')` — '2024-12'를 '2024-12-01' 날짜로 변환
   - `DATE_ADD(..., INTERVAL -1 MONTH)` — 한 달 전으로 이동 → '2024-11-01'
   - `DATE_FORMAT(..., '%Y-%m')` — 다시 '2024-11' 형태로 변환
4. **LEFT JOIN** — 전달 데이터가 없는 첫 달은 NULL로 남깁니다.

**응용:** MySQL 8.0 이상이라면 `LAG()` 윈도우 함수를 사용하면 더 간결하게 작성할 수 있습니다.

```sql
-- 방법 2: LAG 윈도우 함수 (MySQL 8.0+)
SELECT
  월,
  주문건수,
  총매출,
  LAG(주문건수) OVER (ORDER BY 월)                AS 전월주문건수,
  주문건수 - LAG(주문건수) OVER (ORDER BY 월)     AS 주문건수증감
FROM (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS 월,
    COUNT(*)                          AS 주문건수,
    SUM(total_price)                  AS 총매출
  FROM orders
  GROUP BY 월
) AS 월별집계
ORDER BY 월;
```

`LAG(컬럼) OVER (ORDER BY 기준)` — 현재 행의 이전 행 값을 가져옵니다.  
윈도우 함수는 GROUP BY와 달리 행을 합치지 않아 이전/다음 행 참조가 쉽습니다.

</details>

---

## 오늘 문제 총정리

| 번호 | 핵심 개념 | 포인트 |
|------|----------|--------|
| 1 | COUNT(*) | 전체 행 수 세기 |
| 2 | SUM, AVG, MAX, MIN | 집계함수 4종 한 번에 |
| 3 | COUNT(*) vs COUNT(컬럼) | NULL 처리 차이 이해 |
| 4 | GROUP BY 기본 | 가게별 그룹핑 |
| 5 | HAVING | 집계 후 그룹 필터 |
| 6 | 날짜 + GROUP BY | DATE_FORMAT 활용 |
| 7 | 다중 GROUP BY | 월 + 가게 두 기준 그룹핑 |
| 8 | WHERE + GROUP BY + HAVING | 복합 조건 올바른 위치에 배치 |
| 보너스 1 | CASE WHEN | 집계 결과에 등급 부여 |
| 보너스 2 | 서브쿼리 / LAG | 전월 대비 증감 분석 |

---

*한입배달 MySQL 10일 완성 | Day 5 실습 | 한국IT교육센터 부산점*
