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
│   ├── agents/              # 18 agents + _TEMPLATE-agent.md
│   ├── skills/              # 23 skills + _partage/ + _TEMPLATE-skill.md
│   ├── commands/            # 23 alias /<nom>
│   └── hooks/               # porte de review, niveau E2E, preuve de fix
├── codex/
│   ├── AGENTS.md            # regles projet pour Codex
│   ├── .agents/skills/      # 23 skills Codex
│   ├── .codex/agents/       # 18 agents TOML
│   └── .codex/hooks/        # memes scripts, lances par les skills
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

Les 18 agents hors template vierge :

| Agent | Role |
|---|---|
| `po-metier` | PO produit |
| `full-stack-lead` | Tech lead full-stack |
| `designer-uxui` | Designer UX/UI |
| `integrateur` | Integration front d'une maquette validee |
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
| `full-stack-worker` | Worker frais d'une tranche de `/call-tech-lead` |
| `review-finder` | Chercheur de `/review-pr` (un angle) |
| `review-verifier` | Contre-expert de `/review-pr` (un verdict par candidat) |
| `pre-mortem-adversaire` | Edge cases d'un diff sensible (`/pre-mortem`) |

Supprime les agents inutiles apres setup. Un routing avec peu d'agents bien specialises est souvent meilleur qu'une equipe trop large.

## Skills Fournis

Les 23 skills :

| Famille | Skills |
|---|---|
| Setup | `setup-project` |
| Orchestration | `call-tech-lead`, `call-growth-lead` |
| Voie courte | `dev-express` (sujet de taille S), `fix-bug` (bug S avec preuve inversee) |
| Tech | `redige-us`, `fullstack-lead-tech`, `investigate-bug`, `integre-design`, `review-pr`, `qa-flow`, `verify`, `pre-mortem`, `ship-pr`, `security-audit` |
| Growth | `redige-brief`, `ship-landing`, `audit-funnel`, `brief-demo`, `retro-campagne` |
| Transverse | `retro`, `close-session`, `audit-memory` |

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
.claude/reviews/
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
