import { build } from "esbuild";
import fs from "fs";
fs.rmSync("www", { recursive: true, force: true }); fs.mkdirSync("www", { recursive: true });
await build({ entryPoints: ["src/main.js"], bundle: true, minify: true, outfile: "www/app.js", format: "iife", target: "chrome80", loader: { ".json": "json" }, define: { __BUILD__: JSON.stringify(process.env.VERSION_CODE || "") } });
for (const f of ["index.html", "style.css", "manifest.webmanifest", "sw.js", "dua.png", "privacy.html"]) fs.copyFileSync("src/" + f, "www/" + f);
fs.copyFileSync("assets/icon.png", "www/icon.png");
if (fs.existsSync("android/app/src/main/res/raw/adhan.wav")) fs.copyFileSync("android/app/src/main/res/raw/adhan.wav", "www/adhan.wav");   // "Adhan sound" preview in Settings
for (const d of ["mushaf", "fonts"]) if (fs.existsSync("assets/" + d)) fs.cpSync("assets/" + d, "www/" + d, { recursive: true });
console.log("built");
