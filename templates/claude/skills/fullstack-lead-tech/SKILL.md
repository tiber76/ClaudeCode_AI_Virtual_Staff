---
name: fullstack-lead-tech
description: |
  À partir d'une User Story (fichier `docs/us/US-*.md` ou texte collé), produit un plan
  technique global avec une section UX/UI soignée obligatoire : impact architectural
  (DB/API/UI/helpers), états empty/loading/error/success, accessibilité, responsive,
  tests à écrire, découpe en PR par tranche (jamais par couche) avec porte de taille,
  risques via les pièges connus du GUIDE-LLM, checklist sécurité, estimation d'effort
  et matrice de traçabilité bloquante (chaque critère d'acceptation → un lot → un test).
  Sauvegarde dans `docs/plans/PLAN-<slug>.md`.
  Invoquer après `/redige-us` ou quand une US existe et qu'on veut le plan tech avant
  de coder.
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
  - Agent
  - AskUserQuestion
triggers:
  - lead tech
  - plan technique
  - propose le plan
  - plan tech UX
---

# /fullstack-lead-tech

Restitution du plan à l'utilisateur (tableau par tranche, décisions à trancher) : `.claude/skills/_partage/fil-de-progression.md`, « Demander une validation ».

## Objectif
Produire un plan technique complet **avec un soin UX/UI obligatoire** à partir d'une US. Livrable unique : un fichier `docs/plans/PLAN-<slug>.md`. **Aucun code n'est produit par ce skill.**

## Quand l'utiliser
- Une US existe dans `docs/us/` (produite par `/redige-us`) ou est fournie en texte.
- Avant de coder une feature non-triviale (> ~50 lignes ou > 2 fichiers).
- Pour challenger une approche avant de l'implémenter.

## Principes
1. **Explorer avant de planifier** : toujours lire les patterns existants avant de proposer une archi neuve (routes similaires, composants, helpers `{{DIR_HELPERS}}`).
2. **UX/UI n'est pas optionnel** : la section UX/UI doit couvrir les 4 états (empty/loading/error/success), l'a11y et le responsive. Pas de raccourci.
3. **Ne JAMAIS proposer un script de migration SQL ad-hoc** : fournir uniquement le fichier SQL idempotent. L'utilisateur joue les migrations lui-même.
4. **Découper par tranche, jamais par couche** : une PR = une tranche de l'US (ou deux tranches `S`). Jamais une PR « migration + API » sans écran : l'utilisateur ne peut rien valider à l'écran. La migration voyage avec la tranche qui en a besoin, ou dans un Lot 0 (socle) si au moins 2 tranches la partagent. Seuils par défaut : tranche ≤ 2 j, PR ≤ ~800 lignes hors tests et fixtures ; au-delà, un tableau « Justification de complexité » (section 10.3) est obligatoire.
5. **Citer les pièges connus applicables** : chaque piège §12 du GUIDE-LLM qui s'applique doit être mentionné explicitement avec sa mitigation.
6. **Discipline TDD systématique** : la section 4 liste, par lot, les tests écrits en rouge AVANT le code. Le QA produit en parallèle le brief des cas à couvrir, qui sert d'oracle au dev. Pas de tests après coup.
7. **Traçabilité dans les deux sens** : aucun critère d'acceptation de l'US ne reste orphelin (sans lot ni test), et aucun lot n'existe sans critère rattaché (sinon dérive de périmètre). Le contrôle est **bloquant** (étape 3 bis) : un plan avec un critère orphelin non arbitré n'est pas livrable.

## Étapes

### 1. Lecture de l'US
- Si l'input est un chemin → `Read docs/us/US-xxx.md`.
- Sinon → prendre le texte collé tel quel.
- Si l'US n'a pas de critères d'acceptation clairs **ou n'est pas découpée en tranches priorisées** → relancer `/redige-us` d'abord. Pour une US ancienne (liste plate de scénarios), le plan commence par proposer le découpage en tranches (T1 = MVP démontrable seule) et le fait valider via `AskUserQuestion` avant d'aller plus loin.

### 2. Exploration du code existant
Pour chaque élément de l'US, chercher le pattern existant :
- **Routes API similaires** : `Glob {{DIR_ROUTES_API}}**/*` + `Grep` du verbe/ressource.
- **Composants UI proches** : `Glob {{DIR_COMPONENTS}}**/*`.
- **Tables DB touchées** : lire les migrations récentes pour le schéma actuel.
- **Helpers `{{DIR_HELPERS}}`** réutilisables.

Si le scope est large (>3 zones) → déléguer à un sous-agent `Explore` pour ne pas saturer le contexte.

### 3. Rédaction du plan
Format strict :

```markdown
# PLAN-<slug> — <titre de l'US>

**US source** : [US-<slug>](../us/US-<slug>.md)
**Identifiant** : `<slug>` — tranches `<slug>/Tn`, repris dans les commits et les titres de PR
**Date** : <YYYY-MM-DD>
**Tranches** : N (T1 = MVP), reprises de l'US ; si l'US n'en a pas, proposées ici et validées avant la section 2
**Estimation effort** : par tranche (S ≤ 0,5 j | M ≤ 2 j) + total
**Découpage PR** : une PR par tranche, PR 1 = Lot 0 + T1, PR 2 = T2… (voir section 5)

---

## 1. Résumé exécutif
<3-5 lignes : quoi, où, combien, principaux risques>

## 2. Impact architectural

### 2.1. Base de données
- **Tables modifiées** : <nom> → colonnes ajoutées/modifiées
- **Tables créées** : <nom> → schéma complet
- **Index à ajouter** : <sur quelles colonnes, pourquoi — cf. GUIDE-LLM §3>
- **RLS / policies** : politiques à ajouter/modifier
- **Migration** : fichier SQL idempotent (`CREATE ... IF NOT EXISTS`) dans le dossier de migrations du projet
- ⚠️ **L'utilisateur joue la migration lui-même** en staging puis prod — pas de script d'exécution.

### 2.2. Routes API
| Verbe | Route | Auth | Rate-limit | Validation | Notes |
|---|---|---|---|---|---|
| GET | `/api/...` | session user | non | — | … |
| POST | `/api/...` | session user + rôle | {{#IF HAS_RATE_LIMITING}}5/min `<nom>`{{/IF}}{{#IF !HAS_RATE_LIMITING}}—{{/IF}} | schéma validation | … |

{{#IF HAS_RATE_LIMITING}}Pour chaque route POST/PUT/DELETE → rate-limit obligatoire (cf. §7).{{/IF}}

### 2.3. Composants UI
- **Pages touchées** : <chemin>
- **Composants à créer/modifier** : <chemin> — convention `{{NAMING_COMPONENTS}}`
- **Fichiers client à modifier** : <chemin dans `{{DIR_COMPONENTS}}` ou équivalent> — attention syntaxe (piège §12)
- **Helpers `{{DIR_HELPERS}}`** : à créer ou réutiliser

### 2.4. Dépendances externes
- Nouvelle lib ? Si oui : justifier, vérifier maintenance, popularité, CVE (cf. §8)
- Nouveau domaine appelé en `fetch()` côté client ? → mettre à jour la CSP (`connect-src`) si configurée

---

## 3. UX / UI (section obligatoire)

### 3.1. Wireframe textuel
<disposition ASCII ou description précise de l'écran, hiérarchie visuelle>

### 3.2. États
| État | Comportement | Message {{UI_LANGUAGE}} |
|---|---|---|
| **empty** | Aucune donnée à afficher | ex: "Aucun résultat pour le moment." |
| **loading** | Chargement initial ou action en cours | skeleton ? spinner ? placeholder ? |
| **error** | Échec API ou validation | phrase complète avec contexte (pas "Erreur") |
| **success** | Action réussie | toast ? redirection ? inline ? |

### 3.3. Micro-interactions
- Hover sur <élément> → <effet>
- Transitions : durée, easing (cohérent avec l'existant)
- Feedback utilisateur : toast / inline / modal ?
- Focus management : où part le focus après action ?

### 3.4. Responsive
- Breakpoints touchés (mobile / tablette / desktop)
- Comportement spécifique mobile si applicable
- Touch targets ≥ 44px

### 3.5. Accessibilité (cf. GUIDE-LLM §8)
- [ ] `aria-label` sur boutons icon-only
- [ ] `role="dialog"` + `aria-modal="true"` si modal
- [ ] Focus visible jamais supprimé (`:focus-visible`)
- [ ] `aria-live="polite"` si toast/notification
- [ ] Z-index via variables/tokens du design system, pas de hardcode

### 3.6. Ton éditorial
- Labels cohérents (boutons, actions) selon le référentiel projet
- Langue UI : {{UI_LANGUAGE}} (respect strict de l'orthographe et des accents si applicable)
- Messages d'erreur = phrases complètes

### 3.7. Cohérence design
{{#IF HAS_DESIGN_SYSTEM}}- Réutilisation des tokens / variables du design system `{{DESIGN_SYSTEM_NAME}}`
- Composants partagés (éviter de dupliquer){{/IF}}
{{#IF !HAS_DESIGN_SYSTEM}}- Réutiliser les variables CSS existantes et les composants partagés (éviter de dupliquer){{/IF}}

---

## 4. Tests à écrire (cf. GUIDE-LLM §4, discipline TDD)

Chaque test est écrit en rouge d'abord, avant le code de production qu'il couvre. Le DEV écrit les tests unitaires, API, lib, composants et d'intégration. Le QA écrit les E2E (lot final).

| Type | Fichier | Couvre | Qui écrit | Quand |
|---|---|---|---|---|
| Unit | `{{DIR_TESTS_UNIT}}<nom>.test.*` | Logique pure, helpers, composants | DEV | Avant chaque lot d'implémentation |
| Unit API | `{{DIR_TESTS_UNIT}}<route>.test.*` | Handler API : 200, 401, 403, 404, 405, 500 | DEV | Avant le handler |
| Intégration | `{{DIR_TESTS_INT}}<flow>.test.*` | Flow multi-étapes | DEV | Avant le flow |
| E2E | `{{DIR_TESTS_E2E}}<feature>.spec.*` | Parcours dans le navigateur (`@smoke` ou `@critical`) | QA | Lot final, une fois unit et intégration verts |

**Règles** :
- Chaque fichier source applicatif modifié a au moins un test unitaire écrit en rouge d'abord.
- Exceptions TDD : migrations idempotentes, config pure, markup et CSS purs (contrôle visuel + E2E), docs.

### Tableau « tests par lot » (fait foi)

C'est la source unique du mapping lot → critères → test. La section 10 ne le recopie pas : elle le contrôle. Tout chemin de test n'apparaît qu'ici.

| Lot | Critères US + cas du brief QA | Fichier de test | Niveau | Qui |
|---|---|---|---|---|
| Lot 0 — socle : helper pur partagé par T1 et T2 | AC-2, M-1, M-2 | `{{DIR_TESTS_UNIT}}yyy.test.*` | Unit | DEV |
| T1.api `[T1]` `[P]` — handler `POST /api/xxx` | AC-1, T-1 (401), T-2 (403), T-4 (validation) | `{{DIR_TESTS_UNIT}}xxx.test.*` | Unit API | DEV |
| T1.ui `[T1]` `[P]` — composant (logique) | AC-4, UX-1 à UX-4 (4 états) | `{{DIR_TESTS_UNIT}}Zzz.test.*` | Unit composant | DEV |
| T1.e2e `[T1]` — parcours de la tranche 1 | AC-1, AC-3, UX-5 = test indépendant T1 | `{{DIR_TESTS_E2E}}<feature>.spec.*` | E2E `@smoke` | QA fin de PR |

Étiquettes : `[Tn]` = tranche servie (obligatoire hors Lot 0 et lot final) ; `[P]` = parallélisable (fichiers différents, aucune dépendance sur un lot non terminé) : deux lots ne tournent en parallèle que si les deux portent `[P]`. Chaque lot cite ses chemins de fichiers : un agent doit pouvoir l'exécuter avec sa seule section du plan. Suffixes de sous-lot : `.api` (handler, helpers, flow d'intégration), `.ia` (helpers IA), `.ui` (markup + logique composant), `.page` (intégration page, routing), `.e2e` (E2E de la tranche).

---

## 5. Découpe en PR — une PR par tranche

### PR 1 — Lot 0 (socle) + Tranche 1 (MVP) (~X lignes hors tests)
- Lots : 0, T1.api, T1.ui, T1.page, T1.e2e
- Démontrable : <le test indépendant de la tranche 1, repris de l'US>
- Mergeable seule : oui, rien n'est à moitié branché après elle
- Titre de PR : `<type>(<scope>): <slug>/T1 — <titre>`

### PR 2 — Tranche 2 (~X lignes hors tests)
- Lots : T2.api, …
- Démontrable : <test indépendant T2>

Règles : jamais une PR par couche (« migration → API → UI ») ; une PR peut embarquer deux tranches `S` ; une tranche `M` = une PR ; au-delà de ~800 lignes hors tests et fixtures → « Justification de complexité » (section 10.3). Pour un chantier technique (refacto, migration de framework), la « tranche » est une surface (une page, une modale, un helper) : même règle.

---

## 6. Risques & pièges connus (cf. GUIDE-LLM §12)

| Piège | Concerné ? | Mitigation |
|---|---|---|
| Filtrage serveur vs client | oui/non | <explication> |
| Fonctions dupliquées (écrasement silencieux) | oui/non | <explication> |
| Appels asynchrones non awaités avant re-render | oui/non | <explication> |
| Syntaxe fragile dans les fichiers client globaux | oui/non | <explication> |
| Schéma DB réel vs migration non-appliquée | oui/non | <explication> |
| CSP `connect-src` manquant pour un nouveau domaine | oui/non | <explication> |
| Handlers inline HTML (bloqués par CSP nonce) | oui/non | <explication> |

### 6.1. Hypothèses à lever au smoke réel (section obligatoire ; écrire « aucune » en toutes lettres sinon)

Tout comportement d'un binaire ou d'un service externe que le code simule dans ses tests (CLI, webhook, signal système) et que personne n'a observé en vrai pour cette feature. Une ligne chacun : l'hypothèse, comment la lever en moins de 5 minutes, ce qui casse si elle est fausse. L'orchestrateur de `/call-tech-lead` joue ce smoke avant la première `/review-pr` ; sans cette section, il ne le joue jamais.

---

## 7. Checklist sécurité (cf. GUIDE-LLM §7)
- [ ] Auth vérifiée en début de chaque route (helper session du projet)
- [ ] Rôle vérifié côté serveur (jamais faire confiance au client)
{{#IF HAS_RATE_LIMITING}}- [ ] Rate-limit sur POST/PUT/DELETE{{/IF}}
- [ ] Validation inputs côté serveur
- [ ] Pas de client admin ni secrets côté frontend
- [ ] Magic bytes vérifiés si upload
- [ ] Logs sans secrets
- [ ] Erreurs au format `{ error: '...' }` sans `details` en prod
{{#IF HAS_2FA}}- [ ] Parcours sensibles protégés par 2FA si nécessaire{{/IF}}
{{#IF HAS_RGPD}}- [ ] Données personnelles : minimisation, consentement, droit à l'effacement{{/IF}}

---

## 8. Ordre d'implémentation (TDD strict, par tranche, jamais par couche)

Pour chaque lot : test rouge (écrit par le dev) → code minimal → refactor → `/verify` → commit `<type>(<scope>): <slug> Tn — TDD <NB tests>`. Les commits restent atomiques (6-8 par PR, un par lot) mais **ordonnés par tranche** : après le dernier lot d'une tranche, l'app est démontrable et rien n'est à moitié branché.

0. **Lot 0 — Socle** (uniquement ce qui est partagé par au moins 2 tranches) : migration idempotente (l'utilisateur l'applique, pas de TDD) + helper pur partagé (TDD). Minimal, bloquant.
1. **Tranche 1 (MVP)**, dans l'ordre, uniquement les lots que la tranche exige :
   - **T1.api** (DEV) : test rouge du handler, handler, vert, `/verify`, commit ; idem pour les helpers et le flow d'intégration.
   - **T1.ia** (AI/LLM engineer) si feature IA : parsers et validators en TDD, appels au modèle simulés.
   - **T1.ui** : intégrateur (markup + CSS, contrôle visuel, helper JS en TDD) en parallèle du DEV (logique composant en TDD), lots `[P]`.
   - **T1.page** : intégration page et routing.
   - **T1.e2e** (QA, lot final de la PR) + **point de contrôle « démontrable »** : le test indépendant de la tranche passe. Une PR peut s'arrêter ici.
2. **Tranche 2** : même séquence. Puis tranche 3, etc.
3. **Lot final de chaque PR — QA** : relit la couverture du dev et écrit les E2E des tranches embarquées.
4. `/qa-flow`, puis `/ship-pr` (qui enchaîne `/review-pr` lui-même ; `/review-pr` reste invocable seul pour auto-challenger un diff).

---

## 9. Questions à trancher avant de coder
- [ ] <questions ouvertes spécifiques à cette feature>

---

## 10. Traçabilité US → lots → tests (contrôle bloquant)

Cette section ne réplique aucune donnée : le tableau de la section 4 fait foi, on le lit dans les deux sens. Ne jamais recopier ici un chemin de test.

### 10.1. Sens descendant — chaque critère d'acceptation apparaît en section 4

| Critère US | Intitulé court | Lot(s) en section 4 | Statut |
|---|---|---|---|
| AC-1 | <intitulé> | T1.api, T1.e2e | ✅ |
| AC-3 | <intitulé> | aucun | ❌ orphelin |

Statuts : ✅ couvert (le critère figure dans au moins un lot **doté d'un fichier de test**) · ⚠️ partiel (rattaché à un lot sans test) · ❌ orphelin (absent de toute la section 4).

### 10.2. Sens remontant — chaque lot sert un critère

| Lot | Critère(s) rattaché(s) | Statut |
|---|---|---|
| T1.api | AC-1, AC-4 | ✅ |
| T2.ui | aucun | ⚠️ dérive de périmètre |

### 10.3. Verdict

> **Traçabilité : N/N critères couverts — <PLAN LIVRABLE | PLAN BLOQUÉ>**
> **Taille : N tranches · max X j / tranche · PR prévue ≤ ~800 lignes hors tests — <OK | BLOQUÉ>**

**Justification de complexité** (uniquement si une tranche dépasse 2 j ou une PR ~800 lignes hors tests ; sinon supprimer le tableau) :

| Écart | Pourquoi nécessaire | Alternative plus simple rejetée parce que |
|---|---|---|
| <ex. : renommage sur 80 fichiers en une PR> | <atomicité : un renommage à moitié fait casse le build> | <deux PR laisseraient la branche cassée entre les deux> |

**Écarts arbitrés** (uniquement si l'utilisateur a tranché un ❌/⚠️ en « hors périmètre assumé ») :
- AC-3 → reporté, motif : <raison>, décision le <date>.
```

### 3 bis. Contrôle de cohérence US ↔ lots ↔ tests (BLOQUANT, avant sauvegarde)

Ne jamais écrire le plan sans avoir joué ce contrôle : on remplit la matrice de la section 10 ligne à ligne, pas « en gros ».

1. **Extraire les critères d'acceptation de l'US** et les numéroter `AC-1..AC-n` s'ils ne le sont pas (proposer de répercuter la numérotation dans l'US : les identifiants deviennent le vocabulaire commun plan ↔ brief QA ↔ commits).
2. **Sens descendant** : chaque `AC-n` figure dans la colonne « Critères US » d'au moins un lot de la section 4, et ce lot a un fichier de test. Un lot sans test = ⚠️ partiel, pas ✅.
3. **Sens remontant** : chaque lot sert au moins un `AC-n`. Lot sans critère = ⚠️ dérive de périmètre : soit il révèle un critère implicite manquant dans l'US (le remonter), soit il sort du périmètre (le retirer).
4. **Contrôle de taille** : somme des lots de chaque tranche ≤ 2 j ; chaque PR prévue en section 5 ≤ ~800 lignes hors tests. Dépassement → découper (nouvelle tranche ou nouvelle PR) ou remplir la « Justification de complexité ». Ni l'un ni l'autre = PLAN BLOQUÉ.
5. **Verdict** : renseigner la section 10.3 (couverture et taille).

Le tableau de la section 4 est la source unique : si un test manque, on complète la section 4 puis on rejoue le contrôle, on ne « répare » pas la matrice.

**Règle de blocage** : s'il reste un ❌ ou un ⚠️, ou une taille hors seuil sans justification :
- Ne pas livrer le plan en l'état, ne pas dégrader silencieusement le critère, ne pas le renvoyer à plus tard sans le dire.
- Simple oubli → corriger (ajouter le lot ou le test) et recommencer le contrôle.
- Sinon → `AskUserQuestion` avec, pour chaque écart : le critère concerné, pourquoi il n'est pas couvrable dans ce périmètre, et 2 options concrètes (l'inclure et l'effort ajouté / le sortir explicitement et ce qu'on perd). Reporter la décision dans « Écarts arbitrés » avec la date.

Un critère perdu au plan n'aura ni test ni implémentation et ne réapparaîtra qu'en production : ce contrôle coûte presque rien comparé à cette dérive.

### 4. Sauvegarde
- Slug identique à celui de l'US si possible.
- `mkdir -p docs/plans`.
- Écrire `docs/plans/PLAN-<slug>.md`.
- Mettre à jour le tableau « Suivi des tranches » de l'US (colonne « Lots du plan », état « planifiée ») dans le même commit : c'est le seul endroit où l'arbre demande → tranches → PR se lit en entier.
- Afficher le chemin + un résumé en restitution (un tableau, une ligne par tranche : à quoi ça sert, ce que ça touche, taille ; plus les décisions à trancher), pas le plan complet.

### 5. Suite suggérée
Terminer par :
> **Prochaines étapes** :
> 1. Valider le plan avec l'utilisateur (questions section 9 si présentes)
> 2. Implémenter dans l'ordre de la section 8
> 3. `/qa-flow` pour tester, `/ship-pr` pour créer la PR (il enchaîne `/review-pr`)

## Anti-patterns à éviter
- ❌ Produire du code dans le plan (que du descriptif).
- ❌ Sauter la section UX/UI ou la réduire à "reprendre le design existant".
- ❌ Ne pas lister les tests à écrire.
- ❌ Proposer un script d'exécution de migration (l'utilisateur joue lui-même).
- ❌ Oublier de citer les pièges connus §12 applicables.
- ❌ Donner une estimation sans justification.
- ❌ Écrire le plan sans avoir rempli la matrice de traçabilité (« je l'ai vérifié mentalement » ne compte pas).
- ❌ Laisser un critère d'acceptation orphelin, ou le faire disparaître en le reformulant plus petit.
- ❌ Découper une PR par couche (« migration → API → UI ») : une PR sans écran n'est pas validable.
- ❌ Tranche > 2 j ou PR > ~800 lignes hors tests sans « Justification de complexité ».

## Référence GUIDE-LLM
- §1 Clean Code (taille fichiers, nommage)
- §3 Performance & Index DB
- §4 Tests (stratégie unit/integration/E2E)
- §7 Sécurité (checklist nouvelle route)
- §8 UX/UI (modals, z-index, accessibilité, CSP, handlers inline)
- §12 Pièges connus

## 💰 Coût indicatif

Tokens : ~50-120k brut · ~20-40k effective (avec prompt caching 90%)
Équivalent API : ~$0.2-0.5
Détail complet et optimisations : `docs/COUTS-LLM.md`.
