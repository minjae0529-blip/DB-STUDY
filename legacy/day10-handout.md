# Day 10 핸드아웃 — 도서관 DB 라이브 코딩
## 한국IT교육센터 부산점 | MySQL 10일 완성 | library_db

---

> 💡 **오늘의 핵심 질문**
> "10일간 배운 걸 처음부터 끝까지 한번에 써먹을 수 있을까?"

오늘은 강사와 함께 **도서관 DB(library_db)** 를 처음부터 끝까지 만들어봅니다.
사용자 관리 → 백업 → 📚 도서관 DB 라이브 코딩 → 정보처리기사 기출 순서로 진행합니다.

---

## 목차

1. [사용자 관리 (DCL)](#1-사용자-관리-dcl)
2. [백업 & 복원](#2-백업--복원)
3. [도서관 DB 라이브 코딩 6단계](#3-도서관-db-라이브-코딩-6단계)
4. [정보처리기사 SQL 기출 유형 5가지](#4-정보처리기사-sql-기출-유형-5가지)
5. [10일 전체 SQL 치트시트](#5-10일-전체-sql-치트시트)
6. [이후 학습 로드맵](#6-이후-학습-로드맵)

---

## 1. 사용자 관리 (DCL)

### 1.1 왜 사용자 관리가 필요한가?

지금까지 우리는 **root** 계정으로 모든 작업을 했습니다.
하지만 실무에서는 역할에 따라 권한을 나눠야 합니다.

> 💡 **비유: 배달앱 직원 권한**
> - **아르바이트생** → 주문 조회(SELECT)만 가능
> - **매니저** → 주문 조회 + 메뉴 추가/수정(INSERT/UPDATE)까지
> - **오너(root)** → 모든 것(ALL PRIVILEGES) 가능

---

### 1.2 CREATE USER — 사용자 생성

#### 문법

```sql
CREATE USER '사용자명'@'호스트' IDENTIFIED BY '비밀번호';
```

#### 예시

```sql
-- 로컬 전용 계정 (localhost에서만 접속 가능)
CREATE USER 'hanip_staff'@'localhost' IDENTIFIED BY 'Staff1234!';

-- 어디서든 접속 가능한 계정 (% = 모든 호스트)
CREATE USER 'hanip_analyst'@'%' IDENTIFIED BY 'Analyst1234!';
```

#### `'user'@'localhost'` vs `'user'@'%'` 차이

| 표현 | 의미 | 사용 상황 |
|------|------|-----------|
| `'user'@'localhost'` | 같은 서버 내에서만 접속 가능 | 개발/테스트 환경, 로컬 앱 |
| `'user'@'127.0.0.1'` | IPv4 루프백 주소로만 접속 | localhost와 거의 동일 |
| `'user'@'%'` | 모든 IP에서 접속 가능 | 원격 접속이 필요한 경우 |
| `'user'@'192.168.1.%'` | 특정 대역 IP만 허용 | 사내 네트워크 전용 |

⚠️ **주의**: `'user'@'%'`는 편리하지만 보안 위험이 있습니다. 운영 환경에서는 IP 범위를 좁히세요.

---

### 1.3 GRANT — 권한 부여

#### 문법

```sql
GRANT 권한종류 ON 데이터베이스.테이블 TO '사용자명'@'호스트';
```

#### 권한 종류 표

| 권한 | 설명 | 예시 상황 |
|------|------|-----------|
| `SELECT` | 데이터 조회 | 통계 분석 전용 계정 |
| `INSERT` | 데이터 삽입 | 주문 접수 처리 |
| `UPDATE` | 데이터 수정 | 주문 상태 변경 |
| `DELETE` | 데이터 삭제 | 데이터 정리 담당자 |
| `CREATE` | 테이블/DB 생성 | 개발자 계정 |
| `DROP` | 테이블/DB 삭제 | 관리자 계정 |
| `INDEX` | 인덱스 생성/삭제 | DBA |
| `ALTER` | 테이블 구조 변경 | DBA |
| `ALL PRIVILEGES` | 모든 권한 | 오너/DBA |
| `GRANT OPTION` | 다른 사용자에게 권한 부여 가능 | 팀장급 |

#### 예시

```sql
-- hanip_db 전체에 SELECT만 허용
GRANT SELECT ON hanip_db.* TO 'hanip_staff'@'localhost';

-- 특정 테이블에만 SELECT/INSERT 허용
GRANT SELECT, INSERT ON hanip_db.orders TO 'hanip_staff'@'localhost';

-- 모든 권한 부여 (DBA 계정)
GRANT ALL PRIVILEGES ON hanip_db.* TO 'hanip_analyst'@'localhost';

-- 권한 변경사항 즉시 반영
FLUSH PRIVILEGES;
```

⭐ **MySQL 8.x 주의사항**:
MySQL 8.0부터 `GRANT` 명령으로 계정을 자동 생성할 수 없습니다.
반드시 **CREATE USER 먼저 → 그 다음 GRANT** 순서로 실행하세요.

```sql
-- ❌ MySQL 8.x에서 안 됨 (예전 방식)
GRANT ALL ON hanip_db.* TO 'newuser'@'localhost' IDENTIFIED BY 'pw';

-- ✅ MySQL 8.x 올바른 방식
CREATE USER 'newuser'@'localhost' IDENTIFIED BY 'pw';
GRANT ALL ON hanip_db.* TO 'newuser'@'localhost';
FLUSH PRIVILEGES;
```

---

### 1.4 SHOW GRANTS FOR — 권한 확인

```sql
-- 특정 사용자의 권한 확인
SHOW GRANTS FOR 'hanip_staff'@'localhost';

-- 현재 로그인한 사용자의 권한 확인
SHOW GRANTS;
SHOW GRANTS FOR CURRENT_USER();
```

결과 예시:

```
+-----------------------------------------------------------------------+
| Grants for hanip_staff@localhost                                      |
+-----------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `hanip_staff`@`localhost`                      |
| GRANT SELECT ON `hanip_db`.* TO `hanip_staff`@`localhost`            |
+-----------------------------------------------------------------------+
```

---

### 1.5 REVOKE — 권한 회수

#### 문법

```sql
REVOKE 권한종류 ON 데이터베이스.테이블 FROM '사용자명'@'호스트';
```

#### 예시

```sql
-- INSERT 권한만 회수
REVOKE INSERT ON hanip_db.* FROM 'hanip_staff'@'localhost';

-- 모든 권한 회수
REVOKE ALL PRIVILEGES ON hanip_db.* FROM 'hanip_analyst'@'localhost';
```

---

### 1.6 DROP USER — 사용자 삭제

```sql
-- 사용자 삭제
DROP USER 'hanip_staff'@'localhost';

-- 존재하지 않아도 에러 없이 넘어가기
DROP USER IF EXISTS 'hanip_staff'@'localhost';
```

---

### 1.7 사용자 관리 전체 실습 시나리오

```sql
-- ① 읽기 전용 직원 계정 생성
CREATE USER 'readonly_staff'@'localhost' IDENTIFIED BY 'Read1234!';

-- ② SELECT 권한만 부여
GRANT SELECT ON hanip_db.* TO 'readonly_staff'@'localhost';
FLUSH PRIVILEGES;

-- ③ 권한 확인
SHOW GRANTS FOR 'readonly_staff'@'localhost';

-- ④ 해당 계정으로 INSERT 시도 → 에러 발생 확인
-- (Workbench에서 새 커넥션으로 테스트)

-- ⑤ 권한 업그레이드 (매니저로 승진)
GRANT INSERT, UPDATE ON hanip_db.orders TO 'readonly_staff'@'localhost';
FLUSH PRIVILEGES;

-- ⑥ 직원 퇴사 처리
DROP USER 'readonly_staff'@'localhost';
```

⭐ **팁**: 실무에서는 비밀번호에 대문자+숫자+특수문자를 섞어야 MySQL의 보안 정책을 통과합니다.

---

## 2. 백업 & 복원

### 2.1 왜 백업이 필요한가?

> ⚠️ "WHERE 없이 DELETE FROM orders 실행 → 50건 데이터 전부 삭제"

이런 상황을 대비해 **주기적인 백업**이 필수입니다.

---

### 2.2 mysqldump — 명령줄 백업

#### 기본 문법 (터미널/CMD에서 실행)

```bash
mysqldump -u [사용자] -p [데이터베이스명] > [파일명.sql]
```

#### 실전 예시

```bash
# hanip_db 전체 백업 (데이터 + 구조 모두)
mysqldump -u root -p hanip_db > hanip_backup_20260511.sql

# 구조만 백업 (데이터 없이)
mysqldump -u root -p --no-data hanip_db > hanip_structure.sql

# 여러 DB 한꺼번에 백업
mysqldump -u root -p --databases hanip_db test_db > multi_backup.sql

# 모든 DB 백업
mysqldump -u root -p --all-databases > all_backup.sql

# InnoDB 테이블 락 없이 안전하게 백업 (운영 중 백업)
mysqldump -u root -p --single-transaction hanip_db > hanip_safe_backup.sql
```

#### 주요 옵션 정리

| 옵션 | 설명 | 사용 상황 |
|------|------|-----------|
| `--no-data` | 테이블 구조만 백업 (INSERT 없음) | 스키마 공유, 신규 환경 구축 |
| `--databases DB1 DB2` | 여러 DB 지정 백업 | 여러 프로젝트 한꺼번에 |
| `--all-databases` | 모든 DB 백업 | 서버 전체 백업 |
| `--single-transaction` | 트랜잭션 내에서 백업 (InnoDB) | 서비스 중단 없는 백업 |
| `--where="id > 100"` | 조건에 맞는 데이터만 백업 | 부분 백업 |
| `--ignore-table=DB.테이블` | 특정 테이블 제외 | 로그 테이블 제외 등 |

---

### 2.3 복원 방법

```bash
# 백업 파일로 복원 (터미널에서 실행)
mysql -u root -p hanip_db < hanip_backup_20260511.sql

# 데이터베이스가 없는 경우, 먼저 생성 후 복원
mysql -u root -p -e "CREATE DATABASE hanip_db;"
mysql -u root -p hanip_db < hanip_backup_20260511.sql
```

MySQL Workbench에서 복원:

```sql
-- 또는 Workbench SQL 에디터에서 직접 실행
SOURCE /Users/code1218/korit/hanip_backup_20260511.sql;
```

---

### 2.4 MySQL Workbench GUI 백업 방법

#### Data Export (백업)

1. Workbench 상단 메뉴 → **Server** → **Data Export**
2. 왼쪽 패널에서 백업할 **데이터베이스 선택** (hanip_db 체크)
3. 오른쪽에서 백업할 **테이블 선택** (또는 전체)
4. Export Options:
   - `Export to Dump Project Folder`: 테이블별 개별 파일
   - `Export to Self-Contained File`: 단일 .sql 파일 ← **권장**
5. **Start Export** 클릭

#### Data Import (복원)

1. **Server** → **Data Import**
2. `Import from Self-Contained File` 선택
3. 백업 파일(.sql) 경로 지정
4. `Default Target Schema`에 복원할 데이터베이스 선택 또는 생성
5. **Start Import** 클릭

---

### 2.5 백업 전략: 언제, 얼마나 자주?

| 백업 유형 | 주기 | 방법 | 대상 |
|-----------|------|------|------|
| **풀 백업** | 주 1회 (주말) | mysqldump --all-databases | 전체 DB |
| **증분 백업** | 매일 | Binary Log 활용 | 변경 데이터만 |
| **스냅샷** | 큰 변경 전 | mysqldump 해당 DB | 특정 DB |
| **개발 전 백업** | 매번 | mysqldump | 변경 대상 DB |

> ⭐ **황금 규칙**: "배포 전에는 반드시 백업부터!"
> 학생 프로젝트에서도 실수로 전체 삭제 시를 대비해 백업 습관을 들이세요.

---

## 3. 도서관 DB 라이브 코딩 6단계

> 📚 **library_db** — 도서관 관리 시스템을 처음부터 끝까지 함께 만들어봅니다.
> Day 1~9에서 배운 모든 기술을 한 번에 복습하는 시간입니다.

### 전체 흐름 (90분)

```
[STEP 1] DB 생성 + ERD 설명  (15분)
    ↓
[STEP 2] CREATE TABLE        (20분)
    ↓
[STEP 3] INSERT 데이터        (15분)
    ↓
[STEP 4] SELECT 쿼리         (20분)
    ↓
[STEP 5] 서브쿼리 + VIEW + INDEX  (15분)
    ↓
[STEP 6] DCL — 사서 계정 만들기   ( 5분)
```

---

### STEP 1: DB 생성 + ERD 설명 (15분)

#### ERD 관계도

```
[authors]     1 ──── N  [books]
[categories]  1 ──── N  [books]
[members]     1 ──── N  [rentals]
[books]       1 ──── N  [rentals]
[members]     1 ──── N  [reservations]
[books]       1 ──── N  [reservations]
```

#### 테이블 생성 순서 — 부모 먼저!

```
authors → categories → books → members → rentals → reservations
```

> ⚠️ FK를 가진 테이블은 참조 대상(부모)보다 반드시 나중에 만들어야 합니다.

```sql
DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE library_db;
```

---

### STEP 2: CREATE TABLE (20분)

#### 2-1. authors (저자 — 부모)

```sql
CREATE TABLE authors (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(50) NOT NULL,
    nationality VARCHAR(30) DEFAULT '한국',
    birth_year  INT
);
```

#### 2-2. categories (장르 — 부모)

```sql
CREATE TABLE categories (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(100)
);
```

#### 2-3. books (도서 — 자식)

```sql
CREATE TABLE books (
    id               INT          PRIMARY KEY AUTO_INCREMENT,
    title            VARCHAR(100) NOT NULL,
    author_id        INT,
    category_id      INT,
    isbn             VARCHAR(20)  UNIQUE,
    published_year   INT,
    total_copies     INT          NOT NULL DEFAULT 1,
    available_copies INT          NOT NULL DEFAULT 1,
    FOREIGN KEY (author_id)   REFERENCES authors(id)    ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);
```

> 💡 **ON DELETE SET NULL**: 저자가 삭제되어도 책은 남되, author_id가 NULL로 바뀜

#### 2-4. members (회원 — 독립)

```sql
CREATE TABLE members (
    id              INT         PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(30) NOT NULL,
    phone           VARCHAR(15) UNIQUE,
    email           VARCHAR(50) UNIQUE,
    joined_date     DATE        DEFAULT (CURDATE()),
    membership_type VARCHAR(10) DEFAULT '일반'  -- 일반 / 프리미엄
);
```

#### 2-5. rentals (대출 — 자식)

```sql
CREATE TABLE rentals (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    book_id     INT         NOT NULL,
    member_id   INT         NOT NULL,
    rented_at   DATE        DEFAULT (CURDATE()),
    due_date    DATE        NOT NULL,
    returned_at DATE,                            -- NULL = 아직 반납 안 함
    status      VARCHAR(10) DEFAULT '대출중',    -- 대출중 / 반납완료 / 연체
    FOREIGN KEY (book_id)   REFERENCES books(id),
    FOREIGN KEY (member_id) REFERENCES members(id)
);
```

#### 2-6. reservations (예약 — 자식)

```sql
CREATE TABLE reservations (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    book_id     INT         NOT NULL,
    member_id   INT         NOT NULL,
    reserved_at DATETIME    DEFAULT CURRENT_TIMESTAMP,
    status      VARCHAR(10) DEFAULT '대기중',    -- 대기중 / 확정 / 취소
    FOREIGN KEY (book_id)   REFERENCES books(id),
    FOREIGN KEY (member_id) REFERENCES members(id)
);
```

#### 체크리스트

```
[ ] SHOW TABLES; 로 6개 테이블 모두 생성됐는지 확인
[ ] DESC books; 로 FK 컬럼 확인
[ ] 부모→자식 순서로 생성했는가?
```

---

### STEP 3: INSERT 데이터 (15분)

> 📌 **핵심 원칙**: 부모 테이블 데이터를 먼저 넣어야 FK 에러가 나지 않습니다!

```sql
-- 1. authors
INSERT INTO authors (name, nationality, birth_year) VALUES
('김영하', '한국', 1968), ('한강', '한국', 1970),
('무라카미 하루키', '일본', 1949), ('조지 오웰', '영국', 1903),
('생텍쥐페리', '프랑스', 1900);

-- 2. categories
INSERT INTO categories (name, description) VALUES
('소설', '국내외 소설 작품'), ('에세이', '개인 경험과 생각을 담은 글'),
('과학', '과학 이론 및 교양 과학'), ('역사', '역사적 사건과 인물'),
('자기계발', '성장과 동기부여 관련');

-- 3. books (author_id=NULL 포함 → LEFT JOIN 실습용)
INSERT INTO books (title, author_id, category_id, published_year, total_copies, available_copies) VALUES
('채식주의자',      2, 1, 2007, 3, 2),
('노르웨이의 숲',   3, 1, 1987, 4, 3),
('1984',           4, 1, 1949, 3, 3),
('어린 왕자',      5, 1, 1943, 5, 4),
('작별하지 않는다', 2, 1, 2021, 2, 0),  -- 재고 0 → 예약 실습용
('코스모스',       NULL, 3, 1980, 2, 2); -- 저자 NULL → LEFT JOIN 실습용

-- 4. members (대출 없는 회원 2명 의도적 포함 → LEFT JOIN IS NULL 실습용)
INSERT INTO members (name, phone, email, membership_type) VALUES
('김지수', '010-1111-2222', 'jisu@email.com',    '프리미엄'),
('이민준', '010-3333-4444', 'minjun@email.com',  '일반'),
('박서연', '010-5555-6666', 'seoyeon@email.com', '일반'),
('윤수아', '010-4444-5555', 'sua@email.com',     '일반'),  -- 대출 없음
('임태양', '010-6666-7777', 'taeyang@email.com', '일반');  -- 대출 없음

-- 5. rentals (상태 다양하게)
INSERT INTO rentals (book_id, member_id, rented_at, due_date, returned_at, status) VALUES
(1, 1, '2026-03-01', '2026-03-15', '2026-03-14', '반납완료'),
(2, 1, '2026-04-01', '2026-04-15', NULL,          '대출중'),
(3, 2, '2026-04-10', '2026-04-24', NULL,          '대출중'),
(2, 2, '2026-03-10', '2026-03-24', '2026-03-30', '연체'),
(4, 3, '2026-05-01', '2026-05-15', NULL,          '대출중');

-- 6. reservations
INSERT INTO reservations (book_id, member_id, status) VALUES
(5, 1, '대기중'), (5, 2, '대기중'), (1, 3, '확정');
```

---

### STEP 4: SELECT 쿼리 (20분)

#### Q1. 현재 대출 중인 도서 [Day 3]

```sql
SELECT * FROM rentals WHERE status = '대출중' ORDER BY due_date;
```

#### Q2. 연체 중인 대출 + 연체일수 [Day 4]

```sql
SELECT b.title AS 도서명, m.name AS 회원명,
       r.due_date AS 반납기한,
       DATEDIFF(CURDATE(), r.due_date) AS 연체일수
FROM rentals r
JOIN books   b ON r.book_id   = b.id
JOIN members m ON r.member_id = m.id
WHERE r.status = '연체';
```

#### Q3. 장르별 도서 수 [Day 5]

```sql
SELECT c.name AS 장르, COUNT(b.id) AS 도서수
FROM categories c
LEFT JOIN books b ON c.id = b.category_id
GROUP BY c.id, c.name
ORDER BY 도서수 DESC;
```

#### Q4. 회원별 대출 횟수 (2회 이상) [Day 5]

```sql
SELECT m.name AS 회원명, COUNT(r.id) AS 대출횟수
FROM members m
LEFT JOIN rentals r ON m.id = r.member_id
GROUP BY m.id, m.name
HAVING COUNT(r.id) >= 2
ORDER BY 대출횟수 DESC;
```

#### Q5. 전체 대출 내역 (도서명 + 저자 + 회원명) [Day 6]

```sql
SELECT r.id AS 대출번호, b.title AS 도서명,
       a.name AS 저자, m.name AS 회원명,
       r.rented_at AS 대출일, r.status AS 상태
FROM rentals r
JOIN books   b ON r.book_id   = b.id
LEFT JOIN authors a ON b.author_id = a.id  -- 저자 없는 책도 포함
JOIN members m ON r.member_id = m.id
ORDER BY r.rented_at DESC;
```

#### Q6. 한 번도 대출하지 않은 회원 [Day 6]

```sql
SELECT m.name AS 미대출회원, m.phone
FROM members m
LEFT JOIN rentals r ON m.id = r.member_id
WHERE r.id IS NULL;
```

---

### STEP 5: 서브쿼리 + VIEW + INDEX (15분)

#### Q7. 평균 대출 횟수보다 많이 빌린 회원 [Day 7]

```sql
SELECT m.name AS 회원명, COUNT(r.id) AS 대출횟수
FROM members m
JOIN rentals r ON m.id = r.member_id
GROUP BY m.id, m.name
HAVING COUNT(r.id) > (
    SELECT AVG(cnt)
    FROM (SELECT COUNT(*) AS cnt FROM rentals GROUP BY member_id) AS sub
)
ORDER BY 대출횟수 DESC;
```

#### VIEW 생성 [Day 8]

```sql
CREATE VIEW v_rental_status AS
SELECT r.id AS 대출번호,
       b.title AS 도서명,
       m.name  AS 회원명,
       r.due_date AS 반납기한,
       IFNULL(DATEDIFF(CURDATE(), r.due_date), 0) AS 연체일수,
       r.status AS 상태
FROM rentals r
JOIN books   b ON r.book_id   = b.id
JOIN members m ON r.member_id = m.id;

-- 활용
SELECT * FROM v_rental_status WHERE 연체일수 > 0 ORDER BY 연체일수 DESC;
```

#### INDEX + EXPLAIN [Day 8]

```sql
-- 인덱스 전
EXPLAIN SELECT * FROM rentals WHERE member_id = 1;
-- type=ALL (전체 탐색)

CREATE INDEX idx_rentals_member ON rentals(member_id);

-- 인덱스 후
EXPLAIN SELECT * FROM rentals WHERE member_id = 1;
-- type=ref, rows 대폭 감소 ✅
```

---

### STEP 6: DCL — 사서 계정 만들기 (5분)

> 💡 **비유**: 도서관 사서는 대출/반납만 처리하면 됩니다.
> 책을 삭제하거나 테이블을 수정하는 권한은 필요 없습니다.

```sql
-- 사서 계정 (대출/예약 관리만)
CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'Lib2026!';
GRANT SELECT                     ON library_db.*             TO 'librarian'@'localhost';
GRANT INSERT, UPDATE             ON library_db.rentals       TO 'librarian'@'localhost';
GRANT INSERT, UPDATE             ON library_db.reservations  TO 'librarian'@'localhost';
FLUSH PRIVILEGES;

-- 관리자 계정 (전체 권한)
CREATE USER 'lib_admin'@'localhost' IDENTIFIED BY 'Admin2026!';
GRANT ALL PRIVILEGES ON library_db.* TO 'lib_admin'@'localhost';
FLUSH PRIVILEGES;

-- 권한 확인
SHOW GRANTS FOR 'librarian'@'localhost';
SHOW GRANTS FOR 'lib_admin'@'localhost';
```

#### 사서 vs 관리자 권한 비교

| 작업 | librarian | lib_admin |
|------|-----------|-----------|
| 도서 조회 | ✅ SELECT | ✅ |
| 대출 등록 | ✅ INSERT | ✅ |
| 대출 상태 변경 | ✅ UPDATE | ✅ |
| 도서 삭제 | ❌ | ✅ |
| 회원 삭제 | ❌ | ✅ |
| 테이블 구조 변경 | ❌ | ✅ |

---

### 🎉 완성! — library_db 최종 점검

```sql
SELECT '도서수'    AS 항목, COUNT(*) AS 건수 FROM books
UNION ALL SELECT '회원수',   COUNT(*) FROM members
UNION ALL SELECT '대출수',   COUNT(*) FROM rentals
UNION ALL SELECT '예약수',   COUNT(*) FROM reservations
UNION ALL SELECT '현재대출중', COUNT(*) FROM rentals WHERE status = '대출중'
UNION ALL SELECT '연체건수',  COUNT(*) FROM rentals WHERE status = '연체';
```

---

## 4. 정보처리기사 SQL 기출 유형 5가지

### 유형 1: SELECT 결과 예측

💡 **핵심 포인트**
- WHERE 조건의 논리 연산자 (AND, OR) 우선순위 파악
- ORDER BY 방향 (ASC/DESC 기본값은 ASC)
- NULL 값이 있을 때 비교 연산 결과

#### 기준 데이터 (employees 테이블)

| id | name | dept | salary |
|----|------|------|--------|
| 1  | 김철수 | A | 3500 |
| 2  | 이영희 | B | 2800 |
| 3  | 박민준 | A | 4200 |
| 4  | 최수연 | C | 3100 |
| 5  | 정태양 | A | 2900 |
| 6  | 한지민 | B | 3800 |

#### 기출 스타일 문제 1-1

```sql
SELECT name, salary
FROM employees
WHERE dept = 'A' AND salary > 3000
ORDER BY salary DESC;
```

**Q. 위 쿼리의 결과로 올바른 것은?**

① 김철수(3500), 박민준(4200)
② 박민준(4200), 김철수(3500)
③ 김철수(3500), 박민준(4200), 정태양(2900)
④ 박민준(4200), 정태양(2900)

**정답**: ②
**해설**: dept='A'이고 salary>3000인 직원은 김철수(3500)와 박민준(4200). ORDER BY salary DESC이므로 높은 금액부터 → 박민준, 김철수 순서.

---

#### 기출 스타일 문제 1-2

```sql
SELECT COUNT(*), COUNT(dept), AVG(salary)
FROM employees
WHERE salary >= 3000;
```

**Q. 위 쿼리의 결과가 올바르게 짝지어진 것은? (dept 컬럼에 NULL이 1건 있다고 가정)**

① COUNT(*): 4, COUNT(dept): 4, AVG: 3650
② COUNT(*): 4, COUNT(dept): 3, AVG: 3650
③ COUNT(*): 6, COUNT(dept): 6, AVG: 3383
④ COUNT(*): 4, COUNT(dept): 4, AVG: 14600

**정답**: ②
**해설**: salary >= 3000 조건을 만족하는 행은 4개(3500, 4200, 3100, 3800). COUNT(*)는 NULL 포함 행 수 → 4. COUNT(dept)는 dept가 NULL이 아닌 행만 → 3. AVG = (3500+4200+3100+3800)/4 = 3650.

---

### 유형 2: JOIN 결과 행 수

💡 **핵심 포인트**
- INNER JOIN: 양쪽 모두 매칭되는 행만 결과에 포함
- LEFT JOIN: 왼쪽 테이블 기준, 오른쪽에 없으면 NULL로 포함
- 1:N 관계에서 JOIN 시 행 수는 N쪽 기준

#### 기준 데이터

**departments 테이블**

| dept_id | dept_name |
|---------|-----------|
| A | 개발팀 |
| B | 마케팅팀 |
| C | 디자인팀 |

**employees 테이블** (dept_id가 없는 직원 포함)

| emp_id | name | dept_id |
|--------|------|---------|
| 1 | 김철수 | A |
| 2 | 이영희 | B |
| 3 | 박민준 | A |
| 4 | 최수연 | NULL |
| 5 | 정태양 | D |

#### 기출 스타일 문제 2-1

```sql
-- 쿼리 A: INNER JOIN
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 쿼리 B: LEFT JOIN
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
```

**Q. 쿼리 A와 쿼리 B의 결과 행 수로 올바른 것은?**

① A: 3행, B: 5행
② A: 5행, B: 5행
③ A: 3행, B: 3행
④ A: 2행, B: 5행

**정답**: ①
**해설**: INNER JOIN — dept_id가 A, B에 매칭되는 직원만: 김철수(A), 이영희(B), 박민준(A) = 3행. LEFT JOIN — employees 기준 전체 5명: 최수연(NULL→NULL), 정태양(D→없으므로 NULL) 포함 = 5행.

---

### 유형 3: GROUP BY + HAVING

💡 **핵심 포인트**
- WHERE는 개별 행 필터링 (GROUP BY 전에 실행)
- HAVING은 그룹 결과 필터링 (GROUP BY 후에 실행)
- SELECT에는 GROUP BY 컬럼 또는 집계함수만 사용 가능

#### 기출 스타일 문제 3-1

```sql
SELECT dept, COUNT(*) AS cnt, AVG(salary) AS avg_sal
FROM employees
WHERE salary >= 2900
GROUP BY dept
HAVING COUNT(*) >= 2
ORDER BY avg_sal DESC;
```

**Q. 위 쿼리 실행 결과로 올바른 것은?** (앞선 employees 데이터 기준)

① A팀: 2명, 평균 3850 / B팀: 2명, 평균 3300
② A팀: 3명, 평균 3533 / B팀: 2명, 평균 3300
③ A팀: 2명, 평균 3850
④ 결과 없음

**정답**: ③
**해설**: salary >= 2900 조건 → 정태양(2900) 포함. A팀: 김철수(3500), 박민준(4200), 정태양(2900) = 3명. 하지만 WHERE salary >= 2900에서 정태양 포함 후 GROUP BY. A팀 3명, B팀 2명(이영희 2800 제외되어 한지민 1명만 → HAVING COUNT(*) >= 2 탈락). 따라서 A팀만 결과에 포함. AVG = (3500+4200+2900)/3 = 3533.

⚠️ **주의**: 위 문제에서 정태양의 salary=2900은 WHERE salary >= 2900에 포함됩니다. 경계값 처리에 주의하세요.

---

### 유형 4: DDL 문법

💡 **핵심 포인트**
- CREATE TABLE: 제약조건 위치와 문법
- ALTER TABLE: ADD / MODIFY / DROP / RENAME
- 제약조건 종류: PRIMARY KEY, NOT NULL, UNIQUE, DEFAULT, CHECK, FOREIGN KEY

#### 기출 스타일 문제 4-1

다음 중 올바른 SQL 문법은?

```sql
① CREATE TABLE orders (
       id INT,
       PRIMARY KEY id
   );

② CREATE TABLE orders (
       id INT PRIMARY KEY,
       amount INT NOT NULL DEFAULT = 0
   );

③ CREATE TABLE orders (
       id INT PRIMARY KEY AUTO_INCREMENT,
       amount INT NOT NULL DEFAULT 0
   );

④ CREATE TABLE orders (
       id INT PRIMARY KEY AUTO INCREMENT,
       amount INT NOT NULL DEFAULT 0
   );
```

**정답**: ③
**해설**:
- ①: `PRIMARY KEY(id)` 또는 컬럼 정의 시 `id INT PRIMARY KEY`가 올바른 문법
- ②: DEFAULT 뒤에 `=` 기호 불필요. `DEFAULT 0`이 올바른 문법
- ③: 올바른 문법
- ④: `AUTO INCREMENT` → `AUTO_INCREMENT` (밑줄 필요)

---

#### 기출 스타일 문제 4-2

```sql
-- 다음 중 customers 테이블에 email 컬럼(VARCHAR 100, NOT NULL)을 추가하는 올바른 문법은?
① ALTER TABLE customers INSERT COLUMN email VARCHAR(100) NOT NULL;
② ALTER TABLE customers ADD email VARCHAR(100) NOT NULL;
③ ALTER TABLE customers ADD COLUMN email VARCHAR(100) NOT NULL;
④ 위 ②와 ③ 모두 올바르다.
```

**정답**: ④
**해설**: MySQL에서 `ADD`와 `ADD COLUMN` 모두 올바른 문법입니다. COLUMN 키워드는 선택사항(optional)입니다.

---

### 유형 5: 트랜잭션

💡 **핵심 포인트**
- COMMIT 전 변경사항은 현재 세션에서만 보임
- ROLLBACK은 마지막 COMMIT 이후의 모든 변경을 취소
- SAVEPOINT는 특정 지점까지만 롤백 가능
- DDL(CREATE, DROP 등)은 자동 COMMIT (묵시적 커밋)

#### SAVEPOINT 전/후 데이터 상태 추적 예시

```
초기 상태: orders 테이블에 id=10, status='주문완료'

START TRANSACTION;
    → [상태: 주문완료]

UPDATE orders SET status='조리중' WHERE id=10;
    → [트랜잭션 내 상태: 조리중 (미확정)]

SAVEPOINT sp1;
    → [저장점 sp1 설정: 조리중]

UPDATE orders SET status='배달중' WHERE id=10;
    → [트랜잭션 내 상태: 배달중 (미확정)]

ROLLBACK TO SAVEPOINT sp1;
    → [상태: 조리중으로 복구 (sp1 시점)]

COMMIT;
    → [최종 확정 상태: 조리중]
```

#### 기출 스타일 문제 5-1

다음 트랜잭션 실행 후 balance의 최종값은?

```sql
-- 초기값: balance = 1000

START TRANSACTION;
UPDATE account SET balance = balance - 300;   -- (1)
SAVEPOINT sp1;
UPDATE account SET balance = balance + 500;   -- (2)
ROLLBACK TO SAVEPOINT sp1;                    -- (3)
UPDATE account SET balance = balance - 100;   -- (4)
COMMIT;                                       -- (5)
```

① 1100
② 700
③ 600
④ 1000

**정답**: ③
**해설**:
- 초기: 1000
- (1) 실행 후: 700
- SAVEPOINT sp1 (700 상태로 저장)
- (2) 실행 후: 1200
- (3) sp1로 롤백 → 700으로 복구
- (4) 실행 후: 600
- (5) COMMIT → 최종값 600

---

#### 기출 스타일 문제 5-2

다음 중 트랜잭션에 대한 설명으로 **틀린** 것은?

① COMMIT을 실행하면 트랜잭션 내의 변경사항이 데이터베이스에 영구 반영된다.
② ROLLBACK은 가장 최근 SAVEPOINT 이후의 변경사항만 취소한다.
③ MySQL에서 AUTO_COMMIT이 ON이면 각 SQL 문이 자동으로 COMMIT된다.
④ DDL 문(CREATE, DROP 등)을 실행하면 묵시적 COMMIT이 발생한다.

**정답**: ②
**해설**: SAVEPOINT 없이 ROLLBACK을 실행하면 마지막 COMMIT 이후의 **모든** 변경사항이 취소됩니다. SAVEPOINT를 명시해야 해당 지점까지만 롤백됩니다. (`ROLLBACK TO SAVEPOINT sp1`처럼 사용해야 특정 지점으로 롤백)

---

## 5. 10일 전체 SQL 치트시트

### Day 1~2: DDL (데이터 정의어)

```sql
-- 데이터베이스
CREATE DATABASE hanip_db;
USE hanip_db;
SHOW DATABASES;
DROP DATABASE hanip_db;

-- 테이블 생성
CREATE TABLE 테이블명 (
    컬럼명 데이터타입 [제약조건],
    ...
    [테이블 제약조건]
);

-- 주요 데이터 타입
-- INT / BIGINT          정수
-- DECIMAL(p,s)          소수 (p: 전체자리, s: 소수자리)
-- VARCHAR(n)            가변 문자열 (최대 n글자)
-- CHAR(n)               고정 문자열
-- TEXT                  긴 텍스트
-- DATE / DATETIME       날짜 / 날짜+시간
-- TINYINT               0~255 또는 -128~127

-- 주요 제약조건
-- PRIMARY KEY           기본키 (유일 + NOT NULL)
-- AUTO_INCREMENT        자동 증가
-- NOT NULL              NULL 불허
-- UNIQUE                중복 불허
-- DEFAULT 값            기본값 설정
-- CHECK (조건)          값 범위 검사
-- FOREIGN KEY           외래키

-- 테이블 수정
ALTER TABLE 테이블명 ADD    컬럼명 데이터타입;
ALTER TABLE 테이블명 MODIFY 컬럼명 새데이터타입;
ALTER TABLE 테이블명 DROP   COLUMN 컬럼명;
ALTER TABLE 테이블명 RENAME TO 새테이블명;

-- 테이블 삭제
DROP TABLE 테이블명;
TRUNCATE TABLE 테이블명;  -- 데이터만 전체 삭제 (구조 유지)

-- 구조 확인
DESC 테이블명;
SHOW TABLES;
```

---

### Day 3: DML (데이터 조작어)

```sql
-- INSERT
INSERT INTO 테이블명 (컬럼1, 컬럼2) VALUES (값1, 값2);
INSERT INTO 테이블명 VALUES (값1, 값2, ...);  -- 모든 컬럼 순서대로
INSERT INTO 테이블명 (컬럼1, 컬럼2)
VALUES (값1, 값2), (값3, 값4);               -- 다중 삽입

-- SELECT
SELECT * FROM 테이블명;
SELECT 컬럼1, 컬럼2 FROM 테이블명;
SELECT 컬럼 AS 별칭 FROM 테이블명;

-- WHERE 조건
WHERE 컬럼 = 값
WHERE 컬럼 != 값
WHERE 컬럼 > 값 AND 컬럼 < 값
WHERE 컬럼 BETWEEN 값1 AND 값2
WHERE 컬럼 IN (값1, 값2, 값3)
WHERE 컬럼 LIKE '패턴%'           -- 시작 일치
WHERE 컬럼 LIKE '%패턴%'          -- 포함
WHERE 컬럼 IS NULL
WHERE 컬럼 IS NOT NULL

-- 정렬 & 제한
ORDER BY 컬럼 ASC                  -- 오름차순 (기본)
ORDER BY 컬럼 DESC                 -- 내림차순
LIMIT 10                           -- 상위 10건
LIMIT 10 OFFSET 20                 -- 21번째부터 10건 (페이징)

-- UPDATE (⚠️ WHERE 없으면 전체!)
UPDATE 테이블명 SET 컬럼 = 값 WHERE 조건;

-- DELETE (⚠️ WHERE 없으면 전체!)
DELETE FROM 테이블명 WHERE 조건;
```

---

### Day 4: 내장 함수

```sql
-- 문자열 함수
CONCAT('a', 'b', 'c')             -- 문자열 연결
SUBSTRING(str, 시작, 길이)         -- 부분 문자열
LENGTH('Hello')                    -- 바이트 수
CHAR_LENGTH('안녕')                -- 문자 수 (한글 유의)
TRIM('  공백  ')                   -- 앞뒤 공백 제거
REPLACE(str, '찾기', '바꾸기')
LPAD('5', 3, '0')                 -- '005'
UPPER('hello') / LOWER('HELLO')

-- 숫자 함수
ROUND(3.567, 2)                   -- 3.57 (반올림)
CEIL(3.1)                         -- 4  (올림)
FLOOR(3.9)                        -- 3  (버림)
MOD(10, 3)                        -- 1  (나머지)
ABS(-5)                           -- 5  (절댓값)

-- 날짜 함수
NOW()                             -- 현재 날짜+시간
CURDATE()                         -- 현재 날짜
DATE_FORMAT(날짜, '%Y-%m-%d')     -- 날짜 포맷
DATEDIFF('2026-12-31', NOW())     -- D-day 계산
DATE_ADD(NOW(), INTERVAL 7 DAY)   -- 7일 후

-- 조건 함수
IFNULL(컬럼, 'N/A')               -- NULL이면 'N/A'
IF(조건, 참값, 거짓값)
CASE WHEN 조건1 THEN 값1
     WHEN 조건2 THEN 값2
     ELSE 기본값
END
```

---

### Day 5: 집계 & GROUP BY

```sql
-- 집계 함수
COUNT(*)                          -- 전체 행 수 (NULL 포함)
COUNT(컬럼)                       -- NULL 제외 행 수
SUM(컬럼)                         -- 합계
AVG(컬럼)                         -- 평균 (NULL 제외)
MAX(컬럼)                         -- 최댓값
MIN(컬럼)                         -- 최솟값

-- GROUP BY
SELECT 컬럼, 집계함수
FROM 테이블명
WHERE 행_필터_조건
GROUP BY 컬럼
HAVING 그룹_필터_조건
ORDER BY 정렬기준
LIMIT 제한수;

-- SELECT 실행 순서 (암기!)
-- FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

---

### Day 6: JOIN

```sql
-- INNER JOIN (교집합 — 양쪽 모두 있는 것만)
SELECT *
FROM 테이블A a
INNER JOIN 테이블B b ON a.id = b.a_id;

-- LEFT JOIN (왼쪽 기준 — 오른쪽 없으면 NULL)
SELECT *
FROM 테이블A a
LEFT JOIN 테이블B b ON a.id = b.a_id;

-- LEFT JOIN IS NULL (왼쪽에만 있는 것 = B와 매칭 없는 A)
SELECT * FROM 테이블A a
LEFT JOIN 테이블B b ON a.id = b.a_id
WHERE b.id IS NULL;

-- RIGHT JOIN (오른쪽 기준)
SELECT * FROM 테이블A a
RIGHT JOIN 테이블B b ON a.id = b.a_id;

-- 3개 테이블 JOIN
SELECT *
FROM orders o
JOIN customers c    ON o.customer_id = c.id
JOIN restaurants r  ON o.restaurant_id = r.id;
```

---

### Day 7: 서브쿼리

```sql
-- WHERE절 서브쿼리 (단일행)
SELECT * FROM menus
WHERE price > (SELECT AVG(price) FROM menus);

-- WHERE절 서브쿼리 (다중행) — IN 사용
SELECT * FROM orders
WHERE restaurant_id IN (
    SELECT id FROM restaurants WHERE category = '한식'
);

-- FROM절 서브쿼리 (인라인 뷰) — 반드시 별칭 필요!
SELECT * FROM (
    SELECT restaurant_id, COUNT(*) AS cnt
    FROM orders
    GROUP BY restaurant_id
) AS order_count
WHERE cnt >= 5;

-- SELECT절 스칼라 서브쿼리 (반드시 1행 1열 반환)
SELECT name,
       (SELECT COUNT(*) FROM orders WHERE customer_id = c.id) AS 주문수
FROM customers c;

-- EXISTS / NOT EXISTS
SELECT * FROM restaurants r
WHERE EXISTS (
    SELECT 1 FROM orders WHERE restaurant_id = r.id
);

-- UNION (중복 제거) / UNION ALL (중복 포함)
SELECT name FROM customers
UNION
SELECT name FROM riders;
```

---

### Day 8: 인덱스, 뷰, 트랜잭션

```sql
-- 인덱스
CREATE INDEX 인덱스명 ON 테이블(컬럼);
CREATE UNIQUE INDEX 인덱스명 ON 테이블(컬럼);
SHOW INDEX FROM 테이블명;
DROP INDEX 인덱스명 ON 테이블명;
EXPLAIN SELECT ...;               -- 실행 계획 확인

-- 뷰
CREATE VIEW 뷰이름 AS SELECT ...;
SELECT * FROM 뷰이름;
DROP VIEW IF EXISTS 뷰이름;

-- 트랜잭션
START TRANSACTION;
-- SQL 작업들...
SAVEPOINT 저장점명;
-- 더 많은 작업들...
ROLLBACK TO SAVEPOINT 저장점명;  -- 특정 지점으로 롤백
ROLLBACK;                         -- 전체 롤백
COMMIT;                           -- 최종 확정
```

---

### Day 9: ERD, FK, 정규화

```sql
-- FOREIGN KEY 추가 (테이블 생성 시)
CREATE TABLE menus (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    restaurant_id   INT NOT NULL,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- FK ON DELETE 옵션
-- CASCADE   : 부모 삭제 시 자식도 자동 삭제
-- SET NULL  : 부모 삭제 시 자식 FK = NULL
-- RESTRICT  : 자식이 있으면 부모 삭제 불가 (기본)
-- NO ACTION : RESTRICT와 동일

-- 기존 테이블에 FK 추가
ALTER TABLE menus
ADD CONSTRAINT fk_menu_restaurant
FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);

-- FK 삭제
ALTER TABLE menus DROP FOREIGN KEY fk_menu_restaurant;
```

---

### Day 10: DCL (데이터 제어어)

```sql
-- 사용자 생성
CREATE USER '사용자'@'호스트' IDENTIFIED BY '비밀번호';

-- 권한 부여
GRANT 권한 ON DB명.테이블 TO '사용자'@'호스트';
FLUSH PRIVILEGES;

-- 권한 확인
SHOW GRANTS FOR '사용자'@'호스트';

-- 권한 회수
REVOKE 권한 ON DB명.테이블 FROM '사용자'@'호스트';

-- 사용자 삭제
DROP USER IF EXISTS '사용자'@'호스트';
```

---

## 6. 이후 학습 로드맵

### 현재 여러분의 수준

```
✅ CREATE / ALTER / DROP 테이블 설계
✅ INSERT / SELECT / UPDATE / DELETE
✅ WHERE, ORDER BY, LIMIT, GROUP BY, HAVING
✅ 내장 함수 (문자열/숫자/날짜/조건)
✅ INNER JOIN / LEFT JOIN / RIGHT JOIN
✅ 서브쿼리 (WHERE/FROM/SELECT)
✅ 인덱스, 뷰, 트랜잭션
✅ ERD 설계, FK, 정규화
✅ 사용자 관리, 백업
```

이 수준이면 **웹 서비스 DB 기초 설계 및 운영**이 가능합니다!

---

### 경로 1: 백엔드 개발자가 되고 싶다면

```
MySQL 10일 완성 (완료!)
        ↓
Java 기초 → Spring Boot → JPA/Hibernate
또는
Python 기초 → Django 또는 Flask → SQLAlchemy
        ↓
REST API 설계 → 인증(JWT) → 배포(AWS/GCP)
```

| 기술 | 역할 | 학습 시간 |
|------|------|-----------|
| Spring Boot + JPA | Java 백엔드 프레임워크 | 3~4개월 |
| Django + ORM | Python 풀스택 프레임워크 | 2~3개월 |
| Flask + SQLAlchemy | Python 경량 백엔드 | 1~2개월 |

> 💡 **JPA/ORM**: SQL을 직접 쓰지 않고 객체(Class)로 DB 조작. 하지만 복잡한 쿼리는 결국 SQL로 돌아옵니다. SQL 기초가 탄탄해야 합니다.

---

### 경로 2: 데이터 분석가가 되고 싶다면

```
MySQL 10일 완성 (완료!)
        ↓
Python 기초 → pandas/numpy → 데이터 시각화
        ↓
통계 기초 → 머신러닝 입문 (scikit-learn)
        ↓
BI 도구: Tableau / Power BI / Looker
```

| 기술 | 역할 | 학습 시간 |
|------|------|-----------|
| pandas | 데이터 처리/분석 | 1~2개월 |
| matplotlib/seaborn | 데이터 시각화 | 2~4주 |
| Tableau | BI 대시보드 | 1개월 |
| Power BI | Microsoft BI 도구 | 1개월 |

> 💡 **SQL + Python pandas** 조합이 현업에서 가장 많이 쓰이는 조합입니다.

---

### 경로 3: DBA(데이터베이스 관리자)가 되고 싶다면

```
MySQL 10일 완성 (완료!)
        ↓
MySQL 고급: 쿼리 최적화, 실행 계획 심화
        ↓
복제(Replication) / 파티셔닝 / 샤딩
        ↓
고가용성: InnoDB Cluster / ProxySQL
        ↓
모니터링: Percona Monitoring / Grafana
```

| 기술 | 역할 |
|------|------|
| MySQL 복제 | 읽기 부하 분산, 장애 복구 |
| 파티셔닝 | 대용량 테이블 성능 관리 |
| Performance Schema | 쿼리 성능 분석 도구 |
| Binary Log | 증분 백업, 포인트인타임 복구 |

---

### 경로 4: 자격증 취득

| 자격증 | 주관 | 난이도 | 취득 후 활용 |
|--------|------|--------|-------------|
| **정보처리기사** | 한국산업인력공단 | ⭐⭐⭐ | 취업, 대기업 필수 |
| **SQLD** | 한국데이터산업진흥원 | ⭐⭐ | SQL 전문성 증명 |
| **SQLP** | 한국데이터산업진흥원 | ⭐⭐⭐⭐ | 고급 DBA, 컨설턴트 |
| **OCP(MySQL)** | Oracle | ⭐⭐⭐⭐ | MySQL 전문가 국제 자격 |

> ⭐ **추천 순서**: 정보처리기사(필기 준비 중이라면) → SQLD → SQLP

---

### 추천 학습 자료

#### 공식 문서
- **MySQL 8.0 공식 문서**: https://dev.mysql.com/doc/refman/8.0/en/
- **SQL Tutorial (W3Schools)**: https://www.w3schools.com/sql/

#### 온라인 강의 플랫폼
- **인프런**: 한국어 강의 다수, MySQL/SQL 초중급 강의 추천
- **유데미(Udemy)**: "The Complete MySQL Bootcamp" (영문) — 세일 시 1~2만원
- **유튜브**: "얄팍한 코딩사전" SQL 시리즈 — 무료, 한국어, 초보자 친화

#### 실습 사이트
- **HackerRank SQL**: 레벨별 SQL 문제 풀기 (영문)
- **프로그래머스 SQL 고득점 Kit**: 한국어, 코딩 테스트 대비
- **LeetCode Database**: 코딩 인터뷰 SQL 문제 (영문)

---

> 💡 **마지막 조언**
>
> SQL은 **"쓰면 늘고, 안 쓰면 잊는다"**는 특성이 있습니다.
> 오늘 만든 프로젝트를 포트폴리오로 GitHub에 올려두고,
> 매주 프로그래머스 SQL 문제 2~3개씩 풀어가는 것이 가장 확실한 실력 유지 방법입니다.
>
> 10일 동안 함께해서 감사했습니다! 🎉

---

*한국IT교육센터 부산점 | MySQL 10일 완성 | Day 10*
*강사: ___________________*
