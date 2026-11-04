# Day 7 실습 문제 — 서브쿼리

> **한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점**  
> DB: `hanip_delivery` | 테이블: `restaurants`, `customers`, `menus`, `orders`

---

## 문제 목록

| 번호 | 난이도 | 주제 |
|------|--------|------|
| 1 | ⭐ | WHERE절 단일행 서브쿼리 — AVG |
| 2 | ⭐ | WHERE절 단일행 서브쿼리 — MAX |
| 3 | ⭐ | WHERE절 단일행 서브쿼리 — MIN |
| 4 | ⭐⭐ | WHERE절 다중행 서브쿼리 — IN |
| 5 | ⭐⭐ | WHERE절 다중행 서브쿼리 — NOT IN |
| 6 | ⭐⭐ | FROM절 서브쿼리 (인라인 뷰) |
| 7 | ⭐⭐ | FROM절 서브쿼리 + JOIN |
| 8 | ⭐⭐⭐ | EXISTS / NOT EXISTS |
| 9 | ⭐⭐⭐ | UNION / UNION ALL |
| 10 | ⭐⭐⭐ | 복합 서브쿼리 (서브쿼리 중첩) |
| 보너스 1 | ★ | 서브쿼리 → JOIN으로 변환 |
| 보너스 2 | ★★ | SELECT절 스칼라 서브쿼리 |

---

## ⭐ 기초 문제 (WHERE절 단일행 서브쿼리)

---

### 문제 1. ⭐

> **배달의민족 운영팀**이 알고 싶어합니다:  
> "전체 메뉴 중 가격이 **전체 평균 가격보다 높은** 메뉴의 이름과 가격을 조회하세요.  
> 가격 높은 순서로 정렬하세요."

**사용 테이블**: `menus`  
**핵심 개념**: 단일행 서브쿼리, `AVG()`

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 한우소갈비탕 | 22000 |
| 왕갈비탕 | 18000 |
| 양념치킨 | 17000 |
| 후라이드치킨 | 16000 |
| ... | ... |

*(전체 평균 약 12,500원 기준으로 그 이상인 메뉴)*

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price
FROM menus
WHERE price > (SELECT AVG(price) FROM menus)
ORDER BY price DESC;
```

**풀이 설명**:
1. `SELECT AVG(price) FROM menus` → 전체 평균 가격을 하나의 숫자로 반환 (예: 12500)
2. `WHERE price > 12500` 조건으로 메뉴를 필터링
3. 서브쿼리를 사용하면 평균이 바뀌어도 자동으로 반영됨

</details>

---

### 문제 2. ⭐

> **한 가게 사장님**이 알고 싶어합니다:  
> "우리 가게(`restaurant_id = 1`) 메뉴 중에서 **가장 비싼 메뉴와 동일한 가격**의 메뉴를 모두 조회하세요.  
> (같은 가격의 메뉴가 여러 개일 수 있습니다.)"

**사용 테이블**: `menus`  
**핵심 개념**: 단일행 서브쿼리, `MAX()`

**힌트**: `WHERE price = (서브쿼리)` 형태를 사용하세요.

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 한우소갈비탕 | 22000 |

*(최고가 메뉴, 해당 가격이 같은 메뉴가 있다면 모두 표시)*

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price
FROM menus
WHERE restaurant_id = 1
  AND price = (
      SELECT MAX(price)
      FROM menus
      WHERE restaurant_id = 1
  );
```

**풀이 설명**:
- 서브쿼리: `restaurant_id = 1`인 메뉴들 중 최고가를 단일값으로 반환
- 바깥 쿼리: 그 최고가와 동일한 가격의 메뉴를 찾음
- `MAX()`는 항상 단 하나의 값을 반환하므로 `=` 연산자 사용 가능

</details>

---

### 문제 3. ⭐

> **운영팀**이 알고 싶어합니다:  
> "가장 저렴한 메뉴보다 3,000원 이상 비싼 메뉴를 조회하세요.  
> 가격 오름차순으로 정렬하고, 메뉴 이름과 가격을 표시하세요."

**사용 테이블**: `menus`  
**핵심 개념**: 단일행 서브쿼리, `MIN()`, 산술 연산

**힌트**: `(SELECT MIN(price) FROM menus) + 3000`처럼 서브쿼리 결과에 산술 연산을 할 수 있습니다.

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 김치찌개 | 8000 |
| 된장찌개 | 8000 |
| 순대국밥 | 8000 |
| ... | ... |

*(최저가 3000원 기준 → 6000원 이상인 메뉴)*

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price
FROM menus
WHERE price >= (SELECT MIN(price) FROM menus) + 3000
ORDER BY price;
```

**풀이 설명**:
- `(SELECT MIN(price) FROM menus)`로 최저가(예: 3000)를 구함
- 거기에 + 3000을 더하면 비교 기준값이 6000이 됨
- `WHERE price >= 6000`과 동일하지만, 서브쿼리를 쓰면 데이터가 바뀌어도 자동 반영

</details>

---

## ⭐⭐ 응용 문제 (다중행 서브쿼리 / FROM절 서브쿼리)

---

### 문제 4. ⭐⭐

> **운영팀**이 알고 싶어합니다:  
> "**한식 또는 분식** 카테고리 가게의 메뉴를 모두 조회하세요.  
> 가게 이름, 메뉴 이름, 가격을 표시하고 가게 이름 오름차순으로 정렬하세요.  
> **단, JOIN을 사용하지 말고 서브쿼리만으로 해결하세요.**"

**사용 테이블**: `menus`, `restaurants`  
**핵심 개념**: `IN` 다중행 서브쿼리

**힌트**: `restaurant_id IN (SELECT id FROM restaurants WHERE category IN ('한식', '분식'))`

**예상 결과**:

| 가게명 | menu_name | price |
|--------|-----------|-------|
| 부산한식당 | 된장찌개 | 8000 |
| 부산한식당 | 비빔밥 | 9000 |
| 부산한식당 | 한우소갈비탕 | 22000 |
| 새벽분식 | 떡볶이 | 5000 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT r.name      AS 가게명,
       m.menu_name,
       m.price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE m.restaurant_id IN (
    SELECT id
    FROM restaurants
    WHERE category IN ('한식', '분식')
)
ORDER BY r.name, m.price;
```

**풀이 설명**:
- 서브쿼리: `category IN ('한식', '분식')`인 가게들의 `id` 목록을 반환 (여러 행)
- `IN (...)`: 서브쿼리가 여러 값을 반환하므로 `IN` 사용
- `JOIN`은 가게 이름을 표시하기 위해 필요 (서브쿼리와 별개로 사용 가능)

**추가**: JOIN 없이 서브쿼리만으로 풀려면?
```sql
SELECT (SELECT name FROM restaurants WHERE id = m.restaurant_id) AS 가게명,
       m.menu_name,
       m.price
FROM menus m
WHERE m.restaurant_id IN (
    SELECT id FROM restaurants WHERE category IN ('한식', '분식')
)
ORDER BY 가게명, m.price;
```

</details>

---

### 문제 5. ⭐⭐

> **마케팅팀**이 알고 싶어합니다:  
> "**한 번도 주문된 적 없는 메뉴** 목록을 뽑아주세요.  
> 이 메뉴들을 '이달의 추천 메뉴'로 홍보하려 합니다.  
> 메뉴 이름과 가격을 표시하고, 가격 오름차순으로 정렬하세요."

**사용 테이블**: `menus`, `orders`  
**핵심 개념**: `NOT IN` 다중행 서브쿼리

**주의**: `NOT IN`을 사용할 때 NULL이 있으면 빈 결과가 나올 수 있으니, 서브쿼리에 `WHERE menu_id IS NOT NULL`을 추가하세요.

**예상 결과**:

| menu_name | price |
|-----------|-------|
| 계절비빔밥 | 9000 |
| 김치볶음밥 | 8000 |
| 오징어볶음 | 11000 |
| ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price
FROM menus
WHERE id NOT IN (
    SELECT DISTINCT menu_id
    FROM orders
    WHERE menu_id IS NOT NULL
)
ORDER BY price;
```

**풀이 설명**:
- 서브쿼리: `orders` 테이블에서 주문된 적 있는 `menu_id` 목록 반환
- `DISTINCT`: 중복 제거 (성능 최적화)
- `WHERE menu_id IS NOT NULL`: NULL이 서브쿼리 결과에 포함되면 `NOT IN`이 항상 빈 결과를 반환하는 버그 방지
- `NOT IN (...)`: 주문된 적 없는 메뉴만 필터링

**더 안전한 방법 (NOT EXISTS)**:
```sql
SELECT menu_name, price
FROM menus m
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.menu_id = m.id
)
ORDER BY price;
```

</details>

---

### 문제 6. ⭐⭐

> **운영팀장님**이 알고 싶어합니다:  
> "가게별로 총 주문수를 집계하고, 그 중에서 **주문수가 전체 가게 평균 이상**인 가게를 조회하세요.  
> 가게 번호와 주문수를 표시하고, 주문수 내림차순으로 정렬하세요."

**사용 테이블**: `orders`  
**핵심 개념**: FROM절 서브쿼리 (인라인 뷰), `AVG()`

**힌트**: 두 단계로 생각하세요.
1. 가게별 주문수를 집계한 임시 테이블 만들기
2. 그 임시 테이블에서 평균 이상인 것만 필터링

**예상 결과**:

| restaurant_id | 주문수 |
|---------------|--------|
| 3 | 8 |
| 7 | 7 |
| 1 | 6 |
| 5 | 6 |

*(평균 주문수가 약 5건이라고 가정할 때 5건 이상인 가게들)*

<details>
<summary>정답 보기</summary>

```sql
SELECT restaurant_id, 주문수
FROM (
    SELECT restaurant_id,
           COUNT(*) AS 주문수
    FROM orders
    GROUP BY restaurant_id
) AS 가게별집계
WHERE 주문수 >= (
    SELECT AVG(주문수)
    FROM (
        SELECT COUNT(*) AS 주문수
        FROM orders
        GROUP BY restaurant_id
    ) AS 평균계산용
)
ORDER BY 주문수 DESC;
```

**풀이 설명**:
- 안쪽 인라인 뷰: 가게별 주문수 집계
- 바깥 WHERE: 평균 주문수 이상인 가게만 필터링
- 평균 계산을 위해 동일한 집계를 서브쿼리로 한 번 더 사용

**간단한 방법** (HAVING 활용):
```sql
SELECT restaurant_id, COUNT(*) AS 주문수
FROM orders
GROUP BY restaurant_id
HAVING COUNT(*) >= (
    SELECT AVG(cnt)
    FROM (
        SELECT COUNT(*) AS cnt
        FROM orders
        GROUP BY restaurant_id
    ) AS 집계
)
ORDER BY 주문수 DESC;
```

</details>

---

### 문제 7. ⭐⭐

> **데이터 분석팀**이 알고 싶어합니다:  
> "가게별 총 주문수를 집계하고, 가게 이름도 함께 표시하세요.  
> 그 중 주문수가 **5건 이상**인 가게만 보여주세요.  
> 주문수 내림차순으로 정렬하세요."

**사용 테이블**: `orders`, `restaurants`  
**핵심 개념**: FROM절 서브쿼리 + JOIN

**예상 결과**:

| 가게명 | 주문수 |
|--------|--------|
| 부산한식당 | 8 |
| 황금치킨 | 7 |
| 원조칼국수 | 6 |
| 맛있는치킨 | 6 |
| 수제피자 | 5 |

<details>
<summary>정답 보기</summary>

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

**풀이 설명**:
- FROM절 서브쿼리로 가게별 주문수 임시 테이블 생성
- `JOIN restaurants`로 가게 이름을 가져옴
- `WHERE 집계.주문수 >= 5`로 최종 필터링

**핵심**: 인라인 뷰(FROM절 서브쿼리)는 마치 일반 테이블처럼 JOIN할 수 있습니다.

</details>

---

## ⭐⭐⭐ 도전 문제 (EXISTS / UNION / 복합 서브쿼리)

---

### 문제 8. ⭐⭐⭐

> **CRM팀**이 알고 싶어합니다:  
> "**한 번도 주문한 적 없는 고객** 목록을 뽑아주세요.  
> 이 고객들에게 재방문 유도 쿠폰을 보낼 예정입니다.  
> 고객 번호, 이름, 전화번호를 표시하고 고객 번호 오름차순으로 정렬하세요.  
> **NOT EXISTS를 사용하세요.**"

**사용 테이블**: `customers`, `orders`  
**핵심 개념**: `NOT EXISTS`

**예상 결과**:

| id | name | phone |
|----|------|-------|
| 9 | 박민서 | 010-9999-0001 |
| 10 | 정하윤 | 010-9999-0002 |

*(customers 데이터에서 주문이 없는 2명)*

<details>
<summary>정답 보기</summary>

```sql
SELECT c.id, c.name, c.phone
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
)
ORDER BY c.id;
```

**풀이 설명**:
- `NOT EXISTS`: 서브쿼리에서 해당 고객의 주문이 0건이면 TRUE
- `SELECT 1`: 실제 값이 필요 없고 존재 여부만 확인하므로 1(상수)을 사용
- `o.customer_id = c.id`: 바깥 쿼리의 현재 고객과 연결되는 부분 (상관 서브쿼리)

**LEFT JOIN IS NULL과 비교**:
```sql
SELECT c.id, c.name, c.phone
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.id IS NULL
ORDER BY c.id;
```
두 쿼리는 동일한 결과를 반환합니다. 어떤 방법이 더 읽기 쉬운지 팀과 상의해서 결정하세요.

</details>

---

### 문제 9. ⭐⭐⭐

> **마케팅팀**이 알고 싶어합니다:  
> "**가장 비싼 메뉴 TOP 3**와 **가장 저렴한 메뉴 TOP 3**를 한 목록으로 보여주세요.  
> 각 메뉴에 '고가' 또는 '저가' 구분 컬럼을 추가하고,  
> 가격 내림차순으로 정렬하세요."

**사용 테이블**: `menus`  
**핵심 개념**: `UNION ALL`, `LIMIT`

**힌트**: 고가 메뉴와 저가 메뉴를 각각 SELECT한 뒤 `UNION ALL`로 합칩니다.

**예상 결과**:

| menu_name | price | 구분 |
|-----------|-------|------|
| 한우소갈비탕 | 22000 | 고가 |
| 왕갈비탕 | 18000 | 고가 |
| 양념치킨 | 17000 | 고가 |
| 떡볶이 | 5000 | 저가 |
| 순대 | 4000 | 저가 |
| 김밥 | 3000 | 저가 |

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price, '고가' AS 구분
FROM menus
ORDER BY price DESC
LIMIT 3

UNION ALL

SELECT menu_name, price, '저가'
FROM menus
ORDER BY price
LIMIT 3

ORDER BY price DESC;
```

**주의**: 위 쿼리는 `UNION ALL` 앞뒤에 개별 `ORDER BY + LIMIT`을 사용합니다. MySQL에서는 이를 지원하지만, 일부 버전에서는 괄호로 감싸야 할 수 있습니다.

**더 안전한 방법**:
```sql
SELECT menu_name, price, '고가' AS 구분
FROM (
    SELECT menu_name, price
    FROM menus
    ORDER BY price DESC
    LIMIT 3
) AS 고가메뉴

UNION ALL

SELECT menu_name, price, '저가'
FROM (
    SELECT menu_name, price
    FROM menus
    ORDER BY price
    LIMIT 3
) AS 저가메뉴

ORDER BY price DESC;
```

**풀이 설명**:
- 각 SELECT에서 LIMIT으로 TOP 3를 먼저 추림
- `UNION ALL`로 두 결과 합치기 (중복 걱정 없으므로 ALL 사용)
- 마지막 `ORDER BY price DESC`로 전체 정렬

</details>

---

### 문제 10. ⭐⭐⭐

> **경영진**이 알고 싶어합니다:  
> "가게별로, 해당 가게 메뉴들의 평균 가격을 구하고,  
> **그 평균이 전체 가게 평균 메뉴가격보다 높은 가게**를 조회하세요.  
> 가게 이름, 해당 가게 메뉴 평균가격, 전체 평균가격을 표시하고  
> 가게 메뉴 평균가격 내림차순으로 정렬하세요."

**사용 테이블**: `restaurants`, `menus`  
**핵심 개념**: FROM절 서브쿼리, 단일행 서브쿼리 중첩

**예상 결과**:

| 가게명 | 가게메뉴평균 | 전체평균 |
|--------|-------------|----------|
| 부산한식당 | 15667 | 12500 |
| 황금치킨 | 15500 | 12500 |
| 수제피자 | 14333 | 12500 |
| ... | ... | ... |

*(전체 평균 12500원보다 메뉴 평균이 높은 가게)*

<details>
<summary>정답 보기</summary>

```sql
SELECT r.name                                AS 가게명,
       가게평균.avg_price                    AS 가게메뉴평균,
       (SELECT AVG(price) FROM menus)        AS 전체평균
FROM (
    SELECT restaurant_id,
           AVG(price) AS avg_price
    FROM menus
    GROUP BY restaurant_id
) AS 가게평균
JOIN restaurants r ON 가게평균.restaurant_id = r.id
WHERE 가게평균.avg_price > (SELECT AVG(price) FROM menus)
ORDER BY 가게평균.avg_price DESC;
```

**풀이 설명**:
- FROM절 서브쿼리: 가게별 평균 가격 집계
- WHERE절 서브쿼리: 전체 평균 계산 (단일행)
- SELECT절 서브쿼리: 전체 평균을 컬럼으로 표시 (스칼라)
- 세 종류의 서브쿼리를 모두 사용한 종합 문제

**ROUND를 추가해서 깔끔하게**:
```sql
SELECT r.name                                      AS 가게명,
       ROUND(가게평균.avg_price)                   AS 가게메뉴평균,
       ROUND((SELECT AVG(price) FROM menus))       AS 전체평균
FROM (
    SELECT restaurant_id,
           AVG(price) AS avg_price
    FROM menus
    GROUP BY restaurant_id
) AS 가게평균
JOIN restaurants r ON 가게평균.restaurant_id = r.id
WHERE 가게평균.avg_price > (SELECT AVG(price) FROM menus)
ORDER BY 가게평균.avg_price DESC;
```

</details>

---

## ★ 보너스 문제

---

### 보너스 1. ★ — 서브쿼리 → JOIN으로 변환

아래 서브쿼리 버전 쿼리를 **JOIN으로** 바꿔보세요.  
결과가 동일한지 확인하세요.

**서브쿼리 버전**:
```sql
SELECT menu_name, price
FROM menus
WHERE restaurant_id IN (
    SELECT id
    FROM restaurants
    WHERE category = '치킨'
)
ORDER BY price DESC;
```

**조건**:
- JOIN을 사용해서 동일한 결과를 내는 쿼리를 작성하세요.
- 결과 컬럼: `menu_name`, `price`
- 정렬: `price` 내림차순

<details>
<summary>정답 보기</summary>

```sql
-- JOIN 버전
SELECT m.menu_name, m.price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.id
WHERE r.category = '치킨'
ORDER BY m.price DESC;
```

**비교**:

| 항목 | 서브쿼리 버전 | JOIN 버전 |
|------|------------|---------|
| 코드 길이 | 더 긺 | 더 짧음 |
| 읽기 쉬움 | 조건 로직 명확 | 관계 명확 |
| 성능 | 유사 (옵티마이저가 최적화) | 유사 |

**어떤 게 더 좋은가?**  
이 경우에는 JOIN이 더 간결합니다. 그러나 비교 기준이 되는 값을 계산해야 하는 경우(예: AVG, MAX)에는 서브쿼리가 필요합니다.

</details>

---

### 보너스 2. ★★ — SELECT절 스칼라 서브쿼리

> "각 **가게**의 이름, 카테고리, 전체 메뉴 수, 전체 가게 평균 메뉴 수를 조회하고,  
> 본인 가게의 메뉴 수가 전체 평균 메뉴 수보다 많은지 적은지 '많음'/'보통'/'적음'으로 표시하세요."

**사용 테이블**: `restaurants`, `menus`  
**핵심 개념**: SELECT절 스칼라 서브쿼리, `CASE WHEN`

**예상 결과**:

| name | category | 메뉴수 | 전체평균메뉴수 | 평균비교 |
|------|----------|--------|---------------|----------|
| 부산한식당 | 한식 | 5 | 3.0 | 많음 |
| 황금치킨 | 치킨 | 4 | 3.0 | 많음 |
| 원조칼국수 | 한식 | 3 | 3.0 | 보통 |
| 새벽분식 | 분식 | 2 | 3.0 | 적음 |
| ... | ... | ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT r.name                                                AS name,
       r.category,
       COUNT(m.id)                                           AS 메뉴수,
       ROUND(
           (SELECT COUNT(*) / COUNT(DISTINCT restaurant_id)
            FROM menus)
       , 1)                                                  AS 전체평균메뉴수,
       CASE
           WHEN COUNT(m.id) > (SELECT COUNT(*) / COUNT(DISTINCT restaurant_id) FROM menus)
               THEN '많음'
           WHEN COUNT(m.id) = ROUND((SELECT COUNT(*) / COUNT(DISTINCT restaurant_id) FROM menus), 0)
               THEN '보통'
           ELSE '적음'
       END                                                   AS 평균비교
FROM restaurants r
LEFT JOIN menus m ON r.id = m.restaurant_id
GROUP BY r.id, r.name, r.category
ORDER BY 메뉴수 DESC;
```

**더 간결한 방법** (FROM절 서브쿼리 활용):
```sql
SELECT r.name,
       r.category,
       IFNULL(메뉴집계.메뉴수, 0)       AS 메뉴수,
       전체평균.avg_menu_count           AS 전체평균메뉴수,
       CASE
           WHEN IFNULL(메뉴집계.메뉴수, 0) > 전체평균.avg_menu_count THEN '많음'
           WHEN IFNULL(메뉴집계.메뉴수, 0) = ROUND(전체평균.avg_menu_count, 0) THEN '보통'
           ELSE '적음'
       END                              AS 평균비교
FROM restaurants r
LEFT JOIN (
    SELECT restaurant_id, COUNT(*) AS 메뉴수
    FROM menus
    GROUP BY restaurant_id
) AS 메뉴집계 ON r.id = 메뉴집계.restaurant_id
CROSS JOIN (
    SELECT ROUND(COUNT(*) / COUNT(DISTINCT restaurant_id), 1) AS avg_menu_count
    FROM menus
) AS 전체평균
ORDER BY IFNULL(메뉴집계.메뉴수, 0) DESC;
```

**풀이 설명**:
- `LEFT JOIN 메뉴집계`: 가게별 메뉴 수 계산
- `CROSS JOIN 전체평균`: 전체 평균 메뉴 수를 단 한 번만 계산해서 모든 행에 붙임
- `CASE WHEN`: 메뉴수와 평균 비교 후 '많음'/'보통'/'적음' 레이블 부여

</details>

---

## 오늘의 핵심 정리

```
서브쿼리 위치별 정리:

WHERE절  → 단일행(= > <), 다중행(IN / NOT IN / ANY / ALL / EXISTS)
FROM절   → 임시 테이블처럼 사용 (반드시 AS 별칭 필요!)
SELECT절 → 스칼라 서브쿼리 (반드시 1행 1열 반환)

UNION vs UNION ALL:
UNION    → 중복 제거 (느림)
UNION ALL → 중복 포함 (빠름)

NOT IN vs NOT EXISTS:
NOT IN      → NULL 있으면 위험
NOT EXISTS  → NULL 안전, 대부분 권장
```

---

*한입배달 MySQL 10일 완성 | 한국IT교육센터 부산점*
