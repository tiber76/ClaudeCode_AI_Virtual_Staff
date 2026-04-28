# Templates — Reference Des Fichiers Installes

Ce dossier documente les fichiers copies par `npm run setup`. Pour installer le kit, utilise d'abord la procedure du README racine :

```bash
npm run setup
```

La copie manuelle des fichiers de ce dossier est une reference de maintenance, pas le chemin recommande pour un utilisateur final.

Ce dossier contient les deux adapters du starter kit :

- `claude/` pour Claude Code.
- `codex/` pour OpenAI Codex.
- `docs/` et `backlog.template.md` communs aux deux.

## Structure

```text
templates/
├── README.md
├── backlog.template.md
├── claude/
│   ├── settings.template.json
│   ├── agents/              # 13 agents + _TEMPLATE-agent.md
│   ├── skills/              # 16 skills + _TEMPLATE-skill.md
│   └── commands/            # 16 alias /<nom>
├── codex/
│   ├── AGENTS.md            # regles projet pour Codex
│   ├── .agents/skills/      # 16 skills Codex
│   └── .codex/agents/       # 13 agents TOML
└── docs/
    ├── GUIDE-LLM.template.md
    ├── EQUIPES-LLM.template.md
    ├── COUTS-LLM.template.md
    └── formats/
```

## Commandes Utiles Apres Installation

Si tu as choisi Claude Code :

```text
/setup-project --ai
```

Si `/setup-project` n'apparait pas dans Claude Code, ferme puis rouvre Claude Code a la racine du projet. Les commandes slash sont chargees depuis `.claude/commands/` au demarrage de session.

Si tu as choisi OpenAI Codex :

```text
$setup-project --ai
```

Le mode `setup-project --ai` inspecte le repo, infere la configuration, puis pose seulement les questions bloquantes.

Premier run conseille :

```text
Claude Code : /call-tech-lead "..." --depth=lean --mode=semi
OpenAI Codex : $call-tech-lead "..." --depth=lean --mode=semi
```

`--depth=lean|standard|full` permet d'adapter le cout token a la criticite du besoin.

## Installation Non Interactive

```bash
npm run setup -- --target /chemin/vers/projet --provider claude --conflicts backup
npm run setup -- --target /chemin/vers/projet --provider codex --conflicts backup
npm run setup -- --target /chemin/vers/projet --provider both --conflicts backup
```

## Agents Fournis

Les 13 agents hors template vierge :

| Agent | Role |
|---|---|
| `po-metier` | PO produit |
| `full-stack-lead` | Tech lead full-stack |
| `designer-uxui` | Designer UX/UI |
| `qa` | QA lead |
| `cso` | Securite |
| `data-engineer` | Data et performance |
| `ai-llm-engineer` | Features IA/LLM |
| `growth-lead` | Strategie growth |
| `sales-b2b` | Sales B2B |
| `customer-success` | Activation, retention, QBR |
| `copywriter-brand` | Copy et voice & tone |
| `content-seo` | SEO et contenu |
| `marketing-analytics` | Funnel, cohortes, A/B |

Supprime les agents inutiles apres setup. Un routing avec peu d'agents bien specialises est souvent meilleur qu'une equipe trop large.

## Skills Fournis

Les 16 skills :

| Famille | Skills |
|---|---|
| Orchestration | `call-tech-lead`, `call-growth-lead` |
| Setup | `setup-project` |
| Tech | `redige-us`, `fullstack-lead-tech`, `investigate-bug`, `review-pr`, `qa-flow`, `ship-pr`, `security-audit` |
| Growth | `redige-brief`, `ship-landing`, `audit-funnel`, `brief-demo`, `retro-campagne` |
| Transverse | `retro` |

## Maintenance Codex

L'arbre `codex/` est genere depuis `claude/` pour eviter deux sources de verite :

```bash
node scripts/generate-codex-templates.mjs
node scripts/validate-templates.mjs
```

Ne modifie les fichiers generes dans `templates/codex/` a la main que si tu acceptes de reporter ensuite la modification dans le generateur ou dans les sources Claude.

## Gitignore Conseille

Claude Code :

```gitignore
.claude/call-call-tech-lead-runs/
.claude/call-call-growth-lead-runs/
.claude/settings.local.json
```

Codex :

```gitignore
.codex/runs/
```

## Fichiers Communs

- `backlog.template.md` : format universel de backlog.
- `docs/formats/*.md` : formats US, plan, brief, retro.
- `docs/GUIDE-LLM.template.md` : source de verite projet a completer apres setup.
