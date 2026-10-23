// Madinah Mushaf reader: King Fahd Complex QCF4 page fonts inside a Zukhrufa border (port of MushafPages.swift).
import QCF from "./mushaf-qcf.json";
import META from "./quran-meta.json";

const C = { paper: "#F2F9FD", paperDeep: "#D4EAF7", ink: "#14233A", frame: "#2A78AE", muted: "#5A6E86", navy: "#133D63", sky: "#8ED0EE", sky2: "#BFE6F7", gold: "#C79A3A", text: "#111111" };
const PAGES = QCF.pages.map(p => ({ font: p[0], lines: p[p.length - 1].map(l => ({ n: l[0], kind: l[1], text: l[2], ends: new Set(l[3] || []) })) }));
const before = (a, b) => a[0] < b[0] || (a[0] === b[0] && a[1] < b[1]);
export const juzOfPage = p => { const st = META.pages[p - 1]; let j = 0; META.juz.forEach((x, i) => { if (!before(st, x)) j = i; }); return j + 1; };
export const pageOf = (s, n = 1) => { let r = 0; META.pages.forEach((x, i) => { if (!before([s, n], x)) r = i; }); return r + 1; };
export const suraOfPage = p => META.pages[p - 1][0];
export const SURAS = META.suras;
const arDigits = n => String(n).replace(/\d/g, d => String.fromCharCode(0x660 + +d));
const suraTabs = p => { const ls = PAGES[p - 1].lines.filter(l => l.kind === "t"); const f = suraOfPage(p); // first surah on the page, and the last if another one starts
  const hs = PAGES[p - 1].lines.filter(l => l.kind === "h").map(l => +l.text); const all = [f, ...hs]; const last = all[all.length - 1]; return f === last ? [f] : [f, last]; };

/* ---------- fonts ---------- */
const loaded = new Map();
function loadFont(n) {
  const fam = n === 0 ? "QCFHdr" : "QCFp" + String(n).padStart(2, "0");
  if (!loaded.has(n)) {
    const url = n === 0 ? "mushaf/hdr.woff2" : `mushaf/h${String(n).padStart(2, "0")}.woff2`;
    const ff = new FontFace(fam, `url(${url})`);
    loaded.set(n, ff.load().then(f => { document.fonts.add(f); return fam; }).catch(() => fam));
  }
  return loaded.get(n);
}
const famOf = n => (n === 0 ? "QCFHdr" : "QCFp" + String(n).padStart(2, "0"));

/* ---------- Zukhrufa drawing (canvas) ---------- */
const B = 24, L = 48;
const VINE = new Path2D("M0 12 C12 2 24 2 24 12 C24 22 36 22 48 12");
const LEAVES = [
  new Path2D("M12 6.2 C16.5 8.5 17.5 14 14.2 19.5 C13.6 16.6 12.8 15.4 12 15.2 C11.2 15.4 10.4 16.6 9.8 19.5 C6.5 14 7.5 8.5 12 6.2 Z"),
  new Path2D("M36 17.8 C40.5 15.5 41.5 10 38.2 4.5 C37.6 7.4 36.8 8.6 36 8.8 C35.2 8.6 34.4 7.4 33.8 4.5 C30.5 10 31.5 15.5 36 17.8 Z"),
];
const VEINS = new Path2D("M12 8 L12 14.5 M36 16 L36 9.5");
const TENDRILS = new Path2D("M19.5 6.4 C22.5 4.2 25.8 6 24.6 8.6 C23.7 10.4 21.4 9.6 22.2 8 M4.5 6.4 C1.5 4.2 -1.8 6 -0.6 8.6 M28.5 17.6 C25.5 19.8 22.2 18 23.4 15.4 C24.3 13.6 26.6 14.4 25.8 16 M43.5 17.6 C46.5 19.8 49.8 18 48.6 15.4 C47.7 13.6 45.4 14.4 46.2 16");

function flower(ctx, x, y, r) {
  for (let i = 0; i < 5; i++) {
    const a = i * 72 * Math.PI / 180 - Math.PI / 2, px = x + Math.cos(a) * r * 0.62, py = y + Math.sin(a) * r * 0.62;
    ctx.beginPath(); ctx.arc(px, py, r * 0.42, 0, 7); ctx.fillStyle = "#fff"; ctx.fill(); ctx.lineWidth = 0.6; ctx.strokeStyle = C.navy; ctx.stroke();
  }
  ctx.beginPath(); ctx.arc(x, y, r * 0.36, 0, 7); ctx.fillStyle = C.gold; ctx.fill(); ctx.lineWidth = 0.5; ctx.strokeStyle = C.navy; ctx.stroke();
}
// one band tile; m = [a,b,c,d,e,f] maps tile space (x along the band, y=0 on the outer edge) to the canvas
function tile(ctx, m, k) {
  ctx.save(); ctx.transform(...m);
  ctx.fillStyle = C.sky; ctx.fillRect(0, 0, L, B);
  ctx.lineCap = "butt";
  ctx.strokeStyle = "#fff"; ctx.lineWidth = 3.6 / k; ctx.stroke(VINE);
  ctx.strokeStyle = C.navy; ctx.lineWidth = 1.3 / k; ctx.stroke(VINE);
  for (const lf of LEAVES) { ctx.fillStyle = C.gold; ctx.fill(lf); ctx.lineJoin = "round"; ctx.lineWidth = 0.9 / k; ctx.strokeStyle = C.navy; ctx.stroke(lf); }
  ctx.lineWidth = 0.6 / k; ctx.stroke(VEINS);
  ctx.lineCap = "round"; ctx.lineWidth = 1 / k; ctx.stroke(TENDRILS);
  ctx.lineCap = "butt"; ctx.strokeStyle = C.navy; ctx.lineWidth = 1 / k;
  ctx.beginPath(); ctx.moveTo(0, 0.5); ctx.lineTo(L, 0.5); ctx.moveTo(0, B - 0.5); ctx.lineTo(L, B - 0.5); ctx.stroke();
  ctx.strokeStyle = C.gold; ctx.lineWidth = 0.7 / k;
  ctx.beginPath(); ctx.moveTo(0, 2); ctx.lineTo(L, 2); ctx.moveTo(0, B - 2); ctx.lineTo(L, B - 2); ctx.stroke();
  ctx.restore();
  const ap = (x, y) => [m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5]];
  for (const x of [0, 24, 48]) { const [px, py] = ap(x, 12); flower(ctx, px, py, 4.2 * k); }
}
function side(ctx, length, tileLength, k, place) {
  const n = Math.max(1, Math.round(length / tileLength)), sx = length / (n * tileLength);
  for (let i = 0; i < n; i++) tile(ctx, place(i * tileLength * sx, sx), k);
}
function corner(ctx, ox, oy, b) {
  ctx.fillStyle = C.navy; ctx.fillRect(ox, oy, b, b);
  ctx.strokeStyle = C.gold; ctx.lineWidth = 0.7; ctx.strokeRect(ox + 1.6, oy + 1.6, b - 3.2, b - 3.2);
  const cx = ox + b / 2, cy = oy + b / 2, r = b * 0.42;
  for (const [sd, col] of [[r * 1.44, C.gold], [r, C.sky]]) for (const rot of [0, Math.PI / 4]) {
    ctx.save(); ctx.translate(cx, cy); ctx.rotate(rot); ctx.fillStyle = col; ctx.fillRect(-sd / 2, -sd / 2, sd, sd); ctx.restore();
  }
  flower(ctx, cx, cy, 4.4);
}
function guilloche(ctx, x, y, w, h, g) {
  ctx.strokeStyle = C.sky2; ctx.lineWidth = g; ctx.strokeRect(x, y, w, h);
  ctx.strokeStyle = C.navy; ctx.lineWidth = 0.8; ctx.strokeRect(x - g / 2, y - g / 2, w + g, h + g); ctx.strokeRect(x + g / 2, y + g / 2, w - g, h - g);
  const sides = [[x, y, x + w, y], [x, y + h, x + w, y + h], [x, y, x, y + h], [x + w, y, x + w, y + h]];
  for (const [ax, ay, zx, zy] of sides) {
    const len = Math.hypot(zx - ax, zy - ay); if (len <= 9) continue;
    const dx = (zx - ax) / len, dy = (zy - ay) / len, nx = -dy, ny = dx, wl = len / Math.round(len / 9);
    for (const ph of [0, Math.PI]) {
      ctx.beginPath();
      for (let t = 0; t <= len; t++) { const off = 2.1 * Math.sin(t / wl * 2 * Math.PI + ph), qx = ax + dx * t + nx * off, qy = ay + dy * t + ny * off; t ? ctx.lineTo(qx, qy) : ctx.moveTo(qx, qy); }
      ctx.strokeStyle = "#fff"; ctx.lineWidth = 1.8; ctx.stroke(); ctx.strokeStyle = C.navy; ctx.lineWidth = 0.7; ctx.stroke();
    }
  }
}
const FK = 0.62, FOUT = 4, FBAND = B * FK, TEXT_SIDE = 30, TEXT_TOP = 38;
function frame(ctx, W, H) {
  const o = FOUT, b = FBAND, k = FK;
  ctx.lineWidth = 1.2; ctx.strokeStyle = C.navy; ctx.strokeRect(0.75, 0.75, W - 1.5, H - 1.5);
  ctx.lineWidth = 0.7; ctx.strokeStyle = C.gold; ctx.strokeRect(2.5, 2.5, W - 5, H - 5);
  const ix = o + b, iy = o + b, iw = W - 2 * (o + b), ih = H - 2 * (o + b);
  ctx.fillStyle = C.paper; ctx.fillRect(ix, iy, iw, ih);
  const tl = L * k;
  side(ctx, iw, tl, k, (t, sx) => [sx * k, 0, 0, k, o + b + t, o]);
  side(ctx, iw, tl, k, (t, sx) => [sx * k, 0, 0, -k, o + b + t, H - o]);
  side(ctx, ih, tl, k, (t, sx) => [0, sx * k, k, 0, o, o + b + t]);
  side(ctx, ih, tl, k, (t, sx) => [0, sx * k, -k, 0, W - o, o + b + t]);
  for (const [cx, cy] of [[o, o], [W - o - b, o], [o, H - o - b], [W - o - b, H - o - b]]) corner(ctx, cx, cy, b);
  guilloche(ctx, ix + 2.5, iy + 2.5, iw - 5, ih - 5, 5);
}
function cartouchePath(ctx, x, y, w, h) {
  const e = Math.min(h * 0.55, w / 4), r = x + w, bt = y + h, my = y + h / 2;
  ctx.beginPath(); ctx.moveTo(x, my);
  ctx.quadraticCurveTo(x + e * 0.1, y, x + e, y); ctx.lineTo(r - e, y);
  ctx.quadraticCurveTo(r - e * 0.1, y, r, my); ctx.quadraticCurveTo(r - e * 0.1, bt, r - e, bt);
  ctx.lineTo(x + e, bt); ctx.quadraticCurveTo(x + e * 0.1, bt, x, my); ctx.closePath();
}
const fitCache = new Map();
function fitGlyph(ctx, glyph, w, h) {
  const key = glyph + "|" + w.toFixed(1) + "|" + h.toFixed(1); if (fitCache.has(key)) return fitCache.get(key);
  ctx.save(); ctx.font = `100px ${famOf(0)}`; const m = ctx.measureText(glyph); ctx.restore();
  const bw = m.actualBoundingBoxLeft + m.actualBoundingBoxRight, bh = m.actualBoundingBoxAscent + m.actualBoundingBoxDescent;
  const r = bw > 0 && bh > 0 ? { k: Math.min(w / bw, h / bh), m } : { k: 0.2, m }; fitCache.set(key, r); return r;
}
// lozenge cartouche; glyph = calligraphic header (QBSML) or text
function cartouche(ctx, cx, cy, w, h, label, isGlyph) {
  const x = cx - w / 2, y = cy - h / 2;
  cartoucheLabelBg(ctx, x, y, w, h);
  ctx.save(); ctx.fillStyle = "#000"; ctx.textBaseline = "alphabetic";
  if (isGlyph) {
    const f = fitGlyph(ctx, label, w * 0.72, h * 0.66), s = 100 * f.k, m = f.m;
    ctx.font = `${s}px ${famOf(0)}`; ctx.textAlign = "left";
    const px = cx - (m.actualBoundingBoxRight - m.actualBoundingBoxLeft) / 2 * f.k, py = cy + (m.actualBoundingBoxAscent - m.actualBoundingBoxDescent) / 2 * f.k;
    for (const [dx, dy] of [[0, 0], [0.3, 0], [0, 0.2]]) ctx.fillText(label, px + dx, py + dy);
  } else {
    ctx.fillStyle = C.navy; ctx.font = `700 ${Math.min(14, h * 0.58)}px system-ui,sans-serif`; ctx.textAlign = "center"; ctx.fillText(label, cx, cy + h * 0.2);
  }
  ctx.restore();
}
function cartoucheLabelBg(ctx, x, y, w, h) {
  cartouchePath(ctx, x + 3.5, y + 2.5, w - 7, h - 5); ctx.fillStyle = C.sky2; ctx.fill(); // inset (under)
  cartouchePath(ctx, x, y, w, h); ctx.fillStyle = "#fff"; ctx.fill();
  cartouchePath(ctx, x + 3.5, y + 2.5, w - 7, h - 5); ctx.fillStyle = C.sky2; ctx.globalAlpha = 0.55; ctx.fill(); ctx.globalAlpha = 1;
  ctx.strokeStyle = C.gold; ctx.lineWidth = 0.8; cartouchePath(ctx, x + 3.5, y + 2.5, w - 7, h - 5); ctx.stroke();
  ctx.strokeStyle = C.navy; ctx.lineWidth = 1.3; cartouchePath(ctx, x, y, w, h); ctx.stroke();
}
function banner(ctx, x, y, w, h, sura) {
  ctx.save(); ctx.beginPath(); ctx.rect(x, y, w, h); ctx.clip();
  const k = h / B; side(ctx, w, L * k, k, (t, sx) => [sx * k, 0, 0, k, x + t, y]);
  ctx.restore(); ctx.strokeStyle = C.navy; ctx.lineWidth = 1.2; ctx.strokeRect(x + 0.6, y + 0.6, w - 1.2, h - 1.2);
  cartouche(ctx, x + w / 2, y + h / 2, Math.min(w * 0.6, 270), h * 0.86, String.fromCharCode(0xF100 + sura - 1), true);
}

/* ---------- lines ---------- */
function qrows(page) {
  const p = PAGES[page - 1], count = page <= 2 ? Math.max(...p.lines.map(l => l.n)) : 15, out = new Array(count).fill(null);
  for (const l of p.lines) {
    if (l.n < 1 || l.n > count) continue;
    if (l.kind === "h") out[l.n - 1] = { t: "banner", sura: +l.text };
    else if (l.kind === "b") out[l.n - 1] = page > 2 ? { t: "bis", text: "𢡄𣏕㮝䀘", font: 0 } : { t: "bis", text: l.text, font: p.font };
    else out[l.n - 1] = { t: "text", text: l.text, ends: l.ends };
  }
  return { font: p.font, rows: out };
}
const MARK = 1.3;
function drawLine(ctx, text, fontNo, size, x, y, w, h, centred, ends) {
  ctx.save(); ctx.font = `${size}px ${famOf(fontNo)}`; ctx.textAlign = "left"; ctx.textBaseline = "alphabetic";
  const chars = [...text], adv = chars.map(c => ctx.measureText(c).width);
  ends.forEach(i => { if (adv[i] != null) adv[i] *= MARK; });
  const natural = adv.reduce((a, b) => a + b, 0); if (natural <= 0) { ctx.restore(); return; }
  let scale = 1; if (natural > w) scale = w / natural; else if (!centred && natural > w * 0.88) scale = w / natural;
  const total = natural * scale; let px = x + (w + total) / 2;
  const m = ctx.measureText(""); const asc = m.fontBoundingBoxAscent ?? size * 0.9, desc = m.fontBoundingBoxDescent ?? size * 0.3;
  const base = y + (h + (asc - desc)) / 2;
  ctx.lineJoin = "round";
  for (let i = 0; i < chars.length; i++) {
    const wd = adv[i] * scale; px -= wd; const isMark = ends.has(i);
    ctx.save(); ctx.translate(px, base + (isMark ? -size * 0.04 : 0)); ctx.scale(scale * (isMark ? MARK : 1), isMark ? MARK : 1);
    const col = isMark ? C.frame : C.text; ctx.fillStyle = col; ctx.strokeStyle = col; ctx.lineWidth = size * (isMark ? 0.012 : 0.03);
    ctx.strokeText(chars[i], 0, 0); ctx.fillText(chars[i], 0, 0); ctx.restore();
  }
  ctx.restore();
}

/* ---------- page ---------- */
export async function drawPage(canvas, page, cssW, cssH) {
  const dpr = Math.min(3, (window.devicePixelRatio || 1) * 1.5);
  canvas.width = Math.round(cssW * dpr); canvas.height = Math.round(cssH * dpr);
  canvas.style.width = cssW + "px"; canvas.style.height = cssH + "px";
  const { font, rows } = qrows(page);
  await Promise.all([loadFont(font), loadFont(0)]);
  if (canvas.dataset.page !== String(page)) return;
  const ctx = canvas.getContext("2d"); ctx.setTransform(dpr, 0, 0, dpr, 0, 0); ctx.clearRect(0, 0, cssW, cssH);
  const W = cssW, H = cssH, bw = W - 2 * TEXT_SIDE, bh = H - 2 * TEXT_TOP, opening = page <= 2;
  const rowH = opening ? Math.min(bh / Math.max(rows.length, 1), bh / 11) : bh / Math.max(rows.length, 1);
  const size = Math.min(bw / 16.3, rowH / 1.25), bandY = FOUT + FBAND / 2;
  frame(ctx, W, H);
  rows.forEach((r, i) => {
    if (!r) return; const x = TEXT_SIDE, y = TEXT_TOP + i * rowH;
    if (r.t === "banner") { const bhh = Math.min(rowH * 0.86, size * 2.1); banner(ctx, x, y + (rowH - bhh) / 2, bw, bhh, r.sura); }
    else if (r.t === "bis") drawLine(ctx, r.text, r.font, size * 1.12, x, y, bw, rowH, true, new Set());
    else drawLine(ctx, r.text, font, size, x, y, bw, rowH, opening, r.ends);
  });
  const tabs = [String.fromCharCode(0xF1D8 + Math.min(Math.max(juzOfPage(page), 1), 30) - 1), ...suraTabs(page).map(s => String.fromCharCode(0xF100 + s - 1))];
  const tabW = Math.min(146, (W - 70) / tabs.length - 6);
  tabs.forEach((t, i) => {
    const slot = W - 34 - tabW / 2 - i * (W - 68 - tabW) / Math.max(1, tabs.length - 1);
    cartouche(ctx, tabs.length === 1 ? W / 2 : slot, Math.max(bandY, 19), tabW, 36, t, true);
  });
  cartouche(ctx, W / 2, H - bandY, 64, 24, arDigits(page), false);
}

/* ---------- reader UI ---------- */
let state = { page: 1, index: false, byJuz: false, zoom: 1, tx: 0, ty: 0 };
try { state.page = Math.min(604, Math.max(1, +localStorage.getItem("rafeeq_mpage") || 1)); } catch (e) {}
const juzOrd = ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس", "السابع", "الثامن", "التاسع", "العاشر", "الحادي عشر", "الثاني عشر", "الثالث عشر", "الرابع عشر", "الخامس عشر", "السادس عشر", "السابع عشر", "الثامن عشر", "التاسع عشر", "العشرون", "الحادي والعشرون", "الثاني والعشرون", "الثالث والعشرون", "الرابع والعشرون", "الخامس والعشرون", "السادس والعشرون", "السابع والعشرون", "الثامن والعشرون", "التاسع والعشرون", "الثلاثون"];
const ICON = { back: '<svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>', list: '<svg viewBox="0 0 24 24"><path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/></svg>' };

export function mushafHTML(isAr) {
  const s = suraOfPage(state.page);
  return `<div class="mush" id="mush"><div class="mbar"><button class="mbtn" data-act="mclose" aria-label="Done">${ICON.back}</button>
    <div class="mtitle" id="mtitle">سورة ${SURAS[s - 1].ar}</div><button class="mbtn" data-act="mindex" aria-label="${isAr ? "الفهرس" : "Surahs"}">${ICON.list}</button></div>
    <div class="mstage" id="mstage"><div class="mpage" id="mpage"><canvas id="mcanvas"></canvas></div></div>
    <div id="mindexhost"></div></div>`;
}
let rendering = 0;
export function mushafAfter(isAr, L) {
  CTX = { isAr, L };
  const stage = document.getElementById("mstage"); if (!stage) return;
  const fit = () => { const r = stage.getBoundingClientRect(); return [Math.max(200, r.width - 16), Math.max(300, r.height - 12)]; };
  const paint = () => { const cv = document.getElementById("mcanvas"); if (!cv) return; const [w, h] = fit(); cv.dataset.page = String(state.page); const tk = ++rendering;
    drawPage(cv, state.page, w, h).then(() => {}); document.getElementById("mtitle").textContent = "سورة " + SURAS[suraOfPage(state.page) - 1].ar;
    try { localStorage.setItem("rafeeq_mpage", String(state.page)); } catch (e) {} void tk; };
  const go = d => { const n = Math.min(604, Math.max(1, state.page + d)); if (n !== state.page) { state.page = n; resetZoom(); paint(); } };
  const mp = document.getElementById("mpage");
  const resetZoom = () => { state.zoom = 1; state.tx = 0; state.ty = 0; mp.style.transform = ""; };
  const applyZoom = () => { mp.style.transform = `translate(${state.tx}px,${state.ty}px) scale(${state.zoom})`; };
  // swipe: right = next page (like a printed Mushaf), left = previous; pinch / double-tap to zoom
  let t0 = null, pinch = null, lastTap = 0;
  stage.addEventListener("touchstart", e => {
    if (e.touches.length === 2) { pinch = { d: Math.hypot(e.touches[0].clientX - e.touches[1].clientX, e.touches[0].clientY - e.touches[1].clientY), z: state.zoom }; t0 = null; }
    else if (e.touches.length === 1) { t0 = { x: e.touches[0].clientX, y: e.touches[0].clientY, tx: state.tx, ty: state.ty, t: Date.now() }; }
  }, { passive: true });
  stage.addEventListener("touchmove", e => {
    if (pinch && e.touches.length === 2) { const d = Math.hypot(e.touches[0].clientX - e.touches[1].clientX, e.touches[0].clientY - e.touches[1].clientY); state.zoom = Math.min(4, Math.max(1, pinch.z * d / pinch.d)); applyZoom(); e.preventDefault(); }
    else if (t0 && state.zoom > 1) { state.tx = t0.tx + e.touches[0].clientX - t0.x; state.ty = t0.ty + e.touches[0].clientY - t0.y; applyZoom(); e.preventDefault(); }
  }, { passive: false });
  stage.addEventListener("touchend", e => {
    if (pinch) { if (e.touches.length < 2) { pinch = null; if (state.zoom < 1.05) resetZoom(); } return; }
    if (!t0) return; const x = e.changedTouches[0].clientX, y = e.changedTouches[0].clientY, dx = x - t0.x, dy = y - t0.y, now = Date.now(), moved = Math.abs(dx) + Math.abs(dy);
    if (state.zoom === 1 && Math.abs(dx) > 55 && Math.abs(dx) > Math.abs(dy) * 1.4) go(dx > 0 ? 1 : -1);
    else if (moved < 10) { if (now - lastTap < 300) { if (state.zoom > 1) resetZoom(); else { state.zoom = 2.2; const r = stage.getBoundingClientRect(); state.tx = (r.width / 2 - (x - r.left)) * 1.2; state.ty = (r.height / 2 - (y - r.top)) * 1.2; applyZoom(); } lastTap = 0; } else lastTap = now; }
    t0 = null;
  }, { passive: true });
  // desktop / keyboard
  window.onkeydown = e => { if (!document.getElementById("mush")) return; if (e.key === "ArrowLeft") go(1); if (e.key === "ArrowRight") go(-1); };
  paint();
  window.__mushPaint = paint; window.__mushGo = go;
  mushafAfter.go = go;
  if (state.index) renderIndex(isAr, L);
}
let CTX = { isAr: true, L: s => s };
export function mushafIndexToggle() { state.index = !state.index; renderIndex(CTX.isAr, CTX.L); }
export function mushafBy(j) { state.byJuz = j; renderIndex(CTX.isAr, CTX.L); }
export function mushafSetPage(p) { state.page = p; state.index = false; }
export const mushafState = state;
function renderIndex(isAr, L) {
  const host = document.getElementById("mindexhost"); if (!host) return;
  if (!state.index) { host.innerHTML = ""; return; }
  const rows = state.byJuz
    ? Array.from({ length: 30 }, (_, i) => { const st = META.juz[i]; return `<button class="xrow" data-act="mgo" data-p="${pageOf(st[0], st[1])}"><span class="mn">${isAr ? arDigits(i + 1) : i + 1}</span><span class="mt"><b>الجزء ${juzOrd[i]}</b><small>سورة ${SURAS[st[0] - 1].ar} · ${isAr ? arDigits(st[1]) : st[1]}</small></span><span class="mp">${isAr ? arDigits(pageOf(st[0], st[1])) : pageOf(st[0], st[1])}</span></button>`; })
    : SURAS.map((s, i) => `<button class="xrow" data-act="mgo" data-p="${pageOf(i + 1)}"><span class="mn">${isAr ? arDigits(i + 1) : i + 1}</span><span class="mt"><b>سورة ${s.ar}</b><small>${isAr ? "" : s.tr + " · "}${isAr ? (s.type === "Meccan" ? "مكية" : "مدنية") + " · " + arDigits(s.ayas) + " آية" : s.ayas + " " + L("ayahs")}</small></span><span class="mp">${isAr ? arDigits(pageOf(i + 1)) : pageOf(i + 1)}</span></button>`).join("");
  host.innerHTML = `<div class="mindex"><div class="mseg"><button class="${state.byJuz ? "" : "sel"}" data-act="mseg" data-v="0">${isAr ? "السور" : L("Surahs")}</button><button class="${state.byJuz ? "sel" : ""}" data-act="mseg" data-v="1">${isAr ? "الأجزاء" : L("Juz")}</button></div>
    <button class="mx" data-act="mindex">✕</button><div class="mlist">${rows}<div class="mfoot">${isAr ? "نص المصحف وخطه: مجمع الملك فهد لطباعة المصحف الشريف، الرسم العثماني برواية حفص (مصحف المدينة النبوية)" : "Quran text and font: King Fahd Glorious Quran Printing Complex, Uthmani script, Hafs (Madinah Mushaf)"}</div></div></div>`;
}
