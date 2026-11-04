
# Day 1 실습 문제
### 한입배달 MySQL 10일 완성 과정

---

> **실습 전 체크리스트**
> - [ ] MySQL Workbench가 켜져 있다
> - [ ] Local instance에 접속되어 있다
> - [ ] `day01_setup.sql` 을 이미 실행했다

---

## 난이도 안내

| 기호 | 난이도 | 설명 |
|------|--------|------|
| ⭐ | 기초 | 수업 내용을 그대로 따라하면 풀 수 있습니다 |
| ⭐⭐ | 응용 | 수업 내용을 응용하거나 살짝 변형합니다 |
| ⭐⭐⭐ | 도전 | 수업 내용을 종합해서 스스로 설계합니다 |

---

## 문제 1 ⭐

> 한입배달 개발팀에서 새 프로젝트를 시작합니다. `hanip_delivery` 데이터베이스를 만들고, 그 데이터베이스를 선택해보세요.

**조건**:
- 데이터베이스 이름: `hanip_delivery`
- 한글 데이터를 저장할 수 있어야 합니다 (CHARACTER SET 지정)
- 이미 같은 이름의 DB가 있어도 에러가 나지 않아야 합니다

**힌트**: `DROP DATABASE IF EXISTS`, `CREATE DATABASE`, `USE` 세 가지 명령어를 순서대로 사용하세요.

**예상 결과**:
```
-- SHOW DATABASES; 실행 시 목록에 아래가 포함되어야 합니다
+--------------------+
| Database           |
+--------------------+
| hanip_delivery     |
+--------------------+
```

<details>
<summary>정답 보기</summary>

```sql
-- Step 1: 기존 DB가 있으면 삭제 (재실행 가능하게)
DROP DATABASE IF EXISTS hanip_delivery;

-- Step 2: 데이터베이스 생성 (한글 지원)
CREATE DATABASE hanip_delivery
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 3: 데이터베이스 선택
USE hanip_delivery;

-- Step 4: 확인
SHOW DATABASES;
```

**핵심 포인트**:
- `IF EXISTS` 덕분에 DB가 없어도 에러 없이 진행됩니다.
- `utf8mb4`는 한글, 이모지까지 모두 저장 가능한 인코딩입니다.
- `USE`를 실행해야 이후 명령어들이 이 DB 안에서 동작합니다.

</details>

---

## 문제 2 ⭐

> 한입배달 개발팀에서 배달 라이더 관리 기능을 추가하기로 했습니다. `delivery_riders` 테이블을 만들어주세요.

**조건**:
- 테이블명: `delivery_riders`
- 컬럼 구성:

| 컬럼명 | 데이터 타입 | 설명 |
|--------|-------------|------|
| `id` | INT | 라이더 고유 번호 |
| `name` | VARCHAR(30) | 라이더 이름 |
| `phone` | VARCHAR(20) | 전화번호 |
| `region` | VARCHAR(30) | 담당 지역 (예: '해운대구', '남구') |

**힌트**: `CREATE TABLE 테이블명 ( 컬럼명 타입, ... );` 형식으로 작성하세요.

**예상 결과** (`DESC delivery_riders;` 실행 시):

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| id | int | YES | | NULL | |
| name | varchar(30) | YES | | NULL | |
| phone | varchar(20) | YES | | NULL | |
| region | varchar(30) | YES | | NULL | |

<details>
<summary>정답 보기</summary>

```sql
-- 테이블 생성
CREATE TABLE delivery_riders (
    id      INT,
    name    VARCHAR(30),
    phone   VARCHAR(20),
    region  VARCHAR(30)
);

-- 구조 확인
DESC delivery_riders;
```

**핵심 포인트**:
- 컬럼 목록의 마지막 항목(`region`) 뒤에는 쉼표를 붙이지 않습니다.
- 전화번호(`phone`)는 숫자처럼 보여도 `VARCHAR`를 사용합니다. `INT`로 저장하면 앞의 `0`이 사라집니다! (`010...` → `10...`)
- `USE hanip_delivery;`를 먼저 실행하지 않으면 엉뚱한 DB에 테이블이 만들어질 수 있습니다.

</details>

---

## 문제 3 ⭐

> 한입배달 개발팀 신입 개발자가 현재 데이터베이스에 어떤 테이블들이 있는지 확인해야 합니다. 테이블 목록을 조회하는 쿼리를 작성해주세요.

**조건**:
- `day01_setup.sql`과 문제 2의 테이블이 모두 만들어진 상태에서 실행하세요.
- 테이블 목록을 보여주는 명령어 1개를 사용합니다.

**예상 결과** (문제 2까지 완료한 경우):

| Tables_in_hanip_delivery |
|--------------------------|
| customers |
| delivery_riders |
| menus |
| restaurants |

**힌트**: `SHOW`로 시작하는 명령어를 사용하세요.

<details>
<summary>정답 보기</summary>

```sql
-- 현재 선택된 데이터베이스의 테이블 목록 조회
SHOW TABLES;
```

**핵심 포인트**:
- `SHOW TABLES`는 현재 `USE`로 선택된 DB의 테이블 목록을 보여줍니다.
- 결과가 알파벳순으로 정렬되어 나옵니다.
- `SHOW TABLES FROM hanip_delivery;` 처럼 DB명을 명시해도 됩니다.

**추가 확인**: 각 테이블의 구조도 확인해보세요.
```sql
DESC customers;
DESC delivery_riders;
DESC menus;
DESC restaurants;
```

</details>

---

## 문제 4 ⭐⭐

> 한입배달에서 쿠폰 기능을 도입하기로 했습니다. 쿠폰 정보를 저장할 `coupons` 테이블을 만들어주세요.

**조건**:
- 테이블명: `coupons`
- 컬럼 구성:

| 컬럼명 | 데이터 타입 | 설명 | 예시 값 |
|--------|-------------|------|---------|
| `id` | INT | 쿠폰 고유 번호 | 1, 2, 3 |
| `coupon_code` | VARCHAR(20) | 쿠폰 코드 (영문+숫자 조합) | `'HANIP2025'`, `'SAVE10'` |
| `discount_rate` | INT | 할인율 (%) | 10, 20, 50 |
| `valid_until` | DATE | 쿠폰 만료일 | `'2025-12-31'` |

**힌트**:
- 만료일은 날짜 타입을 사용합니다.
- 날짜 형식은 `'YYYY-MM-DD'` 입니다.

**예상 결과** (`DESC coupons;` 실행 시):

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| id | int | YES | | NULL | |
| coupon_code | varchar(20) | YES | | NULL | |
| discount_rate | int | YES | | NULL | |
| valid_until | date | YES | | NULL | |

<details>
<summary>정답 보기</summary>

```sql
-- 쿠폰 테이블 생성
CREATE TABLE coupons (
    id             INT,
    coupon_code    VARCHAR(20),
    discount_rate  INT,
    valid_until    DATE
);

-- 구조 확인
DESC coupons;

-- 데이터가 잘 들어가는지 테스트 (선택)
INSERT INTO coupons (id, coupon_code, discount_rate, valid_until)
VALUES (1, 'HANIP2025', 20, '2025-12-31');

SELECT * FROM coupons;
```

**핵심 포인트**:
- `DATE` 타입은 `'YYYY-MM-DD'` 형식의 문자열로 값을 입력합니다.
- `discount_rate`가 소수점 없는 정수 %라면 `INT`가 적합합니다. 소수점이 필요하다면 `DECIMAL(5,2)`를 사용하세요.
- 쿠폰 코드(`coupon_code`)는 숫자가 포함되어 있어도 문자열 데이터이므로 `VARCHAR`를 사용합니다.

</details>

---

## 문제 5 ⭐⭐

> 한입배달 서비스 기획팀에서 "음식점에 별점을 표시하고 싶다"는 요구사항을 전달했습니다. 현재 `restaurants` 테이블의 구조를 확인한 뒤, `rating` 컬럼이 추가된 새 버전의 테이블을 작성해보세요.

**Step 1**: 현재 `restaurants` 테이블 구조를 확인하세요.

```sql
DESC restaurants;
```

현재 구조:

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| id | int | YES | | NULL | |
| name | varchar(50) | YES | | NULL | |
| category | varchar(20) | YES | | NULL | |

**Step 2**: 아래 조건으로 `restaurants` 테이블을 새로 작성하세요.

**추가 조건**:
- 기존 3개 컬럼은 유지합니다.
- `rating` 컬럼 추가: 별점 (예: 4.5, 3.0, 5.0) — 소수점 1자리까지 표현

**힌트**:
- 별점 4.5처럼 소수점이 있는 숫자는 `DECIMAL` 타입을 사용합니다.
- `DECIMAL(전체자릿수, 소수자릿수)` 형식으로 씁니다.
- 테이블을 다시 만들려면 먼저 기존 테이블을 삭제해야 합니다: `DROP TABLE restaurants;`

**예상 결과** (`DESC restaurants;` 실행 시):

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| id | int | YES | | NULL | |
| name | varchar(50) | YES | | NULL | |
| category | varchar(20) | YES | | NULL | |
| rating | decimal(2,1) | YES | | NULL | |

<details>
<summary>정답 보기</summary>

```sql
-- Step 1: 현재 구조 확인
DESC restaurants;

-- Step 2: 기존 테이블 삭제
DROP TABLE restaurants;

-- Step 3: rating 컬럼이 추가된 새 테이블 생성
CREATE TABLE restaurants (
    id        INT,
    name      VARCHAR(50),
    category  VARCHAR(20),
    rating    DECIMAL(2, 1)   -- 최대 2자리, 소수점 1자리 (예: 4.5, 5.0)
);

-- Step 4: 새 구조 확인
DESC restaurants;

-- Step 5: 별점 데이터가 잘 들어가는지 테스트 (선택)
INSERT INTO restaurants (id, name, category, rating)
VALUES (1, '부산갈매기네', '한식', 4.5);

SELECT * FROM restaurants;
```

**핵심 포인트**:
- `DECIMAL(2, 1)`: 전체 2자리, 소수점 이하 1자리 → 0.0 ~ 9.9 범위
- 별점이 10점 만점이라면 `DECIMAL(3, 1)` (예: 10.0)으로 바꿔야 합니다.
- `DROP TABLE`은 테이블 안의 **모든 데이터도 함께 삭제**됩니다. 주의하세요!
- Day 2에서는 `DROP TABLE` 없이 컬럼을 추가하는 `ALTER TABLE ... ADD COLUMN` 을 배웁니다.

</details>

---

## 문제 6 ⭐⭐⭐

> 한입배달 기획팀에서 새로운 기능 "공지사항 게시판"을 개발하기로 했습니다. 아직 테이블 설계가 없는 상태입니다. **공지사항을 저장할 테이블을 직접 설계하고 `CREATE TABLE` 문을 작성해보세요.**

**조건**:
- 테이블명은 자유롭게 결정하세요 (예: `notices`, `announcements` 등)
- **최소 5개 컬럼** 이상 포함해야 합니다.
- **아래 데이터 타입을 각각 최소 1번씩** 사용해야 합니다:
  - `INT`
  - `VARCHAR`
  - `DATE` 또는 `DATETIME`
  - `TEXT` (긴 글 저장용) 또는 `DECIMAL`

**설계 힌트**: 공지사항에 필요한 정보를 생각해보세요.
- 공지 번호는? 제목은? 내용은? 언제 작성됐나? 누가 작성했나? 조회수는? 중요 공지인가?

**예상 결과**: 본인이 설계한 테이블에 맞는 `DESC 테이블명;` 결과가 나와야 합니다.

> 이 문제에는 **정해진 정답이 없습니다.** 스스로 설계한 테이블을 강사 또는 동료에게 설명해보세요!

<details>
<summary>정답 예시 보기 (참고용 — 다양한 정답이 가능합니다)</summary>

```sql
-- 공지사항 테이블 설계 예시
CREATE TABLE notices (
    id           INT,             -- 공지 번호 (정수)
    title        VARCHAR(100),    -- 제목 (최대 100자)
    content      TEXT,            -- 본문 내용 (긴 글)
    author       VARCHAR(30),     -- 작성자 이름
    view_count   INT,             -- 조회수
    is_important INT,             -- 중요 공지 여부 (1=중요, 0=일반)
    created_at   DATETIME,        -- 작성 일시
    expires_at   DATE             -- 공지 만료일
);

-- 구조 확인
DESC notices;

-- 테스트 데이터 삽입
INSERT INTO notices (id, title, content, author, view_count, is_important, created_at, expires_at)
VALUES (
    1,
    '[필독] 한입배달 서비스 점검 안내',
    '안녕하세요. 한입배달입니다. 2025년 1월 20일 새벽 2시부터 4시까지 서비스 점검이 있을 예정입니다.',
    '관리자',
    0,
    1,
    '2025-01-15 09:00:00',
    '2025-01-21'
);

SELECT * FROM notices;
```

**설계 시 생각해볼 점**:

| 컬럼 | 선택한 타입 | 이유 |
|------|-------------|------|
| `id` | INT | 공지 번호는 정수 |
| `title` | VARCHAR(100) | 제목은 짧은 문자열, 길이 제한 있음 |
| `content` | TEXT | 본문은 길이 제한 없는 긴 글 (최대 65,535자) |
| `author` | VARCHAR(30) | 사람 이름은 짧은 문자열 |
| `view_count` | INT | 조회수는 정수 |
| `is_important` | INT | 0(일반)/1(중요) 플래그, BOOLEAN과 유사 |
| `created_at` | DATETIME | 날짜+시간 모두 필요 |
| `expires_at` | DATE | 만료일은 날짜만 필요 |

**더 생각해볼 것**: Day 2에서 제약조건을 배우면 이 테이블에 어떤 제약조건을 추가할 수 있을까요?
- `id`에 PRIMARY KEY?
- `title`에 NOT NULL?
- `view_count`에 DEFAULT 0?

</details>

---

## 오늘 실습 마무리 체크리스트

실습을 마쳤다면 아래 항목을 확인해보세요.

- [ ] 문제 1: `hanip_delivery` DB를 만들고 `USE`로 선택했다
- [ ] 문제 2: `delivery_riders` 테이블을 만들고 `DESC`로 구조를 확인했다
- [ ] 문제 3: `SHOW TABLES`로 테이블 목록을 확인했다
- [ ] 문제 4: `coupons` 테이블에 `DATE` 타입 컬럼을 포함해서 만들었다
- [ ] 문제 5: `DECIMAL` 타입을 사용해 `rating` 컬럼이 있는 `restaurants` 테이블을 재작성했다
- [ ] 문제 6: 최소 5개 컬럼, 4가지 이상의 타입을 사용해 테이블을 스스로 설계했다

---

> **다음 시간 예고**: Day 2에서는 지금 만든 테이블에 제약조건을 추가해서 "아무 데이터나 들어가는" 문제를 해결합니다. 오늘 만든 테이블들이 그대로 사용되니 Workbench를 닫기 전에 실습 내용을 저장해두세요!

---

*한입배달 MySQL 10일 완성 과정 — Day 1 실습 문제*
