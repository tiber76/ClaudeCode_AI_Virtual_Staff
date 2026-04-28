---
name: call-tech-lead
description: |
  Orchestrateur multi-agents. Tu formules un besoin en texte libre, l'orchestrateur
  convoque dynamiquement une équipe virtuelle (Full-Stack Lead, PO Métier, Designer
  UX/UI, QA, CSO, Data Engineer, AI/LLM Engineer) — les agents débattent franchement,
  le tech-lead synchronise et tranche. Deux modes : `--mode=auto` (100% autonome jusqu'à
  la PR) ou `--mode=semi` (checkpoints à US, plan, push). Produit un TRANSCRIPT.md
  détaillé de tous les échanges et décisions. Jamais de merge auto (règle §0).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
triggers:
  - tech lead
  - orchestre cette feature
  - équipe virtuelle
  - feature complète
  - lance le tech lead
---

# /call-tech-lead

## Objectif
Orchestrer une équipe virtuelle d'experts spécialisés sur {{PROJECT_NAME}} ({{PROJECT_DESCRIPTION}}) pour mener une feature de l'idée à la PR ouverte, avec débats francs et traçabilité complète.

## Format d'invocation

```
/call-tech-lead <besoin en texte libre> [--mode=auto|semi] [--depth=lean|standard|full]
```

- **Mode par défaut** : `semi` (checkpoints aux 3 jalons clés).
- Pour auto : `--mode=auto`.
- **Depth par défaut** : `standard`.
  - `lean` : routing serré, avis courts, round 2 désactivé sauf friction critique.
  - `standard` : agents ciblés, round 2 uniquement si vraie friction.
  - `full` : orchestration complète, utile pour features critiques, sécurité, data ou architecture lourde.

## L'équipe virtuelle

Agents tech dans `.claude/agents/` :

| Agent | Rôle | Convoqué quand |
|---|---|---|
| `po-metier` | PO produit | **Quasi systématique** — rédaction US |
| `full-stack-lead` | Tech Lead {{PROJECT_TYPE}} | **Systématique** — architecture |
| `qa` | QA Lead, stratégie tests | **Systématique** — mapping US↔tests exhaustif |
{{#IF HAS_DESIGN_SYSTEM}}
| `designer-uxui` | Designer produit ({{DESIGN_SYSTEM_NAME}}) | Si feature touche UI |
{{/IF}}
| `cso` | Chief Security Officer | Si feature touche auth / data sensible / permissions |
| `data-engineer` | Data & Performance | Si feature touche KPI / requêtes lourdes / modélisation |
{{#IF HAS_AI_FEATURE}}
| `ai-llm-engineer` | AI/LLM Engineer | Si feature touche LLM / prompts / parsers IA / rapports / chatbot |
{{/IF}}

{{#IF HAS_GROWTH_TEAM}}
### Équipe commerciale & marketing — consultation OPT-IN uniquement

6 agents commerciaux existent aussi (growth-lead, sales-b2b, customer-success, copywriter-brand, content-seo, marketing-analytics). **Ils ne sont JAMAIS convoqués automatiquement par `/call-tech-lead`.**

Protocole strict :
1. Si un signal commercial fort est détecté en phase 1 (feature pricing / différenciateur / refonte plan / nouveau segment), tech-lead **propose** à l'utilisateur via `AskUserQuestion` :
   > "Signal commercial détecté : `<raison>`. Veux-tu consulter l'équipe commerciale (growth-lead{{#IF IS_B2B}} + sales-b2b{{/IF}}, +~100k tokens) ? Oui / Non."
2. **Par défaut : Non**. L'utilisateur doit opt-in explicitement.
3. En **mode auto** : tech-lead **n'escalade jamais** vers l'équipe commerciale. Il documente le signal dans TRANSCRIPT : "Signal commercial détecté `<raison>`. Mode auto — pas d'escalade. À consulter manuellement via `/call-growth-lead` si besoin."
4. Pour lancer une initiative commerciale indépendante → `/call-growth-lead <besoin>`.
{{/IF}}

## Garde-fous absolus (règle §0 GUIDE-LLM)

- ❌ **JAMAIS merger la PR** : "ok pour la PR" ≠ "merge". Ordre explicite de l'utilisateur requis.
- ❌ **JAMAIS commit sur `{{GIT_PROD_BRANCH}}` ou `{{GIT_DEFAULT_BRANCH}}`** directement.
- ❌ **JAMAIS push force**, `--no-verify`, `--amend` sans demande explicite.
{{#IF HAS_MIGRATIONS}}
- ❌ **JAMAIS exécuter une migration SQL** : l'utilisateur joue lui-même en staging puis prod.
{{/IF}}
- ✅ Commit sur branche `{{GIT_PREFIX_FEATURE}}*` autorisé après tests verts.
- ✅ `gh pr create --base {{GIT_DEFAULT_BRANCH}}` autorisé automatiquement.

## Profils de coût — règle de sobriété

Le tech-lead choisit le profil le moins cher qui reste sûr. Si l'utilisateur ne précise pas `--depth`, utiliser `standard`, mais rétrograder en `lean` pour une tâche simple et demander confirmation avant de passer en `full`.

| Depth | Agents max hors PO | Round 1 | Round 2 | Usage |
|---|---:|---|---|---|
| `lean` | 2-3 | 150-220 mots / agent | Seulement si risque critique | petite feature, refacto localisé, bug déjà compris |
| `standard` | 3-4 | 250-320 mots / agent | Seulement si friction réelle | feature produit normale |
| `full` | Tous les agents pertinents | 350-450 mots / agent | Oui si frictions ou arbitrages lourds | auth, paiement, PII, data model, IA, migration, refonte majeure |

Garde-fous token :

- Ne jamais convoquer un agent "au cas où". Chaque agent doit avoir un signal explicite.
- `full-stack-lead` + `qa` forment le noyau minimal technique.
- `po-metier` est requis pour une feature utilisateur, facultatif pour refacto interne ou bug technique.
- `designer-uxui`, `cso`, `data-engineer`, `ai-llm-engineer` sont opt-in par signal.
- Le round 2 est **facultatif** : s'il n'y a pas de désaccord actionnable, écrire "Aucune friction nécessitant débat" dans `04-round2-debates.md` et passer au plan.

## Les 8 phases du flux

### Phase 0 — Intake & setup

1. Parse le besoin, `--mode` (défaut : `semi`) et `--depth` (défaut : `standard`, avec rétrogradation possible en `lean` si tâche simple).
2. Détermine un slug kebab-case à partir du besoin.
3. Crée `.claude/call-call-tech-lead-runs/<YYYYMMDD-HHMMSS>-<slug>/` (inclus dans `.gitignore`).
4. Écrit `00-input.md` avec le besoin verbatim + mode + timestamp.
5. **Vérifie la branche courante** :
   - Si `{{GIT_DEFAULT_BRANCH}}` à jour → `git checkout -b {{GIT_PREFIX_FEATURE}}<slug>`.
   - Si autre → demande confirmation avant de créer la branche.
6. Initialise `TRANSCRIPT.md` avec l'en-tête.

### Phase 1 — Routing (quels agents convoquer ?)

Tech-lead analyse le besoin et remplit la grille :

| Signal dans le besoin | Agents convoqués |
|---|---|
| Nouvelle route API / authentification / permissions / upload / paiement | + **cso** |
| Feature data / nouveau KPI / requête lourde / agrégation / modélisation DB | + **data-engineer** |
{{#IF HAS_AI_FEATURE}}
| Feature IA : LLM / prompts / parsers / rapports IA / chatbot / chained-context | + **ai-llm-engineer** (+ souvent **cso** pour scrub-pii / log tokens anormaux) |
{{/IF}}
{{#IF HAS_DESIGN_SYSTEM}}
| Nouvelle page / composant UI / refonte / design | + **designer-uxui** |
{{/IF}}
| Refacto pur sans impact utilisateur | **full-stack-lead + qa uniquement** |
| Feature complète "classique" | **full-stack-lead + qa + po-metier + spécialistes signalés** |
{{#IF HAS_AI_FEATURE}}
| Feature complète IA-first | **full-stack-lead + qa + ai-llm-engineer + cso si PII/logs + data-engineer si agrégations** |
{{/IF}}
| Bug trivial / typo / one-liner | 🛑 **refuse d'orchestrer**, propose direct édition ou `/investigate-bug` |

{{#IF HAS_AI_FEATURE}}
**Détection signals IA** : mots-clés qui convoquent `ai-llm-engineer` automatiquement — `llm`, `prompt`, `ai_insights`, `parser`, `rapport IA`, `chatbot`, `chained-context`, `scrub-pii`, `structured-output`, `tool_choice`, `validator`.
{{/IF}}

{{#IF HAS_GROWTH_TEAM}}
### Signal commercial — détection + opt-in (pas auto)

Si le besoin contient un des signaux suivants, tech-lead **détecte** mais **n'auto-convoque pas** :

| Signal commercial | Agents commerciaux suggérés (opt-in) |
|---|---|
{{#IF HAS_PRICING_TIERS}}
| Refonte pricing / packaging / plan | growth-lead{{#IF IS_B2B}} + sales-b2b{{/IF}} |
{{/IF}}
| Feature positionnée comme différenciateur majeur | growth-lead + copywriter-brand |
| Nouveau segment / ICP cible | growth-lead{{#IF IS_B2B}} + sales-b2b{{/IF}} + customer-success |
| Feature orientée activation / onboarding | customer-success |
| Refonte landing ou pricing page | growth-lead + copywriter-brand |

**Protocole obligatoire** :
- **Mode semi** : `AskUserQuestion` à l'utilisateur — "Signal commercial `<X>` détecté. Consulter `<agents>` (+~100k tokens) ? Oui / Non". Default = Non.
- **Mode auto** : jamais d'escalade. Documente dans TRANSCRIPT et continue sans eux.
{{/IF}}

Applique ensuite les plafonds `--depth` :

- `lean` : maximum 3 agents hors PO. Si plus de 3 signaux apparaissent, garder les risques bloquants dans l'ordre `cso` → `data-engineer` → `ai-llm-engineer` → `designer-uxui`, et documenter les agents exclus.
- `standard` : maximum 4 agents hors PO, sauf risque sécurité/data/IA majeur.
- `full` : pas de plafond autre que pertinence réelle.

Écrit `01-routing.md` avec justification (inclure les agents exclus et le signal commercial détecté même si pas d'escalade). Update `TRANSCRIPT.md`.

### Phase 2 — PO rédige l'US

Invoque l'agent `po-metier` via le tool `Agent` avec le besoin initial. L'agent produit une US structurée (sauvée dans `docs/us/US-<slug>.md` + copie dans `02-us.md`).

**Checkpoint `--mode=semi`** :
- Affiche l'US dans le chat.
- Pose la question : "Valide l'US ? (oui / modifier / stop)"
- Si "modifier" → `AskUserQuestion` pour collecter les ajustements, re-délègue au PO.
- Si "stop" → arrête le run proprement, sauvegarde l'état.

**Mode `--mode=auto`** : passe direct à la phase 3, loggue dans TRANSCRIPT.

### Phase 3 — Round 1 : avis indépendants (en parallèle)

Pour **chaque agent convoqué sauf PO** (déjà intervenu), tech-lead délègue en parallèle (plusieurs Agent tool calls dans le même message) :

> "Voici l'US : [contenu de 02-us.md].
>
> Donne ton avis depuis ton rôle : risques, contraintes, propositions, points à challenger chez les autres experts. **Cite des fichiers existants avec lignes exactes (`fichier.ext:L42-55`)** quand tu proposes de modifier du code existant — sans ligne exacte, c'est une hypothèse à vérifier. Format structuré (bullets). Budget : `lean` 200 mots max, `standard` 300 mots max, `full` 450 mots max."

**Spécificités par agent** :
- **`qa`** : demande explicitement le **tableau de couverture US→tests exhaustif** (toutes les sections de son mandat, y compris pièges connus du projet). Pour tout composant UI > 100 lignes, exige la question *"quelles fonctions pures extraites et testables sans DOM ?"*.
- **`data-engineer`** : mandat **élargi par défaut** — *"audit efficience globale sur le module touché (requêtes / routes / caching existants) en plus du surcoût du nouveau scope. Challenge ce qui n'est pas optimal dans le legacy ET indique ce qui est déjà optimal (à ne pas re-proposer)."* (pattern projet : évite du rework post-livraison en élargissant le périmètre au legacy existant).
{{#IF HAS_DESIGN_SYSTEM}}
- **`designer-uxui`** : si le besoin contient un sujet visuel subjectif (couleur, taille, disposition, spacing), demande *"produis 2-3 variantes descriptibles en preview DOM côte à côte (pas de code définitif), on fera trancher l'utilisateur avant la phase 6"*.
{{/IF}}
{{#IF HAS_AI_FEATURE}}
- **`ai-llm-engineer`** (si convoqué) : mandat inclut scrub-pii, structured outputs (pattern officiel vs configs décoratives), seuils de confiance, synchro validator ↔ lexique prompt, budget guard, chaînage inter-rapports.
{{/IF}}

Chaque output → `03-round1-<agent>.md`.

Update TRANSCRIPT avec extrait 3-5 lignes de chaque avis sous `### Round 1 — avis <agent>`.

### Phase 4 — Round 2 : challenges croisés facultatifs

Tech-lead lit tous les round1 + US, identifie les **points de friction** :

- **CSO dit "rate-limit 3/min"** mais **PO dit "usage massif légitime"**
- **Designer dit "modal full-screen"** mais **Full-stack dit "scroll-lock casse l'input mobile"**
- **Data dit "agrégation serveur SQL"** mais **QA dit "fonction SQL dure à mocker"**
- **CSO dit "2FA obligatoire"** mais **PO dit "friction UX inacceptable"**

Pour **chaque point de friction** identifié :

1. Délègue à l'agent A : "L'agent B dit ceci : `<avis B>`. Tu as dit cela : `<ton avis>`. Challenge ou concède : 150 mots. **Si ta réponse implique de modifier du code existant, cite les lignes exactes que tu as lues (`fichier.ext:L42-55`). Sans ligne exacte, c'est une hypothèse non vérifiée → tu dois aller lire AVANT de répondre.** Si compromis possible, propose-le."
2. Délègue à l'agent B : même prompt inversé.
3. **Vérification factuelle tech-lead** : pour toute reco round 2 qui affecte du code existant, lis toi-même le fichier cité. Si l'agent a recommandé un changement **déjà en place** (pattern connu : reco fantôme alors que la modification existait déjà avec commentaire explicite), **supprime la reco du plan final**. Pas de travail inutile.
4. Après ce round, tech-lead synthétise dans `04-round2-debates.md` sous forme :

```markdown
## Débat N — <titre>

**<agent A>** ouvre :
> <citation avis initial>

**<agent B>** répond :
> <challenge ou concession>

**<agent A>** contre-réponse :
> <...>

**✅ Décision tech-lead** : <arbitrage clair avec justification>
```

**Règle d'escalade** :
- **Mode `--mode=semi`** : si désaccord persiste après 2 rounds sur un point Critique → `AskUserQuestion` à l'utilisateur.
- **Mode `--mode=auto`** : tech-lead tranche seul, documente **explicitement** dans TRANSCRIPT : "Auto-arbitrage sans escalade : <raison>".
- **Depth `lean`** : ne lancer le round 2 que pour une friction bloquante ou un risque sécurité/data/IA. Sinon écrire une note de synthèse sans redéléguer.
- **Aucune friction** : ne pas lancer d'agents. Écrire `04-round2-debates.md` avec "Aucune friction actionnable détectée" + 3-5 lignes de justification.

**Update TRANSCRIPT** avec les débats complets sous `## ⚔️ Phase 4 — Débats`.

### Phase 5 — Plan final

Tech-lead consolide :
- US validée
- Avis round 1
- Arbitrages débats round 2
- Plan technique complet en appelant `/fullstack-lead-tech` en sous-routine (qui produit un plan structuré avec UX/UI, tests, sécu, perf)

Output → `05-plan-final.md` + copie dans `docs/plans/PLAN-<slug>.md`.

**Checkpoint `--mode=semi`** : "Valide le plan ? (oui / ajuste / stop)"

**Update TRANSCRIPT** avec synthèse décisions clés.

### Phase 6 — Implémentation

Tech-lead délègue à `full-stack-lead` (et `qa` en parallèle pour écrire les tests) avec le plan validé. L'implémentation se fait par **lots atomiques** :

{{#IF HAS_MIGRATIONS}}
1. **Lot 1 — DB & Migration SQL** : génère le fichier `{{DIR_MIGRATIONS}}<YYYYMMDD>_<slug>.sql` (**ne l'exécute pas**). Commit `feat(sql): <slug>`.
2. **Lot 2 — Tests API rouges** : `qa` écrit les tests qui doivent échouer avant l'implémentation. Commit `test(api): <slug> — red`.
3. **Lot 3 — Handler API + helpers** (`{{DIR_ROUTES_API}}` + `{{DIR_HELPERS}}`) : `full-stack-lead` implémente. Lance les tests → doivent passer. Commit `feat(api): <slug>`.
4. **Lot 4 — Tests composants rouges** : tests UI. Commit `test(ui): <slug> — red`.
{{#IF HAS_DESIGN_SYSTEM}}
5. **Lot 5 — Composants UI + styles** : `full-stack-lead` + `designer-uxui` reviewent. **Si sujet visuel subjectif détecté** (couleur, taille, spacing, disposition) : `designer-uxui` produit d'abord 2-3 variantes en preview DOM, screenshot côte à côte, l'utilisateur tranche, **puis** commit la version retenue. Pas de ping-pong commit → feedback → commit. Commit `feat(ui): <slug>`.
{{/IF}}
{{#IF !HAS_DESIGN_SYSTEM}}
5. **Lot 5 — Composants UI** : `full-stack-lead` implémente. Commit `feat(ui): <slug>`.
{{/IF}}
6. **Lot 6 — Intégration page + routing** : commit `feat(page): <slug>`.
7. **Lot 7 — Tests E2E** : `qa` écrit le spec avec tag `@smoke` ou `@critical` selon criticité. Commit `test(e2e): <slug>`.
{{/IF}}
{{#IF !HAS_MIGRATIONS}}
1. **Lot 1 — Tests API rouges** : `qa` écrit les tests qui doivent échouer avant l'implémentation. Commit `test(api): <slug> — red`.
2. **Lot 2 — Handler API + helpers** (`{{DIR_ROUTES_API}}` + `{{DIR_HELPERS}}`) : `full-stack-lead` implémente. Lance les tests → doivent passer. Commit `feat(api): <slug>`.
3. **Lot 3 — Tests composants rouges** : tests UI. Commit `test(ui): <slug> — red`.
{{#IF HAS_DESIGN_SYSTEM}}
4. **Lot 4 — Composants UI + styles** : `full-stack-lead` + `designer-uxui` reviewent. **Si sujet visuel subjectif détecté** : `designer-uxui` produit d'abord 2-3 variantes en preview DOM, l'utilisateur tranche, puis commit la version retenue. Commit `feat(ui): <slug>`.
{{/IF}}
{{#IF !HAS_DESIGN_SYSTEM}}
4. **Lot 4 — Composants UI** : `full-stack-lead` implémente. Commit `feat(ui): <slug>`.
{{/IF}}
5. **Lot 5 — Intégration page + routing** : commit `feat(page): <slug>`.
6. **Lot 6 — Tests E2E** : `qa` écrit le spec avec tag `@smoke` ou `@critical` selon criticité. Commit `test(e2e): <slug>`.
{{/IF}}

Log temps réel dans `06-implementation.log`. Update TRANSCRIPT après chaque lot : "Lot N : <titre> — X fichiers, Y lignes, tests Z/Y".

**Pas de push** à cette phase, tout reste local.

### Phase 7 — Review & QA automatiques

Tech-lead exécute séquentiellement :

1. **`/review-pr`** (skill existant) → rapport 🔴/🟠/🟢. Écrit dans `07-review.md`.
   - Si 🔴 bloquant → retour phase 6 pour correction (max 3 itérations).
   - Si 🟠 non-bloquant → documente mais continue.
2. **`cso` passe finale** : relit le diff, valide que les bloquants sécu du round 1 ont été traités. Peut bloquer ici si trou de sécu non mitigé.
3. **`/qa-flow`** (skill existant) :
   - `{{CMD_UNIT_TEST}}`
   - `{{CMD_INT_TEST}}`
   - `{{CMD_E2E_FULL}}`
   - Si échec : `{{CMD_E2E_LAST_FAILED}}` en boucle jusqu'au vert (règle §4).
   - Écrit dans `08-qa.md`.

**Update TRANSCRIPT** avec statut final de chaque check.

### Phase 8 — Ship

**Checkpoint `--mode=semi`** : "Prêt à push + PR ? (oui / stop)"

Tech-lead invoque `/ship-pr` qui :
- Valide branche `{{GIT_PREFIX_FEATURE}}*`.
- Push `git push -u origin {{GIT_PREFIX_FEATURE}}<slug>`.
- Crée PR : `gh pr create --base {{GIT_DEFAULT_BRANCH}} --title "..." --body "..."` (body inclut lien vers TRANSCRIPT.md).
- **Ne merge pas** (règle absolue §0).

URL sauvée dans `09-pr.md`. Update TRANSCRIPT avec URL finale.

**Hygiène backlog** : si la feature résout une ou plusieurs entrées de `backlog.md` (🔴 P0 / 🟠 P1 / 🟡 P2 / 🟢 P3), tech-lead le mentionne dans la description PR ("Résout backlog P1 «titre»"). Le déplacement effectif vers `✅ Fait` se fait **au merge** — pas avant. À la fin du run, tech-lead rappelle à l'utilisateur : *"Au merge de cette PR, penser à nettoyer backlog.md : entrées X, Y, Z."*

## TRANSCRIPT.md — format détaillé

**Mis à jour incrémentalement à chaque phase** (pas écrit en une fois à la fin). L'utilisateur peut faire `tail -f .claude/call-call-tech-lead-runs/<slug>/TRANSCRIPT.md` en direct.

Format complet :

```markdown
# TRANSCRIPT — <titre US> — run du <timestamp>

**Mode** : auto | semi
**Branche** : {{GIT_PREFIX_FEATURE}}<slug>
**Agents convoqués** : <liste>
**Démarrage** : <HH:MM:SS>
**Fin** : <HH:MM:SS>
**Durée totale** : XmYs
**PR finale** : <url>
**Coût tokens estimé** : ~Xk tokens (~$Y)

---

## 📥 Phase 0 — Input

> <besoin original verbatim>

**Décisions** :
- Branche créée : `{{GIT_PREFIX_FEATURE}}<slug>`
- Mode : <semi|auto>

---

## 🎯 Phase 1 — Routing (quels agents ?)

**Analyse tech-lead** :
> <raisonnement 3-5 lignes>

**Agents convoqués** : <liste>
**Agents exclus** : <liste + raison>

---

## 📝 Phase 2 — US (PO métier)

<extrait 5-10 lignes de l'US>

[Détail : `02-us.md`]

**Checkpoint semi** : ✅ validé / 🔧 Modifiée sur feedback / ⛔ Stoppé.

---

## 💬 Phase 3 — Round 1 : avis indépendants

### 🏗️ full-stack-lead dit :
> <résumé 3-5 lignes>
> **Points saillants** : …

{{#IF HAS_DESIGN_SYSTEM}}
### 🎨 designer-uxui dit :
> …
{{/IF}}

### 🔐 cso dit :
> …

### 📊 data-engineer dit :
> …

### 🧪 qa dit :
> **Couverture exhaustive proposée** : N tests (X unit, Y intégration, Z E2E — A @smoke, B @critical).
> Points d'alerte : …

{{#IF HAS_AI_FEATURE}}
### 🤖 ai-llm-engineer dit :
> …
{{/IF}}

[Détail : `03-round1-*.md`]

---

## ⚔️ Phase 4 — Débats (Round 2)

### Débat 1 : <titre>

**<agent A>** ouvre :
> "…"

**<agent B>** répond :
> "…"

**<agent A>** contre :
> "…"

**✅ Décision tech-lead** : <arbitrage clair>

### Débat 2 : …

[Détail : `04-round2-debates.md`]

---

## 📐 Phase 5 — Plan final

**Architecture** : <résumé 3-5 lignes>
**UX/UI** : <…>
**Sécu** : <…>
**Tests** : <total + répartition>
{{#IF HAS_MIGRATIONS}}
**Migration SQL** : <fichier ou "aucune">
{{/IF}}
**Effort estimé** : <…>

[Détail : `05-plan-final.md` + `docs/plans/PLAN-<slug>.md`]

**Checkpoint semi** : ✅ / 🔧 / ⛔

---

## 🛠️ Phase 6 — Implémentation

| Lot | Titre | Fichiers | Lignes | Commit |
|---|---|---|---|---|
{{#IF HAS_MIGRATIONS}}
| 1 | SQL | {{DIR_MIGRATIONS}}…sql | +42 | `feat(sql): …` |
| 2 | Tests API rouges | {{DIR_TESTS_UNIT}}…test.ext | +78 | `test(api): …` |
| 3 | Handler API | {{DIR_ROUTES_API}}…/route.ext | +117 | `feat(api): …` |
| 4 | Tests UI rouges | {{DIR_TESTS_UNIT}}…test.ext | +56 | `test(ui): …` |
| 5 | Composants UI | {{DIR_COMPONENTS}}…, {{DIR_STYLES}}…css | +234 | `feat(ui): …` |
| 6 | Intégration page | {{DIR_ROUTES_API}}…/page.ext | +45 | `feat(page): …` |
| 7 | Tests E2E | {{DIR_TESTS_E2E}}…spec.ext | +89 | `test(e2e): …` |
{{/IF}}
{{#IF !HAS_MIGRATIONS}}
| 1 | Tests API rouges | {{DIR_TESTS_UNIT}}…test.ext | +78 | `test(api): …` |
| 2 | Handler API | {{DIR_ROUTES_API}}…/route.ext | +117 | `feat(api): …` |
| 3 | Tests UI rouges | {{DIR_TESTS_UNIT}}…test.ext | +56 | `test(ui): …` |
| 4 | Composants UI | {{DIR_COMPONENTS}}…, {{DIR_STYLES}}…css | +234 | `feat(ui): …` |
| 5 | Intégration page | {{DIR_ROUTES_API}}…/page.ext | +45 | `feat(page): …` |
| 6 | Tests E2E | {{DIR_TESTS_E2E}}…spec.ext | +89 | `test(e2e): …` |
{{/IF}}

**Total** : N commits, X lignes ajoutées, Y tests écrits.

[Log complet : `06-implementation.log`]

---

## ✅ Phase 7 — Review & QA

- **`/review-pr`** : 🔴 X / 🟠 Y / 🟢 Z
- **`cso` passe finale** : ✅ OK / ⛔ bloqué (raison)
- **Tests unit + API** : ✅ / ❌ (détails)
- **Tests intégration** : ✅
- **Tests E2E smoke** : ✅ (~30s)
- **Tests E2E critical** : ✅ (~3min)
- **Tests E2E full** : ✅ (~6min)

[Détails : `07-review.md`, `08-qa.md`]

---

## 🚀 Phase 8 — PR ouverte

**URL** : <pr_url>
**Base** : {{GIT_DEFAULT_BRANCH}}
**Mergée** : ❌ NON (règle §0)

---

## 📊 Synthèse

- **Durée run** : XmYs
- **Tokens** : ~Xk (~$Y avec prompt caching)
- **Escalades utilisateur** : N
- **Auto-arbitrages tech-lead** : M
- **Itérations correction (phase 6→7)** : K

## 🎯 Prochaines étapes suggérées

{{#IF HAS_MIGRATIONS}}
- [ ] Jouer la migration SQL en staging : `<fichier>`
{{/IF}}
- [ ] Smoke test manuel sur la PR
- [ ] Si OK → dire "merge la PR" pour lancer le merge
- [ ] Après merge : `/retro` pour capitaliser
```

## Refus d'orchestrer — quand le skill s'arrête tôt

Le skill refuse de convoquer l'équipe et propose une alternative si le besoin est :

- **Typo / correction cosmétique** → "Utilise directement `Edit` sur le fichier, l'équipe est surqualifiée."
- **Bug existant** → "Utilise plutôt `/investigate-bug` pour trouver la cause racine, puis on orchestrera si besoin de refacto."
- **Question de doc / explication** → "Pas besoin de coder, je peux expliquer."
- **Refacto interne simple** → "Utilise `/fullstack-lead-tech` + implémentation directe, pas besoin d'équipe."

Garde-fou de sur-qualité.

## Intégration avec les skills existants

Le skill `/call-tech-lead` **appelle** les skills existants comme sous-routines :

| Skill | Utilisé en phase |
|---|---|
| `/redige-us` | Phase 2 (via agent `po-metier`) |
| `/fullstack-lead-tech` | Phase 5 (synthèse plan) |
| `/review-pr` | Phase 7 |
| `/qa-flow` | Phase 7 |
| `/ship-pr` | Phase 8 |
| `/security-audit` | Phase 7 (via agent `cso` en passe finale) |
| `/investigate-bug` | Non utilisé (hors scope : bugs traités séparément) |
| `/retro` | Suggéré dans la synthèse finale, invoqué manuellement après merge |

{{#IF HAS_GROWTH_TEAM}}
### Skills commerciaux/marketing — jamais invoqués auto

`/call-growth-lead`, `/redige-brief`, `/ship-landing`, `/audit-funnel`, `/brief-demo`, `/retro-campagne` sont des **skills peer**, pas des sous-routines. Tech-lead ne les appelle jamais automatiquement. Si un signal commercial émerge, escalade opt-in uniquement (voir section Routing).
{{/IF}}

## Répartition modèles (Claude)

Pour préserver le budget du modèle premium, seuls les agents dont le raisonnement est **vraiment complexe** utilisent Opus :

| Agent | Modèle | Raison |
|---|---|---|
| `full-stack-lead` | **Opus** | Raisonnement architectural complexe, choix de patterns |
| `cso` | **Opus** | Threat modeling + STRIDE = raisonnement multi-facteurs |
| `po-metier` | Sonnet | Rédaction US structurée, pattern matching domaine |
{{#IF HAS_DESIGN_SYSTEM}}
| `designer-uxui` | Sonnet | Application du design system, rédaction copy |
{{/IF}}
| `data-engineer` | Sonnet | Requêtes SQL et index — Sonnet excellent sur ce domaine |
| `qa` | Sonnet | Exécution tests, cartographie US→tests |
{{#IF HAS_AI_FEATURE}}
| `ai-llm-engineer` | Sonnet | Prompts / parsers / validators IA — domaine bien cadré (pattern-matching) |
{{/IF}}

## 💰 Coût tokens — transparence obligatoire

**Référence détaillée** : `docs/COUTS-LLM.md`.

### Annonce au lancement (phase 0)

Le skill **doit afficher** avant de commencer :

```
💰 Estimation coût — /call-tech-lead
────────────────────────────────
Scope détecté : <routing phase 1 preview>
Agents : <liste> (<N> agents)
Mode : <semi|auto>
Depth : <lean|standard|full>
Tokens estimés : <X-Yk> (range selon complexité)
Équivalent API : ~$<Z> (avec prompt caching)
Budget plan : <impact estimé selon fournisseur>
Optimisations possibles : <pointeurs si applicable>
────────────────────────────────
Continuer ? (y/n) — en mode semi uniquement
```

En **mode auto** : affiche l'estimation mais continue sans attendre.

### Répartition par phase (feature standard)

| Phase | Tokens | % total |
|---|---|---|
| 0-1 Intake & routing | 15-30k | 3% |
| 2 PO rédige US | 30-70k | 8% |
| 3 Round 1 (3-4 agents) | 120-280k | 35% |
| 4 Round 2 facultatif | 0-120k | 0-15% |
| 5 Plan final | 40-100k | 12% |
| 6 Implémentation | 120-350k | 30% |
| 7 Review + QA | 40-130k | 10% |
| 8 Ship | 15-30k | 3% |
| **Total brut** | **350-900k** | — |
| **Profil `lean`** | **180-450k** | — |
| **Profil `full`** | **600k-1.4M** | — |

### Top coût par agent (ordre décroissant)

1. `full-stack-lead` (Opus) — ~35%
2. `qa` (Sonnet) — ~20%
3. `cso` (Opus, si convoqué) — ~15%
4. `po-metier` (Sonnet) — ~10%
5. Autres agents Sonnet — ~10% combiné
6. Orchestrateur — ~10%

### Récap en footer TRANSCRIPT

À la fin du run, ajouter dans TRANSCRIPT.md :

```markdown
## 📊 Synthèse coût

- Tokens totaux : ~Xk (input: A, output: B, cache read: C, cache write: D)
- Équivalent API : ~$Y.YY
- Répartition par agent :
  - full-stack-lead (Opus) : ~Xk (~$Y)
  - qa (Sonnet) : ~Xk (~$Y)
  - ...
- Durée totale : <MmSs>
- Budget plan : <impact estimé selon fournisseur>
```

### Optimisations disponibles

Voir `docs/COUTS-LLM.md` pour les 10 optimisations SANS baisse de qualité. Les principales applicables à `/call-tech-lead` :

1. **Utiliser `--depth=lean`** quand le risque est faible (-40-70%)
2. **Ne pas lancer le round 2** sans friction actionnable (-15-35%)
3. **Fournir contexte précis** en input (-20-40%)
4. **Scope agents** explicite ("skip cso, pas de signal sécu") (-15-30%)
5. **Référencer US/plan existants** (`/call-tech-lead "implémente PLAN-X.md"`) (-30%)

**Budget** : dépend du fournisseur et du plan. Toujours tracer `depth`, agents invoqués et round 2 lancé/non lancé dans `TRANSCRIPT.md`.

**Quand le jeu en vaut la chandelle** :
- ✅ Feature complexe (> 1h conception seul)
- ✅ Feature qui touche sécu + data + UI (les experts apportent de la valeur)
- ✅ Tu es absent / multi-tâche → mode auto libère ton temps
- ❌ Bug trivial, typo, refacto mineur → skill refuse d'orchestrer (garde-fou)

## Résumé final utilisateur — OBLIGATOIRE à la fin de chaque run

Après avoir fini (PR ouverte ou toutes les PR livrées), **en plus du TRANSCRIPT technique**, produit **toujours** un **résumé en français compréhensible** destiné à l'utilisateur. Objectif : qu'il comprenne ce qui a été fait **sans avoir à lire le code ni le TRANSCRIPT**.

### Format attendu

1. **Contexte** en 1-2 phrases — ce qu'il a demandé, rappelé avec ses mots à lui.
2. **Ce qui a été trouvé / identifié** — bugs, gaps, points à corriger (éviter le jargon tech, dire l'impact utilisateur).
3. **Tableau des PRs livrées** : numéro, URL, et **ce que ça fait pour l'utilisateur** (pas le détail technique).
4. **Tableau des changements visibles** (ex : avant/après d'un flux, nouvelles sections, features exposées…).
5. **Ce qui n'a pas été fait** et pourquoi (backlog reporté, scope volontairement limité).
6. **Décisions prises en autonomie** quand le mode auto a tranché seul.
7. **Coût** : tokens approximatifs, équivalent API si disponible, impact budget selon fournisseur.

### Règles de rédaction

- ❌ Pas de jargon tech non expliqué (pas de noms de fonctions / props internes sans paraphrase accessible).
- ❌ Pas de copier-coller du TRANSCRIPT.
- ✅ Parler en impact utilisateur (« telle page promettait X qui n'existait plus, nouveaux users en confusion → corrigé »).
- ✅ Tableaux Markdown pour les comparatifs.
- ✅ Liens cliquables vers les PRs GitHub.
- ✅ Ton direct, factuel, sans superlatifs (« révolutionnaire », « game-changer » bannis — cf. copywriter-brand).

### Quand le produire

- **Mode semi** : à la fin de la Phase 8 (PR ouverte) ou après merge si instruction explicite.
- **Mode auto** : à la fin de la dernière PR du plan (après merges) OU à la fin du run si pas de merge demandé.
- **Run multi-PR** : un seul résumé final couvrant toutes les PRs, pas un par PR.

### Placement dans la réponse finale

Le résumé arrive **avant** toute autre proposition (retro, next steps). C'est la première chose que l'utilisateur doit voir quand il revient d'absence.

## Anti-patterns de l'orchestrateur

- ❌ Orchestrer une feature triviale (gaspille tokens).
- ❌ Sauter Phase 3 round 1 sur un sujet ambigu (les avis indépendants sont la base de la valeur).
- ❌ Lancer Phase 4 sans friction actionnable — le round 2 est facultatif.
- ❌ Supprimer un débat critique quand sécurité, data, IA ou architecture divergent vraiment.
- ❌ Commit sur `{{GIT_DEFAULT_BRANCH}}` / `{{GIT_PROD_BRANCH}}` (ne jamais).
- ❌ Merger la PR automatiquement (règle §0).
{{#IF HAS_MIGRATIONS}}
- ❌ Exécuter la migration SQL (l'utilisateur la joue).
{{/IF}}
- ❌ Cacher un auto-arbitrage à l'utilisateur en mode auto — tout arbitrage doit être traçable dans TRANSCRIPT.
- ❌ Continuer après qu'un agent (notamment `cso`) a posé un 🔴 bloquant non mitigé.
- ❌ **Oublier le résumé final en français** — TRANSCRIPT seul ne suffit pas, l'utilisateur doit pouvoir comprendre sans ouvrir le fichier.

## Référence

- Agents : `.claude/agents/full-stack-lead.md`, `po-metier.md`{{#IF HAS_DESIGN_SYSTEM}}, `designer-uxui.md`{{/IF}}, `qa.md`, `cso.md`, `data-engineer.md`{{#IF HAS_AI_FEATURE}}, `ai-llm-engineer.md`{{/IF}}
- Skills utilisés : `.claude/skills/{redige-us, lead-tech, review-pr, qa-flow, ship-pr, security-audit}/SKILL.md`
- `docs/GUIDE-LLM.md` : source de vérité projet
- Mémoire projet : PR toujours `--base {{GIT_DEFAULT_BRANCH}}`{{#IF HAS_MIGRATIONS}}, l'utilisateur joue les migrations SQL lui-même{{/IF}}
