# Ch12. 저장 프로시저와 함수

> **PART 4 · 서버 프로그래밍** | 3시간 | 난이도 ★★★
> 이전: [Ch11. 트리거](../ch11-trigger/README.md) | 다음: [종합 프로젝트 — 단골 리워드](../../project/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery12`**가 만들어집니다.

```sql
USE hanip_delivery12;
SELECT @@autocommit, @@sql_safe_updates, @@log_bin;   -- 1, 1, 1 (MySQL 8 기본값)
```

> 오늘도 `DELIMITER $$ … END $$ DELIMITER ;`(Ch11 2-2절)를 씁니다.

## 오늘의 요청

> **From.** 개발팀 한 팀장 · 정산팀 정 대리
>
> 1. **주문 접수**: Ch08의 주문 접수 트랜잭션을 웹, 안드로이드, iOS, 관리자 화면이 **각자 복사해서** 쓰고 있어요. 하나를 고치면 넷을 다 고쳐야 하고, 한 곳은 에러 후 ROLLBACK을 빼먹어서 빈 주문이 생겼습니다. DB에 **하나로 저장**해 두고 `CALL` 한 줄로 부르게 해 주세요. **실패하면 알아서 되돌리고, 왜 실패했는지 기록**도 남겨 주세요.
> 2. **등급 재산정**: 매달 1일, 최근 3개월 결제액으로 **전 고객의 등급을 다시 매깁니다**. 가입 한 달이 안 된 신규 고객은 건너뛰고요. 몇 명이 바뀌었는지도 알려 주세요.
> 3. **일별 매출표**: 가게별 일 매출을 뽑으면 **주문이 없는 날이 빠져서** 그래프가 이상해져요. 기간 안의 모든 날짜가 0원이라도 나와야 합니다.

변수 · 조건문 · 반복문 · 예외 처리 · 트랜잭션을 갖춘 **저장 프로시저(STORED PROCEDURE)**로 풉니다. 답은 [10절](#10-오늘의-요청-해결).

## 학습 목표

1. `CREATE PROCEDURE` · `CALL`로 프로시저를 만들고 실행한다.
2. 지역 변수(`DECLARE` · `SET` · `SELECT … INTO`)와 `IN` · `OUT` 파라미터를 쓴다.
3. **조건문**(`IF` · `CASE`)과 **반복문**(`WHILE` · `REPEAT` · `LOOP`, `LEAVE` · `ITERATE`)을 쓴다.
4. **커서**로 조회 결과를 한 행씩 처리한다.
5. **예외 처리**: `DECLARE … HANDLER`, `SIGNAL` · `RESIGNAL`, `GET DIAGNOSTICS`로 에러를 잡고, 다시 던지고, 기록한다.
6. 프로시저 안에서 **트랜잭션**을 열고, 실패하면 ROLLBACK하는 구조를 만든다.
7. 저장 함수를 만들고, 프로시저와의 차이와 `EXECUTE` 권한을 설명한다.

---

## 1. 프로시저란

**저장 프로시저**는 이름을 붙여 DB에 **저장해 둔 SQL 프로그램**입니다. 뷰(Ch10)가 SELECT 한 문장을 저장했다면, 프로시저는 여러 문장 · 조건 · 반복 · 트랜잭션까지 저장합니다.

| | 앱에 SQL을 직접 쓰기 | 저장 프로시저 |
|---|---|---|
| 로직 위치 | 앱마다 복사 | **DB에 한 벌** |
| 실행 | 문장마다 네트워크 왕복 | `CALL` 한 번 |
| 권한 | 테이블마다 INSERT · UPDATE 권한 필요 | **프로시저 실행 권한(`EXECUTE`)만** (9절) |
| 단점 | — | 버전 관리 · 디버깅이 어렵고, 특정 DBMS에 묶임 |

### 1-1. 첫 프로시저

가게 번호를 받아 그 가게의 요약을 보여 주는 프로시저입니다.

```sql
DELIMITER $$
CREATE PROCEDURE sp_restaurant_summary(IN p_restaurant_id INT)
BEGIN
    SELECT r.name, r.category, COUNT(o.order_id) AS delivered_orders,
        MAX(o.ordered_at) AS last_order
    FROM restaurants r
    LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id AND o.status = '배달완료'
    WHERE r.restaurant_id = p_restaurant_id
    GROUP BY r.restaurant_id, r.name, r.category;
END $$
DELIMITER ;

CALL sp_restaurant_summary(1);
```

<sub>▶ 실행 결과 · 1행</sub>

| name | category | delivered_orders | last_order |
|---|---|---|---|
| 서면옛날돼지국밥 | 한식 | 65 | 2026-06-27 18:55:37 |


| 부분 | 뜻 |
|---|---|
| `sp_restaurant_summary` | 이름 규칙: `sp_동사_대상` (stored procedure) |
| `IN p_restaurant_id INT` | 입력 파라미터. 이름 규칙 `p_` — 열 이름과 겹치지 않게 |
| `CALL 이름(값)` | 실행. 프로시저 안의 SELECT 결과가 그대로 돌려진다 |

## 2. 변수와 파라미터

### 2-1. 지역 변수 — DECLARE · SET · SELECT INTO

```sql
DECLARE v_total INT DEFAULT 0;                      -- 선언 (BEGIN 바로 뒤, 다른 문장보다 먼저)
SET v_total = v_total + 1000;                       -- 대입
SELECT COUNT(*) INTO v_total FROM orders WHERE …;   -- 조회 결과를 변수에 (반드시 1행)
```

| 종류 | 표기 | 범위 | 예 |
|---|---|---|---|
| **지역 변수** | `v_이름` (선언 필수) | `BEGIN … END` 안 | `DECLARE v_total INT;` |
| **파라미터** | `p_이름` | 프로시저 전체 | `IN p_customer_id INT` |
| **사용자(세션) 변수** | `@이름` (선언 없음) | 접속이 끊길 때까지 | `SET @order_id = 10;` (Ch08) |

### 2-2. OUT 파라미터 — 값을 돌려받기

결과를 표가 아니라 **값**으로 받고 싶을 때는 `OUT` 파라미터를 씁니다. 호출할 때 세션 변수(`@`)를 넘기면 그 안에 값이 담깁니다.

```sql
DELIMITER $$
CREATE PROCEDURE sp_customer_stats(
    IN  p_customer_id INT,
    OUT p_orders      INT,
    OUT p_total_paid  INT
)
BEGIN
    SELECT COUNT(*), COALESCE(SUM(t.amount), 0)
    INTO p_orders, p_total_paid
    FROM (
        SELECT o.order_id,
            SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS amount
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.customer_id = p_customer_id AND o.status = '배달완료'
        GROUP BY o.order_id
    ) t;
END $$
DELIMITER ;

CALL sp_customer_stats(1, @orders, @total);
SELECT @orders AS orders, @total AS total_paid;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders | total_paid |
|---|---|
| 47 | 1674500 |


| 모드 | 방향 | 용도 |
|---|---|---|
| `IN` (기본) | 호출 → 프로시저 | 입력값 |
| `OUT` | 프로시저 → 호출 | 결과값 (시작할 때 NULL) |
| `INOUT` | 양방향 | 값을 받아 고쳐서 돌려줌 |

> Java(JDBC)에서는 `CallableStatement`로 `{call sp_customer_stats(?, ?, ?)}`를 실행하고 `registerOutParameter`로 OUT 값을 받습니다. Spring 과정에서 다시 만납니다.

## 3. 조건문

### 3-1. IF · ELSEIF · ELSE — 등급 판정

최근 3개월 결제액으로 등급을 판정합니다. (기준: 60만 원 이상 VIP · 40만 원 이상 골드 · 20만 원 이상 실버 · 나머지 일반)

```sql
DELIMITER $$
CREATE PROCEDURE sp_check_grade(IN p_customer_id INT, IN p_base_date DATE)
BEGIN
    DECLARE v_spend INT DEFAULT 0;
    DECLARE v_grade VARCHAR(10);

    SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0)
         + COALESCE((SELECT SUM(delivery_fee - discount_amount) FROM orders
                     WHERE customer_id = p_customer_id AND status = '배달완료'
                       AND ordered_at >= p_base_date - INTERVAL 3 MONTH AND ordered_at < p_base_date), 0)
    INTO v_spend
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id AND o.status = '배달완료'
      AND o.ordered_at >= p_base_date - INTERVAL 3 MONTH AND o.ordered_at < p_base_date;

    IF v_spend >= 600000 THEN
        SET v_grade = 'VIP';
    ELSEIF v_spend >= 400000 THEN
        SET v_grade = '골드';
    ELSEIF v_spend >= 200000 THEN
        SET v_grade = '실버';
    ELSE
        SET v_grade = '일반';
    END IF;

    SELECT name, grade AS current_grade, v_spend AS spend_3m, v_grade AS new_grade
    FROM customers WHERE customer_id = p_customer_id;
END $$
DELIMITER ;

CALL sp_check_grade(5, '2026-07-01');
```

<sub>▶ 실행 결과 · 1행</sub>

| name | current_grade | spend_3m | new_grade |
|---|---|---|---|
| 정우진 | 골드 | 733500 | VIP |


> 위에서부터 차례로 검사하고 **처음 참인 곳에서 멈춥니다.** 그래서 큰 기준부터 씁니다. `ELSE IF`(띄어쓰기)가 아니라 `ELSEIF`, 끝은 `END IF;`.

### 3-2. CASE 문 — 쿠폰 할인액 계산

Ch03의 `CASE` **식**은 값 하나를 돌려주지만, 프로시저의 `CASE` **문**은 갈래마다 **여러 문장**을 실행합니다. 쿠폰 종류(정액 · 정률)에 따라 할인액을 계산합니다.

```sql
DELIMITER $$
CREATE PROCEDURE sp_calc_discount(
    IN  p_coupon_id   INT,
    IN  p_food_amount INT,
    OUT p_discount    INT
)
BEGIN
    DECLARE v_type  VARCHAR(10);
    DECLARE v_value INT;
    DECLARE v_max   INT;
    DECLARE v_min   INT;

    SELECT discount_type, discount_value, max_discount, min_order_amount
    INTO v_type, v_value, v_max, v_min
    FROM coupons WHERE coupon_id = p_coupon_id;

    IF p_food_amount < v_min THEN
        SET p_discount = 0;                                  -- 최소 주문 금액 미달
    ELSE
        CASE v_type
            WHEN '정액' THEN
                SET p_discount = LEAST(v_value, p_food_amount);
            WHEN '정률' THEN
                SET p_discount = FLOOR(p_food_amount * v_value / 100);
                IF v_max IS NOT NULL AND p_discount > v_max THEN
                    SET p_discount = v_max;                  -- 최대 할인액 제한
                END IF;
        END CASE;
    END IF;
END $$
DELIMITER ;

CALL sp_calc_discount(2, 40000, @d1);   -- 주말 15%, 최대 5,000원
CALL sp_calc_discount(2, 25000, @d2);
CALL sp_calc_discount(2, 18000, @d3);   -- 최소 주문 20,000원 미달
CALL sp_calc_discount(3, 30000, @d4);   -- VIP 정액 5,000원
SELECT @d1 AS weekend_40000, @d2 AS weekend_25000, @d3 AS weekend_18000, @d4 AS vip_30000;
```

<sub>▶ 실행 결과 · 1행</sub>

| weekend_40000 | weekend_25000 | weekend_18000 | vip_30000 |
|---|---|---|---|
| 5000 | 3750 | 0 | 5000 |


40,000원의 15%는 6,000원이지만 최대 5,000원에서 잘렸습니다. 이 계산을 앱 네 곳에 따로 두면, 언젠가 한 곳은 최대 할인액을 빼먹습니다.

## 4. 반복문

| 반복문 | 형태 | 특징 |
|---|---|---|
| `WHILE 조건 DO … END WHILE;` | 조건을 **먼저** 검사 | 0번 실행될 수 있음 |
| `REPEAT … UNTIL 조건 END REPEAT;` | 조건을 **나중에** 검사 | 최소 1번 실행 |
| `이름: LOOP … END LOOP 이름;` | 조건 없음 | `LEAVE 이름`으로 빠져나감, `ITERATE 이름`으로 다음 회차 |

### 4-1. WHILE — 빈 날짜까지 채운 일별 매출표

세 번째 요청입니다. GROUP BY로는 주문이 있는 날만 나옵니다.

```sql
SELECT DATE(ordered_at) AS sales_date, COUNT(*) AS orders
FROM orders
WHERE restaurant_id = 7 AND status = '배달완료'
  AND ordered_at >= '2026-06-21' AND ordered_at < '2026-07-01'
GROUP BY DATE(ordered_at);
```

<sub>▶ 실행 결과 · 2행</sub>

| sales_date | orders |
|---|---|
| 2026-06-21 | 1 |
| 2026-06-28 | 1 |


열흘 중 이틀만 나옵니다. 날짜를 하루씩 늘려 가며 **모든 날짜**를 채웁니다.

```sql
CREATE TABLE daily_sales_report (
    restaurant_id INT  NOT NULL,
    sales_date    DATE NOT NULL,
    orders        INT  NOT NULL,
    food_sales    INT  NOT NULL,
    CONSTRAINT pk_daily_sales_report PRIMARY KEY (restaurant_id, sales_date)
);

DELIMITER $$
CREATE PROCEDURE sp_daily_sales(IN p_restaurant_id INT, IN p_from DATE, IN p_to DATE)
BEGIN
    DECLARE v_day DATE DEFAULT p_from;

    DELETE FROM daily_sales_report
    WHERE restaurant_id = p_restaurant_id AND sales_date BETWEEN p_from AND p_to;

    WHILE v_day <= p_to DO
        INSERT INTO daily_sales_report (restaurant_id, sales_date, orders, food_sales)
        SELECT p_restaurant_id, v_day, COUNT(DISTINCT o.order_id),
            COALESCE(SUM(oi.quantity * oi.unit_price), 0)
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.restaurant_id = p_restaurant_id AND o.status = '배달완료'
          AND o.ordered_at >= v_day AND o.ordered_at < v_day + INTERVAL 1 DAY;

        SET v_day = v_day + INTERVAL 1 DAY;
    END WHILE;

    SELECT sales_date, orders, food_sales FROM daily_sales_report
    WHERE restaurant_id = p_restaurant_id AND sales_date BETWEEN p_from AND p_to
    ORDER BY sales_date;
END $$
DELIMITER ;

CALL sp_daily_sales(7, '2026-06-21', '2026-06-30');
```

<sub>▶ 실행 결과 · 10행</sub>

| sales_date | orders | food_sales |
|---|---|---|
| 2026-06-21 | 1 | 48000 |
| 2026-06-22 | 0 | 0 |
| 2026-06-23 | 0 | 0 |
| 2026-06-24 | 0 | 0 |
| 2026-06-25 | 0 | 0 |
| 2026-06-26 | 0 | 0 |
| 2026-06-27 | 0 | 0 |
| 2026-06-28 | 1 | 49000 |
| 2026-06-29 | 0 | 0 |
| 2026-06-30 | 0 | 0 |


열흘이 모두 나오고 주문 없는 날은 0입니다. 집계 함수는 대상 행이 없어도 **한 행**(COUNT 0, SUM NULL)을 돌려준다는 점(Ch04)을 이용했습니다. 처음에 같은 기간을 지우고 다시 넣으므로 **몇 번을 다시 실행해도** 결과가 같습니다.

> 반복은 꼭 필요할 때만. 이 문제는 Ch06의 재귀 CTE(`WITH RECURSIVE`)로 날짜 목록을 만들어 LEFT JOIN하는 **한 문장**으로도 풀 수 있고, 데이터가 크면 그쪽이 빠릅니다. 프로시저의 장점은 "기간을 받아 표를 갱신한다"는 **작업 단위**를 이름으로 저장한다는 데 있습니다.

### 4-2. REPEAT — 나눠서 지우기

운영 DB에서 수십만 행을 `DELETE` 한 번에 지우면 그동안 테이블이 잠겨 서비스가 멈춥니다. 그래서 **조금씩 나눠** 지웁니다. 지운 행이 0이 될 때까지 최소 한 번은 실행해야 하므로 `REPEAT`가 어울립니다. (실습용으로 주문 상세를 복사한 테이블에서 시험합니다.)

```sql
CREATE TABLE order_items_archive AS SELECT * FROM order_items;

DELIMITER $$
CREATE PROCEDURE sp_purge_archive(IN p_batch INT, OUT p_rounds INT)
BEGIN
    DECLARE v_deleted INT;
    SET p_rounds = 0;

    REPEAT
        DELETE FROM order_items_archive LIMIT p_batch;
        SET v_deleted = ROW_COUNT();          -- 바로 다음 문장에서 받아 둔다
        SET p_rounds = p_rounds + 1;
    UNTIL v_deleted = 0 END REPEAT;
END $$
DELIMITER ;

CALL sp_purge_archive(300, @rounds);
SELECT @rounds AS rounds, (SELECT COUNT(*) FROM order_items_archive) AS remaining;
```

<sub>▶ 실행 결과 · 1행</sub>

| rounds | remaining |
|---|---|
| 5 | 0 |


1,060행을 300행씩: 300 · 300 · 300 · 160 · 0 → 5회. `ROW_COUNT()`는 **직전 문장**의 영향받은 행 수라서, 다른 문장(`SET`)이 끼기 전에 변수에 받아 둬야 합니다. `LIMIT`이 있는 DELETE는 안전 업데이트 모드에서도 허용됩니다.

### 4-3. LOOP + 커서 — 등급 재산정

두 번째 요청입니다. 고객을 **한 명씩** 꺼내 결제액을 계산하고 등급을 매깁니다. 조회 결과를 한 행씩 꺼내는 도구가 **커서(CURSOR)**입니다.

```sql
DELIMITER $$
CREATE PROCEDURE sp_recalc_grades(IN p_base_date DATE, OUT p_changed INT, OUT p_skipped INT)
BEGIN
    DECLARE v_done        BOOLEAN DEFAULT FALSE;
    DECLARE v_customer_id INT;
    DECLARE v_old_grade   VARCHAR(10);
    DECLARE v_joined_at   DATETIME;
    DECLARE v_spend       INT;
    DECLARE v_new_grade   VARCHAR(10);

    -- ① 커서: 처리할 대상 (변수 다음, 핸들러 전에 선언)
    DECLARE cur_customers CURSOR FOR
        SELECT customer_id, grade, joined_at FROM customers ORDER BY customer_id;
    -- ② 더 꺼낼 행이 없으면(NOT FOUND) 표시만 하고 계속
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_changed = 0, p_skipped = 0;
    OPEN cur_customers;

    read_loop: LOOP
        FETCH cur_customers INTO v_customer_id, v_old_grade, v_joined_at;
        IF v_done THEN
            LEAVE read_loop;                                -- ③ 다 읽었으면 탈출
        END IF;

        IF v_joined_at >= p_base_date - INTERVAL 1 MONTH THEN
            SET p_skipped = p_skipped + 1;
            ITERATE read_loop;                              -- ④ 신규 고객은 건너뛰고 다음 회차
        END IF;

        SELECT COALESCE(SUM(t.amount), 0) INTO v_spend
        FROM (
            SELECT SUM(oi.quantity * oi.unit_price) + o.delivery_fee - o.discount_amount AS amount
            FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
            WHERE o.customer_id = v_customer_id AND o.status = '배달완료'
              AND o.ordered_at >= p_base_date - INTERVAL 3 MONTH AND o.ordered_at < p_base_date
            GROUP BY o.order_id
        ) t;

        SET v_new_grade = CASE
            WHEN v_spend >= 600000 THEN 'VIP'
            WHEN v_spend >= 400000 THEN '골드'
            WHEN v_spend >= 200000 THEN '실버'
            ELSE '일반'
        END;

        IF v_new_grade <> v_old_grade THEN
            UPDATE customers SET grade = v_new_grade WHERE customer_id = v_customer_id;
            SET p_changed = p_changed + 1;
        END IF;
    END LOOP read_loop;

    CLOSE cur_customers;
END $$
DELIMITER ;
```


| 단계 | 문법 | 뜻 |
|---|---|---|
| 선언 | `DECLARE 커서 CURSOR FOR SELECT …` | 처리할 결과 집합 |
| 끝 감지 | `DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE` | FETCH할 행이 없으면 깃발을 올림 |
| 열기 · 읽기 · 닫기 | `OPEN` → `FETCH … INTO 변수` → `CLOSE` | 한 행씩 변수로 |
| 반복 제어 | `LEAVE 라벨` / `ITERATE 라벨` | 반복 종료 / 이번 회차 건너뛰기 |

> `DECLARE` 순서는 **변수 → 커서 → 핸들러**로 정해져 있습니다. 순서가 바뀌면 1337 · 1338 에러가 납니다.

7월 1일 기준으로 실행합니다.

```sql
CALL sp_recalc_grades('2026-07-01', @changed, @skipped);
SELECT @changed AS changed, @skipped AS skipped_new_customers;
```

<sub>▶ 실행 결과 · 1행</sub>

| changed | skipped_new_customers |
|---|---|
| 10 | 1 |


```sql
SELECT grade, COUNT(*) AS customers
FROM customers
GROUP BY grade
ORDER BY FIELD(grade, 'VIP', '골드', '실버', '일반');
```

<sub>▶ 실행 결과 · 4행</sub>

| grade | customers |
|---|---|
| VIP | 6 |
| 골드 | 4 |
| 실버 | 10 |
| 일반 | 10 |


> **커서는 마지막 수단입니다.** 이 작업도 사실 `UPDATE customers c JOIN (결제액 집계) t … SET c.grade = CASE …` **한 문장**으로 할 수 있고, 수만 명이면 그쪽이 수십 배 빠릅니다(SQL은 집합 단위로 일할 때 가장 빠릅니다). 커서는 행마다 **다른 프로시저를 부르거나, 행마다 다른 처리·예외 처리**가 필요할 때 씁니다. 오늘은 반복문과 커서의 문법을 익히는 것이 목적입니다.

## 5. 예외 처리

### 5-1. 처리하지 않으면: 트랜잭션이 열린 채 멈춘다

먼저 실패 이유를 기록할 테이블입니다.

```sql
CREATE TABLE error_logs (
    log_id        INT           NOT NULL AUTO_INCREMENT,
    proc_name     VARCHAR(64)   NOT NULL,
    error_code    INT           NOT NULL,
    error_message VARCHAR(500)  NOT NULL,
    params        VARCHAR(200)      NULL,
    logged_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_error_logs PRIMARY KEY (log_id)
) COMMENT '프로시저 실패 기록';
```


예외 처리 없이 Ch08 방식 그대로 주문 머리 + 주문 상세를 넣는 프로시저를 만들어, 없는 메뉴(999번)로 호출합니다.

```sql
DELIMITER $$
CREATE PROCEDURE sp_order_naive(IN p_customer_id INT, IN p_restaurant_id INT, IN p_menu_id INT)
BEGIN
    START TRANSACTION;
    INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', '카드', 0, '2026-06-30 19:00:00');
    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (LAST_INSERT_ID(), p_menu_id, 1, 1000);
    COMMIT;
END $$
DELIMITER ;
```


```sql
CALL sp_order_naive(2, 1, 999);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`hanip_delivery12`.`order_items`, CONSTRAINT `fk_order_items_menu` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`menu_id`))
```


에러가 나는 순간 프로시저가 멈췄습니다. `COMMIT`에도 `ROLLBACK`에도 도달하지 못했으니 **주문 머리 1행이 열린 트랜잭션 안에 남아 있습니다.** 이 접속에서 다음에 누가 `COMMIT`을 하면 빈 주문이 저장됩니다.

```sql
SELECT COUNT(*) AS orders_in_open_tx FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_in_open_tx |
|---|
| 564 |


```sql
ROLLBACK;
SELECT COUNT(*) AS orders_after_rollback FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_after_rollback |
|---|
| 563 |


개발팀이 말한 "한 곳은 ROLLBACK을 빼먹어서 빈 주문이 생겼다"가 바로 이 상황입니다.

### 5-2. DECLARE HANDLER — 에러를 잡는다

**핸들러**는 "이런 에러가 나면 이렇게 하라"는 약속입니다.

```sql
DECLARE {EXIT | CONTINUE} HANDLER FOR 조건
    처리할 문장;            -- 여러 문장이면 BEGIN … END
```

| 구분 | 뜻 |
|---|---|
| `EXIT` | 처리한 뒤 **프로시저(그 BEGIN 블록)를 끝낸다** — 트랜잭션 실패 처리에 사용 |
| `CONTINUE` | 처리한 뒤 **다음 문장부터 계속** — "없으면 표시만" 같은 경우(4-3절 NOT FOUND) |

| 조건 | 잡는 것 |
|---|---|
| `SQLEXCEPTION` | 모든 에러 |
| `SQLWARNING` | 경고 |
| `NOT FOUND` | 커서 끝, `SELECT … INTO` 결과 0행 |
| 에러 번호 `1062` | 특정 MySQL 에러 (예: UNIQUE 중복) |
| `SQLSTATE '45000'` | 특정 SQLSTATE (SIGNAL로 일으킨 사용자 정의 에러) |

### 5-3. EXIT HANDLER + ROLLBACK + RESIGNAL — 되돌리고 다시 던진다

같은 프로시저에 핸들러 하나를 더합니다. 에러가 나면 **되돌리고(ROLLBACK)**, 에러를 **그대로 다시 던집니다(RESIGNAL)**. 호출한 앱은 원래 에러를 그대로 받아 사용자에게 알릴 수 있습니다.

```sql
DROP PROCEDURE sp_order_naive;

DELIMITER $$
CREATE PROCEDURE sp_order_safe(IN p_customer_id INT, IN p_restaurant_id INT, IN p_menu_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', '카드', 0, '2026-06-30 19:00:00');
    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (LAST_INSERT_ID(), p_menu_id, 1, 1000);
    COMMIT;
END $$
DELIMITER ;
```


```sql
CALL sp_order_safe(2, 1, 999);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`hanip_delivery12`.`order_items`, CONSTRAINT `fk_order_items_menu` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`menu_id`))
```


```sql
SELECT COUNT(*) AS orders_total FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_total |
|---|
| 563 |


에러 메시지는 똑같지만, 이번에는 주문 머리가 남지 않았습니다. **호출하는 쪽이 ROLLBACK을 잊어도** 프로시저가 책임집니다.

### 5-4. GET DIAGNOSTICS — 무슨 에러였는지 꺼내서 기록한다

`RESIGNAL` 대신 에러 내용을 꺼내 **기록**하고, 결과를 OUT 파라미터로 알려 주는 방식도 있습니다.

```sql
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    GET DIAGNOSTICS CONDITION 1
        v_code = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;   -- ① 가장 먼저 (다른 문장이 실행되면 지워짐)
    ROLLBACK;                                          -- ② 되돌리고
    INSERT INTO error_logs (proc_name, error_code, error_message)
    VALUES ('sp_…', v_code, v_msg);                    -- ③ 트랜잭션 밖이라 기록은 남는다
    SET p_result = CONCAT('실패: ', v_msg);            -- ④ 호출한 쪽에 알림
END;
```

| 방식 | 호출한 쪽이 받는 것 | 어울리는 곳 |
|---|---|---|
| `ROLLBACK; RESIGNAL;` | **에러** (원래 번호와 메시지) | 앱이 예외로 처리 (Spring `@Transactional`과 같은 흐름) |
| `GET DIAGNOSTICS` + 기록 + OUT | **정상 종료** + 결과 메시지 | 배치 작업, 실패 이유를 DB에 남겨야 할 때 |

> 순서가 중요합니다. **ROLLBACK을 먼저** 해야 에러 로그 INSERT가 함께 취소되지 않습니다. autocommit = 1 이므로 ROLLBACK 뒤의 INSERT는 바로 확정됩니다.

### 5-5. SIGNAL — 업무 규칙 위반을 에러로

Ch11에서 쓴 `SIGNAL`은 프로시저에서도 같습니다. "품절", "최소 주문 금액 미달"처럼 **SQL 문법은 맞지만 업무상 안 되는** 경우를 에러로 만들어 위의 핸들러로 보냅니다.

```sql
IF v_sold_out THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '품절된 메뉴입니다.', MYSQL_ERRNO = 5001;   -- 번호도 직접 정할 수 있다
END IF;
```

## 6. 종합 — 주문 접수 프로시저

첫 번째 요청의 답입니다. 지금까지의 모든 것(변수 · IF · CASE · SIGNAL · 핸들러 · 트랜잭션)이 들어갑니다.

```sql
DELIMITER $$
CREATE PROCEDURE sp_place_order(
    IN  p_customer_id        INT,
    IN  p_restaurant_id      INT,
    IN  p_menu_id            INT,
    IN  p_quantity           INT,
    IN  p_customer_coupon_id INT,        -- 쿠폰 없으면 NULL
    IN  p_payment_method     VARCHAR(10),
    IN  p_ordered_at         DATETIME,   -- NULL이면 지금
    OUT p_order_id           INT,
    OUT p_result             VARCHAR(200)
)
BEGIN
    DECLARE v_price       INT;
    DECLARE v_sold_out    BOOLEAN;
    DECLARE v_is_open     BOOLEAN;
    DECLARE v_min_order   INT;
    DECLARE v_fee         INT;
    DECLARE v_food        INT;
    DECLARE v_coupon_id   INT;
    DECLARE v_discount    INT DEFAULT 0;
    DECLARE v_code        INT;
    DECLARE v_msg         VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_code = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO error_logs (proc_name, error_code, error_message, params)
        VALUES ('sp_place_order', v_code, v_msg,
                CONCAT_WS(',', p_customer_id, p_restaurant_id, p_menu_id, p_quantity, p_customer_coupon_id));
        SET p_order_id = NULL;
        SET p_result = CONCAT('실패: ', v_msg);
    END;

    SET p_ordered_at = COALESCE(p_ordered_at, NOW());

    -- ① 검증: 가게
    SELECT is_open, min_order_amount, delivery_fee INTO v_is_open, v_min_order, v_fee
    FROM restaurants WHERE restaurant_id = p_restaurant_id;
    IF v_is_open IS NULL OR NOT v_is_open THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '주문할 수 없는 가게입니다.', MYSQL_ERRNO = 5001;
    END IF;

    -- ② 검증: 메뉴 (그 가게의 메뉴인지, 품절인지)
    SELECT price, is_sold_out INTO v_price, v_sold_out
    FROM menus WHERE menu_id = p_menu_id AND restaurant_id = p_restaurant_id;
    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이 가게의 메뉴가 아닙니다.', MYSQL_ERRNO = 5002;
    ELSEIF v_sold_out THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '품절된 메뉴입니다.', MYSQL_ERRNO = 5003;
    END IF;

    -- ③ 검증: 최소 주문 금액
    SET v_food = v_price * p_quantity;
    IF v_food < v_min_order THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '최소 주문 금액에 못 미칩니다.', MYSQL_ERRNO = 5004;
    END IF;

    -- ④ 쿠폰 할인액 (3-2절 프로시저 재사용)
    IF p_customer_coupon_id IS NOT NULL THEN
        SELECT coupon_id INTO v_coupon_id FROM customer_coupons
        WHERE customer_coupon_id = p_customer_coupon_id AND customer_id = p_customer_id;
        IF v_coupon_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '고객의 쿠폰이 아닙니다.', MYSQL_ERRNO = 5005;
        END IF;
        CALL sp_calc_discount(v_coupon_id, v_food, v_discount);
    END IF;

    -- ⑤ 트랜잭션: 주문 머리 → 주문 상세 → 쿠폰 사용
    START TRANSACTION;

    INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                        delivery_fee, discount_amount, ordered_at)
    VALUES (p_customer_id, p_restaurant_id, '접수', p_payment_method, v_fee, v_discount, p_ordered_at);
    SET p_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
    VALUES (p_order_id, p_menu_id, p_quantity, v_price);

    IF p_customer_coupon_id IS NOT NULL THEN
        UPDATE customer_coupons SET used_order_id = p_order_id
        WHERE customer_coupon_id = p_customer_coupon_id
          AND used_order_id IS NULL AND expires_at > p_ordered_at;
        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 사용했거나 만료된 쿠폰입니다.', MYSQL_ERRNO = 5006;
        END IF;
    END IF;

    COMMIT;
    SET p_result = CONCAT('성공: 결제 금액 ', FORMAT(v_food + v_fee - v_discount, 0), '원');
END $$
DELIMITER ;
```


| 구간 | 하는 일 | 실패하면 |
|---|---|---|
| ①~④ 검증 | 가게 · 메뉴 · 최소 금액 · 쿠폰 소유 | `SIGNAL` → 핸들러 → 기록 (트랜잭션 전이라 되돌릴 것 없음) |
| ⑤ 트랜잭션 | 주문 · 상세 · 쿠폰 사용 | `SIGNAL` 또는 FK 등 SQL 에러 → 핸들러 → **ROLLBACK** → 기록 |
| 공통 | 결과 메시지를 `p_result`로 | 앱은 `p_order_id`가 NULL인지로 성공 여부 판단 |

### 6-1. 성공

김민준 님(1번)이 서면옛날돼지국밥에서 돼지국밥 3그릇, VIP 5,000원 쿠폰(보유 쿠폰 4번)으로 주문합니다.

```sql
CALL sp_place_order(1, 1, 1, 3, 4, '간편결제', '2026-06-30 19:05:00', @order_id, @result);
SELECT @order_id AS order_id, @result AS result;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | result |
|---|---|
| 566 | 성공: 결제 금액 27,500원 |


주문 번호가 564가 아니라 566인 이유: 5-1절과 5-3절의 실패한 시도가 564 · 565번을 이미 가져갔기 때문입니다. **AUTO_INCREMENT 번호는 ROLLBACK돼도 돌아가지 않습니다.** 주문 번호에 빈 번호가 있는 것은 정상입니다.

```sql
SELECT o.order_id, o.delivery_fee, o.discount_amount, oi.menu_id, oi.quantity, oi.unit_price,
    cc.used_order_id AS coupon_used_by
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN customer_coupons cc ON cc.used_order_id = o.order_id
WHERE o.order_id = @order_id;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | delivery_fee | discount_amount | menu_id | quantity | unit_price | coupon_used_by |
|---|---|---|---|---|---|---|
| 566 | 2500 | 5000 | 1 | 3 | 10000 | 566 |


### 6-2. 실패 세 가지

```sql
CALL sp_place_order(1, 1, 1, 2, 4, '카드', '2026-06-30 19:20:00', @o1, @r1);   -- 같은 쿠폰 또 사용
CALL sp_place_order(4, 5, 24, 1, NULL, '카드', '2026-06-30 19:21:00', @o2, @r2); -- 품절 메뉴
CALL sp_place_order(7, 12, 59, 1, NULL, '카드', '2026-06-30 19:22:00', @o3, @r3); -- 최소 주문 금액 미달
SELECT @o1 AS order_1, @r1 AS result_1;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_1 | result_1 |
|---|---|
| NULL | 실패: 이미 사용했거나 만료된 쿠폰입니다. |


```sql
SELECT @r2 AS result_2, @r3 AS result_3;
```

<sub>▶ 실행 결과 · 1행</sub>

| result_2 | result_3 |
|---|---|
| 실패: 품절된 메뉴입니다. | 실패: 최소 주문 금액에 못 미칩니다. |


```sql
SELECT log_id, proc_name, error_code, error_message, params FROM error_logs ORDER BY log_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| log_id | proc_name | error_code | error_message | params |
|---|---|---|---|---|
| 1 | sp_place_order | 5006 | 이미 사용했거나 만료된 쿠폰입니다. | 1,1,1,2,4 |
| 2 | sp_place_order | 5003 | 품절된 메뉴입니다. | 4,5,24,1 |
| 3 | sp_place_order | 5004 | 최소 주문 금액에 못 미칩니다. | 7,12,59,1 |


```sql
SELECT COUNT(*) AS orders_total,
    (SELECT COUNT(*) FROM orders WHERE ordered_at >= '2026-06-30 19:20:00') AS failed_orders_left
FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_total | failed_orders_left |
|---|---|
| 564 | 0 |


첫 번째 실패는 **트랜잭션 안에서** 일어났습니다(주문 머리와 상세가 이미 들어간 뒤 쿠폰 UPDATE가 0행). 핸들러가 ROLLBACK했으므로 남은 주문은 0건이고, 실패 이유 세 건은 `error_logs`에 남았습니다. 앱은 이제 `CALL` 한 줄과 결과 확인만 하면 됩니다.

## 7. 저장 함수

### 7-1. 함수는 SELECT 안에서 쓴다

프로시저는 `CALL`로 실행하는 **작업**이고, 함수는 값 하나를 돌려주는 **계산**이라 `SELECT` 안에서 씁니다. 매번 JOIN과 GROUP BY로 계산하던 주문 금액을 함수로 만듭니다.

```sql
DELIMITER $$
CREATE FUNCTION fn_order_total(p_order_id INT)
RETURNS INT
BEGIN
    RETURN (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = p_order_id)
         + (SELECT delivery_fee - discount_amount FROM orders WHERE order_id = p_order_id);
END $$
DELIMITER ;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1418. This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA in its declaration and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)
```


**1418 에러.** MySQL 8은 기본적으로 **바이너리 로그**(복제·복구용 변경 기록)가 켜져 있어서, 함수가 데이터를 바꾸는지 아닌지를 **선언**해야 만들 수 있습니다.

| 특성 | 뜻 |
|---|---|
| `DETERMINISTIC` | 같은 입력이면 항상 같은 결과 (테이블을 읽지 않는 순수 계산) |
| `READS SQL DATA` | 테이블을 **읽기만** 한다 |
| `NO SQL` | SQL을 쓰지 않는다 |

```sql
DELIMITER $$
CREATE FUNCTION fn_order_total(p_order_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = p_order_id)
         + (SELECT delivery_fee - discount_amount FROM orders WHERE order_id = p_order_id);
END $$

CREATE FUNCTION fn_grade_by_amount(p_amount INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    RETURN CASE
        WHEN p_amount >= 600000 THEN 'VIP'
        WHEN p_amount >= 400000 THEN '골드'
        WHEN p_amount >= 200000 THEN '실버'
        ELSE '일반'
    END;
END $$
DELIMITER ;

SELECT order_id, status, fn_order_total(order_id) AS total
FROM orders
WHERE ordered_at >= '2026-06-30 18:00:00'
ORDER BY order_id;
```

<sub>▶ 실행 결과 · 3행</sub>

| order_id | status | total |
|---|---|---|
| 562 | 조리중 | 23000 |
| 563 | 접수 | 31000 |
| 566 | 접수 | 27500 |


> 인터넷에는 `SET GLOBAL log_bin_trust_function_creators = 1;`로 1418을 "해결"하라는 글이 많습니다. 서버 전체 안전장치를 끄는 것이니, 특성을 정확히 선언하는 것이 정답입니다(Ch08의 안전 모드와 같은 이야기).

### 7-2. 함수로 집합 단위 처리

4-3절에서 커서로 한 명씩 했던 등급 판정을, 함수를 쓰면 **한 문장**으로 미리 볼 수 있습니다.

```sql
SELECT c.name, c.grade, t.spend_3m, fn_grade_by_amount(t.spend_3m) AS by_function
FROM customers c
JOIN (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS spend_3m
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료' AND o.ordered_at >= '2026-04-01' AND o.ordered_at < '2026-07-01'
    GROUP BY o.customer_id
) t ON c.customer_id = t.customer_id
ORDER BY t.spend_3m DESC;
```

<sub>▶ 실행 결과 · 26행 (상위 6행 표시)</sub>

| name | grade | spend_3m | by_function |
|---|---|---|---|
| 이서연 | VIP | 766000 | VIP |
| 김민준 | VIP | 719000 | VIP |
| 정우진 | VIP | 679000 | VIP |
| 임도현 | VIP | 641000 | VIP |
| 서지우 | VIP | 612000 | VIP |
| 박지훈 | VIP | 594500 | 골드 |


> 이 예시의 결제액은 음식값만 더해서 4-3절(배달팁·할인 포함)과 조금 다릅니다. 박지훈 님은 4-3절 기준으로는 VIP(627,500원)인데 여기서는 골드로 나옵니다. 실무에서는 계산 규칙 자체를 **함수 하나**에 두고 프로시저·쿼리·리포트가 모두 그 함수를 쓰게 해야 이런 차이가 생기지 않습니다.

### 7-3. 프로시저 vs 함수

| | 프로시저 | 함수 |
|---|---|---|
| 실행 | `CALL sp_…()` | `SELECT fn_…()` — 식 안에서 |
| 돌려주는 것 | 결과 집합, OUT 파라미터 여러 개 | **값 하나** (`RETURN`) |
| 트랜잭션 · 데이터 변경 | 가능 (`COMMIT` · `ROLLBACK`) | 트랜잭션 제어 불가(1422), 변경은 피함 |
| 용도 | **작업** — 주문 접수, 배치, 재산정 | **계산** — 금액, 등급, 포맷 |

## 8. 트랜잭션과 프로시저 정리

| 상황 | 결과 | 대처 |
|---|---|---|
| 프로시저 안 SQL 에러, 핸들러 없음 | 프로시저 즉시 중단, **열린 트랜잭션은 그대로** | 호출한 쪽이 ROLLBACK해야 함 (5-1절) |
| `EXIT HANDLER FOR SQLEXCEPTION` + `ROLLBACK` | 프로시저가 스스로 되돌림 | **표준 패턴** (5-3 · 6절) |
| 핸들러에서 `RESIGNAL` | 호출한 쪽은 원래 에러를 받음 | 앱이 예외로 처리할 때 |
| 핸들러에서 기록 + OUT | 정상 종료 + 결과 메시지 | 배치 · 실패 기록이 필요할 때 |
| 프로시저 안에서 `START TRANSACTION` | 바깥에 열린 트랜잭션이 있었다면 **암묵적 COMMIT** | 트랜잭션을 여는 곳은 한 군데로 (프로시저 또는 앱) |
| 트리거가 걸린 테이블을 프로시저가 변경 | 트리거도 같은 트랜잭션 (Ch11) | 프로시저 ROLLBACK 시 트리거 결과도 취소 |

## 9. 관리와 권한

```sql
SELECT routine_name AS routine_name, routine_type AS routine_type, sql_data_access AS data_access
FROM information_schema.routines
WHERE routine_schema = DATABASE()
ORDER BY routine_type DESC, routine_name;
```

<sub>▶ 실행 결과 · 11행</sub>

| routine_name | routine_type | data_access |
|---|---|---|
| sp_calc_discount | PROCEDURE | CONTAINS SQL |
| sp_check_grade | PROCEDURE | CONTAINS SQL |
| sp_customer_stats | PROCEDURE | CONTAINS SQL |
| sp_daily_sales | PROCEDURE | CONTAINS SQL |
| sp_order_safe | PROCEDURE | CONTAINS SQL |
| sp_place_order | PROCEDURE | CONTAINS SQL |
| sp_purge_archive | PROCEDURE | CONTAINS SQL |
| sp_recalc_grades | PROCEDURE | CONTAINS SQL |
| sp_restaurant_summary | PROCEDURE | CONTAINS SQL |
| fn_grade_by_amount | FUNCTION | CONTAINS SQL |
| fn_order_total | FUNCTION | READS SQL DATA |


```sql
SHOW PROCEDURE STATUS WHERE Db = DATABASE();      -- 프로시저 목록
SHOW CREATE PROCEDURE sp_place_order;             -- 본문 확인
DROP PROCEDURE IF EXISTS sp_place_order;          -- 삭제 (본문 수정은 삭제 후 재생성)
DROP FUNCTION IF EXISTS fn_order_total;
```

### 9-1. EXECUTE 권한 — 테이블 대신 프로시저를 열어 준다

앱 서버 계정에 테이블 INSERT 권한을 주는 대신, **주문 접수 프로시저 실행 권한만** 줍니다. 앱은 주문을 오직 `sp_place_order`를 통해서만 넣을 수 있고, 검증을 건너뛰는 INSERT는 불가능해집니다.

```sql
DROP USER IF EXISTS 'hanip_app'@'localhost';
CREATE USER 'hanip_app'@'localhost' IDENTIFIED BY 'App!2026';
GRANT EXECUTE ON PROCEDURE hanip_delivery12.sp_place_order TO 'hanip_app'@'localhost';

SHOW GRANTS FOR 'hanip_app'@'localhost';
```

<sub>▶ 실행 결과 · 2행</sub>

| Grants for hanip_app@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_app`@`localhost` |
| GRANT EXECUTE ON PROCEDURE `hanip_delivery12`.`sp_place_order` TO `hanip_app`@`localhost` |


```sql
-- hanip_app 으로 접속하면
CALL hanip_delivery12.sp_place_order(2, 1, 1, 2, NULL, '카드', NULL, @id, @msg);   -- ✓ 가능
INSERT INTO hanip_delivery12.orders (…) VALUES (…);                               -- ✗ 1142 INSERT command denied
```

> 프로시저는 기본적으로 **만든 사람(DEFINER)의 권한**으로 실행됩니다(`SQL SECURITY DEFINER`). 그래서 `hanip_app`은 테이블 권한이 없어도 프로시저 안의 INSERT는 성공합니다. Ch10의 보안 뷰와 같은 원리입니다.

## 10. 오늘의 요청 해결

> **To.** 개발팀 한 팀장 · 정산팀 정 대리
>
> | 요청 | 프로시저 · 함수 | 핵심 |
> |---|---|---|
> | ① 주문 접수 | `sp_place_order` | 검증(가게·메뉴·최소 금액·쿠폰) → 트랜잭션 → 실패하면 **자동 ROLLBACK + `error_logs` 기록**, 결과는 OUT으로 |
> | ② 등급 재산정 | `sp_recalc_grades` | 커서 + LOOP, 신규 고객 `ITERATE`, 바뀐 인원·건너뛴 인원을 OUT으로 |
> | ③ 일별 매출표 | `sp_daily_sales` | WHILE로 기간의 모든 날짜, 주문 없는 날 0원, 재실행해도 같은 결과 |
> | (덤) | `sp_calc_discount` · `fn_order_total` · `fn_grade_by_amount` | 할인·금액·등급 규칙을 한 곳에 |
>
> 앱에는 `GRANT EXECUTE`로 프로시저 실행 권한만 주세요. 앱 네 곳의 주문 코드는 `CALL sp_place_order(…)` 한 줄이 됩니다.

## 정리

| 개념 | 핵심 |
|---|---|
| `CREATE PROCEDURE` · `CALL` | SQL 프로그램을 이름으로 저장 · 실행 |
| 변수 · 파라미터 | `DECLARE`(BEGIN 직후) · `SET` · `SELECT … INTO` / `IN` · `OUT` · `INOUT` |
| 조건문 | `IF … ELSEIF … ELSE … END IF` / `CASE … WHEN … END CASE` |
| 반복문 | `WHILE`(먼저 검사) · `REPEAT … UNTIL`(최소 1번) · `LOOP` + `LEAVE` / `ITERATE` |
| 커서 | `DECLARE CURSOR` → `OPEN` → `FETCH` → `CLOSE`, 끝은 `NOT FOUND` 핸들러. 집합 처리가 가능하면 커서보다 한 문장 |
| 핸들러 | `EXIT` / `CONTINUE` `HANDLER FOR SQLEXCEPTION · NOT FOUND · 1062 · SQLSTATE` |
| 에러 다루기 | `SIGNAL`(일으키기) · `RESIGNAL`(다시 던지기) · `GET DIAGNOSTICS`(내용 꺼내기) |
| 트랜잭션 프로시저 | `EXIT HANDLER` → `ROLLBACK` → 기록 / `RESIGNAL`. 핸들러 없으면 트랜잭션이 열린 채 남음 |
| 저장 함수 | `RETURNS` · `RETURN`, `SELECT` 안에서. 바이너리 로그 → `DETERMINISTIC` / `READS SQL DATA` 선언(1418) |
| 권한 | `GRANT EXECUTE ON PROCEDURE` — 테이블 대신 프로시저만 열어 주기 |

## 과정을 마치며

12번의 수업 동안 `hanip_delivery01`부터 `hanip_delivery12`까지 열두 개의 DB가 쌓였습니다.

| PART | 챕터 | 할 수 있게 된 것 |
|---|---|---|
| 1 · 읽기 | 01~06 | 원하는 데이터를 꺼내고, 묶고, 잇고, 순위를 매긴다 |
| 2 · 쓰기 | 07~08 | 테이블을 만들고, 데이터를 안전하게 바꾼다 |
| 3 · 설계와 운영 | 09~10 | 구조의 이유를 설명하고, 쿼리를 저장하고, 빠르게 만들고, 권한을 나눈다 |
| 4 · 서버 프로그래밍 | 11~12 | 변경을 자동으로 기록·검증하고, 업무 로직을 트랜잭션과 예외 처리까지 갖춰 DB에 둔다 |

마지막으로 [종합 프로젝트 — 단골 리워드](../../project/README.md)에서 요구사항부터 ERD, DDL, 분석 쿼리, 뷰·인덱스·권한, 트리거·프로시저까지 혼자(또는 팀으로) 끝까지 만들어 봅니다.

<!-- lecture:auto -->
