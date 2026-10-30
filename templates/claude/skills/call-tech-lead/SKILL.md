---
name: call-tech-lead
description: |
  Orchestrateur multi-agents. Tu formules un besoin en texte libre, l'orchestrateur
  convoque dynamiquement une équipe virtuelle (Full-Stack Lead, PO Métier, Designer
  UX/UI, QA, CSO, Data Engineer, AI/LLM Engineer) — les agents débattent franchement,
  le tech-lead synchronise et tranche. Un sujet de taille S bascule vers `/dev-express`.
  Une feature est découpée en tranches : chaque tranche est portée par un worker à
  contexte frais, l'orchestrateur joue la review et la PR. Deux modes : `--mode=auto`
  (autonome jusqu'à la PR) ou `--mode=semi` (checkpoints à US, plan, push). Trois
  profils de coût (`--depth=lean|standard|full`). Produit un TRANSCRIPT.md détaillé.
  Jamais de merge sans ordre explicite.
allowed-tools:
  - SendMessage
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - Skill
triggers:
  - tech lead
  - orchestre cette feature
  - équipe virtuelle
  - feature complète
  - lance le tech lead
---

# /call-tech-lead

> **Fil de progression** : plan de route annoncé au départ, une ligne `▶/✓ Étape N/M · Nom` par phase, blocs « À TOI » pour toute action attendue de l'utilisateur, selon `.claude/skills/_partage/fil-de-progression.md` (à lire au lancement). Si les phases ci-dessous changent, le plan de route change dans le même commit.

## Objectif

Orchestrer une équipe virtuelle d'experts sur {{PROJECT_NAME}} ({{PROJECT_DESCRIPTION}}) pour mener une feature de l'idée à la PR ouverte, avec débats francs et traçabilité complète.

## Format d'invocation

```
/call-tech-lead <besoin en texte libre> [--mode=auto|semi] [--depth=lean|standard|full]
```

- **Mode par défaut** : `semi` (checkpoints aux jalons clés : US, plan, push). `--mode=auto` : autonome jusqu'à la PR.
- **Depth par défaut** : `standard`. Le tech-lead choisit le profil le moins cher qui reste sûr ; il rétrograde en `lean` pour une tâche simple et demande confirmation avant de passer en `full`.

| Depth | Agents max hors PO | Round 1 | Round 2 | Usage |
|---|---:|---|---|---|
| `lean` | 2-3 | 150-220 mots / agent | seulement si risque critique | petite feature, refacto localisé |
| `standard` | 3-4 | 250-320 mots / agent | seulement si friction réelle | feature produit normale |
| `full` | tous les pertinents | 350-450 mots / agent | oui si frictions ou arbitrages lourds | auth, paiement, données perso, modèle de données, IA, migration, refonte majeure |

Garde-fou token : jamais d'agent « au cas où », chacun a un signal explicite de routing. `full-stack-lead` + `qa` forment le noyau minimal.

**Run multi-tranches** (US découpée) : chaque tranche est portée par un **worker à contexte frais**, la review et la PR étant jouées par l'orchestrateur, et **Tn+1 ne démarre qu'après merge de Tn**. Le merge n'est jamais autonome, quel que soit le mode : le run s'arrête après l'ouverture de la PR de Tn et l'orchestrateur attend l'ordre de merge explicite de l'utilisateur avant de lancer Tn+1.

## L'équipe virtuelle

Agents dans `.claude/agents/` :

| Agent | Rôle | Convoqué quand |
|---|---|---|
| `po-metier` | PO produit — rédige l'US découpée en tranches | quasi systématique pour une feature utilisateur |
| `full-stack-lead` | Tech Lead — avis d'architecture, plan, **TDD strict** | systématique |
| `full-stack-worker` | Le `full-stack-lead` en mode worker de tranche (même mandat, lu par renvoi) | Phase 6, une fois par tranche |
| `qa` | QA Lead — brief de cas à couvrir (oracle) en Round 1, **écrit uniquement les E2E** du lot final de chaque PR | systématique (Round 1 + lot final) ; silence radio entre les deux |
{{#IF HAS_DESIGN_SYSTEM}}
| `designer-uxui` | Designer — maquette, copy, états empty/loading/error/success | si la feature touche l'UI |
| `integrateur` | Intégrateur markup + CSS depuis une maquette, réutilise l'existant | si la feature touche l'UI (binôme avec le designer) |
{{/IF}}
| `cso` | Chief Security Officer | auth, données sensibles, permissions, route qui accepte un ID de ressource |
| `data-engineer` | Data & Performance | KPI, requêtes lourdes, modélisation |
{{#IF HAS_AI_FEATURE}}
| `ai-llm-engineer` | AI/LLM Engineer — TDD sur parsers/validators | LLM, prompts, parsers IA, rapports, chatbot |
{{/IF}}

Le **dev écrit** ses tests unitaires/API/intégration en TDD ; le **QA écrit** les E2E et fournit la liste des cas AVANT les tests dev (pair working asynchrone via brief).

{{#IF HAS_GROWTH_TEAM}}
### Équipe commerciale & marketing — consultation OPT-IN uniquement

Les agents commerciaux (growth-lead, sales-b2b, customer-success, copywriter-brand, content-seo, marketing-analytics) ne sont **JAMAIS** convoqués automatiquement. Signal fort détecté en Phase 1 (pricing, différenciateur, nouveau segment) :
- **semi** : `AskUserQuestion` « Signal commercial `<raison>`. Consulter l'équipe commerciale (+~100k tokens) ? Oui / Non » — défaut Non.
- **auto** : jamais d'escalade ; le signal est noté dans le TRANSCRIPT (« à consulter via `/call-growth-lead` »).
{{/IF}}

## Garde-fous absolus

- ❌ **JAMAIS merger la PR** : « ok pour la PR » ≠ « merge ». Ordre explicite de l'utilisateur requis. Un ordre permanent dans la demande initiale (« merge chaque tranche après review verte ») vaut ordre explicite pour les tranches de cette US, et seulement elles.
- ❌ **JAMAIS commit ni push direct** sur `{{GIT_PROD_BRANCH}}` ou `{{GIT_DEFAULT_BRANCH}}`.
- ❌ **JAMAIS** push force, `--no-verify`, `--amend` sans demande explicite.
{{#IF HAS_MIGRATIONS}}
- ❌ **JAMAIS exécuter une migration** : on écrit le fichier dans `{{DIR_MIGRATIONS}}`, l'utilisateur le joue (staging puis prod).
{{/IF}}
- ✅ Commits sur `{{GIT_PREFIX_FEATURE}}*` après tests verts ; `gh pr create --base {{GIT_DEFAULT_BRANCH}}`.
- ❌ Pas de push ni de PR sans rapport de review au sha qui part (porte `review-gate`, hook installé dans `.claude/hooks/`). Bypass uniquement sur instruction de l'utilisateur, jamais silencieux.

## Les phases

| # | Phase | Résumé (détail : `phases.md`, `rounds.md`) |
|---|---|---|
| 0 | Intake & setup | Parse, **éligibilité `/dev-express`** (bascule si sujet de taille S), slug, branche provisoire, TRANSCRIPT, annonce coût |
| 1 | Routing | Grille signaux → agents convoqués, plafonds `--depth` |
| 2 | PO rédige l'US | Délègue `po-metier` ; US en tranches (T1 = MVP démontrable seule) |
| 3 | Round 1 | Avis indépendants en parallèle + brief QA oracle (`rounds.md`) |
| 4 | Round 2 (facultatif) | Débats sur frictions réelles seulement ; sauté si convergence (`rounds.md`) |
| 5 | Plan final | `/fullstack-lead-tech` ; lots **par tranche**, jamais par couche |
| 6 | Implémentation | **Une tranche = un worker frais** (`full-stack-worker`) ; l'orchestrateur joue garde, suite de tests, **`/review-pr`** et la boucle de correction |
| 7 | QA & sécu | Vérifie review verte + passe `cso` finale + pyramide de tests consignée |
| 8 | Ship | Push + `gh pr create --base {{GIT_DEFAULT_BRANCH}}` par l'orchestrateur ; **merge de Tn avant Tn+1** ; jamais de merge sans ordre |

Fichiers d'appui, à lire à la demande : `phases.md` (phases 0, 1, 2, 5-8, après identification du besoin), `rounds.md` (avant la Phase 3), `transcript-format.md` (à l'init du TRANSCRIPT puis à chaque phase).

## Refus d'orchestrer — quand le skill s'arrête tôt

- **Petit sujet de taille S** (critères : `.claude/skills/dev-express/SKILL.md` § Éligibilité, source unique, jamais recopiée ici) → bascule sur `/dev-express <cible> --mode=<même mode>` ; le run `/call-tech-lead` s'arrête là. `auto` : bascule automatique ; `semi` : une question avant.
- **Typo / correction cosmétique** → `Edit` direct, l'équipe est surqualifiée.
- **Bug existant** → `/fix-bug` (cause racine, test de reproduction, preuve inversée), ou `/investigate-bug` seul pour la cause racine.
- **Question / explication** → pas besoin de coder, répondre.
- **Refacto interne** → taille S : `/dev-express` ; taille M : `/fullstack-lead-tech` puis implémentation directe.

## Skills et agents utilisés

| Skill | Phase |
|---|---|
| `/dev-express` | 0 (bascule) |
| `/redige-us` | 2 (via `po-metier`) |
| `/fullstack-lead-tech` | 5 |
| `/verify`, `/pre-mortem` | 6 (dans chaque worker / chemin sensible) |
| `/review-pr` | 6 (jouée par l'orchestrateur, pipeline complet) |
| `/qa-flow` | 7 (correction d'un échec en `--last-failed`) |
| `/ship-pr` | 8 (règles du body de PR appliquées par l'orchestrateur) |
| `/retro` | suggéré en fin de run, invoqué manuellement après merge |
| `/close-session` | après merge de la dernière tranche |

## Modèle et effort par agent

Règle : **la réflexion se porte sur le modèle le plus fort** (session, orchestrateur, conseil d'architecture, passes qui bloquent) ; un modèle plus léger **exécute des tâches cadrées par un mandat**. Un appel qui s'écarte du frontmatter passe `model` explicitement.

| Agent | Modèle | Raison |
|---|---|---|
| `full-stack-lead` | Opus, effort élevé | Architecture, détection des pièges (Round 1, plan) |
| `full-stack-worker` | Opus, effort `high` | Exécute une tranche avec le plan complet en main |
| `cso` | Opus en passe finale (Phase 6/7) · Sonnet en Round 1/2, `model` explicite | Modèle de menace quand il bloque ; un avis parmi d'autres en Round |
| `po-metier`, `designer-uxui`, `integrateur`, `data-engineer`, `qa`, `ai-llm-engineer` | Sonnet | Rédaction, application d'un système existant, cartographie |

Les agents de review (`review-finder`, `review-verifier`) et `pre-mortem-adversaire` tiennent leur réglage de leur propre skill.

## Coût tokens — annonce obligatoire

Au lancement (Phase 0), afficher avant de commencer :

```
💰 Estimation coût — /call-tech-lead
Scope détecté : <routing preview> · Agents : <liste> (<N>) · Mode : <semi|auto> · Depth : <lean|standard|full>
Tranches prévues : <N> · Tokens estimés : <X-Yk> · Équivalent API : ~$<Z> (review incluse)
Continuer ? (y/n) — en mode semi uniquement
```

En `auto` : affiche l'estimation et continue. Le pipeline de review pèse l'essentiel du coût d'un run : le profil `lean` et un Round 2 sauté sont les deux leviers principaux. Détail : `docs/COUTS-LLM.md` si le projet le tient.

## Résumé final — obligatoire à la fin du run

En plus du TRANSCRIPT, un résumé en français **compréhensible sans lire le code** : contexte (avec les mots de l'utilisateur), ce qui a été fait (impact visible, avant/après), tableau des PR (lien + ce que ça change), ce qui n'est pas fait et pourquoi, décisions prises en autonomie (mode auto), test manuel, coût. Un seul résumé pour un run multi-PR, placé avant toute autre proposition. Règles de restitution : `_partage/fil-de-progression.md`.

## Anti-patterns de l'orchestrateur

- ❌ Orchestrer une feature triviale (bascule `/dev-express`, Phase 0).
- ❌ Sauter le Round 1 sur un sujet ambigu ; lancer le Round 2 sans friction actionnable ; supprimer un débat critique (sécurité, données, IA, architecture) qui diverge vraiment.
- ❌ Écrire du code de tranche dans le contexte de l'orchestrateur (même une petite correction) : toujours un worker.
- ❌ Empiler Tn+1 sur Tn non mergée.
- ❌ Merger la PR sans ordre explicite ; exécuter une migration.
- ❌ Cacher un auto-arbitrage en mode auto : tout arbitrage est traçable dans le TRANSCRIPT.
- ❌ Continuer après qu'un agent (notamment `cso`) a posé un 🔴 bloquant non mitigé.
- ❌ Oublier le résumé final en français.

## Référence

- Agents : `.claude/agents/{full-stack-lead, full-stack-worker, po-metier, qa, cso, data-engineer}.md`{{#IF HAS_DESIGN_SYSTEM}}, `designer-uxui.md`, `integrateur.md`{{/IF}}{{#IF HAS_AI_FEATURE}}, `ai-llm-engineer.md`{{/IF}}
- Skills : `.claude/skills/{dev-express, redige-us, fullstack-lead-tech, verify, review-pr, qa-flow, ship-pr}/SKILL.md`
- `docs/GUIDE-LLM.md` : source de vérité projet (§12 pièges connus)
- PR toujours `--base {{GIT_DEFAULT_BRANCH}}`{{#IF HAS_MIGRATIONS}} ; l'utilisateur joue les migrations lui-même{{/IF}}
