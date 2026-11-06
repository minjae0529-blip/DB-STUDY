# Ch11 복습 퀴즈 (Ch12 시작 10분)

**Q1.** 다음 중 트리거 안에서 `NEW`와 `OLD`를 **둘 다** 쓸 수 있는 이벤트는?
- ① INSERT ② UPDATE ③ DELETE ④ SELECT ⑤ 없음

**Q2.** "메뉴 가격을 절반 미만으로 내리지 못하게" 막으려 한다. 알맞은 트리거는?
- ① AFTER UPDATE + INSERT 로그
- ② BEFORE UPDATE + `SIGNAL`
- ③ AFTER INSERT + `SET NEW.price`
- ④ BEFORE DELETE + `ROLLBACK`
- ⑤ CHECK 제약조건으로 충분하다

**Q3.** 다음을 실행한 뒤 `menu_price_history`의 행 수는? (가격 이력 트리거가 있고, 시작 시 0행, autocommit = 1)
```sql
START TRANSACTION;
UPDATE menus SET price = price + 500 WHERE restaurant_id = 3;   -- 4행 변경
ROLLBACK;
UPDATE menus SET price = 9500 WHERE menu_id = 11;               -- 9000 → 9500
```

**Q4.** Workbench에서 트리거를 만들 때 `DELIMITER $$`를 쓰는 이유는?

**Q5.** 트리거 본문에 `COMMIT;`을 넣으면 어떻게 되는가? 그 이유는?

**Q6.** 주문 상세 3행을 INSERT 한 문장으로 넣는데, BEFORE INSERT 트리거가 두 번째 행에서 `SIGNAL`을 일으켰다. 몇 행이 들어가는가?

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | ② | INSERT는 NEW만, DELETE는 OLD만 |
| Q2 | ② | 막을 거면 BEFORE. 이전 값과 비교하는 규칙은 CHECK로 불가 |
| Q3 | 1 | 트리거가 넣은 4행은 ROLLBACK으로 함께 취소 |
| Q4 | 본문 안의 `;`에서 Workbench가 문장을 자르지 않도록 문장 끝 표시를 바꾸기 위해 | DELIMITER는 클라이언트 지시, 서버로 가지 않음 |
| Q5 | 생성 시 1422 에러 | 트리거는 바깥 트랜잭션의 일부라 혼자 확정할 수 없음 |
| Q6 | 0행 | 문장 단위 원자성 — 실패한 문장이 바꾼 것은 전부 취소 |

</details>
