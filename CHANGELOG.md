# Changelog

Toutes les évolutions notables du kit.

Format basé sur [Keep a Changelog](https://keepachangelog.com/). Versionning [SemVer](https://semver.org/).

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
