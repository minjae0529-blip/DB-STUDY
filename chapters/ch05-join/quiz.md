# Ch05 복습 퀴즈 (Ch06 시작 10분)

**Q1.** 다음 쿼리가 1052 에러를 내는 이유는?
```sql
SELECT name, price
FROM menus m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id;
```

**Q2.** `orders`는 563행이고 그중 `rider_id`가 NULL인 행이 51개다. 다음 두 쿼리의 결과 행 수는?
```sql
-- (가)
SELECT o.order_id FROM orders o JOIN riders rd ON o.rider_id = rd.rider_id;
-- (나)
SELECT o.order_id FROM orders o LEFT JOIN riders rd ON o.rider_id = rd.rider_id;
```

**Q3.** "주문이 한 번도 없는 고객"을 찾는 쿼리의 빈칸은?
```sql
SELECT c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE ____________ ;
```

**Q4.** 고객별 취소 주문 수를 **취소 0건 고객까지 포함**해 구하려 한다. 조건 `o.status = '취소'`를 넣을 위치로 옳은 것은?
- ① WHERE 절 ② ON 절 ③ HAVING 절 ④ GROUP BY 절 ⑤ 어디든 결과는 같다

**Q5.** 주문 7번은 배달팁 2,000원, 주문 상세가 3줄이다. 다음 결과는?
```sql
SELECT SUM(o.delivery_fee)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_id = 7;
```

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | `name`이 두 테이블에 모두 있어 어느 쪽인지 모호함 | `m.name`, `r.name`으로 지정 |
| Q2 | (가) 512, (나) 563 | INNER는 짝 없는 행을 버리고 LEFT는 남김 |
| Q3 | `o.order_id IS NULL` | 원래 NULL일 수 없는 오른쪽 기본키로 검사 |
| Q4 | ② | WHERE에 쓰면 짝 없는(NULL) 행이 걸러져 INNER JOIN처럼 동작 |
| Q5 | `6000` | 1:N JOIN 후 "1" 쪽 값을 SUM하면 N배 — fan-out |

</details>
