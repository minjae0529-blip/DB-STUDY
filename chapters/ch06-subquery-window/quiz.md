# Ch06 복습 퀴즈 (Ch07 시작 10분)

**Q1.** 다음 쿼리가 1242 에러를 내는 이유는?
```sql
SELECT name FROM menus
WHERE price > (SELECT price FROM menus WHERE restaurant_id = 6);
```

**Q2.** 서브쿼리 `(SELECT rider_id FROM orders WHERE …)`의 결과가 `1, 3, NULL`일 때, 다음 쿼리의 결과 행 수는? (`riders`는 8행)
```sql
SELECT name FROM riders WHERE rider_id NOT IN (서브쿼리);
```
- ① 6 ② 7 ③ 8 ④ 0 ⑤ 에러

**Q3.** 점수가 `100, 90, 90, 80`일 때 `RANK()`와 `DENSE_RANK()`의 결과를 각각 쓰시오.

**Q4.** 다음 중 **윈도우 함수 결과로 행을 거르는** 올바른 방법은?
- ① `WHERE ROW_NUMBER() OVER (…) = 1`
- ② `HAVING ROW_NUMBER() OVER (…) = 1`
- ③ CTE(또는 FROM절 서브쿼리)에서 계산한 뒤 바깥 쿼리의 WHERE에서 거른다
- ④ `GROUP BY ROW_NUMBER() OVER (…)`
- ⑤ 윈도우 함수 결과는 거를 수 없다

**Q5.** `UNION`과 `UNION ALL`의 차이를 한 문장으로 쓰시오.

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | 서브쿼리가 여러 행을 돌려주는데 `>` 비교에는 값 하나가 필요 | `> ALL (…)`, `> (SELECT MAX …)` 등으로 의도를 분명히 |
| Q2 | ④ | NOT IN 목록에 NULL이 있으면 모든 비교가 "모름" → 0행 |
| Q3 | RANK: 1, 2, 2, 4 / DENSE_RANK: 1, 2, 2, 3 | |
| Q4 | ③ | 윈도우 함수는 SELECT 단계에서 계산되므로 WHERE·HAVING에서 직접 못 씀 |
| Q5 | UNION은 중복 행을 제거하고, UNION ALL은 그대로 둔다 (그래서 더 빠르다) | |

</details>
