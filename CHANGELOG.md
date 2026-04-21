# Changelog

Toutes les évolutions notables du kit.

Format basé sur [Keep a Changelog](https://keepachangelog.com/). Versionning [SemVer](https://semver.org/).

---

## [0.1.0] — YYYY-MM-DD

### Added
- 13 agents portables (équipe tech + équipe growth) avec placeholders et blocs conditionnels.
- 16 skills (2 orchestrateurs `/call-tech-lead` et `/call-growth-lead`, 7 skills tech, 5 skills growth, `/retro`, `/setup-project`).
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
