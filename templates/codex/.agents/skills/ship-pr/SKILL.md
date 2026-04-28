---
name: ship-pr
description: |
  Chaîne complète de pré-PR : vérifie qu'on est sur une branche feature/* ou fix/*,
  lance unit → intégration → E2E → build, affiche git status pour confirmation,
  puis commit et `gh pr create --base {{GIT_DEFAULT_BRANCH}}`. Respecte la règle GUIDE-LLM §0 :
  ne merge JAMAIS la PR, c'est une instruction explicite requise de l'utilisateur.
  Invoquer quand une feature est reviewée et testée, prête à partir en PR.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$ship-pr` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $ship-pr

## Objectif
Automatiser l'enchaînement pré-PR avec tous les garde-fous du GUIDE-LLM. Sortie : une PR ouverte vers `{{GIT_DEFAULT_BRANCH}}`, jamais mergée.

## Quand l'utiliser
- Après `$review-pr` (0 bloquant) et `$qa-flow` (tout vert).
- Quand la feature est prête à être soumise.

## Garde-fous absolus (cf. GUIDE-LLM §0)
- ❌ JAMAIS commit sur `{{GIT_PROD_BRANCH}}` ni `{{GIT_DEFAULT_BRANCH}}` directement.
- ❌ JAMAIS merger la PR automatiquement — "ok pour la PR" ≠ "merge". Attendre "merge la PR" ou "go merge" explicite.
- ❌ JAMAIS de `--no-verify`, `--force`, `--amend` sans demande explicite.
- ❌ JAMAIS supprimer une branche sans ordre explicite.
- ✅ Commit autorisé APRÈS que l'utilisateur a vu `git status` + `git diff --stat` et confirmé.
- ✅ `gh pr create` autorisé automatiquement (pas de merge).

## Étapes

### 1. Vérification de la branche
```bash
git branch --show-current
```
- Si `{{GIT_PROD_BRANCH}}` ou `{{GIT_DEFAULT_BRANCH}}` → 🛑 arrêter immédiatement. Demander de créer une branche `{{GIT_PREFIX_FEATURE}}*` ou `{{GIT_PREFIX_FIX}}*`.
- Si `{{GIT_PREFIX_FEATURE}}*` ou `{{GIT_PREFIX_FIX}}*` ou `{{GIT_PREFIX_HOTFIX}}*` → continuer.
- Autres patterns → demander confirmation à l'utilisateur.

### 2. État du working tree
```bash
git status
git diff --stat
```
- Si fichiers non trackés suspects (`.env*`, `*.secret`, `credentials*`) → 🛑 signaler et demander avant de continuer.
- Si aucun changement → 🛑 rien à ship.

### 3. Tests unit + API (obligatoire, cf. §5)
```bash
{{CMD_UNIT_TEST}}
```
Doit passer. Si échec → 🛑 stop, invoquer `$qa-flow`.

### 4. Tests intégration (obligatoire, cf. §5)
```bash
{{CMD_INT_TEST}}
```
Doit passer.

### 5. Tests E2E (obligatoire avant PR, cf. §4)
```bash
{{CMD_E2E_FULL}}
```
Si échec → 🛑 stop, invoquer `$qa-flow` (boucle `--last-failed`).

### 6. Build
```bash
{{CMD_BUILD}}
```
Doit passer sans erreur.

### 7. Recap avant commit
Afficher :
```bash
git status
git diff --stat
git log origin/{{GIT_DEFAULT_BRANCH}}..HEAD --oneline
```
**S'arrêter ici et demander explicitement** :
> "Prêt à commit et ouvrir la PR vers `{{GIT_DEFAULT_BRANCH}}` ? (oui / non / modifier)"

Attendre la réponse. Si pas de "oui" / "go" / équivalent → stop.

### 8. Commit
Après validation uniquement :
- Stager uniquement les fichiers pertinents (éviter `git add -A` ; préférer `git add <fichiers explicites>`).
- Message de commit :
  - Format : `<type>(<scope>): <description concise>` (ex: `feat(alerts): canaux Slack + Teams`)
  - Types : `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
  - Multi-ligne si nécessaire pour expliquer le "pourquoi"
  - Footer : `Co-Authored-By: Codex <noreply@openai.com>`

Utiliser HEREDOC pour préserver le formatage :
```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<détails optionnels>

Co-Authored-By: Codex <noreply@openai.com>
EOF
)"
```

### 9. Push
```bash
git push -u origin <nom-branche>
```
Si la branche n'existe pas remote → `-u` crée le tracking.

### 10. Création de la PR
```bash
gh pr create --base {{GIT_DEFAULT_BRANCH}} --title "<titre court <70 car>" --body "$(cat <<'EOF'
## Résumé
- <bullet 1>
- <bullet 2>
- <bullet 3>

## Changements
<liste des modifs principales>

## Tests
- [x] Unit + API : `{{CMD_UNIT_TEST}}`
- [x] Intégration : `{{CMD_INT_TEST}}`
- [x] E2E full : `{{CMD_E2E_FULL}}`
- [x] Build : `{{CMD_BUILD}}`

## Checklist
- [x] Review passée (`$review-pr`)
- [x] QA passée (`$qa-flow`)
- [x] Pas de bloquant sécurité
- [x] Tests écrits pour les changements

## Déploiement
- [ ] Migration SQL à jouer manuellement : <oui/non + chemin>
- [ ] Variables d'env à ajouter : <oui/non + liste>

🤖 Generated with [Codex](https://claude.com/claude-code)
EOF
)"
```

### 11. Verdict final
Retourner l'URL de la PR et :
```markdown
✅ PR ouverte : <url>
⚠️  PR **non mergée** (règle GUIDE-LLM §0). Pour merger, dire "merge la PR".
Prochaines étapes suggérées :
- Si migration SQL → l'utilisateur la joue en staging, puis prod.
- Une fois OK → "merge la PR" pour exécuter le merge.
```

## Anti-patterns à éviter
- ❌ `git add -A` ou `git add .` aveuglément (risque de commit `.env`, secrets).
- ❌ Skip des tests parce que "je suis sûr que ça passe".
- ❌ Merger la PR sans instruction explicite.
- ❌ Push force sans raison explicite et autorisation.
- ❌ Committer sur `{{GIT_PROD_BRANCH}}` ou `{{GIT_DEFAULT_BRANCH}}`.
- ❌ Commit avec message "fix" ou "WIP" seul.
- ❌ Omettre le `Co-Authored-By` OpenAI/Codex.

## Référence GUIDE-LLM
- §0 Git flow (branches, règles de merge, PR base `{{GIT_DEFAULT_BRANCH}}`)
- §4 Tests (E2E obligatoire avant PR)
- §5 Checklist avant commit
- §7 Sécurité (pas de secrets en commit)

## 💰 Coût indicatif

Tokens : ~20-60k brut · ~10-25k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.25
Détail complet et optimisations : `docs/COUTS-LLM.md`.
