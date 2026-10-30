# Starter Kit — Equipes Virtuelles Claude Code & OpenAI Codex

Ce depot installe dans un projet une equipe virtuelle d'agents : produit, tech, design, QA, securite, data, IA, growth, sales et contenu.

Le kit fonctionne avec deux outils :

| Outil | Invocation | Fichiers installes |
|---|---|---|
| Claude Code | `/setup-project --ai`, `/call-tech-lead ...` | `.claude/agents`, `.claude/skills`, `.claude/commands` |
| OpenAI Codex | `$setup-project --ai`, `$call-tech-lead ...` | `.agents/skills`, `.codex/agents`, `AGENTS.md` |

Le fonctionnement reste le meme dans les deux cas : un orchestrateur comprend le besoin, choisit les agents utiles, collecte des avis independants, arbitre les frictions, implemente ou produit les livrables, verifie, puis documente le run dans un `TRANSCRIPT.md`.

## Disclaimer Tokens

Une equipe virtuelle multi-agents peut consommer beaucoup de tokens, surtout avec les gros modeles et les runs `--depth=full`. Commence petit, surveille les couts de ton fournisseur, et evite de convoquer toute l'equipe pour des sujets simples.

Le kit est fait pour s'ameliorer avec l'usage : lance `retro` apres les runs importants pour capitaliser ce qui marche, supprimer les agents rarement utiles, ajuster le routing et adapter les pratiques aux vrais besoins du projet.

Pour Claude Code, tu peux aussi monitorer gratuitement les sessions et sous-agents avec **Claude Code Usage Monitor** : https://github.com/tiber76/monitor-ccu. L'outil lit les fichiers locaux `~/.claude/projects/`, affiche les couts/tokens par session, les modeles utilises et le detail des sous-agents, sans API key ni service externe.

## Installation Recommandee

Le chemin normal est unique : **on clone, on lance `npm run setup`, puis l'AI configure le projet cible**.

### 1. Lancer l'installateur

Depuis ce depot clone :

```bash
npm run setup
```

Le script pose 4 questions :

| Question | Exemple |
|---|---|
| Projet cible | `/Users/me/repos/mon-projet` |
| Outil a installer | `codex`, `claude` ou `both` |
| Si un fichier existe deja | `backup`, `abort` ou `overwrite` |
| Installer aussi `CLAUDE.md` racine (token efficiency, compaction) | `y` / `n` (par defaut `n`) |

La 4eme question n'apparait que si tu installes l'adapter Claude. Le `CLAUDE.md` racine est un preambule auto-charge par Claude Code qui inscrit les regles d'output court, de lecture ciblee et de survie post-compaction. Si ton projet a deja un `CLAUDE.md`, garde-le et reponds `n` ; tu pourras t'inspirer de `templates/CLAUDE.md.template` manuellement.

Le script copie les bons fichiers, renomme les templates, met a jour `.gitignore`, puis cree :

- `virtual-staff-install-report.md` : rapport de copie.
- `virtual-staff-ai-setup.md` : prompt pret a coller si besoin.

### 2. Ouvrir le projet cible

Ouvre ensuite **le projet cible**, pas ce depot starter kit.

```text
Claude Code : /setup-project --ai
OpenAI Codex : $setup-project --ai
```

Note Claude Code : les commandes slash sont chargees depuis `.claude/commands/`. Si `/setup-project` n'apparait pas, ferme puis rouvre Claude Code a la racine du projet cible.

### 3. Laisser l'AI adapter le kit

`setup-project --ai` inspecte le repo cible, infere la stack, les commandes, les entites metier, les risques et les agents utiles. Il affiche une synthese puis pose seulement les questions bloquantes.

### 4. Faire un premier run court

```text
Claude Code : /call-tech-lead "Ajoute une petite feature test" --depth=lean --mode=semi
OpenAI Codex : $call-tech-lead "Ajoute une petite feature test" --depth=lean --mode=semi
```

`--depth=lean` evite de convoquer trop d'agents pour le premier essai.

## Mettre A Jour Un Projet Deja Installe

Si tu as installe le kit dans un projet avec une version anterieure (v0.3.0 ou v0.4.0), tu peux recuperer les ajouts de la derniere version sans reinstaller.

### Methode recommandee : script

Depuis le repo du kit clone et mis a jour :

```bash
# 1. Mets a jour ton clone du kit
git pull

# 2. Dry-run : affiche le plan, rien n'est ecrit
node scripts/update.mjs --target /chemin/vers/ton/projet

# 3. Applique si le plan te convient
node scripts/update.mjs --target /chemin/vers/ton/projet --apply
```

Le script :

- Detecte automatiquement la version source de ton projet (SHA-256 manifests).
- Ne touche **jamais** : `docs/GUIDE-LLM.md`, `docs/EQUIPES-LLM.md`, `docs/COUTS-LLM.md`, `.claude/settings.local.json`, `backlog.md`.
- Backup systematique en `.backup-YYYYMMDD-HHMMSS` avant ecrasement.
- Sur un fichier customise, demande `[s]kip / [b]ackup+replace / [a]bort` (ou applique `--conflicts backup|skip|abort` en non-interactif).
- Ecrit un rapport `virtual-staff-update-report.md` a la racine du projet cible.

### Methode alternative : prompt a coller

Si tu n'as pas le kit clone en local, copie le prompt dans `templates/update-prompt.md` et colle-le dans Claude Code ou Codex ouvert a la racine de ton projet. L'AI va recuperer le manifest publie sur GitHub et patcher fichier par fichier.

Cette methode est moins deterministe que le script — privilegie le script si possible.

### Detail

Voir `MIGRATION-v0.5.md` (et `MIGRATION-v0.4.md` depuis la v0.3.0) pour le guide pas-a-pas, les options du script, et les questions frequentes.

## Quel Outil Choisir ?

| Besoin | Choix conseille |
|---|---|
| Tu travailles deja dans Claude Code | `claude` |
| Tu veux utiliser Codex / OpenAI | `codex` |
| Tu veux tester les deux adapters | `both` |
| Tu maintiens ce starter kit | modifier `templates/claude/`, puis regenerer `templates/codex/` |

## Ce Que Le Kit Installe

### Agents

18 agents specialises :

- Tech : `po-metier`, `full-stack-lead`, `designer-uxui`, `integrateur`, `qa`, `cso`, `data-engineer`, `ai-llm-engineer`.
- Mecanique : `full-stack-worker` (une tranche = un worker frais), `review-finder` et `review-verifier` (pipeline de review), `pre-mortem-adversaire` (edge cases avant commit).
- Growth : `growth-lead`, `sales-b2b`, `customer-success`, `copywriter-brand`, `content-seo`, `marketing-analytics`.

### Skills

23 skills :

| Famille | Skills |
|---|---|
| Setup | `setup-project` |
| Orchestration | `call-tech-lead`, `call-growth-lead` |
| Voie courte | `dev-express` (sujet de taille S), `fix-bug` (bug S avec preuve inversee) |
| Tech | `redige-us`, `fullstack-lead-tech`, `investigate-bug`, `integre-design`, `review-pr`, `qa-flow`, `verify`, `pre-mortem`, `ship-pr`, `security-audit` |
| Growth | `redige-brief`, `ship-landing`, `audit-funnel`, `brief-demo`, `retro-campagne` |
| Transverse | `retro`, `close-session`, `audit-memory` |

Plus `_partage/` (fil de progression, test manuel local), lus par les skills.

### Hooks (Claude Code)

`.claude/hooks/`. Le controle des push passe par un **hook git `pre-push`** (branche par `install-git-hooks.sh`, lance par `install.mjs`) : git lui donne les commits et les branches qui partent reellement, quelle que soit l'ecriture de la commande, et il vaut pour Claude Code, Codex et un humain au terminal. Le hook Claude Code (`review-gate.sh`, cable dans `settings.local.json`) empeche l'agent de le desactiver et juge HEAD avant `gh pr create`. Prérequis : `bash` et `jq`.

| Hook | Role |
|---|---|
| `pre-push` + `install-git-hooks.sh` | hook git : refuse un push vers une branche protegee ou d'un commit sans rapport `/review-pr` valable |
| `review-gate.sh` | juge un commit (rapport, palier, preuve de fix) ; cote Claude Code, refuse `--no-verify` / `core.hooksPath` et juge HEAD avant `gh pr create` |
| `review-level.sh` | calcule le palier de review depuis le diff : `docs` (1 chercheur), `leger` (5), `complet` (8) |
| `push-target-guard.sh` | lit les references poussees : destination protegee ou non |
| `e2e-level.sh` | niveau d'E2E avant PR depuis le diff : `aucun`, `specs`, `smoke` (jamais juge par l'agent) |
| `fix-proof.sh` | preuve inversee d'un fix : le test echoue sans le fix, passe avec |

Reglages dans `.claude/hooks/config.sh` (branches) et `e2e-sensitive.txt` (chemins sensibles). Bypass de la porte : une ligne `SKIP-review-pr: <raison>` dans le body du commit, sur instruction humaine uniquement. Prerequis : `bash` et `jq`. Cote Codex, les memes scripts sont copies dans `.codex/hooks/` et le meme hook git `pre-push` s'applique.

### Documentation Projet

Le setup installe aussi :

- `docs/GUIDE-LLM.md` : source de verite projet.
- `docs/EQUIPES-LLM.md` : cartographie agents/skills.
- `docs/COUTS-LLM.md` : estimation tokens/couts.
- `backlog.md` : dettes, risques, decisions a reprendre.

## Utilisation Au Quotidien

Pour une feature technique :

```text
/call-tech-lead "..." --depth=standard --mode=semi
$call-tech-lead "..." --depth=standard --mode=semi
```

Pour une initiative growth :

```text
/call-growth-lead "..." --depth=standard --mode=semi
$call-growth-lead "..." --depth=standard --mode=semi
```

Pour un petit sujet (bug, dette, tache de taille S) :

```text
/dev-express "..."      # voie courte, memes garde-fous, sans ceremonie
/fix-bug "..."          # bug S : cause racine, test rouge, preuve inversee
```

Le cycle standard d'un dev : TDD → `/verify` avant chaque commit applicatif → `/ship-pr` (tests, E2E au niveau calcule, `/review-pr` en parallele, zero dette, PR) → merge sur ordre humain → `/close-session`.

Pour une tache courte en orchestration, commence par `--depth=lean`. Pour une decision critique, utilise `--depth=full`.

Apres une feature non triviale, lance une retro :

```text
Claude Code : /retro
OpenAI Codex : $retro
```

La retro sert a mettre a jour les pratiques de l'equipe, le backlog et `docs/GUIDE-LLM.md`.

## Sobriete Tokens Et Modeles

Les orchestrateurs acceptent `--depth=lean|standard|full`.

| Depth | Usage | Effet attendu |
|---|---|---|
| `lean` | petite feature, bug compris, refacto localise | moins d'agents, round 2 rare |
| `standard` | feature produit normale | defaut recommande |
| `full` | auth, paiement, PII, data model, IA, pricing, GTM majeur | qualite prioritaire |

Le round 2 est facultatif : s'il n'y a pas de friction actionnable, aucun agent n'est relance.

Modeles par defaut du kit :

| Famille d'agents | Claude Code | OpenAI Codex |
|---|---|---|
| Architecture, securite critique | Opus (`full-stack-lead`, `cso`) | `gpt-5.3-codex` avec effort `high` |
| Tests, data, IA integree au code | Sonnet | `gpt-5.3-codex` avec effort `medium` |
| Produit, design, contenu, operations | Sonnet | `gpt-5.4-mini` avec effort `medium` |
| Strategie growth / sales | Opus (`growth-lead`, `sales-b2b`) | `gpt-5.5` avec effort `high` |

Ces defaults sont volontairement conservateurs. Ils doivent etre ajustes selon ton abonnement, tes couts reels et la criticite du projet. Detail : `OPTIMISATION-TOKENS.md`.

Conseil pratique : apres 5 a 10 runs, relis les transcripts et lance `retro` pour identifier les agents trop souvent inutiles, les prompts trop longs et les decisions qui devraient etre automatisees ou simplifiees.

Monitoring Claude Code : le projet gratuit `monitor-ccu` peut aider a suivre les couts, les modeles et les sous-agents en temps reel : https://github.com/tiber76/monitor-ccu.

## Options Avancees

### Installation non interactive

Utile en script ou CI :

```bash
npm run setup -- --target /chemin/vers/projet --provider claude --conflicts backup
npm run setup -- --target /chemin/vers/projet --provider codex --conflicts backup
npm run setup -- --target /chemin/vers/projet --provider both --conflicts backup

# Avec ou sans le CLAUDE.md racine
npm run setup -- --target ... --provider claude --conflicts backup --with-root-claudemd
npm run setup -- --target ... --provider claude --conflicts backup --no-root-claudemd
```

### Installation manuelle

La copie manuelle existe seulement comme reference de maintenance dans `templates/README.md`. Pour un utilisateur normal, garde `npm run setup`.

### Maintenance Codex

L'arbre Codex est genere depuis les sources Claude pour eviter deux sources de verite :

```bash
node scripts/generate-codex-templates.mjs
node scripts/validate-templates.mjs
```

Validation attendue :

```text
Templates OK
```

## Fichiers A Lire Ensuite

| Fichier | Usage |
|---|---|
| `CHECKLIST-KICKOFF.md` | Checklist d'installation et de verification |
| `OPTIMISATION-TOKENS.md` | Depth, routing, rounds facultatifs, modeles, patterns d'output, compaction |
| `MIGRATION-v0.5.md` | Guide de migration v0.4.0 → v0.5.0 |
| `MIGRATION-v0.4.md` | Guide de migration v0.3.0 → v0.4.0 |
| `PORTAGE-CODEX.md` | Mapping Claude Code vers Codex |
| `ARCHITECTURE.md` | Fonctionnement interne des orchestrateurs |
| `PATTERNS.md` | Patterns invariants du systeme |
| `REGLES-TRANSVERSES.md` | Regles git, securite, tests, process |
| `GUIDE-ADAPTATION.md` | Personnalisation fine apres setup |

## Limites

- `setup-project --ai` configure les placeholders generiques, mais les sections metier fines peuvent rester a completer.
- Les workflows preparent les PRs et les livrables, mais ne font pas les actes irreversibles sans instruction explicite : merge, publication, envoi commercial, migration prod.
- Les couts et modeles dependent du fournisseur et du plan utilise.
