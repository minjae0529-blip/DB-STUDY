# Day 9 핸드아웃 — ERD & 정규화: FK 설계, 참조무결성, 정규화(1NF~3NF)

> **한국IT교육센터 부산점 | MySQL 10일 완성 | 배달앱 "한입배달" DB 시나리오**

---

## 오늘 배울 것

1. ERD (Entity-Relationship Diagram) — 건물 설계도 읽는 법
2. FOREIGN KEY — 테이블 간의 약속
3. 정규화 (Normalization) — 방 정리의 기술
4. 한입배달 최종 ERD 완성
5. FK 설계 체크리스트
6. 자주 하는 실수 & 에러 정리
7. SQL 치트시트 (Day 9)

---

## 1. ERD (Entity-Relationship Diagram)

### 1-1. ERD란 무엇인가?

> 💡 **핵심 비유**: ERD는 건물 설계도다.
>
> 건물을 짓기 전에 건축가가 설계도를 그리듯, DB 개발자는 테이블을 만들기 전에 ERD를 그린다.
> 설계도 없이 건물을 지으면? → 벽을 다 세웠는데 화장실이 없다거나, 계단이 방을 막는 상황이 생긴다.
> DB도 마찬가지다. 설계 없이 테이블을 만들면 → 나중에 고치기가 매우 힘들다.

ERD(Entity-Relationship Diagram)는 데이터베이스의 구조를 시각적으로 표현한 다이어그램이다. ERD를 보면 다음 세 가지를 알 수 있다.

- 어떤 **테이블**(엔티티)들이 있는지
- 각 테이블에 어떤 **컬럼**(속성)들이 있는지
- 테이블들이 어떻게 **연결**(관계)되어 있는지

---

### 1-2. ERD의 세 가지 구성 요소

#### ① 엔티티 (Entity) = 테이블

"독립적으로 존재하는 사물이나 개념"이다. 현실 세계에서 관리하고 싶은 대상을 생각하면 된다.

| 현실 세계의 대상 | ERD의 엔티티 | MySQL 테이블 |
|-----------------|-------------|-------------|
| 배달앱의 가게들 | restaurants | restaurants |
| 주문을 하는 고객들 | customers | customers |
| 가게에서 파는 음식 | menus | menus |
| 고객이 넣은 주문 | orders | orders |

```
사각형으로 표현:
┌─────────────┐
│ restaurants │   ← 엔티티 이름
└─────────────┘
```

#### ② 속성 (Attribute) = 컬럼

엔티티가 가지는 특성/정보다.

```
┌──────────────────────┐
│      restaurants     │
├──────────────────────┤
│ PK  id               │   ← 기본키 (Primary Key)
│     name             │
│     category         │
│     address          │
│     rating           │
└──────────────────────┘
```

#### ③ 관계 (Relationship) = 선

테이블 간의 연결을 표현한다. 선의 끝 모양으로 관계의 종류(1:1, 1:N, M:N)를 나타낸다.

---

### 1-3. 관계의 종류

#### 1:1 관계 (One-to-One)

하나의 레코드가 다른 테이블의 딱 하나의 레코드에만 대응된다.

> 📌 예: 사용자(customers) ↔ 배달 주소(delivery_addresses)
> 한 고객이 딱 하나의 "기본 배달 주소"만 가지는 경우

```
customers    delivery_addresses
┌──────┐     ┌──────────────────┐
│ id=1 │────►│ customer_id = 1  │
└──────┘     └──────────────────┘
  (1)               (1)
```

ERD에서 실제 1:1은 흔하지 않다. 보통 두 테이블을 합칠 수 있다.

#### 1:N 관계 (One-to-Many) ← 가장 많이 나오는 패턴!

하나의 레코드가 다른 테이블의 여러 레코드에 대응된다.

> 📌 한입배달 예시:
> - **가게(1) ↔ 메뉴(N)**: 한 가게에 여러 메뉴가 있다
> - **고객(1) ↔ 주문(N)**: 한 고객이 여러 주문을 할 수 있다
> - **가게(1) ↔ 주문(N)**: 한 가게에서 여러 주문이 들어온다

```
1:N 예시 — 가게와 메뉴

restaurants             menus
┌──────────────┐        ┌────────────────────┐
│ id=1  부산치킨 │──┬────►│ id=1  후라이드      │
└──────────────┘  ├────►│ id=2  양념치킨      │
                  └────►│ id=3  뿌링클        │
                         └────────────────────┘
        (1)                      (N)
```

1:N에서 N쪽 테이블(menus)에 1쪽 테이블(restaurants)의 PK를 저장한다.
→ 이것이 바로 **외래키(FK, Foreign Key)**다.

```sql
-- menus 테이블의 restaurant_id 컬럼이 FK
SELECT id, menu_name, price, restaurant_id
FROM menus;

-- 결과:
-- id | menu_name   | price | restaurant_id
-- 1  | 후라이드     | 15000 | 1            ← restaurants.id = 1 참조
-- 2  | 양념치킨     | 16000 | 1
-- 3  | 뿌링클       | 18000 | 1
-- 4  | 짜장면       | 8000  | 2            ← restaurants.id = 2 참조
```

#### M:N 관계 (Many-to-Many)

양쪽 테이블 모두에서 여러 레코드가 서로 대응된다.

> 📌 한입배달 예시:
> - **고객(M) ↔ 쿠폰(N)**: 한 고객이 여러 쿠폰을 가질 수 있고, 하나의 쿠폰이 여러 고객에게 발급될 수 있다

```
customers    ←M:N→    coupons

김민준 고객 → [치킨 할인 쿠폰, 배달비 무료 쿠폰]
이수진 고객 → [치킨 할인 쿠폰, 첫 주문 쿠폰]
치킨 할인 쿠폰 → [김민준, 이수진, 박지호]
```

---

### 1-4. M:N을 왜 중간 테이블로 분리해야 하는가?

⚠️ **M:N 관계를 직접 표현하는 것은 관계형 DB에서 불가능하다!**

만약 customers 테이블에 쿠폰 정보를 직접 넣으려 하면:

```
-- 잘못된 설계 (1NF 위반 + M:N 직접 표현 불가)
customers:
id | name   | coupon_ids
1  | 김민준  | 1,2          ← 하나의 셀에 여러 값 → 1NF 위반!
2  | 이수진  | 1,3
```

이렇게 되면:
- 쿠폰을 사용했는지 여부를 어떻게 저장하나?
- 쿠폰 발급 시점을 어떻게 저장하나?
- 쿠폰 검색이 매우 비효율적

**해결책: 중간 테이블(Junction Table / Bridge Table / Associative Table)**

```
customers ──(1:N)── customer_coupons ──(N:1)── coupons

customer_coupons 테이블:
id | customer_id(FK) | coupon_id(FK) | issued_at           | used_at | is_used
1  | 1               | 1             | 2024-03-01 10:00:00 | NULL    | 0
2  | 1               | 2             | 2024-03-05 14:00:00 | NULL    | 0
3  | 2               | 1             | 2024-03-02 09:00:00 | 2024-03-10 | 1
```

M:N을 중간 테이블로 분리하면:
- 관계 자체에 속성(issued_at, used_at, is_used)을 붙일 수 있다
- 양쪽 테이블과 1:N 관계로 정상 연결 가능
- 검색/집계가 훨씬 쉽다

---

### 1-5. 한입배달 관계 구조 (텍스트 ERD)

```
[한입배달 전체 관계 구조]

restaurants ──(1:N)──► menus
     │
     └──(1:N)──► orders ◄──(N:1)── customers
                   │                    │
                   │                    └──(M:N 중간)── customer_coupons ──(N:1)── coupons
                   │
                   └──(1:N)──► reviews
```

핵심 관계 요약:

| 부모 테이블 | 자식 테이블 | 관계 | 설명 |
|------------|------------|------|------|
| restaurants | menus | 1:N | 한 가게에 여러 메뉴 |
| restaurants | orders | 1:N | 한 가게에 여러 주문 |
| customers | orders | 1:N | 한 고객이 여러 주문 |
| menus | orders | 1:N | 한 메뉴가 여러 주문에 포함 |
| orders | reviews | 1:N | 한 주문에 하나의 리뷰 (실질적 1:1) |
| customers | customer_coupons | 1:N | 한 고객이 여러 쿠폰 보유 |
| coupons | customer_coupons | 1:N | 한 쿠폰이 여러 고객에게 발급 |

---

## 2. FOREIGN KEY (외래키)

### 2-1. FK란 무엇인가?

> 💡 **핵심 비유**: FK는 "테이블 간의 약속"이다.
>
> 결혼 반지를 생각해보자. 반지를 끼고 있다는 것은 "나는 저 사람과 연결되어 있어"라는 증표다.
> FK 컬럼도 마찬가지다. menus 테이블의 restaurant_id가 1이라면, "나는 restaurants 테이블의 id=1 가게에 속해 있어"라는 뜻이다.
>
> 약속을 어기면 어떻게 되나? → **ERROR 1452** (존재하지 않는 가게 번호를 가진 메뉴는 등록 불가)

FK는 두 테이블 간의 **참조 무결성(Referential Integrity)**을 보장한다.
즉, "자식 테이블의 FK 값은 반드시 부모 테이블의 PK에 존재해야 한다"는 규칙이다.

---

### 2-2. FK 기본 문법

#### CREATE TABLE 시 FK 정의

```sql
CREATE TABLE menus (
    id           INT           NOT NULL AUTO_INCREMENT,
    restaurant_id INT          NOT NULL,
    menu_name    VARCHAR(100)  NOT NULL,
    price        INT           NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_menus_restaurant          -- 제약조건 이름 (선택, 권장)
        FOREIGN KEY (restaurant_id)          -- 이 테이블의 FK 컬럼
        REFERENCES restaurants(id)           -- 참조할 테이블(컬럼)
        ON DELETE CASCADE                    -- 부모 삭제 시 동작
);
```

#### 기본 문법 구조

```sql
FOREIGN KEY (현재테이블의_컬럼명)
REFERENCES 참조할_테이블명(참조할_컬럼명)
```

> ⭐ **팁**: FK는 반드시 참조 대상 컬럼과 데이터 타입이 같아야 한다.
> restaurants.id가 INT라면 menus.restaurant_id도 INT여야 한다.

---

### 2-3. ON DELETE 옵션 3가지 비교

FK에서 가장 중요한 설계 결정 중 하나가 ON DELETE 옵션이다.
"부모 행이 삭제될 때 자식 행을 어떻게 처리할 것인가?"

| 옵션 | 동작 | 언제 쓰나 | 한입배달 예시 |
|------|------|----------|-------------|
| **CASCADE** | 부모 삭제 → 자식 자동 삭제 | 부모가 없으면 자식도 의미 없을 때 | 가게 폐업 → 해당 가게 메뉴 자동 삭제 |
| **SET NULL** | 부모 삭제 → 자식 FK를 NULL로 변경 | 자식이 부모 없이도 존재 의미 있을 때 | 배달원 퇴사 → 주문의 rider_id를 NULL |
| **RESTRICT** | 부모 삭제 불가 (에러 발생) | 자식이 있으면 부모를 삭제하면 안 될 때 | 주문 내역 있는 고객은 탈퇴 불가 |

> 📌 **ON DELETE RESTRICT는 ON DELETE NO ACTION과 동일**하며, MySQL의 기본값이다.
> FK를 걸었는데 ON DELETE 옵션을 지정하지 않으면 RESTRICT가 적용된다.

#### CASCADE 예시

```sql
-- 가게를 삭제하면 해당 가게의 메뉴도 자동 삭제
CREATE TABLE menus (
    id            INT  NOT NULL AUTO_INCREMENT,
    restaurant_id INT  NOT NULL,
    menu_name     VARCHAR(100) NOT NULL,
    price         INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(id)
        ON DELETE CASCADE    -- 가게 삭제 시 메뉴도 자동 삭제
);

-- 실행 결과:
-- restaurants에서 id=1인 '부산치킨' 삭제
DELETE FROM restaurants WHERE id = 1;

-- menus에서 restaurant_id=1인 행들이 자동으로 삭제됨
-- (후라이드, 양념치킨, 뿌링클 모두 사라짐)
```

#### SET NULL 예시

```sql
-- SET NULL 사용 시 FK 컬럼은 NULL 허용이어야 함!
CREATE TABLE orders (
    id          INT  NOT NULL AUTO_INCREMENT,
    customer_id INT  NOT NULL,
    rider_id    INT  NULL,        -- NULL 허용 필수!
    total_price INT  NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (rider_id)
        REFERENCES riders(id)
        ON DELETE SET NULL    -- 배달원 퇴사 시 rider_id를 NULL로
);
```

#### RESTRICT 예시

```sql
CREATE TABLE orders (
    id          INT  NOT NULL AUTO_INCREMENT,
    customer_id INT  NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON DELETE RESTRICT    -- 기본값. 주문 있는 고객은 삭제 불가
);

-- 실행 시 에러:
DELETE FROM customers WHERE id = 1;
-- ERROR 1451 (23000): Cannot delete or update a parent row:
-- a foreign key constraint fails
```

---

### 2-4. ALTER TABLE로 FK 추가

이미 만들어진 테이블에 FK를 추가할 때 사용한다.

```sql
-- 기본 문법
ALTER TABLE 자식테이블명
ADD CONSTRAINT 제약조건이름
FOREIGN KEY (FK컬럼명)
REFERENCES 부모테이블명(참조컬럼명)
ON DELETE 옵션;
```

#### 실습 예시: menus 테이블에 FK 추가

```sql
-- menus 테이블에 restaurant_id FK 추가
ALTER TABLE menus
ADD CONSTRAINT fk_menus_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(id)
ON DELETE CASCADE;

-- 성공 시: Query OK, 0 rows affected
```

#### 실습 예시: orders 테이블에 FK 3개 추가

```sql
-- customer_id FK
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE RESTRICT;

-- restaurant_id FK
ALTER TABLE orders
ADD CONSTRAINT fk_orders_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(id)
ON DELETE RESTRICT;

-- menu_id FK
ALTER TABLE orders
ADD CONSTRAINT fk_orders_menu
FOREIGN KEY (menu_id)
REFERENCES menus(id)
ON DELETE RESTRICT;
```

> ⚠️ **주의**: ALTER TABLE로 FK를 추가할 때, 이미 데이터가 있다면 **고아 데이터(Orphan Data)**가 없어야 한다.
> 예를 들어 menus에 restaurant_id=999가 있는데 restaurants에 id=999가 없으면 FK 추가 실패!

---

### 2-5. FK 관련 에러 패턴

#### ERROR 1452 — 자식 테이블에 없는 부모 값 INSERT

```sql
-- restaurants에 id=999가 없는데 menus에 restaurant_id=999로 INSERT 시도
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (999, '존재하지않는가게버거', 10000);

-- 에러:
-- ERROR 1452 (23000): Cannot add or update a child row:
-- a foreign key constraint fails
-- (`hanip_delivery`.`menus`, CONSTRAINT `fk_menus_restaurant`
-- FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`id`)
-- ON DELETE CASCADE)
```

해결 방법:
1. 먼저 restaurants 테이블에 해당 가게를 INSERT한다
2. 또는 menus에 올바른 restaurant_id를 사용한다

#### ERROR 1451 — 부모 삭제 시 자식이 존재

```sql
-- 주문이 있는 고객을 삭제하려 할 때 (RESTRICT)
DELETE FROM customers WHERE id = 1;

-- 에러:
-- ERROR 1451 (23000): Cannot delete or update a parent row:
-- a foreign key constraint fails
-- (`hanip_delivery`.`orders`, CONSTRAINT `fk_orders_customer`
-- FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`))
```

해결 방법:
1. 자식 테이블(orders)의 해당 데이터를 먼저 삭제한다
2. 또는 FK를 CASCADE로 변경한다
3. 또는 비즈니스 로직상 삭제 대신 "탈퇴 처리" 컬럼(is_deleted)을 사용한다

---

## 3. 정규화 (Normalization)

### 3-1. 정규화란 무엇인가?

> 💡 **핵심 비유**: 정규화는 "방 정리"다.
>
> 이사 후 짐을 대충 던져놓으면 옷이 침실 서랍, 거실 쇼파, 욕실 바닥에 흩어진다.
> 나중에 "내 흰 티셔츠 어디 있지?" → 세 군데를 다 뒤져야 한다.
>
> DB도 마찬가지다. 같은 정보(고객 이름, 가게 이름 등)가 여러 테이블에 흩어지면:
> - 고객 이름 바뀌면 → 여러 테이블을 다 수정해야 한다 (갱신 이상)
> - 데이터가 불일치할 수 있다
> - 삭제할 때 원치 않는 데이터까지 사라진다 (삭제 이상)

**정규화의 핵심 원칙**: "하나의 사실은 한 곳에만 저장한다"

정규화를 하면:
- **데이터 중복** 최소화
- **이상 현상(Anomaly)** 방지
- **데이터 일관성** 보장

---

### 3-2. 정규화를 하지 않으면 생기는 문제 (이상 현상)

#### 정규화되지 않은 테이블 예시

```
order_details_raw 테이블 (비정규):
┌──────┬──────────┬───────────┬─────────────┬─────────────┬──────────────┬────────────┬──────────┐
│order_│customer_│customer_  │restaurant_  │restaurant_  │restaurant_   │menu_name   │quantity  │
│id    │id       │name       │id           │name         │category      │            │          │
├──────┼──────────┼───────────┼─────────────┼─────────────┼──────────────┼────────────┼──────────┤
│ 1    │ 1       │ 김민준    │ 1           │ 부산치킨    │ 치킨          │ 후라이드   │ 2        │
│ 2    │ 1       │ 김민준    │ 2           │ 해운대짜장  │ 중식          │ 짜장면     │ 1        │
│ 3    │ 2       │ 이수진    │ 1           │ 부산치킨    │ 치킨          │ 양념치킨   │ 1        │
└──────┴──────────┴───────────┴─────────────┴─────────────┴──────────────┴────────────┴──────────┘
```

이 테이블에서 발생하는 이상 현상:

| 이상 현상 | 설명 | 예시 |
|----------|------|------|
| **삽입 이상** | 불필요한 데이터 없이는 원하는 데이터를 삽입할 수 없음 | 주문 없이는 가게 정보를 테이블에 추가할 수 없음 |
| **갱신 이상** | 한 데이터를 수정하면 여러 행을 다 수정해야 함 | '부산치킨' → '부산1등치킨'으로 이름 변경 시 해당 가게 주문이 있는 모든 행을 수정 |
| **삭제 이상** | 한 데이터 삭제 시 원치 않는 다른 데이터도 사라짐 | 주문 1번을 삭제하면 '부산치킨' 가게 정보도 사라질 수 있음 |

---

### 3-3. 1NF (제1정규형 — First Normal Form)

**규칙**: 각 컬럼(셀)은 **하나의 값**만 가져야 한다. 반복 그룹이 없어야 한다.

#### 1NF 위반 예시

```
orders_bad 테이블:
┌──────┬─────────────┬───────────────────────────┐
│ id   │ customer_id │ menu_names                │
├──────┼─────────────┼───────────────────────────┤
│ 1    │ 1           │ 불고기버거,감자튀김,콜라    │  ← 하나의 셀에 여러 값!
│ 2    │ 2           │ 짜장면,탕수육              │
└──────┴─────────────┴───────────────────────────┘
```

위 테이블에서 발생하는 문제:
- "불고기버거" 주문만 조회하려면? → LIKE '%불고기버거%' (비효율, 오류 가능)
- "불고기버거" 가격을 조회하려면? → 불가능
- 메뉴가 추가되면 문자열이 더 길어짐

#### 1NF 적용 (해결: 행 분리)

```sql
-- 1NF를 만족하는 구조
order_items 테이블:
┌──────┬──────────┬────────────┬──────────┐
│ id   │ order_id │ menu_name  │ quantity │
├──────┼──────────┼────────────┼──────────┤
│ 1    │ 1        │ 불고기버거  │ 1        │  ← 한 셀에 하나의 값
│ 2    │ 1        │ 감자튀김    │ 2        │
│ 3    │ 1        │ 콜라       │ 2        │
│ 4    │ 2        │ 짜장면      │ 1        │
│ 5    │ 2        │ 탕수육      │ 1        │
└──────┴──────────┴────────────┴──────────┘
```

> ⭐ **팁**: 컬럼 이름에 번호가 붙어 있다면 1NF 위반 신호!
> `menu_name1, menu_name2, menu_name3` → 이런 구조는 1NF 위반

---

### 3-4. 2NF (제2정규형 — Second Normal Form)

**규칙**: 1NF를 만족하면서, **부분 함수 종속**이 없어야 한다.
즉, 복합 기본키(PK가 2개 이상인 경우)에서 일반 컬럼이 기본키 전체가 아닌 일부에만 종속되면 안 된다.

> 📌 **참고**: 2NF는 복합 PK가 있을 때 주로 문제가 된다. PK가 단일 컬럼이면 자동으로 2NF를 만족한다.

#### 2NF 위반 예시

```
order_menus 테이블 (1NF는 만족, 2NF 위반):
┌──────────┬─────────┬──────────────────┬──────────┬─────────────┬──────────────┐
│ order_id │ menu_id │ menu_name        │ price    │ customer_id │ customer_name│
│ (PK)     │ (PK)    │                  │          │             │              │
├──────────┼─────────┼──────────────────┼──────────┼─────────────┼──────────────┤
│ 1        │ 1       │ 후라이드         │ 15000    │ 1           │ 김민준       │
│ 1        │ 2       │ 양념치킨         │ 16000    │ 1           │ 김민준       │
│ 2        │ 3       │ 짜장면           │ 8000     │ 2           │ 이수진       │
└──────────┴─────────┴──────────────────┴──────────┴─────────────┴──────────────┘
```

이 테이블의 복합 PK는 (order_id, menu_id)이다.
- `menu_name`, `price`는 `menu_id`에만 종속 → **부분 함수 종속!**
- `customer_id`, `customer_name`은 `order_id`에만 종속 → **부분 함수 종속!**

#### 2NF 적용 (해결: 부분 종속 컬럼을 별도 테이블로 분리)

```sql
-- ① order_items 테이블 (주문-메뉴 관계)
-- PK: (order_id, menu_id), 전체 PK에 종속된 컬럼만
┌──────────┬─────────┬──────────┐
│ order_id │ menu_id │ quantity │  ← quantity는 order_id와 menu_id 모두에 종속
│ (PK)     │ (PK)    │          │
├──────────┼─────────┼──────────┤
│ 1        │ 1       │ 2        │
│ 1        │ 2       │ 1        │
│ 2        │ 3       │ 1        │
└──────────┴─────────┴──────────┘

-- ② menus 테이블 (menu_id에만 종속되는 정보)
┌─────────┬──────────────────┬──────────┐
│ id (PK) │ menu_name        │ price    │
├─────────┼──────────────────┼──────────┤
│ 1       │ 후라이드         │ 15000    │
│ 2       │ 양념치킨         │ 16000    │
│ 3       │ 짜장면           │ 8000     │
└─────────┴──────────────────┴──────────┘

-- ③ orders 테이블 (order_id에만 종속되는 정보)
┌─────────┬─────────────┐
│ id (PK) │ customer_id │
├─────────┼─────────────┤
│ 1       │ 1           │
│ 2       │ 2           │
└─────────┴─────────────┘
```

---

### 3-5. 3NF (제3정규형 — Third Normal Form)

**규칙**: 2NF를 만족하면서, **이행 함수 종속**이 없어야 한다.
즉, 기본키가 아닌 컬럼이 다른 비기본키 컬럼에 종속되면 안 된다.

> 💡 **이행 함수 종속**이란?
> A → B → C 관계에서 A가 PK라면, C는 A에 직접 종속되는 게 아니라 B를 통해 간접 종속된 상태

#### 3NF 위반 예시

```
menus_with_restaurant 테이블:
┌─────────┬──────────────────┬──────────┬───────────────┬──────────────────┬──────────────────────┐
│ id (PK) │ menu_name        │ price    │ restaurant_id │ restaurant_name  │ restaurant_category  │
├─────────┼──────────────────┼──────────┼───────────────┼──────────────────┼──────────────────────┤
│ 1       │ 후라이드          │ 15000    │ 1             │ 부산치킨         │ 치킨                 │
│ 2       │ 양념치킨          │ 16000    │ 1             │ 부산치킨         │ 치킨                 │
│ 3       │ 뿌링클           │ 18000    │ 1             │ 부산치킨         │ 치킨                 │
│ 4       │ 짜장면           │ 8000     │ 2             │ 해운대짜장       │ 중식                 │
└─────────┴──────────────────┴──────────┴───────────────┴──────────────────┴──────────────────────┘
```

종속 관계:
- `menu_id` → `restaurant_id` (메뉴는 특정 가게에 속함)
- `restaurant_id` → `restaurant_name` (가게 ID로 이름 결정)
- `restaurant_id` → `restaurant_category` (가게 ID로 카테고리 결정)

즉: `menu_id` → `restaurant_id` → `restaurant_name` 이행 종속 발생!

문제점:
- '부산치킨'이 이름을 변경하면 menus 테이블에서 해당 가게 메뉴 행을 모두 수정해야 한다
- 데이터 중복: restaurant_name, restaurant_category가 메뉴마다 반복 저장

#### 3NF 적용 (해결: 이행 종속 컬럼을 별도 테이블로 분리)

```sql
-- ① restaurants 테이블 (가게 정보는 여기에만)
CREATE TABLE restaurants (
    id       INT          NOT NULL AUTO_INCREMENT,
    name     VARCHAR(100) NOT NULL,
    category VARCHAR(50)  NOT NULL,
    address  VARCHAR(200),
    rating   DECIMAL(2,1) DEFAULT 0.0,
    PRIMARY KEY (id)
);

-- ② menus 테이블 (가게 이름, 카테고리는 restaurant_id FK로만 참조)
CREATE TABLE menus (
    id            INT          NOT NULL AUTO_INCREMENT,
    restaurant_id INT          NOT NULL,
    menu_name     VARCHAR(100) NOT NULL,
    price         INT          NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(id)
        ON DELETE CASCADE
);
```

가게 이름을 변경하고 싶다면? → restaurants 테이블에서 1줄만 수정하면 된다!

---

### 3-6. 정규화 단계별 변환 요약

```
비정규 (Unnormalized Form)
     ↓  [각 셀에 원자값만 허용, 반복 그룹 제거]
1NF (제1정규형)
     ↓  [부분 함수 종속 제거 — 복합 PK 시 적용]
2NF (제2정규형)
     ↓  [이행 함수 종속 제거]
3NF (제3정규형)
     ↓  [결정자가 후보키가 아닌 함수 종속 제거 — 심화]
BCNF (Boyce-Codd Normal Form)
```

> 📌 실무에서는 3NF 또는 BCNF까지 정규화하는 것이 일반적이다.
> 4NF, 5NF는 매우 특수한 경우에만 필요하다.

---

### 3-7. 반정규화 (Denormalization)

> ⭐ **팁**: 정규화를 하면 데이터 일관성은 좋아지지만, 조회 성능은 나빠질 수 있다.
> 테이블이 많이 쪼개질수록 JOIN이 많아지기 때문이다.

**반정규화**는 성능 향상을 위해 의도적으로 중복을 허용하는 것이다.

| 상황 | 정규화 | 반정규화 |
|------|--------|---------|
| 데이터 수정이 잦음 | 정규화 유리 | 불리 (여러 곳 수정) |
| 읽기가 매우 잦음 | 불리 (JOIN 많음) | 반정규화 고려 |
| 데이터 일관성 중요 | 정규화 필수 | 위험 |

```sql
-- 반정규화 예시: orders 테이블에 restaurant_name을 직접 저장
-- (원래는 restaurant_id FK만 있어야 함)
CREATE TABLE orders (
    id              INT NOT NULL AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    restaurant_id   INT NOT NULL,
    restaurant_name VARCHAR(100),  -- 반정규화: 성능을 위해 중복 저장
    total_price     INT NOT NULL,
    PRIMARY KEY (id)
);
```

> ⚠️ **주의**: 반정규화는 반드시 "필요성"을 확인한 후 의도적으로 선택해야 한다.
> 무분별한 반정규화는 데이터 불일치(inconsistency) 문제로 이어진다.

---

## 4. 한입배달 최종 ERD (텍스트 형식)

### 4-1. 전체 테이블 관계 다이어그램

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         한입배달 (hanip_delivery) 최종 ERD                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐           ┌───────────────────────┐
│   restaurants   │           │         menus         │
├─────────────────┤  1     N  ├───────────────────────┤
│ PK id           │──────────►│ PK id                 │
│    name         │           │ FK restaurant_id      │
│    category     │           │    menu_name          │
│    address      │           │    price              │
│    rating       │           └───────────────────────┘
└────────┬────────┘
         │                    ┌───────────────────────┐
         │ 1              N   │        orders         │
         └───────────────────►│ PK id                 │
                              │ FK customer_id        │
┌─────────────────┐  1     N  │ FK restaurant_id      │
│    customers    │──────────►│ FK menu_id            │
├─────────────────┤           │    quantity           │
│ PK id           │           │    total_price        │
│    name         │           │    order_date         │
│    phone        │           │    delivery_fee       │
│    address      │           │    status             │
└────────┬────────┘           └──────────┬────────────┘
         │                               │
         │ 1                             │ 1
         ▼                               ▼ N
┌────────────────────────┐    ┌───────────────────────┐
│   customer_coupons     │    │        reviews        │
├────────────────────────┤    ├───────────────────────┤
│ PK id                  │    │ PK id                 │
│ FK customer_id         │    │ FK order_id           │
│ FK coupon_id           │    │ FK customer_id        │
│    issued_at           │    │    rating (1~5)       │
│    used_at             │    │    content            │
│    is_used             │    │    created_at         │
└────────┬───────────────┘    └───────────────────────┘
         │
         │ N
         ▼ 1
┌─────────────────┐
│     coupons     │
├─────────────────┤
│ PK id           │
│    coupon_name  │
│    discount_type│
│    discount_value│
│    min_order_   │
│    amount       │
└─────────────────┘


riders (독립 테이블, orders.rider_id로 참조 가능)
┌─────────────────┐
│     riders      │
├─────────────────┤
│ PK id           │
│    name         │
│    phone        │
│    region       │
│    is_active    │
└─────────────────┘
```

### 4-2. 관계 선 표기 설명

```
──────►  : 1:N 관계 (화살표 방향이 N쪽)
   1      : 관계의 1쪽
   N      : 관계의 N쪽
   M:N    : customer_coupons를 통해 구현
```

---

### 4-3. 전체 테이블 상세 스키마

```sql
-- ① restaurants (가게 정보)
CREATE TABLE restaurants (
    id       INT           NOT NULL AUTO_INCREMENT,
    name     VARCHAR(100)  NOT NULL,
    category VARCHAR(50)   NOT NULL,
    address  VARCHAR(200),
    rating   DECIMAL(2,1)  DEFAULT 0.0,
    PRIMARY KEY (id)
);

-- ② customers (고객 정보)
CREATE TABLE customers (
    id      INT           NOT NULL AUTO_INCREMENT,
    name    VARCHAR(50)   NOT NULL,
    phone   VARCHAR(20)   UNIQUE,
    address VARCHAR(200),
    PRIMARY KEY (id)
);

-- ③ menus (메뉴 정보, restaurants 참조)
CREATE TABLE menus (
    id            INT           NOT NULL AUTO_INCREMENT,
    restaurant_id INT           NOT NULL,
    menu_name     VARCHAR(100)  NOT NULL,
    price         INT           NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_menus_restaurant
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(id)
        ON DELETE CASCADE
);

-- ④ riders (배달원 정보)
CREATE TABLE riders (
    id        INT          NOT NULL AUTO_INCREMENT,
    name      VARCHAR(50)  NOT NULL,
    phone     VARCHAR(20)  UNIQUE,
    region    VARCHAR(50),
    is_active TINYINT(1)   DEFAULT 1,
    PRIMARY KEY (id)
);

-- ⑤ orders (주문 정보, customers/restaurants/menus 참조)
CREATE TABLE orders (
    id            INT           NOT NULL AUTO_INCREMENT,
    customer_id   INT           NOT NULL,
    restaurant_id INT           NOT NULL,
    menu_id       INT           NOT NULL,
    rider_id      INT           NULL,          -- SET NULL 대비 NULL 허용
    quantity      INT           NOT NULL DEFAULT 1,
    total_price   INT           NOT NULL,
    order_date    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivery_fee  INT           DEFAULT 0,
    status        VARCHAR(20)   DEFAULT '주문접수',
    PRIMARY KEY (id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)   REFERENCES customers(id)    ON DELETE RESTRICT,
    CONSTRAINT fk_orders_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)  ON DELETE RESTRICT,
    CONSTRAINT fk_orders_menu
        FOREIGN KEY (menu_id)       REFERENCES menus(id)        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_rider
        FOREIGN KEY (rider_id)      REFERENCES riders(id)       ON DELETE SET NULL
);

-- ⑥ reviews (리뷰 정보, orders/customers 참조)
CREATE TABLE reviews (
    id          INT           NOT NULL AUTO_INCREMENT,
    order_id    INT           NOT NULL,
    customer_id INT           NOT NULL,
    rating      TINYINT       NOT NULL CHECK (rating BETWEEN 1 AND 5),
    content     TEXT,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)    REFERENCES orders(id)    ON DELETE CASCADE,
    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
);

-- ⑦ coupons (쿠폰 정보)
CREATE TABLE coupons (
    id                INT           NOT NULL AUTO_INCREMENT,
    coupon_name       VARCHAR(100)  NOT NULL,
    discount_type     ENUM('정액','정률') NOT NULL,
    discount_value    INT           NOT NULL,
    min_order_amount  INT           DEFAULT 0,
    PRIMARY KEY (id)
);

-- ⑧ customer_coupons (고객-쿠폰 중간 테이블, M:N 구현)
CREATE TABLE customer_coupons (
    id          INT       NOT NULL AUTO_INCREMENT,
    customer_id INT       NOT NULL,
    coupon_id   INT       NOT NULL,
    issued_at   DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    used_at     DATETIME  NULL,
    is_used     TINYINT(1) DEFAULT 0,
    PRIMARY KEY (id),
    CONSTRAINT fk_cc_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    CONSTRAINT fk_cc_coupon
        FOREIGN KEY (coupon_id)   REFERENCES coupons(id)   ON DELETE CASCADE
);
```

---

## 5. FK 설계 체크리스트

### 5-1. FK 추가 전 확인사항

```
□ 1. 부모 테이블이 먼저 생성되어 있는가?
      (자식 테이블에서 참조할 테이블이 존재해야 함)

□ 2. 참조할 컬럼(보통 PK)에 인덱스가 있는가?
      (PRIMARY KEY는 자동으로 인덱스 생성)

□ 3. FK 컬럼의 데이터 타입이 참조 컬럼과 동일한가?
      (INT → INT, VARCHAR(50) → VARCHAR(50) 등)

□ 4. 기존 데이터에 고아 데이터(Orphan Data)가 없는가?
      -- 고아 데이터 확인 쿼리
      SELECT m.id, m.restaurant_id
      FROM menus m
      LEFT JOIN restaurants r ON m.restaurant_id = r.id
      WHERE r.id IS NULL;
      -- 결과가 없어야 FK 추가 가능

□ 5. SET NULL 옵션 사용 시 FK 컬럼이 NULL 허용인가?
      (NOT NULL 컬럼에 SET NULL 불가)

□ 6. 제약조건 이름이 DB 내에서 고유한가?
      (같은 이름의 FK 제약조건이 이미 있으면 에러)
```

### 5-2. ON DELETE 옵션 선택 기준

```
질문 1: 부모가 삭제될 때 자식 데이터도 같이 지워야 하나?
  ├─ YES → CASCADE
  └─ NO → 다음 질문으로

질문 2: 부모 없이도 자식이 존재할 수 있나?
  ├─ YES (자식이 orphan 상태로 유지 가능) → SET NULL
  │         단, FK 컬럼이 NULL 허용이어야 함
  └─ NO (부모 없는 자식은 의미 없음) → RESTRICT
         (부모를 삭제하기 전에 자식부터 지워야 함)
```

### 5-3. 인덱스와 FK 관계

> ⭐ **중요**: MySQL InnoDB에서 FK를 걸면 해당 컬럼에 자동으로 인덱스가 생성된다.

```sql
-- FK 추가 후 인덱스 확인
SHOW INDEX FROM menus;

-- 결과 예시:
-- Table | Key_name              | Column_name   | Index_type
-- menus | PRIMARY               | id            | BTREE     ← PK 인덱스
-- menus | fk_menus_restaurant   | restaurant_id | BTREE     ← FK 자동 인덱스
```

이는 FK 컬럼으로 JOIN이나 WHERE 조건을 걸 때 자동으로 인덱스를 활용하게 된다.

> ⚠️ **주의**: 반면 부모 테이블 삭제 시 자식 테이블을 검색해야 하므로,
> FK가 많은 테이블은 DELETE/UPDATE 성능이 영향을 받을 수 있다.

---

## 6. 자주 하는 실수 & 에러 정리

### 6-1. ERROR 1452 — 자식 테이블에 없는 부모 값 INSERT

**상황**: 부모 테이블에 없는 값을 자식 테이블의 FK 컬럼에 INSERT할 때

```sql
-- 예시: restaurant_id=999 가게는 존재하지 않음
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (999, '유령메뉴', 5000);

-- 에러 메시지:
-- ERROR 1452 (23000): Cannot add or update a child row:
-- a foreign key constraint fails (`hanip_delivery`.`menus`,
-- CONSTRAINT `fk_menus_restaurant` FOREIGN KEY (`restaurant_id`)
-- REFERENCES `restaurants` (`id`) ON DELETE CASCADE)
```

**해결**:
```sql
-- 1) 올바른 restaurant_id 사용
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (1, '유령메뉴', 5000);  -- id=1이 존재하는지 확인

-- 2) 또는 먼저 restaurants에 가게 INSERT
INSERT INTO restaurants (name, category) VALUES ('새가게', '분식');
-- 그 다음 menus INSERT
INSERT INTO menus (restaurant_id, menu_name, price)
VALUES (LAST_INSERT_ID(), '유령메뉴', 5000);
```

---

### 6-2. ERROR 1451 — 자식 데이터 있는 부모 행 삭제 시도

**상황**: RESTRICT 옵션이 걸린 FK가 있는데, 자식 데이터가 남아있는 부모를 삭제할 때

```sql
-- 예시: customer_id=1 고객에게 주문이 존재
DELETE FROM customers WHERE id = 1;

-- 에러 메시지:
-- ERROR 1451 (23000): Cannot delete or update a parent row:
-- a foreign key constraint fails (`hanip_delivery`.`orders`,
-- CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`)
-- REFERENCES `customers` (`id`))
```

**해결**:
```sql
-- 방법 1: 자식 데이터 먼저 삭제 (트랜잭션과 함께)
START TRANSACTION;
DELETE FROM orders WHERE customer_id = 1;
DELETE FROM customers WHERE id = 1;
COMMIT;

-- 방법 2: 논리적 삭제 (실무 권장)
ALTER TABLE customers ADD COLUMN is_deleted TINYINT(1) DEFAULT 0;
UPDATE customers SET is_deleted = 1 WHERE id = 1;
-- 실제 행 삭제 없이 탈퇴 처리
```

---

### 6-3. ERROR 1215 — FK 생성 실패 (데이터 타입 불일치)

```sql
-- restaurants.id가 INT인데 menus.restaurant_id를 VARCHAR로 만든 경우
ALTER TABLE menus
ADD CONSTRAINT fk_bad
FOREIGN KEY (restaurant_id_varchar)  -- VARCHAR 컬럼
REFERENCES restaurants(id);           -- INT 컬럼

-- 에러:
-- ERROR 1215 (HY000): Cannot add foreign key constraint
```

**해결**: FK 컬럼과 참조 컬럼의 데이터 타입을 일치시킨다.

---

### 6-4. 정규화 위반으로 인한 이상 현상 요약

| 이상 현상 | 발생 원인 | 예시 |
|----------|----------|------|
| **삽입 이상** (Insertion Anomaly) | 필요한 데이터를 삽입할 때 불필요한 데이터도 같이 넣어야 함 | 주문 없이 가게 정보를 비정규 테이블에 추가 불가 |
| **갱신 이상** (Update Anomaly) | 중복 저장된 데이터 수정 시 일부만 변경돼 불일치 발생 | 가게 이름이 바뀌면 수십 개의 주문 행을 모두 수정 |
| **삭제 이상** (Deletion Anomaly) | 특정 데이터 삭제 시 원치 않는 다른 데이터도 같이 삭제 | 마지막 주문을 삭제하면 가게 정보까지 사라짐 |

---

## 7. SQL 치트시트 (Day 9)

### 7-1. FK 추가

```sql
-- CREATE TABLE 시 FK 정의
CREATE TABLE 자식테이블 (
    id            INT NOT NULL AUTO_INCREMENT,
    부모테이블_id  INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT 제약조건이름
        FOREIGN KEY (부모테이블_id)
        REFERENCES 부모테이블(id)
        ON DELETE CASCADE   -- 또는 SET NULL 또는 RESTRICT
);

-- ALTER TABLE로 FK 추가
ALTER TABLE 자식테이블
ADD CONSTRAINT 제약조건이름
FOREIGN KEY (FK컬럼)
REFERENCES 부모테이블(참조컬럼)
ON DELETE CASCADE;
```

### 7-2. FK 삭제

```sql
-- FK 제약조건 삭제
ALTER TABLE 자식테이블
DROP FOREIGN KEY 제약조건이름;

-- 예시
ALTER TABLE menus
DROP FOREIGN KEY fk_menus_restaurant;

-- ⭐ 팁: FK를 삭제해도 인덱스는 남는다. 인덱스도 삭제하려면:
ALTER TABLE menus
DROP INDEX fk_menus_restaurant;
```

### 7-3. FK 목록 확인 (information_schema 활용)

```sql
-- 현재 DB의 모든 FK 조회
SELECT
    TABLE_NAME      AS '자식 테이블',
    COLUMN_NAME     AS 'FK 컬럼',
    CONSTRAINT_NAME AS '제약조건 이름',
    REFERENCED_TABLE_NAME  AS '부모 테이블',
    REFERENCED_COLUMN_NAME AS '참조 컬럼'
FROM
    information_schema.KEY_COLUMN_USAGE
WHERE
    REFERENCED_TABLE_NAME IS NOT NULL
    AND TABLE_SCHEMA = DATABASE()
ORDER BY
    TABLE_NAME;
```

#### 예상 결과

```
자식 테이블          | FK 컬럼        | 제약조건 이름             | 부모 테이블   | 참조 컬럼
menus               | restaurant_id | fk_menus_restaurant       | restaurants   | id
orders              | customer_id   | fk_orders_customer        | customers     | id
orders              | restaurant_id | fk_orders_restaurant      | restaurants   | id
orders              | menu_id       | fk_orders_menu            | menus         | id
orders              | rider_id      | fk_orders_rider           | riders        | id
reviews             | order_id      | fk_reviews_order          | orders        | id
reviews             | customer_id   | fk_reviews_customer       | customers     | id
customer_coupons    | customer_id   | fk_cc_customer            | customers     | id
customer_coupons    | coupon_id     | fk_cc_coupon              | coupons       | id
```

### 7-4. SHOW CREATE TABLE로 FK 확인

```sql
-- 테이블의 전체 DDL 확인 (FK 포함)
SHOW CREATE TABLE menus;

-- 결과 예시 (FOREIGN KEY 부분):
-- CREATE TABLE `menus` (
--   `id` int NOT NULL AUTO_INCREMENT,
--   `restaurant_id` int NOT NULL,
--   `menu_name` varchar(100) NOT NULL,
--   `price` int NOT NULL,
--   PRIMARY KEY (`id`),
--   KEY `fk_menus_restaurant` (`restaurant_id`),
--   CONSTRAINT `fk_menus_restaurant`
--     FOREIGN KEY (`restaurant_id`)
--     REFERENCES `restaurants` (`id`)
--     ON DELETE CASCADE
-- ) ENGINE=InnoDB
```

### 7-5. FK 비활성화 (대량 데이터 입력 시 임시 사용)

```sql
-- FK 체크 비활성화 (순서 무관 데이터 입력 시)
SET FOREIGN_KEY_CHECKS = 0;

-- 데이터 INSERT 작업
INSERT INTO menus ... ;
INSERT INTO restaurants ... ;

-- FK 체크 재활성화
SET FOREIGN_KEY_CHECKS = 1;
```

> ⚠️ **주의**: FOREIGN_KEY_CHECKS = 0은 임시방편이다.
> 가능하면 부모 테이블 데이터를 먼저 입력하는 것이 올바른 방법이다.
> FOREIGN_KEY_CHECKS = 0 후에는 반드시 데이터 정합성을 수동으로 확인하라.

### 7-6. 정규화 관련 진단 쿼리

```sql
-- 1NF 위반 가능성 진단: 특정 컬럼에 쉼표가 들어간 데이터 찾기
SELECT id, menu_names
FROM orders_bad
WHERE menu_names LIKE '%,%';

-- 2NF/3NF 위반 진단: 중복 데이터 확인
SELECT restaurant_name, COUNT(*) AS 중복수
FROM orders_bad
GROUP BY restaurant_name
HAVING COUNT(*) > 1;

-- 고아 데이터 확인 (FK 추가 전 필수)
SELECT m.id AS menu_id, m.restaurant_id
FROM menus m
LEFT JOIN restaurants r ON m.restaurant_id = r.id
WHERE r.id IS NULL;
```

---

## 부록: 오늘 배운 핵심 키워드 정리

| 키워드 | 설명 |
|--------|------|
| ERD | 테이블과 관계를 시각적으로 표현한 설계 다이어그램 |
| 엔티티 | ERD에서 테이블을 의미 |
| 1:N 관계 | 하나의 부모 레코드가 여러 자식 레코드와 연결 |
| M:N 관계 | 양쪽 모두 여러 레코드가 연결, 중간 테이블로 구현 |
| FOREIGN KEY | 다른 테이블의 PK를 참조하는 컬럼 |
| 참조 무결성 | FK는 부모 테이블에 반드시 존재하는 값만 가능 |
| ON DELETE CASCADE | 부모 삭제 시 자식도 자동 삭제 |
| ON DELETE SET NULL | 부모 삭제 시 자식 FK를 NULL로 변경 |
| ON DELETE RESTRICT | 자식 있으면 부모 삭제 불가 |
| ERROR 1452 | 존재하지 않는 부모 값으로 자식 INSERT |
| ERROR 1451 | 자식 있는 부모를 RESTRICT로 삭제 시도 |
| 정규화 | 데이터 중복 제거 및 이상 현상 방지를 위한 테이블 설계 |
| 1NF | 각 셀은 하나의 값만 (원자값) |
| 2NF | 1NF + 부분 함수 종속 제거 |
| 3NF | 2NF + 이행 함수 종속 제거 |
| 반정규화 | 성능을 위해 의도적으로 중복 허용 |
| 고아 데이터 | 부모가 없는 자식 행 |
| 삽입/갱신/삭제 이상 | 정규화 위반 테이블에서 발생하는 데이터 조작 문제 |

---

> **다음 시간 (Day 10)**: 10일간 배운 모든 것을 하나의 미니 프로젝트로 완성합니다.
> ERD 설계 → 테이블 생성 → 데이터 입력 → 쿼리 작성 → 뷰 & 트랜잭션 → 인덱스까지
> 처음부터 끝까지 혼자 해보는 시간입니다!
