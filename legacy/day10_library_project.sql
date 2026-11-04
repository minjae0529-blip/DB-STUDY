-- ============================================================
-- 📚 library_db — 도서관 DB 라이브 코딩 (90분)
-- Day 10 | MySQL 10일 완성 | 한국IT교육센터 부산점
-- ============================================================
-- [시간 가이드]
--   STEP 1 : DB 생성 + ERD 설명        [0:10~0:25]  15분
--   STEP 2 : CREATE TABLE              [0:25~0:45]  20분
--   STEP 3 : INSERT 데이터              [0:45~1:00]  15분
--   STEP 4 : SELECT 쿼리 (집계 + JOIN)  [1:00~1:20]  20분
--   STEP 5 : 서브쿼리 + VIEW + INDEX    [1:20~1:35]  15분
--   STEP 6 : DCL — 사서 계정 만들기     [1:35~1:40]   5분
-- ============================================================


-- ============================================================
-- STEP 1 : DB 생성  [0:10~0:25, 15분]
-- 📌 강사 포인트
--    화이트보드에 ERD 먼저 그리고 시작!
--
--    authors  1:N  books  N:1  categories
--    members  1:N  rentals     N:1  books
--    members  1:N  reservations N:1 books
-- ============================================================

DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE library_db;


-- ============================================================
-- STEP 2 : CREATE TABLE  [0:25~0:45, 20분]
-- 📌 강사 포인트
--    "FK를 가진 테이블은 반드시 참조 대상보다 나중에 만든다!"
--    순서: authors → categories → books → members
--          → rentals → reservations
-- ============================================================

-- 2-1. authors (부모) ─────────────────────────────────────────
CREATE TABLE authors (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(50) NOT NULL,
    nationality VARCHAR(30) DEFAULT '한국',
    birth_year  INT
);

-- 2-2. categories (부모) ──────────────────────────────────────
CREATE TABLE categories (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(100)
);

-- 2-3. books (자식 → authors, categories) ─────────────────────
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

-- 2-4. members (독립) ─────────────────────────────────────────
CREATE TABLE members (
    id              INT         PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(30) NOT NULL,
    phone           VARCHAR(15) UNIQUE,
    email           VARCHAR(50) UNIQUE,
    joined_date     DATE        DEFAULT (CURDATE()),
    membership_type VARCHAR(10) DEFAULT '일반'  -- 일반 / 프리미엄
);

-- 2-5. rentals (자식 → books, members) ────────────────────────
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

-- 2-6. reservations (자식 → books, members) ───────────────────
CREATE TABLE reservations (
    id          INT         PRIMARY KEY AUTO_INCREMENT,
    book_id     INT         NOT NULL,
    member_id   INT         NOT NULL,
    reserved_at DATETIME    DEFAULT CURRENT_TIMESTAMP,
    status      VARCHAR(10) DEFAULT '대기중',    -- 대기중 / 확정 / 취소
    FOREIGN KEY (book_id)   REFERENCES books(id),
    FOREIGN KEY (member_id) REFERENCES members(id)
);

-- 구조 확인 ───────────────────────────────────────────────────
SHOW TABLES;
DESC books;
DESC rentals;


-- ============================================================
-- STEP 3 : INSERT 데이터  [0:45~1:00, 15분]
-- 📌 강사 포인트
--    "부모 테이블 데이터를 먼저 넣어야 FK 에러가 안 납니다!"
--    순서: authors → categories → books → members
--          → rentals → reservations
-- ============================================================

-- 3-1. authors (5건) ──────────────────────────────────────────
INSERT INTO authors (name, nationality, birth_year) VALUES
('김영하',        '한국',   1968),
('한강',          '한국',   1970),
('무라카미 하루키', '일본',  1949),
('조지 오웰',     '영국',   1903),
('생텍쥐페리',    '프랑스', 1900);

-- 3-2. categories (5건) ───────────────────────────────────────
INSERT INTO categories (name, description) VALUES
('소설',    '국내외 소설 작품'),
('에세이',  '개인 경험과 생각을 담은 글'),
('과학',    '과학 이론 및 교양 과학'),
('역사',    '역사적 사건과 인물'),
('자기계발', '성장과 동기부여 관련');

-- 3-3. books (10건) ───────────────────────────────────────────
INSERT INTO books (title, author_id, category_id, isbn, published_year, total_copies, available_copies) VALUES
('채식주의자',      2, 1, '9788936434120', 2007, 3, 2),
('알쏭달쏭 나의 삶', 1, 2, '9788954651234', 2019, 2, 1),
('노르웨이의 숲',   3, 1, '9788937460449', 1987, 4, 3),
('1984',           4, 1, '9788937460012', 1949, 3, 3),
('어린 왕자',      5, 1, '9788901000123', 1943, 5, 4),
('작별하지 않는다', 2, 1, '9788936434890', 2021, 2, 0),  -- 재고 0 → 예약 실습용
('호밀밭의 파수꾼', 1, 1, '9788937460555', 1951, 2, 2),
('코스모스',       NULL, 3, '9788983711680', 1980, 2, 2), -- 저자 NULL → LEFT JOIN 실습용
('총균쇠',         NULL, 4, '9791162540355', 1997, 3, 2),
('아주 작은 습관', NULL, 5, '9791162540365', 2019, 4, 4);

-- 3-4. members (8건 — 대출 없는 회원 2명 포함) ────────────────
INSERT INTO members (name, phone, email, joined_date, membership_type) VALUES
('김지수', '010-1111-2222', 'jisu@email.com',    '2025-01-10', '프리미엄'),
('이민준', '010-3333-4444', 'minjun@email.com',  '2025-02-15', '일반'),
('박서연', '010-5555-6666', 'seoyeon@email.com', '2025-03-20', '일반'),
('최준혁', '010-7777-8888', 'junhyeok@email.com','2025-04-05', '프리미엄'),
('정하은', '010-9999-0000', 'haeun@email.com',   '2025-06-01', '일반'),
('강도윤', '010-2222-3333', 'doyun@email.com',   '2025-08-10', '일반'),
('윤수아', '010-4444-5555', 'sua@email.com',     '2025-09-01', '일반'),   -- 대출 없음
('임태양', '010-6666-7777', 'taeyang@email.com', '2025-10-15', '일반');   -- 대출 없음

-- 3-5. rentals (15건 — 대출중 / 반납완료 / 연체 섞기) ──────────
INSERT INTO rentals (book_id, member_id, rented_at, due_date, returned_at, status) VALUES
(1,  1, '2026-02-01', '2026-02-15', '2026-02-14', '반납완료'),
(2,  1, '2026-03-01', '2026-03-15', '2026-03-20', '연체'),
(3,  2, '2026-03-10', '2026-03-24', '2026-03-23', '반납완료'),
(4,  2, '2026-04-01', '2026-04-15', NULL,          '대출중'),
(5,  3, '2026-04-05', '2026-04-19', '2026-04-18', '반납완료'),
(6,  3, '2026-04-10', '2026-04-24', NULL,          '대출중'),
(7,  4, '2026-04-15', '2026-04-29', NULL,          '대출중'),
(1,  4, '2026-04-20', '2026-05-04', '2026-05-03', '반납완료'),
(3,  5, '2026-05-01', '2026-05-15', NULL,          '대출중'),
(8,  5, '2026-05-02', '2026-05-16', NULL,          '대출중'),
(9,  1, '2026-05-03', '2026-05-17', NULL,          '대출중'),
(10, 2, '2026-05-04', '2026-05-18', NULL,          '대출중'),
(2,  3, '2026-05-05', '2026-05-19', NULL,          '대출중'),
(5,  4, '2026-03-15', '2026-03-29', '2026-04-05', '연체'),
(4,  5, '2026-04-25', '2026-05-09', '2026-05-08', '반납완료');

-- 3-6. reservations (5건) ─────────────────────────────────────
INSERT INTO reservations (book_id, member_id, reserved_at, status) VALUES
(6, 1, '2026-05-08 10:00:00', '대기중'),
(6, 2, '2026-05-08 11:00:00', '대기중'),
(4, 3, '2026-05-09 09:00:00', '대기중'),
(1, 5, '2026-05-10 14:00:00', '확정'),
(3, 6, '2026-05-10 15:00:00', '취소');

-- 데이터 확인 ─────────────────────────────────────────────────
SELECT COUNT(*) AS 도서수    FROM books;
SELECT COUNT(*) AS 회원수    FROM members;
SELECT COUNT(*) AS 대출수    FROM rentals;
SELECT COUNT(*) AS 예약수    FROM reservations;


-- ============================================================
-- STEP 4 : SELECT 쿼리  [1:00~1:20, 20분]
-- 📌 Day 3~6 총복습
-- ============================================================

-- [Day 3] Q1. 현재 대출 중인 도서 목록 ─────────────────────────
SELECT * FROM rentals
WHERE status = '대출중'
ORDER BY due_date;

-- [Day 4] Q2. 연체 중인 대출 — 오늘 기준 며칠 연체인지 ──────────
-- 📌 DATEDIFF, JOIN 동시에 복습
SELECT r.id            AS 대출번호,
       b.title         AS 도서명,
       m.name          AS 회원명,
       r.due_date      AS 반납기한,
       DATEDIFF(CURDATE(), r.due_date) AS 연체일수
FROM rentals r
JOIN books   b ON r.book_id   = b.id
JOIN members m ON r.member_id = m.id
WHERE r.status = '연체'
   OR (r.returned_at IS NULL AND r.due_date < CURDATE());

-- [Day 5] Q3. 장르별 도서 수 및 평균 발행연도 ───────────────────
SELECT c.name                          AS 장르,
       COUNT(b.id)                     AS 도서수,
       ROUND(AVG(b.published_year))    AS 평균발행연도
FROM categories c
LEFT JOIN books b ON c.id = b.category_id
GROUP BY c.id, c.name
ORDER BY 도서수 DESC;

-- [Day 5] Q4. 회원별 총 대출 횟수 — 3회 이상만 ──────────────────
SELECT m.name            AS 회원명,
       m.membership_type AS 등급,
       COUNT(r.id)       AS 대출횟수
FROM members m
LEFT JOIN rentals r ON m.id = r.member_id
GROUP BY m.id, m.name, m.membership_type
HAVING COUNT(r.id) >= 3
ORDER BY 대출횟수 DESC;

-- [Day 6] Q5. 전체 대출 내역 (도서명 + 저자 + 회원명 포함) ────────
SELECT r.id            AS 대출번호,
       b.title         AS 도서명,
       a.name          AS 저자,
       m.name          AS 회원명,
       r.rented_at     AS 대출일,
       r.due_date      AS 반납기한,
       r.status        AS 상태
FROM rentals r
JOIN books   b ON r.book_id   = b.id
LEFT JOIN authors a ON b.author_id = a.id   -- 저자 없는 책도 포함 (LEFT JOIN)
JOIN members m ON r.member_id = m.id
ORDER BY r.rented_at DESC;

-- [Day 6] Q6. 한 번도 대출하지 않은 회원 ──────────────────────────
-- 📌 LEFT JOIN IS NULL 패턴 복습
SELECT m.name        AS 미대출회원,
       m.phone,
       m.joined_date AS 가입일
FROM members m
LEFT JOIN rentals r ON m.id = r.member_id
WHERE r.id IS NULL;


-- ============================================================
-- STEP 5 : 서브쿼리 + VIEW + INDEX  [1:20~1:35, 15분]
-- 📌 Day 7~8 총복습
-- ============================================================

-- [Day 7] Q7. 평균 대출 횟수보다 많이 빌린 회원 ─────────────────
SELECT m.name      AS 회원명,
       COUNT(r.id) AS 대출횟수
FROM members m
JOIN rentals r ON m.id = r.member_id
GROUP BY m.id, m.name
HAVING COUNT(r.id) > (
    SELECT AVG(cnt)
    FROM (
        SELECT COUNT(*) AS cnt
        FROM rentals
        GROUP BY member_id
    ) AS avg_sub
)
ORDER BY 대출횟수 DESC;

-- [Day 7] Q8. 현재 대출 중이면서 예약도 걸려 있는 도서 ────────────
SELECT b.title           AS 도서명,
       b.available_copies AS 남은재고
FROM books b
WHERE b.id IN (SELECT book_id FROM rentals      WHERE status = '대출중')
  AND b.id IN (SELECT book_id FROM reservations WHERE status = '대기중');

-- [Day 8] VIEW — 대출 현황 한눈에 ─────────────────────────────
CREATE VIEW v_rental_status AS
SELECT r.id        AS 대출번호,
       b.title     AS 도서명,
       a.name      AS 저자,
       m.name      AS 회원명,
       r.rented_at AS 대출일,
       r.due_date  AS 반납기한,
       IFNULL(DATEDIFF(CURDATE(), r.due_date), 0) AS 연체일수,
       r.status    AS 상태
FROM rentals r
JOIN books   b ON r.book_id   = b.id
LEFT JOIN authors a ON b.author_id = a.id
JOIN members m ON r.member_id = m.id;

-- 뷰 활용
SELECT * FROM v_rental_status WHERE 상태 = '대출중';
SELECT * FROM v_rental_status WHERE 연체일수 > 0 ORDER BY 연체일수 DESC;

-- [Day 8] INDEX + EXPLAIN ─────────────────────────────────────
-- 인덱스 전
EXPLAIN SELECT * FROM rentals WHERE member_id = 1;

CREATE INDEX idx_rentals_member ON rentals(member_id);

-- 인덱스 후 — type: ALL → ref, rows 감소 확인
EXPLAIN SELECT * FROM rentals WHERE member_id = 1;


-- ============================================================
-- STEP 6 : DCL — 사서 계정 만들기  [1:35~1:40, 5분]
-- 📌 강사 포인트
--    "도서관 DB 완성! 이제 사서한테 딱 필요한 권한만 줘봅시다"
--    사서  : SELECT(전체) + INSERT/UPDATE(rentals, reservations)
--    관리자 : ALL PRIVILEGES
-- ============================================================

-- 사서 계정 생성 (대출/예약 관리만 가능)
CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'Lib2026!';
GRANT SELECT                       ON library_db.*              TO 'librarian'@'localhost';
GRANT INSERT, UPDATE               ON library_db.rentals        TO 'librarian'@'localhost';
GRANT INSERT, UPDATE               ON library_db.reservations   TO 'librarian'@'localhost';
FLUSH PRIVILEGES;

-- 관리자 계정 생성 (전체 권한)
CREATE USER 'lib_admin'@'localhost' IDENTIFIED BY 'Admin2026!';
GRANT ALL PRIVILEGES ON library_db.* TO 'lib_admin'@'localhost';
FLUSH PRIVILEGES;

-- 권한 확인
SHOW GRANTS FOR 'librarian'@'localhost';
SHOW GRANTS FOR 'lib_admin'@'localhost';

-- ============================================================
-- 🎉 완성! — library_db 최종 점검
-- ============================================================
SELECT '도서수'    AS 항목, COUNT(*) AS 건수 FROM books
UNION ALL
SELECT '회원수',            COUNT(*)        FROM members
UNION ALL
SELECT '대출수',            COUNT(*)        FROM rentals
UNION ALL
SELECT '예약수',            COUNT(*)        FROM reservations
UNION ALL
SELECT '현재대출중',        COUNT(*)        FROM rentals WHERE status = '대출중'
UNION ALL
SELECT '연체건수',          COUNT(*)        FROM rentals WHERE status = '연체';
