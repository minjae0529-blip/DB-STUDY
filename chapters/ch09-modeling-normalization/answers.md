# Ch09 실습 — 정규화 집중 훈련 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery09;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> 정규화 **전** 시트는 `ex_`로 시작합니다. 여러분이 나눠서 만드는 테이블은 `p_`로 시작합니다.
> **문제를 순서대로 푸세요.** 5번은 3·4번의 판단을, 9번은 8번에서 만든 테이블을 씁니다.
> 다시 처음부터 하고 싶으면 `setup.sql` 위쪽의 `DROP DATABASE` 주석을 풀고 다시 실행하면 됩니다.

| 문제 | 정규형 | 시트 | 하는 일 |
|---|---|---|---|
| 1 · 2 | 1NF | `ex_rider_sheet`, `ex_review_sheet` | 한 칸의 여러 값 / 반복 열을 행으로 펴기 |
| 3 · 4 · 5 | 2NF | `ex_coupon_sheet` | 함수 종속 검증 → 후보키 찾기 → 부분 종속 분해 |
| 6 · 7 | 3NF | `ex_menu_sheet` | 이상 현상 찾기 → 이행 종속 분해 |
| 8 · 9 | BCNF | `ex_inspection_sheet` | 결정자 분해 → 무손실 vs 가짜 튜플 |
| 10 | 판정 | (종이 문제) | 정규형 판정 5문항 — 정보처리기사 유형 |
| 11 | 종합 | `ex_event_sheet` | 비정규형 시트 하나를 끝까지 정규화 |

마지막 **팀 과제**는 정답 SQL이 없는 설계 과제입니다.

---

### 문제 1. 한 칸에 구역 여러 개 — 1NF ★

> **배차팀** `ex_rider_sheet`의 `zones` 칸에 담당 구역이 `'서면, 전포, 범천'`처럼 몰려 있어서 "서면 담당 기사가 누구지?"에 답하기 어렵습니다.
> 기사 · 구역 한 쌍이 한 행인 **`p_rider_zones`** (`rider_name`, `zone`, PK는 두 열 조합)를 만들고, **기사가 2명 이상인 구역**을 보여 주세요.
> 힌트: 수업 5-1절. 한 기사의 구역은 최대 5개입니다.

- 열: `zone`, `rider_count`, `riders` (기사 이름을 가나다순으로 `', '`로 이어 붙임)
- 순서: `zone`

**정답 SQL**

```sql
CREATE TABLE p_rider_zones AS
SELECT r.rider_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(r.zones, ', ', seq.n), ', ', -1) AS zone
FROM ex_rider_sheet r
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5) seq
  ON seq.n <= (CHAR_LENGTH(r.zones) - CHAR_LENGTH(REPLACE(r.zones, ', ', ''))) / 2 + 1;

ALTER TABLE p_rider_zones ADD CONSTRAINT pk_p_rider_zones PRIMARY KEY (rider_name, zone);

SELECT zone, COUNT(*) AS rider_count,
    GROUP_CONCAT(rider_name ORDER BY rider_name SEPARATOR ', ') AS riders
FROM p_rider_zones
GROUP BY zone
HAVING COUNT(*) >= 2
ORDER BY zone;
```

<sub>▶ 실행 결과 · 5행</sub>

| zone | rider_count | riders |
|---|---|---|
| 대연 | 2 | 민경수, 엄소희 |
| 범천 | 2 | 배성진, 하민호 |
| 서면 | 2 | 노지환, 배성진 |
| 전포 | 2 | 배성진, 하민호 |
| 해운대 | 2 | 곽태호, 전유나 |


> **해설** `p_rider_zones`는 24행입니다. 한 칸에 값이 하나씩 들어가자 `WHERE zone = '서면'`, `GROUP BY zone`이 바로 됩니다. 원래 시트에서 `WHERE zones LIKE '%서면%'`으로 찾으면 `'서면'`과 `'서면역'` 같은 구역을 구별하지 못합니다. 원래 시트의 `phone`은 기사에게만 종속되므로 새 테이블로 옮기지 않습니다 — 펴는 열만 옮기고 나머지는 원래 주인(기사 테이블)에 둡니다.

### 문제 2. 사진 1 · 사진 2 · 사진 3 — 반복 열과 1NF ★

> **리뷰팀** 구 앱의 `ex_review_sheet`는 사진을 `photo1`~`photo3` 열에 저장했습니다. "사진 4장"을 허용하려면 열을 또 추가해야 합니다.
> 사진 한 장이 한 행인 **`p_review_photos`** (`review_id`, `sort_order`, `photo_url`, PK는 `review_id` + `sort_order`)를 만들고, **리뷰별 사진 수**를 보여 주세요. 사진이 없는 리뷰도 0으로 나와야 합니다.
> `sort_order`는 원래 열 번호(1, 2, 3)를 그대로 씁니다.

- 열: `review_id`, `customer_name`, `photo_count`
- 순서: `review_id`

**정답 SQL**

```sql
CREATE TABLE p_review_photos AS
SELECT review_id, 1 AS sort_order, photo1 AS photo_url FROM ex_review_sheet WHERE photo1 IS NOT NULL
UNION ALL
SELECT review_id, 2, photo2 FROM ex_review_sheet WHERE photo2 IS NOT NULL
UNION ALL
SELECT review_id, 3, photo3 FROM ex_review_sheet WHERE photo3 IS NOT NULL;

ALTER TABLE p_review_photos ADD CONSTRAINT pk_p_review_photos PRIMARY KEY (review_id, sort_order);

SELECT r.review_id, r.customer_name, COUNT(p.photo_url) AS photo_count
FROM ex_review_sheet r
LEFT JOIN p_review_photos p ON r.review_id = p.review_id
GROUP BY r.review_id, r.customer_name
ORDER BY r.review_id;
```

<sub>▶ 실행 결과 · 8행</sub>

| review_id | customer_name | photo_count |
|---|---|---|
| 801 | 김민준 | 3 |
| 802 | 이서연 | 1 |
| 803 | 박지훈 | 0 |
| 804 | 최수아 | 2 |
| 805 | 정우진 | 1 |
| 806 | 강하은 | 3 |
| 807 | 조현우 | 0 |
| 808 | 윤지아 | 2 |


> **해설** 반복 열(`photo1`, `photo2`, …)은 "한 칸에 값 여러 개"를 옆으로 펼친 것일 뿐, 같은 1NF 위반입니다. `UNION ALL`로 열 하나씩 세로로 쌓으면 됩니다(언피벗). 805번 리뷰는 `photo1` 없이 `photo2`만 있어 `sort_order`가 2부터 시작합니다 — 반복 열 구조에서는 이런 **빈칸**이 흔합니다. 행 구조에서는 사진을 몇 장이든 저장할 수 있고, 장수 제한(예: 5장)은 7절처럼 `CHECK (sort_order BETWEEN 1 AND 5)`로 겁니다. `COUNT(*)`가 아니라 `COUNT(p.photo_url)`이어야 사진 없는 리뷰가 0이 됩니다.

### 문제 3. 함수 종속 검증 ★★

> **마케팅팀** `ex_coupon_sheet`(쿠폰 사용 장부)에 대해 팀원들이 세 가지를 주장합니다. 각각 **위반하는 결정자 값의 개수**를 구해 참 · 거짓을 판정하세요. (0이면 지금 데이터에서는 성립)
> ① `coupon_code → discount_amount` ② `customer_phone → customer_name` ③ `coupon_name → discount_amount`

- 열: `code_to_discount`, `phone_to_name`, `name_to_discount`

**정답 SQL**

```sql
SELECT
    (SELECT COUNT(*) FROM (SELECT coupon_code FROM ex_coupon_sheet GROUP BY coupon_code
                           HAVING COUNT(DISTINCT discount_amount) > 1) t) AS code_to_discount,
    (SELECT COUNT(*) FROM (SELECT customer_phone FROM ex_coupon_sheet GROUP BY customer_phone
                           HAVING COUNT(DISTINCT customer_name) > 1) t) AS phone_to_name,
    (SELECT COUNT(*) FROM (SELECT coupon_name FROM ex_coupon_sheet GROUP BY coupon_name
                           HAVING COUNT(DISTINCT discount_amount) > 1) t) AS name_to_discount;
```

<sub>▶ 실행 결과 · 1행</sub>

| code_to_discount | phone_to_name | name_to_discount |
|---|---|---|
| 0 | 0 | 1 |


> **해설** ①②는 성립, ③은 거짓입니다. `'첫 주문 할인'`이라는 이름의 쿠폰이 3,000원(`HELLO3K`)과 5,000원(`HELLO5K`) 두 가지라서 **이름으로는 쿠폰을 구별할 수 없습니다.** 그래서 쿠폰 테이블의 키는 이름이 아니라 코드여야 합니다. 함수 종속은 데이터로 **반례를 찾을 수는** 있지만, 0이 나왔다고 규칙이 증명되지는 않습니다. ①이 진짜 규칙인지는 마케팅팀에 "같은 코드인데 할인액이 바뀔 수 있나요?"라고 물어서 확정합니다.

### 문제 4. 후보키 찾기 ★★

> **데이터팀** `ex_coupon_sheet`에는 PK가 없습니다. 업무 규칙은 "**한 고객은 같은 쿠폰을 한 번만 쓴다**"입니다. 아래 조합마다 `COUNT(DISTINCT …)`를 구해 전체 행 수와 비교하세요.
> `coupon_code` / `customer_phone` / (`coupon_code`, `customer_phone`) / (`customer_phone`, `used_at`)

- 열: `total_rows`, `by_code`, `by_phone`, `by_code_phone`, `by_phone_used_at`

**정답 SQL**

```sql
SELECT COUNT(*) AS total_rows,
    COUNT(DISTINCT coupon_code)               AS by_code,
    COUNT(DISTINCT customer_phone)            AS by_phone,
    COUNT(DISTINCT coupon_code, customer_phone) AS by_code_phone,
    COUNT(DISTINCT customer_phone, used_at)   AS by_phone_used_at
FROM ex_coupon_sheet;
```

<sub>▶ 실행 결과 · 1행</sub>

| total_rows | by_code | by_phone | by_code_phone | by_phone_used_at |
|---|---|---|---|---|
| 15 | 5 | 10 | 15 | 15 |


> **해설** 행 수(15)와 같은 조합이 후보키 **후보**입니다. (`coupon_code`, `customer_phone`)는 업무 규칙과도 맞으므로 후보키입니다. (`customer_phone`, `used_at`)도 지금은 15로 유일하지만 **우연**입니다. 한 사람이 같은 시각에 쿠폰 두 장을 쓰는 것을 막는 규칙은 없습니다. 후보키는 데이터가 아니라 **규칙**이 정합니다. 단일 열은 둘 다 15보다 작으므로 어느 것도 혼자서는 키가 아닙니다 → 키가 두 열 조합이라는 뜻이고, 이것이 **2NF 위반이 생길 수 있는 조건**입니다(문제 5).

### 문제 5. 부분 종속 제거 — 2NF ★★

> **데이터팀** 키 (`coupon_code`, `customer_phone`)의 **일부에만** 종속된 열을 떼어 내세요.
> - `p_coupons` (`coupon_code` PK, `coupon_name`, `discount_amount`)
> - `p_coupon_customers` (`customer_phone` PK, `customer_name`)
> - `p_coupon_uses` (`coupon_code`, `customer_phone`, `used_at`) — PK는 두 열 조합, 두 열 각각 위 테이블을 참조하는 FK
>
> 세 테이블의 행 수를 확인하세요.

- 열: `coupons_rows`, `customers_rows`, `uses_rows`

**정답 SQL**

```sql
CREATE TABLE p_coupons AS
SELECT DISTINCT coupon_code, coupon_name, discount_amount FROM ex_coupon_sheet;

CREATE TABLE p_coupon_customers AS
SELECT DISTINCT customer_phone, customer_name FROM ex_coupon_sheet;

CREATE TABLE p_coupon_uses AS
SELECT coupon_code, customer_phone, used_at FROM ex_coupon_sheet;

ALTER TABLE p_coupons          ADD CONSTRAINT pk_p_coupons          PRIMARY KEY (coupon_code);
ALTER TABLE p_coupon_customers ADD CONSTRAINT pk_p_coupon_customers PRIMARY KEY (customer_phone);
ALTER TABLE p_coupon_uses
    ADD CONSTRAINT pk_p_coupon_uses          PRIMARY KEY (coupon_code, customer_phone),
    ADD CONSTRAINT fk_p_coupon_uses_coupon   FOREIGN KEY (coupon_code)    REFERENCES p_coupons (coupon_code),
    ADD CONSTRAINT fk_p_coupon_uses_customer FOREIGN KEY (customer_phone) REFERENCES p_coupon_customers (customer_phone);

SELECT (SELECT COUNT(*) FROM p_coupons)          AS coupons_rows,
       (SELECT COUNT(*) FROM p_coupon_customers) AS customers_rows,
       (SELECT COUNT(*) FROM p_coupon_uses)      AS uses_rows;
```

<sub>▶ 실행 결과 · 1행</sub>

| coupons_rows | customers_rows | uses_rows |
|---|---|---|
| 5 | 10 | 15 |


> **해설** 부분 종속이 두 개(`coupon_code → 이름, 할인액`, `customer_phone → 고객 이름`)라서 두 테이블을 떼어 냈고, 키 **전체**에 종속된 `used_at`만 남았습니다. 이제 `VIP10K`의 할인액을 바꿀 때 `p_coupons` 한 행만 고치면 됩니다(원래는 3행). PK 추가가 성공한 것이 문제 3 ①②의 종속이 성립한다는 증거입니다. 남은 세 테이블은 이행 종속도 없으므로 **3NF이자 BCNF**입니다. 실무라면 전화번호 대신 `customer_id`를 키로 씁니다(바뀔 수 있는 값은 PK로 쓰지 않기).

### 문제 6. 메뉴 하나 지웠더니 — 이상 현상 ★★

> **운영팀** `ex_menu_sheet`는 메뉴 코드가 PK라서 2NF는 만족합니다(단일 열 키에는 부분 종속이 생길 수 없음). 그래도 사고가 납니다.
> **메뉴 한 개만 지워도** 이 시트에서 **완전히 사라지는 가게와 분류**를 찾아 주세요. (메뉴가 딱 1개뿐인 가게, 딱 1개뿐인 분류)

- 열: `kind` ('가게' 또는 '분류'), `name`, `menu_count`
- 순서: `kind` → `name`

**정답 SQL**

```sql
SELECT '가게' AS kind, restaurant_name AS name, COUNT(*) AS menu_count
FROM ex_menu_sheet
GROUP BY restaurant_name
HAVING COUNT(*) = 1
UNION ALL
SELECT '분류', category_name, COUNT(*)
FROM ex_menu_sheet
GROUP BY category_name
HAVING COUNT(*) = 1
ORDER BY kind, name;
```

<sub>▶ 실행 결과 · 2행</sub>

| kind | name | menu_count |
|---|---|---|
| 가게 | 광안리화덕피자 | 1 |
| 분류 | 피자 | 1 |


> **해설** 광안리화덕피자의 마르게리타를 단종하면 **가게 이름 · 사장님**과 **'피자' 분류**까지 사라집니다(삭제 이상). 같은 이유로 메뉴가 없는 새 가게나 새 분류(예: '분식')는 등록할 수 없고(삽입 이상), 전포카츠 사장님이 바뀌면 3행을 모두 고쳐야 합니다(갱신 이상). 원인은 `menu_code → restaurant_code → owner_name, category_code → category_name`으로 이어지는 **이행 종속**입니다. 2NF는 이 문제를 잡지 못합니다.

### 문제 7. 이행 종속 제거 — 3NF ★★

> **운영팀** `ex_menu_sheet`를 3NF로 나누세요. 종속이 **두 단계**로 이어진다는 데 주의합니다.
> - `p_menu_categories` (`category_code` PK, `category_name`)
> - `p_menu_restaurants` (`restaurant_code` PK, `restaurant_name`, `owner_name`, `category_code` FK)
> - `p_menus` (`menu_code` PK, `menu_name`, `price`, `restaurant_code` FK)
>
> 세 테이블을 만든 뒤, 3NF 테이블에 **메뉴 없는 분류 '분식'(`C04`)을 등록**할 수 있는지 확인하고 분류별 메뉴 수를 구하세요.

- 열: `category_code`, `category_name`, `menu_count`
- 순서: `category_code`

**정답 SQL**

```sql
CREATE TABLE p_menu_categories AS
SELECT DISTINCT category_code, category_name FROM ex_menu_sheet;

CREATE TABLE p_menu_restaurants AS
SELECT DISTINCT restaurant_code, restaurant_name, owner_name, category_code FROM ex_menu_sheet;

CREATE TABLE p_menus AS
SELECT menu_code, menu_name, price, restaurant_code FROM ex_menu_sheet;

ALTER TABLE p_menu_categories  ADD CONSTRAINT pk_p_menu_categories PRIMARY KEY (category_code);
ALTER TABLE p_menu_restaurants
    ADD CONSTRAINT pk_p_menu_restaurants          PRIMARY KEY (restaurant_code),
    ADD CONSTRAINT fk_p_menu_restaurants_category FOREIGN KEY (category_code) REFERENCES p_menu_categories (category_code);
ALTER TABLE p_menus
    ADD CONSTRAINT pk_p_menus            PRIMARY KEY (menu_code),
    ADD CONSTRAINT fk_p_menus_restaurant FOREIGN KEY (restaurant_code) REFERENCES p_menu_restaurants (restaurant_code);

INSERT INTO p_menu_categories VALUES ('C04', '분식');

SELECT c.category_code, c.category_name, COUNT(m.menu_code) AS menu_count
FROM p_menu_categories c
LEFT JOIN p_menu_restaurants r ON c.category_code   = r.category_code
LEFT JOIN p_menus            m ON r.restaurant_code = m.restaurant_code
GROUP BY c.category_code, c.category_name
ORDER BY c.category_code;
```

<sub>▶ 실행 결과 · 4행</sub>

| category_code | category_name | menu_count |
|---|---|---|
| C01 | 한식 | 6 |
| C02 | 일식 | 3 |
| C03 | 피자 | 1 |
| C04 | 분식 | 0 |


> **해설** `category_code`는 메뉴가 아니라 **가게**에 종속되므로 `p_menus`가 아니라 `p_menu_restaurants`에 둡니다. `p_menus`에 `category_code`를 남기면 `menu_code → restaurant_code → category_code` 이행 종속이 그대로 남습니다. 분해 후에는 메뉴가 없는 '분식'도 등록되고(삽입 이상 해결), 마르게리타를 지워도 광안리화덕피자와 '피자'는 남습니다(삭제 이상 해결). `LEFT JOIN`을 두 번 써야 메뉴가 0인 분류가 결과에 남습니다.

### 문제 8. 결정자가 후보키가 아니다 — BCNF ★★

> **안전관리팀** `ex_inspection_sheet`의 규칙은 두 가지입니다.
> - 가게마다 점검 종류별 담당 점검원은 한 명 → PK (`restaurant_name`, `inspection_type`)
> - 점검원은 **한 종류만** 맡는다 → `inspector_name → inspection_type`
>
> ① 두 번째 규칙이 데이터에서 성립하는지 확인하고, ② BCNF로 나누세요.
> - `p_inspectors` (`inspector_name` PK, `inspection_type`)
> - `p_restaurant_inspectors` (`restaurant_name`, `inspector_name`) — PK는 두 열 조합, `inspector_name`은 FK

- 열: `violations` (①), `inspectors_rows`, `assignments_rows`

**정답 SQL**

```sql
CREATE TABLE p_inspectors AS
SELECT DISTINCT inspector_name, inspection_type FROM ex_inspection_sheet;

CREATE TABLE p_restaurant_inspectors AS
SELECT restaurant_name, inspector_name FROM ex_inspection_sheet;

ALTER TABLE p_inspectors ADD CONSTRAINT pk_p_inspectors PRIMARY KEY (inspector_name);
ALTER TABLE p_restaurant_inspectors
    ADD CONSTRAINT pk_p_restaurant_inspectors   PRIMARY KEY (restaurant_name, inspector_name),
    ADD CONSTRAINT fk_p_restaurant_inspectors_i FOREIGN KEY (inspector_name) REFERENCES p_inspectors (inspector_name);

SELECT
    (SELECT COUNT(*) FROM (SELECT inspector_name FROM ex_inspection_sheet GROUP BY inspector_name
                           HAVING COUNT(DISTINCT inspection_type) > 1) t) AS violations,
    (SELECT COUNT(*) FROM p_inspectors)            AS inspectors_rows,
    (SELECT COUNT(*) FROM p_restaurant_inspectors) AS assignments_rows;
```

<sub>▶ 실행 결과 · 1행</sub>

| violations | inspectors_rows | assignments_rows |
|---|---|---|
| 0 | 5 | 13 |


> **해설** 수업 5-6절 `rider_assign`과 같은 모양입니다. 후보키는 (가게, 점검 종류)와 (가게, 점검원) 두 개이고, 세 열이 모두 어떤 후보키의 일부라 **3NF는 만족**합니다. 하지만 결정자 `inspector_name`이 후보키가 아니므로 **BCNF 위반**입니다. 백승호 점검원의 담당 종류가 바뀌면 원래 시트에서는 4행을 고쳐야 했지만 이제 `p_inspectors` 1행입니다. 대신 "가게마다 종류별 점검원은 한 명" 규칙은 어떤 키로도 지켜지지 않습니다 — 같은 가게에 위생 점검원 두 명을 넣어도 막을 수 없습니다(종속 보존 실패).

### 문제 9. 무손실 분해 vs 가짜 튜플 ★★★

> **데이터팀** 같은 시트를 두 가지로 나눈 뒤 다시 JOIN해 비교합니다.
> - **올바른 분해**: 8번의 `p_inspectors` ⋈ `p_restaurant_inspectors` (`inspector_name`으로 JOIN)
> - **잘못된 분해**: (`restaurant_name`, `inspection_type`)과 (`inspection_type`, `inspector_name`)으로 나누고 `inspection_type`으로 JOIN (테이블을 만들지 말고 CTE로)
>
> 각 방법의 재조립 행 수와, 원래 시트에 **없던** 행(가짜 튜플) 수를 구하세요.

- 열: `method` ('올바른 분해' / '잘못된 분해'), `rebuilt_rows`, `extra_rows`
- 순서: 올바른 분해 → 잘못된 분해

**정답 SQL**

```sql
WITH good AS (
    SELECT ri.restaurant_name, i.inspection_type, ri.inspector_name
    FROM p_restaurant_inspectors ri
    JOIN p_inspectors i ON ri.inspector_name = i.inspector_name
), part_a AS (
    SELECT DISTINCT restaurant_name, inspection_type FROM ex_inspection_sheet
), part_b AS (
    SELECT DISTINCT inspection_type, inspector_name FROM ex_inspection_sheet
), bad AS (
    SELECT a.restaurant_name, a.inspection_type, b.inspector_name
    FROM part_a a
    JOIN part_b b ON a.inspection_type = b.inspection_type
), orig AS (
    SELECT restaurant_name, inspection_type, inspector_name FROM ex_inspection_sheet
)
SELECT '올바른 분해' AS method, (SELECT COUNT(*) FROM good) AS rebuilt_rows,
    (SELECT COUNT(*) FROM (SELECT * FROM good EXCEPT SELECT * FROM orig) x) AS extra_rows
UNION ALL
SELECT '잘못된 분해', (SELECT COUNT(*) FROM bad),
    (SELECT COUNT(*) FROM (SELECT * FROM bad EXCEPT SELECT * FROM orig) y);
```

<sub>▶ 실행 결과 · 2행</sub>

| method | rebuilt_rows | extra_rows |
|---|---|---|
| 올바른 분해 | 13 | 0 |
| 잘못된 분해 | 22 | 9 |


> **해설** 잘못된 분해는 행이 늘어납니다. 공통 열 `inspection_type`은 **어느 쪽에서도 키가 아니라서**, 위생 점검이 있는 가게마다 위생 점검원 두 명(송미라, 문재석)이 모두 붙습니다. 원래 없던 "서면옛날돼지국밥 위생 = 문재석" 같은 행이 **가짜 튜플**입니다. 행이 늘었으니 정보가 늘어난 것 같지만, 실제로는 무엇이 진짜인지 **알 수 없게** 됐으므로 정보를 잃은 것입니다(손실 분해). 무손실의 조건: **두 테이블의 공통 열이 적어도 한쪽의 키**여야 합니다. 올바른 분해의 공통 열 `inspector_name`은 `p_inspectors`의 PK입니다.

### 문제 10. 정규형 판정 — 정보처리기사 유형 ★★

> SQL 없이 푸는 문제입니다. 각 릴레이션이 만족하는 **가장 높은 정규형**과 그 이유(위반하는 종속)를 쓰세요. 밑줄은 기본키입니다.
>
> | # | 릴레이션 | 함수 종속 |
> |---|---|---|
> | (가) | 수강(<u>학번</u>, <u>과목코드</u>, 성적) | (학번, 과목코드) → 성적 |
> | (나) | 주문상세(<u>주문번호</u>, <u>메뉴번호</u>, 수량, 주문일시) | (주문번호, 메뉴번호) → 수량 / 주문번호 → 주문일시 |
> | (다) | 가게(<u>가게번호</u>, 가게명, 우편번호, 구) | 가게번호 → 가게명, 우편번호 / 우편번호 → 구 |
> | (라) | 배정(<u>고객</u>, <u>가게</u>, 기사) | (고객, 가게) → 기사 / 기사 → 가게 |
> | (마) | 회원(<u>회원번호</u>, 이름, 전화번호들) | 전화번호들 = `'010-1111-2222, 010-3333-4444'` |
>
> 추가 질문: (나)와 (다)를 각각 한 단계 위 정규형으로 분해한 결과를 릴레이션 표기로 쓰세요.

> **정답**
>
> | # | 최고 정규형 | 이유 |
> |---|---|---|
> | (가) | **BCNF** | 유일한 결정자 (학번, 과목코드)가 후보키 |
> | (나) | **1NF** | 주문일시가 키의 일부(주문번호)에만 종속 → 부분 종속(2NF 위반) |
> | (다) | **2NF** | 가게번호 → 우편번호 → 구 이행 종속(3NF 위반). 키가 단일 열이라 부분 종속은 없음 |
> | (라) | **3NF** | 후보키 (고객, 가게), (고객, 기사) — 세 열 모두 주요 속성이라 3NF는 만족. 결정자 '기사'가 후보키가 아님(BCNF 위반) |
> | (마) | **비정규형** | 한 칸에 전화번호 여러 개(1NF 위반) |
>
> 분해: (나) → 주문(<u>주문번호</u>, 주문일시), 주문상세(<u>주문번호</u>, <u>메뉴번호</u>, 수량) / (다) → 가게(<u>가게번호</u>, 가게명, 우편번호), 우편번호(<u>우편번호</u>, 구)
>
> 흔한 오답: (라)를 2NF로 쓰는 것. "기사 → 가게"를 부분 종속으로 착각하기 쉽지만, 2NF·3NF가 검사하는 대상은 **비주요 속성**(어떤 후보키에도 속하지 않는 열)입니다. (라)에는 비주요 속성이 없습니다.

### 문제 11. 비정규형 시트 하나를 끝까지 — 종합 ★★★

> **마케팅팀** `ex_event_sheet`는 할인 이벤트 참여 시트입니다. PK는 (`event_code`, `restaurant_name`)이고, 할인 메뉴는 한 칸에 몰려 있습니다.
> 함수 종속: `event_code → event_name, discount_rate` / `restaurant_name → restaurant_phone` / (`event_code`, `restaurant_name`) → `joined_at`, `menu_list`
>
> 1NF부터 BCNF까지 정규화해서 아래 네 테이블을 만들고, PK · FK를 모두 거세요.
> - `p_events` (`event_code` PK, `event_name`, `discount_rate`)
> - `p_event_shops` (`restaurant_name` PK, `restaurant_phone`)
> - `p_event_joins` (`event_code`, `restaurant_name`, `joined_at`) — PK 두 열, FK 두 개
> - `p_event_menus` (`event_code`, `restaurant_name`, `menu_name`) — PK 세 열, (`event_code`, `restaurant_name`)은 `p_event_joins`를 참조하는 FK
>
> 마지막으로 **이벤트별 참여 가게 수와 할인 메뉴 수**를 구하세요.

- 열: `event_code`, `event_name`, `discount_rate`, `shop_count`, `menu_count`
- 순서: `event_code`

**정답 SQL**

```sql
CREATE TABLE p_events AS
SELECT DISTINCT event_code, event_name, discount_rate FROM ex_event_sheet;

CREATE TABLE p_event_shops AS
SELECT DISTINCT restaurant_name, restaurant_phone FROM ex_event_sheet;

CREATE TABLE p_event_joins AS
SELECT event_code, restaurant_name, joined_at FROM ex_event_sheet;

CREATE TABLE p_event_menus AS
SELECT e.event_code, e.restaurant_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(e.menu_list, ', ', seq.n), ', ', -1) AS menu_name
FROM ex_event_sheet e
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) seq
  ON seq.n <= (CHAR_LENGTH(e.menu_list) - CHAR_LENGTH(REPLACE(e.menu_list, ', ', ''))) / 2 + 1;

ALTER TABLE p_events      ADD CONSTRAINT pk_p_events      PRIMARY KEY (event_code);
ALTER TABLE p_event_shops ADD CONSTRAINT pk_p_event_shops PRIMARY KEY (restaurant_name);
ALTER TABLE p_event_joins
    ADD CONSTRAINT pk_p_event_joins       PRIMARY KEY (event_code, restaurant_name),
    ADD CONSTRAINT fk_p_event_joins_event FOREIGN KEY (event_code)      REFERENCES p_events (event_code),
    ADD CONSTRAINT fk_p_event_joins_shop  FOREIGN KEY (restaurant_name) REFERENCES p_event_shops (restaurant_name);
ALTER TABLE p_event_menus
    ADD CONSTRAINT pk_p_event_menus      PRIMARY KEY (event_code, restaurant_name, menu_name),
    ADD CONSTRAINT fk_p_event_menus_join FOREIGN KEY (event_code, restaurant_name)
        REFERENCES p_event_joins (event_code, restaurant_name);

SELECT e.event_code, e.event_name, e.discount_rate,
    COUNT(DISTINCT j.restaurant_name) AS shop_count,
    COUNT(m.menu_name)                AS menu_count
FROM p_events e
JOIN p_event_joins j      ON e.event_code = j.event_code
LEFT JOIN p_event_menus m ON j.event_code = m.event_code AND j.restaurant_name = m.restaurant_name
GROUP BY e.event_code, e.event_name, e.discount_rate
ORDER BY e.event_code;
```

<sub>▶ 실행 결과 · 3행</sub>

| event_code | event_name | discount_rate | shop_count | menu_count |
|---|---|---|---|---|
| E01 | 여름 밀면 페스타 | 10 | 2 | 3 |
| E02 | 야식 대전 | 15 | 3 | 7 |
| E03 | 비 오는 날 전 데이 | 20 | 2 | 3 |


> **해설** 단계별로 보면
> 1. **1NF**: `menu_list`를 펴서 `p_event_menus` (한 칸에 메뉴 하나)
> 2. **2NF**: 키의 일부에만 종속된 것 → `event_code → 이름, 할인율`은 `p_events`, `restaurant_name → 전화`는 `p_event_shops`
> 3. **3NF · BCNF**: 남은 `p_event_joins`의 `joined_at`은 키 전체에 종속, 다른 결정자 없음 → 네 테이블 모두 BCNF
>
> 서면옛날돼지국밥은 두 이벤트에 참여하지만 전화번호는 `p_event_shops`에 **한 번만** 있습니다. `p_event_menus`의 FK가 `p_event_joins`의 **복합키**를 참조한다는 점도 보세요 — "참여하지 않은 이벤트에 할인 메뉴를 등록"하는 실수를 DB가 막습니다. 할인 메뉴 수는 E01 3개, E02 7개, E03 3개입니다.

---

## 팀 과제 — 기능 추가 ERD (3~4인, 25분 + 발표 3분)

다음 중 **하나**를 골라 설계하세요.

| 주제 | 요구사항 |
|---|---|
| ① 찜하기 | 고객은 가게를 찜할 수 있다. 같은 가게를 두 번 찜할 수 없다. 찜한 날짜를 보여 준다. 찜 해제 가능 |
| ② 가게 휴무일 | 가게는 정기 휴무 요일(여러 개)과 임시 휴무일(날짜, 사유)을 등록한다. 같은 날 임시 휴무 중복 불가 |
| ③ 라이더 정산 | 기사는 배달 1건마다 배달료를 받는다. 주 단위로 정산하며, 정산 1건에 여러 배달이 묶인다. 배달 하나는 한 번만 정산 |

**제출물**
1. 요구사항 문장 3개 이상 (명사·동사에 밑줄)
2. ERD — Workbench 또는 mermaid. 카디널리티(`||`, `o|`, `|{`, `o{`) 표시
3. DDL — PK·FK·UNIQUE·CHECK 이름 붙여서, `hanip_delivery09`에서 실제 실행
4. 샘플 데이터 INSERT 3행 이상 + 규칙 위반 INSERT 1개(에러 확인)
5. 확인 쿼리 1개 (예: "찜이 가장 많은 가게 TOP 3")

**발표 체크리스트**: 왜 이 테이블로 나눴나 · **각 테이블이 BCNF인지와 그 근거**(후보키 · 결정자) · 카디널리티의 근거 · 요구사항 규칙이 어떤 제약조건으로 번역됐나 · 반정규화한 것이 있다면 그 이유

**① 찜하기 예시 답안**

```sql
CREATE TABLE favorites (
    customer_id   INT      NOT NULL,
    restaurant_id INT      NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_favorites            PRIMARY KEY (customer_id, restaurant_id),
    CONSTRAINT fk_favorites_customer   FOREIGN KEY (customer_id)   REFERENCES customers (customer_id),
    CONSTRAINT fk_favorites_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)
);
-- 고객 ↔ 가게 M:N. 두 열 조합 PK가 "두 번 찜 불가"를 강제. 찜 해제 = DELETE (이력이 필요하면 removed_at 열)
```

**② 가게 휴무일**: `restaurant_weekly_holidays (restaurant_id, day_of_week)` 조합 PK + `CHECK (day_of_week BETWEEN 1 AND 7)` / `restaurant_temp_holidays (holiday_id, restaurant_id, holiday_date, reason)` + `UNIQUE (restaurant_id, holiday_date)`. 요일 여러 개를 한 칸에 `'월,화'`로 넣으면 1NF 위반.

**③ 라이더 정산**: `rider_settlements (settlement_id, rider_id, week_start, total_amount, settled_at)` + `UNIQUE (rider_id, week_start)` / 배달 쪽에 `orders.settlement_id` FK(NULL 허용) 또는 연결 테이블 `settlement_orders (settlement_id, order_id)` + `UNIQUE (order_id)`. `total_amount`는 계산 가능한 값을 저장한 **반정규화** — 정산 확정 후 바뀌면 안 되는 금액이라 저장하는 것이 맞습니다(6-1절과 같은 이유).
