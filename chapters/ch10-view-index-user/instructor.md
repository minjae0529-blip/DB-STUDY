# Ch10 강사 노트

> 마지막 챕터입니다. 뷰·인덱스·권한은 각각 하나의 과정이 될 만큼 깊지만, 오늘의 목표는 **"운영 DB에서 이것들을 왜 쓰는지" 감을 잡는 것**입니다. 특히 인덱스는 563행 데이터로는 체감 속도 차이가 없으니, **`EXPLAIN`의 `type`과 `rows`가 근거**라는 점을 처음부터 분명히 하세요.

## 시간 배분 (3시간)

| 시간 | 활동 | 자료 | 포인트 |
|---|---|---|---|
| 수업 전 | 수업 준비 | `setup.sql` | **root로 실행.** 맨 끝 ANALYZE TABLE이 통계를 갱신 |
| 0:00–0:10 | Ch09 복습 퀴즈 | `ch09/quiz.md` | |
| 0:10–0:15 | 오늘의 요청 | README 도입 | 세 요청 = 뷰 · 인덱스 · 권한 |
| 0:15–0:55 | 뷰 | README 1절 | 금액 뷰 → 리포트 뷰(뷰 위에 뷰) → CHECK OPTION → 마스킹 뷰 |
| 0:55–1:35 | 인덱스 | README 2절 | 찾아보기 비유 → EXPLAIN 읽기 → 생성 전후 → 열 가공 → 복합 인덱스 |
| 1:35–1:45 | 휴식 | | |
| 1:45–2:20 | 사용자 · 권한 · 역할 | README 3절 | **인턴 계정으로 직접 접속**해서 1142를 보여 주는 장면이 핵심 |
| 2:20–2:30 | 백업 | README 4절 | 01~10 전체 백업 명령을 함께 실행 (과정 기록 보관) |
| 2:30–2:40 | SQL 총정리 | README 5절 | 정보처리기사 분류표 |
| 2:40–3:00 | 실습 + 마무리 | `practice.md` | 9·10번은 계정을 만들어 직접 접속까지 해 보게 |

## 강조할 것

1. **뷰는 데이터를 저장하지 않는다.** 가장 흔한 오해입니다("뷰를 만들면 빨라지나요?" → 아니요, 매번 실행됩니다). 미리 계산해 저장하는 것은 Ch08·09의 요약 테이블입니다.
2. **성능은 `EXPLAIN`으로 본다.** `type`(ALL은 경고), `key`(무엇을 썼나), `rows`(몇 행 읽나). 이 세 개만 읽을 줄 알아도 충분합니다.
3. **열을 가공하지 마라.** `DATE(ordered_at) =`, `YEAR(…) =`는 학생들이 Ch03에서 배운 대로 쓰는 패턴이라 더 위험합니다. Ch03의 "반열린 구간"과 연결하세요.
4. **복합 인덱스는 전화번호부.** 성 → 이름 순. 이름만으로는 못 찾는다.
5. **최소 권한.** "root 비밀번호를 팀 단톡방에 공유하는 회사"가 실제로 많습니다. 계정은 사람·용도별로.

## 수업 운영 팁

- **계정 실습은 root로.** 학생이 `dev` 같은 일반 계정으로 접속해 있으면 `CREATE USER`에서 1227(권한 없음)이 납니다.
- 계정은 서버 전체에 속합니다. 학생들이 같은 서버(실습실 공용 서버)를 쓰면 `hanip_intern`이 서로 충돌하니, 그 경우 `hanip_intern_학번`처럼 이름을 나누게 하세요.
- MySQL에 **비밀번호 정책(validate_password)**이 켜져 있으면 약한 비밀번호가 1819로 거부됩니다. 예제 비밀번호(`Intern!2026`)는 대문자·소문자·숫자·특수문자를 모두 넣었습니다.
- 인덱스를 만들면 FK용 자동 인덱스가 **사라지는** 경우가 있습니다(새 인덱스가 FK 열로 시작하면 MySQL이 그것을 대신 씀). 실습 5·8번 해설에 이 현상이 나오니, 학생이 "fk 인덱스가 없어졌어요"라고 하면 정상이라고 알려 주세요.
- 체감 속도를 보여 주고 싶다면 아래 스크립트로 큰 테이블을 만들어 시연하세요(50만 행, 수 초 소요). 인덱스 전후 `SELECT`의 Duration 차이가 Workbench 출력 창에 보입니다.

```sql
SET SESSION cte_max_recursion_depth = 1000000;
CREATE TABLE order_logs AS
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 500000)
SELECT i AS log_id,
       1 + (i % 30) AS customer_id,
       TIMESTAMP('2025-01-01') + INTERVAL (i * 97) % 47304000 SECOND AS logged_at
FROM n;

SELECT COUNT(*) FROM order_logs WHERE logged_at >= '2026-06-30';   -- 인덱스 전 (Duration 확인)
CREATE INDEX idx_logs_logged_at ON order_logs (logged_at);
SELECT COUNT(*) FROM order_logs WHERE logged_at >= '2026-06-30';   -- 인덱스 후
DROP TABLE order_logs;
```

## 자주 나오는 질문

| 질문 | 답변 요지 |
|---|---|
| "인덱스를 모든 열에 걸면 안 돼요?" | 쓰기가 느려지고 공간을 씀. 자주 조회하는 조건 열에만 |
| "PK에는 인덱스 안 만들어도 돼요?" | PK·UNIQUE·FK는 자동 생성 |
| "뷰에 인덱스를 걸 수 있어요?" | MySQL은 불가. 원본 테이블의 인덱스를 씀 |
| "Materialized View는요?" | 결과를 저장하는 뷰(Oracle·PostgreSQL). MySQL엔 없어 요약 테이블로 대신 |
| "`'%'` 호스트로 만들면 편하지 않아요?" | 어디서든 접속 가능 = 공격 표면 증가. 운영에서는 IP 대역으로 제한 |
| "비밀번호를 잊어버렸어요" | root가 `ALTER USER … IDENTIFIED BY …`로 재설정 |

## 자주 하는 실수

| 실수 | 증상 | 대처 |
|---|---|---|
| 집계 뷰를 UPDATE | 1288 not updatable | 원본 테이블을 수정 |
| CHECK OPTION 뷰로 조건 밖 값 수정 | 1369 CHECK OPTION failed | 의도된 보호. 원본에서 수정 |
| 인덱스 열을 함수로 감쌈 | `type = ALL` | 값 쪽을 범위로 |
| 복합 인덱스 열 순서 반대 | 인덱스 안 탐 | = 조건 열을 앞에 |
| `GRANT … FROM` / `REVOKE … TO` | 1064 문법 에러 | GRANT는 TO, REVOKE는 FROM |
| 역할만 주고 `SET DEFAULT ROLE` 안 함 | 접속하면 권한 없음 | `SET DEFAULT ROLE` 또는 접속 후 `SET ROLE ALL` |
| 일반 계정으로 CREATE USER | 1227 Access denied | root로 접속 |
