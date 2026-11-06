# Ch11 실습 — 자동으로 기록하고, 막고, 맞추기

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery11;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 뒤 문제가 앞에서 만든 트리거와 데이터를 씁니다.
> 트리거 본문은 `DELIMITER $$ … END $$ DELIMITER ;`로 감싸야 합니다.
> 수업 중 만든 트리거와 이름이 겹치거나 데이터가 꼬였다면 `setup.sql`의 DROP 줄 주석을 풀고 다시 실행한 뒤 시작하세요.

---

### 문제 1. 등급 변경 이력 ★

> **마케팅팀** 고객 등급이 바뀔 때마다 기록을 남겨 주세요.
> - 테이블 `customer_grade_logs`: `log_id` (PK, AUTO_INCREMENT), `customer_id` (FK), `old_grade`, `new_grade` (VARCHAR(10)), `changed_at` (DATETIME, 기본값 현재 시각)
> - 트리거 `trg_customers_grade_log`: 등급이 **실제로 바뀐 경우만** 기록
>
> 윤서아 님(30번)을 '실버'로 올리고, 이름만 바꾼 경우(30번 이름을 그대로 다시 저장)에는 기록되지 않는지 확인하세요.

- 열: `log_id`, `customer_id`, `old_grade`, `new_grade`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| log_id | customer_id | old_grade | new_grade |
|---|---|---|---|
| 1 | 30 | 일반 | 실버 |



### 문제 2. 리뷰 내용 정리 ★

> **CS팀** 앱에서 공백만 있는 리뷰(`'   '`)가 들어오거나, 앞뒤에 공백이 붙어 들어옵니다. 리뷰가 저장되기 **전에** 앞뒤 공백을 지우고, 지운 결과가 빈 문자열이면 NULL(별점만 남긴 리뷰)로 바꾸는 트리거 `trg_reviews_clean_content`를 만드세요.
>
> 549번 주문에 `'   '`(5점), 531번 주문에 `'  맛있어요  '`(4점) 리뷰를 넣고 확인합니다. 작성 일시는 둘 다 `'2026-06-30 18:50:00'`.

- 열: `order_id`, `rating`, `content`, `content_length` (`CHAR_LENGTH(content)`)
- 순서: `order_id`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| order_id | rating | content | content_length |
|---|---|---|---|
| 531 | 4 | 맛있어요 | 4 |
| 549 | 5 | NULL | NULL |



### 문제 3. 가격 급락 방지 ★★

> **운영팀** 사장님이 가격을 실수로 0 하나 빼고 입력하는 사고(13,000 → 1,300)가 있었습니다. 메뉴 가격을 **기존 가격의 절반 미만**으로 내리려 하면 `'가격을 절반 미만으로 내릴 수 없습니다. 운영팀에 문의하세요.'` 에러를 내는 트리거 `trg_menus_price_guard`를 만드세요.
>
> 정상적인 인하(돼지국밥 10,000 → 9,000)는 통과하는지 확인합니다.

- 열: `menu_id`, `name`, `price`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| menu_id | name | price |
|---|---|---|
| 1 | 돼지국밥 | 9000 |



### 문제 4. 트리거가 한 일도 ROLLBACK된다 ★★

> **마케팅팀** 정우진 님(5번)을 'VIP'로 올렸다가 착오임을 알고 되돌립니다. 트랜잭션 안에서 등급을 바꾼 뒤 ROLLBACK하고, 등급과 **1번의 이력 테이블 행 수**가 모두 원래대로인지 확인하세요.

- 열: `grade`, `log_count`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| grade | log_count |
|---|---|
| 골드 | 1 |



### 문제 5. 기사 배달 건수 ★★

> **정산팀** 기사별 배달 완료 건수를 `riders.delivery_count`에 저장하고 트리거로 유지해 주세요.
> 1. `delivery_count INT NOT NULL DEFAULT 0` 열 추가, 지금까지의 배달완료 건수로 초기값 채우기
> 2. 트리거 `trg_orders_rider_count`: 주문 상태가 **'배달완료'로 바뀌는 순간** 그 주문의 기사 건수 +1
>
> 배달중인 561번 주문(4번 기사)을 배달완료로 바꾸고 확인하세요.

- 열: `rider_id`, `name`, `delivery_count`, `actual_count` (orders에서 직접 센 배달완료 건수)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| rider_id | name | delivery_count | actual_count |
|---|---|---|---|
| 4 | 전유나 | 51 | 51 |



### 문제 6. 쿠폰 보호 ★★

> **개발팀** 쿠폰 사용 표시(`customer_coupons.used_order_id`)에 두 가지 규칙을 걸어 주세요. 트리거 이름은 `trg_customer_coupons_guard`.
> - 이미 사용한 쿠폰을 **다른 주문으로** 바꾸면 `'이미 사용한 쿠폰입니다.'` (사용 취소, 즉 NULL로 되돌리는 것은 허용)
> - 쿠폰 만료 시각(`expires_at`)보다 **나중에 주문한** 주문에 쓰려 하면 `'만료된 쿠폰입니다.'`
>
> 정우진 님(5번)의 주말 쿠폰(2번)을 그의 563번 주문(6월 30일 18:47)에 사용 처리하고 확인하세요.

- 열: `customer_id`, `coupon_id`, `expires_at`, `used_order_id`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| customer_id | coupon_id | expires_at | used_order_id |
|---|---|---|---|
| 5 | 2 | 2026-07-04 00:00:00 | 563 |



### 문제 7. 주문 취소하면 쿠폰 복구 ★★★

> **CS팀** 쿠폰을 쓴 주문이 **취소되면 쿠폰을 자동으로 돌려주는** 트리거 `trg_orders_restore_coupon`을 만드세요.
>
> 그다음 윤서아 님(30번)의 첫 주문을 Ch08처럼 **트랜잭션**으로 접수합니다: 광안리브런치카페(14번 가게)에서 에그 베네딕트(63번) 1개 + 아메리카노(66번) 1개, 배달팁 3,000원, 신규 쿠폰(1번, 3,000원 할인), 카드, 주문 시각 `'2026-06-30 19:10:00'`. 쿠폰 표시가 1행 바뀌면 COMMIT합니다. 이후 고객이 주문을 취소하면 쿠폰이 돌아오는지 확인하세요.

- 결과: 취소 후 윤서아 님의 쿠폰 행 (`customer_id`, `coupon_id`, `used_order_id`)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| customer_id | coupon_id | used_order_id |
|---|---|---|
| 30 | 1 | NULL |



### 문제 8. 가게 리뷰 통계 완성판 ★★★

> **운영팀** 수업에서 만든 가게 리뷰 통계를 **INSERT · UPDATE · DELETE 세 경우 모두** 맞도록 완성하세요.
> 1. `restaurants`에 `review_count`, `rating_sum` 열 추가 (INT, NOT NULL, 기본 0) 후 현재 리뷰로 초기값 채우기
> 2. 트리거 세 개: `trg_reviews_stats_insert` · `trg_reviews_stats_update` · `trg_reviews_stats_delete`
> 3. UPDATE 트리거는 별점이 바뀐 경우 차이만큼 `rating_sum`을 조정
>
> 2번 문제에서 549번 주문에 단 리뷰(5점)를 고객 요청으로 **1점**으로 수정하고, 서면옛날돼지국밥(1번 가게)의 통계를 확인하세요.

- 열: `restaurant_id`, `review_count`, `rating_sum`, `avg_rating` (소수 둘째 자리)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| restaurant_id | review_count | rating_sum | avg_rating |
|---|---|---|---|
| 1 | 26 | 112 | 4.31 |



### 문제 9. 통계가 정말 맞는지 검증 ★★

> **데이터팀** 리뷰를 하나 더 넣고(486번 주문, 3점, 내용 `'보통이에요'`, `'2026-06-30 18:55:00'`), 리뷰 1번을 삭제한 뒤, 모든 가게의 `review_count` · `rating_sum`이 실제 리뷰와 일치하는지 검증하세요.

- 열: `mismatched_restaurants`, `total_reviews` (reviews 행 수), `total_count` (restaurants.review_count 합계)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| mismatched_restaurants | total_reviews | total_count |
|---|---|---|
| 0 | 262 | 262 |



### 문제 10. 내가 만든 트리거 목록 ★

> **개발팀** 지금 DB에 있는 트리거 전체를 테이블 · 이벤트 · 시점 순으로 정리해 주세요. 새로 온 개발자에게 넘길 문서의 재료입니다.

- 열: `table_name`, `event`, `timing`, `trigger_name`
- 순서: `table_name` → `event` → `timing` → `trigger_name`

**기대 결과**

<sub>▶ 실행 결과 · 9행</sub>

| table_name | event | timing | trigger_name |
|---|---|---|---|
| customer_coupons | UPDATE | BEFORE | trg_customer_coupons_guard |
| customers | UPDATE | AFTER | trg_customers_grade_log |
| menus | UPDATE | BEFORE | trg_menus_price_guard |
| orders | UPDATE | AFTER | trg_orders_restore_coupon |
| orders | UPDATE | AFTER | trg_orders_rider_count |
| reviews | INSERT | BEFORE | trg_reviews_clean_content |
| reviews | INSERT | AFTER | trg_reviews_stats_insert |
| reviews | UPDATE | AFTER | trg_reviews_stats_update |
| reviews | DELETE | AFTER | trg_reviews_stats_delete |


