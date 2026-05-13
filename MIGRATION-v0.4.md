# Migration v0.3.0 → v0.4.0

La v0.4.0 ajoute des **optimisations tokens** (output court, lecture ciblée, survie post-compaction, délégation sans injection inline) et un **mécanisme d'update** pour les projets déjà installés.

**Aucun breaking change** : tous les agents et skills existants restent compatibles. Seuls des fichiers s'ajoutent ou se mettent à jour.

## Quoi de neuf concrètement

- Un `CLAUDE.md` template (opt-in) à installer à la racine du projet cible — il code les règles d'output et de compaction directement dans le préambule chargé par Claude Code.
- Un `AGENTS.md` (racine, Codex) enrichi des mêmes sections, adapté au vocabulaire Codex.
- Un fichier `OPTIMISATION-TOKENS.md` enrichi de 4 sections (`Patterns D'Output`, `Lecture Ciblée`, `Délégation Aux Skills`, `Compaction Et Survie Contextuelle`).
- Des **marqueurs de version** `<!-- virtual-staff-kit:NAME v0.4.0 -->` en tête des fichiers gérés par le kit, pour permettre les updates futurs sans écraser le custom.

## Trois chemins pour mettre à jour ton projet

### Chemin 1 — Script (recommandé)

Si tu as cloné le kit en local, c'est le plus sûr et le plus rapide.

```bash
# 1. Mets à jour ton clone du kit
cd /chemin/vers/ClaudeCode_AI_Virtual_Staff
git pull            # ou git fetch && git checkout v0.4.0 si tu utilises les tags

# 2. Dry-run sur ton projet (rien n'est écrit, juste le plan)
node scripts/update.mjs --target /chemin/vers/ton/projet

# 3. Si le plan te convient, applique
node scripts/update.mjs --target /chemin/vers/ton/projet --apply
```

Le script :

- Détecte automatiquement la version source de ton projet (en comparant les SHA-256 aux manifests v0.3.0 et v0.4.0).
- Classe chaque fichier comme `current` / `missing` / `outdated` / `customized`.
- Ne touche **JAMAIS** : `docs/GUIDE-LLM.md`, `docs/EQUIPES-LLM.md`, `docs/COUTS-LLM.md`, `.claude/settings.local.json`, `backlog.md`, et tout fichier hors du manifest.
- Backup systématique en `.backup-YYYYMMDD-HHMMSS` avant d'écraser un fichier outdated.
- Sur un fichier `customized` (modifié par toi ailleurs qu'à l'install), prompt interactif `[s]kip / [b]ackup+replace / [a]bort`.

Options utiles :

```bash
# Mode non-interactif : skip systématique des fichiers customisés
node scripts/update.mjs --target ... --apply --conflicts skip

# Mode non-interactif : backup+replace même les customisés
node scripts/update.mjs --target ... --apply --conflicts backup

# Forcer la version source (skip la détection)
node scripts/update.mjs --target ... --apply --from 0.3.0
```

À la fin, un rapport est écrit dans `<projet>/virtual-staff-update-report.md`.

### Chemin 2 — Prompt à coller (pas de kit cloné)

Si tu n'as pas le kit cloné en local mais tu veux récupérer les updates :

1. Ouvre Claude Code ou Codex à la racine de ton projet.
2. Ouvre `templates/update-prompt.md` (dans ce repo) et copie le bloc encadré.
3. Remplace `{{KIT_REPO}}` par `<owner>/ClaudeCode_AI_Virtual_Staff` (le fork qui contient v0.4.0) et `{{KIT_VERSION}}` par `0.4.0`.
4. Colle-le dans Claude Code / Codex et valide chaque étape.

Cette méthode est moins déterministe (l'AI peut faire des erreurs de diff). À privilégier seulement si le chemin 1 n'est pas accessible.

### Chemin 3 — Manuel

Pour les éléments individuels qui t'intéressent :

| Pour ajouter... | Copier depuis le kit |
|---|---|
| Le `CLAUDE.md` racine | `templates/CLAUDE.md.template` → `<projet>/CLAUDE.md` |
| L'`AGENTS.md` enrichi | `templates/codex/AGENTS.md` → `<projet>/AGENTS.md` (écrase l'ancien si présent) |
| Les nouvelles sections de doc | `OPTIMISATION-TOKENS.md` (à la racine du kit, pas à copier dans ton projet — c'est de la doc kit) |
| Un agent / skill mis à jour | `templates/claude/agents/<x>.md` → `<projet>/.claude/agents/<x>.md` |

## Ce que le `CLAUDE.md` apporte concrètement

Sans `CLAUDE.md` à la racine de ton projet, Claude Code charge uniquement ses instructions globales + tes consignes au runtime. Le `CLAUDE.md` v0.4.0 ajoute **systématiquement à chaque session** :

1. La règle "raisonnement profond, output court" — réduit les phrases transitoires et préambules de 5-15% en moyenne sur les outputs.
2. La règle "lecture ciblée" — force `ripgrep` + `Read` offset/limit avant tout `Read` plein de fichier > 100 lignes.
3. La règle "délégation sans injection inline" — économise 14-35 k tokens par run multi-agents quand l'orchestrateur délègue un document long.
4. La procédure post-compaction — évite de perdre la branche / le commit en cours / les verdicts agents quand la conversation est compactée.

**À noter** : ces règles ont un **override sécurité** : elles s'effacent dès qu'un sujet touche sécurité, data loss, breaking change, RGPD, migration prod, paiement, PII. Le coût tokens passe au second plan sur ces sujets.

## Vérifier que la migration s'est bien passée

Après `--apply` :

```bash
cd /chemin/vers/ton/projet

# 1. Le rapport doit lister les fichiers mis à jour
cat virtual-staff-update-report.md

# 2. Les marqueurs doivent être présents
grep -l "virtual-staff-kit:.* v0.4.0" CLAUDE.md AGENTS.md 2>/dev/null

# 3. Tes fichiers user n'ont pas bougé
git diff -- docs/GUIDE-LLM.md docs/EQUIPES-LLM.md docs/COUTS-LLM.md .claude/settings.local.json backlog.md
# (doit être vide si tu avais commité avant)

# 4. Les backups sont là si tu veux annuler
ls -la .claude/**/*.backup-* 2>/dev/null
ls -la *.backup-* 2>/dev/null
```

## Rollback

Si l'update a touché un fichier que tu voulais garder :

```bash
mv chemin/du/fichier.backup-YYYYMMDD-HHMMSS chemin/du/fichier
```

Tous les backups sont datés au moment de l'update, donc tu peux les identifier facilement.

## Questions fréquentes

**Q : Mon `CLAUDE.md` existe déjà (j'en ai créé un à la main), que se passe-t-il ?**
R : Sans marqueur kit, le script ne touche pas le fichier. Tu peux merger manuellement en t'inspirant de `templates/CLAUDE.md.template`. Si tu veux écraser, copie-le à la main (chemin 3).

**Q : J'ai customisé l'agent `qa.md`, l'update va l'écraser ?**
R : Non. Le script détecte le hash, voit qu'il ne matche ni v0.3.0 ni v0.4.0, et te demande quoi faire (skip par défaut, backup+replace si tu acceptes).

**Q : Comment générer le manifest pour une nouvelle version du kit ?**
R : `node scripts/generate-manifest.mjs --version X.Y.Z` (depuis le repo du kit, après avoir mis à jour les templates). Pour les versions passées : `--from-git <commit-sha>`.
