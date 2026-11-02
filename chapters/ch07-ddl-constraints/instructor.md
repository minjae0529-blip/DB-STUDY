# Ch07 강사 노트

> PART 2(쓰기)의 시작입니다. 학생들이 처음으로 **DB를 바꾸는** 날이라 실수가 많습니다. 챕터별 DB 덕분에 무엇을 망쳐도 `setup.sql`의 DROP 줄 주석만 풀면 처음 상태로 돌아간다는 점을 먼저 안심시키세요.

## 시간 배분 (3시간)

| 시간 | 활동 | 자료 | 포인트 |
|---|---|---|---|
| 수업 전 | 수업 준비 | `setup.sql` | `hanip_delivery07` 생성 확인 |
| 0:00–0:10 | Ch06 복습 퀴즈 | `ch06/quiz.md` | |
| 0:10–0:15 | 오늘의 요청 | README 도입 | 요청서의 규칙 4개를 칠판에 적어 두고, 수업 끝에 하나씩 지우기 |
| 0:15–0:35 | SHOW CREATE TABLE 해부 | README 1절 | **"제약조건 한 줄 = 비즈니스 규칙 한 줄"** |
| 0:35–1:00 | 데이터 타입 | README 2절 | FLOAT 오차와 엄격 모드 에러를 직접 실행 |
| 1:00–1:10 | 규칙 없는 테이블 | README 3절 | 음수 쿠폰이 들어가는 장면 → 문제의식 |
| 1:10–1:20 | 휴식 | | |
| 1:20–1:50 | 제약조건 · coupons | README 4절 | 위반 INSERT 4개를 학생이 예측 → 실행 |
| 1:50–2:10 | FK · M:N · ON DELETE | README 5절 | 1452와 1451의 차이(자식 쪽 / 부모 쪽) |
| 2:10–2:20 | ALTER · DROP · TRUNCATE | README 6~7절 | 3730(참조된 테이블 DROP)도 보여 주기 |
| 2:20–2:55 | 실습 | `practice.md` | 1~6 개인, 7~8 짝 설계. 8번은 답이 하나가 아님 — 2~3팀 발표 |
| 2:55–3:00 | 요청 해결 + 예고 | README 9절 | 칠판의 규칙 4개가 모두 지워졌는지 확인 |

## 강조할 것

1. **규칙은 DB가 강제한다.** "애플리케이션에서 검사하면 되지 않나요?"라는 질문이 꼭 나옵니다. 앱은 여러 개(웹·앱·관리자·배치)이고 버그는 언제나 생기지만, DB는 하나입니다.
2. **제약조건에 이름을 붙인다.** 에러 메시지에 `ck_coupons_value`가 그대로 나오는 장면을 보여 주면 납득합니다.
3. **CASCADE는 신중히.** 실습 7번(메뉴 옵션 = CASCADE OK)과 주문 데이터(CASCADE 금지)를 대비시키세요.
4. **DROP 전에 `SELECT DATABASE();`** — 오늘부터 습관화. 챕터별 DB를 쓰니 "지금 몇 번 DB인지" 확인하는 연습이 자연스럽게 됩니다.

## 자주 나오는 질문

| 질문 | 답변 요지 |
|---|---|
| "VARCHAR(255)로 다 하면 안 돼요?" | 동작은 함. 하지만 길이 제한도 검증 규칙의 일부. 이름 255자는 이상 데이터 |
| "PK를 쿠폰 코드로 하면 안 돼요?" | 코드는 바뀔 수 있고(오타 수정, 리브랜딩) 다른 테이블이 참조 중이면 바꾸기 어려움. 의미 없는 번호(대리키)를 PK로, 코드는 UNIQUE로 |
| "UNIQUE 열에 NULL 여러 개 들어가요?" | MySQL은 허용. `used_order_id`가 그래서 UNIQUE + NULL 허용으로 동작 |
| "CHECK는 MySQL 5.7에서도 돼요?" | 5.7은 문법만 받고 **무시**함. 8.0.16부터 실제로 검사. 버전 확인 중요 |
| "TIMESTAMP와 DATETIME 중 뭐 써요?" | TIMESTAMP는 2038년 한계와 시간대 변환이 있음. 업무 일시는 DATETIME 권장 |
| "check_clause의 한글이 깨져요" | MySQL 8.0 information_schema의 알려진 표시 문제. `SHOW CREATE TABLE`로 확인 |

## 자주 하는 실수

| 실수 | 증상 | 대처 |
|---|---|---|
| 같은 CREATE를 두 번 실행 | 1050 Table already exists | `DROP TABLE IF EXISTS` 또는 DB 초기화 |
| 제약 이름 중복 (다른 테이블과 같은 이름) | 3822 / 1826 Duplicate check/foreign key constraint name | 이름에 테이블명 넣기 |
| FK의 타입이 부모 PK와 다름 | 3780 incompatible | 타입·부호 일치 |
| 부모보다 자식을 먼저 CREATE | 1824 Failed to open the referenced table | 만드는 순서: 부모 → 자식 |
| 자식이 있는 부모 DROP | 3730 | 지우는 순서: 자식 → 부모 |
| NOT NULL 열 생략 | 1364 doesn't have a default value | 값 지정 또는 DEFAULT |
