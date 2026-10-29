---
name: fix-bug
description: |
  Le profil bug de $dev-express : corriger un bug de taille S avec la preuve que le fix est
  qualitatif, pas seulement vert. Cause racine avant tout patch ($investigate-bug), test de
  reproduction écrit et rouge avant le fix, preuve inversée mécanique (.codex/hooks/fix-proof.sh :
  le test échoue sans le fix, passe avec, vérifié pas déclaré, et vérifiée par la porte
  review-gate sur les branches de fix), angle « altitude » ajouté à la review quel que soit
  le palier, périmètre du diff = la cause et son test, audit des tests E2E du parcours avant
  le fix (pourquoi étaient-ils verts ?). Même éligibilité que $dev-express (§ Éligibilité,
  source unique : un signal lourd renvoie à $call-tech-lead). Jamais de merge.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$fix-bug` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $fix-bug

> **Fil de progression** : plan de route, lignes `Étape N/M` et blocs « À TOI » selon `.agents/skills/_partage/fil-de-progression.md`.

## Objectif

Corriger un bug avec quatre preuves que le fix est qualitatif, et pas seulement que le test est vert :

1. **Reproduction** : le test échoue sans le fix et passe avec, vérifié par un script, jamais déclaré. Un test vert sans le fix ne prouve rien : la preuve inversée débranche la pièce réparée.
2. **Profondeur** : la review joue l'angle altitude (cause racine corrigée, ou symptôme pansé ?) quel que soit le palier.
3. **Périmètre** : le diff contient la cause et son test, rien « pendant qu'on y est ».
4. **Couverture** : si le bug est visible à l'écran, le test E2E qui aurait dû le voir est nommé, la raison de son silence classée, le trou fermé et la famille rejouée verte avant la PR (étapes 1 bis et 6 bis).

## Format d'invocation

```
$fix-bug <cible> [--mode=auto|semi]
```

`<cible>` : un ticket, une issue, une entrée de backlog de type bug, ou la description d'un bug. Modes : ceux de `$dev-express`.

## Ce que ce skill partage avec `$dev-express` (source unique, rien recopié ici)

- **Éligibilité** : `dev-express/SKILL.md` § Éligibilité, et rien d'autre (la liste des signaux lourds n'est pas recopiée ici : deux copies finissent par diverger). Un bug non éligible va à `$call-tech-lead`, qui impose déjà `$investigate-bug` en Phase 0.
- **Étape 0** (intake : dossier de run, branche `{{GIT_PREFIX_FIX}}<slug>`, TRANSCRIPT), **étape 3** (dev en session : TDD, commits FR, `$verify`), **étape 4** (`$ship-pr`, tests du périmètre), **étape 5** (restitution).
- `$dev-express` étape 1 renvoie ici dès que la cible est un bug. Le TRANSCRIPT est celui de `$dev-express` : sa ligne `Investigation (bug) :` porte la cause racine, `Preuve inversée (fix-bug) :` la ligne ok (test, base), `Tests E2E (fix-bug) :` le verdict de l'audit et le rejeu final.

## Étapes propres au bug

### 1. Cause racine d'abord, jamais de patch avant le rapport

`Skill(skill="investigate-bug")`, rapport dans `<run>/01-investigation.md` : faits, hypothèses, cause racine, match avec les pièges connus (`docs/GUIDE-LLM.md` §12), options A (minimal) et B (robuste), test de non-régression proposé. **Option B par défaut** ; A se justifie dans la note de cadrage, jamais en silence.

**Bug évident** (la cause tient en une ligne, visible dans le code, aucune hypothèse concurrente) : pas d'investigation ; la note de cadrage porte trois lignes (fait observé, cause, `fichier:ligne`) et la preuve inversée de l'étape 4 reste obligatoire, c'est elle qui valide la cause. Au moindre doute, investigation complète. Cause inédite (aucun piège §12 ne matche) → le body de PR propose le piège en une ligne, à trancher en rétro.

### 1 bis. Audit des tests E2E, avant tout correctif

**Pourquoi** : la QA manuelle et la production trouvent des bugs alors que la suite E2E est verte. Chaque bug dit quel test aurait dû le voir ; comprendre pourquoi il était vert est aussi utile que le fix.

Rapport : `<run>/e2e-rapport.md`, copié du gabarit `.agents/skills/fix-bug/e2e-rapport.md` (rubriques, tableau et catégories fixes), rubrique « Avant le correctif » remplie ici.

1. **Identifier** les E2E du parcours du bug, depuis ce que le ticket décrit (écran, action, texte vu) : `rg -l` dans `{{DIR_TESTS_E2E}}` sur la route de la page, la route API appelée, le texte affiché, l'identifiant de test ou la classe de l'élément fautif ; puis `rg -n "test\(|describe\("` sur les fichiers trouvés pour nommer les tests. Les mots cherchés vont dans le rapport (une recherche vide doit être rejouable). Aucun test trouvé = catégorie `trou`, jamais une case vide.
2. **Les lire, sans run** : pour chaque test, ce qu'il joue (route, rôle, données, viewport), ce qui le simule (interception réseau, fixture qui contourne l'appel), ce qui le désactive (`skip`, `fixme`, liste d'exclusion) et ce qu'il vérifie à l'écran, face à ce que le ticket décrit. La ligne citée (`fichier:ligne`) est la preuve du classement. **Un run seulement si la lecture ne tranche pas** (l'assertion semble porter sur le texte faussé et pourtant le test passe ; données construites à l'exécution) : la raison va dans le rapport, ligne **Run**, et ce run ne s'ajoute pas : il part avec le rouge de l'E2E de la note (étape 3), un seul run sans le correctif. Run impossible → « non joué — <raison> », jamais un vert supposé.
3. **Classer** chaque test selon la catégorie du gabarit (`trou`, `assertion muette`, `données`, `simulé`, `désactivé`, `déjà rouge`, `environnement`, `hors E2E`), preuve à l'appui. Un test `déjà rouge` se dit en tête du verdict : le bug était vu et ignoré, c'est une information pour l'utilisateur avant d'être un correctif.
4. **Verdict** en une phrase : ce qui manquait à nos tests. Il nourrit la note de cadrage (étape 2).

**Sans E2E** (projet ou périmètre sans suite E2E : outil interne, script) : l'audit porte sur les tests les plus hauts qui existent pour ce parcours (composant, route), et le rapport commence par « pas d'E2E dans ce périmètre ». **Bug invisible à l'écran** (calcul, API, tâche de fond) : une ligne `hors E2E` et la raison.

### 2. Note de cadrage = le rapport, plus le test de reproduction

`00-cadrage.md` (gabarit de `$dev-express` étape 2). « Cas de test » commence par **le** test de reproduction proposé par l'investigation, au niveau le plus bas qui reproduit (unitaire, puis intégration, puis E2E), puis les cas adjacents que l'option B couvre. « Fichiers pressentis » = ceux de la cause racine, pas ceux du symptôme.

Checkpoint `semi` : la note s'affiche en entier dans le chat (dix lignes au plus) ; la cause, un exemple vécu et les options A / B aussi, le rapport `01-investigation.md` en lien, avant « la note te va ? ».

**Et l'E2E qui aurait dû le voir** : dès que le bug est visible à l'écran et que l'audit a classé un test autrement que `hors E2E` ou `environnement`, la note liste aussi l'E2E à corriger (assertion renforcée, données qui montrent le bug, skip retiré, simulation retirée) ou à ajouter (`trou`), avec ce qu'il vérifiera à l'écran (le texte attendu, pas « l'élément est visible »). Le test bas prouve la cause ; l'E2E ferme le trou de la suite. Les deux sont exigés, aucun ne remplace l'autre.

### 3. RED de reproduction, puis le fix

Le test de reproduction est écrit et lancé **avant** le fix. Son message d'échec doit être le bug (la valeur fausse, le crash), pas un import cassé ni une faute de frappe : ce message est recopié tel quel dans le body du commit du fix (preuve du RED). Puis le fix minimal pour vert, refactor, `$verify`.

**L'E2E de la note** suit la même règle : écrit ou corrigé avant le fix, joué (`{{CMD_E2E_LAST_FAILED}}` ou la commande ciblée du projet sur ses fichiers), **rouge** sur le bug (son message d'échec montre le texte faux à l'écran, pas un sélecteur introuvable ni un timeout ; sélecteur vérifié contre le DOM réel), identifiant du run rouge dans la colonne « Sans le correctif » du rapport. Un E2E vert avant le fix ne reproduit pas le bug : le retravailler. `fix-proof.sh` ne le rejoue pas : sa preuve à lui est le couple de runs rouge puis vert du rapport.

### 4. Preuve inversée, avant le commit du fix puis au ship

Avant de commiter (fix non commité, la base est déduite : HEAD) :

```bash
bash .codex/hooks/fix-proof.sh --test "<commande du test de reproduction>" [--cwd <sous-dossier>] -- <fichiers source du fix>
```

Le script crée un **worktree temporaire**, y remet la version d'avant des fichiers du fix (l'arbre de travail réel n'est jamais touché), lance la commande de test (doit échouer), remet le fix, relance (doit passer), puis écrit `.codex/reviews/fix-proof-<sha7 de HEAD>.md`. Contrat complet en tête du script. Fichiers à passer : les fichiers **source** du fix, jamais le fichier de test (il reste en place pour les deux runs) ; un fichier neuf dont le test dépend se commite avant de jouer la preuve.

- La ligne `preuve inversée ok : …` va dans le body du commit du fix, sous la trace `$verify`. Le dernier message du test sans le fix est relu par le dev et cité dans le body : ce doit être le bug (la valeur fausse), pas « Cannot find module ».
- Sur une branche de fix, `review-gate.sh` peut exiger une preuve couvrant le diff applicatif ; un fichier du fix retouché après la preuve la périme : rejouer (`--base <commit du fix>~1` si d'autres commits ont suivi).
- `STOP-TEST-VERT-SANS-FIX` : le test passe sans le fix, il ne reproduit pas le bug → retour à l'étape 3, jamais de commit.
- `STOP-TEST-ROUGE-AVEC-FIX` : le fix ne corrige pas ce que le test mesure → retour à l'étape 3.
- **Avant la première passe de review** : la preuve doit être valable pour HEAD. Un correctif de review qui touche un fichier du fix ou le fichier de test → rejouer, et la nouvelle ligne remplace l'ancienne dans le body de PR.
- Limite assumée : la preuve atteste « rouge sans, vert avec », pas la pertinence du test. Un test qui dépend d'un état hors dépôt (base de données, réseau) mesure l'environnement autant que le fix : le dire dans le body.

### 5. Review : le palier calculé, plus l'angle altitude

`$ship-pr` joue `$review-pr` au palier calculé par `review-level.sh`, une fois la preuve inversée valable pour HEAD et le bilan E2E (6 bis) vert : rien ne doit plus ajouter de commit après la première passe. Sous `$fix-bug`, l'orchestrateur **ajoute l'angle altitude** (`review-pr/angles.md`) quel que soit le palier, avec dans son mandat la cause racine annoncée (`01-investigation.md`, ou les trois lignes de la note pour un bug évident) et le journal de la preuve : la cause corrigée est-elle celle annoncée, et à la bonne profondeur ? Un niveau supérieur au palier est toujours permis, jamais inférieur ; la ligne Coût du rapport le dit (« + angle altitude ($fix-bug) »). Le rapport porte une ligne d'en-tête `**Angle altitude** : joué ($fix-bug, preuve : fix-proof-<sha7>.md)`.

### 6. Périmètre

`$verify` item 6 : `git diff --stat` = les fichiers de la cause + le test (+ les E2E ajoutés ou corrigés que la note de cadrage liste). Tout autre fichier est un « pendant qu'on y est » : commit séparé hors de cette PR, ou justification écrite dans la note. Un fix qui touche cinq fichiers pour un `if` a un problème de cause.

### 6 bis. Bilan E2E, avant `$ship-pr`

Sur le dernier commit (celui qui part) : **un seul run**, qui rejoue tous les E2E de l'audit (étape 1 bis), tous ceux ajoutés ou corrigés **et** ce que demande le niveau E2E de `$ship-pr`, calculé juste avant par `.codex/hooks/e2e-level.sh` (source unique, jamais redéfini ici) : ce run est celui de `$ship-pr`, qui le reprend sans le rejouer. Si le niveau est `smoke`, le motif de filtre du smoke est complété par les specs du bilan (union, pas intersection), et le rapport cite pour chaque spec du bilan son nombre de tests joués (0 = filtre raté, rejouer).

Attendu : tout vert, **zéro skip** (un test skippé se corrige, il ne se laisse pas). Un rouge → `$qa-flow` (boucle `--last-failed`), jamais la PR. Puis la rubrique « Après le correctif » du rapport : tests ajoutés ou corrigés (sans le correctif / avec), rejeu final (identifiant du run, sha, compte, niveau couvert). Un correctif de review qui touche un E2E ou un fichier du fix → rejouer le bilan.

Le rapport entier va dans le body de PR, encadré « Tests E2E », replié dans un `<details>` s'il dépasse dix lignes. Projet sans suite E2E : la rubrique dit « non applicable » et pourquoi.

### Budget E2E — un run, deux au plus

- **Un run** par défaut : le bilan 6 bis, qui vaut aussi pour `$ship-pr`.
- **Deux au plus** : + le rouge de l'E2E ajouté ou corrigé (étape 3), ou, sans E2E à changer, le run d'audit que la lecture n'a pas tranché.
- **Au-delà** : seulement une relance justifiée (un rouge corrigé par `$qa-flow`, un correctif de review qui touche un E2E ou un fichier du fix), sa raison dans le rapport, jamais « pour être sûr ».

### 6 ter. Test manuel local, avant `$ship-pr`

Dès que le correctif touche du code servi par l'application (règle unique : `.agents/skills/_partage/test-manuel-local.md`) : reproduire le symptôme du ticket tel que décrit, avec le rôle et les données du ticket, puis constater le comportement corrigé et relever le texte réel lu à l'écran. Se joue après le bilan E2E, sur le dernier commit ; son statut (✓ / ✗ / non joué / sans objet) va dans la ligne de statut de la PR, le TRANSCRIPT et la rubrique `Test manuel local` du message final, distincte des E2E.

## Body de PR (en plus des règles de `$dev-express`)

- La ligne de statut est celle de `$dev-express` étape 4 (`Mode : fix-bug`), complétée par `· cause racine : <une phrase> · preuve inversée : ok (<test>, base <sha7>) · angle altitude joué · tests E2E : <n> audités (<catégories>), <m> ajoutés ou corrigés, rejeu <identifiant> vert | non joué (<raison>)`. Jamais une seconde ligne.
- « À vérifier » commence par : reproduire le bug tel que le ticket le décrit → constater le comportement corrigé, avec le texte réel vu à l'écran.

## Garde-fous (en plus de ceux de `$dev-express`)

- Jamais de commit de fix sans la ligne de preuve inversée dans son body.
- Jamais un fix sans test de reproduction. Seule exception : config pure ou texte, et le body dit pourquoi.
- Jamais de patch avant la cause écrite (rapport d'investigation, ou les trois lignes d'un bug évident).
- Jamais de patch avant la rubrique « Avant le correctif » du rapport E2E (étape 1 bis), jamais de PR sans sa rubrique « Après » (étape 6 bis). Bug évident compris : l'audit ne coûte qu'une recherche et une lecture.

## Ce que le skill ne fait pas

Les bugs lourds (auth, migration, API, permissions, IA) ; le refacto du voisinage ; `$investigate-bug` seul, quand on veut la cause racine avant de décider si l'on code.

## Référence

- `$dev-express` (étapes partagées, éligibilité), `$investigate-bug`, `$review-pr` (angle altitude), `$verify`, `$ship-pr`, `$qa-flow`.
- `.codex/hooks/fix-proof.sh` (contrat en tête du script), `.codex/hooks/e2e-level.sh`.
- `e2e-rapport.md` (ce dossier) : gabarit du rapport E2E et catégories, source unique.
