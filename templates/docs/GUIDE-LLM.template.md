# Guide LLM — Règles de développement {{PROJECT_NAME}}

> Ce guide définit les règles que le LLM doit suivre pour tout développement sur ce projet.
> Il est lu à chaque session pour garantir la cohérence et la qualité du code.

---

## 0. Gestion de session & Git flow

> **À faire systématiquement en début de chaque nouvelle session :**
> 1. Lire ce guide (`docs/GUIDE-LLM.md`)
> 2. Lire `backlog.md` à la racine et **rappeler** les dettes / tâches en attente (voir §0.1)
> 3. `git checkout develop && git pull origin develop` pour partir à jour

### 0.1 Backlog — rappel systématique

- `backlog.md` (racine) liste les dettes techniques / tâches non traitées, classées par priorité (🔴 P0 / 🟠 P1 / 🟡 P2 / 🟢 P3).
- **Au début de chaque session**, scanner `backlog.md` et dire en une phrase : *"Backlog : N P0 / N P1 / N P2 en attente — traiter avant la tâche courante ?"*. Citer au plus 3 titres prioritaires.
- **À chaque nouvelle dette** (task spawnée, scope refusé, bug latent), ajouter immédiatement une entrée dans `backlog.md` : titre, priorité, origine (PR/date), contexte, livrable attendu, branche cible.
- **Au merge d'une PR qui traite une entrée**, déplacer immédiatement vers `✅ Fait` avec date + PR. Nettoyer au-delà de 30 jours glissants.
- Pas directif — juste informatif. Toujours demander avant de traiter un item.

### ⚠️ Règle absolue — Actions Git irréversibles

**Ne JAMAIS merger, supprimer une branche, ou pusher en force sans confirmation explicite.**

- Créer une PR → OK automatiquement
- Merger une PR → **attendre un "merge" ou "go" explicite**
- Supprimer une branche → **jamais sans ordre explicite**
- Push force → **jamais sans ordre explicite**

> "ok pour le PR" = approbation du contenu, **pas une instruction de merger**.

### Règles de branchement

- **Ne JAMAIS committer directement sur `main`** — `main` est la branche de production, protégée.
- **Branche par défaut : `develop`** — toute nouvelle feature ou correction part de `develop` à jour.
  ```bash
  git checkout develop && git pull origin develop
  git checkout -b feature/ma-feature
  ```
- **Hotfix uniquement sur demande explicite** — on ne tire depuis `main` que sur ordre "hotfix".
- En résumé :
  - Feature / correction → `develop` → `feature/xxx` ou `fix/xxx`
  - Hotfix urgent (sur demande explicite) → `main` → `hotfix/xxx`

---

## 1. Clean Code

### Nommage
- {{NOMMAGE_VARIABLES}} (ex: camelCase pour JS/TS, snake_case pour Python)
- {{NOMMAGE_COMPOSANTS}} (ex: PascalCase pour React)
- {{NOMMAGE_FICHIERS}} (ex: kebab-case pour routes API, camelCase pour helpers)
- Constantes en **UPPER_SNAKE_CASE**
- Noms explicites et descriptifs — jamais d'abréviations cryptiques

### Fonctions
- **Une fonction = une responsabilité** (Single Responsibility)
- Maximum ~40 lignes par fonction — au-delà, découper
- Extraire la logique métier des handlers en helpers
- Toujours retourner tôt (early return) pour les cas d'erreur

### Fichiers
- Un composant par fichier
- Un handler API par fichier
- Helpers partagés dans {{HELPERS_DIR}}
- Maximum ~300 lignes par fichier — au-delà, refactoriser

### Lisibilité & structure
- Code **propre, aéré et modulaire** — sauter des lignes entre les blocs logiques
- Grouper les imports, puis les constantes, puis la logique, puis l'export
- Éviter les fonctions "fourre-tout" — découper en sous-fonctions nommées
- **Structures de données trop grosses** → extraire dans un fichier dédié

### Commentaires
- Code lisible > commentaires — le code doit se suffire à lui-même
- Commenter uniquement le **pourquoi**, jamais le **quoi**
- `// TODO:` pour les tâches en attente (avec contexte)
- Pas de code commenté — supprimer ou mettre dans un commit séparé

---

## 2. Refactorisation

### Quand refactoriser
- Avant d'ajouter une feature sur du code existant
- Quand on touche un fichier et qu'on voit de la duplication
- Quand un fichier dépasse les limites de taille
- **Quand on constate un fichier trop long → proposer une refacto** avant de continuer

### Principes
- **DRY** — extraire le code dupliqué en helper
- **Composants partagés**
- **Helpers réutilisables** dans {{HELPERS_DIR}}
- Ne jamais casser l'existant — refactoriser progressivement

### Checklist avant refacto
- [ ] Les tests existants passent-ils ?
- [ ] La refacto est-elle isolable dans un commit séparé ?
- [ ] Le comportement externe reste-t-il identique ?

---

## 3. Performance

### {{BACKEND_NAME}} / API Routes
- {{PERF_RULE_1}} (ex: minimiser les appels DB, combiner les requêtes)
- {{PERF_RULE_2}} (ex: `.select('col1, col2')` au lieu de `.select('*')`)
- {{PERF_RULE_3}} (ex: `.single()` / `.maybeSingle()` quand on attend 1 résultat)
- Indexer les colonnes utilisées dans les `WHERE` / `eq()`

### Frontend
- {{FRONTEND_PERF_RULES}}

### Index & Base de données
- **À chaque nouvelle requête** : vérifier si les colonnes utilisées dans les filtres sont indexées
- Les FK ne sont **pas indexées automatiquement** par {{DB_NAME}} — créer un index sur les colonnes FK utilisées en filtre
- Privilégier les **index composites** quand une requête filtre sur 2+ colonnes
- Utiliser des **index partiels** (`WHERE ... IS NULL`) quand seul un sous-ensemble est requêté
- **Monitoring** : vérifier régulièrement les stats d'utilisation des index
- Tout nouveau script d'index doit être **idempotent** (`CREATE INDEX IF NOT EXISTS`)
- Appliquer les index sur **les deux bases** (prod + staging) simultanément

---

## 4. Tests

### Règle d'or
> **Chaque évolution doit être accompagnée de tests.**
> Pas de code mergé sans couverture sur les changements.

### ⚠️ Obligation de relancer les tests
- **À chaque évolution**, relancer les tests unitaires + API — obligatoire, rapide
- **Tests d'intégration** — relancer avant chaque commit
- **Tests E2E** — relancer **uniquement quand nécessaire** (changement UI, navigation) ou **avant chaque PR**
- **Quand on dit "lance tous les tests"** → unitaires + API + intégration + E2E. Tout.
- Ne jamais supposer que "ça ne casse rien" — toujours vérifier
- Si un test échoue, le corriger **avant** de continuer

### ⚠️ Règle E2E avant PR — obligatoire
> **Avant toute PR, lancer la suite E2E complète :**
> ```bash
> {{E2E_RUN_COMMAND}}
> ```
> **Si des tests échouent**, ne relancer **que les tests failed** :
> ```bash
> {{E2E_LAST_FAILED_COMMAND}}
> ```
> Corriger les échecs, puis relancer `--last-failed` jusqu'à ce que tout passe.
> Ne jamais relancer la suite complète pour corriger 2-3 tests.

### Types de tests
| Type | Dossier | Commande | Quand |
|---|---|---|---|
| Unitaire | {{UNIT_DIR}} | {{UNIT_CMD}} | Chaque modification |
| Intégration | {{INT_DIR}} | {{INT_CMD}} | Avant commit |
| E2E Smoke | {{E2E_DIR}} | {{E2E_SMOKE_CMD}} | Pendant le dev |
| E2E Complet | {{E2E_DIR}} | {{E2E_FULL_CMD}} | Avant PR |
| E2E Failed only | {{E2E_DIR}} | {{E2E_FAILED_CMD}} | Après run complet |

### ⚠️ Checklist avant commit
1. ✅ Tests unitaires passent
2. ✅ Tests intégration passent

### ⚠️ Checklist avant PR
3. ✅ Tests E2E complet passent

### Écriture des tests
- Un fichier de test par fichier source
- Utiliser les helpers existants : {{TEST_HELPERS}}
- Mocker les dépendances externes en unit test
- Tester les cas nominaux **ET** les cas d'erreur (401, 403, 404, 405, 500)
- Tests d'access-control pour chaque nouvelle route

### ⚠️ Prévention des régressions sur le rendu client
- **Toute modification de logique de filtrage / tri / affichage** doit être accompagnée d'un test unitaire qui reproduit le scénario avant/après
- **Les données temporelles** sont une source fréquente de bugs — toujours tester les cas limites
- **Quand on supprime du code**, vérifier que le comportement supprimé n'était pas nécessaire — si oui, ajouter un test qui échouerait si on le re-supprime

### Naming convention
```
describe('POST /api/xxx', () => {
  it('should return 401 if not authenticated', ...)
  it('should return 403 if not authorized', ...)
  it('should create X and return 201', ...)
  it('should return 400 if field missing', ...)
})
```

---

## 5. Avant chaque commit

### Checklist obligatoire
```bash
# 1. Tests unitaires
{{UNIT_CMD}}

# 2. Build (si applicable)
{{BUILD_CMD}}

# 3. Vérifier les fichiers modifiés
git diff --stat

# 4. Ne JAMAIS committer :
#    - .env, .env.local, .env.test (secrets)
#    - node_modules/, .next/, coverage/
#    - Fichiers temporaires
```

### Message de commit
- Format : `<type>(<scope>): <description>`
- Types : `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- Pas de commit "WIP" ou "fix" seul
- Multi-ligne si nécessaire (résumé + détails)

---

## 6. Architecture — Rappels

### Structure du projet
```
{{PROJECT_STRUCTURE}}
```

### Patterns obligatoires
- **Auth** : toujours via {{AUTH_HELPER}}
- **Rôles** : vérifier `{{ROLE_FIELD}}` après auth — jamais faire confiance au client
- **Erreurs** : format standard `{ error: 'Message utilisateur.' }` — ne pas exposer `details` en production
- **DB** : toujours vérifier `error` après chaque requête
- **Webhooks** : vérification de signature obligatoire

### Anti-patterns interdits
- ❌ Secrets côté client/navigateur
- ❌ `select('*')` sans raison
- ❌ Logique métier dans les composants UI (→ helpers ou API)
- ❌ `console.log` en production (sauf erreurs critiques)
- ❌ Catch silencieux (`catch(e) {}`)
- ❌ Mutations de state sans sauvegarde API
- ❌ Commit sans tests

---

## 7. Sécurité

- **Jamais de secrets dans le code** — tout dans `.env.local`
- **Validation des inputs** côté serveur — ne jamais faire confiance aux données client
- **Honeypot** sur les formulaires publics (si applicable)
- **Rate limiting** sur les endpoints sensibles
- **CORS** : géré par le framework
- **Cookies httpOnly** pour les sessions
- **Vérification de signature** sur les webhooks

### 2FA (si applicable)
{{MFA_SECTION}}

### Rate Limiting
- **Implémentation** : {{RATE_LIMIT_HELPER}}
- **Bypassé en dev/test** pour ne pas bloquer les tests
- **À chaque nouvelle route POST/PUT/DELETE** : évaluer si un rate limit est nécessaire

| Endpoint | Limite | Nom |
|---|---|---|
{{RATE_LIMIT_TABLE}}

### Checklist sécurité — à chaque nouvelle route/feature
- [ ] Auth vérifiée en début de handler
- [ ] Rôle : vérifier le rôle — jamais faire confiance au client
- [ ] Rate limit : évaluer si nécessaire sur POST/PUT/DELETE
- [ ] Validation : valider et sanitiser les inputs côté serveur
- [ ] CSP : si appel externe → vérifier directive `connect-src`
- [ ] Upload : valider magic bytes, whitelist extensions, limiter taille
- [ ] Pas de secrets dans les réponses API ni dans les logs

---

## 8. UX/UI — Règles obligatoires

### Les 4 états obligatoires
Chaque nouvelle UI qui affiche des données doit couvrir :
- **Empty** : aucune donnée (message + CTA éventuel)
- **Loading** : skeleton/spinner pendant le chargement
- **Error** : message d'erreur FR complet, pas juste "Erreur"
- **Success** : affichage des données + toast/confirmation éventuel

### Modals (si applicable)
- {{MODAL_HELPER}} pour ouvrir/fermer
- Scroll lock du body obligatoire quand modal ouvert
- `role="dialog"` + `aria-modal="true"` (a11y)

### Z-index (si applicable web)
- **Utiliser les CSS variables** — jamais de valeurs hardcodées
- Échelle : {{Z_INDEX_SCALE}}

### Métadonnées
- **Chaque nouvelle page** doit exporter `metadata` avec un `title`
- Pages protégées : `robots: { index: false, follow: false }`
- Pages publiques : `description` SEO

### Accessibilité (minimum obligatoire)
- Modals : `role="dialog"` + `aria-modal="true"`
- Boutons icon-only : `aria-label` décrivant l'action
- Images : attribut `alt` systématique
- Toast : container `aria-live="polite"`
- Focus visible : ne jamais supprimer les outlines `:focus-visible`

### Texte et labels
- Tout le texte UI est en **{{UI_LANGUAGE}}**
- {{SPECIFIC_TYPOGRAPHY_RULES}}
- Labels boutons cohérents : {{BUTTON_LABELS}}
- Messages d'erreur : phrase complète avec contexte, pas juste "Erreur"

### CSP / Sécurité web (si applicable)
- **À chaque appel vers une API externe** (fetch client), vérifier que le domaine est dans `connect-src` de {{CSP_CONFIG}}
- Oublier cette étape provoque un blocage silencieux
- Domaines actuels autorisés : {{CSP_ALLOWED}}

---

## 9. Déploiement

```bash
# Tests avant deploy
{{FULL_TEST_CMD}}

# Build local
{{BUILD_CMD}}

# Deploy prod
{{DEPLOY_CMD}}
```

- Ne jamais déployer avec des tests en échec
- Vérifier les logs après chaque deploy
- Tester les routes critiques manuellement après deploy

---

## 10. Architecture spécifique {{PROJECT_NAME}} (optionnel)

{{PROJECT_SPECIFIC_ARCHITECTURE}}

---

## 11. IA / LLM (optionnel, si applicable)

### Architecture IA
- **Infra partagée** : {{AI_HELPER}}
- **Stockage** : {{AI_STORAGE}}
- **Budget** : {{AI_BUDGET}}

### Règles prompt IA
- **Bienveillance obligatoire** — coach, pas juge
- **JSON seul** sans backticks markdown — le parser gère les fallbacks mais le prompt doit l'interdire
- **Budget tokens** : le prompt demande N insights percutants plutôt que 2N tronqués
- **Scrub PII** server-side à la persistance — jamais compter sur une purge a posteriori

---

## 12. Pièges connus — Leçons apprises

> Cette section grandit via `/retro` après chaque feature non-triviale ou bug complexe.
> Au démarrage du projet, elle est vide — c'est normal.

### ⚠️ (Template de piège)
- **Symptôme** : ce qu'on observe
- **Cause** : pourquoi ça arrive
- **Mitigation** : comment l'éviter
- **Incident de référence** : date / commit / PR
