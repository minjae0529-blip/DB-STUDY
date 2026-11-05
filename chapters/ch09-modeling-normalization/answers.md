# Ch09 실습 — 나누고, 검증하고, 설계하기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery09;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 6~8번은 앞 문제에서 만든 테이블을 씁니다.
> 수업 중 만든 `nf_` 테이블과 겹치지 않도록 실습 테이블은 `p_`로 시작합니다.
> 다시 처음부터 하고 싶으면 `setup.sql` 위쪽의 `DROP DATABASE` 주석을 풀고 다시 실행하면 됩니다.
> 마지막 **팀 과제**는 정답 SQL이 없는 설계 과제입니다.

---

### 문제 1. 카디널리티 확인 ★

> **데이터팀** ERD에서 `riders |o--o{ orders`, `menus ||--o{ order_items`라고 그렸습니다. 선 끝의 `o`(0 허용)가 실제 데이터에서도 맞는지 확인해 주세요.
> ① **기사가 배정되지 않은 주문** 수 ② **한 번도 주문되지 않은 메뉴** 수

- 열: `orders_without_rider`, `menus_never_ordered`

**정답 SQL**

```sql
SELECT
    (SELECT COUNT(*) FROM orders WHERE rider_id IS NULL) AS orders_without_rider,
    (SELECT COUNT(*) FROM menus m
     WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.menu_id = m.menu_id)) AS menus_never_ordered;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_without_rider | menus_never_ordered |
|---|---|
| 51 | 4 |


> **해설** 둘 다 0보다 크므로 `o`가 맞습니다. 기사 없는 주문은 접수·조리중·취소 주문이고, 주문 안 된 메뉴는 신메뉴나 인기 없는 메뉴입니다. 만약 `menus_never_ordered`가 0이었다면 `||--|{`로 그려야 할까요? 아닙니다. 카디널리티는 **지금 데이터**가 아니라 **업무 규칙**("메뉴는 주문 없이도 등록할 수 있다")으로 정합니다. 쿼리는 규칙이 지켜지는지 확인하는 도구입니다.

### 문제 2. 1NF의 힘 ★

> **정산팀** `order_flat`(메뉴 한 줄 = 한 행)에서 6월 **판매 수량 상위 5개 메뉴**를 뽑아 주세요. `order_sheet`로는 할 수 없던 일입니다.
> 힌트: 메뉴 이름만으로는 가게가 정해지지 않으니 가게 이름과 함께 묶으세요.

- 열: `restaurant_name`, `menu_name`, `total_qty`
- 순서: `total_qty` 내림차순 → `restaurant_name` → `menu_name`, 5행

**정답 SQL**

```sql
SELECT restaurant_name, menu_name, SUM(quantity) AS total_qty
FROM order_flat
GROUP BY restaurant_name, menu_name
ORDER BY total_qty DESC, restaurant_name, menu_name
LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| restaurant_name | menu_name | total_qty |
|---|---|---|
| 장전동든든김밥 | 든든김밥 | 18 |
| 광안리화덕피자 | 마르게리타 | 12 |
| 하단버거스탠드 | 클래식 치즈버거 | 11 |
| 대연동크런치치킨 | 감자튀김 | 10 |
| 서면옛날돼지국밥 | 돼지국밥 | 10 |


> **해설** 한 칸에 값이 하나씩 들어 있어야 `GROUP BY`·`SUM`을 쓸 수 있습니다. `GROUP BY menu_name`만 쓰면 다른 가게의 같은 이름 메뉴(예: 두 치킨집의 "양념 치킨")가 합쳐질 수 있습니다.

### 문제 3. 함수 종속 검증 ★★

> **데이터팀** "(가게, 메뉴) → 단가" 종속이 성립하는지 두 범위에서 확인해 주세요.
> ① `order_flat`(6월)에서 (`restaurant_name`, `menu_name`)이 같은데 `unit_price`가 2개 이상인 조합 수
> ② 전체 기간 `order_items`에서 `menu_id`가 같은데 `unit_price`가 2개 이상인 메뉴 수

- 열: `june_violations`, `all_time_violations`

**정답 SQL**

```sql
SELECT
    (SELECT COUNT(*) FROM (SELECT restaurant_name, menu_name FROM order_flat
                           GROUP BY restaurant_name, menu_name
                           HAVING COUNT(DISTINCT unit_price) > 1) t) AS june_violations,
    (SELECT COUNT(*) FROM (SELECT menu_id FROM order_items
                           GROUP BY menu_id
                           HAVING COUNT(DISTINCT unit_price) > 1) t) AS all_time_violations;
```

<sub>▶ 실행 결과 · 1행</sub>

| june_violations | all_time_violations |
|---|---|
| 0 | 6 |


> **해설** 6월만 보면 성립하는 것처럼 보이지만(0), 전체 기간에는 가격이 바뀐 메뉴들 때문에 깨집니다. **짧은 기간의 데이터만 보고 함수 종속을 판단하면 안 됩니다.** "메뉴 → 단가"는 업무 규칙상 성립하지 않으므로(가격은 바뀐다), 단가는 메뉴가 아니라 **주문 줄**의 속성이고 `order_items`에 있어야 합니다.

### 문제 4. 갱신 이상 재현 ★★

> **CS팀** 김민준 님이 전화번호를 `010-2841-0000`으로 바꿨습니다. 상담원이 `order_flat`에서 **457번 주문만** 고쳤다고 가정하고, 트랜잭션 안에서 재현한 뒤 김민준 님의 전화번호가 몇 개로 보이는지 확인하고 **ROLLBACK**하세요.

- 열: `customer_phone`, `line_count` (ROLLBACK 전)
- 순서: `customer_phone`

**정답 SQL**

```sql
START TRANSACTION;
UPDATE order_flat SET customer_phone = '010-2841-0000'
WHERE order_id = 457;

SELECT customer_phone, COUNT(*) AS line_count
FROM order_flat
WHERE customer_name = '김민준'
GROUP BY customer_phone
ORDER BY customer_phone;
ROLLBACK;
```

<sub>▶ 실행 결과 · 2행</sub>

| customer_phone | line_count |
|---|---|
| 010-2841-0000 | 1 |
| 010-2841-5523 | 13 |


> **해설** 한 사람에게 번호가 두 개 생겼습니다. 다음 주문 알림은 어느 번호로 보내야 할까요? 정규화된 스키마에서는 `customers` 한 행만 바꾸면 되고, 모든 주문은 `customer_id`로 그 행을 가리키므로 모순이 생길 수 없습니다.

### 문제 5. 삭제 이상 후보 찾기 ★★

> **데이터팀** `order_flat`에서 주문 **한 건만** 지워도 주문장에서 완전히 사라지는 **가게**와 **고객**을 찾아 주세요. (6월 주문이 딱 1건인 가게·고객)

- 열: `kind` ('가게' 또는 '고객'), `name`
- 순서: `kind` → `name`

**정답 SQL**

```sql
SELECT '가게' AS kind, restaurant_name AS name
FROM order_flat
GROUP BY restaurant_name
HAVING COUNT(DISTINCT order_id) = 1
UNION ALL
SELECT '고객', customer_name
FROM order_flat
GROUP BY customer_name
HAVING COUNT(DISTINCT order_id) = 1
ORDER BY kind, name;
```

<sub>▶ 실행 결과 · 2행</sub>

| kind | name |
|---|---|
| 가게 | 해운대스시하루 |
| 고객 | 송재원 |


> **해설** `COUNT(*)`가 아니라 `COUNT(DISTINCT order_id)`입니다. 주문 한 건이 메뉴 줄 여러 행일 수 있기 때문입니다. 이 가게·고객의 정보는 주문에 **붙어서만** 존재합니다. 정규화된 스키마에서는 `restaurants`, `customers`에 따로 있으므로 주문을 지워도 남습니다.

### 문제 6. 2NF로 분해 ★★

> **데이터팀** `order_flat`에서 `order_id`에만 종속된 열을 떼어 `p_orders`를, 나머지로 `p_order_items`를 만드세요. 각각 PK를 걸고 행 수를 확인합니다.
> - `p_orders`: `order_id`, `ordered_at`, `customer_phone`, `customer_name`, `customer_grade`, `restaurant_name`, `restaurant_phone`, `delivery_fee` / PK `order_id`
> - `p_order_items`: `order_id`, `menu_name`, `quantity`, `unit_price` / PK (`order_id`, `menu_name`)

- 열: `orders_rows`, `items_rows`

**정답 SQL**

```sql
CREATE TABLE p_orders AS
SELECT DISTINCT order_id, ordered_at, customer_phone, customer_name, customer_grade,
    restaurant_name, restaurant_phone, delivery_fee
FROM order_flat;

CREATE TABLE p_order_items AS
SELECT order_id, menu_name, quantity, unit_price
FROM order_flat;

ALTER TABLE p_orders      ADD CONSTRAINT pk_p_orders      PRIMARY KEY (order_id);
ALTER TABLE p_order_items ADD CONSTRAINT pk_p_order_items PRIMARY KEY (order_id, menu_name);

SELECT (SELECT COUNT(*) FROM p_orders) AS orders_rows,
       (SELECT COUNT(*) FROM p_order_items) AS items_rows;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_rows | items_rows |
|---|---|
| 97 | 178 |


> **해설** `p_orders`에 PK가 걸렸다는 것 = `DISTINCT` 결과에 같은 `order_id`가 두 번 나오지 않았다 = `order_id`가 나머지 열을 결정한다는 증거입니다. CTAS는 제약조건을 복사하지 않으므로 PK는 직접 걸어야 합니다.

### 문제 7. 3NF로 분해 ★★

> **데이터팀** `p_orders`에서 이행 종속을 없애세요.
> - `p_customers` (`customer_phone` PK, `customer_name`, `customer_grade`)
> - `p_restaurants` (`restaurant_name` PK, `restaurant_phone`)
> - `p_orders`에서 `customer_name`, `customer_grade`, `restaurant_phone` 열 삭제

- 열: `customers_rows`, `restaurants_rows`, `orders_columns` (`p_orders`의 남은 열 수)

**정답 SQL**

```sql
CREATE TABLE p_customers AS
SELECT DISTINCT customer_phone, customer_name, customer_grade FROM p_orders;

CREATE TABLE p_restaurants AS
SELECT DISTINCT restaurant_name, restaurant_phone FROM p_orders;

ALTER TABLE p_customers   ADD CONSTRAINT pk_p_customers   PRIMARY KEY (customer_phone);
ALTER TABLE p_restaurants ADD CONSTRAINT pk_p_restaurants PRIMARY KEY (restaurant_name);
ALTER TABLE p_orders DROP COLUMN customer_name, DROP COLUMN customer_grade, DROP COLUMN restaurant_phone;

SELECT (SELECT COUNT(*) FROM p_customers) AS customers_rows,
       (SELECT COUNT(*) FROM p_restaurants) AS restaurants_rows,
       (SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'p_orders') AS orders_columns;
```

<sub>▶ 실행 결과 · 1행</sub>

| customers_rows | restaurants_rows | orders_columns |
|---|---|---|
| 22 | 13 | 5 |


> **해설** `p_orders`에는 `order_id`, `ordered_at`, `customer_phone`, `restaurant_name`, `delivery_fee` 5열이 남습니다. `customer_phone`, `restaurant_name`이 각각 `p_customers`, `p_restaurants`를 가리키는 **FK 역할**을 합니다. 우리 스키마는 여기서 한 걸음 더 나가 전화번호·이름 대신 바뀌지 않는 번호(`customer_id`, `restaurant_id`)를 키로 씁니다.

### 문제 8. 무손실 분해 검증 ★★★

> **데이터팀** 6·7번에서 나눈 네 테이블을 JOIN해 `order_flat`과 비교하세요. **양쪽 방향**으로 확인합니다.
> ① `order_flat`에는 있는데 재조립 결과에는 없는 행 수 ② 재조립 결과에는 있는데 `order_flat`에는 없는 행 수
> 비교 열: `order_id`, `menu_name`, `customer_name`, `customer_grade`, `restaurant_phone`, `quantity`, `unit_price`

- 열: `lost_rows`, `extra_rows`

**정답 SQL**

```sql
WITH rebuilt AS (
    SELECT o.order_id, i.menu_name, c.customer_name, c.customer_grade,
        r.restaurant_phone, i.quantity, i.unit_price
    FROM p_orders o
    JOIN p_order_items i ON o.order_id        = i.order_id
    JOIN p_customers   c ON o.customer_phone  = c.customer_phone
    JOIN p_restaurants r ON o.restaurant_name = r.restaurant_name
), flat AS (
    SELECT order_id, menu_name, customer_name, customer_grade,
        restaurant_phone, quantity, unit_price
    FROM order_flat
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM flat EXCEPT SELECT * FROM rebuilt) a) AS lost_rows,
    (SELECT COUNT(*) FROM (SELECT * FROM rebuilt EXCEPT SELECT * FROM flat) b) AS extra_rows;
```

<sub>▶ 실행 결과 · 1행</sub>

| lost_rows | extra_rows |
|---|---|
| 0 | 0 |


> **해설** 둘 다 0이면 정보가 빠지지도(lost) 가짜로 생기지도(extra) 않은 **무손실 분해**입니다. 잘못 나누면(예: 공통 열 없이 나누거나, 키가 아닌 열로 JOIN) `extra_rows`가 생깁니다 — 원래 없던 조합이 만들어지는 것을 "가짜 튜플(spurious tuple)"이라 부릅니다. `restaurant_phone`처럼 NULL이 있는 열은 `EXCEPT`에서 NULL끼리 같다고 비교되므로 여기서는 문제없습니다.

### 문제 9. 반정규화가 필요한 이유 ★★

> **정산팀** 해운대명가밀면 **물밀면**(`menu_id = 11`)의 전체 기간 배달완료 매출을 ① 실제 판매가(`unit_price`)와 ② 현재 메뉴 가격(`menus.price`)으로 각각 계산하고, 판매가별 판매 줄 수도 함께 보여 주세요.

- 열: `unit_price`, `line_count`, `real_sales`, `sales_by_current_price`
- 순서: `unit_price`

**정답 SQL**

```sql
SELECT oi.unit_price, COUNT(*) AS line_count,
    SUM(oi.quantity * oi.unit_price) AS real_sales,
    SUM(oi.quantity * m.price)       AS sales_by_current_price
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN menus  m ON oi.menu_id  = m.menu_id
WHERE oi.menu_id = 11
  AND o.status = '배달완료'
GROUP BY oi.unit_price
ORDER BY oi.unit_price;
```

<sub>▶ 실행 결과 · 2행</sub>

| unit_price | line_count | real_sales | sales_by_current_price |
|---|---|---|---|
| 8000 | 12 | 144000 | 162000 |
| 9000 | 5 | 54000 | 54000 |


> **해설** 물밀면은 5월 1일에 8,000원 → 9,000원으로 올랐습니다. 현재 가격으로 계산하면 4월까지 팔린 그릇이 모두 1,000원씩 비싸게 계산되어 과거 매출이 실제보다 커집니다. `unit_price`는 "중복"이 아니라 **그 주문 시점의 사실**이고, 이 값을 보관하지 않으면 과거 정산을 다시 맞출 방법이 없습니다.

### 문제 10. 메뉴 옵션 설계 ★★★

> **개발팀** "밥 추가 +1,000원", "고기 추가 +3,000원" 같은 **메뉴 옵션** 기능을 설계해 주세요.
> - `menu_options`: `option_id` (PK, AUTO_INCREMENT), `menu_id` (FK → menus), `name` VARCHAR(30), `extra_price` INT (0 이상, 기본 0). 한 메뉴 안에서 옵션 이름 중복 불가
> - `order_item_options`: 주문 줄 ↔ 옵션 M:N 연결 테이블. `order_item_id` (FK → order_items), `option_id` (FK → menu_options), PK는 두 열 조합 (식별 관계)
>
> 돼지국밥(`menu_id = 1`)에 옵션 3개(밥 추가 1000, 고기 추가 3000, 다대기 빼기 0)를 등록하고, **457번 주문의 돼지국밥 줄**에 "밥 추가"와 "고기 추가"를 붙인 뒤, 그 줄의 옵션 포함 금액을 확인하세요.
> 힌트: 주문 줄 번호를 모르므로 `INSERT … SELECT`로 `order_items`와 `menu_options`를 JOIN해서 넣습니다.

- 열: `menu_name`, `quantity`, `unit_price`, `option_names`, `option_price`, `line_total`
- `option_names`: 옵션 이름을 `option_id` 순으로 `', '`로 이어 붙임 / `line_total` = (단가 + 옵션 금액 합) × 수량

**정답 SQL**

```sql
CREATE TABLE menu_options (
    option_id   INT          NOT NULL AUTO_INCREMENT,
    menu_id     INT          NOT NULL,
    name        VARCHAR(30)  NOT NULL,
    extra_price INT          NOT NULL DEFAULT 0,
    CONSTRAINT pk_menu_options      PRIMARY KEY (option_id),
    CONSTRAINT fk_menu_options_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id),
    CONSTRAINT uq_menu_options_name UNIQUE (menu_id, name),
    CONSTRAINT ck_menu_options_price CHECK (extra_price >= 0)
);

CREATE TABLE order_item_options (
    order_item_id INT NOT NULL,
    option_id     INT NOT NULL,
    CONSTRAINT pk_order_item_options PRIMARY KEY (order_item_id, option_id),
    CONSTRAINT fk_oio_item   FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id),
    CONSTRAINT fk_oio_option FOREIGN KEY (option_id)     REFERENCES menu_options (option_id)
);

INSERT INTO menu_options (menu_id, name, extra_price) VALUES
    (1, '밥 추가', 1000),
    (1, '고기 추가', 3000),
    (1, '다대기 빼기', 0);

INSERT INTO order_item_options (order_item_id, option_id)
SELECT oi.order_item_id, mo.option_id
FROM order_items oi
JOIN menu_options mo ON oi.menu_id = mo.menu_id
WHERE oi.order_id = 457
  AND mo.name IN ('밥 추가', '고기 추가');

SELECT m.name AS menu_name, oi.quantity, oi.unit_price,
    GROUP_CONCAT(mo.name ORDER BY mo.option_id SEPARATOR ', ') AS option_names,
    SUM(mo.extra_price) AS option_price,
    (oi.unit_price + SUM(mo.extra_price)) * oi.quantity AS line_total
FROM order_items oi
JOIN menus m               ON oi.menu_id       = m.menu_id
JOIN order_item_options oo ON oi.order_item_id = oo.order_item_id
JOIN menu_options mo       ON oo.option_id     = mo.option_id
WHERE oi.order_id = 457
GROUP BY oi.order_item_id, m.name, oi.quantity, oi.unit_price;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_name | quantity | unit_price | option_names | option_price | line_total |
|---|---|---|---|---|---|
| 돼지국밥 | 2 | 10000 | 밥 추가, 고기 추가 | 4000 | 28000 |


> **해설** 주문 줄 하나에 옵션 여럿, 옵션 하나도 여러 주문 줄에 붙으므로 M:N → 연결 테이블입니다. PK가 (`order_item_id`, `option_id`)라 같은 옵션을 한 줄에 두 번 붙일 수 없습니다. 한 가지 더 생각해 볼 점: 옵션 가격이 나중에 바뀌면? 문제 9와 같은 이유로 실무에서는 `order_item_options`에도 **주문 당시 옵션 가격**(`extra_price_at_order`)을 복사해 두는 것이 안전합니다.

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

**발표 체크리스트**: 왜 이 테이블로 나눴나 · 카디널리티의 근거 · 요구사항 규칙이 어떤 제약조건으로 번역됐나 · 반정규화한 것이 있다면 그 이유

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
