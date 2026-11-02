# Ch07. 테이블 설계와 제약조건 (DDL)

> **PART 2 · 쓰기** | 3시간 | 난이도 ★★
> 이전: [Ch06. 서브쿼리·집합·윈도우 함수](../ch06-subquery-window/README.md) | 다음: Ch08. 데이터 변경과 트랜잭션 (준비 중)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery07`**가 만들어집니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';   -- 지난 시간 hanip_delivery06 도 그대로 남아 있음
USE hanip_delivery07;
```

> 오늘부터는 테이블을 **만들고 바꿉니다.** 챕터별 DB를 쓰는 이유가 여기서 드러납니다. 오늘 `hanip_delivery07`를 아무리 바꿔도 지난 챕터 DB는 그대로이고, 다음 챕터는 다시 깨끗한 DB에서 시작합니다.

## 오늘의 요청

> **From.** 개발팀 한 팀장
>
> 다음 달에 **쿠폰 기능**이 나갑니다. 테이블 두 개가 필요해요.
> - **쿠폰 종류**: "첫 주문 3,000원 할인", "주말 15% 할인" 같은 쿠폰의 정의
> - **고객 보유 쿠폰**: 어떤 고객이 어떤 쿠폰을 언제 받았고, 썼는지
>
> 꼭 지켜야 할 규칙이 있어요. **쿠폰 코드는 중복 불가**, **할인액·할인율은 음수 불가**, **같은 쿠폰을 한 고객에게 두 번 지급 불가**, **없는 고객에게 쿠폰 지급 불가**. 애플리케이션에서도 검사하지만, DB에서 막아 주지 않으면 언젠가 반드시 뚫립니다.

지금까지는 이미 있는 테이블을 **읽기만** 했습니다. 오늘은 우리 DB가 왜 지금 모양인지 **해부**하고, 같은 원리로 쿠폰 테이블을 **직접 설계해서 만듭니다**. 완성 DDL은 [9절](#9-오늘의-요청-해결).

## 학습 목표

1. `SHOW CREATE TABLE`을 읽고 각 줄(타입·NULL·기본값·제약조건)의 의미를 설명한다.
2. 데이터의 성격에 맞는 **타입**(정수·소수·문자·날짜·참거짓)을 고른다.
3. `CREATE TABLE`로 테이블을 만들고, **제약조건 6종**(PK·NOT NULL·UNIQUE·DEFAULT·CHECK·FK)에 이름을 붙여 건다.
4. 제약조건 위반 에러(1048·1062·3819·1452·1451)를 읽고 원인을 설명한다.
5. `ALTER TABLE`로 구조를 바꾸고, `DROP`·`TRUNCATE`·`DELETE`의 차이를 설명한다.

---

## 1. 우리 테이블 해부하기

Ch01에서 `SHOW CREATE TABLE`로 FOREIGN KEY 한 줄만 찾아봤습니다. 오늘은 전부 읽습니다. 가장 짧은 `reviews` 테이블입니다.

```sql
SHOW CREATE TABLE reviews;
```

```sql
CREATE TABLE `reviews` (
  `review_id` int NOT NULL AUTO_INCREMENT COMMENT '리뷰 번호',
  `order_id` int NOT NULL COMMENT '주문 번호',
  `rating` tinyint NOT NULL COMMENT '별점 1~5',
  `content` varchar(500) DEFAULT NULL COMMENT '리뷰 내용 (별점만 남기면 NULL)',
  `created_at` datetime NOT NULL COMMENT '작성 일시',
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uq_reviews_order` (`order_id`),
  CONSTRAINT `fk_reviews_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  CONSTRAINT `ck_reviews_rating` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리뷰'
```

| 줄 | 읽는 법 | 막아 주는 사고 |
|---|---|---|
| `review_id int NOT NULL AUTO_INCREMENT` | 정수, 필수, 번호 자동 증가 | 번호 중복·누락 |
| `rating tinyint NOT NULL` | 작은 정수(-128~127), 필수 | 별점 없는 리뷰 |
| `content varchar(500) DEFAULT NULL` | 최대 500자, 비워도 됨 | — (선택 입력) |
| `PRIMARY KEY (review_id)` | 이 열로 행을 식별 | 같은 번호 리뷰 2개 |
| `UNIQUE KEY uq_reviews_order (order_id)` | 주문번호 중복 불가 | **한 주문에 리뷰 2개** |
| `FOREIGN KEY (order_id) REFERENCES orders` | 반드시 존재하는 주문 | **없는 주문에 대한 리뷰** |
| `CHECK (rating between 1 and 5)` | 1~5만 허용 | 별점 0점·10점 |
| `ENGINE=InnoDB` | 트랜잭션·FK를 지원하는 저장 엔진 | (Ch08) |

> 제약조건 하나하나가 **비즈니스 규칙**입니다. "주문 1건당 리뷰는 1개"라는 기획서 한 줄이 `UNIQUE` 한 줄이 됩니다. 테이블 설계는 규칙을 DB가 강제하도록 번역하는 일입니다.

---

## 2. 데이터 타입 고르기

### 2-1. 자주 쓰는 타입

| 분류 | 타입 | 범위·특징 | 한입배달에서 |
|---|---|---|---|
| 정수 | `TINYINT` | -128 ~ 127 | 별점 |
| | `INT` | 약 ±21억 | 번호(PK), 가격, 수량 |
| | `BIGINT` | 약 ±922경 | 로그·대규모 서비스의 PK |
| 소수 | `DECIMAL(p, s)` | 정확한 소수. 전체 p자리 중 소수 s자리 | 할인율 `DECIMAL(5,2)` |
| | `FLOAT` / `DOUBLE` | 근사값 (오차 있음) | 쓰지 않음 (위치 좌표 정도) |
| 문자 | `VARCHAR(n)` | 최대 n**글자**, 길이만큼 저장 | 이름, 주소, 메뉴명 |
| | `CHAR(n)` | 항상 n글자 고정 | 전화번호 `CHAR(13)` |
| | `TEXT` | 긴 글 (최대 약 6만 5천 바이트) | 공지 본문 |
| 날짜 | `DATE` | 날짜만 | 생년월일, 입점일 |
| | `DATETIME` | 날짜 + 시각 | 주문 일시 |
| | `TIME` | 시각만 | 영업 시작·종료 |
| | `TIMESTAMP` | 날짜+시각, 시간대 변환됨, 2038년까지 | 행 수정 시각 기록 |
| 참거짓 | `BOOLEAN` | 실제로는 `TINYINT(1)` | `is_open`, `is_sold_out` |

### 2-2. ⚠️ 돈에는 FLOAT를 쓰지 않는다

```sql
SELECT 0.1E0 + 0.2E0 AS float_sum,
    0.1 + 0.2 AS decimal_sum,
    (0.1E0 + 0.2E0 = 0.3E0) AS float_equal;
```

<sub>▶ 실행 결과 · 1행</sub>

| float_sum | decimal_sum | float_equal |
|---|---|---|
| 0.30000000000000004 | 0.3 | 0 |


`FLOAT`·`DOUBLE`은 2진수 근사값이라 `0.1 + 0.2`가 정확히 `0.3`이 아닙니다. 수천 건을 더하면 원 단위 오차가 생기고, `=` 비교가 실패합니다. **금액·비율은 `INT`(원 단위) 또는 `DECIMAL`.**

### 2-3. 범위와 길이를 넘으면 — 에러가 우리를 지킨다

연습용 테이블로 확인해 봅니다. (`INSERT`는 Ch08에서 자세히 배웁니다. 오늘은 "값을 넣어 본다"는 용도로만 씁니다.)

```sql
DROP TABLE IF EXISTS type_test;
CREATE TABLE type_test (
    score TINYINT,
    nickname VARCHAR(5)
);
```


```sql
INSERT INTO type_test (score, nickname) VALUES (300, '준일');
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1264. Out of range value for column 'score' at row 1
```


```sql
INSERT INTO type_test (score, nickname) VALUES (5, '부산광역시진구');
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1406. Data too long for column 'nickname' at row 1
```


> MySQL 8의 기본 **엄격 모드**(`STRICT_TRANS_TABLES`)가 잘못된 값을 거부합니다. 엄격 모드가 꺼진 서버에서는 300이 127로, 긴 문자열이 잘린 채로 **경고만 남기고 저장**됩니다. 운영 서버의 `sql_mode`를 꼭 확인하세요.
> `VARCHAR(5)`는 **5글자**입니다. 한글도 5글자까지 들어갑니다(바이트가 아님).

```sql
DROP TABLE type_test;
```


### 2-4. 타입 선택 체크리스트

1. 계산하나? → 숫자(`INT`/`DECIMAL`). 전화번호·우편번호처럼 **계산하지 않는 숫자**는 문자(`CHAR`/`VARCHAR`) — 앞자리 `0`이 사라지지 않게.
2. 돈인가? → `INT`(원 단위) 또는 `DECIMAL`. **FLOAT 금지.**
3. 길이가 고정인가? → `CHAR(n)`, 아니면 `VARCHAR(n)`. n은 넉넉하되 터무니없지 않게.
4. 날짜만? 시각까지? → `DATE` / `DATETIME`.
5. 예/아니오? → `BOOLEAN`, 열 이름은 `is_…`.

---

## 3. CREATE TABLE — 규칙 없는 테이블의 최후

쿠폰 테이블을 일단 **제약조건 없이** 만들어 봅니다.

```sql
DROP TABLE IF EXISTS coupons_draft;
CREATE TABLE coupons_draft (
    coupon_id INT,
    code VARCHAR(20),
    name VARCHAR(50),
    discount_amount INT
);
```


```sql
INSERT INTO coupons_draft (coupon_id, code, name, discount_amount) VALUES
    (1, 'WELCOME3000', '첫 주문 3,000원 할인', 3000),
    (1, 'WELCOME3000', NULL, -5000),
    (NULL, NULL, '이름만 있는 쿠폰', NULL);
```


```sql
SELECT * FROM coupons_draft;
```

<sub>▶ 실행 결과 · 3행</sub>

| coupon_id | code | name | discount_amount |
|---|---|---|---|
| 1 | WELCOME3000 | 첫 주문 3,000원 할인 | 3000 |
| 1 | WELCOME3000 | NULL | -5000 |
| NULL | NULL | 이름만 있는 쿠폰 | NULL |


번호가 같은 쿠폰, 이름 없는 쿠폰, **할인액이 -5,000원**(결제 금액이 오히려 늘어나는) 쿠폰이 아무 저항 없이 들어갔습니다. 이 테이블로 서비스를 열면 이 데이터는 언젠가 반드시 들어옵니다.

```sql
DROP TABLE coupons_draft;
```


---

## 4. 제약조건 6종

| 제약조건 | 의미 | 위반 시 에러 | 비유 |
|---|---|---|---|
| `PRIMARY KEY` | 행 식별자. NOT NULL + UNIQUE | 1062 / 1048 | 주민등록번호 |
| `NOT NULL` | 빈 값 금지 | 1048 | 필수 기입란 |
| `UNIQUE` | 중복 금지 (NULL은 여러 개 허용) | 1062 | 아이디 중복 확인 |
| `DEFAULT` | 값을 안 주면 넣을 기본값 | — | 기본 선택값 |
| `CHECK` | 조건을 만족하는 값만 | 3819 | 입력값 검사 |
| `FOREIGN KEY` | 다른 테이블에 존재하는 값만 | 1452 / 1451 | "존재하는 고객에게만" |

### 4-1. 제약조건에 이름 붙이기

```sql
-- 열 옆에 쓰기 (열 제약): 짧지만 이름이 자동 생성됨
code VARCHAR(20) NOT NULL UNIQUE

-- 아래에 따로 쓰기 (테이블 제약): 이름을 붙일 수 있음 ← 이 과정의 기본
CONSTRAINT uq_coupons_code UNIQUE (code)
```

이름을 붙이면 에러 메시지에 **어느 규칙을 어겼는지**가 그대로 나오고, 나중에 `ALTER TABLE … DROP CONSTRAINT 이름`으로 정확히 지울 수 있습니다. 이름 규칙: `pk_테이블`, `uq_테이블_열`, `ck_테이블_열`, `fk_테이블_참조대상`.

### 4-2. 쿠폰 종류 테이블

```sql
CREATE TABLE coupons (
    coupon_id        INT          NOT NULL AUTO_INCREMENT,
    code             VARCHAR(20)  NOT NULL,
    name             VARCHAR(50)  NOT NULL,
    discount_type    VARCHAR(10)  NOT NULL,
    discount_value   INT          NOT NULL,
    min_order_amount INT          NOT NULL DEFAULT 0,
    valid_days       INT          NOT NULL DEFAULT 30,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
    CONSTRAINT uq_coupons_code UNIQUE (code),
    CONSTRAINT ck_coupons_type CHECK (discount_type IN ('정액', '정률')),
    CONSTRAINT ck_coupons_value CHECK (
        (discount_type = '정액' AND discount_value > 0)
        OR (discount_type = '정률' AND discount_value BETWEEN 1 AND 50)
    ),
    CONSTRAINT ck_coupons_min CHECK (min_order_amount >= 0),
    CONSTRAINT ck_coupons_days CHECK (valid_days > 0)
);
```


> - `discount_type` + `discount_value` 한 쌍으로 "3,000원 할인(정액)"과 "15% 할인(정률)"을 함께 표현합니다.
> - CHECK에는 **여러 열을 조합한 조건**도 쓸 수 있습니다. 정률 쿠폰은 1~50%만 허용 — "100% 할인 쿠폰"이 실수로 만들어지는 사고를 막습니다.
> - `created_at`의 `DEFAULT CURRENT_TIMESTAMP`는 값을 안 주면 **저장 시각**을 넣어 줍니다.

정상 데이터를 넣어 봅니다. 기본값이 있는 열은 생략할 수 있습니다.

```sql
INSERT INTO coupons (code, name, discount_type, discount_value, min_order_amount, valid_days) VALUES
    ('WELCOME3000', '첫 주문 3,000원 할인', '정액', 3000, 15000, 30),
    ('WEEKEND15',   '주말 15% 할인',         '정률', 15,   20000, 7),
    ('VIP5000',     'VIP 5,000원 할인',      '정액', 5000, 25000, 60);
```


```sql
SELECT coupon_id, code, name, discount_type, discount_value, min_order_amount, valid_days, is_active
FROM coupons;
```

<sub>▶ 실행 결과 · 3행</sub>

| coupon_id | code | name | discount_type | discount_value | min_order_amount | valid_days | is_active |
|---|---|---|---|---|---|---|---|
| 1 | WELCOME3000 | 첫 주문 3,000원 할인 | 정액 | 3000 | 15000 | 30 | 1 |
| 2 | WEEKEND15 | 주말 15% 할인 | 정률 | 15 | 20000 | 7 | 1 |
| 3 | VIP5000 | VIP 5,000원 할인 | 정액 | 5000 | 25000 | 60 | 1 |


### 4-3. 규칙이 사고를 막는 장면

3절에서 아무 저항 없이 들어갔던 데이터를 다시 넣어 봅니다.

**① 코드 중복 — UNIQUE**

```sql
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('WELCOME3000', '중복 코드 쿠폰', '정액', 1000);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1062. Duplicate entry 'WELCOME3000' for key 'coupons.uq_coupons_code'
```


**② 이름 없음 — NOT NULL**

```sql
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('NONAME', NULL, '정액', 1000);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1048. Column 'name' cannot be null
```


**③ 음수 할인 — CHECK**

```sql
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('MINUS', '마이너스 쿠폰', '정액', -5000);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 3819. Check constraint 'ck_coupons_value' is violated.
```


**④ 100% 할인 — 여러 열 CHECK**

```sql
INSERT INTO coupons (code, name, discount_type, discount_value)
VALUES ('FREE', '전액 무료', '정률', 100);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 3819. Check constraint 'ck_coupons_value' is violated.
```


> 에러 메시지에 `ck_coupons_value`라는 **제약조건 이름**이 그대로 나옵니다. 이름을 붙인 보람이 있죠. 개발팀은 이 이름을 보고 어떤 규칙을 어겼는지 바로 압니다.

---

## 5. FOREIGN KEY — 테이블 사이의 약속

### 5-1. 고객 보유 쿠폰 테이블 (M : N 연결)

고객 한 명은 여러 쿠폰을, 쿠폰 하나는 여러 고객에게 지급됩니다(**다대다, M:N**). 관계형 DB는 M:N을 직접 표현할 수 없어서 **가운데에 연결 테이블**을 둡니다.

```
 customers 1 ──< customer_coupons >── 1 coupons
                      │ 0..1
                      └── orders (쿠폰을 쓴 주문)
```

```sql
CREATE TABLE customer_coupons (
    customer_coupon_id INT       NOT NULL AUTO_INCREMENT,
    customer_id        INT       NOT NULL,
    coupon_id          INT       NOT NULL,
    issued_at          DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at         DATETIME  NOT NULL,
    used_order_id      INT           NULL,
    CONSTRAINT pk_customer_coupons PRIMARY KEY (customer_coupon_id),
    CONSTRAINT fk_cc_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_cc_coupon   FOREIGN KEY (coupon_id)   REFERENCES coupons (coupon_id),
    CONSTRAINT fk_cc_order    FOREIGN KEY (used_order_id) REFERENCES orders (order_id),
    CONSTRAINT uq_cc_customer_coupon UNIQUE (customer_id, coupon_id),
    CONSTRAINT uq_cc_used_order UNIQUE (used_order_id),
    CONSTRAINT ck_cc_period CHECK (expires_at > issued_at)
);
```


| 줄 | 지키는 규칙 |
|---|---|
| `fk_cc_customer` | 존재하는 고객에게만 지급 |
| `fk_cc_coupon` | 존재하는 쿠폰만 지급 |
| `fk_cc_order` + `used_order_id NULL` | 미사용이면 NULL, 썼으면 실제 주문 번호 |
| `uq_cc_customer_coupon (customer_id, coupon_id)` | **같은 쿠폰을 한 고객에게 두 번 지급 불가** (두 열 조합의 UNIQUE) |
| `uq_cc_used_order` | 주문 1건에 쿠폰 1장만 (NULL은 여러 개 허용) |
| `ck_cc_period` | 만료일은 지급일 이후 |

```sql
INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at) VALUES
    (30, 1, '2026-06-28 16:30:00', '2026-07-28 16:30:00'),   -- 신규 가입 윤서아 → 첫 주문 쿠폰
    (1,  3, '2026-06-30 09:00:00', '2026-08-29 09:00:00'),   -- VIP 김민준
    (2,  3, '2026-06-30 09:00:00', '2026-08-29 09:00:00');   -- VIP 이서연
```


```sql
SELECT c.name AS customer_name,
    cp.name AS coupon_name,
    cc.issued_at,
    cc.expires_at,
    cc.used_order_id
FROM customer_coupons cc
JOIN customers c ON cc.customer_id = c.customer_id
JOIN coupons cp  ON cc.coupon_id   = cp.coupon_id
ORDER BY cc.customer_coupon_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| customer_name | coupon_name | issued_at | expires_at | used_order_id |
|---|---|---|---|---|
| 윤서아 | 첫 주문 3,000원 할인 | 2026-06-28 16:30:00 | 2026-07-28 16:30:00 | NULL |
| 김민준 | VIP 5,000원 할인 | 2026-06-30 09:00:00 | 2026-08-29 09:00:00 | NULL |
| 이서연 | VIP 5,000원 할인 | 2026-06-30 09:00:00 | 2026-08-29 09:00:00 | NULL |


### 5-2. FK가 막는 것 ① — 없는 대상을 가리키기 (1452)

```sql
INSERT INTO customer_coupons (customer_id, coupon_id, expires_at)
VALUES (999, 1, '2026-12-31 00:00:00');
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`hanip_delivery07`.`customer_coupons`, CONSTRAINT `fk_cc_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`))
```


### 5-3. 두 열 UNIQUE — 같은 쿠폰 두 번 지급 (1062)

```sql
INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
VALUES (1, 3, '2026-06-30 10:00:00', '2026-08-29 10:00:00');
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1062. Duplicate entry '1-3' for key 'customer_coupons.uq_cc_customer_coupon'
```


### 5-4. FK가 막는 것 ② — 참조되고 있는 부모 지우기 (1451)

```sql
DELETE FROM coupons WHERE coupon_id = 3;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1451. Cannot delete or update a parent row: a foreign key constraint fails (`hanip_delivery07`.`customer_coupons`, CONSTRAINT `fk_cc_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`coupon_id`))
```


> VIP 쿠폰을 받은 고객이 있는데 쿠폰 정의를 지우면, 고객 보유 쿠폰이 **존재하지 않는 쿠폰**을 가리키게 됩니다(고아 데이터). FK가 이를 막습니다.

### 5-5. ON DELETE — 부모가 지워질 때의 정책

FK에 정책을 지정할 수 있습니다.

| 옵션 | 부모 행이 삭제되면 자식 행은 | 예 |
|---|---|---|
| `RESTRICT` / `NO ACTION` (기본값) | **삭제를 막음** | 주문이 있는 고객은 못 지움 |
| `CASCADE` | 자식도 **같이 삭제** | 게시글 삭제 → 댓글도 삭제 |
| `SET NULL` | 자식의 FK 열을 **NULL로** | 기사 계정 삭제 → 주문의 기사 = NULL |

```sql
CONSTRAINT fk_cc_coupon FOREIGN KEY (coupon_id)
    REFERENCES coupons (coupon_id)
    ON DELETE RESTRICT
```

> ⚠️ `CASCADE`는 편하지만 위험합니다. 고객 한 명을 지웠는데 주문·주문상세·리뷰·쿠폰이 연쇄로 사라질 수 있습니다. 돈과 관련된 데이터는 **RESTRICT(기본값)**로 두고, 삭제 대신 `is_active = FALSE` 같은 **논리 삭제**를 씁니다. 우리 `restaurants.is_open`, `riders.is_active`가 그 예입니다.

---

## 6. ALTER TABLE — 운영 중인 테이블 고치기

서비스를 시작한 뒤에도 요구사항은 바뀝니다. 테이블을 지우고 다시 만들 수 없으니 `ALTER TABLE`로 고칩니다.

| 작업 | 문법 |
|---|---|
| 열 추가 | `ALTER TABLE t ADD COLUMN 열 타입 [제약] [AFTER 열]` |
| 타입·제약 변경 | `ALTER TABLE t MODIFY COLUMN 열 새타입 [제약]` |
| 이름 변경 | `ALTER TABLE t RENAME COLUMN 옛이름 TO 새이름` |
| 열 삭제 | `ALTER TABLE t DROP COLUMN 열` |
| 제약 추가 | `ALTER TABLE t ADD CONSTRAINT 이름 …` |
| 제약 삭제 | `ALTER TABLE t DROP CONSTRAINT 이름` (FK는 `DROP FOREIGN KEY 이름`) |

> **요청 변경**: "정률 쿠폰은 **최대 할인 금액**(예: 15%, 최대 5,000원)이 필요해요."

```sql
ALTER TABLE coupons
    ADD COLUMN max_discount INT NULL AFTER discount_value;
```


```sql
ALTER TABLE coupons
    ADD CONSTRAINT ck_coupons_max CHECK (max_discount IS NULL OR max_discount > 0);
```


```sql
UPDATE coupons SET max_discount = 5000 WHERE code = 'WEEKEND15';
```


```sql
SELECT code, discount_type, discount_value, max_discount FROM coupons;
```

<sub>▶ 실행 결과 · 3행</sub>

| code | discount_type | discount_value | max_discount |
|---|---|---|---|
| WELCOME3000 | 정액 | 3000 | NULL |
| WEEKEND15 | 정률 | 15 | 5000 |
| VIP5000 | 정액 | 5000 | NULL |


> - 이미 데이터가 있는 테이블에 `NOT NULL` 열을 추가하면 기존 행에 무엇을 넣을지 정해야 합니다(`DEFAULT` 필요). 그래서 새 열은 보통 **NULL 허용으로 추가 → 값 채우기 → 필요하면 NOT NULL로 MODIFY** 순서로 진행합니다.
> - 수백만 행 테이블의 ALTER는 몇 분~몇 시간 걸리고 그동안 테이블이 잠길 수 있습니다. 운영 DB에서는 DBA와 상의하고 사용자가 적은 시간에 합니다.

### 제약조건 확인하기

테이블에 걸린 제약조건 목록은 `information_schema`(DB에 대한 정보를 담은 시스템 DB)에서 조회합니다.

```sql
SELECT constraint_name AS constraint_name,
    constraint_type AS constraint_type
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
    AND table_name = 'customer_coupons'
ORDER BY constraint_type, constraint_name;
```

<sub>▶ 실행 결과 · 7행</sub>

| constraint_name | constraint_type |
|---|---|
| ck_cc_period | CHECK |
| fk_cc_coupon | FOREIGN KEY |
| fk_cc_customer | FOREIGN KEY |
| fk_cc_order | FOREIGN KEY |
| PRIMARY | PRIMARY KEY |
| uq_cc_customer_coupon | UNIQUE |
| uq_cc_used_order | UNIQUE |


---

## 7. DROP · TRUNCATE · DELETE

| 명령 | 분류 | 지우는 것 | 되돌리기 | AUTO_INCREMENT |
|---|---|---|---|---|
| `DELETE FROM t WHERE …` | DML | **조건에 맞는 행** | 트랜잭션이면 가능 (Ch08) | 유지 |
| `TRUNCATE TABLE t` | DDL | **모든 행** (구조는 남김) | 불가 | 1로 초기화 |
| `DROP TABLE t` | DDL | **테이블 자체** | 불가 | — |

FK로 참조되고 있는 테이블은 DROP도 막힙니다.

```sql
DROP TABLE coupons;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 3730. Cannot drop table 'coupons' referenced by a foreign key constraint 'fk_cc_coupon' on table 'customer_coupons'.
```


> 지우려면 자식(`customer_coupons`)부터 지우거나 FK를 먼저 제거해야 합니다. **만든 순서의 반대로 지운다**고 기억하세요. 우리 `setup.sql`이 DB 통째로 `DROP DATABASE` 하는 이유이기도 합니다.

> ⚠️ `DROP`과 `TRUNCATE`는 **되돌릴 수 없습니다.** 실무에서는 실행 전에 ① 지금 접속한 DB가 맞는지(`SELECT DATABASE();`) ② 백업이 있는지 확인하는 습관을 들이세요. 운영 DB와 개발 DB를 헷갈려 테이블을 날리는 사고는 생각보다 자주 일어납니다.

---

## 8. 설계 체크리스트

새 테이블을 만들 때 스스로 묻는 질문입니다.

1. **이 테이블의 한 행은 무엇인가?** (쿠폰 종류 1개 / 고객이 받은 쿠폰 1장)
2. **행을 식별하는 열(PK)은?** 의미 없는 번호(`AUTO_INCREMENT`)가 기본. 코드처럼 바뀔 수 있는 값은 PK 대신 UNIQUE로.
3. **반드시 있어야 하는 값은?** → NOT NULL. "없을 수 있다"에 업무적 이유가 있을 때만 NULL 허용.
4. **중복되면 안 되는 값·조합은?** → UNIQUE (두 열 조합 포함)
5. **허용 범위가 있는 값은?** → CHECK
6. **다른 테이블을 가리키는 값은?** → FK. 부모가 지워지면? → ON DELETE 정책
7. **이름 규칙**: 테이블 복수형, PK `단수_id`, FK는 참조 PK와 같은 이름, 제약조건 이름 붙이기

---

## 9. 오늘의 요청 해결

4-2절의 `coupons`와 5-1절의 `customer_coupons`, 6절의 `max_discount` 추가가 오늘의 결과물입니다. 개발팀에 넘길 최종 DDL은 이렇게 정리합니다.

```sql
CREATE TABLE coupons (
    coupon_id        INT          NOT NULL AUTO_INCREMENT  COMMENT '쿠폰 번호',
    code             VARCHAR(20)  NOT NULL                 COMMENT '쿠폰 코드',
    name             VARCHAR(50)  NOT NULL                 COMMENT '쿠폰 이름',
    discount_type    VARCHAR(10)  NOT NULL                 COMMENT '정액 / 정률',
    discount_value   INT          NOT NULL                 COMMENT '정액: 원, 정률: %',
    max_discount     INT              NULL                 COMMENT '정률 쿠폰 최대 할인액(원)',
    min_order_amount INT          NOT NULL DEFAULT 0       COMMENT '최소 주문 금액(원)',
    valid_days       INT          NOT NULL DEFAULT 30      COMMENT '지급 후 유효 일수',
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE    COMMENT '발급 가능 여부',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
    CONSTRAINT uq_coupons_code UNIQUE (code),
    CONSTRAINT ck_coupons_type CHECK (discount_type IN ('정액', '정률')),
    CONSTRAINT ck_coupons_value CHECK (
        (discount_type = '정액' AND discount_value > 0)
        OR (discount_type = '정률' AND discount_value BETWEEN 1 AND 50)),
    CONSTRAINT ck_coupons_max CHECK (max_discount IS NULL OR max_discount > 0),
    CONSTRAINT ck_coupons_min CHECK (min_order_amount >= 0),
    CONSTRAINT ck_coupons_days CHECK (valid_days > 0)
) COMMENT '쿠폰 종류';

CREATE TABLE customer_coupons (
    customer_coupon_id INT       NOT NULL AUTO_INCREMENT,
    customer_id        INT       NOT NULL,
    coupon_id          INT       NOT NULL,
    issued_at          DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at         DATETIME  NOT NULL,
    used_order_id      INT           NULL                  COMMENT '사용한 주문 (미사용 NULL)',
    CONSTRAINT pk_customer_coupons PRIMARY KEY (customer_coupon_id),
    CONSTRAINT fk_cc_customer FOREIGN KEY (customer_id)   REFERENCES customers (customer_id),
    CONSTRAINT fk_cc_coupon   FOREIGN KEY (coupon_id)     REFERENCES coupons (coupon_id),
    CONSTRAINT fk_cc_order    FOREIGN KEY (used_order_id) REFERENCES orders (order_id),
    CONSTRAINT uq_cc_customer_coupon UNIQUE (customer_id, coupon_id),
    CONSTRAINT uq_cc_used_order UNIQUE (used_order_id),
    CONSTRAINT ck_cc_period CHECK (expires_at > issued_at)
) COMMENT '고객 보유 쿠폰';
```

> 요청서의 규칙 네 가지가 각각 `uq_coupons_code`, `ck_coupons_value`, `uq_cc_customer_coupon`, `fk_cc_customer`로 번역됐습니다. **DB가 규칙을 강제하면 애플리케이션 버그가 있어도 잘못된 데이터는 저장되지 않습니다.**

## 정리

| 개념 | 핵심 |
|---|---|
| 타입 | 돈은 INT/DECIMAL(FLOAT 금지), 계산 안 하는 숫자는 문자, VARCHAR(n)은 글자 수 |
| `CREATE TABLE` | 열 정의 + 아래에 `CONSTRAINT 이름 …` |
| PK / NOT NULL / UNIQUE | 식별 / 필수 / 중복 금지 (두 열 조합 가능) |
| DEFAULT / CHECK | 기본값 / 허용 범위 (여러 열 조합 가능) |
| FK | 존재하는 값만. 부모 삭제는 기본 RESTRICT, CASCADE는 신중히 |
| M:N | 가운데 연결 테이블 + FK 두 개 + 조합 UNIQUE |
| `ALTER TABLE` | ADD / MODIFY / RENAME / DROP COLUMN, ADD / DROP CONSTRAINT |
| DROP · TRUNCATE · DELETE | 테이블 / 모든 행 / 조건 행. 앞의 둘은 되돌릴 수 없음 |
| 에러 번호 | 1048 NULL · 1062 중복 · 3819 CHECK · 1452 없는 부모 · 1451 자식 있는 부모 |

## 다음 챕터 예고

> **From.** 개발팀 한 팀장
> 테이블 고마워요! 이제 **주문 접수 로직**을 SQL로 짜 주세요. 주문 1건을 넣으려면 `orders`에 한 행, `order_items`에 여러 행, 쿠폰을 썼으면 `customer_coupons`에 사용 표시까지 해야 해요. **중간에 하나라도 실패하면 전부 없던 일**이 돼야 합니다. 주문은 들어갔는데 쿠폰만 안 쓰인 상태가 되면 큰일이에요.

INSERT·UPDATE·DELETE로 데이터를 바꾸는 법, 그리고 여러 작업을 **하나로 묶는** 트랜잭션 — Ch08입니다.

<!-- lecture:auto -->
