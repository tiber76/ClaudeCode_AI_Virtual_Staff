# Fil de progression — ce que l'utilisateur lit dans le chat pendant un travail

Source unique. `CLAUDE.md` et chaque commande renvoient ici, ils ne recopient pas la règle. Ce fichier vise le **fil du chat** : le TRANSCRIPT, les rapports de review et les bodies de PR gardent leur format strict. Exception : la section « Restitution : le fond » vaut pour toute restitution à l'utilisateur, quel que soit le support.

**Pourquoi** : sans fil, le chat est illisible et les demandes d'action arrivent sans contexte, noyées dans un paragraphe. L'utilisateur doit savoir en un coup d'œil où on en est, ce qui reste, et quand il doit agir, avec tout ce qu'il faut pour le faire.

## Quand ça s'applique

- **Toute commande** de la table finale, dès son lancement.
- **Le chat normal dès qu'une tâche compte 3 étapes ou plus** : le plan de route est composé pour l'occasion, avec des noms d'étape en mots simples. Moins de 3 étapes, ou une question : réponse directe, sans plan.

## Les quatre pièces

### 1. Le plan de route, une fois, au départ

```
🗺️ Plan de route : 6 étapes
1 Analyse · 2 Test rouge · 3 Correctif · 4 Vérifications · 5 Relecture · 6 PR
Ce que tu auras à faire : <à priori, …> | rien de prévu
```

### 2. Une ligne par étape, au début et à la fin

```
▶ Étape 3/6 · Correctif : en cours
✓ Étape 3/6 · Correctif : <ce qui est acquis, en une phrase lisible sans le code>
```

- Compteur **N/M**, jamais de pourcentage (une relecture dure 2 ou 20 minutes : le % mentirait).
- **Entre deux lignes, silence**, sauf si quelque chose change pour l'utilisateur. Un message intermédiaire dit ce qui vient de finir, ce que ça change pour l'issue et ce qui reste, en mots (✅ « La relecture « conventions » a rendu 6 alertes à vérifier, aucune sur la sécurité ; 4 relecteurs sur 8 encore en cours. » · ❌ « Angle F rendu. Reste A, C, G, H. »). S'il ne peut rien dire de plus que « tel outil a rendu », on n'écrit rien.
- **Jamais un identifiant interne nu** (angle F, V3, M1, T2) : traduit, ou absent.
- **Chapitre** : à chaque ▶, si l'environnement expose un outil de chapitrage (table des matières de la session), l'appeler avec le nom de l'étape. Outil absent : on saute, sans le dire.

### 3. Le bloc « À TOI », dès que l'utilisateur doit agir ou décider

```
---

🟥 **À TOI** · bloque la suite

**Quoi**
<l'action ou la décision, en une phrase>

**Pourquoi**
<ce qui casse ou reste bloqué sans elle, exemple concret>

**Comment**
1. <où aller, quoi cliquer>
2. <quoi coller, quoi lancer>
3. <quoi attendre>
(ou les options A / B, une par ligne, la recommandée signalée)

**Durée** : <estimation>

**Ensuite** : réponds « <mot attendu> », je reprends à l'étape N/M

---
```

- 🟥 **bloque la suite** : rien n'avance sans réponse. 🟧 **avant le merge** : rien ne bloque maintenant, mais la PR ne doit pas être mergée sans.
- Les cinq rubriques sont obligatoires. Un « Comment » doit se suivre sans rien deviner : chemin exact, écran, commande à copier, fichier nommé. Une décision donne ses options avec leur conséquence visible (« le total affiché sur la facture passerait de 12 à 15 »), pas leur mécanisme.
- Le bloc accompagne la question posée à l'utilisateur quand il y en a une, il ne la remplace pas.
- Jamais une action demandée dans un paragraphe : si l'utilisateur doit faire quelque chose, c'est un bloc.

### 4. La fin : ✅ Terminé N/N

```
---

✅ **Terminé** · 6/6

**Ce qui change**
<avant / après vu par l'utilisateur, exemple vécu, une phrase par ligne>

**Écart**
<ce qui n'est pas exactement ce qui était demandé, et pourquoi>   — ou « **Écart** : aucun »

**À valider** : <décisions prises à la place de l'utilisateur, 2-3 max, en puces> | rien

**À toi** : <les 🟧 encore ouverts, repris en blocs complets> | rien

**Pas fait**
- <limite, test non joué et pourquoi>

**Test manuel local** : ✓ joué (<scénario, rôle, ce qui s'affiche>) | ✗ cassé (<quoi, où>) | non joué (<raison>) | sans objet (<raison>)

**Preuves** : <tests, review, typecheck en une ligne>

---
```

C'est la version en rubriques des 5 questions (section « Restitution : le fond »), bloc « à quoi ça sert » compris quand l'étape livrée le demande.

**Test manuel local** : rubrique obligatoire dès qu'un bug ou une US touche du code servi par l'application, distincte des tests automatiques de `Preuves`. Règle, statuts et « sans objet » : `_partage/test-manuel-local.md` (source unique). Un diff sans code servi écrit « sans objet (raison) », jamais l'omission.

## Restitution : le fond (besoin, plan, lot, fin de dev)

Les quatre pièces donnent la forme ; cette section dit ce qu'on y met.

### En entrée : présenter un besoin, un plan, des lots

L'utilisateur valide bien mieux avec du **concret en français** (`$call-tech-lead`, `$redige-us`, `$fullstack-lead-tech`, `$investigate-bug`, toute synthèse). Le raisonnement technique peut rester profond ; la restitution reste pédagogique et illustrée :

- **Langage simple, pas le diff** : « ce que ça fait maintenant qui n'était pas le cas avant ».
- **Exemple concret vécu** plutôt qu'abstrait (« le client ouvre une fiche, sauvegarde → "échoué" »).
- **Comparaison ou analogie mémorisable** entre avant et après, ou d'un lot à l'autre.
- **Le pourquoi (besoin métier + risque évité) avant le comment** ; le technique ensuite, à la demande.
- **Chaque lot** : d'abord une phrase « à quoi ça sert » et ce qu'il débloque, ensuite seulement la liste technique.

Objectif : l'utilisateur comprend et valide sans décoder le diff mentalement.

### Demander une validation : le contenu dans le chat

Une question de validation ne part qu'après son contenu, affiché dans le chat au-dessus d'elle. Un renvoi du type « voir `plan-final.md` » ne suffit pas : l'utilisateur ne doit pas avoir à ouvrir un fichier pour savoir ce qu'il valide.

Ce qui s'affiche, dans cet ordre :

1. **Le fond, en restitution** : ce que ça change (avant / après, exemple vécu), puis chaque lot ou tranche en une ligne « à quoi ça sert », puis ce qu'il fait, en mots. Pas de paraphrase du fichier, pas d'identifiant nu sans traduction.
2. **Le lien** vers le fichier complet, en lien markdown, pour le détail technique. Le lien vient en plus du fond, jamais à sa place.
3. **Le bloc 🟥 À TOI** : la décision, avec ses options A / B, chacune avec sa conséquence visible, la recommandée signalée.
4. **La question**, une seule, avec le mot de réponse attendu.

**Taille** : une note de cadrage tient en entier dans le chat (une dizaine de lignes). Un plan ou une US se résume en un tableau, une ligne par tranche ou lot (à quoi ça sert, ce que ça touche, taille), plus les décisions à trancher. Le détail reste dans le fichier.

**Où ça s'applique** : la demande directe, `$dev-express` et `$fix-bug` (note de cadrage, diagnostic de `$investigate-bug`), `$call-tech-lead` (l'US, le plan, la PR prête).

**Hors validation** : en mode `auto`, personne ne répond, rien à valider ; le contenu validé va dans le TRANSCRIPT. Une reprise après compaction réaffiche le plan.

### En sortie : les 5 questions de fin de dev

Dès qu'un dev est terminé (PR créée, ou travail livré sans PR), une synthèse FR qui répond aux 5 questions que l'utilisateur se pose, dans cet ordre. Jamais une paraphrase du diff, jamais la liste des fichiers en ouverture.

1. **Ce que ça change concrètement**, avec un exemple vécu : l'avant / après du point de vue utilisateur.
2. **Pourquoi ce n'est pas exactement ce qui était demandé**, si c'est le cas : écart au cadrage, cause racine trouvée en cours de route, maillon non prévu. À dire franchement : c'est ce qui coûte le plus cher à découvrir après merge.
3. **Ce que l'utilisateur doit valider** : uniquement les décisions prises à sa place (arbitrage produit, cap, formulation, gating), 2-3 au plus, pas la liste des choix techniques évidents.
4. **Ce que l'utilisateur doit faire**, hors code : migration à jouer et dans quel ordre, variable d'environnement, vérification visuelle, décision business en attente. Rien à faire = le dire explicitement.
5. **Ce qui n'a pas été fait** : limites, tests non joués et pourquoi, mesure absente, périmètre volontairement exclu. Jamais masqué derrière un « livré ✓ ».

Puis seulement les preuves, en une ligne (tests verts, review, typecheck).

**Anti-patterns** : annoncer « terminé » sans dire ce qui reste à faire côté utilisateur ; noyer un prérequis de déploiement au milieu du body de PR ; présenter comme validé ce qui n'a pas été vérifié (rendu visuel non regardé) ; lister les lots techniques avant d'avoir dit à quoi ça sert.

### Le bloc « à quoi ça sert », à chaque étape livrée

La question 1 se rate facilement : on croit expliquer alors qu'on paraphrase le correctif. Elle accompagne **chaque étape livrée** (lot, commit significatif, migration jouée, PR), sans qu'on la demande. Cinq ingrédients, tous obligatoires :

1. **Le texte réel que lit le client**, cité tel quel, en bloc. Pas « le libellé était faux » mais `> Délai de livraison estimé : 25 semaines`. Ce que l'œil voit à l'écran, pas ce que le code contient.
2. **Un exemple chiffré et nommé** : « une cliente dont la commande partait en 25 jours ». Jamais « dans certains cas ».
3. **Une analogie du quotidien**, hors informatique : un compteur gradué en km/h qui affiche des m/s. C'est ce qui rend l'explication mémorisable une semaine plus tard.
4. **Le « pourquoi il fallait toucher ça »**, pas le mécanisme : la raison d'être, pas l'implémentation.
5. **Un chiffre qui recadre l'ampleur**, dès qu'il est disponible : « un seul compte avait changé ce réglage : le défaut touchait tout le monde sauf un ». Une conséquence sans ordre de grandeur ne se hiérarchise pas.

**Zéro jargon interne.** Bannis en restitution : dénominateur, effectif, empreinte, garde-fou, sentinelle, invariant, seuil permissif, fixture. S'ils sont indispensables, les traduire à la première occurrence.

**Test avant d'envoyer** : est-ce que ça tient sans lire une ligne de code ? Si la réponse suppose de connaître un nom de fonction ou de fichier, c'est raté.

## Mise en page — aérer

Le fil se lit en diagonale : chaque rubrique doit se repérer d'un coup d'œil.

- **Titre de rubrique en gras sur sa propre ligne**, contenu en dessous. Exception : un contenu de quelques mots reste sur la ligne du titre (« **Durée** : 5 min »).
- **Une ligne vide entre deux rubriques.**
- **Une phrase par ligne**, 15 à 20 mots au plus ; au-delà, couper ou passer en puces.
- **Liste numérotée** pour des actions à faire dans l'ordre, **puces** pour le reste.
- **Séparateur `---`** avant et après un bloc « À TOI » ou « Terminé ».
- **Les lignes d'étape restent sur une ligne** (`✓ Étape 3/6 · …`) : leur force est d'être compactes.
- **Une réponse courte reste courte** : aérer ne veut pas dire allonger. Une réponse d'une phrase ou une ligne de statut ne prend ni titres ni séparateurs.

## Les cas qui cassent un compteur

- **Commandes imbriquées** (`$dev-express` → `$fix-bug` → `$ship-pr` → `$review-pr`) : **seule la commande tapée par l'utilisateur** annonce un plan et compte N/M. Les commandes appelées ne rendent qu'une progression à l'intérieur de l'étape en cours (« ▶ Étape 5/6 · Relecture : 3 relecteurs sur 5 »), sans nouveau plan.
- **Bascule** (`$call-tech-lead` → `$dev-express`, `$dev-express` → `$fix-bug`) : le plan de la voie retenue remplace le premier, annoncé une fois : « Plan révisé : … ».
- **Étape sans objet** : elle reste affichée, `✓ Étape 4/6 · E2E : sans objet (<raison>)`. On ne renumérote jamais : le « /6 » annoncé reste vrai.
- **Étape ajoutée** (requalification, correction après review) : « Plan révisé » une fois, la numérotation déjà affichée ne bouge pas.
- **Reprise dans une nouvelle session** (tranche suivante, reprise après compaction) : le plan est réannoncé en entier, étapes faites marquées ✓, pour repartir au bon N.
- **Mode auto** (personne ne lit pendant le run) : les lignes d'étape restent, aucun 🟥 (les décisions prises seules sont tracées au TRANSCRIPT), les 🟧 vont dans le ✅ final et le body de PR.

## Plans de route des commandes

Chaque commande renvoie ici. Quand ses étapes internes changent, cette table change dans le même commit.

| Commande | Plan de route affiché |
|---|---|
| `$call-tech-lead` | 1 Cadrage · 2 Besoin · 3 Avis des experts · 4 Débats · 5 Plan · 6 Développement (sous-progression « tranche k/n ») · 7 Contrôles qualité et sécurité · 8 PR |
| `$dev-express` | 1 Cadrage · 2 Développement · 3 Vérifications · 4 Relecture · 5 PR |
| `$fix-bug` | 1 Analyse · 2 Test rouge · 3 Correctif · 4 Vérifications · 5 Relecture · 6 PR |
| `$ship-pr` | 1 Contrôles · 2 Tests · 3 Commit · 4 Relecture · 5 PR |
| `$review-pr` | 1 Préparation · 2 Relecteurs · 3 Vérification des alertes · 4 Rapport |
| `$investigate-bug` | 1 Faits · 2 Hypothèses · 3 Vérification · 4 Cause racine · 5 Options et rapport |
| `$qa-flow` | 1 Périmètre · 2 Unitaires · 3 Intégration · 4 E2E · 5 Corrections · 6 Rapport |
| `$integre-design` | 1 Récupération · 2 Inventaire de l'existant · 3 Découpage · 4 Code et contrôle visuel · 5 Commit et rapport |
| `$audit-memory` | 1 Inventaire · 2 Analyse · 3 Rapport · 4 Actions validées |

Une autre commande lancée directement (audit, rétro, `$verify`…) compose son plan à partir de ses étapes, en mots simples, dès qu'elle en compte 3 ou plus.
