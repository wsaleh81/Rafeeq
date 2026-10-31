// Compass dials ported from the iOS app: themed Classic (3D slate disc + Islamic arrow) and Rings.
const hex = c => [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)];
export const mix = (a, b, t) => { const x = hex(a), y = hex(b); return "#" + x.map((v, i) => Math.round(v + (y[i] - v) * t).toString(16).padStart(2, "0")).join(""); };
const sin = d => Math.sin(d * Math.PI / 180), cos = d => Math.cos(d * Math.PI / 180);

function look(T, themed) {
  if (!themed) return { faceTop: "#5A6480", faceBottom: "#394058", thickTop: "#2A3040", thickBottom: "#12151D", inner: "#20242F", ink: "#EEF2F8", muted: "#8E98AE", cardinal: "#7AD0FF", degree: "#D0D6E3", accent: "#55BBFA", accentLight: "#C9EBFF", accentDark: "#1F78BF" };
  const a = T.accent;
  return { faceTop: mix(T.tile, "#ffffff", 0.14), faceBottom: T.card, thickTop: T.line, thickBottom: mix(T.line, "#000000", 0.55), inner: T.night, ink: T.ink, muted: T.muted, cardinal: a, degree: T.muted, accent: a, accentLight: mix(a, "#ffffff", 0.6), accentDark: mix(a, "#000000", 0.5) };
}

function arrowSVG(w, h, dark, light, glow) {
  const X = p => (p / 100 * w - w / 2).toFixed(2), HY = p => (-h / 2 + p / 100 * h * 0.5).toFixed(2), TY = p => (p / 100 * h * 0.5).toFixed(2);
  const star = []; const sr = w * 0.31;
  for (let i = 0; i < 16; i++) { const r = i % 2 === 0 ? sr : sr * 0.62, a = i * Math.PI / 8 - Math.PI / 2; star.push((r * Math.cos(a)).toFixed(2) + "," + (r * Math.sin(a)).toFixed(2)); }
  return `<g class="iarrow"><g class="ia-glow" style="--glow:${glow}">
    <polygon class="ia-tail" points="${X(50)},${TY(100)} ${X(76)},${TY(62)} ${X(50)},${TY(70)} ${X(24)},${TY(62)}" fill="${dark}" fill-opacity=".55"/>
    <rect class="ia-shaft" x="${-w * 0.06}" y="${-h * 0.35}" width="${w * 0.12}" height="${h * 0.7}" rx="${w * 0.06}" fill="${dark}"/>
    <polygon class="ia-head" points="${X(50)},${HY(0)} ${X(78)},${HY(46)} ${X(50)},${HY(36)} ${X(22)},${HY(46)}" fill="${dark}" stroke="${light}" stroke-opacity=".7" stroke-width="1"/>
    <polygon class="ia-star" points="${star.join(" ")}" fill="${light}" stroke="${dark}" stroke-width="1"/></g></g>`;
}

// Rings dial centre: a mihrab (prayer niche) arch; its top points to the Qibla. Gold, green when aligned.
function mihrabSVG(c) {
  return `<g class="mihrab"><g class="ia-glow">
    <path class="mh-in" d="M-7.5,22 L-7.5,0 Q-7.5,-9 0,-16 Q7.5,-9 7.5,0 L7.5,22" fill="${c}" fill-opacity=".4"/>
    <path class="mh-arch" d="M-15,22 L-15,-5 Q-15,-20 0,-32 Q15,-20 15,-5 L15,22 Z" fill="none" stroke="${c}" stroke-width="3" stroke-linejoin="round"/></g></g>`;
}

export function classicSVG(T, themed) {
  const L = look(T, themed);
  let ticks = "";
  for (let i = 0; i < 72; i++) {
    const major = i % 6 === 0, r0 = major ? 108 : 115, r1 = major ? 131 : 128, a = i * 5;
    ticks += `<line x1="${150 + r0 * sin(a)}" y1="${150 - r0 * cos(a)}" x2="${150 + r1 * sin(a)}" y2="${150 - r1 * cos(a)}" stroke="${major ? L.ink : L.muted}" stroke-width="${major ? 3.2 : 1.6}"/>`;
  }
  let labels = "";
  for (let d = 0; d < 360; d += 30) {
    const c = d % 90 === 0, t = d === 0 ? "N" : d === 90 ? "E" : d === 180 ? "S" : d === 270 ? "W" : d + "°";
    labels += `<text transform="rotate(${d} 150 150)" x="150" y="${150 - (c ? 92 : 88)}" text-anchor="middle" dominant-baseline="central" font-size="${c ? 25 : 14}" font-weight="${c ? 800 : 700}" fill="${c ? L.cardinal : L.degree}">${t}</text>`;
  }
  return `<svg viewBox="-20 -20 340 340" class="dialsvg" data-style="classic">
   <defs>
    <linearGradient id="gEdge" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${L.thickTop}"/><stop offset="1" stop-color="${L.thickBottom}"/></linearGradient>
    <linearGradient id="gTop" x1=".25" y1="0" x2=".75" y2="1"><stop offset="0" stop-color="${L.faceTop}"/><stop offset="1" stop-color="${L.faceBottom}"/></linearGradient>
    <radialGradient id="gShadow"><stop offset=".48" stop-color="#000" stop-opacity=".6"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
    <radialGradient id="gCore" cx=".4" cy=".28" r=".8"><stop offset="0" stop-color="${L.accentLight}"/><stop offset=".5" stop-color="${L.accent}"/><stop offset="1" stop-color="${L.accentDark}"/></radialGradient>
    <radialGradient id="gMark" cx=".4" cy=".3" r=".7"><stop offset="0" stop-color="${L.accentLight}"/><stop offset=".5" stop-color="${L.accent}"/><stop offset="1" stop-color="${L.accentDark}"/></radialGradient>
    <linearGradient id="gRay" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="${L.accent}" stop-opacity="0"/><stop offset="1" stop-color="${L.accent}"/></linearGradient>
    <radialGradient id="gSun"><stop offset="0" stop-color="#FF9F1C" stop-opacity=".7"/><stop offset="1" stop-color="#FF9F1C" stop-opacity="0"/></radialGradient>
   </defs>
   <ellipse cx="150" cy="189" rx="190" ry="170" fill="url(#gShadow)"/>
   <circle cx="150" cy="168" r="150" fill="url(#gEdge)"/>
   <circle cx="150" cy="150" r="150" fill="url(#gTop)"/>
   <circle cx="150" cy="150" r="149" fill="none" stroke="#fff" stroke-opacity=".2" stroke-width="1.5"/>
   <circle cx="150" cy="150" r="141" fill="none" stroke="#1B1F2B" stroke-opacity=".55" stroke-width="2"/>
   <g id="dcard">
     ${ticks}${labels}
     <circle cx="150" cy="150" r="58" fill="${L.inner}" stroke="#0E1118" stroke-opacity=".8" stroke-width="3"/>
     <g id="sunlayer"></g>
     <g id="qmark" transform="rotate(0 150 150)">
       <rect x="147.5" y="40" width="5" height="60" rx="2.5" fill="url(#gRay)"/>
       <circle cx="150" cy="28" r="15" fill="${L.inner}"/>
       <circle cx="150" cy="24" r="15" fill="url(#gMark)" stroke="#fff" stroke-opacity=".8" stroke-width="1.5"/>
       <g id="kaaba"><rect x="143" y="17" width="14" height="14" rx="2" fill="#10151F"/><rect x="143" y="22" width="14" height="2" fill="#FFB627"/></g>
     </g>
   </g>
   <!-- centre: the same circles as the Rings dial, with the mihrab arch pointing to the Qibla -->
   <circle cx="150" cy="150" r="50" fill="${T.accent}" fill-opacity=".55"/>
   <circle cx="150" cy="150" r="31" fill="${T.night}"/>
   <g id="darrow" transform="translate(150 150)"><g transform="scale(.78)">${mihrabSVG(T.accent)}</g></g>
   <polygon id="dtri" points="139,-10 161,-10 150,8" fill="${T.accent}" stroke="${T.accent}" stroke-width="3" stroke-linejoin="round"/>
  </svg>`;
}

export function ringsSVG(T) {
  return `<svg viewBox="-20 -20 340 340" class="dialsvg" data-style="rings">
   <defs><filter id="rsh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="10" stdDeviation="9" flood-color="#000" flood-opacity=".25"/></filter></defs>
   <circle cx="150" cy="150" r="150" fill="${T.tint}" filter="url(#rsh)"/>
   <circle cx="150" cy="150" r="106.5" fill="${T.accent}" fill-opacity=".28"/>
   <circle cx="150" cy="150" r="68.25" fill="${T.accent}" fill-opacity=".55"/>
   <circle cx="150" cy="150" r="41.25" fill="${T.night}"/>
   <g id="rarrow" transform="translate(150 150)">${mihrabSVG(T.accent)}</g>
   <g id="rmark" transform="translate(150 34.5)">
     <circle id="rring" r="19.5" fill="${T.accent}" stroke="transparent" stroke-width="3"/>
     <rect x="-6.75" y="-7.5" width="13.5" height="15" rx="2" fill="${T.night}"/><rect x="-6.75" y="-4.5" width="13.5" height="2" fill="${T.sun}"/>
   </g>
   <polygon id="rtri" points="-9,0 9,0 0,15" transform="translate(150 -3)" fill="${T.accent}"/>
  </svg>`;
}

const set = (el, a, v) => el && el.setAttribute(a, v);
// shown = smoothed heading, q = Qibla bearing, aligned = facing the Qibla, tint = arrow colour for Rings (zone)
export function updateDial(root, T, shown, q, aligned, tint) {
  if (!root) return;
  const svg = root.querySelector("svg"); if (!svg) return;
  const g = id => svg.querySelector("#" + id);
  const toQ = q - shown;
  if (svg.dataset.style === "classic") {
    set(g("dcard"), "transform", `rotate(${-shown} 150 150)`);
    set(g("qmark"), "transform", `rotate(${q} 150 150)`);
    set(g("kaaba"), "transform", `rotate(${shown - q} 150 24)`);
    set(g("darrow"), "transform", `translate(150 150) rotate(${toQ})`);
    const mc = aligned ? T.ok : T.accent;
    set(svg.querySelector("#darrow .mh-arch"), "stroke", mc);
    set(svg.querySelector("#darrow .mh-in"), "fill", mc);
    svg.classList.toggle("aligned", !!aligned);
    const tri = g("dtri"); set(tri, "fill", aligned ? T.ok : T.accent); set(tri, "stroke", aligned ? T.ok : T.accent);
  } else {
    set(g("rarrow"), "transform", `translate(150 150) rotate(${toQ})`);
    // the mihrab arch stays in the theme accent (gold) and turns green and glows when facing the Qibla
    const c = aligned ? T.ok : T.accent;
    set(svg.querySelector("#rarrow .mh-arch"), "stroke", c);
    set(svg.querySelector("#rarrow .mh-in"), "fill", c);
    svg.classList.toggle("aligned", !!aligned);
    set(g("rmark"), "transform", `translate(${150 + 115.5 * sin(toQ)} ${150 - 115.5 * cos(toQ)})`);
    set(g("rring"), "stroke", aligned ? T.ok : "transparent");
    set(g("rtri"), "fill", aligned ? T.ok : T.accent);
  }
}

// sun path for today (radius 70 on the rotating card)
export function sunLayerSVG(sn) {
  const r = 70, pt = a => [150 + r * sin(a), 150 - r * cos(a)];
  const f = a => a - 360 * Math.floor(a / 360);
  const span = sn.northern ? f(sn.setAz - sn.riseAz) : f(sn.riseAz - sn.setAz), start = sn.northern ? sn.riseAz : sn.setAz;
  const [x0, y0] = pt(start), [x1, y1] = pt(start + span), [sx, sy] = pt(sn.az), [rx, ry] = pt(sn.riseAz), [ex, ey] = pt(sn.setAz);
  return `<path d="M${x0} ${y0} A${r} ${r} 0 ${span > 180 ? 1 : 0} 1 ${x1} ${y1}" fill="none" stroke="#FF9F1C" stroke-width="3" stroke-linecap="round" stroke-dasharray="0.1 7"/>
  <circle cx="${rx}" cy="${ry}" r="4" fill="#FF9F1C"/><circle cx="${ex}" cy="${ey}" r="4" fill="#FF9F1C"/>
  <g opacity="${sn.up ? 1 : 0.4}"><circle cx="${sx}" cy="${sy}" r="28" fill="url(#gSun)"/><circle cx="${sx}" cy="${sy + 4}" r="10" fill="#8A4F00"/><circle cx="${sx}" cy="${sy}" r="10" fill="#FF9F1C" stroke="#FFD08A" stroke-width="2"/></g>`;
}
