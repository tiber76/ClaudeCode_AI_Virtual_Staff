# Équipes virtuelles {{PROJECT_NAME}} — Capacités & commandes

Deux équipes d'agents IA spécialisés collaborent sur {{PROJECT_NAME}}, chacune avec son orchestrateur et ses skills. Aucun agent n'auto-escalade vers l'autre équipe — les consultations croisées sont **opt-in**.

---

## 🏗️ Équipe Tech

**Orchestrateur** : `/call-tech-lead`
**Mission** : concevoir, coder, tester, reviewer une feature jusqu'à une PR ouverte vers `develop`.
**Jamais** : merger la PR, commit sur `main`/`develop`, exécuter une migration SQL.

### Les agents tech

| Agent | Modèle | Expertise | Quand le convoquer |
|---|---|---|---|
| `po-metier` | Sonnet | PO — {{ROLES}}, entités métier, ton éditorial | Rédaction US, validation valeur métier |
| `full-stack-lead` | Opus | {{STACK}} — helpers, patterns, pièges projet | Architecture, choix patterns |
| `designer-uxui` | Sonnet | Design system — typographie, z-index, 4 états, a11y | UX/UI d'une feature, copy |
| `qa` | Sonnet | {{TEST_FRAMEWORK}} — tags smoke/critical, fixtures | Stratégie tests, mapping US↔tests |
| `cso` | Opus | Sécurité §7 — rate-limit, 2FA, CSP, RGPD | Features auth / data sensible / permissions |
| `data-engineer` | Sonnet | KPI, index DB, agrégations, budget AI | Modélisation data, optim requêtes |
| `ai-llm-engineer` | Sonnet | Claude/LLM — prompts, parsers, validators | Features IA (si applicable) |

### Les skills tech

| Commande | Objectif | Sortie |
|---|---|---|
| **`/call-tech-lead <besoin>`** | Orchestrer feature avec équipe virtuelle, débats, arbitrages | TRANSCRIPT + PR ouverte `develop` |
| `/redige-us <besoin>` | Transformer besoin en User Story Gherkin | `docs/us/US-<slug>.md` |
| `/fullstack-lead-tech <US>` | Plan technique (archi, UX, sécu, tests, effort) | `docs/plans/PLAN-<slug>.md` |
| `/investigate-bug <bug>` | Root-cause analysis + 2 fixes (pas de patch direct) | Rapport hypothèses vérifiées |
| `/qa-flow` | Pyramide tests (smoke → critical → full) + correctif itératif | Rapport before/after |
| `/review-pr` | Code review pré-merge | 🔴 Bloquants / 🟠 À corriger / 🟢 OK |
| `/security-audit` | Audit sécu périodique | Rapport Critique/Élevé/Moyen/Info |
| `/ship-pr` | Tests → build → commit → `gh pr create --base develop` | PR URL (ne merge jamais) |
| `/retro` | Rétro post-feature/bug | 3 marché / 3 coincé / préventions |

---

## 📣 Équipe Commerciale & Marketing (si applicable)

**Orchestrateur** : `/call-growth-lead`
**Mission** : concevoir, rédiger, orchestrer les initiatives go-to-market — campagnes, landings, séquences outbound, audits funnel, plans éditoriaux.
**Jamais** : publier, envoyer un email réel, créer un compte externe, fabriquer un chiffre.

### Les agents growth

| Agent | Modèle | Expertise | Quand le convoquer |
|---|---|---|---|
| `growth-lead` | Opus | CMO — funnel AARRR, stratégie canaux, benchmarks | Stratégie GTM, arbitrage canaux |
| `sales-b2b` | Opus | AE sénior — MEDDPICC, démos, objections | Playbook sales, prep démo, séquence outbound |
| `customer-success` | Sonnet | CSM — onboarding, health scoring, QBR | Parcours activation, prévention churn |
| `copywriter-brand` | Sonnet | Voice & tone — landings, emails, ads | Rédaction externe |
| `content-seo` | Sonnet | Topic clusters, guides, LinkedIn organic | Plan éditorial, guide/article |
| `marketing-analytics` | Sonnet | Funnel AARRR, cohortes, A/B, CAC/LTV | Audit funnel, cadre A/B |

### Les skills growth

| Commande | Objectif | Sortie |
|---|---|---|
| **`/call-growth-lead <besoin>`** | Orchestrer initiative growth, débats, livrables | TRANSCRIPT + `docs/growth/` |
| `/redige-brief <besoin>` | Formaliser besoin en brief SMART | `docs/growth/BRIEF-<slug>.md` |
| `/ship-landing <besoin>` | Livrer landing page complète | `docs/growth/landings/<slug>.md` |
| `/audit-funnel` | Diagnostiquer funnel AARRR + 3 fuites + 3 fixes | `docs/growth/audits/FUNNEL-<date>.md` |
| `/brief-demo <prospect>` | Préparer démo personnalisée | `docs/growth/demos/<prospect>.md` |
| `/retro-campagne <slug>` | Post-mortem campagne | `docs/growth/retros/RETRO-<slug>.md` |

---

## 🔀 Interaction entre les 2 équipes

**Règle absolue** : aucune escalade automatique.

### Cas 1 — Feature tech qui touche le pricing
→ `/call-tech-lead <besoin>`
→ Le skill détecte le signal commercial et **propose** : "Consulter growth-lead + sales-b2b (+~100k tokens) ? Oui/Non"
→ **Par défaut : Non**. Opt-in explicite requis.

### Cas 2 — Initiative commerciale qui nécessite un dev
→ `/call-growth-lead <besoin>`
→ Les livrables contiennent un "handoff implémentation" à destination de `full-stack-lead`
→ Invoquer ensuite `/call-tech-lead` pour implémenter.

### Cas 3 — Question simple
→ Pas d'orchestrateur. Invoquer directement l'agent.

---

## 💰 Coûts indicatifs

Détail : [`docs/COUTS-LLM.md`](COUTS-LLM.md).

| Run | Tokens brut | Avec cache | API |
|---|---|---|---|
| `/call-tech-lead` (feature complète) | 600k-1.4M | 150-350k | **$2-5** |
| `/call-growth-lead` (initiative) | 300-800k | 80-230k | **$1-4** |
| Skill utilitaire solo | 80-200k | 30-60k | $0.4-1 |
| Skill léger (`/redige-us`, `/retro`) | 30-80k | 10-25k | $0.1-0.3 |
| Agent solo | 20-50k | 10-20k | $0.05-0.5 |

---

## 🎯 Cheat sheet

| Besoin | Commande |
|---|---|
| Formaliser une US | `/redige-us` |
| Plan technique d'une US | `/fullstack-lead-tech` |
| Feature complète → PR | `/call-tech-lead` |
| Debug méthodique | `/investigate-bug` |
| Tests à corriger | `/qa-flow` |
| Review pré-merge | `/review-pr` |
| PR automatisée | `/ship-pr` |
| Audit sécu | `/security-audit` |
| Rétro post-feature | `/retro` |
| --- | --- |
| Brief campagne | `/redige-brief` |
| Initiative growth | `/call-growth-lead` |
| Landing page | `/ship-landing` |
| Audit funnel | `/audit-funnel` |
| Préparer démo | `/brief-demo` |
| Bilan campagne | `/retro-campagne` |

---

## 📂 Arborescence

```
.claude/
├── agents/           ← N agents (.md) = tech + commerciaux
├── skills/           ← N skills = tech + commerciaux
├── commands/         ← alias /<nom>
└── settings.local.json

docs/
├── us/               ← User Stories (/redige-us)
├── plans/            ← Plans techniques (/fullstack-lead-tech)
├── GUIDE-LLM.md      ← source de vérité projet
├── EQUIPES-LLM.md    ← ce fichier
├── COUTS-LLM.md      ← estimations tokens
└── growth/           ← livrables équipe commerciale
    ├── BRIEF-*.md
    ├── landings/
    ├── guides/
    ├── articles/
    ├── emails/
    ├── ads/
    ├── outbound/
    ├── demos/
    ├── audits/
    ├── retros/
    └── studies/
```
