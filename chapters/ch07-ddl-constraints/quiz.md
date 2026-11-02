# Ch07 복습 퀴즈 (Ch08 시작 10분)

**Q1.** 메뉴 가격을 저장할 열의 타입으로 가장 **부적절한** 것은?
- ① `INT` ② `DECIMAL(10,0)` ③ `DECIMAL(12,2)` ④ `FLOAT` ⑤ `BIGINT`

**Q2.** 다음 제약조건이 막아 주는 상황을 한 문장으로 쓰시오.
```sql
CONSTRAINT uq_cc_customer_coupon UNIQUE (customer_id, coupon_id)
```

**Q3.** 다음 에러 번호와 원인을 연결하시오.

| 에러 | 원인 |
|---|---|
| (가) 1048 | ① 존재하지 않는 부모를 가리킴 |
| (나) 1062 | ② CHECK 조건 위반 |
| (다) 1452 | ③ NOT NULL 열에 NULL |
| (라) 3819 | ④ UNIQUE·PK 중복 |

**Q4.** 고객 테이블의 행을 지우면 그 고객의 주문도 **자동으로 함께 삭제**되도록 하는 FK 옵션은? 그리고 이 옵션을 주문 데이터에 쓰면 안 되는 이유는?

**Q5.** `DELETE FROM t;`, `TRUNCATE TABLE t;`, `DROP TABLE t;`를 실행한 뒤 **테이블 구조가 남아 있는 것**을 모두 고르시오.

---

<details>
<summary>정답</summary>

| 문항 | 정답 | 해설 |
|---|---|---|
| Q1 | ④ | FLOAT는 근사값이라 금액 합계·비교에 오차 |
| Q2 | 같은 쿠폰이 한 고객에게 두 번 지급되는 것 | 두 열 **조합**의 중복 금지 |
| Q3 | (가)③ (나)④ (다)① (라)② | |
| Q4 | `ON DELETE CASCADE` / 주문·결제 기록은 법적·회계적으로 남아야 하는 데이터라 연쇄 삭제되면 복구 불가 | 고객은 `is_active` 같은 논리 삭제로 |
| Q5 | `DELETE`, `TRUNCATE` | DROP은 테이블 자체를 삭제 |

</details>
