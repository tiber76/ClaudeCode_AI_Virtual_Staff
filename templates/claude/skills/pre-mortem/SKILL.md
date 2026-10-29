---
name: pre-mortem
description: |
  Pensée adversaire sur un diff sensible : génère 5-10 edge cases (temporels, état utilisateur
  rare, environnement dégradé, charge, erreurs externes) à transformer en tests AVANT le commit.
  Path-gating calculé : ne tourne que si `review-level.sh --files` classe un fichier du diff
  « sensible » (liste réglable, voir section « Path-gating »). Hors chemin sensible, skip explicite
  (`SKIP-pre-mortem` dans le body du commit). Délègue au sous-agent `pre-mortem-adversaire`. Appelé
  par /verify sur chemin sensible, par le worker `full-stack-lead` et par /call-tech-lead (phase 6).
allowed-tools:
  - Agent
  - Bash
  - Read
  - Grep
  - Glob
triggers:
  - pre-mortem
  - pré-mortem
  - edge cases du diff
  - pensée adversaire
  - what could go wrong
---

# /pre-mortem

## Objectif
Forcer une passe « pensée adversaire » sur un diff sensible avant le commit. 5-10 edge cases concrets à couvrir par tests (RED puis GREEN), pas une réflexion abstraite.

## Path-gating (configurable)

Activer le skill **uniquement** si le calcul ci-dessous affiche au moins une ligne `sensible`. La liste des chemins sensibles a une source unique, `.claude/hooks/review-level.sh`, réglable via `REVIEW_SENSITIVE_RE` dans `.claude/hooks/config.sh` (ne pas la recopier ici) :

```bash
ROOT=$(git rev-parse --show-toplevel)
bash "$ROOT/.claude/hooks/review-level.sh" --files "$ROOT" origin/{{GIT_DEFAULT_BRANCH}} HEAD | grep '^sensible'
```

Aucune ligne `sensible` : log explicite `pre-mortem skipped : diff hors chemin sensible. Pour forcer : /pre-mortem --force.`

## Quand l'utiliser
- Avant chaque commit applicatif sur un chemin sensible (`/verify` le demande, le worker `full-stack-lead` aussi).
- `/call-tech-lead`, phase 6, pour une tranche qui touche un chemin sensible.
- Manuellement, après une modif déjà faite mais avant commit.

## Principes
1. **5-10 cas concrets, pas un essai philosophique.** Format : *quand X arrive, Y se passe, le diff doit réagir Z, voici le test*.
2. **Ancré sur les risques connus** : pièges de `docs/GUIDE-LLM.md` §12 et rétros récentes. Pas d'invention abstraite.
3. **Liste, pas dialogue.** La sortie est une checklist Markdown intégrable au body du commit.
4. **Le sous-agent ne corrige pas.** Il propose des cas ; le dev écrit les tests.

## Étapes

### 1. Récolte du diff
```bash
git diff origin/{{GIT_DEFAULT_BRANCH}}...HEAD --name-only
git diff origin/{{GIT_DEFAULT_BRANCH}}...HEAD
```
Vérifier le path-gating. Hors scope → skip.

### 2. Contexte
- Les concepts de `docs/GUIDE-LLM.md` touchés par le diff (helpers canoniques modifiés, contrat changé).
- Les 3-5 dernières rétros du domaine (`docs/retros/`, si le dossier existe) pour rappeler les pièges déjà vécus.

### 3. Délégation au sous-agent `pre-mortem-adversaire`

Entrée : diff + concepts touchés + extraits de pièges §12 pertinents + rétros. Sortie attendue : 5-10 cas répartis en :
- **Temporel** : expiration de session, TTL de cache, quota mensuel, changement d'heure.
- **État utilisateur rare** : rôle sans rattachement, essai expiré avec abonnement actif, compte verrouillé, authentification à deux facteurs incomplète.
- **Environnement manquant ou dégradé** : variable d'environnement absente, base indisponible, webhook retardé.
- **Charge / concurrence** : double soumission, course entre deux écritures, verrou à libérer.
- **Erreurs externes** : 500 d'un service tiers, délai dépassé, JSON malformé.

Format imposé par cas :
```
- **<catégorie> : <description courte>**
  - Quand : <condition déclenchante>
  - Effet attendu : <ce que le diff doit faire>
  - Test à écrire : <fichier:nom du test>
```

### 4. Sortie dans le body du commit
```
Pre-mortem
----------
- [ ] <cas 1>
- [ ] <cas 2>
```
Le dev coche les cas dont le test existe avant le commit. Un cas non coché = une ligne explicite à l'utilisateur, pas un oubli silencieux.

## Budget
Skip hors chemin = 0 token. Sur chemin sensible, viser ~5k tokens effectifs par invocation.

## Anti-patterns
- ❌ Activer hors chemin sensible « pour le principe » : fatigue et indifférence.
- ❌ Sortir une réflexion sans cas concrets : sortie rejetée.
- ❌ Proposer des correctifs : rôle du dev ou de `/call-tech-lead`.
- ❌ Reproposer des cas déjà couverts par les tests existants : vérifier d'abord.
