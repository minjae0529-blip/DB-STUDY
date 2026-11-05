# Ch10 실습 — 저장하고, 빠르게, 안전하게

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery10;` · **root로 접속** (계정 문제 9·10번)
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 7번은 6번의 인덱스를 씁니다.
> 수업 중 만든 뷰·인덱스와 이름이 겹치면 `1050`(이미 있음) 에러가 납니다. 그럴 땐 `setup.sql`의 DROP 줄 주석을 풀고 다시 실행한 뒤 시작하세요.

---

### 문제 1. 가게 평점 뷰 ★

> **마케팅팀** 가게별 리뷰 수와 평균 별점을 `v_restaurant_ratings` 뷰로 만들어 주세요. 그다음 뷰에서 **평균 별점 상위 3곳**을 조회합니다.
> - 뷰 열: `restaurant_id`, `restaurant_name`, `review_count`, `avg_rating` (소수 둘째 자리 반올림)
> - 리뷰가 없는 가게는 뷰에 나오지 않아도 됩니다.

- 조회 열: `restaurant_name`, `review_count`, `avg_rating`
- 순서: `avg_rating` 내림차순 → `review_count` 내림차순, 3행

**기대 결과**

<sub>▶ 실행 결과 · 3행</sub>

| restaurant_name | review_count | avg_rating |
|---|---|---|
| 해운대스시하루 | 14 | 4.57 |
| 서면옛날돼지국밥 | 24 | 4.46 |
| 전포카츠 | 28 | 4.43 |



### 문제 2. 기사 공개 뷰 ★

> **CS팀** 고객 문의 응대용으로 기사 정보를 보여 주되, **이름은 가운데를 가리고**(`김민수` → `김*수`) 전화번호는 빼서 `v_riders_public` 뷰로 만들어 주세요.

- 뷰 열: `rider_id`, `name_masked`, `vehicle`, `district`, `is_active`
- 조회: 뷰 전체, `rider_id` 순

**기대 결과**

<sub>▶ 실행 결과 · 8행</sub>

| rider_id | name_masked | vehicle | district | is_active |
|---|---|---|---|---|
| 1 | 배*진 | 오토바이 | 부산진구 | 1 |
| 2 | 노*환 | 오토바이 | 수영구 | 1 |
| 3 | 하*호 | 오토바이 | 해운대구 | 1 |
| 4 | 전*나 | 자전거 | 부산진구 | 1 |
| 5 | 곽*호 | 오토바이 | 남구 | 1 |
| 6 | 민*수 | 오토바이 | 연제구 | 0 |
| 7 | 엄*희 | 도보 | 중구 | 1 |
| 8 | 천*현 | 오토바이 | 사하구 | 1 |



### 문제 3. 뷰 위에 쿼리 쌓기 ★★

> **정산팀** 수업에서 만든 것과 같은 `v_order_amounts` 뷰(주문별 `food_amount`, `delivery_fee`, `discount_amount`, `total_amount`)를 이 DB에 만들고, 그 뷰를 이용해 **6월 배달완료 결제 총액 상위 5명**을 뽑아 주세요.

- 열: `customer_name`, `orders`, `total_paid`
- 순서: `total_paid` 내림차순, 5행

**기대 결과**

<sub>▶ 실행 결과 · 5행</sub>

| customer_name | orders | total_paid |
|---|---|---|
| 임도현 | 8 | 316000 |
| 배수빈 | 6 | 264000 |
| 김민준 | 8 | 262500 |
| 이서연 | 8 | 247500 |
| 박지훈 | 6 | 221500 |



### 문제 4. 조건을 지키는 뷰 ★★

> **운영팀** 판매 중인 메뉴만 보이는 `v_menus_on_sale` 뷰(`menu_id`, `restaurant_id`, `name`, `price`, `is_sold_out`, 조건 `is_sold_out = FALSE`)를 `WITH CHECK OPTION`으로 만드세요. 그다음 이 뷰를 통해 **장전동든든김밥 든든김밥**(`menu_id = 51`)의 가격을 4,500원으로 바꾸고, 원본 `menus`에서 확인합니다.

- 열: `menu_id`, `name`, `price`, `is_sold_out` (원본 `menus`에서)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price | is_sold_out |
|---|---|---|---|
| 51 | 든든김밥 | 4500 | 0 |



### 문제 5. 이미 있는 인덱스 ★

> **개발팀** `order_items` 테이블에 어떤 인덱스가 있는지 `information_schema.statistics`에서 조회하고, 각 인덱스가 **왜 생겼는지**(PK / UNIQUE / FK) 설명해 주세요.

- 열: `index_name`, `column_name`, `seq_in_index`, `non_unique`
- 순서: `index_name` → `seq_in_index`

**기대 결과**

<sub>▶ 실행 결과 · 4행</sub>

| index_name | column_name | seq_in_index | non_unique |
|---|---|---|---|
| fk_order_items_menu | menu_id | 1 | 1 |
| PRIMARY | order_item_id | 1 | 0 |
| uq_order_items | order_id | 1 | 0 |
| uq_order_items | menu_id | 2 | 0 |



### 문제 6. EXPLAIN 전후 비교 ★★

> **CS팀** "6월 이후 리뷰" 조회가 자주 쓰입니다. 먼저 아래 쿼리의 `EXPLAIN`을 확인한 뒤, `reviews.created_at`에 `idx_reviews_created_at` 인덱스를 만들고 다시 `EXPLAIN` 하세요.
> ```sql
> SELECT review_id, rating, created_at FROM reviews WHERE created_at >= '2026-06-01';
> ```

- 결과: 인덱스 생성 **후**의 `EXPLAIN` (`type`, `key`, `rows`를 확인)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | reviews | NULL | range | idx_reviews_created_at | idx_reviews_created_at | 5 | NULL | 49 | 100.00 | Using index condition |



### 문제 7. 인덱스를 살리는 쿼리 ★★

> **CS팀** 다른 직원이 같은 조회를 이렇게 썼습니다. 인덱스를 못 쓰는 이유를 설명하고, **결과는 같으면서 인덱스를 쓰도록** 고친 쿼리의 `EXPLAIN`을 보여 주세요.
> ```sql
> SELECT review_id, rating, created_at FROM reviews
> WHERE YEAR(created_at) = 2026 AND MONTH(created_at) = 6;
> ```

- 결과: 고친 쿼리의 `EXPLAIN`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | reviews | NULL | range | idx_reviews_created_at | idx_reviews_created_at | 5 | NULL | 49 | 100.00 | Using index condition |



### 문제 8. 정렬까지 인덱스로 ★★★

> **개발팀** 앱의 "최근 주문 5건" 화면 쿼리입니다. `EXPLAIN`의 `Extra`를 보면 `Using filesort`(별도 정렬)가 있습니다. 조건 열과 정렬 열을 함께 담은 복합 인덱스 `idx_orders_customer_date`를 만들어 **정렬 작업을 없애고**, 다시 `EXPLAIN` 하세요.
> ```sql
> SELECT order_id, status, ordered_at FROM orders
> WHERE customer_id = 1 ORDER BY ordered_at DESC LIMIT 5;
> ```

- 결과: 인덱스 생성 **후**의 `EXPLAIN` (`key`, `Extra` 확인)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | ref | idx_orders_customer_date | idx_orders_customer_date | 4 | const | 52 | 100.00 | Backward index scan |



### 문제 9. 읽기 전용 분석가 계정 ★★

> **데이터팀** 분석가용 계정 `hanip_analyst`@`localhost`(비밀번호 `Analyst!2026`)를 만들고, 이 DB의 **모든 테이블·뷰를 읽기만** 할 수 있게 해 주세요. 이미 있으면 지우고 새로 만듭니다.

- 결과: `SHOW GRANTS FOR 'hanip_analyst'@'localhost';`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| Grants for hanip_analyst@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_analyst`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.* TO `hanip_analyst`@`localhost` |



### 문제 10. CS 상담원 역할 ★★★

> **CS팀** 상담원 여러 명이 같은 권한을 쓰도록 역할 `hanip_cs`를 만들어 주세요.
> - `orders` 테이블: 조회 가능, 단 수정은 **`status` 열만** (주문 취소 처리용)
> - 기사 정보는 2번에서 만든 `v_riders_public` 뷰만 조회
>
> 상담원 계정 `hanip_cs01`@`localhost`(비밀번호 `Cs01!2026`)에 역할을 주고 **기본 역할로 설정**한 뒤, 역할을 포함한 권한을 확인하세요. 역할·계정이 이미 있으면 지우고 새로 만듭니다.

- 결과: `SHOW GRANTS FOR 'hanip_cs01'@'localhost' USING 'hanip_cs';`

**기대 결과**

<sub>▶ 실행 결과 · 4행</sub>

| Grants for hanip_cs01@localhost |
|---|
| GRANT USAGE ON *.* TO `hanip_cs01`@`localhost` |
| GRANT SELECT, UPDATE (`status`) ON `hanip_delivery10`.`orders` TO `hanip_cs01`@`localhost` |
| GRANT SELECT ON `hanip_delivery10`.`v_riders_public` TO `hanip_cs01`@`localhost` |
| GRANT `hanip_cs`@`%` TO `hanip_cs01`@`localhost` |


