---
name: close-session
description: |
  Clôture propre d'une session de dev en worktree : nettoie les artefacts de la session
  (serveur dev du worktree, fichiers temporaires, dossiers de run archivés), puis supprime
  le worktree + la branche (locale + distante) — UNIQUEMENT si la branche est mergée dans
  origin/{{GIT_DEFAULT_BRANCH}} et le worktree est clean (politique stricte, zéro perte de
  travail). Rend un verdict « session clean » (rien ne traîne) ou la liste exacte de ce qui
  reste à faire à l'utilisateur. Invoquer quand l'utilisateur dit « clôture la session »,
  « termine + nettoie le worktree », ou tape /close-session. Doit être lancé DEPUIS le
  worktree à supprimer.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - AskUserQuestion
triggers:
  - clôture la session
  - clôt la session
  - close session
  - nettoie le worktree
  - termine la session
---

# /close-session — clôture + teardown sûr du worktree

## Objectif

Automatiser la fin de session : nettoyer les artefacts de dev puis supprimer le worktree et sa branche, **sans jamais risquer de perdre du travail**. Une session est **clean** quand rien ne traîne derrière elle : worktree propre, travail sur `{{GIT_DEFAULT_BRANCH}}`, aucun reste-à-faire en suspens.

## Politique de sécurité (STRICTE)

Suppression du worktree + branche **locale + distante**, mais **uniquement si** :

- on est bien dans un worktree secondaire (`git rev-parse --git-dir` ≠ `git rev-parse --git-common-dir`), jamais dans le dépôt principal ;
- la branche n'est pas protégée (`{{GIT_DEFAULT_BRANCH}}`, `{{GIT_PROD_BRANCH}}`, `main`, `master`) ;
- le worktree est **clean** (`git status --porcelain` vide ; les fichiers ignorés par git sont exclus) ;
- le **travail de la branche est bien sur `origin/{{GIT_DEFAULT_BRANCH}}`**.

Si une seule condition manque → **STOP**, on rapporte le blocage, **aucune suppression**. On ne force jamais.

### « Le travail est sur {{GIT_DEFAULT_BRANCH}} » : trois preuves acceptées

Beaucoup d'équipes mergent en **squash** : la branche de base reçoit un commit neuf, sans parenté avec le sommet de la branche. Un test d'ancêtre seul produit alors un faux négatif systématique. Essayer trois preuves, de la moins chère à la plus coûteuse ; la première qui aboutit autorise :

1. **Ancêtre** : `git merge-base --is-ancestor HEAD origin/{{GIT_DEFAULT_BRANCH}}` (merge classique, fast-forward, rebase).
2. **PR mergée** : `gh pr list --head <branche> --state merged --json number,headRefOid` renvoie une PR dont `headRefOid` **vaut le HEAD local**. La comparaison de SHA empêche d'autoriser une branche qui a reçu des commits *après* le merge.
3. **Équivalence de contenu** : tous les fichiers modifiés par la branche depuis son point de départ (`git diff --name-only $(git merge-base origin/{{GIT_DEFAULT_BRANCH}} HEAD) HEAD`) sont identiques entre `HEAD` et `origin/{{GIT_DEFAULT_BRANCH}}` (`git diff --quiet HEAD origin/{{GIT_DEFAULT_BRANCH}} -- <fichiers>`). Filet quand `gh` manque ou n'est pas authentifié.

Aucune preuve → refus, avec la liste des fichiers absents ou différents sur la branche de base.

## Étapes

### 1. Contexte et gardes (aperçu, rien n'est supprimé)

```bash
git fetch origin --prune
git rev-parse --show-toplevel; git branch --show-current
git rev-parse --git-dir; git rev-parse --git-common-dir
git status --porcelain
```

Vérifier chaque garde de la politique ci-dessus et annoncer le résultat. **Si une garde échoue** (non mergé, non clean, branche protégée, hors worktree) : s'arrêter, expliquer en clair ce qui bloque (« la branche n'est pas encore mergée dans {{GIT_DEFAULT_BRANCH}} », « il reste des modifications non commitées : <liste> ») et **ne rien supprimer**. Proposer la correction (merger d'abord, committer ou mettre de côté).

### 2. Pré-cleanup best-effort (avant teardown)

- **Dossiers de run gitignorés** (`.claude/call-call-tech-lead-runs/`, `.claude/reviews/`) : les archiver hors du worktree avant son retrait (`mkdir -p ~/.claude-archives/<worktree> && cp -R …`). Une archive impossible **bloque** le teardown : mieux vaut un worktree de plus qu'un run perdu.
- **Serveur dev du worktree** : arrêter le serveur de développement lancé depuis ce worktree (`{{CMD_DEV}}`), en ciblant le processus par son port ou son répertoire de travail ; jamais un serveur d'une session parallèle.
- **Fichiers temporaires de la session** : supprimer dans `/tmp` les fichiers qui portent le nom du worktree (messages de commit, corps de PR) ; jamais un dossier, jamais un fichier d'une autre session.
- **Comptes ou données de test créés par la session** : lister ce qui a été créé pendant la session et le nettoyer avec l'outil prévu par le projet ; sans outil, le lister dans les restes à faire.

### 3. « À trancher » et non-bloquants de la session

Les « à trancher » non tranchés et la liste des non-bloquants des rapports de `/review-pr` sont présentés à l'utilisateur un par un dans un bloc `🟧 À TOI` (`fichier:ligne`, catégorie, impact) : il décide de créer une entrée de backlog, de fusionner ou d'abandonner. **Aucune entrée n'est créée d'office** ; ce qui reste sans réponse figure dans le rapport final, jamais perdu dans le chat.

### 4. Teardown réel (gardes OK uniquement)

Dans l'ordre, depuis le dépôt principal (on ne peut pas retirer un worktree depuis l'intérieur ; le retrait du worktree est la **dernière** action, après elle le répertoire courant de la session est obsolète, c'est normal) :

1. `git -C <dépôt principal> worktree remove <chemin du worktree>` (sans `--force` : il refuse si le worktree n'est pas clean) ;
2. `git -C <dépôt principal> branch -D <branche>` : `-D` est nécessaire après un squash-merge, mais n'est lancé que parce que l'une des trois preuves a passé ; jamais sur une branche protégée ;
3. branche distante : supprimer **uniquement si** son sommet est celui de la copie locale ou déjà contenu dans `origin/{{GIT_DEFAULT_BRANCH}}` (sinon `RESTE:` : jamais un travail venu d'ailleurs effacé) ; `git push origin --delete <branche>` si les hooks du projet l'autorisent, sinon `gh api -X DELETE repos/{owner}/{repo}/git/refs/heads/<branche>` ;
4. `git worktree prune`.

Chaque chose qui n'a pas pu être faite est notée `RESTE: …` avec la commande à rejouer. Un échec de suppression de branche distante ne défait pas le teardown local.

### 5. Rapport final + verdict clean

```
✅ Session clôturée — clean.
- Dossiers de run archivés : <n> dans <chemin> (ou « aucun »)
- Serveur dev du worktree arrêté (:port) (ou « aucun »)
- Fichiers temporaires supprimés : <n>
- Worktree retiré : <chemin>
- Branche supprimée : <branche> (locale + origin)
```

**Clean = les trois à la fois** : worktree propre, travail sur `{{GIT_DEFAULT_BRANCH}}`, aucun reste-à-faire (dont aucune ligne `RESTE:`). Sinon l'intitulé devient `⚠️ Session clôturée — pas clean` et chaque reste passe en bloc `🟧 À TOI` (Quoi / Pourquoi / Comment / Durée / Ensuite) : entrée de backlog ou ticket à clore avec sa commande exacte, migration à jouer par l'utilisateur, décision à trancher. Ne jamais déguiser un reste-à-faire en simple phrase dans le rapport.

## Garde-fous

- Ne jamais supprimer si une garde a échoué ; ne jamais forcer (`worktree remove --force`, `branch -D` sans preuve de merge).
- Ne jamais supprimer `{{GIT_DEFAULT_BRANCH}}`, `{{GIT_PROD_BRANCH}}`, `main`, `master`, ni le dépôt principal.
- Ne jamais clore un ticket ni une entrée de backlog sur un rapprochement incertain avec la PR : le lister dans les restes.
- Ne jamais lancer d'action payante ni de migration au nom de l'utilisateur : consigner et signaler.
- Ne jamais purger des artefacts d'une session parallèle (serveurs, fichiers, comptes de test) : seulement ceux de cette session.
- Lancer depuis le worktree à supprimer (sinon refuser).

## Référence

- Worktrees : `docs/GUIDE-LLM.md` (section sur les worktrees, si le projet en a une).
- `/ship-pr` (qui ouvre la PR, jamais mergée automatiquement) précède la clôture ; `/retro` peut la suivre.
