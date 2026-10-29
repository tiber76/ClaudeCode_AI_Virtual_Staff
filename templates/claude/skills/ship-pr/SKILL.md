---
name: ship-pr
description: |
  Chaîne complète de pré-PR : vérifie qu'on est sur une branche autorisée ({{GIT_PREFIX_FEATURE}}*,
  {{GIT_PREFIX_FIX}}*, {{GIT_PREFIX_HOTFIX}}*, chore/*, docs/*), lance unit → intégration, vérifie la trace
  `/verify` dans les commits applicatifs, affiche git status (confirmation demandée seulement si aucune
  autorisation de départ ne couvre la PR), commit, puis joue **en parallèle** l'E2E au niveau calculé
  (`aucun`, `specs` ou `smoke`, par `.claude/hooks/e2e-level.sh`) et **`/review-pr` sur le commit qui part,
  qui bloque sur 🔴 et 🟠 (zéro dette) et dont les corrections partent sans question**, le build après l'E2E,
  puis push et `gh pr create --base {{GIT_DEFAULT_BRANCH}}`. Ne merge JAMAIS la PR : le merge exige une
  instruction explicite de l'utilisateur. Invoquer quand une feature est testée, prête à partir en PR
  (`/review-pr` n'est plus à lancer à la main).
allowed-tools:
  - Bash
  - Read
  - Grep
  - Skill
triggers:
  - ship la PR
  - crée la PR
  - prêt à merger
  - ship pr
  - envoie la PR
---

# /ship-pr

> **Fil de progression** : plan de route, lignes `Étape N/M` et blocs « À TOI » selon `.claude/skills/_partage/fil-de-progression.md`. Si les étapes ci-dessous changent, la ligne de la table de ce fichier change dans le même commit.

## Objectif
Enchaîner tous les garde-fous avant PR. Sortie : une PR ouverte vers `{{GIT_DEFAULT_BRANCH}}`, **jamais mergée**.

## Quand l'utiliser
- Après `/qa-flow` (tout vert). Pas besoin de lancer `/review-pr` : il est embarqué à l'étape 8 bis, sur le commit qui part.

## Garde-fous absolus (GUIDE-LLM §0)
- ❌ JAMAIS de commit direct sur `{{GIT_PROD_BRANCH}}` ni `{{GIT_DEFAULT_BRANCH}}`.
- ❌ JAMAIS de merge automatique : « ok pour la PR » ≠ « merge ». Attendre « merge la PR » explicite.
- ❌ JAMAIS de `--no-verify`, `--force`, `--amend` sans demande explicite.
- ❌ JAMAIS supprimer une branche sans ordre explicite.
- ✅ `gh pr create` autorisé automatiquement (pas de merge).
- ✅ Commits correctifs de review : corrigés sans question après la liste affichée (cas limites : étape 8 bis).

## Ordre d'exécution

Les numéros ne bougent pas, l'ordre de jeu est : 1-2 → 3 → 4 → 6 bis → 7 → 8 (commit) → **en parallèle** l'étape 5 (E2E, en arrière-plan, sur l'arbre committé) et l'étape 8 bis (review) → l'étape 6 (build) quand le run E2E est fini, pendant que la review termine → étape 9 (push) quand E2E, build et review sont verts.

- Le disque ne bouge pas entre le lancement de l'E2E et la fin du build : un correctif de review attend la fin du build.
- Aucun commit entre l'écriture du diff de la passe `/review-pr` et le `Write` de son rapport : le rapport prend le sha de HEAD à ce moment.
- Un E2E rouge pendant la review se corrige en commit de plus, relu par la passe incrémentale suivante.

## Étapes

### 1. Branche
```bash
git branch --show-current
```
- `{{GIT_PROD_BRANCH}}` ou `{{GIT_DEFAULT_BRANCH}}` → 🛑 stop, demander de créer une branche autorisée.
- `{{GIT_PREFIX_FEATURE}}*`, `{{GIT_PREFIX_FIX}}*`, `{{GIT_PREFIX_HOTFIX}}*`, `chore/*`, `docs/*` → continuer. Autre → demander confirmation.

### 2. Working tree
```bash
git status
git diff --stat
```
Fichiers non suivis suspects (`.env*`, `*.secret`, `credentials*`) → 🛑 signaler. Aucun changement → 🛑 rien à ship.

### 3. Tests unit + API
```bash
{{CMD_UNIT_TEST}}
```
Doit passer. Échec → 🛑 stop, `/qa-flow`.

### 4. Tests d'intégration
```bash
{{CMD_INT_TEST}}
```
Doit passer. Si le diff touche un chemin sensible et que la passe de sécurité (`cso`) est due avant la review, la lancer dans le même tour (elle lit le diff sans toucher au disque).

### 5. Tests E2E : niveau calculé par le script, jamais jugé

Aucune CI ne joue les E2E avant PR, mais le **nightly rejoue toute la suite** et fait foi. Avant PR, un E2E ne se joue que si le diff le demande. **L'agent ne juge pas** : il lance le script et applique son verdict.

```bash
ROOT=$(git rev-parse --show-toplevel); git fetch origin {{GIT_DEFAULT_BRANCH}} 2>/dev/null || true
BASE=origin/{{GIT_DEFAULT_BRANCH}}   # après un correctif de review : le sha du dernier run E2E vert noté
bash "$ROOT/.claude/hooks/e2e-level.sh" "$ROOT" "$BASE" HEAD
```
Ligne 1 : `aucun|specs|smoke` · ligne 2 : la raison · puis `spec<TAB>chemin` par spec à jouer. La liste des chemins sensibles : `e2e-level.sh --sensitive` (fichier `.claude/hooks/e2e-sensitive.txt`, source unique, jamais recopiée).

| Niveau | Quand | Ce qui se joue avant PR |
|---|---|---|
| `smoke` | le diff touche un chemin sensible | `{{CMD_E2E_SMOKE}}` **avec** les specs listés, dans le même run |
| `specs` | aucun chemin sensible, mais un spec E2E ajouté ou modifié | ces specs seuls : sinon un test jamais joué n'est vu qu'au nightly |
| `aucun` | tout le reste | rien : la PR part sans E2E, la ligne de statut le dit |

- **Niveau `aucun`** : pas de run « pour être sûr », c'est la décision.
- **Script introuvable ou en échec** (code non nul, première ligne inattendue) : niveau `smoke`, le sens sûr, la raison dite dans la ligne de statut.
- **Runner détaché** : si le projet en a un (runner qui survit au kill de la session et garantit un seul run à la fois), l'utiliser plutôt que lancer l'E2E en direct dans la session. Attente en arrière-plan, jamais de `sleep` au premier plan.
- **Verdict** : vert = code 0, aucun échec, aucun test ignoré hors liste admise. Un skip hors liste se corrige comme un échec. Jamais de `.only` committé.
- **Un rouge est un rouge** : ne jamais rejouer un spec rouge dans un autre mode pour obtenir un vert. Corriger le test ou le helper.
- **Élargir** (`{{CMD_E2E_CRITICAL}}`, suite complète) seulement sur demande de l'utilisateur.
- **Run impossible** (clés E2E absentes, runner refusé) → « non joué : <raison> », jamais un vert supposé.
- Rouge → 🛑 stop, `/qa-flow` (relance des seuls échecs, `{{CMD_E2E_LAST_FAILED}}`).

### 5 bis. Test manuel local (si le diff touche du code servi)
Avant le commit qui part : le parcours du sujet est joué à la main sur le serveur local, dans un vrai navigateur (`.claude/skills/_partage/test-manuel-local.md`). Déjà joué sur ce sha par `/dev-express` ou `/fix-bug` → reprendre son statut. Un ✗ = 🛑 correctif, jamais la PR. Non joué (raison) ou sans objet (diff sans code servi) : dit tel quel dans la ligne de statut, jamais un ✓ supposé.

### 6. Build
```bash
{{CMD_BUILD}}
```
Après la fin du run E2E s'il y en a un, jamais pendant (le run sert l'app depuis le dossier de build que ce build réécrirait). Diff sans code compilé (docs, scripts shell) → sans objet, dit dans la ligne de statut.

### 6 bis. Trace `/verify` dans les commits
```bash
git log origin/{{GIT_DEFAULT_BRANCH}}..HEAD --pretty=format:"%h %s%n%b%n---"
```
Pour chaque commit qui touche du **code applicatif** (hors migrations pures, configs, docs) : le body porte une ligne `/verify : N/8 ✓` (ou `/verify : OK`). Absente sur 1+ commits → 🛑 lister les commits, demander : continuer quand même (hotfix urgent) ou rebaser pour ajouter la trace ?

### 7. Récap avant commit
```bash
git status
git diff --stat
git log origin/{{GIT_DEFAULT_BRANCH}}..HEAD --oneline
```
L'affichage est toujours fait. La question ne se pose que si **aucune autorisation explicite** de l'utilisateur ne couvre cette PR dans la session, ou si le périmètre a bougé depuis. Sinon, une ligne « Autorisation de départ : <citation courte>, périmètre inchangé » et on continue.
Dans les deux cas où elle se pose : **s'arrêter** et demander « Prêt à commit et ouvrir la PR vers `{{GIT_DEFAULT_BRANCH}}` ? (oui / non / modifier) ».

### 8. Commit
- Stager des fichiers nommés (jamais `git add -A`).
- Format `<type>(<scope>): <description>` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`), pourquoi en body si utile.
- Footer `Co-Authored-By` **tel que le harnais le fournit** (rappel d'attribution de la session), jamais recopié d'un exemple.
- Message en français avec accents : l'écrire dans un fichier temporaire et `git commit -F <fichier>` (nom de fichier frais à chaque commit, sinon git peut réutiliser un fichier obsolète).

### 8 bis. `/review-pr` sur le commit qui part (obligatoire, jamais skippable)

Après le commit, **en parallèle** du run E2E, **avant** le push. Le rapport est nommé par le sha du commit qui part : c'est la preuve qu'exige le hook `review-gate` (`.claude/hooks/review-gate.sh`). Un rapport déjà présent pour HEAD ne dispense de la passe que s'il porte ce sha, le verdict « Prêt pour /ship-pr : oui » et un niveau de pipeline conforme.

**Relire en dernier** : avant la première passe, plus rien ne doit ajouter de commit (preuve inversée sur `{{GIT_PREFIX_FIX}}*`, passe sécurité si due, conflits avec `{{GIT_DEFAULT_BRANCH}}` signalés). Ce qu'elles trouvent se corrige avant la passe.

Invoquer via le **Skill tool**, jamais en bash : `Skill(skill="review-pr")`. Le rapport classe 🔴 Bloquants / 🟠 À corriger / 🟢 OK ; chaque finding porte sa certitude et un scénario d'échec : un 🔴 confirmé est directement un test RED à écrire avant de corriger.

**Règle de blocage (zéro dette)** :
- **1+ finding 🔴 ou 🟠** : lister `fichier:ligne` + règle + correctif prévu, puis **corriger aussitôt, sans question**. Une seule question (`AskUserQuestion`, une par passe, jamais une par commit) dans quatre cas seulement : (a) un « à trancher » (décision produit), (b) un finding que le correcteur conteste sur pièce, (c) un correctif hors périmètre de la PR, (d) un correctif qui retire ou assouplit un contrôle de sécurité (authentification, droit d'accès, validation serveur, limite de débit, politique de sécurité…) ou un garde-fou du dépôt.
- **Concevoir avant de coder** pour un finding de catégorie bug : l'invariant rétabli, le cas symétrique, le test (vraies fonctions du projet, doublures à la frontière système seulement). Test rouge d'abord, correctif ensuite.
- **Tous les findings d'une passe se corrigent avant de relancer une passe** (jamais finding par finding). Nouveau commit par groupe cohérent, jamais d'amend, `/verify` tracé.
- Rejouer les étapes 3-4 sur le périmètre touché, l'étape 5 recalculée sur le delta, l'étape 6 si du code compilé bouge, puis rejouer 8 bis sur le nouveau sha. **Jamais « review sur un sha, push d'un autre ».**
- Les findings non bloquants (au sens de `/review-pr`) vont sur une liste ⚪ présentée à l'utilisateur en fin de session, qui décide un par un ; aucune entrée de backlog créée d'office.
- **Exception « à trancher »** : un 🟠 (jamais un 🔴) qui exige une décision produit → encadré « À trancher » dans la PR (quoi · options · comportement actuel). Il n'empêche pas le push, il bloque le merge.
- **0 🔴 et 0 🟠 ouvert** → étape 9, dès que E2E et build sont verts.

**Bypass interdit** : aucun skip de cette étape sans instruction explicite de l'utilisateur (`SKIP-review-pr` dans le body du commit, ou phrase explicite). Skipper en silence = anti-pattern bloquant, équivalent à `--no-verify`.

### 9. Push
```bash
git push -u origin <nom-branche>
```
Le hook `review-gate` bloque si le rapport `.claude/reviews/<sha HEAD>.md` manque ou n'est pas conforme (verdict « oui », aucun « À trancher » non traité, niveau ≥ palier calculé) et, sur une branche `fix/*`, si la preuve inversée de `fix-proof.sh` manque pour HEAD. Le run E2E vert n'est pas vérifié par la porte : c'est l'étape 5 qui en répond, et la PR le cite. Le message dit laquelle : revenir à l'étape 8 bis. Après le push, vérifier `git ls-remote origin refs/heads/<branche>` : « pre-push OK » ne prouve pas que la branche est partie.

### 10. Description de PR

Si `.github/pull_request_template.md` existe, le remplir ; sinon : Résumé, Tests, Déploiement. Le lecteur lit le body puis teste, il ne lit pas le diff.
- **Plafond 30 lignes.** Couper plutôt que condenser en prose.
- **Langage produit** : une page ou une route se nomme, un fichier ou une fonction jamais. Le pourquoi technique vit dans le body des commits.
- Une ligne de statut honnête : tests, E2E (niveau et raison), build, review (palier, passes), ce qui n'a pas été joué.
- Un changement visible à l'écran : une capture ou une étape « À vérifier » (parcours à rejouer).
- Migration à jouer, variable d'environnement à ajouter : à dire explicitement.

Écrire le body dans un fichier temporaire puis :
```bash
gh pr create --base {{GIT_DEFAULT_BRANCH}} --title "<titre court <70 car>" --body-file <fichier>
```
Terminer le body par la ligne d'attribution fournie par le harnais, le cas échéant.

### 11. Verdict final
```markdown
✅ PR ouverte : <url>
⚠️ PR **non mergée** (GUIDE-LLM §0). Pour merger, dire « merge la PR ».
```
Puis la liste ⚪ et les « à trancher » restants, pour décision de l'utilisateur.

## Anti-patterns
- ❌ `git add -A` / `git add .` (risque de commit `.env`, secrets).
- ❌ Passer l'E2E « parce que je suis sûr » ou le jouer « pour être sûr » : le niveau est calculé.
- ❌ Merger sans instruction explicite ; push force sans autorisation ; commit sur `{{GIT_PROD_BRANCH}}`/`{{GIT_DEFAULT_BRANCH}}`.
- ❌ Message de commit « fix » ou « WIP » seul.
- ❌ Un vert supposé : « non joué (raison) » ou rien.

## Référence
GUIDE-LLM §0 (git flow, merge), §4 (tests), §5 (checklist avant commit), §7 (sécurité).
