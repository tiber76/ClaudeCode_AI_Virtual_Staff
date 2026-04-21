# Coûts LLM — Estimations & optimisations {{PROJECT_NAME}}

Estimations des coûts d'usage des skills et agents, par run. À actualiser avec les vrais chiffres observés sur ton plan.

---

## Prérequis — tarification Anthropic (référence)

| Modèle | Input / 1M tokens | Cached input (90% discount) / 1M | Output / 1M tokens |
|---|---|---|---|
| Claude Opus | $15 | $1.50 | $75 |
| Claude Sonnet | $3 | $0.30 | $15 |
| Claude Haiku | $1 | $0.10 | $5 |

**Prompt caching** : après le premier appel qui écrit le cache (coût +25% sur le chunk caché), les appels suivants dans les 5 min lisent à 10% du prix normal.

---

## Estimations par skill (run moyen)

| Skill | Tokens brut | Avec cache 90% | Équivalent API | % session Opus 5h (Max 20x) |
|---|---|---|---|---|
| `/call-tech-lead` (feature complète, 6 agents) | 600k-1.4M | 150-350k | **$2-5** | 5-10% |
| `/call-tech-lead` (refacto simple) | 200-400k | 50-100k | $0.7-1.5 | 2-3% |
| `/call-growth-lead` (initiative 6 agents) | 300-800k | 80-230k | **$1-4** | 3-8% |
| `/audit-funnel`, `/ship-landing` (solo) | 80-200k | 30-60k | $0.4-1 | 1-2% |
| `/redige-us`, `/redige-brief`, `/retro*` | 30-80k | 10-25k | $0.1-0.3 | <1% |
| Agent solo (invocation directe) | 20-50k | 10-20k | $0.05-0.5 | <1% |

---

## Répartition type d'un `/call-tech-lead` complet

| Phase | Tokens | % total |
|---|---|---|
| 0-1 Intake & routing | 15-30k | 3% |
| 2 PO rédige US | 40-80k | 8% |
| 3 Round 1 (5 agents) | 200-350k | 40% |
| 4 Débats Round 2 | 60-200k | 15% |
| 5 Plan final | 50-120k | 12% |
| 6 Implémentation | 150-400k | 25% |
| 7 Review + QA | 50-150k | 10% |
| 8 Ship | 15-30k | 3% |
| **Total brut** | **600k-1.4M** | — |
| **Effective avec cache** | 150-350k | — |
| **Équivalent API** | **$2-5** | — |

---

## Top 10 optimisations SANS baisse de qualité

### 1. Refus d'orchestrer les triviaux — économie 80-95%
Le skill doit refuser de convoquer l'équipe pour : typo, one-liner, refacto mineur, question de doc. Propose direct `Edit` ou `/investigate-bug`.

### 2. Fournir le contexte précis en input — économie 20-40%
Plus tu donnes de contexte pertinent (fichiers concernés, US existante, contraintes), moins les agents consomment en clarification.

### 3. Réutiliser les artefacts — économie 30%
Au lieu de `/call-tech-lead "implémente X"`, passer `/call-tech-lead "implémente PLAN-X.md"` référence un plan déjà produit.

### 4. Agent solo pour questions fermées — économie 90%
"Demande à `sales-b2b` : comment répondre à 'on a déjà Lever' ?" — pas besoin d'orchestrateur complet.

### 5. `/fullstack-lead-tech` seul si US claire — économie 60-80%
Si tu as une US bien cadrée et que tu n'as pas besoin de débats, `/fullstack-lead-tech` produit le plan tech direct, sans orchestration multi-agents.

### 6. Mode auto pour runs longs sans décision critique
Libère le dev (pas de checkpoints), budget préservé sur des features "classiques".

### 7. Mode semi pour runs à risque
Les checkpoints évitent des runs perdus si l'orchestrateur part dans une mauvaise direction.

### 8. Scope agents explicite — économie 15-30%
"Skip cso, pas de signal sécu" — évite de convoquer un agent inutile.

### 9. Prompt caching préservé
Variables dans le user message, pas le system prompt. Voir [`PATTERNS.md`](../starter-kit-equipes-claude/PATTERNS.md) Pattern 3.

### 10. Répartition Opus/Sonnet optimisée
Seuls 2 agents en Opus par défaut (full-stack-lead, cso côté tech ; growth-lead, sales-b2b côté growth). Les autres en Sonnet. Voir [`PATTERNS.md`](../starter-kit-equipes-claude/PATTERNS.md) Pattern 2.

---

## Leviers à éviter (qui dégradent la qualité)

- ❌ **Passer tous les agents en Haiku** : la qualité de raisonnement s'effondre sur les arbitrages complexes.
- ❌ **Sauter la phase 3 round 1** : les avis indépendants sont la base de la valeur de l'orchestration.
- ❌ **Squeezer les débats phase 4** : c'est là que les frictions sont arbitrées.
- ❌ **Refuser tous les checkpoints en mode semi** : tu perds le contrôle direction.
- ❌ **Donner trop peu de contexte en input** : les agents vont le réclamer en rounds de clarification (plus cher).

---

## Budget sur plan Claude Max 20x

Typiquement :
- **1 run `/call-tech-lead` ≈ 5-10% d'une session Opus 5h**
- Budget confortable : **60-160 runs `/call-tech-lead` / semaine** sans toucher le weekly cap Opus
- Si tu approches le cap Opus : passe `full-stack-lead` et `cso` en Sonnet temporairement.

---

## Tracking réel

Pour tracker tes vrais coûts :

1. Console Anthropic → usage par API key
2. Sentry / Datadog → metrics custom si tu logues les runs
3. `TRANSCRIPT.md` → chaque run orchestré indique son coût final en pied de page

Actualise ce fichier tous les 3 mois avec les vrais chiffres observés.
