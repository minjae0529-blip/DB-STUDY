# Ch12 복습 퀴즈 (종합 프로젝트 시작 10분 · 또는 과정 마무리 테스트)

**Q1.** 다음 중 **최소 한 번은 반드시 실행되는** 반복문은?
- ① `WHILE … DO … END WHILE`
- ② `REPEAT … UNTIL … END REPEAT`
- ③ `LOOP`에 `LEAVE`를 맨 앞에 둔 것
- ④ 커서
- ⑤ `ITERATE`

**Q2.** 프로시저 안의 `DECLARE` 순서로 옳은 것은?
- ① 핸들러 → 커서 → 변수
- ② 커서 → 변수 → 핸들러
- ③ 변수 → 커서 → 핸들러
- ④ 변수 → 핸들러 → 커서
- ⑤ 순서는 상관없다

**Q3.** 다음 프로시저를 실행하다 두 번째 INSERT에서 FK 에러가 났다. 핸들러가 **없다면** 어떻게 되는가?
```sql
START TRANSACTION;
INSERT INTO orders …;        -- 성공
INSERT INTO order_items …;   -- FK 에러
COMMIT;
```

**Q4.** 위 프로시저에 넣을 예외 처리를 쓰시오. (에러가 나면 되돌리고, 호출한 쪽에 원래 에러를 그대로 전달)

**Q5.** `EXIT HANDLER`와 `CONTINUE HANDLER`의 차이는?

**Q6.** 바이너리 로그가 켜진 MySQL 8에서 테이블을 읽는 함수를 `RETURNS INT BEGIN … END`로만 만들면 1418 에러가 난다. 무엇을 추가해야 하는가?

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | ② | 조건을 나중에 검사 |
| Q2 | ③ | 변수 → 커서 → 핸들러 (어기면 1337 · 1338) |
| Q3 | 프로시저가 에러로 중단되고, 첫 INSERT는 **열린 트랜잭션 안에 남는다** | COMMIT도 ROLLBACK도 실행되지 않음. 호출한 쪽이 ROLLBACK해야 함 |
| Q4 | `DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;` | DECLARE 부분, START TRANSACTION 전에 |
| Q5 | EXIT는 처리 후 블록을 끝냄, CONTINUE는 처리 후 다음 문장부터 계속 | |
| Q6 | `READS SQL DATA` | 테이블을 읽기만 한다는 선언. 순수 계산이면 `DETERMINISTIC` |

</details>
