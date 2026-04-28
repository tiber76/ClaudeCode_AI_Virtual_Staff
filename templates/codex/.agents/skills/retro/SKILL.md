---
name: retro
description: |
  Rétrospective post-feature ou post-bug : capture les leçons apprises, identifie
  les pièges nouveaux, propose un ajout à `docs/GUIDE-LLM.md` §12 si un piège inédit
  a été rencontré, propose une entrée en mémoire si l'apprentissage est transverse.
  Produit un résumé court : 3 points "a marché", 3 points "a coincé", 1-3 actions
  de prévention. Invoquer après merge d'une feature non-triviale ou résolution d'un
  bug complexe.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$retro` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $retro

## Objectif
Capitaliser sur l'expérience qui vient de se dérouler : ce qui a bien marché, ce qui a coincé, ce qu'on retient pour la prochaine fois. Objectif secondaire : enrichir `docs/GUIDE-LLM.md` §12 avec les nouveaux pièges rencontrés.

## Quand l'utiliser
- Après le merge d'une feature non-triviale (>1 jour de travail).
- Après résolution d'un bug complexe qui a pris du temps.
- Après un incident (rollback, régression en prod).
- Trimestriel : retro globale sur la qualité des X dernières PR.

## Principes
1. **Factuel, pas émotionnel.** Décrire ce qui s'est passé, pas "j'étais frustré".
2. **Actionable > constat.** Chaque "a coincé" doit aboutir à une action concrète ou rester explicitement "à observer".
3. **Pas de blame.** Les "erreurs" sont des apprentissages de process, pas de personne — même en équipe.
4. **Proposer, ne pas écrire direct.** Les ajouts à `docs/GUIDE-LLM.md` ou à la mémoire sont proposés en diff — validation utilisateur requise.

## Étapes

### 1. Cadrage
Demander (ou déduire du contexte conversationnel) :
- **Sujet de la retro** : quelle feature / quel bug ?
- **Période couverte** : du <date> au <date>.
- **Commits concernés** : `git log --oneline <depuis>..<jusqua>`
- **Tickets / issues** : lien si applicable.

Si l'utilisateur ne fournit rien → proposer à partir du dernier merge sur la branche par défaut :
```bash
git log {{GIT_DEFAULT_BRANCH}} --merges -5 --pretty=format:"%h %s (%ar)"
```

### 2. Exploration
Lire rapidement :
- Le diff agrégé de la période (`git log --stat`).
- Les tests ajoutés (diff de `{{DIR_TESTS_UNIT}}` / `{{DIR_TESTS_INT}}` / `{{DIR_TESTS_E2E}}`).
- Les changements à `docs/` (s'il y en a).

### 3. Collecte "a marché"
Identifier 3 choses qui ont bien fonctionné. Exemples génériques :
- Pattern réutilisé qui a fait gagner du temps.
- Découpage en petites PR qui a simplifié la review.
- Un test bien ciblé qui a attrapé un bug tôt.
- Un helper partagé (`{{DIR_HELPERS}}`) qui a évité de la duplication.

### 4. Collecte "a coincé"
Identifier 3 choses qui ont coincé. Questions déclencheuses :
- Y a-t-il eu un bug qui a surpris ? Pourquoi il n'a pas été anticipé ?
- Une étape qui a pris 2-3× plus de temps que prévu ?
- Un test qui est tombé en boucle ?
- Un conflit de merge douloureux ?
- Un piège qui n'était pas documenté ?

Pour chaque "a coincé", déterminer :
- **Cause** : la cause racine (pas le symptôme).
- **Coût** : temps perdu, effort, impact utilisateur.
- **Reproductibilité** : est-ce que ça peut arriver à la prochaine feature ?

### 5. Identifier les pièges nouveaux (→ §12 GUIDE-LLM)
Pour chaque "a coincé" :
- Est-ce un piège déjà documenté dans §12 ? Si oui → signaler que la documentation n'a pas suffi (le piège a été oublié).
- Est-ce un piège nouveau ? → Proposer son ajout à §12.

Format proposé pour §12 :
```markdown
### <Titre du piège>
- **Symptôme** : <ce qu'on observe>
- **Cause** : <pourquoi ça arrive>
- **Mitigation** : <comment l'éviter>
- **Incident de référence** : <date / commit / feature>
```

### 6. Identifier les apprentissages transverses (→ mémoire)
Si une leçon est :
- **Spécifique au projet** (règle de process, convention) → va dans `docs/GUIDE-LLM.md`.
- **Transverse** (préférence utilisateur, pattern IA, workflow Codex) → va dans `memory/` sous forme de `feedback` ou `project`.

Pour chaque apprentissage transverse identifié, proposer une mémoire au format :
```markdown
---
name: <nom>
description: <one-liner>
type: feedback | project | user | reference
---

<contenu>

**Why** : …
**How to apply** : …
```

### 7. Actions de prévention
Lister 1-3 actions concrètes, avec propriétaire et échéance (ex: "avant la prochaine PR sur ce domaine"). Exemples :
- Ajouter un test E2E pour le cas X.
- Mettre à jour §12 avec le piège Y.
- Créer un helper dans `{{DIR_HELPERS}}` pour éviter la duplication Z.

### 8. Rapport final

```markdown
# Retro — <sujet>

**Période** : <date début> → <date fin>
**Commits** : N commits, X PR mergées
**Temps estimé** : <N jours>

## Ce qui a marché
1. **<point 1>** — <1 phrase>
2. **<point 2>** — …
3. **<point 3>** — …

## Ce qui a coincé
1. **<point 1>**
   - Cause : …
   - Coût : …
   - Mitigation : …
2. …
3. …

## Pièges à documenter (nouveaux)
<si applicable, diff proposé pour GUIDE-LLM §12>

## Apprentissages transverses (mémoire)
<si applicable, mémoire proposée>

## Actions de prévention
- [ ] **<action 1>** — échéance : <quand>
- [ ] **<action 2>** — …

## Signal global
- **Qualité globale** : bonne / correcte / à améliorer
- **Vélocité** : conforme / au-dessus / en-dessous des attentes
- **Points de vigilance pour la prochaine itération** : …
```

### 9. Proposition de diff (GUIDE-LLM et mémoire)
- **Ne PAS éditer** `docs/GUIDE-LLM.md` ou un fichier mémoire directement.
- **Proposer le diff** (old/new exact) et demander validation explicite avant d'appliquer avec `Edit` ou `Write`.
- Si validé → appliquer, puis suggérer un commit séparé (`docs(guide-llm): ajout piège XXX vu dans retro YYY`).

## Anti-patterns à éviter
- Retro trop générale ("globalement ça s'est bien passé").
- "A coincé" sans cause racine.
- Actions vagues ("mieux tester à l'avenir").
- Éditer `docs/GUIDE-LLM.md` sans validation.
- Retro hebdo automatique qui devient une corvée — la retro se déclenche sur événement (merge, bug), pas sur calendrier.

## Référence GUIDE-LLM
- §11 IA Coaching & Management (ton bienveillant — s'applique aussi aux retros)
- §12 Pièges connus (destination des nouveaux pièges identifiés)

## Coût indicatif

Tokens : ~30-80k brut · ~10-25k effective (avec prompt caching 90%)
Équivalent API : ~$0.1-0.3
Détail complet et optimisations : `docs/COUTS-LLM.md`.
