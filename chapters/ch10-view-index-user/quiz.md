# Ch10 복습 퀴즈 (Ch11 시작 10분)

**Q1.** 뷰(VIEW)에 대한 설명으로 **틀린** 것은?
- ① 뷰는 SELECT문을 저장한 가상 테이블이다
- ② 원본 테이블이 바뀌면 뷰 조회 결과도 바뀐다
- ③ 뷰를 만들면 조회 결과가 별도로 저장되어 조회가 빨라진다
- ④ 보여 줄 열만 담은 뷰에 권한을 주어 보안에 활용할 수 있다
- ⑤ GROUP BY로 집계한 뷰는 UPDATE할 수 없다

**Q2.** `orders.ordered_at`에 인덱스가 있을 때, 인덱스를 **사용할 수 없는** 조건은?
- ① `WHERE ordered_at >= '2026-06-01'`
- ② `WHERE ordered_at BETWEEN '2026-06-01' AND '2026-06-30 23:59:59'`
- ③ `WHERE DATE(ordered_at) = '2026-06-30'`
- ④ `WHERE ordered_at < '2026-01-01'`

**Q3.** 복합 인덱스 `(restaurant_id, ordered_at)`가 있다. 이 인덱스를 효과적으로 쓰지 **못하는** 쿼리는?
- ① `WHERE restaurant_id = 4`
- ② `WHERE restaurant_id = 4 AND ordered_at >= '2026-06-01'`
- ③ `WHERE ordered_at >= '2026-06-01'`
- ④ `WHERE restaurant_id = 4 ORDER BY ordered_at`

**Q4.** `EXPLAIN` 결과의 `type`이 `ALL`이라는 것은 무슨 뜻인가?

**Q5.** 사용자 `kim`@`localhost`에게 `hanip_delivery10` DB의 `reviews` 테이블 **조회 권한만** 주는 SQL과, 그 권한을 회수하는 SQL을 쓰시오.

**Q6.** 다음 중 DCL에 속하는 명령어를 모두 고르시오.
- ① `COMMIT` ② `GRANT` ③ `ALTER` ④ `REVOKE` ⑤ `TRUNCATE`

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | ③ | 뷰는 데이터를 저장하지 않음. 조회할 때마다 SELECT가 실행됨 |
| Q2 | ③ | 인덱스 열을 함수로 가공하면 인덱스 사용 불가 |
| Q3 | ③ | 최좌측 접두사 규칙 — 첫 열(`restaurant_id`)을 건너뜀 |
| Q4 | 풀 테이블 스캔 — 인덱스 없이 모든 행을 읽음 | |
| Q5 | `GRANT SELECT ON hanip_delivery10.reviews TO 'kim'@'localhost';` / `REVOKE SELECT ON hanip_delivery10.reviews FROM 'kim'@'localhost';` | GRANT는 TO, REVOKE는 FROM |
| Q6 | ②, ④ | ① TCL, ③·⑤ DDL |

</details>
