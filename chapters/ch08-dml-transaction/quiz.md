# Ch08 복습 퀴즈 (Ch09 시작 10분)

**Q1.** 주문을 넣은 직후 **그 주문의 번호**를 얻는 가장 안전한 방법은?
- ① `SELECT MAX(order_id) FROM orders;`
- ② `SELECT COUNT(*) FROM orders;`
- ③ `SELECT LAST_INSERT_ID();`
- ④ `SELECT order_id FROM orders ORDER BY ordered_at DESC LIMIT 1;`
- ⑤ 주문 번호를 미리 정해서 INSERT한다

**Q2.** Workbench의 안전 업데이트 모드에서 **실행이 막히는** 문장을 모두 고르시오.
- ① `UPDATE menus SET price = price + 500;`
- ② `UPDATE menus SET price = 9000 WHERE menu_id = 11;`
- ③ `DELETE FROM reviews WHERE rating = 1;`
- ④ `DELETE FROM reviews WHERE review_id = 7;`

**Q3.** 다음을 실행한 뒤 `reviews`의 행 수는? (시작 시 260행, autocommit = 1)
```sql
START TRANSACTION;
DELETE FROM reviews WHERE review_id = 1;
SAVEPOINT s1;
DELETE FROM reviews WHERE review_id = 2;
ROLLBACK TO SAVEPOINT s1;
COMMIT;
```

**Q4.** 트랜잭션 도중 한 문장이 FK 에러로 실패했다. 옳은 설명은?
- ① 트랜잭션 전체가 자동으로 ROLLBACK된다
- ② 실패한 문장만 무효이고, 앞의 변경은 트랜잭션 안에 남아 있다
- ③ 앞의 변경이 자동으로 COMMIT된다
- ④ 서버가 접속을 끊는다
- ⑤ 다음 문장도 모두 실패한다

**Q5.** ACID의 네 가지 성질을 쓰고, 그중 "COMMIT된 결과는 서버가 꺼져도 남는다"에 해당하는 것은?

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | ③ | 세션별로 관리되어 동시 주문과 섞이지 않음. ①·④는 남의 주문을 가져올 수 있음 |
| Q2 | ①, ③ | ① WHERE 없음, ③ `rating`은 키(인덱스) 열이 아님 → 1175 |
| Q3 | 259 | 1번 삭제는 남고 2번 삭제만 취소 |
| Q4 | ② | 그래서 에러가 나면 반드시 직접 ROLLBACK |
| Q5 | 원자성·일관성·격리성·지속성 / 지속성(Durability) | |

</details>
