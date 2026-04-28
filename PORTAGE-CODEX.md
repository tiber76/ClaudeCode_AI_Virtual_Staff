# Portage OpenAI Codex

Ce document decrit le mapping entre le kit Claude Code historique et l'adapter Codex ajoute dans `templates/codex/`.

## Mapping

| Concept | Claude Code | OpenAI Codex |
|---|---|---|
| Regles projet chargees en session | `docs/GUIDE-LLM.md` + memoire Claude | `AGENTS.md` + `docs/GUIDE-LLM.md` |
| Skills | `.claude/skills/<nom>/SKILL.md` | `.agents/skills/<nom>/SKILL.md` |
| Invocation explicite | `/<skill>` | `$<skill>` |
| Agents specialises | `.claude/agents/<nom>.md` | `.codex/agents/<nom>.toml` |
| Runs orchestres | `.claude/call-call-*-runs/` | `.codex/runs/<skill>/` |
| Settings | `.claude/settings.local.json` | `.codex/config.toml` / configuration Codex locale |

## Modeles Par Defaut

Les templates Claude gardent les familles `opus` et `sonnet`. L'adapter Codex ne fait pas un mapping brut `opus -> gpt-5.5` pour tous les agents : il choisit le modele selon le role.

| Famille d'agents | Claude | Codex |
|---|---|---|
| Architecture, securite critique | Opus | `gpt-5.3-codex` avec effort `high` |
| Tests, data, IA integree au code | Sonnet | `gpt-5.3-codex` avec effort `medium` |
| Produit, design, operations | Sonnet | `gpt-5.4-mini` avec effort `medium` |
| Strategie growth / sales | Opus | `gpt-5.5` avec effort `high` |

Voir `OPTIMISATION-TOKENS.md` pour la matrice complete.

## Generation

L'adapter Codex est genere depuis les sources Claude :

```bash
node scripts/generate-codex-templates.mjs
node scripts/validate-templates.mjs
```

Le validateur controle :

- 13 agents Claude hors template.
- 16 skills Claude.
- 16 commandes Claude.
- 13 agents Codex.
- 16 skills Codex.
- frontmatter `name` / `description`.
- absence de reliquats `.claude`, `AskUserQuestion`, `allowed-tools`, `triggers` dans l'arbre Codex genere.

## Points D'Attention

- Le portage est utilisable, mais la source canonique reste `templates/claude/`.
- Les skills Codex gardent les placeholders `{{VAR}}` et blocs `{{#IF ...}}`; ils sont resolus par `setup-project` comme cote Claude.
- `setup-project --ai` est le mode recommande : Codex inspecte le repo, infere la configuration, puis pose seulement les questions bloquantes.
- Les commandes slash Claude ne sont pas transposees en fichiers de commande Codex. Dans Codex, privilegie l'invocation `$skill`.
- Les regles IA liees a un provider doivent etre relues dans `ai-llm-engineer` et `REGLES-TRANSVERSES.md` avant usage production. OpenAI Structured Outputs et les outils Responses API ne se pilotent pas toujours comme les APIs Anthropic.
