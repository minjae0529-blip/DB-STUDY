"""교안 빌더.

src/ 아래 마크다운을 읽어 SQL 블록을 실제 MySQL 에서 실행하고,
실행 결과 표를 붙여 저장소 경로에 출력한다. → 교안에 적힌 결과 = 실제 결과 (항상 일치)

챕터별 DB
  chNN 폴더마다 setup.sql 을 생성한다: CREATE DATABASE hanip_deliveryNN + schema.sql + seed.sql
  해당 챕터 교안은 hanip_deliveryNN 에서 실행해 결과를 만든다.
  src 의 자리표시자: {{DB}} → hanip_deliveryNN, {{NN}} → NN

지원 펜스
  ```sql run [limit=N]     실행 + 결과표 삽입 (기본 limit=10)
  ```sql error             실행 시 에러가 나야 함 → 에러 메시지 삽입
  ```sql                   실행하지 않음 (문법 틀 등)
  ```sql answer [limit=N]  (practice 전용) 정답 SQL — 문제지에는 결과표만, 해설지에는 SQL+결과

practice 원본(practice.src.md)은 두 파일로 분리된다:
  practice.md  : 문제 + 기대 결과   /  answers.md : 문제 + 정답 SQL + 결과   / answers.sql
"""
import re
import sys
from pathlib import Path

import pymysql

ROOT = Path(__file__).resolve().parent.parent
FENCE = re.compile(r"```sql([^\n]*)\n(.*?)```", re.S)


CHAPTER_DIR = re.compile(r"ch(\d\d)-")


def db_name(nn):
    return f"hanip_delivery{nn}"


def make_setup(nn, title):
    db = db_name(nn)
    schema = (ROOT / "database" / "schema.sql").read_text(encoding="utf-8")
    seed = (ROOT / "database" / "seed.sql").read_text(encoding="utf-8")
    counts = "\n".join(
        ["SELECT DATABASE() AS current_db;", "",
         "SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers"]
        + [f"UNION ALL SELECT '{t}', COUNT(*) FROM {t}" for t in ["restaurants", "menus", "riders", "orders", "order_items", "reviews"]]
    ) + ";\n"
    head = f"""-- =============================================================================
--  {title} — 수업 준비 스크립트
--  생성 DB : {db}
--
--  이 과정은 챕터마다 새 DB를 만듭니다 (Ch01 = hanip_delivery01, Ch02 = hanip_delivery02 …).
--  지난 챕터의 DB와 실습 기록은 그대로 남습니다 → SHOW DATABASES LIKE 'hanip_delivery%';
--
--  실행 방법 : Workbench 에서 이 파일 열기 → Ctrl+Shift+Enter (전체 실행)
--             명령줄: mysql -u root -p < setup.sql
--  정상 완료 : 맨 아래 결과에 customers 30 … orders 563 … reviews 260
--
--  ⚠ {db} 가 이미 있으면 CREATE DATABASE 에서 1007 에러로 멈춥니다. (실습 기록 보호)
--    이 챕터 DB를 처음 상태로 되돌리려면 아래 DROP 줄 맨 앞의 '-- ' 를 지우고 다시 실행하세요.
-- =============================================================================
SET NAMES utf8mb4;

-- DROP DATABASE IF EXISTS {db};
CREATE DATABASE {db}
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE {db};

"""
    return head + schema.split("-- =============================================================================\n", 2)[-1] \
        + "\n" + seed + "\n-- 설치 확인\n" + counts


def conn(db):
    # 디코더를 빼고 서버가 보낸 텍스트를 그대로 받는다 → Workbench 표시와 동일 (9:00:00 X, 09:00:00 O)
    enc = {k: v for k, v in pymysql.converters.conversions.items() if isinstance(k, type)}
    c = pymysql.connect(host="localhost", user="dev", password="dev", database=db, charset="utf8mb4",
                        autocommit=False, conv=enc)
    with c.cursor() as cur:
        cur.execute("SET time_zone = '+09:00'")
    return c


def install(setup_sql):
    """setup.sql 을 DROP 줄 주석 해제 후 실행 (빌드용 초기화)"""
    import subprocess
    sql = setup_sql.replace("-- DROP DATABASE IF EXISTS", "DROP DATABASE IF EXISTS", 1)
    subprocess.run(["mysql"], input=sql.encode(), check=True, stdout=subprocess.DEVNULL)


def fmt(v):
    if v is None:
        return "NULL"
    if isinstance(v, bytes):
        return v.decode()
    s = str(v)
    if hasattr(v, "is_integer") or type(v).__name__ == "Decimal":
        s = str(v)
    return s.replace("|", "\\|").replace("\n", " ")


def run(c, code):
    """마지막 결과셋을 돌려준다. (여러 문장이면 마지막 SELECT 결과)"""
    stmts = [s.strip() for s in split_sql(code) if s.strip()]
    result = None
    with c.cursor() as cur:
        for s in stmts:
            cur.execute(s)
            if cur.description:
                cols = [d[0] for d in cur.description]
                result = (cols, cur.fetchall())
    c.commit()
    return result


def split_sql(code):
    # 주석 제거 후 ; 기준 분리 (문자열 안의 ; 고려)
    out, buf, q = [], [], None
    lines = []
    for line in code.splitlines():
        if line.strip().startswith("--"):
            continue
        lines.append(line)
    text = "\n".join(lines)
    for ch in text:
        if q:
            buf.append(ch)
            if ch == q:
                q = None
        elif ch in "'\"":
            q = ch
            buf.append(ch)
        elif ch == ";":
            out.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    out.append("".join(buf))
    return out


def table(res, limit):
    cols, rows = res
    n = len(rows)
    show = rows[:limit]
    head = f"<sub>▶ 실행 결과 · {n}행" + (f" (상위 {limit}행 표시)" if n > limit else "") + "</sub>\n\n"
    if n == 0:
        return head.replace(f"{n}행", "0행 — 조건에 맞는 데이터 없음") + "\n"
    md = "| " + " | ".join(cols) + " |\n|" + "|".join(["---"] * len(cols)) + "|\n"
    for r in show:
        md += "| " + " | ".join(fmt(v) for v in r) + " |\n"
    return head + md


def opts(flag):
    parts = flag.split()
    kind = parts[0] if parts else ""
    limit = 10
    for p in parts[1:]:
        if p.startswith("limit="):
            limit = int(p[6:])
    return kind, limit


def process(text, c, mode="doc"):
    """mode: doc | practice | answers"""
    def rep(m):
        kind, limit = opts(m.group(1).strip())
        code = m.group(2).rstrip() + "\n"
        if kind == "run":
            res = run(c, code)
            body = f"```sql\n{code}```\n"
            return body + ("\n" + table(res, limit) if res else "")
        if kind == "error":
            try:
                run(c, code)
            except pymysql.MySQLError as e:
                c.rollback()
                return f"```sql\n{code}```\n\n<sub>▶ 실행 결과 · 에러</sub>\n\n```text\nError Code: {e.args[0]}. {e.args[1]}\n```\n"
            raise SystemExit(f"에러가 나야 하는데 성공함:\n{code}")
        if kind == "answer":
            res = run(c, code)
            tbl = table(res, limit) if res else ""
            if mode == "practice":
                return "**기대 결과**\n\n" + tbl
            return f"**정답 SQL**\n\n```sql\n{code}```\n\n" + tbl
        return m.group(0)
    return FENCE.sub(rep, text)


def answers_sql(text, title, db):
    out = [f"-- {title} — 정답 SQL", f"-- 전제: 이 챕터의 setup.sql 실행 완료 ({db})", f"USE {db};", ""]
    for block in re.split(r"\n(?=### )", text):
        h = re.match(r"### (.+)", block)
        for m in FENCE.finditer(block):
            if m.group(1).strip().startswith("answer"):
                out.append(f"-- {h.group(1).strip() if h else ''}")
                out.append(m.group(2).rstrip())
                out.append("")
    return "\n".join(out)


def lecture_sql(text, db):
    """README 의 sql 블록을 절 제목과 함께 시연 스크립트로 추출"""
    title = text.splitlines()[0].lstrip("# ").strip()
    out = ["-- =============================================================",
           f"--  {title} — 강사 시연 스크립트 (README 예제 순서)",
           f"--  전제: 이 챕터의 setup.sql 실행 완료 ({db})",
           "--  사용법: 블록에 커서를 두고 Ctrl+Enter / ⚠ 표시는 일부러 에러를 내는 예제",
           "-- =============================================================",
           f"USE {db};", ""]
    pos = 0
    heads = [(m.start(), m.group(2)) for m in re.finditer(r"^(#{2,4}) (.+)$", text, re.M)]
    for m in FENCE.finditer(text):
        kind = m.group(1).strip().split()[0] if m.group(1).strip() else ""
        if kind not in ("run", "error"):
            continue
        h = [t for (p, t) in heads if p < m.start()]
        if h and h[-1] != (out and getattr(lecture_sql, "_last", None)):
            if h[-1] != getattr(lecture_sql, "_last", None):
                out += ["", "-- -------------------------------------------------------------", f"-- {h[-1]}", "-- -------------------------------------------------------------"]
                lecture_sql._last = h[-1]
        if kind == "error":
            out.append("-- ⚠ 에러 예제")
        out.append(m.group(2).rstrip())
        out.append("")
    lecture_sql._last = None
    return "\n".join(out) + "\n"


def strip_tag(text, tag):
    """<!-- tag:start --> ... <!-- tag:end --> 구간 제거"""
    return re.sub(rf"<!-- {tag}:start -->.*?<!-- {tag}:end -->\n?", "", text, flags=re.S)


def keep_tag(text, tag):
    return re.sub(rf"<!-- {tag}:(start|end) -->\n?", "", text)


def main():
    built = 0
    for src in sorted((ROOT / "src").rglob("*")):
        if not src.is_file() or "__pycache__" in src.parts or src.parts[len(ROOT.parts) + 1] == "slides":
            continue  # 슬라이드 정의(src/slides)는 tools/build_slides.py 담당
        rel = src.relative_to(ROOT / "src")
        m = CHAPTER_DIR.search(str(rel))
        nn = m.group(1) if m else "01"
        db = db_name(nn)
        dst = ROOT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        text = src.read_text(encoding="utf-8")
        text = text.replace("{{DB}}", db if m else "hanip_deliveryNN").replace("{{NN}}", nn if m else "NN")
        if m and not (dst.parent / ".setup_done").exists():
            title = (ROOT / "src" / rel.parts[0] / rel.parts[1] / "README.md").read_text(encoding="utf-8").splitlines()[0].lstrip("# ")
            setup = make_setup(nn, title)
            (dst.parent / "setup.sql").write_text(setup, encoding="utf-8")
            (dst.parent / ".setup_done").touch()
        if src.suffix != ".md":
            dst.write_text(text, encoding="utf-8")
            print("copied", rel)
            continue
        # 매 파일마다 해당 챕터 DB를 초기 상태로 설치한 뒤 실행 (파일 간 영향 차단)
        install(make_setup(nn, "build"))
        c = conn(db)
        if src.name == "practice.src.md":
            title = text.splitlines()[0].lstrip("# ").strip()
            p = process(strip_tag(keep_tag(text, "q"), "a"), c, "practice")
            c.close()
            install(make_setup(nn, "build"))   # 문제지·해설지를 각각 깨끗한 DB에서 (DDL 실습 대비)
            c = conn(db)
            a = process(keep_tag(strip_tag(text, "q"), "a"), c, "answers")
            (dst.parent / "practice.md").write_text(p, encoding="utf-8")
            (dst.parent / "answers.md").write_text(a.replace(title, title + " — 정답과 해설", 1), encoding="utf-8")
            (dst.parent / "answers.sql").write_text(answers_sql(text, title, db), encoding="utf-8")
        else:
            dst.write_text(process(text, c), encoding="utf-8")
            if "<!-- lecture:auto -->" in text:
                (dst.parent / "lecture.sql").write_text(lecture_sql(text, db), encoding="utf-8")
        c.close()
        built += 1
        print("built", rel)
    for f in ROOT.glob("chapters/*/.setup_done"):
        f.unlink()


if __name__ == "__main__":
    main()
