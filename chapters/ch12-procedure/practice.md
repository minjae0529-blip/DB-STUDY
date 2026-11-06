# Ch12 실습 — 조건, 반복, 예외, 트랜잭션

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery12;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 프로시저를 고칠 때는 `DROP PROCEDURE IF EXISTS 이름;` 후 다시 만듭니다.
> 수업 중 만든 프로시저·테이블과 이름이 겹치면 `setup.sql`의 DROP 줄 주석을 풀고 다시 실행한 뒤 시작하세요.

---

### 문제 1. 가게 메뉴판 ★

> **운영팀** 가게 번호를 받아 그 가게의 메뉴를 **가격 높은 순**으로 보여 주는 프로시저 `sp_menu_list`를 만들고, 해운대명가밀면(3번)으로 실행하세요.

- 열: `menu_id`, `name`, `price`, `is_sold_out`
- 순서: `price` 내림차순 → `menu_id`

**기대 결과**

<sub>▶ 실행 결과 · 4행</sub>

| menu_id | name | price | is_sold_out |
|---|---|---|---|
| 13 | 회밀면 | 11000 | 0 |
| 11 | 물밀면 | 9000 | 0 |
| 12 | 비빔밀면 | 9000 | 0 |
| 14 | 왕만두 (6개) | 7000 | 0 |



### 문제 2. OUT 파라미터 ★

> **정산팀** 가게 번호를 받아 **6월 배달완료** 주문 수와 음식 매출을 OUT 파라미터로 돌려주는 `sp_restaurant_june(IN p_restaurant_id, OUT p_orders, OUT p_food_sales)`를 만드세요. 서면옛날돼지국밥(1번)으로 실행합니다.

- 열: `orders`, `food_sales`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| orders | food_sales |
|---|---|
| 7 | 241000 |



### 문제 3. 배달팁 함수 ★★

> **개발팀** 가게와 음식 금액을 받아 실제 배달팁을 돌려주는 **함수** `fn_delivery_fee(p_restaurant_id, p_food_amount)`를 만드세요.
> - 음식 금액 30,000원 이상: 무료(0원)
> - 20,000원 이상: 가게 기본 배달팁에서 1,000원 할인 (0원 미만은 0원)
> - 그 외: 가게 기본 배달팁
>
> 광안리화덕피자(4번, 기본 3,500원)에 15,000 · 25,000 · 35,000원을 넣어 확인하세요.

- 열: `fee_15000`, `fee_25000`, `fee_35000`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| fee_15000 | fee_25000 | fee_35000 |
|---|---|---|
| 3500 | 2500 | 0 |



### 문제 4. 다음 상태 — CASE 문 ★★

> **운영팀** 주문 번호를 받아 **다음 상태**를 알려 주는 `sp_next_status(IN p_order_id, OUT p_next)`를 `CASE` 문으로 만드세요. 접수 → 조리중 → 배달중 → 배달완료, 배달완료와 취소는 `'변경 불가'`, 없는 주문은 `'없는 주문'`.
>
> 563번(접수), 561번(배달중), 1번(배달완료), 9999번으로 확인하세요.

- 열: `order_563`, `order_561`, `order_1`, `order_9999`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| order_563 | order_561 | order_1 | order_9999 |
|---|---|---|---|
| 조리중 | 배달완료 | 변경 불가 | 없는 주문 |



### 문제 5. 월별 매출표 — WHILE ★★

> **정산팀** 연도와 시작·끝 월을 받아 월별 배달완료 주문 수와 음식 매출을 `month_sales` 테이블(`sales_month` CHAR(7) PK, `orders`, `food_sales`)에 채우는 `sp_fill_month_sales(IN p_year, IN p_from_month, IN p_to_month)`를 `WHILE`로 만드세요. 같은 달을 다시 실행하면 **덮어써야** 합니다. 2026년 1~6월로 실행하고 표를 확인하세요.

- 열: `sales_month`, `orders`, `food_sales`
- 순서: `sales_month`

**기대 결과**

<sub>▶ 실행 결과 · 6행</sub>

| sales_month | orders | food_sales |
|---|---|---|
| 2026-01 | 74 | 2523400 |
| 2026-02 | 70 | 2079100 |
| 2026-03 | 73 | 2116800 |
| 2026-04 | 91 | 2879800 |
| 2026-05 | 106 | 3157700 |
| 2026-06 | 97 | 2920100 |



### 문제 6. 나눠서 지우기 — REPEAT ★★

> **개발팀** 리뷰를 복사한 보관 테이블 `reviews_archive`를 만들고(`CREATE TABLE … AS SELECT`), 지정한 개수씩 나눠 지우는 `sp_purge_reviews_archive(IN p_batch, OUT p_rounds)`를 `REPEAT`로 만드세요. 100개씩 지우면 몇 번 반복하는지 확인합니다.

- 열: `rounds`, `remaining`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| rounds | remaining |
|---|---|
| 4 | 0 |



### 문제 7. 중복 발급은 표시만 — CONTINUE HANDLER ★★

> **마케팅팀** 쿠폰을 발급하는 `sp_issue_coupon(IN p_customer_id, IN p_coupon_id, IN p_issued_at, OUT p_result)`를 만드세요.
> - 만료 시각 = 발급 시각 + 쿠폰의 `valid_days`일
> - 이미 같은 쿠폰을 가진 고객이면(1062, `uq_cc_customer_coupon`) **에러 대신** `p_result = '이미 보유한 쿠폰'`
> - 성공하면 `'발급 완료'`
>
> 조현우 님(7번)에게 불편 보상 쿠폰(4번)을 `'2026-06-30 10:00:00'`에 두 번 발급해 보세요.

- 열: `first_try`, `second_try`, `coupon_rows` (조현우 님의 4번 쿠폰 행 수)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| first_try | second_try | coupon_rows |
|---|---|---|
| 발급 완료 | 이미 보유한 쿠폰 | 1 |



### 문제 8. 가격 변경 검증 — SIGNAL ★★★

> **운영팀** 메뉴 가격 변경을 프로시저로만 하기로 했습니다. `sp_change_price(IN p_menu_id, IN p_new_price)`를 만드세요.
> - 없는 메뉴: `SIGNAL` 메시지 `'없는 메뉴입니다.'`, 에러 번호 5101
> - 0원 이하: `'가격은 0원보다 커야 합니다.'`, 5102
> - 기존 가격 대비 **30% 넘게** 오르거나 내리면: `'한 번에 30% 넘게 바꿀 수 없습니다.'`, 5103
>
> 물밀면(11번)을 9,000원에서 10,000원으로 바꾸고 확인하세요.

- 열: `menu_id`, `name`, `price`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price |
|---|---|---|
| 11 | 물밀면 | 10000 |



### 문제 9. 주문 취소 — 트랜잭션 + EXIT HANDLER + 기록 ★★★

> **CS팀** 주문 취소를 한 번에 처리하는 `sp_cancel_order(IN p_order_id, OUT p_result)`를 만드세요.
> 1. 실패 기록용 `error_logs` 테이블 (`log_id` PK AUTO_INCREMENT, `proc_name` VARCHAR(64), `error_code` INT, `error_message` VARCHAR(500), `logged_at` DATETIME 기본값 현재 시각)
> 2. 트랜잭션 안에서: 주문을 `SELECT … FOR UPDATE`로 잠그고 → 없는 주문이면 `'없는 주문입니다.'`(5201), 상태가 '접수' · '조리중'이 아니면 `'이미 조리가 끝나 취소할 수 없습니다.'`(5202) → 상태를 '취소'로 → 그 주문에 쓴 쿠폰 되돌리기 → 고객에게 불편 보상 쿠폰(4번) 발급 (`'2026-06-30 19:30:00'`, 30일)
> 3. 어떤 에러든 **ROLLBACK 후 error_logs에 기록**, `p_result = '실패: 메시지'`. 성공하면 `'취소 완료'`
>
> 563번(접수), 561번(배달중), 9999번을 차례로 취소해 보세요.

- 열: `result_563`, `result_561`, `result_9999`, `status_563`, `error_count`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| result_563 | result_561 | result_9999 | status_563 | error_count |
|---|---|---|---|---|
| 취소 완료 | 실패: 이미 조리가 끝나 취소할 수 없습니다. | 실패: 없는 주문입니다. | 취소 | 2 |



### 문제 10. 평점 낮은 가게 찾기 — 커서 + LOOP ★★★

> **운영팀** 커서로 가게를 하나씩 돌며, **영업 중인** 가게 중 리뷰가 `p_min_reviews`개 이상이고 평균 별점이 `p_threshold` 미만인 곳을 `restaurant_alerts` 테이블(`restaurant_id` PK, `review_count`, `avg_rating` DECIMAL(3,2), `message` VARCHAR(100))에 기록하는 `sp_flag_low_rating(IN p_min_reviews, IN p_threshold, OUT p_flagged)`를 만드세요. 폐업한 가게는 `ITERATE`로 건너뜁니다. 메시지는 `'평균 3.38점 — 품질 점검 필요'` 형식.
>
> 리뷰 5개 이상, 3.5점 미만으로 실행하세요.

- 결과: `restaurant_alerts` 전체 + 가게 이름 (`restaurant_id`, `name`, `review_count`, `avg_rating`, `message`), `restaurant_id` 순

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| restaurant_id | name | review_count | avg_rating | message |
|---|---|---|---|---|
| 5 | 남천동마라공방 | 13 | 3.38 | 평균 3.38점 — 품질 점검 필요 |
| 10 | 하단버거스탠드 | 15 | 3.27 | 평균 3.27점 — 품질 점검 필요 |


