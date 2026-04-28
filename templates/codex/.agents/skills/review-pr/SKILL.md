---
name: review-pr
description: |
  Code review pré-merge : applique la checklist sécurité / clean code / tests / pièges
  connus de `docs/GUIDE-LLM.md` sur le diff entre la branche courante et `{{GIT_DEFAULT_BRANCH}}`.
  Produit un rapport structuré en 3 blocs : 🔴 Bloquants / 🟠 À corriger / 🟢 OK.
  Invoquer avant toute création de PR, ou à tout moment pour auto-challenger son code.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$review-pr` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $review-pr

## Objectif
Challenger le diff courant contre les règles du `docs/GUIDE-LLM.md` avant de créer/merger une PR. Produire un rapport priorisé qui identifie les bloquants réels (pas de bruit).

## Quand l'utiliser
- Juste avant `$ship-pr` (systématique).
- Pour auto-review pendant le développement.
- Après avoir résolu un conflit de merge, pour valider que rien n'a été perdu.

## Principes
1. **Signal > bruit.** Un bloquant doit être *vraiment* bloquant (sécurité, régression, casse). Ne pas crier "à corriger" sur chaque préférence de style.
2. **Citer la règle.** Chaque finding doit référencer la section du GUIDE-LLM ou le piège §12 applicable.
3. **Localiser précisément.** Toujours donner `fichier:ligne` pour chaque finding.
4. **Ne JAMAIS modifier le code dans ce skill.** Observer, rapporter. Les corrections sont hors scope (laissez l'utilisateur décider ou invoquer un autre skill).

## Étapes

### 1. Récolte du diff
```bash
git fetch origin {{GIT_DEFAULT_BRANCH}} 2>/dev/null || true
git diff origin/{{GIT_DEFAULT_BRANCH}}...HEAD --stat
git diff origin/{{GIT_DEFAULT_BRANCH}}...HEAD
```
Si pas de diff vs `{{GIT_DEFAULT_BRANCH}}` → signaler et s'arrêter.

### 2. Scan par catégorie

Pour chaque catégorie, parcourir le diff et relever les findings.

#### 2.1. Sécurité (cf. §7) — catégorie critique, défaut au bloquant
- [ ] Chaque nouvelle route API a un check d'authentification (helper session du projet) en début de handler.
{{#IF HAS_RATE_LIMITING}}- [ ] Chaque POST/PUT/DELETE a un check de rate-limit — si non, vérifier dans la table §7 si la route est listée. Sinon → 🔴 bloquant sur routes publiques, 🟠 sur routes authentifiées.{{/IF}}
- [ ] Aucun client admin ou secret côté client : grep des identifiants admin dans les bundles front — doit être vide.
- [ ] Pas de nouveau `fetch()` client vers un domaine externe sans update CSP `connect-src` (si CSP configurée).
- [ ] Validation des inputs côté serveur (pas de confiance au body/query sans sanitization).
- [ ] Pas de `console.log` avec payload sensible.
- [ ] Format erreur `{ error: '...' }` — pas de `details` exposé en prod.
- [ ] Upload : magic bytes + whitelist extensions + limite taille si applicable.
{{#IF HAS_2FA}}- [ ] Parcours sensibles (changement email, suppression compte, admin) protégés par 2FA.{{/IF}}
{{#IF HAS_RGPD}}- [ ] Données personnelles : minimisation, pas d'export silencieux, logs sans PII identifiante.{{/IF}}

#### 2.2. Clean code (cf. §1)
- [ ] Nommage conforme ({{NAMING_VARIABLES}} fonctions, {{NAMING_COMPONENTS}} composants, {{NAMING_FILES_API}} API, {{NAMING_CONSTANTS}} constantes).
- [ ] Fonctions < ~40 lignes — sinon 🟠.
- [ ] Fichiers < ~300 lignes — sinon 🟠 + suggérer refacto.
- [ ] Pas de code commenté (supprimer ou déplacer en commit séparé).
- [ ] Early return sur cas d'erreur.
- [ ] Pas d'abréviations cryptiques.

#### 2.3. Tests (cf. §4)
- [ ] Chaque fichier source modifié a un fichier test correspondant mis à jour ou créé.
- [ ] Si logique client modifiée (filtrage, tri, affichage) → test unitaire dans `{{DIR_TESTS_UNIT}}` ajouté.
- [ ] Tests d'access-control présents pour nouvelles routes (401, 403, 405).
- [ ] Si changement de contrat API → test E2E associé mis à jour.

#### 2.4. Pièges connus (cf. §12)
Pour chaque piège applicable au diff, vérifier :
- **Filtrage serveur vs client** : filtrage métier côté serveur ? 🔴 bloquant si fait uniquement côté client sur données sensibles.
- **Fonctions dupliquées** : deux définitions de même nom dans scope accessible → 🔴.
- **Appels asynchrones non awaités** : save/fetch async suivi de re-render sans attendre la résolution → 🟠.
- **Syntaxe fragile côté client** : vérifier visuellement `try`/`catch` équilibrés. Tout warning JS → 🔴.
- **Schéma DB réel** : nouvel `INSERT`/`UPDATE` avec colonne qui n'existe peut-être pas dans le schéma actuel → 🟠 demander confirmation.
- **Colonnes auto-gérées (triggers)** : ne pas écrire dans un `updated_at` géré par trigger SQL → 🔴 si présent.
- **Handlers inline HTML** (`onclick=`, `onchange=` dans fichiers client avec CSP nonce) : 🔴 (bloqué par CSP).

#### 2.5. UX/UI (cf. §8) — si modifications UI
- [ ] Modals via les APIs du design system / helpers existants, pas manipulation directe de classes.
- [ ] Z-index via variables/tokens, pas hardcodé.
- [ ] `aria-label` sur boutons icon-only.
- [ ] Métadonnées page (`title`, `robots` si protégée).
- [ ] Texte en {{UI_LANGUAGE}} cohérent (accents si applicable).

#### 2.6. Git hygiene
- [ ] Pas de commit sur fichiers sensibles (`.env*`, secrets).
- [ ] Pas de `node_modules/`, build output, `coverage/` dans le diff.
- [ ] Message de commit descriptif (verbe + contexte).

### 3. Rapport final

Format strict :

```markdown
# Review — <nom de branche>

**Base** : `{{GIT_DEFAULT_BRANCH}}`
**Diff** : X fichiers modifiés, +N / -M lignes
**Date** : <YYYY-MM-DD HH:MM>

## 🔴 Bloquants (doivent être corrigés avant PR)
1. **<fichier>:<ligne>** — <problème>
   - Règle : GUIDE-LLM §<x> "<titre>"
   - Pourquoi c'est bloquant : <1 phrase>
   - Suggestion : <fix concret>

*(si aucun → "Aucun bloquant détecté.")*

## 🟠 À corriger avant merge
1. **<fichier>:<ligne>** — <problème>
   - Règle : <référence>
   - Suggestion : <fix>

## 🟢 OK / points positifs notables
- <ex: couverture de tests complète>
- <ex: bon usage des helpers `{{DIR_HELPERS}}`>

## Verdict
- **Prêt pour `$qa-flow`** : oui / non (si bloquants)
- **Prêt pour `$ship-pr`** : oui / non
```

### 4. Ne pas corriger automatiquement
Si l'utilisateur demande "corrige les bloquants", proposer un diff mais **attendre validation** avant d'éditer. Pour une correction autonome, l'utilisateur doit explicitement dire "go" ou "corrige".

## Anti-patterns à éviter
- ❌ Lister tous les findings possibles (bruit). Prioriser.
- ❌ Marquer 🔴 sur de la préférence de style (c'est 🟠 au pire).
- ❌ Corriger le code sans demander.
- ❌ Ne pas citer la règle du GUIDE-LLM.
- ❌ Review un diff vide sans le signaler.

## Référence GUIDE-LLM
- §1 Clean Code
- §4 Tests
- §5 Checklist avant commit
- §7 Sécurité
- §8 UX/UI
- §12 Pièges connus

## 💰 Coût indicatif

Tokens : ~40-120k brut · ~15-40k effective (avec prompt caching 90%)
Équivalent API : ~$0.15-0.5
Détail complet et optimisations : `docs/COUTS-LLM.md`.
