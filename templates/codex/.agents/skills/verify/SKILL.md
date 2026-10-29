---
name: verify
description: |
  Checklist obligatoire à exécuter AVANT chaque commit qui touche du code applicatif.
  Vérifie : tests verts sur le scope touché, smoke visuel sur le layout réel (si UI),
  edge cases du brief QA effectivement couverts, pas de régression sur les symboles
  changés, logs console propres, git diff --stat cohérent, pièges connus (GUIDE-LLM §12)
  respectés, décision business actée. Trace exigée dans le body du commit et reprise par
  $ship-pr avant gh pr create. Skill court, invocable seul ou enchaîné par les agents dev
  en fin de chaque task TDD.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$verify` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $verify

## Objectif

Bloquer un commit prématuré : une checklist courte et déterministe sur le scope touché, avant que ça parte en commit puis en PR via `$ship-pr`.

**Étape obligatoire** du workflow TDD de chaque agent dev (`full-stack-lead`, `full-stack-worker`, `integrateur`, `ai-llm-engineer`) après RED → GREEN → REFACTOR, avant `git commit`.

## Quand l'utiliser

- **Toujours** avant un commit qui touche du code applicatif (handler API, helper, composant, script client, parser/validator).
- Après chaque task TDD d'un dev pendant `$call-tech-lead`, `$dev-express`, `$fix-bug`.

**Pas requis** sur : migration SQL idempotente seule, docs Markdown pures, config pure, renommage ou déplacement pur sans changement de comportement.

## Quels tests, à quel moment

| Moment | Ce qu'on lance | Commande |
|---|---|---|
| **Cycle TDD** (rouge, vert, refactor) | le seul fichier de test du cas | `{{CMD_UNIT_TEST}}` restreint au fichier |
| **Commit** (item 1) | les suites qui importent les sources touchées | ciblage « tests liés aux sources » de votre runner (ex. `--findRelatedTests`) |
| **Avant de rendre la main** ou `$ship-pr` | la suite entière unit + intégration, **une fois** | `{{CMD_UNIT_TEST}}` puis `{{CMD_INT_TEST}}` ; E2E au niveau calculé par `.codex/hooks/e2e-level.sh` (`$ship-pr` étape 5) |
| **Après un échec de la suite entière** | les seuls fichiers en échec jusqu'au vert, puis la suite entière une dernière fois | fichiers nommés |

- **Ciblée, pas le seul test du lot** : dès que le commit touche un composant ou un helper partagé, lancer les suites qui l'importent, pas seulement le test écrit pour le lot (un test sœur qui rend le même composant casse en silence sinon).
- **Limite du ciblage** : il suit les imports statiques. Un test d'intégration qui atteint la route par HTTP, un `require()` calculé ou un sous-processus ne remontent pas : les nommer à la main.
- **Entière une fois, jamais par commit.** Exception : un commit qui change la config de test elle-même (config du runner, setup, helpers communs) touche toutes les suites, sa suite ciblée est la suite entière.
- **Après un échec : les seuls fichiers en échec**, jamais la suite entière entre deux essais.
- **Au premier plan** : une commande qui tient sous 10 min se lance au premier plan avec un timeout adapté. Jamais d'arrière-plan suivi d'une boucle `sleep` qui guette la sortie.

## Checklist (8 items)

Chaque item produit un statut : ✓ (OK), ⚠️ (à expliquer dans le body du commit), ❌ (bloquant : commit refusé).

### 1. Tests verts sur le scope touché
La suite **ciblée** du commit (voir tableau). ✓ tous verts, dont les tests rouges écrits dans cette task qui sont passés au vert. ❌ un test rouge, un skip silencieux, un `.only` committé, « No tests found » sur des sources qui ont des tests.

**+ typecheck** si le diff touche un fichier hors graphe de tests (config, types partagés, helper non importé par les tests) : le runner de tests ne typecheck que ce que les tests importent. ❌ toute erreur de typage.

### 2. Smoke visuel sur le layout réel (si UI touchée)
Si le commit touche du JSX/HTML/CSS : ouvrir la page cible dans un vrai navigateur avec une vraie session (pas une injection de DOM dans une page de login), mesurer les éléments clés (largeur et hauteur non nulles pour tout élément censé être visible), capturer. ✓ rendu correct. ⚠️ navigateur indisponible (dit dans le body). ❌ layout cassé, élément invisible, override d'un parent.

### 3. Cas du brief QA effectivement couverts
Dans un run `$call-tech-lead`, lire le brief QA (round 1) et vérifier que les cas applicables à la task ont un test vert. Hors run : nominal + accès refusé + cas limites métier. ✓ tous couverts. ⚠️ 1-2 cas non critiques différés (à lister). ❌ cas sécurité ou données critique non couvert.

### 4. Pas de régression sur les symboles changés
Pour chaque symbole renommé ou modifié, chercher ses appelants (`rg -n "<symbole>"`, hors dépendances et build). ✓ tous à jour. ❌ un appelant utilise l'ancienne signature.

### 5. Logs console propres (si UI touchée)
Console du navigateur pendant le smoke : ✓ aucune erreur, aucun warning du framework, aucune violation de politique de sécurité (CSP), aucun 404 réseau. ⚠️ warning connu expliqué. ❌ erreur runtime ou requête bloquée en silence.

### 6. `git diff --stat` cohérent avec le scope
✓ nombre de fichiers ≈ scope annoncé, aucun fichier surprise (`.env`, lockfile non sollicité, fichier d'une autre feature). ❌ fichier non lié → le retirer de l'index avant commit.

### 7. Pièges connus (GUIDE-LLM §12) respectés
Scanner l'index de `docs/GUIDE-LLM.md` §12 « Pièges connus » pour la zone touchée (handler API, composant, accès aux données, sécurité, CSS, E2E…). ✓ pièges pertinents mitigés ou non applicables. ❌ un piège pertinent ignoré.

### 8. Décision business ou autorisation prise AVANT le commit
Si le commit applique une décision métier non triviale (gating par rôle, règle de calcul, autorisation d'accès), l'utilisateur l'a-t-il validée avant ? ✓ décision actée ou aucune dans ce commit. ❌ option business engagée sans validation : stop, demander d'abord.

## Sortie

Format compact, 2 lignes max par item :

```
$verify — <slug>

1. Tests : ✓ 12 verts (3 rouges→verts cette task)
2. Smoke visuel : ✓ /page, élément 312px, capture OK
3. Brief QA : ✓ AC-1, AC-3, T-1 couverts
4. Symboles changés : ✓ 4 appelants à jour
5. Logs console : ✓ propres
6. git diff --stat : ✓ 5 fichiers, scope cohérent
7. Pièges §12 : ✓ accès aux données vérifié côté serveur
8. Décision business : N/A

→ OK pour commit. Trace pour le body :
   $verify : 8/8 ✓
```

Un ❌ : le dire sur l'item (« fix avant commit, relancer $verify après »), pas de trace.

## Trace dans le commit

Quand tous les items sont ✓ ou ⚠️ justifiés, le body du commit porte :

```
feat(api): create-poste, TDD 6 tests

Cas QA round 1 couverts : AC-1, AC-3, T-1
$verify : 8/8 ✓
```

(La ligne `Co-Authored-By` se recopie du rappel d'attribution de la session.) `$ship-pr` (étape 6 bis) lit cette trace avant la création de la PR et bloque si elle manque sur un commit applicatif.

## Anti-patterns
- ❌ Cocher la checklist sans la lancer : une trace `$verify : 8/8 ✓` fausse ruine la confiance dans toutes les autres.
- ❌ Suite complète à chaque `$verify` (perte de temps et de tokens : cibler le scope).
- ❌ Sauter le smoke visuel parce que « le rechargement à chaud était bon » (il peut être périmé).
- ❌ `$verify` après le commit pour « valider » : le but est de bloquer AVANT.

## Référence
`CLAUDE.md` § Discipline de développement · `docs/GUIDE-LLM.md` §12 (pièges connus).
