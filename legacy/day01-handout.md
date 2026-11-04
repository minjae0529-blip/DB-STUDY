# Day 1 — 데이터베이스, 왜 쓰는 건데?
### 한입배달 MySQL 10일 완성 과정

---

## 1. Day 1 개요

> "엑셀이면 되는 거 아닌가요?"

오늘은 이 질문에서 시작합니다. 엑셀도 훌륭한 도구입니다. 하지만 배달앱처럼 **수백만 명이 동시에 쓰는 서비스**를 만들 때는 엑셀만으로는 버티지 못합니다. 오늘 그 이유를 직접 눈으로 확인하고, 데이터베이스의 세계로 첫발을 내딛습니다.

### 학습 목표

오늘 수업이 끝나면 다음을 할 수 있습니다.

1. 데이터베이스가 왜 필요한지 엑셀과 비교하여 설명할 수 있다.
2. MySQL, Workbench, SQL의 역할을 각각 비유로 설명할 수 있다.
3. `CREATE DATABASE`, `USE`, `SHOW DATABASES` 를 직접 실행할 수 있다.
4. INT, VARCHAR, DATE, DECIMAL 타입의 차이를 알고 상황에 맞게 선택할 수 있다.
5. `CREATE TABLE`, `DESC`, `SHOW TABLES` 로 테이블을 만들고 구조를 확인할 수 있다.

---

## 2. 왜 데이터베이스인가?

### 엑셀 vs 데이터베이스 비교표

| 비교 항목 | 엑셀 | 데이터베이스 (MySQL) |
|-----------|------|----------------------|
| **동시 접속** | 한 명만 편집 가능 (공유 시 충돌) | 수천 명이 동시에 읽고 쓸 수 있음 |
| **데이터 용량** | 수십만 행이면 느려짐 | 수억 행도 빠르게 처리 |
| **데이터 안전** | 실수로 삭제해도 모름 | 권한 관리, 트랜잭션으로 보호 |
| **데이터 정확성** | 아무 값이나 입력 가능 | 규칙(제약조건)으로 잘못된 데이터 차단 |
| **여러 데이터 연결** | VLOOKUP으로 힘겹게 연결 | JOIN으로 여러 테이블을 쉽게 합침 |
| **자동화 / 연동** | 수동 작업 중심 | 앱, 웹, API와 쉽게 연동 |

### 실제 배달앱 사례

한입배달 앱이 하루에 처리하는 일을 생각해보세요.

- 고객 10만 명이 **동시에** 앱을 켭니다.
- 초당 수백 건의 주문이 들어옵니다.
- 각 주문은 고객 정보, 음식점 정보, 메뉴 정보, 결제 정보를 **동시에 저장**해야 합니다.
- 사장님은 실시간으로 오늘 매출을 확인합니다.

이 모든 걸 엑셀로 처리할 수 있을까요? 그래서 데이터베이스가 필요합니다.

---

## 3. 핵심 개념 3가지

세 가지 개념이 헷갈릴 수 있습니다. 비유로 확실히 잡아봅시다.

### MySQL = 창고

> "MySQL은 데이터를 보관하는 **거대한 창고**입니다."

- 창고 안에는 여러 **선반(테이블)** 이 있습니다.
- 각 선반에는 정해진 **규격의 상자(데이터 타입)** 만 올릴 수 있습니다.
- 창고 자체는 화면이 없습니다. 직접 들어가서 눈으로 보기 어렵습니다.

### Workbench = 창고 관리 사무실

> "MySQL Workbench는 창고 옆에 붙어 있는 **관리 사무실**입니다."

- 사무실에서 창고 안을 모니터로 확인할 수 있습니다.
- 마우스로 클릭하며 편하게 작업할 수 있습니다.
- Workbench 없이도 MySQL을 쓸 수 있지만, Workbench가 있으면 훨씬 편합니다.
- (참고: DBeaver, DataGrip 등 다른 사무실 도구를 써도 됩니다.)

### SQL = 지시서

> "SQL은 창고 직원(MySQL)에게 내리는 **지시서**입니다."

- "음식점 선반에서 '한식' 카테고리 상자만 꺼내와." → `SELECT`
- "새 상자를 만들어서 올려놔." → `INSERT`
- "이 상자의 내용을 바꿔줘." → `UPDATE`
- "이 상자를 버려줘." → `DELETE`
- SQL(Structured Query Language)은 **데이터베이스와 대화하는 언어**입니다.

---

## 4. SQL 분류 — 전체 지도

SQL 명령어는 목적에 따라 4가지로 분류됩니다. 지금 당장 외울 필요는 없습니다. "이런 지도가 있구나" 정도로만 봐두세요. 10일 동안 하나씩 채워나갑니다.

| 분류 | 이름 | 역할 | 대표 명령어 | 배우는 날 |
|------|------|------|-------------|-----------|
| **DDL** | Data Definition Language | 창고 구조 설계 (테이블 만들기/수정/삭제) | `CREATE`, `ALTER`, `DROP` | Day 1~2 |
| **DML** | Data Manipulation Language | 데이터 다루기 (넣기/읽기/수정/삭제) | `INSERT`, `SELECT`, `UPDATE`, `DELETE` | Day 3~ |
| **DCL** | Data Control Language | 권한 관리 (누가 뭘 할 수 있는지) | `GRANT`, `REVOKE` | Day 10 |
| **TCL** | Transaction Control Language | 작업 묶음 관리 (한꺼번에 성공/실패) | `COMMIT`, `ROLLBACK` | Day 8 |

> **오늘은 DDL만 배웁니다.** 창고를 먼저 만들어야 데이터도 넣을 수 있으니까요.

---

## 5. MySQL 설치 & 접속

### 설치 확인

MySQL이 이미 설치되어 있다면 아래 명령어로 확인할 수 있습니다.

```sql
-- MySQL Workbench 상단 Query 창에서 실행
SELECT VERSION();
```

예상 결과:
```
8.0.xx
```

### MySQL Workbench 접속 순서

1. **MySQL Workbench 실행**
2. **Local instance MySQL80 클릭** (또는 강사가 안내한 커넥션 선택)
3. **비밀번호 입력** (설치 시 설정한 root 비밀번호)
4. **연결 성공** → 왼쪽 패널에 기존 DB 목록이 보임

### Workbench 화면 구조

```
┌─────────────────────────────────────────────────────────┐
│  Navigator (왼쪽)  │  Query 창 (가운데)  │  출력 (아래) │
│  - SCHEMAS         │  여기에 SQL 입력    │  결과 테이블 │
│  - 테이블 목록     │  Ctrl+Enter: 실행   │  에러 메시지 │
└─────────────────────────────────────────────────────────┘
```

> **팁**: SQL 전체 실행은 `Ctrl+Shift+Enter`, 커서가 있는 줄 하나만 실행은 `Ctrl+Enter`

---

## 6. 첫 번째 데이터베이스 만들기

### CREATE DATABASE

데이터베이스(창고 건물)를 새로 만드는 명령어입니다.

```sql
CREATE DATABASE hanip_delivery
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
```

| 옵션 | 의미 |
|------|------|
| `CHARACTER SET utf8mb4` | 한글, 이모지 등 모든 문자를 저장할 수 있는 인코딩 |
| `COLLATE utf8mb4_unicode_ci` | 정렬·비교 시 대소문자를 구분하지 않음 (`ci` = case insensitive) |

> **주의**: 한글 데이터를 저장할 때는 반드시 `utf8mb4`를 사용하세요. `utf8`만 쓰면 일부 이모지가 깨질 수 있습니다.

### USE

만든 데이터베이스를 선택(=입장)하는 명령어입니다.

```sql
USE hanip_delivery;
```

`USE` 없이 테이블을 만들면 엉뚱한 DB에 만들어질 수 있습니다. **항상 USE를 먼저 실행하세요.**

### SHOW DATABASES

현재 MySQL 서버에 있는 모든 데이터베이스 목록을 봅니다.

```sql
SHOW DATABASES;
```

예상 결과:

| Database |
|----------|
| hanip_delivery |
| information_schema |
| mysql |
| performance_schema |
| sys |

> `information_schema`, `mysql`, `sys` 등은 MySQL이 자체적으로 쓰는 시스템 DB입니다. 건드리지 마세요!

---

## 7. 데이터 타입 입문 — 택배 상자 비유

> "데이터 타입은 **택배 상자**입니다. 상자 크기와 모양이 미리 정해져 있어서, 맞는 물건만 들어갑니다."

테이블의 각 컬럼은 **어떤 종류의 데이터만 받을지** 미리 정해줘야 합니다. 이것이 데이터 타입입니다.

### INT — 정수 상자

| 항목 | 내용 |
|------|------|
| **저장 가능한 값** | -2,147,483,648 ~ 2,147,483,647 (약 ±21억) |
| **용량** | 4바이트 |
| **언제 쓰나** | 고객 ID, 주문 수량, 가격(원 단위), 나이 |
| **주의사항** | 소수점이 있으면 사용 불가. 가격이 소수점 없는 원화면 OK |

```sql
id       INT,   -- 고객 번호: 1, 2, 3, 100, 50000
quantity INT,   -- 주문 수량: 1, 2, 3
price    INT    -- 가격: 8000, 18000, 25000
```

> **INT 계열 비교**
> | 타입 | 범위 | 용량 | 용도 |
> |------|------|------|------|
> | TINYINT | -128 ~ 127 | 1바이트 | 별점(1~5), 나이 |
> | SMALLINT | -32,768 ~ 32,767 | 2바이트 | 재고 수량 |
> | INT | ±21억 | 4바이트 | 일반 ID, 가격 |
> | BIGINT | ±9.2경 | 8바이트 | 트위터 게시물 ID 같은 매우 큰 수 |

### VARCHAR — 가변 길이 문자열 상자

| 항목 | 내용 |
|------|------|
| **저장 가능한 값** | 문자열 (최대 길이를 괄호 안에 지정) |
| **특징** | 실제 저장 데이터 길이만큼만 용량 사용 (가변) |
| **언제 쓰나** | 이름, 전화번호, 주소, 이메일, 카테고리 |
| **주의사항** | 전화번호는 숫자처럼 보여도 VARCHAR 사용! (앞자리 0이 사라지는 문제 방지) |

```sql
name     VARCHAR(30),   -- 최대 30자: '김민준', 'John Smith'
phone    VARCHAR(20),   -- 최대 20자: '010-1234-5678'
address  VARCHAR(100)   -- 최대 100자: '부산시 해운대구 우동 123번지'
```

> **VARCHAR vs CHAR 비교**
> | 타입 | 특징 | 용도 |
> |------|------|------|
> | `VARCHAR(n)` | 가변 길이. 실제 길이만큼만 저장 | 이름, 주소 등 길이가 다양한 데이터 |
> | `CHAR(n)` | 고정 길이. 항상 n바이트 차지 | 주민번호 뒷자리, 우편번호처럼 항상 같은 길이인 데이터 |

### DATE — 날짜 상자

| 항목 | 내용 |
|------|------|
| **형식** | `'YYYY-MM-DD'` (예: `'2025-01-15'`) |
| **저장 가능한 범위** | 1000-01-01 ~ 9999-12-31 |
| **언제 쓰나** | 생년월일, 쿠폰 만료일, 서비스 가입일 |
| **주의사항** | 시간까지 필요하면 `DATETIME` 또는 `TIMESTAMP` 사용 |

```sql
birth_date   DATE,       -- '1995-08-23'
valid_until  DATE,       -- '2025-12-31'
order_date   DATETIME    -- '2025-01-15 14:30:00' (날짜+시간)
```

> **날짜/시간 타입 비교**
> | 타입 | 형식 | 용도 |
> |------|------|------|
> | `DATE` | YYYY-MM-DD | 날짜만 (생일, 만료일) |
> | `TIME` | HH:MM:SS | 시간만 (영업 시작 시간) |
> | `DATETIME` | YYYY-MM-DD HH:MM:SS | 날짜+시간 (주문 시각) |
> | `TIMESTAMP` | YYYY-MM-DD HH:MM:SS | DATETIME과 비슷, 타임존 자동 적용 |

### DECIMAL — 소수점 숫자 상자

| 항목 | 내용 |
|------|------|
| **형식** | `DECIMAL(전체자릿수, 소수점이하자릿수)` |
| **언제 쓰나** | 별점, 할인율, 정확한 금액 계산 (오차 없음) |
| **주의사항** | `FLOAT`, `DOUBLE`은 부동소수점 오차가 있어 금액 계산에 부적합 |

```sql
rating          DECIMAL(2, 1),  -- 별점: 4.5, 3.0, 5.0  (전체 2자리, 소수 1자리)
discount_rate   DECIMAL(4, 2),  -- 할인율: 10.50, 99.99 (전체 4자리, 소수 2자리)
```

### 데이터 타입 전체 비교표

| 데이터 타입 | 저장하는 것 | 예시 | 비유 (택배 상자) |
|-------------|-------------|------|-----------------|
| `INT` | 정수 | 1, 1000, -5 | 수량 적힌 작은 봉투 |
| `BIGINT` | 매우 큰 정수 | 9,200,000,000 | 대형 번호 봉투 |
| `DECIMAL(n,m)` | 정밀한 소수 | 4.5, 10.99 | 눈금 있는 계량컵 |
| `VARCHAR(n)` | 가변 문자열 | '김민준', '010-...' | 크기 조절 봉투 |
| `CHAR(n)` | 고정 문자열 | '남', '여' | 딱 맞는 규격 봉투 |
| `TEXT` | 긴 문자열 | 리뷰 내용, 공지사항 | 대형 포대 자루 |
| `DATE` | 날짜 | '2025-01-15' | 날짜 도장 봉투 |
| `DATETIME` | 날짜+시간 | '2025-01-15 14:30:00' | 날짜+시각 봉투 |
| `BOOLEAN` | 참/거짓 | 0(거짓), 1(참) | 체크박스 봉투 |

---

## 8. 첫 번째 테이블 만들기

### CREATE TABLE 문법

```sql
CREATE TABLE 테이블명 (
    컬럼명1  데이터타입,
    컬럼명2  데이터타입,
    컬럼명3  데이터타입
);
```

- 컬럼 목록은 소괄호 `( )` 안에 씁니다.
- 각 컬럼은 쉼표 `,` 로 구분합니다.
- **마지막 컬럼 뒤에는 쉼표를 쓰지 않습니다.** (자주 하는 실수!)
- SQL 문 끝에는 세미콜론 `;` 을 붙입니다.

### SHOW TABLES — 테이블 목록 확인

```sql
SHOW TABLES;
```

예상 결과:

| Tables_in_hanip_delivery |
|--------------------------|
| customers |
| menus |
| restaurants |

### DESC — 테이블 구조 확인

`DESC`는 `DESCRIBE`의 줄임말입니다. 테이블의 컬럼 목록과 타입을 보여줍니다.

```sql
DESC restaurants;
```

예상 결과:

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| id | int | YES | | NULL | |
| name | varchar(50) | YES | | NULL | |
| category | varchar(20) | YES | | NULL | |

### 한입배달 테이블 3개 생성

**restaurants (음식점)**

```sql
CREATE TABLE restaurants (
    id          INT,
    name        VARCHAR(50),
    category    VARCHAR(20)
);
```

**customers (고객)**

```sql
CREATE TABLE customers (
    id       INT,
    name     VARCHAR(30),
    phone    VARCHAR(20),
    address  VARCHAR(100)
);
```

**menus (메뉴)**

```sql
CREATE TABLE menus (
    id             INT,
    restaurant_id  INT,
    menu_name      VARCHAR(50),
    price          INT
);
```

> **잠깐, 이 테이블에 문제가 있지 않나요?**
>
> 날카로운 분들은 눈치챘을 겁니다. 지금 테이블은 **아무 데이터나 다 들어갑니다.**
> - 음식점 ID가 중복돼도 저장됩니다.
> - 음식점 이름이 비어 있어도(NULL) 저장됩니다.
> - 존재하지 않는 음식점 ID를 가진 메뉴가 저장됩니다.
>
> 이것은 **의도적인 설계**입니다. Day 2에서 이 모든 문제를 **제약조건**으로 해결합니다.

---

## 9. 에러 메시지 읽는 법

SQL을 처음 배울 때 에러는 필연입니다. 에러 메시지를 겁내지 말고 **친구처럼** 대하세요. 에러 메시지는 항상 무엇이 잘못됐는지 알려줍니다.

### 자주 나오는 에러 3가지

#### 에러 1: 데이터베이스를 선택하지 않음

```
Error Code: 1046. No database selected
```

**원인**: `USE 데이터베이스명;` 을 실행하지 않았습니다.

**해결책**:
```sql
USE hanip_delivery;  -- 이걸 먼저 실행하세요!
```

---

#### 에러 2: 이미 존재하는 테이블을 다시 만들려 함

```
Error Code: 1050. Table 'restaurants' already exists
```

**원인**: 같은 이름의 테이블이 이미 있는데 `CREATE TABLE`을 또 실행했습니다.

**해결책 A**: 기존 테이블을 삭제하고 다시 만들기
```sql
DROP TABLE restaurants;
CREATE TABLE restaurants ( ... );
```

**해결책 B**: 없을 때만 만들기 (안전한 방법)
```sql
CREATE TABLE IF NOT EXISTS restaurants ( ... );
```

---

#### 에러 3: SQL 문법 오류

```
Error Code: 1064. You have an error in your SQL syntax; check the manual
that corresponds to your MySQL server version for the right syntax to use
near '...' at line N
```

**원인**: SQL 문법이 틀렸습니다. 가장 흔한 원인:
- 마지막 컬럼 뒤에 쉼표 `,` 를 붙임
- 따옴표를 열고 닫지 않음
- 오타 (SELCT, CREAT TABLE 등)

**해결책**:
```sql
-- 잘못된 예 (마지막 컬럼 뒤 쉼표)
CREATE TABLE test (
    id    INT,
    name  VARCHAR(30),   -- ← 이 쉼표가 문제!
);

-- 올바른 예
CREATE TABLE test (
    id    INT,
    name  VARCHAR(30)    -- ← 마지막 컬럼에는 쉼표 없음
);
```

> **팁**: 에러 메시지에서 `near '...'` 뒤에 오는 텍스트가 에러가 발생한 **직후** 위치를 가리킵니다. 그 바로 앞 부분을 확인해보세요.

---

## 10. 오늘의 핵심 정리

### 오늘 배운 키워드 요약

| 키워드 | 분류 | 한 줄 설명 |
|--------|------|------------|
| `CREATE DATABASE` | DDL | 새 데이터베이스(창고) 만들기 |
| `USE` | — | 사용할 데이터베이스 선택 |
| `SHOW DATABASES` | — | 전체 데이터베이스 목록 보기 |
| `CREATE TABLE` | DDL | 새 테이블(선반) 만들기 |
| `SHOW TABLES` | — | 현재 DB의 테이블 목록 보기 |
| `DESC` | — | 테이블 컬럼 구조 확인 |
| `DROP DATABASE IF EXISTS` | DDL | 데이터베이스 삭제 (있으면) |
| `INT` | 데이터 타입 | 정수 저장 |
| `VARCHAR(n)` | 데이터 타입 | 가변 길이 문자열 저장 |
| `DATE` | 데이터 타입 | 날짜 저장 (YYYY-MM-DD) |
| `DECIMAL(n,m)` | 데이터 타입 | 소수점 있는 수 저장 |

### 오늘 완성한 테이블 구조

```
hanip_delivery 데이터베이스
├── restaurants (id, name, category)
├── customers   (id, name, phone, address)
└── menus       (id, restaurant_id, menu_name, price)
```

---

## 11. 다음 시간 예고 — Day 2

오늘 만든 테이블에 직접 이상한 데이터를 넣어봅시다.

```sql
-- 이게 저장이 된다고?!
INSERT INTO restaurants (id, name, category) VALUES (1, NULL, NULL);
INSERT INTO restaurants (id, name, category) VALUES (1, '중복된ID가게', '한식');
```

두 쿼리 모두 **에러 없이 저장됩니다.** 이름 없는 가게, 중복된 ID... 실제 서비스라면 큰일 나겠죠?

> **Day 2에서는 이 "자물쇠 없는 창고" 문제를 해결합니다.**
> `PRIMARY KEY`, `NOT NULL`, `UNIQUE`, `DEFAULT`, `CHECK` — 이것들이 바로 **제약조건**입니다.
> 테이블에 자물쇠를 달아봅시다!

---

*한입배달 MySQL 10일 완성 과정 — Day 1 핸드아웃*
*다음 수업 전에 오늘 배운 SQL 5개를 직접 타이핑해보세요. 보지 않고 칠 수 있을 때까지!*
