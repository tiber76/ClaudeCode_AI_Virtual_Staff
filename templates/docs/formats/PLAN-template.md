# PLAN-<slug> — <titre US associée>

**US source** : `docs/us/US-<slug>.md`
**Créé le** : <YYYY-MM-DD>
**Effort estimé** : <XS / S / M / L / XL>
**Complexité** : simple / moyenne / lourde

---

## 1. Impact architectural

### Base de données
- <nouvelles tables / colonnes / index>
- Migration SQL : `supabase/migrations/<YYYYMMDD>_<slug>.sql` (à jouer par l'humain)
- Cascade / contraintes à prévoir :

### API
- Nouvelles routes :
  - `GET /api/<ressource>` — <description>
  - `POST /api/<ressource>` — <description>
- Routes modifiées :
- Helpers à créer dans `lib/` :

### UI / Composants
- Nouvelles pages :
- Nouveaux composants :
- Styles à ajouter :

### Tracking / Observabilité
- Events à tracker :
- Sentry / logs :

---

## 2. UX / UI (obligatoire)

### Les 4 états couverts
- **Empty** : <copy + CTA>
- **Loading** : <skeleton / spinner>
- **Error** : <message FR complet>
- **Success** : <affichage + toast éventuel>

### Accessibilité
- [ ] Focus visible
- [ ] ARIA labels sur actions icon-only
- [ ] `role="dialog"` + `aria-modal` si modal
- [ ] Navigation clavier (Tab, Enter, Esc)
- [ ] Contraste AA minimum

### Responsive
- [ ] Mobile (touch targets ≥ 44px)
- [ ] Tablet
- [ ] Desktop
- [ ] Breakpoints utilisés :

### Copy FR
- Titre principal :
- CTA boutons :
- Messages empty/error/success :
- Tooltips / hints :

---

## 3. Tests (obligatoires — mappés sur les critères d'acceptation)

### Pyramide prévue
| Type | Fichier | Nb tests | Tag E2E |
|---|---|---|---|
| Unit | `tests/...` | N | — |
| Intégration | `tests/integration/...` | N | — |
| E2E | `e2e/...` | N | `@smoke` / `@critical` |

### Couverture critère → test
| AC# | Critère Gherkin | Type | Fichier |
|---|---|---|---|
| AC-1 | Given... When... Then... | E2E `@smoke` | `e2e/<slug>.spec.js` |
| AC-2 | ... | unit API | ... |

### Cas transverses obligatoires
- [ ] 401 si non authentifié
- [ ] 403 pour chaque rôle non autorisé
- [ ] 405 si méthode non supportée
- [ ] 400 pour chaque champ requis manquant
- [ ] 500 si dépendance externe down
- [ ] 429 si rate limit dépassé (si applicable)

---

## 4. Sécurité (obligatoire)

- [ ] Auth vérifiée en début de handler
- [ ] Rôle vérifié côté serveur
- [ ] Inputs validés et sanitizés
- [ ] Rate limit évalué (nécessaire ? oui/non + valeur)
- [ ] CSP mis à jour si nouveau domaine externe
- [ ] Upload : magic bytes + extensions + taille (si applicable)
- [ ] Pas de secrets dans les réponses / logs
- [ ] RGPD : chemin de purge documenté (si PII collectées)

---

## 5. Performance

- Requêtes DB optimisées (index utilisés ?)
- Pas de `SELECT *` sans raison
- Pagination prévue si liste potentiellement longue
- Cache prévu si calcul coûteux (TTL, invalidation)

---

## 6. Découpe en PR (si feature non-triviale)

### PR 1 — DB + migration
- `supabase/migrations/...`
- Commit : `feat(sql): <slug>`

### PR 2 — API + tests API
- `app/api/<slug>/route.js`
- `tests/api/<slug>.test.js`
- Commit : `feat(api): <slug>`

### PR 3 — UI + tests composants
- `components/<Slug>.js`
- `tests/components/<Slug>.test.js`
- Commit : `feat(ui): <slug>`

### PR 4 — E2E + intégration finale
- `e2e/<slug>.spec.js`
- Commit : `test(e2e): <slug>`

---

## 7. Risques / Pièges (à valider vs GUIDE-LLM §12)

- **Risque 1** : <description> — mitigation : <…>
- **Risque 2** : <description> — mitigation : <…>

---

## 8. Estimation d'effort

| Phase | Heures |
|---|---|
| Conception (déjà faite) | — |
| DB + migration | |
| API + tests API | |
| UI + tests composants | |
| E2E | |
| Review + QA | |
| **Total** | |
