# Patterns méta — ce qui fait que le système tient

Ce document explique les patterns invariants du kit, séparés de leur implémentation. Utile pour adapter le système à ton contexte sans casser ce qui fonctionne.

---

## Pattern 1 — Orchestrateur multi-agents (Round 1 → Round 2 → Tranche)

C'est **le** pattern central. Tous les skills orchestrateurs (`/tech-lead`, `/growth-lead`) suivent cette chorégraphie.

### Phase 0 — Intake
- Parse le besoin.
- Détermine un slug unique (kebab-case du titre).
- Crée un dossier de run `<skill>-runs/YYYYMMDD-HHMMSS-<slug>/`.
- Initialise TRANSCRIPT.md avec l'en-tête (mode, agents, timestamp).

### Phase 1 — Routing
- Analyse le besoin pour décider **quels agents convoquer**.
- Matrice de signaux → agents (ex : mot "auth" → convoque CSO).
- Documente les agents convoqués ET les agents exclus avec justification.

### Phase 2 — Rédaction initiale (PO ou équivalent)
- Un agent "cadreur" produit l'artefact de départ (US, brief).
- Checkpoint utilisateur (mode semi) : valide ? modifie ? stop ?

### Phase 3 — Round 1 : avis indépendants (parallèle)
- Chaque agent reçoit l'artefact cadreur + le GUIDE-LLM.
- Chaque agent produit un avis de 300-400 mots : risques, propositions, challenges à préparer.
- **Invoqués en parallèle** (plusieurs Agent tool calls dans le même message).
- Aucun agent ne voit l'avis des autres (évite l'écho de groupe).

### Phase 4 — Round 2 : débats ciblés (séquentiel)
- L'orchestrateur détecte les **points de friction** entre avis (A dit X, B dit non-X).
- Pour chaque friction :
  - Délègue à A : "B dit <ceci>. Challenge ou concède (150 mots max)."
  - Délègue à B : prompt inverse.
  - Vérifie les faits cités par chaque agent (si un agent propose de modifier du code existant, lis le fichier pour valider).
  - Tranche avec justification écrite.

### Phase 5 — Plan final
- Consolide avis + arbitrages en un plan exploitable.
- Invoque un skill de synthèse (`/lead-tech`, `/ship-landing`) pour produire le livrable structuré.
- Checkpoint utilisateur (mode semi).

### Phase 6 — Exécution
- Délégation atomique par lot (DB → tests rouges → impl → UI → E2E chez tech ; hero → body → CTA → FAQ chez growth).
- Commits/écritures atomiques.

### Phase 7 — Revue
- Audit automatique (review code, audit copy, QA tests).
- Passe finale par l'agent le plus exigeant (CSO en tech, Growth Lead en commercial).

### Phase 8 — Livraison
- Création PR / publication du draft / export vers canal.
- **Jamais de merge/publication automatique** sans ordre explicite.

### Pourquoi ce pattern fonctionne

1. **Séparation avis/débats/arbitrage** évite les ambiances Yes-man.
2. **Parallélisation round 1** divise la latence par N agents.
3. **TRANSCRIPT** permet l'audit asynchrone (tu peux lire le fichier 2 jours plus tard et comprendre le raisonnement).
4. **Checkpoints mode semi** empêchent le détournement silencieux de direction.
5. **Ordre atomique phase 6** rend chaque commit annulable indépendamment.

---

## Pattern 2 — Répartition Opus / Sonnet / Haiku

Budget quota sur Claude Max (ou coût sur API) = contrainte réelle. Régles empiriques :

| Besoin raisonnement | Modèle recommandé |
|---|---|
| Architecture, threat modeling, arbitrages multi-facteurs complexes | **Opus** |
| Rédaction structurée, application de patterns, cartographie tests | **Sonnet** |
| Extraction/transformation simple, parsing, reformulation courte | **Haiku** |

### Répartition type pour l'équipe tech

- `full-stack-lead` : **Opus** (architecture, trade-offs)
- `cso` : **Opus** (threat modeling STRIDE)
- `po-metier` : Sonnet (pattern-matching domaine)
- `designer-uxui` : Sonnet (DS + copy)
- `data-engineer` : Sonnet (SQL, index)
- `qa` : Sonnet (mapping tests)
- `ai-llm-engineer` : Sonnet (prompt/parser/validator)

### Répartition type pour l'équipe growth

- `growth-lead` : **Opus** (positionnement, arbitrage canaux)
- `sales-b2b` : **Opus** (négo, MEDDPICC)
- `copywriter-brand` : Sonnet (voice & tone)
- `customer-success` : Sonnet (playbook)
- `content-seo` : Sonnet (topic clusters)
- `marketing-analytics` : Sonnet (funnel analytics)

### Règle de glissement

Si tu passes d'API pure à Max 20x (ou vice-versa), ajuste :
- **API facturée** : push vers Sonnet partout où ça passe (coût ÷ 3-5).
- **Max 20x** : garde Opus pour les 2-3 agents les plus critiques, Sonnet pour le reste (économise le weekly cap Opus).

---

## Pattern 3 — Prompt caching 90% via system prompt stable

Claude (Anthropic) supporte le prompt caching : si un gros chunk de contexte reste identique entre appels, il est facturé **10% du prix normal** (lecture de cache).

### Règle d'or : invariant dans system prompt, variable dans user message

```
❌ MAUVAIS (prompt caching cassé)
System prompt : "Tu es un expert. Le ton est bienveillant. Voici les données : {DATA_VARIABLE}"
→ Le DATA change à chaque appel, le system prompt entier est recalculé.

✅ BON (prompt caching préservé)
System prompt : "Tu es un expert. Le ton est bienveillant. [règles fixes de formatting]"
User message : "Voici les données : {DATA_VARIABLE}. Produis l'analyse."
→ Le system prompt est stable, facturé 10% après le premier appel.
```

### Exemple concret — injection de personnalité IA

Cas vécu : un ton de génération (`bienveillant | franc | analytique`) était initialement dans le system prompt → chaque run cassait le cache. Correctif : injecté dans le user message avec ~5 tokens supplémentaires. Cache préservé à 90%.

### Point d'application dans ce kit

- Le **GUIDE-LLM.md** est injecté dans le contexte : reste stable → cacheable.
- Les **agents** ont un system prompt stable (rôle, stack, pièges) → cacheable.
- Les **variables de run** (US, plan, données courantes) vont dans le user message → non-cachées mais marginales.

---

## Pattern 4 — TRANSCRIPT.md comme audit trail

Chaque run orchestré produit un TRANSCRIPT.md **mis à jour incrémentalement** (pas écrit en une fois à la fin).

### Format minimal

```markdown
# TRANSCRIPT — <titre> — <timestamp>

**Mode** : auto | semi
**Agents convoqués** : <liste>
**Durée** : XmYs
**Résultat** : PR <url> | livrable <chemin>

## 📥 Phase 0 — Input
> <besoin verbatim>

## 🎯 Phase 1 — Routing
**Analyse** : <raisonnement>
**Agents convoqués** : <liste>

## 💬 Phase 3 — Round 1
### <agent 1> :
> <extrait 3-5 lignes>

### <agent 2> :
> ...

## ⚔️ Phase 4 — Débats
### Débat 1 : <titre friction>
**<agent A>** : "..."
**<agent B>** : "..."
**✅ Décision** : <arbitrage avec justification>

## 📐 Phase 5 — Plan final
<résumé 5-10 lignes>

## 🛠️ Phase 6 — Exécution
| Lot | Titre | Fichiers | Commit |
|---|---|---|---|
| 1 | ... | ... | ... |

## 🚀 Phase 8 — Livraison
**Résultat** : <URL/chemin>
**Statut** : non mergé/non publié (règle §0)

## 📊 Synthèse coût
- Tokens : ~Xk
- Équivalent API : ~$Y
- Escalades utilisateur : N
```

### Pourquoi c'est critique

- **Auditable** : tu peux relire 2 semaines plus tard pourquoi tel arbitrage a été fait.
- **Reproductible** : si tu veux relancer une feature similaire, tu relis le TRANSCRIPT pour t'inspirer.
- **Transparent** : en mode auto, tous les arbitrages "tech-lead seul" sont tracés avec justification.
- **Debug** : si la feature livrée déraille, tu remontes au TRANSCRIPT pour comprendre où la décision a glissé.

---

## Pattern 5 — Opt-in cross-équipes (pas d'auto-escalade)

L'orchestrateur tech `/tech-lead` et l'orchestrateur growth `/growth-lead` vivent **côte à côte**, ils ne s'appellent pas l'un l'autre sauf accord explicite.

### Règle stricte

- `/tech-lead` détecte un signal commercial (refonte pricing, différenciateur majeur, nouveau segment).
- En **mode semi** → `AskUserQuestion` : "Signal commercial `<X>` détecté. Consulter `<agents growth>` (+~100k tokens) ? Oui/Non." Default = Non.
- En **mode auto** → JAMAIS d'escalade. Documente dans TRANSCRIPT : "Signal commercial détecté, pas d'escalade (mode auto)."

### Pourquoi cette règle

- Évite les runs qui explosent en tokens sans contrôle.
- Évite les décisions métier prises en solo par un agent qui n'a pas le contexte growth.
- Rend les runs **prévisibles en budget**.

---

## Pattern 6 — Refus d'orchestrer pour les tâches triviales

L'orchestrateur a un **garde-fou** : il refuse de lancer toute la mécanique pour une tâche qui ne le mérite pas.

### Exemples de refus

- "Change la couleur du bouton en bleu" → `Edit` direct, pas d'orchestration.
- "Renomme la fonction `getUser` en `fetchUser`" → `Edit` direct.
- "Un bug : le dropdown ne s'ouvre pas" → propose `/investigate-bug` avant d'orchestrer.
- "Corrige une typo dans le README" → `Edit` direct.

### Implémentation

Dans la Phase 1 de l'orchestrateur, détection :

```
Bug trivial / typo / one-liner → 🛑 refuse d'orchestrer, propose direct édition ou /investigate-bug
Refacto interne simple → propose /lead-tech + impl direct, pas besoin d'équipe
Question de doc → répond sans orchestrer
```

**Économie typique** : 80-95% des tokens par rapport à un run complet.

---

## Pattern 7 — Capitalisation via /retro

Après chaque feature non-triviale ou bug complexe, un `/retro` :

1. Identifie **3 points qui ont marché** (pour les répéter).
2. Identifie **3 points qui ont coincé** (avec cause racine, pas juste symptôme).
3. Propose un **ajout au GUIDE-LLM §12 "Pièges connus"** si un piège inédit a été rencontré.
4. Propose une **entrée en mémoire persistante** si l'apprentissage est transverse (ex : préférence de workflow, pattern IA, convention projet).
5. Liste **1-3 actions de prévention** concrètes.

### Pourquoi c'est critique

- Le GUIDE-LLM §12 devient ta mémoire institutionnelle — il grandit avec le projet.
- Chaque piège documenté est un bug futur évité.
- Un projet actif accumule 10-20 pièges §12 en quelques mois → gain de qualité exponentiel.

---

## Pattern 8 — Backlog comme mémoire courte

Un `backlog.md` à la racine, scanné en début de session :

```markdown
# Backlog

## 🔴 P0 — Critique
- Titre (origine: PR #X)

## 🟠 P1 — Important
## 🟡 P2 — Nice-to-have
## 🟢 P3 — Idées
## ✅ Fait (< 30j)
```

### Règles

- **Au début de chaque session** : Claude dit "N P0 / N P1 en attente — traiter avant la tâche courante ?"
- **À chaque dette créée** (scope refusé dans une PR, bug latent, task spawnée) : entrée ajoutée immédiatement.
- **Au merge d'une PR qui résout une entrée** : déplacement immédiat vers `✅ Fait` (règle "nettoyer au merge").
- **Au-delà de 30 jours** : purge de la section `Fait`.

### Pourquoi c'est un pattern, pas juste un fichier

- Empêche l'oubli de dette technique (piège classique des projets solo).
- Rend la charge mentale visible (tu vois si tu accumules 10 P0, tu sais qu'il faut arrêter le nouveau développement).
- Intègre la discipline dans le workflow Claude Code (rappel systématique).

---

## Pattern 9 — Estimation coût au lancement

Chaque skill orchestrateur **annonce son coût estimé AVANT de lancer** :

```
💰 Estimation coût — /tech-lead
────────────────────────────────
Scope détecté : nouvelle route API + composant UI
Agents : po-metier + full-stack-lead + designer-uxui + qa (4 agents)
Mode : semi
Tokens estimés : 400-800k (range selon complexité)
Équivalent API : ~$2-4 (avec prompt caching)
Équivalent Max 20x : ~5-10% d'une session Opus 5h
Optimisations possibles : passer en Sonnet partout si budget serré
────────────────────────────────
Continuer ? (y/n)
```

### Pourquoi

- Transparence budget : tu sais ce que tu engages.
- Évite les "oh merde je viens de cramer 50k tokens sur une typo".
- Force l'orchestrateur à justifier son routing (4 agents = $4 justifiés).

---

## Anti-patterns connus

### 1. Orchestrer pour orchestrer
Si ton besoin est clair et que tu sais ce qu'il faut faire, n'invoque pas `/tech-lead` — `Edit` direct. Orchestration = ~50× plus cher.

### 2. Mélanger plusieurs objectifs dans un run
Un `/tech-lead` = une feature atomique. "Refonte parcours signup + KPI dashboard + alertes Slack" → 3 runs séparés, pas 1.

### 3. Sauter le round 1
Tentation de "on sait ce qu'il faut faire, juste produis le plan". Mauvaise idée — 30% du temps, un agent soulève un point que personne n'avait vu.

### 4. Oublier le checkpoint utilisateur en mode semi
Si tu passes tous les checkpoints en auto-validation, tu perds le contrôle direction. Le mode semi existe pour une raison.

### 5. TRANSCRIPT écrit à la fin seulement
Si le run crash en phase 6, tu perds tout. Update incrémental après chaque phase.

### 6. Ne pas documenter les auto-arbitrages en mode auto
Si l'orchestrateur tranche seul en mode auto sans justification écrite → pas d'audit possible, la confiance s'érode.
