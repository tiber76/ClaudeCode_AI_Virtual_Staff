---
name: investigate-bug
description: |
  Méthodologie root-cause avant de patcher : récolte des faits, hypothèses priorisées,
  vérifications ciblées, identification de la cause racine (pas du symptôme), match
  avec les pièges connus §12. Propose 2 fixes (minimal + robuste) avec trade-offs
  et un test de non-régression. Invoquer dès qu'un bug est signalé, avant toute
  modification de code.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
triggers:
  - investigate
  - debug ce bug
  - root cause
  - pourquoi ça bug
  - trouve la cause
---

# /investigate-bug

## Objectif
Trouver la **cause racine** d'un bug avant de le patcher, pour éviter le "j'ai appliqué un fix qui marche mais je ne sais pas pourquoi". Aboutit à 2 options de fix + un test qui échouerait sans le fix.

## Quand l'utiliser
- Un bug est signalé (par l'utilisateur, les logs, un test).
- Avant de toucher au code — jamais l'inverse.
- Si un fix "évident" a déjà été tenté sans succès, pour reprendre depuis zéro proprement.

## Principes
1. **Facts before theories.** Récolter tous les faits observables avant toute hypothèse.
2. **Symptôme ≠ cause.** Le test échoue = symptôme. Pourquoi il échoue = cause.
3. **Pas de "fix and pray".** Si on n'explique pas pourquoi le fix marche, on n'a pas trouvé la cause.
4. **Test avant fix.** Le test qui reproduit le bug doit être écrit AVANT le fix — c'est lui qui prouve qu'on a bien corrigé.
5. **Ne pas modifier le code dans ce skill.** Proposer, pas exécuter.

## Étapes

### 1. Récolte des faits
Demander à l'utilisateur (ou déduire du contexte) :
- **Symptôme exact** : qu'est-ce qui ne marche pas ? (message d'erreur, comportement observé)
- **Attendu** : qu'est-ce qui devrait se passer ?
- **Reproduction** : étapes précises pour reproduire. Si non reproductible → flag intermittent (cas spécial).
- **Environnement** : local / staging / prod ? Navigateur ? Rôle utilisateur ?
- **Fréquence** : toujours, parfois, depuis quand ?
- **Changements récents** : `git log --since='7 days ago' --oneline` sur la zone touchée.

### 2. Localisation
- Identifier le(s) fichier(s) probable(s) via grep du message d'erreur, ou via la trace de la stack.
- Lire le code concerné sans préjugés.
- Identifier les zones adjacentes (fonctions appelées, handlers amont/aval).

### 3. Hypothèses (min 3)
Lister 3 à 5 causes possibles, classées par probabilité :

```markdown
| # | Hypothèse | Probabilité | Vérification |
|---|---|---|---|
| 1 | <la plus probable> | Élevée | Commande/lecture pour confirmer |
| 2 | ... | Moyenne | ... |
| 3 | ... | Faible | ... |
```

Éviter le biais de confirmation : toujours inclure au moins une hypothèse "contre-intuitive".

### 4. Vérification
Pour chaque hypothèse, exécuter la vérification (grep, lecture, test isolé, requête DB). Sortie attendue : **confirmée / infirmée / non concluante**.

### 5. Match avec les pièges connus §12
Vérifier systématiquement si une classe de bug documentée s'applique. Exemples génériques :
- [ ] Filtrage serveur vs client (données manquantes après reload par désynchro de filtre)
- [ ] Fonctions / variables avec le même nom (écrasement silencieux par ordre de chargement)
- [ ] Saves async : doublon de fonctions `save()` vs `saveXxxV2()`, `.then()` manquant, debounce qui annule la dernière écriture
- [ ] Régression rendu client (scripts de `{{DIR_COMPONENTS}}` ou page statique, filtrage temporel cassé)
- [ ] Erreur de syntaxe dans un fichier chargé globalement (casse toute l'UI)
- [ ] Schéma DB réel vs migration non appliquée en staging/prod
- [ ] Colonnes attendues mais inexistantes sur certaines tables (ex: `updated_at` absent)
- [ ] Entités archivées/soft-deleted exclues par défaut du GET (appel explicite manquant)
{{#IF HAS_RATE_LIMITING}}
- [ ] CSP `connect-src` manquant pour un domaine externe (blocage silencieux)
- [ ] Rate-limit trop agressif ou bypassé selon l'endpoint
{{/IF}}
- [ ] Handlers inline HTML (bloqués par nonce CSP strict)
- [ ] Scripts chargés en lazy sans garde `typeof fn === 'function'`
- [ ] Test E2E en serial vs parallel : cleanup partagé qui pollue les workers

Si match → c'est probablement la cause. Citer la section.

### 6. Cause racine
Rédiger la cause racine en 1-3 phrases. Elle doit répondre à :
- **Qu'est-ce qui fait que le bug se produit ?**
- **Pourquoi c'est arrivé maintenant ?** (changement récent, condition rare, etc.)
- **Est-ce que d'autres endroits sont impactés ?**

Si on ne peut pas répondre aux 3 → creuser encore. Pas de fix tant que pas de réponse claire.

### 7. Deux options de fix

```markdown
## Option A — Patch minimal
- **Changement** : <1-3 lignes>
- **Fichiers touchés** : <liste>
- **Risque** : faible / moyen / élevé
- **Effet** : règle le symptôme immédiat
- **Limites** : ne résout pas <cas adjacent>

## Option B — Fix robuste
- **Changement** : <refonte/extraction/guard>
- **Fichiers touchés** : <liste>
- **Risque** : ...
- **Effet** : élimine la classe entière de bugs similaires
- **Coût** : ... (plus de lignes, refactor potentiel)
```

Recommander l'une explicitement avec justification.

### 8. Test de non-régression
Proposer le test (code exact) qui :
- Échoue aujourd'hui (reproduit le bug).
- Passera après le fix.

Choix du niveau :
- Bug de logique → test unitaire (`{{DIR_TESTS_UNIT}}`).
- Bug de flux → test d'intégration (`{{DIR_TESTS_INT}}`).
- Bug visible uniquement dans le navigateur → E2E (`{{DIR_TESTS_E2E}}`).

Règle §4 : toujours préférer le niveau le plus bas possible qui reproduit.

### 9. Rapport final

```markdown
# Investigation — <titre court du bug>

**Date** : <YYYY-MM-DD>
**Statut** : diagnostiqué, fix proposé (non appliqué)

## Symptôme
<description observée>

## Attendu
<comportement attendu>

## Reproduction
1. …
2. …

## Hypothèses testées
| Hypothèse | Résultat |
|---|---|
| H1 | Infirmée (raison) |
| H2 | **Confirmée** (preuve) |
| H3 | Non concluante |

## Cause racine
<1-3 phrases précises>

**Piège connu applicable** : <§12 ref ou "aucun">

## Fix proposé
<Option A ou B recommandée, avec trade-off>

## Test de non-régression (à écrire avant le fix)
\`\`\`js
// <fichier test>
describe(...)  {
  it('...', () => { ... });
}
\`\`\`

## Prochaines étapes
1. Valider le diagnostic.
2. Écrire le test (rouge).
3. Appliquer le fix choisi.
4. Test vert.
5. `/review-pr` → `/qa-flow` → `/ship-pr`.
```

## Anti-patterns à éviter
- Patcher avant d'avoir compris.
- "Ça marche maintenant, je ne sais pas pourquoi" — c'est un red flag, reprendre.
- Modifier le test pour qu'il passe au lieu de corriger le code.
- Ajouter un `try/catch` pour masquer un symptôme.
- Une seule hypothèse (biais de confirmation).

## Référence GUIDE-LLM
- §4 Tests (prévention des régressions sur rendu client)
- §12 Pièges connus (table de match exhaustive)

## Coût indicatif

Tokens : ~50-150k brut · ~20-50k effective (avec prompt caching 90%)
Équivalent API : ~$0.2-0.7
Détail complet et optimisations : `docs/COUTS-LLM.md`.
