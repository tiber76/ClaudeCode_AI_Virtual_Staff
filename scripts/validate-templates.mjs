#!/usr/bin/env node
import { access, readdir, readFile, stat } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import { constants } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const PKG = JSON.parse(await readFile(join(ROOT, "package.json"), "utf8"));
const KIT_VERSION = PKG.version;
const failures = [];

async function exists(path) {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}
const expectedCodexModels = {
  "full-stack-lead.toml": ["gpt-5.3-codex", "high"],
  "cso.toml": ["gpt-5.3-codex", "high"],
  "qa.toml": ["gpt-5.3-codex", "medium"],
  "data-engineer.toml": ["gpt-5.3-codex", "medium"],
  "ai-llm-engineer.toml": ["gpt-5.3-codex", "medium"],
  "growth-lead.toml": ["gpt-5.5", "high"],
  "sales-b2b.toml": ["gpt-5.5", "high"],
};

async function listFiles(dir, predicate = () => true) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...await listFiles(path, predicate));
    if (entry.isFile() && predicate(path)) files.push(path);
  }
  return files;
}

function fail(message) {
  failures.push(message);
}

function hasFrontmatter(source, file) {
  if (!source.startsWith("---\n") || source.indexOf("\n---", 4) === -1) {
    fail(`${file}: frontmatter YAML manquant ou invalide`);
    return false;
  }
  return true;
}

async function validateMarkdownFrontmatter(files, requiredKeys) {
  for (const file of files) {
    const source = await readFile(file, "utf8");
    if (!hasFrontmatter(source, file)) continue;
    const frontmatter = source.slice(4, source.indexOf("\n---", 4));
    for (const key of requiredKeys) {
      if (!new RegExp(`^${key}:`, "m").test(frontmatter)) {
        fail(`${file}: frontmatter sans ${key}`);
      }
    }
  }
}

async function main() {
  const claudeAgents = await listFiles(join(ROOT, "templates", "claude", "agents"), (file) => file.endsWith(".md") && !file.endsWith("_TEMPLATE-agent.md"));
  const claudeSkills = await listFiles(join(ROOT, "templates", "claude", "skills"), (file) => file.endsWith("SKILL.md") && !file.includes("_TEMPLATE-skill"));
  const claudeCommands = await listFiles(join(ROOT, "templates", "claude", "commands"), (file) => file.endsWith(".md"));
  const codexSkills = await listFiles(join(ROOT, "templates", "codex", ".agents", "skills"), (file) => file.endsWith("SKILL.md"));
  const codexAgents = await listFiles(join(ROOT, "templates", "codex", ".codex", "agents"), (file) => file.endsWith(".toml"));

  const EXPECTED_AGENTS = 18;
  const EXPECTED_SKILLS = 23;
  if (claudeAgents.length !== EXPECTED_AGENTS) fail(`templates/claude/agents: attendu ${EXPECTED_AGENTS} agents, obtenu ${claudeAgents.length}`);
  if (claudeSkills.length !== EXPECTED_SKILLS) fail(`templates/claude/skills: attendu ${EXPECTED_SKILLS} skills, obtenu ${claudeSkills.length}`);
  if (claudeCommands.length !== EXPECTED_SKILLS) fail(`templates/claude/commands: attendu ${EXPECTED_SKILLS} commandes, obtenu ${claudeCommands.length}`);
  if (codexSkills.length !== EXPECTED_SKILLS) fail(`templates/codex/.agents/skills: attendu ${EXPECTED_SKILLS} skills, obtenu ${codexSkills.length}`);
  if (codexAgents.length !== EXPECTED_AGENTS) fail(`templates/codex/.codex/agents: attendu ${EXPECTED_AGENTS} agents, obtenu ${codexAgents.length}`);

  // Chaque skill a sa commande slash, et inversement.
  const skillNames = new Set(claudeSkills.map((file) => file.split("/").at(-2)));
  const commandNames = new Set(claudeCommands.map((file) => file.split("/").pop().replace(/\.md$/, "")));
  for (const name of skillNames) if (!commandNames.has(name)) fail(`templates/claude/commands/${name}.md manquant`);
  for (const name of commandNames) if (!skillNames.has(name)) fail(`templates/claude/commands/${name}.md sans skill`);

  // v0.5.0+: hooks executables et syntaxe bash valide.
  for (const dir of [join(ROOT, "templates", "claude", "hooks"), join(ROOT, "templates", "codex", ".codex", "hooks")]) {
    const hooks = await listFiles(dir, (file) => file.endsWith(".sh") || file.endsWith("/pre-push"));
    // config.sh et review-dir.sh sont sourcés, pas exécutés : seule la syntaxe compte.
    const sourced = new Set(["config.sh", "review-dir.sh"]);
    if (hooks.length === 0) fail(`${dir}: aucun hook`);
    for (const file of hooks) {
      if (!sourced.has(file.split("/").pop()) && ((await stat(file)).mode & 0o111) === 0) fail(`${file}: non executable (chmod +x)`);
      try {
        execFileSync("bash", ["-n", file], { stdio: "pipe" });
      } catch (error) {
        fail(`${file}: syntaxe bash invalide\n${error.stderr}`);
      }
    }
  }

  await validateMarkdownFrontmatter([...claudeAgents, ...claudeSkills, ...codexSkills], ["name", "description"]);

  for (const file of codexAgents) {
    const source = await readFile(file, "utf8");
    for (const key of ["name", "description", "model", "model_reasoning_effort", "developer_instructions"]) {
      if (!new RegExp(`^${key}\\s*=`, "m").test(source)) {
        fail(`${file}: champ TOML ${key} manquant`);
      }
    }
    const basename = file.split("/").pop();
    if (expectedCodexModels[basename]) {
      const [model, effort] = expectedCodexModels[basename];
      if (!source.includes(`model = "${model}"`)) {
        fail(`${file}: modele attendu ${model}`);
      }
      if (!source.includes(`model_reasoning_effort = "${effort}"`)) {
        fail(`${file}: effort attendu ${effort}`);
      }
    }
  }

  for (const file of [...codexSkills, ...codexAgents]) {
    const source = await readFile(file, "utf8");
    for (const forbidden of [".claude", "AskUserQuestion", "allowed-tools:", "triggers:"]) {
      if (source.includes(forbidden)) {
        fail(`${file}: reliquat Claude detecte (${forbidden})`);
      }
    }
  }

  // v0.4.0+: kit-managed root files must carry version marker.
  const markerFiles = [
    { path: join(ROOT, "templates", "CLAUDE.md.template"), name: "CLAUDE.md" },
    { path: join(ROOT, "templates", "codex", "AGENTS.md"), name: "AGENTS.md" },
  ];
  for (const { path, name } of markerFiles) {
    if (!await exists(path)) {
      fail(`${path}: fichier attendu manquant`);
      continue;
    }
    const source = await readFile(path, "utf8");
    const expected = `<!-- virtual-staff-kit:${name} v${KIT_VERSION} -->`;
    if (!source.startsWith(expected)) {
      fail(`${path}: marqueur attendu en tete: ${expected}`);
    }
  }

  // Manifest pour la version courante doit exister.
  const manifestPath = join(ROOT, "scripts", "manifests", `v${KIT_VERSION}.json`);
  if (!await exists(manifestPath)) {
    fail(`manifest manquant: ${manifestPath} (lance: npm run generate:manifest -- --version ${KIT_VERSION})`);
  } else {
    const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
    if (manifest.version !== KIT_VERSION) {
      fail(`manifest version mismatch: ${manifest.version} vs ${KIT_VERSION}`);
    }
    if (!manifest.files || Object.keys(manifest.files).length < 50) {
      fail(`manifest v${KIT_VERSION}: nombre de fichiers suspect (${Object.keys(manifest.files || {}).length})`);
    }
  }

  if (failures.length > 0) {
    console.error(failures.map((failure) => `- ${failure}`).join("\n"));
    process.exit(1);
  }

  console.log("Templates OK");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
