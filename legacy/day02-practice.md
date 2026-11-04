# Day 2 실습 문제 — 제약조건 & ALTER TABLE

> **한입배달 시나리오**: 한입배달 개발팀에 합류한 당신은 DB 구조를 설계하고 관리하는 업무를 맡았습니다.  
> 팀장이 요청한 아래 8가지 작업을 수행해보세요.

---

## 준비 사항

실습 전에 Day 2 스크립트가 실행되어 있어야 합니다.

```sql
USE hanip_delivery;

-- 현재 테이블 목록 확인
SHOW TABLES;
-- restaurants, customers, menus 3개가 있어야 합니다
```

---

## 문제 1. ⭐ 배달 라이더 테이블 생성

> 팀장: "배달 라이더를 관리하는 테이블이 필요해요.  
> 라이더마다 고유 번호를 자동으로 부여하고, 이름과 전화번호는 반드시 있어야 합니다.  
> 전화번호는 중복되면 안 되고요."

**요구사항:**
- 테이블명: `delivery_riders`
- 컬럼 구성:

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|---------|------|
| id | INT | PK, AUTO_INCREMENT | 라이더 번호 (자동) |
| name | VARCHAR(30) | NOT NULL | 라이더 이름 (필수) |
| phone | VARCHAR(20) | UNIQUE NOT NULL | 전화번호 (중복 불가, 필수) |
| region | VARCHAR(50) | NOT NULL | 담당 지역 (필수) |
| is_active | BOOLEAN | DEFAULT TRUE | 활동 여부 (기본: 활동 중) |
| joined_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 입사일 (자동) |

**힌트:** `PRIMARY KEY AUTO_INCREMENT`는 항상 붙어다닙니다.

<details>
<summary>정답 보기</summary>

```sql
CREATE TABLE delivery_riders (
    id        INT          PRIMARY KEY AUTO_INCREMENT,
    name      VARCHAR(30)  NOT NULL,
    phone     VARCHAR(20)  UNIQUE NOT NULL,
    region    VARCHAR(50)  NOT NULL,
    is_active BOOLEAN      DEFAULT TRUE,
    joined_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- 구조 확인
DESC delivery_riders;

-- 테스트 데이터 삽입 (id는 자동으로 입력됩니다)
INSERT INTO delivery_riders (name, phone, region) VALUES
('홍길동', '010-1111-0001', '해운대구'),
('김배달', '010-1111-0002', '수영구'),
('이라이더', '010-1111-0003', '부산진구');

SELECT * FROM delivery_riders;
```

**예상 결과:**

| id | name   | phone         | region  | is_active | joined_at           |
|----|--------|---------------|---------|-----------|---------------------|
| 1  | 홍길동  | 010-1111-0001 | 해운대구 | 1         | 2026-04-13 09:00:00 |
| 2  | 김배달  | 010-1111-0002 | 수영구   | 1         | 2026-04-13 09:00:00 |
| 3  | 이라이더 | 010-1111-0003 | 부산진구 | 1         | 2026-04-13 09:00:00 |

**핵심 포인트:**
- `id`를 INSERT 할 때 명시하지 않았지만 자동으로 1, 2, 3이 부여됩니다.
- `is_active`와 `joined_at`도 명시하지 않았지만 DEFAULT 값이 들어갑니다.

</details>

---

## 문제 2. ⭐ 관리자 테이블 생성

> 팀장: "한입배달 서비스를 관리하는 관리자 계정 테이블이 필요합니다.  
> 관리자 ID와 이메일은 절대 중복되면 안 되고, 이름과 이메일은 반드시 입력해야 합니다."

**요구사항:**
- 테이블명: `admins`
- 컬럼 구성:

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|---------|------|
| id | INT | PK, AUTO_INCREMENT | 관리자 번호 |
| username | VARCHAR(30) | UNIQUE NOT NULL | 로그인 ID (중복 불가, 필수) |
| email | VARCHAR(100) | UNIQUE NOT NULL | 이메일 (중복 불가, 필수) |
| full_name | VARCHAR(50) | NOT NULL | 실명 (필수) |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 생성일 |

**힌트:** UNIQUE와 NOT NULL은 동시에 사용할 수 있습니다: `컬럼명 타입 UNIQUE NOT NULL`

<details>
<summary>정답 보기</summary>

```sql
CREATE TABLE admins (
    id         INT          PRIMARY KEY AUTO_INCREMENT,
    username   VARCHAR(30)  UNIQUE NOT NULL,
    email      VARCHAR(100) UNIQUE NOT NULL,
    full_name  VARCHAR(50)  NOT NULL,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- 구조 확인
DESC admins;

-- 정상 삽입 테스트
INSERT INTO admins (username, email, full_name) VALUES
('admin01', 'admin01@hanip.com', '김관리자'),
('admin02', 'admin02@hanip.com', '이관리자');

-- UNIQUE 위반 테스트 (에러 발생 예상)
-- INSERT INTO admins (username, email, full_name) VALUES
-- ('admin01', 'new@hanip.com', '박관리자');
-- Error Code: 1062. Duplicate entry 'admin01' for key 'admins.username'

SELECT * FROM admins;
```

**핵심 포인트:**
- `username`과 `email` 모두 UNIQUE이므로 둘 중 하나라도 중복이면 에러가 발생합니다.
- NOT NULL이므로 어느 한 컬럼도 비워둘 수 없습니다.

</details>

---

## 문제 3. ⭐ 쿠폰 테이블 생성

> 팀장: "이벤트 쿠폰을 관리하는 테이블을 만들어주세요.  
> 할인율은 기본 10%, 쿠폰 활성화 여부는 기본적으로 활성화 상태이고,  
> 만료일을 설정하지 않으면 NULL로 두세요 (무기한 쿠폰)."

**요구사항:**
- 테이블명: `coupons`
- 컬럼 구성:

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|---------|------|
| id | INT | PK, AUTO_INCREMENT | 쿠폰 번호 |
| coupon_code | VARCHAR(20) | UNIQUE NOT NULL | 쿠폰 코드 |
| discount_rate | INT | DEFAULT 10 | 할인율 % (기본: 10) |
| min_order_amount | INT | DEFAULT 0 | 최소 주문 금액 (기본: 0) |
| is_active | BOOLEAN | DEFAULT TRUE | 활성화 여부 (기본: 활성화) |
| expires_at | DATE | (없음 — NULL 허용) | 만료일 (선택) |

**힌트:** DEFAULT는 숫자, 문자열, BOOLEAN 모두 설정 가능합니다.

<details>
<summary>정답 보기</summary>

```sql
CREATE TABLE coupons (
    id                INT         PRIMARY KEY AUTO_INCREMENT,
    coupon_code       VARCHAR(20) UNIQUE NOT NULL,
    discount_rate     INT         DEFAULT 10,
    min_order_amount  INT         DEFAULT 0,
    is_active         BOOLEAN     DEFAULT TRUE,
    expires_at        DATE
);

-- 구조 확인
DESC coupons;

-- 다양한 케이스로 삽입
INSERT INTO coupons (coupon_code) VALUES
    ('WELCOME2026');                                         -- 모두 기본값 사용

INSERT INTO coupons (coupon_code, discount_rate, min_order_amount) VALUES
    ('SUMMER20', 20, 15000);                                -- 할인율과 최소금액 지정

INSERT INTO coupons (coupon_code, discount_rate, expires_at) VALUES
    ('LIMITED30', 30, '2026-12-31');                        -- 만료일 있는 쿠폰

SELECT * FROM coupons;
```

**예상 결과:**

| id | coupon_code | discount_rate | min_order_amount | is_active | expires_at |
|----|-------------|---------------|-----------------|-----------|------------|
| 1  | WELCOME2026 | 10            | 0               | 1         | NULL       |
| 2  | SUMMER20    | 20            | 15000           | 1         | NULL       |
| 3  | LIMITED30   | 30            | 0               | 1         | 2026-12-31 |

**핵심 포인트:**
- 명시하지 않은 컬럼들(`discount_rate`, `min_order_amount`, `is_active`)에 DEFAULT 값이 자동 적용됩니다.
- `expires_at`은 제약조건이 없으므로 NULL이 그대로 들어갑니다.

</details>

---

## 문제 4. ⭐⭐ 기존 테이블에 컬럼 추가 (CHECK 포함)

> 팀장: "menus 테이블에 매운 맛 단계(spicy_level)를 추가해주세요.  
> 기본값은 0(맵지 않음)이고, 0에서 5 사이의 정수만 허용해야 합니다.  
> 이미 있는 테이블이니까 ALTER TABLE로 추가해야 해요."

**요구사항:**
- 대상 테이블: `menus`
- 추가할 컬럼: `spicy_level INT DEFAULT 0 CHECK (spicy_level BETWEEN 0 AND 5)`

**작업 순서:**
1. ALTER TABLE로 컬럼 추가
2. DESC로 구조 확인
3. 정상 데이터 UPDATE 테스트 (id 1~3 메뉴에 각각 0, 2, 4 설정)
4. CHECK 위반 데이터 테스트 (spicy_level = 6 으로 UPDATE 시도)

**힌트:** `ALTER TABLE 테이블명 ADD COLUMN 컬럼명 타입 제약조건;`

<details>
<summary>정답 보기</summary>

```sql
-- 1. 컬럼 추가
ALTER TABLE menus
    ADD COLUMN spicy_level INT DEFAULT 0 CHECK (spicy_level BETWEEN 0 AND 5);

-- 2. 구조 확인
DESC menus;

-- 3. 정상 데이터 업데이트
UPDATE menus SET spicy_level = 0 WHERE id = 1;   -- 갈비탕 (맵지 않음)
UPDATE menus SET spicy_level = 2 WHERE id = 2;   -- 소갈비구이 (약간 매움)
UPDATE menus SET spicy_level = 4 WHERE id = 8;   -- 짬뽕 (매움)

-- 변경 확인
SELECT id, menu_name, price, spicy_level FROM menus WHERE id IN (1, 2, 8);

-- 4. CHECK 위반 테스트 (에러 발생 예상)
UPDATE menus SET spicy_level = 6 WHERE id = 1;
-- Error Code: 3819. Check constraint 'menus_spicy_level_check' is violated.

-- 올바른 값으로 재시도
UPDATE menus SET spicy_level = 5 WHERE id = 1;   -- 5는 BETWEEN 0 AND 5 만족
```

**예상 에러 메시지:**
```
Error Code: 3819. Check constraint 'menus_chk_2' is violated.
```

**핵심 포인트:**
- 기존 테이블에 데이터가 있어도 `ADD COLUMN`은 안전합니다 (기존 행에는 DEFAULT 값 적용).
- `CHECK (spicy_level BETWEEN 0 AND 5)`는 0, 1, 2, 3, 4, 5만 허용합니다.
- 6 이상이나 음수는 에러가 발생합니다.

</details>

---

## 문제 5. ⭐⭐ 컬럼 추가 후 UNIQUE 제약조건 설정

> 팀장: "restaurants 테이블에 가게 전화번호(phone) 컬럼을 추가해주세요.  
> 나중에 데이터를 채워 넣을 예정이니 NULL은 허용해도 됩니다.  
> 단, 전화번호가 입력된 경우에는 중복이 없어야 합니다."

**요구사항:**
- 대상 테이블: `restaurants`
- 추가할 컬럼: `phone VARCHAR(20) UNIQUE`
- 테스트: 가게 1, 2번에 전화번호 입력 → 이미 존재하는 번호로 또 입력 시도

**작업 순서:**
1. ALTER TABLE로 phone 컬럼 추가 (UNIQUE 포함)
2. id 1번 가게에 '051-111-1001' 입력
3. id 2번 가게에 '051-111-1002' 입력
4. id 3번 가게에 '051-111-1001' 입력 시도 (에러 예상)
5. 올바른 번호로 재입력

**힌트:** `ALTER TABLE restaurants ADD COLUMN phone VARCHAR(20) UNIQUE;`

<details>
<summary>정답 보기</summary>

```sql
-- 1. 컬럼 추가 (UNIQUE, NULL 허용)
ALTER TABLE restaurants
    ADD COLUMN phone VARCHAR(20) UNIQUE;

-- 구조 확인
DESC restaurants;

-- 2~3. 가게 전화번호 입력
UPDATE restaurants SET phone = '051-111-1001' WHERE id = 1;
UPDATE restaurants SET phone = '051-111-1002' WHERE id = 2;

-- 4. 중복 번호 입력 시도 (에러 예상)
UPDATE restaurants SET phone = '051-111-1001' WHERE id = 3;
-- Error Code: 1062. Duplicate entry '051-111-1001' for key 'restaurants.phone'

-- 5. 올바른 번호로 재입력
UPDATE restaurants SET phone = '051-111-1003' WHERE id = 3;

-- 확인 (NULL이 있는 행도 표시)
SELECT id, name, phone FROM restaurants ORDER BY id;
```

**예상 에러 메시지:**
```
Error Code: 1062. Duplicate entry '051-111-1001' for key 'restaurants.phone'
```

**핵심 포인트:**
- `UNIQUE` 제약조건은 NULL 값에는 적용되지 않습니다.
  - id 4~10번 가게는 phone이 NULL이지만, NULL끼리는 중복으로 보지 않습니다.
- 실제 값(NULL이 아닌 값)만 중복 검사가 이루어집니다.
- 이 특성 덕분에 "있으면 유일해야 하고, 없어도 되는" 컬럼에 UNIQUE를 쓸 수 있습니다.

</details>

---

## 문제 6. ⭐⭐ CHECK 제약조건 위반 시나리오

> 팀장: "새로운 메뉴를 등록하는데 담당자가 실수로 가격을 0원이나 음수로 입력하려 합니다.  
> CHECK 제약조건이 실제로 막아주는지 확인하고, 올바른 데이터로 다시 입력하세요."

**시나리오:**
- 한 담당자가 '이벤트 무료 시식' 메뉴를 0원으로 등록 시도
- 다른 담당자가 '환불 이벤트' 메뉴를 -5000원으로 등록 시도
- CHECK 에러 메시지를 확인
- 최소 가격 1원으로 수정하여 정상 등록

**힌트:** `menus` 테이블의 `price` 컬럼에는 `CHECK (price > 0)` 제약조건이 있습니다.

<details>
<summary>정답 보기</summary>

```sql
-- 에러 1: 가격이 0원 (CHECK 위반)
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (1, '이벤트 무료 시식', 0);
-- Error Code: 3819. Check constraint 'menus_chk_1' is violated.

-- 에러 2: 가격이 음수 (CHECK 위반)
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (1, '환불 이벤트', -5000);
-- Error Code: 3819. Check constraint 'menus_chk_1' is violated.

-- 해결: 1원 이상의 가격으로 정상 등록
INSERT INTO menus (restaurant_id, menu_name, price, menu_description)
VALUES (1, '이벤트 시식 할인', 1000, '이벤트 기간 한정 특별 가격');

-- 확인
SELECT id, restaurant_id, menu_name, price
FROM menus
WHERE restaurant_id = 1
ORDER BY id;
```

**에러 메시지 전체:**
```
Error Code: 3819. Check constraint 'menus_chk_1' is violated.
```

**추가 실습 — rating CHECK 위반:**
```sql
-- restaurants 테이블의 rating에 6.0을 넣으면? (DECIMAL(2,1) 범위 초과)
-- rating 컬럼에 별도 CHECK는 없지만 DECIMAL(2,1)이 소수점 1자리 정수 1자리 = 최대 9.9
UPDATE restaurants SET rating = 6.0 WHERE id = 1;
-- 경고만 발생하거나 정상 처리됨 (CHECK가 없으면 타입 범위 안에서 허용)
-- 이것이 CHECK 제약조건이 필요한 이유입니다!
```

**핵심 포인트:**
- CHECK 제약조건은 비즈니스 규칙(가격 > 0, 수량 >= 0 등)을 DB 레벨에서 강제합니다.
- 애플리케이션 코드에서만 검증하면 직접 DB에 접근할 때 우회가 가능합니다.
- CHECK가 없으면 `DECIMAL(2,1)` 타입 범위 안이라면 값이 들어갑니다.

</details>

---

## 문제 7. ⭐⭐⭐ UNIQUE 위반 해결 시나리오

> 팀장: "고객 '박지훈' 씨가 전화번호를 바꿨는데, 새 번호가 이미 다른 고객으로 등록되어 있대요.  
> 에러 상황을 재현하고, 올바르게 해결하는 방법을 보여주세요.  
> 그리고 혹시 이메일이 NULL인 고객들을 찾아서 이메일을 업데이트하는 작업도 해주세요."

**시나리오 1 — 전화번호 중복:**
1. id 3번 고객(박지훈)의 phone을 id 1번 고객(김민준)의 번호로 변경 시도
2. 에러 확인
3. 새로운 번호로 올바르게 변경

**시나리오 2 — NULL 이메일 업데이트:**
1. 이메일이 NULL인 고객 목록 조회
2. 각 고객에게 이메일 업데이트
3. 업데이트 후 NULL 이메일 고객이 없는지 재확인

**힌트:**
- `IS NULL` 조건으로 NULL 값을 찾습니다.
- UNIQUE 컬럼은 NULL이 여러 개 있어도 되지만, 실제 값은 중복 불가합니다.

<details>
<summary>정답 보기</summary>

```sql
-- === 시나리오 1: 전화번호 중복 에러 ===

-- 현재 상태 확인
SELECT id, name, phone FROM customers WHERE id IN (1, 3);

-- 에러 유발: 박지훈(id=3)의 번호를 김민준(id=1)과 동일하게 변경
UPDATE customers
SET phone = '010-1234-5678'  -- 이미 id=1이 사용 중인 번호
WHERE id = 3;
-- Error Code: 1062. Duplicate entry '010-1234-5678' for key 'customers.phone'

-- 해결: 새로운 고유한 번호로 변경
UPDATE customers
SET phone = '010-3456-0099'
WHERE id = 3;

-- 확인
SELECT id, name, phone FROM customers WHERE id = 3;


-- === 시나리오 2: NULL 이메일 고객 찾아서 업데이트 ===

-- NULL 이메일 고객 조회
SELECT id, name, phone, email
FROM customers
WHERE email IS NULL;

-- 예상 결과: id 4(최수아), 6(한유진), 10(윤성호)

-- 각 고객 이메일 업데이트
UPDATE customers SET email = 'sooa.choi@gmail.com'  WHERE id = 4;
UPDATE customers SET email = 'yujin.han@naver.com'  WHERE id = 6;
UPDATE customers SET email = 'sungho.yoon@daum.net' WHERE id = 10;

-- 업데이트 결과 확인
SELECT id, name, email FROM customers ORDER BY id;

-- NULL이 남아있는지 확인
SELECT COUNT(*) AS null_email_count
FROM customers
WHERE email IS NULL;
-- 결과: 0 (모두 채워짐)
```

**예상 에러 메시지:**
```
Error Code: 1062. Duplicate entry '010-1234-5678' for key 'customers.phone'
```

**핵심 포인트:**
- UNIQUE 제약조건은 `UPDATE` 시에도 동작합니다 (INSERT 때만이 아님).
- `WHERE email IS NULL`은 이메일이 없는 행만 찾습니다.
  - `WHERE email = NULL`은 작동하지 않습니다 — NULL은 `=`로 비교하면 안 됩니다!
- 이메일처럼 선택 입력 필드는 UNIQUE이지만 NULL을 여러 개 허용합니다.

</details>

---

## 문제 8. ⭐⭐⭐ orders 테이블 설계 및 생성

> 팀장: "드디어 주문 테이블을 만들 차례입니다! (실제 서비스 핵심 테이블이에요)  
> 주문 한 건에는 어떤 정보가 필요한지 생각해보고,  
> 적절한 제약조건과 DEFAULT 값을 설정해서 테이블을 완성해주세요."

**포함해야 할 정보:**
- 주문 번호 (자동 발급)
- 어떤 고객이 주문했는가 (customer_id)
- 어느 가게에서 주문했는가 (restaurant_id)
- 어떤 메뉴를 주문했는가 (menu_id)
- 몇 개 주문했는가 (quantity — 기본값 1, 최소 1 이상)
- 주문 상태: '접수중', '조리중', '배달중', '완료', '취소' 중 하나
- 주문 일시 (자동)

**제약조건 설계 힌트:**
- `customer_id`, `restaurant_id`, `menu_id`는 모두 필수
- `quantity`는 0 이하일 수 없음 → `CHECK (quantity >= 1)`
- `status`는 특정 값만 허용 → `CHECK (status IN (...))`
- 주문 일시는 현재 시각으로 자동 설정

**도전 목표:** 테이블 생성 후 샘플 주문 3건을 INSERT 하고 결과를 조회하세요.

<details>
<summary>정답 보기</summary>

```sql
-- orders 테이블 생성
CREATE TABLE orders (
    id            INT          PRIMARY KEY AUTO_INCREMENT,
    customer_id   INT          NOT NULL,
    restaurant_id INT          NOT NULL,
    menu_id       INT          NOT NULL,
    quantity      INT          NOT NULL DEFAULT 1
                               CHECK (quantity >= 1),
    status        VARCHAR(10)  NOT NULL DEFAULT '접수중'
                               CHECK (status IN ('접수중', '조리중', '배달중', '완료', '취소')),
    order_date    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- 구조 확인
DESC orders;

-- 샘플 주문 3건 INSERT
INSERT INTO orders (customer_id, restaurant_id, menu_id) VALUES
    (1, 4, 10);  -- 김민준이 해운대통닭에서 후라이드치킨 1개 주문 (기본값 적용)

INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity) VALUES
    (2, 1, 1, 2);  -- 이서연이 부산명가갈비에서 갈비탕 2개

INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity, status) VALUES
    (3, 8, 22, 1, '조리중');  -- 박지훈이 연산동짬뽕왕에서 짬뽕 1개, 이미 조리 중

-- 결과 확인
SELECT * FROM orders;

-- CHECK 위반 테스트
-- 수량이 0인 주문 (에러 예상)
INSERT INTO orders (customer_id, restaurant_id, menu_id, quantity) VALUES (1, 1, 1, 0);
-- Error Code: 3819. Check constraint 'orders_chk_1' is violated.

-- 잘못된 상태값 (에러 예상)
INSERT INTO orders (customer_id, restaurant_id, menu_id, status) VALUES (1, 1, 1, '취소완료');
-- Error Code: 3819. Check constraint 'orders_chk_2' is violated.
```

**예상 결과:**

| id | customer_id | restaurant_id | menu_id | quantity | status | order_date          |
|----|-------------|---------------|---------|----------|--------|---------------------|
| 1  | 1           | 4             | 10      | 1        | 접수중  | 2026-04-13 09:00:00 |
| 2  | 2           | 1             | 1       | 2        | 접수중  | 2026-04-13 09:00:00 |
| 3  | 3           | 8             | 22      | 1        | 조리중  | 2026-04-13 09:00:00 |

**추가 도전 — 현재 테이블 한계 생각해보기:**
```sql
-- 지금 이 테이블의 문제점은 무엇일까요?
SELECT * FROM orders;

-- 문제 1: customer_id가 1000이어도 들어갑니다 (실제 고객이 아닌데!)
INSERT INTO orders (customer_id, restaurant_id, menu_id) VALUES (9999, 9999, 9999);
-- → Day 9에서 배울 FOREIGN KEY로 해결합니다

-- 문제 2: restaurant_id와 menu_id가 맞는 조합인지 검증 안 됨
-- → 애플리케이션 레벨에서 검증하거나, 복합 CHECK로 일부 해결 가능
```

**핵심 포인트:**
- `DEFAULT '접수중'`으로 새 주문은 항상 '접수중' 상태로 시작합니다.
- `CHECK (status IN (...))`로 정해진 상태값만 허용합니다.
- `quantity >= 1` CHECK로 0개나 음수 주문을 차단합니다.
- 이 테이블은 Day 9에서 `FOREIGN KEY`를 추가해 customer_id, restaurant_id, menu_id의 참조 무결성을 보장하게 됩니다.

</details>

---

## 정리 & 복습 체크리스트

실습을 마친 후 아래 항목을 스스로 점검해보세요.

- [ ] `PRIMARY KEY AUTO_INCREMENT`가 있으면 INSERT 시 id를 쓰지 않아도 되는 이유를 설명할 수 있다.
- [ ] `UNIQUE`와 `NOT NULL`을 같이 쓰는 경우와 `UNIQUE`만 쓰는 경우의 차이를 말할 수 있다.
- [ ] `DEFAULT` 값이 있는 컬럼은 INSERT 시 생략 가능한 이유를 설명할 수 있다.
- [ ] `CHECK` 제약조건 위반 시 어떤 에러(에러 코드)가 나는지 안다.
- [ ] `ALTER TABLE`로 컬럼을 추가/수정/삭제할 수 있다.
- [ ] `IS NULL`로 NULL 값을 가진 행을 찾을 수 있다.

---

> **다음 시간(Day 3) 예고:**  
> 오늘 만든 테이블에 INSERT/SELECT/UPDATE/DELETE를 마음껏 써봅니다.  
> 특히 **WHERE 없는 UPDATE/DELETE**가 왜 위험한지 직접 체험합니다!
