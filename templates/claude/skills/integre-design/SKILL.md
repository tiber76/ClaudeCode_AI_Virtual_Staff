---
name: integre-design
description: |
  Intègre une maquette validée par le designer-uxui, ou un bundle de design
  exporté par un outil de design, en code propre : markup + CSS qui réutilise les
  variables du design system ({{DESIGN_SYSTEM_NAME}}), l'échelle z-index et les
  composants partagés, sans jamais dupliquer une classe ou un token. Workflow en
  5 étapes pour éviter de tourner en rond : source canonique, inventaire exhaustif
  de l'existant, découpage avec le dev, code et contrôle visuel, commit et rapport.
  Produit du code commité et un rapport `docs/integrations/INT-<slug>.md`.
  Invoquer quand une maquette est validée et qu'il faut passer au code.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - Agent
  - AskUserQuestion
triggers:
  - intègre ce design
  - intégration du design
  - passe la maquette en code
  - bundle de design
  - intègre la refonte
---

# /integre-design

Plan de route, lignes d'étape et blocs « À TOI » : `.claude/skills/_partage/fil-de-progression.md`.

## Objectif

Transformer un design validé en code propre, intégré dans `{{DIR_STYLES}}` et `{{DIR_COMPONENTS}}` existants, **sans dupliquer** de tokens, de classes ni de composants. Livrable : commits atomiques et rapport `docs/integrations/INT-<slug>.md`.

## Quand l'utiliser

- Une maquette a été validée par le designer-uxui (via `/call-tech-lead` ou directement).
- L'utilisateur fournit un bundle de design exporté (URL ou fichier) à intégrer.
- Une refonte visuelle est tranchée et prête à passer au code.

**Ne pas utiliser pour** : concevoir un design (designer-uxui), écrire de la logique métier (full-stack-lead), débugger un rendu cassé en production (`/investigate-bug`).

## Principes

1. **Le design canonique fait foi.** Une copie locale d'une maquette (export HTML dans `docs/`) n'est pas le rendu final : la source est le bundle ou la maquette validée.
2. **Chercher avant d'écrire** : toute classe, variable ou composant à créer est d'abord cherché dans le dépôt.
3. **Tokens uniquement** : couleur, rayon, ombre, z-index passent par `var(--xxx)`, jamais en dur.
4. **Zéro duplication** : étendre le fichier de `{{DIR_STYLES}}` de la zone concernée, ne pas en créer un nouveau.
5. **Scope clair avec le dev** : markup et CSS pour l'intégrateur, logique métier pour le full-stack-lead.
6. **Contrôle visuel dans le navigateur avant chaque commit** de markup ou de CSS.
7. **Sujet subjectif (couleur exacte, espacement) = 2-3 variantes côte à côte**, l'utilisateur choisit, un seul commit. Pas de ping-pong de commits.

## Invocation

```
/integre-design <bundle-url|chemin maquette|slug US> [--scope=markup|css|full]
```

`--scope=markup` : seulement la structure. `--scope=css` : seulement le style (le markup existe). `full` (défaut) : les deux.

## Les 5 étapes

### Étape 1 — Source canonique

1. **Bundle (URL ou fichier)** : le récupérer et le lire en entier, avec son README ou la conversation de design qui l'accompagne (l'intention de l'utilisateur au designer). Ne pas se contenter d'une copie locale ancienne.
2. **Chemin de maquette** : vérifier qu'il ne s'agit pas d'un export local obsolète ; en cas de doute, demander la source canonique.
3. **Slug d'US** : lire l'US (`docs/us/US-<slug>.md`) et le plan (`docs/plans/PLAN-<slug>.md`) ; y chercher la référence de la maquette.

Produire un résumé de 10-15 lignes : zones de page impactées, composants identifiés, palette utilisée, états spécifiés (vide / chargement / erreur / succès), copy exacte.

### Étape 2 — Inventaire exhaustif de l'existant

Chercher avant de créer, avec `rg` :

```bash
rg -n "\.<classe-1>|\.<classe-2>" {{DIR_STYLES}}          # classes CSS déjà définies
rg -n "export (default )?(function|const) <Composant>" {{DIR_COMPONENTS}}   # composants
rg -n "^\s*--" {{DIR_STYLES}}                              # tokens définis
```

Produire un tableau :

| Élément du design | Existe ? | Fichier:ligne | Action |
|---|---|---|---|
| `.card` | oui | `{{DIR_STYLES}}/components.css:42` | réutiliser |
| `.sidebar-section` | non | — | créer dans le fichier de la zone |
| rayon `12px` | oui via `--radius-md` | `base.css:28` | `var(--radius-md)` |
| couleur `#3b82f6` | non | — | remonter au designer-uxui |

**Un token manque** (couleur, rayon absents du design system `{{DESIGN_SYSTEM_NAME}}`) : s'arrêter et remonter au designer-uxui ou demander à l'utilisateur. Ne jamais inventer. Vérifier aussi la **valeur résolue** d'un token existant : un token qui existe peut résoudre vers autre chose que ce que son nom laisse croire.

### Étape 3 — Découpage avec le dev

Si un dev travaille en parallèle sur la même US (ou si l'intégration suit `/call-tech-lead`) :

- **Intégrateur** : markup (structure, sémantique, accessibilité), CSS (tokens, responsive, états hover / focus / actif / désactivé), copy, points d'accroche pour le comportement (attributs `data-*`), composants partagés réutilisés.
- **Full-stack-lead** : handlers et logique, appels API, état, validation, conditions de rôle.
- **Contrat** : écrire les points d'accroche attendus, par exemple `data-action="save-mode" + data-mode="<compact|expanded>" → handler côté dev`, et la classe d'état que le dev pose (`.item.active`).

Intégration lancée seule, sans dev en parallèle : sauter l'étape, tu prends tout le scope UI.

### Étape 4 — Code et contrôle visuel

Pour chaque zone :

1. **CSS** dans le fichier existant de `{{DIR_STYLES}}` : variables du design system seulement, z-index dans l'échelle définie, mobile-first, tous les états (`:hover`, `:focus-visible`, `:active`, `:disabled`).
2. **Markup** dans `{{DIR_COMPONENTS}}` (ou le template du projet), sans logique métier.
3. **Contrôle visuel obligatoire avant chaque commit** : lancer `{{CMD_DEV}}`, ouvrir la zone dans un vrai navigateur, mesurer l'élément (largeur et hauteur non nulles : un élément « visible » à 0 px est cassé), capturer l'écran, vérifier mobile.
4. **Variantes** si le sujet est subjectif : injecter 2-3 variantes côte à côte dans le DOM, capturer, demander à l'utilisateur (A / B / C), n'implémenter que la retenue.
5. **Commits atomiques par zone** : `feat(styles): <zone>`, `feat(ui): <composant>`, `feat(ui): <composant> états hover/focus`. Jamais un méga-commit.

### Étape 5 — Rapport d'intégration

Écrire `docs/integrations/INT-<slug>.md` :

```markdown
# INT-<slug> — <titre>

**Source design** : <URL ou chemin> · **Date** : <YYYY-MM-DD> · **Scope** : markup | css | full
**US source** : `<slug>` (si applicable)

## 1. Existant réutilisé
| Élément | Fichier:ligne | Note |

## 2. Éléments créés
| Élément | Fichier:ligne | Justification |

## 3. Tokens manquants signalés
| Élément | Valeur du design | Remontée au designer-uxui |

## 4. Fichiers modifiés

## 5. Contrat avec le dev
- `data-action="..."` sur `<button.x>` → handler dev
- classe d'état posée par le dev
- props attendues

## 6. Contrôle visuel
- Navigateur : ✅ / ❌ · capture avant / après : <chemin> · dimensions mesurées : <w×h> · mobile : ✅ / ❌

## 7. Commits

## 8. Reste à faire
- [ ] handler à brancher côté dev
- [ ] E2E à écrire (qa)
```

## Quand le skill refuse

- Maquette non validée par le designer-uxui : « Lance `/call-tech-lead` d'abord pour faire trancher le design. »
- Source canonique introuvable et maquette ambiguë : demander le bundle ou la maquette de référence.
- Nouveau token nécessaire sans validation : remonter au designer-uxui, la décision est globale.
- Logique métier impliquée : « Lance `/fullstack-lead-tech` en parallèle ; je prends markup et CSS. »

## Relation avec les autres skills

| Skill | Relation |
|---|---|
| `/call-tech-lead` | invoque l'agent `integrateur` en phase de développement quand la feature touche le design |
| `/fullstack-lead-tech` | le plan indique la zone CSS et les composants, `/integre-design` les implémente |
| `/review-pr` | vérifie l'usage des tokens et l'absence de classes dupliquées |
| `/qa-flow` | valide que les E2E passent après intégration |
| `/ship-pr` | crée la PR après intégration et contrôle visuel |

## Anti-patterns

- ❌ Intégrer sans avoir lu la source canonique.
- ❌ Sauter l'inventaire : duplication silencieuse garantie.
- ❌ Créer un nouveau fichier CSS pour une zone déjà couverte.
- ❌ Committer du markup ou du CSS sans contrôle visuel mesuré.
- ❌ Inventer un token au lieu de remonter au designer-uxui.
- ❌ Écrire de la logique métier dans le markup.
- ❌ Gestionnaires d'événements inline (`onclick=`) quand le projet a un mécanisme d'actions déclaratives.
- ❌ Couleur, z-index ou rayon en dur au lieu d'un token.

## Référence

- Agent : `.claude/agents/integrateur.md`
- Tokens : `{{DIR_STYLES}}` (source de vérité du design system `{{DESIGN_SYSTEM_NAME}}`)
- Règles UX/UI et pièges : `docs/GUIDE-LLM.md` (§ UX/UI et §12 « Pièges connus »)
