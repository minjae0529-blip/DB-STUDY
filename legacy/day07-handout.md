# Day 7 — 서브쿼리: 쿼리 안의 쿼리

> **한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점**

---

## 목차

1. [오늘의 핵심 질문](#1-오늘의-핵심-질문)
2. [서브쿼리란 무엇인가?](#2-서브쿼리란-무엇인가)
3. [WHERE절 서브쿼리 — 단일행](#3-where절-서브쿼리--단일행)
4. [WHERE절 서브쿼리 — 다중행](#4-where절-서브쿼리--다중행)
5. [FROM절 서브쿼리 (인라인 뷰)](#5-from절-서브쿼리-인라인-뷰)
6. [SELECT절 스칼라 서브쿼리](#6-select절-스칼라-서브쿼리)
7. [EXISTS / NOT EXISTS](#7-exists--not-exists)
8. [UNION / UNION ALL](#8-union--union-all)
9. [서브쿼리 vs JOIN 선택 기준](#9-서브쿼리-vs-join-선택-기준)
10. [서브쿼리 작성 팁](#10-서브쿼리-작성-팁)
11. [자주 발생하는 에러 3가지](#11-자주-발생하는-에러-3가지)
12. [오늘 배운 것 정리](#12-오늘-배운-것-정리)
13. [Day 8 예고](#13-day-8-예고)

---

## 1. 오늘의 핵심 질문

> "가격이 평균보다 비싼 메뉴만 보려면, 평균을 먼저 구해야 하는데…"

### 비유로 이해하기 — 시험 평균 이상 학생 찾기

학교 시험이 끝났다고 상상해 보세요. 선생님이 "반 평균 이상인 학생을 칭찬하겠다"고 합니다. 이 작업을 어떻게 진행할까요?

**사람이 하는 방식**
1. 먼저 전체 점수를 더해서 평균을 구한다 → 평균: 72점
2. "72점 이상인 학생"을 명단에서 찾는다

**SQL에서도 똑같이 두 단계**가 필요합니다.

```sql
-- Step 1: 평균 먼저
SELECT AVG(price) FROM menus;
-- 결과: 12500

-- Step 2: 그 숫자로 필터링
SELECT menu_name, price FROM menus WHERE price > 12500;
```

**문제점**: 평균 가격이 바뀌면 매번 Step 1을 실행하고, 12500이라는 숫자를 Step 2에 직접 고쳐야 합니다. 데이터가 바뀔 때마다 수동으로 바꿔줘야 하니 번거롭습니다.

**해결책**: 두 단계를 하나로 합친다 → **서브쿼리(Subquery)**

```sql
SELECT menu_name, price
FROM menus
WHERE price > (SELECT AVG(price) FROM menus);
```

괄호 안의 `SELECT AVG(price) FROM menus`가 먼저 실행되고, 그 결과가 바깥 `WHERE` 조건의 비교값으로 사용됩니다. 데이터가 바뀌어도 쿼리를 수정할 필요가 없습니다.

---

## 2. 서브쿼리란 무엇인가?

### 정의

**서브쿼리(Subquery)** 는 다른 SQL 문 안에 포함된 SELECT 문입니다. "쿼리 안의 쿼리", "중첩 쿼리"라고도 부릅니다.

```
바깥 쿼리(메인 쿼리)
    SELECT ...
    FROM ...
    WHERE 컬럼 > (  ← 여기서 서브쿼리 시작
        SELECT ...  ← 서브쿼리
        FROM ...
    )              ← 서브쿼리 끝
```

### 핵심 규칙 3가지

| 규칙 | 설명 |
|------|------|
| **괄호로 감싼다** | 서브쿼리는 반드시 `( )` 안에 작성한다 |
| **서브쿼리가 먼저 실행된다** | MySQL은 안쪽 쿼리를 먼저 실행하고 그 결과를 바깥 쿼리에 전달한다 |
| **위치에 따라 역할이 다르다** | WHERE절, FROM절, SELECT절에 각각 다른 방식으로 사용한다 |

### 서브쿼리 위치별 분류

| 위치 | 이름 | 반환 형태 | 특징 |
|------|------|-----------|------|
| WHERE절 | 조건 서브쿼리 | 단일값 또는 여러 값 | 비교 연산자 또는 IN/ANY/ALL/EXISTS와 함께 사용 |
| FROM절 | 인라인 뷰 | 테이블 | 임시 테이블처럼 동작, 반드시 별칭 필요 |
| SELECT절 | 스칼라 서브쿼리 | 단일값(1행 1열) | 각 행마다 단 하나의 값을 반환해야 함 |

---

## 3. WHERE절 서브쿼리 — 단일행

### 개념

서브쿼리가 **딱 하나의 값(1행 1열)** 을 반환할 때 사용합니다. `=`, `>`, `<`, `>=`, `<=`, `!=` 같은 일반 비교 연산자를 그대로 쓸 수 있습니다.

```
바깥 쿼리의 WHERE 조건:
    컬럼명  비교연산자  (서브쿼리)
    price   >           (SELECT AVG(price) FROM menus)
```

### 예제 1 — 가격이 전체 평균 이상인 메뉴

```sql
SELECT menu_name, price
FROM menus
WHERE price >= (SELECT AVG(price) FROM menus)
ORDER BY price DESC;
```

**실행 순서**:
1. `SELECT AVG(price) FROM menus` 실행 → 결과: `12500`
2. `WHERE price >= 12500` 조건으로 menus 테이블 필터링

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 한우소갈비탕 | 22000 |
| 왕갈비탕 | 18000 |
| 양념반반치킨 | 17000 |
| 후라이드치킨 | 16000 |
| ... | ... |

### 예제 2 — 가장 비싼 메뉴와 동일한 가격의 메뉴 찾기

```sql
SELECT menu_name, price
FROM menus
WHERE price = (SELECT MAX(price) FROM menus);
```

`MAX(price)`는 항상 단 하나의 값을 반환하므로 `=` 연산자를 사용할 수 있습니다. 만약 동일한 최고가 메뉴가 여러 개라면 모두 조회됩니다.

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 한우소갈비탕 | 22000 |

### 예제 3 — 평균 주문금액 이상인 주문

```sql
SELECT o.id        AS 주문번호,
       c.name      AS 고객명,
       m.menu_name AS 메뉴명,
       m.price     AS 가격
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN menus     m ON o.menu_id     = m.id
WHERE m.price >= (SELECT AVG(price) FROM menus)
ORDER BY m.price DESC;
```

JOIN과 서브쿼리를 함께 사용한 예제입니다. WHERE절의 서브쿼리는 JOIN과 완전히 독립적으로 먼저 실행됩니다.

---

## 4. WHERE절 서브쿼리 — 다중행

### 개념

서브쿼리가 **여러 행**을 반환할 때는 일반 비교 연산자(`=`, `>` 등)를 사용할 수 없습니다. 다음 연산자들을 사용해야 합니다.

| 연산자 | 의미 | 예시 |
|--------|------|------|
| `IN` | 서브쿼리 결과 중 하나와 같으면 TRUE | `WHERE id IN (1, 3, 5)` |
| `NOT IN` | 서브쿼리 결과 중 어떤 것과도 다르면 TRUE | `WHERE id NOT IN (1, 3, 5)` |
| `ANY` | 서브쿼리 결과 중 어느 하나라도 조건 만족 시 TRUE | `WHERE price > ANY (...)` |
| `ALL` | 서브쿼리 결과 전체에 대해 조건 만족 시 TRUE | `WHERE price > ALL (...)` |

### IN — 치킨 카테고리 가게의 모든 메뉴

```sql
SELECT m.menu_name, m.price, r.name AS 가게명
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.restaurant_id IN (
    SELECT id
    FROM restaurants
    WHERE category = '치킨'
)
ORDER BY r.name, m.price;
```

**실행 순서**:
1. 서브쿼리 실행: `category = '치킨'`인 가게들의 `id` 목록을 구한다 → 예: `(2, 5, 8)`
2. `WHERE m.restaurant_id IN (2, 5, 8)` 조건으로 필터링

**예상 결과**:

| menu_name | price | 가게명 |
|-----------|-------|--------|
| 후라이드치킨 | 16000 | 맛있는치킨 |
| 양념치킨 | 17000 | 맛있는치킨 |
| 반반치킨 | 17000 | 맛있는치킨 |
| 치킨강정 | 14000 | 황금치킨 |
| ... | ... | ... |

### NOT IN — 한 번도 주문받지 않은 메뉴

```sql
SELECT menu_name, price
FROM menus
WHERE id NOT IN (
    SELECT DISTINCT menu_id
    FROM orders
)
ORDER BY menu_name;
```

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 계절비빔밥 | 9000 |
| 김치볶음밥 | 8000 |
| ... | ... |

> **중요 주의사항**: `NOT IN`을 사용할 때 서브쿼리 결과에 `NULL`이 포함되어 있으면 예상과 다른 결과(빈 결과)가 나올 수 있습니다. `DISTINCT`를 사용하거나, 더 안전한 `NOT EXISTS`를 사용하는 것이 좋습니다.

**왜 NULL이 문제가 되나?**

`NOT IN (1, 2, NULL)`은 내부적으로 `id != 1 AND id != 2 AND id != NULL`로 처리됩니다. `id != NULL`은 항상 `NULL`(알 수 없음)을 반환하므로, 전체 조건이 `NULL`이 되어 어떤 행도 선택되지 않습니다.

### ANY — 어느 한 가게의 최고가 메뉴보다 비싼 것

```sql
SELECT menu_name, price
FROM menus
WHERE price > ANY (
    SELECT MAX(price)
    FROM menus
    GROUP BY restaurant_id
)
ORDER BY price;
```

`> ANY`는 "서브쿼리 결과들 중 가장 작은 값보다 크면 OK"라는 의미입니다. 가장 너그러운 조건입니다.

**직관적 이해**:
- 서브쿼리 결과: `(8000, 12000, 16000, 18000, 22000, ...)` (가게별 최고가 목록)
- `> ANY (...)` = `> MIN(...)` = 8000보다 크면 선택

### ALL — 모든 가게의 최고가 메뉴보다 비싼 것

```sql
SELECT menu_name, price
FROM menus
WHERE price > ALL (
    SELECT MAX(price)
    FROM menus
    GROUP BY restaurant_id
)
ORDER BY price;
```

`> ALL`은 "서브쿼리 결과들 중 가장 큰 값보다도 크면 OK"라는 의미입니다. 가장 엄격한 조건입니다.

**ANY vs ALL 정리**:

```
서브쿼리 결과:  [5000, 8000, 12000, 18000, 22000]

price > ANY → price > 5000  (가장 작은 값 기준)
price > ALL → price > 22000 (가장 큰 값 기준)
```

---

## 5. FROM절 서브쿼리 (인라인 뷰)

### 개념

FROM절에 서브쿼리를 사용하면 서브쿼리의 결과를 **임시 테이블**처럼 활용할 수 있습니다. "인라인 뷰(Inline View)"라고도 부릅니다.

**비유: 1차 집계표 → 2차 분석**

회사에서 부서별 매출을 분석할 때 이런 과정을 거칩니다.
1. 회계팀이 부서별 매출을 한 장으로 정리한 "1차 집계표"를 만든다
2. 경영팀이 그 집계표를 보고 "매출 1억 이상 부서"를 골라낸다

SQL에서도 동일합니다.
1. FROM절 서브쿼리로 "1차 집계표(임시 테이블)"를 만든다
2. 바깥 쿼리에서 그 임시 테이블에 추가 조건을 걸어 분석한다

### 기본 문법

```sql
SELECT *
FROM (
    SELECT ...   -- 1차 집계
    FROM ...
    GROUP BY ...
) AS 별칭명      -- ★ 반드시 별칭 필요!
WHERE 조건;
```

> **중요**: FROM절 서브쿼리에는 **반드시 `AS 별칭`** 을 붙여야 합니다. 없으면 에러가 발생합니다.

### 예제 1 — 주문수 5건 이상인 가게만 조회

```sql
SELECT *
FROM (
    SELECT restaurant_id,
           COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
) AS 가게별집계
WHERE 가게별집계.주문수 >= 5
ORDER BY 가게별집계.주문수 DESC;
```

**왜 이렇게 해야 하나?**

`HAVING`을 쓰면 안 되나요? 다음과 같이 써도 같은 결과를 얻을 수 있습니다.

```sql
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
GROUP BY restaurant_id
HAVING COUNT(*) >= 5;
```

단, FROM절 서브쿼리는 집계 결과를 다른 테이블과 JOIN하거나, 집계 결과에 또 다른 집계를 적용하는 등 더 복잡한 분석이 필요할 때 필수적으로 사용됩니다.

**예상 결과**:

| restaurant_id | 주문수 |
|---------------|--------|
| 3 | 8 |
| 7 | 7 |
| 1 | 6 |
| 5 | 6 |
| 2 | 5 |

### 예제 2 — 집계 결과에 JOIN 추가 (가게 이름 표시)

```sql
SELECT r.name      AS 가게명,
       집계.주문수
FROM (
    SELECT restaurant_id,
           COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
) AS 집계
JOIN restaurants r ON 집계.restaurant_id = r.id
WHERE 집계.주문수 >= 5
ORDER BY 집계.주문수 DESC;
```

**예상 결과**:

| 가게명 | 주문수 |
|--------|--------|
| 부산한식당 | 8 |
| 황금치킨 | 7 |
| 원조칼국수 | 6 |
| ... | ... |

### 예제 3 — 주문수 상위 3개 가게의 모든 메뉴 조회

```sql
SELECT r.name      AS 가게명,
       m.menu_name AS 메뉴명,
       m.price     AS 가격
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.restaurant_id IN (
    SELECT restaurant_id
    FROM (
        SELECT restaurant_id,
               COUNT(*) AS cnt
        FROM orders
        GROUP BY restaurant_id
        ORDER BY cnt DESC
        LIMIT 3
    ) AS 상위3가게
)
ORDER BY r.name, m.price DESC;
```

서브쿼리 안에 또 서브쿼리가 중첩된 형태입니다. 안쪽부터 읽으면 이해하기 쉽습니다.

---

## 6. SELECT절 스칼라 서브쿼리

### 개념

SELECT절에 서브쿼리를 넣으면 **각 행마다 하나의 값**을 계산하여 새로운 컬럼처럼 표시할 수 있습니다. 이를 "스칼라 서브쿼리(Scalar Subquery)"라고 부릅니다.

**스칼라(Scalar)**: 단 하나의 숫자나 문자를 의미하는 수학/프로그래밍 용어

> **핵심 조건**: 스칼라 서브쿼리는 **항상 정확히 1행 1열**만 반환해야 합니다. 2행 이상 반환되면 에러가 발생합니다.

### 예제 1 — 각 메뉴 옆에 전체 평균 표시

```sql
SELECT menu_name                                         AS 메뉴명,
       price                                             AS 가격,
       (SELECT AVG(price) FROM menus)                   AS 전체평균,
       price - (SELECT AVG(price) FROM menus)           AS 평균과의_차이,
       CASE
           WHEN price > (SELECT AVG(price) FROM menus) THEN '평균초과'
           WHEN price = (SELECT AVG(price) FROM menus) THEN '평균일치'
           ELSE '평균미만'
       END                                              AS 평균비교
FROM menus
ORDER BY price DESC;
```

**예상 결과**:

| 메뉴명 | 가격 | 전체평균 | 평균과의_차이 | 평균비교 |
|--------|------|----------|---------------|----------|
| 한우소갈비탕 | 22000 | 12500 | 9500 | 평균초과 |
| 왕갈비탕 | 18000 | 12500 | 5500 | 평균초과 |
| 양념치킨 | 17000 | 12500 | 4500 | 평균초과 |
| 순대국밥 | 8000 | 12500 | -4500 | 평균미만 |
| 떡볶이 | 5000 | 12500 | -7500 | 평균미만 |

### 예제 2 — 각 주문 옆에 해당 가게의 총 주문수 표시

```sql
SELECT o.id                             AS 주문번호,
       r.name                           AS 가게명,
       m.menu_name                      AS 메뉴명,
       (
           SELECT COUNT(*)
           FROM orders o2
           WHERE o2.restaurant_id = o.restaurant_id
       )                                AS 해당가게_총주문수
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
JOIN menus      m ON o.menu_id        = m.id
ORDER BY 해당가게_총주문수 DESC, o.id;
```

이 서브쿼리는 `o.restaurant_id`를 참조하므로 **바깥 쿼리의 현재 행에 따라** 다른 결과를 반환합니다. 이런 서브쿼리를 "상관 서브쿼리(Correlated Subquery)"라고 부릅니다.

**예상 결과**:

| 주문번호 | 가게명 | 메뉴명 | 해당가게_총주문수 |
|----------|--------|--------|-------------------|
| 5 | 부산한식당 | 된장찌개 | 8 |
| 12 | 부산한식당 | 비빔밥 | 8 |
| 3 | 황금치킨 | 양념치킨 | 7 |
| ... | ... | ... | ... |

### 예제 3 — 가게별 메뉴 수

```sql
SELECT id    AS 가게번호,
       name  AS 가게명,
       (
           SELECT COUNT(*)
           FROM menus m
           WHERE m.restaurant_id = r.id
       )     AS 메뉴수
FROM restaurants r
ORDER BY 메뉴수 DESC;
```

**예상 결과**:

| 가게번호 | 가게명 | 메뉴수 |
|----------|--------|--------|
| 1 | 부산한식당 | 5 |
| 3 | 황금치킨 | 4 |
| 2 | 원조칼국수 | 3 |
| ... | ... | ... |

### 성능 주의사항

스칼라 서브쿼리는 **행마다 한 번씩 실행**됩니다. menus 테이블에 1,000개의 행이 있다면 서브쿼리도 1,000번 실행됩니다. 데이터가 많은 경우 JOIN으로 바꾸면 성능이 크게 향상됩니다.

```sql
-- 스칼라 서브쿼리 버전 (느릴 수 있음)
SELECT r.name,
       (SELECT COUNT(*) FROM menus m WHERE m.restaurant_id = r.id) AS 메뉴수
FROM restaurants r;

-- JOIN 버전 (빠름)
SELECT r.name, COUNT(m.id) AS 메뉴수
FROM restaurants r
LEFT JOIN menus m ON r.id = m.restaurant_id
GROUP BY r.id, r.name;
```

---

## 7. EXISTS / NOT EXISTS

### 개념

`EXISTS`와 `NOT EXISTS`는 서브쿼리의 결과가 존재하는지 여부만 확인합니다.

| 연산자 | TRUE 조건 |
|--------|-----------|
| `EXISTS` | 서브쿼리 결과가 1건이라도 있으면 TRUE |
| `NOT EXISTS` | 서브쿼리 결과가 0건이면 TRUE |

```sql
WHERE EXISTS (서브쿼리)
WHERE NOT EXISTS (서브쿼리)
```

서브쿼리 안에는 관례적으로 `SELECT 1`을 씁니다. 실제 값을 가져올 필요가 없고 존재 여부만 확인하면 되기 때문입니다.

### 예제 1 — 주문이 있는 가게 (EXISTS)

```sql
SELECT r.id, r.name, r.category
FROM restaurants r
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.restaurant_id = r.id
)
ORDER BY r.name;
```

### 예제 2 — 주문이 없는 가게 (NOT EXISTS)

```sql
SELECT r.id, r.name, r.category
FROM restaurants r
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.restaurant_id = r.id
)
ORDER BY r.name;
```

**예상 결과** (주문 0건 가게 1곳):

| id | name | category |
|----|------|----------|
| 10 | 새벽분식 | 분식 |

### EXISTS vs LEFT JOIN IS NULL vs NOT IN 비교표

동일한 결과를 얻는 세 가지 방법을 비교합니다. "주문이 없는 가게 찾기"를 예로 들겠습니다.

**방법 1: NOT EXISTS**
```sql
SELECT r.name
FROM restaurants r
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.restaurant_id = r.id
);
```

**방법 2: LEFT JOIN IS NULL**
```sql
SELECT r.name
FROM restaurants r
LEFT JOIN orders o ON r.id = o.restaurant_id
WHERE o.id IS NULL;
```

**방법 3: NOT IN**
```sql
SELECT r.name
FROM restaurants r
WHERE r.id NOT IN (
    SELECT DISTINCT restaurant_id FROM orders
);
```

**비교표**:

| 방법 | NULL 안전? | 직관성 | 권장 상황 |
|------|-----------|--------|-----------|
| NOT EXISTS | 안전 | 높음 ("없는지 확인") | 대부분의 경우 권장 |
| LEFT JOIN IS NULL | 안전 | 보통 (OUTER JOIN 이해 필요) | JOIN에 익숙할 때 |
| NOT IN | 위험 (NULL 있으면 빈 결과) | 높음 (읽기 쉬움) | 서브쿼리에 NULL이 없다고 확실할 때만 |

> **실무 팁**: `NOT EXISTS`를 기본으로 사용하세요. NULL 관련 버그를 방지하고, 대부분의 DBMS에서 최적화가 잘 됩니다.

---

## 8. UNION / UNION ALL

### 개념

두 개 이상의 SELECT 결과를 세로로 합칩니다.

| 연산자 | 중복 처리 |
|--------|-----------|
| `UNION` | 중복 행 제거 (DISTINCT 적용) |
| `UNION ALL` | 중복 행 포함 (모두 표시) |

### 기본 문법

```sql
SELECT 컬럼1, 컬럼2
FROM 테이블A
WHERE 조건

UNION [ALL]

SELECT 컬럼1, 컬럼2
FROM 테이블B
WHERE 조건

ORDER BY 컬럼1;  -- ORDER BY는 맨 마지막에 한 번만
```

### 필수 규칙

1. **컬럼 수가 같아야 한다**  
   첫 번째 SELECT에 컬럼이 3개면, 두 번째 SELECT도 3개여야 합니다.

2. **대응하는 컬럼의 데이터 타입이 호환되어야 한다**  
   첫 번째 SELECT의 2번째 컬럼이 INT라면, 두 번째 SELECT의 2번째 컬럼도 INT나 호환 가능한 타입이어야 합니다.

3. **결과의 컬럼 이름은 첫 번째 SELECT를 따른다**  
   두 번째 SELECT의 컬럼 이름은 무시됩니다.

4. **ORDER BY는 마지막에 한 번만**  
   각 SELECT 문에 ORDER BY를 붙이면 에러가 발생합니다.

### 예제 1 — 한식 가게와 치킨 가게 합치기

```sql
SELECT name, '한식' AS 카테고리구분
FROM restaurants
WHERE category = '한식'

UNION

SELECT name, '치킨'
FROM restaurants
WHERE category = '치킨'

ORDER BY 카테고리구분, name;
```

**예상 결과**:

| name | 카테고리구분 |
|------|-------------|
| 부산한식당 | 한식 |
| 원조해장국 | 한식 |
| 황금치킨 | 치킨 |
| 맛있는치킨 | 치킨 |

### 예제 2 — UNION vs UNION ALL 차이 직접 확인

```sql
-- UNION: 중복 제거
SELECT name FROM restaurants WHERE category = '한식'
UNION
SELECT name FROM restaurants WHERE category = '한식';
-- 결과: 한식 가게 이름이 한 번씩만 표시됨

-- UNION ALL: 중복 포함
SELECT name FROM restaurants WHERE category = '한식'
UNION ALL
SELECT name FROM restaurants WHERE category = '한식';
-- 결과: 한식 가게 이름이 두 번씩 표시됨
```

### 예제 3 — 고가 메뉴(20,000원 이상)와 저가 메뉴(5,000원 이하) 목록

```sql
SELECT menu_name, price, '고가메뉴' AS 구분
FROM menus
WHERE price >= 20000

UNION ALL

SELECT menu_name, price, '저가메뉴'
FROM menus
WHERE price <= 5000

ORDER BY price DESC;
```

**예상 결과**:

| menu_name | price | 구분 |
|-----------|-------|------|
| 한우소갈비탕 | 22000 | 고가메뉴 |
| 왕갈비탕 | 18000 | 고가메뉴 |
| 순대 | 4000 | 저가메뉴 |
| 떡볶이 | 5000 | 저가메뉴 |

> **UNION vs UNION ALL 선택 기준**  
> - 두 결과 집합 간에 중복이 없다고 확신하면 → `UNION ALL` (더 빠름, 중복 검사 생략)  
> - 중복 제거가 필요하면 → `UNION`  
> - 실무에서는 성능 이유로 `UNION ALL`을 더 자주 사용하는 경향이 있습니다.

---

## 9. 서브쿼리 vs JOIN 선택 기준

서브쿼리와 JOIN은 종종 같은 결과를 가져옵니다. 어떤 것을 선택해야 할까요?

### 같은 결과, 다른 방법 비교

**문제**: "주문이 있는 가게의 이름을 조회하라"

**서브쿼리 버전**:
```sql
SELECT name
FROM restaurants
WHERE id IN (SELECT DISTINCT restaurant_id FROM orders);
```

**JOIN 버전**:
```sql
SELECT DISTINCT r.name
FROM restaurants r
JOIN orders o ON r.id = o.restaurant_id;
```

### 선택 기준표

| 상황 | 권장 방법 | 이유 |
|------|-----------|------|
| 단순 존재 여부 확인 | EXISTS/NOT EXISTS | 빠르고 명확 |
| 합쳐진 결과가 필요 없을 때 | 서브쿼리 | 가독성 좋음 |
| 여러 테이블의 컬럼을 함께 SELECT할 때 | JOIN | 서브쿼리로는 불가능하거나 복잡 |
| 집계 결과를 다시 분석할 때 | FROM절 서브쿼리 또는 CTE | 논리 구조가 명확 |
| 성능이 중요할 때 | EXPLAIN으로 직접 비교 후 결정 | 상황마다 다름 |

### 성능 측면

**이론**:
- 과거에는 서브쿼리가 JOIN보다 느린 경우가 많았습니다.
- MySQL 8.0+에서는 옵티마이저가 서브쿼리를 자동으로 JOIN으로 변환하는 경우가 많아졌습니다.

**실전 조언**:
- 먼저 읽기 쉬운 방법으로 작성한다.
- 성능 이슈가 발생하면 `EXPLAIN`으로 실행 계획을 확인하고 최적화한다. (Day 8에서 자세히 다룸)

### 가독성 측면

서브쿼리가 유리한 경우:
- "평균보다 큰" 처럼 비교 기준이 되는 단일값 계산
- 조건 로직이 여러 단계로 나뉘는 경우
- 중간 결과에 이름을 붙이고 싶은 경우 (FROM절 서브쿼리)

JOIN이 유리한 경우:
- 여러 테이블의 컬럼을 한꺼번에 SELECT 해야 할 때
- 팀 내 JOIN에 더 익숙한 경우

---

## 10. 서브쿼리 작성 팁

### 팁 1 — 안에서 밖으로 읽기

서브쿼리는 실행 순서(안 → 밖)와 쓰는 순서(밖 → 안)가 반대입니다. 처음에는 헷갈릴 수 있으니 **읽을 때는 안에서 밖으로** 읽으세요.

```sql
SELECT menu_name, price          -- 3. 결과 컬럼 선택
FROM menus                       -- 2. menus 테이블에서
WHERE price > (                  -- 1. price가 다음 값보다 크면:
    SELECT AVG(price)            --    전체 평균 계산
    FROM menus
);
```

### 팁 2 — 서브쿼리를 먼저 단독으로 테스트하기

복잡한 서브쿼리를 작성할 때, 서브쿼리 부분만 먼저 실행해서 원하는 결과가 나오는지 확인하세요.

```sql
-- Step 1: 서브쿼리만 먼저 테스트
SELECT AVG(price) FROM menus;
-- 결과: 12500 ← OK

-- Step 2: 바깥 쿼리에 넣기
SELECT menu_name, price
FROM menus
WHERE price > (SELECT AVG(price) FROM menus);
```

### 팁 3 — FROM절 서브쿼리에는 반드시 별칭

```sql
-- 에러: 별칭 없음
SELECT * FROM (SELECT id FROM menus WHERE price > 10000);

-- 정상: 별칭 있음
SELECT * FROM (SELECT id FROM menus WHERE price > 10000) AS 고가메뉴;
```

### 팁 4 — 단일행 서브쿼리에 단일값 반환 확인

`=`, `>` 같은 단일값 비교 연산자를 쓸 때, 서브쿼리가 정말 1행만 반환하는지 확인하세요. 여러 행이 반환되면 에러가 발생합니다.

```sql
-- 위험: MAX 대신 조건에 따라 여러 값이 나올 수 있는 서브쿼리
-- WHERE price = (SELECT price FROM menus WHERE restaurant_id = 1);
-- → restaurant_id = 1의 메뉴가 여러 개면 에러!

-- 안전: MAX로 명확히 단일값 보장
WHERE price = (SELECT MAX(price) FROM menus WHERE restaurant_id = 1);
```

### 팁 5 — NOT IN과 NULL 조심

```sql
-- NULL이 포함된 경우 빈 결과 반환 위험
WHERE id NOT IN (SELECT menu_id FROM orders);

-- 안전한 버전 (NULL 제외 또는 NOT EXISTS 사용)
WHERE id NOT IN (SELECT menu_id FROM orders WHERE menu_id IS NOT NULL);
-- 또는
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.menu_id = m.id);
```

---

## 11. 자주 발생하는 에러 3가지

### 에러 1 — 단일행 서브쿼리가 여러 행 반환

**에러 메시지**:
```
ERROR 1242 (21000): Subquery returns more than 1 row
```

**원인**: `=`, `>` 같은 단일값 비교 연산자를 쓰는데 서브쿼리가 여러 행을 반환

**잘못된 코드**:
```sql
SELECT menu_name, price
FROM menus
WHERE restaurant_id = (SELECT id FROM restaurants WHERE category = '치킨');
-- 치킨 카테고리 가게가 여러 개이면 에러!
```

**해결 방법**:
```sql
-- IN으로 변경 (여러 값에 대응)
SELECT menu_name, price
FROM menus
WHERE restaurant_id IN (SELECT id FROM restaurants WHERE category = '치킨');
```

### 에러 2 — FROM절 서브쿼리에 별칭 누락

**에러 메시지**:
```
ERROR 1248 (42000): Every derived table must have its own alias
```

**원인**: FROM절의 서브쿼리에 `AS 별칭`을 붙이지 않음

**잘못된 코드**:
```sql
SELECT * FROM (
    SELECT restaurant_id, COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
);  -- 별칭 없음!
```

**해결 방법**:
```sql
SELECT * FROM (
    SELECT restaurant_id, COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
) AS 가게별집계;  -- AS 별칭 추가
```

### 에러 3 — 스칼라 서브쿼리에서 여러 행 반환

**에러 메시지**:
```
ERROR 1242 (21000): Subquery returns more than 1 row
```

**원인**: SELECT절에 사용한 서브쿼리가 여러 행을 반환

**잘못된 코드**:
```sql
SELECT menu_name,
       (SELECT price FROM menus WHERE restaurant_id = 1)  -- 여러 메뉴가 있으면 에러!
FROM menus;
```

**해결 방법**:
```sql
-- 집계함수로 단일값 보장
SELECT menu_name,
       (SELECT MAX(price) FROM menus WHERE restaurant_id = 1) AS 가게1최고가
FROM menus;

-- 또는 JOIN으로 바꾸기
SELECT m.menu_name, r1.max_price AS 가게1최고가
FROM menus m
CROSS JOIN (SELECT MAX(price) AS max_price FROM menus WHERE restaurant_id = 1) r1;
```

---

## 12. 오늘 배운 것 정리

### 핵심 키워드 정리

| 키워드 | 의미 |
|--------|------|
| **서브쿼리** | 쿼리 안의 쿼리. 괄호로 감싸며 안쪽이 먼저 실행된다 |
| **단일행 서브쿼리** | 결과가 1행 1열. `=`, `>` 등 일반 비교 연산자 사용 |
| **다중행 서브쿼리** | 결과가 여러 행. `IN`, `NOT IN`, `ANY`, `ALL` 사용 |
| **인라인 뷰** | FROM절 서브쿼리. 임시 테이블처럼 사용. 반드시 별칭 필요 |
| **스칼라 서브쿼리** | SELECT절 서브쿼리. 각 행마다 단일값 반환 |
| **EXISTS** | 서브쿼리 결과가 1건 이상 존재하면 TRUE |
| **NOT EXISTS** | 서브쿼리 결과가 0건이면 TRUE. NULL에 안전 |
| **UNION** | 두 SELECT 결과 합치기 (중복 제거) |
| **UNION ALL** | 두 SELECT 결과 합치기 (중복 포함) |

### 위치별 서브쿼리 요약

```
SELECT  (스칼라 서브쿼리)    -- 각 행마다 단일값 반환
FROM    (인라인 뷰)          -- 임시 테이블, 반드시 AS 별칭
WHERE   (조건 서브쿼리)      -- 단일행: = > <, 다중행: IN ANY ALL EXISTS
```

### UNION 규칙 요약

```
첫번째 SELECT
UNION [ALL]
두번째 SELECT
ORDER BY ...    ← 마지막에 한 번만

규칙:
1) 컬럼 수 동일
2) 데이터 타입 호환
3) 컬럼명은 첫 번째 SELECT 기준
```

---

## 13. Day 8 예고

오늘 서브쿼리를 배우면서 이런 생각이 들지 않았나요?

> "쿼리가 복잡해지니까 확실히 느려진 것 같아요..."  
> "같은 서브쿼리를 매번 쓰는 게 번거로워요..."  
> "트랜잭션 처리 중간에 에러가 나면 어떡해요?"

**Day 8 — 성능과 안전: 인덱스, 뷰, 트랜잭션**에서 이 세 가지 문제를 해결합니다.

- **인덱스(Index)**: 책의 목차처럼 쿼리 속도를 빠르게 — `EXPLAIN`으로 전/후 비교
- **뷰(VIEW)**: 복잡한 쿼리를 즐겨찾기처럼 저장 — 재사용 가능
- **트랜잭션(Transaction)**: 계좌이체처럼 "전부 성공하거나 전부 취소하거나" — ACID, COMMIT, ROLLBACK

---

*한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점*
