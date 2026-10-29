# Changelog

Toutes les évolutions notables du kit.

Format basé sur [Keep a Changelog](https://keepachangelog.com/). Versionning [SemVer](https://semver.org/).

---

## [0.5.0] — 2026-10-29

Cette release porte dans le kit public cinq mois de rodage sur un projet privé en production : une voie courte pour les petits sujets, une porte de review mécanique avant chaque push, une review en pipeline chercheurs / vérificateurs, et un `call-tech-lead` découpé en tranches portées chacune par un contexte frais.

### Added

- **7 skills** (+ commandes slash) :
  - `dev-express` — voie courte pour un sujet de taille S (bug, dette, tâche, outillage) : mêmes garde-fous, sans US ni rounds ; section « Éligibilité » qui renvoie à `/call-tech-lead` au moindre signal lourd.
  - `fix-bug` — profil bug de `dev-express` : cause racine d'abord, test de reproduction rouge avant le fix, **preuve inversée mécanique** (`fix-proof.sh`), angle « altitude » en review, audit des E2E du parcours (pourquoi étaient-ils verts ?).
  - `verify` — checklist 8 points avant chaque commit applicatif, trace `/verify : N/8 ✓` dans le body du commit.
  - `pre-mortem` — pensée adversaire sur un diff sensible (path-gating configurable), 5-10 edge cases à transformer en tests.
  - `close-session` — clôture d'une session en worktree : supprime worktree et branche seulement si mergée et clean, verdict « session clean » ou liste des restes.
  - `audit-memory` — audit du dossier mémoire Claude Code (doublons, orphelins, obsolètes, budget de `MEMORY.md`), sans action destructive.
  - `integre-design` — maquette validée → code propre qui réutilise le design system sans dupliquer.
- **Fichiers partagés** `skills/_partage/` : `fil-de-progression.md` (plan de route, lignes `▶/✓ Étape N/M`, blocs `🟥/🟧 À TOI`, restitution sans jargon, demande de validation) et `test-manuel-local.md` (l'agent joue lui-même le parcours dans un vrai navigateur).
- **5 agents** : `full-stack-worker` (une tranche = un worker frais), `review-finder` et `review-verifier` (pipeline de review), `pre-mortem-adversaire`, `integrateur`.
- **Hooks Claude Code** `templates/claude/hooks/` (câblés dans `settings.template.json`) :
  - `review-gate.sh` — bloque `git push` / `gh pr create` sans rapport `.claude/reviews/<sha HEAD>.md` au palier calculé ; sur `fix/*`, exige aussi la preuve inversée. Bypass : une ligne `SKIP-review-pr: <raison>` dans le body du commit, sur instruction humaine. Reconnaît les formes usuelles de push (`cd … && git push`, `bash -c`, `git -c …`) ; refuse un commit et un push dans le même appel.
  - `review-level.sh` — palier de review depuis le diff : `docs` (1 chercheur), `leger` (5), `complet` (8).
  - `push-target-guard.sh` — refuse un push direct sur les branches protégées.
  - `e2e-level.sh` + `e2e-sensitive.txt` — niveau d'E2E avant PR (`aucun` / `specs` / `smoke`), calculé, jamais jugé ; le nightly fait foi.
  - `fix-proof.sh` — rejoue le test sans le fix dans un worktree temporaire (l'arbre réel n'est jamais touché).
  - `config.sh` — branches de base et protégées (placeholders remplis par `/setup-project`) ; auto-tests `*.test.sh`.
- Adapter Codex : les mêmes scripts dans `.codex/hooks/` (lancés par les skills, Codex n'ayant pas de hook automatique) ; fichiers d'appui des skills et `_partage/` désormais générés.
- `MIGRATION-v0.5.md`, manifest `scripts/manifests/v0.5.0.json`.

### Changed

- **`call-tech-lead`** refondu : `SKILL.md` court + `phases.md`, `rounds.md`, `transcript-format.md`. Intake qui bascule vers `/dev-express` pour un sujet S, découpe en tranches, un worker frais par tranche, review (`/review-pr`) et PR jouées par l'orchestrateur, Tn+1 seulement après merge de Tn. `--depth` et round 2 facultatif conservés.
- **`review-pr`** refondu en pipeline : palier calculé, chercheurs indépendants par angle (`angles.md`), un vérificateur par candidat (CONFIRMÉ / PLAUSIBLE / RÉFUTÉ, ligne citée), ≤ 10 findings détaillés, rapport 🔴/🟠/🟢 qui sert de preuve à la porte.
- **`ship-pr`** : E2E au niveau calculé joué en parallèle de `/review-pr` sur le commit qui part, zéro dette (🔴 et 🟠 bloquent, corrections sans question), trace `/verify` exigée, PR vers `{{GIT_DEFAULT_BRANCH}}` (plus de `develop` en dur).
- `investigate-bug` (règle des 3 tentatives, comparaison avec l'analogue qui marche, diagnostic validé dans le chat), `qa-flow`, `retro`, `redige-us` (tranches priorisées, tranche 1 = MVP), `fullstack-lead-tech` (matrice de traçabilité critère → lot → test, découpe par tranche), `setup-project` (hooks, nouveaux agents).
- Agents `full-stack-lead`, `po-metier`, `qa`, `designer-uxui`, `cso`, `data-engineer`, `ai-llm-engineer` : règles génériques éprouvées (TDD sanctionné, mode worker, niveaux E2E…).
- `CLAUDE.md.template` : quelle voie choisir, porte de review, discipline TDD (qualité du RED, sanction), recevoir une review sans acquiescement réflexe, test manuel local, restitution en 5 questions, fil de progression, « une PR = un contexte frais ».
- `scripts/generate-codex-templates.mjs` : ne régénère plus `AGENTS.md` (maintenu à la main depuis la v0.4.0), réécriture des commandes slash robuste aux chemins (`.claude/skills/verify/` n'est plus touché).
- `scripts/validate-templates.mjs` : 18 agents / 23 skills, une commande par skill, hooks exécutables et syntaxe bash valide.
- `install.mjs` : `.claude/reviews/` et `.codex/reviews/` ajoutés au `.gitignore`.

### Migration depuis 0.4.0

`node scripts/update.mjs --target <projet>` puis `--apply` : voir `MIGRATION-v0.5.md`.

---

## [0.4.0] — 2026-05-13

Cette release porte dans le kit publique les optimisations tokens éprouvées sur un projet privé en production. Elle introduit aussi un mécanisme d'update pour patcher les projets déjà installés en v0.3.0 sans écraser le travail utilisateur.

### Added

- **`CLAUDE.md` template à la racine du projet cible** (opt-in à l'install) :
  - Section **Token efficiency** — principe "raisonnement profond, output court", zéro phrase transitoire avant tool call, bullets ultra-courtes, lecture ciblée obligatoire (`ripgrep` puis `Read` avec offset/limit), override sécurité/data loss/breaking/RGPD.
  - Section **Compaction et survie contextuelle** — seuil 80% via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80`, hiérarchie 🔴/🟡/🟢, procédure post-compaction.
  - Section **Délégation aux skills** — interdiction de l'injection inline (> 100 lignes), Read par chemin absolu, gain quantifié 14-35 k tokens par run multi-agents.
  - Fichier : `templates/CLAUDE.md.template`.
- **Script `npm run update`** (`scripts/update.mjs`) :
  - Met à jour un projet déjà installé sans toucher au contenu utilisateur (`docs/GUIDE-LLM.md`, `.claude/settings.local.json`, `backlog.md`, etc.).
  - Détecte les fichiers customisés via SHA-256 manifests (`scripts/manifests/v0.X.Y.json`).
  - Dry-run par défaut. `--apply` pour écrire. `--conflicts backup|skip|abort` pour les customisés.
  - Génère `virtual-staff-update-report.md` à la racine cible.
- **Prompt fallback `templates/update-prompt.md`** pour mettre à jour sans avoir le kit cloné en local.
- **Script `npm run generate:manifest`** (`scripts/generate-manifest.mjs`) :
  - Génère un manifest SHA-256 des fichiers kit-managed pour une version donnée.
  - Supporte `--from-git <ref>` pour calculer le manifest d'une version passée.
- **Manifests** : `scripts/manifests/v0.3.0.json` et `scripts/manifests/v0.4.0.json`.
- **Marqueurs version** en tête des fichiers root du kit : `<!-- virtual-staff-kit:<name> v<X.Y.Z> -->` sur `CLAUDE.md` et `AGENTS.md` (permet la détection lors de l'update).
- **`MIGRATION-v0.4.md`** : guide pas-à-pas pour passer de v0.3.0 à v0.4.0 (3 chemins : script, prompt, manuel).

### Changed

- **`scripts/install.mjs`** : nouvelle question opt-in `"Installer aussi CLAUDE.md de référence à la racine ?"` (flags non-interactifs `--with-root-claudemd` / `--no-root-claudemd`).
- **`templates/codex/AGENTS.md`** : ajout du marqueur version + sections Token efficiency, Délégation et Compaction (équivalent du `CLAUDE.md`, adapté vocabulaire Codex).
- **`OPTIMISATION-TOKENS.md`** : nouvelles sections `Patterns D'Output`, `Lecture Ciblée`, `Délégation Aux Skills`, `Compaction Et Survie Contextuelle`. Les sections depth/routing/modèles existantes sont préservées.
- **`scripts/validate-templates.mjs`** : nouvelles assertions sur la présence du marqueur version et du manifest correspondant à la version courante.
- **`package.json`** : version bumpée à `0.4.0`, nouveaux scripts `update` et `generate:manifest`, nouveau bin `virtual-staff-update`.

### Migration depuis 0.3.0

Trois chemins documentés dans `MIGRATION-v0.4.md` :

1. **Script (recommandé)** — depuis le kit cloné mis à jour :
   ```bash
   git pull                                                                 # récupérer v0.4.0
   node scripts/update.mjs --target /chemin/vers/ton/projet                 # dry-run
   node scripts/update.mjs --target /chemin/vers/ton/projet --apply         # exécute
   ```
2. **Prompt à coller** — si tu n'as pas le kit cloné : `templates/update-prompt.md` (cf. CHANGELOG entry).
3. **Manuel** — copier à la main les fichiers depuis `templates/` vers ton projet.

Le `CLAUDE.md` racine n'est PAS ajouté automatiquement par l'update (opt-in à l'install fresh uniquement). Pour l'ajouter à un projet existant, copier `templates/CLAUDE.md.template` → `<projet>/CLAUDE.md`.

---

## [0.3.0] — 2026-04-28

### Added
- Adapter **OpenAI Codex** complet dans `templates/codex/` :
  - 16 skills Codex dans `.agents/skills/`.
  - 13 agents Codex en TOML dans `.codex/agents/`.
  - `AGENTS.md` pour les règles transverses Codex.
- Générateur `scripts/generate-codex-templates.mjs` pour produire l'adapter Codex depuis les sources Claude.
- Validateur `scripts/validate-templates.mjs` pour contrôler les comptages, frontmatter, modèles et reliquats provider.
- Installateur `npm run setup` via `scripts/install.mjs` :
  - choix du projet cible ;
  - provider `codex`, `claude` ou `both` ;
  - stratégie de conflit `backup`, `abort` ou `overwrite` ;
  - génération de `virtual-staff-install-report.md` et `virtual-staff-ai-setup.md`.
- Documentation de portage `PORTAGE-CODEX.md`.
- Guide `OPTIMISATION-TOKENS.md` pour routing, depth, modèles et sobriété tokens.

### Changed
- README réorganisé autour d'un seul chemin recommandé : `npm run setup` puis `/setup-project --ai` ou `$setup-project --ai`.
- `setup-project` passe en mode **AI-assisted** par défaut : inspection du repo, inférence de la stack, questions limitées aux informations bloquantes.
- Les orchestrateurs `call-tech-lead` et `call-growth-lead` acceptent maintenant `--depth=lean|standard|full`.
- Le round 2 devient facultatif : aucun agent n'est relancé s'il n'y a pas de friction actionnable.
- Routing plus sobre : plafonds d'agents selon `depth` et documentation des agents exclus.
- Documentation équilibrée des modèles Claude et Codex :
  - Claude : familles `Opus` / `Sonnet`.
  - Codex : `gpt-5.3-codex`, `gpt-5.4-mini`, `gpt-5.5` avec effort adapté au rôle.
- `docs/COUTS-LLM.template.md` devient provider-agnostic et documente les profils de profondeur.

### Documentation
- Ajout d'un disclaimer tokens : les runs multi-agents peuvent consommer vite, surtout avec les gros modèles et `--depth=full`.
- Recommandation explicite d'utiliser `retro` après les runs importants pour améliorer le routing, réduire les prompts et capitaliser dans `docs/GUIDE-LLM.md`.
- Mention de **Claude Code Usage Monitor** (`monitor-ccu`) pour monitorer gratuitement les sessions, modèles, sous-agents, tokens et coûts Claude Code : https://github.com/tiber76/monitor-ccu.
- Note Claude Code : rouvrir Claude Code si les slash commands nouvellement copiées n'apparaissent pas.

### Fixed
- Correction de références croisées vers `call-growth-lead` qui pointaient vers un agent au lieu du skill.
- Correction des chemins générés Codex (`.codex/runs/<skill>/`, `.agents/skills/<skill>/SKILL.md`, agents `.toml`).
- Mise à jour des comptages `15 skills` vers `16 skills`.

---

## [0.2.0] — 2026-04-21

### Changed (breaking)
- Renommage des 2 skills orchestrateurs et du skill plan technique pour lever l'ambiguïté `/tech-lead` vs `/lead-tech` :
  - `/tech-lead` → `/call-tech-lead` (orchestrateur équipe tech)
  - `/growth-lead` → `/call-growth-lead` (orchestrateur équipe growth)
  - `/lead-tech` → `/fullstack-lead-tech` (plan technique détaillé)
- Dossiers `.claude/skills/*/` renommés via `git mv` (historique préservé).
- Fichiers `.claude/commands/*.md` renommés en conséquence.
- Toutes les références croisées mises à jour (agents, docs méta, templates).

### Added
- Commande `.claude/commands/setup-project.md` pour bénéficier de l'autocomplétion `/setup-project` dans Claude Code (la commande manquait en v0.1.0, seul le skill existait).
- Section "Autocomplétion automatique" dans `ARCHITECTURE.md` : explique que Claude Code scan `.claude/commands/*.md` automatiquement, sans config supplémentaire.
- Section enrichie dans `CHECKLIST-KICKOFF.md` Phase 6 : comment créer une nouvelle commande après le setup + règle "1 skill = 1 commande".

### Migration depuis 0.1.0
Si ton projet utilise v0.1.0, remplace dans tes invocations et tes doc internes :
- `/tech-lead` → `/call-tech-lead`
- `/growth-lead` → `/call-growth-lead`
- `/lead-tech` → `/fullstack-lead-tech`

L'agent `growth-lead` (rôle PO growth) reste inchangé — seul le skill a été renommé.

---

## [0.1.0] — 2026-04-21

### Added
- 13 agents portables (équipe tech + équipe growth) avec placeholders et blocs conditionnels.
- 16 skills (2 orchestrateurs `/tech-lead` et `/growth-lead`, 7 skills tech, 5 skills growth, `/retro`, `/setup-project`).
- Squelette `docs/GUIDE-LLM.template.md` avec 12 sections à remplir.
- Squelette `docs/EQUIPES-LLM.template.md` et `docs/COUTS-LLM.template.md`.
- 4 formats de livrables (`US`, `PLAN`, `BRIEF`, `RETRO`).
- Skill `/setup-project` qui remplit tous les placeholders via un questionnaire interactif (~30 questions en 6 vagues).
- Documentation méta complète : `README.md`, `CHECKLIST-KICKOFF.md`, `GUIDE-ADAPTATION.md`, `ARCHITECTURE.md`, `PATTERNS.md`, `REGLES-TRANSVERSES.md`, `PLACEHOLDERS.md`.
- Support de 3 syntaxes de blocs conditionnels : `{{#IF FLAG}}`, `{{#IF !FLAG}}`, `{{#IF FLAG}}...{{#ELSE}}...{{/IF}}`.
- 7 flags dérivés calculés automatiquement par `/setup-project` (`HAS_MIGRATIONS`, `BUSINESS_MODEL_TRIAL`, etc.).

### Testé en production
Ce kit est extrait d'un système utilisé en production sur un SaaS B2B pendant plusieurs mois avant publication. Il a été dépouillé de tout contexte spécifique pour être utilisable sur n'importe quel projet.

---

## Conventions de version

- **MAJOR** : changement cassant dans la structure des agents/skills (ex: format frontmatter change, placeholders renommés).
- **MINOR** : nouvel agent, nouveau skill, nouvelle section dans le GUIDE-LLM template.
- **PATCH** : corrections de bug, typos, améliorations doc non structurantes.
