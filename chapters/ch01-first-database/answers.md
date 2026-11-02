# Ch01 실습 — 처음 보는 DB 파악하기 — 정답과 해설

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery01;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> 각 문제의 **기대 결과**와 내 결과가 같으면 정답입니다. (행 순서까지 같아야 하는 문제는 문제에 적어 두었습니다)

---

### 문제 1. 테이블 목록 ★

김 팀장이 "우리 DB에 테이블이 몇 개나 있어요?"라고 묻습니다. `hanip_delivery01`의 테이블 목록을 조회하세요.

**정답 SQL**

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


> **해설** 테이블은 7개입니다. 이름이 모두 **복수형 snake_case**(`order_items`)라는 규칙도 눈여겨보세요. 1146 에러를 피하는 가장 쉬운 방법은 이 규칙을 기억하는 것입니다.

### 문제 2. 고객 테이블 구조 ★

`customers` 테이블의 구조를 확인하고 다음에 답하세요.

1. 기본키 열은?
2. 비워 둘 수 있는(NULL 허용) 열은 몇 개이고 무엇인가?
3. 값을 넣지 않으면 자동으로 채워지는 열과 그 기본값은?

**정답 SQL**

```sql
DESC customers;
```

<sub>▶ 실행 결과 · 10행</sub>

| Field | Type | Null | Key | Default | Extra |
|---|---|---|---|---|---|
| customer_id | int | NO | PRI | NULL | auto_increment |
| name | varchar(20) | NO |  | NULL |  |
| phone | char(13) | NO | UNI | NULL |  |
| email | varchar(100) | YES | UNI | NULL |  |
| birth_date | date | YES |  | NULL |  |
| district | varchar(10) | NO |  | NULL |  |
| address | varchar(100) | NO |  | NULL |  |
| grade | varchar(10) | NO |  | 일반 |  |
| marketing_agreed | tinyint(1) | NO |  | 0 |  |
| joined_at | datetime | NO |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |


> **해설**
> 1. `Key`가 `PRI`인 `customer_id`
> 2. `Null`이 `YES`인 `email`, `birth_date` — 2개. 회원가입 때 선택 입력 항목입니다.
> 3. `grade`(일반), `marketing_agreed`(0 = FALSE), `joined_at`(현재 시각, `CURRENT_TIMESTAMP`)
>
> `phone`과 `email`에 `UNI`가 붙어 있습니다. 같은 전화번호·이메일로 두 번 가입할 수 없다는 뜻입니다.

### 문제 3. 메뉴 미리보기 ★

`menus` 테이블의 모든 열을 **5행만** 조회하세요.

**정답 SQL**

```sql
SELECT * FROM menus LIMIT 5;
```

<sub>▶ 실행 결과 · 5행</sub>

| menu_id | restaurant_id | name | price | description | is_signature | is_sold_out |
|---|---|---|---|---|---|---|
| 1 | 1 | 돼지국밥 | 10000 | 12시간 끓인 사골 육수에 앞다리살 듬뿍 | 1 | 0 |
| 2 | 1 | 순대국밥 | 10000 | NULL | 0 | 0 |
| 3 | 1 | 섞어국밥 | 10500 | 돼지고기 + 순대 + 내장 | 0 | 0 |
| 4 | 1 | 수육 백반 | 13000 | 수육 반 접시 + 국밥 + 공깃밥 | 0 | 0 |
| 5 | 1 | 수육 (중) | 22000 | NULL | 0 | 0 |


### 문제 4. 배달 기사 명단 ★

운영팀이 기사 명단을 요청했습니다. `riders` 테이블에서 **이름, 운송 수단, 주 활동 구, 활동 중 여부**만 조회하세요. (열 이름은 `DESC riders;`로 직접 찾으세요)

**정답 SQL**

```sql
SELECT name, vehicle, district, is_active FROM riders;
```

<sub>▶ 실행 결과 · 8행</sub>

| name | vehicle | district | is_active |
|---|---|---|---|
| 배성진 | 오토바이 | 부산진구 | 1 |
| 노지환 | 오토바이 | 수영구 | 1 |
| 하민호 | 오토바이 | 해운대구 | 1 |
| 전유나 | 자전거 | 부산진구 | 1 |
| 곽태호 | 오토바이 | 남구 | 1 |
| 민경수 | 오토바이 | 연제구 | 0 |
| 엄소희 | 도보 | 중구 | 1 |
| 천동현 | 오토바이 | 사하구 | 1 |


> **해설** `is_active`가 `0`인 기사(민경수)가 한 명 있습니다. `BOOLEAN` 열은 `1`(TRUE) / `0`(FALSE)으로 보입니다. Ch02에서 `WHERE is_active = TRUE`로 활동 중인 기사만 골라냅니다.

### 문제 5. 주문 상세는 몇 줄일까 ★★

수업에서 `orders`는 563행이었습니다. `order_items`는 몇 행인지 세어 보고, 왜 `orders`보다 많은지 한 문장으로 설명하세요.

**정답 SQL**

```sql
SELECT COUNT(*) FROM order_items;
```

<sub>▶ 실행 결과 · 1행</sub>

| COUNT(*) |
|---|
| 1060 |


> **해설** 1,060행. 주문 한 건(`orders` 1행)에 메뉴를 여러 개 담을 수 있고, 메뉴 하나가 `order_items`의 한 줄이 되기 때문입니다. 주문 1건당 평균 약 1.9줄입니다. 이렇게 "머리(orders) 1 : 몸통(order_items) N"으로 나눈 이유는 Ch09에서 정규화로 설명합니다.

### 문제 6. 에러 고치기 ① ★★

신입 동료가 아래 쿼리를 실행했더니 에러가 났습니다. 에러 번호와 원인을 말하고, 고친 쿼리를 작성하세요.

```sql
SELECT name, phone, grade FROM customer LIMIT 3;
```

**정답 SQL**

```sql
SELECT name, phone, grade FROM customers LIMIT 3;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | phone | grade |
|---|---|---|
| 김민준 | 010-2841-5523 | VIP |
| 이서연 | 010-3392-1187 | VIP |
| 박지훈 | 010-4410-7762 | VIP |


> **해설** `Error Code: 1146. Table 'hanip_delivery01.customer' doesn't exist` — 테이블 이름은 복수형 `customers`입니다.

### 문제 7. 에러 고치기 ② ★★

아래 쿼리는 메뉴의 이름과 가격을 보려는 것입니다. 에러 없이 실행되지만 **결과가 이상합니다.** 무엇이 이상한지 설명하고 고치세요.

```sql
SELECT name price FROM menus LIMIT 3;
```

**정답 SQL**

```sql
SELECT name, price FROM menus LIMIT 3;
```

<sub>▶ 실행 결과 · 3행</sub>

| name | price |
|---|---|
| 돼지국밥 | 10000 |
| 순대국밥 | 10000 |
| 섞어국밥 | 10500 |


> **해설** 쉼표가 빠져서 `name price`가 **"`name` 열을 `price`라는 이름으로 보여 줘"**(별칭)로 해석됩니다. 결과에 `price`라는 열 하나만 나오고, 그 안에는 가격이 아니라 메뉴 이름이 들어 있습니다. 에러가 나는 실수보다 **에러가 안 나는 실수**가 더 위험합니다. 결과 열 이름과 값이 기대와 맞는지 항상 확인하세요.

### 문제 8. 탐색 보고서 ★★★

`DESC`와 `SHOW CREATE TABLE`만 사용해 다음 질문에 답하세요. (SQL 답안 없이 서술형)

1. `orders.rider_id`는 왜 NULL을 허용할까? 어떤 주문의 `rider_id`가 비어 있을지 두 가지 경우를 추측해 보세요.
2. `reviews.order_id`에는 `UNI`(중복 불가)가 걸려 있습니다. 이 규칙이 비즈니스적으로 의미하는 것은?
3. 주문의 **총 결제 금액**을 저장하는 열은 어디에 있나요? 없다면 무엇으로 계산할 수 있을까요?

> **해설**
> 1. 기사가 배정되기 **전**인 주문(접수·조리중)과 **취소**된 주문은 배달할 기사가 없습니다. 값이 "아직 없음/해당 없음"일 때 NULL을 씁니다. 실제로 확인하는 쿼리는 Ch02에서 작성합니다.
> 2. **주문 1건에 리뷰는 최대 1개**. 같은 주문으로 리뷰를 두 번 쓸 수 없습니다.
> 3. 저장하는 열은 **없습니다.** `order_items`의 `quantity × unit_price`를 모두 더한 음식 금액에, `orders`의 `delivery_fee`를 더하고 `discount_amount`를 빼서 계산합니다 (Ch04). 계산할 수 있는 값을 따로 저장하면 원본과 어긋날 위험이 생기기 때문입니다.
