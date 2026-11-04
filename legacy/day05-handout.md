# Day 5 학생 핸드아웃
# 데이터 요약의 기술 — 집계함수 & GROUP BY

**과정명:** 한입배달 MySQL 10일 완성  
**교육기관:** 한국IT교육센터 부산점  
**대상:** 완전 초보자  
**소요시간:** 약 3시간

---

## 목차

1. 오늘의 핵심 질문
2. 복습 체크 (Day 3 돌아보기)
3. orders 테이블 소개
4. 집계함수 5종
5. GROUP BY — 그룹별로 집계하기
6. HAVING — 그룹에 조건 달기
7. 날짜 + GROUP BY 조합
8. 다중 GROUP BY
9. 실전 쿼리 예제 5개
10. 자주 발생하는 에러 3가지
11. 오늘 배운 것 정리
12. Day 6 예고

---

## 1. 오늘의 핵심 질문

사장님이 어느 날 이런 질문을 합니다.

> "지금까지 총 매출이 얼마야?  
> 가게별로 보면 어떤 가게가 제일 잘 팔려?  
> 11월, 12월, 1월 각각 얼마나 팔았어?"

Day 1~4에서 우리는 데이터를 **조회**하고 **필터링**하는 방법을 배웠습니다.  
하지만 지금까지 배운 SELECT는 한 번에 하나씩 행을 돌려줬습니다.

사장님이 원하는 건 **요약된 숫자** 입니다.  
50건의 주문을 전부 출력하는 게 아니라, 가게별로 합산하거나, 월별로 묶어서 숫자 하나를 뽑아내야 합니다.

오늘 이것을 해결하는 두 가지 도구를 배웁니다.

- **집계함수** — COUNT, SUM, AVG, MAX, MIN
- **GROUP BY** — 그룹별로 집계하기

---

## 2. 복습 체크 (Day 3 돌아보기)

| 배운 내용 | 핵심 키워드 |
|-----------|-------------|
| 조건 걸기 | WHERE, AND |
| 정렬과 제한 | ORDER BY, LIMIT |

**Day 4 핵심 문법 요약:**

```sql
SELECT a.컬럼, b.컬럼
FROM 테이블A a
INNER JOIN 테이블B b ON a.id = b.a_id
WHERE 조건
ORDER BY 컬럼 DESC
LIMIT 10;
```

오늘은 여기에 **GROUP BY**와 **HAVING**이 추가됩니다.

---

## 3. orders 테이블 소개

### 새 테이블 등장!

오늘부터 **orders** 테이블을 사용합니다.  
실제 배달 앱에서 주문이 들어오면 이런 형태로 저장됩니다.

```sql
CREATE TABLE orders (
  id            INT PRIMARY KEY AUTO_INCREMENT,
  customer_id   INT NOT NULL,
  restaurant_id INT NOT NULL,
  menu_id       INT NOT NULL,
  quantity      INT NOT NULL DEFAULT 1,
  total_price   INT NOT NULL,
  order_date    DATETIME NOT NULL,
  delivery_fee  INT NOT NULL DEFAULT 3000,
  status        VARCHAR(20) DEFAULT '배달완료'
);
```

### 컬럼별 설명

| 컬럼명 | 타입 | 설명 | 예시 |
|--------|------|------|------|
| id | INT | 주문 고유 번호, 자동 증가 | 1, 2, 3 … |
| customer_id | INT | 주문한 고객 번호 (customers.id 참조) | 1 ~ 8 |
| restaurant_id | INT | 주문받은 가게 번호 (restaurants.id 참조) | 1 ~ 9 |
| menu_id | INT | 주문된 메뉴 번호 (menus.id 참조) | 1 ~ 30 |
| quantity | INT | 주문 수량 (기본값 1) | 1, 2, 3 |
| total_price | INT | 총 결제금액 (메뉴 가격 × 수량) | 9000, 18000 … |
| order_date | DATETIME | 주문 일시 | 2024-11-01 12:10:00 |
| delivery_fee | INT | 배달료 (기본값 3000) | 2000, 2500, 3000, 4000 |
| status | VARCHAR(20) | 주문 상태 | '배달완료' |

### 실습 데이터 현황

오늘 실습에서 사용하는 orders 테이블은 다음 조건으로 구성되어 있습니다.

- **총 50건** 의 주문 데이터
- **주문 기간:** 2024년 11월 ~ 2025년 1월 (3개월)
- **고객:** customer_id 1~8만 주문 (9, 10은 주문 없음 — Day 6 복선!)
- **가게:** restaurant_id 1~9만 주문 (10은 주문 없음 — Day 6 복선!)
- **금액:** 7,000원 ~ 32,000원

---

## 4. 집계함수 5종

### 집계함수란?

여러 행의 값을 **하나의 값으로 요약**하는 함수입니다.  
50건의 주문에서 "총 얼마?"를 하나의 숫자로 만들어 주는 것이 집계함수입니다.

| 함수 | 기능 | 예시 |
|------|------|------|
| COUNT | 행의 개수를 셉니다 | 주문 건수 |
| SUM | 값을 모두 더합니다 | 총 매출 |
| AVG | 평균값을 구합니다 | 평균 주문금액 |
| MAX | 가장 큰 값을 구합니다 | 최고 주문금액 |
| MIN | 가장 작은 값을 구합니다 | 최저 주문금액 |

---

### 4-1. COUNT — 개수 세기

#### 기본 문법

```sql
SELECT COUNT(*) FROM 테이블명;
SELECT COUNT(컬럼명) FROM 테이블명;
```

#### COUNT(*) vs COUNT(컬럼) ★★ 중요

이 둘은 비슷해 보이지만 **NULL 처리 방식이 다릅니다.**

| 구분 | NULL 처리 | 설명 |
|------|-----------|------|
| COUNT(*) | NULL 포함 | 행 자체를 셈. NULL이 있어도 카운트 |
| COUNT(컬럼) | NULL 제외 | 해당 컬럼 값이 NULL인 행은 제외하고 셈 |

**실습 예시:**

```sql
-- orders 전체 행 수 (NULL 여부 무관)
SELECT COUNT(*) FROM orders;
```

| COUNT(*) |
|----------|
| 50 |

```sql
-- customers에서 차이 확인
-- (email을 입력하지 않은 고객은 NULL이므로 COUNT(email)이 더 작게 나옴)
SELECT COUNT(*) AS 전체고객수, COUNT(email) AS 이메일등록수
FROM customers;
```

| 전체고객수 | 이메일등록수 |
|-----------|-------------|
| 10 | 7 |

**해석:** 고객은 10명이지만 이메일을 등록한 사람은 7명입니다.  
`COUNT(*)`은 10, `COUNT(email)`은 7이 나오는 이유입니다.

**흔한 실수:**
> "COUNT(*) 쓰면 뭔가 잘못된 거 아닌가요?"

아닙니다. 행의 전체 개수를 셀 때는 `COUNT(*)`가 정석입니다.  
특정 컬럼에 NULL이 없는지 파악할 때 `COUNT(컬럼)`를 씁니다.

---

### 4-2. SUM — 합계

#### 기본 문법

```sql
SELECT SUM(컬럼명) FROM 테이블명;
```

**실습 예시:**

```sql
-- 전체 총 매출
SELECT SUM(total_price) AS 총매출 FROM orders;
```

| 총매출 |
|--------|
| 790000 |

```sql
-- 총 배달료 합계
SELECT SUM(delivery_fee) AS 총배달료 FROM orders;
```

| 총배달료 |
|---------|
| 130500 |

**주의:** SUM은 숫자 컬럼에만 사용할 수 있습니다.  
문자 컬럼에 SUM을 쓰면 0이 반환되거나 오류가 납니다.

---

### 4-3. AVG — 평균

#### 기본 문법

```sql
SELECT AVG(컬럼명) FROM 테이블명;
```

**실습 예시:**

```sql
-- 평균 주문금액 (소수점 포함)
SELECT AVG(total_price) AS 평균주문금액 FROM orders;
```

| 평균주문금액 |
|-------------|
| 15800.0000 |

소수점이 너무 많이 나오면 `ROUND()`로 반올림합니다.

```sql
-- ROUND로 깔끔하게
SELECT ROUND(AVG(total_price)) AS 평균주문금액 FROM orders;
```

| 평균주문금액 |
|-------------|
| 15800 |

```sql
-- 소수점 둘째 자리까지 표시
SELECT ROUND(AVG(total_price), 2) AS 평균주문금액 FROM orders;
```

| 평균주문금액 |
|-------------|
| 15800.00 |

---

### 4-4. MAX / MIN — 최대·최솟값

#### 기본 문법

```sql
SELECT MAX(컬럼명), MIN(컬럼명) FROM 테이블명;
```

**실습 예시:**

```sql
-- 가장 비싼 주문과 가장 저렴한 주문
SELECT MAX(total_price) AS 최고주문금액, MIN(total_price) AS 최저주문금액
FROM orders;
```

| 최고주문금액 | 최저주문금액 |
|-------------|-------------|
| 32000 | 7000 |

```sql
-- 가장 최근 주문일과 가장 오래된 주문일
SELECT MAX(order_date) AS 최근주문일, MIN(order_date) AS 첫주문일
FROM orders;
```

| 최근주문일 | 첫주문일 |
|-----------|---------|
| 2025-01-31 18:45:00 | 2024-11-01 12:10:00 |

**Tip:** MAX/MIN은 숫자뿐만 아니라 날짜, 문자열에도 사용할 수 있습니다.

---

### 4-5. 집계함수 한꺼번에 사용하기

```sql
-- 전체 주문 요약 한 방에
SELECT
  COUNT(*)                    AS 총주문건수,
  SUM(total_price)            AS 총매출,
  ROUND(AVG(total_price))     AS 평균주문금액,
  MAX(total_price)            AS 최고주문금액,
  MIN(total_price)            AS 최저주문금액
FROM orders;
```

| 총주문건수 | 총매출 | 평균주문금액 | 최고주문금액 | 최저주문금액 |
|-----------|--------|-------------|-------------|-------------|
| 50 | 790000 | 15800 | 32000 | 7000 |

---

## 5. GROUP BY — 그룹별로 집계하기

### 왜 GROUP BY가 필요할까?

집계함수만 쓰면 **전체** 에 대한 숫자 하나만 나옵니다.  
"가게별로" 또는 "고객별로" 나눠서 집계하려면 **GROUP BY** 가 필요합니다.

**비유: 학교 시험 점수**

> 전체 학생 평균 점수 → 집계함수 하나면 됨  
> **반별** 평균 점수 → GROUP BY 반 을 써야 함

집계함수가 "전체 학교 평균"을 구한다면,  
GROUP BY는 "각 반의 평균"을 구하는 것입니다.

---

### 5-1. GROUP BY 없을 때 vs 있을 때 비교

**GROUP BY 없을 때 — 전체 집계**

```sql
SELECT COUNT(*) AS 주문수 FROM orders;
```

| 주문수 |
|--------|
| 50 |

전체 50건을 하나의 숫자로 요약합니다.

**GROUP BY 있을 때 — 가게별 집계**

```sql
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
GROUP BY restaurant_id;
```

| restaurant_id | 주문수 |
|--------------|--------|
| 1 | 7 |
| 2 | 6 |
| 3 | 6 |
| 4 | 5 |
| 5 | 6 |
| 6 | 5 |
| 7 | 5 |
| 8 | 5 |
| 9 | 5 |

가게마다 따로따로 집계됩니다.

---

### 5-2. GROUP BY 기본 문법

```sql
SELECT 그룹컬럼, 집계함수(컬럼)
FROM 테이블명
GROUP BY 그룹컬럼;
```

**가게별 총 매출 (높은 순)**

```sql
SELECT
  restaurant_id,
  SUM(total_price) AS 총매출
FROM orders
GROUP BY restaurant_id
ORDER BY 총매출 DESC;
```

| restaurant_id | 총매출 |
|--------------|--------|
| 8 | 98000 |
| 6 | 97000 |
| 1 | 84000 |
| ... | ... |

---

### 5-3. SELECT 규칙 ← 자주 틀리는 부분 ★★★

GROUP BY를 사용할 때 SELECT에 올 수 있는 컬럼은 두 종류뿐입니다.

> **① GROUP BY에 명시된 컬럼**  
> **② 집계함수로 감싼 컬럼**

이 규칙을 어기면 오류가 나거나 예상과 다른 결과가 나옵니다.

**잘못된 예:**

```sql
-- ❌ status는 GROUP BY에도 없고, 집계함수로 감싸지도 않았음
SELECT restaurant_id, status, COUNT(*)
FROM orders
GROUP BY restaurant_id;
```

MySQL은 이 쿼리를 실행할 수 있지만 `status` 값이 **임의로 선택**되어 의미 없는 결과가 나옵니다.  
(다른 DBMS에서는 오류가 납니다.)

**올바른 예:**

```sql
-- ✅ restaurant_id만 GROUP BY에 있으므로 SELECT에도 그것만 (+ 집계함수)
SELECT restaurant_id, COUNT(*) AS 주문수, SUM(total_price) AS 총매출
FROM orders
GROUP BY restaurant_id;
```

---

### 5-4. 쿼리 실행 순서 다이어그램

MySQL이 쿼리를 처리하는 순서는 작성 순서와 다릅니다!

```
작성 순서              실행 순서
─────────────          ─────────────────────────────────────────
SELECT        →    1. FROM       (어떤 테이블에서?)
FROM          →    2. WHERE      (어떤 행만 남길까?)
WHERE         →    3. GROUP BY   (어떻게 그룹 나눌까?)
GROUP BY      →    4. HAVING     (어떤 그룹만 남길까?)
HAVING        →    5. SELECT     (어떤 컬럼을 보여줄까?)
ORDER BY      →    6. ORDER BY   (어떤 순서로 정렬할까?)
LIMIT         →    7. LIMIT      (몇 개만 보여줄까?)
```

이 순서를 기억하면 WHERE와 HAVING의 차이를 이해하기 쉽습니다.  
**WHERE**는 3단계 이전(GROUP BY 전)에 실행되므로 집계함수 결과를 알 수 없습니다.  
**HAVING**은 4단계(GROUP BY 후)에 실행되므로 집계함수 결과로 필터링할 수 있습니다.

---

## 6. HAVING — 그룹에 조건 달기

### WHERE는 개인 필터, HAVING은 그룹 필터

**비유:**

> - WHERE: 시험 점수 70점 이하인 **학생**을 제외하고 평균 구하기
> - HAVING: 반 평균이 80점 이상인 **반**만 보여주기

WHERE는 **행(개인)** 에 조건을 겁니다.  
HAVING은 **그룹** 에 조건을 겁니다.

---

### 6-1. WHERE vs HAVING 비교 표

| 구분 | WHERE | HAVING |
|------|-------|--------|
| 적용 시점 | GROUP BY 이전 | GROUP BY 이후 |
| 필터 대상 | 개별 행 | 그룹 |
| 집계함수 사용 | 불가 | 가능 |
| 인덱스 활용 | 가능 (빠름) | 제한적 |

---

### 6-2. HAVING 기본 문법

```sql
SELECT 그룹컬럼, 집계함수(컬럼)
FROM 테이블명
GROUP BY 그룹컬럼
HAVING 조건;
```

**주문이 5건 이상인 가게만 보기**

```sql
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
GROUP BY restaurant_id
HAVING 주문수 >= 5;
```

| restaurant_id | 주문수 |
|--------------|--------|
| 1 | 7 |
| 2 | 6 |
| 3 | 6 |
| 5 | 6 |
| 4 | 5 |
| 6 | 5 |
| 7 | 5 |
| 8 | 5 |
| 9 | 5 |

---

### 6-3. 잘못된 예 vs 올바른 예

**[상황] 배달완료 건만 집계하고, 그중 주문이 5건 이상인 가게 보기**

```sql
-- ❌ 잘못된 예: HAVING에서 집계 전 컬럼 필터링
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
GROUP BY restaurant_id
HAVING status = '배달완료' AND 주문수 >= 5;
-- status는 GROUP BY 이전에 필터해야 할 컬럼 → WHERE로 이동
```

```sql
-- ✅ 올바른 예: WHERE로 먼저 필터 → GROUP BY → HAVING
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
WHERE status = '배달완료'      -- 집계 전: 배달완료 건만 남김
GROUP BY restaurant_id
HAVING 주문수 >= 5;            -- 집계 후: 5건 이상인 그룹만 남김
```

**[상황] 총 지출이 5만 원 이상인 고객 보기**

```sql
-- ✅ 올바른 예
SELECT customer_id, SUM(total_price) AS 총지출
FROM orders
GROUP BY customer_id
HAVING 총지출 >= 50000
ORDER BY 총지출 DESC;
```

| customer_id | 총지출 |
|------------|--------|
| 1 | 110000 |
| 2 | 94000 |
| 3 | 89000 |
| ... | ... |

---

## 7. 날짜 + GROUP BY 조합

### DATE_FORMAT 함수

날짜를 원하는 형식의 문자열로 변환하는 함수입니다.  
GROUP BY와 함께 사용하면 **월별, 연도별, 일별** 집계가 가능합니다.

```sql
DATE_FORMAT(날짜컬럼, '형식문자열')
```

**자주 쓰는 형식 패턴:**

| 패턴 | 의미 | 예시 |
|------|------|------|
| %Y | 4자리 연도 | 2024 |
| %m | 2자리 월 (01~12) | 11 |
| %d | 2자리 일 (01~31) | 15 |
| %Y-%m | 연-월 | 2024-11 |
| %Y-%m-%d | 연-월-일 | 2024-11-15 |

---

### 7-1. 월별 주문 수

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  COUNT(*) AS 주문수
FROM orders
GROUP BY 월
ORDER BY 월;
```

| 월 | 주문수 |
|----|--------|
| 2024-11 | 16 |
| 2024-12 | 21 |
| 2025-01 | 13 |

---

### 7-2. 월별 종합 분석

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  COUNT(*)                          AS 주문수,
  SUM(total_price)                  AS 총매출,
  ROUND(AVG(total_price))           AS 평균주문금액
FROM orders
GROUP BY 월
ORDER BY 월;
```

| 월 | 주문수 | 총매출 | 평균주문금액 |
|----|--------|--------|-------------|
| 2024-11 | 16 | 247000 | 15438 |
| 2024-12 | 21 | 335000 | 15952 |
| 2025-01 | 13 | 223000 | 17154 |

---

## 8. 다중 GROUP BY

GROUP BY에 컬럼을 **여러 개** 나열하면 더 세밀하게 그룹을 나눌 수 있습니다.

```sql
GROUP BY 컬럼1, 컬럼2
```

컬럼1과 컬럼2의 **조합**이 같은 행들이 하나의 그룹이 됩니다.

---

### 8-1. 월별 + 가게별 그룹핑

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  restaurant_id,
  COUNT(*)         AS 주문수,
  SUM(total_price) AS 매출
FROM orders
GROUP BY 월, restaurant_id
ORDER BY 월, 매출 DESC;
```

| 월 | restaurant_id | 주문수 | 매출 |
|----|--------------|--------|------|
| 2024-11 | 8 | 2 | 39000 |
| 2024-11 | 6 | 2 | 30000 |
| 2024-11 | 7 | 2 | 31000 |
| 2024-11 | 1 | 2 | 27000 |
| ... | ... | ... | ... |
| 2024-12 | 8 | 3 | 68000 |
| ... | ... | ... | ... |

---

### 8-2. 고객별 주문 요약

```sql
SELECT
  customer_id,
  COUNT(*)         AS 주문횟수,
  SUM(total_price) AS 총지출
FROM orders
GROUP BY customer_id
ORDER BY 총지출 DESC;
```

| customer_id | 주문횟수 | 총지출 |
|------------|---------|--------|
| 1 | 8 | 110000 |
| 2 | 7 | 94000 |
| 3 | 7 | 89000 |
| ... | ... | ... |

---

## 9. 실전 쿼리 예제 — "사장님이 알고 싶어합니다"

### 예제 1 — 전체 서비스 현황 요약

> "우리 서비스 전체 매출이 얼마야? 총 몇 건 주문이 들어왔어?"

```sql
SELECT
  COUNT(*)                    AS 총주문건수,
  SUM(total_price)            AS 총매출,
  ROUND(AVG(total_price))     AS 평균주문금액,
  MIN(total_price)            AS 최소주문금액,
  MAX(total_price)            AS 최대주문금액
FROM orders;
```

| 총주문건수 | 총매출 | 평균주문금액 | 최소주문금액 | 최대주문금액 |
|-----------|--------|-------------|-------------|-------------|
| 50 | 790000 | 15800 | 7000 | 32000 |

---

### 예제 2 — 가게별 매출 Top 5

> "가게별로 얼마나 팔았어? 매출 상위 5개 가게 알고 싶어."

```sql
SELECT
  restaurant_id,
  COUNT(*)                    AS 주문건수,
  SUM(total_price)            AS 총매출,
  ROUND(AVG(total_price))     AS 평균주문금액
FROM orders
GROUP BY restaurant_id
ORDER BY 총매출 DESC
LIMIT 5;
```

| restaurant_id | 주문건수 | 총매출 | 평균주문금액 |
|--------------|---------|--------|-------------|
| 8 | 5 | 98000 | 19600 |
| 6 | 5 | 97000 | 19400 |
| 1 | 7 | 84000 | 12000 |
| ... | ... | ... | ... |

---

### 예제 3 — 월별 매출 추이

> "월별로 주문량이 어떻게 변하고 있어? 성수기가 언제야?"

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  COUNT(*)                          AS 주문건수,
  SUM(total_price)                  AS 월매출,
  ROUND(AVG(total_price))           AS 평균주문금액
FROM orders
GROUP BY 월
ORDER BY 월;
```

| 월 | 주문건수 | 월매출 | 평균주문금액 |
|----|---------|--------|-------------|
| 2024-11 | 16 | 247000 | 15438 |
| 2024-12 | 21 | 335000 | 15952 |
| 2025-01 | 13 | 208000 | 16000 |

---

### 예제 4 — 단골 고객 Top 5

> "우리 단골 고객 TOP 5 알려줘. 지출 많은 순으로."

```sql
SELECT
  customer_id,
  COUNT(*)                    AS 주문횟수,
  SUM(total_price)            AS 총지출,
  ROUND(AVG(total_price))     AS 평균주문금액,
  MAX(order_date)             AS 최근주문일
FROM orders
GROUP BY customer_id
ORDER BY 총지출 DESC
LIMIT 5;
```

| customer_id | 주문횟수 | 총지출 | 평균주문금액 | 최근주문일 |
|------------|---------|--------|-------------|-----------|
| 1 | 8 | 110000 | 13750 | 2025-01-17 18:20:00 |
| 2 | 7 | 94000 | 13428 | 2025-01-19 12:30:00 |
| ... | ... | ... | ... | ... |

---

### 예제 5 — 부진 가게 점검

> "주문이 뜸한 가게(월 3건 미만)가 어디야? 관리가 필요해 보여."

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS 월,
  restaurant_id,
  COUNT(*)                          AS 월별주문수
FROM orders
GROUP BY 월, restaurant_id
HAVING 월별주문수 < 3
ORDER BY 월, 월별주문수;
```

| 월 | restaurant_id | 월별주문수 |
|----|--------------|-----------|
| 2024-11 | 1 | 2 |
| 2024-11 | 2 | 2 |
| ... | ... | ... |

---

## 10. 자주 발생하는 에러 3가지

### 에러 1 — GROUP BY에 없는 컬럼을 SELECT에 사용

**에러 상황:**

```sql
-- ❌ 문제가 되는 쿼리
SELECT restaurant_id, status, COUNT(*)
FROM orders
GROUP BY restaurant_id;
-- status가 GROUP BY에 없음!
```

**발생 가능한 에러:**  
MySQL의 `ONLY_FULL_GROUP_BY` 모드가 켜져 있으면 다음 에러가 납니다.

```
ERROR 1055 (42000): Expression #2 of SELECT list is not in GROUP BY clause
and contains nonaggregated column 'hanip_delivery.orders.status' which is
not functionally dependent on columns in GROUP BY clause
```

**해결법:**  
SELECT에는 GROUP BY 컬럼과 집계함수만 씁니다.

```sql
-- ✅ 해결: status를 빼거나 GROUP BY에 추가
SELECT restaurant_id, COUNT(*)
FROM orders
GROUP BY restaurant_id;

-- 또는
SELECT restaurant_id, status, COUNT(*)
FROM orders
GROUP BY restaurant_id, status;
```

---

### 에러 2 — WHERE에 집계함수 사용

**에러 상황:**

```sql
-- ❌ WHERE 절에 집계함수 사용
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
WHERE COUNT(*) >= 5
GROUP BY restaurant_id;
```

**발생 에러:**

```
ERROR 1111 (HY000): Invalid use of group function
```

**이유:** WHERE는 GROUP BY보다 먼저 실행됩니다. 이 시점에는 아직 COUNT()가 계산되지 않았습니다.

**해결법:**  
집계함수 조건은 반드시 HAVING을 사용합니다.

```sql
-- ✅ 해결: HAVING으로 이동
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
GROUP BY restaurant_id
HAVING 주문수 >= 5;
```

---

### 에러 3 — GROUP BY 없이 집계함수와 일반 컬럼 혼용

**에러 상황:**

```sql
-- ❌ GROUP BY 없이 집계함수 + 일반 컬럼 혼용
SELECT restaurant_id, COUNT(*)
FROM orders;
-- GROUP BY가 없으므로 restaurant_id가 무엇을 가리켜야 할지 모름
```

**발생 가능한 에러 (ONLY_FULL_GROUP_BY 모드):**

```
ERROR 1140 (42000): In aggregated query without GROUP BY, expression #1
of SELECT list contains nonaggregated column 'hanip_delivery.orders.restaurant_id'
```

**해결법 ①** GROUP BY 추가

```sql
SELECT restaurant_id, COUNT(*)
FROM orders
GROUP BY restaurant_id;
```

**해결법 ②** 집계함수만 SELECT (전체 집계가 목적이라면)

```sql
SELECT COUNT(*) FROM orders;
```

---

## 11. 오늘 배운 것 정리 — 키워드 요약표

| 키워드 / 함수 | 역할 | 사용 위치 |
|--------------|------|-----------|
| COUNT(*) | 전체 행 수 (NULL 포함) | SELECT |
| COUNT(컬럼) | NULL 제외 행 수 | SELECT |
| SUM(컬럼) | 합계 | SELECT |
| AVG(컬럼) | 평균 | SELECT |
| MAX(컬럼) | 최댓값 | SELECT |
| MIN(컬럼) | 최솟값 | SELECT |
| ROUND(값, 자릿수) | 반올림 | SELECT |
| GROUP BY 컬럼 | 그룹 기준 지정 | GROUP BY 절 |
| HAVING 조건 | 그룹 필터 (집계 후) | HAVING 절 |
| WHERE 조건 | 행 필터 (집계 전) | WHERE 절 |
| DATE_FORMAT(날짜, 형식) | 날짜를 원하는 형식 문자열로 변환 | SELECT, GROUP BY |

### 실행 순서 기억법

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

> "**프웨그하셀오리**" 처럼 앞 글자를 따서 외워보세요!  
> **프**(FROM) **웨**(WHERE) **그**(GROUP BY) **하**(HAVING) **셀**(SELECT) **오**(ORDER BY) **리**(LIMIT)

---

### 핵심 규칙 3가지 요약

```
1. GROUP BY 사용 시 SELECT에는 GROUP BY 컬럼 또는 집계함수만 가능
2. WHERE는 집계 전(개별 행) 필터, HAVING은 집계 후(그룹) 필터
3. 집계함수는 WHERE에서 사용 불가, HAVING에서만 사용 가능
```

---

## 12. Day 6 예고 — "이름으로 보고 싶어요!"

오늘 실습에서 집계 결과를 보면 이런 점이 불편했을 것입니다.

| restaurant_id | 총매출 |
|--------------|--------|
| 1 | 84000 |
| 2 | 71000 |
| 3 | ... |

> "restaurant_id 1이 어느 가게야? 이름으로 보여주면 좋겠는데..."

맞습니다! 숫자 ID보다 가게 이름이 더 직관적입니다.  
**Day 6**에서는 오늘 배운 GROUP BY에 **JOIN**을 결합합니다.

```sql
-- Day 6에서 배울 내용 미리 보기
SELECT
  r.name AS 가게이름,
  COUNT(*) AS 주문수,
  SUM(o.total_price) AS 총매출
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
GROUP BY r.id, r.name
ORDER BY 총매출 DESC;
```

그러면 이렇게 나옵니다.

| 가게이름 | 주문수 | 총매출 |
|---------|--------|--------|
| 홍길동 순대국 | 7 | 84000 |
| 부산 돼지국밥 | 6 | 71000 |
| ... | ... | ... |

또한, 오늘 데이터에서 **customer_id 9, 10번 고객과 restaurant_id 10번 가게는 주문이 0건**입니다.  
INNER JOIN을 사용하면 이들은 결과에서 **사라집니다**.  
하지만 "주문이 없는 가게도 보고 싶다"면 어떻게 할까요?  
Day 6에서 **LEFT JOIN**으로 해결합니다!

---

*한입배달 MySQL 10일 완성 | Day 5 | 한국IT교육센터 부산점*
