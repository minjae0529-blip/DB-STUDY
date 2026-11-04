# Day 3 — 데이터 넣고 꺼내기: CRUD

> MySQL 10일 완성 과정 | 한입배달 DB | 2026-04-17

---

## 1. Day 3 개요

### 학습 목표

이번 수업을 마치면 다음을 할 수 있습니다.

1. `INSERT` 문을 사용해 단건/다건 데이터를 테이블에 넣을 수 있다.
2. `SELECT`와 `WHERE`로 원하는 조건의 데이터를 조회할 수 있다.
3. `ORDER BY`와 `LIMIT`으로 정렬 및 개수 제한 조회를 할 수 있다.
4. `UPDATE`와 `DELETE`를 안전하게 실행할 수 있다 (WHERE의 중요성 이해).
5. NULL 값을 올바르게 다룰 수 있다.

### Day 2 복습 한줄 요약

> Day 2에서는 제약조건(PK, AI, NOT NULL, UNIQUE, DEFAULT, CHECK)으로 **"아무 데이터나 들어오지 못하는 자물쇠"**를 테이블에 달았고, 한입배달의 restaurants·customers·menus 테이블을 완성했습니다.

---

## 2. INSERT — 데이터 입고

### 기본 문법

**단건 INSERT (컬럼명 명시 — 권장)**

```sql
INSERT INTO 테이블명 (컬럼1, 컬럼2, 컬럼3)
VALUES (값1, 값2, 값3);
```

**단건 INSERT (컬럼명 생략)**

```sql
INSERT INTO 테이블명
VALUES (값1, 값2, 값3);   -- 테이블 컬럼 순서 그대로 값을 채워야 함
```

**다건 INSERT (한 번에 여러 행)**

```sql
INSERT INTO 테이블명 (컬럼1, 컬럼2)
VALUES
    (값a1, 값a2),
    (값b1, 값b2),
    (값c1, 값c2);
```

### 코드 예제

```sql
-- 단건: menus에 새 메뉴 추가
INSERT INTO menus (restaurant_id, menu_name, price, description, is_available)
VALUES (1, '양념반후라이드반', 22000, '반반 황금 조합', TRUE);

-- 다건: 여러 메뉴를 한 번에
INSERT INTO menus (restaurant_id, menu_name, price, description, is_available)
VALUES
    (4, '비빔냉면',    9000,  '쫄깃한 면발, 매콤한 소스', TRUE),
    (5, '탕수육 (소)', 15000, NULL,                       TRUE),
    (6, '김치찌개 정식', 8500, '된장찌개 선택 가능',       TRUE);
```

### AUTO_INCREMENT 컬럼 생략 방법

`id` 컬럼에 `AUTO_INCREMENT`가 걸려 있으면 INSERT 시 **컬럼 목록에서 id를 빼면** 됩니다. DB가 알아서 다음 번호를 채워줍니다.

```sql
-- id 컬럼을 아예 목록에서 제외
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (3, '떡볶이 세트', 8000);
```

컬럼명을 생략하고 VALUES만 쓰는 경우에는 `id` 자리에 `NULL` 또는 `0`을 넣으면 AUTO_INCREMENT가 동작합니다.

```sql
INSERT INTO menus
VALUES (NULL, 2, '불고기피자', 18000, '달콤한 불고기 소스', TRUE);
```

### 주의사항

- 문자열(VARCHAR)은 반드시 `'작은따옴표'`로 감쌉니다.
- NOT NULL 컬럼에 값을 넣지 않으면 에러가 발생합니다.
- 컬럼명을 명시하지 않으면 테이블의 컬럼 수와 순서가 정확히 맞아야 합니다 — 나중에 컬럼이 추가되면 깨질 수 있어서 **컬럼명 명시를 강력 권장**합니다.

### 다건 INSERT vs 반복 INSERT 성능 차이

| 방식 | 쿼리 수 | 성능 |
|------|---------|------|
| 단건 INSERT 10회 반복 | 10번 | 느림 (매번 DB 연결 왕복) |
| 다건 INSERT 1회 | 1번 | 빠름 (연결 1회) |

> 실무에서 대량 데이터를 넣을 때는 반드시 다건 INSERT나 `LOAD DATA INFILE`을 사용합니다.

---

## 3. SELECT 기본

### `SELECT *` vs 컬럼 지정 비교

```sql
-- 전체 컬럼 조회 (개발/확인용)
SELECT * FROM restaurants;

-- 필요한 컬럼만 조회 (실무 권장)
SELECT name, category, rating FROM restaurants;
```

| 방식 | 장점 | 단점 |
|------|------|------|
| `SELECT *` | 빠르게 전체 확인 가능 | 불필요한 데이터 전송, 컬럼 추가 시 결과 변경 |
| 컬럼 명시 | 필요한 것만 가져와 효율적 | 컬럼명을 직접 타이핑해야 함 |

> 실무에서는 성능과 명확성을 위해 **컬럼명을 명시**하는 것이 원칙입니다.

### FROM 절과 세미콜론

- `FROM` 뒤에는 데이터를 가져올 **테이블명**을 씁니다.
- 쿼리 끝에는 반드시 **세미콜론(`;`)**을 붙입니다. Workbench에서 여러 쿼리를 같이 쓸 때 구분자 역할을 합니다.

---

## 4. WHERE — 검색 필터 (쿠팡 비유)

쿠팡에서 "가격 1만원 이하", "별점 4개 이상"으로 필터링하듯, WHERE는 **원하는 행(row)만 골라내는 필터**입니다.

```sql
SELECT 컬럼명
FROM 테이블명
WHERE 조건;
```

### 비교 연산자

| 연산자 | 의미 | 예제 |
|--------|------|------|
| `=` | 같다 | `WHERE category = '치킨'` |
| `!=` 또는 `<>` | 다르다 | `WHERE category != '치킨'` |
| `>` | 크다 | `WHERE rating > 4.0` |
| `<` | 작다 | `WHERE price < 10000` |
| `>=` | 크거나 같다 | `WHERE rating >= 4.0` |
| `<=` | 작거나 같다 | `WHERE price <= 15000` |

### BETWEEN — 범위 조건

```sql
-- 가격 8000원 이상, 15000원 이하 (경계값 포함)
SELECT menu_name, price FROM menus
WHERE price BETWEEN 8000 AND 15000;

-- 위와 동일한 의미
WHERE price >= 8000 AND price <= 15000
```

> `BETWEEN a AND b`는 a, b 경계값을 **모두 포함**합니다.

### IN — 목록 일치

```sql
-- 치킨, 피자, 분식 중 하나인 가게
SELECT name, category FROM restaurants
WHERE category IN ('치킨', '피자', '분식');

-- 반대: NOT IN
WHERE category NOT IN ('치킨', '피자')
```

`IN`은 `OR`을 여러 개 쓴 것과 같지만 훨씬 간결합니다.

### LIKE + 와일드카드

LIKE는 **패턴으로 부분 일치** 검색을 할 때 사용합니다.

| 와일드카드 | 의미 | 예 |
|-----------|------|-----|
| `%` | 0개 이상의 임의 문자 | `'%치킨%'` → 치킨이 어디든 포함 |
| `_` | 정확히 1개의 임의 문자 | `'_순_'` → 3글자, 가운데가 순 |

```sql
-- '김치'가 포함된 메뉴 (앞뒤 어디든)
WHERE menu_name LIKE '%김치%'
-- 결과 예: 김치찌개, 묵은지김치찜, 김치볶음밥

-- '김'으로 시작하는 고객 이름
WHERE name LIKE '김%'
-- 결과 예: 김철수, 김영희, 김민준

-- '동'으로 끝나는 주소
WHERE address LIKE '%동'
-- 결과 예: 해운대동, 서면동, 광안동

-- 3글자이고 가운데 글자가 '순'
WHERE name LIKE '_순_'
-- 결과 예: 이순신, 박순이, 최순옥

-- 5글자로 시작이 '치', 끝이 '세트'
WHERE menu_name LIKE '치__세트'
-- '_'는 1글자씩이므로 '치XX세트' 형태
```

> **주의:** LIKE는 인덱스를 타지 못하는 경우가 많아 대용량 테이블에서는 느릴 수 있습니다. 특히 `LIKE '%단어'`(앞에 %) 형태는 풀스캔이 발생합니다.

### IS NULL / IS NOT NULL

NULL은 "값이 없음"을 의미합니다. NULL과의 비교는 반드시 `IS NULL` / `IS NOT NULL`을 사용해야 합니다.

```sql
-- description이 없는 메뉴
SELECT menu_name FROM menus WHERE description IS NULL;

-- description이 있는 메뉴
SELECT menu_name FROM menus WHERE description IS NOT NULL;
```

> ❌ **잘못된 예:** `WHERE description = NULL` → 이 조건은 항상 거짓이라 결과가 나오지 않습니다!
> ✅ **올바른 예:** `WHERE description IS NULL`

### AND / OR / NOT + 연산자 우선순위

```sql
-- AND: 두 조건 모두 참
WHERE category = '치킨' AND rating >= 4.0

-- OR: 둘 중 하나라도 참
WHERE category = '치킨' OR category = '피자'

-- NOT: 조건의 반대
WHERE NOT category = '분식'
```

**연산자 우선순위:** `NOT` > `AND` > `OR`

괄호를 쓰지 않으면 AND가 OR보다 먼저 계산됩니다.

```sql
-- ❗ 의도와 다를 수 있는 쿼리 (AND가 먼저)
WHERE category = '치킨' OR category = '피자' AND rating >= 4.0
-- 실제 계산: category = '치킨' OR (category = '피자' AND rating >= 4.0)

-- ✅ 괄호로 의도를 명확히
WHERE (category = '치킨' OR category = '피자') AND rating >= 4.0
```

> **팁:** 복합 조건에는 항상 **괄호**를 사용해 의도를 명확히 하세요.

---

## 5. ORDER BY & LIMIT

### ORDER BY — 정렬

```sql
SELECT 컬럼명
FROM 테이블명
ORDER BY 정렬기준컬럼 ASC;   -- ASC: 오름차순 (기본값)
ORDER BY 정렬기준컬럼 DESC;  -- DESC: 내림차순
```

```sql
-- 평점 높은 순 (내림차순)
SELECT name, rating FROM restaurants ORDER BY rating DESC;

-- 가격 낮은 순 (오름차순, 생략 가능)
SELECT menu_name, price FROM menus ORDER BY price ASC;
```

### 다중 정렬

1차 기준으로 정렬하고, 같은 값이 있으면 2차 기준으로 정렬합니다.

```sql
-- 카테고리 오름차순 → 같은 카테고리 안에서는 평점 내림차순
SELECT name, category, rating FROM restaurants
ORDER BY category ASC, rating DESC;
```

### LIMIT — 개수 제한

```sql
-- 상위 N개만
SELECT name, rating FROM restaurants
ORDER BY rating DESC
LIMIT 3;

-- N개를 건너뛰고 M개 가져오기 (페이지네이션)
SELECT menu_name, price FROM menus
ORDER BY id
LIMIT 5 OFFSET 10;   -- 11번째부터 5개
```

### 페이지네이션 개념

쇼핑몰에서 "1페이지, 2페이지" 처럼 데이터를 나눠서 보여주는 것을 페이지네이션이라고 합니다.

| 페이지 | 공식 | SQL |
|--------|------|-----|
| 1페이지 | OFFSET = (1-1) × 5 = 0 | `LIMIT 5 OFFSET 0` |
| 2페이지 | OFFSET = (2-1) × 5 = 5 | `LIMIT 5 OFFSET 5` |
| 3페이지 | OFFSET = (3-1) × 5 = 10 | `LIMIT 5 OFFSET 10` |

> **공식:** `OFFSET = (페이지 번호 - 1) × 페이지 크기`

---

## 6. UPDATE — 데이터 수정

### 기본 문법

```sql
UPDATE 테이블명
SET 컬럼1 = 값1, 컬럼2 = 값2
WHERE 조건;
```

### 예제

```sql
-- id가 1인 가게의 평점 수정
UPDATE restaurants
SET rating = 4.5
WHERE id = 1;

-- 1번 가게 메뉴 가격 10% 인상
UPDATE menus
SET price = price * 1.1
WHERE restaurant_id = 1;
```

### WHERE의 중요성 — 핵버튼 시나리오

WHERE를 빠뜨리면 **테이블의 모든 행**이 수정됩니다.

```sql
-- ⚠️ 핵버튼 시나리오 — 절대 실행 금지!
UPDATE restaurants SET rating = 0;
-- 결과: 10개 가게 모두 평점 0점... 복구하려면 백업이 있어야 함
```

> **비유:** WHERE는 핵버튼의 **안전핀**입니다. 안전핀 없이 버튼을 누르면 전체가 날아갑니다.

### SAFE UPDATE MODE 설정법

MySQL Workbench는 기본적으로 WHERE 없는 UPDATE/DELETE를 차단합니다.

**GUI에서 확인:**  
`Edit` → `Preferences` → `SQL Editor` → `Safe Updates` 체크 여부 확인

**코드로 제어 (세션 내):**

```sql
SET SQL_SAFE_UPDATES = 1;  -- 안전모드 켜기 (권장)
SET SQL_SAFE_UPDATES = 0;  -- 안전모드 끄기 (주의)
```

---

## 7. DELETE — 데이터 삭제

### 기본 문법

```sql
DELETE FROM 테이블명
WHERE 조건;
```

### 예제

```sql
-- 판매 중지된 메뉴만 삭제
DELETE FROM menus
WHERE is_available = FALSE;

-- 특정 고객 데이터 삭제
DELETE FROM customers
WHERE id = 5;
```

### TRUNCATE vs DELETE 차이

| 구분 | TRUNCATE | DELETE |
|------|----------|--------|
| WHERE 사용 | 불가 (전체만) | 가능 |
| 속도 | 매우 빠름 | 느림 |
| 롤백(ROLLBACK) | 불가 | 가능 (트랜잭션 안에서) |
| AUTO_INCREMENT 초기화 | O (1로 리셋) | X (유지) |
| 용도 | 개발 중 테이블 초기화 | 운영 중 특정 데이터 삭제 |

```sql
-- 테이블 전체를 빠르게 비우고 싶을 때 (되돌리기 불가)
TRUNCATE TABLE menus;
```

> **경고:** `DELETE FROM 테이블명;` (WHERE 없음)도 전체 삭제입니다. TRUNCATE보다 느리고 로그는 남지만, 마찬가지로 위험합니다.

---

## 8. SELECT 실행 순서

쿼리를 작성하는 순서와 DB가 **내부적으로 실행하는 순서**는 다릅니다.

**작성 순서:**

```sql
SELECT   → FROM → WHERE → ORDER BY → LIMIT
```

**실행 순서:**

```
1. FROM      — 어느 테이블에서?
2. WHERE     — 어느 행을?
3. SELECT    — 어느 컬럼을?
4. ORDER BY  — 어떤 순서로?
5. LIMIT     — 몇 개만?
```

이 순서를 이해하면 "왜 WHERE에서는 SELECT의 별칭(AS)을 쓸 수 없는지"를 알 수 있습니다. WHERE는 SELECT보다 먼저 실행되기 때문에 아직 별칭이 정해지지 않은 상태입니다.

```sql
-- ❌ 에러: WHERE는 SELECT보다 먼저 실행되므로 별칭을 인식 못 함
SELECT price * 1.1 AS new_price FROM menus WHERE new_price > 10000;

-- ✅ 올바른 방법: 원래 컬럼명이나 식을 그대로 사용
SELECT price * 1.1 AS new_price FROM menus WHERE price * 1.1 > 10000;
```

---

## 9. 자주 하는 실수

**① WHERE에서 NULL을 `=`로 비교**

```sql
-- ❌ 작동 안 함
WHERE description = NULL

-- ✅ 올바른 방법
WHERE description IS NULL
```

**② WHERE 없는 UPDATE / DELETE 실행**

```sql
-- ❌ 전체 수정/삭제 (핵버튼!)
UPDATE menus SET price = 9999;
DELETE FROM menus;

-- ✅ 항상 WHERE로 대상 특정
UPDATE menus SET price = 9999 WHERE id = 5;
DELETE FROM menus WHERE is_available = FALSE;
```

**③ 문자열 비교에 작은따옴표 빠뜨리기**

```sql
-- ❌ 에러 발생 (컬럼명으로 인식)
WHERE category = 치킨

-- ✅ 작은따옴표로 감싸야 함
WHERE category = '치킨'
```

**④ BETWEEN 경계값 반대로 쓰기**

```sql
-- ❌ 결과 없음 (8000 <= price <= 5000을 만족하는 값 없음)
WHERE price BETWEEN 8000 AND 5000

-- ✅ 작은 값을 먼저
WHERE price BETWEEN 5000 AND 8000
```

**⑤ ORDER BY 없이 LIMIT 쓰기**

```sql
-- ❌ 순서 보장 없음 (DB 내부 순서에 의존)
SELECT * FROM menus LIMIT 5;

-- ✅ 항상 ORDER BY와 함께
SELECT * FROM menus ORDER BY id LIMIT 5;
```

---

## 10. 오늘의 핵심 정리

| 구문 | 역할 | 핵심 포인트 |
|------|------|------------|
| `INSERT` | 데이터 추가 | 컬럼명 명시, AUTO_INCREMENT 생략 |
| `SELECT` | 데이터 조회 | `*` vs 컬럼 지정 |
| `WHERE` | 행 필터링 | 쿠팡 검색 필터, NULL은 IS NULL |
| `ORDER BY` | 정렬 | ASC(기본)/DESC, 다중 정렬 |
| `LIMIT` | 개수 제한 | TOP N, OFFSET으로 페이지네이션 |
| `UPDATE` | 데이터 수정 | **WHERE 필수** (핵버튼 주의!) |
| `DELETE` | 데이터 삭제 | **WHERE 필수**, TRUNCATE와 구분 |

### 다음 시간 예고 — Day 4: 데이터 가공의 기술

> "데이터를 꺼냈는데, 이름 앞뒤 공백을 없애거나, 날짜를 '2026년 4월' 형식으로 바꾸거나, 배달비가 NULL이면 0으로 표시하고 싶다면?"

Day 4에서는 MySQL 내장 함수(문자열, 숫자, 날짜, 조건)를 배웁니다.  
엑셀의 `IF`, `LEFT`, `ROUND`를 SQL에서 쓰는 방법이 궁금하다면 기대해 주세요!
