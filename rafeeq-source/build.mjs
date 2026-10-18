import { build } from "esbuild";
import fs from "fs";
fs.rmSync("www", { recursive: true, force: true }); fs.mkdirSync("www", { recursive: true });
await build({ entryPoints: ["src/main.js"], bundle: true, minify: true, outfile: "www/app.js", format: "iife", target: "chrome80", loader: { ".json": "json" } });
for (const f of ["index.html", "style.css", "manifest.webmanifest", "sw.js", "dua.png", "privacy.html"]) fs.copyFileSync("src/" + f, "www/" + f);
fs.copyFileSync("assets/icon.png", "www/icon.png");
console.log("built");
