# Ch02 복습 퀴즈 (Ch03 시작 10분)

**Q1.** 다음 쿼리의 결과로 옳은 것은?
```sql
SELECT name FROM customers WHERE email = NULL;
```
- ① 이메일이 없는 고객 6명 ② 이메일이 있는 고객 24명 ③ 30명 전부 ④ 0행 ⑤ 1064 에러

**Q2.** "부산진구 또는 수영구의 한식 가게"를 찾는 조건으로 옳은 것을 **모두** 고르면?
- ① `district = '부산진구' OR district = '수영구' AND category = '한식'`
- ② `(district = '부산진구' OR district = '수영구') AND category = '한식'`
- ③ `district IN ('부산진구', '수영구') AND category = '한식'`
- ④ `district = '부산진구' AND category = '한식' OR district = '수영구'`

**Q3.** 6월 한 달 주문을 빠짐없이 고르는 조건을 완성하시오. (`ordered_at`은 DATETIME)
```sql
WHERE ordered_at >= '2026-06-01' AND ordered_at ____ '__________'
```

**Q4.** 다음 쿼리가 1054 에러를 내는 이유를 SELECT 문의 **실행 순서**로 설명하시오.
```sql
SELECT name, price * 1.1 AS vat_price FROM menus WHERE vat_price > 20000;
```

**Q5.** 메뉴를 가격 낮은 순으로 한 페이지에 10개씩 보여 줄 때 **4페이지**를 가져오는 절은?
- ① `LIMIT 10 OFFSET 4` ② `LIMIT 10 OFFSET 30` ③ `LIMIT 30 OFFSET 10` ④ `LIMIT 40` ⑤ `LIMIT 4, 10`

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | ④ | `= NULL`은 항상 참이 아님(UNKNOWN). `IS NULL`을 써야 함 |
| Q2 | ②, ③ | ①·④는 AND가 먼저 계산되어 의도와 다름 |
| Q3 | `<`, `2026-07-01` | 반열린 구간. `BETWEEN … '2026-06-30'`은 30일 0시 이후 누락 |
| Q4 | FROM → WHERE → SELECT 순으로 실행되므로 WHERE 시점엔 별칭 `vat_price`가 아직 없음 | |
| Q5 | ② | OFFSET = (4−1)×10 = 30. ⑤ `LIMIT 4, 10`은 4개 건너뛰고 10개 |

</details>
