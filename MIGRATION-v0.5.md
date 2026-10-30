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

Ou à la main : `grep -rn "{{" .claude/ | grep -v "{{#IF" | grep -v "{{/IF}}"` puis remplacer avec les valeurs déjà posées dans tes autres fichiers (branche de base, commandes de test, dossiers). Le plus important : `.claude/hooks/config.sh` (`REVIEW_BASE_BRANCH`, `PROTECTED_BRANCHES`, `FIX_BRANCH_PREFIX`, `E2E_DIR`). Un placeholder resté tel quel y vaut « non réglé » : la base devient `origin/develop` si elle existe, sinon la branche par défaut du remote ; les branches protégées, la base plus `develop main master`.

## Étape 3 — Câbler les hooks

`settings.local.json` n'est pas modifié par l'update. Ajoute le bloc `hooks` de `templates/claude/settings.template.json` (du kit) dans `.claude/settings.local.json`, ou mieux dans `.claude/settings.json` versionné pour que toute l'équipe ait la porte :

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "timeout": 15,
          "command": "if [ -x \"$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh\" ]; then exec \"$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh\"; fi; if grep -qE '(git|gh)[^\"]*(push|pr create)'; then echo \"🛑 hook review-gate.sh absent ou non exécutable (chmod +x .claude/hooks/*.sh .claude/hooks/pre-push) : push refusé\" >&2; exit 2; fi"
        }
      ]
    }
  ]
}
```

Recopie la version exacte depuis `templates/claude/settings.template.json` si elle diffère de cet extrait : c'est elle qui fait foi. Si le hook manque ou perd son bit exécutable, ce câblage refuse les push (message « hook … absent ou non exécutable ») au lieu de laisser passer en silence.

Ce hook Claude Code ne juge pas les push lui-même : c'est le **hook git `pre-push`** qui le fait, sur ce que git envoie réellement. Le hook Claude empêche l'agent de le désactiver (`--no-verify`, `core.hooksPath`), refuse un push tant que le hook git n'est pas branché, et juge HEAD avant `gh pr create`.

Prérequis : `bash` et `jq`. Sans `jq`, le hook Claude ferme la porte sur toute commande qui ressemble à un push.

Puis :

```bash
chmod +x .claude/hooks/*.sh .claude/hooks/pre-push
bash .claude/hooks/install-git-hooks.sh
for t in .claude/hooks/*.test.sh; do bash "$t"; done
echo ".claude/reviews/" >> .gitignore
```

`install-git-hooks.sh` pose `.git/hooks/pre-push` (partagé par les worktrees) ; une fois par clone. Si un hook `pre-push` existe déjà ou si `core.hooksPath` est réglé (husky…), il ne touche à rien et affiche la ligne à ajouter au hook existant. `bash .claude/hooks/install-git-hooks.sh --status` dit s'il est branché.

Adapte `.claude/hooks/e2e-sensitive.txt` (chemins qui déclenchent le smoke E2E) et, au besoin, `REVIEW_SENSITIVE_RE` dans `config.sh` (chemins qui imposent le palier de review `complet`) à tes vrais dossiers.

## Étape 4 — Docs projet (optionnel)

`docs/EQUIPES-LLM.md` n'est jamais touché par l'update. `CLAUDE.md` l'est : s'il a été personnalisé (ce qui est le cas après `/setup-project`), l'update le classe « customisé » et, avec `--conflicts backup`, le remplace par le template brut en gardant une copie `.backup-…`. Pour le garder tel quel, relancer avec `--conflicts skip`, ou récupérer ta version depuis la copie. Pour profiter des nouvelles règles :

- reprendre les tableaux « agents de mécanique » et « skills tech » de `templates/docs/EQUIPES-LLM.template.md` ;
- comparer ton `CLAUDE.md` avec `templates/CLAUDE.md.template` (sections « Quelle voie », « Porte de review », « Discipline de développement », « Restitution »).

## Ce qui change dans l'usage

- Petit sujet → `/dev-express` ; bug S → `/fix-bug` ; feature → `/call-tech-lead`.
- Avant chaque commit applicatif → `/verify`.
- `/ship-pr` lance lui-même `/review-pr` : plus besoin de le lancer à la main. Un push d'une branche dont le commit poussé n'a pas de rapport de review est refusé par git (hook `pre-push`).
- Bypass de la porte : une ligne `SKIP-review-pr: <raison>` en début de ligne dans le body du commit, **uniquement sur instruction humaine**. Une phrase qui cite la convention ne déclenche rien.
- `git push --no-verify` saute le hook : interdit à l'agent ; un humain qui le tape assume le contournement.
- Fin de session en worktree → `/close-session`.

## FAQ

**La porte bloque mon push alors que j'ai lancé `/review-pr`.** Le rapport est lié au SHA : tout nouveau commit (même une correction de review) demande une nouvelle review. Relancer `/review-pr` sur HEAD.

**Je ne veux pas des hooks.** Ne câble pas l'étape 3 et retire `.git/hooks/pre-push` : les skills fonctionnent sans, la porte n'est alors qu'une consigne.

**J'utilise Codex.** Le contrôle des push est un hook git : il s'applique à Codex comme à Claude Code. Les scripts sont dans `.codex/hooks/` ; brancher le hook avec `bash .codex/hooks/install-git-hooks.sh`. Seule différence : Codex n'a pas d'équivalent du hook PreToolUse, donc rien n'y empêche l'agent de taper `--no-verify` — `AGENTS.md` le lui interdit.
