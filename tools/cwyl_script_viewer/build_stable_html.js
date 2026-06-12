const fs = require("fs");
const path = require("path");

const viewerDir = __dirname;
const root = path.resolve(viewerDir, "..", "..");
const sourceHtmlPath = path.join(viewerDir, "cwyl_script_viewer.html");
const outputHtmlPath = path.join(viewerDir, "cwyl_script_viewer_stable.html");
const dataDir = path.join(root, "tmp", "cwyl_extract", "clean");

const raw = {
  scenarios: JSON.parse(fs.readFileSync(path.join(dataDir, "scenario_readable.json"), "utf8")),
  localization: JSON.parse(fs.readFileSync(path.join(dataDir, "LocalizationMaster.json"), "utf8")),
  groups: JSON.parse(fs.readFileSync(path.join(dataDir, "ScenarioGroupMaster.json"), "utf8"))
};

const html = fs.readFileSync(sourceHtmlPath, "utf8");
const embeddedJson = JSON.stringify(raw)
  .replace(/</g, "\\u003c")
  .replace(/\u2028/g, "\\u2028")
  .replace(/\u2029/g, "\\u2029");

const stableHtml = html.replace(
  /<script id="embedded-data" type="application\/json">[\s\S]*?<\/script>/,
  `<script id="embedded-data" type="application/json">${embeddedJson}</script>`
);

if (stableHtml === html) {
  throw new Error("Could not find embedded-data script tag in source HTML.");
}

fs.writeFileSync(outputHtmlPath, stableHtml, "utf8");

const textLineCount = raw.scenarios.reduce((total, group) => {
  return total + group.commands.filter((command) => String(command.en || "").trim()).length;
}, 0);

const playerChoiceCount = raw.scenarios.reduce((total, group) => {
  return total + group.commands.filter((command) => String(command.id || "").includes("_selection_")).length;
}, 0);

console.log(`Wrote ${outputHtmlPath}`);
console.log(`Embedded ${raw.scenarios.length} groups, ${textLineCount} text rows, ${playerChoiceCount} player choices.`);
