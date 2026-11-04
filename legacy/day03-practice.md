# Day 3 실습 문제 — CRUD

> MySQL 10일 완성 과정 | 한입배달 DB | Day 3

---

## 실습 전 확인사항

- `USE hanip_delivery;` 를 먼저 실행했는지 확인하세요.
- restaurants 10건, customers 10건, menus 30건이 들어 있어야 합니다.
- 모르는 문법은 `day03-handout.md`를 참고하세요.

---

## 문제 1. ⭐ 새 가게 3건 INSERT

> 사장님이 "우리 앱에 파트너 가게 3곳을 새로 등록해달라고요" 라고 합니다.  
> 아래 정보를 `restaurants` 테이블에 한 번의 INSERT 문으로 넣어보세요.

| name | category | address | rating |
|------|----------|---------|--------|
| 할매순대국 | 한식 | 부산시 동래구 온천동 | 4.2 |
| 화덕피자헛 | 피자 | 부산시 수영구 광안동 | 3.9 |
| 마늘치킨공화국 | 치킨 | 부산시 해운대구 좌동 | 4.6 |

**힌트:** 다건 INSERT 문을 사용하고, `id`는 AUTO_INCREMENT이므로 컬럼 목록에서 생략하세요.

**예상 결과:** INSERT 성공 후 `SELECT * FROM restaurants;` 실행 시 총 13행 조회됨.

<details>
<summary>정답 보기</summary>

```sql
INSERT INTO restaurants (name, category, address, rating)
VALUES
    ('할매순대국',     '한식', '부산시 동래구 온천동',    4.2),
    ('화덕피자헛',     '피자', '부산시 수영구 광안동',    3.9),
    ('마늘치킨공화국', '치킨', '부산시 해운대구 좌동',    4.6);
```

**핵심 포인트:**
- `id` 컬럼은 AUTO_INCREMENT이므로 컬럼 목록과 VALUES에서 모두 제외합니다.
- 다건 INSERT는 VALUES 뒤에 쉼표(`,`)로 구분해서 한 번에 씁니다.
- 문자열은 반드시 `'작은따옴표'`로 감쌉니다.

</details>

---

## 문제 2. ⭐ 전체 메뉴 조회

> 사장님이 "현재 앱에 등록된 메뉴가 뭐뭐 있는지 전부 보고 싶어요" 라고 합니다.  
> `menus` 테이블의 모든 컬럼, 모든 행을 조회하세요.

**힌트:** `SELECT *` 사용.

**예상 결과:** 30행 이상 (Day 3 실습 중 추가 데이터가 있을 수 있음)

| id | restaurant_id | menu_name | price | description | is_available |
|----|--------------|-----------|-------|-------------|--------------|
| 1  | 1            | (메뉴명) | ...   | ...         | ...          |
| ...| ...          | ...       | ...   | ...         | ...          |

<details>
<summary>정답 보기</summary>

```sql
SELECT * FROM menus;
```

**핵심 포인트:**
- `SELECT *`는 모든 컬럼을 가져옵니다.
- 개발/확인 목적으로는 편리하지만, 실무에서는 필요한 컬럼만 명시하는 것이 좋습니다.
- 세미콜론(`;`)을 빠뜨리지 마세요.

</details>

---

## 문제 3. ⭐ 카테고리 필터링

> 사장님이 "우리 앱에서 치킨 가게만 따로 보고 싶어요" 라고 합니다.  
> `restaurants` 테이블에서 `category`가 `'치킨'`인 가게의 `name`, `address`, `rating`만 조회하세요.

**힌트:** `WHERE 컬럼 = '값'` 사용.

**예상 결과:** 치킨 카테고리 가게만 조회 (Day 2 더미 데이터 기준 2~3행)

| name | address | rating |
|------|---------|--------|
| (치킨 가게명) | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT name, address, rating
FROM restaurants
WHERE category = '치킨';
```

**핵심 포인트:**
- `SELECT *` 대신 필요한 컬럼명을 명시했습니다.
- 문자열 비교 시 `=` 연산자와 `'작은따옴표'`를 사용합니다.
- 대소문자는 MySQL 기본 설정에서 구분하지 않지만, 정확히 입력하는 습관을 들이세요.

</details>

---

## 문제 4. ⭐⭐ 가격 범위 필터링 (BETWEEN)

> 사장님이 "배달 앱에서 '1만원 이상 2만원 이하' 메뉴를 보여주는 필터를 만들려고 해요.  
> 해당 가격 범위의 메뉴 이름과 가격을 조회하고, 가격 오름차순으로 정렬해 주세요" 라고 합니다.

**힌트:** `BETWEEN a AND b`, `ORDER BY 컬럼 ASC`

**예상 결과 (샘플):**

| menu_name | price |
|-----------|-------|
| (메뉴명) | 10000 |
| (메뉴명) | 12000 |
| ... | ... |
| (메뉴명) | 20000 |

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price
FROM menus
WHERE price BETWEEN 10000 AND 20000
ORDER BY price ASC;
```

**핵심 포인트:**
- `BETWEEN 10000 AND 20000`은 10000 이상, 20000 이하를 의미합니다 (경계값 포함).
- 이는 `WHERE price >= 10000 AND price <= 20000`과 동일합니다.
- `ORDER BY price ASC`에서 `ASC`는 기본값이므로 생략해도 됩니다.
- `BETWEEN`에서 작은 값을 먼저 씁니다. `BETWEEN 20000 AND 10000`은 결과가 없습니다.

</details>

---

## 문제 5. ⭐⭐ 메뉴명 부분 검색 (LIKE)

> 사장님이 "고객들이 '김치' 관련 메뉴를 자주 검색해요. 앱에서 검색 기능을 만들려는데,  
> 메뉴명에 '김치'가 들어가는 메뉴를 전부 뽑아주세요" 라고 합니다.  
> `menu_name`과 `price`를 조회하세요.

**힌트:** `WHERE menu_name LIKE '%패턴%'`

**예상 결과 (샘플):**

| menu_name | price |
|-----------|-------|
| 김치찌개 정식 | 8500 |
| 묵은지김치찜 | (가격) |
| ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT menu_name, price
FROM menus
WHERE menu_name LIKE '%김치%';
```

**핵심 포인트:**
- `%김치%`는 '김치' 앞뒤에 어떤 문자든 올 수 있다는 의미입니다.
- `김치%` → 김치로 시작하는 것만 (김치찌개 O, 묵은지김치찜 X)
- `%김치` → 김치로 끝나는 것만
- `%김치%` → 어디든 김치가 들어있으면 모두 해당
- LIKE는 대소문자를 구분하지 않는 것이 MySQL 기본 설정입니다.

</details>

---

## 문제 6. ⭐⭐ 평점 TOP 5 가게 조회 (ORDER BY + LIMIT)

> 사장님이 "앱 메인 화면에 '인기 가게 TOP 5'를 보여주고 싶어요.  
> 평점이 높은 순서로 가게 이름, 카테고리, 평점을 5개만 조회해 주세요" 라고 합니다.

**힌트:** `ORDER BY 컬럼 DESC`, `LIMIT n`

**예상 결과:** 정확히 5행, 첫 번째 행이 가장 높은 평점

| name | category | rating |
|------|----------|--------|
| (1위 가게) | ... | 4.8 |
| (2위 가게) | ... | 4.6 |
| ... | ... | ... |

<details>
<summary>정답 보기</summary>

```sql
SELECT name, category, rating
FROM restaurants
ORDER BY rating DESC
LIMIT 5;
```

**핵심 포인트:**
- `ORDER BY rating DESC` — 평점 내림차순 (높은 것부터)
- `LIMIT 5` — 상위 5개만
- `ORDER BY`와 `LIMIT`은 항상 이 순서로 씁니다 (`LIMIT`이 마지막).
- `ORDER BY` 없이 `LIMIT`만 쓰면 결과 순서가 보장되지 않습니다.

</details>

---

## 문제 7. ⭐⭐⭐ 가격 10% 인상 UPDATE

> 사장님이 "1번 가게 사장님이 식재료값이 올랐다며 자기 가게 메뉴 가격을 전부 10% 올려달라고 했어요.  
> 처리해 주세요" 라고 합니다.  
> `restaurant_id`가 1인 모든 메뉴의 `price`를 10% 인상하세요.  
> UPDATE 전후로 해당 메뉴를 조회해서 가격이 바뀐 것을 확인하세요.

**힌트:** `UPDATE ... SET price = price * 1.1 WHERE ...`

**예상 결과:** `restaurant_id = 1`인 메뉴의 price가 1.1배로 변경됨

<details>
<summary>정답 보기</summary>

```sql
-- 1단계: 변경 전 확인
SELECT menu_name, price FROM menus WHERE restaurant_id = 1;

-- 2단계: 가격 10% 인상
UPDATE menus
SET price = price * 1.1
WHERE restaurant_id = 1;

-- 3단계: 변경 후 확인
SELECT menu_name, price FROM menus WHERE restaurant_id = 1;
```

**핵심 포인트:**
- `price = price * 1.1` — 현재 가격에 1.1을 곱해 10% 인상합니다.
- `WHERE restaurant_id = 1` — **반드시 WHERE로 대상을 특정해야 합니다!**

⚠️ **경고 — 핵버튼 시나리오:**
```sql
-- 절대 하지 말 것! WHERE가 없으면 모든 메뉴 가격이 10% 오릅니다.
UPDATE menus SET price = price * 1.1;
```
WHERE 없는 UPDATE는 취소가 어렵습니다 (트랜잭션이 없다면 복구 불가).  
UPDATE를 실행하기 전에는 항상 `SELECT`로 대상 행을 먼저 확인하는 습관을 들이세요.

**보너스:** 가격을 정수로 반올림하고 싶다면:
```sql
UPDATE menus
SET price = ROUND(price * 1.1)
WHERE restaurant_id = 1;
```

</details>

---

## 문제 8. ⭐⭐⭐ 비활성 메뉴 조회 후 삭제

> 사장님이 "판매 중지된 메뉴(is_available = FALSE)는 앱에 안 보이게 아예 삭제해 주세요.  
> 근데 혹시 모르니 먼저 어떤 메뉴인지 확인하고 삭제해 주세요" 라고 합니다.  
> 2단계로 처리하세요: ① 비활성 메뉴 조회 → ② 비활성 메뉴 삭제 → ③ 삭제 후 재확인

**힌트:** `WHERE is_available = FALSE`, `DELETE FROM`

**예상 결과:**
- 삭제 전: `is_available = FALSE`인 행이 조회됨 (Day 3 실습에서 몇 건 추가됨)
- 삭제 후: 동일 SELECT 결과가 0행

<details>
<summary>정답 보기</summary>

```sql
-- 1단계: 삭제 대상 확인 (항상 먼저 SELECT로 확인!)
SELECT id, menu_name, price, is_available
FROM menus
WHERE is_available = FALSE;

-- 2단계: 비활성 메뉴 삭제
DELETE FROM menus
WHERE is_available = FALSE;

-- 3단계: 삭제 후 재확인 (0행이어야 함)
SELECT id, menu_name, price, is_available
FROM menus
WHERE is_available = FALSE;
```

**핵심 포인트:**
- `DELETE FROM` 전에 **반드시 같은 WHERE 조건으로 SELECT를 먼저 실행**해서 대상을 확인합니다.
- `WHERE is_available = FALSE` — 이 WHERE가 없으면 전체 메뉴가 삭제됩니다!

⚠️ **경고 — 최악의 핵버튼:**
```sql
-- 절대 하지 말 것! 모든 메뉴 데이터가 삭제됩니다.
DELETE FROM menus;
```
DELETE는 ROLLBACK이 없는 환경에서는 **복구 불가**입니다.  
반드시 ①SELECT로 확인 → ②DELETE 실행 순서를 지키세요.

**TRUNCATE와 차이:**
```sql
-- 이것도 전체 삭제지만 더 빠르고 AUTO_INCREMENT까지 초기화됨
TRUNCATE TABLE menus;  -- 운영 DB에서는 절대 사용 금지!
```

</details>

---

## 도전 과제 (선택)

Day 3 내용을 모두 마쳤다면 아래 쿼리도 작성해 보세요.

**도전 1:** `restaurants` 테이블에서 주소에 '해운대'가 들어가는 가게의 이름과 카테고리를 조회하세요.

**도전 2:** `menus` 테이블에서 `description`이 NULL인 메뉴의 `menu_name`과 `price`를 가격 내림차순으로 조회하세요.

**도전 3:** `menus` 테이블에서 가격이 10000원 미만이거나 20000원 초과인 메뉴를 조회하세요.  
(힌트: OR 조건 또는 NOT BETWEEN 사용)

**도전 4:** 방금 INSERT한 3개 가게 중 평점이 4.0 이상인 가게만 조회하세요.  
(힌트: id 조건 또는 name IN ('가게1', '가게2', '가게3') 활용)
