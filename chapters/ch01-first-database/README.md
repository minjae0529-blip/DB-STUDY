# Ch01. 데이터베이스와 첫 만남

> **PART 1 · 읽기** | 3시간 | 난이도 ★
> 이전: — | 다음: [Ch02. SELECT 기본](../ch02-select-basics/README.md)

## 오늘의 요청

> **From.** 데이터팀 김 팀장
> **To.** 신입 데이터 엔지니어
>
> 입사를 환영합니다. 첫 주 업무는 **우리 서비스 DB를 내 PC에 설치하고, 어떤 데이터가 어디에 있는지 파악하는 것**입니다.
> 오늘 퇴근 전에 "주문 한 건이 DB에 어떻게 저장되는지" 저한테 설명할 수 있으면 됩니다.

## 학습 목표

이 챕터를 마치면 다음을 할 수 있습니다.

1. 스프레드시트 대신 데이터베이스를 쓰는 이유를 **한입배달의 실제 상황**으로 설명한다.
2. DBMS, 테이블, 행, 열, 기본키, 외래키를 구분해 말한다.
3. MySQL 서버와 Workbench의 관계(서버–클라이언트)를 설명하고, 챕터용 한입배달 DB(`hanip_delivery01`)를 만든다.
4. `SHOW`, `USE`, `DESC`, `SELECT … LIMIT`로 처음 보는 DB의 구조와 데이터를 탐색한다.
5. MySQL 에러 메시지에서 **에러 번호와 원인**을 읽어 내고 스스로 고친다.

---

## 1. 왜 데이터베이스인가

한입배달은 상반기(1~6월) 동안 563건의 주문을 받았습니다. 이걸 엑셀 파일 하나로 관리한다고 상상해 봅시다. 한 행에 주문 하나씩 적습니다.

| 주문일시 | 고객명 | 고객전화 | 가게명 | 가게주소 | 메뉴 | 수량 | 단가 |
|---|---|---|---|---|---|---|---|
| 2026-01-03 11:32 | 김민준 | 010-2841-5523 | 연산동짬뽕반점 | 연제구 연산동 중앙대로 1105 | 짜장면 | 1 | 7000 |
| 2026-01-03 11:32 | 김민준 | 010-2841-5523 | 연산동짬뽕반점 | 연제구 연산동 중앙대로 1105 | 탕수육 (소) | 1 | 16000 |
| 2026-01-03 11:32 | 김민준 | 010-2841-5523 | 연산동짬뽕반점 | 연제구 연산동 중앙대로 1105 | 군만두 (8개) | 1 | 6000 |
| 2026-01-07 19:47 | 김민준 | 010-2841-5523 | 대연동크런치치킨 | 남구 대연동 못골로 41 | 양념 치킨 | 1 | 20000 |

처음엔 문제없어 보이지만, 서비스가 굴러가기 시작하면 곧 이런 일이 생깁니다.

| 상황 | 스프레드시트에서 생기는 일 | 데이터베이스가 해결하는 방식 | 배울 챕터 |
|---|---|---|---|
| 김민준 님이 전화번호를 바꿈 | 52건 주문의 모든 행을 전부 찾아 고쳐야 함. 하나라도 놓치면 같은 사람이 두 번호를 가짐 | 고객 정보는 `customers`에 **한 번만** 저장하고 주문은 고객 번호로 연결 | 05, 09 |
| 직원이 가격 칸에 `만원`이라고 입력 | 그대로 저장됨. 월말 합계 수식이 깨짐 | 열마다 **타입**(정수)과 **규칙**(0보다 큼)을 정해 잘못된 값은 거부 | 07 |
| 상담원 3명이 동시에 같은 파일 수정 | 마지막 저장이 앞 사람 작업을 덮어씀 | 수많은 사용자가 동시에 읽고 써도 안전하게 처리 | 08 |
| 주문 저장 중 PC가 꺼짐 | 주문은 들어갔는데 결제 내역만 빠진 상태로 남음 | **트랜잭션** — 전부 성공하거나 전부 취소 | 08 |
| "4월 부산진구 치킨 매출은?" | 필터·피벗을 매번 손으로 | `SELECT` 한 문장으로 즉시 | 02~06 |
| 아르바이트생에게 주문 조회만 허용 | 파일을 주면 전부 보고 고칠 수 있음 | 사용자별로 **권한**을 나눠 줌 | 10 |

> **핵심**: 데이터베이스는 "큰 엑셀"이 아니라, **데이터를 정확하게 · 동시에 · 안전하게** 다루기 위한 시스템입니다.

---

## 2. 기본 용어

### 데이터베이스와 DBMS

| 용어 | 뜻 | 한입배달에서는 |
|---|---|---|
| **데이터베이스 (DB)** | 체계적으로 정리해 저장한 데이터의 집합 | `hanip_delivery01` (챕터마다 새로 만듦, 5절) |
| **DBMS** | 데이터베이스를 만들고 관리하는 소프트웨어 | MySQL 8.0 |
| **RDBMS** | 데이터를 **표(테이블)** 형태로 저장하고 표끼리 연결하는 DBMS | MySQL, Oracle, PostgreSQL, SQL Server, MariaDB |
| **SQL** | RDBMS에 일을 시키는 표준 언어 | `SELECT name FROM restaurants;` |

### 테이블의 구성

```
                         열(column) = 속성
              ┌───────────────┬────────────┬──────────┐
              │ restaurant_id │ name       │ category │   ← 열 이름
              ├───────────────┼────────────┼──────────┤
 행(row)  →   │ 1             │ 서면옛날…  │ 한식     │
 = 레코드     │ 2             │ 전포카츠   │ 일식     │
              └───────────────┴────────────┴──────────┘
                     ↑
                 기본키(PK): 행을 하나로 콕 집는 값
```

| 용어 | 다른 이름 | 뜻 |
|---|---|---|
| 테이블 (table) | 릴레이션 | 같은 종류의 데이터를 모은 표 |
| 행 (row) | 레코드, 튜플 | 데이터 한 건 (가게 하나, 주문 하나) |
| 열 (column) | 필드, 속성(attribute) | 데이터의 항목 (가게명, 업종) |
| 스키마 (schema) | — | 테이블의 설계도: 어떤 열이 있고 각 열에 무엇이 들어가는가. MySQL에서는 "데이터베이스"와 같은 뜻으로도 씁니다 |
| **기본키 (PK)** | Primary Key | 행을 유일하게 식별하는 열. 중복·빈 값 불가 (`restaurant_id`) |
| **외래키 (FK)** | Foreign Key | 다른 테이블의 기본키를 가리키는 열 (`orders.customer_id` → `customers.customer_id`) |

### 주문 한 건은 어떻게 저장될까

1절 스프레드시트의 첫 세 줄(김민준 님의 1월 3일 짬뽕반점 주문)은 DB에서 **다섯 테이블에 나뉘어** 저장됩니다.

```
customers                    orders                                       restaurants
┌─────────────┬────────┐     ┌──────────┬─────────────┬───────────────┐     ┌───────────────┬────────────────┐
│ customer_id │ name   │     │ order_id │ customer_id │ restaurant_id │     │ restaurant_id │ name           │
│ 1           │ 김민준 │◀────│ 7        │ 1           │ 8             │────▶│ 8             │ 연산동짬뽕반점 │
└─────────────┴────────┘     └──────────┴─────────────┴───────────────┘     └───────────────┴────────────────┘
                                   ▲
                    order_items    │ order_id = 7 인 줄이 3개          menus
                    ┌──────────┬─────────┬──────────┬────────────┐   ┌─────────┬──────────────┐
                    │ order_id │ menu_id │ quantity │ unit_price │   │ menu_id │ name         │
                    │ 7        │ 35      │ 1        │ 7000       │──▶│ 35      │ 짜장면       │
                    │ 7        │ 38      │ 1        │ 16000      │──▶│ 38      │ 탕수육 (소)  │
                    │ 7        │ 40      │ 1        │ 6000       │──▶│ 40      │ 군만두 (8개) │
                    └──────────┴─────────┴──────────┴────────────┘   └─────────┴──────────────┘
```

고객 이름·가게 주소는 각자의 테이블에 **한 번만** 있고, 주문은 번호(외래키)로 가리키기만 합니다. 그래서 김민준 님이 전화번호를 바꿔도 `customers`의 한 행만 고치면 됩니다. 이렇게 나눠 저장한 데이터를 다시 합쳐 보는 기술이 Ch05의 JOIN입니다.

---

## 3. SQL의 네 가지 종류

SQL 문장은 하는 일에 따라 넷으로 나뉩니다. 이 과정 10챕터의 지도이기도 합니다.

| 분류 | 이름 | 하는 일 | 대표 명령 | 챕터 |
|---|---|---|---|---|
| **DQL·DML** | 데이터 조회·조작 | 데이터를 읽고, 넣고, 고치고, 지움 | `SELECT` / `INSERT` `UPDATE` `DELETE` | 01~06 / 08 |
| **DDL** | 데이터 정의 | 테이블 같은 **구조**를 만들고 바꿈 | `CREATE` `ALTER` `DROP` `TRUNCATE` | 07 |
| **TCL** | 트랜잭션 제어 | 여러 작업을 한 묶음으로 확정·취소 | `COMMIT` `ROLLBACK` `SAVEPOINT` | 08 |
| **DCL** | 데이터 제어 | 사용자 **권한**을 주고 뺏음 | `GRANT` `REVOKE` | 10 |

> 교과서에 따라 `SELECT`를 DML에 넣기도 하고 DQL로 따로 빼기도 합니다. 정보처리기사는 DML에 포함합니다.

---

## 4. 실습 환경

### MySQL 서버와 Workbench는 다른 프로그램이다

```
 ┌───────────────────────┐   SQL 문장 전송    ┌─────────────────────────┐
 │  MySQL Workbench      │ ─────────────────▶ │  MySQL Server (mysqld)  │
 │  (클라이언트)          │ ◀───────────────── │  (서버, 포트 3306)       │
 │  SQL을 쓰고 결과를 봄  │   결과 표 반환       │  데이터를 실제로 저장   │
 └───────────────────────┘                    └─────────────────────────┘
       Java·Python 프로그램, mysql 명령줄도 모두 "클라이언트"입니다
```

- **서버**가 꺼져 있으면 Workbench는 아무것도 못 합니다. ("Cannot connect to MySQL server" 에러의 1순위 원인)
- 나중에 Spring·Django로 만드는 웹 서비스도 Workbench와 똑같이 **클라이언트로서** 서버에 SQL을 보냅니다.

### 설치 점검표

| 확인 항목 | 확인 방법 | 정상 |
|---|---|---|
| MySQL 서버 버전 | Workbench 접속 후 `SELECT VERSION();` | `8.0.x` 이상 |
| 서버 실행 여부 | Windows: 서비스(services.msc) → `MySQL80` | 실행 중 |
| 접속 정보 | Workbench 홈 → Local instance | `root@localhost:3306` |
| 문자셋 | `SHOW VARIABLES LIKE 'character_set_server';` | `utf8mb4` |

```sql
SELECT VERSION() >= '8.0' AS is_mysql8;
```

<sub>▶ 실행 결과 · 1행</sub>

| is_mysql8 |
|---|
| 1 |


### Workbench에서 SQL 실행하기

| 단축키 | 동작 | 언제 |
|---|---|---|
| `Ctrl + Enter` | **커서가 있는 문장 하나** 실행 | 평소 수업 (가장 많이 씀) |
| `Ctrl + Shift + Enter` | 선택 영역(없으면 전체) 실행 | 설치 스크립트 실행 |
| `Ctrl + /` | 선택한 줄 주석 토글 | |
| `Ctrl + B` | 선택 쿼리 자동 정렬 (Beautify) | |

---

## 5. 한입배달 DB 설치 — 챕터마다 새 DB

이 과정은 **챕터를 시작할 때마다 새 데이터베이스를 만듭니다.**

| 챕터 | 실행할 파일 | 만들어지는 DB |
|---|---|---|
| Ch01 | `chapters/ch01-first-database/setup.sql` | `hanip_delivery01` |
| Ch02 | `chapters/ch02-select-basics/setup.sql` | `hanip_delivery02` |
| Ch03 | `chapters/ch03-functions/setup.sql` | `hanip_delivery03` |
| … | … | … |

- 매 챕터 **같은 데이터로 깨끗하게** 시작합니다. 지난 시간에 실수로 데이터를 지웠어도 상관없습니다.
- 지난 챕터 DB는 **지우지 않고 남겨 둡니다.** 그날 작성한 쿼리와 실습 결과를 나중에 다시 열어 볼 수 있는 **수업 기록**이 됩니다. Ch07(테이블 만들기)·Ch08(데이터 바꾸기)부터는 챕터마다 DB 모양이 달라지므로 이 기록이 특히 유용합니다.

### setup.sql 실행하기

1. Workbench에서 `File > Open SQL Script` → `chapters/ch01-first-database/setup.sql`
2. `Ctrl + Shift + Enter` (전체 실행)
3. 맨 아래 결과에 `current_db = hanip_delivery01`과 테이블별 행 수가 나오면 성공

setup.sql의 첫 부분은 이렇게 생겼습니다. 오늘 배울 내용은 아니지만 **DB를 만드는 SQL은 이 두 줄**입니다.

```sql
CREATE DATABASE hanip_delivery01           -- 새 데이터베이스 만들기 (DDL)
    DEFAULT CHARACTER SET utf8mb4         -- 한글·이모지까지 저장 가능한 문자셋
    DEFAULT COLLATE utf8mb4_0900_ai_ci;   -- 정렬·비교 규칙

USE hanip_delivery01;                      -- 이제부터 이 DB에서 작업
```

> ⚠️ 같은 setup.sql을 **두 번** 실행하면 `Error Code: 1007. Can't create database 'hanip_delivery01'; database exists`로 멈춥니다. 기록을 실수로 덮어쓰지 않게 하는 안전장치입니다. 이 챕터 DB를 **처음 상태로 되돌리고 싶을 때만** 파일 위쪽의 `-- DROP DATABASE IF EXISTS …` 줄에서 `-- `를 지우고 다시 실행하세요.

지금까지 만든 수업 DB 목록은 언제든 이렇게 확인합니다.

```sql
SHOW DATABASES LIKE 'hanip_delivery%';
```

---

## 6. 처음 보는 DB 탐색하기

실무에서 처음 보는 DB를 받으면 아래 순서로 둘러봅니다. **어떤 DB가 있나 → 어떤 테이블이 있나 → 테이블은 어떻게 생겼나 → 데이터는 어떤 모습인가.**

### 6-1. DB 목록과 선택

```sql
SHOW DATABASES;          -- 서버에 있는 DB 목록 (sys, mysql 등 시스템 DB도 보임)
USE hanip_delivery01;    -- 이제부터 이 DB를 기준으로 실행 (오늘은 01번)
```

```sql
SELECT DATABASE() AS current_db;   -- 지금 선택된 DB 확인
```

<sub>▶ 실행 결과 · 1행</sub>

| current_db |
|---|
| hanip_delivery01 |


> `USE`를 빼먹으면 `Error Code: 1046. No database selected`가 납니다. Workbench 왼쪽 SCHEMAS 패널에서 DB 이름을 **더블클릭**해도 `USE`와 같습니다 (굵게 표시됨).

### 6-2. 테이블 목록

```sql
SHOW TABLES;
```

<sub>▶ 실행 결과 · 7행</sub>

| Tables_in_hanip_delivery01 |
|---|
| customers |
| menus |
| order_items |
| orders |
| restaurants |
| reviews |
| riders |


### 6-3. 테이블 구조 — DESC

`DESC 테이블명`(DESCRIBE)은 테이블의 **설계도**를 보여 줍니다.

```sql
DESC restaurants;
```

<sub>▶ 실행 결과 · 12행</sub>

| Field | Type | Null | Key | Default | Extra |
|---|---|---|---|---|---|
| restaurant_id | int | NO | PRI | NULL | auto_increment |
| name | varchar(50) | NO |  | NULL |  |
| category | varchar(10) | NO |  | NULL |  |
| district | varchar(10) | NO |  | NULL |  |
| address | varchar(100) | NO |  | NULL |  |
| phone | varchar(13) | YES |  | NULL |  |
| min_order_amount | int | NO |  | 0 |  |
| delivery_fee | int | NO |  | 3000 |  |
| open_time | time | NO |  | NULL |  |
| close_time | time | NO |  | NULL |  |
| opened_at | date | NO |  | NULL |  |
| is_open | tinyint(1) | NO |  | 1 |  |


| 열 | 의미 |
|---|---|
| `Field` | 열 이름 |
| `Type` | 데이터 타입 — `int` 정수, `varchar(50)` 최대 50자 문자열, `time` 시각, `date` 날짜, `tinyint(1)` 참/거짓 |
| `Null` | `NO`면 반드시 값이 있어야 함, `YES`면 비워 둘 수 있음 |
| `Key` | `PRI` 기본키, `UNI` 중복 불가, `MUL` 외래키 등 인덱스가 걸린 열 |
| `Default` | 값을 안 넣었을 때 자동으로 들어가는 값 |
| `Extra` | `auto_increment` — 번호를 자동으로 1씩 늘려 매김 |

> `BOOLEAN`으로 만든 열은 MySQL 내부에서 `tinyint(1)`로 저장됩니다. `TRUE`는 `1`, `FALSE`는 `0`입니다.

### 6-4. 데이터 미리보기 — SELECT … LIMIT

```sql
SELECT * FROM restaurants LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| restaurant_id | name | category | district | address | phone | min_order_amount | delivery_fee | open_time | close_time | opened_at | is_open |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 서면옛날돼지국밥 | 한식 | 부산진구 | 부산광역시 부산진구 부전동 서면로 68 | 051-805-1124 | 10000 | 2500 | 09:00:00 | 22:00:00 | 2023-03-15 | 1 |
| 2 | 전포카츠 | 일식 | 부산진구 | 부산광역시 부산진구 전포동 전포대로 199 | 051-816-3302 | 12000 | 3000 | 11:00:00 | 21:00:00 | 2024-05-02 | 1 |
| 3 | 해운대명가밀면 | 한식 | 해운대구 | 부산광역시 해운대구 중동 해운대로 570 | 051-742-5508 | 9000 | 2000 | 10:30:00 | 20:30:00 | 2022-07-01 | 1 |
| 4 | 광안리화덕피자 | 피자 | 수영구 | 부산광역시 수영구 광안동 광안해변로 219 | 051-757-2210 | 18000 | 3500 | 11:30:00 | 23:00:00 | 2023-09-20 | 1 |
| 5 | 남천동마라공방 | 중식 | 수영구 | 부산광역시 수영구 남천동 수영로 312 | NULL | 13000 | 3000 | 11:00:00 | 22:00:00 | 2025-02-10 | 1 |


- `*` 는 "모든 열". 탐색할 때는 편하지만, 실무 코드에서는 필요한 열만 적습니다 (Ch02).
- `LIMIT 5` 는 "5행만". 주문처럼 큰 테이블을 `LIMIT` 없이 열면 수만~수억 행을 가져오느라 오래 걸립니다. **처음 보는 테이블은 항상 `LIMIT`부터.**
- `LIMIT`만 쓰면 어떤 5행이 나올지 **보장되지 않습니다**. 순서를 정하는 `ORDER BY`는 Ch02에서 배웁니다.

필요한 열만 골라서 보기:

```sql
SELECT name, category, district FROM restaurants LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| name | category | district |
|---|---|---|
| 서면옛날돼지국밥 | 한식 | 부산진구 |
| 전포카츠 | 일식 | 부산진구 |
| 해운대명가밀면 | 한식 | 해운대구 |
| 광안리화덕피자 | 피자 | 수영구 |
| 남천동마라공방 | 중식 | 수영구 |


### 6-5. 몇 행인지 세기 — COUNT(*) 맛보기

```sql
SELECT COUNT(*) FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| COUNT(*) |
|---|
| 563 |


> `COUNT(*)`는 Ch04에서 자세히 배웁니다. 오늘은 "행 개수를 세는 도구" 정도로만 씁니다.

### 6-6. 구조 원문 보기 — SHOW CREATE TABLE

```sql
SHOW CREATE TABLE menus;
```

테이블을 만들 때 쓴 `CREATE TABLE` 문장 전체를 보여 줍니다. 지금은 `FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)` 한 줄만 찾아보세요. **"메뉴는 반드시 존재하는 가게에 속해야 한다"**는 규칙이 이렇게 구조에 새겨져 있습니다. 나머지는 Ch07에서 한 줄씩 해부합니다.

---

## 7. SQL 작성 규칙

과정 전체 규칙은 [docs/CONVENTIONS.md](../../docs/CONVENTIONS.md). 오늘은 다섯 가지만 기억합니다.

1. **예약어는 대문자, 테이블·열 이름은 소문자.** MySQL은 예약어 대소문자를 구분하지 않지만 읽기 쉬워집니다.
2. **문장 끝에는 세미콜론 `;`.** 여러 문장이 있을 때 경계가 됩니다.
3. **문자열과 날짜는 작은따옴표** `'부산진구'`, `'2026-06-30'`.
4. **절마다 줄바꿈.** 길어지면 `SELECT` / `FROM` / `WHERE`를 각각 새 줄에.
5. **주석**은 `-- `(하이픈 두 개 + **공백**) 또는 `/* 여러 줄 */`.

```sql
-- 한 줄 주석: 이 줄은 실행되지 않습니다
SELECT name,        /* 상호 */
    category        -- 업종
FROM restaurants
LIMIT 3;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | category |
|---|---|
| 서면옛날돼지국밥 | 한식 |
| 전포카츠 | 일식 |
| 해운대명가밀면 | 한식 |


---

## 8. 에러 메시지 읽는 법

에러는 실패가 아니라 **DB가 주는 힌트**입니다. Workbench 아래 Output 창의 메시지는 항상 같은 구조입니다.

```
Error Code: 1146. Table 'hanip_delivery01.restaurant' doesn't exist
            ────  ────────────────────────────────────────────────
            번호   무엇이 잘못됐는지 (영어지만 핵심 단어만 읽으면 됨)
```

입문 단계에서 90%를 차지하는 네 가지입니다.

**① 1146 — 테이블이 없음** (이름 오타, 단수/복수 실수)

```sql
SELECT * FROM restaurant;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1146. Table 'hanip_delivery01.restaurant' doesn't exist
```


**② 1054 — 열이 없음** (열 이름 오타, 다른 테이블의 열)

```sql
SELECT menu_name FROM menus;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1054. Unknown column 'menu_name' in 'field list'
```


> 메뉴명 열의 이름은 `menu_name`이 아니라 `name`입니다. 열 이름이 기억나지 않으면 추측하지 말고 `DESC menus;`로 확인하세요.

**③ 1064 — 문법 오류** (쉼표·따옴표·키워드 순서). `near '…'` 바로 **앞**을 보세요.

```sql
SELECT name category, FROM restaurants;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1064. You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'FROM restaurants' at line 1
```


> `near 'FROM restaurants'` → FROM 바로 앞, 즉 `category,` 의 쉼표가 문제입니다. (덤으로 `name category`는 쉼표가 빠져서 `category`가 `name`의 별칭이 됩니다. Ch02에서 다룹니다.)

**④ 1046 — DB를 선택하지 않음**

```text
Error Code: 1046. No database selected
```

> `USE hanip_delivery01;` 를 먼저 실행하거나, SCHEMAS 패널에서 DB를 더블클릭합니다.

### 에러가 나면 이 순서로

1. **에러 번호**를 본다 → 위 네 가지 중 무엇인가?
2. 메시지 속 **이름**(테이블·열)이나 **`near` 뒤의 위치**를 본다.
3. `SHOW TABLES;` / `DESC 테이블;` 로 실제 이름과 비교한다.
4. 그래도 모르겠으면 에러 메시지를 **그대로 복사해서** 검색하거나 질문한다. ("에러 났어요"가 아니라 "1054 Unknown column 'menu_name'이 나요")

---

## 정리

| 개념 | 한 줄 요약 |
|---|---|
| DBMS | 데이터를 정확·동시·안전하게 다루는 소프트웨어 (MySQL) |
| 테이블·행·열 | 표 · 데이터 한 건 · 항목 |
| 기본키 / 외래키 | 행을 콕 집는 값 / 다른 테이블의 기본키를 가리키는 값 |
| SQL 분류 | DML(조회·조작) · DDL(구조) · TCL(트랜잭션) · DCL(권한) |
| 챕터별 DB | 매 챕터 `setup.sql` → `hanip_deliveryNN` 생성, 지난 DB는 기록으로 보관 |
| 탐색 순서 | `SHOW DATABASES` → `USE` → `SHOW TABLES` → `DESC` → `SELECT … LIMIT` |
| 에러 | 번호 → 이름/위치 → `DESC`로 비교 |

## 다음 챕터 예고

> **From.** 운영팀 박 팀장
> 부산진구·수영구에 있는 **영업 중인** 가게 중에서 **최소 주문 금액이 15,000원 이하**인 곳만, **배달팁이 싼 순서로** 뽑아 주세요.

`SELECT * FROM restaurants`로는 15곳 전부가 나옵니다. 원하는 **행만** 고르고 **순서**를 정하는 방법 — Ch02에서 배웁니다.
