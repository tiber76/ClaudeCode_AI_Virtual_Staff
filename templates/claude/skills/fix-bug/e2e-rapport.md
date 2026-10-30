# Gabarit — rapport des tests E2E d'un bug

Copié tel quel dans `<run>/e2e-rapport.md` à l'étape 1 bis de `/fix-bug`, complété à l'étape 6 bis.
Langage de restitution (`.claude/skills/_partage/fil-de-progression.md` § Restitution) : le texte vu à l'écran, pas le nom des fonctions.

```markdown
# Tests E2E — <titre du bug> (<ticket | issue | entrée de backlog>)

## Avant le correctif

**Le bug, tel que le ticket le décrit** : <écran, action, texte réel vu>

**Tests E2E qui passent par ce parcours** (recherche : <mots cherchés>)

| Test (fichier › titre) | Résultat | Pourquoi il n'a pas vu le bug |
|---|---|---|
| `<dossier E2E>/<fichier>` › <titre> | lu / rouge au nightly / vert / rouge / skippé / non joué | <catégorie> — <preuve : ligne citée> |

Aucun test trouvé → une ligne « aucun », catégorie `trou`.

**Run** : aucun, audit par lecture | `<identifiant>` (<n> passés, <n> échoués, <n> skippés) — <pourquoi la lecture ne tranchait pas> | non joué — <raison>

**Verdict** : <une phrase : ce qui manquait à nos tests>

## Après le correctif

**Tests ajoutés ou corrigés**

| Test (fichier › titre) | Ce qu'il vérifie maintenant | Sans le correctif | Avec le correctif |
|---|---|---|---|
| `<dossier E2E>/<fichier>` › <titre> | <le texte ou l'état attendu à l'écran> | rouge (`<identifiant>`) | vert (`<identifiant>`) |

E2E sans objet → une ligne « aucun » et la raison (bug invisible à l'écran, périmètre sans E2E…).

**Rejeu final** : `<identifiant>` sur `<sha7>` — un seul run : tous les tests de l'audit, les nouveaux et le niveau
`e2e-level.sh` (<aucun | specs | smoke>) : <n> passés, 0 échoué, 0 skippé — par spec du bilan : `<nom>` <n> tests
joués (jamais 0) | non joué — <raison>

**Runs E2E de ce correctif** : <1 | 2> (<lesquels>) ; au-delà : <la relance et sa raison>
```

## Catégories — « pourquoi il n'a pas vu le bug »

Une seule par ligne, la plus précise ; la preuve est la ligne du test citée.

| Catégorie | Le test… |
|---|---|
| `trou` | n'existe pas : aucun E2E ne passe par ce parcours |
| `assertion muette` | passe par le parcours mais ne vérifie pas ce qui est cassé (présence au lieu du contenu, « visible » au lieu du texte, compte au lieu de la valeur) |
| `données` | joue avec un état qui masque le bug : autre rôle, autre plan, liste vide, une seule valeur, viewport desktop |
| `simulé` | intercepte ou simule la partie cassée (route mockée, fixture qui contourne l'appel) |
| `désactivé` | est skippé, `fixme` ou dans la liste d'exclusion |
| `déjà rouge` | échouait déjà : le bug était vu et ignoré |
| `environnement` | ne peut pas voir le bug là où il joue (préproduction ≠ production, donnée absente, service externe) |
| `hors E2E` | le bug n'est pas visible à l'écran (calcul, API, tâche de fond) : le test bas suffit |
