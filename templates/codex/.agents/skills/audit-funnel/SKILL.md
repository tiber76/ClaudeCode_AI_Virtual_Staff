---
name: audit-funnel
description: |
  Audit du funnel growth {{PROJECT_NAME}} (Acquisition → Activation → Rétention →
  Revenue → Referral). Lit les métriques dispos (ou pose le tracking plan à
  construire), identifie les 3 fuites prioritaires, propose 3 fixes testables
  avec cadre A/B et sample size. Produit un rapport structuré dans
  docs/growth/audits/FUNNEL-<date>.md. Invoquer trimestriellement ou avant un
  investissement budgétaire growth.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$audit-funnel` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $audit-funnel

## Objectif

Produire un **diagnostic factuel** du funnel growth : où on perd des utilisateurs, combien, pourquoi (hypothèses rangées), et quoi faire (3 fixes testables priorisés).

## Format d'invocation

```
$audit-funnel [--scope=full|acquisition|activation|retention|revenue|referral]
```

- Par défaut : `full` (les 5 étapes AARRR).
- Sinon audit ciblé d'une étape.

## Flux

### 1. Collecte data

**Si {{PROJECT_NAME}} n'a pas encore les events instrumentés** :
- Documenter les métriques manquantes dans `docs/growth/audits/FUNNEL-<date>-tracking-gap.md`
- Proposer le tracking plan à construire (events + UTM + dashboard)
- L'audit devient "audit préliminaire" : hypothèses basées sur benchmarks marché + qualitatif

**Si data dispo** :
- Lire les metrics (requêtes `{{STACK_DATABASE}}`, export analytics — coord `data-engineer`)
- Normaliser par cohortes mensuelles
- Comparer aux benchmarks {{PROJECT_TYPE}} de ton secteur

### 2. Analyse des 5 étapes

Pour chaque étape, produire :

| Étape | Métrique clé | Valeur {{PROJECT_NAME}} | Benchmark ton secteur | Gap | Verdict |
|---|---|---|---|---|---|
| Acquisition | Sessions qualifiées / mois | `<X>` | variable | — | 🟢/🟡/🔴 |
| Activation | % signup → aha <48h | `<Y%>` | <benchmark secteur> | — | — |
| Retention | W4 retention | `<Z%>` | <benchmark secteur> | — | — |
| Revenue | Signup → paid | `<W%>` | <benchmark secteur> | — | — |
| Referral | NPS | `<N>` | <benchmark secteur> | — | — |

**Règle** : si pas de data → `<À mesurer>` + placeholder benchmark.

### 3. Identification des 3 fuites prioritaires

Priorisation par **impact revenue** × **facilité à fixer** :

| Fuite | Volume perdu | Impact €/mois | Effort fix | Priorité |
|---|---|---|---|---|
| <ex : drop à l'activation J+2> | X% des signups | `<à estimer>` | M | P1 |
| <ex : conversion signup→paid> | N pts vs benchmark | `<à estimer>` | H | P2 |
| <ex : bounce landing pricing> | X% | `<à estimer>` | S | P3 |

### 4. 3 fixes testables

Pour chaque P1/P2/P3, format :

```markdown
### Fix #1 — <titre>

**Hypothèse** : En <changement>, on augmente <métrique> de <X%> parce que <raison>.

**Métrique primaire** : <une seule>
**Métriques secondaires** : <2-3>
**Anti-métrique** : <effet de bord à surveiller>

**Variant A (contrôle)** : <description>
**Variant B (test)** : <description>

**Sample size** : <N> par variant (calcul basé sur baseline X%, uplift cible Y%, α=0.05, β=0.2)
**Durée min** : <semaines>
**Budget** : <€ si applicable>
**Critères de décision** :
- Uplift stat sig > <X%> → déploie B
- Pas de diff → garde A (cheaper)
- Uplift négatif stat sig → rollback immédiat

**Propriétaire** : <agent / équipe>
**Livrables requis avant lancement** : <ex : tracking event X, copy variant B>
```

### 5. Plan d'action 90 jours

```
J+0 à J+14 : tracking gap comblé, data consolidée
J+15 à J+30 : lancement Fix #1 (P1)
J+31 à J+60 : mesure Fix #1, lancement Fix #2 si P1 validé
J+61 à J+90 : mesure Fix #2, bilan + next audit
```

### 6. Sauvegarde

Rapport complet dans `docs/growth/audits/FUNNEL-<YYYY-MM-DD>.md`.

## Template rapport complet

```markdown
# Audit funnel {{PROJECT_NAME}} — <YYYY-MM-DD>

**Scope** : <full|étape>
**Auteur** : marketing-analytics (via $audit-funnel)
**Data source** : <events {{STACK_DATABASE}} | analytics | placeholder>
**Période analysée** : <du X au Y>
**Volume dispo** : <nombre d'utilisateurs>

---

## 📊 Executive summary (5 lignes max)

- Health global : 🟢 bon / 🟡 à surveiller / 🔴 rouge
- Fuite #1 critique : <étape + métrique + gap>
- Opportunité #1 : <fix proposé>
- Impact revenue 90j estimé : `<placeholder>` ou <calcul>
- Prochain audit recommandé : <date>

---

## 1. Acquisition

**Métriques** :
- Sessions par source : <table>
- CTR CTA primaire : <valeur>
- Coût par session (paid) : <valeur>
- Share of voice par mot-clé : <top 10>

**Verdict** : 🟢/🟡/🔴 + 2-3 lignes d'analyse

---

## 2. Activation

**Métriques** :
- Signup rate visit→signup : <valeur>
- Activation rate signup→aha : <valeur>
- Time to aha (médiane) : <valeur>
- % revenus J+2 / J+7 : <valeur>

**Verdict** : 🟢/🟡/🔴 + analyse

---

## 3. Retention

**Métriques** :
- WAU : <valeur>
- DAU/WAU ratio : <valeur>
- W1/W4 retention par cohorte : <table>
- Features adoption (top 3 features) : <%>

**Verdict** : 🟢/🟡/🔴 + analyse

---

## 4. Revenue

**Métriques** :
{{#IF HAS_PRICING_TIERS}}
- Conversion signup → paid : <valeur>
- ARPA par plan (voir `{{PRICING_PLANS_LIST}}`) : <table>
- New MRR / Expansion MRR / Churn MRR : <table>
- NRR / GRR : <valeur>
{{/IF}}
- LTV:CAC : <valeur>
- Payback : <valeur>

**Verdict** : 🟢/🟡/🔴 + analyse

---

## 5. Referral

**Métriques** :
- NPS : <valeur + verbatims>
- % nouveaux signups "par recommandation" : <valeur>
- K-factor : <valeur>

**Verdict** : 🟢/🟡/🔴 + analyse

---

## 🎯 Les 3 fuites prioritaires

[détaillées avec fix testable — voir template section 4]

---

## 📆 Plan d'action 90 jours

[planning]

---

## 📡 Gap d'instrumentation

Events manquants à tracker :
- <liste>

Tracking plan à construire (coord `data-engineer` + `full-stack-lead`) : <lien vers spec>

---

## ⚠️ Limites de l'analyse

- Volume < <seuil> : résultats indicatifs, pas stat significatifs
- Période courte (< 3 mois) : effets saisonniers non lissés
- Cohortes non comparables si <condition>

---

## 🔗 Références benchmarks

- <benchmark secteur {{PROJECT_TYPE}} sourcé>
- <benchmark rétention {{PROJECT_TYPE}} sourcé>
- <étude sectorielle spécifique à l'ICP>
- <autres sources citées>
```

## Règles

- ❌ **Jamais inventer** une métrique {{PROJECT_NAME}}. Placeholder `<À mesurer>` obligatoire si data indispo.
- ❌ **Pas de conclusion stat** sur échantillons < 50 par variant → note explicite "non conclusif".
- ❌ **Pas de recommandation budgétaire chiffrée** sans LTV:CAC validé → note "indicatif".
- ✅ Comparer aux benchmarks sourcés de ton secteur, citer la source.
- ✅ Proposer des fixes **testables** (A/B structuré) pas des "améliorations" vagues.

## Anti-patterns

- ❌ Audit "dashboard dump" sans hiérarchie priorités
- ❌ Recommandations non testables ("améliorer l'UX")
- ❌ Pas de sample size calculé pour les fixes
- ❌ Ignorer l'anti-métrique (fix qui améliore A mais casse B silencieusement)
- ❌ "Trafic en hausse" présenté comme succès sans check qualification

## Référence

- `.codex/agents/marketing-analytics.toml` — méthode complète
- `.codex/agents/data-engineer.toml` — construction dashboard
- `.agents/skills/call-growth-lead/SKILL.md` — priorisation stratégique
- `docs/growth/audits/` — audits existants

## 💰 Coût indicatif

Tokens : ~80-200k brut · ~30-60k effective (avec prompt caching 90%)
Équivalent API : ~$0.4-1
Détail complet et optimisations : `docs/COUTS-LLM.md`.
