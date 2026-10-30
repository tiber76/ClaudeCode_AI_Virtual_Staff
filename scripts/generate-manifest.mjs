#!/usr/bin/env node
// Generates a SHA-256 manifest of kit-managed files for a given version.
// Manifest maps target-relative paths (post-install) -> sha256 hex.
// Used by scripts/update.mjs to detect customized vs untouched files.

import { createHash } from "node:crypto";
import { readFile, readdir, writeFile, stat } from "node:fs/promises";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const TEMPLATES = join(ROOT, "templates");
const MANIFESTS = join(ROOT, "scripts", "manifests");

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

// Mapping declaration: each entry produces target-relative paths after install.
// (sourceGlob, mapTargetPath) where mapTargetPath((relPath) => targetRelPath
const MAPPINGS = [
  { sourceDir: "claude/agents", targetPrefix: ".claude/agents" },
  { sourceDir: "claude/skills", targetPrefix: ".claude/skills" },
  { sourceDir: "claude/commands", targetPrefix: ".claude/commands" },
  { sourceDir: "claude/hooks", targetPrefix: ".claude/hooks" },
  { sourceDir: "codex/.agents/skills", targetPrefix: ".agents/skills" },
  { sourceDir: "codex/.codex/agents", targetPrefix: ".codex/agents" },
  { sourceDir: "codex/.codex/hooks", targetPrefix: ".codex/hooks" },
  { sourceDir: "docs/formats", targetPrefix: "docs/formats" },
  { sourceFile: "codex/AGENTS.md", targetPath: "AGENTS.md" },
  { sourceFile: "CLAUDE.md.template", targetPath: "CLAUDE.md" },
];

async function walkFiles(dir) {
  const out = [];
  let entries;
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...await walkFiles(full));
    } else if (entry.isFile()) {
      out.push(full);
    }
  }
  return out;
}

function hashContent(content) {
  return createHash("sha256").update(content).digest("hex");
}

async function buildFromTree(templatesRoot) {
  const manifest = {};
  for (const mapping of MAPPINGS) {
    if (mapping.sourceDir) {
      const sourceDir = join(templatesRoot, mapping.sourceDir);
      const files = await walkFiles(sourceDir);
      for (const file of files) {
        const rel = relative(sourceDir, file);
        const targetRel = join(mapping.targetPrefix, rel);
        const content = await readFile(file);
        manifest[targetRel] = hashContent(content);
      }
    } else if (mapping.sourceFile) {
      const sourceFile = join(templatesRoot, mapping.sourceFile);
      try {
        const content = await readFile(sourceFile);
        manifest[mapping.targetPath] = hashContent(content);
      } catch {
        // File absent at this version — skip silently.
      }
    }
  }
  return manifest;
}

function gitShow(ref, path) {
  try {
    return execFileSync("git", ["show", `${ref}:${path}`], { cwd: ROOT });
  } catch {
    return null;
  }
}

function gitListTree(ref, path) {
  try {
    const out = execFileSync("git", ["ls-tree", "-r", "--name-only", ref, "--", path], { cwd: ROOT, encoding: "utf8" });
    return out.split("\n").filter(Boolean);
  } catch {
    return [];
  }
}

async function buildFromGit(ref) {
  const manifest = {};
  for (const mapping of MAPPINGS) {
    if (mapping.sourceDir) {
      const sourceDir = `templates/${mapping.sourceDir}`;
      const files = gitListTree(ref, sourceDir);
      for (const file of files) {
        const content = gitShow(ref, file);
        if (!content) continue;
        const rel = relative(sourceDir, file);
        const targetRel = join(mapping.targetPrefix, rel);
        manifest[targetRel] = hashContent(content);
      }
    } else if (mapping.sourceFile) {
      const sourceFile = `templates/${mapping.sourceFile}`;
      const content = gitShow(ref, sourceFile);
      if (content) manifest[mapping.targetPath] = hashContent(content);
    }
  }
  return manifest;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.version) {
    console.error("Usage: node scripts/generate-manifest.mjs --version <X.Y.Z> [--from-git <ref>]");
    process.exit(1);
  }
  const version = args.version;
  const fromGit = args["from-git"];

  const manifest = fromGit ? await buildFromGit(fromGit) : await buildFromTree(TEMPLATES);
  const sorted = Object.fromEntries(Object.entries(manifest).sort(([a], [b]) => a.localeCompare(b)));

  const payload = {
    version,
    generated_at: new Date().toISOString(),
    source: fromGit ? `git:${fromGit}` : "working-tree",
    files: sorted,
  };

  const outPath = join(MANIFESTS, `v${version}.json`);
  await writeFile(outPath, JSON.stringify(payload, null, 2) + "\n", "utf8");

  const count = Object.keys(sorted).length;
  console.log(`Wrote ${outPath} (${count} files, source: ${payload.source})`);
}

main().catch((error) => {
  console.error(`\nErreur: ${error.message}`);
  process.exit(1);
});
