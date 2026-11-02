# Ch03 복습 퀴즈 (Ch04 시작 10분)

**Q1.** 다음 결과를 쓰시오.
```sql
SELECT CHAR_LENGTH('돼지국밥'), LENGTH('돼지국밥');
```

**Q2.** 정가 13,950원 메뉴의 10% 할인가를 **100원 단위 버림**으로 구하는 식은?
- ① `ROUND(13950 * 0.9, 2)` ② `ROUND(13950 * 0.9, -2)` ③ `TRUNCATE(13950 * 0.9, -2)` ④ `FLOOR(13950 * 0.9)` ⑤ `CEIL(13950 * 0.9, -2)`

**Q3.** 주문 시각 `'2026-06-30 18:09:35'`을 `18:09`로 표시하는 형식 문자열은?
```sql
DATE_FORMAT(ordered_at, '__________')
```

**Q4.** 다음 결과로 옳은 것은? (`email`이 NULL인 고객)
```sql
SELECT CONCAT(name, ' <', email, '>') FROM customers WHERE email IS NULL;
```
- ① `윤지아 <>` ② `윤지아 <NULL>` ③ `윤지아` ④ `NULL` ⑤ 에러

**Q5.** 다음 CASE에서 배달 소요 시간이 **45분**인 주문의 결과는?
```sql
CASE
    WHEN minutes <= 60 THEN '보통'
    WHEN minutes <= 30 THEN '빠름'
    ELSE '지연'
END
```

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | `4`, `12` | 한글은 utf8mb4에서 글자당 3바이트 |
| Q2 | ③ | 12555 → 12500. ②는 반올림(12600) |
| Q3 | `%H:%i` | 분은 `%i`. `%M`은 월 이름 |
| Q4 | ④ | NULL이 하나라도 섞이면 CONCAT 결과 전체가 NULL |
| Q5 | `보통` | 위에서부터 처음 참인 조건. 이 CASE는 순서가 잘못돼서 `빠름`이 영영 나오지 않음 — 함께 지적하기 |

</details>
