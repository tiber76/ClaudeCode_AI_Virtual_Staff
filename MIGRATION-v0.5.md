# Migration v0.4.0 → v0.5.0

La v0.5.0 ajoute une **voie courte** pour les petits sujets (`/dev-express`, `/fix-bug`), une **porte de review mécanique** avant chaque push (hooks `.claude/hooks/`), une **review en pipeline** chercheurs / vérificateurs, et un **`/call-tech-lead` découpé en tranches** portées chacune par un worker frais. Détail : `CHANGELOG.md`.

Depuis la v0.3.0 : passer d'abord par `MIGRATION-v0.4.md` (le script sait aussi sauter directement de 0.3.0 à 0.5.0).

## Ce qui arrive dans ton projet

| Quoi | Où |
|---|---|
| 7 skills + commandes : `dev-express`, `fix-bug`, `verify`, `pre-mortem`, `close-session`, `audit-memory`, `integre-design` | `.claude/skills/`, `.claude/commands/` |
| Fichiers partagés lus par les skills | `.claude/skills/_partage/` |
| 5 agents : `full-stack-worker`, `review-finder`, `review-verifier`, `pre-mortem-adversaire`, `integrateur` | `.claude/agents/` |
| Hooks + réglages + auto-tests | `.claude/hooks/` |
| Refonte de `call-tech-lead`, `review-pr`, `ship-pr` (fichiers d'appui `phases.md`, `rounds.md`, `angles.md`…) | `.claude/skills/` |
| Équivalents Codex | `.agents/skills/`, `.codex/agents/`, `.codex/hooks/` |

## Étape 1 — Script

```bash
cd /chemin/vers/ClaudeCode_AI_Virtual_Staff
git pull

node scripts/update.mjs --target /chemin/vers/ton/projet            # dry-run
node scripts/update.mjs --target /chemin/vers/ton/projet --apply    # écrit
```

Mêmes garanties qu'en v0.4.0 : backup `.backup-YYYYMMDD-HHMMSS` avant tout écrasement, fichiers customisés détectés par SHA-256 (`--conflicts skip|backup|abort`), rapport `virtual-staff-update-report.md`.

Les fichiers que le script ne touche jamais (`docs/GUIDE-LLM.md`, `docs/EQUIPES-LLM.md`, `.claude/settings.local.json`, `backlog.md`…) demandent les étapes 2 à 4.

## Étape 2 — Remplir les placeholders des nouveaux fichiers

Les fichiers ajoutés arrivent bruts, avec leurs `{{PLACEHOLDERS}}`. Dans Claude Code, à la racine du projet :

```text
/setup-project --ai
```

Ou à la main : `grep -rn "{{" .claude/ | grep -v "{{#IF" | grep -v "{{/IF}}"` puis remplacer avec les valeurs déjà posées dans tes autres fichiers (branche de base, commandes de test, dossiers). Le plus important : `.claude/hooks/config.sh` (`REVIEW_BASE_BRANCH`, `PROTECTED_BRANCHES`). Un placeholder resté tel quel y vaut « défaut » (`develop` / `develop main`), jamais une valeur cassée.

## Étape 3 — Câbler les hooks

`settings.local.json` n'est pas modifié par l'update. Ajoute le bloc `hooks` de `templates/claude/settings.template.json` (du kit) dans `.claude/settings.local.json`, ou mieux dans `.claude/settings.json` versionné pour que toute l'équipe ait la porte :

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "timeout": 15, "command": "if [ -x \"$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh\" ]; then exec \"$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh\"; fi" },
        { "type": "command", "timeout": 15, "command": "if [ -x \"$CLAUDE_PROJECT_DIR/.claude/hooks/push-target-guard.sh\" ]; then exec \"$CLAUDE_PROJECT_DIR/.claude/hooks/push-target-guard.sh\"; fi" }
      ]
    }
  ]
}
```

Recopie la version exacte depuis `templates/claude/settings.template.json` si elle diffère de cet extrait : c'est elle qui fait foi.

Puis :

```bash
chmod +x .claude/hooks/*.sh
for t in .claude/hooks/*.test.sh; do bash "$t"; done
echo ".claude/reviews/" >> .gitignore
```

Adapte `.claude/hooks/e2e-sensitive.txt` (chemins qui déclenchent le smoke E2E) et, au besoin, `REVIEW_SENSITIVE_RE` dans `config.sh` (chemins qui imposent le palier de review `complet`) à tes vrais dossiers.

## Étape 4 — Docs projet (optionnel)

`docs/EQUIPES-LLM.md` et ton `CLAUDE.md` ne sont pas écrasés. Pour profiter des nouvelles règles :

- reprendre les tableaux « agents de mécanique » et « skills tech » de `templates/docs/EQUIPES-LLM.template.md` ;
- comparer ton `CLAUDE.md` avec `templates/CLAUDE.md.template` (sections « Quelle voie », « Porte de review », « Discipline de développement », « Restitution »).

## Ce qui change dans l'usage

- Petit sujet → `/dev-express` ; bug S → `/fix-bug` ; feature → `/call-tech-lead`.
- Avant chaque commit applicatif → `/verify`.
- `/ship-pr` lance lui-même `/review-pr` : plus besoin de le lancer à la main. Un push sans rapport de review pour le commit HEAD est bloqué par la porte.
- Bypass de la porte : `SKIP-review-pr` dans le body du commit, **uniquement sur instruction humaine**.
- Fin de session en worktree → `/close-session`.

## FAQ

**La porte bloque mon push alors que j'ai lancé `/review-pr`.** Le rapport est lié au SHA : tout nouveau commit (même une correction de review) demande une nouvelle review. Relancer `/review-pr` sur HEAD.

**Je ne veux pas des hooks.** Ne câble pas l'étape 3 : les skills fonctionnent sans, la porte n'est alors qu'une consigne.

**J'utilise Codex.** Codex n'a pas de hook automatique : les scripts sont dans `.codex/hooks/` et `AGENTS.md` demande de lancer `review-gate.sh` et `push-target-guard.sh` à la main avant le push. La porte y est une discipline, pas un blocage.
