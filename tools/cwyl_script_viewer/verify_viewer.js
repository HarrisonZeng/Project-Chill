const fs = require("fs");
const path = require("path");
const vm = require("vm");

const viewerDir = __dirname;
const root = path.resolve(viewerDir, "..", "..");
const dataDir = path.join(root, "tmp", "cwyl_extract", "clean");
const liveHtmlPath = path.join(viewerDir, "cwyl_script_viewer.html");
const stableHtmlPath = path.join(viewerDir, "cwyl_script_viewer_stable.html");

const raw = {
  scenarios: JSON.parse(fs.readFileSync(path.join(dataDir, "scenario_readable.json"), "utf8")),
  localization: JSON.parse(fs.readFileSync(path.join(dataDir, "LocalizationMaster.json"), "utf8")),
  groups: JSON.parse(fs.readFileSync(path.join(dataDir, "ScenarioGroupMaster.json"), "utf8"))
};

function extractScripts(html) {
  const scripts = [];
  const scriptRegex = /<script([^>]*)>([\s\S]*?)<\/script>/g;
  let match;
  while ((match = scriptRegex.exec(html))) {
    if (!match[1].includes("application/json")) {
      scripts.push(match[2]);
    }
  }
  return scripts;
}

function extractEmbeddedJson(html) {
  const match = html.match(/<script id="embedded-data" type="application\/json">([\s\S]*?)<\/script>/);
  return match ? match[1] : "";
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function reactionFamily(id) {
  const match = String(id).match(/^(.*_reaction_[^_]+)(?:_\d+)?$/);
  return match ? match[1] : String(id);
}

function isReactionId(id) {
  return /_reaction(?:_|$)/.test(String(id));
}

function inspectData(data) {
  const locById = new Map(data.localization.Items.map((item) => [item.ID, item]));
  const groupById = new Map(data.groups.Items.map((item) => [item.ID, item]));
  const stats = {
    groups: data.scenarios.length,
    textLines: 0,
    zhLines: 0,
    choiceGroups: 0,
    playerChoices: 0,
    responseLines: 0,
    missingMetadata: 0,
    choicesWithoutResponse: []
  };

  for (const group of data.scenarios) {
    if (!groupById.has(group.group_id)) {
      stats.missingMetadata += 1;
    }

    const commands = group.commands.map((command) => {
      const loc = locById.get(command.localization_id) || locById.get(command.id) || {};
      const id = String(command.id || "");
      const en = String(loc.En || command.en || "").trim();
      const zh = String(loc.ZhHans || "").trim();
      return { ...command, id, en, zh };
    });

    let localChoices = 0;
    for (const command of commands) {
      if (command.en) stats.textLines += 1;
      if (command.zh) stats.zhLines += 1;
      if (isReactionId(command.id) && command.en) stats.responseLines += 1;

      if (command.id.includes("_selection_")) {
        localChoices += 1;
        stats.playerChoices += 1;
        const families = new Set([
          reactionFamily(String(command.arg1 || "")),
          reactionFamily(command.id.replace(/_selection_([^_]+)/, "_reaction_$1"))
        ]);
        const linkedResponses = commands.filter((candidate) => {
          if (!candidate.en || !isReactionId(candidate.id)) return false;
          return Array.from(families).some((family) => candidate.id === family || candidate.id.startsWith(`${family}_`));
        });
        if (!linkedResponses.length) {
          stats.choicesWithoutResponse.push(`${group.group_id}:${command.id}`);
        }
      }
    }
    if (localChoices) stats.choiceGroups += 1;
  }
  return stats;
}

for (const filePath of [liveHtmlPath, stableHtmlPath]) {
  const html = fs.readFileSync(filePath, "utf8");
  const scripts = extractScripts(html);
  assert(scripts.length === 1, `${path.basename(filePath)} should have one executable script tag.`);
  for (const script of scripts) {
    new vm.Script(script);
  }
}

const liveEmbedded = extractEmbeddedJson(fs.readFileSync(liveHtmlPath, "utf8"));
const stableEmbedded = extractEmbeddedJson(fs.readFileSync(stableHtmlPath, "utf8"));
assert(liveEmbedded.trim() === "", "Live viewer should not embed frozen data.");
assert(stableEmbedded.length > 100000, "Stable viewer should embed the script dataset.");

const stableRaw = JSON.parse(stableEmbedded);
const sourceStats = inspectData(raw);
const stableStats = inspectData(stableRaw);

assert(JSON.stringify(sourceStats) === JSON.stringify(stableStats), "Stable embedded data does not match source data stats.");
assert(sourceStats.groups === 501, "Expected 501 scenario groups.");
assert(sourceStats.textLines === 1317, "Expected 1317 localized English text lines.");
assert(sourceStats.zhLines === 1317, "Expected 1317 Simplified Chinese text lines.");
assert(sourceStats.choiceGroups === 24, "Expected 24 choice groups.");
assert(sourceStats.playerChoices === 74, "Expected 74 player choices.");
assert(sourceStats.missingMetadata === 0, "Every scenario should have ScenarioGroupMaster metadata.");

const knownEmptyDemoChoices = new Set([
  "gamedemo_scenario_001:gamedemo_scenario_01_002_selection_1",
  "gamedemo_scenario_001:gamedemo_scenario_01_002_selection_2"
]);
const unexpectedMissing = sourceStats.choicesWithoutResponse.filter((id) => !knownEmptyDemoChoices.has(id));
assert(unexpectedMissing.length === 0, `Unexpected choices without linked response: ${unexpectedMissing.join(", ")}`);

console.log(JSON.stringify({
  status: "ok",
  stableHtml: stableHtmlPath,
  bytes: fs.statSync(stableHtmlPath).size,
  ...sourceStats,
  knownEmptyDemoChoices: sourceStats.choicesWithoutResponse
}, null, 2));
