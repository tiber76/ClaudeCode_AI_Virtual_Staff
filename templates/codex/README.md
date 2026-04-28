# Templates Codex / OpenAI

Ce dossier est l'adapter Codex du starter kit d'equipes virtuelles.

## Structure

```
codex/
├── AGENTS.md                 # regles projet lues par Codex
├── .agents/skills/           # 16 skills Codex, un dossier par workflow
└── .codex/agents/            # 13 agents specialises Codex en TOML
```

## Installation dans un projet cible

Depuis la racine du projet cible :

```bash
cp -r <chemin-kit>/templates/codex/.agents ./
cp -r <chemin-kit>/templates/codex/.codex ./
cp <chemin-kit>/templates/codex/AGENTS.md ./AGENTS.md
cp -r <chemin-kit>/templates/docs ./docs
cp <chemin-kit>/templates/backlog.template.md ./backlog.md

mv docs/GUIDE-LLM.template.md docs/GUIDE-LLM.md
mv docs/EQUIPES-LLM.template.md docs/EQUIPES-LLM.md
mv docs/COUTS-LLM.template.md docs/COUTS-LLM.md
```

Puis ouvrir Codex a la racine et lancer :

```
$setup-project --ai
```

## Invocation

Codex active les skills soit explicitement avec `$nom-du-skill`, soit implicitement quand la description correspond a la demande. Les equivalents principaux sont :

- `$call-tech-lead` : feature technique complete jusqu'a PR.
- `$call-growth-lead` : campagne, landing, brief, audit funnel.
- `$redige-us`, `$fullstack-lead-tech`, `$review-pr`, `$qa-flow`, `$ship-pr` : workflows tech cibles.
- `$retro` : capitalisation apres livraison.

## Maintenance

Ne modifie pas les fichiers generes a la main si la source Claude doit rester canonique. Regenerer avec :

```bash
node scripts/generate-codex-templates.mjs
```
