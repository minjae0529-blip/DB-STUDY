"""한입배달 시드 데이터 생성기 (결정적: 같은 seed → 항상 같은 데이터).

출력: database/seed.sql
데이터 기간: 2026-01-01 ~ 2026-06-30  (과정 기준일 = 2026-06-30)
"""
import random
from datetime import date, datetime, time, timedelta
from pathlib import Path

rng = random.Random(20260630)
BASE = date(2026, 6, 30)  # 기준일

# ---------------------------------------------------------------------------
# 가게
# ---------------------------------------------------------------------------
# (name, category, district, address, phone, min, fee, open, close, opened_at, is_open, popularity, quality)
RESTAURANTS = [
    ("서면옛날돼지국밥", "한식", "부산진구", "부산진구 부전동 서면로 68", "051-805-1124", 10000, 2500, "09:00", "22:00", "2023-03-15", True, 10, 4.5),
    ("전포카츠", "일식", "부산진구", "부산진구 전포동 전포대로 199", "051-816-3302", 12000, 3000, "11:00", "21:00", "2024-05-02", True, 8, 4.6),
    ("해운대명가밀면", "한식", "해운대구", "해운대구 중동 해운대로 570", "051-742-5508", 9000, 2000, "10:30", "20:30", "2022-07-01", True, 7, 4.3),
    ("광안리화덕피자", "피자", "수영구", "수영구 광안동 광안해변로 219", "051-757-2210", 18000, 3500, "11:30", "23:00", "2023-09-20", True, 7, 4.4),
    ("남천동마라공방", "중식", "수영구", "수영구 남천동 수영로 312", None, 13000, 3000, "11:00", "22:00", "2025-02-10", True, 6, 3.9),
    ("대연동크런치치킨", "치킨", "남구", "남구 대연동 못골로 41", "051-626-9981", 17000, 3000, "15:00", "02:00", "2023-11-01", True, 10, 4.2),
    ("동래파전골목집", "한식", "동래구", "동래구 수안동 명륜로 94", "051-552-7713", 15000, 3000, "11:00", "22:00", "2022-04-18", True, 4, 4.7),
    ("연산동짬뽕반점", "중식", "연제구", "연제구 연산동 중앙대로 1105", "051-866-4420", 8000, 2000, "10:30", "21:30", "2021-08-09", True, 9, 4.0),
    ("남포동떡볶이연구소", "분식", "중구", "중구 남포동 광복로 37", "051-245-0067", 10000, 2500, "11:00", "21:00", "2024-01-15", True, 6, 4.4),
    ("하단버거스탠드", "양식", "사하구", "사하구 하단동 낙동대로 552", "051-204-8831", 12000, 3000, "11:00", "22:00", "2024-08-26", True, 5, 3.6),
    ("장전동든든김밥", "분식", "금정구", "금정구 장전동 부산대학로 63", None, 8000, 2000, "07:00", "20:00", "2023-02-27", True, 7, 4.1),
    ("해운대스시하루", "일식", "해운대구", "해운대구 우동 마린시티2로 33", "051-746-1550", 20000, 4000, "11:30", "21:30", "2025-06-12", True, 4, 4.8),
    ("서면야식치킨", "치킨", "부산진구", "부산진구 부전동 중앙대로 708", "051-809-4477", 16000, 2000, "17:00", "03:00", "2022-10-05", False, 5, 3.4),
    ("광안리브런치카페", "카페·디저트", "수영구", "수영구 민락동 광안해변로 277", "051-754-6006", 15000, 3500, "09:00", "20:00", "2024-03-30", True, 4, 4.5),
    ("전포동오일파스타", "양식", "부산진구", "부산진구 전포동 동천로 87", "051-818-2025", 15000, 3000, "11:30", "21:30", "2026-06-24", True, 0, 4.5),
]
CLOSED_LAST_DAY = date(2026, 3, 31)
CUSTOMER_LAST_ORDER = {13: date(2026, 2, 20)}  # 신동욱: 2월 이후 주문 없음 (휴면 고객 패턴)  # 서면야식치킨 마지막 영업일

# ---------------------------------------------------------------------------
# 메뉴: restaurant_no -> [(name, price, description, signature, sold_out, flags)]
#   flags: "never" = 한 번도 주문되지 않는 메뉴
#   가격 인상: PRICE_CHANGES 에서 처리 (인상 이전 주문은 이전 가격으로 기록)
# ---------------------------------------------------------------------------
MENUS = {
    1: [("돼지국밥", 10000, "12시간 끓인 사골 육수에 앞다리살 듬뿍", True, False, ""),
        ("순대국밥", 10000, None, False, False, ""),
        ("섞어국밥", 10500, "돼지고기 + 순대 + 내장", False, False, ""),
        ("수육 백반", 13000, "수육 반 접시 + 국밥 + 공깃밥", False, False, ""),
        ("수육 (중)", 22000, None, False, False, "")],
    2: [("등심카츠", 11000, "180g 국내산 등심, 저온 숙성", True, False, ""),
        ("안심카츠", 12500, "부드러운 안심 160g", False, False, ""),
        ("치즈카츠", 13000, "모차렐라가 흘러나오는 치즈카츠", True, False, ""),
        ("카레우동", 9000, None, False, False, ""),
        ("새우튀김 (3pc)", 6000, None, False, False, "")],
    3: [("물밀면", 9000, "한우 사골과 한약재로 낸 시원한 육수", True, False, ""),
        ("비빔밀면", 9000, "매콤달콤 양념장", True, False, ""),
        ("회밀면", 11000, None, False, False, ""),
        ("왕만두 (6개)", 7000, "고기·김치 반반", False, False, "")],
    4: [("마르게리타", 17000, "토마토, 모차렐라, 생바질", True, False, ""),
        ("페퍼로니", 19000, None, False, False, ""),
        ("고르곤졸라", 18000, "꿀을 곁들인 고르곤졸라", False, False, ""),
        ("트러플 머쉬룸", 23000, "트러플 오일과 양송이·새송이", True, False, ""),
        ("시저 샐러드", 9000, None, False, False, ""),
        ("콜라 1.25L", 3000, None, False, False, "")],
    5: [("마라탕 (1인)", 13000, "기본 재료 + 원하는 맵기 선택", True, False, ""),
        ("마라샹궈 (2인)", 27000, None, True, False, ""),
        ("꿔바로우 (소)", 15000, "찹쌀 탕수육", False, False, ""),
        ("마라 볶음면", 11000, None, False, True, "")],
    6: [("후라이드 치킨", 20000, "바삭한 크런치 파우더 튀김", True, False, ""),
        ("양념 치킨", 21000, None, True, False, ""),
        ("반반 치킨", 21000, "후라이드 반 + 양념 반", False, False, ""),
        ("순살 간장 치킨", 22000, "다리살만 사용한 순살", False, False, ""),
        ("치즈볼 (5개)", 5000, None, False, False, ""),
        ("감자튀김", 4000, None, False, False, "")],
    7: [("해물파전", 18000, "동래식 쪽파와 해물 듬뿍", True, False, ""),
        ("김치전", 13000, None, False, False, ""),
        ("도토리묵무침", 12000, None, False, False, ""),
        ("동래 막걸리 750ml", 5000, None, False, False, "")],
    8: [("짜장면", 7000, None, False, False, ""),
        ("짬뽕", 9000, "홍합과 오징어를 넣은 불맛 짬뽕", True, False, ""),
        ("간짜장", 8500, None, False, False, ""),
        ("탕수육 (소)", 16000, "부먹·찍먹 선택", True, False, ""),
        ("볶음밥", 8500, None, False, False, ""),
        ("군만두 (8개)", 6000, None, False, False, "")],
    9: [("국물떡볶이", 5500, "부산식 어묵 국물 떡볶이", True, False, ""),
        ("로제떡볶이", 8000, None, True, False, ""),
        ("모둠튀김 (5종)", 6000, None, False, False, ""),
        ("순대", 5000, None, False, False, ""),
        ("부산 어묵 (3꼬치)", 4500, "부산 수제 어묵", False, False, "")],
    10: [("클래식 치즈버거", 8900, "더블 체다 치즈 + 수제 패티", True, False, ""),
         ("베이컨 BBQ 버거", 10900, None, False, False, ""),
         ("감자튀김 (L)", 4500, None, False, False, ""),
         ("어니언링", 5000, None, False, False, ""),
         ("밀크쉐이크", 5500, None, False, True, "")],
    11: [("든든김밥", 4000, "계란·햄·단무지·시금치", True, False, ""),
         ("참치김밥", 5000, None, False, False, ""),
         ("라볶이", 7000, None, False, False, ""),
         ("돈가스 김밥", 5500, None, False, False, ""),
         ("쫄면", 7000, None, False, False, "")],
    12: [("모둠 초밥 (12pc)", 22000, "광어·연어·참치 등 그날의 생선", True, False, ""),
         ("연어 초밥 (10pc)", 19000, None, False, False, ""),
         ("특선 오마카세 도시락", 45000, "하루 10개 한정", False, False, "never"),
         ("미소 된장국", 3000, None, False, False, "")],
    13: [("후라이드 치킨", 17000, None, True, False, ""),
         ("양념 치킨", 18000, None, False, False, ""),
         ("닭똥집 튀김", 12000, None, False, False, "")],
    14: [("에그 베네딕트", 14500, "수란과 홀랜다이즈 소스", True, False, ""),
         ("프렌치 토스트", 12000, None, False, False, ""),
         ("리코타 샐러드", 11000, None, False, False, ""),
         ("아메리카노", 4500, None, False, False, ""),
         ("딸기 크로플", 8500, "계절 한정", False, True, "")],
    15: [("알리오 올리오", 13000, "마늘과 페페론치노", True, False, ""),
         ("쉬림프 오일 파스타", 16000, None, False, False, ""),
         ("감바스 알 아히요", 17000, None, False, False, "")],
}
# (restaurant_no, menu_name, old_price, effective_date)  — effective_date 부터 현재가
PRICE_CHANGES = [
    (1, "돼지국밥", 9000, date(2026, 4, 1)),
    (1, "순대국밥", 9000, date(2026, 4, 1)),
    (6, "후라이드 치킨", 19000, date(2026, 4, 1)),
    (6, "양념 치킨", 20000, date(2026, 4, 1)),
    (3, "물밀면", 8000, date(2026, 5, 1)),
    (3, "비빔밀면", 8000, date(2026, 5, 1)),
]

# ---------------------------------------------------------------------------
# 고객 (name, phone, email, birth, district, address, marketing, joined_at, activity)
#   activity: 주문 빈도 가중치 (0 = 주문 없음)
# ---------------------------------------------------------------------------
CUSTOMERS = [
    ("김민준", "010-2841-5523", "minjun.kim@gmail.com", "1994-03-12", "부산진구", "부산진구 전포동 서전로 23, 302호", True, "2023-04-02 14:21:07", 9),
    ("이서연", "010-3392-1187", "seoyeon.lee@naver.com", "1998-07-25", "수영구", "수영구 광안동 수영로 510, 1104호", True, "2023-06-18 09:47:51", 8),
    ("박지훈", "010-4410-7762", "jihoon.park@kakao.com", "1989-11-03", "남구", "남구 대연동 수영로 290, 801호", False, "2023-08-29 20:13:40", 7),
    ("최수아", "010-5527-3018", None, "2001-02-14", "금정구", "금정구 장전동 금강로 15, 201호", True, "2024-03-04 11:02:33", 6),
    ("정우진", "010-6631-9045", "woojin.jung@gmail.com", "1985-09-30", "해운대구", "해운대구 우동 센텀중앙로 78, 2301호", False, "2023-01-15 18:30:12", 5),
    ("강하은", "010-7714-2290", "haeun.kang@naver.com", "1996-12-08", "부산진구", "부산진구 부전동 가야대로 772, 1503호", True, "2024-07-21 22:41:09", 6),
    ("조현우", "010-8825-6631", "hyunwoo.cho@daum.net", "1992-05-19", "연제구", "연제구 연산동 월드컵대로 125, 702호", False, "2023-10-07 13:55:48", 5),
    ("윤지아", "010-9936-4407", None, None, "동래구", "동래구 온천동 충렬대로 107, 1201호", False, "2024-11-11 11:11:11", 3),
    ("임도현", "010-2047-8813", "dohyun.lim@gmail.com", "1990-08-22", "수영구", "수영구 남천동 황령대로 489, 905호", True, "2023-05-09 08:16:24", 6),
    ("한예린", "010-3158-2276", "yerin.han@naver.com", "2003-04-01", "금정구", "금정구 장전동 부산대학로 49, 3층", True, "2025-03-02 10:05:37", 5),
    ("오승민", "010-4269-5534", "seungmin.oh@kakao.com", "1987-01-27", "사하구", "사하구 하단동 하신중앙로 17, 1406호", False, "2024-02-19 19:44:02", 4),
    ("서지우", "010-5370-1149", "jiwoo.seo@gmail.com", "1999-10-16", "해운대구", "해운대구 중동 달맞이길 30, 607호", True, "2024-09-08 16:27:45", 4),
    ("신동욱", "010-6481-7720", None, "1983-06-05", "부산진구", "부산진구 양정동 중앙대로 891, 1102호", False, "2022-12-24 21:08:19", 4),
    ("권나연", "010-7592-3365", "nayeon.kwon@naver.com", "1995-03-29", "남구", "남구 문현동 전포대로 133, 2004호", True, "2025-01-06 12:39:56", 4),
    ("황태민", "010-8603-8891", "taemin.hwang@daum.net", "1991-11-11", "중구", "중구 중앙동 중앙대로 70, 503호", False, "2024-05-14 09:21:30", 3),
    ("안소율", "010-9714-6602", "soyul.ahn@gmail.com", "2000-09-09", "수영구", "수영구 민락동 광안해변로 344, 1801호", True, "2025-07-19 15:03:48", 3),
    ("송재원", "010-2825-4473", "jaewon.song@kakao.com", None, "동래구", "동래구 명륜동 명륜로 112, 401호", False, "2023-09-03 17:52:14", 3),
    ("배수빈", "010-3936-0058", None, "1997-08-03", "연제구", "연제구 거제동 거제대로 220, 1302호", True, "2024-12-28 23:47:05", 3),
    ("유준호", "010-4047-9934", "junho.yoo@naver.com", "1986-04-17", "부산진구", "부산진구 범천동 범일로 40, 805호", False, "2023-02-11 10:10:59", 3),
    ("문하린", "010-5158-3381", "harin.moon@gmail.com", "2002-01-23", "해운대구", "해운대구 좌동 좌동순환로 99, 1007호", True, "2025-09-30 20:18:44", 2),
    ("장민석", "010-6269-7716", "minseok.jang@daum.net", "1993-07-07", "사하구", "사하구 다대동 다대로 515, 302호", False, "2024-04-22 07:58:31", 2),
    ("홍채원", "010-7370-2245", "chaewon.hong@naver.com", "1998-02-28", "남구", "남구 용호동 분포로 111, 2503호", True, "2025-05-17 13:36:22", 2),
    ("김서준", "010-8481-5579", None, None, "금정구", "금정구 구서동 금강로 380, 1205호", False, "2025-11-03 18:42:10", 2),
    ("이하윤", "010-9592-8812", "hayoon.lee@kakao.com", "1990-12-31", "중구", "중구 남포동 구덕로 40, 6층", True, "2024-08-15 12:00:00", 2),
    ("박시우", "010-2603-1167", "siwoo.park@gmail.com", "1988-05-05", "동래구", "동래구 사직동 사직로 55, 904호", False, "2025-12-20 19:25:13", 2),
    ("최예준", "010-3714-4490", "yejun.choi@naver.com", "1995-10-10", "부산진구", "부산진구 전포동 동천로 109, 1403호", True, "2026-02-14 21:14:52", 3),
    ("정다인", "010-4825-7723", "dain.jung@daum.net", "2004-06-18", "수영구", "수영구 광안동 광남로 120, 201호", True, "2026-04-05 10:31:19", 2),
    ("강도윤", "010-5936-0156", "doyun.kang@gmail.com", "1979-03-21", "해운대구", "해운대구 우동 해운대해변로 197, 3802호", False, "2023-07-30 22:05:41", 0),
    ("조은서", "010-6047-3589", None, "1999-11-27", "남구", "남구 대연동 유엔평화로 76, 1106호", False, "2024-10-09 14:47:26", 0),
    ("윤서아", "010-7158-6812", "seoa.yoon@naver.com", "2005-08-14", "부산진구", "부산진구 부전동 서면문화로 10, 901호", True, "2026-06-28 16:20:03", 0),
]

# (name, phone, vehicle, district, hired_at, is_active, last_day)
RIDERS = [
    ("배성진", "010-2210-4401", "오토바이", "부산진구", "2023-03-02", True, None),
    ("노지환", "010-2321-5512", "오토바이", "수영구", "2023-06-12", True, None),
    ("하민호", "010-2432-6623", "오토바이", "해운대구", "2024-01-08", True, None),
    ("전유나", "010-2543-7734", "자전거", "부산진구", "2025-04-01", True, None),
    ("곽태호", "010-2654-8845", "오토바이", "남구", "2022-09-19", True, None),
    ("민경수", "010-2765-9956", "오토바이", "연제구", "2024-06-03", False, date(2026, 2, 28)),
    ("엄소희", "010-2876-0067", "도보", "중구", "2025-10-13", True, None),
    ("천동현", "010-2987-1178", "오토바이", "사하구", "2025-02-17", True, None),
]

NEAR = {  # 구 → 가까운 구 (배달 가능 범위)
    "부산진구": ["부산진구", "연제구", "남구", "동래구", "수영구"],
    "수영구": ["수영구", "해운대구", "남구", "연제구", "부산진구"],
    "남구": ["남구", "수영구", "부산진구"],
    "해운대구": ["해운대구", "수영구"],
    "연제구": ["연제구", "동래구", "부산진구", "수영구"],
    "동래구": ["동래구", "연제구", "금정구", "부산진구"],
    "금정구": ["금정구", "동래구"],
    "중구": ["중구", "부산진구", "사하구"],
    "사하구": ["사하구", "중구"],
}
RIDER_COVER = {  # 가게 구 → 우선 배정 기사 구
    "부산진구": ["부산진구", "연제구"], "연제구": ["연제구", "부산진구"], "동래구": ["연제구", "부산진구"],
    "수영구": ["수영구", "해운대구"], "해운대구": ["해운대구", "수영구"], "남구": ["남구", "수영구"],
    "중구": ["중구", "사하구"], "사하구": ["사하구", "중구"], "금정구": ["연제구", "부산진구"],
}
NOTES = ["문 앞에 두고 벨 눌러주세요", "수저·포크는 빼주세요", "덜 맵게 해주세요", "아기가 자고 있어요. 노크만 해주세요",
         "공동현관 비밀번호는 문자로 보냈어요", "리뷰 이벤트 참여합니다", "도착하면 전화 주세요", "소스 많이 주세요"]
REVIEW_TEXT = {
    5: ["진짜 맛있어요. 재주문 의사 100%", "양도 많고 따뜻하게 왔어요", "사장님 친절하시고 포장도 꼼꼼해요", "여기서만 시켜 먹어요", "배달 빠르고 맛은 최고"],
    4: ["맛있게 잘 먹었습니다", "무난하게 맛있어요. 다음에 또 시킬게요", "조금 늦었지만 맛은 좋았어요", "가성비 좋아요"],
    3: ["평범했어요", "생각보다 양이 적었어요", "배달이 좀 늦었어요", "맛은 괜찮은데 조금 식어서 왔어요"],
    2: ["많이 식어서 왔어요", "요청사항이 반영이 안 됐어요", "예전보다 맛이 떨어졌네요"],
    1: ["주문한 메뉴가 누락됐어요", "1시간 넘게 걸렸습니다", "다시는 안 시킬 것 같아요"],
}


def sql(v):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, datetime):
        return f"'{v:%Y-%m-%d %H:%M:%S}'"
    if isinstance(v, date):
        return f"'{v:%Y-%m-%d}'"
    return "'" + str(v).replace("'", "''") + "'"


def pick_weighted(items, weights):
    return rng.choices(items, weights=weights, k=1)[0]


def main():
    # ---- id 부여 -----------------------------------------------------------
    menus = []  # dict
    mid = 0
    for rno in range(1, len(RESTAURANTS) + 1):
        for (name, price, desc, sig, sold, flags) in MENUS[rno]:
            mid += 1
            menus.append(dict(id=mid, rid=rno, name=name, price=price, desc=desc, sig=sig, sold=sold, never="never" in flags))
    by_rest = {}
    for m in menus:
        by_rest.setdefault(m["rid"], []).append(m)
    price_hist = {}
    for rno, mname, old, eff in PRICE_CHANGES:
        m = next(x for x in by_rest[rno] if x["name"] == mname)
        price_hist[m["id"]] = (old, eff)

    def price_at(m, d):
        if m["id"] in price_hist:
            old, eff = price_hist[m["id"]]
            if d < eff:
                return old
        return m["price"]

    rests = []
    for i, r in enumerate(RESTAURANTS, 1):
        name, cat, dist, addr, phone, mn, fee, op, cl, opened, is_open, pop, q = r
        rests.append(dict(id=i, name=name, cat=cat, dist=dist, addr=addr, phone=phone, min=mn, fee=fee,
                          op=time.fromisoformat(op), cl=time.fromisoformat(cl), opened=date.fromisoformat(opened),
                          is_open=is_open, pop=pop, q=q))
    custs = []
    for i, c in enumerate(CUSTOMERS, 1):
        name, phone, email, birth, dist, addr, mk, joined, act = c
        custs.append(dict(id=i, name=name, phone=phone, email=email, birth=birth and date.fromisoformat(birth), dist=dist,
                          addr=addr, mk=mk, joined=datetime.fromisoformat(joined), act=act))
    riders = []
    for i, r in enumerate(RIDERS, 1):
        name, phone, veh, dist, hired, active, last = r
        riders.append(dict(id=i, name=name, phone=phone, veh=veh, dist=dist, hired=date.fromisoformat(hired), active=active, last=last))

    # ---- 주문 생성 ---------------------------------------------------------
    orders, items, reviews = [], [], []
    d = date(2026, 1, 1)
    while d <= BASE:
        weekend = d.weekday() >= 4  # 금·토·일
        n = rng.choice([1, 2, 2, 2, 3, 3]) + (1 if weekend else 0) + (1 if d.month >= 4 else 0)
        if d == BASE:
            n = 6  # 기준일: 진행 중 주문(접수·조리중·배달중) 포함
        for _ in range(n):
            cands = [c for c in custs if c["act"] > 0 and c["joined"].date() <= d
                     and d <= CUSTOMER_LAST_ORDER.get(c["id"], BASE)]
            c = pick_weighted(cands, [c["act"] for c in cands])
            def open_on(r):
                if r["pop"] == 0 or r["opened"] > d:
                    return False
                if not r["is_open"] and d > CLOSED_LAST_DAY:
                    return False
                return True
            rc = [r for r in rests if open_on(r) and r["dist"] in NEAR[c["dist"]]]
            if not rc:
                continue
            r = pick_weighted(rc, [r["pop"] * (3 if r["dist"] == c["dist"] else 1) for r in rc])
            # 주문 시각: 영업시간 안에서 점심/저녁 피크 가중
            op_h = r["op"].hour + r["op"].minute / 60
            cl_h = r["cl"].hour + r["cl"].minute / 60
            if cl_h <= op_h:
                cl_h += 24
            for _try in range(50):
                h = rng.choice([rng.uniform(11.3, 13.5), rng.uniform(17.5, 20.5), rng.uniform(17.5, 20.5),
                                rng.uniform(20.5, 25.5), rng.uniform(op_h, cl_h)])
                if op_h + 0.25 <= h <= cl_h - 0.5:
                    break
            else:
                h = (op_h + cl_h) / 2
            od = d
            if h >= 24:
                h -= 24
                od = d + timedelta(days=1)
                if od > BASE:
                    continue
            ordered = datetime.combine(od, time(int(h), int((h % 1) * 60), rng.randrange(60)))
            if ordered <= c["joined"]:
                continue
            # 메뉴 담기
            avail = [m for m in by_rest[r["id"]] if not m["never"] and not (m["sold"] and od >= date(2026, 6, 1))]
            sigs = [m for m in avail if m["sig"]]
            k = rng.choice([1, 1, 2, 2, 2, 3])
            chosen = []
            first = rng.choice(sigs) if sigs and rng.random() < 0.65 else rng.choice(avail)
            chosen.append(first)
            for m in rng.sample(avail, len(avail)):
                if len(chosen) >= k:
                    break
                if m not in chosen:
                    chosen.append(m)
            lines = [[m, rng.choice([1, 1, 1, 1, 2, 2, 3]) if m["price"] < 8000 else rng.choice([1, 1, 1, 2]), price_at(m, od)] for m in chosen]
            tot = sum(q * p for _, q, p in lines)
            guard = 0
            while tot < r["min"] and guard < 10:
                lines[0][1] += 1
                tot = sum(q * p for _, q, p in lines)
                guard += 1
            orders.append(dict(c=c, r=r, ordered=ordered, lines=lines, total=tot))
        d += timedelta(days=1)

    orders.sort(key=lambda o: o["ordered"])
    # 마지막 날 마감 직전 주문 3건: 진행 중 상태로 만들 대상
    last_day = [o for o in orders if o["ordered"].date() == BASE]
    in_progress = {}
    states = ["배달중", "조리중", "접수"]
    for o, s in zip(sorted(last_day, key=lambda o: o["ordered"])[-3:], states):
        in_progress[id(o)] = s

    for oid, o in enumerate(orders, 1):
        o["id"] = oid
        r = o["r"]
        st = in_progress.get(id(o))
        if st is None:
            st = "취소" if rng.random() < 0.07 else "배달완료"
        o["status"] = st
        o["pay"] = pick_weighted(["카드", "간편결제", "계좌이체", "현장결제"], [45, 35, 10, 10])
        if st == "취소" and o["pay"] == "현장결제":
            o["pay"] = "카드"
        o["fee"] = 0 if o["total"] >= 50000 else r["fee"]
        o["disc"] = pick_weighted([0, 1000, 2000, 3000, 5000], [80, 6, 6, 5, 3])
        if o["disc"] == 5000 and o["total"] < 25000:
            o["disc"] = 2000
        o["note"] = rng.choice(NOTES) if rng.random() < 0.3 else None
        # 기사 배정
        rider = None
        if st in ("배달완료", "배달중"):
            od = o["ordered"].date()
            ok = [x for x in riders if x["hired"] <= od and (x["last"] is None or od <= x["last"])]
            pref = [x for x in ok if x["dist"] in RIDER_COVER[r["dist"]]]
            pool = pref or ok
            rider = pick_weighted(pool, [3 if x["veh"] == "오토바이" else 1 for x in pool])
        o["rider"] = rider
        if st == "배달완료":
            base = {"오토바이": (18, 45), "자전거": (25, 55), "도보": (30, 65)}[rider["veh"]]
            mins = rng.randint(*base)
            if rng.random() < 0.05:
                mins += rng.randint(25, 40)  # 지연 배달
            o["delivered"] = o["ordered"] + timedelta(minutes=mins, seconds=rng.randrange(60))
        else:
            o["delivered"] = None
        for m, q, p in o["lines"]:
            items.append((o["id"], m["id"], q, p))
        # 리뷰
        if st == "배달완료" and rng.random() < 0.45:
            mu = r["q"] - (1.8 if (o["delivered"] - o["ordered"]).seconds > 60 * 60 else 0)
            rating = max(1, min(5, round(rng.gauss(mu, 0.8))))
            content = None if rng.random() < 0.2 else rng.choice(REVIEW_TEXT[rating])
            created = o["delivered"] + timedelta(minutes=rng.randint(10, 60 * 48))
            limit = datetime(2026, 6, 30, 18, 59, 0)  # 스냅숏 시각 19:00 이전
            if created > limit:
                created = min(limit, o["delivered"] + timedelta(minutes=15))
            reviews.append((o["id"], rating, content, created))
    reviews.sort(key=lambda x: x[3])

    # ---- 등급 산정 (상반기 결제 금액 기준) ----------------------------------
    spend = {c["id"]: 0 for c in custs}
    for o in orders:
        if o["status"] == "배달완료":
            spend[o["c"]["id"]] += o["total"] + o["fee"] - o["disc"]
    ranked = sorted([c for c in custs if spend[c["id"]] > 0], key=lambda c: -spend[c["id"]])
    for i, c in enumerate(ranked):
        c["grade"] = "VIP" if i < 3 else "골드" if i < 8 else "실버" if i < 15 else "일반"
    for c in custs:
        c.setdefault("grade", "일반")

    # ---- SQL 출력 ----------------------------------------------------------
    out = []
    w = out.append
    w("-- =============================================================================")
    w("--  한입배달 — 시드 데이터 (원본 템플릿)")
    w("--  ※ 이 파일은 tools/gen_seed.py 로 자동 생성되었습니다. 직접 수정하지 마세요.")
    w("--  데이터 기간 : 2026-01-01 ~ 2026-06-30   (스냅숏 시각 = 2026-06-30 19:00)")
    w(f"--  건수        : customers {len(custs)} / restaurants {len(rests)} / menus {len(menus)} / riders {len(riders)}")
    w(f"--                orders {len(orders)} / order_items {len(items)} / reviews {len(reviews)}")
    w("--  ※ 직접 실행하지 않습니다. 각 챕터의 setup.sql 에 합쳐져 들어갑니다.")
    w("-- =============================================================================")
    w("")


    def block(title, table, cols, rows):
        w(f"-- {title} ({len(rows)}건)")
        w(f"INSERT INTO {table} ({', '.join(cols)}) VALUES")
        w(",\n".join("    (" + ", ".join(sql(v) for v in row) + ")" for row in rows) + ";")
        w("")

    block("가게", "restaurants",
          ["restaurant_id", "name", "category", "district", "address", "phone", "min_order_amount", "delivery_fee", "open_time", "close_time", "opened_at", "is_open"],
          [(r["id"], r["name"], r["cat"], r["dist"], "부산광역시 " + r["addr"], r["phone"], r["min"], r["fee"],
            r["op"].strftime("%H:%M:%S"), r["cl"].strftime("%H:%M:%S"), r["opened"], r["is_open"]) for r in rests])
    block("메뉴", "menus",
          ["menu_id", "restaurant_id", "name", "price", "description", "is_signature", "is_sold_out"],
          [(m["id"], m["rid"], m["name"], m["price"], m["desc"], m["sig"], m["sold"]) for m in menus])
    block("고객", "customers",
          ["customer_id", "name", "phone", "email", "birth_date", "district", "address", "grade", "marketing_agreed", "joined_at"],
          [(c["id"], c["name"], c["phone"], c["email"], c["birth"], c["dist"], "부산광역시 " + c["addr"], c["grade"], c["mk"], c["joined"]) for c in custs])
    block("배달 기사", "riders",
          ["rider_id", "name", "phone", "vehicle", "district", "hired_at", "is_active"],
          [(x["id"], x["name"], x["phone"], x["veh"], x["dist"], x["hired"], x["active"]) for x in riders])
    block("주문", "orders",
          ["order_id", "customer_id", "restaurant_id", "rider_id", "status", "payment_method", "delivery_fee", "discount_amount", "request_note", "ordered_at", "delivered_at"],
          [(o["id"], o["c"]["id"], o["r"]["id"], o["rider"]["id"] if o["rider"] else None, o["status"], o["pay"], o["fee"], o["disc"], o["note"], o["ordered"], o["delivered"]) for o in orders])
    block("주문 상세", "order_items", ["order_item_id", "order_id", "menu_id", "quantity", "unit_price"],
          [(i, *it) for i, it in enumerate(items, 1)])
    block("리뷰", "reviews", ["review_id", "order_id", "rating", "content", "created_at"],
          [(i, *rv) for i, rv in enumerate(reviews, 1)])
    Path(__file__).resolve().parent.parent.joinpath("database/seed.sql").write_text("\n".join(out) + "\n", encoding="utf-8")
    print("orders", len(orders), "items", len(items), "reviews", len(reviews))


if __name__ == "__main__":
    main()
