---
name: fullstack-lead-tech
description: |
  À partir d'une User Story (fichier `docs/us/US-*.md` ou texte collé), produit un plan
  technique global avec une section UX/UI soignée obligatoire : impact architectural
  (DB/API/UI/helpers), états empty/loading/error/success, accessibilité, responsive,
  tests à écrire, découpe en PR, risques via les pièges connus du GUIDE-LLM, checklist
  sécurité et estimation d'effort. Sauvegarde dans `docs/plans/PLAN-<slug>.md`.
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
4. **Découper si > 300 lignes** : proposer 2-3 PR incrémentales (ex: migration → API → UI).
5. **Citer les pièges connus applicables** : chaque piège §12 du GUIDE-LLM qui s'applique doit être mentionné explicitement avec sa mitigation.

## Étapes

### 1. Lecture de l'US
- Si l'input est un chemin → `Read docs/us/US-xxx.md`.
- Sinon → prendre le texte collé tel quel.
- Si l'US n'a pas de critères d'acceptation clairs → suggérer de relancer `/redige-us` d'abord.

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
**Date** : <YYYY-MM-DD>
**Estimation effort** : 1h | demi-journée | 1 jour | 2+ jours
**Découpage PR** : 1 PR | 2 PR | 3+ PR (voir section Découpe)

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

## 4. Tests à écrire (cf. GUIDE-LLM §4)

| Type | Fichier | Couvre |
|---|---|---|
| Unit | `{{DIR_TESTS_UNIT}}<nom>.test.*` | Logique pure, helpers, composants |
| Unit | `{{DIR_TESTS_UNIT}}<route>.test.*` | Handler API : 200, 401, 403, 404, 405, 500 |
| Intégration | `{{DIR_TESTS_INT}}<flow>.test.*` | Flow multi-étapes |
| E2E | `{{DIR_TESTS_E2E}}<feature>.spec.*` | Parcours user dans le navigateur — tagger `@smoke` ou `@critical` |

**Règle** : chaque fichier source modifié = au moins un test unitaire.

---

## 5. Découpe en PR (si > 300 lignes)

### PR 1 — <titre> (~X lignes)
- Fichiers : <liste>
- Objectif : brique indépendante mergeable seule

### PR 2 — <titre>
…

### PR 3 — <titre>
…

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

## 8. Ordre d'implémentation suggéré
1. Migration SQL (l'utilisateur l'applique en staging)
2. Tests API (rouge au départ)
3. Handler API
4. Tests unit composants (rouge au départ)
5. Composants UI
6. Intégration page
7. Tests E2E
8. `/review-pr` puis `/qa-flow` puis `/ship-pr`

---

## 9. Questions à trancher avant de coder
- [ ] <questions ouvertes spécifiques à cette feature>
```

### 4. Sauvegarde
- Slug identique à celui de l'US si possible.
- `mkdir -p docs/plans`.
- Écrire `docs/plans/PLAN-<slug>.md`.
- Afficher le chemin + un résumé court (pas le plan complet) dans la réponse, renvoyer vers le fichier pour le détail.

### 5. Suite suggérée
Terminer par :
> **Prochaines étapes** :
> 1. Valider le plan (questions section 9 si présentes)
> 2. Implémenter dans l'ordre de la section 8
> 3. `/review-pr` avant PR, `/qa-flow` pour tester, `/ship-pr` pour créer la PR

## Anti-patterns à éviter
- ❌ Produire du code dans le plan (que du descriptif).
- ❌ Sauter la section UX/UI ou la réduire à "reprendre le design existant".
- ❌ Ne pas lister les tests à écrire.
- ❌ Proposer un script d'exécution de migration (l'utilisateur joue lui-même).
- ❌ Oublier de citer les pièges connus §12 applicables.
- ❌ Donner une estimation sans justification.

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
