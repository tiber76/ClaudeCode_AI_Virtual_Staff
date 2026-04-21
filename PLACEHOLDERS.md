# Dictionnaire de placeholders

Source de vérité unique des variables utilisées dans les templates. Le skill `/setup-project` pose des questions qui remplissent ces placeholders, puis fait un remplacement global dans tous les fichiers.

**Règle** : tout placeholder apparaît **toujours** sous la forme `{{NOM}}` (double accolades, UPPER_SNAKE_CASE). Pas de `${NOM}`, pas de `<NOM>`, pas de `%NOM%`.

---

## 1. Identité projet

| Placeholder | Type | Exemple | Description |
|---|---|---|---|
| `{{PROJECT_NAME}}` | string | "Linear" | Nom du projet |
| `{{PROJECT_TAGLINE}}` | string | "The issue tracking tool you'll enjoy using" | One-liner produit |
| `{{PROJECT_DESCRIPTION}}` | string | "un SaaS B2B de gestion de tickets et projets" | Description courte pour contexte agent |
| `{{PROJECT_TYPE}}` | enum | "SaaS B2B" | SaaS B2B / SaaS B2C / Mobile app / CLI / Open source / Internal tool / Marketplace |
| `{{BUSINESS_MODEL}}` | enum | "freemium" | freemium / free trial / subscription / pay-per-use / open source / none |
| `{{UI_LANGUAGE}}` | enum | "FR" | FR / EN / multi |

---

## 2. Stack technique

### Backend
| Placeholder | Exemple | Description |
|---|---|---|
| `{{STACK_LANGUAGE_BACKEND}}` | "Node.js 22" | Langage + version |
| `{{STACK_FRAMEWORK_BACKEND}}` | "Next.js 16 App Router" | Framework backend |
| `{{STACK_DATABASE}}` | "PostgreSQL 16" | Base de données principale |
| `{{STACK_DB_CLIENT}}` | "Supabase SDK" | ORM / client DB (Prisma, Drizzle, SQLAlchemy, raw, etc.) |

### Frontend
| Placeholder | Exemple | Description |
|---|---|---|
| `{{STACK_FRAMEWORK_FRONTEND}}` | "React 19" | Framework UI (ou "vanilla JS", "native SwiftUI", etc.) |
| `{{STACK_STYLING}}` | "CSS modules + CSS vars" | Approche styling (Tailwind, CSS-in-JS, etc.) |

### Infrastructure
| Placeholder | Exemple | Description |
|---|---|---|
| `{{STACK_AUTH}}` | "Supabase Auth avec 2FA TOTP" | Solution auth |
| `{{STACK_DEPLOYMENT}}` | "Vercel" | Plateforme déploiement |
| `{{STACK_MONITORING}}` | "Sentry" | Observabilité ("none" si aucun) |

### Tests
| Placeholder | Exemple | Description |
|---|---|---|
| `{{STACK_TEST_UNIT}}` | "Jest" | Framework test unit |
| `{{STACK_TEST_E2E}}` | "Playwright" | Framework test E2E ("none" si pas de E2E) |

### Intégrations optionnelles
| Placeholder | Exemple | Description |
|---|---|---|
| `{{STACK_PAYMENT}}` | "Stripe" | Paiement ("none" si pas applicable) |
| `{{STACK_EMAIL}}` | "Resend" | Email transac ("none" si pas applicable) |
| `{{STACK_AI}}` | "Anthropic Claude" | LLM provider ("none" si pas d'IA produit) |

---

## 3. Commandes exactes

| Placeholder | Exemple | Description |
|---|---|---|
| `{{CMD_UNIT_TEST}}` | `npx jest tests/components/ tests/api/ --no-coverage` | Commande tests unit |
| `{{CMD_INT_TEST}}` | `npx jest tests/integration/ --no-coverage --runInBand` | Commande tests intégration |
| `{{CMD_E2E_FULL}}` | `npx playwright test --reporter=dot` | E2E complet |
| `{{CMD_E2E_SMOKE}}` | `npm run test:e2e:smoke` | E2E smoke (dev) |
| `{{CMD_E2E_CRITICAL}}` | `npm run test:e2e:critical` | E2E smoke + critical |
| `{{CMD_E2E_LAST_FAILED}}` | `npx playwright test --last-failed` | E2E failed only |
| `{{CMD_BUILD}}` | `npm run build` | Build production |
| `{{CMD_DEPLOY}}` | `vercel --prod` | Déploiement prod |
| `{{CMD_DEV}}` | `npm run dev` | Serveur dev |

---

## 4. Structure de dossiers

| Placeholder | Exemple | Description |
|---|---|---|
| `{{DIR_HELPERS}}` | `lib/` | Helpers serveur partagés |
| `{{DIR_ROUTES_API}}` | `app/api/` | Routes API |
| `{{DIR_COMPONENTS}}` | `components/` | Composants UI |
| `{{DIR_STYLES}}` | `styles/` | CSS global |
| `{{DIR_TESTS_UNIT}}` | `tests/` | Tests unit + API |
| `{{DIR_TESTS_INT}}` | `tests/integration/` | Tests intégration |
| `{{DIR_TESTS_E2E}}` | `e2e/` | Tests E2E |
| `{{DIR_MIGRATIONS}}` | `supabase/migrations/` | Migrations SQL ("none" si pas applicable) |

---

## 5. Conventions de nommage

| Placeholder | Exemple | Description |
|---|---|---|
| `{{NAMING_VARIABLES}}` | "camelCase" | Convention variables/fonctions |
| `{{NAMING_COMPONENTS}}` | "PascalCase" | Convention composants |
| `{{NAMING_FILES_API}}` | "kebab-case" | Convention fichiers API |
| `{{NAMING_CONSTANTS}}` | "UPPER_SNAKE_CASE" | Convention constantes |

---

## 6. Rôles utilisateurs

| Placeholder | Type | Description |
|---|---|---|
| `{{ROLES_LIST}}` | markdown table | Tableau des rôles avec label FR et permissions |
| `{{ROLES_COUNT}}` | number | Nombre de rôles (utilisé dans les docs) |
| `{{ROLE_ADMIN}}` | string | Nom du rôle admin/owner |
| `{{ROLES_ENUM}}` | comma-list | Liste courte pour énumération ("owner, admin, member, viewer") |

**Exemple `{{ROLES_LIST}}`** :

```markdown
| Rôle | Label | Accès data | Capacités clés |
|---|---|---|---|
| **owner** | Propriétaire | Tout | Admin, facturation, création ressources |
| **admin** | Administrateur | Son scope | Gestion users, config |
| **member** | Membre | Scope assigné | CRUD sur ses données |
| **viewer** | Lecteur | Scope assigné | Lecture seule |
```

---

## 7. Entités métier

| Placeholder | Type | Description |
|---|---|---|
| `{{ENTITIES_LIST}}` | markdown table | Tableau des entités principales avec source API et rôle métier |
| `{{ENTITIES_COUNT}}` | number | Nombre d'entités principales |
| `{{ENTITY_PRIMARY}}` | string | Entité principale (celle qui structure le produit) |

**Exemple `{{ENTITIES_LIST}}`** :

```markdown
| Entité | Source | Rôle métier |
|---|---|---|
| `Issue` | `/api/issues` | Ticket de travail avec priorité, statut, assigné |
| `Project` | `/api/projects` | Regroupement d'issues, milestones |
| `Team` | `/api/teams` | Groupe d'utilisateurs avec rôles |
```

---

## 8. Workflow / Statuts (si applicable)

| Placeholder | Type | Description |
|---|---|---|
| `{{HAS_STATUS_WORKFLOW}}` | boolean | true si le produit a un workflow par statuts |
| `{{STATUS_LIST}}` | markdown table | Tableau des statuts avec sens métier (si applicable) |
| `{{STATUS_WORKFLOW_DIAGRAM}}` | code block | Schéma ASCII du workflow (si applicable) |

---

## 9. Modèle business

| Placeholder | Type | Description |
|---|---|---|
| `{{HAS_PRICING_TIERS}}` | boolean | true si SaaS avec plans |
| `{{PRICING_PLANS_LIST}}` | markdown table | Tableau des plans + features gated |
| `{{PRICING_PLANS_COUNT}}` | number | Nombre de plans |
| `{{TRIAL_DURATION}}` | string | "14 jours" / "30 jours" / "none" |

---

## 10. Ton éditorial

| Placeholder | Type | Exemple | Description |
|---|---|---|---|
| `{{TONE_REGISTER}}` | enum | "direct, transparent, pragmatique" | Registre général |
| `{{TONE_SLOGAN}}` | string | "Built for modern product teams" | Slogan produit |
| `{{TONE_BANNED_WORDS}}` | comma-list | "révolutionnaire, disruptif, game-changer" | Mots bannis |
| `{{TONE_SIGNATURE_PHRASES}}` | markdown list | Phrases types du ton ADN |
| `{{TONE_EXAMPLES}}` | markdown | 3-5 exemples "MAUVAIS → BON" |

---

## 11. Sécurité / Compliance

| Placeholder | Type | Description |
|---|---|---|
| `{{HAS_AUTH}}` | boolean | Y a-t-il de l'auth (true pour la plupart) |
| `{{HAS_2FA}}` | boolean | 2FA implémentée ou prévue |
| `{{HAS_RGPD}}` | boolean | Données UE → RGPD |
| `{{HAS_RATE_LIMITING}}` | boolean | Rate limit en place |
| `{{RATE_LIMIT_ENDPOINTS}}` | markdown table | Endpoints rate-limités (si applicable) |
| `{{SENSITIVE_DATA_TYPES}}` | comma-list | "PII, données financières, données santé, credentials" |

---

## 12. Features produit

| Placeholder | Type | Description |
|---|---|---|
| `{{HAS_AI_FEATURE}}` | boolean | Produit embarque LLM (active ou supprime `ai-llm-engineer`) |
| `{{HAS_GROWTH_TEAM}}` | boolean | Activer l'équipe growth (6 agents commerciaux) |
| `{{IS_B2B}}` | boolean | B2B → garde `sales-b2b` |
| `{{IS_B2C}}` | boolean | B2C → supprime `sales-b2b` |
| `{{HAS_DESIGN_SYSTEM}}` | boolean | Design system défini |
| `{{DESIGN_SYSTEM_NAME}}` | string | Nom du DS si oui |

---

## 13. Git & déploiement

| Placeholder | Type | Exemple | Description |
|---|---|---|---|
| `{{GIT_DEFAULT_BRANCH}}` | string | "develop" | Branche par défaut des features |
| `{{GIT_PROD_BRANCH}}` | string | "main" | Branche prod protégée |
| `{{GIT_PREFIX_FEATURE}}` | string | "feature/" | Préfixe branches features |
| `{{GIT_PREFIX_FIX}}` | string | "fix/" | Préfixe branches fix |
| `{{GIT_PREFIX_HOTFIX}}` | string | "hotfix/" | Préfixe branches hotfix |

---

## 14. Métriques équipe

| Placeholder | Type | Exemple | Description |
|---|---|---|---|
| `{{TEAM_SIZE}}` | enum | "solo" | solo / 2-5 / 5-15 / 15+ |
| `{{PROJECT_STAGE}}` | enum | "prod" | idée / prototype / MVP / bêta / prod |
| `{{COMMIT_AUTHOR_NAME}}` | string | "Alex Martin" | Nom pour Co-Authored-By si présent |

---

## 15. Drapeaux d'activation agents

Ces booléens décident quels agents sont installés :

| Placeholder | Impact |
|---|---|
| `{{AGENT_PO_ENABLED}}` | true par défaut — supprime `po-metier` si false (produits techniques sans dimension métier) |
| `{{AGENT_FULL_STACK_ENABLED}}` | true par défaut |
| `{{AGENT_DESIGNER_ENABLED}}` | true par défaut — supprime si pas d'UI (CLI, API-only) |
| `{{AGENT_QA_ENABLED}}` | true par défaut |
| `{{AGENT_CSO_ENABLED}}` | conditionnel — supprime si pas de composante sécu significative |
| `{{AGENT_DATA_ENABLED}}` | conditionnel — supprime si pas d'agrégations data |
| `{{AGENT_AI_LLM_ENABLED}}` | `{{HAS_AI_FEATURE}}` |
| `{{AGENT_GROWTH_ENABLED}}` | `{{HAS_GROWTH_TEAM}}` |
| `{{AGENT_SALES_ENABLED}}` | `{{IS_B2B}} && {{HAS_GROWTH_TEAM}}` |
| `{{AGENT_CSM_ENABLED}}` | `{{HAS_GROWTH_TEAM}}` |
| `{{AGENT_COPY_ENABLED}}` | `{{HAS_GROWTH_TEAM}}` |
| `{{AGENT_CONTENT_ENABLED}}` | `{{HAS_GROWTH_TEAM}}` |
| `{{AGENT_ANALYTICS_ENABLED}}` | `{{HAS_GROWTH_TEAM}}` |

---

## 16. Flags dérivés (calculés automatiquement)

Ces flags sont **dérivés** des réponses au questionnaire — le skill `/setup-project` les calcule tout seul, ils n'apparaissent pas dans les questions directement.

| Placeholder | Dérivé de | Condition true si... |
|---|---|---|
| `{{HAS_MIGRATIONS}}` | `{{DIR_MIGRATIONS}}` | `{{DIR_MIGRATIONS}}` ≠ "none" |
| `{{BUSINESS_MODEL_TRIAL}}` | `{{BUSINESS_MODEL}}` | Valeur ∈ {"free trial", "freemium"} |
| `{{BUSINESS_MODEL_SUBSCRIPTION}}` | `{{BUSINESS_MODEL}}` | Valeur ∈ {"subscription", "free trial", "freemium"} |
| `{{BUSINESS_MODEL_OPEN_SOURCE}}` | `{{BUSINESS_MODEL}}` | Valeur = "open source" |
| `{{HAS_MONITORING}}` | `{{STACK_MONITORING}}` | `{{STACK_MONITORING}}` ≠ "none" |
| `{{HAS_PAYMENT}}` | `{{STACK_PAYMENT}}` | `{{STACK_PAYMENT}}` ≠ "none" |
| `{{HAS_EMAIL}}` | `{{STACK_EMAIL}}` | `{{STACK_EMAIL}}` ≠ "none" |

---

## Règles de formatage

### Variables multi-lignes
Pour les variables qui contiennent du markdown (tables, listes), le skill de setup injecte le contenu directement — pas de `{{VAR}}` entre quotes.

### Valeurs par défaut
Si une question n'a pas de réponse claire, le skill propose une valeur par défaut. Jamais de placeholder oublié en sortie — toujours remplacé par au moins une valeur indicative (ex: "(à compléter)").

### Variables optionnelles
Si une section entière est optionnelle (ex: `{{PRICING_PLANS_LIST}}` quand `{{HAS_PRICING_TIERS}}` est false), le skill supprime la section complète du fichier plutôt que de la laisser vide.

### Blocs conditionnels — 3 syntaxes supportées

**1. Inclusion conditionnelle simple**
```
{{#IF HAS_AI_FEATURE}}
Contenu qui n'apparaît que si HAS_AI_FEATURE est true
{{/IF}}
```

**2. Négation (contenu si false)**
```
{{#IF !HAS_PRICING_TIERS}}
Contenu qui n'apparaît que si HAS_PRICING_TIERS est false
{{/IF}}
```

**3. Branches alternatives (if/else)**
```
{{#IF IS_B2B}}
Version B2B du contenu
{{#ELSE}}
Version B2C du contenu
{{/IF}}
```

Le skill `/setup-project` évalue ces blocs et les inclut ou les supprime selon les réponses. Les blocs peuvent être imbriqués.

### Ordre d'évaluation

Le skill applique les remplacements dans cet ordre :

1. **Calcul des flags dérivés** (§16) depuis les valeurs saisies.
2. **Évaluation des blocs conditionnels** `{{#IF ...}} ... {{/IF}}` (inclusion/exclusion).
3. **Remplacement des placeholders simples** `{{VAR}}` par leur valeur.
4. **Nettoyage final** : sections vides supprimées, espaces multiples réduits.

### Placeholders non résolus

Si un placeholder n'a pas de valeur à la fin du processus, le skill :
1. Le remplace par `<!-- TODO: {{VAR}} à compléter -->`
2. Ajoute une entrée P1 dans `backlog.md` pour le traiter manuellement.
