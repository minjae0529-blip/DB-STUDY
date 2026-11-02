-- =============================================================
--  Ch01 데이터베이스와 첫 만남 — 강사 시연 스크립트
--  전제: chapters/ch01-first-database/setup.sql 실행 완료 (hanip_delivery01)
--  사용법: 블록 하나에 커서를 두고 Ctrl+Enter
-- =============================================================


-- -------------------------------------------------------------
-- [1] 서버 확인
-- -------------------------------------------------------------
SELECT VERSION();
SHOW VARIABLES LIKE 'character_set_server';   -- utf8mb4 이면 정상


-- -------------------------------------------------------------
-- [2] 어떤 DB가 있나 → 선택
-- -------------------------------------------------------------
SHOW DATABASES;
SHOW DATABASES LIKE 'hanip_delivery%';   -- 수업 DB만 (Ch02부터 하나씩 늘어남)
USE hanip_delivery01;
SELECT DATABASE() AS current_db;


-- -------------------------------------------------------------
-- [3] 어떤 테이블이 있나
-- -------------------------------------------------------------
SHOW TABLES;


-- -------------------------------------------------------------
-- [4] 테이블은 어떻게 생겼나 — DESC
--     Field / Type / Null / Key / Default / Extra 를 하나씩 읽어 주기
-- -------------------------------------------------------------
DESC restaurants;
DESC menus;          -- restaurant_id 의 Key = MUL (외래키)
DESC orders;         -- rider_id 의 Null = YES  →  왜일까? (질문 던지기)


-- -------------------------------------------------------------
-- [5] 데이터는 어떤 모습인가 — SELECT … LIMIT
-- -------------------------------------------------------------
SELECT * FROM restaurants LIMIT 5;
SELECT name, category, district FROM restaurants LIMIT 5;

SELECT COUNT(*) FROM orders;         -- 563
SELECT COUNT(*) FROM order_items;    -- orders 보다 많은 이유? (문제 5 복선)


-- -------------------------------------------------------------
-- [6] 주문 7번 따라가기 — README 2절 그림을 데이터로 확인
--     (WHERE 는 Ch02 에서 배움. 지금은 "7번만 골라 본다" 정도로)
-- -------------------------------------------------------------
SELECT * FROM orders      WHERE order_id = 7;
SELECT * FROM order_items WHERE order_id = 7;
SELECT * FROM customers   WHERE customer_id = 1;
SELECT * FROM restaurants WHERE restaurant_id = 8;
SELECT * FROM menus       WHERE menu_id = 35;


-- -------------------------------------------------------------
-- [7] 구조 원문 — FOREIGN KEY 한 줄만 찾아보기
-- -------------------------------------------------------------
SHOW CREATE TABLE menus;


-- -------------------------------------------------------------
-- [8] 에러 읽기 — 일부러 틀리기
-- -------------------------------------------------------------
SELECT * FROM restaurant;                 -- 1146 Table doesn't exist
SELECT menu_name FROM menus;              -- 1054 Unknown column
SELECT name category, FROM restaurants;   -- 1064 syntax error near 'FROM …'
SELECT name price FROM menus LIMIT 3;     -- 에러 없음! 그런데 결과가 이상하다 (별칭)
