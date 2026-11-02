# Ch04 복습 퀴즈 (Ch05 시작 10분)

**Q1.** `customers`는 30행이고 `email`이 NULL인 행이 6개다. 결과를 쓰시오.
```sql
SELECT COUNT(*), COUNT(email) FROM customers;
```

**Q2.** 주문이 한 건도 없는 가게에 대해 다음 쿼리를 실행했다. 결과로 옳은 것은?
```sql
SELECT COUNT(*), SUM(delivery_fee) FROM orders WHERE restaurant_id = 15;
```
- ① `0`, `0` ② `0`, `NULL` ③ `NULL`, `NULL` ④ 0행(결과 없음) ⑤ 에러

**Q3.** 다음 쿼리가 1055 에러를 내는 이유는?
```sql
SELECT category, name, COUNT(*) FROM restaurants GROUP BY category;
```

**Q4.** "배달 완료 주문이 50건 이상인 가게"를 구할 때 빈칸에 들어갈 키워드는?
```sql
SELECT restaurant_id, COUNT(*)
FROM orders
_____ status = '배달완료'
GROUP BY restaurant_id
_____ COUNT(*) >= 50;
```

**Q5.** SELECT 문의 논리적 실행 순서를 바르게 나열한 것은?
- ① SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY
- ② FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
- ③ FROM → GROUP BY → WHERE → HAVING → SELECT → ORDER BY
- ④ FROM → WHERE → HAVING → GROUP BY → SELECT → ORDER BY
- ⑤ FROM → SELECT → WHERE → GROUP BY → HAVING → ORDER BY

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | `30`, `24` | COUNT(열)은 NULL을 세지 않음 |
| Q2 | ② | 대상 0행: COUNT는 0, SUM은 NULL. 집계 쿼리는 GROUP BY가 없으면 항상 1행 |
| Q3 | 한 업종(그룹)에 가게가 여러 개라 `name`을 하나로 정할 수 없음. SELECT에는 GROUP BY 열이나 집계 함수만 | |
| Q4 | `WHERE`, `HAVING` | 행 조건은 WHERE, 집계 조건은 HAVING |
| Q5 | ② | 정보처리기사 단골 문제 |

</details>
