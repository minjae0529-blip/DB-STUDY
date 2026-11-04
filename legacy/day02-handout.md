# Day 2 — 테이블을 제대로 만들자: 제약조건

> "아무 데이터나 들어가면 안 되잖아요?"

---

## 1. Day 2 개요

### 오늘 배울 것

오늘은 Day 1에서 만든 테이블의 **심각한 문제점**을 직접 확인하고,  
**제약조건(Constraint)** 이라는 도구로 그 문제를 해결합니다.

### 학습 목표 5가지

1. 제약조건이 **왜 필요한지** 설명할 수 있다.
2. **PK, AUTO_INCREMENT, NOT NULL, UNIQUE, DEFAULT, CHECK** 6가지 제약조건을 직접 사용할 수 있다.
3. **CHAR와 VARCHAR의 차이**를 구분하고 상황에 맞게 선택할 수 있다.
4. `CREATE TABLE` 문에 제약조건을 포함하여 테이블을 생성할 수 있다.
5. `ALTER TABLE` 로 기존 테이블 구조를 수정할 수 있다.

### Day 1 복습 요약

| 배운 것 | 핵심 명령어 |
|---------|------------|
| 데이터베이스 생성 | `CREATE DATABASE hanip_delivery;` |
| 데이터베이스 선택 | `USE hanip_delivery;` |
| 테이블 생성 | `CREATE TABLE restaurants (...)` |
| 구조 확인 | `DESC restaurants;` |
| 데이터 타입 | `INT`, `VARCHAR(n)`, `DATE`, `DECIMAL(p,s)` |

> **Day 1의 핵심 복습**: 테이블을 만들 수는 있게 됐습니다.  
> **오늘의 핵심 질문**: 그런데 그 테이블에 **아무 데이터나 들어가도 되나요?**

---

## 2. 왜 제약조건이 필요한가?

### Day 1 테이블의 문제점 직접 확인

아래 코드를 실행하면 어떤 일이 벌어질까요?

```sql
-- Day 1에서 만든 허술한 테이블
CREATE TABLE restaurants_v1 (
    id       INT,
    name     VARCHAR(100),
    category VARCHAR(50)
);

-- 이상한 데이터를 마음껏 넣어봅니다
INSERT INTO restaurants_v1 VALUES (NULL, '테스트가게', '한식');  -- id가 NULL?
INSERT INTO restaurants_v1 VALUES (1,    '부산맛집A',  '한식');
INSERT INTO restaurants_v1 VALUES (1,    '부산맛집B',  '치킨');  -- id 1이 또?!
INSERT INTO restaurants_v1 VALUES (2,    NULL,         '피자');  -- 이름 없는 가게?
INSERT INTO restaurants_v1 VALUES (NULL, NULL,         NULL);   -- 전부 비어있다?

SELECT * FROM restaurants_v1;
```

**실행 결과:**

| id   | name     | category |
|------|----------|----------|
| NULL | 테스트가게 | 한식     |
| 1    | 부산맛집A | 한식     |
| 1    | 부산맛집B | 치킨     |
| 2    | NULL     | 피자     |
| NULL | NULL     | NULL     |

MySQL이 에러 없이 모두 INSERT를 허용했습니다. 이게 **문제**입니다.

### 발생하는 문제들

**문제 1: NULL ID — 이 가게는 누구인가?**
```sql
SELECT * FROM restaurants_v1 WHERE id = NULL;
-- 결과: 0건! NULL은 = 연산자로 찾을 수 없습니다.
```

**문제 2: 중복 ID — 어느 가게를 말하는 건가?**
```sql
SELECT * FROM restaurants_v1 WHERE id = 1;
-- 결과: 2건! 어느 가게인지 특정할 수 없습니다.
```

**문제 3: NULL 이름 — 앱 화면에 가게 이름이 비어있다.**
> 배달앱에서 가게 이름이 빈칸으로 표시된다면? 사용자 입장에서 최악의 경험입니다.

### "자물쇠 없는 창고" 비유

> 창고에 자물쇠가 없으면 아무나 들어와서 아무 물건이나 집어넣을 수 있습니다.  
> 창고 관리가 엉망이 되는 건 시간 문제죠.  
> **제약조건은 창고의 자물쇠입니다.**  
> "이 자리에는 반드시 이런 규격의 물건만 들어올 수 있다"고 규칙을 정하는 겁니다.

---

## 3. 제약조건 6가지

### 3-1. PRIMARY KEY (기본 키)

> "주민등록번호처럼, 모든 행을 유일하게 식별하는 값"

**설명:**
- 테이블의 **각 행을 구별하는 고유 식별자**입니다.
- 자동으로 **NOT NULL + UNIQUE** 두 가지가 적용됩니다.
- 테이블당 **하나만** 설정할 수 있습니다.

**문법:**

```sql
-- 방법 1: 컬럼 정의 옆에 직접 붙이기 (가장 일반적)
CREATE TABLE 테이블명 (
    id INT PRIMARY KEY,
    ...
);

-- 방법 2: 컬럼 정의 후 별도로 선언하기 (복합 PK에 사용)
CREATE TABLE 테이블명 (
    id   INT,
    ...
    PRIMARY KEY (id)
);
```

**예제:**

```sql
CREATE TABLE test_pk (
    id   INT PRIMARY KEY,
    name VARCHAR(50)
);

INSERT INTO test_pk VALUES (1, '가게A');    -- 성공
INSERT INTO test_pk VALUES (1, '가게B');    -- 에러! id 1 중복
INSERT INTO test_pk VALUES (NULL, '가게C'); -- 에러! PK는 NULL 불가
```

**에러 메시지:**
```
Error Code: 1062. Duplicate entry '1' for key 'test_pk.PRIMARY'
```

**주의사항:**
- PK 값은 **절대 변경하지 않는 것**이 원칙입니다.
- 한 번 삭제된 PK 번호는 재사용하지 않는 것이 좋습니다.
- 테이블당 **딱 하나**만 만들 수 있습니다 (여러 컬럼 묶음은 복합 PK).

---

### 3-2. AUTO_INCREMENT (자동 증가)

> "번호표 기계처럼, 다음 번호를 자동으로 발급해줍니다"

**설명:**
- 새 행이 INSERT 될 때마다 **자동으로 1씩 증가**하는 번호를 부여합니다.
- **항상 PRIMARY KEY와 함께** 사용합니다.
- id 값을 직접 입력할 필요가 없어집니다.

**문법:**

```sql
CREATE TABLE 테이블명 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ...
);
```

**예제:**

```sql
CREATE TABLE test_ai (
    id   INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50)
);

INSERT INTO test_ai (name) VALUES ('가게A');  -- id 자동: 1
INSERT INTO test_ai (name) VALUES ('가게B');  -- id 자동: 2
INSERT INTO test_ai (name) VALUES ('가게C');  -- id 자동: 3

SELECT * FROM test_ai;
```

**결과:**

| id | name  |
|----|-------|
| 1  | 가게A |
| 2  | 가게B |
| 3  | 가게C |

**중요한 특징:**
```sql
-- id 3번 행을 삭제해도 다음 INSERT는 4번부터 시작합니다
DELETE FROM test_ai WHERE id = 3;
INSERT INTO test_ai (name) VALUES ('가게D');  -- id는 4 (3이 아님!)
```

> 번호표 기계가 한 번 뽑힌 번호(3번)는 다시 발급하지 않는 것과 같습니다.  
> 중간에 빈 번호가 생겨도 괜찮습니다 — 그게 정상입니다.

---

### 3-3. NOT NULL (필수 입력)

> "종이 서류의 필수 기입란 — 비워두면 접수가 안 됩니다"

**설명:**
- 해당 컬럼에 **NULL(빈값)이 들어오는 것을 금지**합니다.
- 반드시 값이 있어야 하는 필드에 사용합니다.

**문법:**

```sql
CREATE TABLE 테이블명 (
    name VARCHAR(50) NOT NULL,
    ...
);
```

**예제:**

```sql
CREATE TABLE test_nn (
    id   INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,       -- 필수
    memo VARCHAR(100)                -- 선택 (NULL 허용)
);

INSERT INTO test_nn (name, memo) VALUES ('부산명가', '맛있음');  -- 성공
INSERT INTO test_nn (name) VALUES ('해운대통닭');                 -- 성공 (memo는 선택)
INSERT INTO test_nn (memo) VALUES ('설명만');                    -- 에러! name은 필수
```

**에러 메시지:**
```
Error Code: 1364. Field 'name' doesn't have a default value
```

---

### 3-4. UNIQUE (유일값)

> "이메일 주소처럼, 같은 값이 두 번 들어올 수 없습니다"

**설명:**
- 해당 컬럼의 값이 **테이블 전체에서 중복될 수 없습니다**.
- PRIMARY KEY와의 차이: **NULL은 허용**됩니다 (NULL은 '값 없음'이므로 서로 같지 않다고 봅니다).
- 테이블 하나에 여러 개의 UNIQUE 제약조건을 걸 수 있습니다.

**문법:**

```sql
CREATE TABLE 테이블명 (
    phone VARCHAR(20) UNIQUE,            -- 방법 1: 인라인
    email VARCHAR(100),
    UNIQUE KEY uq_email (email)          -- 방법 2: 테이블 레벨
);
```

**예제:**

```sql
CREATE TABLE test_uq (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE           -- NULL은 여러 개 가능
);

INSERT INTO test_uq (phone, email) VALUES ('010-1111-2222', 'a@test.com');  -- 성공
INSERT INTO test_uq (phone, email) VALUES ('010-3333-4444', NULL);          -- 성공 (NULL)
INSERT INTO test_uq (phone, email) VALUES ('010-5555-6666', NULL);          -- 성공 (NULL 중복 허용)
INSERT INTO test_uq (phone, email) VALUES ('010-1111-2222', 'b@test.com');  -- 에러! phone 중복
```

**에러 메시지:**
```
Error Code: 1062. Duplicate entry '010-1111-2222' for key 'test_uq.phone'
```

**PRIMARY KEY vs UNIQUE 비교:**

| 구분 | PRIMARY KEY | UNIQUE |
|------|-------------|--------|
| NULL 허용 | 불가 | 허용 |
| 개수 제한 | 테이블당 1개 | 여러 개 가능 |
| 용도 | 행의 대표 식별자 | 중복 방지 (보조) |

---

### 3-5. DEFAULT (기본값)

> "입사 서류에서 학력란이 비어있으면 '고졸'로 처리 — 미리 정한 기본값"

**설명:**
- INSERT 시 해당 컬럼 값을 명시하지 않으면 **자동으로 설정되는 값**입니다.
- NULL과 다릅니다: DEFAULT는 '정해진 기본값', NULL은 '값이 없음'입니다.

**문법:**

```sql
CREATE TABLE 테이블명 (
    status   VARCHAR(20)  DEFAULT 'active',
    quantity INT          DEFAULT 0,
    reg_date TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);
```

**예제:**

```sql
CREATE TABLE test_def (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(50) NOT NULL,
    rating     DECIMAL(2,1) DEFAULT 0.0,
    is_open    BOOLEAN      DEFAULT TRUE,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- rating, is_open, created_at을 명시하지 않아도 기본값이 들어갑니다
INSERT INTO test_def (name) VALUES ('새로운 가게');

SELECT * FROM test_def;
```

**결과:**

| id | name      | rating | is_open | created_at          |
|----|-----------|--------|---------|---------------------|
| 1  | 새로운 가게 | 0.0    | 1       | 2026-04-13 09:00:00 |

---

### 3-6. CHECK (유효성 검사)

> "나이는 0 이상, 100 이하여야 한다 — 말이 안 되는 값을 차단"

**설명:**
- INSERT/UPDATE 시 **지정한 조건을 만족하는 값만** 허용합니다.
- MySQL 8.0.16 버전부터 실제로 동작합니다 (이전 버전은 문법만 허용).
- 다양한 조건 표현식을 사용할 수 있습니다.

**문법:**

```sql
CREATE TABLE 테이블명 (
    price  INT CHECK (price > 0),
    rating DECIMAL(2,1) CHECK (rating BETWEEN 0.0 AND 5.0),
    age    INT CHECK (age >= 0 AND age <= 150)
);
```

**예제:**

```sql
CREATE TABLE test_chk (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    name  VARCHAR(50) NOT NULL,
    price INT NOT NULL CHECK (price > 0)
);

INSERT INTO test_chk (name, price) VALUES ('갈비탕', 13000);    -- 성공
INSERT INTO test_chk (name, price) VALUES ('공짜음식', 0);       -- 에러! 0은 > 0 불만족
INSERT INTO test_chk (name, price) VALUES ('마이너스', -5000);   -- 에러! 음수
```

**에러 메시지:**
```
Error Code: 3819. Check constraint 'test_chk_chk_1' is violated.
```

---

## 4. CHAR vs VARCHAR — 어떤 걸 써야 할까?

### 기본 개념

두 타입 모두 **문자열**을 저장하지만, 저장 방식이 다릅니다.

#### CHAR(n) — 고정 길이

- 항상 **n바이트를 고정으로** 사용합니다.
- 짧은 문자열을 넣으면 **오른쪽에 공백으로 채웁니다**.
- 읽을 때 오른쪽 공백을 자동으로 제거합니다.

```sql
CHAR(10)에 'AB'를 저장하면?
→ 'AB        ' (10칸 고정, 빈 자리는 공백)
```

#### VARCHAR(n) — 가변 길이

- **실제 문자열 길이 + 1~2바이트**(길이 정보)만 사용합니다.
- 짧은 문자열을 넣으면 짧게만 저장합니다.
- 최대 n글자까지 저장 가능합니다.

```sql
VARCHAR(100)에 'AB'를 저장하면?
→ 'AB' (3바이트: 문자 2 + 길이 1)
```

### 비교표

| 구분 | CHAR(n) | VARCHAR(n) |
|------|---------|------------|
| 저장 방식 | 고정 길이 (항상 n바이트) | 가변 길이 (실제 길이 + 1~2) |
| 빈 공간 | 공백으로 채움 | 낭비 없음 |
| 성능 | 고정 크기라 읽기 빠름 | 길이가 다양하면 약간 느릴 수 있음 |
| 최대 길이 | 255자 | 65,535바이트 |
| 적합한 경우 | 길이가 고정된 값 | 길이가 다양한 값 |

### 언제 CHAR, 언제 VARCHAR?

**CHAR를 쓰는 경우:**
```sql
-- 길이가 항상 일정한 값들
gender    CHAR(1),   -- 'M', 'F'
status    CHAR(1),   -- 'Y', 'N'
country   CHAR(2),   -- 'KR', 'US', 'JP'
```

> CHAR(1)로 'Y'/'N'을 저장하면 항상 1바이트.  
> VARCHAR(1)로 저장하면 1바이트 + 1바이트(길이 정보) = 2배 낭비.

**VARCHAR를 쓰는 경우:**
```sql
-- 길이가 다양한 값들
name      VARCHAR(50),   -- '김민준'(6바이트) ~ '황보민우아'(15바이트)
address   VARCHAR(100),  -- 주소는 길이가 제각각
email     VARCHAR(100),  -- 이메일 길이도 다양
menu_desc VARCHAR(200),  -- 설명 텍스트
```

**실무 요약:**
> 길이가 **항상 고정**이면 CHAR, **들쑥날쑥**하면 VARCHAR.  
> 모르겠으면 그냥 **VARCHAR 쓰세요**. 손해 없습니다.

---

## 5. 한입배달 테이블 리뉴얼

Day 1의 허술한 테이블을 제약조건이 완비된 버전으로 다시 만듭니다.

### 기존 테이블 삭제

```sql
-- 순서 중요! 참조하는 테이블부터 먼저 삭제
DROP TABLE IF EXISTS menus;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
```

### restaurants 테이블 (완성본)

```sql
CREATE TABLE restaurants (
    id               INT          PRIMARY KEY AUTO_INCREMENT,
    name             VARCHAR(50)  NOT NULL,
    category         VARCHAR(20)  NOT NULL,
    address          VARCHAR(100),
    rating           DECIMAL(2,1) DEFAULT 0.0,
    created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);
```

각 제약조건의 이유:

| 컬럼 | 제약조건 | 이유 |
|------|---------|------|
| id | PK + AI | 각 가게를 유일하게 식별, 번호 자동 발급 |
| name | NOT NULL | 이름 없는 가게는 존재할 수 없음 |
| category | NOT NULL | 카테고리 없으면 필터링 불가 |
| address | (없음) | 나중에 등록 가능, 선택 사항 |
| rating | DEFAULT 0.0 | 신규 가게는 평점 0으로 시작 |
| created_at | DEFAULT NOW | 등록 시각 자동 기록 |

### customers 테이블 (완성본)

```sql
CREATE TABLE customers (
    id               INT          PRIMARY KEY AUTO_INCREMENT,
    name             VARCHAR(30)  NOT NULL,
    phone            VARCHAR(20)  UNIQUE NOT NULL,
    email            VARCHAR(100) UNIQUE,
    address          VARCHAR(100),
    joined_at        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);
```

| 컬럼 | 제약조건 | 이유 |
|------|---------|------|
| phone | UNIQUE NOT NULL | 전화번호는 중복 불가, 반드시 있어야 함 |
| email | UNIQUE | 이메일도 중복 불가, 단 선택 사항이므로 NULL 허용 |

### menus 테이블 (완성본)

```sql
CREATE TABLE menus (
    id               INT          PRIMARY KEY AUTO_INCREMENT,
    restaurant_id    INT          NOT NULL,
    menu_name        VARCHAR(50)  NOT NULL,
    price            INT          NOT NULL CHECK (price > 0),
    menu_description VARCHAR(200),
    is_available     BOOLEAN      DEFAULT TRUE
);
```

| 컬럼 | 제약조건 | 이유 |
|------|---------|------|
| restaurant_id | NOT NULL | 어느 가게 메뉴인지는 반드시 알아야 함 |
| price | NOT NULL + CHECK(>0) | 가격은 필수, 0원 이하는 불가 |
| menu_description | (없음) | 설명은 선택 사항 |
| is_available | DEFAULT TRUE | 신규 등록 메뉴는 기본으로 판매 중 |

---

## 6. ALTER TABLE — 이미 만든 테이블 수정하기

> "이미 완공된 건물도 리모델링할 수 있습니다.  
> 방을 추가하거나, 방 크기를 늘리거나, 방 이름을 바꿀 수 있습니다.  
> 단, 방을 허무는 건 조심해야 합니다 — 그 안에 있던 물건이 사라집니다."

### 6-1. ADD COLUMN — 컬럼 추가

```sql
-- 기본 문법
ALTER TABLE 테이블명
    ADD COLUMN 컬럼명 데이터타입 [제약조건];

-- 예제: restaurants에 최소주문금액 컬럼 추가
ALTER TABLE restaurants
    ADD COLUMN min_order_amount INT DEFAULT 0;
```

### 6-2. MODIFY COLUMN — 컬럼 타입/속성 변경

```sql
-- 기본 문법
ALTER TABLE 테이블명
    MODIFY COLUMN 컬럼명 새로운_데이터타입 [새로운_제약조건];

-- 예제: name 컬럼을 VARCHAR(30)에서 VARCHAR(50)으로 확장
ALTER TABLE customers
    MODIFY COLUMN name VARCHAR(50) NOT NULL;
```

> **주의**: 컬럼 크기를 **줄이면** 기존 데이터가 잘릴 수 있습니다. 늘리는 건 안전합니다.

### 6-3. RENAME COLUMN — 컬럼명 변경

```sql
-- 기본 문법 (MySQL 8.0 이상)
ALTER TABLE 테이블명
    RENAME COLUMN 기존_컬럼명 TO 새_컬럼명;

-- 예제: description을 menu_description으로 변경
ALTER TABLE menus
    RENAME COLUMN description TO menu_description;
```

### 6-4. DROP COLUMN — 컬럼 삭제

```sql
-- 기본 문법
ALTER TABLE 테이블명
    DROP COLUMN 컬럼명;

-- 예제: 임시로 추가한 컬럼 제거
ALTER TABLE menus
    DROP COLUMN temp_column;
```

> **경고**: DROP COLUMN은 **해당 컬럼의 모든 데이터가 영구 삭제**됩니다.  
> 실행 전 반드시 확인하세요!

### ALTER TABLE 요약

| 작업 | 명령어 | 위험도 |
|------|--------|--------|
| 컬럼 추가 | `ADD COLUMN` | 낮음 (기존 데이터 영향 없음) |
| 타입/속성 변경 | `MODIFY COLUMN` | 중간 (크기 줄이면 데이터 손실 가능) |
| 컬럼명 변경 | `RENAME COLUMN` | 낮음 (데이터 유지됨) |
| 컬럼 삭제 | `DROP COLUMN` | 높음 (데이터 영구 삭제!) |

---

## 7. 자주 발생하는 제약조건 에러

### 에러 1: PK 중복 (Error 1062)

```
Error Code: 1062. Duplicate entry '1' for key 'PRIMARY'
```

**원인**: 이미 존재하는 PK 값을 INSERT 하려고 할 때

**예시:**
```sql
INSERT INTO restaurants (id, name) VALUES (1, '가게A');
INSERT INTO restaurants (id, name) VALUES (1, '가게B');  -- 에러!
```

**해결책**: AUTO_INCREMENT를 사용하면 id를 직접 입력하지 않아도 됩니다.
```sql
INSERT INTO restaurants (name, category) VALUES ('가게B', '한식');  -- id 자동 발급
```

---

### 에러 2: NOT NULL 위반 (Error 1364)

```
Error Code: 1364. Field 'name' doesn't have a default value
```

**원인**: NOT NULL 컬럼에 NULL을 넣거나 값을 아예 생략할 때

**예시:**
```sql
INSERT INTO restaurants (category) VALUES ('한식');  -- name을 생략!
```

**해결책**: NOT NULL 컬럼은 반드시 값을 제공합니다.
```sql
INSERT INTO restaurants (name, category) VALUES ('해운대맛집', '한식');
```

---

### 에러 3: UNIQUE 위반 (Error 1062)

```
Error Code: 1062. Duplicate entry '010-1234-5678' for key 'customers.phone'
```

**원인**: UNIQUE 제약조건이 걸린 컬럼에 이미 존재하는 값을 넣을 때

**예시:**
```sql
INSERT INTO customers (name, phone) VALUES ('김민준', '010-1234-5678');
INSERT INTO customers (name, phone) VALUES ('이서연', '010-1234-5678');  -- 동일 번호!
```

**해결책**: 올바른(중복되지 않는) 값을 입력합니다.
```sql
INSERT INTO customers (name, phone) VALUES ('이서연', '010-9999-8888');
```

---

### 에러 4: CHECK 위반 (Error 3819)

```
Error Code: 3819. Check constraint 'menus_chk_1' is violated.
```

**원인**: CHECK 조건에 맞지 않는 값을 INSERT/UPDATE 할 때

**예시:**
```sql
INSERT INTO menus (restaurant_id, menu_name, price) VALUES (1, '무료시식', 0);   -- 0은 > 0 불만족
INSERT INTO menus (restaurant_id, menu_name, price) VALUES (1, '환불이벤트', -1000);  -- 음수도 불가
```

**해결책**: CHECK 조건을 만족하는 값을 입력합니다.
```sql
INSERT INTO menus (restaurant_id, menu_name, price) VALUES (1, '시식코너', 1000);  -- 1000 > 0 만족
```

---

### 에러 5: 데이터 타입 초과 (Warning/Error)

```
Warning: Data truncated for column 'category' at row 1
```

**원인**: VARCHAR(20)에 20자를 초과하는 문자열을 넣을 때

**예시:**
```sql
-- VARCHAR(20) 컬럼에 30자짜리 문자열 삽입
INSERT INTO restaurants (name, category) VALUES ('가게', '매우매우매우매우매우매우매우매우매우매우긴카테고리');
```

**해결책**: 적절한 길이의 값을 사용하거나, 컬럼 크기를 `ALTER TABLE`로 늘립니다.

---

## 8. 제약조건 정리표

| 제약조건 | 키워드 | 역할 | NULL 허용 | 테이블당 개수 |
|---------|--------|------|----------|-------------|
| 기본 키 | `PRIMARY KEY` | 행 고유 식별 | 불가 | 1개 |
| 자동 증가 | `AUTO_INCREMENT` | 자동 번호 발급 | — | 1개 |
| 필수 입력 | `NOT NULL` | NULL 차단 | 불가 | 제한 없음 |
| 유일값 | `UNIQUE` | 중복 차단 | 허용 | 제한 없음 |
| 기본값 | `DEFAULT` | 미입력 시 자동값 | — | 제한 없음 |
| 유효성 검사 | `CHECK` | 조건 불만족 차단 | — | 제한 없음 |

---

## 9. 오늘의 핵심 정리

### 오늘 배운 명령어

```sql
-- 제약조건이 완비된 테이블 생성
CREATE TABLE menus (
    id               INT          PRIMARY KEY AUTO_INCREMENT,
    restaurant_id    INT          NOT NULL,
    menu_name        VARCHAR(50)  NOT NULL,
    price            INT          NOT NULL CHECK (price > 0),
    menu_description VARCHAR(200),
    is_available     BOOLEAN      DEFAULT TRUE
);

-- 테이블 구조 수정
ALTER TABLE restaurants ADD COLUMN min_order_amount INT DEFAULT 0;
ALTER TABLE customers   MODIFY COLUMN name VARCHAR(50) NOT NULL;
ALTER TABLE menus       RENAME COLUMN description TO menu_description;
ALTER TABLE menus       DROP COLUMN temp_column;
```

### 핵심 개념 요약

| 비유 | SQL 개념 |
|------|---------|
| 주민등록번호 | PRIMARY KEY |
| 번호표 기계 | AUTO_INCREMENT |
| 필수 기입란 | NOT NULL |
| 이메일 (중복 불가) | UNIQUE |
| 기본값 설정 | DEFAULT |
| 입력값 유효성 검사 | CHECK |
| 건물 리모델링 | ALTER TABLE |

---

## 10. 다음 시간 예고 — Day 3: CRUD

> "테이블도 완벽하게 만들었고, 더미 데이터도 넣었습니다.  
> 그런데 데이터를 어떻게 넣고(INSERT), 꺼내고(SELECT), 수정하고(UPDATE), 지우는(DELETE) 건지 아직 제대로 배우지 않았죠?"

**Day 3 예고:**
- `INSERT` — 데이터 추가 (택배 입고)
- `SELECT` + `WHERE` — 조건에 맞는 데이터 조회 (쿠팡 필터)
- `UPDATE` — 데이터 수정 (주의: WHERE 없으면 전체 수정!)
- `DELETE` — 데이터 삭제 (주의: WHERE 없으면 전체 삭제!)

```
⚠️  미리 경고: WHERE 없는 UPDATE/DELETE는 "핵버튼"입니다.
    Day 3에서 실수하지 않는 법도 함께 배웁니다.
```
