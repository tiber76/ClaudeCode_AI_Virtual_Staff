---
name: security-audit
description: |
  Audit sécurité périodique du projet : scan des routes API (auth + rate-limit),
  vérif qu'aucun client admin/service-role ne fuite côté client, `select('*')`,
  CSP `connect-src`, `npm audit`, tests access-control sur routes récentes.
  Produit un rapport priorisé Critique / Élevé / Moyen / Info. Invoquer
  mensuellement ou après ajout de nouvelles routes API.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$security-audit` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $security-audit

## Objectif
Vérifier systématiquement que les règles sécurité du GUIDE-LLM §7 sont appliquées dans tout le code. Remonter les trous avant qu'ils ne soient exploités.

## Quand l'utiliser
- Mensuel (routine).
- Après avoir ajouté 3+ nouvelles routes API.
- Avant un déploiement majeur.
- Après une alerte `npm audit` ou une CVE publiée.

## Principes
1. **Faux positifs signalés comme tels.** Si une route n'a pas de rate-limit mais est protégée par un guard admin, signaler "faible risque" pas "critique".
2. **Priorité = impact × exposition.** Une route publique non rate-limitée = Critique. Une route admin-only sans rate-limit = Moyen.
3. **Ne pas corriger dans ce skill.** Observer, rapporter, suggérer.

## Étapes

### 1. Inventaire des routes API
```bash
find {{DIR_ROUTES_API}} -name "*.js" -o -name "*.ts" -o -name "route.js" -o -name "route.ts" 2>/dev/null
```
Liste toutes les routes à auditer.

### 2. Scan auth
Pour chaque route, vérifier la présence du (ou des) pattern(s) d'auth du projet (ex: `getSessionUser(`, `requireAuth(`, middleware global, etc.) en début de handler :
```bash
# Routes sans pattern d'auth détecté — adapter la regex au projet
for f in $(find {{DIR_ROUTES_API}} -name "*.js" -o -name "*.ts"); do
  if ! grep -qE "(getSessionUser|requireAuth|withAuth|middleware)" "$f"; then
    echo "NO_AUTH: $f"
  fi
done
```
Analyser chaque résultat — certaines routes publiques (login, signup, contact, webhooks signés) sont légitimement sans auth.

{{#IF HAS_RATE_LIMITING}}
### 3. Scan rate-limit (POST/PUT/DELETE)
Grep `export default` ou `export async function POST|PUT|DELETE` puis vérifier l'appel au helper de rate-limit du projet dans le même fichier. Si absent + route sensible → signaler.

Comparer à la table §7 du GUIDE-LLM (liste des routes actuellement rate-limitées) pour repérer les nouvelles routes non listées.
{{/IF}}

### 4. Scan client admin / service-role côté client (critique)
Grep les symboles de client "admin" / "service-role" (ex: `supabaseAdmin`, `adminClient`, `SERVICE_ROLE_KEY`) dans tout le code frontend :
```bash
grep -rnE "(supabaseAdmin|adminClient|SERVICE_ROLE)" {{DIR_COMPONENTS}} public/ app/ 2>/dev/null | grep -v "//"
```
Doit être **vide ou ne ramener que des composants server-side explicites**. Toute occurrence dans du code marqué `'use client'` ou dans un bundle public = Critique.

### 5. Scan `select('*')`
```bash
grep -rn "\.select('\*')" {{DIR_ROUTES_API}} {{DIR_HELPERS}} 2>/dev/null
```
Signaler chaque occurrence. Certaines peuvent être légitimes (lecture complète nécessaire), d'autres sont de la flemme et surexposent des colonnes sensibles.

{{#IF STACK_DB_CLIENT}}
### 5bis. Vérification RLS / politiques d'accès DB
Si la stack utilise `{{STACK_DB_CLIENT}}` avec des politiques Row Level Security ou équivalent :
- Lister les tables sans policy active (requête système selon la stack).
- Vérifier que chaque table contenant des données utilisateur a au moins une policy `SELECT` restrictive.
- Signaler toute table accessible en anon sans filtrage explicite.
{{/IF}}

### 6. CSP `connect-src` vs `fetch()` client
- Lire la config de headers (ex: `next.config.js`, middleware Express, fichier de proxy) → extraire les domaines de `connect-src`.
- Grep tous les `fetch(` dans `{{DIR_COMPONENTS}}` / bundles client → extraire les domaines externes.
- Différentiel : tout domaine fetché non listé en CSP → Élevé (blocage silencieux en prod).

```bash
grep -rhE "fetch\s*\(\s*['\"\`]https?://" {{DIR_COMPONENTS}} public/ 2>/dev/null | \
  sed -E "s/.*fetch\s*\(\s*['\"\`](https?:\/\/[^'\"\`\/]+).*/\1/" | sort -u
```

### 7. Audit dépendances
```bash
npm audit --audit-level=moderate
```
Lister les vulnérabilités high/critical. Pour chaque → proposer `npm audit fix` ou alternative.

### 8. Tests access-control sur routes récentes
```bash
git log --since='30 days ago' --name-only --pretty=format: | grep -E "{{DIR_ROUTES_API}}.*\.(js|ts)$" | sort -u
```
Pour chaque route récemment ajoutée/modifiée, vérifier la présence d'un fichier `{{DIR_TESTS_UNIT}}/...` avec tests 401/403.

### 9. Scan secrets en commit (rétrospectif)
```bash
git log --all --full-history -- "*.env" "*.env.*" "*secret*" "*credentials*" 2>/dev/null | head -20
```
Si quelque chose apparaît → Critique (rotation des secrets requise, au-delà du scope de ce skill).

### 10. Scan `console.log` en code serveur
```bash
grep -rn "console\.log" {{DIR_ROUTES_API}} {{DIR_HELPERS}} 2>/dev/null | grep -v "// " | head -20
```
Signaler — ne pas supprimer (peut être du debug volontaire). Attention aux logs qui exposent des données sensibles.

### 11. Scan handlers inline HTML (piège §12)
```bash
grep -rnE 'on(click|change|submit|input|mouseenter)=' {{DIR_COMPONENTS}} public/ 2>/dev/null
```
Doit être vide (si CSP `nonce` ou `strict-dynamic` actif). Toute occurrence = Critique (bloqué CSP).

{{#IF HAS_2FA}}
### 12. Vérification 2FA / MFA
- Lister les endpoints sensibles (changement de mot de passe, suppression compte, accès facturation).
- Vérifier pour chacun la présence d'un guard qui exige un challenge 2FA récent (timestamp signé, session élevée).
- Signaler tout endpoint sensible sans challenge.
{{/IF}}

{{#IF HAS_RGPD}}
### 13. Conformité RGPD
- Vérifier la présence d'endpoints d'export et de suppression des données utilisateur (droit à l'oubli, portabilité).
- Vérifier que la politique de rétention est documentée (dans `docs/` ou équivalent).
- Vérifier le consentement cookies / tracking si applicable.
- Signaler toute collecte de donnée sensible sans base légale documentée.
{{/IF}}

### 14. Rapport final

```markdown
# Security Audit — {{PROJECT_NAME}} — <YYYY-MM-DD>

**Scope** : tout le projet
**Durée scan** : Xs
**Commit** : <hash>

## Critique (action immédiate)
<items ici — vide si rien>

## Élevé (à traiter avant prochain deploy)
<items>

## Moyen (à planifier)
<items>

## Info / faux positifs possibles
<items à challenger humainement>

## Synthèse quantitative
| Catégorie | OK | Problèmes |
|---|---|---|
| Routes avec auth | X / Y | ... |
| Routes POST/PUT/DELETE avec rate-limit | X / Y | ... |
| Clients admin côté client | 0 / N | ... |
| CSP `connect-src` complet | OK / KO | ... |
| `npm audit` (high+critical) | N vulnérabilités | ... |
| Tests access-control routes récentes | X / Y | ... |

## Recommandations priorisées
1. <action 1>
2. <action 2>
3. <action 3>

## Comparaison vs audit précédent
<si cache disponible : évolution du score>
```

## Anti-patterns à éviter
- Tout marquer "Critique" pour paraître rigoureux — tue la priorisation.
- Corriger automatiquement une vuln (pourrait casser le code, demander validation).
- Ignorer les "Info" sans réfléchir (c'est là que se cachent les pièges subtils).
- Ne pas tenir compte du contexte (route publique vs admin-only).

## Référence GUIDE-LLM
- §7 Sécurité (checklist nouvelle route, rate-limit, 2FA, CSP)
- §8 UX/UI (CSP `connect-src`, handlers inline interdits)
- §12 Pièges connus (handlers inline HTML)

## Coût indicatif

Tokens : ~60-150k brut · ~20-50k effective (avec prompt caching 90%)
Équivalent API : ~$0.25-0.7
Détail complet et optimisations : `docs/COUTS-LLM.md`.
