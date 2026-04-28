#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const failures = [];
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

  if (claudeAgents.length !== 13) fail(`templates/claude/agents: attendu 13 agents, obtenu ${claudeAgents.length}`);
  if (claudeSkills.length !== 16) fail(`templates/claude/skills: attendu 16 skills, obtenu ${claudeSkills.length}`);
  if (claudeCommands.length !== 16) fail(`templates/claude/commands: attendu 16 commandes, obtenu ${claudeCommands.length}`);
  if (codexSkills.length !== 16) fail(`templates/codex/.agents/skills: attendu 16 skills, obtenu ${codexSkills.length}`);
  if (codexAgents.length !== 13) fail(`templates/codex/.codex/agents: attendu 13 agents, obtenu ${codexAgents.length}`);

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
