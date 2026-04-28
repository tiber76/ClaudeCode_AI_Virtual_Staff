---
name: qa-flow
description: |
  Lance la suite de tests appropriée (E2E smoke → critical → full) sur le périmètre
  touché et corrige les échecs de manière itérative avec `--last-failed`. Respecte
  la règle GUIDE-LLM §4 : ne jamais relancer la suite complète pour corriger 2-3 tests.
  Produit un rapport before/after avec la liste des tests verts et les fix proposés.
  Invoquer quand une feature est prête à tester ou qu'un test a échoué et qu'on
  veut le corriger proprement.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$qa-flow` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $qa-flow

## Objectif
Garantir qu'une feature est testée à tous les niveaux (unit + intégration + E2E) avant d'aller en PR. Diagnostiquer et corriger les échecs sans gaspiller de temps.

## Quand l'utiliser
- Une feature est codée, on veut valider avant `$review-pr` et `$ship-pr`.
- Un test E2E a échoué et on veut le corriger proprement.
- Après un refactoring, pour s'assurer qu'aucune régression.

## Principes
1. **Pyramide de tests** : unit (rapide) → intégration → E2E smoke → E2E critical → E2E full. Escalader seulement si les précédents passent.
2. **Ne JAMAIS relancer la suite E2E complète pour fixer 2-3 tests** : `{{CMD_E2E_LAST_FAILED}}` en boucle (cf. §4).
3. **Diagnostiquer avant de fixer** : lire le test + le source + les logs avant de modifier quoi que ce soit.
4. **Proposer le fix, ne pas l'appliquer sans validation** — sauf si le bug est trivial (typo, import manquant) ou que l'utilisateur a dit "corrige en autonomie".
5. **Ne pas contourner un test qui échoue** : si le test révèle un vrai bug, on corrige le code, pas le test.

## Étapes

### 1. Identification du périmètre
```bash
git diff {{GIT_DEFAULT_BRANCH}} --name-only
```
Lister les fichiers touchés → identifier les zones à re-tester en priorité.

### 2. Tests unit + API (rapide, ~30s)
```bash
{{CMD_UNIT_TEST}}
```
- Si ✅ → continuer.
- Si ❌ → lire l'échec, diagnostiquer, proposer fix. Ne pas passer à l'étape suivante tant que c'est rouge.

### 3. Tests d'intégration
```bash
{{CMD_INT_TEST}}
```
⚠️ Exécution séquentielle (cf. §4) — voir `{{CMD_INT_TEST}}` pour les options projet.

### 4. E2E Smoke (~30s)
```bash
{{CMD_E2E_SMOKE}}
```
Si ✅ → proposer la suite.

### 5. E2E Critical (~2-3 min)
```bash
{{CMD_E2E_CRITICAL}}
```
Demander à l'utilisateur si on enchaîne sur la suite full avant PR, ou si on s'arrête là.

### 6. E2E Full (~6 min) — obligatoire avant PR
```bash
{{CMD_E2E_FULL}}
```

### 7. Boucle de correction
Si des tests échouent à n'importe quelle étape :
1. Lister les tests failed (le runner E2E génère un résumé).
2. Pour chaque test :
   - Lire le test (`{{DIR_TESTS_E2E}}<nom>.spec.*`).
   - Lire le code source concerné.
   - Analyser l'assertion qui fail : attend quoi ? trouve quoi ?
   - Consulter les pièges §12 pour voir si un pattern connu s'applique.
   - Proposer le diagnostic + fix.
3. Après fix → `{{CMD_E2E_LAST_FAILED}}` (JAMAIS la suite complète pour 2-3 tests).
4. Répéter jusqu'au vert.
5. Une fois tout vert avec `--last-failed` → faire UN run complet final pour confirmer qu'aucune autre régression n'est apparue.

### 8. Rapport final

```markdown
# QA Flow — <branche>

**Date** : <YYYY-MM-DD HH:MM>
**Périmètre** : <N fichiers touchés>

## Tests exécutés

| Niveau | Commande | Statut | Durée |
|---|---|---|---|
| Unit + API | `{{CMD_UNIT_TEST}}` | ✅ / ❌ | Xs |
| Intégration | `{{CMD_INT_TEST}}` | ✅ / ❌ | Xs |
| E2E Smoke | `{{CMD_E2E_SMOKE}}` | ✅ | ~30s |
| E2E Critical | `{{CMD_E2E_CRITICAL}}` | ✅ | ~3min |
| E2E Full | `{{CMD_E2E_FULL}}` | ✅ | ~6min |

## Échecs rencontrés et corrigés
1. **<nom du test>** — `<fichier>:<ligne>`
   - Diagnostic : <cause racine>
   - Fix appliqué : <description + commit si fait>

## État final
- ✅ Tous les tests verts
- ✅ Prêt pour `$ship-pr`

## (Optionnel) Suggestions de tests manquants
- <ex: logique X dans le rendu client non couverte — voir §4 régressions>
```

## Anti-patterns à éviter
- ❌ Relancer la suite E2E complète pour fixer 2-3 tests (très coûteux, cf. §4).
- ❌ "Commenter" un test qui échoue pour faire passer la CI.
- ❌ Modifier un test pour matcher le nouveau comportement sans vérifier que l'ancien comportement n'était pas le bon.
- ❌ Passer à l'étape suivante tant qu'une étape amont est rouge.
- ❌ Mocker en E2E (les E2E doivent tester le vrai flow).

## Référence GUIDE-LLM
- §4 Tests (stratégie, règle E2E avant PR, checklist obligatoire)
- §12 Pièges connus (régressions sur rendu client)

## 💰 Coût indicatif

Tokens : ~30-100k brut · ~15-35k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.4
Détail complet et optimisations : `docs/COUTS-LLM.md`.
