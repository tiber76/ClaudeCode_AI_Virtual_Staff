#!/usr/bin/env node
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const CLAUDE_DIR = join(ROOT, "templates", "claude");
const CODEX_DIR = join(ROOT, "templates", "codex");

const AGENT_MODEL_MAP = {
  opus: { model: "gpt-5.5", effort: "high" },
  sonnet: { model: "gpt-5.4-mini", effort: "medium" },
  haiku: { model: "gpt-5.4-nano", effort: "low" },
};

const CODEX_AGENT_MODEL_MAP = {
  "full-stack-lead": { model: "gpt-5.3-codex", effort: "high" },
  cso: { model: "gpt-5.3-codex", effort: "high" },
  qa: { model: "gpt-5.3-codex", effort: "medium" },
  "data-engineer": { model: "gpt-5.3-codex", effort: "medium" },
  "ai-llm-engineer": { model: "gpt-5.3-codex", effort: "medium" },
  "po-metier": { model: "gpt-5.4-mini", effort: "medium" },
  "designer-uxui": { model: "gpt-5.4-mini", effort: "medium" },
  "growth-lead": { model: "gpt-5.5", effort: "high" },
  "sales-b2b": { model: "gpt-5.5", effort: "high" },
  "customer-success": { model: "gpt-5.4-mini", effort: "medium" },
  "copywriter-brand": { model: "gpt-5.4-mini", effort: "medium" },
  "content-seo": { model: "gpt-5.4-mini", effort: "medium" },
  "marketing-analytics": { model: "gpt-5.4-mini", effort: "medium" },
};

const SKILLS = [
  "audit-funnel",
  "brief-demo",
  "call-growth-lead",
  "call-tech-lead",
  "fullstack-lead-tech",
  "investigate-bug",
  "qa-flow",
  "redige-brief",
  "redige-us",
  "retro",
  "retro-campagne",
  "review-pr",
  "security-audit",
  "setup-project",
  "ship-landing",
  "ship-pr",
];

const AGENTS = [
  "ai-llm-engineer",
  "content-seo",
  "copywriter-brand",
  "cso",
  "customer-success",
  "data-engineer",
  "designer-uxui",
  "full-stack-lead",
  "growth-lead",
  "marketing-analytics",
  "po-metier",
  "qa",
  "sales-b2b",
];

function splitMarkdownFrontmatter(source, file) {
  if (!source.startsWith("---\n")) {
    throw new Error(`Missing frontmatter in ${file}`);
  }
  const end = source.indexOf("\n---", 4);
  if (end === -1) {
    throw new Error(`Unclosed frontmatter in ${file}`);
  }
  return {
    frontmatter: source.slice(4, end),
    body: source.slice(end + 5).replace(/^\n/, ""),
  };
}

function readYamlScalar(frontmatter, key) {
  const lines = frontmatter.split("\n");
  const start = lines.findIndex((line) => line.startsWith(`${key}:`));
  if (start === -1) return "";

  const line = lines[start];
  if (line.trim() === `${key}: |`) {
    const block = [];
    for (let i = start + 1; i < lines.length; i += 1) {
      const current = lines[i];
      if (/^[a-zA-Z0-9_-]+:/.test(current)) break;
      block.push(current.replace(/^  /, ""));
    }
    return block.join("\n").trim();
  }

  return line.slice(`${key}:`.length).trim().replace(/^["']|["']$/g, "");
}

function codexize(text) {
  let output = text
    .replaceAll("Claude Code", "Codex")
    .replaceAll("Claude", "OpenAI/Codex")
    .replaceAll(".claude/call-call-tech-lead-runs", ".codex/runs/call-tech-lead")
    .replaceAll(".claude/call-call-growth-lead-runs", ".codex/runs/call-growth-lead")
    .replaceAll(".claude/agents", ".codex/agents")
    .replaceAll(".claude/skills", ".agents/skills")
    .replaceAll(".claude/commands", ".agents/skills")
    .replaceAll(".claude/settings.local.json", ".codex/config.toml")
    .replaceAll(".claude", ".codex")
    .replaceAll("Agent(subagent_type:", "spawn subagent:")
    .replaceAll("Agent tool", "subagent spawning")
    .replaceAll("tool `Agent`", "mecanisme de subagents Codex")
    .replaceAll("AskUserQuestion", "question utilisateur")
    .replaceAll("Opus", "gpt-5.5")
    .replaceAll("Sonnet", "gpt-5.4-mini")
    .replaceAll("Haiku", "gpt-5.4-nano")
    .replaceAll("Claude Max", "abonnement Codex/OpenAI")
    .replaceAll("Claude API", "OpenAI API")
    .replaceAll("Anthropic", "OpenAI")
    .replaceAll("callClaude()", "callLLM()")
    .replaceAll("Generated with [OpenAI/Codex Code](https://claude.com/claude-code)", "Generated with Codex")
    .replaceAll("Co-Authored-By: OpenAI/Codex gpt-5.5 4.7 (1M context) <noreply@anthropic.com>", "Co-Authored-By: Codex <noreply@openai.com>")
    .replaceAll("templates/claude", "templates/codex");

  output = output
    .replaceAll("utilisent gpt-5.5 :", "utilisent le modele Codex adapte a leur role :")
    .replaceAll("| `full-stack-lead` | **gpt-5.5** |", "| `full-stack-lead` | **gpt-5.3-codex / high** |")
    .replaceAll("| `cso` | **gpt-5.5** |", "| `cso` | **gpt-5.3-codex / high** |")
    .replaceAll("| `data-engineer` | gpt-5.4-mini |", "| `data-engineer` | gpt-5.3-codex / medium |")
    .replaceAll("| `qa` | gpt-5.4-mini |", "| `qa` | gpt-5.3-codex / medium |")
    .replaceAll("| `ai-llm-engineer` | gpt-5.4-mini |", "| `ai-llm-engineer` | gpt-5.3-codex / medium |")
    .replaceAll("Requêtes SQL et index — gpt-5.4-mini excellent sur ce domaine", "Requêtes SQL, index et migrations — raisonnement code/data")
    .replaceAll("`full-stack-lead` (gpt-5.5)", "`full-stack-lead` (gpt-5.3-codex)")
    .replaceAll("full-stack-lead (gpt-5.5)", "full-stack-lead (gpt-5.3-codex)")
    .replaceAll("`qa` (gpt-5.4-mini)", "`qa` (gpt-5.3-codex)")
    .replaceAll("qa (gpt-5.4-mini)", "qa (gpt-5.3-codex)")
    .replaceAll("`cso` (gpt-5.5, si convoqué)", "`cso` (gpt-5.3-codex, si convoqué)");

  for (const skill of SKILLS) {
    output = output.replaceAll(`/${skill}`, `$${skill}`);
  }

  for (const agent of AGENTS) {
    output = output.replaceAll(`.codex/agents/${agent}.md`, `.codex/agents/${agent}.toml`);
    output = output.replaceAll(`\`${agent}.md\``, `\`${agent}.toml\``);
  }

  return output
    .replaceAll("`/<nom>`", "`$<nom>`")
    .replaceAll("/<nom>", "$<nom>")
    .replaceAll("commandes `", "skills `")
    .replaceAll("hors de `.codex/`, `docs/`", "hors de `.agents/`, `.codex/`, `docs/`")
    .replaceAll("grep -r \"{{\" .codex/ docs/", "grep -r \"{{\" .agents/ .codex/ docs/")
    .replaceAll("grep -rn \"{{\" .codex/ docs/", "grep -rn \"{{\" .agents/ .codex/ docs/")
    .replaceAll("cp -r .codex .codex.backup", "cp -r .agents .agents.backup")
    .replaceAll(
      "cp -r .agents .agents.backup-$(date +%Y%m%d-%H%M%S)",
      "cp -r .agents .agents.backup-$(date +%Y%m%d-%H%M%S)\ncp -r .codex .codex.backup-$(date +%Y%m%d-%H%M%S)",
    )
    .replaceAll("git add .codex/ docs/", "git add .agents/ .codex/ docs/")
    .replaceAll(".codex/runs$call-tech-lead", ".codex/runs/call-tech-lead")
    .replaceAll(".codex/runs$call-growth-lead", ".codex/runs/call-growth-lead")
    .replaceAll(".agents/skills$call-tech-lead", ".agents/skills/call-tech-lead")
    .replaceAll(".agents/skills$call-growth-lead", ".agents/skills/call-growth-lead")
    .replaceAll(".agents/skills$retro", ".agents/skills/retro")
    .replaceAll(".codex/agents$<nom>.md", ".codex/agents/<nom>.toml")
    .replaceAll(".codex/agents/<agent>.md", ".codex/agents/<agent>.toml")
    .replaceAll(".codex/agents/*.md", ".codex/agents/*.toml")
    .replaceAll(".agents/skills/*.md", ".agents/skills/*/SKILL.md");
}

function codexSkillFrontmatter(name, description) {
  return `---\nname: ${name}\ndescription: |\n${description
    .split("\n")
    .map((line) => `  ${codexize(line)}`)
    .join("\n")}\n---\n`;
}

function tomlLiteral(value) {
  return `'''\n${value.replaceAll("'''", "''' + \"'''\" + '''")}\n'''`;
}

async function writeCodexSkill(name) {
  const sourcePath = join(CLAUDE_DIR, "skills", name, "SKILL.md");
  const source = await readFile(sourcePath, "utf8");
  const { frontmatter, body } = splitMarkdownFrontmatter(source, sourcePath);
  const description = readYamlScalar(frontmatter, "description");
  const targetPath = join(CODEX_DIR, ".agents", "skills", name, "SKILL.md");
  const prelude = [
    "",
    "> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$" + name + "` ou laisser Codex le choisir par sa description.",
    "> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.",
    "",
  ].join("\n");

  const content = `${codexSkillFrontmatter(name, description)}${prelude}${codexize(body)}`;
  await mkdir(dirname(targetPath), { recursive: true });
  await writeFile(targetPath, content, "utf8");
}

async function writeCodexAgent(name) {
  const sourcePath = join(CLAUDE_DIR, "agents", `${name}.md`);
  const source = await readFile(sourcePath, "utf8");
  const { frontmatter, body } = splitMarkdownFrontmatter(source, sourcePath);
  const description = codexize(readYamlScalar(frontmatter, "description"));
  const claudeModel = readYamlScalar(frontmatter, "model") || "sonnet";
  const { model, effort } = CODEX_AGENT_MODEL_MAP[name] || AGENT_MODEL_MAP[claudeModel] || AGENT_MODEL_MAP.sonnet;
  const instructions = codexize(body);
  const targetPath = join(CODEX_DIR, ".codex", "agents", `${name}.toml`);

  const content = [
    `name = ${JSON.stringify(name)}`,
    `description = ${JSON.stringify(description)}`,
    `model = ${JSON.stringify(model)}`,
    `model_reasoning_effort = ${JSON.stringify(effort)}`,
    "",
    `developer_instructions = ${tomlLiteral(instructions)}`,
    "",
  ].join("\n");

  await mkdir(dirname(targetPath), { recursive: true });
  await writeFile(targetPath, content, "utf8");
}

async function writeStaticFiles() {
  const agentsMd = [
    "# AGENTS.md — Equipe virtuelle Codex {{PROJECT_NAME}}",
    "",
    "Ce fichier donne a Codex les regles transverses du projet. Les details projet vivent dans `docs/GUIDE-LLM.md`, les dettes dans `backlog.md`, les skills dans `.agents/skills/`, et les agents specialises dans `.codex/agents/`.",
    "",
    "## Debut de session",
    "",
    "1. Lire `docs/GUIDE-LLM.md` si present.",
    "2. Lire `backlog.md` si present et rappeler en une phrase le nombre de P0/P1/P2 ouverts, sans traiter le backlog sans accord explicite.",
    "3. Verifier la branche courante avant toute modification.",
    "4. Ne jamais merger, supprimer une branche, force push, amend ou executer une migration de production sans instruction explicite.",
    "",
    "## Orchestration",
    "",
    "- Pour une feature non triviale, utiliser le skill `$call-tech-lead`.",
    "- Pour une initiative marketing/growth, utiliser `$call-growth-lead`.",
    "- Pour un bug, commencer par `$investigate-bug` sauf si la cause est deja isolee.",
    "- Les runs orchestres ecrivent leurs artefacts sous `.codex/runs/<skill>/<YYYYMMDD-HHMMSS-slug>/`.",
    "- Les subagents Codex sont convoques explicitement par l'orchestrateur, avec avis independants au round 1 puis debat cible au round 2.",
    "",
    "## Verification",
    "",
    "- Toute evolution doit avoir une verification adaptee au risque : test unitaire, integration, E2E, build ou revue manuelle documentee.",
    "- Les resultats des commandes doivent etre resumes dans le transcript de run quand un skill orchestre le travail.",
    "- Les migrations SQL sont produites comme fichiers idempotents, jamais executees automatiquement contre staging/prod.",
    "",
    "## Livraison",
    "",
    "- PR autorisee si les checks demandes sont passes.",
    "- Merge interdit sans ordre explicite contenant clairement `merge` ou equivalent.",
    "- Apres merge d'une feature non triviale, lancer `$retro` pour capitaliser dans `docs/GUIDE-LLM.md` et/ou le backlog.",
    "",
  ].join("\n");

  const readme = [
    "# Templates Codex / OpenAI",
    "",
    "Ce dossier est l'adapter Codex du starter kit d'equipes virtuelles.",
    "",
    "## Structure",
    "",
    "```",
    "codex/",
    "├── AGENTS.md                 # regles projet lues par Codex",
    "├── .agents/skills/           # 16 skills Codex, un dossier par workflow",
    "└── .codex/agents/            # 13 agents specialises Codex en TOML",
    "```",
    "",
    "## Installation dans un projet cible",
    "",
    "Depuis la racine du projet cible :",
    "",
    "```bash",
    "cp -r <chemin-kit>/templates/codex/.agents ./",
    "cp -r <chemin-kit>/templates/codex/.codex ./",
    "cp <chemin-kit>/templates/codex/AGENTS.md ./AGENTS.md",
    "cp -r <chemin-kit>/templates/docs ./docs",
    "cp <chemin-kit>/templates/backlog.template.md ./backlog.md",
    "",
    "mv docs/GUIDE-LLM.template.md docs/GUIDE-LLM.md",
    "mv docs/EQUIPES-LLM.template.md docs/EQUIPES-LLM.md",
    "mv docs/COUTS-LLM.template.md docs/COUTS-LLM.md",
    "```",
    "",
    "Puis ouvrir Codex a la racine et lancer :",
    "",
    "```",
    "$setup-project --ai",
    "```",
    "",
    "## Invocation",
    "",
    "Codex active les skills soit explicitement avec `$nom-du-skill`, soit implicitement quand la description correspond a la demande. Les equivalents principaux sont :",
    "",
    "- `$call-tech-lead` : feature technique complete jusqu'a PR.",
    "- `$call-growth-lead` : campagne, landing, brief, audit funnel.",
    "- `$redige-us`, `$fullstack-lead-tech`, `$review-pr`, `$qa-flow`, `$ship-pr` : workflows tech cibles.",
    "- `$retro` : capitalisation apres livraison.",
    "",
    "## Maintenance",
    "",
    "Ne modifie pas les fichiers generes a la main si la source Claude doit rester canonique. Regenerer avec :",
    "",
    "```bash",
    "node scripts/generate-codex-templates.mjs",
    "```",
    "",
  ].join("\n");

  await writeFile(join(CODEX_DIR, "AGENTS.md"), agentsMd, "utf8");
  await writeFile(join(CODEX_DIR, "README.md"), readme, "utf8");
}

async function main() {
  await rm(CODEX_DIR, { recursive: true, force: true });
  await mkdir(CODEX_DIR, { recursive: true });
  for (const name of SKILLS) await writeCodexSkill(name);
  for (const name of AGENTS) await writeCodexAgent(name);
  await writeStaticFiles();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
