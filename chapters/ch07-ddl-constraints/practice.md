# Ch07 실습 — 테이블 설계하고 만들기

> 전제: 이 챕터의 `setup.sql` 실행 완료 · `USE hanip_delivery07;`
> 난이도: ★ 기초 · ★★ 응용 · ★★★ 도전
> **문제를 순서대로 푸세요.** 뒤 문제가 앞 문제에서 만든 테이블을 씁니다.
> 다시 처음부터 하고 싶으면 `setup.sql` 위쪽의 `DROP DATABASE` 주석을 풀고 다시 실행하면 됩니다.
> DDL 문제의 "기대 결과"는 만든 뒤 확인용 SELECT의 결과입니다. 열 이름·타입·제약 이름은 문제에 적힌 대로 쓰세요.

---

### 문제 1. NULL을 허용하는 열 ★

> **개발팀** `orders` 테이블에서 **NULL을 허용하는 열**이 무엇인지 목록으로 주세요. `information_schema.columns`를 쓰세요.
> 힌트: `table_schema = DATABASE()`, `table_name = 'orders'`, `is_nullable = 'YES'`

- 열: `column_name`, `data_type`
- 순서: 테이블 정의 순서(`ordinal_position`)

**기대 결과**

<sub>▶ 실행 결과 · 3행</sub>

| column_name | data_type |
|---|---|
| rider_id | int |
| request_note | varchar |
| delivered_at | datetime |



### 문제 2. CHECK 제약조건 읽기 ★

> **개발팀** `orders` 테이블에 걸린 **CHECK 제약조건의 이름**을 `information_schema.table_constraints`에서 조회하세요. 그다음 `SHOW CREATE TABLE orders;`로 각 제약조건의 **조건식**을 확인해 무엇을 막는지 한 줄씩 적어 보세요.
> 힌트: `table_schema = DATABASE()`, `table_name = 'orders'`, `constraint_type = 'CHECK'`

- 열: `constraint_name`

**기대 결과**

<sub>▶ 실행 결과 · 4행</sub>

| constraint_name |
|---|
| ck_orders_discount |
| ck_orders_fee |
| ck_orders_payment |
| ck_orders_status |



### 문제 3. 타입 고르기 ★

> 다음 데이터에 알맞은 타입을 고르고 이유를 한 줄로 쓰세요. (SQL 없음)

| 데이터 | 예시 |
|---|---|
| ① 사업자등록번호 | 123-45-67890 |
| ② 메뉴 할인율 | 12.5% |
| ③ 가게 공지 본문 | 최대 2,000자 |
| ④ 기사 위치 위도 | 35.1577 |
| ⑤ 쿠폰 사용 일시 | 2026-06-30 18:47:07 |
| ⑥ 프랜차이즈 여부 | 예 / 아니오 |


### 문제 4. 공지사항 테이블 ★★

> **운영팀** 가게 사장님들께 보낼 **공지사항** 테이블 `notices`를 만들어 주세요.

| 열 | 타입 | 규칙 |
|---|---|---|
| `notice_id` | INT | PK, 자동 증가 |
| `title` | VARCHAR(100) | 필수 |
| `content` | TEXT | 필수 |
| `is_pinned` | BOOLEAN | 필수, 기본값 FALSE |
| `published_at` | DATETIME | 필수, 기본값 현재 시각 |

> 만든 뒤 공지 2건을 넣고 확인하세요.
> - "7월 정산일 안내" / "7월 정산은 10일에 진행됩니다." / 상단 고정
> - "배달팁 정책 변경" / "8월부터 5만 원 이상 무료 배달 기준이 4만 원으로 바뀝니다." / 고정 안 함

- 확인 열: `notice_id`, `title`, `is_pinned`

**기대 결과**

<sub>▶ 실행 결과 · 2행</sub>

| notice_id | title | is_pinned |
|---|---|---|
| 1 | 7월 정산일 안내 | 1 |
| 2 | 배달팁 정책 변경 | 0 |



### 문제 5. 휴무일 테이블 ★★

> **운영팀** 가게별 **임시 휴무일**을 저장할 `restaurant_holidays` 테이블을 만들어 주세요.

| 열 | 타입 | 규칙 |
|---|---|---|
| `holiday_id` | INT | PK, 자동 증가 |
| `restaurant_id` | INT | 필수, `restaurants` 참조 (`fk_holidays_restaurant`) |
| `holiday_date` | DATE | 필수 |
| `reason` | VARCHAR(50) | 선택 |

> 추가 규칙: **같은 가게의 같은 날짜는 한 번만** 등록 (`uq_holidays_date`)
> 만든 뒤 아래 휴무를 등록하고, **가게 이름과 함께** 날짜 순으로 조회하세요.
> - 1번 가게 2026-07-15 '내부 수리' / 6번 가게 2026-07-15 (사유 없음) / 1번 가게 2026-07-16 '내부 수리'

- 확인 열: `holiday_date`, `restaurant_name`, `reason`

**기대 결과**

<sub>▶ 실행 결과 · 3행</sub>

| holiday_date | restaurant_name | reason |
|---|---|---|
| 2026-07-15 | 서면옛날돼지국밥 | 내부 수리 |
| 2026-07-15 | 대연동크런치치킨 | NULL |
| 2026-07-16 | 서면옛날돼지국밥 | 내부 수리 |



### 문제 6. 실패할 INSERT 고르기 ★★

> 문제 5의 테이블에 아래 INSERT를 **하나씩** 실행한다고 할 때, 실패하는 것을 모두 고르고 에러 번호를 예측하세요. 예측한 뒤 직접 실행해서 확인하세요.

```sql
-- (가)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (6, '2026-07-16');
-- (나)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (1, '2026-07-15');
-- (다)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (99, '2026-07-20');
-- (라)
INSERT INTO restaurant_holidays (restaurant_id, reason) VALUES (2, '명절');
```


### 문제 7. 메뉴 옵션 테이블 ★★★

> **개발팀** "곱빼기 +1,000원", "치즈 추가 +2,000원" 같은 **메뉴 옵션**을 저장할 `menu_options` 테이블을 설계해 주세요.
> - 옵션은 하나의 메뉴에 속하고(`menus` 참조, `fk_options_menu`), **메뉴가 삭제되면 옵션도 함께 삭제**
> - 옵션 이름 필수, 추가 금액은 **0원 이상**(`ck_options_price`), 기본 0원
> - 같은 메뉴에 같은 이름의 옵션은 하나만(`uq_options_name`)
> - PK는 `option_id` 자동 증가
>
> 만든 뒤 짜장면(`menu_id = 35`)에 '곱빼기' 1,000원, '계란 프라이' 1,500원, '면 추가 없음' 0원을 넣고, **메뉴명·옵션명·옵션 포함 가격**을 조회하세요.

- 확인 열: `menu_name`, `option_name`, `price_with_option`
- 순서: 옵션 포함 가격 순

**기대 결과**

<sub>▶ 실행 결과 · 3행</sub>

| menu_name | option_name | price_with_option |
|---|---|---|
| 짜장면 | 면 추가 없음 | 7000 |
| 짜장면 | 곱빼기 | 8000 |
| 짜장면 | 계란 프라이 | 8500 |



### 문제 8. 기사 월 정산 테이블 ★★★

> **정산팀** 기사별 **월 정산 내역**을 저장할 테이블 `rider_settlements`를 직접 설계해 주세요. 열 이름·타입·제약조건은 자유지만 아래 규칙을 모두 DB가 강제해야 합니다.
> 1. 정산 대상 기사는 실제로 존재해야 한다
> 2. 정산 월은 `'2026-06'` 같은 `YYYY-MM` 형식이다
> 3. 같은 기사·같은 월의 정산은 한 번만 존재한다
> 4. 배달 건수와 정산 금액은 0 이상이다
> 5. 지급 여부를 기록하고, 처음엔 미지급이다
> 6. 지급했으면 지급 일시가 있어야 하고, 미지급이면 지급 일시는 비어 있어야 한다
>
> 만든 뒤 `information_schema.table_constraints`로 제약조건 목록을 확인하세요.

- 확인 열: `constraint_name`, `constraint_type` (제약 이름은 예시 답안 기준)

**기대 결과**

<sub>▶ 실행 결과 · 7행</sub>

| constraint_name | constraint_type |
|---|---|
| ck_settlements_amount | CHECK |
| ck_settlements_count | CHECK |
| ck_settlements_month | CHECK |
| ck_settlements_paid | CHECK |
| fk_settlements_rider | FOREIGN KEY |
| PRIMARY | PRIMARY KEY |
| uq_settlements_month | UNIQUE |


