# Ch09 실습 — 나누고, 검증하고, 설계하기

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery09;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 6~8번은 앞 문제에서 만든 테이블을 씁니다.
> 수업 중 만든 `nf_` 테이블과 겹치지 않도록 실습 테이블은 `p_`로 시작합니다.
> 다시 처음부터 하고 싶으면 `setup.sql` 위쪽의 `DROP DATABASE` 주석을 풀고 다시 실행하면 됩니다.
> 마지막 **팀 과제**는 정답 SQL이 없는 설계 과제입니다.

---

### 문제 1. 카디널리티 확인 ★

> **데이터팀** ERD에서 `riders |o--o{ orders`, `menus ||--o{ order_items`라고 그렸습니다. 선 끝의 `o`(0 허용)가 실제 데이터에서도 맞는지 확인해 주세요.
> ① **기사가 배정되지 않은 주문** 수 ② **한 번도 주문되지 않은 메뉴** 수

- 열: `orders_without_rider`, `menus_never_ordered`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| orders_without_rider | menus_never_ordered |
|---|---|
| 51 | 4 |



### 문제 2. 1NF의 힘 ★

> **정산팀** `order_flat`(메뉴 한 줄 = 한 행)에서 6월 **판매 수량 상위 5개 메뉴**를 뽑아 주세요. `order_sheet`로는 할 수 없던 일입니다.
> 힌트: 메뉴 이름만으로는 가게가 정해지지 않으니 가게 이름과 함께 묶으세요.

- 열: `restaurant_name`, `menu_name`, `total_qty`
- 순서: `total_qty` 내림차순 → `restaurant_name` → `menu_name`, 5행

**기대 결과**

<sub>▶ 실행 결과 · 5행</sub>

| restaurant_name | menu_name | total_qty |
|---|---|---|
| 장전동든든김밥 | 든든김밥 | 18 |
| 광안리화덕피자 | 마르게리타 | 12 |
| 하단버거스탠드 | 클래식 치즈버거 | 11 |
| 대연동크런치치킨 | 감자튀김 | 10 |
| 서면옛날돼지국밥 | 돼지국밥 | 10 |



### 문제 3. 함수 종속 검증 ★★

> **데이터팀** "(가게, 메뉴) → 단가" 종속이 성립하는지 두 범위에서 확인해 주세요.
> ① `order_flat`(6월)에서 (`restaurant_name`, `menu_name`)이 같은데 `unit_price`가 2개 이상인 조합 수
> ② 전체 기간 `order_items`에서 `menu_id`가 같은데 `unit_price`가 2개 이상인 메뉴 수

- 열: `june_violations`, `all_time_violations`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| june_violations | all_time_violations |
|---|---|
| 0 | 6 |



### 문제 4. 갱신 이상 재현 ★★

> **CS팀** 김민준 님이 전화번호를 `010-2841-0000`으로 바꿨습니다. 상담원이 `order_flat`에서 **457번 주문만** 고쳤다고 가정하고, 트랜잭션 안에서 재현한 뒤 김민준 님의 전화번호가 몇 개로 보이는지 확인하고 **ROLLBACK**하세요.

- 열: `customer_phone`, `line_count` (ROLLBACK 전)
- 순서: `customer_phone`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| customer_phone | line_count |
|---|---|
| 010-2841-0000 | 1 |
| 010-2841-5523 | 13 |



### 문제 5. 삭제 이상 후보 찾기 ★★

> **데이터팀** `order_flat`에서 주문 **한 건만** 지워도 주문장에서 완전히 사라지는 **가게**와 **고객**을 찾아 주세요. (6월 주문이 딱 1건인 가게·고객)

- 열: `kind` ('가게' 또는 '고객'), `name`
- 순서: `kind` → `name`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| kind | name |
|---|---|
| 가게 | 해운대스시하루 |
| 고객 | 송재원 |



### 문제 6. 2NF로 분해 ★★

> **데이터팀** `order_flat`에서 `order_id`에만 종속된 열을 떼어 `p_orders`를, 나머지로 `p_order_items`를 만드세요. 각각 PK를 걸고 행 수를 확인합니다.
> - `p_orders`: `order_id`, `ordered_at`, `customer_phone`, `customer_name`, `customer_grade`, `restaurant_name`, `restaurant_phone`, `delivery_fee` / PK `order_id`
> - `p_order_items`: `order_id`, `menu_name`, `quantity`, `unit_price` / PK (`order_id`, `menu_name`)

- 열: `orders_rows`, `items_rows`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| orders_rows | items_rows |
|---|---|
| 97 | 178 |



### 문제 7. 3NF로 분해 ★★

> **데이터팀** `p_orders`에서 이행 종속을 없애세요.
> - `p_customers` (`customer_phone` PK, `customer_name`, `customer_grade`)
> - `p_restaurants` (`restaurant_name` PK, `restaurant_phone`)
> - `p_orders`에서 `customer_name`, `customer_grade`, `restaurant_phone` 열 삭제

- 열: `customers_rows`, `restaurants_rows`, `orders_columns` (`p_orders`의 남은 열 수)

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| customers_rows | restaurants_rows | orders_columns |
|---|---|---|
| 22 | 13 | 5 |



### 문제 8. 무손실 분해 검증 ★★★

> **데이터팀** 6·7번에서 나눈 네 테이블을 JOIN해 `order_flat`과 비교하세요. **양쪽 방향**으로 확인합니다.
> ① `order_flat`에는 있는데 재조립 결과에는 없는 행 수 ② 재조립 결과에는 있는데 `order_flat`에는 없는 행 수
> 비교 열: `order_id`, `menu_name`, `customer_name`, `customer_grade`, `restaurant_phone`, `quantity`, `unit_price`

- 열: `lost_rows`, `extra_rows`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| lost_rows | extra_rows |
|---|---|
| 0 | 0 |



### 문제 9. 반정규화가 필요한 이유 ★★

> **정산팀** 해운대명가밀면 **물밀면**(`menu_id = 11`)의 전체 기간 배달완료 매출을 ① 실제 판매가(`unit_price`)와 ② 현재 메뉴 가격(`menus.price`)으로 각각 계산하고, 판매가별 판매 줄 수도 함께 보여 주세요.

- 열: `unit_price`, `line_count`, `real_sales`, `sales_by_current_price`
- 순서: `unit_price`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| unit_price | line_count | real_sales | sales_by_current_price |
|---|---|---|---|
| 8000 | 12 | 144000 | 162000 |
| 9000 | 5 | 54000 | 54000 |



### 문제 10. 메뉴 옵션 설계 ★★★

> **개발팀** "밥 추가 +1,000원", "고기 추가 +3,000원" 같은 **메뉴 옵션** 기능을 설계해 주세요.
> - `menu_options`: `option_id` (PK, AUTO_INCREMENT), `menu_id` (FK → menus), `name` VARCHAR(30), `extra_price` INT (0 이상, 기본 0). 한 메뉴 안에서 옵션 이름 중복 불가
> - `order_item_options`: 주문 줄 ↔ 옵션 M:N 연결 테이블. `order_item_id` (FK → order_items), `option_id` (FK → menu_options), PK는 두 열 조합 (식별 관계)
>
> 돼지국밥(`menu_id = 1`)에 옵션 3개(밥 추가 1000, 고기 추가 3000, 다대기 빼기 0)를 등록하고, **457번 주문의 돼지국밥 줄**에 "밥 추가"와 "고기 추가"를 붙인 뒤, 그 줄의 옵션 포함 금액을 확인하세요.
> 힌트: 주문 줄 번호를 모르므로 `INSERT … SELECT`로 `order_items`와 `menu_options`를 JOIN해서 넣습니다.

- 열: `menu_name`, `quantity`, `unit_price`, `option_names`, `option_price`, `line_total`
- `option_names`: 옵션 이름을 `option_id` 순으로 `', '`로 이어 붙임 / `line_total` = (단가 + 옵션 금액 합) × 수량

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| menu_name | quantity | unit_price | option_names | option_price | line_total |
|---|---|---|---|---|---|
| 돼지국밥 | 2 | 10000 | 밥 추가, 고기 추가 | 4000 | 28000 |



---

## 팀 과제 — 기능 추가 ERD (3~4인, 25분 + 발표 3분)

다음 중 **하나**를 골라 설계하세요.

| 주제 | 요구사항 |
|---|---|
| ① 찜하기 | 고객은 가게를 찜할 수 있다. 같은 가게를 두 번 찜할 수 없다. 찜한 날짜를 보여 준다. 찜 해제 가능 |
| ② 가게 휴무일 | 가게는 정기 휴무 요일(여러 개)과 임시 휴무일(날짜, 사유)을 등록한다. 같은 날 임시 휴무 중복 불가 |
| ③ 라이더 정산 | 기사는 배달 1건마다 배달료를 받는다. 주 단위로 정산하며, 정산 1건에 여러 배달이 묶인다. 배달 하나는 한 번만 정산 |

**제출물**
1. 요구사항 문장 3개 이상 (명사·동사에 밑줄)
2. ERD — Workbench 또는 mermaid. 카디널리티(`||`, `o|`, `|{`, `o{`) 표시
3. DDL — PK·FK·UNIQUE·CHECK 이름 붙여서, `hanip_delivery09`에서 실제 실행
4. 샘플 데이터 INSERT 3행 이상 + 규칙 위반 INSERT 1개(에러 확인)
5. 확인 쿼리 1개 (예: "찜이 가장 많은 가게 TOP 3")

**발표 체크리스트**: 왜 이 테이블로 나눴나 · 카디널리티의 근거 · 요구사항 규칙이 어떤 제약조건으로 번역됐나 · 반정규화한 것이 있다면 그 이유

