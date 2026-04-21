---
name: redige-us
description: |
  Transforme un besoin exprimé en texte libre en User Story structurée et exploitable.
  Pose un minimum de questions de clarification, puis produit une US au format standard
  (En tant que… je veux… afin de…) avec critères d'acceptation Gherkin, périmètre,
  impact utilisateurs et priorité. Sauvegarde dans `docs/us/US-<slug>.md`.
  Invoquer dès qu'un besoin métier est formulé et qu'on veut le formaliser avant
  d'attaquer le plan technique.
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

## Objectif
Produire une User Story claire, testable et priorisée à partir d'un besoin exprimé en texte libre. Livrable unique : un fichier `docs/us/US-<slug>.md`.

## Quand l'utiliser
- L'utilisateur décrit un besoin sans format précis ("je voudrais que…", "il faudrait pouvoir…").
- Avant d'appeler `/lead-tech` pour obtenir le plan technique.
- Avant d'ouvrir un ticket interne ou une issue GitHub.

## Principes
1. **Ne jamais inventer de détail métier.** Si un point critique manque (persona, déclencheur, critère de succès), le signaler dans "Questions ouvertes" ou demander une clarification.
2. **Max 3 questions de clarification** via `AskUserQuestion`, uniquement si vraiment bloquant. Préférer noter dans "Questions ouvertes" quand c'est un détail.
3. **Une US = un objectif atomique.** Si le besoin contient plusieurs objectifs indépendants, proposer de le découper en plusieurs US.
4. **Personae cohérents avec le projet** : rôles définis dans `{{ROLES_ENUM}}` (+ `anonyme` pour les visiteurs publics si applicable). Pas d'autres rôles inventés.

## Étapes

### 1. Lecture du besoin
Prendre l'input brut. Identifier :
- **Persona** : qui va utiliser ? (rôle projet)
- **Action** : quoi faire ?
- **Bénéfice** : pourquoi — quelle douleur résolue, quelle valeur apportée ?
- **Déclencheur** : quand / dans quel contexte ?

### 2. Clarification (optionnelle, max 3 questions)
Si un élément critique manque, poser max 3 questions via `AskUserQuestion`. Exemples :
- "Qui est concerné exactement : tous les utilisateurs, ou seulement un sous-ensemble (rôle, plan, statut) ?"
- "Le déclencheur est manuel (clic bouton) ou automatique (événement système) ?"
- "Quel critère permettrait de dire que la feature est un succès ?"

Si le besoin est déjà clair → skip cette étape.

### 3. Rédaction de l'US
Format strict :

```markdown
# US-<slug> — <titre court descriptif>

**Statut** : draft
**Priorité suggérée** : P0 | P1 | P2 — <justification en 1 ligne>
**Créée le** : <YYYY-MM-DD>

## Titre
En tant que `<persona>`, je veux `<action>` afin de `<bénéfice>`.

## Contexte / Douleur actuelle
<2-4 phrases : pourquoi ce besoin existe aujourd'hui, ce qui coince sans cette feature>

## Périmètre

### In-scope
- <item 1>
- <item 2>
- <item 3>

### Out-of-scope (explicite)
- <ce qui pourrait être confondu avec la feature mais n'en fait PAS partie>

## Critères d'acceptation

### Scénario 1 — <nom court>
**Given** <contexte initial>
**When** <action déclenchée>
**Then** <résultat observable>

### Scénario 2 — <cas limite ou erreur>
**Given** …
**When** …
**Then** …

<3 à 6 scénarios couvrant : cas nominal, cas d'erreur, cas limite, permissions/auth>

## Impact utilisateurs
{{ROLES_LIST}}

*(Pour chaque rôle ci-dessus, indiquer : impact direct / indirect / aucun.)*

## Métriques de succès
- <ex: X% des utilisateurs cibles adoptent la feature dans les 30 jours>
- <ex: réduction de X% du temps passé sur Y>

## Questions ouvertes / hypothèses
- [ ] <tout ce qui n'a pas été tranché, avec hypothèse par défaut si pertinent>

## Dépendances techniques pressenties (à confirmer par `/lead-tech`)
- <ex: nouvelle table DB, nouvelle route API, envoi email>
```

### 4. Sauvegarde
- Déterminer un slug kebab-case depuis le titre (ex: "Export CSV des ressources par équipe" → `export-csv-ressources-equipe`).
- Créer le dossier `docs/us/` s'il n'existe pas (`mkdir -p docs/us`).
- Écrire le fichier `docs/us/US-<slug>.md`.
- Afficher le chemin + contenu complet dans la réponse.

### 5. Suite suggérée
Terminer la réponse par :
> **Suite suggérée** : `/lead-tech docs/us/US-<slug>.md` pour obtenir le plan technique et UX/UI.

## Anti-patterns à éviter
- ❌ Inventer des personae ou rôles qui n'existent pas dans le projet.
- ❌ Poser plus de 3 questions de clarification en une fois.
- ❌ Écrire des critères d'acceptation vagues ("ça doit marcher", "c'est rapide").
- ❌ Mélanger plusieurs objectifs dans une seule US → proposer un découpage.
- ❌ Décider de la solution technique dans l'US (c'est le job de `/lead-tech`).

## Référence GUIDE-LLM
- Rôles projet : `{{ROLES_ENUM}}` (cf. architecture du projet)
- Ton éditorial {{UI_LANGUAGE}} obligatoire (§8)

## 💰 Coût indicatif

Tokens : ~30-80k brut · ~10-25k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.3
Détail complet et optimisations : `docs/COUTS-LLM.md`.
