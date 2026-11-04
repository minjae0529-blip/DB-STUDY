/**
 * 강의 슬라이드 렌더러 (pptxgenjs)
 *   node tools/slides.js <resolved.json> <out.pptx>
 *
 * resolved.json 은 tools/build_slides.py 가 만든다. (SQL 실행 결과가 이미 채워져 있음)
 *
 * 디자인: 부경대 석사 발표 스타일
 *   - 미색 배경 + 남색 글씨 + 주황 포인트, 표지·마무리는 짙은 남색
 *   - 제목 Gowun Batang(명조), 본문 IBM Plex Sans KR, 코드 IBM Plex Mono
 *   - 카드·아이콘·그림자 없이 여백과 가는 선으로 구분
 */
const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");

const SKILL = process.env.PPTX_SKILL || "";
const { applyTheme } = SKILL ? require(path.join(SKILL, "scripts/apply_theme.js")) : { applyTheme: null };

// ── 디자인 토큰 ────────────────────────────────────────────────
const K = {
  ink: "1B2130",       // 표지 배경(짙은 남색)
  paper: "F4F2EE",     // 본문 배경(미색)
  paper2: "EAE6DF",    // 섹션 구분 배경
  text: "1F2937",      // 본문 글씨
  muted: "6B7280",     // 보조 글씨
  line: "D6D1C7",      // 가는 선
  accent: "A44A1B",    // 밝은 배경 위 주황(라벨)
  accentLt: "E08A4F",  // 어두운 배경 위 주황
  onInk: "F4F2EE",
  onInkMuted: "C5CAD3",
  onInkFaint: "9AA1AD",
  code: "22262E",      // 코드 배경
  codeText: "E5E1D8",
  kw: "E08A4F",        // SQL 키워드
  num: "8DB3E8",       // 숫자
  str: "B5CC8E",       // 문자열
  cmt: "8A8F98",       // 주석
  bad: "B42318",
  good: "2F6B4F",
  tint: "FBFAF7",      // 결과표 배경
};
const F = { head: "Gowun Batang", body: "IBM Plex Sans KR", mono: "IBM Plex Mono" };
const W = 13.333, H = 7.5, M = 0.65;

const THEME = {
  name: "Pukyong Thesis",
  headFontFace: F.head,
  bodyFontFace: F.body,
  colors: {
    dk1: K.text, lt1: K.paper, dk2: K.ink, lt2: K.paper2,
    accent1: K.accent, accent2: K.accentLt, accent3: K.num, accent4: K.good,
    accent5: K.muted, accent6: K.line, hlink: K.accent, folHlink: K.muted,
  },
};

const SQL_KW = new Set(("SELECT FROM WHERE AND OR NOT IN IS NULL AS ORDER BY GROUP HAVING LIMIT OFFSET ASC DESC " +
  "DISTINCT BETWEEN LIKE CASE WHEN THEN ELSE END JOIN LEFT RIGHT INNER OUTER ON USING UNION ALL " +
  "INSERT INTO VALUES UPDATE SET DELETE CREATE TABLE DATABASE DROP ALTER USE SHOW TABLES DATABASES DESC " +
  "DEFAULT CHARACTER COLLATE PRIMARY KEY FOREIGN REFERENCES UNIQUE CHECK CONSTRAINT TRUE FALSE WITH ROLLUP " +
  "INTERVAL DAY MONTH YEAR MINUTE HOUR SEPARATOR IF EXISTS").split(" "));

// ── SQL 하이라이트 → pptxgenjs runs ──────────────────────────
function sqlRuns(sql, size) {
  const runs = [];
  const lines = sql.replace(/\s+$/, "").split("\n");
  lines.forEach((line, li) => {
    const re = /(--.*$)|('(?:[^']|'')*')|(\b\d+(?:\.\d+)?\b)|([A-Za-z_][A-Za-z_0-9]*)|(\s+)|(.)/g;
    let m;
    const push = (text, color, extra = {}) => runs.push({ text, options: { color, fontFace: F.mono, fontSize: size, ...extra } });
    if (line === "") push(" ", K.codeText);
    while ((m = re.exec(line)) !== null) {
      if (m[1]) push(m[1], K.cmt, { italic: true });
      else if (m[2]) push(m[2], K.str);
      else if (m[3]) push(m[3], K.num);
      else if (m[4]) push(m[4], SQL_KW.has(m[4].toUpperCase()) && m[4] === m[4].toUpperCase() ? K.kw : K.codeText,
        SQL_KW.has(m[4].toUpperCase()) && m[4] === m[4].toUpperCase() ? { bold: true } : {});
      else push(m[0], K.codeText);
    }
    if (li < lines.length - 1) runs[runs.length - 1].options.breakLine = true;
  });
  return runs;
}

// ── 공통 요소 ────────────────────────────────────────────────
// 코드 폭 측정: 한글은 고정폭 글꼴에서 약 2칸
function codeWidth(sql) {
  return Math.max(...sql.replace(/\s+$/, "").split("\n").map((l) => [...l].reduce((a, ch) => a + (/[\u3131-\uD79D]/.test(ch) ? 1.75 : 1), 0)));
}
function fitSize(sql, w, preferred, min = 12) {
  let size = preferred;
  while (size > min && codeWidth(sql) * size * 0.6 / 72 > w - 0.5) size -= 1;
  return size;
}
function fitHeight(sql, size, avail, min = 11) {
  while (size > min && codeHeight(sql, size) > avail) size -= 1;
  return size;
}
function codeHeight(sql, size) {
  const n = sql.replace(/\s+$/, "").split("\n").length;
  return Math.max(0.6, n * size * 1.26 / 72 + 0.38);
}
function codeBlock(slide, sql, x, y, w, size) {
  const n = sql.replace(/\s+$/, "").split("\n").length;
  const lh = size * 1.26 / 72;
  const h = Math.max(0.6, n * lh + 0.38);
  slide.addShape("rect", { x, y, w, h, fill: { color: K.code }, line: { type: "none" }, objectName: "code-bg" });
  slide.addText(sqlRuns(sql, size), {
    x: x + 0.22, y: y + 0.16, w: w - 0.44, h: h - 0.32, valign: "top", margin: 0,
    isTextBox: true, paraSpaceAfter: 0, lineSpacingMultiple: 1.0, objectName: "code", fit: "none",
  });
  return h;
}

function resultTable(slide, res, x, y, w, size, maxH) {
  if (!res) return 0;
  if (res.error) {
    slide.addText([
      { text: "▶ 실행 결과 · 에러", options: { color: K.bad, bold: true, fontSize: 12, breakLine: true, paraSpaceAfter: 6 } },
      { text: res.error.length > 120 ? res.error.slice(0, 110).replace(/\s+\S*$/, "") + " …" : res.error, options: { color: K.bad, fontFace: F.mono, fontSize: 16 } },
    ], { x, y, w, h: Math.min(maxH, 1.5), valign: "top", margin: 0, isTextBox: true, objectName: "error" });
    return 1.5;
  }
  const { cols, total } = res;
  let rows = res.rows;
  const rowH0 = size * 1.9 / 72;
  const fitRows = Math.max(1, Math.floor((maxH - 0.32) / rowH0) - 1);
  if (rows.length > fitRows) rows = rows.slice(0, fitRows);
  const cap = total === 0 ? "▶ 실행 결과 · 0행" : (total > rows.length ? `▶ 실행 결과 · ${total}행 중 ${rows.length}행` : `▶ 실행 결과 · ${total}행`);
  slide.addText(cap, { x, y, w, h: 0.28, fontSize: 11, color: K.muted, margin: 0, isTextBox: true, objectName: "result-caption" });
  if (total === 0) return 0.35;
  const rowH = size * 1.9 / 72;
  const hb = (c) => ({ type: "solid", pt: c ? 1.25 : 0.75, color: c ? K.text : K.line });
  const none = { type: "none" };
  const head = cols.map((c) => ({
    text: c, options: { bold: true, color: K.text, fontFace: F.mono, fontSize: size - 1, fill: { color: K.tint },
      border: [none, none, hb(true), none] },
  }));
  const body = rows.map((r) => r.map((v) => ({
    text: String(v), options: { color: v === "NULL" ? K.muted : K.text, italic: v === "NULL", fontSize: size,
      fill: { color: K.tint }, border: [none, none, hb(false), none] },
  })));
  const tbl = [head, ...body];
  slide.addTable(tbl, {
    x, y: y + 0.32, w, colW: colWidths(cols, rows, w), rowH, fontFace: F.body, margin: [0.03, 0.08, 0.03, 0.08],
    valign: "middle", autoPage: false, objectName: "result-table",
  });
  return 0.32 + rowH * tbl.length;
}

function colWidths(cols, rows, w) {
  const len = (s) => [...String(s)].reduce((a, ch) => a + (/[ㄱ-힝]/.test(ch) ? 1.8 : 1), 0);
  const want = cols.map((c, i) => Math.max(len(c) + 1, ...rows.map((r) => Math.min(len(r[i]), 40)), 4));
  const sum = want.reduce((a, b) => a + b, 0);
  return want.map((v) => (v / sum) * w);
}

function label(slide, text, dark) {
  slide.addText(text, { placeholder: "label", color: dark ? K.accentLt : K.accent });
}

function para(text, opts = {}) {
  // **굵게** 와 `코드` 를 runs 로, \n 은 줄바꿈
  const lines = String(text).split("\n");
  if (lines.length > 1) {
    const all = [];
    lines.forEach((ln, i) => {
      const r = paraLine(ln === "" ? " " : ln, opts);
      if (i < lines.length - 1) r[r.length - 1].options = { ...r[r.length - 1].options, breakLine: true };
      all.push(...r);
    });
    return all;
  }
  return paraLine(text, opts);
}

function paraLine(text, opts) {
  const out = [];
  const re = /(\*\*[^*]+\*\*)|(`[^`]+`)|([^*`]+)/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    if (m[1]) out.push({ text: m[1].slice(2, -2), options: { ...opts, bold: true } });
    else if (m[2]) out.push({ text: m[2].slice(1, -1), options: { ...opts, fontFace: F.mono, color: opts.codeColor || K.accent } });
    else out.push({ text: m[3], options: { ...opts } });
  }
  return out;
}

function bulletList(items, size, color) {
  // 불릿 기호 대신 주황 대시(—)를 직접 붙인다 (렌더러마다 불릿 표시가 달라서)
  const runs = [];
  items.forEach((it, i) => {
    const sub = typeof it === "object" && it.sub;
    const text = typeof it === "object" ? it.text : it;
    const sz = sub ? size - 3 : size;
    const lead = { text: sub ? "      · " : "—  ", options: { fontSize: sz, color: sub ? K.muted : K.accent, bold: false, fontFace: F.body } };
    const r = para(text, { fontSize: sz, color: sub ? K.muted : color });
    const all = [lead, ...r];
    all[all.length - 1].options = { ...all[all.length - 1].options, breakLine: i < items.length - 1 };
    all[0].options.paraSpaceAfter = sub ? 8 : 12;
    runs.push(...all);
  });
  return runs;
}

// ── 레이아웃 정의 ────────────────────────────────────────────
function defineLayouts(pres, footer) {
  const lab = (color) => ({ placeholder: { options: { name: "label", type: "body", x: M, y: 0.42, w: W - 2 * M, h: 0.34,
    fontFace: F.body, fontSize: 13, bold: true, color, margin: 0, charSpacing: 1 }, text: "" } });
  pres.defineSlideMaster({
    title: "COVER", background: { color: K.ink },
    objects: [lab(K.accentLt),
      { placeholder: { options: { name: "title", type: "title", x: M, y: 2.0, w: W - 2 * M, h: 2.6, fontFace: F.head,
        fontSize: 54, bold: true, color: K.onInk, valign: "bottom", align: "left", margin: 0, lineSpacingMultiple: 1.1 }, text: "" } },
      { placeholder: { options: { name: "sub", type: "body", x: M, y: 4.8, w: W - 2 * M, h: 1.0, fontFace: F.body,
        fontSize: 20, color: K.onInkMuted, valign: "top", margin: 0 }, text: "" } },
      { text: { text: footer.org, options: { x: M, y: 6.6, w: 8, h: 0.4, fontFace: F.body, fontSize: 13, color: K.onInkFaint, margin: 0 } } },
    ],
  });
  pres.defineSlideMaster({
    title: "SECTION", background: { color: K.paper2 },
    objects: [lab(K.accent),
      { placeholder: { options: { name: "title", type: "title", x: M, y: 2.4, w: W - 2 * M, h: 2.0, fontFace: F.head,
        fontSize: 48, bold: true, color: K.text, valign: "middle", align: "left", margin: 0 }, text: "" } },
      { placeholder: { options: { name: "sub", type: "body", x: M, y: 4.5, w: W - 2 * M, h: 1.0, fontFace: F.body,
        fontSize: 18, color: K.muted, valign: "top", margin: 0 }, text: "" } },
    ],
    slideNumber: { x: W - M - 0.6, y: 6.95, w: 0.6, h: 0.3, fontFace: F.body, fontSize: 10, color: K.muted, align: "right" },
  });
  pres.defineSlideMaster({
    title: "CONTENT", background: { color: K.paper },
    objects: [lab(K.accent),
      { placeholder: { options: { name: "title", type: "title", x: M, y: 0.78, w: W - 2 * M, h: 0.78, fontFace: F.head,
        fontSize: 30, bold: true, color: K.text, valign: "top", align: "left", margin: 0 }, text: "" } },
      { text: { text: footer.chapter, options: { x: M, y: 6.95, w: 8, h: 0.3, fontFace: F.body, fontSize: 10, color: K.muted, margin: 0 } } },
    ],
    slideNumber: { x: W - M - 0.6, y: 6.95, w: 0.6, h: 0.3, fontFace: F.body, fontSize: 10, color: K.muted, align: "right" },
  });
  pres.defineSlideMaster({
    title: "CLOSING", background: { color: K.ink },
    objects: [lab(K.accentLt),
      { placeholder: { options: { name: "title", type: "title", x: M, y: 1.2, w: W - 2 * M, h: 0.9, fontFace: F.head,
        fontSize: 34, bold: true, color: K.onInk, valign: "top", align: "left", margin: 0 }, text: "" } },
    ],
  });
}

const TOP = 1.75, BOTTOM = 6.75;

// ── 슬라이드 타입별 렌더 ─────────────────────────────────────
const R = {
  cover(pres, s, sec) {
    const sl = pres.addSlide({ masterName: "COVER", sectionTitle: sec });
    label(sl, s.label, true);
    sl.addText(s.title, { placeholder: "title" });
    sl.addText(s.sub || "", { placeholder: "sub" });
    return sl;
  },
  section(pres, s, sec) {
    const sl = pres.addSlide({ masterName: "SECTION", sectionTitle: sec });
    label(sl, s.label);
    sl.addText(s.title, { placeholder: "title" });
    if (s.sub) sl.addText(para(s.sub, { color: K.muted }), { placeholder: "sub" });
    return sl;
  },
  agenda(pres, s, sec) {
    const sl = content(pres, s, sec);
    const n = s.items.length, rowH = Math.min(0.85, (BOTTOM - TOP) / n);
    s.items.forEach((it, i) => {
      const y = TOP + i * rowH;
      sl.addText(String(i + 1).padStart(2, "0"), { x: M, y, w: 0.9, h: rowH, fontFace: F.head, fontSize: 26, color: K.accent, valign: "middle", margin: 0, isTextBox: true });
      sl.addText(para(it[0], { fontSize: 20, color: K.text, bold: true }), { x: M + 1.0, y, w: 4.6, h: rowH, valign: "middle", margin: 0, isTextBox: true });
      sl.addText(para(it[1] || "", { fontSize: 15, color: K.muted }), { x: M + 5.7, y, w: W - 2 * M - 5.7, h: rowH, valign: "middle", margin: 0, isTextBox: true });
      if (i < n - 1) sl.addShape("line", { x: M, y: y + rowH, w: W - 2 * M, h: 0, line: { color: K.line, width: 0.75 } });
    });
    return sl;
  },
  request(pres, s, sec) {
    const sl = content(pres, s, sec);
    sl.addText(`From. ${s.from}`, { x: M, y: TOP + 0.1, w: 6, h: 0.4, fontFace: F.body, fontSize: 15, bold: true, color: K.accent, margin: 0, isTextBox: true });
    sl.addText(para(s.text, { fontFace: F.head, fontSize: 24, color: K.text }), { x: M, y: TOP + 0.65, w: W - 2 * M - 0.5, h: 3.0, valign: "top", margin: 0, lineSpacingMultiple: 1.3, isTextBox: true });
    if (s.note) {
      sl.addShape("line", { x: M, y: 5.6, w: W - 2 * M, h: 0, line: { color: K.line, width: 0.75 } });
      sl.addText(para(s.note, { fontSize: 16, color: K.muted }), { x: M, y: 5.75, w: W - 2 * M, h: 0.9, valign: "top", margin: 0, isTextBox: true });
    }
    return sl;
  },
  bullets(pres, s, sec) {
    const sl = content(pres, s, sec);
    const w = s.aside ? 7.4 : W - 2 * M;
    sl.addText(bulletList(s.bullets, s.size || 19, K.text), { x: M, y: TOP + 0.05, w, h: BOTTOM - TOP - 0.1, valign: "top", margin: 0, isTextBox: true });
    if (s.aside) aside(sl, s.aside, M + w + 0.5, TOP + 0.05, W - 2 * M - w - 0.5);
    return sl;
  },
  table(pres, s, sec) {
    const sl = content(pres, s, sec);
    const none = { type: "none" };
    const size = s.size || 15;
    const head = s.headers.map((c) => ({ text: c, options: { bold: true, color: K.text, fontSize: size - 1, border: [none, none, { type: "solid", pt: 1.25, color: K.text }, none] } }));
    const body = s.rows.map((r) => r.map((v, i) => ({ text: para(String(v), { fontSize: size, color: K.text, bold: i === 0 && s.boldFirst !== false }),
      options: { border: [none, none, { type: "solid", pt: 0.75, color: K.line }, none] } })));
    const rowH = s.rowH || 0.5;
    sl.addTable([head, ...body], { x: M, y: TOP + 0.05, w: W - 2 * M, colW: s.colW, rowH, fontFace: F.body, valign: "middle", margin: [0.04, 0.1, 0.04, 0.02], autoPage: false, objectName: "table" });
    if (s.caption) caption(sl, s.caption, TOP + 0.05 + rowH * (s.rows.length + 1) + 0.3);
    return sl;
  },
  code(pres, s, sec) {
    const sl = content(pres, s, sec);
    const res = s.result;
    const nLines = s.sql.trim().split("\n").length;
    const nCols = res && res.cols ? res.cols.length : 0;
    const pref = s.codeSize || (nLines > 12 ? 14 : nLines > 8 ? 16 : nLines > 4 ? 18 : 20);
    const cw = 6.4;
    if (s.layout === "two") {
      // 코드가 길고 결과도 길 때: 코드 슬라이드 + 결과 전용 슬라이드
      const size = fitHeight(s.sql, fitSize(s.sql, W - 2 * M, pref), BOTTOM - TOP - (s.caption ? 0.75 : 0.1));
      const ch = codeBlock(sl, s.sql, M, TOP + 0.05, W - 2 * M, size);
      if (s.caption) caption(sl, s.caption, TOP + 0.05 + ch + 0.3);
      const sl2 = content(pres, { label: s.label, title: s.title + " — 실행 결과" }, sec);
      resultTable(sl2, res, M, TOP + 0.05, W - 2 * M, s.resSize || 14, BOTTOM - TOP - (s.caption2 ? 0.6 : 0));
      if (s.caption2) caption(sl2, s.caption2, BOTTOM - 0.45);
      return sl;
    }
    let side = s.layout ? s.layout === "side" : (res && !res.error && nCols <= 4 && nLines <= 12);
    if (side && fitSize(s.sql, cw, pref) < Math.min(pref, 15) && !s.layout) side = false;
    if (side && res) {
      const size = fitSize(s.sql, cw, pref);
      const ch = codeBlock(sl, s.sql, M, TOP + 0.05, cw, size);
      const th = resultTable(sl, res, M + cw + 0.45, TOP + 0.05, W - 2 * M - cw - 0.45, s.resSize || 14, BOTTOM - TOP - 0.1 - (s.caption ? 0.6 : 0));
      if (s.caption) caption(sl, s.caption, TOP + 0.05 + Math.max(ch, th) + 0.3);
    } else {
      const size = fitSize(s.sql, W - 2 * M, pref);
      const ch = codeBlock(sl, s.sql, M, TOP + 0.05, W - 2 * M, size);
      let y = TOP + 0.05 + ch + 0.3;
      if (res) y += resultTable(sl, res, M, y, W - 2 * M, s.resSize || 14, BOTTOM - y - (s.caption ? 0.6 : 0)) + 0.25;
      if (s.caption) caption(sl, s.caption, y);
    }
    return sl;
  },
  compare(pres, s, sec) {
    const sl = content(pres, s, sec);
    const cw = (W - 2 * M - 0.5) / 2;
    let bottom = 0;
    const size = Math.min(...[s.left, s.right].map((p) => fitSize(p.sql, cw, p.codeSize || 16)));
    const rsize = s.resSize || 12;
    [s.left, s.right].forEach((p, i) => {
      const x = M + i * (cw + 0.5);
      sl.addText(p.tag, { x, y: TOP, w: cw, h: 0.4, fontFace: F.body, fontSize: 16, bold: true, color: p.good ? K.good : K.bad, margin: 0, isTextBox: true });
      const ch = codeBlock(sl, p.sql, x, TOP + 0.48, cw, size);
      let b = TOP + 0.48 + ch;
      if (p.result) b += 0.25 + resultTable(sl, p.result, x, TOP + 0.48 + ch + 0.25, cw, rsize, BOTTOM - (TOP + 0.48 + ch + 0.25) - (s.caption ? 0.65 : 0));
      bottom = Math.max(bottom, b);
    });
    if (s.caption) caption(sl, s.caption, bottom + 0.3);
    return sl;
  },
  diagram(pres, s, sec) {
    const sl = content(pres, s, sec);
    const lines = s.text.split("\n").length;
    const size = s.size || Math.min(16, Math.floor((BOTTOM - TOP - 0.8) * 72 / lines / 1.25));
    sl.addText(s.text, { x: M, y: TOP + 0.05, w: W - 2 * M, h: lines * size * 1.3 / 72 + 0.2, fontFace: F.mono, fontSize: size, color: K.text, valign: "top", margin: 0, isTextBox: true, objectName: "diagram" });
    if (s.caption) caption(sl, s.caption, TOP + 0.05 + lines * size * 1.3 / 72 + 0.45);
    return sl;
  },
  stats(pres, s, sec) {
    const sl = content(pres, s, sec);
    const n = s.items.length, cw = (W - 2 * M) / n;
    s.items.forEach(([num, lab2, note], i) => {
      const x = M + i * cw;
      if (i > 0) sl.addShape("line", { x, y: TOP + 0.4, w: 0, h: 2.2, line: { color: K.line, width: 0.75 } });
      sl.addText(num, { x: x + 0.25, y: TOP + 0.3, w: cw - 0.4, h: 1.3, fontFace: F.head, fontSize: 60, bold: true, color: K.text, margin: 0, valign: "bottom", isTextBox: true });
      sl.addText(lab2, { x: x + 0.25, y: TOP + 1.7, w: cw - 0.4, h: 0.45, fontSize: 17, bold: true, color: K.accent, margin: 0, isTextBox: true });
      if (note) sl.addText(para(note, { fontSize: 13, color: K.muted }), { x: x + 0.25, y: TOP + 2.15, w: cw - 0.4, h: 0.8, valign: "top", margin: 0, isTextBox: true });
    });
    if (s.caption) caption(sl, s.caption, TOP + 3.4);
    return sl;
  },
  practice(pres, s, sec) {
    const sl = content(pres, s, sec);
    const half = Math.ceil(s.items.length / 2);
    [s.items.slice(0, half), s.items.slice(half)].forEach((col, ci) => {
      const runs = [];
      col.forEach((it, i) => {
        const no = ci * half + i + 1;
        runs.push({ text: `${String(no).padStart(2, "0")}   `, options: { fontFace: F.mono, color: K.accent, fontSize: 20, bold: true } });
        runs.push({ text: it, options: { color: K.text, fontSize: 20, breakLine: i < col.length - 1, paraSpaceAfter: 18 } });
      });
      sl.addText(runs, { x: M + ci * 6.15, y: TOP + 0.05, w: 5.9, h: 4.3, valign: "top", margin: 0, isTextBox: true });
    });
    if (s.caption) caption(sl, s.caption, 6.1);
    return sl;
  },
  canvas(pres, s, sec) {
    // 도형으로 그린 다이어그램: table / box / arrow / text 요소를 좌표로 배치
    const sl = content(pres, s, sec);
    const none = { type: "none" };
    for (const e of s.elements) {
      if (e.kind === "table") {
        const size = e.size || 13;
        if (e.title) sl.addText(e.title, { x: e.x, y: e.y - 0.36, w: e.w, h: 0.32, fontFace: F.mono, fontSize: size, bold: true, color: K.accent, margin: 0, isTextBox: true });
        const hl = new Set(e.highlight || []);
        const head = e.headers.map((c) => ({ text: c, options: { bold: true, fontFace: F.mono, fontSize: size - 1, color: K.text, fill: { color: K.paper2 },
          border: [{ type: "solid", pt: 0.75, color: K.text }, { type: "solid", pt: 0.75, color: K.line }, { type: "solid", pt: 1, color: K.text }, { type: "solid", pt: 0.75, color: K.line }] } }));
        const body = e.rows.map((r) => r.map((v, ci) => ({ text: String(v), options: { fontSize: size, color: hl.has(ci) ? K.accent : K.text, bold: hl.has(ci),
          fill: { color: "FFFFFF" }, border: [{ type: "solid", pt: 0.5, color: K.line }, { type: "solid", pt: 0.75, color: K.line }, { type: "solid", pt: 0.5, color: K.line }, { type: "solid", pt: 0.75, color: K.line }] } })));
        sl.addTable([head, ...body], { x: e.x, y: e.y, w: e.w, colW: e.colW, rowH: e.rowH || size * 2.0 / 72, fontFace: F.body, margin: [0.02, 0.08, 0.02, 0.08], valign: "middle", autoPage: false });
      } else if (e.kind === "box") {
        sl.addShape("rect", { x: e.x, y: e.y, w: e.w, h: e.h, fill: { color: e.dark ? K.ink : "FFFFFF" }, line: { color: e.dark ? K.ink : K.text, width: 1 } });
        sl.addText(para(e.text, { fontSize: e.size || 17, color: e.dark ? K.onInk : K.text, codeColor: e.dark ? K.accentLt : K.accent }), { x: e.x + 0.2, y: e.y + 0.1, w: e.w - 0.4, h: e.h - 0.2, valign: "middle", align: e.align || "left", margin: 0, isTextBox: true });
      } else if (e.kind === "arrow") {
        sl.addShape("line", { x: Math.min(e.x1, e.x2), y: Math.min(e.y1, e.y2), w: Math.abs(e.x2 - e.x1), h: Math.abs(e.y2 - e.y1),
          flipH: e.x2 < e.x1, flipV: e.y2 < e.y1, line: { color: e.color ? K[e.color] : K.accent, width: 1.75, endArrowType: "triangle", dashType: e.dash ? "dash" : "solid" } });
        if (e.label) sl.addText(e.label, { x: e.lx ?? Math.min(e.x1, e.x2), y: e.ly ?? (Math.min(e.y1, e.y2) - 0.38), w: e.lw || Math.max(1.6, Math.abs(e.x2 - e.x1)), h: 0.32, fontSize: e.lsize || 13, color: K.accent, align: e.lalign || "center", margin: 0, isTextBox: true });
      } else if (e.kind === "text") {
        sl.addText(para(e.text, { fontSize: e.size || 15, color: e.muted ? K.muted : K.text, bold: !!e.bold, fontFace: e.head ? F.head : F.body }), { x: e.x, y: e.y, w: e.w, h: e.h || 0.4, valign: e.valign || "top", align: e.align || "left", margin: 0, isTextBox: true });
      }
    }
    if (s.caption) caption(sl, s.caption, s.captionY || 5.9);
    return sl;
  },
  closing(pres, s, sec) {
    const sl = pres.addSlide({ masterName: "CLOSING", sectionTitle: sec });
    label(sl, s.label, true);
    sl.addText(s.title, { placeholder: "title" });
    sl.addText(`From. ${s.from}`, { x: M, y: 2.35, w: 8, h: 0.4, fontSize: 15, bold: true, color: K.accentLt, margin: 0, isTextBox: true });
    sl.addText(para(s.text, { fontFace: F.head, fontSize: 24, color: K.onInk, codeColor: K.accentLt }), { x: M, y: 2.9, w: W - 2 * M - 0.6, h: 2.0, valign: "top", margin: 0, lineSpacingMultiple: 1.3, isTextBox: true });
    sl.addText(para(s.teaser, { fontSize: 17, color: K.onInkMuted, codeColor: K.accentLt }), { x: M, y: 5.3, w: W - 2 * M, h: 1.1, valign: "top", margin: 0, isTextBox: true });
    return sl;
  },
};

function content(pres, s, sec) {
  const sl = pres.addSlide({ masterName: "CONTENT", sectionTitle: sec });
  label(sl, s.label || "");
  sl.addText(s.title, { placeholder: "title" });
  return sl;
}
function caption(sl, text, y) {
  if (y > BOTTOM - 0.3) y = BOTTOM - 0.3;
  sl.addText(para(text, { fontSize: 17, color: K.text }), { x: M, y, w: W - 2 * M, h: Math.max(0.4, BOTTOM + 0.1 - y), valign: "top", margin: 0, isTextBox: true, objectName: "caption" });
}
function aside(sl, text, x, y, w) {
  sl.addShape("line", { x: x - 0.25, y, w: 0, h: 3.6, line: { color: K.line, width: 0.75 } });
  sl.addText(para(text, { fontFace: F.head, fontSize: 19, color: K.text }), { x, y, w, h: 3.6, valign: "top", margin: 0, lineSpacingMultiple: 1.35, isTextBox: true });
}

// ── main ─────────────────────────────────────────────────────
async function main() {
  const [, , inFile, outFile] = process.argv;
  const deck = JSON.parse(fs.readFileSync(inFile, "utf8"));
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE";
  pres.theme = { headFontFace: F.head, bodyFontFace: F.body };
  pres.author = "김준일";
  pres.company = "Korea IT Academy Busan";
  pres.title = deck.title;
  defineLayouts(pres, { org: deck.org, chapter: deck.footer });
  for (const sec of deck.sections) {
    pres.addSection({ title: sec.title });
    for (const s of sec.slides) {
      const fn = R[s.type];
      if (!fn) throw new Error("unknown slide type " + s.type);
      const sl = fn(pres, s, sec.title);
      if (s.notes) sl.addNotes(s.notes);
    }
  }
  await pres.writeFile({ fileName: outFile });
  if (applyTheme) await applyTheme(outFile, THEME);
}
main().catch((e) => { console.error(e); process.exit(1); });
