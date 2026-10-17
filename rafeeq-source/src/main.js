import { Capacitor } from "@capacitor/core";
import { LocalNotifications } from "@capacitor/local-notifications";
import { Geolocation } from "@capacitor/geolocation";
import DATA from "./data.json";
import AR from "./ar.json";
import { Qibla, haversine, diff, norm, cardinal, sunInfo, METHODS, PRAYERS, prayerEvents, dayFor } from "./core.js";

/* ---------- palettes (same as the iOS app) ---------- */
const H = n => "#" + n.toString(16).padStart(6, "0");
const P = (id, title, bg, card, ink, muted, line, tile, accent, deep, tint, rowNow, on) => ({ id, title, c: { bg, card, ink, muted, line, tile, accent, deep, tint, rowNow, on } });
const PALETTES = [
  P("ocean", "Ocean", [0xEDF2F8, 0x0B0F17], [0xFFFFFF, 0x2A3040], [0x0E1726, 0xEEF2F8], [0x5B677A, 0x9AA3B5], [0xDCE5F0, 0x3E4558], [0xE3ECF6, 0x3A4156], [0x2F9BE8, 0x55BBFA], [0x1B7FCC, 0x55BBFA], [0xDCEBFA, 0x1F3550], [0xDCEBFA, 0x34405A], [0xFFFFFF, 0x0B0F17]),
  P("emerald", "Emerald", [0xEAF5EF, 0x08130F], [0xFFFFFF, 0x15271F], [0x0B2A1F, 0xECF8F2], [0x527466, 0x8FB0A2], [0xD2E5DB, 0x27443A], [0xDDEEE5, 0x1F382E], [0x22B07D, 0x34D399], [0x0A7552, 0x4ADFA8], [0xD8F3E6, 0x12362B], [0xD8F3E6, 0x16382B], [0xFFFFFF, 0x06150F]),
  P("royal", "Royal", [0xF2EEFA, 0x0F0B1A], [0xFFFFFF, 0x241C38], [0x1B1230, 0xF3EEFC], [0x6A5C86, 0xA99BC4], [0xE1D8F2, 0x3B2F58], [0xE9E1F7, 0x33284D], [0x8A5CE0, 0xB794F6], [0x6D3FC4, 0xC4A8FA], [0xE8DEFA, 0x2E2248], [0xE8DEFA, 0x33264F], [0xFFFFFF, 0x150E26]),
  P("sunset", "Sunset", [0xFDF1EA, 0x150C08], [0xFFFFFF, 0x2B1B14], [0x2B1308, 0xFDF1EA], [0x8A6552, 0xBFA08F], [0xF3DACB, 0x4A2F22], [0xF9E5D8, 0x3B261B], [0xF26B21, 0xFF8A4C], [0xD04E0A, 0xFF9F69], [0xFCDDC8, 0x3A2316], [0xFCDDC8, 0x40271A], [0xFFFFFF, 0x1E0C03]),
  P("rose", "Rose", [0xFCEFF2, 0x170B10], [0xFFFFFF, 0x2C1820], [0x2B0F18, 0xFDEFF3], [0x8A5A68, 0xC09AA8], [0xF2D6DD, 0x4A2A37], [0xF8E3E8, 0x3B2029], [0xEE5C85, 0xFF7A9C], [0xC8325A, 0xFF93AF], [0xFBDDE6, 0x3A1E29], [0xFBDDE6, 0x40202C], [0xFFFFFF, 0x1E0810]),
  P("graphite", "Graphite", [0xEFF0F2, 0x0E0F11], [0xFFFFFF, 0x232528], [0x15171A, 0xF2F3F5], [0x5F656E, 0x9EA3AB], [0xDDE0E4, 0x383B40], [0xE6E8EB, 0x2E3136], [0x4A5058, 0xD6DAE0], [0x2B3036, 0xE4E7EB], [0xE1E4E8, 0x2A2D32], [0xE1E4E8, 0x30343A], [0xFFFFFF, 0x101113]),
];

/* ---------- settings store ---------- */
const DEF = {
  lang: "ar", palette: "ocean", appearance: "auto", textSize: "1", bold: false, azkarSize: "1",
  method: "kuwait", hanafi: false, off: {}, notif: false, remind: 0, sunriseAlert: false, muted: {},
  temp: "c", preview: false, tab: 1, welcomed: false,
  place: { name: "Kuwait City", country: "Kuwait", lat: 29.3759, lon: 47.9774, tz: "Asia/Kuwait", iso: "KW" },
  gps: false,
};
let S = { ...DEF };
try { Object.assign(S, JSON.parse(localStorage.getItem("rafeeq") || "{}")); } catch (e) {}
const save = () => { try { localStorage.setItem("rafeeq", JSON.stringify(S)); } catch (e) {} };
const ar = () => S.lang === "ar";
const L = s => (ar() ? (AR[s] || s) : s);
const esc = s => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const $ = (s, r = document) => r.querySelector(s);
const method = () => METHODS.find(m => m.id === S.method) || METHODS[0];
const iso3 = c => DATA.iso3[c] || c;
const CITIES = DATA.cities.map(c => ({ name: c[0], country: c[1], lat: c[2], lon: c[3], tz: c[4], iso: c[5] }));

const LANGS = [["ar", "العربية · Arabic"], ["en", "English · English"], ["tr", "Türkçe · Turkish"], ["fr", "Français · French"], ["it", "Italiano · Italian"], ["de", "Deutsch · German"], ["nl", "Nederlands · Dutch"], ["es", "Español · Spanish"]];
const PNAME_EN = { fajr: "Fajr", sunrise: "Sunrise", dhuhr: "Dhuhr", asr: "Asr", maghrib: "Maghrib", isha: "Isha" };
const PNAME_AR = { fajr: "الفجر", sunrise: "الشروق", dhuhr: "الظهر", asr: "العصر", maghrib: "المغرب", isha: "العشاء" };
const PNAME_LOCAL = {
  tr: { fajr: "İmsak", sunrise: "Güneş", dhuhr: "Öğle", asr: "İkindi", maghrib: "Akşam", isha: "Yatsı" },
  fr: { fajr: "Fajr (Aube)", sunrise: "Lever du soleil", dhuhr: "Dhuhr (Midi)", asr: "Asr (Après-midi)", maghrib: "Maghrib (Coucher)", isha: "Isha (Nuit)" },
  it: { fajr: "Fajr (Alba)", sunrise: "Alba solare", dhuhr: "Dhuhr (Mezzogiorno)", asr: "Asr (Pomeriggio)", maghrib: "Maghrib (Tramonto)", isha: "Isha (Notte)" },
  de: { fajr: "Fadschr (Morgen)", sunrise: "Sonnenaufgang", dhuhr: "Dhuhr (Mittag)", asr: "Asr (Nachmittag)", maghrib: "Maghrib (Abend)", isha: "Ischa (Nacht)" },
  nl: { fajr: "Fadjr (Dageraad)", sunrise: "Zonsopkomst", dhuhr: "Dhuhr (Middag)", asr: "Asr (Namiddag)", maghrib: "Maghrib (Zonsondergang)", isha: "Isja (Nacht)" },
  es: { fajr: "Fajr (Alba)", sunrise: "Amanecer", dhuhr: "Dhuhr (Mediodía)", asr: "Asr (Tarde)", maghrib: "Magrib (Atardecer)", isha: "Isha (Noche)" },
};
const pName = p => (ar() ? PNAME_AR[p] : PNAME_EN[p]);
const pLocal = p => (PNAME_LOCAL[S.lang] || PNAME_AR)[p];
const CAT_TITLES = {
  ar: ["الصباح", "المساء", "بعد الصلاة", "النوم", "السفر"], en: ["Morning", "Evening", "After prayer", "Sleep", "Travel"],
  tr: ["Sabah", "Akşam", "Namaz sonrası", "Uyku", "Yolculuk"], fr: ["Matin", "Soir", "Après la prière", "Sommeil", "Voyage"],
  it: ["Mattina", "Sera", "Dopo la preghiera", "Sonno", "Viaggio"], de: ["Morgen", "Abend", "Nach dem Gebet", "Schlaf", "Reise"],
  nl: ["Ochtend", "Avond", "Na het gebed", "Slaap", "Reis"], es: ["Mañana", "Tarde", "Tras la oración", "Dormir", "Viaje"],
};
const CATS = ["morning", "evening", "afterPrayer", "sleep", "travel"];
const catTitle = i => (CAT_TITLES[S.lang] || CAT_TITLES.en)[i];

/* ---------- icons ---------- */
const I = {
  qibla: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 5.5l3 6.5-3 6.5-3-6.5z" fill="currentColor"/></svg>',
  clock: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 6.5V12l3.5 2.2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></svg>',
  mosque: '<svg viewBox="0 0 24 24"><path d="M12 2c.8 1.4 1 2 1 3a1 1 0 0 1-2 0c0-1 .2-1.6 1-3zM5 21v-8h14v8M3 21h18M7.5 13c0-3 2-5 4.500-5s4.500 2 4.500 5M3 21V10M21 21V10" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></svg>',
  dua: '<span class="mask" style="-webkit-mask-image:url(dua.png);mask-image:url(dua.png)"></span>',
  gear: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3.2" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.100 2.100M16.600 16.600l2.100 2.100M5.300 18.700l2.100-2.100M16.600 7.400l2.100-2.100" stroke="currentColor" stroke-width="2.200" stroke-linecap="round"/></svg>',
  pin: '<svg viewBox="0 0 24 24"><path d="M12 21s7-6.2 7-11.500A7 7 0 0 0 5 9.500C5 14.800 12 21 12 21z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="9.500" r="2.500" fill="currentColor"/></svg>',
  chev: '<svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.400" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  left: '<svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" stroke-width="2.600" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  right: '<svg viewBox="0 0 24 24"><path d="M9 5l7 7-7 7" fill="none" stroke="currentColor" stroke-width="2.600" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  refresh: '<svg viewBox="0 0 24 24"><path d="M20 12a8 8 0 1 1-2.500-5.800M20 4v5h-5" fill="none" stroke="currentColor" stroke-width="2.400" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  bell: '<svg viewBox="0 0 24 24"><path d="M6 17V11a6 6 0 0 1 12 0v6l1.500 2h-15zM10 21a2 2 0 0 0 4 0" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg>',
  bellOff: '<svg viewBox="0 0 24 24"><path d="M6 17V11a6 6 0 0 1 12 0v6l1.500 2h-15zM10 21a2 2 0 0 0 4 0M4 4l16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></svg>',
  check: '<svg viewBox="0 0 24 24"><path d="M5 12.500l4.500 4.500L19 7" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  rot: '<svg viewBox="0 0 24 24"><path d="M20 12a8 8 0 1 1-2.500-5.800M20 4v5h-5" fill="none" stroke="currentColor" stroke-width="2.600" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  rotL: '<svg viewBox="0 0 24 24" style="transform:scaleX(-1)"><path d="M20 12a8 8 0 1 1-2.500-5.800M20 4v5h-5" fill="none" stroke="currentColor" stroke-width="2.600" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  palette: '<svg viewBox="0 0 24 24"><path d="M12 3a9 9 0 1 0 0 18c1.500 0 2-1 1.500-2.200-.5-1.300.2-2.300 1.500-2.300H17a4 4 0 0 0 4-4C21 6.500 17 3 12 3z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="7.500" cy="11" r="1.300" fill="currentColor"/><circle cx="10.500" cy="7.500" r="1.300" fill="currentColor"/><circle cx="15" cy="8" r="1.300" fill="currentColor"/></svg>',
};

/* ---------- theme ---------- */
function applyTheme() {
  const pal = PALETTES.find(p => p.id === S.palette) || PALETTES[0];
  const dark = S.appearance === "dark" || (S.appearance === "auto" && matchMedia("(prefers-color-scheme: dark)").matches);
  const r = document.documentElement.style, i = dark ? 1 : 0;
  for (const [k, v] of Object.entries(pal.c)) r.setProperty("--" + k, H(v[i]));
  r.setProperty("--zg", "#35D07F"); r.setProperty("--zy", "#FFC83D"); r.setProperty("--zr", "#FF5A5F"); r.setProperty("--sun", "#FF9F1C");
  r.setProperty("--ts", String(+S.textSize || 1)); r.setProperty("--as", String(+S.azkarSize || 1));
  document.documentElement.style.fontSize = 16 * (+S.textSize || 1) + "px";
  document.documentElement.dir = ar() ? "rtl" : "ltr";
  document.documentElement.lang = S.lang;
  document.body.classList.toggle("bold", !!S.bold);
  document.body.classList.toggle("dark", dark);
  document.querySelector('meta[name="theme-color"]').setAttribute("content", H(pal.c.bg[i]));
}
matchMedia("(prefers-color-scheme: dark)").addEventListener?.("change", () => { applyTheme(); render(); });

/* ---------- compass sensor ---------- */
const sensor = { heading: null, accuracy: null, available: true, listening: false, needPermission: false };
let shown = 0, previewDeg = 0, dialEls = null, wasAligned = false;
function headingFrom(e) {
  if (e.webkitCompassHeading != null) return e.webkitCompassHeading;
  if (e.alpha == null) return null;
  const a = e.alpha * Math.PI / 180, b = (e.beta || 0) * Math.PI / 180, g = (e.gamma || 0) * Math.PI / 180;
  const cA = Math.cos(a), sA = Math.sin(a), sB = Math.sin(b), cB = Math.cos(b), sG = Math.sin(g), cG = Math.cos(g);
  const rA = -cA * sG - sA * sB * cG, rB = -sA * sG + cA * sB * cG;
  let h = Math.atan2(rA, rB); if (h < 0) h += 2 * Math.PI;
  return h * 180 / Math.PI;
}
let lastSensor = 0;
function onOrient(e) {
  if (e.type === "deviceorientation" && sensor.absSeen && e.webkitCompassHeading == null) return;
  if (e.type === "deviceorientationabsolute") sensor.absSeen = true;
  if (e.type === "deviceorientation" && e.webkitCompassHeading == null && e.absolute !== true) return;
  const h = headingFrom(e); if (h == null || isNaN(h)) return;
  sensor.heading = h; sensor.accuracy = e.webkitCompassAccuracy ?? null;
  const now = performance.now(); if (now - lastSensor < 40) return; lastSensor = now;
  if (S.tab === 0 && !S.preview) updateDial();
}
async function startCompass() {
  if (sensor.listening) return;
  try {
    if (typeof DeviceOrientationEvent !== "undefined" && typeof DeviceOrientationEvent.requestPermission === "function") {
      const r = await DeviceOrientationEvent.requestPermission();
      if (r !== "granted") { sensor.denied = true; return; }
    }
  } catch (e) { sensor.needPermission = true; return; }
  window.addEventListener("deviceorientationabsolute", onOrient, true);
  window.addEventListener("deviceorientation", onOrient, true);
  sensor.listening = true;
  setTimeout(() => { if (sensor.heading == null) { sensor.available = false; if (S.tab === 0) render(); } }, 2500);
}
const needsPerm = () => typeof DeviceOrientationEvent !== "undefined" && typeof DeviceOrientationEvent.requestPermission === "function";

/* ---------- state: place, weather ---------- */
const net = { online: navigator.onLine };
addEventListener("online", () => { net.online = true; loadWeather(); render(); }); addEventListener("offline", () => { net.online = false; render(); });
let weather = null;
async function loadWeather() {
  try {
    const p = S.place;
    const r = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${p.lat}&longitude=${p.lon}&current=temperature_2m,weather_code,is_day&timezone=auto`);
    const j = await r.json(); weather = { t: j.current.temperature_2m, code: j.current.weather_code, day: j.current.is_day === 1 };
    const el = $("#wchip"); if (el) el.outerHTML = weatherChip();
  } catch (e) {}
}
function wIcon(c, day) {
  if (c === 0) return day ? "☀️" : "🌙"; if (c <= 2) return day ? "🌤️" : "☁️"; if (c === 3) return "☁️"; if (c <= 48) return "🌫️";
  if (c <= 57) return "🌦️"; if (c <= 67) return "🌧️"; if (c <= 77) return "🌨️"; if (c <= 82) return "🌧️"; if (c <= 86) return "🌨️"; return "⛈️";
}
function weatherChip() {
  const w = weather;
  const txt = !w ? (net.online ? "…" : "—") : (S.temp === "f" ? Math.round(w.t * 9 / 5 + 32) + "°F" : Math.round(w.t) + "°C");
  return `<div class="chip" id="wchip"><span>${w ? wIcon(w.code, w.day) : (net.online ? "☁️" : "📴")}</span><b>${txt}</b></div>`;
}
function qiblaDeg() { return Qibla.bearing(S.place.lat, S.place.lon); }

async function useGPS(silent) {
  gpsState = "finding"; if (!silent) render();
  try {
    let pos;
    if (Capacitor.isNativePlatform()) {
      const pm = await Geolocation.requestPermissions();
      if (pm.location === "denied") throw new Error("denied");
      pos = await Geolocation.getCurrentPosition({ enableHighAccuracy: true, timeout: 15000 });
    } else {
      pos = await new Promise((ok, no) => navigator.geolocation.getCurrentPosition(ok, no, { enableHighAccuracy: true, timeout: 15000 }));
    }
    const { latitude: lat, longitude: lon, accuracy } = pos.coords;
    gpsAcc = accuracy;
    let near = CITIES.map(c => ({ c, d: haversine(lat, lon, c.lat, c.lon) })).sort((a, b) => a.d - b.d)[0];
    let name = near.d < 40 ? near.c.name : "My location", country = near.c.country, iso = near.c.iso;
    if (net.online) {
      try {
        const r = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&zoom=10&accept-language=${ar() ? "ar" : "en"}&lat=${lat}&lon=${lon}`);
        const j = await r.json(); const a = j.address || {};
        name = a.city || a.town || a.village || a.suburb || a.county || a.state || name; country = a.country || country; iso = (a.country_code || iso || "--").toUpperCase();
      } catch (e) {}
    } else if (near.d >= 40) { iso = near.c.iso; }
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || near.c.tz;
    S.place = { name, country, lat, lon, tz, iso, gps: true }; S.gps = true; save();
    gpsState = "ok"; weather = null; loadWeather(); scheduleAlerts(); render();
  } catch (e) { gpsState = "denied"; render(); }
}
let gpsState = "idle", gpsAcc = null;

/* ---------- alerts ---------- */
const nativeOK = () => Capacitor.isNativePlatform();
async function scheduleAlerts() {
  if (!nativeOK()) return;
  try {
    const pending = await LocalNotifications.getPending();
    if (pending.notifications.length) await LocalNotifications.cancel({ notifications: pending.notifications });
    if (!S.notif) return;
    await LocalNotifications.createChannel({ id: "adhan", name: "Adhan alerts", importance: 5, visibility: 1, vibration: true });
    const p = S.place, now = Date.now();
    const ev = prayerEvents(now, p.lat, p.lon, p.tz, method(), S.hanafi, offs(), 10).all
      .filter(e => e.date > now && (e.prayer !== "sunrise" || S.sunriseAlert) && !S.muted[e.prayer]);
    const list = []; let id = 1;
    for (const e of ev.slice(0, 120)) {
      const nm = ar() ? PNAME_AR[e.prayer] : PNAME_EN[e.prayer];
      list.push({ id: id++, title: ar() ? `حان وقت ${nm}` : `Time for ${nm}`, body: p.name, channelId: "adhan", schedule: { at: new Date(e.date), allowWhileIdle: true } });
      if (S.remind > 0 && e.date - S.remind * 60000 > now)
        list.push({ id: id++, title: ar() ? `${nm} بعد ${S.remind} دقيقة` : `${nm} in ${S.remind} minutes`, body: p.name, channelId: "adhan", schedule: { at: new Date(e.date - S.remind * 60000), allowWhileIdle: true } });
    }
    for (let i = 0; i < list.length; i += 50) await LocalNotifications.schedule({ notifications: list.slice(i, i + 50) });
  } catch (e) { console.log("alerts", e); }
}
async function setAlerts(on) {
  if (on && nativeOK()) {
    const r = await LocalNotifications.requestPermissions();
    if (r.display !== "granted") { alertsDenied = true; S.notif = false; save(); render(); return; }
    try { const ex = await LocalNotifications.checkExactNotificationSetting(); if (ex.exact_alarm !== "granted") await LocalNotifications.changeExactNotificationSetting(); } catch (e) {}
  } else if (on && typeof Notification !== "undefined") { try { await Notification.requestPermission(); } catch (e) {} }
  alertsDenied = false; S.notif = on; save(); await scheduleAlerts(); render();
}
let alertsDenied = false;
const offs = () => S.off || {};

/* ---------- formatting ---------- */
const tf = tz => new Intl.DateTimeFormat("en-GB", { timeZone: tz, hour: "2-digit", minute: "2-digit", hour12: false });
const clock = (ms, tz) => (ms == null ? "—" : tf(tz).format(new Date(ms)));
const pad = n => String(n).padStart(2, "0");
const cd = ms => { const s = Math.max(0, Math.floor(ms / 1000)); return `${pad(Math.floor(s / 3600))}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`; };

/* ---------- UI pieces ---------- */
const title = (en, arT) => (ar() ? `<div class="ptitle ar">${arT}</div>` : `<div class="ptitle"><span>${en}</span><span class="ar">${arT}</span></div>`);
const badge = c => `<span class="iso">${esc(iso3((c || "--").toUpperCase()))}</span>`;
let prayDay = 0, azkarCat = null, azkarCounts = {}, mosqueAround = null, mosqueState = { loading: false, list: [], failed: false, key: "" };
let pickerOpen = null, pickerQuery = "", pickerRemote = [], sheet = null;
try { azkarCounts = JSON.parse(localStorage.getItem("rafeeq_counts") || "{}"); } catch (e) {}

function placeBtn() {
  return `<button class="pill" data-act="picker">${I.pin}<span class="pn">${esc(S.place.name)}</span>${I.chev}</button>`;
}

/* ----- Qibla tab ----- */
function dialSVG() {
  let ticks = "";
  for (let i = 0; i < 72; i++) {
    const major = i % 6 === 0, r0 = major ? 119 : 120, r1 = major ? 131 : 128, a = i * 5 * Math.PI / 180;
    ticks += `<line x1="${150 + r0 * Math.sin(a)}" y1="${150 - r0 * Math.cos(a)}" x2="${150 + r1 * Math.sin(a)}" y2="${150 - r1 * Math.cos(a)}" stroke="${major ? "#EEF2F8" : "#8E98AE"}" stroke-width="${major ? 2.6 : 1.4}"/>`;
  }
  let labels = "";
  for (let d = 0; d < 360; d += 30) {
    const card = d % 90 === 0, t = d === 0 ? "N" : d === 90 ? "E" : d === 180 ? "S" : d === 270 ? "W" : d + "°";
    labels += `<text transform="rotate(${d} 150 150)" x="150" y="${150 - (card ? 108 : 98)}" text-anchor="middle" dominant-baseline="central" font-size="${card ? 18 : 11}" font-weight="${card ? 800 : 700}" fill="${card ? "#7AD0FF" : "#D0D6E3"}">${t}</text>`;
  }
  return `
  <svg viewBox="-20 -20 340 340" class="dialsvg">
   <defs>
    <linearGradient id="gEdge" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2A3040"/><stop offset="1" stop-color="#12151D"/></linearGradient>
    <linearGradient id="gTop" x1=".25" y1="0" x2=".75" y2="1"><stop offset="0" stop-color="#5A6480"/><stop offset="1" stop-color="#394058"/></linearGradient>
    <radialGradient id="gShadow"><stop offset=".5" stop-color="#000" stop-opacity=".6"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
    <radialGradient id="gCore" cx=".4" cy=".28" r=".8"><stop offset="0" stop-color="#C9EBFF"/><stop offset=".5" stop-color="#55BBFA"/><stop offset="1" stop-color="#1F78BF"/></radialGradient>
    <radialGradient id="gMark" cx=".4" cy=".3" r=".7"><stop offset="0" stop-color="#9FDCFF"/><stop offset=".5" stop-color="#55BBFA"/><stop offset="1" stop-color="#1F78BF"/></radialGradient>
    <linearGradient id="gRay" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#55BBFA" stop-opacity="0"/><stop offset="1" stop-color="#55BBFA"/></linearGradient>
    <radialGradient id="gSun"><stop offset="0" stop-color="#FF9F1C" stop-opacity=".7"/><stop offset="1" stop-color="#FF9F1C" stop-opacity="0"/></radialGradient>
   </defs>
   <ellipse cx="150" cy="170" rx="190" ry="170" fill="url(#gShadow)"/>
   <circle cx="150" cy="168" r="150" fill="url(#gEdge)"/>
   <circle cx="150" cy="150" r="150" fill="url(#gTop)"/>
   <circle cx="150" cy="150" r="149" fill="none" stroke="#fff" stroke-opacity=".2" stroke-width="1.5"/>
   <circle cx="150" cy="150" r="141" fill="none" stroke="#1B1F2B" stroke-opacity=".55" stroke-width="2"/>
   <g id="card" style="transform-origin:150px 150px">
     ${ticks}${labels}
     <circle cx="150" cy="150" r="80" fill="#20242F" stroke="#0E1118" stroke-opacity=".8" stroke-width="3"/>
     <g id="sunlayer"></g>
     <g id="qmark" style="transform-origin:150px 150px">
       <rect x="147.500" y="24" width="5" height="60" rx="2.500" fill="url(#gRay)"/>
       <circle cx="150" cy="28" r="15" fill="#1B3550"/>
       <circle cx="150" cy="24" r="15" fill="url(#gMark)" stroke="#fff" stroke-opacity=".8" stroke-width="1.500"/>
       <g id="kaaba" style="transform-origin:150px 24px"><rect x="143" y="17" width="14" height="14" rx="2" fill="#10151F"/><rect x="143" y="22" width="14" height="2" fill="#FFB627"/></g>
     </g>
   </g>
   <circle cx="150" cy="162" r="52" fill="#16537F"/>
   <circle cx="150" cy="150" r="52" fill="url(#gCore)" stroke="#fff" stroke-opacity=".7" stroke-width="1.500"/>
   <ellipse cx="150" cy="116" rx="30" ry="13" fill="#fff" fill-opacity=".35"/>
   <g transform="translate(0,-17)">
     <polygon points="128,143 150,152 150,176 128,167" fill="#BFE7FF"/><polygon points="172,143 150,152 150,176 172,167" fill="#8FD2FA"/>
     <polygon points="150,134 172,143 150,152 128,143" fill="#E4F6FF"/><polyline points="128,148 150,157 172,148" fill="none" stroke="#FFB627" stroke-width="2.400" stroke-linejoin="round"/>
   </g>
   <polygon points="139,-10 161,-10 150,8" fill="#fff" stroke="#fff" stroke-width="3" stroke-linejoin="round"/>
  </svg>`;
}
function sunLayerSVG(sn) {
  const r = 88, pt = a => [150 + r * Math.sin(a * Math.PI / 180), 150 - r * Math.cos(a * Math.PI / 180)];
  const f = a => a - 360 * Math.floor(a / 360);
  const span = sn.northern ? f(sn.setAz - sn.riseAz) : f(sn.riseAz - sn.setAz), start = sn.northern ? sn.riseAz : sn.setAz;
  const [x0, y0] = pt(start), [x1, y1] = pt(start + span), [sx, sy] = pt(sn.az), [rx, ry] = pt(sn.riseAz), [ex, ey] = pt(sn.setAz);
  return `<path d="M${x0} ${y0} A${r} ${r} 0 ${span > 180 ? 1 : 0} 1 ${x1} ${y1}" fill="none" stroke="#FF9F1C" stroke-width="3" stroke-linecap="round" stroke-dasharray="0.1 7"/>
  <circle cx="${rx}" cy="${ry}" r="4" fill="#FF9F1C"/><circle cx="${ex}" cy="${ey}" r="4" fill="#FF9F1C"/>
  <g opacity="${sn.up ? 1 : 0.4}"><circle cx="${sx}" cy="${sy}" r="28" fill="url(#gSun)"/><circle cx="${sx}" cy="${sy + 4}" r="10" fill="#8A4F00"/><circle cx="${sx}" cy="${sy}" r="10" fill="#FF9F1C" stroke="#FFD08A" stroke-width="2"/></g>`;
}
function target() { return S.preview ? previewDeg : sensor.heading; }
function zoneColor(d) { if (d == null) return "var(--muted)"; const a = Math.abs(d); return a > 45 ? "var(--zr)" : a > 15 ? "var(--zy)" : "var(--zg)"; }
function qibText(d) {
  if (d == null) return [L("Finding the compass"), ar() ? `القبلة ${Math.round(qiblaDeg())}° من الشمال الحقيقي` : `Qibla is ${Math.round(qiblaDeg())}° ${cardinal(qiblaDeg())} of true north`];
  const a = Math.abs(d);
  if (a <= 3) return [L("You're facing the Qibla"), L("Hold steady, then begin your prayer")];
  return [ar() ? `لُف ${d > 0 ? "يمينًا" : "يسارًا"} ${Math.round(a)}°` : `Turn ${d > 0 ? "right" : "left"} ${Math.round(a)}°`,
    L(a <= 15 ? "Almost there, hold steady" : a <= 45 ? "Getting closer, keep turning" : "Rotate until the Kaaba reaches the top")];
}
function updateDial() {
  if (!dialEls) return;
  const t = target(), q = qiblaDeg();
  if (t != null) { shown += diff(t, shown); }
  dialEls.card.style.transform = `rotate(${-shown}deg)`;
  dialEls.kaaba.style.transform = `rotate(${shown - q}deg)`;
  const d = t == null ? null : diff(q, t), aligned = d != null && Math.abs(d) <= 3;
  const [ti, su] = qibText(d), z = zoneColor(d);
  const st = $("#qstatus"); if (st) {
    st.style.setProperty("--z", z);
    $("#qt").textContent = ti; $("#qs").textContent = su;
    $("#qi").innerHTML = aligned ? I.check : (d != null && d < 0 ? I.rotL : I.rot);
  }
  if (aligned && !wasAligned && navigator.vibrate) navigator.vibrate(40);
  wasAligned = aligned;
}
function viewQibla() {
  const p = S.place, q = qiblaDeg(), sn = sunInfo(p.lat, p.lon, new Date());
  const today = dayFor(Date.now(), p.lat, p.lon, p.tz, method(), S.hanafi, offs());
  const km = Math.round(Qibla.distanceKm(p.lat, p.lon));
  let note = "";
  if (!S.preview) {
    if (sensor.denied) note = L("This device has no compass. Turn on preview mode in Settings.");
    else if (needsPerm() && !sensor.listening) note = `<button class="btn" data-act="compass">${ar() ? "تشغيل البوصلة" : "Start the compass"}</button>`;
    else if (!sensor.available) note = L("This device has no compass. Turn on preview mode in Settings.");
    else if (sensor.heading == null) note = L("Starting the compass…");
    else note = ar() ? "يعرض الشمال المغناطيسي. حرّك هاتفك على شكل ٨ للمعايرة." : "Showing magnetic north. Move your phone in a figure of eight to calibrate.";
  }
  const acc = gpsAcc != null ? `±${Math.round(gpsAcc)} ${L("m")}` : (ar() ? "لا يوجد تحديد" : "no fix yet");
  return `${title("Qibla", "القبلة")}
  <div class="row between gap"><div style="flex:1;min-width:0">${placeBtn()}</div>${weatherChip()}</div>
  <div class="srcline"><i class="dot ${net.online ? "on" : ""}"></i>${ar() ? (net.online ? `متصل · GPS ${acc}` : `دون اتصال · GPS والبوصلة · ${acc}`) : (net.online ? `Online · GPS ${acc}` : `Offline · using GPS and compass · ${acc}`)}</div>
  <div class="dialwrap"><div class="dial">${dialSVG()}</div></div>
  <div class="card qcard">
    <div class="status" id="qstatus"><div class="zbtn" id="qi">${I.rot}</div><div class="stxt"><div class="st1" id="qt"></div><div class="st2" id="qs"></div></div></div>
    <div class="tiles">
      ${tile("☀️↑", "Sunrise", clock(today.sunrise, p.tz), (ar() ? "عند " : "at ") + Math.round(sn.riseAz) + "°")}
      ${tile("☀️↓", "Sunset", clock(today.maghrib, p.tz), (ar() ? "عند " : "at ") + Math.round(sn.setAz) + "°")}
      ${tile("↔", "Distance", km.toLocaleString("en-US"), L("km to Makkah"))}
    </div>
  </div>
  ${S.preview ? `<div class="prev"><div class="cap">${L("PREVIEW HEADING")}</div><input type="range" min="0" max="359" step="1" value="${previewDeg}" id="prevSlider"></div>` : `<div class="note">${note}</div>`}`;
}
const tile = (ic, lab, val, unit) => `<div class="tile"><div class="tl"><span>${ic}</span>${L(lab)}</div><div class="tv">${val}</div><div class="tu">${unit}</div></div>`;
function afterQibla() {
  dialEls = { card: $("#card"), kaaba: $("#kaaba"), q: $("#qmark") };
  const p = S.place; $("#sunlayer").innerHTML = sunLayerSVG(sunInfo(p.lat, p.lon, new Date()));
  dialEls.q.style.transform = `rotate(${qiblaDeg()}deg)`;
  const sl = $("#prevSlider"); if (sl) sl.oninput = () => { previewDeg = +sl.value; updateDial(); };
  updateDial();
  if (!S.preview) startCompass();
}

/* ----- Prayer tab ----- */
function viewPrayer() {
  const now = Date.now(), p = S.place;
  const shownMs = now + prayDay * 86400000;
  const day = prayDay === 0 ? prayerEvents(now, p.lat, p.lon, p.tz, method(), S.hanafi, offs()).today : dayFor(shownMs, p.lat, p.lon, p.tz, method(), S.hanafi, offs());
  const greg = new Intl.DateTimeFormat(ar() ? "ar-u-nu-latn" : "en-GB", { timeZone: p.tz, weekday: "long", day: "numeric", month: "long" }).format(new Date(shownMs));
  const hij = new Intl.DateTimeFormat("ar-SA-u-ca-islamic-umalqura-nu-latn", { timeZone: p.tz, day: "numeric", month: "long", year: "numeric" }).format(new Date(shownMs)).replace(/\s*هـ$/, "") + " هـ";
  const rows = PRAYERS.map(k => {
    const muted = S.muted[k];
    return `<div class="prow" id="r-${k}" data-k="${k}">
      <div class="pn1">${pName(k)}</div><div class="pt">${clock(day[k], p.tz)}</div>
      <div class="pn2">${ar() ? "" : pLocal(k)}</div>
      ${k === "sunrise" ? '<span class="bellsp"></span>' : `<button class="bell ${muted ? "off" : ""}" data-act="mute" data-k="${k}" aria-label="mute">${muted ? I.bellOff : I.bell}</button>`}
    </div>`;
  }).join("");
  return `${title("Prayer Times", "مواقيت الصلاة")}
  <div class="row between gap">${placeBtn()}<button class="iconbtn" data-act="refreshGPS" aria-label="GPS">${I.refresh}</button></div>
  <div class="datebar"><button class="iconbtn sm" data-act="day" data-d="-1">${ar() ? I.right : I.left}</button>
    <div class="dates"><b>${greg}</b><span>${hij}</span></div>
    <button class="iconbtn sm" data-act="day" data-d="1">${ar() ? I.left : I.right}</button></div>
  <div class="hero" id="hero"></div>
  <div class="plist">${rows}</div>
  <div class="foot">${ar() ? `تم الحساب على هذا الجهاز · طريقة ${L(method().name)}` : `Calculated on this device · ${method().name} method`}</div>`;
}
function tickPrayer() {
  const hero = $("#hero"); if (!hero) return;
  const p = S.place, now = Date.now();
  const r = prayerEvents(now, p.lat, p.lon, p.tz, method(), S.hanafi, offs());
  const counted = r.all.filter(e => e.prayer !== "sunrise");
  const next = counted.find(e => e.date > now), prev = [...counted].reverse().find(e => e.date <= now);
  if (next) {
    const frac = prev ? Math.min(1, Math.max(0, (now - prev.date) / (next.date - prev.date))) : 0;
    const C = 2 * Math.PI * 64;
    hero.innerHTML = `<div class="ringwrap"><svg viewBox="0 0 150 150"><circle cx="75" cy="75" r="64" fill="none" stroke="var(--tile)" stroke-width="9"/><circle cx="75" cy="75" r="64" fill="none" stroke="var(--accent)" stroke-width="9" stroke-linecap="round" stroke-dasharray="${C * frac} ${C}" transform="rotate(-90 75 75)"/></svg>
      <div class="rtxt"><div class="r1">${ar() ? `${pName(next.prayer)} بعد` : `${pName(next.prayer)} in`}</div><div class="r2">${cd(next.date - now)}</div><div class="r3">${ar() ? "عند" : "at"} ${clock(next.date, p.tz)}</div></div></div>`;
  }
  for (const k of PRAYERS) {
    const el = $("#r-" + k); if (!el) continue;
    const t = r.today[k];
    const isNow = prayDay === 0 && prev && prev.prayer === k && prev.date === t, isNext = prayDay === 0 && next && next.prayer === k && next.date === t;
    el.classList.toggle("now", !!isNow); el.classList.toggle("next", !!isNext);
    el.classList.toggle("past", prayDay === 0 && !isNow && t != null && t < now);
    if (prayDay !== 0) el.classList.remove("now", "next", "past");
  }
}

/* ----- Mosques tab ----- */
function distTxt(m) { return m < 1000 ? `${Math.round(m)} ${L("m")}` : `${(m / 1000).toFixed(1)} ${L("km")}`; }
function viewMosques() {
  const c = mosqueAround || S.place, ms = mosqueState;
  const lab = mosqueAround ? (ar() ? `بالقرب من ${c.name}` : `Near ${c.name}`) : `${L("Near me")} · ${c.name}`;
  let body = "";
  if (!net.online && !ms.list.length) body = notice("📴", "You are offline", "Finding mosques needs internet. Prayer times and Qibla keep working without it.");
  else if (ms.loading && !ms.list.length) body = `<div class="center muted pad">${L("Looking for mosques…")}</div>`;
  else if (ms.failed) body = notice("⚠️", "Couldn’t search", "Check your connection and tap refresh.");
  else if (!ms.list.length) body = notice("📍", "No mosques found nearby", "Try another city from the menu above.");
  else {
    const f = ms.list[0];
    body = `<div class="card sug">${mCard(f, true)}</div><div class="sect">${ar() ? "قريبة" : "Nearby"}</div>` + ms.list.slice(1).map(m => `<div class="card mrow">${mCard(m)}</div>`).join("") +
      `<div class="foot">${ar() ? "المصدر: © مساهمو OpenStreetMap. المسافات بخط مستقيم من موقعك." : "Source: © OpenStreetMap contributors. Distances are straight-line from your position."}</div>`;
  }
  return `${title("Mosques", "المساجد")}
  <div class="row between gap"><button class="pill" data-act="mpicker">${I.pin}<span class="pn">${esc(lab)}</span>${I.chev}</button><button class="iconbtn" data-act="mrefresh">${I.refresh}</button></div>${body}`;
}
const notice = (ic, t, s) => `<div class="notice"><div class="ni">${ic}</div><b>${L(t)}</b><p>${L(s)}</p></div>`;
function mCard(m, big) {
  const g = `https://www.google.com/maps/search/?api=1&query=${m.lat},${m.lon}`, w = `https://waze.com/ul?ll=${m.lat},${m.lon}&navigate=yes`;
  return `<div class="mname">${esc(m.name)}</div>${m.address ? `<div class="muted sm">${esc(m.address)}</div>` : ""}
   <div class="mmeta"><span>${distTxt(m.d)}</span><span>${L("walk")} ${Math.max(1, Math.round(m.d / 80))} ${L("min")}</span></div>
   <div class="mbtns"><a class="btn sm" href="${g}" target="_blank" rel="noopener">${L("Open in Google Maps")}</a><a class="btn sm ghost" href="${w}" target="_blank" rel="noopener">${L("Open in Waze")}</a></div>`;
}
async function loadMosques(force) {
  const c = mosqueAround || S.place, key = c.lat.toFixed(2) + "," + c.lon.toFixed(2);
  if (!force && mosqueState.key === key) return;
  mosqueState = { loading: true, list: mosqueState.key === key ? mosqueState.list : [], failed: false, key };
  try { const cached = JSON.parse(localStorage.getItem("rafeeq_m_" + key) || "null"); if (cached && !mosqueState.list.length) mosqueState.list = cached; } catch (e) {}
  if (S.tab === 2) render();
  if (!net.online) { mosqueState.loading = false; if (S.tab === 2) render(); return; }
  const ql = `[out:json][timeout:10];(node["amenity"="place_of_worship"]["religion"="muslim"](around:3000,${c.lat},${c.lon});way["amenity"="place_of_worship"]["religion"="muslim"](around:3000,${c.lat},${c.lon}););out center tags 60;`;
  let j = null;
  for (const host of ["https://overpass-api.de/api/interpreter", "https://overpass.kumi.systems/api/interpreter"]) {
    try { const r = await fetch(host + "?data=" + encodeURIComponent(ql)); j = await r.json(); if (j && j.elements) break; } catch (e) {}
  }
  if (j && j.elements) {
    const seen = new Set(), out = [];
    for (const e of j.elements) {
      const la = e.lat ?? e.center?.lat, lo = e.lon ?? e.center?.lon; if (la == null) continue;
      const t = e.tags || {}, k = la.toFixed(5) + lo.toFixed(5); if (seen.has(k)) continue; seen.add(k);
      out.push({ name: (ar() ? (t["name:ar"] || t.name) : (t["name:en"] || t.name)) || t["name:ar"] || L("Mosque"), address: [t["addr:street"], t["addr:suburb"] || t["addr:city"]].filter(Boolean).join(", "), lat: la, lon: lo, d: haversine(c.lat, c.lon, la, lo) * 1000 });
    }
    out.sort((a, b) => a.d - b.d); mosqueState.list = out.slice(0, 40);
    try { localStorage.setItem("rafeeq_m_" + key, JSON.stringify(mosqueState.list)); } catch (e) {}
  } else mosqueState.failed = !mosqueState.list.length;
  mosqueState.loading = false; if (S.tab === 2) render();
}

/* ----- Azkhar tab ----- */
function viewAzkhar() {
  if (azkarCat != null) return viewAzkharDetail();
  const cards = CATS.map((c, i) => `<button class="acat" data-act="cat" data-i="${i}"><span class="aci ${i === 2 ? "" : ""}">${["🌅", "🌇", I.dua, "🌙", "✈️"][i]}</span><span class="act">${catTitle(i)}</span>${ar() ? "" : `<span class="ar act2">${CAT_TITLES.ar[i]}</span>`}<small>${DATA.azkar[c].length}</small></button>`).join("");
  return `${title("Azkhar", "الأذكار")}<div class="agrid">${cards}</div><div class="foot">${ar() ? "القرآن: تنزيل · الأذكار: حصن المسلم" : "Quran: Tanzil · Adhkar: Hisn al-Muslim"}</div>`;
}
function transOf(d) { return d.tr[S.lang] || d.tr.en || ""; }
function viewAzkharDetail() {
  const i = azkarCat, items = DATA.azkar[CATS[i]];
  const hint = { ar: "اضغط على البطاقة للعدّ. النصوص مضمّنة وتعمل بدون إنترنت.", tr: "Saymak için karta dokunun. Metinler çevrimdışı çalışır.", fr: "Touchez une carte pour compter. Les textes fonctionnent hors ligne.", it: "Tocca una scheda per contare. I testi funzionano offline.", de: "Karte antippen zum Zählen. Die Texte funktionieren offline.", nl: "Tik op een kaart om te tellen. De teksten werken offline.", es: "Toca una tarjeta para contar. Los textos funcionan sin conexión." }[S.lang] || "Tap a card to count. Texts work offline.";
  const done = { ar: "تم", tr: "Tamam", fr: "Terminé", it: "Fatto", de: "Fertig", nl: "Klaar", es: "Hecho" }[S.lang] || "Done";
  return `<div class="ahead"><button class="iconbtn" data-act="back">${ar() ? I.right : I.left}</button><div class="atitle">${catTitle(i)}</div>${ar() ? "" : `<div class="atitle ar acc">${CAT_TITLES.ar[i]}</div>`}</div>
  ${items.map(d => {
    const n = azkarCounts[d.id] || 0, fin = n >= d.n;
    return `<div class="card dcard ${fin ? "fin" : ""}" data-act="count" data-id="${d.id}" data-n="${d.n}">
      <div class="darb">${esc(d.ar)}</div>
      ${transOf(d) ? `<hr><div class="dtr">${esc(transOf(d))}</div>` : ""}
      <div class="dref">${esc(d.ref)}</div>
      <div class="dfoot"><div class="dbar"><i style="width:${Math.min(100, n / d.n * 100)}%"></i></div><div class="dcnt" id="c-${d.id}">${fin ? done : `${n} / ${d.n}`}</div></div></div>`;
  }).join("")}<div class="foot">${hint}</div><div class="foot">${ar() ? "القرآن: تنزيل · الأذكار: حصن المسلم" : "Quran: Tanzil · Adhkar: Hisn al-Muslim"}</div>`;
}

/* ----- Settings tab ----- */
const sel = (k, opts, cur) => `<select data-k="${k}">${opts.map(([v, t]) => `<option value="${v}" ${String(v) === String(cur) ? "selected" : ""}>${esc(t)}</option>`).join("")}</select>`;
const tog = (k, on) => `<label class="sw"><input type="checkbox" data-k="${k}" ${on ? "checked" : ""}><i></i></label>`;
const srow = (label, ctl, sub) => `<div class="srow"><div class="sl">${label}${sub ? `<small>${sub}</small>` : ""}</div>${ctl}</div>`;
const sect = (t, body, foot) => `<div class="shead">${L(t)}</div><div class="card sbox">${body}</div>${foot ? `<div class="sfoot">${foot}</div>` : ""}`;
function viewSettings() {
  const tsizes = [["1", L("Standard")], ["1.15", L("Large")], ["1.3", L("Larger")], ["1.5", L("Largest")]];
  const asizes = [["1", L("Standard")], ["1.2", L("Large")], ["1.4", L("Larger")], ["1.7", L("Largest")]];
  const sw = PALETTES.map(p => `<button class="sw1 ${p.id === S.palette ? "sel" : ""}" data-act="pal" data-id="${p.id}"><i style="background:${H(p.c.accent[0])}"></i><span>${L(p.title)}</span></button>`).join("");
  const adj = PRAYERS.map(k => `<div class="srow"><div class="sl">${pName(k)}</div><div class="step"><button data-act="adj" data-k="${k}" data-d="-1">−</button><b>${(offs()[k] || 0) > 0 ? "+" : ""}${offs()[k] || 0}</b><button data-act="adj" data-k="${k}" data-d="1">+</button></div></div>`).join("");
  return `${title("Settings", "الإعدادات")}
  ${sect("theme", `<div class="swatches">${sw}</div>` + srow(L("Appearance"), sel("appearance", [["auto", L("Auto")], ["light", L("Light")], ["dark", L("Dark")]], S.appearance)))}
  ${sect("accessibility", srow(L("Text size"), sel("textSize", tsizes, S.textSize)) + srow(L("Azkhar text size"), sel("azkarSize", asizes, S.azkarSize)) + srow(L("Bold text"), tog("bold", S.bold)))}
  ${sect("language", srow(L("Application language"), sel("lang", LANGS, S.lang)))}
  ${sect("prayers", srow(L("Method"), sel("method", METHODS.map(m => [m.id, L(m.name)]), S.method)) + srow(L("Hanafi Asr"), tog("hanafi", S.hanafi)))}
  ${sect("Adjust times", adj, L("Add or subtract minutes to match your local mosque or official timetable."))}
  ${sect("notifications", srow(L("Adhan alerts"), tog("notif", S.notif)) + srow(L("Remind"), sel("remind", [[0, L("Off")], [5, "5 " + L("min")], [10, "10 " + L("min")], [15, "15 " + L("min")], [30, "30 " + L("min")]], S.remind)) + srow(L("Sunrise alert"), tog("sunriseAlert", S.sunriseAlert)),
    (alertsDenied ? (ar() ? "التنبيهات مغلقة لهذا التطبيق في إعدادات الجهاز. " : "Notifications are off for this app in device settings. ") : "") + L("Tap the bell next to a prayer to mute just that prayer.") + (nativeOK() ? "" : (ar() ? " التنبيهات المجدولة تعمل في تطبيق الأندرويد." : " Scheduled alerts work in the Android app.")))}
  ${sect("compass", srow(L("Preview mode (turn dial by hand)"), tog("preview", S.preview)))}
  ${sect("units", srow(L("Temperature"), sel("temp", [["c", L("Celsius (°C)")], ["f", L("Fahrenheit (°F)")]], S.temp)))}
  <div class="shead">${L("About")}</div><div class="card sbox"><div class="srow"><div class="sl">Rafeeq رفيق 1.0</div></div></div>
  <div class="sfoot">${ar() ? "كل الحسابات تتم على هذا الجهاز. تُرسل مدينتك التقريبية فقط عند البحث عن المساجد والطقس." : "Everything is calculated on this device. Only your approximate location is sent when you look up mosques or weather."}</div>`;
}

/* ----- place picker sheet ----- */
function viewPicker() {
  const q = pickerQuery.trim().toLowerCase();
  let list = CITIES;
  if (q) list = CITIES.filter(c => (c.name + " " + c.country + " " + c.iso + " " + iso3(c.iso)).toLowerCase().includes(q));
  list = list.slice(0, 60);
  const remote = pickerRemote.map(c => `<button class="crow" data-act="pick" data-r="${pickerRemote.indexOf(c)}"><span><b>${esc(c.name)}</b><small>${esc(c.country)}</small></span>${badge(c.iso)}</button>`).join("");
  const rows = list.map(c => `<button class="crow" data-act="pick" data-i="${CITIES.indexOf(c)}"><span><b>${esc(c.name)}</b><small>${esc(c.country)}</small></span>${badge(c.iso)}</button>`).join("");
  return `<div class="sheetbg" data-act="closeSheet"></div><div class="sheet"><div class="grab"></div>
   <div class="row between"><b class="shtitle">${pickerOpen === "m" ? L("Find mosques in") : L("City")}</b><button class="iconbtn sm" data-act="closeSheet">✕</button></div>
   <input id="cq" class="search" placeholder="${esc(L("Search city, country or code"))}" value="${esc(pickerQuery)}" autocomplete="off">
   <div class="clist">
    ${pickerOpen === "m" ? `<button class="crow gps" data-act="pickme"><span><b>${L("Near me")}</b><small>${esc(S.place.name)}</small></span>${I.pin}</button>` : `<button class="crow gps" data-act="gps"><span><b>${L("Detect location automatically")}</b><small>${gpsState === "finding" ? L("Finding your location…") : gpsState === "denied" ? (ar() ? "الموقع مغلق لهذا التطبيق. فعّله من الإعدادات أو اختر مدينة." : "Location is off for this app. Turn it on in settings, or choose a city.") : ""}</small></span>${I.pin}</button>`}
    ${rows}${remote ? `<div class="sect">${L("More results")}</div>${remote}` : ""}
    ${!rows && !remote ? `<div class="center muted pad">${net.online ? L("No city found. Try another spelling.") : L("No match offline. Connect to the internet to search more cities.")}</div>` : ""}
   </div></div>`;
}
let searchTimer = null;
function remoteSearch(q) {
  clearTimeout(searchTimer); pickerRemote = [];
  if (q.trim().length < 3 || !net.online) return;
  searchTimer = setTimeout(async () => {
    try {
      const r = await fetch(`https://geocoding-api.open-meteo.com/v1/search?count=8&language=${ar() ? "ar" : "en"}&name=${encodeURIComponent(q.trim())}`);
      const j = await r.json();
      pickerRemote = (j.results || []).map(x => ({ name: x.name, country: [x.admin1, x.country].filter(Boolean).join(", "), lat: x.latitude, lon: x.longitude, tz: x.timezone, iso: (x.country_code || "--").toUpperCase() }));
      if (pickerOpen) { const keep = $("#cq")?.selectionStart; renderSheet(); const el = $("#cq"); if (el) { el.focus(); el.setSelectionRange(keep, keep); } }
    } catch (e) {}
  }, 450);
}
function renderSheet() { const el = $("#sheet"); el.innerHTML = pickerOpen ? viewPicker() : ""; }
function choose(c) {
  if (pickerOpen === "m") { mosqueAround = c; mosqueState.key = ""; pickerOpen = null; renderSheet(); loadMosques(true); return; }
  S.place = { ...c }; S.gps = false; save(); weather = null; pickerOpen = null; renderSheet(); loadWeather(); scheduleAlerts(); render();
}

/* ---------- render & events ---------- */
const TABS = [["Qibla", "qibla"], ["Prayer Times", "clock"], ["Mosques", "mosque"], ["Azkhar", "dua"], ["Settings", "gear"]];
function render() {
  applyTheme();
  const v = $("#view"), st = v.scrollTop;
  v.innerHTML = [viewQibla, viewPrayer, viewMosques, viewAzkhar, viewSettings][S.tab]();
  $("#tabs").innerHTML = TABS.map((t, i) => `<button class="tab ${i === S.tab ? "sel" : ""}" data-act="tab" data-i="${i}">${I[t[1]]}<span>${L(t[0])}</span></button>`).join("");
  if (S.tab === 0) afterQibla(); else dialEls = null;
  if (S.tab === 1) tickPrayer();
  if (S.tab === 2) loadMosques();
  v.scrollTop = st;
}
function vibr() { try { navigator.vibrate && navigator.vibrate(12); } catch (e) {} }
const ACT = {
  tab(el) { S.tab = +el.dataset.i; azkarCat = null; save(); render(); $("#view").scrollTop = 0; },
  picker() { pickerOpen = "p"; pickerQuery = ""; pickerRemote = []; renderSheet(); },
  mpicker() { pickerOpen = "m"; pickerQuery = ""; pickerRemote = []; renderSheet(); },
  closeSheet() { pickerOpen = null; renderSheet(); },
  pick(el) { choose(el.dataset.r != null ? pickerRemote[+el.dataset.r] : CITIES[+el.dataset.i]); },
  pickme() { mosqueAround = null; mosqueState.key = ""; pickerOpen = null; renderSheet(); loadMosques(true); },
  gps() { useGPS().then(() => { if (gpsState === "ok") { pickerOpen = null; renderSheet(); } else renderSheet(); }); renderSheet(); },
  refreshGPS() { useGPS(); },
  mrefresh() { loadMosques(true); },
  compass() { startCompass().then(render); },
  day(el) { prayDay += +el.dataset.d; render(); },
  mute(el) { const k = el.dataset.k; S.muted[k] = !S.muted[k]; save(); scheduleAlerts(); render(); },
  cat(el) { azkarCat = +el.dataset.i; render(); $("#view").scrollTop = 0; },
  back() { azkarCat = null; render(); },
  count(el) {
    const id = el.dataset.id, n = +el.dataset.n, c = azkarCounts[id] || 0; if (c >= n) return;
    azkarCounts[id] = c + 1; vibr(); try { localStorage.setItem("rafeeq_counts", JSON.stringify(azkarCounts)); } catch (e) {}
    const fin = c + 1 >= n, done = { ar: "تم", tr: "Tamam", fr: "Terminé", it: "Fatto", de: "Fertig", nl: "Klaar", es: "Hecho" }[S.lang] || "Done";
    $("#c-" + id).textContent = fin ? done : `${c + 1} / ${n}`; el.querySelector(".dbar i").style.width = Math.min(100, (c + 1) / n * 100) + "%"; el.classList.toggle("fin", fin);
  },
  pal(el) { S.palette = el.dataset.id; save(); render(); },
  adj(el) { const k = el.dataset.k; S.off = { ...offs(), [k]: Math.max(-60, Math.min(60, (offs()[k] || 0) + +el.dataset.d)) }; save(); scheduleAlerts(); render(); },
};
document.addEventListener("click", e => { const el = e.target.closest("[data-act]"); if (el && ACT[el.dataset.act]) { if (el.tagName === "A") return; ACT[el.dataset.act](el); } });
document.addEventListener("change", e => {
  const el = e.target.closest("[data-k]"); if (!el || el.dataset.act) return;
  const k = el.dataset.k; let v = el.type === "checkbox" ? el.checked : el.value;
  if (k === "remind") v = +v;
  if (k === "notif") { setAlerts(v); return; }
  S[k] = v; save();
  if (["lang", "method", "hanafi", "remind", "sunriseAlert"].includes(k)) scheduleAlerts();
  if (k === "lang") { mosqueState.key = ""; weather = weather; }
  render();
});
document.addEventListener("input", e => { if (e.target.id === "cq") { pickerQuery = e.target.value; const pos = e.target.selectionStart; renderSheet(); const el = $("#cq"); el.focus(); el.setSelectionRange(pos, pos); remoteSearch(pickerQuery); } });
// swipe right inside an azkar page goes back to the cards
let sx = null, sy = null;
document.addEventListener("touchstart", e => { sx = e.touches[0].clientX; sy = e.touches[0].clientY; }, { passive: true });
document.addEventListener("touchend", e => {
  if (sx == null || S.tab !== 3 || azkarCat == null) return;
  const dx = e.changedTouches[0].clientX - sx, dy = e.changedTouches[0].clientY - sy; sx = null;
  if (Math.abs(dx) > 80 && Math.abs(dx) > Math.abs(dy) * 1.5 && (ar() ? dx < 0 : dx > 0)) ACT.back();
}, { passive: true });

/* ---------- boot ---------- */
function welcome() {
  const el = $("#sheet");
  el.innerHTML = `<div class="sheetbg"></div><div class="sheet welcome"><img src="icon.png" class="wlogo" alt=""><h1>${ar() ? "رفيق" : "Rafeeq"}</h1>
   <p>${ar() ? "القبلة ومواقيت الصلاة والأذكار في أي مكان — يعمل دون إنترنت." : "Qibla, prayer times and Azkhar, anywhere. Works offline."}</p>
   <ul><li>${ar() ? "بلا حساب ولا تتبع ولا إعلانات" : "No account, no tracking, no ads"}</li><li>${ar() ? "الحسابات تتم على هاتفك" : "Calculated on your phone"}</li></ul>
   <button class="btn big" id="wgps">${L("Allow location while using the app")}</button><button class="btn ghost big" id="wcity">${L("Choose a city instead")}</button></div>`;
  $("#wgps").onclick = () => { S.welcomed = true; save(); el.innerHTML = ""; useGPS(); };
  $("#wcity").onclick = () => { S.welcomed = true; save(); el.innerHTML = ""; pickerOpen = "p"; pickerQuery = ""; renderSheet(); };
}
function boot() {
  render(); loadWeather();
  setInterval(() => { if (S.tab === 1) tickPrayer(); }, 1000);
  setInterval(() => { if (S.tab === 0) { const p = S.place; $("#sunlayer") && ($("#sunlayer").innerHTML = sunLayerSVG(sunInfo(p.lat, p.lon, new Date()))); } }, 60000);
  document.addEventListener("visibilitychange", () => { if (!document.hidden) { scheduleAlerts(); render(); } });
  if (!S.welcomed) welcome(); else { scheduleAlerts(); if (S.gps) useGPS(true); }
  if ("serviceWorker" in navigator && !nativeOK() && location.protocol.startsWith("http")) navigator.serviceWorker.register("sw.js").catch(() => {});
}
boot();
