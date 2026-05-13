#!/usr/bin/env node
// Updates a project that was installed by a previous version of the kit.
// - Detects kit-managed files via SHA-256 manifests (scripts/manifests/v*.json)
// - Preserves user-edited files (interactive prompt or --conflicts policy)
// - Never touches user-owned files (docs/GUIDE-LLM.md, settings.local.json, backlog.md, ...)
// - Dry-run by default; pass --apply to actually write changes.

import { createHash } from "node:crypto";
import { createInterface } from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import { access, cp, mkdir, readdir, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const TEMPLATES = join(ROOT, "templates");
const MANIFESTS = join(ROOT, "scripts", "manifests");
const TIMESTAMP = new Date().toISOString().replace(/[-:]/g, "").replace(/\..+/, "").replace("T", "-");
const PKG = JSON.parse(await readFile(join(ROOT, "package.json"), "utf8"));
const KIT_VERSION = PKG.version;

// Map target-relative path -> absolute source path in templates/
function sourceFor(targetRelPath) {
  if (targetRelPath === "AGENTS.md") return join(TEMPLATES, "codex", "AGENTS.md");
  if (targetRelPath === "CLAUDE.md") return join(TEMPLATES, "CLAUDE.md.template");
  if (targetRelPath.startsWith(".claude/agents/")) return join(TEMPLATES, "claude", "agents", targetRelPath.slice(".claude/agents/".length));
  if (targetRelPath.startsWith(".claude/skills/")) return join(TEMPLATES, "claude", "skills", targetRelPath.slice(".claude/skills/".length));
  if (targetRelPath.startsWith(".claude/commands/")) return join(TEMPLATES, "claude", "commands", targetRelPath.slice(".claude/commands/".length));
  if (targetRelPath.startsWith(".agents/skills/")) return join(TEMPLATES, "codex", ".agents", "skills", targetRelPath.slice(".agents/skills/".length));
  if (targetRelPath.startsWith(".codex/agents/")) return join(TEMPLATES, "codex", ".codex", "agents", targetRelPath.slice(".codex/agents/".length));
  if (targetRelPath.startsWith("docs/formats/")) return join(TEMPLATES, "docs", "formats", targetRelPath.slice("docs/formats/".length));
  return null;
}

// Paths we never touch even if present.
const PRESERVE_PATHS = new Set([
  ".claude/settings.local.json",
  "docs/GUIDE-LLM.md",
  "docs/EQUIPES-LLM.md",
  "docs/COUTS-LLM.md",
  "backlog.md",
  "virtual-staff-install-report.md",
  "virtual-staff-ai-setup.md",
  "virtual-staff-update-report.md",
]);

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

function hashContent(buf) {
  return createHash("sha256").update(buf).digest("hex");
}

async function hashFile(path) {
  const buf = await readFile(path);
  return hashContent(buf);
}

async function loadManifest(version) {
  const path = join(MANIFESTS, `v${version}.json`);
  if (!await exists(path)) return null;
  return JSON.parse(await readFile(path, "utf8"));
}

async function listAvailableManifests() {
  const entries = await readdir(MANIFESTS).catch(() => []);
  return entries
    .filter((name) => name.startsWith("v") && name.endsWith(".json"))
    .map((name) => name.slice(1, -5));
}

async function detectVersion(targetRoot, manifests) {
  // Match the target tree against all known manifests.
  // The version whose hashes match the most files (without conflict) is the best guess.
  let best = { version: null, matches: 0 };
  for (const m of manifests) {
    let matches = 0;
    for (const [relPath, hash] of Object.entries(m.files)) {
      const fullPath = join(targetRoot, relPath);
      if (!await exists(fullPath)) continue;
      const localHash = await hashFile(fullPath);
      if (localHash === hash) matches += 1;
    }
    if (matches > best.matches) best = { version: m.version, matches };
  }
  return best;
}

async function classifyFile(targetRoot, relPath, currentManifest, allManifests) {
  const fullPath = join(targetRoot, relPath);
  const expectedHash = currentManifest.files[relPath];
  const sourcePath = sourceFor(relPath);

  if (!sourcePath) return { status: "no-source", message: "no source mapping" };
  if (!await exists(sourcePath)) return { status: "no-source", message: "source missing in templates" };

  if (!await exists(fullPath)) return { status: "missing", expectedHash, sourcePath };

  const localHash = await hashFile(fullPath);
  if (localHash === expectedHash) return { status: "current", localHash };

  // Look across all known manifests to see if this is a known older version.
  for (const m of allManifests) {
    if (m.files[relPath] === localHash) {
      return { status: "outdated", fromVersion: m.version, localHash, expectedHash, sourcePath };
    }
  }
  return { status: "customized", localHash, expectedHash, sourcePath };
}

async function ensureParent(path) {
  await mkdir(dirname(path), { recursive: true });
}

async function backupAndReplace(targetPath, sourcePath, conflicts, plannedActions) {
  if (await exists(targetPath)) {
    if (conflicts === "skip") {
      plannedActions.push({ action: "skip", target: targetPath, note: "exists, --conflicts=skip" });
      return;
    }
    if (conflicts === "abort") {
      throw new Error(`File exists and --conflicts=abort: ${targetPath}`);
    }
    const backup = `${targetPath}.backup-${TIMESTAMP}`;
    plannedActions.push({ action: "backup", source: targetPath, target: backup });
  }
  plannedActions.push({ action: "write", source: sourcePath, target: targetPath });
}

async function executeActions(actions) {
  const log = [];
  for (const a of actions) {
    if (a.action === "skip") {
      log.push(`SKIP   ${a.target}${a.note ? ` (${a.note})` : ""}`);
      continue;
    }
    if (a.action === "backup") {
      await rename(a.source, a.target);
      log.push(`BACKUP ${a.source} -> ${a.target}`);
      continue;
    }
    if (a.action === "write") {
      await ensureParent(a.target);
      await cp(a.source, a.target);
      log.push(`WRITE  ${a.target}`);
      continue;
    }
    if (a.action === "noop") {
      log.push(`NOOP   ${a.target}${a.note ? ` (${a.note})` : ""}`);
    }
  }
  return log;
}

async function promptCustomized(rl, relPath, fromVersion) {
  while (true) {
    const hint = fromVersion ? `was v${fromVersion}` : "unknown origin";
    const answer = (await rl.question(`  ${relPath} customised (${hint}) — [s]kip / [b]ackup+replace / [a]bort ? `)).trim().toLowerCase();
    if (["s", "skip"].includes(answer)) return "skip";
    if (["b", "backup"].includes(answer)) return "replace";
    if (["a", "abort"].includes(answer)) return "abort";
  }
}

async function assertTarget(path) {
  if (!await exists(path)) throw new Error(`Target directory does not exist: ${path}`);
  const stats = await stat(path);
  if (!stats.isDirectory()) throw new Error(`Target is not a directory: ${path}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const targetAnswer = args.target;
  if (!targetAnswer) {
    console.error("Usage: node scripts/update.mjs --target <path> [--apply] [--from <version>] [--conflicts backup|skip|abort]");
    process.exit(1);
  }
  const targetRoot = resolve(targetAnswer);
  await assertTarget(targetRoot);

  const apply = !!args.apply;
  const conflicts = args.conflicts || "backup";
  if (!["backup", "skip", "abort"].includes(conflicts)) {
    throw new Error("--conflicts must be backup, skip or abort");
  }
  // CLAUDE.md is opt-in even during update. Without the flag, skip if missing.
  const withRootClaudeMd = !!args["with-root-claudemd"];

  // Load the current manifest (the version we're updating TO).
  const currentManifest = await loadManifest(KIT_VERSION);
  if (!currentManifest) throw new Error(`No manifest for current version v${KIT_VERSION} at ${MANIFESTS}`);

  // Load all manifests for version detection.
  const versions = await listAvailableManifests();
  const allManifests = (await Promise.all(versions.map((v) => loadManifest(v)))).filter(Boolean);

  // Detect or accept from-version.
  let detected = { version: args.from || null, matches: 0 };
  if (!args.from) {
    detected = await detectVersion(targetRoot, allManifests);
  }

  console.log(`Kit version (target): v${KIT_VERSION}`);
  console.log(`Project: ${targetRoot}`);
  console.log(`Detected source version: ${detected.version ? `v${detected.version} (${detected.matches} files matched)` : "unknown"}`);
  console.log(`Mode: ${apply ? "APPLY" : "DRY-RUN (use --apply to write)"}`);
  console.log(`Conflicts policy: ${conflicts}`);
  console.log("");

  // Classify each file in the current manifest.
  const classifications = {};
  for (const relPath of Object.keys(currentManifest.files)) {
    if (PRESERVE_PATHS.has(relPath)) continue;
    classifications[relPath] = await classifyFile(targetRoot, relPath, currentManifest, allManifests);
  }

  // Plan actions.
  const planned = [];
  const summary = { current: [], missing: [], outdated: [], customized: [], skipped: [], errors: [] };
  const rl = createInterface({ input, output });

  try {
    for (const [relPath, info] of Object.entries(classifications)) {
      const fullPath = join(targetRoot, relPath);
      // CLAUDE.md (root) is opt-in: skip if not present and no --with-root-claudemd flag.
      if (relPath === "CLAUDE.md" && info.status === "missing" && !withRootClaudeMd) {
        summary.skipped.push(relPath);
        planned.push({ action: "skip", target: fullPath, note: "CLAUDE.md opt-in, pass --with-root-claudemd to add" });
        continue;
      }
      if (info.status === "current") {
        summary.current.push(relPath);
        planned.push({ action: "noop", target: fullPath, note: "current" });
      } else if (info.status === "missing") {
        summary.missing.push(relPath);
        planned.push({ action: "write", source: info.sourcePath, target: fullPath });
      } else if (info.status === "outdated") {
        // Outdated = file matches a known older kit version, safe to backup+replace.
        // --conflicts policy applies only to customized files (unknown hash).
        summary.outdated.push(relPath);
        await backupAndReplace(fullPath, info.sourcePath, "backup", planned);
      } else if (info.status === "customized") {
        let decision = "replace";
        if (conflicts === "skip") {
          decision = "skip";
        } else if (conflicts === "abort") {
          throw new Error(`Customized file with --conflicts=abort: ${relPath}`);
        } else if (apply && process.stdin.isTTY) {
          // Only prompt in interactive apply mode.
          decision = await promptCustomized(rl, relPath, info.fromVersion);
          if (decision === "abort") throw new Error("Aborted by user");
        } else if (!apply) {
          // In dry-run, just report; will need interactive decision on --apply.
          summary.customized.push(relPath);
          planned.push({ action: "noop", target: fullPath, note: "customized — needs decision on --apply" });
          continue;
        }
        if (decision === "skip") {
          summary.skipped.push(relPath);
          planned.push({ action: "skip", target: fullPath, note: "customized, kept" });
        } else {
          summary.customized.push(relPath);
          await backupAndReplace(fullPath, info.sourcePath, conflicts === "skip" ? "skip" : "backup", planned);
        }
      } else if (info.status === "no-source") {
        summary.errors.push(`${relPath}: ${info.message}`);
      }
    }

    // Print plan.
    console.log(`Files current (skip): ${summary.current.length}`);
    console.log(`Files missing (add):  ${summary.missing.length}`);
    console.log(`Files outdated:       ${summary.outdated.length}`);
    console.log(`Files customized:     ${summary.customized.length}`);
    console.log(`Files skipped:        ${summary.skipped.length}`);
    if (summary.errors.length) console.log(`Errors: ${summary.errors.length}`);
    console.log("");

    if (summary.missing.length) {
      console.log("To add:");
      summary.missing.forEach((p) => console.log(`  + ${p}`));
      console.log("");
    }
    if (summary.outdated.length) {
      console.log("To update (outdated, identical to a known older version):");
      summary.outdated.forEach((p) => console.log(`  ~ ${p}`));
      console.log("");
    }
    if (summary.customized.length) {
      console.log("Customized (will prompt on --apply, or follow --conflicts policy):");
      summary.customized.forEach((p) => console.log(`  ! ${p}`));
      console.log("");
    }
    if (summary.errors.length) {
      console.log("Errors:");
      summary.errors.forEach((e) => console.log(`  X ${e}`));
      console.log("");
    }

    if (!apply) {
      console.log("Dry-run complete. Re-run with --apply to write changes.");
      return;
    }

    const log = await executeActions(planned);

    const report = [
      "# Virtual Staff Kit — update report",
      "",
      `Date: ${new Date().toISOString()}`,
      `Kit version: v${KIT_VERSION}`,
      `Detected source: ${detected.version ? `v${detected.version}` : "unknown"}`,
      `Conflicts policy: ${conflicts}`,
      "",
      "## Actions",
      ...log.map((l) => `- ${l}`),
      "",
      "## Summary",
      `- current: ${summary.current.length}`,
      `- added: ${summary.missing.length}`,
      `- updated: ${summary.outdated.length}`,
      `- customized handled: ${summary.customized.length}`,
      `- skipped: ${summary.skipped.length}`,
      `- errors: ${summary.errors.length}`,
      "",
    ].join("\n");
    const reportPath = join(targetRoot, "virtual-staff-update-report.md");
    await writeFile(reportPath, report, "utf8");
    console.log(`\nUpdate applied. Report: ${reportPath}`);
  } finally {
    rl.close();
  }
}

main().catch((error) => {
  console.error(`\nErreur: ${error.message}`);
  process.exit(1);
});
