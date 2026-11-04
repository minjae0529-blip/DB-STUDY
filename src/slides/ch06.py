"""Ch06 서브쿼리·집합·윈도우 함수 — 슬라이드 정의 (교안 chapters/ch06-subquery-window/README.md 기준)"""

VIP = """WITH order_food AS (
    SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS food_amount
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.order_id, o.customer_id
),
customer_avg AS (
    SELECT customer_id, COUNT(*) AS orders, ROUND(AVG(food_amount)) AS avg_food
    FROM order_food GROUP BY customer_id
)
SELECT c.name, c.grade, ca.orders, ca.avg_food
FROM customer_avg ca
JOIN customers c ON ca.customer_id = c.customer_id
WHERE ca.avg_food > (SELECT AVG(food_amount) FROM order_food)
    AND ca.orders >= 10
ORDER BY ca.avg_food DESC;"""

TOP_MENU = """WITH menu_sales AS (
    SELECT m.restaurant_id, m.menu_id, m.name AS menu_name, SUM(oi.quantity) AS sold_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN menus m  ON oi.menu_id  = m.menu_id
    WHERE o.status = '배달완료'
    GROUP BY m.restaurant_id, m.menu_id, m.name
),
ranked AS (
    SELECT ms.*, RANK() OVER (PARTITION BY restaurant_id ORDER BY sold_quantity DESC) AS rnk
    FROM menu_sales ms
)
SELECT r.name AS restaurant_name, rk.menu_name, rk.sold_quantity
FROM ranked rk
JOIN restaurants r ON rk.restaurant_id = r.restaurant_id
WHERE rk.rnk = 1
ORDER BY r.restaurant_id, rk.menu_name;"""

DECK = {
    "title": "Ch06. 서브쿼리·집합·윈도우 함수",
    "footer": "Ch06 · 서브쿼리·집합·윈도우 함수",
    "org": "Korea IT Academy Busan · 강사 김준일",
    "sections": [
        {"title": "시작", "slides": [
            {"type": "cover", "label": "MySQL 30시간 · CHAPTER 06",
             "title": "서브쿼리 · 윈도우 함수\n쿼리 안의 쿼리, 그리고 순위", "sub": "오늘의 DB · hanip_delivery06"},
            {"type": "request", "label": "오늘의 요청", "title": "VIP 혜택 대상과 가게별 1등 메뉴",
             "from": "마케팅팀 이 매니저",
             "text": "**객단가가 전체 평균보다 높은** 고객을 주세요. 우연히 크게 시킨 분은 빼고 싶으니 **배달 완료 10건 이상**만요.\n그리고 **가게마다 가장 많이 팔린 메뉴 1등**도요.",
             "note": "\"전체 평균\"은 **먼저** 구해야 비교할 수 있고, \"가게마다 1등\"은 GROUP BY만으로는 메뉴 이름을 못 뽑습니다(1055)."},
            {"type": "agenda", "label": "목차", "title": "오늘 배울 것", "items": [
                ["서브쿼리", "값 하나 · 목록 · 표 — 세 가지 모양"],
                ["IN · EXISTS", "NOT IN과 NULL의 함정"],
                ["FROM절 · WITH(CTE)", "단계별로 이름 붙여 쌓기, fan-out 해결"],
                ["UNION", "결과를 위아래로 합치기"],
                ["윈도우 함수", "ROW_NUMBER · RANK · DENSE_RANK · SUM OVER"],
            ]},
        ]},
        {"title": "서브쿼리", "slides": [
            {"type": "section", "label": "01", "title": "서브쿼리", "sub": "먼저 구해야 하는 값이 있을 때"},
            {"type": "compare", "label": "01 · 서브쿼리", "title": "손으로 옮겨 적은 숫자 대신 쿼리를",
             "left": {"tag": "✗ 평균을 따로 구해 옮겨 적기", "sql": "SELECT AVG(price) FROM menus;\n-- 11840을 보고…\nSELECT name, price FROM menus\nWHERE price > 11840;", "run": False},
             "right": {"tag": "✓ 괄호 안에 쿼리", "good": True, "sql": "SELECT name, price\nFROM menus\nWHERE price >\n  (SELECT AVG(price) FROM menus)\nORDER BY price DESC;", "limit": 4},
             "caption": "괄호 안의 쿼리(**서브쿼리**)를 DB가 먼저 계산해 그 자리에 채웁니다. 메뉴가 바뀌어도 항상 맞는 값."},
            {"type": "table", "label": "01 · 서브쿼리", "title": "서브쿼리가 돌려주는 세 가지 모양",
             "headers": ["모양", "예", "쓰는 곳", "비교"],
             "rows": [["**값 하나** (스칼라)", "`(SELECT AVG(price) FROM menus)`", "WHERE · SELECT", "`=` `>` `<`"],
                      ["**목록** (N행 1열)", "`(SELECT restaurant_id FROM restaurants WHERE …)`", "WHERE", "`IN` `NOT IN`"],
                      ["**표** (N행 M열)", "`(SELECT … GROUP BY …) t`", "FROM", "테이블처럼 JOIN"]],
             "colW": [2.6, 5.4, 2.0, 2.03], "rowH": 0.75, "boldFirst": False,
             "caption": "값 하나가 와야 할 자리에 여러 행이 오면 **1242** Subquery returns more than 1 row."},
            {"type": "code", "label": "02 · IN", "title": "목록 서브쿼리 — IN",
             "sql": "SELECT order_id, restaurant_id, ordered_at, status\nFROM orders\nWHERE restaurant_id IN\n    (SELECT restaurant_id FROM restaurants\n     WHERE category = '치킨')\n  AND ordered_at >= '2026-06-24'\nORDER BY ordered_at;", "limit": 5, "layout": "stack", "codeSize": 16,
             "caption": "결과에 가게 열이 필요하면 JOIN, **걸러내기만** 하면 IN이 읽기 쉽습니다."},
            {"type": "compare", "label": "02 · NOT IN의 함정", "title": "⚠ 오늘 배달 안 한 기사는? — 0행",
             "left": {"tag": "✗ NOT IN — 0행", "sql": "SELECT name FROM riders\nWHERE rider_id NOT IN\n  (SELECT rider_id FROM orders\n   WHERE ordered_at >= '2026-06-30');"},
             "right": {"tag": "서브쿼리 결과를 보면…", "sql": "SELECT rider_id\nFROM orders\nWHERE ordered_at >= '2026-06-30';", "limit": 6},
             "caption": "목록에 NULL → `x <> NULL`이 항상 \"모름\" → **모든 행이 빠짐.**", "resSize": 11,
             "notes": "학생에게 먼저 예상 결과를 묻고 실행. 4명이 나와야 하는데 0행."},
        ]},
        {"title": "EXISTS", "slides": [
            {"type": "code", "label": "03 · EXISTS", "title": "NOT EXISTS — NULL에 안전하다",
             "sql": "SELECT rd.name\nFROM riders rd\nWHERE NOT EXISTS (\n    SELECT 1\n    FROM orders o\n    WHERE o.rider_id = rd.rider_id     -- 바깥 행 참조\n      AND o.ordered_at >= '2026-06-30'\n);", "limit": 4,
             "caption": "서브쿼리가 **바깥 쿼리의 행**(`rd`)을 참조 = **상관 서브쿼리**. 바깥 행마다 다시 계산합니다."},
            {"type": "table", "label": "03 · EXISTS", "title": "\"없는 것\"을 찾는 세 가지 방법",
             "headers": ["방법", "장점", "주의"],
             "rows": [["`LEFT JOIN … IS NULL`", "오른쪽 열도 함께 볼 수 있음", "1:N이면 행이 불어날 수 있음"],
                      ["`NOT EXISTS`", "의도가 문장 그대로 읽힘, NULL 안전", "오른쪽 열은 못 봄"],
                      ["`NOT IN`", "짧다", "**NULL이 섞이면 0행**"]],
             "colW": [3.4, 4.6, 4.03], "rowH": 0.7, "boldFirst": False,
             "caption": "습관적으로 **NOT EXISTS**. 실무의 \"데이터가 하나도 안 나와요\" 대표 원인이 NOT IN + NULL입니다."},
            {"type": "code", "label": "03 · 상관 서브쿼리", "title": "자기 가게 평균가보다 비싼 메뉴",
             "sql": "SELECT m.restaurant_id, m.name, m.price\nFROM menus m\nWHERE m.price > (\n    SELECT AVG(m2.price)\n    FROM menus m2\n    WHERE m2.restaurant_id = m.restaurant_id\n)\nORDER BY m.restaurant_id, m.price DESC;", "limit": 6,
             "caption": "전체 평균이 아니라 **행마다 다른 기준**. 안팎에서 같은 테이블을 쓰므로 별칭(`m`, `m2`)으로 구분."},
        ]},
        {"title": "FROM절 · CTE", "slides": [
            {"type": "section", "label": "04", "title": "FROM절 서브쿼리와 WITH", "sub": "쿼리 결과도 표다 — 이름을 붙여 단계별로 쌓기"},
            {"type": "code", "label": "04 · CTE", "title": "Ch05의 fan-out, 이렇게 해결한다",
             "sql": "WITH order_food AS (                 -- ① 주문별 음식 금액\n    SELECT order_id, SUM(quantity * unit_price) AS food_amount\n    FROM order_items\n    GROUP BY order_id\n)\nSELECT r.name AS restaurant_name,     -- ② 가게별 집계\n    COUNT(*) AS delivered_orders,\n    SUM(f.food_amount) AS food_sales,\n    SUM(o.delivery_fee) AS fee_sum\nFROM orders o\nJOIN order_food f  ON o.order_id = f.order_id\nJOIN restaurants r ON o.restaurant_id = r.restaurant_id\nWHERE o.status = '배달완료'\nGROUP BY r.restaurant_id, r.name\nORDER BY food_sales DESC;", "limit": 5, "layout": "two", "codeSize": 15,
             "caption": "주문 상세를 **먼저 주문 단위로 묶은 뒤** JOIN → 주문 1건 = 1행 → 배달팁이 부풀지 않습니다.",
             "caption2": "음식 매출과 배달팁을 한 표에. `WITH 이름 AS ( … )`로 먼저 정의하고 아래에서 테이블처럼 씁니다(CTE)."},
            {"type": "bullets", "label": "04 · CTE", "title": "WITH(CTE)로 쓰는 습관",
             "bullets": [
                 "FROM절 서브쿼리 = 결과를 표처럼 쓰기. **별칭 필수** (빠뜨리면 1248)",
                 "괄호가 겹겹이 쌓이면 `WITH 이름 AS ( … )`로 위로 꺼낸다",
                 "쉼표로 여러 개, 뒤의 CTE가 앞의 CTE를 참조 가능",
                 "\"① 재료 만들기 → ② 묶기 → ③ 비교하기\"로 단계 이름 붙이기",
                 "단계마다 `SELECT * FROM 단계이름`으로 **중간 결과 확인**",
             ],
             "aside": "WITH a AS ( … ),\n     b AS ( … FROM a … )\nSELECT … FROM b;\n\nMySQL 8.0부터 지원"},
        ]},
        {"title": "UNION", "slides": [
            {"type": "code", "label": "05 · UNION", "title": "UNION — 결과를 위아래로",
             "sql": "SELECT '고객' AS kind, name, phone\nFROM customers WHERE district = '중구'\nUNION ALL\nSELECT '기사', name, phone\nFROM riders WHERE district = '중구'\nORDER BY kind, name;",
             "caption": "JOIN은 **옆으로**, UNION은 **아래로**. 위아래 열 개수가 같아야 하고, 열 이름은 첫 번째 쿼리를 따릅니다."},
            {"type": "table", "label": "05 · UNION", "title": "UNION vs UNION ALL",
             "headers": ["", "UNION", "UNION ALL"],
             "rows": [["중복 행", "제거", "그대로"], ["속도", "중복 확인 때문에 느림", "빠름"], ["언제", "중복이 생기면 안 될 때", "대부분 (중복이 없거나 있어도 될 때)"]],
             "colW": [2.4, 4.6, 5.03], "rowH": 0.65},
        ]},
        {"title": "윈도우 함수", "slides": [
            {"type": "section", "label": "06", "title": "윈도우 함수", "sub": "행을 유지한 채 그룹 계산 — `함수() OVER (PARTITION BY … ORDER BY …)`"},
            {"type": "code", "label": "06 · 윈도우 함수", "title": "순위 함수 세 가지",
             "sql": "SELECT name, price,\n    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,\n    RANK()       OVER (ORDER BY price DESC) AS rnk,\n    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rnk\nFROM menus\nWHERE restaurant_id IN (1, 6)\nORDER BY price DESC, name;", "limit": 7, "layout": "two", "codeSize": 18, "resSize": 16,
             "caption": "같은 정렬 기준, 다른 동점 처리. 결과를 보기 전에 세 열의 숫자를 예상해 보세요.",
             "caption2": "동점(22000, 22000) → ROW_NUMBER **1, 2** · RANK **1, 1, 3** · DENSE_RANK **1, 1, 2**"},
            {"type": "code", "label": "06 · 윈도우 함수", "title": "PARTITION BY — 그룹마다 1위부터 다시",
             "sql": "SELECT restaurant_id, name, price,\n    RANK() OVER (PARTITION BY restaurant_id\n                 ORDER BY price DESC) AS price_rank\nFROM menus\nWHERE restaurant_id IN (1, 2)\nORDER BY restaurant_id, price_rank;", "limit": 10, "layout": "side", "codeSize": 15,
             "caption": "GROUP BY는 그룹을 1행으로 **줄이고**, 윈도우 함수는 행을 **그대로 둔 채** 옆에 붙입니다."},
            {"type": "code", "label": "06 · 윈도우 함수", "title": "그룹별 Top-N — CTE로 감싸서 거른다",
             "sql": "WITH ranked AS (\n    SELECT restaurant_id, name, price,\n        ROW_NUMBER() OVER (PARTITION BY restaurant_id\n                           ORDER BY price DESC, menu_id) AS rn\n    FROM menus\n)\nSELECT restaurant_id, name, price\nFROM ranked\nWHERE rn = 1\nORDER BY restaurant_id;", "limit": 15, "layout": "two", "codeSize": 17,
             "caption": "윈도우 함수는 SELECT(⑤) 단계에서 계산 → WHERE에서 **직접 못 씀**(3593). CTE로 한 번 감싼 뒤 거릅니다.",
             "caption2": "\"가게별 가장 비싼 메뉴\" — GROUP BY로는 메뉴 이름을 뽑을 수 없던(1055) 문제가 풀렸습니다."},
            {"type": "code", "label": "06 · 윈도우 함수", "title": "SUM OVER — 누적 합계와 비율",
             "sql": "SELECT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month,\n    SUM(delivery_fee) AS fee_sum,\n    SUM(SUM(delivery_fee)) OVER (ORDER BY DATE_FORMAT(ordered_at, '%Y-%m')) AS cumulative_fee,\n    ROUND(SUM(delivery_fee) * 100 / SUM(SUM(delivery_fee)) OVER (), 1) AS share_pct\nFROM orders\nWHERE status = '배달완료'\nGROUP BY order_month\nORDER BY order_month;", "limit": 6, "layout": "two", "codeSize": 15, "resSize": 16,
             "caption": "안쪽 SUM은 월별 합계, 바깥 `SUM … OVER`는 그것을 누적합니다.",
             "caption2": "`OVER ()` — 괄호가 비면 **전체**가 하나의 창 → 전체 대비 비율. 누적 합계의 마지막 값이 상반기 배달팁 총액."},
        ]},
        {"title": "마무리", "slides": [
            {"type": "code", "label": "오늘의 요청 해결", "title": "① 객단가가 평균보다 높은 단골 고객",
             "sql": VIP, "limit": 10, "layout": "two", "codeSize": 14, "resSize": 15,
             "caption": "CTE로 **주문별 음식 금액 → 고객별 객단가 → 전체 평균과 비교** 세 단계.",
             "caption2": "`orders >= 10`을 빼면 9건 주문한 일반 등급 고객이 1위로 올라옵니다. 등급(총액 기준)과 객단가 기준의 차이를 **데이터로 보여 주는 것**이 데이터팀의 일."},
            {"type": "code", "label": "오늘의 요청 해결", "title": "② 가게별 판매 1위 메뉴",
             "sql": TOP_MENU, "limit": 15, "layout": "two", "codeSize": 14, "resSize": 13,
             "caption": "`RANK`를 썼기 때문에 공동 1위는 모두 나옵니다.",
             "caption2": "남포동떡볶이연구소는 **공동 1위**(18개)라 2행. 가게당 1행이어야 한다면 ROW_NUMBER — 그러면 하나는 임의 기준으로 탈락. **어느 쪽이 맞는지는 요청자에게 묻습니다.**"},
            {"type": "table", "label": "정리", "title": "오늘 배운 것",
             "headers": ["문법", "핵심"],
             "rows": [["스칼라 서브쿼리", "값 하나. 여러 행이면 1242"],
                      ["`IN (서브쿼리)`", "목록 중 하나. `NOT IN`에 NULL이 섞이면 **0행**"],
                      ["`EXISTS` / `NOT EXISTS`", "그런 행이 있나. 상관 서브쿼리, NULL 안전"],
                      ["FROM절 서브쿼리 · `WITH`", "결과를 표처럼, 이름 붙여 단계별로. fan-out 해결"],
                      ["`UNION` / `UNION ALL`", "아래로 합치기. 중복 제거 여부"],
                      ["`ROW_NUMBER` `RANK` `DENSE_RANK`", "동점 처리가 다름"],
                      ["`OVER (PARTITION BY … ORDER BY …)`", "행 유지한 채 그룹 계산. 거르려면 CTE로 감싸기"]],
             "colW": [4.8, 7.23], "rowH": 0.56, "size": 14},
            {"type": "practice", "label": "실습", "title": "practice.md — 쿼리 안의 쿼리, 그리고 순위",
             "items": ["최고가 메뉴 ★", "리뷰가 있는 가게 ★", "가장 최근 주문 ★", "리뷰 작성률, 제대로 ★", "6월에 사라진 고객 ★★", "업종 평균보다 높은 문턱 ★★",
                       "결제 금액 Top 5 ★★", "휴면 위험 고객 ★★", "매출 순위와 점유율 ★★", "고객의 첫 주문 가게 ★★★", "업종별 Top 2 가게 ★★★", "빈칸 없는 월별 매출표 ★★★"],
             "caption": "**숫자를 직접 타이핑하지 마세요.** 평균·최댓값·건수 같은 기준값은 서브쿼리로."},
            {"type": "closing", "label": "다음 시간 · Ch07 테이블 설계와 제약조건", "title": "이제는 만드는 차례",
             "from": "개발팀 한 팀장",
             "text": "다음 달에 **쿠폰 기능**이 나갑니다. 쿠폰 종류와 고객 보유 쿠폰 테이블을 **설계해서 만들어** 주세요. 같은 쿠폰 두 번 지급, 음수 할인은 **절대 안 됩니다.**",
             "teaser": "지금까지는 **읽기만** 했습니다. 우리 테이블이 왜 지금 모양인지 해부하고, 같은 원리로 직접 만듭니다 — Ch07."},
        ]},
    ],
}
