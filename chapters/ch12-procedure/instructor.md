# Ch12 강사 노트

> 과정에서 가장 분량이 많은 날입니다. 변수 · 조건 · 반복 · 커서 · 예외 · 트랜잭션 · 함수 · 권한을 3시간에 다 하려면 **문법은 빠르게, 예외 처리와 트랜잭션은 천천히** 가야 합니다. 학생 대부분이 Java를 배웠거나 배울 예정이니 "Java의 if/for/try-catch를 SQL로 쓰면 이렇게 된다"로 연결하면 문법 설명 시간이 크게 줄어듭니다.

## 시간 배분 (3시간)

| 시간 | 활동 | 자료 | 포인트 |
|---|---|---|---|
| 수업 전 | 수업 준비 | `setup.sql` | `hanip_delivery12` 생성 |
| 0:00–0:10 | Ch11 복습 퀴즈 | `ch11/quiz.md` | |
| 0:10–0:15 | 오늘의 요청 | README 도입 | "앱 네 곳에 복사된 주문 코드" |
| 0:15–0:30 | 프로시저 · 변수 · 파라미터 | README 1~2절 | OUT은 `@변수`로 받는다 |
| 0:30–0:50 | 조건문 | README 3절 | IF = Java if/else if, CASE 문 = switch. `ELSEIF` 붙여 쓰기 |
| 0:50–1:20 | 반복문 · 커서 | README 4절 | WHILE(일별 매출) → REPEAT(나눠 지우기) → LOOP+커서(등급). **커서는 최후 수단** |
| 1:20–1:30 | 휴식 | | |
| 1:30–2:05 | 예외 처리 | README 5절 | **5-1절을 꼭 시연**: 핸들러 없으면 트랜잭션이 열린 채 남는다(564 → ROLLBACK → 563) |
| 2:05–2:25 | 주문 접수 프로시저 | README 6절 | 성공 1 + 실패 3 → error_logs. 오늘의 클라이맥스 |
| 2:25–2:35 | 함수 · 권한 | README 7, 9절 | 1418을 직접 보기, `GRANT EXECUTE` |
| 2:35–3:00 | 실습 + 과정 마무리 | `practice.md` | 1~5번 수업 중, 6~10번 과제. 종합 프로젝트 안내 |

## 강조할 것

1. **트랜잭션을 연 프로시저는 반드시 핸들러를 갖는다.** `START TRANSACTION`을 쓰는 프로시저에 `DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; …; END;`가 없으면 버그라고 가르치세요. Java의 `try { … commit } catch { rollback }`과 같은 구조입니다.
2. **핸들러 안의 순서: GET DIAGNOSTICS → ROLLBACK → 기록.** GET DIAGNOSTICS는 다른 문장이 실행되면 내용이 지워지고, 기록을 ROLLBACK 전에 하면 기록도 함께 취소됩니다.
3. **잡을 에러는 좁게.** `CONTINUE HANDLER FOR SQLEXCEPTION`으로 모든 에러를 삼키면 진짜 장애가 숨습니다(실습 7번).
4. **커서보다 집합.** 4-3절 끝, 7-2절, 실습 10번 해설에서 세 번 반복합니다. 면접에서도 "커서를 언제 쓰나요?"는 단골입니다.
5. **AUTO_INCREMENT는 ROLLBACK돼도 돌아가지 않는다.** 6-1절의 566번. "주문 번호 사이에 빈 번호가 있다"는 CS 문의의 정답입니다.

## 수업 운영 팁

- 프로시저를 고칠 때마다 `DROP PROCEDURE IF EXISTS` → `CREATE`를 반복하게 됩니다. 실습 파일 맨 위에 DROP 줄을 미리 써 두게 하세요. Workbench Navigator → Stored Procedures에서 우클릭 → **Alter Stored Procedure**로 편집할 수도 있습니다(내부적으로 DROP + CREATE).
- Workbench는 `CALL` 결과에 **결과 탭이 여러 개** 생길 수 있습니다(프로시저 안 SELECT마다 하나). 마지막 탭만 보고 "결과가 이상하다"는 학생이 있으니 탭을 넘겨 보게 하세요.
- `CALL` 후 OUT 값을 보려면 `SELECT @변수`를 따로 실행해야 합니다. 같은 줄에 붙여 쓰고 `Ctrl+Enter`(현재 문장만 실행)로 실행하면 CALL만 실행됩니다. 블록을 드래그해 `Ctrl+Shift+Enter`로 실행하게 하세요.
- 1418이 안 나는 학생: `SELECT @@log_bin;`이 0이면 바이너리 로그가 꺼진 설치입니다. 정상이며, 그래도 특성 선언을 습관으로 들이게 하세요.
- 5-1절 시연 뒤 학생이 ROLLBACK을 안 하고 넘어가면, 다음 예제에서 주문 수가 하나씩 어긋납니다. 그 자체가 좋은 교육 장면이지만, 진도가 급하면 setup.sql을 다시 실행하게 하세요.
- 디버깅: 프로시저 안에서 중간값을 보려면 `SELECT v_spend AS debug;`를 임시로 넣으면 결과 탭으로 나옵니다. 끝나면 지우기.

## 자주 나오는 질문

| 질문 | 답변 요지 |
|---|---|
| "실무에서 프로시저를 많이 쓰나요?" | 웹 서비스(Spring · JPA)는 로직을 앱에 두는 편. 금융 · 공공 · ERP · 배치 작업 · 레거시에는 여전히 많음. **읽고 고칠 줄은 알아야** 함 |
| "프로시저 안에서 다른 프로시저를 불러도 돼요?" | 됨(6절에서 `sp_calc_discount` 호출). 단 둘 다 `START TRANSACTION`을 쓰면 안쪽이 바깥 트랜잭션을 COMMIT해 버림 |
| "배열이나 리스트를 파라미터로 받을 수 있어요?" | 없음. JSON 파라미터 + `JSON_TABLE`, 임시 테이블, 또는 줄마다 CALL. 이번 주문 접수가 메뉴 1개만 받는 이유 |
| "매달 1일 자동 실행은요?" | `CREATE EVENT … ON SCHEDULE EVERY 1 MONTH DO CALL sp_recalc_grades(…)` (이벤트 스케줄러). 심화 |
| "프로시저 버전 관리는 어떻게 해요?" | `.sql` 파일로 Git에 두고 배포 때 DROP + CREATE. Flyway · Liquibase 같은 마이그레이션 도구 |

## 자주 하는 실수

| 실수 | 증상 | 대처 |
|---|---|---|
| 파라미터 이름 = 열 이름 | WHERE가 항상 참 | `p_` · `v_` 접두어 |
| `DECLARE`를 중간에 씀 | 1064 | BEGIN 직후, 변수 → 커서 → 핸들러 |
| `ELSE IF`로 띄어 씀 | IF가 하나 더 열려 `END IF` 부족 | `ELSEIF` |
| CASE 문에 ELSE 없음 | 1339 Case not found | ELSE 추가 |
| `SELECT … INTO`가 여러 행 | 1172 | 조건 · LIMIT · 집계 |
| `ROW_COUNT()`를 늦게 읽음 | −1 → 무한 반복 | 변경 문장 바로 다음 줄에서 |
| 트랜잭션 프로시저에 핸들러 없음 | 실패 시 트랜잭션이 열린 채 남음 | EXIT HANDLER + ROLLBACK |
| 핸들러에서 기록 후 ROLLBACK | 기록이 사라짐 | ROLLBACK 먼저 |
| 함수 특성 선언 없음 | 1418 | `READS SQL DATA` / `DETERMINISTIC` |
