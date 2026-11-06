# Ch12 실습 — 조건, 반복, 예외, 트랜잭션 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery12;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 프로시저를 고칠 때는 `DROP PROCEDURE IF EXISTS 이름;` 후 다시 만듭니다.
> 수업 중 만든 프로시저·테이블과 이름이 겹치면 `setup.sql`의 DROP 줄 주석을 풀고 다시 실행한 뒤 시작하세요.

---

### 문제 1. 가게 메뉴판 ★

> **운영팀** 가게 번호를 받아 그 가게의 메뉴를 **가격 높은 순**으로 보여 주는 프로시저 `sp_menu_list`를 만들고, 해운대명가밀면(3번)으로 실행하세요.

- 열: `menu_id`, `name`, `price`, `is_sold_out`
- 순서: `price` 내림차순 → `menu_id`

**정답 SQL**

```sql
DELIMITER $$
CREATE PROCEDURE sp_menu_list(IN p_restaurant_id INT)
BEGIN
    SELECT menu_id, name, price, is_sold_out
    FROM menus
    WHERE restaurant_id = p_restaurant_id
    ORDER BY price DESC, menu_id;
END $$
DELIMITER ;

CALL sp_menu_list(3);
```

<sub>▶ 실행 결과 · 4행</sub>

| menu_id | name | price | is_sold_out |
|---|---|---|---|
| 13 | 회밀면 | 11000 | 0 |
| 11 | 물밀면 | 9000 | 0 |
| 12 | 비빔밀면 | 9000 | 0 |
| 14 | 왕만두 (6개) | 7000 | 0 |


> **해설** 파라미터 이름을 `restaurant_id`로 지으면 `WHERE restaurant_id = restaurant_id`가 되어 MySQL이 **열과 파라미터를 구별하지 못하고** 항상 참이 됩니다(모든 메뉴가 나옴). 파라미터는 `p_`, 지역 변수는 `v_`로 시작하는 규칙이 이런 사고를 막습니다.

### 문제 2. OUT 파라미터 ★

> **정산팀** 가게 번호를 받아 **6월 배달완료** 주문 수와 음식 매출을 OUT 파라미터로 돌려주는 `sp_restaurant_june(IN p_restaurant_id, OUT p_orders, OUT p_food_sales)`를 만드세요. 서면옛날돼지국밥(1번)으로 실행합니다.

- 열: `orders`, `food_sales`

**정답 SQL**

```sql
DELIMITER $$
CREATE PROCEDURE sp_restaurant_june(
    IN  p_restaurant_id INT,
    OUT p_orders        INT,
    OUT p_food_sales    INT
)
BEGIN
    SELECT COUNT(DISTINCT o.order_id), COALESCE(SUM(oi.quantity * oi.unit_price), 0)
    INTO p_orders, p_food_sales
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.restaurant_id = p_restaurant_id AND o.status = '배달완료'
      AND o.ordered_at >= '2026-06-01' AND o.ordered_at < '2026-07-01';
END $$
DELIMITER ;

CALL sp_restaurant_june(1, @orders, @sales);
SELECT @orders AS orders, @sales AS food_sales;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders | food_sales |
|---|---|
| 7 | 241000 |


> **해설** `SELECT … INTO 변수1, 변수2`는 열 순서대로 담습니다. 결과가 **2행 이상**이면 1172 에러, 0행이면 변수가 바뀌지 않고 경고(NOT FOUND)가 납니다. 그래서 집계 함수처럼 항상 1행을 돌려주는 쿼리에 쓰는 것이 안전합니다.

### 문제 3. 배달팁 함수 ★★

> **개발팀** 가게와 음식 금액을 받아 실제 배달팁을 돌려주는 **함수** `fn_delivery_fee(p_restaurant_id, p_food_amount)`를 만드세요.
> - 음식 금액 30,000원 이상: 무료(0원)
> - 20,000원 이상: 가게 기본 배달팁에서 1,000원 할인 (0원 미만은 0원)
> - 그 외: 가게 기본 배달팁
>
> 광안리화덕피자(4번, 기본 3,500원)에 15,000 · 25,000 · 35,000원을 넣어 확인하세요.

- 열: `fee_15000`, `fee_25000`, `fee_35000`

**정답 SQL**

```sql
DELIMITER $$
CREATE FUNCTION fn_delivery_fee(p_restaurant_id INT, p_food_amount INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_fee INT;
    SELECT delivery_fee INTO v_fee FROM restaurants WHERE restaurant_id = p_restaurant_id;

    IF p_food_amount >= 30000 THEN
        RETURN 0;
    ELSEIF p_food_amount >= 20000 THEN
        RETURN GREATEST(v_fee - 1000, 0);
    ELSE
        RETURN v_fee;
    END IF;
END $$
DELIMITER ;

SELECT fn_delivery_fee(4, 15000) AS fee_15000,
       fn_delivery_fee(4, 25000) AS fee_25000,
       fn_delivery_fee(4, 35000) AS fee_35000;
```

<sub>▶ 실행 결과 · 1행</sub>

| fee_15000 | fee_25000 | fee_35000 |
|---|---|---|
| 3500 | 2500 | 0 |


> **해설** 테이블을 읽으므로 `READS SQL DATA`를 선언해야 합니다(빠뜨리면 1418). 함수라서 `SELECT r.name, fn_delivery_fee(r.restaurant_id, 25000) FROM restaurants r`처럼 **모든 가게에 한 번에** 적용할 수 있다는 점이 프로시저와 다릅니다.

### 문제 4. 다음 상태 — CASE 문 ★★

> **운영팀** 주문 번호를 받아 **다음 상태**를 알려 주는 `sp_next_status(IN p_order_id, OUT p_next)`를 `CASE` 문으로 만드세요. 접수 → 조리중 → 배달중 → 배달완료, 배달완료와 취소는 `'변경 불가'`, 없는 주문은 `'없는 주문'`.
>
> 563번(접수), 561번(배달중), 1번(배달완료), 9999번으로 확인하세요.

- 열: `order_563`, `order_561`, `order_1`, `order_9999`

**정답 SQL**

```sql
DELIMITER $$
CREATE PROCEDURE sp_next_status(IN p_order_id INT, OUT p_next VARCHAR(10))
BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status FROM orders WHERE order_id = p_order_id;

    CASE v_status
        WHEN '접수'   THEN SET p_next = '조리중';
        WHEN '조리중' THEN SET p_next = '배달중';
        WHEN '배달중' THEN SET p_next = '배달완료';
        WHEN '배달완료' THEN SET p_next = '변경 불가';
        WHEN '취소'   THEN SET p_next = '변경 불가';
        ELSE SET p_next = '없는 주문';
    END CASE;
END $$
DELIMITER ;

CALL sp_next_status(563, @a);
CALL sp_next_status(561, @b);
CALL sp_next_status(1, @c);
CALL sp_next_status(9999, @d);
SELECT @a AS order_563, @b AS order_561, @c AS order_1, @d AS order_9999;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_563 | order_561 | order_1 | order_9999 |
|---|---|---|---|
| 조리중 | 배달완료 | 변경 불가 | 없는 주문 |


> **해설** 9999번은 `SELECT … INTO`가 0행이라 `v_status`가 NULL로 남고, `ELSE`로 갑니다. **`CASE` 문에 `ELSE`를 빠뜨리면** 어느 `WHEN`에도 맞지 않을 때 1339 에러(Case not found)가 납니다. CASE **식**(Ch03)은 ELSE가 없으면 NULL을 돌려주는 것과 다르니 주의하세요.

### 문제 5. 월별 매출표 — WHILE ★★

> **정산팀** 연도와 시작·끝 월을 받아 월별 배달완료 주문 수와 음식 매출을 `month_sales` 테이블(`sales_month` CHAR(7) PK, `orders`, `food_sales`)에 채우는 `sp_fill_month_sales(IN p_year, IN p_from_month, IN p_to_month)`를 `WHILE`로 만드세요. 같은 달을 다시 실행하면 **덮어써야** 합니다. 2026년 1~6월로 실행하고 표를 확인하세요.

- 열: `sales_month`, `orders`, `food_sales`
- 순서: `sales_month`

**정답 SQL**

```sql
CREATE TABLE month_sales (
    sales_month CHAR(7) NOT NULL,
    orders      INT     NOT NULL,
    food_sales  INT     NOT NULL,
    CONSTRAINT pk_month_sales PRIMARY KEY (sales_month)
);

DELIMITER $$
CREATE PROCEDURE sp_fill_month_sales(IN p_year INT, IN p_from_month INT, IN p_to_month INT)
BEGIN
    DECLARE v_month INT DEFAULT p_from_month;
    DECLARE v_start DATE;

    WHILE v_month <= p_to_month DO
        SET v_start = MAKEDATE(p_year, 1) + INTERVAL (v_month - 1) MONTH;

        DELETE FROM month_sales WHERE sales_month = DATE_FORMAT(v_start, '%Y-%m');
        INSERT INTO month_sales (sales_month, orders, food_sales)
        SELECT DATE_FORMAT(v_start, '%Y-%m'), COUNT(DISTINCT o.order_id),
            COALESCE(SUM(oi.quantity * oi.unit_price), 0)
        FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.status = '배달완료'
          AND o.ordered_at >= v_start AND o.ordered_at < v_start + INTERVAL 1 MONTH;

        SET v_month = v_month + 1;
    END WHILE;
END $$
DELIMITER ;

CALL sp_fill_month_sales(2026, 1, 6);
SELECT sales_month, orders, food_sales FROM month_sales ORDER BY sales_month;
```

<sub>▶ 실행 결과 · 6행</sub>

| sales_month | orders | food_sales |
|---|---|---|
| 2026-01 | 74 | 2523400 |
| 2026-02 | 70 | 2079100 |
| 2026-03 | 73 | 2116800 |
| 2026-04 | 91 | 2879800 |
| 2026-05 | 106 | 3157700 |
| 2026-06 | 97 | 2920100 |


> **해설** `MAKEDATE(2026, 1)`은 2026년의 1일째 날(1월 1일). 여기에 `INTERVAL (월-1) MONTH`를 더해 각 달의 1일을 만듭니다. 넣기 전에 같은 달을 지우므로 몇 번 실행해도 결과가 같습니다(**멱등성**). `INSERT … ON DUPLICATE KEY UPDATE`로도 같은 효과를 낼 수 있습니다.

### 문제 6. 나눠서 지우기 — REPEAT ★★

> **개발팀** 리뷰를 복사한 보관 테이블 `reviews_archive`를 만들고(`CREATE TABLE … AS SELECT`), 지정한 개수씩 나눠 지우는 `sp_purge_reviews_archive(IN p_batch, OUT p_rounds)`를 `REPEAT`로 만드세요. 100개씩 지우면 몇 번 반복하는지 확인합니다.

- 열: `rounds`, `remaining`

**정답 SQL**

```sql
CREATE TABLE reviews_archive AS SELECT * FROM reviews;

DELIMITER $$
CREATE PROCEDURE sp_purge_reviews_archive(IN p_batch INT, OUT p_rounds INT)
BEGIN
    DECLARE v_deleted INT;
    SET p_rounds = 0;

    REPEAT
        DELETE FROM reviews_archive LIMIT p_batch;
        SET v_deleted = ROW_COUNT();
        SET p_rounds = p_rounds + 1;
    UNTIL v_deleted = 0 END REPEAT;
END $$
DELIMITER ;

CALL sp_purge_reviews_archive(100, @rounds);
SELECT @rounds AS rounds, (SELECT COUNT(*) FROM reviews_archive) AS remaining;
```

<sub>▶ 실행 결과 · 1행</sub>

| rounds | remaining |
|---|---|
| 4 | 0 |


> **해설** 260행을 100개씩: 100 · 100 · 60 · 0 → 4회. 마지막 0행 회차에서 `UNTIL`이 참이 되어 끝납니다. `UNTIL v_deleted < p_batch`로 쓰면 60행을 지운 3회차에서 바로 끝나 한 번을 아낄 수 있습니다. `SET v_deleted = ROW_COUNT();`를 `SET p_rounds = …` 뒤로 옮기면 `ROW_COUNT()`가 직전 SET문 기준(−1)이 되어 **무한 반복**에 빠집니다.

### 문제 7. 중복 발급은 표시만 — CONTINUE HANDLER ★★

> **마케팅팀** 쿠폰을 발급하는 `sp_issue_coupon(IN p_customer_id, IN p_coupon_id, IN p_issued_at, OUT p_result)`를 만드세요.
> - 만료 시각 = 발급 시각 + 쿠폰의 `valid_days`일
> - 이미 같은 쿠폰을 가진 고객이면(1062, `uq_cc_customer_coupon`) **에러 대신** `p_result = '이미 보유한 쿠폰'`
> - 성공하면 `'발급 완료'`
>
> 조현우 님(7번)에게 불편 보상 쿠폰(4번)을 `'2026-06-30 10:00:00'`에 두 번 발급해 보세요.

- 열: `first_try`, `second_try`, `coupon_rows` (조현우 님의 4번 쿠폰 행 수)

**정답 SQL**

```sql
DELIMITER $$
CREATE PROCEDURE sp_issue_coupon(
    IN  p_customer_id INT,
    IN  p_coupon_id   INT,
    IN  p_issued_at   DATETIME,
    OUT p_result      VARCHAR(50)
)
BEGIN
    DECLARE v_duplicate BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR 1062 SET v_duplicate = TRUE;

    INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
    SELECT p_customer_id, coupon_id, p_issued_at, p_issued_at + INTERVAL valid_days DAY
    FROM coupons WHERE coupon_id = p_coupon_id;

    IF v_duplicate THEN
        SET p_result = '이미 보유한 쿠폰';
    ELSE
        SET p_result = '발급 완료';
    END IF;
END $$
DELIMITER ;

CALL sp_issue_coupon(7, 4, '2026-06-30 10:00:00', @r1);
CALL sp_issue_coupon(7, 4, '2026-06-30 10:00:00', @r2);
SELECT @r1 AS first_try, @r2 AS second_try,
    (SELECT COUNT(*) FROM customer_coupons WHERE customer_id = 7 AND coupon_id = 4) AS coupon_rows;
```

<sub>▶ 실행 결과 · 1행</sub>

| first_try | second_try | coupon_rows |
|---|---|---|
| 발급 완료 | 이미 보유한 쿠폰 | 1 |


> **해설** `CONTINUE` 핸들러라 1062가 나도 프로시저가 멈추지 않고 다음 문장(IF)으로 갑니다. 1062만 잡았으므로 **다른 에러**(예: 없는 고객 → 1452)는 그대로 호출한 쪽에 전달됩니다. 잡을 에러를 좁게 지정하는 것이 좋은 예외 처리입니다. 모든 에러를 `SQLEXCEPTION`으로 잡아 조용히 넘기면 진짜 문제가 숨습니다.

### 문제 8. 가격 변경 검증 — SIGNAL ★★★

> **운영팀** 메뉴 가격 변경을 프로시저로만 하기로 했습니다. `sp_change_price(IN p_menu_id, IN p_new_price)`를 만드세요.
> - 없는 메뉴: `SIGNAL` 메시지 `'없는 메뉴입니다.'`, 에러 번호 5101
> - 0원 이하: `'가격은 0원보다 커야 합니다.'`, 5102
> - 기존 가격 대비 **30% 넘게** 오르거나 내리면: `'한 번에 30% 넘게 바꿀 수 없습니다.'`, 5103
>
> 물밀면(11번)을 9,000원에서 10,000원으로 바꾸고 확인하세요.

- 열: `menu_id`, `name`, `price`

**정답 SQL**

```sql
DELIMITER $$
CREATE PROCEDURE sp_change_price(IN p_menu_id INT, IN p_new_price INT)
BEGIN
    DECLARE v_old INT;
    SELECT price INTO v_old FROM menus WHERE menu_id = p_menu_id;

    IF v_old IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '없는 메뉴입니다.', MYSQL_ERRNO = 5101;
    ELSEIF p_new_price <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '가격은 0원보다 커야 합니다.', MYSQL_ERRNO = 5102;
    ELSEIF ABS(p_new_price - v_old) > v_old * 0.3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '한 번에 30% 넘게 바꿀 수 없습니다.', MYSQL_ERRNO = 5103;
    END IF;

    UPDATE menus SET price = p_new_price WHERE menu_id = p_menu_id;
END $$
DELIMITER ;

CALL sp_change_price(11, 10000);
SELECT menu_id, name, price FROM menus WHERE menu_id = 11;
```

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price |
|---|---|---|
| 11 | 물밀면 | 10000 |


> **해설** `CALL sp_change_price(11, 1000);`은 `Error Code: 5103. 한 번에 30% 넘게 바꿀 수 없습니다.`, `CALL sp_change_price(999, 5000);`은 5101로 막힙니다. 이 프로시저에는 핸들러가 없으므로 `SIGNAL` 에러가 **그대로 호출한 쪽에** 전달됩니다 — 앱이 메시지를 받아 화면에 보여 주면 됩니다. Ch11의 가격 이력 트리거가 있었다면 이 UPDATE도 자동으로 기록됩니다.

### 문제 9. 주문 취소 — 트랜잭션 + EXIT HANDLER + 기록 ★★★

> **CS팀** 주문 취소를 한 번에 처리하는 `sp_cancel_order(IN p_order_id, OUT p_result)`를 만드세요.
> 1. 실패 기록용 `error_logs` 테이블 (`log_id` PK AUTO_INCREMENT, `proc_name` VARCHAR(64), `error_code` INT, `error_message` VARCHAR(500), `logged_at` DATETIME 기본값 현재 시각)
> 2. 트랜잭션 안에서: 주문을 `SELECT … FOR UPDATE`로 잠그고 → 없는 주문이면 `'없는 주문입니다.'`(5201), 상태가 '접수' · '조리중'이 아니면 `'이미 조리가 끝나 취소할 수 없습니다.'`(5202) → 상태를 '취소'로 → 그 주문에 쓴 쿠폰 되돌리기 → 고객에게 불편 보상 쿠폰(4번) 발급 (`'2026-06-30 19:30:00'`, 30일)
> 3. 어떤 에러든 **ROLLBACK 후 error_logs에 기록**, `p_result = '실패: 메시지'`. 성공하면 `'취소 완료'`
>
> 563번(접수), 561번(배달중), 9999번을 차례로 취소해 보세요.

- 열: `result_563`, `result_561`, `result_9999`, `status_563`, `error_count`

**정답 SQL**

```sql
CREATE TABLE error_logs (
    log_id        INT           NOT NULL AUTO_INCREMENT,
    proc_name     VARCHAR(64)   NOT NULL,
    error_code    INT           NOT NULL,
    error_message VARCHAR(500)  NOT NULL,
    logged_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_error_logs PRIMARY KEY (log_id)
);

DELIMITER $$
CREATE PROCEDURE sp_cancel_order(IN p_order_id INT, OUT p_result VARCHAR(200))
BEGIN
    DECLARE v_status      VARCHAR(10);
    DECLARE v_customer_id INT;
    DECLARE v_code        INT;
    DECLARE v_msg         VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_code = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO error_logs (proc_name, error_code, error_message)
        VALUES ('sp_cancel_order', v_code, v_msg);
        SET p_result = CONCAT('실패: ', v_msg);
    END;

    START TRANSACTION;

    SELECT status, customer_id INTO v_status, v_customer_id
    FROM orders WHERE order_id = p_order_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '없는 주문입니다.', MYSQL_ERRNO = 5201;
    ELSEIF v_status NOT IN ('접수', '조리중') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 조리가 끝나 취소할 수 없습니다.', MYSQL_ERRNO = 5202;
    END IF;

    UPDATE orders SET status = '취소' WHERE order_id = p_order_id;
    UPDATE customer_coupons SET used_order_id = NULL WHERE used_order_id = p_order_id;

    INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
    VALUES (v_customer_id, 4, '2026-06-30 19:30:00', '2026-06-30 19:30:00' + INTERVAL 30 DAY);

    COMMIT;
    SET p_result = '취소 완료';
END $$
DELIMITER ;

CALL sp_cancel_order(563, @r1);
CALL sp_cancel_order(561, @r2);
CALL sp_cancel_order(9999, @r3);
SELECT @r1 AS result_563, @r2 AS result_561, @r3 AS result_9999,
    (SELECT status FROM orders WHERE order_id = 563) AS status_563,
    (SELECT COUNT(*) FROM error_logs) AS error_count;
```

<sub>▶ 실행 결과 · 1행</sub>

| result_563 | result_561 | result_9999 | status_563 | error_count |
|---|---|---|---|---|
| 취소 완료 | 실패: 이미 조리가 끝나 취소할 수 없습니다. | 실패: 없는 주문입니다. | 취소 | 2 |


> **해설** `FOR UPDATE`는 읽는 순간 그 행을 **잠가서**, 확인한 뒤 바꾸기 전까지 다른 상담원이 같은 주문을 바꾸지 못하게 합니다(Ch08의 행 잠금). 생각해 볼 점: 정우진 님이 이미 보상 쿠폰(4번)을 갖고 있었다면 마지막 INSERT가 1062로 실패하고, **취소 자체도 ROLLBACK**됩니다. 보상 쿠폰 때문에 취소가 막히는 게 맞을까요? 업무적으로는 아니므로, 실무라면 쿠폰 발급만 7번처럼 `CONTINUE HANDLER FOR 1062`로 감싸거나 `INSERT IGNORE`를 씁니다. **무엇을 한 트랜잭션으로 묶을지**는 SQL이 아니라 업무 규칙이 정합니다.

### 문제 10. 평점 낮은 가게 찾기 — 커서 + LOOP ★★★

> **운영팀** 커서로 가게를 하나씩 돌며, **영업 중인** 가게 중 리뷰가 `p_min_reviews`개 이상이고 평균 별점이 `p_threshold` 미만인 곳을 `restaurant_alerts` 테이블(`restaurant_id` PK, `review_count`, `avg_rating` DECIMAL(3,2), `message` VARCHAR(100))에 기록하는 `sp_flag_low_rating(IN p_min_reviews, IN p_threshold, OUT p_flagged)`를 만드세요. 폐업한 가게는 `ITERATE`로 건너뜁니다. 메시지는 `'평균 3.38점 — 품질 점검 필요'` 형식.
>
> 리뷰 5개 이상, 3.5점 미만으로 실행하세요.

- 결과: `restaurant_alerts` 전체 + 가게 이름 (`restaurant_id`, `name`, `review_count`, `avg_rating`, `message`), `restaurant_id` 순

**정답 SQL**

```sql
CREATE TABLE restaurant_alerts (
    restaurant_id INT           NOT NULL,
    review_count  INT           NOT NULL,
    avg_rating    DECIMAL(3,2)  NOT NULL,
    message       VARCHAR(100)  NOT NULL,
    CONSTRAINT pk_restaurant_alerts PRIMARY KEY (restaurant_id)
);

DELIMITER $$
CREATE PROCEDURE sp_flag_low_rating(IN p_min_reviews INT, IN p_threshold DECIMAL(3,2), OUT p_flagged INT)
BEGIN
    DECLARE v_done          BOOLEAN DEFAULT FALSE;
    DECLARE v_restaurant_id INT;
    DECLARE v_is_open       BOOLEAN;
    DECLARE v_count         INT;
    DECLARE v_avg           DECIMAL(3,2);

    DECLARE cur_restaurants CURSOR FOR
        SELECT restaurant_id, is_open FROM restaurants ORDER BY restaurant_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_flagged = 0;
    DELETE FROM restaurant_alerts WHERE restaurant_id > 0;
    OPEN cur_restaurants;

    shop_loop: LOOP
        FETCH cur_restaurants INTO v_restaurant_id, v_is_open;
        IF v_done THEN
            LEAVE shop_loop;
        END IF;
        IF NOT v_is_open THEN
            ITERATE shop_loop;
        END IF;

        SELECT COUNT(*), AVG(rv.rating) INTO v_count, v_avg
        FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
        WHERE o.restaurant_id = v_restaurant_id;

        IF v_count >= p_min_reviews AND v_avg < p_threshold THEN
            INSERT INTO restaurant_alerts (restaurant_id, review_count, avg_rating, message)
            VALUES (v_restaurant_id, v_count, v_avg, CONCAT('평균 ', v_avg, '점 — 품질 점검 필요'));
            SET p_flagged = p_flagged + 1;
        END IF;
    END LOOP shop_loop;

    CLOSE cur_restaurants;
END $$
DELIMITER ;

CALL sp_flag_low_rating(5, 3.5, @flagged);
SELECT a.restaurant_id, r.name, a.review_count, a.avg_rating, a.message
FROM restaurant_alerts a JOIN restaurants r ON a.restaurant_id = r.restaurant_id
ORDER BY a.restaurant_id;
```

<sub>▶ 실행 결과 · 2행</sub>

| restaurant_id | name | review_count | avg_rating | message |
|---|---|---|---|---|
| 5 | 남천동마라공방 | 13 | 3.38 | 평균 3.38점 — 품질 점검 필요 |
| 10 | 하단버거스탠드 | 15 | 3.27 | 평균 3.27점 — 품질 점검 필요 |


> **해설** 서면야식치킨(13번, 평균 3.00)은 폐업이라 `ITERATE`로 건너뛰었습니다. 리뷰가 없는 가게는 `AVG`가 NULL이라 `v_avg < p_threshold`가 NULL(거짓)이 되어 자연스럽게 빠집니다. 커서 안의 `SELECT … INTO`가 0행을 돌려주면 **NOT FOUND 핸들러가 켜져** 반복이 일찍 끝나는 함정이 있는데, 여기서는 집계 함수라 항상 1행이므로 안전합니다. 이 문제도 `INSERT … SELECT … GROUP BY … HAVING` 한 문장으로 풀 수 있습니다 — 직접 써서 결과를 비교해 보세요.
