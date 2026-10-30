// Ported 1:1 from the iOS app (SunMath, QiblaMath, PrayerCalculator)
const rad = d => d * Math.PI / 180, deg = r => r * 180 / Math.PI;
const fix = (a, b) => { const v = a - b * Math.floor(a / b); return v < 0 ? v + b : v; };

export const Qibla = {
  kaaba: { lat: 21.422487, lon: 39.826206 },
  bearing(lat, lon) {
    const p1 = rad(lat), p2 = rad(this.kaaba.lat), dl = rad(this.kaaba.lon - lon);
    const y = Math.sin(dl) * Math.cos(p2);
    const x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl);
    return norm(deg(Math.atan2(y, x)));
  },
  distanceKm(lat, lon) { return haversine(lat, lon, this.kaaba.lat, this.kaaba.lon); },
};
export function haversine(la1, lo1, la2, lo2) {
  const dp = rad(la2 - la1), dl = rad(lo2 - lo1);
  const a = Math.sin(dp / 2) ** 2 + Math.cos(rad(la1)) * Math.cos(rad(la2)) * Math.sin(dl / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(a));
}
export const norm = d => { let v = d % 360; if (v < 0) v += 360; return v; };
export const diff = (a, b) => { const d = (a - b + 540) % 360; return (d < 0 ? d + 360 : d) - 180; };
const PTS = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];
export const cardinal = d => PTS[Math.round(norm(d) / 22.5) % 16];

export function sunInfo(lat, lon, date) {
  const jd = date.getTime() / 86400000 + 2440587.5, d = jd - 2451545.0;
  const g = fix(357.529 + 0.98560028 * d, 360), q = fix(280.459 + 0.98564736 * d, 360);
  const l = fix(q + 1.915 * Math.sin(rad(g)) + 0.020 * Math.sin(rad(2 * g)), 360);
  const e = 23.439 - 0.00000036 * d;
  const ra = fix(deg(Math.atan2(Math.cos(rad(e)) * Math.sin(rad(l)), Math.cos(rad(l)))) / 15, 24);
  const dec = deg(Math.asin(Math.sin(rad(e)) * Math.sin(rad(l))));
  const eqt = q / 15 - ra;
  const ut = fix(date.getTime() / 1000, 86400) / 3600;
  const h = fix(15 * (ut + lon / 15 - 12 + eqt), 360);
  const az = fix(deg(Math.atan2(Math.sin(rad(h)), Math.cos(rad(h)) * Math.sin(rad(lat)) - Math.tan(rad(dec)) * Math.cos(rad(lat)))) + 180, 360);
  const alt = deg(Math.asin(Math.sin(rad(lat)) * Math.sin(rad(dec)) + Math.cos(rad(lat)) * Math.cos(rad(dec)) * Math.cos(rad(h))));
  const x = Math.max(-1, Math.min(1, Math.sin(rad(dec)) / Math.max(0.0001, Math.cos(rad(lat)))));
  const rise = deg(Math.acos(x));
  return { az, alt, riseAz: rise, setAz: 360 - rise, northern: lat >= 0, up: alt > 0 };
}

export const METHODS = [
  { id: "kuwait", name: "Kuwait", fajr: 18, isha: 17.5, ishaMin: 0 },
  { id: "mwl", name: "Muslim World League", fajr: 18, isha: 17, ishaMin: 0 },
  { id: "egypt", name: "Egyptian General Authority", fajr: 19.5, isha: 17.5, ishaMin: 0 },
  { id: "karachi", name: "Karachi (UIS)", fajr: 18, isha: 18, ishaMin: 0 },
  { id: "isna", name: "ISNA (North America)", fajr: 15, isha: 15, ishaMin: 0 },
  { id: "ummalqura", name: "Umm al-Qura (Makkah)", fajr: 18.5, isha: 0, ishaMin: 90 },
];
export const PRAYERS = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"];

function julian(y, m, d) {
  if (m <= 2) { y -= 1; m += 12; }
  const a = Math.floor(y / 100), b = 2 - a + Math.floor(a / 4);
  return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + d + b - 1524.5;
}
function sun(jd) {
  const d = jd - 2451545.0;
  const g = fix(357.529 + 0.98560028 * d, 360), q = fix(280.459 + 0.98564736 * d, 360);
  const l = fix(q + 1.915 * Math.sin(rad(g)) + 0.020 * Math.sin(rad(2 * g)), 360);
  const e = 23.439 - 0.00000036 * d;
  const ra = fix(deg(Math.atan2(Math.cos(rad(e)) * Math.sin(rad(l)), Math.cos(rad(l)))) / 15, 24);
  return { decl: deg(Math.asin(Math.sin(rad(e)) * Math.sin(rad(l)))), eqt: q / 15 - ra };
}

export function prayerDay(year, month, day, lat, lon, method, hanafi, offsets = {}) {
  const jd = julian(year, month, day) - lon / (15 * 24);
  const midDay = t => fix(12 - sun(jd + t).eqt, 24);
  const angle = (a, t, ccw) => {
    const dec = sun(jd + t).decl;
    const x = (-Math.sin(rad(a)) - Math.sin(rad(dec)) * Math.sin(rad(lat))) / (Math.cos(rad(dec)) * Math.cos(rad(lat)));
    const tt = deg(Math.acos(x)) / 15;
    return midDay(t) + (ccw ? -tt : tt);
  };
  const asr = (f, t) => {
    const dec = sun(jd + t).decl;
    return angle(-deg(Math.atan(1 / (f + Math.tan(rad(Math.abs(lat - dec)))))), t, false);
  };
  let fajr = 5, sunrise = 6, dhuhr = 12, asrT = 13, sunset = 18, isha = 18;
  for (let i = 0; i < 2; i++) {
    fajr = angle(method.fajr, fajr / 24, true);
    sunrise = angle(0.833, sunrise / 24, true);
    dhuhr = midDay(dhuhr / 24);
    asrT = asr(hanafi ? 2 : 1, asrT / 24);
    sunset = angle(0.833, sunset / 24, false);
    isha = angle(method.isha, isha / 24, false);
  }
  if (!isNaN(sunrise) && !isNaN(sunset)) {
    const night = fix(sunrise - sunset, 24);
    if (method.fajr > 0) {
      const portion = method.fajr / 60 * night;
      if (isNaN(fajr) || fix(sunrise - fajr, 24) > portion) fajr = sunrise - portion;
    }
    if (method.isha > 0) {
      const portion = method.isha / 60 * night;
      if (isNaN(isha) || fix(isha - sunset, 24) > portion) isha = sunset + portion;
    }
  }
  if (method.ishaMin > 0) isha = sunset + method.ishaMin / 60;
  const base = Date.UTC(year, month - 1, day), off = lon / 15;
  const mk = h => (isNaN(h) || !isFinite(h)) ? null : base + (h - off) * 3600000;
  const out = {};
  const pairs = { fajr, sunrise, dhuhr, asr: asrT, maghrib: sunset, isha };
  for (const k of PRAYERS) { const t = mk(pairs[k]); if (t != null) out[k] = t + (offsets[k] || 0) * 60000; }
  return out;
}

export function ymdIn(tz, ms) {
  const p = new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(new Date(ms));
  const g = t => +p.find(x => x.type === t).value;
  return { y: g("year"), m: g("month"), d: g("day") };
}

// yesterday, today, tomorrow in the place's time zone
export function prayerEvents(now, lat, lon, tz, method, hanafi, offsets, span = 1) {
  const c = ymdIn(tz, now);
  let today = {}; const all = [];
  for (let k = -1; k <= span; k++) {
    const u = new Date(Date.UTC(c.y, c.m - 1, c.d + k));
    const t = prayerDay(u.getUTCFullYear(), u.getUTCMonth() + 1, u.getUTCDate(), lat, lon, method, hanafi, offsets);
    if (k === 0) today = t;
    for (const p of PRAYERS) if (t[p] != null) all.push({ prayer: p, date: t[p] });
  }
  all.sort((a, b) => a.date - b.date);
  return { today, all };
}
export function dayFor(ms, lat, lon, tz, method, hanafi, offsets) {
  const c = ymdIn(tz, ms);
  return prayerDay(c.y, c.m, c.d, lat, lon, method, hanafi, offsets);
}
