---
name: redige-brief
description: |
  Transforme un besoin commercial/marketing en texte libre en brief structuré
  et exploitable (SMART + canal + budget + KPI + deadline + livrables). Pose un
  minimum de questions de clarification, puis produit le brief au format standard.
  Sauvegarde dans docs/growth/BRIEF-<slug>.md. Invoquer dès qu'une idée de
  campagne/contenu/outbound est lancée et qu'on veut la formaliser avant
  d'exécuter.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$redige-brief` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $redige-brief

## Objectif

Formaliser un besoin commercial ou marketing en **brief exploitable** : objectif SMART, cible, canal, budget, KPI de succès, deadline, livrables. Point d'entrée avant toute exécution (campagne, landing, séquence, guide).

## Format d'invocation

```
$redige-brief <besoin en texte libre>
```

## Flux

### 1. Parse le besoin

- Identifie le **type** : campagne acquisition / campagne rétention / landing / séquence outbound / série contenu / audit / autre
- Identifie la **cible apparente** (ICP primaire / secondaire / multi — selon la segmentation du projet)
- Identifie le **canal apparent** (SEO / LinkedIn / Email / Google Ads / outbound / autre / multi)

### 2. Pose les questions manquantes (question utilisateur)

**Règle** : max 4 questions, pas 10. Si une info manque et qu'une hypothèse raisonnable existe, utilise l'hypothèse et documente-la.

Questions types :
- **Objectif chiffré** : "Quel résultat mesurable tu vises ? (ex : +N signups qualifiés, +X sessions organiques, N démos sur segment cible)"
- **Deadline** : "Deadline cible ? (30j / 90j / Q2…)"
- **Budget** : "Budget indicatif ? (0€ / <1k / 1-5k / 5-20k / >20k)"
- **Contraintes** : "Blocage connu ? (pas d'accès au segment cible, pas de témoignage client…)"

### 3. Génère le brief

Format standardisé (voir template ci-dessous), sauvegardé dans `docs/growth/BRIEF-<slug>.md`.

### 4. Affiche au user

Affiche le brief dans le chat + chemin du fichier. Propose :
> "Brief prêt. Tu peux l'exécuter avec `$call-growth-lead <même besoin>` pour orchestrer l'équipe, ou partir directement vers un skill ciblé (`$ship-landing`, `$audit-funnel`…)."

## Template brief standard

```markdown
# BRIEF — <titre initiative>

**Slug** : <slug>
**Date** : <YYYY-MM-DD>
**Status** : 📝 Draft

---

## 🎯 Objectif (SMART)

**Quoi** : <action concrète>
**Résultat mesurable** : <chiffre + métrique>
**Délai** : <date cible ou durée>
**Atteignable** : <hypothèses sur lesquelles l'objectif repose>
**Pertinent** : <pourquoi maintenant / pourquoi cette priorité>

Exemple rempli :
> Quoi : Générer N signups qualifiés sur l'ICP primaire
> Mesurable : via source=<slug-campagne> + intent=<plan cible si {{#IF HAS_PRICING_TIERS}}pricing tier{{/IF}}>
> Délai : <date cible> (90j)
> Atteignable : repose sur hypothèse ICP <taille/secteur>, budget canal <€>, CPL attendu <€>
> Pertinent : segment avec upside ARPA ou volume justifiant la priorisation

---

## 👥 Cible

**ICP primaire** : <segment défini dans le positionnement {{PROJECT_NAME}}>
**Persona décideur** : <rôle + entreprise type>
{{#IF IS_B2B}}
**Persona influenceur** : <rôle>
{{/IF}}
**Douleur clé** : <1 phrase>
**Taille audience estimée** : <volume>

---

## 📡 Canal & mix

**Canal primaire** : <SEO / LinkedIn Ads / LinkedIn Organic / Google Ads / Email / Outbound / Partner / Content / App Store / autre>
**Canaux secondaires** : <…>
**Justification mix** : <pourquoi ce canal pour ce persona et ce stage du funnel>

---

## 🪙 Budget

**Paid media** : <€>
**Outils** (tracking, automation…) : <€>
**Salaires / agents temps** : <jours-homme estimés>
**Total estimé** : <€>

---

## 🎯 KPI de succès

**Primaire** (UN seul) : <métrique + seuil>
Ex : Taux conversion visit → signup ≥ X% sur la landing dédiée.

**Secondaires** (2-3 max) : <métrique + seuil>
Ex :
- CPL paid < <€>
- Taux activation trial → aha ≥ X%
- % signups qualifiés ICP cible ≥ X%

**Anti-KPI** (ce qu'on ne veut pas voir bouger mal) : <…>
Ex : Churn mensuel ne doit pas dépasser X% sur les nouveaux signups.

---

## 🧱 Livrables attendus

| Livrable | Owner (agent) | Format | Deadline |
|---|---|---|---|
| Landing page dédiée | copywriter-brand + designer-uxui | Markdown + composants front | J+7 |
| Séquence email onboarding (N emails) | copywriter-brand | Markdown | J+10 |
| 2 variants Ad (canal primaire) | copywriter-brand | Markdown + brief visuel | J+5 |
| Tracking plan events + UTM | marketing-analytics | Doc spec | J+3 |
| Dashboard suivi | marketing-analytics + data-engineer | Doc spec | J+14 |

---

## ⛔ Hors scope

Ce que cette initiative ne fait PAS (éviter scope creep) :
- <…>
- <…>

---

## 🔗 Dépendances

- <ex : feature X doit être shipée avant lancement>
- <ex : étude de cas Client Y doit être validée>

---

## 📉 Risques

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| CPL canal > cible | Moyenne | Fort | Kill switch après <€> spend si CPL > seuil |
| Activation < cible | Faible | Fort | Onboarding email J+1 + relance J+3 |

---

## 📆 Timeline

```
S+0 : Brief validé + kickoff
S+1 : Livrables copy prêts + tracking live
S+2 : Landing + assets prêts
S+3 : Lancement campagne
S+4 à S+12 : Exécution + optimisation
S+13 : Retro (via $retro-campagne)
```

---

## 🗒️ Hypothèses & décisions prises

- <hypothèse 1 si info manquante — ex : "Budget supposé <€> canal X, à confirmer">
- <décision 1 — ex : "Plan cible <tier> car segment = ARPA supérieur">
```

## Règle chiffres

- **Benchmarks marché sourcés** OK (CPL {{PROJECT_TYPE}} typique, taux conversion landing 2-5%…)
- **Chiffres {{PROJECT_NAME}}** : si non dispos, placeholder `<À mesurer>`
- **Jamais inventer** une métrique pour "faire beau"

## Anti-patterns

- ❌ Brief sans métrique primaire chiffrée
- ❌ Brief avec 5+ KPI primaires (dilution focus)
- ❌ Pas de deadline
- ❌ Pas d'anti-KPI (oublie les effets de bord)
- ❌ Livrables sans owner ni format
- ❌ Budget "on verra"
- ❌ ICP vague → exige taille + secteur + persona

## Référence

- `.agents/skills/call-growth-lead/SKILL.md` — arbitrage stratégique
- `docs/growth/BRIEF-*.md` — briefs existants

## 💰 Coût indicatif

Tokens : ~30-60k brut · ~10-20k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.25
Détail complet et optimisations : `docs/COUTS-LLM.md`.
