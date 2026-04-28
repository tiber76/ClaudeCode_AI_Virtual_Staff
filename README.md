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

Le script pose 3 questions :

| Question | Exemple |
|---|---|
| Projet cible | `/Users/me/repos/mon-projet` |
| Outil a installer | `codex`, `claude` ou `both` |
| Si un fichier existe deja | `backup`, `abort` ou `overwrite` |

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

## Quel Outil Choisir ?

| Besoin | Choix conseille |
|---|---|
| Tu travailles deja dans Claude Code | `claude` |
| Tu veux utiliser Codex / OpenAI | `codex` |
| Tu veux tester les deux adapters | `both` |
| Tu maintiens ce starter kit | modifier `templates/claude/`, puis regenerer `templates/codex/` |

## Ce Que Le Kit Installe

### Agents

13 agents specialises :

- Tech : `po-metier`, `full-stack-lead`, `designer-uxui`, `qa`, `cso`, `data-engineer`, `ai-llm-engineer`.
- Growth : `growth-lead`, `sales-b2b`, `customer-success`, `copywriter-brand`, `content-seo`, `marketing-analytics`.

### Skills

16 skills :

| Famille | Skills |
|---|---|
| Setup | `setup-project` |
| Orchestration | `call-tech-lead`, `call-growth-lead` |
| Tech | `redige-us`, `fullstack-lead-tech`, `investigate-bug`, `review-pr`, `qa-flow`, `ship-pr`, `security-audit` |
| Growth | `redige-brief`, `ship-landing`, `audit-funnel`, `brief-demo`, `retro-campagne` |
| Transverse | `retro` |

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

Pour une tache courte, commence par `--depth=lean`. Pour une decision critique, utilise `--depth=full`.

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
| `OPTIMISATION-TOKENS.md` | Depth, routing, rounds facultatifs, modeles |
| `PORTAGE-CODEX.md` | Mapping Claude Code vers Codex |
| `ARCHITECTURE.md` | Fonctionnement interne des orchestrateurs |
| `PATTERNS.md` | Patterns invariants du systeme |
| `REGLES-TRANSVERSES.md` | Regles git, securite, tests, process |
| `GUIDE-ADAPTATION.md` | Personnalisation fine apres setup |

## Limites

- `setup-project --ai` configure les placeholders generiques, mais les sections metier fines peuvent rester a completer.
- Les workflows preparent les PRs et les livrables, mais ne font pas les actes irreversibles sans instruction explicite : merge, publication, envoi commercial, migration prod.
- Les couts et modeles dependent du fournisseur et du plan utilise.
