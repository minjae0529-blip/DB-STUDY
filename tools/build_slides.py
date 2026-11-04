"""강의 슬라이드 빌더.

  python3 tools/build_slides.py            # 모든 챕터
  python3 tools/build_slides.py 01 03      # 지정한 챕터만

src/slides/chNN.py 의 DECK 정의를 읽어, SQL 슬라이드를 해당 챕터 DB(hanip_deliveryNN)에서
실제로 실행하고 결과를 채운 뒤 tools/slides.js 로 chapters/chNN-*/chNN-slides.pptx 를 만든다.
교안과 마찬가지로 슬라이드의 결과표도 손으로 쓰지 않는다.
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pymysql

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import build  # noqa: E402  (make_setup, install, conn, split_sql 재사용)

SKILL = os.environ.get("PPTX_SKILL", "")


def run_sql(c, sql, limit, expect_error=False):
    try:
        res = build.run(c, sql)
    except pymysql.MySQLError as e:
        c.rollback()
        if not expect_error:
            raise SystemExit(f"SQL 실패:\n{sql}\n→ {e}")
        return {"error": f"Error Code: {e.args[0]}. {e.args[1]}"}
    if expect_error:
        raise SystemExit(f"에러가 나야 하는데 성공함:\n{sql}")
    if res is None:
        return None
    cols, rows = res
    return {"cols": cols, "rows": [[build.fmt(v) for v in r] for r in rows[:limit]], "total": len(rows)}


def resolve(slide, c):
    def one(p):
        if "sql" in p and p.get("run", True):
            p["result"] = run_sql(c, p["sql"], p.get("limit", 5), p.get("error", False))
    if slide["type"] == "code":
        one(slide)
    if slide["type"] == "compare":
        one(slide["left"])
        one(slide["right"])


def chapter_dir(nn):
    hits = sorted((ROOT / "chapters").glob(f"ch{nn}-*"))
    if not hits:
        raise SystemExit(f"chapters/ch{nn}-* 폴더 없음")
    return hits[0]


def build_one(spec_path):
    nn = spec_path.stem[2:]
    spec = importlib.util.spec_from_file_location(spec_path.stem, spec_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    deck = mod.DECK
    db = build.db_name(nn)
    build.install(build.make_setup(nn, "slides"))
    c = build.conn(db)
    for sec in deck["sections"]:
        for s in sec["slides"]:
            resolve(s, c)
    c.close()
    out = chapter_dir(nn) / f"ch{nn}-slides.pptx"
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(deck, f, ensure_ascii=False)
    env = dict(os.environ, PPTX_SKILL=SKILL)
    subprocess.run(["node", str(ROOT / "tools" / "slides.js"), f.name, str(out)], check=True, env=env)
    n = sum(len(s["slides"]) + sum(1 for x in s["slides"] if x.get("layout") == "two") for s in deck["sections"])
    print(f"built {out.relative_to(ROOT)} ({n} slides)")


def main():
    want = set(sys.argv[1:])
    for p in sorted((ROOT / "src" / "slides").glob("ch*.py")):
        if not want or p.stem[2:] in want:
            build_one(p)


if __name__ == "__main__":
    main()
