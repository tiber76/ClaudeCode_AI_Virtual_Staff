---
name: dev-express
description: |
  La voie courte pour un petit sujet : bug, dette ou tâche de taille S, outil interne,
  docs. Garde tout ce qui protège — branche depuis {{GIT_DEFAULT_BRANCH}}, $investigate-bug si
  bug, TDD, $verify par commit, $ship-pr (review au palier calculé, porte review-gate,
  zéro dette, PR vers {{GIT_DEFAULT_BRANCH}}) — et retire la cérémonie d'un gros sujet (PO/US,
  Round 1, Round 2, plan, worker frais, transcript long). Refuse vers $call-tech-lead au
  moindre signal lourd. Jamais pour une User Story, jamais de merge.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$dev-express` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $dev-express

> **Fil de progression** : plan de route, lignes `Étape N/M` et blocs « À TOI » selon `.agents/skills/_partage/fil-de-progression.md`.

## Objectif

Livrer un petit sujet en PR avec les mêmes garde-fous que `$call-tech-lead`, sans sa cérémonie. Ce qui protège reste : branche, cause racine, TDD, `$verify`, review au palier calculé, porte, PR vers `{{GIT_DEFAULT_BRANCH}}`. Ce qui cadre un gros sujet saute : PO et US, Round 1, Round 2, plan, worker frais, transcript long, estimation de coût.

**Ce que ça ne change pas** : le palier de review reste calculé par `.codex/hooks/review-level.sh` sur le diff réel, jamais abaissé. Express allège l'amont, pas l'aval.

## Format d'invocation

```
$dev-express <cible> [--mode=auto|semi]
```

- `<cible>` : un ticket, une issue, une entrée de backlog (`backlog.md`), ou un besoin en texte libre.
- `--mode=semi` (défaut) : un seul checkpoint, après la note de cadrage et avant la première ligne de code ; puis ceux de `$ship-pr`.
- `--mode=auto` : aucune question, sauf l'arbitrage indispensable. Les décisions prises seules sont tracées dans le TRANSCRIPT.

Une PR = un contexte frais : un run express = une PR ; un second sujet = une nouvelle session.

## Éligibilité — refuser vers le lourd, jamais vers le léger (source unique)

Éligible si **tout** est vrai :

1. **Origine** : ticket, issue ou entrée de backlog de type bug / dette / tâche de taille **S** ; sujet sur un outil interne (scripts, `.codex/`, docs) ; ou besoin en texte libre que l'utilisateur qualifie lui-même de petit.
2. **Aucun signal lourd**. Un seul suffit à refuser :
   - nouvelle route ou endpoint d'API, identifiant de ressource en paramètre d'URL ;
   - migration de schéma / de données ;
   - authentification, permissions, rôles, multi-tenant ;
   - paiement, facturation ;
   - upload de fichier, données sensibles ({{SENSITIVE_DATA_TYPES}}) ;
   - fonctionnalité IA / prompts ;
   - nouvelle page ou refonte d'interface (un correctif visuel sur une page existante reste express) ;
   - tout ce que la grille de routing de `$call-tech-lead` (Phase 1) convoquerait en renfort (sécurité, data, IA, design).
3. **Jamais une User Story** : une US est un sujet produit par définition (PO, tranches, plan). C'est `$call-tech-lead`.
4. **Taille attendue sous le seuil `leger` de `.codex/hooks/review-level.sh`** (lignes applicatives hors tests), estimée après lecture des fichiers pressentis, pas devinée.

Non éligible, ou un doute → `$call-tech-lead <cible> --mode=<même mode>`. Refuser vers le lourd coûte une cérémonie ; refuser vers le léger coûte un angle mort. **Ce jugement est le seul de la voie express**, et il ne peut faillir que dans le sens sûr : le filet aval recalcule sur le diff réel.

**Filet aval** : à l'étape `$ship-pr`, `review-level.sh` rend le palier sur le diff réel. Si c'est `complet` (chemin sensible, ou au-delà du seuil `leger`), ce n'est pas un échec : la review se joue au palier calculé, et si un chemin sensible est touché, un agent `cso` relit le diff **avant la première passe de review**. La ligne de statut de la PR porte « palier review : complet (<raison>) » : l'utilisateur voit l'écart sans ouvrir le code.

**Requalification en cours de route** : si le dev révèle un signal lourd (une migration devient nécessaire, une route apparaît, une permission entre en jeu) → STOP. En `semi` : `question utilisateur` avec l'analyse et trois options (basculer en `$call-tech-lead`, réduire le scope pour rester express, continuer avec `cso` en plus). En `auto` : écrire `NEXT-RUN-<slug>.md` dans le dossier de run (état, commits, signal détecté, recommandation), clore le TRANSCRIPT sur « Arrêt : requalifié, relancer en standard », **pas de PR**.

## Étapes

### 0. Intake

1. Parse la cible et `--mode`. Slug kebab-case stable (branche, commits, titre de PR).
2. Dossier de run `.codex/runs/call-tech-lead/<YYYYMMDD-HHMMSS>-<slug>/` (gitignoré, même racine que `$call-tech-lead`). Écrire `00-input.md` (cible verbatim, mode, horodatage, origine : direct ou bascule depuis `$call-tech-lead`) et `TRANSCRIPT.md` (gabarit ci-dessous).
3. **Éligibilité** : verdict et raison dans le TRANSCRIPT, une ligne. Non éligible → bascule et fin du run.
4. **Branche** : si une branche de travail est déjà active (créée pour la session), la garder. Sinon la créer depuis la branche de base à jour : `git fetch origin && git switch -c {{GIT_PREFIX_FIX}}<slug> origin/{{GIT_DEFAULT_BRANCH}}` (`chore/<slug>` pour une dette, une tâche ou un outil, `docs/<slug>` pour de la doc seule). Écrire la base : `git merge-base origin/{{GIT_DEFAULT_BRANCH}} HEAD > <run>/06-base.sha`. Sur toute autre branche : confirmation en `semi`, STOP en `auto`. Avant le ship : arbre propre, diff non vide, aucun empilement sur une autre PR.
5. Pas d'annonce de coût, pas de plan, pas d'US.

### 1. Bug → cause racine d'abord

Cible de type bug → `Skill(skill="fix-bug")`, le profil bug de l'express : il reprend les étapes 0, 3, 4 et 5 d'ici et y ajoute la cause racine avant tout patch (`$investigate-bug`, rapport dans `01-investigation.md`, **interdit de patcher sans**), le test de reproduction rouge avant le fix, la preuve inversée par `.codex/hooks/fix-proof.sh` et l'angle altitude en review. Le fix robuste proposé par `$investigate-bug` par défaut ; l'option minimale se justifie dans la note de cadrage, jamais en silence.

### 2. Note de cadrage — 10 lignes, vérifiées

`00-cadrage.md`, écrite **après** `rg` et lecture des fichiers pressentis (une hypothèse vaut ce que vaut le code qui la confirme : recherche et lecture avant d'écrire, jamais une supposition) :

- **Quoi** : le texte réel que verra l'utilisateur final ou l'outil, avant / après.
- **Pourquoi** : le besoin, en une phrase.
- **Fichiers pressentis** : `chemin:ligne`, lus, pas supposés.
- **Cas de test** (5 à 10) : le cas nominal, les bords, l'erreur. C'est le brief QA de l'express, écrit par le dev. Un cas sans état initial et résultat attendu nommables n'est pas un cas.
- **Fini quand** : la preuve démontrable (test vert, capture, commande qui rend le bon résultat).
- **Hors scope** : ce qu'on ne touche pas, explicitement.

`semi` : checkpoint unique. La note s'affiche en entier dans le chat (pas seulement dans le fichier), puis « la note te va ? » ; une phrase de réponse suffit. `auto` : continue.

### 3. Dev en session — TDD, un commit par cas

Pas de worker : la session écrit le code (le contexte est frais par construction, un run = une PR).

- **TDD strict** par cas de la note : test rouge (lire le message d'échec : il vient de la feature manquante, pas d'un import cassé), code minimal, refactor. Exceptions : config pure, docs, renommage pur. Du code applicatif écrit sans test rouge préalable est supprimé et réécrit.
- **Commits atomiques**, 2 à 5 pour un sujet S, messages FR avec accents écrits via fichier (`git commit -F <fichier>`, un nom de fichier unique par commit, ex. `mktemp`, pour qu'un fichier obsolète ne soit pas réutilisé), `git add` nominatif, jamais `-A`. Body : ce que ça change en clair, pourquoi, tests, trace `$verify : N/8 ✓`.
- **`$verify` avant chaque commit** (8 items ; un item sans objet est dit N/A avec la raison, jamais omis). Smoke visuel sur le layout réel si UI.
- **Constantes métier** : `rg` avant tout littéral, pour réutiliser la constante exportée existante plutôt que la redéclarer.
- **Test manuel local** : une fois les cas de la note verts, si le sujet touche l'application, l'agent joue lui-même le parcours sur le serveur local (`{{CMD_DEV}}`), dans un vrai navigateur, avant `$ship-pr`. Règle et statuts (✓ / ✗ / non joué + raison / sans objet) : `.agents/skills/_partage/test-manuel-local.md`. Un ✗ est un défaut à corriger, jamais une PR.
- Log court dans `06-implementation.log` (un bloc par commit : fichiers, tests, verify).
- **Dérive de taille** : au-delà du seuil `leger` ou sur un chemin sensible, on ne s'arrête pas (le filet aval s'en charge), mais le TRANSCRIPT le note à ce moment-là, pas après coup.

### 4. `$ship-pr`, tel quel

`Skill(skill="ship-pr")` sans rien en retirer : tests, trace `$verify`, **`$review-pr` au palier calculé** (zéro dette, porte `review-gate`), push, `gh pr create --base {{GIT_DEFAULT_BRANCH}}`.

- **Tests sur le périmètre touché** : unitaires (`{{CMD_UNIT_TEST}}`) puis intégration (`{{CMD_INT_TEST}}`) ; E2E au niveau calculé par `.codex/hooks/e2e-level.sh` (`aucun`, `specs` ou `smoke`, jamais jugé par l'agent ; sans suite E2E dans le projet, sans objet et dit dans la PR) ; docs seules → rien à jouer, et la PR le dit.
- **Body de PR** : le gabarit de PR du projet, court, en langage produit, plus **une seule ligne de statut**, gabarit unique pour l'express et ses profils (`$fix-bug` y ajoute ses champs, jamais une seconde ligne) : `Mode : express|fix-bug — éligibilité : <origine, taille> · palier review : <docs|leger|complet> (<raison du script>) · test manuel local : <✓ (<scénario court>) | ✗ | non joué (<raison>) | sans objet (<raison>)>`.
- **Chemin sensible dans le diff** (palier `complet`) : agent `cso` sur le diff avant d'invoquer `$ship-pr`, donc avant la première passe de review.
- Jamais de merge.

### 5. Restitution

Message final = les 5 questions de `.agents/skills/_partage/fil-de-progression.md` § Restitution (ce que ça change avec un exemple vécu, l'écart au cadrage, ce que l'utilisateur valide, ce que l'utilisateur fait, ce qui n'est pas fait), la rubrique **Test manuel local** (distincte des tests automatiques), puis les preuves en une ligne. Le TRANSCRIPT est clos avec la même restitution.

## TRANSCRIPT — une page

```markdown
# Express — <slug> (<date>, mode <semi|auto>)

Cible : <ticket | issue | backlog <entrée> | texte libre> · Origine : <direct | bascule $call-tech-lead>
Éligibilité : ✓ <origine, taille, aucun signal lourd> | ✗ → $call-tech-lead (<raison>)
Investigation (bug) : <cause racine, option retenue> | N/A
Preuve inversée (fix-bug) : ok (<test>, base <sha7>) | N/A
Tests E2E (fix-bug) : <n> audités (<catégories>) — <verdict> · <m> ajoutés ou corrigés · rejeu <identifiant du run> vert | non joué (<raison>) | N/A
Note de cadrage : 00-cadrage.md — <n> cas
Commits : <n> — <hash7 titre> …
Tests : <ce qui a été joué, P/T> · $verify : N/8 sur chaque commit
Test manuel local : ✓ <scénario, ce qui s'affiche> | ✗ <quoi, corrigé en <sha7>> | non joué (<raison>) | sans objet (<raison>)
Review : <sha7> palier <docs|leger|complet> (<raison>) — <n> passe(s), 0 🔴 0 🟠 ouvert · à trancher : <n> · non bloquants : <m> | 0
PR : <url>
Non vérifié : <ce qui n'a pas pu l'être, et pourquoi>
Ce que ça change, en clair : <3 lignes, texte réel + exemple>
```

## Garde-fous absolus

- Jamais de merge ; jamais de commit direct sur `{{GIT_DEFAULT_BRANCH}}` ou `{{GIT_PROD_BRANCH}}` ; jamais de contournement des hooks git, de réécriture d'historique ni de push forcé sans ordre explicite de l'utilisateur.
- Jamais jouer une migration : l'agent écrit le fichier, l'utilisateur le joue. Une migration est un signal lourd → `$call-tech-lead`.
- Jamais un palier de review abaissé, jamais de bypass de la porte sans instruction de l'utilisateur.
- Jamais une User Story en express.
- Jamais d'entrée de backlog créée d'office : les non-bloquants et dettes repérées sont listés en fin de session, l'utilisateur décide.
- Commit sur `{{GIT_PREFIX_FEATURE}}*`, `{{GIT_PREFIX_FIX}}*`, `chore/*`, `docs/*` après tests verts ; PR vers `{{GIT_DEFAULT_BRANCH}}`.

## Ce que le skill ne fait pas

Pas d'US ni de PO, pas de Round 1 ni de Round 2, pas de plan dans `docs/plans/`, pas de worker (une seule branche, une seule session), pas d'agents commerciaux, pas d'estimation de coût. Si l'un de ces éléments manque au sujet, c'est que le sujet n'est pas express.

## Référence

- `$call-tech-lead` (la bascule, grille des signaux), `$investigate-bug`, `$fix-bug`, `$verify`, `$ship-pr`, `$review-pr`.
- Hooks : `.codex/hooks/review-level.sh` (paliers et chemins sensibles, source unique), `.codex/hooks/e2e-level.sh`.
