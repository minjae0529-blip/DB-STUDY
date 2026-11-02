# Ch07 실습 — 테이블 설계하고 만들기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery07;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 뒤 문제가 앞 문제에서 만든 테이블을 씁니다.
> 다시 처음부터 하고 싶으면 `setup.sql` 위쪽의 `DROP DATABASE` 주석을 풀고 다시 실행하면 됩니다.
> DDL 문제의 "기대 결과"는 만든 뒤 확인용 SELECT의 결과입니다. 열 이름·타입·제약 이름은 문제에 적힌 대로 쓰세요.

---

### 문제 1. NULL을 허용하는 열 ★

> **개발팀** `orders` 테이블에서 **NULL을 허용하는 열**이 무엇인지 목록으로 주세요. `information_schema.columns`를 쓰세요.
> 힌트: `table_schema = DATABASE()`, `table_name = 'orders'`, `is_nullable = 'YES'`

- 열: `column_name`, `data_type`
- 순서: 테이블 정의 순서(`ordinal_position`)

**정답 SQL**

```sql
SELECT column_name AS column_name,
    data_type AS data_type
FROM information_schema.columns
WHERE table_schema = DATABASE()
    AND table_name = 'orders'
    AND is_nullable = 'YES'
ORDER BY ordinal_position;
```

<sub>▶ 실행 결과 · 3행</sub>

| column_name | data_type |
|---|---|
| rider_id | int |
| request_note | varchar |
| delivered_at | datetime |


> **해설** 네 열 모두 NULL에 업무적 이유가 있습니다. `rider_id`(기사 배정 전·취소), `request_note`(요청사항 선택), `delivered_at`(배달 전·취소). 설계할 때 "왜 이 열은 비어도 되는가?"에 답할 수 없다면 NOT NULL이어야 합니다.

### 문제 2. CHECK 제약조건 읽기 ★

> **개발팀** `orders` 테이블에 걸린 **CHECK 제약조건의 이름**을 `information_schema.table_constraints`에서 조회하세요. 그다음 `SHOW CREATE TABLE orders;`로 각 제약조건의 **조건식**을 확인해 무엇을 막는지 한 줄씩 적어 보세요.
> 힌트: `table_schema = DATABASE()`, `table_name = 'orders'`, `constraint_type = 'CHECK'`

- 열: `constraint_name`

**정답 SQL**

```sql
SELECT constraint_name AS constraint_name
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
    AND table_name = 'orders'
    AND constraint_type = 'CHECK'
ORDER BY constraint_name;
```

<sub>▶ 실행 결과 · 4행</sub>

| constraint_name |
|---|
| ck_orders_discount |
| ck_orders_fee |
| ck_orders_payment |
| ck_orders_status |


> **해설** `SHOW CREATE TABLE orders;`의 조건식은 다음과 같습니다.
> - `ck_orders_discount` — 할인액은 0 이상
> - `ck_orders_fee` — 배달팁은 0 이상
> - `ck_orders_payment` — 결제 수단은 카드·간편결제·계좌이체·현장결제 중 하나
> - `ck_orders_status` — 상태는 접수·조리중·배달중·배달완료·취소 중 하나
>
> 상태·결제 수단 목록이 곧 **코드표**입니다. 새 결제 수단(예: '포인트')이 생기면 이 CHECK를 바꾸지 않는 한 저장할 수 없습니다. 그래서 값이 자주 바뀌는 코드는 CHECK 대신 별도 코드 테이블 + FK로 관리하기도 합니다.
>
> 참고: 조건식은 `information_schema.check_constraints`의 `check_clause`에도 있지만, MySQL 8.0에서는 그 열의 **한글이 깨져 보이는** 알려진 표시 문제가 있습니다. 한글이 든 조건식은 `SHOW CREATE TABLE`로 확인하세요.

### 문제 3. 타입 고르기 ★

> 다음 데이터에 알맞은 타입을 고르고 이유를 한 줄로 쓰세요. (SQL 없음)

| 데이터 | 예시 |
|---|---|
| ① 사업자등록번호 | 123-45-67890 |
| ② 메뉴 할인율 | 12.5% |
| ③ 가게 공지 본문 | 최대 2,000자 |
| ④ 기사 위치 위도 | 35.1577 |
| ⑤ 쿠폰 사용 일시 | 2026-06-30 18:47:07 |
| ⑥ 프랜차이즈 여부 | 예 / 아니오 |

> **해설**
> ① `CHAR(12)` — 계산하지 않는 숫자, 형식이 고정. 숫자 타입이면 하이픈과 앞자리 0이 사라짐
> ② `DECIMAL(4,1)` — 정확한 소수. FLOAT는 근사값
> ③ `VARCHAR(2000)` 또는 `TEXT` — 길이 제한이 분명하면 VARCHAR가 검증에 유리
> ④ `DECIMAL(9,6)` 또는 `DOUBLE` — 좌표는 오차를 허용하는 대표적인 경우. 돈이 아니면 DOUBLE도 가능
> ⑤ `DATETIME` — 날짜와 시각 모두 필요
> ⑥ `BOOLEAN`, 열 이름은 `is_franchise`

### 문제 4. 공지사항 테이블 ★★

> **운영팀** 가게 사장님들께 보낼 **공지사항** 테이블 `notices`를 만들어 주세요.

| 열 | 타입 | 규칙 |
|---|---|---|
| `notice_id` | INT | PK, 자동 증가 |
| `title` | VARCHAR(100) | 필수 |
| `content` | TEXT | 필수 |
| `is_pinned` | BOOLEAN | 필수, 기본값 FALSE |
| `published_at` | DATETIME | 필수, 기본값 현재 시각 |

> 만든 뒤 공지 2건을 넣고 확인하세요.
> - "7월 정산일 안내" / "7월 정산은 10일에 진행됩니다." / 상단 고정
> - "배달팁 정책 변경" / "8월부터 5만 원 이상 무료 배달 기준이 4만 원으로 바뀝니다." / 고정 안 함

- 확인 열: `notice_id`, `title`, `is_pinned`

**정답 SQL**

```sql
CREATE TABLE notices (
    notice_id    INT          NOT NULL AUTO_INCREMENT,
    title        VARCHAR(100) NOT NULL,
    content      TEXT         NOT NULL,
    is_pinned    BOOLEAN      NOT NULL DEFAULT FALSE,
    published_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_notices PRIMARY KEY (notice_id)
);

INSERT INTO notices (title, content, is_pinned) VALUES
    ('7월 정산일 안내', '7월 정산은 10일에 진행됩니다.', TRUE);
INSERT INTO notices (title, content) VALUES
    ('배달팁 정책 변경', '8월부터 5만 원 이상 무료 배달 기준이 4만 원으로 바뀝니다.');

SELECT notice_id, title, is_pinned
FROM notices
ORDER BY notice_id;
```

<sub>▶ 실행 결과 · 2행</sub>

| notice_id | title | is_pinned |
|---|---|---|
| 1 | 7월 정산일 안내 | 1 |
| 2 | 배달팁 정책 변경 | 0 |


> **해설** 두 번째 INSERT는 `is_pinned`와 `published_at`을 생략해서 **기본값**(FALSE, 현재 시각)이 들어갔습니다. `published_at`은 실행 시각에 따라 달라지므로 확인 열에서 뺐습니다.

### 문제 5. 휴무일 테이블 ★★

> **운영팀** 가게별 **임시 휴무일**을 저장할 `restaurant_holidays` 테이블을 만들어 주세요.

| 열 | 타입 | 규칙 |
|---|---|---|
| `holiday_id` | INT | PK, 자동 증가 |
| `restaurant_id` | INT | 필수, `restaurants` 참조 (`fk_holidays_restaurant`) |
| `holiday_date` | DATE | 필수 |
| `reason` | VARCHAR(50) | 선택 |

> 추가 규칙: **같은 가게의 같은 날짜는 한 번만** 등록 (`uq_holidays_date`)
> 만든 뒤 아래 휴무를 등록하고, **가게 이름과 함께** 날짜 순으로 조회하세요.
> - 1번 가게 2026-07-15 '내부 수리' / 6번 가게 2026-07-15 (사유 없음) / 1번 가게 2026-07-16 '내부 수리'

- 확인 열: `holiday_date`, `restaurant_name`, `reason`

**정답 SQL**

```sql
CREATE TABLE restaurant_holidays (
    holiday_id    INT         NOT NULL AUTO_INCREMENT,
    restaurant_id INT         NOT NULL,
    holiday_date  DATE        NOT NULL,
    reason        VARCHAR(50)     NULL,
    CONSTRAINT pk_restaurant_holidays PRIMARY KEY (holiday_id),
    CONSTRAINT fk_holidays_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
    CONSTRAINT uq_holidays_date UNIQUE (restaurant_id, holiday_date)
);

INSERT INTO restaurant_holidays (restaurant_id, holiday_date, reason) VALUES
    (1, '2026-07-15', '내부 수리'),
    (6, '2026-07-15', NULL),
    (1, '2026-07-16', '내부 수리');

SELECT h.holiday_date,
    r.name AS restaurant_name,
    h.reason
FROM restaurant_holidays h
JOIN restaurants r ON h.restaurant_id = r.restaurant_id
ORDER BY h.holiday_date, r.restaurant_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| holiday_date | restaurant_name | reason |
|---|---|---|
| 2026-07-15 | 서면옛날돼지국밥 | 내부 수리 |
| 2026-07-15 | 대연동크런치치킨 | NULL |
| 2026-07-16 | 서면옛날돼지국밥 | 내부 수리 |


> **해설** `UNIQUE (restaurant_id, holiday_date)`는 **두 열의 조합**이 중복되면 안 된다는 뜻입니다. 같은 날 다른 가게(1번, 6번)는 괜찮고, 같은 가게의 다른 날(15일, 16일)도 괜찮습니다.

### 문제 6. 실패할 INSERT 고르기 ★★

> 문제 5의 테이블에 아래 INSERT를 **하나씩** 실행한다고 할 때, 실패하는 것을 모두 고르고 에러 번호를 예측하세요. 예측한 뒤 직접 실행해서 확인하세요.

```sql
-- (가)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (6, '2026-07-16');
-- (나)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (1, '2026-07-15');
-- (다)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (99, '2026-07-20');
-- (라)
INSERT INTO restaurant_holidays (restaurant_id, reason) VALUES (2, '명절');
```

> **해설**
> - (가) **성공** — 6번 가게의 16일은 아직 없음
> - (나) **1062** Duplicate entry '1-2026-07-15' for key 'uq_holidays_date' — 같은 가게·같은 날짜
> - (다) **1452** Cannot add or update a child row — 99번 가게는 없음
> - (라) **1364** Field 'holiday_date' doesn't have a default value — NOT NULL 열을 생략했고 기본값도 없음 (값을 직접 NULL로 넣으면 1048)

### 문제 7. 메뉴 옵션 테이블 ★★★

> **개발팀** "곱빼기 +1,000원", "치즈 추가 +2,000원" 같은 **메뉴 옵션**을 저장할 `menu_options` 테이블을 설계해 주세요.
> - 옵션은 하나의 메뉴에 속하고(`menus` 참조, `fk_options_menu`), **메뉴가 삭제되면 옵션도 함께 삭제**
> - 옵션 이름 필수, 추가 금액은 **0원 이상**(`ck_options_price`), 기본 0원
> - 같은 메뉴에 같은 이름의 옵션은 하나만(`uq_options_name`)
> - PK는 `option_id` 자동 증가
>
> 만든 뒤 짜장면(`menu_id = 35`)에 '곱빼기' 1,000원, '계란 프라이' 1,500원, '면 추가 없음' 0원을 넣고, **메뉴명·옵션명·옵션 포함 가격**을 조회하세요.

- 확인 열: `menu_name`, `option_name`, `price_with_option`
- 순서: 옵션 포함 가격 순

**정답 SQL**

```sql
CREATE TABLE menu_options (
    option_id    INT         NOT NULL AUTO_INCREMENT,
    menu_id      INT         NOT NULL,
    name         VARCHAR(30) NOT NULL,
    extra_price  INT         NOT NULL DEFAULT 0,
    CONSTRAINT pk_menu_options PRIMARY KEY (option_id),
    CONSTRAINT fk_options_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id) ON DELETE CASCADE,
    CONSTRAINT uq_options_name UNIQUE (menu_id, name),
    CONSTRAINT ck_options_price CHECK (extra_price >= 0)
);

INSERT INTO menu_options (menu_id, name, extra_price) VALUES
    (35, '곱빼기', 1000),
    (35, '계란 프라이', 1500),
    (35, '면 추가 없음', 0);

SELECT m.name AS menu_name,
    mo.name AS option_name,
    m.price + mo.extra_price AS price_with_option
FROM menu_options mo
JOIN menus m ON mo.menu_id = m.menu_id
ORDER BY price_with_option, mo.option_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| menu_name | option_name | price_with_option |
|---|---|---|
| 짜장면 | 면 추가 없음 | 7000 |
| 짜장면 | 곱빼기 | 8000 |
| 짜장면 | 계란 프라이 | 8500 |


> **해설** 메뉴 옵션은 메뉴 없이는 의미가 없는 **종속 데이터**라 `ON DELETE CASCADE`가 어울리는 드문 경우입니다. 반대로 주문 상세(`order_items`)는 메뉴가 사라져도 과거 주문 기록으로 남아야 하므로 CASCADE를 걸면 안 됩니다. 같은 "메뉴의 자식"이라도 **데이터의 성격**에 따라 정책이 다릅니다.

### 문제 8. 기사 월 정산 테이블 ★★★

> **정산팀** 기사별 **월 정산 내역**을 저장할 테이블 `rider_settlements`를 직접 설계해 주세요. 열 이름·타입·제약조건은 자유지만 아래 규칙을 모두 DB가 강제해야 합니다.
> 1. 정산 대상 기사는 실제로 존재해야 한다
> 2. 정산 월은 `'2026-06'` 같은 `YYYY-MM` 형식이다
> 3. 같은 기사·같은 월의 정산은 한 번만 존재한다
> 4. 배달 건수와 정산 금액은 0 이상이다
> 5. 지급 여부를 기록하고, 처음엔 미지급이다
> 6. 지급했으면 지급 일시가 있어야 하고, 미지급이면 지급 일시는 비어 있어야 한다
>
> 만든 뒤 `information_schema.table_constraints`로 제약조건 목록을 확인하세요.

- 확인 열: `constraint_name`, `constraint_type` (제약 이름은 예시 답안 기준)

**정답 SQL**

```sql
CREATE TABLE rider_settlements (
    settlement_id   INT       NOT NULL AUTO_INCREMENT,
    rider_id        INT       NOT NULL,
    settle_month    CHAR(7)   NOT NULL,
    delivery_count  INT       NOT NULL DEFAULT 0,
    amount          INT       NOT NULL DEFAULT 0,
    is_paid         BOOLEAN   NOT NULL DEFAULT FALSE,
    paid_at         DATETIME      NULL,
    CONSTRAINT pk_rider_settlements PRIMARY KEY (settlement_id),
    CONSTRAINT fk_settlements_rider FOREIGN KEY (rider_id) REFERENCES riders (rider_id),
    CONSTRAINT uq_settlements_month UNIQUE (rider_id, settle_month),
    CONSTRAINT ck_settlements_month CHECK (settle_month REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_settlements_count CHECK (delivery_count >= 0),
    CONSTRAINT ck_settlements_amount CHECK (amount >= 0),
    CONSTRAINT ck_settlements_paid CHECK (
        (is_paid = TRUE AND paid_at IS NOT NULL)
        OR (is_paid = FALSE AND paid_at IS NULL))
);

SELECT constraint_name AS constraint_name,
    constraint_type AS constraint_type
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
    AND table_name = 'rider_settlements'
ORDER BY constraint_type, constraint_name;
```

<sub>▶ 실행 결과 · 7행</sub>

| constraint_name | constraint_type |
|---|---|
| ck_settlements_amount | CHECK |
| ck_settlements_count | CHECK |
| ck_settlements_month | CHECK |
| ck_settlements_paid | CHECK |
| fk_settlements_rider | FOREIGN KEY |
| PRIMARY | PRIMARY KEY |
| uq_settlements_month | UNIQUE |


> **해설**
> - 규칙 2: `REGEXP`(정규 표현식)로 형식을 검사합니다. `'2026-13'`, `'26-06'`, `'2026/06'`은 모두 거부됩니다. `DATE` 타입으로 매월 1일(`2026-06-01`)을 저장하는 설계도 좋은 답입니다 — 날짜 함수를 바로 쓸 수 있다는 장점이 있습니다.
> - 규칙 6: **두 열의 상태가 서로 맞아야 한다**는 규칙도 CHECK 하나로 강제됩니다. "지급 완료인데 지급 일시가 없는" 데이터는 애플리케이션 버그로 흔히 생기는데, DB가 막아 줍니다.
> - 정산 금액을 `orders`에서 집계해 이 테이블에 넣는 작업(`INSERT … SELECT`)은 Ch08에서 합니다.
