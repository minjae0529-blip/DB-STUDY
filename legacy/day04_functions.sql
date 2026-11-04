-- =============================================================
-- 한입배달 DB 수업 — Day 4: 데이터 가공의 기술 (내장 함수)
-- =============================================================

USE hanip_delivery;

-- =============================================================
-- PART 1. 문자열 함수 (String Functions)
-- =============================================================

-- ── 1-1. CONCAT: 문자열 합치기 ──────────────────────────────
-- 가게명과 카테고리를 합쳐서 "가게명 (카테고리)" 형태로 출력
SELECT
    name,
    category,
    CONCAT(name, ' (', category, ')') AS 가게정보
FROM restaurants;

-- ── 1-2. SUBSTRING: 문자열 일부 추출 ────────────────────────
-- 가게명의 앞 3글자만 추출 (SUBSTR도 동일)
SELECT
    name,
    SUBSTRING(name, 1, 3) AS 가게명앞3글자
FROM restaurants;

-- 메뉴명의 3번째 글자부터 끝까지 추출
SELECT
    menu_name,
    SUBSTRING(menu_name, 3) AS 3번째부터
FROM menus
LIMIT 5;

-- ── 1-3. LENGTH vs CHAR_LENGTH: 바이트 vs 글자 수 ───────────
-- ⚠️ 매우 중요! 한글은 UTF-8에서 한 글자 = 3바이트
-- LENGTH     : 바이트(byte) 수를 반환
-- CHAR_LENGTH: 실제 글자(character) 수를 반환

SELECT
    name,
    LENGTH(name)      AS 바이트수,   -- 한글 1글자 = 3바이트
    CHAR_LENGTH(name) AS 글자수       -- 한글 1글자 = 1글자
FROM restaurants;

-- 직접 확인해보기
SELECT
    '안녕'               AS 문자열,
    LENGTH('안녕')       AS LENGTH결과,       -- 6 (2글자 × 3바이트)
    CHAR_LENGTH('안녕')  AS CHAR_LENGTH결과;  -- 2

-- 실무 활용: 글자 수 기준 필터는 반드시 CHAR_LENGTH 사용
SELECT menu_name
FROM menus
WHERE CHAR_LENGTH(menu_name) >= 5;  -- 5글자 이상 메뉴

-- ── 1-4. TRIM / LTRIM / RTRIM: 공백 제거 ───────────────────
-- TRIM  : 양쪽 공백 제거
-- LTRIM : 왼쪽 공백 제거
-- RTRIM : 오른쪽 공백 제거
SELECT
    '  한입배달  '              AS 원본,
    TRIM('  한입배달  ')        AS TRIM결과,
    LTRIM('  한입배달  ')       AS LTRIM결과,
    RTRIM('  한입배달  ')       AS RTRIM결과;

-- 실무 활용: 사용자 입력값의 공백 제거
SELECT * FROM customers
WHERE TRIM(name) = '김민준';

-- ── 1-5. REPLACE: 문자열 치환 ───────────────────────────────
-- 주소에서 '부산' → '🌊부산' 으로 치환
SELECT
    name,
    address,
    REPLACE(address, '부산', '🌊부산') AS 주소이모지
FROM restaurants;

-- 메뉴명에서 특정 단어 제거 (빈 문자열로 치환)
SELECT
    menu_name,
    REPLACE(menu_name, '구이', '') AS 구이제거
FROM menus
WHERE menu_name LIKE '%구이%';

-- ── 1-6. LPAD / RPAD: 자릿수 채우기 ────────────────────────
-- LPAD: 왼쪽에 지정 문자를 채워 총 N자리로 만들기
-- 주문번호 포맷팅: 1 → '00001', 2 → '00002'
SELECT
    id,
    LPAD(id, 5, '0') AS 주문번호
FROM menus;

-- RPAD: 오른쪽 채우기
SELECT
    menu_name,
    RPAD(menu_name, 15, ' ') AS 메뉴명고정폭
FROM menus
LIMIT 5;

-- ── 1-7. UPPER / LOWER: 대소문자 변환 ──────────────────────
SELECT
    category,
    UPPER(category) AS 대문자,
    LOWER(category) AS 소문자
FROM restaurants;

-- 실무 활용: 대소문자 무관한 비교
SELECT * FROM restaurants
WHERE LOWER(category) = 'chicken';


-- =============================================================
-- PART 2. 숫자 함수 (Numeric Functions)
-- =============================================================

-- ── 2-1. ROUND: 반올림 ──────────────────────────────────────
-- ROUND(값, 소수점자리)
SELECT
    name,
    rating,
    ROUND(rating, 0) AS 별점반올림,   -- 소수점 0자리 = 정수
    ROUND(rating, 1) AS 소수1자리
FROM restaurants;

-- 가격을 100원 단위로 반올림
SELECT
    menu_name,
    price,
    ROUND(price, -2) AS 100원단위반올림  -- 음수 = 정수 자리
FROM menus;

-- ── 2-2. CEIL: 올림 ─────────────────────────────────────────
-- 가격을 천 원 단위로 올림
SELECT
    menu_name,
    price,
    CEIL(price / 1000) AS 천원단위올림,
    CEIL(price / 1000) * 1000 AS 올림가격
FROM menus;

-- ── 2-3. FLOOR: 내림 ────────────────────────────────────────
-- 가격을 천 원 단위로 내림
SELECT
    menu_name,
    price,
    FLOOR(price / 1000) AS 천원단위내림,
    FLOOR(price / 1000) * 1000 AS 내림가격
FROM menus;

-- ROUND / CEIL / FLOOR 비교 (값: 4500)
SELECT
    4500         AS 원래값,
    ROUND(4500 / 1000, 0) AS ROUND결과,   -- 5 (반올림)
    CEIL(4500 / 1000)     AS CEIL결과,    -- 5 (올림)
    FLOOR(4500 / 1000)    AS FLOOR결과;   -- 4 (내림)

-- ── 2-4. MOD: 나머지 ────────────────────────────────────────
-- MOD(피제수, 제수) 또는 % 연산자
SELECT
    menu_name,
    price,
    MOD(price, 1000) AS 천원미만금액,     -- 1000 미만 나머지
    price - MOD(price, 1000) AS 절사가격  -- 100원 이하 절사
FROM menus;

-- 짝수/홀수 구분
SELECT
    id,
    menu_name,
    MOD(id, 2) AS 홀짝,                   -- 0이면 짝수, 1이면 홀수
    IF(MOD(id, 2) = 0, '짝수', '홀수') AS 구분
FROM menus;

-- ── 2-5. ABS: 절댓값 ────────────────────────────────────────
SELECT ABS(-500) AS 절댓값_예시;  -- 500

-- 두 가격의 차이 (어느 쪽이 크든 양수로)
SELECT
    a.menu_name AS 메뉴A,
    b.menu_name AS 메뉴B,
    ABS(a.price - b.price) AS 가격차이
FROM menus a, menus b
WHERE a.id = 1 AND b.id = 2;

-- ── 2-6. TRUNCATE: 소수점 버림 ──────────────────────────────
-- TRUNCATE(값, 소수점자리) — 반올림 없이 그냥 자름
SELECT
    name,
    rating,
    TRUNCATE(rating, 0) AS 버림별점,   -- 4.8 → 4
    FLOOR(rating)       AS FLOOR비교   -- FLOOR와 동일 (양수일 때)
FROM restaurants;

-- 부가세 포함 가격에서 부가세 제거 (반올림 없이)
SELECT
    menu_name,
    price,
    TRUNCATE(price / 1.1, 0) AS 부가세제외가격
FROM menus;


-- =============================================================
-- PART 3. 날짜 함수 (Date Functions)
-- =============================================================

-- ── 3-1. NOW / CURDATE / CURTIME ────────────────────────────
SELECT
    NOW()     AS 현재날짜시간,    -- 2026-04-17 14:30:00
    CURDATE() AS 오늘날짜,        -- 2026-04-17
    CURTIME() AS 현재시간;        -- 14:30:00

-- ── 3-2. DATE_FORMAT: 날짜 형식 변환 ───────────────────────
-- 주요 포맷 코드: %Y(4자리연도), %y(2자리연도),
--                %m(월), %d(일), %H(24시), %h(12시), %i(분), %s(초)
SELECT
    name,
    joined_at,
    DATE_FORMAT(joined_at, '%Y년 %m월 %d일')     AS 한국형식,
    DATE_FORMAT(joined_at, '%Y-%m-%d')            AS ISO형식,
    DATE_FORMAT(joined_at, '%m/%d/%Y')            AS 미국형식,
    DATE_FORMAT(joined_at, '%Y년 %m월')           AS 연월만
FROM customers;

-- 현재 날짜 포맷
SELECT DATE_FORMAT(NOW(), '%Y년 %m월 %d일 %H시 %i분 %s초') AS 현재;

-- ── 3-3. DATEDIFF: 날짜 차이 ────────────────────────────────
-- DATEDIFF(기준날짜, 빼는날짜) = 날짜 차이 (일 단위)
SELECT
    name,
    joined_at,
    DATEDIFF(NOW(), joined_at) AS 가입후일수,
    FLOOR(DATEDIFF(NOW(), joined_at) / 30) AS 가입후개월수
FROM customers
ORDER BY 가입후일수 DESC;

-- ── 3-4. DATE_ADD / DATE_SUB: 날짜 더하기/빼기 ──────────────
-- INTERVAL 단위: DAY, WEEK, MONTH, YEAR, HOUR, MINUTE, SECOND
SELECT
    NOW()                               AS 현재,
    DATE_ADD(NOW(), INTERVAL 7 DAY)     AS 7일후,
    DATE_ADD(NOW(), INTERVAL 1 MONTH)   AS 1달후,
    DATE_ADD(NOW(), INTERVAL 1 YEAR)    AS 1년후,
    DATE_SUB(NOW(), INTERVAL 7 DAY)     AS 7일전,
    DATE_SUB(NOW(), INTERVAL 1 MONTH)   AS 1달전;

-- 실무 활용: 최근 30일 안에 가입한 고객
SELECT name, joined_at
FROM customers
WHERE joined_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY joined_at DESC;

-- 만료일 계산: 가입일로부터 1년 후 멤버십 만료
SELECT
    name,
    joined_at,
    DATE_ADD(joined_at, INTERVAL 1 YEAR) AS 멤버십만료일
FROM customers;

-- ── 3-5. YEAR / MONTH / DAY: 날짜 구성요소 추출 ─────────────
SELECT
    name,
    joined_at,
    YEAR(joined_at)  AS 가입연도,
    MONTH(joined_at) AS 가입월,
    DAY(joined_at)   AS 가입일
FROM customers;

-- 월별 가입 고객 수 (Day 5 복선)
SELECT
    MONTH(joined_at) AS 가입월,
    COUNT(*) AS 고객수
FROM customers
GROUP BY MONTH(joined_at)
ORDER BY 가입월;


-- =============================================================
-- PART 4. 조건 함수 (Conditional Functions)
-- =============================================================

-- ── 4-1. IFNULL: NULL이면 대체값 사용 ───────────────────────
-- IFNULL(값, NULL일때_대체값)
SELECT
    menu_name,
    menu_description,
    IFNULL(menu_description, '설명 없음') AS 설명
FROM menus;

-- ── 4-2. IF: 단순 조건 분기 ─────────────────────────────────
-- IF(조건, 참일때_값, 거짓일때_값) — 엑셀 IF 함수와 동일!
SELECT
    menu_name,
    price,
    IF(price >= 10000, '고가', '저가') AS 가격분류
FROM menus;

-- 별점 4.5 이상이면 '추천', 미만이면 '보통'
SELECT
    name,
    rating,
    IF(rating >= 4.5, '추천', '보통') AS 추천여부
FROM restaurants;

-- ── 4-3. CASE WHEN: 다중 조건 분기 ─────────────────────────
-- 엑셀의 중첩 IF와 동일 — CASE WHEN은 위에서 아래로 첫 번째 참인 조건 적용

-- 메뉴 가격대 분류
SELECT
    menu_name,
    price,
    CASE
        WHEN price >= 15000 THEN '고가'
        WHEN price >= 8000  THEN '중가'
        ELSE                     '저가'
    END AS 가격대
FROM menus
ORDER BY price DESC;

-- 별점 등급 분류
SELECT
    name,
    rating,
    CASE
        WHEN rating >= 4.5 THEN '⭐⭐⭐'
        WHEN rating >= 4.0 THEN '⭐⭐'
        ELSE                    '⭐'
    END AS 별점등급
FROM restaurants
ORDER BY rating DESC;

-- CASE WHEN + 특정 값 비교 (단순형)
SELECT
    menu_name,
    CASE category
        WHEN '한식' THEN '🍚 한식'
        WHEN '치킨' THEN '🍗 치킨'
        WHEN '피자' THEN '🍕 피자'
        ELSE              '기타'
    END AS 카테고리아이콘
FROM menus
JOIN restaurants ON menus.restaurant_id = restaurants.id
LIMIT 10;


-- =============================================================
-- PART 5. DISTINCT & AS
-- =============================================================

-- ── 5-1. DISTINCT: 중복 제거 ────────────────────────────────
-- 카테고리 목록 조회 (중복 없이)
SELECT DISTINCT category
FROM restaurants
ORDER BY category;

-- 고객이 주문한 적 있는 가게 ID 목록 (Day 5 연계)
-- SELECT DISTINCT restaurant_id FROM orders;

-- DISTINCT + COUNT
SELECT COUNT(DISTINCT category) AS 카테고리수
FROM restaurants;

-- ── 5-2. AS: 별칭 (Alias) ────────────────────────────────────
-- 컬럼 별칭
SELECT
    name       AS 가게이름,
    category   AS 카테고리,
    rating     AS 평점
FROM restaurants;

-- 계산식 별칭
SELECT
    menu_name               AS 메뉴명,
    price                   AS 원가,
    ROUND(price * 1.1, 0)   AS VAT포함가격
FROM menus;

-- 함수 결과 별칭
SELECT
    CONCAT(name, ' (', category, ')') AS 가게정보,
    LPAD(id, 5, '0')                  AS 가게번호,
    rating                            AS 평점
FROM restaurants;

-- 한글 별칭 (따옴표 없어도 되지만 한글·공백 포함 시 백틱 권장)
SELECT
    name AS `가게 이름`,
    CONCAT(name, ' - ', category) AS `가게 및 카테고리`
FROM restaurants;

-- ── 5-3. SELECT 최종 문법 구조 정리 ─────────────────────────
-- ============================================================
-- SELECT 함수(컬럼) AS 별칭   ← 가공 + 이름표
-- FROM   테이블               ← 어디서
-- WHERE  조건                 ← 개별 행 필터
-- ORDER BY 기준               ← 정렬
-- LIMIT  개수;                ← 몇 건만
-- ============================================================

-- 종합 예시: 10,000원 이상 메뉴를 가격 내림차순으로 5건, 가격대 분류 포함
SELECT
    menu_name                                             AS 메뉴명,
    price                                                 AS 가격,
    CONCAT(LPAD(id, 5, '0'))                              AS 메뉴번호,
    CASE
        WHEN price >= 15000 THEN '고가'
        WHEN price >= 8000  THEN '중가'
        ELSE                     '저가'
    END                                                   AS 가격대
FROM menus
WHERE price >= 10000
ORDER BY price DESC
LIMIT 5;

-- ===========================================================
-- =====================================================================
-- 한입배달 DB — Day 4 날짜 함수 실습용 스크립트
-- 테이블: members (회원)  |  데이터: 50건
-- 기준일: 2026-07-29 (데이터가 이 날짜 기준으로 설계됨)
-- =====================================================================

USE hanip_delivery;

DROP TABLE IF EXISTS members;

CREATE TABLE members (
    member_id     INT AUTO_INCREMENT PRIMARY KEY,   -- 회원번호
    name          VARCHAR(20)  NOT NULL,            -- 이름
    phone         VARCHAR(20),                      -- 연락처
    birth_date    DATE,                             -- 생년월일  → 나이 계산 실습
    join_date     DATE         NOT NULL,            -- 가입일    → DATEDIFF, 월별 집계
    last_order_at DATETIME,                         -- 최근 주문 일시 → NULL 처리, 휴면 판정
    coupon_expire DATE,                             -- 쿠폰 만료일 → DATE_ADD, 만료 임박
    grade         VARCHAR(10)  DEFAULT '일반',       -- 등급
    point         INT          DEFAULT 0            -- 포인트
);

-- ---------------------------------------------------------------------
-- 샘플 데이터 50건
-- 의도적으로 심어둔 패턴:
--   · last_order_at NULL 7건       → IFNULL / IS NULL 실습 (휴면회원)
--   · coupon_expire NULL 6건       → 쿠폰 미보유
--   · 만료 지난 쿠폰 다수           → CURDATE() 비교 실습
--   · 2월 29일 생일 3건            → 윤년 처리 주의
--   · 월말(1/31, 2/28, 3/31, 12/31) 가입 다수 → LAST_DAY 실습
--   · 가입일 2023 ~ 2026 분산       → YEAR/MONTH GROUP BY 실습
-- ---------------------------------------------------------------------

INSERT INTO members
(name, phone, birth_date, join_date, last_order_at, coupon_expire, grade, point) VALUES
('김민준','010-1234-0001','1988-03-15','2023-01-05','2026-07-20 19:32:11','2026-08-31','VIP',15200),
('이서연','010-1234-0002','1995-07-22','2023-01-19','2026-06-30 12:05:40','2026-07-15','골드',8300),
('박도윤','010-1234-0003','2001-11-03','2023-02-14',NULL,NULL,'일반',0),
('최지우','010-1234-0004','1992-02-29','2023-03-01','2025-12-24 20:11:03','2026-01-31','실버',2400),
('정하준','010-1234-0005','1979-05-30','2023-03-31','2026-07-25 08:47:29','2026-09-30','VIP',22100),
('강예은','010-1234-0006','1999-08-08','2023-05-20','2026-05-11 18:22:57','2026-06-30','골드',9100),
('조시우','010-1234-0007','1985-12-25','2023-06-11','2024-09-02 13:00:00',NULL,'일반',300),
('윤채원','010-1234-0008','2003-01-17','2023-07-04','2026-07-27 21:15:44','2026-08-15','실버',4700),
('장주원','010-1234-0009','1990-10-09','2023-09-23',NULL,'2025-12-31','일반',100),
('임수아','010-1234-0010','1997-04-05','2023-12-31','2026-03-18 11:09:30','2026-04-30','골드',7600),
('한지호','010-1234-0011','1983-06-18','2024-01-01','2026-07-28 09:03:12','2026-12-31','VIP',31000),
('오유진','010-1234-0012','2000-02-29','2024-01-15','2026-02-14 19:44:02','2026-03-31','실버',3300),
('서건우','010-1234-0013','1974-09-12','2024-02-29','2026-07-19 12:31:55','2026-08-31','골드',10500),
('신다은','010-1234-0014','2006-03-27','2024-03-08',NULL,NULL,'일반',0),
('권현우','010-1234-0015','1993-11-11','2024-04-16','2026-06-05 17:26:38','2026-07-05','실버',5200),
('황서윤','010-1234-0016','1987-01-23','2024-05-05','2026-07-12 20:58:19','2026-10-31','VIP',18400),
('안준서','010-1234-0017','2002-07-30','2024-06-21','2025-11-08 14:12:47','2025-12-15','일반',900),
('송하은','010-1234-0018','1996-12-01','2024-07-14','2026-07-26 13:40:05','2026-08-10','골드',12300),
('전지훈','010-1234-0019','1981-08-19','2024-08-31','2026-04-22 10:17:23',NULL,'실버',4100),
('홍민서','010-1234-0020','2005-05-14','2024-09-09','2026-07-05 22:03:51','2026-09-15','일반',1600),
('유재훈','010-1234-0021','1991-03-03','2024-10-25','2026-01-30 18:35:09','2026-02-28','골드',8800),
('문소율','010-1234-0022','1998-06-07','2024-11-30','2026-07-21 12:22:44','2026-08-20','실버',6000),
('배성민','010-1234-0023','1976-10-21','2024-12-24',NULL,'2026-01-15','일반',200),
('백지아','010-1234-0024','2004-02-29','2025-01-02','2026-06-18 19:50:33','2026-07-31','실버',5500),
('허준영','010-1234-0025','1989-09-28','2025-01-31','2026-07-24 11:11:11','2026-11-30','VIP',26700),
('남궁민','010-1234-0026','1994-04-12','2025-02-14','2026-05-30 16:44:20','2026-06-14','골드',9900),
('조은비','010-1234-0027','2007-07-07','2025-03-15','2026-07-18 20:30:00','2026-08-05','일반',1200),
('노태현','010-1234-0028','1980-11-25','2025-04-01','2025-10-12 09:25:41',NULL,'실버',3800),
('심유나','010-1234-0029','1999-01-08','2025-04-30','2026-07-23 18:09:16','2026-09-01','골드',11400),
('하정민','010-1234-0030','1986-08-16','2025-05-18',NULL,'2025-11-30','일반',500),
('곽민재','010-1234-0031','2001-12-19','2025-06-06','2026-07-27 12:55:37','2026-08-25','실버',7200),
('성지원','010-1234-0032','1972-02-02','2025-06-29','2026-03-09 15:18:52','2026-04-15','일반',1800),
('차은서','010-1234-0033','1995-10-31','2025-07-13','2026-07-11 21:47:04','2026-12-31','VIP',20300),
('주형준','010-1234-0034','2003-05-05','2025-08-15','2026-06-27 13:33:33','2026-07-27','골드',8100),
('라윤아','010-1234-0035','1990-07-24','2025-09-01','2026-02-05 10:02:18','2026-03-05','실버',4400),
('구본길','010-1234-0036','1984-03-09','2025-09-30','2026-07-22 19:21:09','2026-10-15','골드',13600),
('표지훈','010-1234-0037','2000-06-13','2025-10-19',NULL,NULL,'일반',0),
('마준혁','010-1234-0038','1997-09-26','2025-11-11','2026-07-14 17:05:26','2026-08-11','실버',6700),
('진서아','010-1234-0039','2006-12-08','2025-12-25','2026-05-19 14:29:47','2026-06-19','일반',2100),
('우현석','010-1234-0040','1978-04-17','2025-12-31','2026-07-28 08:12:03','2027-01-31','VIP',29500),
('방예린','010-1234-0041','2002-01-29','2026-01-10','2026-07-09 20:41:15','2026-08-09','골드',7900),
('석진우','010-1234-0042','1993-08-02','2026-01-31','2026-06-13 12:07:58','2026-07-13','실버',3600),
('탁영호','010-1234-0043','1988-05-21','2026-02-14','2026-07-26 18:53:22','2026-09-14','일반',2800),
('여민지','010-1234-0044','2005-10-04','2026-02-28',NULL,'2026-03-28','일반',0),
('도경민','010-1234-0045','1996-11-16','2026-03-08','2026-07-17 11:38:40','2026-08-08','실버',5000),
('육상현','010-1234-0046','1982-07-11','2026-03-31','2026-07-06 21:26:11','2026-09-30','골드',10200),
('감다혜','010-1234-0047','2004-09-23','2026-04-19','2026-07-25 13:49:35','2026-07-19','일반',1500),
('옥지환','010-1234-0048','1991-02-06','2026-05-05','2026-07-20 16:14:08','2026-08-05','실버',4300),
('천서진','010-1234-0049','1999-12-30','2026-06-15','2026-07-27 19:58:44','2026-09-15','골드',6400),
('태윤호','010-1234-0050','1975-01-13','2026-07-01','2026-07-28 10:20:57','2026-10-01','일반',800);

-- 확인
SELECT COUNT(*) AS 총회원수 FROM members;
SELECT * FROM members LIMIT 10;


-- =====================================================================
-- 실습 문제 (날짜 함수)  ※ 정답은 아래 주석 해제
-- =====================================================================
-- [기초 ⭐]
-- 1. 오늘 날짜와 현재 시각을 각각 출력하세요. (CURDATE, NOW)
-- 2. 회원 이름과 가입일을 '2026년 07월 29일' 형식으로 출력하세요. (DATE_FORMAT)
-- 3. 회원별로 가입한 지 며칠 됐는지 출력하세요. (DATEDIFF)
-- 4. 2026년에 가입한 회원만 조회하세요. (YEAR)
-- 5. 생일이 12월인 회원을 조회하세요. (MONTH)

-- [응용 ⭐⭐]
-- 6. 회원별 만 나이를 계산하세요. (TIMESTAMPDIFF)
-- 7. 쿠폰이 이미 만료된 회원을 조회하세요. (CURDATE 비교)
-- 8. 오늘부터 30일 이내에 쿠폰이 만료되는 회원을 조회하세요. (DATE_ADD)
-- 9. 최근 주문이 없는 회원(휴면)은 '주문내역 없음'으로 표시하세요. (IFNULL)
-- 10. 가입 연도·월별 가입자 수를 구하세요. (DATE_FORMAT + GROUP BY)

-- [도전 ⭐⭐⭐]
-- 11. 각 회원의 가입일이 무슨 요일이었는지 한글 요일로 출력하세요. (DAYOFWEEK + CASE)
-- 12. 마지막 주문 후 180일 이상 지난 회원을 '휴면', 아니면 '활성'으로 표시하세요.
-- 13. 회원별 가입 개월 수를 구하고, 12개월 이상이면 '충성고객'으로 표시하세요.
-- 14. 각 회원의 올해 생일이 지났는지 여부를 출력하세요.
-- 15. 가입일이 속한 달의 마지막 날짜를 구하세요. (LAST_DAY)


-- =====================================================================
-- 정답 예시
-- =====================================================================
/*
-- 3.
SELECT name, join_date, DATEDIFF(CURDATE(), join_date) AS 가입일수 FROM members;

-- 6.
SELECT name, birth_date, TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS 만나이 FROM members;

-- 8.
SELECT name, coupon_expire
FROM members
WHERE coupon_expire BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- 9.
SELECT name, IFNULL(DATE_FORMAT(last_order_at, '%Y-%m-%d %H:%i'), '주문내역 없음') AS 최근주문
FROM members;

-- 10.
SELECT DATE_FORMAT(join_date, '%Y-%m') AS 가입월, COUNT(*) AS 인원수
FROM members
GROUP BY 가입월
ORDER BY 가입월;

-- 11.
SELECT name, join_date,
       CASE DAYOFWEEK(join_date)
            WHEN 1 THEN '일' WHEN 2 THEN '월' WHEN 3 THEN '화' WHEN 4 THEN '수'
            WHEN 5 THEN '목' WHEN 6 THEN '금' ELSE '토' END AS 요일
FROM members;

-- 12.
SELECT name, last_order_at,
       CASE WHEN last_order_at IS NULL THEN '휴면(주문없음)'
            WHEN DATEDIFF(CURDATE(), last_order_at) >= 180 THEN '휴면'
            ELSE '활성' END AS 상태
FROM members;

-- 15.
SELECT name, join_date, LAST_DAY(join_date) AS 가입월_마지막날 FROM members;
*/


