---
name: retro-campagne
description: |
  Post-mortem d'une campagne / landing / séquence growth : 3 points "a marché",
  3 points "a coincé", écarts vs objectifs du brief, 1-3 next bets pour itérer.
  Produit un rapport court actionnable dans docs/growth/retros/RETRO-<slug>.md.
  Propose un ajout aux playbooks agents si leçon transverse détectée. Invoquer
  après une campagne livrée + fenêtre d'évaluation écoulée (14-30-90j selon nature).
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
triggers:
  - retro campagne
  - post-mortem campagne
  - bilan campagne
---

# /retro-campagne

## Objectif

Produire un **bilan honnête et actionnable** d'une initiative growth, en **moins de 600 mots**. Capter les apprentissages pour ne pas les reperdre, proposer 1-3 prochaines actions.

**Règle** : la retro ne juge pas, elle apprend. Pas de "coupable" mais des "leçons transverses".

## Format d'invocation

```
/retro-campagne <slug-campagne>
```

Le slug pointe vers `docs/growth/BRIEF-<slug>.md` et les livrables dans `docs/growth/<sous-dossier>/<slug>/`.

## Flux

### 1. Collecte

Lit :
- Le brief initial `docs/growth/BRIEF-<slug>.md` (objectifs, KPI primaire, anti-KPI)
- Les livrables produits
- Les données réelles (coord `marketing-analytics` si dispo)
- Le TRANSCRIPT d'orchestrateur si invoqué via `/call-growth-lead`

### 2. Calcul écarts

Confronte les résultats aux objectifs du brief :

| KPI | Cible brief | Réel | Écart | Verdict |
|---|---|---|---|---|
| <KPI primaire> | <cible> | <réel> | <écart> | 🟢/🟡/🔴 |
| CPL canal primaire | <cible> | <réel> | <écart> | 🟢/🟡/🔴 |
| <KPI secondaire> | <cible> | <réel> | <écart> | 🟢/🟡/🔴 |

Si **data non dispo** : noter "à mesurer, retro préliminaire sur qualitatif".

### 3. Debrief qualitatif

#### Ce qui a marché (3 points max)

Format obligatoire :
- **<Quoi>** : description courte
- **Pourquoi on pense que ça a marché** : hypothèse argumentée
- **À capitaliser** : action concrète pour réutiliser

#### Ce qui a coincé (3 points max)

Format obligatoire :
- **<Quoi>** : description courte, sans désigner de coupable
- **Cause probable** : hypothèse argumentée (process, message, canal, timing, instrumentation)
- **À corriger** : action concrète pour ne pas reproduire

#### Ce qu'on a appris (transverse)

Leçons qui dépassent cette campagne, utiles pour les prochaines :
- Sur l'**ICP** : <…>
- Sur le **canal** : <…>
- Sur le **message** : <…>
- Sur le **process** : <…>

### 4. Next bets (1-3 max)

Propositions itératives priorisées :

| Bet | Hypothèse | Effort | Impact attendu |
|---|---|---|---|
| <…> | <…> | S/M/L | <…> |

### 5. Ajout aux playbooks agents (si transverse)

Si la leçon est **transverse** (pas spécifique à cette campagne), propose :

- Ajout dans `.claude/agents/<agent>.md` section "Anti-patterns" ou "Style"
- Exemple générique : "Désormais, le `copywriter-brand` exige un moodboard visuel joint au brief avant production landing, car l'absence a coûté N rounds d'itération sur la dernière campagne."

Demande confirmation avant d'écrire dans l'agent.

### 6. Sauvegarde

Rapport court dans `docs/growth/retros/RETRO-<slug>-<YYYY-MM-DD>.md`.

## Template retro complet

```markdown
# Retro — <titre campagne>

**Slug** : <slug>
**Date retro** : <YYYY-MM-DD>
**Période couverte** : <date début> → <date fin>
**Brief de référence** : `docs/growth/BRIEF-<slug>.md`
**Équipe impliquée** : <agents>

---

## 🎯 Rappel objectifs (du brief)

- Objectif primaire : <…>
- KPI primaire : <…> (cible <…>)
- KPI secondaires : <…>
- Anti-KPI : <…>

---

## 📊 Résultats chiffrés

| KPI | Cible | Réel | Écart | Verdict |
|---|---|---|---|---|
| <…> | <…> | <…> | <…> | 🟢/🟡/🔴 |

**Data source** : <events {{STACK_DATABASE}} | analytics | qualitatif>
**Limites mesure** : <…>

---

## ✅ Ce qui a marché (top 3)

### 1. <…>
- **Description** : <…>
- **Pourquoi probablement** : <…>
- **À capitaliser** : <…>

### 2. <…>
[idem]

### 3. <…>
[idem]

---

## ❌ Ce qui a coincé (top 3)

### 1. <…>
- **Description** : <…>
- **Cause probable** : <…>
- **À corriger** : <…>

### 2. <…>
[idem]

### 3. <…>
[idem]

---

## 💡 Leçons transverses

- Sur l'**ICP** : <…>
- Sur le **canal** : <…>
- Sur le **message** : <…>
- Sur le **process** : <…>

---

## 🎯 Next bets (1-3 max)

| Bet | Hypothèse | Effort | Impact attendu | Owner |
|---|---|---|---|---|
| <…> | <…> | <S/M/L> | <…> | <agent> |

---

## 🧠 Ajouts suggérés aux playbooks agents

- [ ] `.claude/agents/<agent>.md` → ajout anti-pattern : <texte>
- [ ] `.claude/agents/<agent>.md` → ajout référence : <texte>

**Décision humain** : appliquer ? (oui / non / modifier)

---

## 🔗 Prochains rendez-vous

- [ ] Retro exécution fixes : <date>
- [ ] Next audit funnel : <date>
- [ ] Prochaine campagne similaire : <date>
```

## Règles

- ❌ **Pas de "coupable"** : critique les **décisions**, pas les **personnes/agents**.
- ❌ **Max 3 points par section** → focus. Si 8 "ça a marché", c'est que tu n'as rien priorisé.
- ❌ **Pas de conclusion si data insuffisante** → note "retro préliminaire" et propose fenêtre d'évaluation étendue.
- ✅ **Chiffres réels uniquement** → placeholder si pas encore mesuré.
- ✅ **Next bets testables** → pas "améliorer la conversion", mais "tester CTA B sur landing X, N visits/variant, p<0.05".

## Anti-patterns

- ❌ Retro auto-congratulante ("tout a été super") → creuse les écarts
- ❌ Retro dépressive ("rien ne marche") → sort au moins 1 apprentissage positif
- ❌ Retro sans next bet actionnable → perdue pour l'avenir
- ❌ Retro > 1 page A4 → trop long, personne ne la relit
- ❌ Retro écrite juste après le lancement (J+3) → attendre fenêtre d'évaluation (14-30-90j selon nature)
- ❌ Leçons transverses non proposées en ajout playbooks → le savoir se perd

## Cadence recommandée

| Nature campagne | Fenêtre d'évaluation avant retro |
|---|---|
| Landing + trafic payant | 14 jours (après stabilisation CPL) |
| Séquence outbound | 30 jours (cycle réponses complet) |
| Guide SEO / cornerstone | 90 jours (rampe SEO) |
| Onboarding / activation flow | 30 jours (1 cohorte complète aha→habit) |
| QBR / étude de cas | N/A (retro = pas de data mesurable mais process) |

## Référence

- `.claude/skills/call-growth-lead/SKILL.md` — priorisation next bets
- `.claude/agents/marketing-analytics.md` — mesure écarts
- `.claude/skills/retro/SKILL.md` — retro côté dev (même esprit)
- `docs/growth/retros/` — retros existantes

## 💰 Coût indicatif

Tokens : ~30-80k brut · ~10-25k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.3
Détail complet et optimisations : `docs/COUTS-LLM.md`.
