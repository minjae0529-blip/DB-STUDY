# Day 4 실습 문제 — 데이터 가공의 기술: 내장 함수

> **한입배달 DB**를 사용합니다. 문제를 풀기 전에 `USE hanip_delivery;`를 실행하세요.

---

## 문제 1. ⭐ 가게 정보 합치기

> 사장님이 앱 메인 화면에 "**가게명 (카테고리)**" 형태로 가게 목록을 보여주고 싶어 합니다.
> `restaurants` 테이블에서 이 형태로 가게 정보를 조회하세요.

**사용 함수**: `CONCAT`

**힌트**: `CONCAT(name, ' (', category, ')')`

**예상 결과**:

| 가게정보 |
|---------|
| 부산명가갈비 (한식) |
| 치킨킹 (치킨) |
| 해운대피자 (피자) |
| ... (총 10건) |

<details>
<summary>정답 보기</summary>

```sql
SELECT CONCAT(name, ' (', category, ')') AS 가게정보
FROM restaurants
ORDER BY name;
```

**포인트**:
- `CONCAT`은 인수가 3개 이상일 때 특히 유용하다.
- 구분자(' (', ')')를 문자열 리터럴로 직접 넣을 수 있다.
- 인수 중 하나라도 NULL이면 전체 결과가 NULL이 된다. (NULL-safe 처리: `CONCAT(IFNULL(name,''), ...)`)
</details>

---

## 문제 2. ⭐ 이름이 긴 메뉴 찾기

> 메뉴 이름이 **4글자 이상**인 메뉴를 `menus` 테이블에서 조회하세요.
> 메뉴명과 글자 수를 함께 출력하고, 글자 수 내림차순으로 정렬하세요.

**사용 함수**: `CHAR_LENGTH`

**힌트**: 한글 글자 수 조건은 `CHAR_LENGTH`를 사용해야 한다. `LENGTH`를 쓰면 안 되는 이유를 생각해보자.

**예상 결과**:

| menu_name | 글자수 |
|-----------|-------|
| 돼지불고기 덮밥 | 8 |
| 간장 반반치킨 | 7 |
| ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    menu_name,
    CHAR_LENGTH(menu_name) AS 글자수
FROM menus
WHERE CHAR_LENGTH(menu_name) >= 4
ORDER BY 글자수 DESC;
```

**포인트**:
- `LENGTH('갈비탕')` = **9** (3글자 × 3바이트)
- `CHAR_LENGTH('갈비탕')` = **3** (실제 글자 수)
- 글자 수 기준 조건은 반드시 `CHAR_LENGTH`를 사용해야 한다.
- `WHERE`절에서는 별칭(글자수)을 쓸 수 없으므로 `CHAR_LENGTH(menu_name)`을 다시 써야 한다.
</details>

---

## 문제 3. ⭐ 메뉴 번호 포맷팅

> 배달 앱에서 메뉴 ID를 **5자리 번호 형식** (예: 00001, 00023)으로 출력하고 싶습니다.
> `menus` 테이블에서 메뉴 번호(5자리)와 메뉴명을 조회하세요.

**사용 함수**: `LPAD`

**힌트**: `LPAD(id, 5, '0')`

**예상 결과**:

| 메뉴번호 | menu_name |
|---------|-----------|
| 00001 | 갈비탕 |
| 00002 | 돼지불고기 |
| 00003 | 된장찌개 |
| ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    LPAD(id, 5, '0') AS 메뉴번호,
    menu_name
FROM menus
ORDER BY id;
```

**포인트**:
- `LPAD(컬럼, 총자릿수, 채울문자)` — 총 5자리가 되도록 왼쪽을 '0'으로 채운다.
- `id`가 정수(INT)여도 `LPAD`가 문자열로 자동 변환하여 처리한다.
- 실무에서 주문번호, 사원번호 포맷팅에 자주 사용된다.
</details>

---

## 문제 4. ⭐⭐ 부가세 제외 가격 계산

> 재무팀에서 각 메뉴의 **부가세(10%) 제외 가격**을 알고 싶어 합니다.
> 현재 `price`는 부가세 포함 가격입니다. `price / 1.1`로 부가세를 제외한 뒤,
> `ROUND`를 사용하여 **원 단위(소수점 없음)**로 계산하세요.
> 메뉴명, 원가(부가세 포함), 부가세 제외 가격을 함께 출력하세요.

**사용 함수**: `ROUND`

**힌트**: `ROUND(price / 1.1, 0)`

**예상 결과**:

| menu_name | 원가 | 부가세제외가격 |
|-----------|------|-------------|
| 갈비탕 | 9000 | 8182 |
| 돼지불고기 | 8000 | 7273 |
| ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    menu_name,
    price                       AS 원가,
    ROUND(price / 1.1, 0)       AS 부가세제외가격
FROM menus
ORDER BY price DESC;
```

**포인트**:
- `ROUND(값, 0)`은 소수점 첫 번째 자리에서 반올림하여 정수를 반환한다.
- 회계 처리 시 반올림 방식(ROUND vs TRUNCATE vs FLOOR)을 사전에 정해두어야 한다.
- `TRUNCATE(price / 1.1, 0)`을 쓰면 반올림 없이 소수점을 그냥 버린다.

**비교:**
```sql
SELECT
    9000 / 1.1                   AS 나누기결과,    -- 8181.818...
    ROUND(9000 / 1.1, 0)         AS ROUND결과,    -- 8182
    FLOOR(9000 / 1.1)            AS FLOOR결과,    -- 8181
    TRUNCATE(9000 / 1.1, 0)      AS TRUNCATE결과; -- 8181
```
</details>

---

## 문제 5. ⭐⭐ 고객 가입일 포맷 변환

> 마케팅팀에서 고객 가입일을 **'2026년 01월 15일'** 형태로 출력해달라고 요청했습니다.
> `customers` 테이블에서 고객명, 포맷된 가입일, 가입 후 며칠이 지났는지를 함께 조회하세요.
> 가입일이 최근인 순서로 정렬하세요.

**사용 함수**: `DATE_FORMAT`, `DATEDIFF`

**힌트**:
- `DATE_FORMAT(joined_at, '%Y년 %m월 %d일')`
- `DATEDIFF(NOW(), joined_at)`

**예상 결과**:

| name | 가입일 | 가입후일수 |
|------|-------|----------|
| 이수연 | 2026년 03월 20일 | 28 |
| 박지훈 | 2026년 02월 10일 | 66 |
| ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    name,
    DATE_FORMAT(joined_at, '%Y년 %m월 %d일') AS 가입일,
    DATEDIFF(NOW(), joined_at)               AS 가입후일수
FROM customers
ORDER BY joined_at DESC;
```

**포인트**:
- `%m`은 2자리 월(01~12)을 반환한다. 앞 0을 원하지 않으면 `%c` 사용.
- `DATEDIFF(A, B)` = A - B(일수). 기준 날짜가 첫 번째 인수다.
- 가입 기간에 따른 등급 분류는 `CASE WHEN`과 조합 가능.
</details>

---

## 문제 6. ⭐⭐ 메뉴 가격대 분류

> 사장님이 메뉴를 가격 기준으로 분류하고 싶어 합니다.
> - **고가**: 15,000원 이상
> - **중가**: 8,000원 이상 ~ 15,000원 미만
> - **저가**: 8,000원 미만
>
> `menus` 테이블에서 메뉴명, 가격, 가격대 분류를 조회하고 가격 내림차순으로 정렬하세요.

**사용 함수**: `CASE WHEN`

**힌트**: 조건은 큰 값부터 작성해야 한다. `CASE WHEN price >= 15000 THEN ... WHEN price >= 8000 THEN ... ELSE ...`

**예상 결과**:

| menu_name | price | 가격대 |
|-----------|-------|-------|
| 왕갈비 2인 세트 | 25000 | 고가 |
| 불고기 정식 | 12000 | 중가 |
| 단무지 | 2000 | 저가 |
| ... |

<details>
<summary>정답 보기</summary>

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

**포인트**:
- `CASE WHEN`은 위에서 아래로 순서대로 체크하여 **처음으로 참인 조건**을 적용한다.
- 조건을 `price >= 8000` 부터 쓰면 15000원짜리도 '중가'가 되어버린다 — 반드시 큰 값부터!
- `ELSE`를 생략하면 해당하는 조건이 없을 때 NULL이 반환된다.

**자주 하는 실수:**
```sql
-- 잘못된 예: 조건 순서가 바뀌면 결과가 달라진다
CASE
    WHEN price >= 8000  THEN '중가'   -- 15000원도 여기서 걸림!
    WHEN price >= 15000 THEN '고가'   -- 이 조건은 절대 실행 안 됨
    ELSE '저가'
END
```
</details>

---

## 문제 7. ⭐⭐⭐ IFNULL + CONCAT 조합

> 앱 상세 페이지에서 메뉴 정보를 **"메뉴명: 설명"** 형태로 출력하려 합니다.
> `menu_description`이 NULL인 경우에는 **"설명없음"**으로 대체하여 출력하세요.
>
> 출력 형식: `갈비탕: 진한 사골 육수의 갈비탕` 또는 `김치찌개: 설명없음`

**사용 함수**: `IFNULL`, `CONCAT`

**힌트**: `CONCAT(menu_name, ': ', IFNULL(menu_description, '설명없음'))`

**예상 결과**:

| 메뉴소개 |
|---------|
| 갈비탕: 진한 사골 육수의 갈비탕 |
| 김치찌개: 설명없음 |
| 돼지불고기: 국내산 돼지고기를 사용한 불고기 |
| ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    CONCAT(
        menu_name,
        ': ',
        IFNULL(menu_description, '설명없음')
    ) AS 메뉴소개
FROM menus
ORDER BY menu_name;
```

**포인트**:
- `CONCAT` 안에 `IFNULL`을 중첩하면 NULL을 처리한 값을 합칠 수 있다.
- `CONCAT(menu_name, ': ', menu_description)`만 쓰면 `menu_description`이 NULL인 경우 **전체 결과가 NULL**이 된다.
- 함수는 중첩(nested)해서 사용할 수 있다. 안쪽 함수가 먼저 실행된다.

**NULL 처리 확인:**
```sql
-- 차이를 직접 비교해보자
SELECT
    menu_name,
    menu_description,
    CONCAT(menu_name, ': ', menu_description)                    AS NULL처리전,
    CONCAT(menu_name, ': ', IFNULL(menu_description, '설명없음')) AS NULL처리후
FROM menus
WHERE menu_description IS NULL
LIMIT 5;
```
</details>

---

## 문제 8. ⭐⭐⭐ 함수 종합 — 가게 소개 포맷 만들기

> 앱 리스트 화면에서 각 가게를 다음 형식으로 출력하고 싶습니다.
>
> **출력 형식**: `★★★ 부산명가갈비 (한식) — 평점: 4.5점`
>
> - 평점 기준 별 아이콘: 4.5 이상 `★★★`, 4.0 이상 `★★`, 나머지 `★`
> - 평점은 소수점 1자리까지 출력 (예: 4.5점)
> - 별점 높은 순서로 정렬하세요.

**사용 함수**: `CASE WHEN`, `CONCAT`, `ROUND`

**힌트**:
1. 먼저 `CASE WHEN`으로 별 아이콘을 만든다.
2. 그 결과를 `CONCAT`으로 나머지 텍스트와 합친다.
3. `ROUND(rating, 1)`로 소수점 1자리를 유지한다.

**예상 결과**:

| 가게소개 |
|---------|
| ★★★ 부산명가갈비 (한식) — 평점: 4.8점 |
| ★★★ 해운대피자 (피자) — 평점: 4.6점 |
| ★★ 치킨킹 (치킨) — 평점: 4.2점 |
| ★ 분식왕 (분식) — 평점: 3.7점 |
| ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT
    CONCAT(
        CASE
            WHEN rating >= 4.5 THEN '★★★ '
            WHEN rating >= 4.0 THEN '★★ '
            ELSE                    '★ '
        END,
        name,
        ' (',
        category,
        ') — 평점: ',
        ROUND(rating, 1),
        '점'
    ) AS 가게소개
FROM restaurants
ORDER BY rating DESC;
```

**포인트**:
- `CONCAT` 안에 `CASE WHEN`을 통째로 넣는 것이 핵심이다.
- `CASE WHEN ... END`의 결과(문자열)가 `CONCAT`의 첫 번째 인수로 들어간다.
- `ROUND(rating, 1)` — 4.8을 그대로 유지. `ROUND(rating, 0)`이면 5가 되어버린다.
- 숫자(`ROUND(rating, 1)`)를 `CONCAT`에 넣으면 MySQL이 자동으로 문자열로 변환한다.

**단계별로 분해해서 이해하기:**
```sql
-- 1단계: 별 아이콘만
SELECT name, CASE WHEN rating >= 4.5 THEN '★★★' WHEN rating >= 4.0 THEN '★★' ELSE '★' END AS 별
FROM restaurants;

-- 2단계: 가게정보 합치기
SELECT CONCAT(name, ' (', category, ')') AS 가게정보
FROM restaurants;

-- 3단계: 두 가지를 조합
SELECT
    CONCAT(
        CASE WHEN rating >= 4.5 THEN '★★★ ' WHEN rating >= 4.0 THEN '★★ ' ELSE '★ ' END,
        name, ' (', category, ') — 평점: ', ROUND(rating, 1), '점'
    ) AS 가게소개
FROM restaurants
ORDER BY rating DESC;
```
</details>

---

## 보너스. 오늘 배운 함수 확인하기

아래 쿼리를 실행하여 오늘 배운 함수들이 어떻게 동작하는지 한눈에 확인해보자.

```sql
-- 문자열 함수 종합
SELECT
    '한입배달'                           AS 원문,
    LENGTH('한입배달')                   AS 바이트수,
    CHAR_LENGTH('한입배달')              AS 글자수,
    CONCAT('[', '한입배달', ']')         AS 괄호추가,
    SUBSTRING('한입배달', 1, 2)          AS 앞2글자,
    LPAD(7, 3, '0')                      AS 번호포맷,
    REPLACE('한입배달', '배달', '딜리버리') AS 치환;

-- 숫자 함수 종합
SELECT
    4567                AS 원래값,
    ROUND(4567, -2)     AS 백단위반올림,   -- 4600
    CEIL(4567 / 1000)   AS 올림,          -- 5
    FLOOR(4567 / 1000)  AS 내림,          -- 4
    MOD(4567, 1000)     AS 나머지,        -- 567
    ABS(-4567)          AS 절댓값;        -- 4567

-- 날짜 함수 종합
SELECT
    NOW()                                         AS 현재,
    DATE_FORMAT(NOW(), '%Y년 %m월 %d일')           AS 포맷날짜,
    DATEDIFF('2026-12-31', '2026-04-17')          AS 연말까지일수,
    DATE_ADD('2026-04-17', INTERVAL 100 DAY)      AS 100일후;
```
