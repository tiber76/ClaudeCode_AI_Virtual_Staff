---
name: call-growth-lead
description: |
  Orchestrateur multi-agents commerce & marketing. Tu formules un besoin en texte
  libre, l'orchestrateur convoque dynamiquement une équipe virtuelle (Growth Lead,
  Sales B2B, Customer Success, Copywriter & Brand, Content & SEO, Marketing Analytics)
  — les agents débattent, le growth-lead synchronise et tranche. Produit un TRANSCRIPT
  détaillé + livrables dans docs/growth/. Deux modes : --mode=auto ou --mode=semi.
  Jamais de publication/envoi sans ordre explicite.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$call-growth-lead` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $call-growth-lead

## Objectif

Orchestrer une équipe virtuelle d'experts commerciaux & marketing sur {{PROJECT_NAME}} ({{PROJECT_DESCRIPTION}}) pour mener une initiative (campagne, landing, séquence sales, audit funnel, série contenu) de l'idée aux livrables prêts à publier.

**Pas un clone du $call-tech-lead** : pas d'implémentation code, pas de PR auto. Les livrables sont des **artefacts** (briefs, copies, plans, rapports) dans `docs/growth/` que l'utilisateur publie ensuite lui-même.

## Format d'invocation

```
$call-growth-lead <besoin en texte libre> [--mode=auto|semi] [--depth=lean|standard|full]
```

- **Mode par défaut** : `semi` (checkpoints aux 3 jalons clés : brief validé / plan validé / livrables prêts).
- Mode auto : `--mode=auto`.
- **Depth par défaut** : `standard`.
  - `lean` : growth-lead + 1-2 spécialistes, pas de débat sauf contradiction majeure.
  - `standard` : spécialistes ciblés, débat uniquement si friction actionnable.
  - `full` : go-to-market complet ou refonte stratégique.

## L'équipe virtuelle

Agents dans `.codex/agents/` :

| Agent | Rôle | Convoqué quand |
|---|---|---|
| `growth-lead` | CMO/Head of Growth, orchestrateur | **Systématique** |
{{#IF IS_B2B}}
| `sales-b2b` | Sales B2B, objections, démos, outbound | Signal sales (playbook, démo, argument commercial, négo) |
{{/IF}}
| `customer-success` | CSM, onboarding, rétention, expansion | Signal CS (activation, churn, QBR, étude de cas) |
| `copywriter-brand` | Voice & tone, landings, emails, ads | Signal rédaction externe (quasi systématique) |
| `content-seo` | SEO, guides, clusters, LinkedIn organique | Signal contenu / SEO / éditorial |
| `marketing-analytics` | Funnel, cohortes, A/B, CAC/LTV | Signal mesure / instrumentation / A/B / budget |

## Garde-fous absolus

- ❌ **JAMAIS publier** un contenu (post LinkedIn, ad, newsletter, article). Les livrables restent dans `docs/growth/`.
- ❌ **JAMAIS envoyer** un email à un prospect ou client réel.
- ❌ **JAMAIS créer** un compte sur une plateforme externe (LinkedIn Ads, Google Ads, Mailchimp…) sans ordre explicite.
- ❌ **JAMAIS fabriquer** un chiffre {{PROJECT_NAME}} (clients, MRR, métriques) — placeholder `<À remplir en prod>` obligatoire.
- ❌ **JAMAIS engager** un budget. Les recommandations chiffrées sont indicatives.
- ✅ Rédaction de drafts, plans, briefs, copies dans `docs/growth/` → OK.
- ✅ Simulation d'A/B test, calcul de sample size, audit funnel conceptuel → OK.

## Profils de coût — règle de sobriété

| Depth | Agents max hors growth-lead | Round 1 | Round 2 | Usage |
|---|---:|---|---|---|
| `lean` | 1-2 | 150-220 mots / agent | Non sauf contradiction majeure | brief rapide, landing simple, séquence courte |
| `standard` | 2-3 | 250-320 mots / agent | Seulement si friction réelle | campagne normale |
| `full` | Tous les agents pertinents | 350-450 mots / agent | Oui si arbitrage stratégique | GTM nouvelle feature, pricing, repositionnement |

Ne jamais convoquer toute l'équipe pour un contenu simple. Pour une landing seule, `copywriter-brand + marketing-analytics` suffit souvent. Pour un contenu SEO, `content-seo + copywriter-brand` suffit souvent.

## Les 7 phases du flux

### Phase 0 — Intake & setup

1. Parse le besoin, `--mode` (défaut : `semi`) et `--depth` (défaut : `standard`, rétrograder en `lean` si demande simple).
2. Détermine un slug kebab-case à partir du besoin.
3. Crée `.codex/runs/call-growth-lead/<YYYYMMDD-HHMMSS>-<slug>/` (hors git).
4. Écrit `00-input.md` avec le besoin verbatim + mode + timestamp.
5. Crée le dossier livrable cible dans `docs/growth/` si besoin (ex : `docs/growth/landings/<slug>/`).
6. Initialise `TRANSCRIPT.md` avec l'en-tête.

### Phase 1 — Routing (quels agents convoquer ?)

Le `growth-lead` (agent) analyse le besoin et remplit la grille :

| Signal | Agents convoqués |
|---|---|
| Campagne acquisition (landing + ads + séquence) | growth-lead + copywriter-brand + marketing-analytics (+ content-seo si SEO) |
{{#IF IS_B2B}}
| Séquence outbound | growth-lead + sales-b2b + copywriter-brand |
{{/IF}}
| Onboarding / activation / étude de cas | growth-lead + customer-success + copywriter-brand |
| Plan éditorial / guide / série LinkedIn | growth-lead + content-seo + copywriter-brand |
{{#IF IS_B2B}}
| Audit funnel / priorisation canaux | growth-lead + marketing-analytics (+ sales-b2b si signal sales) |
{{/IF}}
{{#IF !IS_B2B}}
| Audit funnel / priorisation canaux | growth-lead + marketing-analytics |
{{/IF}}
{{#IF HAS_PRICING_TIERS}}
| Refonte pricing / packaging | growth-lead{{#IF IS_B2B}} + sales-b2b{{/IF}} + customer-success + marketing-analytics |
{{/IF}}
| Go-to-market nouvelle feature | growth-lead + copywriter-brand + marketing-analytics + spécialistes signalés |
| Question simple / brief rapide | 🛑 **refuse d'orchestrer**, propose réponse directe |

Applique ensuite les plafonds `--depth` :

- `lean` : maximum 2 agents hors growth-lead.
- `standard` : maximum 3 agents hors growth-lead.
- `full` : pas de plafond autre que pertinence réelle.

Écrit `01-routing.md` avec justification, y compris les agents exclus pour sobriété. Update TRANSCRIPT.

### Phase 2 — Brief (growth-lead rédige)

Invoque l'agent `growth-lead` (rôle) pour rédiger un brief structuré (SMART + canal + budget + KPI + deadline + livrables) dans `docs/growth/BRIEF-<slug>.md` + copie dans `02-brief.md`.

**Checkpoint `--mode=semi`** :
- Affiche le brief.
- "Valide le brief ? (oui / modifier / stop)"
- Si "modifier" → `question utilisateur` pour ajustements, re-délègue.

**Mode `--mode=auto`** : passe direct à la phase 3.

### Phase 3 — Round 1 : avis indépendants (en parallèle)

Pour chaque agent convoqué sauf growth-lead (déjà intervenu), délègue en parallèle :

> "Voici le brief : [contenu de 02-brief.md].
>
> Donne ton avis depuis ton rôle : risques, angles, contraintes, propositions de livrables, points à challenger chez les autres experts. Cite des ressources concrètes (templates, benchmarks, outils). Format structuré (bullets). Budget : `lean` 200 mots max, `standard` 300 mots max, `full` 450 mots max."

Chaque output → `03-round1-<agent>.md`.

Update TRANSCRIPT avec extrait de chaque avis.

### Phase 4 — Débats facultatifs (Round 2)

`growth-lead` identifie les frictions et arbitre :

Exemples types :
{{#IF HAS_PRICING_TIERS}}
- **sales-b2b dit "gater en plan payant"** vs **growth-lead dit "hook dans plan inférieur pour acquisition"** → trade-off acquisition vs revenue per user
{{/IF}}
- **copywriter-brand dit "headline question"** vs **marketing-analytics dit "headline avec chiffre"** → test A/B recommandé
- **content-seo dit "cluster A prioritaire"** vs **growth-lead dit "cluster B"** → arbitrage volume vs marge
- **customer-success dit "onboarding 7 touchpoints"** vs **marketing-analytics dit "trop de friction"** → simplification

Pour chaque point de friction :
1. Délègue à agent A : "L'agent B dit ceci. Challenge ou concède : 150 mots."
2. Délègue à agent B : prompt inversé.
3. `growth-lead` arbitre dans `04-round2-debates.md`.

**Règle d'escalade** :
- **Mode semi** : désaccord persistant sur point critique → `question utilisateur` à l'utilisateur.
- **Mode auto** : arbitre seul, documente dans TRANSCRIPT "Auto-arbitrage : <raison>".
- **Depth `lean`** : pas de round 2 sauf contradiction majeure sur positionnement, pricing, promesse ou risque légal.
- **Aucune friction** : ne pas relancer d'agents. Écrire `04-round2-debates.md` avec "Aucune friction actionnable détectée" + justification.

### Phase 5 — Plan d'exécution

`growth-lead` consolide :
- Brief validé
- Avis round 1
- Arbitrages débats
- Plan de livrables par agent avec deadline, KPI de succès, dépendances

Output → `05-plan.md` + copie dans `docs/growth/PLAN-<slug>.md`.

**Checkpoint `--mode=semi`** : "Valide le plan ? (oui / ajuste / stop)"

### Phase 6 — Livraison

Chaque agent produit ses livrables dans `docs/growth/<sous-dossier>/<slug>/`.

Exemples de livrables par agent :

| Agent | Livrables types |
|---|---|
| `copywriter-brand` | Landing (markdown ou HTML), email copy, ads copy (LinkedIn + Google), brand voice note |
| `content-seo` | Guide (3000+ mots), articles satellites, calendrier éditorial 90j, plan LinkedIn |
{{#IF IS_B2B}}
| `sales-b2b` | Séquence outbound (email + LinkedIn), playbook objections, script démo, proposition commerciale template |
{{/IF}}
| `customer-success` | Onboarding flow (emails + in-app), checklist aha moment, template QBR, étude de cas draft |
| `marketing-analytics` | Rapport audit funnel, tableau A/B test, tracking plan events, dashboard template |
| `growth-lead` | Note stratégique synthèse, recommandations budget, priorisation trimestrielle |

Chaque livrable respecte :
- **Format standardisé** (voir templates dans skills `$redige-brief`, `$ship-landing`, etc.)
- **Placeholder `<À remplir>`** pour toute data {{PROJECT_NAME}} manquante
- **Sources citées** pour tout chiffre benchmark
- **Review croisée** : chaque livrable externe (landing, email, ad) est relu par `copywriter-brand` pour cohérence voice

Log dans `06-delivery.log`. Update TRANSCRIPT après chaque livrable.

### Phase 7 — Mesure & handoff

`marketing-analytics` définit :
- Les KPI à suivre post-mise en ligne
- La fenêtre d'évaluation (7j, 14j, 30j, 90j selon nature)
- Le tracking plan (events, UTM)
- Le critère de "succès" (seuil chiffré)

Output → `07-metrics.md`.

**Checkpoint `--mode=semi`** : "Tous les livrables sont prêts. Veux-tu une synthèse pour publication ? (oui / stop)"

Si "oui" → produit un **ship plan** : liste ordonnée de ce que l'utilisateur doit faire (publier ici, configurer là, lancer ça), avec owners et délais → `08-ship-plan.md`.

**JAMAIS** le skill publie lui-même. L'utilisateur exécute.

## Format TRANSCRIPT.md

Mis à jour incrémentalement à chaque phase. Format similaire au `$call-tech-lead` :

```markdown
# TRANSCRIPT — <titre initiative> — run <timestamp>

**Mode** : auto | semi
**Agents convoqués** : <liste>
**Dossier livrables** : `docs/growth/<slug>/`
**Démarrage** : <HH:MM:SS>
**Fin** : <HH:MM:SS>
**Durée** : XmYs

---

## 📥 Phase 0 — Input

> <besoin verbatim>

---

## 🎯 Phase 1 — Routing

**Analyse** : <3-5 lignes>
**Agents convoqués** : <liste>
**Agents exclus** : <liste + raison>

---

## 📋 Phase 2 — Brief

<extrait 5-10 lignes>

[Détail : `02-brief.md`]

**Checkpoint semi** : ✅ / 🔧 / ⛔

---

## 💬 Phase 3 — Round 1 (avis indépendants)

### 📣 copywriter-brand dit :
> <résumé>

### 📈 marketing-analytics dit :
> …

{{#IF IS_B2B}}
### 🧲 sales-b2b dit :
> …
{{/IF}}

### ❤️ customer-success dit :
> …

### 📝 content-seo dit :
> …

---

## ⚔️ Phase 4 — Débats

### Débat 1 : <titre>

**<agent A>** ouvre : > …
**<agent B>** répond : > …
**✅ Décision growth-lead** : <arbitrage>

---

## 📐 Phase 5 — Plan

- Livrables : <liste>
- Timeline : <…>
- KPI : <…>

**Checkpoint semi** : ✅ / 🔧 / ⛔

---

## 📦 Phase 6 — Livraison

| Agent | Livrable | Fichier | État |
|---|---|---|---|
| copywriter-brand | Landing hero+FAQ | docs/growth/landings/<slug>.md | ✅ |
| content-seo | Guide cornerstone | docs/growth/guides/<slug>.md | ✅ |
| ... | ... | ... | ... |

---

## 📊 Phase 7 — Mesure & ship plan

- KPI primaire : <…>
- Tracking : <events + UTM>
- Ship plan : `08-ship-plan.md` (actions utilisateur)

---

## 🎯 Prochaines étapes

- [ ] Relire les livrables dans `docs/growth/<slug>/`
- [ ] Exécuter le ship plan manuellement (publier / configurer / lancer)
- [ ] Lancer `$retro-campagne` après 30j d'exécution
```

## Refus d'orchestrer — quand le skill s'arrête tôt

Le skill refuse et propose une alternative si :
- **Question simple** ("c'est quoi un bon CTR ?") → réponse directe sans orchestration
- **Brief déjà existant + besoin mineur** → suggère direct `$redige-brief` ou l'agent solo
- **Sujet sans enjeu commercial** (ex : améliorer une UI) → renvoie vers `$call-tech-lead`
- **Action d'exécution pure** (ex : "poste ce tweet") → refuse, pas dans le scope

## Garde-fou spécial : interactions avec `$call-tech-lead`

**Principe absolu** : `$call-tech-lead` **ne consulte PAS les agents commerciaux par défaut**, même sur signal fort.

Raisons :
1. Coût tokens (ajouter 2-3 agents gpt-5.5/gpt-5.4-mini = +30-40% de tokens par run tech-lead)
2. La plupart des US techniques n'ont pas besoin d'avis commercial
3. L'utilisateur préfère trancher lui-même quand c'est nécessaire

**Protocole quand tech-lead identifie un signal commercial fort** (feature pricing, différenciateur majeur, nouveau segment cible, refonte pricing) :

1. `$call-tech-lead` **détecte** le signal (pas auto-invoque).
2. `$call-tech-lead` **propose** à l'utilisateur en phase 1 routing : "Cette feature touche le pricing / différenciateur. Je peux consulter l'équipe commerciale (growth-lead{{#IF IS_B2B}} + sales-b2b{{/IF}}) → +~100k tokens. Oui / Non ?"
3. **Par défaut : Non**. L'utilisateur opt-in explicitement.
4. Si l'utilisateur dit "oui" → tech-lead délègue à `growth-lead` (agent, pas skill) avec le contexte de l'US.
5. En **mode auto** : tech-lead **n'appelle jamais** les agents commerciaux. Il documente le signal dans TRANSCRIPT : "Signal commercial détecté (refonte pricing). En mode auto, pas d'escalade équipe commerciale — à consulter manuellement via `$call-growth-lead` si besoin."

## 💰 Coût tokens — transparence obligatoire

**Référence détaillée** : `docs/COUTS-LLM.md`.

### Annonce au lancement (phase 0)

Le skill **doit afficher** avant de commencer :

```
💰 Estimation coût — $call-growth-lead
────────────────────────────────
Scope détecté : <routing phase 1 preview>
Agents : <liste> (<N> agents)
Mode : <semi|auto>
Depth : <lean|standard|full>
Tokens estimés : <X-Yk>
Équivalent API : ~$<Z> (avec prompt caching)
Budget plan : <impact estimé selon fournisseur>
Optimisations possibles : <pointeurs si applicable>
────────────────────────────────
Continuer ? (y/n) — en mode semi uniquement
```

En **mode auto** : affiche l'estimation mais continue sans attendre.

### Répartition par phase (initiative standard)

| Phase | Tokens | % total |
|---|---|---|
| 0-1 Intake & routing | 15-30k | 6% |
| 2 Brief SMART | 30-60k | 10% |
| 3 Round 1 (3-4 agents) | 100-220k | 45% |
| 4 Round 2 facultatif | 0-100k | 0-15% |
| 5 Plan d'exécution | 30-60k | 10% |
| 6 Livraison | 50-200k | 25% |
| 7 Mesure & ship plan | 20-50k | 8% |
| **Total brut** | **250-650k** | — |
| **Profil `lean`** | **120-300k** | — |
| **Profil `full`** | **400-900k** | — |

### Top coût par agent (ordre décroissant)

1. `growth-lead` (gpt-5.5) — orchestration + brief + plan = ~30%
2. `copywriter-brand` (gpt-5.4-mini) — phase 6 = ~20%
3. `content-seo` (gpt-5.4-mini) — phase 6 = ~15%
{{#IF IS_B2B}}
4. `sales-b2b` (gpt-5.5) — round 1 + livrables = ~15%
{{/IF}}
5. `marketing-analytics` + `customer-success` — ~20% combiné

### Récap en footer TRANSCRIPT

À la fin du run :

```markdown
## 📊 Synthèse coût

- Tokens totaux : ~Xk (input: A, output: B, cache read: C, cache write: D)
- Équivalent API : ~$Y.YY
- Répartition par agent :
  - growth-lead (gpt-5.5) : ~Xk (~$Y)
  - copywriter-brand (gpt-5.4-mini) : ~Xk (~$Y)
  - ...
- Durée totale : <MmSs>
- Budget plan : <impact estimé selon fournisseur>
```

### Optimisations disponibles

Voir `docs/COUTS-LLM.md` pour les 10 optimisations SANS baisse de qualité. Les principales applicables à `$call-growth-lead` :

1. **Utiliser `--depth=lean`** pour les briefs et campagnes localisées (-40-70%)
2. **Ne pas lancer le round 2** sans friction actionnable (-15-35%)
3. **Référencer un brief existant** (`$call-growth-lead "exécute BRIEF-X.md"`) (-30%)
4. **Skills utilitaires solo** quand le scope est étroit (ex: `$ship-landing` seul vs `$call-growth-lead` full)
5. **Scope agents** explicite ("skip content-seo, pas de besoin SEO") (-15-30%)

**Comparaison `$call-tech-lead` vs `$call-growth-lead`** : growth ~50% moins cher que tech car pas d'implémentation code (phases 6-7 tech sont les plus lourdes).

**Budget** : dépend du fournisseur et du plan. Toujours tracer `depth`, agents invoqués et round 2 lancé/non lancé dans `TRANSCRIPT.md`.

## Anti-patterns de l'orchestrateur

- ❌ Orchestrer pour un brief rapide (gaspille tokens) → refuse.
- ❌ Publier automatiquement un livrable → jamais.
- ❌ Fabriquer des chiffres {{PROJECT_NAME}} → placeholder obligatoire.
- ❌ Sauter Phase 3 sur un sujet ambigu → c'est la valeur du multi-agents.
- ❌ Lancer Phase 4 sans friction actionnable → round 2 facultatif.
- ❌ Supprimer un débat critique quand pricing, promesse, légal ou positionnement divergent vraiment.
- ❌ Envoyer un email / faire un post / créer un compte externe → jamais.
- ❌ S'auto-invoquer via `$call-tech-lead` → interdit, l'utilisateur opt-in manuellement.

## Intégration avec skills utilitaires

| Skill | Utilisé en phase |
|---|---|
| `$redige-brief` | Phase 2 (via growth-lead) |
| `$ship-landing` | Phase 6 (via copywriter-brand) |
| `$audit-funnel` | Phase 3 ou en standalone (via marketing-analytics) |
{{#IF IS_B2B}}
| `$brief-demo` | Phase 6 (via sales-b2b) |
{{/IF}}
| `$retro-campagne` | Post-exécution, invoqué manuellement après 30j |

## Référence

- Agents : `.codex/agents/{growth-lead{{#IF IS_B2B}}, sales-b2b{{/IF}}, customer-success, copywriter-brand, content-seo, marketing-analytics}.md`
- Skills utilitaires : `.agents/skills/{redige-brief, ship-landing, audit-funnel{{#IF IS_B2B}}, brief-demo{{/IF}}, retro-campagne}/SKILL.md`
- `docs/GUIDE-LLM.md` — source de vérité projet (§8 ton éditorial)
- `docs/growth/` — dossier de livrables growth
