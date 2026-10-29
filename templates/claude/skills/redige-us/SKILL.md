---
name: redige-us
description: |
  Transforme un besoin exprimé en texte libre en User Story structurée et exploitable.
  Pose un minimum de questions de clarification (la première est toujours le
  périmètre : quelle tranche est le MVP ?), puis produit une US au format standard
  (En tant que… je veux… afin de…) découpée en tranches priorisées : tranche 1 =
  MVP démontrable seule, chaque tranche avec taille S/M, test indépendant et
  critères d'acceptation Gherkin, plus périmètre, impact utilisateurs et priorité.
  Sauvegarde dans `docs/us/US-<slug>.md`. Invoquer dès qu'un besoin métier est
  formulé et qu'on veut le formaliser avant d'attaquer le plan technique.
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
triggers:
  - rédige une US
  - écris la user story
  - formalise ce besoin
  - transforme ce besoin en US
---

# /redige-us

Restitution à l'utilisateur (US, questions, validation) : `.claude/skills/_partage/fil-de-progression.md`, en particulier « Demander une validation ».

## Objectif
Produire une User Story claire, testable et priorisée à partir d'un besoin exprimé en texte libre. Livrable unique : un fichier `docs/us/US-<slug>.md`.

## Quand l'utiliser
- L'utilisateur décrit un besoin sans format précis (« je voudrais que… », « il faudrait pouvoir… »).
- Avant d'appeler `/fullstack-lead-tech` pour obtenir le plan technique.
- Avant d'ouvrir un ticket interne ou une issue GitHub.

## Principes
1. **Ne jamais inventer de détail métier.** Si un point critique manque (persona, déclencheur, critère de succès), le signaler dans « Questions ouvertes » ou demander une clarification.
2. **Max 3 questions de clarification** via `AskUserQuestion`, uniquement si vraiment bloquant, hors la question de périmètre (étape 2). Un détail va dans « Questions ouvertes ».
3. **Une US = un paquet de tranches priorisées ; la tranche 1 seule doit être livrable et démontrable à l'utilisateur (MVP).** Chaque tranche a une taille `S` (≤ 0,5 j) ou `M` (≤ 2 j) : `L` n'est pas une taille, c'est un signal de découpe. Les scénarios transverses (permissions, rôles) se rattachent à la tranche qu'ils protègent, jamais à une section à part. **≥ 5 tranches = une épopée, pas une US** : écrire une US chapeau de 10 lignes plus N fichiers US fille (`US-<slug>-<n>-<tranche>.md`), chacun livrable seul. Une US fille = exactement une tranche, identifiant `<slug>/Tn`, jamais de sous-tranches ; le tableau « Suivi des tranches » vit dans le chapeau.
4. **Personae cohérents avec le projet** : rôles définis dans `{{ROLES_ENUM}}` (+ `anonyme` pour les visiteurs publics si applicable). Pas d'autres rôles inventés.

## Étapes

### 1. Lecture du besoin
Prendre l'input brut et **le conserver tel quel** : il devient le champ « Demande initiale » de l'US (la reformulation ne remplace jamais l'original). Identifier :
- **Persona** : qui va utiliser ? (rôle projet)
- **Action** : quoi faire ?
- **Bénéfice** : pourquoi, quelle douleur résolue, quelle valeur apportée ?
- **Déclencheur** : quand, dans quel contexte ?

### 2. Clarification (question 0 = périmètre, puis max 3 questions)

**Question 0 : le périmètre, toujours en premier, hors quota des 3.** Lister les tranches identifiées (une ligne chacune : titre · ce qu'on peut vérifier seul · taille S/M) et faire trancher via `AskUserQuestion` : *« Voici les N tranches que je vois. Laquelle est le MVP (tranche 1) ? Lesquelles sortent du périmètre ? »* Options concrètes, recommandation en premier.

En `/call-tech-lead --mode=auto` : pas de question, le PO tranche lui-même (tranche 1 = la plus petite qui apporte une valeur seule) et le consigne dans « Questions ouvertes / hypothèses » comme décision par défaut à confirmer au checkpoint.

Ordre des clarifications suivantes : périmètre > sécurité / données personnelles > UX > technique ; au-delà de 3, hypothèse par défaut documentée. Exemples :
- « Qui est concerné exactement : tous les utilisateurs, ou seulement un sous-ensemble (rôle, plan, statut) ? »
- « Le déclencheur est manuel (clic) ou automatique (événement système) ? »
- « Quel critère permettrait de dire que la feature est un succès ? »

Besoin déjà clair → sauter les questions autres que le périmètre.

### 2 bis. Détection « alignement design » : inputs visuels obligatoires

Si le besoin contient « aligne / réplique / comme / cohérent avec / même design que » suivi d'une autre surface (page, PR, écran), c'est une US d'alignement design. **Question obligatoire** (hors quota) :

> *« Cette US est un alignement design sur `<surface>`. Quel périmètre ?*
> - *(a) **Tokens seulement** : plomberie CSS (mêmes variables, classes modifier), le markup reste identique.*
> - *(b) **Refonte structurelle du markup** : porter la structure. Effort plus important, alignement visuel garanti.*
> - *(c) **Mixte** : tokens partout + refonte structurelle sur `<éléments précis>`. »*

Inputs à exiger dans l'US : captures du rendu de la surface de référence (à fournir ou à générer), bundle ou maquette correspondante si disponible, et des critères Gherkin avec **assertions visuelles structurelles** (« Then la section tendance est rendue en `<svg>`, pas en `<div class="bar">` »), pas seulement « tokens utilisés ». Captures indisponibles : les générer, ou bloquer la rédaction tant que l'input manque. Piège connu : cadrer en « tokens seulement » une US qui demandait une refonte structurelle coûte des heures de plomberie avant que l'écart ne se voie.

### 3. Rédaction de l'US
Format strict :

```markdown
# US-<slug> — <titre court descriptif>

**Statut** : draft
**Priorité suggérée** : P0 | P1 | P2 — <justification en 1 ligne>
**Créée le** : <YYYY-MM-DD>
**Demande initiale** : « <phrase brute de l'utilisateur, verbatim> » — <qui, date>
**Identifiant** : `<slug>` — stable, repris par le plan, la branche, les commits et les titres de PR (`<slug>/Tn`)

## Titre
En tant que `<persona>`, je veux `<action>` afin de `<bénéfice>`.

## Contexte / Douleur actuelle
<2-4 phrases : pourquoi ce besoin existe aujourd'hui, ce qui coince sans cette feature>

## Périmètre

### In-scope
- <item 1>
- <item 2>

### Out-of-scope (explicite)
- <ce qui pourrait être confondu avec la feature mais n'en fait PAS partie>

## Tranches livrables (ordre = priorité ; la tranche 1 seule doit être démontrable)

### Tranche 1 · `<slug>/T1` — <titre court> (P1 — MVP) · Taille : S | M
**Pourquoi cette priorité** : <la valeur qu'elle apporte seule>
**Test indépendant** : « on peut la vérifier seule en <action>, et ça apporte <valeur> »
**Scénarios** :
- **AC-1** — <nom court> · **Given** <contexte initial> · **When** <action déclenchée> · **Then** <résultat observable>
- **AC-2** — <cas d'erreur ou limite> · **Given** … · **When** … · **Then** …

### Tranche 2 · `<slug>/T2` — <titre court> (P2) · Taille : S | M
**Pourquoi cette priorité** : …
**Test indépendant** : …
**Scénarios** :
- **AC-3** — …

<2 à 4 scénarios par tranche : nominal + erreur / limite ; les scénarios de permissions et de rôles vont dans la tranche qu'ils protègent. Numérotation AC-n continue sur toute l'US : c'est le vocabulaire commun plan ↔ brief QA ↔ commits. Le « test indépendant » devient le nom du scénario E2E de la tranche.>

## Impact utilisateurs
{{ROLES_LIST}}

*(Pour chaque rôle ci-dessus, indiquer : impact direct / indirect / aucun.)*

## Métriques de succès
- <ex: X% des utilisateurs cibles adoptent la feature dans les 30 jours>
- <ex: réduction de X% du temps passé sur Y>

## Questions ouvertes / hypothèses
- [ ] <tout ce qui n'a pas été tranché, avec hypothèse par défaut si pertinent>

## Dépendances techniques pressenties (à confirmer par `/fullstack-lead-tech`)
- <ex: nouvelle table, nouvelle route API, envoi d'e-mail>

## Suivi des tranches (le seul endroit où l'arbre demande → tranches → PR se lit en entier)

| Tranche | Lots du plan | PR | État |
|---|---|---|---|
| `<slug>/T1` — <titre> | T1.api, T1.ui, T1.e2e | — | à planifier |
| `<slug>/T2` — <titre> | — | — | à planifier |

États : à planifier · planifiée (plan écrit) · en cours (branche) · ✅ PR #n (date) · reportée (motif, date). Si l'US est une épopée, ce tableau vit dans l'US chapeau et pointe vers les US filles.
```

### 4. Sauvegarde
- Déterminer un slug kebab-case depuis le titre (ex : « Export CSV des ressources par équipe » → `export-csv-ressources-equipe`). Le slug est l'**identifiant stable de la demande** : il ne change plus une fois l'US créée (plan `PLAN-<slug>.md`, branche `{{GIT_PREFIX_FEATURE}}<slug>`, commits `… <slug> Tn …`, titres de PR `<slug>/Tn`).
- `mkdir -p docs/us`, puis écrire `docs/us/US-<slug>.md` (US filles : `docs/us/US-<slug>-<n>-<tranche>.md`).
- Afficher le chemin et le contenu dans le chat, en restitution (voir `fil-de-progression.md`) : un tableau « une ligne par tranche » plutôt que le fichier brut quand l'US est longue.

### 5. Suite suggérée
Terminer la réponse par :
> **Suite suggérée** : `/fullstack-lead-tech docs/us/US-<slug>.md` pour obtenir le plan technique et UX/UI (une PR par tranche, T1 d'abord).

Si l'US compte ≥ 5 tranches : écrire les US filles **avant** d'appeler `/fullstack-lead-tech`.

## Anti-patterns à éviter
- ❌ Inventer des personae ou rôles qui n'existent pas dans le projet.
- ❌ Poser plus de 3 questions de clarification en une fois.
- ❌ Écrire des critères d'acceptation vagues (« ça doit marcher », « c'est rapide »).
- ❌ Mélanger plusieurs objectifs dans une seule US : proposer un découpage en tranches.
- ❌ US sans tranche 1 démontrable seule, ou tranche de taille `L` (« on découpera au plan » : non, c'est ici que ça se découpe).
- ❌ Liste plate de 10+ scénarios sans tranches ni priorité : le plan ne saura pas où s'arrêter, la PR grossira.
- ❌ Scénarios transverses (permissions, rôles) parqués dans une section à part au lieu de la tranche qu'ils protègent.
- ❌ Décider de la solution technique dans l'US (c'est le job de `/fullstack-lead-tech`).

## Référence GUIDE-LLM
- Rôles projet : `{{ROLES_ENUM}}` (cf. architecture du projet)
- Ton éditorial {{UI_LANGUAGE}} obligatoire (§8)

## 💰 Coût indicatif

Tokens : ~30-80k brut · ~10-25k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.3
Détail complet et optimisations : `docs/COUTS-LLM.md`.
