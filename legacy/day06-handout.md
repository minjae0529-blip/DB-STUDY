# Day 6 핸드아웃 — JOIN: 흩어진 퍼즐 맞추기

> 한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점

---

## 목차

1. [오늘의 핵심 질문](#1-오늘의-핵심-질문)
2. [왜 테이블을 나누는가](#2-왜-테이블을-나누는가)
3. [JOIN이란 무엇인가](#3-join이란-무엇인가)
4. [INNER JOIN — 양쪽 모두 매칭되는 것만](#4-inner-join--양쪽-모두-매칭되는-것만)
5. [LEFT JOIN — 출석부, 결석자도 명단에](#5-left-join--출석부-결석자도-명단에)
6. [RIGHT JOIN — 방향만 반대](#6-right-join--방향만-반대)
7. [CROSS JOIN — 모든 조합 만들기](#7-cross-join--모든-조합-만들기)
8. [SELF JOIN — 같은 테이블을 두 번 참조](#8-self-join--같은-테이블을-두-번-참조)
9. [JOIN + GROUP BY 황금 조합](#9-join--group-by-황금-조합)
10. [JOIN 작성 순서 가이드](#10-join-작성-순서-가이드)
11. [자주 발생하는 에러 4가지](#11-자주-발생하는-에러-4가지)
12. [INNER JOIN vs LEFT JOIN 선택 기준](#12-inner-join-vs-left-join-선택-기준)
13. [오늘 배운 것 정리 — JOIN 종류 요약표](#13-오늘-배운-것-정리--join-종류-요약표)
14. [Day 7 예고](#14-day-7-예고)

---

## 1. 오늘의 핵심 질문

Day 5에서 배운 GROUP BY를 복습해 봅시다. 우리는 주문 테이블을 가게별로 묶어 총 매출을 계산했습니다.

```sql
SELECT restaurant_id, SUM(total_price) AS 총매출
FROM orders
GROUP BY restaurant_id
ORDER BY 총매출 DESC;
```

결과는 이렇게 나왔습니다.

| restaurant_id | 총매출 |
|:---:|---:|
| 3 | 245000 |
| 1 | 198000 |
| 7 | 176000 |
| 5 | 154000 |

이 결과를 보고 드는 생각이 있지 않나요?

> **"3번 가게가 어디야? 가게 이름이 뭐야? 숫자만으론 모르겠는데..."**

restaurant_id 컬럼에는 숫자만 있습니다. 가게 이름은 `restaurants` 테이블에 있고, 매출 데이터는 `orders` 테이블에 있습니다. 두 테이블을 연결해야 비로소 의미 있는 정보가 됩니다.

바로 이것이 오늘 배울 **JOIN**이 필요한 이유입니다.

---

## 2. 왜 테이블을 나누는가

JOIN을 배우기 전에, 왜 처음부터 테이블을 나눠서 저장했는지 이해해야 합니다.

### 2-1. 하나의 거대한 테이블로 만들면 어떨까?

주문 정보를 테이블 하나에 모두 담으면 이렇게 됩니다.

| 주문ID | 고객이름 | 고객전화 | 고객주소 | 가게이름 | 가게카테고리 | 가게주소 | 메뉴이름 | 가격 |
|:---:|---|---|---|---|---|---|---|---:|
| 1 | 김민준 | 010-1234-5678 | 부산 해운대구 | 부산치킨 | 치킨 | 부산 수영구 | 후라이드치킨 | 18000 |
| 2 | 김민준 | 010-1234-5678 | 부산 해운대구 | 부산치킨 | 치킨 | 부산 수영구 | 양념치킨 | 19000 |
| 3 | 이서연 | 010-9876-5432 | 부산 남구 | 부산치킨 | 치킨 | 부산 수영구 | 후라이드치킨 | 18000 |

이 구조에는 심각한 문제가 세 가지 있습니다.

**문제 1: 데이터 중복 (중복 저장)**
- 김민준 고객이 100번 주문하면 고객의 이름, 전화번호, 주소가 100번 반복 저장됩니다.
- 부산치킨이 가게 주소를 이전하면 이 고객의 모든 주문 행을 일일이 수정해야 합니다.

**문제 2: 수정의 어려움**
- 부산치킨이 '부산치킨&피자'로 이름을 바꿨다면?
- 이 가게와 연결된 수백, 수천 행을 모두 찾아서 수정해야 합니다.
- 하나라도 빠뜨리면 데이터 불일치가 발생합니다.

**문제 3: 저장 공간 낭비**
- 같은 정보가 계속 반복되면 저장 공간이 낭비됩니다.

### 2-2. 테이블을 나누는 것이 정답이다

올바른 설계는 정보를 **주제별로 분리**해서 저장하는 것입니다.

```
restaurants 테이블: 가게 정보만 (id, name, category, address ...)
customers   테이블: 고객 정보만 (id, name, phone, address ...)
menus       테이블: 메뉴 정보만 (id, restaurant_id, menu_name, price ...)
orders      테이블: 주문 행위만 (id, customer_id, restaurant_id, menu_id ...)
```

orders 테이블은 직접 이름을 저장하는 대신 **번호(ID)만 저장**합니다. 가게 이름이 바뀌어도 orders 테이블은 수정할 필요가 없습니다. restaurants 테이블의 name 컬럼 하나만 수정하면 됩니다.

이렇게 분리된 테이블을 다시 연결해서 보는 방법이 바로 JOIN입니다.

---

## 3. JOIN이란 무엇인가

### 비유 1: 서류철 합치기

인사팀에 두 개의 서류철이 있다고 상상해 보세요.
- **서류철 A**: 사원번호, 사원이름, 부서코드
- **서류철 B**: 부서코드, 부서이름, 부서위치

두 서류철을 '부서코드'를 기준으로 합치면 사원이름과 부서이름을 함께 볼 수 있습니다. 이것이 JOIN입니다.

### 비유 2: 소개팅 매칭

소개팅 앱을 생각해 보세요.
- **남성 프로필 목록**과 **여성 프로필 목록**이 있습니다.
- 두 프로필의 관심사나 조건이 **일치(ON)**하는 쌍을 매칭합니다.
- INNER JOIN은 양쪽이 모두 매칭되는 쌍만 보여줍니다.
- LEFT JOIN은 남성 목록은 전부 보여주되, 매칭 안 되는 경우 여성 쪽은 빈칸으로 표시합니다.

### JOIN의 동작 원리

JOIN은 두 테이블에서 **ON 뒤의 조건**이 일치하는 행끼리 옆으로 붙여 새 가상의 결과 테이블을 만듭니다.

```
orders 테이블                restaurants 테이블
+----+---------------+       +----+----------+----------+
| id | restaurant_id |       | id | name     | category |
+----+---------------+       +----+----------+----------+
|  1 |             3 |       |  1 | 명동칼국수 | 한식     |
|  2 |             1 |       |  2 | 해운대회집 | 한식     |
|  3 |             3 |       |  3 | 부산치킨  | 치킨     |
+----+---------------+       +----+----------+----------+

ON o.restaurant_id = r.id 로 JOIN하면:

+----+---------------+----------+----------+
| id | restaurant_id | name     | category |
+----+---------------+----------+----------+
|  1 |             3 | 부산치킨  | 치킨     |
|  2 |             1 | 명동칼국수 | 한식     |
|  3 |             3 | 부산치킨  | 치킨     |
+----+---------------+----------+----------+
```

---

## 4. INNER JOIN — 양쪽 모두 매칭되는 것만

### 4-1. 문법 구조

```sql
SELECT  컬럼1, 컬럼2, ...
FROM    테이블A  AS 별칭A
    INNER JOIN 테이블B  AS 별칭B
        ON 별칭A.공통키컬럼 = 별칭B.공통키컬럼
WHERE   조건 (선택)
ORDER BY 정렬 (선택);
```

각 키워드의 역할:

| 키워드 | 역할 |
|--------|------|
| `FROM 테이블A` | 기준이 되는 첫 번째 테이블 |
| `INNER JOIN 테이블B` | 연결할 두 번째 테이블 |
| `ON A.컬럼 = B.컬럼` | 어떤 컬럼을 기준으로 연결할지 지정 |
| `WHERE` | JOIN 결과에 추가 필터 적용 |

### 4-2. 2테이블 예시: orders ↔ restaurants

```sql
SELECT
    o.id          AS 주문번호,
    r.name        AS 가게이름,
    r.category    AS 카테고리,
    o.total_price AS 주문금액
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
ORDER BY o.id
LIMIT 5;
```

**실행 결과:**

| 주문번호 | 가게이름 | 카테고리 | 주문금액 |
|:---:|---|---|---:|
| 1 | 부산치킨 | 치킨 | 18000 |
| 2 | 명동칼국수 | 한식 | 12000 |
| 3 | 부산치킨 | 치킨 | 37000 |
| 4 | 해운대피자 | 피자 | 23000 |
| 5 | 서면분식 | 분식 | 8500 |

숫자 restaurant_id 대신 가게 이름이 나타납니다. 이것이 JOIN의 효과입니다.

### 4-3. 다른 2테이블 예시: orders ↔ customers

```sql
SELECT
    o.id          AS 주문번호,
    c.name        AS 고객이름,
    c.phone       AS 연락처,
    o.total_price AS 주문금액,
    o.status      AS 배달상태
FROM orders AS o
    INNER JOIN customers AS c ON o.customer_id = c.id
ORDER BY o.id
LIMIT 5;
```

**실행 결과:**

| 주문번호 | 고객이름 | 연락처 | 주문금액 | 배달상태 |
|:---:|---|---|---:|---|
| 1 | 김민준 | 010-1234-5678 | 18000 | 배달완료 |
| 2 | 이서연 | 010-9876-5432 | 12000 | 배달완료 |
| 3 | 김민준 | 010-1234-5678 | 37000 | 배달완료 |
| 4 | 박지훈 | 010-5555-1234 | 23000 | 배달완료 |
| 5 | 최유진 | 010-7777-8888 | 8500 | 배달완료 |

### 4-4. 3테이블 JOIN

세 번째 테이블을 추가할 때는 INNER JOIN을 한 번 더 쓰면 됩니다.

```sql
SELECT
    o.id          AS 주문번호,
    c.name        AS 고객이름,
    r.name        AS 가게이름,
    o.total_price AS 주문금액,
    o.order_date  AS 주문일시
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
    INNER JOIN customers   AS c ON o.customer_id   = c.id
ORDER BY o.order_date DESC
LIMIT 5;
```

**실행 결과:**

| 주문번호 | 고객이름 | 가게이름 | 주문금액 | 주문일시 |
|:---:|---|---|---:|---|
| 48 | 이서연 | 부산치킨 | 37000 | 2024-03-15 19:22:00 |
| 47 | 정하은 | 명동칼국수 | 12000 | 2024-03-14 12:05:00 |
| 46 | 김민준 | 해운대피자 | 23000 | 2024-03-13 18:44:00 |

이렇게 하면 주문번호, 고객이름, 가게이름을 한 화면에서 볼 수 있습니다.

### 4-5. 별칭(Alias)이 왜 필수인가

여러 테이블을 JOIN하면 같은 이름의 컬럼이 생깁니다. 예를 들어 `id`는 orders에도 있고, restaurants에도 있고, customers에도 있습니다.

```sql
-- 아래 쿼리는 에러가 납니다!
SELECT id, name FROM orders INNER JOIN customers ON orders.customer_id = customers.id;
-- ERROR: Column 'id' in field list is ambiguous
-- "id가 어느 테이블 것인지 모르겠다"는 에러입니다.
```

이를 해결하는 두 가지 방법:

**방법 1: 테이블명.컬럼명 으로 명시**
```sql
SELECT orders.id, customers.name FROM orders INNER JOIN customers ON ...
-- 테이블명이 길면 쿼리가 너무 길어집니다.
```

**방법 2 (권장): 별칭 사용**
```sql
SELECT o.id, c.name FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.id
-- o, c처럼 짧은 별칭을 쓰면 깔끔합니다.
```

**별칭을 사용하는 이유 정리:**
- 컬럼명 충돌 방지 (ambiguous column 에러 방지)
- 쿼리를 짧고 읽기 좋게 만들기
- 여러 테이블이 JOIN될수록 별칭이 없으면 쿼리가 엄청 길어짐

---

## 5. LEFT JOIN — 출석부, 결석자도 명단에

### 5-1. INNER JOIN vs LEFT JOIN 비교

```
[ INNER JOIN ]
customers 테이블     orders 테이블       결과
1번 김민준 ─────────── 1번 주문       →  김민준 + 주문1
2번 이서연 ─────────── 2번 주문       →  이서연 + 주문2
3번 박지훈 ─────────── 3번 주문       →  박지훈 + 주문3
9번 최태양 ─(없음)─                   →  제외! (결과에 안 나옴)
10번 강나래 ─(없음)─                  →  제외! (결과에 안 나옴)

[ LEFT JOIN ]
customers 테이블     orders 테이블       결과
1번 김민준 ─────────── 1번 주문       →  김민준 + 주문1
2번 이서연 ─────────── 2번 주문       →  이서연 + 주문2
3번 박지훈 ─────────── 3번 주문       →  박지훈 + 주문3
9번 최태양 ─(없음)─                   →  최태양 + NULL  ← 포함됨!
10번 강나래 ─(없음)─                  →  강나래 + NULL  ← 포함됨!
```

**비유:** 학교 출석부에는 결석한 학생 이름도 남아 있어야 합니다. 그래야 누가 결석했는지 알 수 있죠. INNER JOIN은 출석한 학생만 올리는 방식이고, LEFT JOIN은 전체 명단을 유지하면서 결석자는 점수 칸을 비워두는 방식입니다.

### 5-2. LEFT JOIN 기본 문법

```sql
SELECT  컬럼들
FROM    테이블A  AS 별칭A         -- '출석부' 역할 (기준 테이블, 모두 포함)
    LEFT JOIN 테이블B  AS 별칭B
        ON 별칭A.공통키 = 별칭B.공통키
```

- FROM 뒤의 테이블(왼쪽)은 **모두** 결과에 포함됩니다.
- 오른쪽 테이블에 일치하는 행이 없으면 해당 컬럼이 **NULL**로 채워집니다.

### 5-3. 예시: 주문 0건 고객도 포함해서 조회

```sql
SELECT
    c.id          AS 고객번호,
    c.name        AS 고객이름,
    o.id          AS 주문번호,
    o.total_price AS 주문금액
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
ORDER BY c.id;
```

**실행 결과 (일부):**

| 고객번호 | 고객이름 | 주문번호 | 주문금액 |
|:---:|---|:---:|---:|
| 1 | 김민준 | 1 | 18000 |
| 1 | 김민준 | 3 | 37000 |
| 2 | 이서연 | 2 | 12000 |
| ... | ... | ... | ... |
| **9** | **최태양** | **NULL** | **NULL** |
| **10** | **강나래** | **NULL** | **NULL** |

9번, 10번 고객의 주문번호와 주문금액이 NULL로 표시됩니다. 이 고객들은 아직 주문을 한 번도 하지 않은 고객입니다.

### 5-4. 주문 0건 고객만 필터링 — WHERE o.id IS NULL

```sql
SELECT
    c.id    AS 고객번호,
    c.name  AS 고객이름,
    c.phone AS 연락처,
    c.email AS 이메일
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
WHERE o.id IS NULL    -- 핵심: 오른쪽이 NULL인 행만 = 주문 없는 고객
ORDER BY c.id;
```

**실행 결과:**

| 고객번호 | 고객이름 | 연락처 | 이메일 |
|:---:|---|---|---|
| 9 | 최태양 | 010-3333-4444 | taesun@email.com |
| 10 | 강나래 | 010-5678-9012 | nara@email.com |

**비즈니스 활용:** 이 두 고객에게 "첫 주문 10% 할인 쿠폰"을 보내면 신규 매출을 만들 수 있습니다. LEFT JOIN + WHERE IS NULL은 "아직 참여하지 않은 대상"을 찾는 강력한 패턴입니다.

### 5-5. 주문 0건인 가게 찾기

같은 방식으로 주문이 없는 가게도 찾을 수 있습니다.

```sql
SELECT
    r.id       AS 가게번호,
    r.name     AS 가게이름,
    r.category AS 카테고리
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
WHERE o.id IS NULL
ORDER BY r.id;
```

**실행 결과:**

| 가게번호 | 가게이름 | 카테고리 |
|:---:|---|---|
| 10 | 부산돈까스 | 일식 |

10번 가게는 한 번도 주문을 받지 못한 가게입니다. 마케팅 지원이 필요하겠네요.

---

## 6. RIGHT JOIN — 방향만 반대

RIGHT JOIN은 LEFT JOIN과 방향만 다릅니다.

- LEFT JOIN: **왼쪽** 테이블 전부 + 오른쪽 매칭
- RIGHT JOIN: **오른쪽** 테이블 전부 + 왼쪽 매칭

```sql
-- RIGHT JOIN 예시: 모든 가게 + 주문 건수 (없으면 0)
SELECT
    r.name               AS 가게이름,
    IFNULL(COUNT(o.id), 0) AS 주문건수
FROM orders AS o
    RIGHT JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name
ORDER BY 주문건수 DESC;
```

**실무 팁:** RIGHT JOIN은 FROM과 JOIN의 테이블 순서를 바꿔서 LEFT JOIN으로 표현할 수 있습니다. 대부분의 현업 개발자들은 가독성을 위해 **LEFT JOIN만 사용**하고 RIGHT JOIN은 거의 쓰지 않습니다.

```sql
-- 위와 동일한 결과를 LEFT JOIN으로 표현:
SELECT
    r.name               AS 가게이름,
    IFNULL(COUNT(o.id), 0) AS 주문건수
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
GROUP BY r.id, r.name
ORDER BY 주문건수 DESC;
```

---

## 7. CROSS JOIN — 모든 조합 만들기

CROSS JOIN은 ON 조건 없이 두 테이블의 모든 행을 서로 조합합니다. A 테이블에 행이 N개, B 테이블에 행이 M개 있으면 결과는 N × M개 행이 됩니다.

```sql
SELECT
    c.name      AS 고객이름,
    m.menu_name AS 메뉴이름
FROM customers AS c
    CROSS JOIN menus AS m
LIMIT 10;
```

고객이 10명이고 메뉴가 30개이면 결과는 300행입니다.

**언제 쓰나?** 실무에서는 특수한 경우에만 사용합니다.
- 요일 × 시간대 조합 테이블 생성
- 상품 × 색상 조합 전체 목록 생성
- 테스트 데이터 대량 생성

실수로 ON 조건을 빠뜨려도 CROSS JOIN처럼 동작하므로, JOIN을 쓸 때는 항상 ON 절을 확인하세요.

---

## 8. SELF JOIN — 같은 테이블을 두 번 참조

SELF JOIN은 하나의 테이블을 마치 두 개인 것처럼 별칭을 달리해서 JOIN하는 방법입니다.

**예시: 같은 카테고리의 가게끼리 쌍 만들기**

```sql
SELECT
    r1.name     AS 가게A,
    r2.name     AS 가게B,
    r1.category AS 공통카테고리
FROM restaurants AS r1
    INNER JOIN restaurants AS r2
        ON  r1.category = r2.category   -- 같은 카테고리
        AND r1.id < r2.id               -- 중복 쌍 방지 (A-B와 B-A를 동시에 안 뽑기)
ORDER BY r1.category, r1.name;
```

**실행 결과 (예시):**

| 가게A | 가게B | 공통카테고리 |
|---|---|---|
| 부산치킨 | 남포동치킨 | 치킨 |
| 명동칼국수 | 해운대설렁탕 | 한식 |
| 광안리피자 | 해운대피자 | 피자 |

`r1.id < r2.id` 조건이 없으면 (부산치킨, 남포동치킨)과 (남포동치킨, 부산치킨) 두 쌍이 모두 나옵니다. `<` 조건으로 한 방향만 뽑습니다.

---

## 9. JOIN + GROUP BY 황금 조합

이 섹션이 오늘 수업의 클라이맥스입니다. JOIN으로 테이블을 연결하고, GROUP BY로 묶으면 가게 이름별, 고객 이름별 통계를 낼 수 있습니다.

### 9-1. 단계별 쿼리 작성법

복잡한 쿼리를 처음부터 완성형으로 쓰려 하지 마세요. 다음 순서로 단계적으로 작성하세요.

**Step 1: 먼저 JOIN만 작성해서 연결이 잘 되는지 확인**
```sql
SELECT o.id, r.name, o.total_price
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
LIMIT 5;
```

**Step 2: GROUP BY 추가 (집계 기준 컬럼 결정)**
```sql
SELECT r.name, SUM(o.total_price)
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name;
```

**Step 3: SELECT 컬럼을 보기 좋게 다듬고 별칭 추가**
```sql
SELECT
    r.name             AS 가게이름,
    COUNT(o.id)        AS 주문건수,
    SUM(o.total_price) AS 총매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name;
```

**Step 4: HAVING, ORDER BY, LIMIT 추가**
```sql
SELECT
    r.name             AS 가게이름,
    COUNT(o.id)        AS 주문건수,
    SUM(o.total_price) AS 총매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name
HAVING SUM(o.total_price) > 100000   -- 총매출 10만원 초과인 가게만
ORDER BY 총매출 DESC;
```

### 9-2. 가게 이름별 매출 랭킹 — 전체 과정

드디어 Part 0의 불편함을 해결하는 완성 쿼리입니다.

```sql
SELECT
    r.name        AS 가게이름,
    r.category    AS 카테고리,
    COUNT(o.id)   AS 주문건수,
    SUM(o.total_price) AS 총매출,
    ROUND(AVG(o.total_price), 0) AS 평균주문금액
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name, r.category
ORDER BY 총매출 DESC;
```

**실행 결과 (예시):**

| 가게이름 | 카테고리 | 주문건수 | 총매출 | 평균주문금액 |
|---|---|:---:|---:|---:|
| 부산치킨 | 치킨 | 12 | 245000 | 20417 |
| 명동칼국수 | 한식 | 9 | 198000 | 22000 |
| 해운대피자 | 피자 | 8 | 176000 | 22000 |
| 서면분식 | 분식 | 11 | 154000 | 14000 |

숫자 ID 대신 가게 이름이 나옵니다. 이것이 JOIN + GROUP BY의 힘입니다.

### 9-3. 카테고리별 평균 주문금액

```sql
SELECT
    r.category    AS 카테고리,
    COUNT(o.id)   AS 주문건수,
    ROUND(AVG(o.total_price), 0) AS 평균주문금액,
    SUM(o.total_price) AS 카테고리총매출
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.category
ORDER BY 평균주문금액 DESC;
```

### 9-4. 인기 메뉴 TOP 5 (주문 횟수 기준)

```sql
SELECT
    m.menu_name   AS 메뉴이름,
    r.name        AS 가게이름,
    COUNT(o.id)   AS 주문횟수,
    SUM(o.total_price) AS 총매출
FROM orders AS o
    INNER JOIN menus       AS m ON o.menu_id       = m.id
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY m.id, m.menu_name, r.name
ORDER BY 주문횟수 DESC
LIMIT 5;
```

### 9-5. SELECT 절 작성 규칙 — GROUP BY와 함께 쓸 때

JOIN + GROUP BY를 함께 쓸 때 SELECT 절에는 다음 중 하나만 올 수 있습니다.

1. **GROUP BY에 포함된 컬럼** (r.id, r.name, r.category 등)
2. **집계함수** (COUNT, SUM, AVG, MAX, MIN)

잘못된 예시:
```sql
-- 에러! o.total_price는 GROUP BY에도 없고 집계함수도 아님
SELECT r.name, o.total_price, SUM(o.total_price)
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.name;
```

---

## 10. JOIN 작성 순서 가이드

"어디서부터 시작해야 할지 모르겠어요"라는 경우 이 순서를 따르세요.

**Step 1. 원하는 결과의 컬럼을 먼저 나열하기**

예: 가게이름, 고객이름, 주문금액, 메뉴명을 보고 싶다.

**Step 2. 그 컬럼들이 어느 테이블에 있는지 확인**

| 원하는 컬럼 | 있는 테이블 |
|---|---|
| 가게이름 (name) | restaurants |
| 고객이름 (name) | customers |
| 주문금액 (total_price) | orders |
| 메뉴명 (menu_name) | menus |

**Step 3. orders를 중심(FROM)으로, 나머지를 JOIN으로 연결**

orders 테이블에는 restaurant_id, customer_id, menu_id가 모두 있습니다. orders가 허브(중심) 역할을 합니다.

```sql
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
    INNER JOIN customers   AS c ON o.customer_id   = c.id
    INNER JOIN menus       AS m ON o.menu_id        = m.id
```

**Step 4. SELECT 절에 원하는 컬럼 채우기**

```sql
SELECT r.name AS 가게이름, c.name AS 고객이름,
       o.total_price AS 주문금액, m.menu_name AS 메뉴명
```

**Step 5. WHERE, GROUP BY, ORDER BY, LIMIT 추가**

조건이 있으면 추가합니다.

---

## 11. 자주 발생하는 에러 4가지

### 에러 1: Ambiguous column (컬럼명 충돌)

```
ERROR: Column 'id' in field list is ambiguous
```

**원인:** 여러 테이블에 같은 이름의 컬럼이 있을 때 어느 테이블 것인지 지정하지 않음

**해결:** 테이블 별칭을 붙여서 명시

```sql
-- 틀림
SELECT id, name FROM orders INNER JOIN customers ON ...

-- 맞음
SELECT o.id, c.name FROM orders AS o INNER JOIN customers AS c ON ...
```

---

### 에러 2: ON 절 빠뜨림

```
ERROR: You have an error in your SQL syntax ... near 'INNER JOIN'
```

또는 결과가 엄청나게 많이 나오는 경우 (카테시안 곱 발생)

**원인:** ON 절이 없으면 CROSS JOIN처럼 동작하거나 에러 발생

**해결:** 반드시 ON 절 작성

```sql
-- 위험! ON이 없음 → 수만 행 발생
SELECT * FROM orders INNER JOIN restaurants;

-- 올바름
SELECT * FROM orders AS o INNER JOIN restaurants AS r ON o.restaurant_id = r.id;
```

---

### 에러 3: WHERE와 ON의 혼용

**원인:** JOIN 조건(ON)과 필터 조건(WHERE)을 혼동

```sql
-- 잘못된 예: JOIN 연결 조건이 WHERE에 들어감
SELECT o.id, r.name
FROM orders AS o, restaurants AS r
WHERE o.restaurant_id = r.id AND r.category = '치킨';
-- 이 구문은 동작하지만 옛날 방식(암묵적 JOIN)이며 가독성이 떨어집니다.

-- 올바른 예: JOIN 연결은 ON, 필터는 WHERE
SELECT o.id, r.name
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
WHERE r.category = '치킨';
```

---

### 에러 4: GROUP BY에 누락된 컬럼

```
ERROR: 'hanip_delivery.r.name' isn't in GROUP BY
```

**원인:** SELECT에서 r.id는 빠뜨리고 r.name만 GROUP BY에 넣은 경우

**해결:** SELECT에서 집계함수가 아닌 컬럼을 모두 GROUP BY에 포함

```sql
-- 문제 있는 쿼리 (r.id가 SELECT에 없지만 r.name만 GROUP BY에 있음)
SELECT r.name, r.category, SUM(o.total_price)
FROM orders AS o INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.name;  -- r.id, r.category도 필요

-- 올바른 쿼리
SELECT r.name, r.category, SUM(o.total_price)
FROM orders AS o INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name, r.category;  -- SELECT의 비집계 컬럼 모두 포함
```

---

## 12. INNER JOIN vs LEFT JOIN 선택 기준

어떤 JOIN을 쓸지 헷갈릴 때 아래 결정 트리를 활용하세요.

```
"조회하려는 데이터에서 연결 대상이 없는 행도 결과에 포함해야 하나?"
                          |
            +-------------+-------------+
            |                           |
           YES                          NO
    (없는 행도 포함)            (양쪽 다 있어야 함)
            |                           |
      LEFT JOIN 사용              INNER JOIN 사용
            |
  "결과에서 연결 대상이 없는 행만 보고 싶나?"
                    |
      +--------------+--------------+
      |                             |
     YES                            NO
  WHERE IS NULL 추가          그냥 LEFT JOIN
  (없는 것만 필터링)           (전체 + NULL 포함)
```

**예제로 적용해 보기:**

| 질문 | 선택 | 이유 |
|---|---|---|
| 주문 내역과 가게 이름을 같이 보고 싶다 | INNER JOIN | 주문이 있으면 가게가 반드시 있음 |
| 모든 고객과 주문 횟수를 보고 싶다 (주문 없는 고객 포함) | LEFT JOIN | 주문 없는 고객도 보여야 함 |
| 한 번도 주문 안 한 고객만 보고 싶다 | LEFT JOIN + WHERE IS NULL | 없는 쪽만 필터링 |
| 주문 없는 가게를 포함한 가게별 실적 | LEFT JOIN | 주문 없는 가게(10번)도 0건으로 포함 |

---

## 13. 오늘 배운 것 정리 — JOIN 종류 요약표

| JOIN 종류 | 특징 | 결과 범위 | 주요 용도 |
|---|---|---|---|
| **INNER JOIN** | 양쪽 모두 매칭 | 교집합 | 일반적인 데이터 조합 |
| **LEFT JOIN** | 왼쪽 전부 + 오른쪽 매칭 | 왼쪽 기준 | 없는 행 포함, NULL 찾기 |
| **RIGHT JOIN** | 오른쪽 전부 + 왼쪽 매칭 | 오른쪽 기준 | LEFT로 대체 가능 |
| **CROSS JOIN** | ON 없이 모든 조합 | 카테시안 곱 | 조합 생성, 테스트 데이터 |
| **SELF JOIN** | 같은 테이블 두 번 참조 | 자기 참조 | 계층 구조, 쌍 비교 |

### 쿼리 작성 순서 요약

```sql
SELECT   -- 4. 보고 싶은 컬럼 (별칭 포함)
FROM     -- 1. 기준 테이블
  JOIN   -- 2. 연결할 테이블 (ON 포함)
  JOIN   -- 2. 추가 테이블 (필요 시)
WHERE    -- 3. 행 필터 (JOIN 이후)
GROUP BY -- 5. 집계 기준 (필요 시)
HAVING   -- 6. 그룹 필터 (필요 시)
ORDER BY -- 7. 정렬
LIMIT;   -- 8. 행 수 제한
```

### 오늘 배운 핵심 패턴

```sql
-- 패턴 1: 기본 INNER JOIN
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id

-- 패턴 2: 주문 없는 고객 찾기 (LEFT + IS NULL)
FROM customers AS c
    LEFT JOIN orders AS o ON c.id = o.customer_id
WHERE o.id IS NULL

-- 패턴 3: JOIN + GROUP BY (황금 조합)
FROM orders AS o
    INNER JOIN restaurants AS r ON o.restaurant_id = r.id
GROUP BY r.id, r.name

-- 패턴 4: IFNULL로 NULL을 0으로 표시
SELECT r.name, IFNULL(COUNT(o.id), 0) AS 주문건수
FROM restaurants AS r
    LEFT JOIN orders AS o ON r.id = o.restaurant_id
GROUP BY r.id, r.name
```

---

## 14. Day 7 예고

오늘 JOIN으로 '가게 이름별 매출 랭킹'을 만들었습니다. 그런데 여기서 한 가지 새로운 불편함이 생겼습니다.

> **"평균 주문금액보다 비싼 메뉴만 보고 싶어요!"**

이 문제를 해결하려면 먼저 평균을 구하고, 그 결과를 비교에 사용해야 합니다.

```sql
-- 이런 게 가능할까요?
SELECT * FROM menus
WHERE price > (SELECT AVG(price) FROM menus);
--              ↑ 쿼리 안에 또 다른 쿼리!
```

이것이 **서브쿼리(Subquery)**입니다. 쿼리 안에 또 다른 쿼리를 넣는 것이죠.

Day 7에서는 이 서브쿼리를 배웁니다:
- WHERE절 서브쿼리: "평균보다 비싼 메뉴"
- FROM절 서브쿼리: "1차 집계 결과를 다시 집계"
- SELECT절 서브쿼리: "각 행 옆에 전체 평균 함께 표시"
- EXISTS: "이 조건을 만족하는 것이 존재하는가?"
- UNION: "두 쿼리 결과를 위아래로 합치기"

내일도 오늘처럼 "왜 필요한가"부터 시작하겠습니다. 오늘 배운 JOIN을 충분히 복습해 오세요!

---

> **한입배달 MySQL 10일 완성 | Day 6 | 한국IT교육센터 부산점**
