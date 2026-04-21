# Templates — fichiers à copier dans ton nouveau projet

Ce dossier contient **tout** ce qu'il faut copier à la racine de ton nouveau projet pour recréer le système.

## Structure

```
templates/
├── README.md                            ← ce fichier
├── backlog.template.md                  ← à copier en backlog.md à la racine
│
├── claude/                              ← à copier en .claude/ à la racine
│   ├── settings.template.json           ← à renommer settings.local.json (NE PAS versionner)
│   ├── agents/                          ← 13 agents + 1 template vierge
│   │   ├── _TEMPLATE-agent.md           ← squelette vierge avec placeholders
│   │   └── <nom>.md                     ← les 13 agents génériques avec placeholders {{VAR}}
│   ├── skills/                          ← 16 skills + 1 template vierge
│   │   ├── _TEMPLATE-skill.md           ← squelette vierge avec placeholders
│   │   ├── setup-project/SKILL.md       ← questionnaire qui remplit tous les placeholders
│   │   └── <nom>/SKILL.md               ← les 15 autres skills génériques
│   └── commands/                        ← 15 alias /<nom> pour les skills
│       └── <nom>.md
│
└── docs/                                ← à copier en docs/ à la racine
    ├── GUIDE-LLM.template.md            ← à renommer GUIDE-LLM.md (squelette 12 sections)
    ├── EQUIPES-LLM.template.md          ← à renommer EQUIPES-LLM.md
    ├── COUTS-LLM.template.md            ← à renommer COUTS-LLM.md
    └── formats/                         ← formats standards des livrables
        ├── US-template.md
        ├── PLAN-template.md
        ├── BRIEF-template.md
        └── RETRO-template.md
```

---

## Les agents fournis

Les 13 fichiers `.md` dans `claude/agents/` (hors `_TEMPLATE-agent.md`) sont des agents **pré-structurés avec placeholders `{{VAR}}`** et blocs conditionnels `{{#IF HAS_X}}...{{/IF}}`.

**Utilisation recommandée** : lance `/setup-project` après avoir copié les fichiers — le skill pose ~30 questions et remplit tous les placeholders automatiquement.

**Alternative** : si tu préfères tout remplir à la main, consulte [`../PLACEHOLDERS.md`](../PLACEHOLDERS.md) pour la liste complète des variables. Ou repars du squelette vierge `_TEMPLATE-agent.md`.

### Liste des agents

**Équipe tech (7 agents)**
- `po-metier.md` — PO produit (Sonnet)
- `full-stack-lead.md` — Tech Lead stack (Opus)
- `designer-uxui.md` — Designer UX/UI + DS (Sonnet)
- `qa.md` — QA Lead + stratégie tests (Sonnet)
- `cso.md` — Chief Security Officer (Opus)
- `data-engineer.md` — Data & performance (Sonnet)
- `ai-llm-engineer.md` — IA/LLM features (Sonnet, optionnel : contenu dans `{{#IF HAS_AI_FEATURE}}`)

**Équipe commerciale & marketing (6 agents, optionnelle via `{{HAS_GROWTH_TEAM}}`)**
- `growth-lead.md` — Head of Growth (Opus)
- `sales-b2b.md` — AE sénior B2B (Opus, contenu dans `{{#IF IS_B2B}}`)
- `customer-success.md` — CSM (Sonnet)
- `copywriter-brand.md` — Voice & tone (Sonnet)
- `content-seo.md` — Content & SEO (Sonnet)
- `marketing-analytics.md` — Funnel analytics (Sonnet)

**Règle générale** : supprime agressivement les agents que ton projet n'utilise pas. Un orchestrateur avec 4 agents bien ciblés vaut mieux que 13 flous. Le skill `/setup-project` propose de supprimer automatiquement les agents non pertinents selon tes réponses au questionnaire.

---

## Les skills fournis

Les 16 skills dans `claude/skills/` sont des skills Claude Code génériques.

**Orchestrateurs (2)**
- `tech-lead/SKILL.md` — orchestre l'équipe tech
- `growth-lead/SKILL.md` — orchestre l'équipe commerciale

**Skill de setup (1)**
- `setup-project/SKILL.md` — questionnaire qui remplit tous les placeholders du kit en une fois

**Skills utilitaires tech (7)**
- `redige-us/SKILL.md`
- `lead-tech/SKILL.md`
- `investigate-bug/SKILL.md`
- `review-pr/SKILL.md`
- `qa-flow/SKILL.md`
- `ship-pr/SKILL.md`
- `security-audit/SKILL.md`

**Skills utilitaires growth (5)**
- `redige-brief/SKILL.md`
- `ship-landing/SKILL.md`
- `audit-funnel/SKILL.md`
- `brief-demo/SKILL.md`
- `retro-campagne/SKILL.md`

**Skill transverse (1)**
- `retro/SKILL.md` — capitalisation post-feature/bug

---

## Les commandes fournies

`claude/commands/*.md` sont des **alias** qui permettent d'invoquer un skill via `/<nom>`. Chaque fichier fait 2-3 lignes :

```markdown
---
description: Description courte dans l'autocomplétion
argument-hint: [--mode=auto|semi] [besoin en texte libre]
---

Invoque le skill `nom-skill` avec les arguments : $ARGUMENTS
```

Ces fichiers sont largement identiques — tu peux les copier tels quels.

---

## Procédure de copie

Depuis la racine de ton nouveau projet :

```bash
# 1. Copier les dossiers (adapter <chemin-kit> à ton cas)
cp -r <chemin-kit>/templates/claude ./.claude
cp -r <chemin-kit>/templates/docs ./docs
cp <chemin-kit>/templates/backlog.template.md ./backlog.md

# 2. Renommer les templates
mv .claude/settings.template.json .claude/settings.local.json
mv docs/GUIDE-LLM.template.md docs/GUIDE-LLM.md
mv docs/EQUIPES-LLM.template.md docs/EQUIPES-LLM.md
mv docs/COUTS-LLM.template.md docs/COUTS-LLM.md

# 3. Ignorer les runs + settings local
cat >> .gitignore <<EOF
.claude/tech-lead-runs/
.claude/growth-lead-runs/
.claude/settings.local.json
EOF

# 4. Lancer le setup interactif dans Claude Code
# Ouvre Claude Code à la racine du projet, puis :
/setup-project

# 5. Après validation : premier test
/redige-us "Ajoute un bouton d'export CSV sur la page listing"
```

---

## Fichiers à comprendre avant modification

- **`settings.template.json`** : les permissions contiennent des patterns Bash. Évalue chaque permission — "allow-all bash" est dangereux.
- **`GUIDE-LLM.template.md`** : squelette 12 sections, à **remplir** avec le contexte de ton projet (le skill `/setup-project` remplit les sections basiques, tu complètes §6/§10/§12).
- **Les 13 agents** : remplissés par `/setup-project` ou manuellement via [`../PLACEHOLDERS.md`](../PLACEHOLDERS.md).

---

## Fichiers qui peuvent être copiés tels quels

- **`backlog.template.md`** : format universel.
- **`docs/formats/*.md`** : formats universels (US, PLAN, BRIEF, RETRO).
- **Commandes `claude/commands/*.md`** : alias de 2-3 lignes.
- **Skills utilitaires** (`redige-us`, `ship-pr`, `review-pr`, `qa-flow`, `retro`, etc.) : largement portables, juste adaptation via placeholders.

---

## Rappel

Ce kit est un **starter**, pas une vérité gravée. Au bout d'un mois d'usage :
- Tu auras supprimé 2-3 agents que tu n'utilises pas.
- Tu auras enrichi le GUIDE-LLM §12 avec tes premiers pièges.
- Tu auras peut-être créé un agent spécifique à ton domaine (ex: `mobile-ios-lead`, `ml-ops-engineer`, `embedded-systems-lead`).

Le kit évolue avec ton projet. Ne le traite pas comme figé.
