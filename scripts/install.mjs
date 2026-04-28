#!/usr/bin/env node
import { createInterface } from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import {
  access,
  appendFile,
  cp,
  mkdir,
  readdir,
  readFile,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { constants } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const TEMPLATES = join(ROOT, "templates");
const TIMESTAMP = new Date().toISOString().replace(/[-:]/g, "").replace(/\..+/, "").replace("T", "-");

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;
    const key = arg.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith("--")) {
      args[key] = true;
    } else {
      args[key] = next;
      i += 1;
    }
  }
  return args;
}

async function exists(path) {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

async function ask(rl, question, defaultValue = "") {
  const suffix = defaultValue ? ` [${defaultValue}]` : "";
  const answer = (await rl.question(`${question}${suffix}: `)).trim();
  return answer || defaultValue;
}

async function askRequired(rl, question, defaultValue = "") {
  while (true) {
    const answer = await ask(rl, question, defaultValue);
    if (answer) return answer;
    console.log("Valeur obligatoire.");
  }
}

async function askChoice(rl, question, choices, defaultValue) {
  const label = choices.map((choice) => choice === defaultValue ? `${choice}*` : choice).join("/");
  while (true) {
    const answer = (await rl.question(`${question} (${label}): `)).trim().toLowerCase() || defaultValue;
    if (choices.includes(answer)) return answer;
    console.log(`Choix invalide. Valeurs possibles: ${choices.join(", ")}`);
  }
}

async function ensureParent(path) {
  await mkdir(dirname(path), { recursive: true });
}

async function handleConflict(path, policy) {
  if (!await exists(path)) return "created";
  if (policy === "abort") {
    throw new Error(`Le fichier existe deja: ${path}`);
  }
  if (policy === "overwrite") {
    await rm(path, { recursive: true, force: true });
    return "overwritten";
  }

  const backupPath = `${path}.backup-${TIMESTAMP}`;
  await rename(path, backupPath);
  return `backed up to ${backupPath}`;
}

async function copyFileSafe(source, target, policy, actions) {
  await ensureParent(target);
  const result = await handleConflict(target, policy);
  await cp(source, target, { recursive: false });
  actions.push(`${target} (${result})`);
}

async function copyDirContents(sourceDir, targetDir, policy, actions) {
  await mkdir(targetDir, { recursive: true });
  const entries = await readdir(sourceDir, { withFileTypes: true });
  for (const entry of entries) {
    const source = join(sourceDir, entry.name);
    const target = join(targetDir, entry.name);
    if (entry.isDirectory()) {
      await copyDirContents(source, target, policy, actions);
    } else if (entry.isFile()) {
      await copyFileSafe(source, target, policy, actions);
    }
  }
}

async function copyDirSafe(source, target, policy, actions) {
  await ensureParent(target);
  const result = await handleConflict(target, policy);
  await cp(source, target, { recursive: true });
  actions.push(`${target} (${result})`);
}

async function installCommon(targetRoot, policy, actions) {
  await copyFileSafe(join(TEMPLATES, "backlog.template.md"), join(targetRoot, "backlog.md"), policy, actions);

  const docsRoot = join(targetRoot, "docs");
  await mkdir(docsRoot, { recursive: true });
  const docMap = [
    ["GUIDE-LLM.template.md", "GUIDE-LLM.md"],
    ["EQUIPES-LLM.template.md", "EQUIPES-LLM.md"],
    ["COUTS-LLM.template.md", "COUTS-LLM.md"],
  ];
  for (const [sourceName, targetName] of docMap) {
    await copyFileSafe(join(TEMPLATES, "docs", sourceName), join(docsRoot, targetName), policy, actions);
  }
  await copyDirContents(join(TEMPLATES, "docs", "formats"), join(docsRoot, "formats"), policy, actions);
}

async function installClaude(targetRoot, policy, actions) {
  await copyDirSafe(join(TEMPLATES, "claude"), join(targetRoot, ".claude"), policy, actions);
  const templateSettings = join(targetRoot, ".claude", "settings.template.json");
  const localSettings = join(targetRoot, ".claude", "settings.local.json");
  if (await exists(templateSettings)) {
    await handleConflict(localSettings, policy);
    await rename(templateSettings, localSettings);
    actions.push(`${localSettings} (renamed from settings.template.json)`);
  }
}

async function installCodex(targetRoot, policy, actions) {
  await copyDirSafe(join(TEMPLATES, "codex", ".agents"), join(targetRoot, ".agents"), policy, actions);
  await copyDirSafe(join(TEMPLATES, "codex", ".codex"), join(targetRoot, ".codex"), policy, actions);
  await copyFileSafe(join(TEMPLATES, "codex", "AGENTS.md"), join(targetRoot, "AGENTS.md"), policy, actions);
}

function gitignoreEntries(provider) {
  const entries = [];
  if (provider === "claude" || provider === "both") {
    entries.push(".claude/call-call-tech-lead-runs/");
    entries.push(".claude/call-call-growth-lead-runs/");
    entries.push(".claude/settings.local.json");
  }
  if (provider === "codex" || provider === "both") {
    entries.push(".codex/runs/");
  }
  return entries;
}

async function updateGitignore(targetRoot, provider, actions) {
  const path = join(targetRoot, ".gitignore");
  const entries = gitignoreEntries(provider);
  const current = await exists(path) ? await readFile(path, "utf8") : "";
  const missing = entries.filter((entry) => !current.split(/\r?\n/).includes(entry));
  if (missing.length === 0) return;

  const prefix = current.endsWith("\n") || current.length === 0 ? "" : "\n";
  await appendFile(path, `${prefix}\n# Virtual staff kit\n${missing.join("\n")}\n`);
  actions.push(`${path} (updated)`);
}

function setupPrompt(provider) {
  const commands = [];
  if (provider === "claude" || provider === "both") commands.push("/setup-project --ai");
  if (provider === "codex" || provider === "both") commands.push("$setup-project --ai");
  const commandText = commands.join(" ou ");

  return [
    "# Setup AI-assisted",
    "",
    "Copie ce prompt dans Claude Code ou OpenAI Codex ouvert a la racine de ce projet.",
    provider === "claude" || provider === "both"
      ? "Note Claude Code : si `/setup-project` n'apparait pas, ferme puis rouvre Claude Code a la racine du projet pour recharger `.claude/commands/`."
      : "",
    "",
    "```text",
    `${commandText}`,
    "",
    "Mode attendu :",
    "1. Inspecte le repo avant de poser des questions.",
    "2. Infere la stack, les commandes, les roles, les entites metier, les risques securite/data/IA/growth et les agents utiles.",
    "3. Presente une synthese de configuration.",
    "4. Pose au maximum 3 questions si des informations bloquantes manquent.",
    "5. Remplis les placeholders du kit, supprime/desactive les agents inutiles, laisse des TODO uniquement pour les inconnues non bloquantes.",
    "6. Ecris le rapport final et propose un premier run test en `--depth=lean`.",
    "```",
    "",
  ].join("\n");
}

async function writeAiSetupPrompt(targetRoot, provider, actions) {
  const path = join(targetRoot, "virtual-staff-ai-setup.md");
  await writeFile(path, setupPrompt(provider), "utf8");
  actions.push(`${path} (created)`);
}

async function assertTarget(path) {
  if (!await exists(path)) {
    throw new Error(`Le dossier cible n'existe pas: ${path}`);
  }
  const stats = await stat(path);
  if (!stats.isDirectory()) {
    throw new Error(`La cible n'est pas un dossier: ${path}`);
  }
}

function nextSteps(provider, targetRoot) {
  const lines = [
    "",
    "Installation terminee.",
    "",
    `Projet cible: ${targetRoot}`,
    "",
    "Prochaine etape:",
  ];

  if (provider === "claude" || provider === "both") {
    lines.push("- Ouvre Claude Code a la racine du projet, puis lance `/setup-project --ai`.");
    lines.push("  Si la commande n'apparait pas, ferme puis rouvre Claude Code a la racine du projet pour recharger `.claude/commands/`.");
  }
  if (provider === "codex" || provider === "both") {
    lines.push("- Ouvre Codex a la racine du projet, puis lance `$setup-project --ai`.");
  }
  lines.push("", "Un prompt pret a coller est disponible dans `virtual-staff-ai-setup.md`.");
  if (provider === "claude") {
    lines.push("Ensuite lance un premier run test: `/call-tech-lead \"Petite feature de test\" --depth=lean --mode=semi`.");
  } else if (provider === "codex") {
    lines.push("Ensuite lance un premier run test: `$call-tech-lead \"Petite feature de test\" --depth=lean --mode=semi`.");
  } else {
    lines.push("Ensuite lance un premier run test: `/call-tech-lead \"Petite feature de test\" --depth=lean --mode=semi` ou `$call-tech-lead \"Petite feature de test\" --depth=lean --mode=semi`.");
  }
  return lines.join("\n");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const rl = createInterface({ input, output });

  try {
    console.log("Installation du starter kit d'equipe virtuelle");
    console.log("Reponds a quelques questions, le script s'occupe de la copie et du renommage.\n");

    const defaultTarget = resolve(process.cwd()) === resolve(ROOT) ? "" : process.cwd();
    const targetAnswer = args.target || await askRequired(rl, "Chemin du projet cible", defaultTarget);
    const targetRoot = resolve(targetAnswer);
    await assertTarget(targetRoot);

    const provider = args.provider || await askChoice(rl, "Adapter a installer", ["codex", "claude", "both"], "codex");
    const policy = args.conflicts || await askChoice(rl, "Si un fichier existe deja", ["backup", "abort", "overwrite"], "backup");

    if (!["codex", "claude", "both"].includes(provider)) {
      throw new Error("--provider doit valoir codex, claude ou both");
    }
    if (!["backup", "abort", "overwrite"].includes(policy)) {
      throw new Error("--conflicts doit valoir backup, abort ou overwrite");
    }

    const actions = [];
    await installCommon(targetRoot, policy, actions);
    if (provider === "claude" || provider === "both") await installClaude(targetRoot, policy, actions);
    if (provider === "codex" || provider === "both") await installCodex(targetRoot, policy, actions);
    await updateGitignore(targetRoot, provider, actions);
    await writeAiSetupPrompt(targetRoot, provider, actions);

    const report = [
      "# Virtual Staff Kit — rapport d'installation",
      "",
      `Date: ${new Date().toISOString()}`,
      `Adapter: ${provider}`,
      `Politique conflits: ${policy}`,
      "",
      "## Actions",
      ...actions.map((action) => `- ${action}`),
      "",
    ].join("\n");
    await writeFile(join(targetRoot, "virtual-staff-install-report.md"), report, "utf8");

    console.log(nextSteps(provider, targetRoot));
    console.log(`\nRapport: ${join(targetRoot, "virtual-staff-install-report.md")}`);
  } finally {
    rl.close();
  }
}

main().catch((error) => {
  console.error(`\nErreur: ${error.message}`);
  process.exit(1);
});
