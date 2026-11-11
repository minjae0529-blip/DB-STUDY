# Ch09 실습 — 정규화 집중 훈련

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery09;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> 정규화 **전** 시트는 `ex_`로 시작합니다. 여러분이 나눠서 만드는 테이블은 `p_`로 시작합니다.
> **문제를 순서대로 푸세요.** 5번은 3·4번의 판단을, 9번은 8번에서 만든 테이블을 씁니다.
> 다시 처음부터 하고 싶으면 `setup.sql` 위쪽의 `DROP DATABASE` 주석을 풀고 다시 실행하면 됩니다.

| 문제 | 정규형 | 시트 | 하는 일 |
|---|---|---|---|
| 1 · 2 | 1NF | `ex_rider_sheet`, `ex_review_sheet` | 한 칸의 여러 값 / 반복 열을 행으로 펴기 |
| 3 · 4 · 5 | 2NF | `ex_coupon_sheet` | 함수 종속 검증 → 후보키 찾기 → 부분 종속 분해 |
| 6 · 7 | 3NF | `ex_menu_sheet` | 이상 현상 찾기 → 이행 종속 분해 |
| 8 · 9 | BCNF | `ex_inspection_sheet` | 결정자 분해 → 무손실 vs 가짜 튜플 |
| 10 | 판정 | (종이 문제) | 정규형 판정 5문항 — 정보처리기사 유형 |
| 11 | 종합 | `ex_event_sheet` | 비정규형 시트 하나를 끝까지 정규화 |

마지막 **팀 과제**는 정답 SQL이 없는 설계 과제입니다.

---

### 문제 1. 한 칸에 구역 여러 개 — 1NF ★

> **배차팀** `ex_rider_sheet`의 `zones` 칸에 담당 구역이 `'서면, 전포, 범천'`처럼 몰려 있어서 "서면 담당 기사가 누구지?"에 답하기 어렵습니다.
> 기사 · 구역 한 쌍이 한 행인 **`p_rider_zones`** (`rider_name`, `zone`, PK는 두 열 조합)를 만들고, **기사가 2명 이상인 구역**을 보여 주세요.
> 힌트: 수업 5-1절. 한 기사의 구역은 최대 5개입니다.

- 열: `zone`, `rider_count`, `riders` (기사 이름을 가나다순으로 `', '`로 이어 붙임)
- 순서: `zone`

**기대 결과**

<sub>▶ 실행 결과 · 5행</sub>

| zone | rider_count | riders |
|---|---|---|
| 대연 | 2 | 민경수, 엄소희 |
| 범천 | 2 | 배성진, 하민호 |
| 서면 | 2 | 노지환, 배성진 |
| 전포 | 2 | 배성진, 하민호 |
| 해운대 | 2 | 곽태호, 전유나 |



### 문제 2. 사진 1 · 사진 2 · 사진 3 — 반복 열과 1NF ★

> **리뷰팀** 구 앱의 `ex_review_sheet`는 사진을 `photo1`~`photo3` 열에 저장했습니다. "사진 4장"을 허용하려면 열을 또 추가해야 합니다.
> 사진 한 장이 한 행인 **`p_review_photos`** (`review_id`, `sort_order`, `photo_url`, PK는 `review_id` + `sort_order`)를 만들고, **리뷰별 사진 수**를 보여 주세요. 사진이 없는 리뷰도 0으로 나와야 합니다.
> `sort_order`는 원래 열 번호(1, 2, 3)를 그대로 씁니다.

- 열: `review_id`, `customer_name`, `photo_count`
- 순서: `review_id`

**기대 결과**

<sub>▶ 실행 결과 · 8행</sub>

| review_id | customer_name | photo_count |
|---|---|---|
| 801 | 김민준 | 3 |
| 802 | 이서연 | 1 |
| 803 | 박지훈 | 0 |
| 804 | 최수아 | 2 |
| 805 | 정우진 | 1 |
| 806 | 강하은 | 3 |
| 807 | 조현우 | 0 |
| 808 | 윤지아 | 2 |



### 문제 3. 함수 종속 검증 ★★

> **마케팅팀** `ex_coupon_sheet`(쿠폰 사용 장부)에 대해 팀원들이 세 가지를 주장합니다. 각각 **위반하는 결정자 값의 개수**를 구해 참 · 거짓을 판정하세요. (0이면 지금 데이터에서는 성립)
> ① `coupon_code → discount_amount` ② `customer_phone → customer_name` ③ `coupon_name → discount_amount`

- 열: `code_to_discount`, `phone_to_name`, `name_to_discount`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| code_to_discount | phone_to_name | name_to_discount |
|---|---|---|
| 0 | 0 | 1 |



### 문제 4. 후보키 찾기 ★★

> **데이터팀** `ex_coupon_sheet`에는 PK가 없습니다. 업무 규칙은 "**한 고객은 같은 쿠폰을 한 번만 쓴다**"입니다. 아래 조합마다 `COUNT(DISTINCT …)`를 구해 전체 행 수와 비교하세요.
> `coupon_code` / `customer_phone` / (`coupon_code`, `customer_phone`) / (`customer_phone`, `used_at`)

- 열: `total_rows`, `by_code`, `by_phone`, `by_code_phone`, `by_phone_used_at`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| total_rows | by_code | by_phone | by_code_phone | by_phone_used_at |
|---|---|---|---|---|
| 15 | 5 | 10 | 15 | 15 |



### 문제 5. 부분 종속 제거 — 2NF ★★

> **데이터팀** 키 (`coupon_code`, `customer_phone`)의 **일부에만** 종속된 열을 떼어 내세요.
> - `p_coupons` (`coupon_code` PK, `coupon_name`, `discount_amount`)
> - `p_coupon_customers` (`customer_phone` PK, `customer_name`)
> - `p_coupon_uses` (`coupon_code`, `customer_phone`, `used_at`) — PK는 두 열 조합, 두 열 각각 위 테이블을 참조하는 FK
>
> 세 테이블의 행 수를 확인하세요.

- 열: `coupons_rows`, `customers_rows`, `uses_rows`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| coupons_rows | customers_rows | uses_rows |
|---|---|---|
| 5 | 10 | 15 |



### 문제 6. 메뉴 하나 지웠더니 — 이상 현상 ★★

> **운영팀** `ex_menu_sheet`는 메뉴 코드가 PK라서 2NF는 만족합니다(단일 열 키에는 부분 종속이 생길 수 없음). 그래도 사고가 납니다.
> **메뉴 한 개만 지워도** 이 시트에서 **완전히 사라지는 가게와 분류**를 찾아 주세요. (메뉴가 딱 1개뿐인 가게, 딱 1개뿐인 분류)

- 열: `kind` ('가게' 또는 '분류'), `name`, `menu_count`
- 순서: `kind` → `name`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| kind | name | menu_count |
|---|---|---|
| 가게 | 광안리화덕피자 | 1 |
| 분류 | 피자 | 1 |



### 문제 7. 이행 종속 제거 — 3NF ★★

> **운영팀** `ex_menu_sheet`를 3NF로 나누세요. 종속이 **두 단계**로 이어진다는 데 주의합니다.
> - `p_menu_categories` (`category_code` PK, `category_name`)
> - `p_menu_restaurants` (`restaurant_code` PK, `restaurant_name`, `owner_name`, `category_code` FK)
> - `p_menus` (`menu_code` PK, `menu_name`, `price`, `restaurant_code` FK)
>
> 세 테이블을 만든 뒤, 3NF 테이블에 **메뉴 없는 분류 '분식'(`C04`)을 등록**할 수 있는지 확인하고 분류별 메뉴 수를 구하세요.

- 열: `category_code`, `category_name`, `menu_count`
- 순서: `category_code`

**기대 결과**

<sub>▶ 실행 결과 · 4행</sub>

| category_code | category_name | menu_count |
|---|---|---|
| C01 | 한식 | 6 |
| C02 | 일식 | 3 |
| C03 | 피자 | 1 |
| C04 | 분식 | 0 |



### 문제 8. 결정자가 후보키가 아니다 — BCNF ★★

> **안전관리팀** `ex_inspection_sheet`의 규칙은 두 가지입니다.
> - 가게마다 점검 종류별 담당 점검원은 한 명 → PK (`restaurant_name`, `inspection_type`)
> - 점검원은 **한 종류만** 맡는다 → `inspector_name → inspection_type`
>
> ① 두 번째 규칙이 데이터에서 성립하는지 확인하고, ② BCNF로 나누세요.
> - `p_inspectors` (`inspector_name` PK, `inspection_type`)
> - `p_restaurant_inspectors` (`restaurant_name`, `inspector_name`) — PK는 두 열 조합, `inspector_name`은 FK

- 열: `violations` (①), `inspectors_rows`, `assignments_rows`

**기대 결과**

<sub>▶ 실행 결과 · 1행</sub>

| violations | inspectors_rows | assignments_rows |
|---|---|---|
| 0 | 5 | 13 |



### 문제 9. 무손실 분해 vs 가짜 튜플 ★★★

> **데이터팀** 같은 시트를 두 가지로 나눈 뒤 다시 JOIN해 비교합니다.
> - **올바른 분해**: 8번의 `p_inspectors` ⋈ `p_restaurant_inspectors` (`inspector_name`으로 JOIN)
> - **잘못된 분해**: (`restaurant_name`, `inspection_type`)과 (`inspection_type`, `inspector_name`)으로 나누고 `inspection_type`으로 JOIN (테이블을 만들지 말고 CTE로)
>
> 각 방법의 재조립 행 수와, 원래 시트에 **없던** 행(가짜 튜플) 수를 구하세요.

- 열: `method` ('올바른 분해' / '잘못된 분해'), `rebuilt_rows`, `extra_rows`
- 순서: 올바른 분해 → 잘못된 분해

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| method | rebuilt_rows | extra_rows |
|---|---|---|
| 올바른 분해 | 13 | 0 |
| 잘못된 분해 | 22 | 9 |



### 문제 10. 정규형 판정 — 정보처리기사 유형 ★★

> SQL 없이 푸는 문제입니다. 각 릴레이션이 만족하는 **가장 높은 정규형**과 그 이유(위반하는 종속)를 쓰세요. 밑줄은 기본키입니다.
>
> | # | 릴레이션 | 함수 종속 |
> |---|---|---|
> | (가) | 수강(<u>학번</u>, <u>과목코드</u>, 성적) | (학번, 과목코드) → 성적 |
> | (나) | 주문상세(<u>주문번호</u>, <u>메뉴번호</u>, 수량, 주문일시) | (주문번호, 메뉴번호) → 수량 / 주문번호 → 주문일시 |
> | (다) | 가게(<u>가게번호</u>, 가게명, 우편번호, 구) | 가게번호 → 가게명, 우편번호 / 우편번호 → 구 |
> | (라) | 배정(<u>고객</u>, <u>가게</u>, 기사) | (고객, 가게) → 기사 / 기사 → 가게 |
> | (마) | 회원(<u>회원번호</u>, 이름, 전화번호들) | 전화번호들 = `'010-1111-2222, 010-3333-4444'` |
>
> 추가 질문: (나)와 (다)를 각각 한 단계 위 정규형으로 분해한 결과를 릴레이션 표기로 쓰세요.


### 문제 11. 비정규형 시트 하나를 끝까지 — 종합 ★★★

> **마케팅팀** `ex_event_sheet`는 할인 이벤트 참여 시트입니다. PK는 (`event_code`, `restaurant_name`)이고, 할인 메뉴는 한 칸에 몰려 있습니다.
> 함수 종속: `event_code → event_name, discount_rate` / `restaurant_name → restaurant_phone` / (`event_code`, `restaurant_name`) → `joined_at`, `menu_list`
>
> 1NF부터 BCNF까지 정규화해서 아래 네 테이블을 만들고, PK · FK를 모두 거세요.
> - `p_events` (`event_code` PK, `event_name`, `discount_rate`)
> - `p_event_shops` (`restaurant_name` PK, `restaurant_phone`)
> - `p_event_joins` (`event_code`, `restaurant_name`, `joined_at`) — PK 두 열, FK 두 개
> - `p_event_menus` (`event_code`, `restaurant_name`, `menu_name`) — PK 세 열, (`event_code`, `restaurant_name`)은 `p_event_joins`를 참조하는 FK
>
> 마지막으로 **이벤트별 참여 가게 수와 할인 메뉴 수**를 구하세요.

- 열: `event_code`, `event_name`, `discount_rate`, `shop_count`, `menu_count`
- 순서: `event_code`

**기대 결과**

<sub>▶ 실행 결과 · 3행</sub>

| event_code | event_name | discount_rate | shop_count | menu_count |
|---|---|---|---|---|
| E01 | 여름 밀면 페스타 | 10 | 2 | 3 |
| E02 | 야식 대전 | 15 | 3 | 7 |
| E03 | 비 오는 날 전 데이 | 20 | 2 | 3 |



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

**발표 체크리스트**: 왜 이 테이블로 나눴나 · **각 테이블이 BCNF인지와 그 근거**(후보키 · 결정자) · 카디널리티의 근거 · 요구사항 규칙이 어떤 제약조건으로 번역됐나 · 반정규화한 것이 있다면 그 이유

