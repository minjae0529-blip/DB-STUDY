# Day 4 — 데이터 가공의 기술: 내장 함수

> "꺼낸 데이터를 좀 다듬고 싶은데요?"

---

## 1. Day 4 개요

### 학습 목표

1. 문자열 함수 7가지를 사용하여 텍스트 데이터를 가공할 수 있다.
2. 숫자 함수 6가지를 사용하여 수치 데이터를 계산할 수 있다.
3. 날짜 함수 8가지를 사용하여 날짜 데이터를 추출·변환할 수 있다.
4. 조건 함수(IFNULL, IF, CASE WHEN)로 데이터를 분류할 수 있다.
5. DISTINCT와 AS(별칭)를 활용하여 조회 결과를 정리할 수 있다.

### Day 3 복습 요약

| 명령어 | 역할 |
|--------|------|
| `INSERT` | 데이터 추가 |
| `SELECT` + `WHERE` | 조건부 조회 |
| `ORDER BY` + `LIMIT` | 정렬 및 개수 제한 |
| `UPDATE` | 데이터 수정 (WHERE 필수!) |
| `DELETE` | 데이터 삭제 (WHERE 필수!) |

> Day 3에서 데이터를 "꺼내는" 방법을 배웠다면, Day 4는 꺼낸 데이터를 "다듬는" 방법이다.

---

## 2. 함수란 무엇인가?

### 엑셀 함수 vs SQL 함수

| 기능 | 엑셀 | SQL |
|------|------|-----|
| 텍스트 합치기 | `=A1 & B1` 또는 `=CONCAT(A1, B1)` | `CONCAT(name, category)` |
| 글자 수 세기 | `=LEN(A1)` | `CHAR_LENGTH(name)` |
| 반올림 | `=ROUND(A1, 0)` | `ROUND(rating, 0)` |
| 오늘 날짜 | `=TODAY()` | `CURDATE()` |
| 조건 분기 | `=IF(A1>10000, "고가", "저가")` | `IF(price>10000, '고가', '저가')` |

**핵심 개념**: 함수는 값을 받아서(입력) 새로운 값을 돌려준다(출력).

```sql
-- 함수 사용 위치: SELECT 절에서 컬럼 대신 사용
SELECT CONCAT(name, ' (', category, ')') FROM restaurants;
--     ↑ 이 자리에 컬럼명 대신 함수(컬럼명)을 쓰면 된다
```

---

## 3. 문자열 함수

### 3-1. CONCAT — 문자열 합치기

**문법**: `CONCAT(값1, 값2, ...)`

```sql
SELECT CONCAT(name, ' (', category, ')') AS 가게정보
FROM restaurants;
```

| 가게정보 |
|---------|
| 부산명가갈비 (한식) |
| 치킨킹 (치킨) |

> **주의**: 인수 중 하나라도 NULL이면 결과 전체가 NULL이 된다. NULL 방지는 `IFNULL`과 함께 사용.

---

### 3-2. SUBSTRING — 부분 문자열 추출

**문법**: `SUBSTRING(문자열, 시작위치, [길이])`

- 시작 위치는 **1부터** 시작 (0이 아님!)
- 길이를 생략하면 시작 위치부터 끝까지

```sql
SELECT
    name,
    SUBSTRING(name, 1, 3) AS 앞3글자,   -- 1번째부터 3글자
    SUBSTRING(name, 3)    AS 3번째부터  -- 3번째부터 끝까지
FROM restaurants;
```

| name | 앞3글자 | 3번째부터 |
|------|---------|---------|
| 부산명가갈비 | 부산명 | 가갈비 |

---

### 3-3. ⚠️ LENGTH vs CHAR_LENGTH — 바이트 수 vs 글자 수

**이것은 한국에서 MySQL을 쓸 때 가장 자주 실수하는 부분이다!**

| 함수 | 반환 기준 | 한글 '안녕' (2글자) 결과 |
|------|----------|----------------------|
| `LENGTH` | **바이트(byte) 수** | 6 (한글 1자 = UTF-8에서 3바이트) |
| `CHAR_LENGTH` | **글자(character) 수** | 2 |

```sql
SELECT
    '안녕'              AS 문자열,
    LENGTH('안녕')      AS LENGTH결과,      -- 6
    CHAR_LENGTH('안녕') AS CHAR_LENGTH결과; -- 2
```

**실무에서 글자 수를 기준으로 필터할 때는 반드시 `CHAR_LENGTH`를 사용해야 한다.**

```sql
-- 잘못된 예: 한글 이름이 4글자면 LENGTH는 12를 반환
SELECT * FROM customers WHERE LENGTH(name) >= 4;       -- 의도와 다른 결과!

-- 올바른 예
SELECT * FROM customers WHERE CHAR_LENGTH(name) >= 4;  -- 글자 수 기준
```

---

### 3-4. TRIM / LTRIM / RTRIM — 공백 제거

**문법**: `TRIM(문자열)`, `LTRIM(문자열)`, `RTRIM(문자열)`

```sql
SELECT
    '  한입배달  '              AS 원본,          -- '  한입배달  '
    TRIM('  한입배달  ')        AS TRIM결과,      -- '한입배달'
    LTRIM('  한입배달  ')       AS LTRIM결과,     -- '한입배달  '
    RTRIM('  한입배달  ')       AS RTRIM결과;     -- '  한입배달'
```

> **실무 활용**: 사용자가 입력한 검색어나 외부 시스템에서 가져온 데이터에 공백이 섞여 있을 때 사용.

---

### 3-5. REPLACE — 문자열 치환

**문법**: `REPLACE(문자열, 찾을값, 바꿀값)`

```sql
SELECT
    address,
    REPLACE(address, '부산', '🌊부산') AS 이모지주소
FROM restaurants;
```

| address | 이모지주소 |
|---------|-----------|
| 부산시 해운대구 | 🌊부산시 해운대구 |

```sql
-- 특정 단어 제거: 빈 문자열('')로 치환
SELECT REPLACE(menu_name, '구이', '') FROM menus WHERE menu_name LIKE '%구이%';
```

---

### 3-6. LPAD — 왼쪽 채우기 (주문번호 포맷팅!)

**문법**: `LPAD(문자열, 총자릿수, 채울문자)`

배달앱에서 주문번호가 1, 2, 3이면 보기 불편하다. 00001, 00002처럼 만들고 싶을 때!

```sql
SELECT
    id,
    LPAD(id, 5, '0') AS 주문번호   -- 1 → '00001', 23 → '00023'
FROM menus;
```

| id | 주문번호 |
|----|---------|
| 1 | 00001 |
| 23 | 00023 |

> `RPAD(문자열, 총자릿수, 채울문자)`: 오른쪽 채우기 (좌우 반대)

---

### 3-7. UPPER / LOWER — 대소문자 변환

**문법**: `UPPER(문자열)`, `LOWER(문자열)`

```sql
SELECT
    UPPER('chicken')  AS 대문자,  -- 'CHICKEN'
    LOWER('CHICKEN')  AS 소문자;  -- 'chicken'

-- 실무 활용: 대소문자 무관한 비교
SELECT * FROM restaurants WHERE LOWER(category) = 'chicken';
```

---

## 4. 숫자 함수

### 4-1. ROUND / CEIL / FLOOR 비교

세 함수 모두 소수점을 처리하지만 방식이 다르다.

| 함수 | 의미 | `4500 / 1000` (= 4.5) 결과 |
|------|------|--------------------------|
| `ROUND(값, 0)` | 반올림 | 5 |
| `CEIL(값)` | 무조건 올림 | 5 |
| `FLOOR(값)` | 무조건 내림 | 4 |

```sql
SELECT
    menu_name,
    price,
    ROUND(price / 1000, 0)  AS 반올림,
    CEIL(price / 1000)      AS 올림,
    FLOOR(price / 1000)     AS 내림
FROM menus;
```

> **실무 팁**: 정산/회계에는 `ROUND`, 고객 혜택(유리한 방향)에는 `CEIL` or `FLOOR` 선택.

**ROUND의 두 번째 인수**

```sql
ROUND(1234.567, 2)   -- 1234.57  (소수점 2자리)
ROUND(1234.567, 0)   -- 1235     (정수)
ROUND(1234.567, -2)  -- 1200     (십의 자리 기준 반올림)
```

---

### 4-2. MOD — 나머지

**문법**: `MOD(피제수, 제수)` 또는 `피제수 % 제수`

```sql
SELECT
    menu_name,
    price,
    MOD(price, 1000) AS 천원미만나머지,
    price - MOD(price, 1000) AS 천원절사가격
FROM menus;
```

> **실무 활용**: 짝수/홀수 구분, 끝자리 계산, 할인가 계산.

---

### 4-3. ABS — 절댓값

**문법**: `ABS(값)`

```sql
SELECT ABS(-500);   -- 500
SELECT ABS(500);    -- 500
```

---

### 4-4. TRUNCATE — 소수점 버림

**문법**: `TRUNCATE(값, 소수점자리)`

`FLOOR`와 유사하지만, `FLOOR`는 소수점 이하를 무조건 내림(음수에서 차이), `TRUNCATE`는 지정 자리 이후를 그냥 잘라낸다.

```sql
SELECT
    rating,
    TRUNCATE(rating, 0) AS TRUNCATE결과,  -- 4.8 → 4 (그냥 자름)
    FLOOR(rating)       AS FLOOR결과;     -- 4.8 → 4 (양수에서는 동일)
FROM restaurants;
```

---

## 5. 날짜 함수

### 5-1. 현재 날짜·시간 조회

```sql
SELECT
    NOW()     AS 현재날짜시간,   -- 2026-04-17 14:30:00
    CURDATE() AS 오늘날짜,       -- 2026-04-17
    CURTIME() AS 현재시간;       -- 14:30:00
```

---

### 5-2. DATE_FORMAT — 날짜 형식 변환

**문법**: `DATE_FORMAT(날짜, '포맷문자열')`

#### 주요 포맷 코드

| 코드 | 의미 | 예시 |
|------|------|------|
| `%Y` | 4자리 연도 | 2026 |
| `%y` | 2자리 연도 | 26 |
| `%m` | 2자리 월 (01~12) | 04 |
| `%c` | 월 (1~12, 앞 0 없음) | 4 |
| `%d` | 2자리 일 (01~31) | 17 |
| `%e` | 일 (1~31, 앞 0 없음) | 17 |
| `%H` | 24시간 시 (00~23) | 14 |
| `%h` | 12시간 시 (01~12) | 02 |
| `%i` | 분 (00~59) | 30 |
| `%s` | 초 (00~59) | 00 |
| `%p` | AM/PM | PM |
| `%W` | 요일 (Monday...) | Friday |

```sql
SELECT
    joined_at,
    DATE_FORMAT(joined_at, '%Y년 %m월 %d일')  AS 한국형식,
    DATE_FORMAT(joined_at, '%Y-%m-%d')         AS ISO형식,
    DATE_FORMAT(joined_at, '%m/%d/%Y')         AS 미국형식
FROM customers;
```

---

### 5-3. DATEDIFF — 날짜 차이 (일 단위)

**문법**: `DATEDIFF(날짜1, 날짜2)` → 날짜1 - 날짜2 (일수)

```sql
SELECT
    name,
    joined_at,
    DATEDIFF(NOW(), joined_at) AS 가입후일수
FROM customers
ORDER BY 가입후일수 DESC;
```

> `DATEDIFF`는 **일(day) 단위**만 반환한다. 월·년 차이는 `TIMESTAMPDIFF` 사용.

---

### 5-4. DATE_ADD / DATE_SUB — 날짜 더하기/빼기

**문법**: `DATE_ADD(날짜, INTERVAL 값 단위)`

| 단위 키워드 | 의미 |
|------------|------|
| `DAY` | 일 |
| `WEEK` | 주 |
| `MONTH` | 월 |
| `YEAR` | 년 |
| `HOUR` | 시간 |
| `MINUTE` | 분 |

```sql
SELECT
    NOW()                               AS 현재,
    DATE_ADD(NOW(), INTERVAL 7 DAY)     AS 7일후,
    DATE_ADD(NOW(), INTERVAL 1 MONTH)   AS 1달후,
    DATE_SUB(NOW(), INTERVAL 1 MONTH)   AS 1달전,
    DATE_SUB(NOW(), INTERVAL 1 YEAR)    AS 1년전;
```

**실무 예시 — 최근 30일 내 가입 고객 조회:**

```sql
SELECT name, joined_at
FROM customers
WHERE joined_at >= DATE_SUB(NOW(), INTERVAL 30 DAY);
```

---

### 5-5. YEAR / MONTH / DAY — 날짜 구성요소 추출

```sql
SELECT
    joined_at,
    YEAR(joined_at)  AS 연도,
    MONTH(joined_at) AS 월,
    DAY(joined_at)   AS 일
FROM customers;
```

---

## 6. 조건 함수

### 6-1. IFNULL — NULL 대체

**문법**: `IFNULL(값, NULL일때_대체값)`

```sql
SELECT
    menu_name,
    IFNULL(menu_description, '설명 없음') AS 설명
FROM menus;
```

| menu_name | 설명 |
|-----------|------|
| 갈비탕 | 진한 사골 육수의 갈비탕 |
| 김치찌개 | 설명 없음 |

---

### 6-2. IF — 단순 조건 분기

**문법**: `IF(조건, 참일때_값, 거짓일때_값)`

엑셀 `=IF(조건, 참, 거짓)`과 완전히 동일하다!

| | 엑셀 | SQL |
|-|------|-----|
| 문법 | `=IF(A1>=10000, "고가", "저가")` | `IF(price>=10000, '고가', '저가')` |
| 차이 | 셀에 결과 표시 | SELECT 결과에 새 컬럼으로 추가 |

```sql
SELECT
    menu_name,
    price,
    IF(price >= 10000, '고가', '저가') AS 가격분류
FROM menus;
```

---

### 6-3. CASE WHEN — 다중 조건 분기

**문법**:
```sql
CASE
    WHEN 조건1 THEN 값1
    WHEN 조건2 THEN 값2
    ELSE 기본값
END
```

엑셀의 중첩 IF `=IF(A1>=15000,"고가",IF(A1>=8000,"중가","저가"))`와 동일하다. 단, CASE WHEN이 훨씬 읽기 쉽다.

**실무 예제 1 — 가격대 분류:**

```sql
SELECT
    menu_name,
    price,
    CASE
        WHEN price >= 15000 THEN '고가'
        WHEN price >= 8000  THEN '중가'
        ELSE                     '저가'
    END AS 가격대
FROM menus
ORDER BY price DESC;
```

| menu_name | price | 가격대 |
|-----------|-------|-------|
| 왕갈비 2인 세트 | 25000 | 고가 |
| 불고기 정식 | 12000 | 중가 |
| 단무지 | 2000 | 저가 |

**실무 예제 2 — 별점 등급 분류:**

```sql
SELECT
    name,
    rating,
    CASE
        WHEN rating >= 4.5 THEN '⭐⭐⭐ 최우수'
        WHEN rating >= 4.0 THEN '⭐⭐ 우수'
        WHEN rating >= 3.5 THEN '⭐ 보통'
        ELSE                    '개선 필요'
    END AS 등급
FROM restaurants
ORDER BY rating DESC;
```

> **주의**: CASE WHEN은 위에서 아래로 순서대로 체크하여 **처음으로 참인 조건**에 해당하는 값을 반환한다. 조건을 "큰 값부터" 작성해야 한다.

---

## 7. DISTINCT & AS

### 7-1. DISTINCT — 중복 제거

**문법**: `SELECT DISTINCT 컬럼명 FROM 테이블;`

```sql
-- 중복 포함: 한식, 한식, 치킨, 치킨, 치킨, 피자 ...
SELECT category FROM restaurants;

-- 중복 제거: 한식, 치킨, 피자, 중식, 분식
SELECT DISTINCT category FROM restaurants;
```

**주의사항**:
- DISTINCT는 NULL도 하나의 값으로 취급한다. NULL이 여러 개면 하나만 남는다.
- 여러 컬럼에 DISTINCT를 쓰면 **조합이 중복**될 때만 제거한다.

```sql
-- 카테고리가 같아도 가게 이름이 다르면 중복이 아님
SELECT DISTINCT category, name FROM restaurants;
```

---

### 7-2. AS — 별칭(Alias)

**문법**: `컬럼명 AS 별칭` (AS는 생략 가능하지만 쓰는 것이 명확)

**① 컬럼 별칭**
```sql
SELECT name AS 가게이름, rating AS 평점
FROM restaurants;
```

**② 계산식 별칭**
```sql
SELECT
    menu_name,
    price,
    ROUND(price * 1.1, 0) AS VAT포함가격
FROM menus;
```

**③ 함수 결과 별칭**
```sql
SELECT CONCAT(name, ' (', category, ')') AS 가게정보
FROM restaurants;
```

**AS 규칙**:
- 별칭에 한글, 공백이 포함되면 백틱(`` ` ``) 또는 따옴표(`"`)로 감싸는 것이 안전하다.
- `WHERE`절에서는 별칭을 사용할 수 없다. (`ORDER BY`에서는 사용 가능)

```sql
-- 잘못된 예: WHERE에서 별칭 사용 불가
SELECT ROUND(price * 1.1, 0) AS VAT포함가격 FROM menus WHERE VAT포함가격 > 10000;

-- 올바른 예
SELECT ROUND(price * 1.1, 0) AS VAT포함가격 FROM menus WHERE ROUND(price * 1.1, 0) > 10000;
```

---

## 8. SELECT 최종 문법 구조

오늘까지 배운 SELECT의 완성형이다.

```sql
SELECT 함수(컬럼) AS 별칭     -- ① 어떤 컬럼을, 어떻게 가공해서, 어떤 이름으로
FROM   테이블                 -- ② 어느 테이블에서
WHERE  조건                   -- ③ 어떤 조건의 행만
ORDER BY 기준 ASC/DESC        -- ④ 어떤 순서로
LIMIT  개수;                  -- ⑤ 몇 개만
```

> SQL은 **작성 순서**와 **실행 순서**가 다르다!
> 실행 순서: FROM → WHERE → SELECT → ORDER BY → LIMIT

**종합 예시:**
```sql
SELECT
    menu_name                                                  AS 메뉴명,
    price                                                      AS 가격,
    LPAD(id, 5, '0')                                           AS 메뉴번호,
    CASE
        WHEN price >= 15000 THEN '고가'
        WHEN price >= 8000  THEN '중가'
        ELSE                     '저가'
    END                                                        AS 가격대
FROM menus
WHERE price >= 5000
ORDER BY price DESC
LIMIT 10;
```

---

## 9. 함수 치트시트

### 문자열 함수

| 함수 | 설명 | 예시 | 결과 |
|------|------|------|------|
| `CONCAT(a, b, ...)` | 문자열 합치기 | `CONCAT('한', '입')` | `'한입'` |
| `SUBSTRING(s, pos, len)` | 부분 추출 | `SUBSTRING('한입배달', 1, 2)` | `'한입'` |
| `LENGTH(s)` | 바이트 수 | `LENGTH('안녕')` | `6` |
| `CHAR_LENGTH(s)` | 글자 수 | `CHAR_LENGTH('안녕')` | `2` |
| `TRIM(s)` | 양쪽 공백 제거 | `TRIM(' 안녕 ')` | `'안녕'` |
| `REPLACE(s, from, to)` | 치환 | `REPLACE('안녕', '녕', '식')` | `'안식'` |
| `LPAD(s, len, pad)` | 왼쪽 채우기 | `LPAD(1, 5, '0')` | `'00001'` |
| `UPPER(s)` | 대문자 변환 | `UPPER('hello')` | `'HELLO'` |
| `LOWER(s)` | 소문자 변환 | `LOWER('HELLO')` | `'hello'` |

### 숫자 함수

| 함수 | 설명 | 예시 | 결과 |
|------|------|------|------|
| `ROUND(n, d)` | 반올림 | `ROUND(4.567, 1)` | `4.6` |
| `CEIL(n)` | 올림 | `CEIL(4.1)` | `5` |
| `FLOOR(n)` | 내림 | `FLOOR(4.9)` | `4` |
| `MOD(n, m)` | 나머지 | `MOD(10, 3)` | `1` |
| `ABS(n)` | 절댓값 | `ABS(-5)` | `5` |
| `TRUNCATE(n, d)` | 버림 | `TRUNCATE(4.9, 0)` | `4` |

### 날짜 함수

| 함수 | 설명 | 예시 결과 |
|------|------|----------|
| `NOW()` | 현재 날짜+시간 | `2026-04-17 14:30:00` |
| `CURDATE()` | 오늘 날짜 | `2026-04-17` |
| `CURTIME()` | 현재 시간 | `14:30:00` |
| `DATE_FORMAT(d, fmt)` | 날짜 포맷 변환 | `'2026년 04월 17일'` |
| `DATEDIFF(d1, d2)` | 날짜 차이(일) | `30` |
| `DATE_ADD(d, INTERVAL n 단위)` | 날짜 더하기 | 7일 후 날짜 |
| `DATE_SUB(d, INTERVAL n 단위)` | 날짜 빼기 | 1달 전 날짜 |
| `YEAR(d)` / `MONTH(d)` / `DAY(d)` | 연/월/일 추출 | `2026` / `4` / `17` |

### 조건 함수

| 함수 | 설명 | 예시 |
|------|------|------|
| `IFNULL(v, alt)` | NULL이면 대체값 | `IFNULL(NULL, '없음')` → `'없음'` |
| `IF(cond, t, f)` | 조건 분기 | `IF(5>3, 'Y', 'N')` → `'Y'` |
| `CASE WHEN ... END` | 다중 조건 분기 | 가격대 분류, 등급 분류 |

---

## 10. 오늘의 핵심 정리 & 다음 시간 예고

### 오늘의 핵심

1. **함수 = 엑셀 함수의 SQL 버전** — 익숙한 개념, 문법만 다르다.
2. **한글은 CHAR_LENGTH!** — LENGTH는 바이트, 글자 수는 CHAR_LENGTH.
3. **CASE WHEN = 중첩 IF** — 조건은 위에서 아래로, 크기 순서 주의.
4. **SELECT 최종 형태**: `SELECT 함수(컬럼) AS 별칭 FROM 테이블 WHERE 조건 ORDER BY 정렬 LIMIT 개수`

### 다음 시간 예고 — Day 5: 집계 & GROUP BY

```
"이번 달 가게별 총 매출이 얼마야?"
"카테고리별로 메뉴가 몇 개야?"
```

오늘은 **행 하나씩** 가공했다면, Day 5에서는 **여러 행을 하나로 요약**하는 집계 함수(COUNT, SUM, AVG, MAX, MIN)와 GROUP BY를 배운다. 배달앱에서 가장 많이 쓰는 통계 분석이 여기서 시작된다.
