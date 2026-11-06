# Ch11. 트리거 — 데이터가 바뀌면 자동으로

> **PART 4 · 서버 프로그래밍** | 3시간 | 난이도 ★★★
> 이전: [Ch10. 뷰·인덱스·사용자 관리](../ch10-view-index-user/README.md) | 다음: [Ch12. 저장 프로시저와 함수](../ch12-procedure/README.md)

## 수업 준비

이 챕터 폴더의 **`setup.sql`**을 Workbench에서 열어 전체 실행(`Ctrl+Shift+Enter`)하세요. 오늘의 DB **`hanip_delivery11`**가 만들어집니다.

```sql
USE hanip_delivery11;
SELECT @@autocommit, @@sql_safe_updates;   -- 1, 1 (Workbench 기본값)
```

> 오늘부터 SQL 안에 `;`가 여러 개 들어가는 **본문(BEGIN … END)**을 씁니다. Workbench에서 `DELIMITER` 사용법(2-2절)을 꼭 먼저 익히세요.

## 오늘의 요청

> **From.** 운영팀 박 팀장 · 정산팀 정 대리
>
> 1. 사장님이 메뉴 가격을 바꿔도 **언제, 얼마에서 얼마로** 바꿨는지 기록이 안 남아요. 고객 분쟁이 나면 증거가 없습니다.
> 2. 주문 상태(접수 → 조리중 → 배달중 → 배달완료)가 **언제 바뀌었는지** 남겨 주세요. 그리고 **배달완료된 주문이 다시 '접수'로 돌아가는** 버그가 있었어요. DB에서 막아 주세요.
> 3. 가게 목록 화면이 매번 리뷰 평균을 계산해서 느려요. 가게 테이블에 **리뷰 수와 평점을 저장**하되, **실제 리뷰와 절대 어긋나면 안 됩니다.**
> 4. 앱 버그로 **품절 메뉴가 주문에 들어간** 적이 있어요. 앱도 고치고 있지만 DB에서도 한 번 더 막아 주세요.
>
> 개발자들이 쿼리마다 이걸 챙기라고 하면 꼭 누군가 빠뜨립니다. **누가 어떤 경로로 데이터를 바꾸든** 자동으로 처리되게 해 주세요.

"누가 바꾸든 자동으로" — 이것이 **트리거(TRIGGER)**입니다. 답은 [9절](#9-오늘의-요청-해결).

## 학습 목표

1. 트리거의 구성(이벤트 · 시점 · `FOR EACH ROW`)과 `NEW` · `OLD`를 설명한다.
2. `DELIMITER`를 써서 `BEGIN … END` 본문이 있는 트리거를 만든다.
3. `AFTER` 트리거로 **변경 이력**을 남기고, `BEFORE` 트리거로 **값을 보정**한다.
4. `SIGNAL`로 업무 규칙 위반을 **에러로 막는다**.
5. 트리거가 **같은 트랜잭션 안에서** 실행된다는 것을 확인하고, 실패·ROLLBACK 때의 동작을 설명한다.
6. 트리거를 쓸 때와 피할 때를 판단한다.

---

## 1. 트리거란

**트리거**는 테이블에 INSERT · UPDATE · DELETE가 일어날 때 **자동으로 실행되는 SQL 묶음**입니다. 현관문이 열리면 저절로 켜지는 센서등처럼, 누가 문을 열든(앱, Workbench, 다른 프로시저) 반드시 켜집니다.

| 구성 | 선택지 | 뜻 |
|---|---|---|
| **이벤트** | `INSERT` · `UPDATE` · `DELETE` | 무엇이 일어났을 때 |
| **시점** | `BEFORE` · `AFTER` | 그 변경이 테이블에 반영되기 전 / 후 |
| **단위** | `FOR EACH ROW` | 바뀐 **행마다** 한 번씩 (MySQL은 행 단위만 지원) |

트리거 안에서는 바뀌는 행을 두 개의 가상 행으로 봅니다.

| | `OLD` (바뀌기 전) | `NEW` (바뀐 후) |
|---|---|---|
| INSERT | 없음 | 새로 들어올 행 |
| UPDATE | 수정 전 값 | 수정 후 값 |
| DELETE | 지워질 행 | 없음 |

## 2. 첫 트리거 — 메뉴 가격 변경 이력

### 2-1. 이력 테이블

먼저 기록을 담을 테이블입니다.

```sql
CREATE TABLE menu_price_history (
    history_id  INT      NOT NULL AUTO_INCREMENT,
    menu_id     INT      NOT NULL,
    old_price   INT      NOT NULL,
    new_price   INT      NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_menu_price_history      PRIMARY KEY (history_id),
    CONSTRAINT fk_menu_price_history_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id)
) COMMENT '메뉴 가격 변경 이력';
```


### 2-2. DELIMITER — 본문 안의 `;` 지키기

트리거 본문에는 `;`로 끝나는 문장이 여러 개 들어갑니다. 그런데 Workbench는 `;`를 만나면 "문장 끝"으로 알고 거기서 잘라 서버에 보냅니다. 그래서 잠시 **문장 끝 표시를 `$$`로 바꿨다가**, 다 쓰고 나서 `;`로 되돌립니다.

```sql
DELIMITER $$          -- 지금부터 문장 끝은 $$
CREATE TRIGGER …
BEGIN
    문장1;            -- 이 ; 들은 본문의 일부로 서버에 그대로 전달된다
    문장2;
END $$                -- 여기서 CREATE TRIGGER 한 문장이 끝
DELIMITER ;           -- 다시 ; 로
```

> `DELIMITER`는 SQL이 아니라 **Workbench(클라이언트)에게 하는 지시**입니다. 서버는 이 단어를 보지 못합니다. `DELIMITER`와 기호 사이에는 공백이 필요하고, 줄 끝에 `;`를 붙이지 않습니다.

### 2-3. CREATE TRIGGER

```sql
DELIMITER $$
CREATE TRIGGER trg_menus_price_history
AFTER UPDATE ON menus
FOR EACH ROW
BEGIN
    IF OLD.price <> NEW.price THEN
        INSERT INTO menu_price_history (menu_id, old_price, new_price)
        VALUES (NEW.menu_id, OLD.price, NEW.price);
    END IF;
END $$
DELIMITER ;
```


| 부분 | 뜻 |
|---|---|
| `trg_menus_price_history` | 이름 규칙: `trg_테이블_역할` |
| `AFTER UPDATE ON menus` | `menus`가 수정된 **후에** |
| `FOR EACH ROW` | 수정된 행마다 |
| `IF OLD.price <> NEW.price` | 가격이 **실제로 바뀐 경우만** (설명만 고친 경우는 기록 안 함) |

### 2-4. 동작 확인

돼지국밥을 10,500원으로 올리고, 순대국밥은 설명만 고쳐 봅니다.

```sql
UPDATE menus SET price = 10500 WHERE menu_id = 1;
UPDATE menus SET description = '토렴한 순대국밥' WHERE menu_id = 2;

SELECT history_id, menu_id, old_price, new_price
FROM menu_price_history;
```

<sub>▶ 실행 결과 · 1행</sub>

| history_id | menu_id | old_price | new_price |
|---|---|---|---|
| 1 | 1 | 10000 | 10500 |


UPDATE문에는 이력을 남기라는 말이 한 줄도 없지만 기록이 남았습니다. 설명만 바꾼 2번 메뉴는 기록되지 않았습니다.

> `changed_at`에는 **실제로 실행한 시각**(`CURRENT_TIMESTAMP`)이 들어갑니다. 교안의 데이터 기준일(2026-06-30)과 다르니 결과표에서는 생략했습니다.

여러 행을 한 번에 바꾸면 트리거는 **행마다** 실행됩니다. 해운대명가밀면(3번 가게)의 메뉴 4개를 모두 500원 올립니다.

```sql
UPDATE menus SET price = price + 500 WHERE restaurant_id = 3;

SELECT menu_id, old_price, new_price
FROM menu_price_history
WHERE history_id > 1
ORDER BY menu_id;
```

<sub>▶ 실행 결과 · 4행</sub>

| menu_id | old_price | new_price |
|---|---|---|
| 11 | 9000 | 9500 |
| 12 | 9000 | 9500 |
| 13 | 11000 | 11500 |
| 14 | 7000 | 7500 |


UPDATE 한 문장에 이력 4행. `FOR EACH ROW`의 의미입니다.

## 3. BEFORE 트리거 — 들어가기 전에 값을 고친다

### 3-1. NEW를 고칠 수 있는 건 BEFORE뿐

`BEFORE` 트리거는 행이 테이블에 들어가기 **전에** 실행되므로 `SET NEW.열 = 값`으로 **들어갈 값을 바꿀 수 있습니다.** 주문 상세에 단가가 비어 있으면 현재 메뉴 가격으로 채우는 트리거입니다.

```sql
DELIMITER $$
CREATE TRIGGER trg_order_items_fill_price
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    IF NEW.unit_price IS NULL OR NEW.unit_price = 0 THEN
        SET NEW.unit_price = (SELECT price FROM menus WHERE menu_id = NEW.menu_id);
    END IF;
END $$
DELIMITER ;
```


> `order_items.unit_price`는 `NOT NULL`이지만, MySQL은 **BEFORE 트리거를 먼저 실행한 뒤** NOT NULL을 검사합니다. 그래서 단가를 NULL(또는 0)로 보내도 트리거가 채워 넣으면 통과합니다. 이 트리거는 6-3절 주문 트랜잭션에서 확인합니다.

`AFTER` 트리거에서는 이미 행이 저장된 뒤라 `NEW`를 바꿀 수 없습니다.

```sql
DELIMITER $$
CREATE TRIGGER trg_bad_after
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    SET NEW.unit_price = 0;
END $$
DELIMITER ;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1362. Updating of NEW row is not allowed in after trigger
```


### 3-2. BEFORE와 AFTER, 언제 무엇을

| 시점 | 할 수 있는 것 | 대표 용도 |
|---|---|---|
| `BEFORE` | `NEW` 값 바꾸기, `SIGNAL`로 막기 | 값 보정 · 기본값 채우기 · **검증** |
| `AFTER` | 다른 테이블에 기록 · 갱신 | **이력(감사 로그)** · 집계 동기화 |

> 원칙: **막을 거면 BEFORE, 기록할 거면 AFTER.** 막을 일을 AFTER에서 하면 이미 바뀐 뒤라 의미가 없고, 기록을 BEFORE에서 하면 뒤이어 제약조건에 걸려 실패한 변경까지 기록될 수 있습니다(트랜잭션이 함께 취소되긴 하지만, 의도가 흐려집니다).

## 4. SIGNAL — 업무 규칙을 에러로 막는다

### 4-1. 주문 상태 이력과 잘못된 상태 변경

두 번째 요청입니다. 상태 이력 테이블과 트리거 두 개(검증용 BEFORE, 기록용 AFTER)를 만듭니다.

```sql
CREATE TABLE order_status_logs (
    log_id       INT          NOT NULL AUTO_INCREMENT,
    order_id     INT          NOT NULL,
    from_status  VARCHAR(10)  NOT NULL,
    to_status    VARCHAR(10)  NOT NULL,
    changed_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_order_status_logs       PRIMARY KEY (log_id),
    CONSTRAINT fk_order_status_logs_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
) COMMENT '주문 상태 변경 이력';

DELIMITER $$
CREATE TRIGGER trg_orders_status_check
BEFORE UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status IN ('배달완료', '취소') AND NEW.status <> OLD.status THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '배달완료 또는 취소된 주문은 상태를 바꿀 수 없습니다.';
    END IF;

    IF NEW.status = '배달완료' AND NEW.delivered_at IS NULL THEN
        SET NEW.delivered_at = NOW();
    END IF;
END $$

CREATE TRIGGER trg_orders_status_log
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO order_status_logs (order_id, from_status, to_status)
        VALUES (NEW.order_id, OLD.status, NEW.status);
    END IF;
END $$
DELIMITER ;
```


| 문법 | 뜻 |
|---|---|
| `SIGNAL SQLSTATE '45000'` | 에러를 **직접 일으킨다**. `45000` = "사용자 정의 예외" |
| `SET MESSAGE_TEXT = '…'` | 에러 메시지 (Workbench 출력 창, 앱의 예외 메시지에 그대로 표시) |
| `SET NEW.delivered_at = NOW()` | 배달완료로 바뀌는 순간 완료 시각을 자동으로 |

### 4-2. 정상 흐름

방금 들어온 563번 주문(해운대명가밀면, 접수)을 끝까지 진행합니다.

```sql
UPDATE orders SET status = '조리중' WHERE order_id = 563;
UPDATE orders SET status = '배달중', rider_id = 2 WHERE order_id = 563;
UPDATE orders SET status = '배달완료' WHERE order_id = 563;

SELECT log_id, order_id, from_status, to_status FROM order_status_logs;
```

<sub>▶ 실행 결과 · 3행</sub>

| log_id | order_id | from_status | to_status |
|---|---|---|---|
| 1 | 563 | 접수 | 조리중 |
| 2 | 563 | 조리중 | 배달중 |
| 3 | 563 | 배달중 | 배달완료 |


```sql
SELECT order_id, status, rider_id, delivered_at IS NOT NULL AS has_delivered_at
FROM orders WHERE order_id = 563;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | status | rider_id | has_delivered_at |
|---|---|---|---|
| 563 | 배달완료 | 2 | 1 |


`delivered_at`은 아무도 넣지 않았는데 BEFORE 트리거가 채웠습니다.

### 4-3. 규칙 위반

배달완료된 563번 주문을 다시 '접수'로 되돌려 봅니다.

```sql
UPDATE orders SET status = '접수' WHERE order_id = 563;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1644. 배달완료 또는 취소된 주문은 상태를 바꿀 수 없습니다.
```


`1644`는 `SIGNAL`로 일으킨 에러의 번호입니다. UPDATE는 실행되지 않았고, AFTER 트리거도 돌지 않았으므로 이력도 그대로입니다.

```sql
SELECT order_id, status FROM orders WHERE order_id = 563;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | status |
|---|---|
| 563 | 배달완료 |


> CHECK 제약조건(Ch07)은 **한 행 안의 값**만 검사할 수 있습니다. "이전 값이 무엇이었는지"(`OLD`)나 "다른 테이블의 값"에 따른 규칙은 트리거 + `SIGNAL`의 몫입니다.

## 5. 반정규화 동기화 — 가게 평점

### 5-1. 열 추가와 초기값

세 번째 요청입니다. Ch09에서 "반정규화는 이유 + **감시**"라고 했습니다. 트리거는 그 감시를 **자동으로 맞춰 주는** 장치입니다.

평균(`avg_rating`)을 저장하면 리뷰가 하나 늘 때마다 평균을 다시 계산하기가 까다롭습니다. 대신 **리뷰 수와 별점 합계**를 저장하고, 평균은 나눠서 구합니다. 더하기·빼기만으로 정확하게 유지됩니다.

```sql
ALTER TABLE restaurants
    ADD COLUMN review_count INT NOT NULL DEFAULT 0 COMMENT '리뷰 수 (트리거로 유지)',
    ADD COLUMN rating_sum   INT NOT NULL DEFAULT 0 COMMENT '별점 합계 (트리거로 유지)';

UPDATE restaurants r
JOIN (
    SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
    FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
    GROUP BY o.restaurant_id
) t ON r.restaurant_id = t.restaurant_id
SET r.review_count = t.cnt, r.rating_sum = t.total
WHERE r.restaurant_id > 0;   -- 안전 업데이트 모드: 키 열 조건 (전체 가게가 대상)

SELECT restaurant_id, name, review_count, rating_sum,
    ROUND(rating_sum / NULLIF(review_count, 0), 2) AS avg_rating
FROM restaurants
WHERE restaurant_id IN (1, 15);
```

<sub>▶ 실행 결과 · 2행</sub>

| restaurant_id | name | review_count | rating_sum | avg_rating |
|---|---|---|---|---|
| 1 | 서면옛날돼지국밥 | 24 | 107 | 4.46 |
| 15 | 전포동오일파스타 | 0 | 0 | NULL |


### 5-2. INSERT · DELETE 트리거

리뷰에는 가게 번호가 없으므로, 트리거 안에서 **변수**에 가게 번호를 찾아 담습니다(`DECLARE` · `SELECT … INTO`는 Ch12에서 자세히).

```sql
DELIMITER $$
CREATE TRIGGER trg_reviews_stats_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = NEW.order_id;

    UPDATE restaurants
    SET review_count = review_count + 1,
        rating_sum   = rating_sum + NEW.rating
    WHERE restaurant_id = v_restaurant_id;
END $$

CREATE TRIGGER trg_reviews_stats_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_restaurant_id INT;
    SELECT restaurant_id INTO v_restaurant_id FROM orders WHERE order_id = OLD.order_id;

    UPDATE restaurants
    SET review_count = review_count - 1,
        rating_sum   = rating_sum - OLD.rating
    WHERE restaurant_id = v_restaurant_id;
END $$
DELIMITER ;
```


### 5-3. 확인

서면옛날돼지국밥의 549번 주문에 5점 리뷰가 달렸습니다.

```sql
INSERT INTO reviews (order_id, rating, content, created_at)
VALUES (549, 5, '국물이 진하고 고기가 많아요', '2026-06-30 18:58:00');

SELECT restaurant_id, review_count, rating_sum,
    ROUND(rating_sum / review_count, 2) AS avg_rating
FROM restaurants WHERE restaurant_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| restaurant_id | review_count | rating_sum | avg_rating |
|---|---|---|---|
| 1 | 25 | 112 | 4.48 |


24개 → 25개. 그 리뷰가 신고로 삭제되면:

```sql
DELETE FROM reviews WHERE order_id = 549;

SELECT restaurant_id, review_count, rating_sum,
    ROUND(rating_sum / review_count, 2) AS avg_rating
FROM restaurants WHERE restaurant_id = 1;
```

<sub>▶ 실행 결과 · 1행</sub>

| restaurant_id | review_count | rating_sum | avg_rating |
|---|---|---|---|
| 1 | 24 | 107 | 4.46 |


원래대로 돌아왔습니다. Ch09의 감시 쿼리로 전체 가게를 검증합니다.

```sql
SELECT COUNT(*) AS mismatched_restaurants
FROM restaurants r
LEFT JOIN (
    SELECT o.restaurant_id, COUNT(*) AS cnt, SUM(rv.rating) AS total
    FROM reviews rv JOIN orders o ON rv.order_id = o.order_id
    GROUP BY o.restaurant_id
) t ON r.restaurant_id = t.restaurant_id
WHERE r.review_count <> COALESCE(t.cnt, 0)
   OR r.rating_sum   <> COALESCE(t.total, 0);
```

<sub>▶ 실행 결과 · 1행</sub>

| mismatched_restaurants |
|---|
| 0 |


> 별점을 **수정**하는 경우(UPDATE)는 아직 반영되지 않습니다. 실습 8번에서 직접 완성합니다.

## 6. 트리거와 트랜잭션

### 6-1. 트리거는 같은 트랜잭션 안에서 실행된다

트리거가 한 일(이력 INSERT, 통계 UPDATE)은 **트리거를 일으킨 문장과 같은 트랜잭션**에 속합니다. 그래서 ROLLBACK하면 함께 사라집니다.

```sql
START TRANSACTION;

UPDATE menus SET price = 11000 WHERE menu_id = 2;

SELECT (SELECT price FROM menus WHERE menu_id = 2) AS price_in_tx,
       (SELECT COUNT(*) FROM menu_price_history)    AS history_in_tx;
```

<sub>▶ 실행 결과 · 1행</sub>

| price_in_tx | history_in_tx |
|---|---|
| 11000 | 6 |


```sql
ROLLBACK;

SELECT (SELECT price FROM menus WHERE menu_id = 2) AS price_after_rollback,
       (SELECT COUNT(*) FROM menu_price_history)    AS history_after_rollback;
```

<sub>▶ 실행 결과 · 1행</sub>

| price_after_rollback | history_after_rollback |
|---|---|
| 10000 | 5 |


가격도, 이력도 함께 되돌아갔습니다. "가격은 안 바뀌었는데 이력만 남는" 일은 생기지 않습니다. 트리거와 원래 문장은 **원자적**(Ch08 ACID의 A)입니다.

### 6-2. 트리거가 실패하면 문장 전체가 실패한다

네 번째 요청입니다. 품절 메뉴는 주문 상세에 들어가지 못하게 막습니다. 3-1절 단가 채우기 트리거와 같은 시점(`BEFORE INSERT`)이므로 **`FOLLOWS`**로 실행 순서를 정해 줍니다.

```sql
DELIMITER $$
CREATE TRIGGER trg_order_items_check_sold_out
BEFORE INSERT ON order_items
FOR EACH ROW
FOLLOWS trg_order_items_fill_price
BEGIN
    IF (SELECT is_sold_out FROM menus WHERE menu_id = NEW.menu_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '품절된 메뉴는 주문할 수 없습니다.';
    END IF;
END $$
DELIMITER ;
```


점심 재료가 떨어져 서면옛날돼지국밥의 **순대국밥**(2번)이 품절됐습니다. 조리중인 562번 주문에 고객이 메뉴 세 줄을 추가하려 하는데, **한 문장**으로 넣고 그중 두 번째가 품절이라면?

```sql
UPDATE menus SET is_sold_out = TRUE WHERE menu_id = 2;

SELECT menu_id, name, price, is_sold_out FROM menus WHERE menu_id IN (2, 4, 5);
```

<sub>▶ 실행 결과 · 3행</sub>

| menu_id | name | price | is_sold_out |
|---|---|---|---|
| 2 | 순대국밥 | 10000 | 1 |
| 4 | 수육 백반 | 13000 | 0 |
| 5 | 수육 (중) | 22000 | 0 |


```sql
INSERT INTO order_items (order_id, menu_id, quantity, unit_price) VALUES
    (562, 4, 1, 0),
    (562, 2, 1, 0),
    (562, 5, 1, 0);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1644. 품절된 메뉴는 주문할 수 없습니다.
```


```sql
SELECT COUNT(*) AS items_of_order_562 FROM order_items WHERE order_id = 562;
```

<sub>▶ 실행 결과 · 1행</sub>

| items_of_order_562 |
|---|
| 2 |


원래 있던 2줄 그대로입니다. 첫 줄(수육 백반)은 트리거를 통과했지만 **한 줄도 들어가지 않았습니다.** InnoDB에서 한 문장은 그 자체로 원자적이라, 중간에 실패하면 그 문장이 바꾼 것은 전부 취소됩니다(**문장 단위 원자성**).

### 6-3. 주문 접수 트랜잭션에 적용

Ch08의 주문 접수 트랜잭션에 트리거가 끼어들면 어떻게 될까요? 최수아 님(4번 고객)이 남천동마라공방(5번 가게)에서 마라탕과 **품절된** 마라 볶음면을 주문합니다. 앱은 단가를 `0`으로 보내고 트리거가 채우게 합니다.

```sql
START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method, delivery_fee, ordered_at)
VALUES (4, 5, '접수', '카드', 3000, '2026-06-30 19:05:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price) VALUES (@order_id, 21, 1, 0);

SELECT order_id, menu_id, quantity, unit_price FROM order_items WHERE order_id = @order_id;
```

<sub>▶ 실행 결과 · 1행</sub>

| order_id | menu_id | quantity | unit_price |
|---|---|---|---|
| 564 | 21 | 1 | 13000 |


첫 메뉴는 들어갔고 단가도 트리거가 채웠습니다. 이제 품절 메뉴입니다.

```sql
INSERT INTO order_items (order_id, menu_id, quantity, unit_price) VALUES (@order_id, 24, 1, 0);
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1644. 품절된 메뉴는 주문할 수 없습니다.
```


Ch08에서 배운 대로, **에러가 났다고 자동으로 ROLLBACK되지 않습니다.** 주문 머리와 첫 메뉴는 아직 트랜잭션 안에 남아 있습니다. 직접 취소합니다.

```sql
ROLLBACK;

SELECT COUNT(*) AS orders_total,
       (SELECT COUNT(*) FROM order_items WHERE order_id = @order_id) AS items_of_failed_order
FROM orders;
```

<sub>▶ 실행 결과 · 1행</sub>

| orders_total | items_of_failed_order |
|---|---|
| 563 | 0 |


> 정리하면: 트리거의 `SIGNAL`은 **그 문장 하나**를 실패시킵니다. 트랜잭션 전체를 되돌릴지는 **트랜잭션을 연 쪽(앱 · 프로시저)**이 정합니다. 이 판단을 프로시저 안에 넣는 방법이 Ch12입니다.

### 6-4. 트리거 안에서 하면 안 되는 것

| 금지 | 에러 | 이유 |
|---|---|---|
| `COMMIT` · `ROLLBACK` · `START TRANSACTION` | 1422 | 트리거는 바깥 트랜잭션의 일부. 혼자 확정할 수 없음 |
| `CREATE` · `ALTER` · `DROP` 등 DDL | 1422 | DDL은 암묵적 COMMIT을 일으킴 (Ch08) |
| 트리거가 걸린 **그 테이블**을 수정 | 1442 | 무한 반복 위험. 같은 행은 `BEFORE`에서 `SET NEW.열`로 |
| 결과를 돌려주는 `SELECT` | 1415 | 트리거는 결과를 받을 사람이 없음. `SELECT … INTO 변수`는 가능 |

```sql
DELIMITER $$
CREATE TRIGGER trg_bad_commit
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    COMMIT;
END $$
DELIMITER ;
```

<sub>▶ 실행 결과 · 에러</sub>

```text
Error Code: 1422. Explicit or implicit commit is not allowed in stored function or trigger.
```


## 7. 트리거 관리

```sql
SELECT trigger_name AS trigger_name, event_object_table AS table_name,
    action_timing AS timing, event_manipulation AS event, action_order AS action_order
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY event_object_table, event_manipulation, action_timing, action_order;
```

<sub>▶ 실행 결과 · 7행</sub>

| trigger_name | table_name | timing | event | action_order |
|---|---|---|---|---|
| trg_menus_price_history | menus | AFTER | UPDATE | 1 |
| trg_order_items_fill_price | order_items | BEFORE | INSERT | 1 |
| trg_order_items_check_sold_out | order_items | BEFORE | INSERT | 2 |
| trg_orders_status_check | orders | BEFORE | UPDATE | 1 |
| trg_orders_status_log | orders | AFTER | UPDATE | 1 |
| trg_reviews_stats_insert | reviews | AFTER | INSERT | 1 |
| trg_reviews_stats_delete | reviews | AFTER | DELETE | 1 |


```sql
SHOW TRIGGERS;                                    -- 현재 DB의 트리거 목록
SHOW CREATE TRIGGER trg_menus_price_history;      -- 본문 확인
DROP TRIGGER IF EXISTS trg_menus_price_history;   -- 삭제 (수정 명령은 없음 → 삭제 후 다시 생성)
```

> 같은 테이블 · 같은 이벤트 · 같은 시점에 트리거가 여러 개면 만든 순서대로 실행됩니다. 순서를 지정하려면 `FOLLOWS 다른트리거` / `PRECEDES 다른트리거`(6-2절).

## 8. 언제 쓰고, 언제 피하나

트리거는 강력하지만 **보이지 않는 코드**입니다. `UPDATE menus …` 한 줄이 실제로는 다른 테이블 세 곳을 바꾸고 있어도, 쿼리만 봐서는 알 수 없습니다.

| 쓰기 좋은 곳 | 피해야 할 곳 |
|---|---|
| **감사 로그 · 변경 이력** — 어떤 경로로 바뀌든 반드시 남아야 함 | 복잡한 업무 흐름(결제 → 포인트 → 알림 …) — 앱이나 프로시저로 |
| **반정규화 값 동기화** — 리뷰 수 · 합계 | 외부 시스템 호출(메일, 푸시) — DB 안에서 불가능하고 느려짐 |
| **마지막 방어선 검증** — 앱 버그가 있어도 지켜야 할 규칙 | 트리거가 트리거를 부르는 연쇄 — 디버깅 지옥 |
| 열 기본값 · 보정 — 단가 채우기, 완료 시각 기록 | 대량 작업이 잦은 테이블 — 행마다 실행되어 느려짐 |

> 팀에 트리거가 있다면 **문서화**가 필수입니다. 테이블 COMMENT나 README에 "이 테이블에는 트리거 ○개가 있다"를 적어 두세요. 새로 온 개발자가 "왜 이 테이블이 저절로 바뀌지?"로 하루를 날리지 않도록.

## 9. 오늘의 요청 해결

> **To.** 운영팀 박 팀장 · 정산팀 정 대리
>
> | 요청 | 트리거 | 동작 |
> |---|---|---|
> | ① 가격 변경 기록 | `trg_menus_price_history` (AFTER UPDATE) | 가격이 바뀐 행마다 이전·이후 가격과 시각 기록 |
> | ② 상태 이력 | `trg_orders_status_log` (AFTER UPDATE) | 상태가 바뀔 때마다 기록 |
> | ② 잘못된 상태 변경 차단 | `trg_orders_status_check` (BEFORE UPDATE) | 완료·취소 주문 변경 시 에러, 배달완료 시각 자동 기록 |
> | ③ 가게 평점 | `trg_reviews_stats_insert` · `_delete` (AFTER) | 리뷰 수·별점 합계 자동 유지, 감시 쿼리 불일치 0건 |
> | ④ 품절 메뉴 차단 | `trg_order_items_check_sold_out` (BEFORE INSERT) | 품절 메뉴가 들어오면 에러 → 앱은 ROLLBACK |
> | (덤) 단가 자동 입력 | `trg_order_items_fill_price` (BEFORE INSERT) | 단가 0이면 현재 메뉴 가격으로 |
>
> 앱에서 어떤 쿼리로 바꾸든, Workbench에서 직접 바꾸든 자동으로 적용됩니다. 단, ④에서 에러가 나면 **트랜잭션을 ROLLBACK하는 것은 앱의 책임**입니다.

## 정리

| 개념 | 핵심 |
|---|---|
| 트리거 | INSERT · UPDATE · DELETE 때 자동 실행. `BEFORE` / `AFTER`, `FOR EACH ROW` |
| `NEW` · `OLD` | INSERT는 NEW만, DELETE는 OLD만, UPDATE는 둘 다 |
| `DELIMITER $$` | 본문의 `;`를 지키기 위한 **클라이언트 지시**. 끝나면 `DELIMITER ;` |
| BEFORE | `SET NEW.열` 값 보정, `SIGNAL`로 차단 — **막을 거면 BEFORE** |
| AFTER | 이력 · 동기화 — **기록할 거면 AFTER** |
| `SIGNAL SQLSTATE '45000'` | 사용자 정의 에러(1644). `MESSAGE_TEXT`로 메시지 |
| 트리거와 트랜잭션 | 같은 트랜잭션. ROLLBACK하면 트리거가 한 일도 취소 |
| 트리거 실패 | 그 **문장** 전체 취소(문장 단위 원자성). 트랜잭션 ROLLBACK은 여는 쪽 책임 |
| 금지 | 트리거 안 COMMIT · DDL(1422), 자기 테이블 수정(1442) |

## 다음 챕터 예고

> **From.** 개발팀 한 팀장
> 트리거 덕분에 품절 메뉴는 막혔는데, 에러가 나면 ROLLBACK하는 코드를 앱마다(웹, 안드로이드, iOS, 관리자) **네 번** 써야 해요. 주문 접수 로직 자체를 DB에 **하나로 저장**해 두고 `CALL 주문하기(…)`로 부를 수는 없나요? 에러가 나면 알아서 ROLLBACK하고, 실패 이유도 기록해서요.
>
> 그리고 정산팀 요청: 매달 1일에 **전 고객 등급을 다시 매기는** 작업, 고객 한 명씩 조건을 따져서 처리해 주세요.

조건문 · 반복문 · 예외 처리까지 갖춘 **저장 프로시저** — Ch12입니다.

<!-- lecture:auto -->
