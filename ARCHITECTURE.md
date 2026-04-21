# Architecture du système

Comment Claude Code charge et utilise chaque élément du kit. Utile pour comprendre où intervenir quand quelque chose ne marche pas comme prévu.

---

## Vue d'ensemble

```
racine-projet/
├── .claude/                              ← lu automatiquement par Claude Code
│   ├── agents/                           ← subagents invocables via Agent tool
│   │   └── <nom-agent>.md                ← 1 agent = 1 fichier Markdown avec frontmatter
│   │
│   ├── skills/                           ← skills invocables via Skill tool
│   │   └── <nom-skill>/
│   │       └── SKILL.md                  ← 1 skill = 1 dossier avec SKILL.md à l'intérieur
│   │
│   ├── commands/                         ← raccourcis /<nom> qui invoquent un skill
│   │   └── <nom>.md
│   │
│   ├── settings.local.json               ← permissions, env vars, hooks (non versionné idéalement)
│   │
│   ├── call-tech-lead-runs/                   ← artefacts produits par /call-tech-lead (inclure dans .gitignore)
│   │   └── YYYYMMDD-HHMMSS-<slug>/
│   │       ├── 00-input.md
│   │       ├── 01-routing.md
│   │       ├── 02-us.md
│   │       ├── 03-round1-<agent>.md      ← un par agent
│   │       ├── 04-round2-debates.md
│   │       ├── 05-plan-final.md
│   │       ├── 06-implementation.log
│   │       ├── 07-review.md
│   │       ├── 08-qa.md
│   │       ├── 09-pr.md
│   │       └── TRANSCRIPT.md             ← synthèse lisible de tout le run
│   │
│   └── call-growth-lead-runs/                 ← même logique pour growth
│
├── backlog.md                            ← lu en début de session (rappel dettes)
│
└── docs/
    ├── GUIDE-LLM.md                      ← source de vérité, 12 sections, lu chaque session
    ├── EQUIPES-LLM.md                    ← doc humain : liste agents + skills
    ├── COUTS-LLM.md                      ← estimations tokens par skill
    │
    ├── us/                               ← User Stories produites par /redige-us
    │   └── US-<slug>.md
    │
    ├── plans/                            ← Plans techniques produits par /fullstack-lead-tech
    │   └── PLAN-<slug>.md
    │
    └── growth/                           ← livrables équipe commerciale
        ├── BRIEF-<slug>.md
        ├── landings/<slug>.md
        ├── retros/RETRO-<slug>.md
        ├── demos/<prospect>.md
        ├── audits/FUNNEL-<date>.md
        └── ...
```

---

## Comment Claude Code charge chaque pièce

### 1. `.claude/agents/<nom>.md`

Format attendu (YAML frontmatter + corps Markdown) :

```markdown
---
name: nom-agent              # obligatoire, doit matcher le nom de fichier
description: |               # obligatoire, décrit quand l'agent doit être invoqué
  Texte court qui apparaîtra dans la liste des subagent_type disponibles.
  L'orchestrateur (ou l'utilisateur via `Agent` tool) lit ce descriptif
  pour décider s'il convoque cet agent.
model: opus | sonnet | haiku # optionnel, sinon hérite du parent
tools:                       # optionnel, liste des outils autorisés à l'agent
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
  - Write
  - AskUserQuestion          # si l'agent peut poser des questions
---

# Titre agent

Corps markdown qui définit le rôle, la stack maîtrisée, la mission dans l'orchestrateur,
les pièges connus, le style, les anti-patterns, les références.
```

**Comment c'est invoqué** :
- Par l'utilisateur : `Demande à l'agent full-stack-lead de…`
- Par un skill (via le tool `Agent`) : l'orchestrateur `/call-tech-lead` invoque `Agent(subagent_type: "full-stack-lead", prompt: "...")` en Phase 3.
- Parallélisation : plusieurs `Agent` tool calls dans le même message = invocations parallèles (gain de latence énorme sur le round 1).

### 2. `.claude/skills/<nom>/SKILL.md`

Format attendu :

```markdown
---
name: nom-skill              # obligatoire, doit matcher le nom du dossier parent
description: |               # obligatoire, apparaît dans la liste des skills
  Description courte qui aide Claude à décider quand invoquer ce skill.
allowed-tools:               # obligatoire, liste des tools autorisés dans le skill
  - Bash
  - Read
  - Write
  - Agent                    # si le skill orchestre d'autres agents
  - AskUserQuestion
triggers:                    # optionnel, mots-clés qui déclenchent le skill
  - rédige une US
  - formalise ce besoin
---

# /nom-skill

Corps markdown qui définit : objectif, quand utiliser, principes, étapes détaillées,
format de sortie, anti-patterns, références.
```

**Comment c'est invoqué** :
- Par l'utilisateur : `/nom-skill <arguments>` OU via l'outil `Skill` depuis une autre conversation.
- Par un autre skill : un skill orchestrateur peut invoquer d'autres skills via appel séquentiel (pas d'imbrication formelle, mais `/call-tech-lead` appelle `/redige-us`, `/fullstack-lead-tech`, `/review-pr`, `/qa-flow`, `/ship-pr` en sous-routines logiques).

### 3. `.claude/commands/<nom>.md`

Format minimaliste, sert juste à créer un alias `/<nom>` qui invoque un skill :

```markdown
---
description: Description courte qui apparaît dans l'autocomplétion /<nom>
argument-hint: [--mode=auto|semi] [besoin en texte libre]
---

Invoque le skill `nom-skill` avec les arguments : $ARGUMENTS
```

Claude Code interprète cette commande comme une instruction d'invoquer le skill correspondant. `$ARGUMENTS` contient tout ce que l'utilisateur a tapé après `/nom`.

#### Autocomplétion automatique

Dès qu'un fichier `<nom>.md` existe dans `.claude/commands/`, Claude Code l'intègre automatiquement dans l'autocomplétion :

- **Taper `/` dans Claude Code** affiche la liste déroulante de toutes les commandes disponibles.
- **Le champ `description`** du frontmatter apparaît à côté du nom dans la liste.
- **Le champ `argument-hint`** apparaît comme placeholder après la commande sélectionnée pour rappeler la syntaxe attendue.
- **Aucune configuration supplémentaire** : pas besoin de déclarer les commandes ailleurs. Claude Code scanne le dossier à chaque session.

Règle pratique : **1 skill = 1 commande** pour garantir l'autocomplétion. Si tu crées un nouveau skill et oublies la commande, tu pourras toujours l'invoquer via le tool `Skill`, mais tu perdras le gain `/nom` + autocomplete.

Pour tester après modification :
1. Le fichier est pris en compte à la prochaine session Claude Code (pas besoin de redémarrer).
2. Si l'autocomplete ne voit pas ta commande : vérifie que le fichier est bien dans `.claude/commands/` (pas dans un sous-dossier) et qu'il a un frontmatter YAML valide.

### 4. `.claude/settings.local.json`

Fichier de configuration locale (typiquement **non versionné** pour éviter de partager des chemins absolus ou des permissions trop larges). Structure :

```json
{
  "permissions": {
    "allow": [
      "Bash(npm install:*)",
      "Bash(npx jest:*)",
      "Bash(gh pr:*)",
      "Read(/chemin/absolu/autorisé/**)",
      "WebSearch"
    ]
  },
  "env": {
    "DEBUG": "false"
  },
  "hooks": {
    "PostToolUse": [ ... ]
  }
}
```

**Ce qui doit être partagé via git** : éventuellement un `settings.json` (versionné) avec les permissions transverses à l'équipe. Ce qui est strictement local va dans `settings.local.json` (ignoré).

### 5. `docs/GUIDE-LLM.md`

Fichier **lu automatiquement** au début de chaque session Claude Code. C'est la source de vérité projet. Il doit rester **sous ~700 lignes** pour éviter la troncation, organisé en sections numérotées (§0 à §12 typiquement) pour que les agents puissent les référencer (cf. `cso` cite §7, `designer-uxui` cite §8).

**Règle critique** : le GUIDE-LLM évolue. Chaque `/retro` propose des ajouts au §12 "Pièges connus". Ne le laisse pas stagner — c'est ta mémoire institutionnelle.

### 6. `backlog.md`

Fichier à la racine, **scanné en début de session**. Format simple :

```markdown
# Backlog

## 🔴 P0 — Critique
- **<titre>** (origine : PR #X / date)
  - Contexte : ...
  - Livrable attendu : ...
  - Branche cible : ...

## 🟠 P1 — Important
- ...

## 🟡 P2 — Nice-to-have
- ...

## 🟢 P3 — Idées
- ...

## ✅ Fait
- <titre> (fait le YYYY-MM-DD, PR #X)
```

**Règle** : en début de session, Claude rappelle "N P0 / N P1 en attente" et cite 3 titres prioritaires. Pas directif — juste informatif.

---

## Flux d'une feature via `/call-tech-lead`

Pour comprendre où chaque fichier est lu/écrit pendant un run orchestré :

```
Utilisateur : /call-tech-lead "Ajoute export CSV candidats" --mode=semi

├── Phase 0 — Setup
│   ├── Crée .claude/call-call-tech-lead-runs/YYYYMMDD-HHMMSS-export-csv-candidats/
│   ├── Écrit 00-input.md
│   ├── Crée branche feature/export-csv-candidats
│   └── Lit docs/GUIDE-LLM.md + backlog.md
│
├── Phase 1 — Routing
│   ├── Analyse le besoin
│   ├── Décide : po-metier + full-stack-lead + qa + data-engineer (pas de cso, pas de designer)
│   └── Écrit 01-routing.md
│
├── Phase 2 — PO rédige l'US
│   ├── Invoque Agent(subagent_type: "po-metier", prompt: <besoin>)
│   ├── L'agent écrit docs/us/US-export-csv-candidats.md
│   ├── Copie dans 02-us.md
│   └── CHECKPOINT (mode semi) : "Valide l'US ? (oui/modifier/stop)"
│
├── Phase 3 — Round 1 (parallèle)
│   ├── Invoque Agent(full-stack-lead) + Agent(qa) + Agent(data-engineer) EN PARALLÈLE
│   ├── Chaque agent lit docs/us/US-*.md + docs/GUIDE-LLM.md
│   ├── Chaque agent écrit 03-round1-<nom>.md
│   └── Orchestrateur synthétise dans TRANSCRIPT.md
│
├── Phase 4 — Débats (séquentiel ciblé)
│   ├── Orchestrateur détecte les frictions
│   ├── Invoque à nouveau les agents concernés avec le désaccord à trancher
│   ├── Écrit 04-round2-debates.md
│   └── Orchestrateur tranche (décision motivée dans TRANSCRIPT)
│
├── Phase 5 — Plan final
│   ├── Invoque le skill /fullstack-lead-tech en sous-routine
│   ├── Écrit docs/plans/PLAN-export-csv-candidats.md
│   └── CHECKPOINT (mode semi) : "Valide le plan ? (oui/ajuste/stop)"
│
├── Phase 6 — Implémentation
│   ├── Invoque Agent(full-stack-lead) + Agent(qa) pour écrire tests + code
│   ├── Commits atomiques par lot (SQL → tests rouges → impl → UI → E2E)
│   └── Log dans 06-implementation.log
│
├── Phase 7 — Review & QA
│   ├── Invoque /review-pr (skill)
│   ├── Invoque Agent(cso) en passe finale
│   ├── Invoque /qa-flow (skill)
│   └── Écrit 07-review.md, 08-qa.md
│
└── Phase 8 — Ship
    ├── Invoque /ship-pr (skill)
    ├── git push + gh pr create --base develop
    ├── Écrit 09-pr.md
    └── Met à jour TRANSCRIPT.md final + résumé user-facing
```

---

## Points d'extension

Où intervenir si tu veux personnaliser :

| Envie | Fichier à modifier |
|---|---|
| Ajouter un nouvel expert | Créer `.claude/agents/<nom>.md` + ajouter à la matrice de routing dans `tech-lead/SKILL.md` ou `growth-lead/SKILL.md` |
| Ajouter un nouveau skill | Créer `.claude/skills/<nom>/SKILL.md` + `.claude/commands/<nom>.md` |
| Changer le modèle d'un agent | Modifier `model:` dans le frontmatter de l'agent |
| Ajouter un checkpoint dans `/call-tech-lead` | Éditer la phase concernée dans `.claude/skills/call-tech-lead/SKILL.md` |
| Changer les types de tests demandés | Éditer `.claude/agents/qa.md` (section "Méthode — tableau de couverture") |
| Changer la règle de merge | Éditer `docs/GUIDE-LLM.md` §0 |
| Ajouter un piège détecté | Éditer `docs/GUIDE-LLM.md` §12 (via `/retro` idéalement) |

---

## Pièges d'architecture connus

### 1. Agents qui s'appellent entre eux
Ne JAMAIS faire ça directement — toujours passer par l'orchestrateur. Un agent qui invoque un autre agent via `Agent` crée un chaînage non traçable.

### 2. Skills qui dupliquent la logique d'un agent
Un skill doit **orchestrer ou produire un artefact**, pas raisonner à la place d'un agent. Si tu sens que le skill fait de l'analyse métier → déplace dans un agent.

### 3. GUIDE-LLM trop long
Au-delà de ~800 lignes, certains clients Claude tronquent. Archive les sections historiques dans des sous-docs (`docs/guide-llm-history.md`).

### 4. Trop d'agents
13 agents c'est déjà beaucoup. Si ton projet n'en a pas besoin, supprime-les. Un orchestrateur avec 3 agents bien ciblés vaut mieux que 13 flous.

### 5. Runs orchestrés commités
`call-tech-lead-runs/` et `call-growth-lead-runs/` doivent être dans `.gitignore`. Sinon ton historique git explose et les TRANSCRIPT.md fuitent des brainstorms internes.
