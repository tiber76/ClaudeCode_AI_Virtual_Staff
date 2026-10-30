---
name: audit-memory
description: |
  Audit périodique du dossier mémoire de Claude Code pour ce projet (mensuel ou
  trimestriel) : détecte les doublons, les fichiers orphelins, les mémoires
  obsolètes, les candidats à consolidation, et mesure le budget de taille de
  MEMORY.md. Produit un rapport structuré dans `docs/audits/AUDIT-MEMORY-<date>.md`
  avec des actions proposées par batch validable. Aucune action destructive sans
  validation de l'utilisateur. Invoquer mensuellement, ou après un pic de
  croissance de la mémoire (plus de 5 nouvelles entrées en 1 mois).
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - AskUserQuestion
triggers:
  - audit-memory
  - audit mémoire
  - cleanup mémoire
  - mémoire orpheline
  - check mémoire
---

# /audit-memory

Plan de route, lignes d'étape et blocs « À TOI » : `.claude/skills/_partage/fil-de-progression.md`.

## Objectif

Garder le dossier mémoire de Claude Code propre et à fort signal dans le temps. La mémoire est injectée à chaque session : chaque octet de `MEMORY.md` se paie à chaque message, et une mémoire périmée induit en erreur.

Dossier audité : `~/.claude/projects/<chemin-du-projet-avec-des-tirets>/memory/` (le chemin absolu du projet, `/` remplacé par `-`). Le repérer par `ls ~/.claude/projects/ | rg <nom-du-projet>` ; en cas de doute, demander.

## Quand l'utiliser

- **Cadence par défaut** : mensuelle.
- **Événementiel** : après un pic de croissance (plus de 5 nouvelles entrées en 1 mois) ; avant une rétro globale ; dès que `MEMORY.md` dépasse son budget.
- **Pas un `/retro`** : ne traite pas un événement précis, c'est un audit transverse de l'état global de la mémoire.

## Budget de taille (à mesurer à chaque audit)

La dérive se mesure en **octets**, pas en nombre d'entrées : l'engraissement sur place des lignes d'index est le canal principal.

- `MEMORY.md` ≤ 10 Ko ; ligne d'index ≤ 300 caractères.
- Une ligne d'index = nom + déclencheur (quand la lire), jamais la règle elle-même.
- Contenu inline réservé à une courte section « réflexes » (≤ 8 règles vraiment chaudes).

```bash
MEM="$HOME/.claude/projects/<dossier-projet>/memory"
wc -c "$MEM/MEMORY.md"                                   # taille
awk 'length > 300 {print FILENAME": ligne "NR" ("length" car.)"}' "$MEM/MEMORY.md"   # lignes trop longues
```

## 4 axes d'audit

### 1. Cohérence index ↔ disque

```bash
INDEXED=$(grep -oE '\]\([A-Za-z0-9_.-]+\.md\)' "$MEM/MEMORY.md" | sort -u | wc -l | tr -d ' ')
ON_DISK=$(ls "$MEM" | grep -v '^MEMORY.md$' | wc -l | tr -d ' ')
echo "Indexées: $INDEXED | Sur disque: $ON_DISK"
```

- **Sur disque > indexées** : fichiers orphelins (jamais injectés dans les sessions futures).
- **Indexées > sur disque** : liens cassés dans `MEMORY.md`.

Pour chaque écart : lire le fichier et décider (réindexer, consolider, supprimer).

### 2. Doublons avec la documentation du projet

Pour chaque entrée dont le sujet est un piège technique ou une convention de code :

```bash
rg -i "<mot-clé central>" docs/GUIDE-LLM.md docs/
```

- Match dans `docs/GUIDE-LLM.md` (§12 « Pièges connus » ou conventions) → **doublon**, supprimer la mémoire (source unique = la doc projet).
- Pas de match mais c'est un piège technique → migrer vers `docs/GUIDE-LLM.md` §12, puis supprimer la mémoire.

Routing (rappel `/retro`) : les pièges techniques vont dans la doc projet, la mémoire garde les préférences de l'utilisateur et le process.

### 3. Candidats à consolidation

Repérer les groupes thématiques d'au moins 3 entrées (git, tests, PR, agents, déploiement…) :

```bash
for theme in "PR" "merge" "test" "agent" "deploy" "css"; do
  echo "$theme: $(grep -c -i "$theme" "$MEM/MEMORY.md") entrées"
done
```

Lire les fichiers du groupe, vérifier qu'ils ne traitent pas d'angles trop différents, puis proposer **une** entrée consolidée.

### 4. Mémoires obsolètes

Pour chaque mémoire qui cite :

- un numéro de PR : `gh pr view <N> --json state,mergedAt` ; fermée non mergée ou très ancienne sans suite = périmée probable ;
- un fichier ou un dossier : `ls` ; supprimé = le contexte a peut-être disparu ;
- une dépendance ou une version : le manifeste du projet ; absente ou majorée = piège peut-être caduc ;
- une fonctionnalité : `rg` dans le code.

Mémoire potentiellement obsolète → demander à l'utilisateur : « X mentionne Y qui n'existe plus. Garder par historique ou supprimer ? »

## Workflow

### 0. Passe de dégrossissage (optionnel)

Si l'environnement fournit un skill de consolidation de mémoire natif (par exemple `consolidate-memory`), le lancer d'abord : il fusionne les doublons évidents et élague l'index, sans action destructive sans confirmation. Il ne couvre ni les doublons avec la doc projet (axe 2) ni l'obsolescence par référence externe (axe 4), qui restent à ce skill. Sauter cette passe s'il n'y a eu aucune nouvelle entrée depuis le dernier audit.

### 1. Cadrage rapide

- Taille actuelle : nombre d'entrées, octets de `MEMORY.md`, lignes hors budget.
- Date du dernier audit : `ls docs/audits/AUDIT-MEMORY-*.md`.

### 2. Lancer les 4 axes et le budget

### 3. Rapport

Écrire `docs/audits/AUDIT-MEMORY-<YYYY-MM-DD>.md` :

```markdown
# Audit mémoire — <date>

**Période couverte** : depuis <dernier audit ou début>
**Taille** : N entrées (<delta>) · MEMORY.md : X Ko (budget 10 Ko) · lignes hors budget : N

## Bilan

| Action proposée | Nb entrées |
|---|---|
| 🟢 GARDER tel quel | N |
| 🟡 CONSOLIDER | N (en X groupes) |
| 🔵 MIGRER vers la doc projet | N |
| 🔴 SUPPRIMER (orphelin / obsolète / doublon) | N |

## Détail

### 🔵 Migrations (X)
| Fichier | Sujet | Cible dans la doc | Déjà couvert ? |

### 🟡 Consolidations (X groupes)
#### Groupe : <thème>
- `<fichier1>` — <résumé>
- `<fichier2>` — <résumé>
Proposition : une entrée `<nom>.md`.

### 🔴 Suppressions (X)
| Fichier | Raison |

### ✂️ Lignes d'index à raccourcir (X)
| Ligne | Longueur | Version courte proposée |

## Validation
Batches de 10-15 entrées, validés un par un avant toute action.

## Cible après audit
Entrées : N → cible · MEMORY.md : X Ko → cible
```

Afficher le bilan et les batches dans le chat avant de demander la validation (voir `fil-de-progression.md`, « Demander une validation »).

### 4. Exécution (sur validation seulement)

- **Aucune action destructive automatique** : le rapport est un livrable en soi.
- Si l'utilisateur valide un batch : l'exécuter, puis re-mesurer le budget.
- Sinon : le rapport reste dans `docs/audits/` et le prochain audit reprend.
- Jamais de suppression de fichier mémoire sans accord explicite sur ce fichier ou son batch.

## Anti-patterns

- ❌ Supprimer sans validation par batch.
- ❌ Proposer de tout garder : pas de signal, l'audit perd son utilité.
- ❌ Ignorer les doublons avec la doc projet : c'est l'indicateur n°1.
- ❌ Sauter l'axe 4 : c'est là que se cachent les mémoires fantômes.
- ❌ Auditer seulement l'index : toujours croiser avec le contenu réel du dossier.
- ❌ Raccourcir une ligne d'index en perdant son déclencheur (quand la lire).

## Relation avec les autres skills

- `/retro` est le point d'entrée d'une leçon (après un événement) ; `/audit-memory` est le gardien dans le temps, il nettoie ce qui s'est accumulé entre deux rétros.
- Source unique des pièges techniques : `docs/GUIDE-LLM.md` §12. Source unique des préférences et du process : `MEMORY.md`.
