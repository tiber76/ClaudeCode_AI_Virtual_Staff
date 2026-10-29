# Phases détaillées de `/call-tech-lead`

> Document compagnon du `SKILL.md`, chargé à la demande pour économiser du contexte à chaque invocation. Couvre les phases 0, 1, 2, 5, 6, 7, 8. Phases 3 et 4 (rounds, débats) : `rounds.md`. Dossier de run : `.claude/call-call-tech-lead-runs/<YYYYMMDD-HHMMSS>-<slug>/` (gitignoré). `<abs>` = chemin absolu du checkout du run.

---

## Phase 0 — Intake & setup

1. Parse le besoin, `--mode` (défaut `semi`), `--depth` (défaut `standard`, rétrogradable en `lean`).
   **1 bis — Éligibilité `/dev-express`** : critères et invariants dans `.claude/skills/dev-express/SKILL.md` § Éligibilité (source unique, jamais recopiée ici). Cible éligible → `Skill(skill="dev-express", args="<cible> --mode=<même mode>")` et **le run s'arrête là** : aucun dossier de run créé ici, `/dev-express` tient son propre TRANSCRIPT (avec la mention de la bascule). `semi` : une question avant (« petit sujet, on part en express ? ») ; `auto` : bascule automatique.
2. Slug kebab-case. **Le slug est l'identifiant stable de la demande** : il ne change plus (US, plan, branches, commits, titres de PR).
3. Crée le dossier de run. Écrit `00-input.md` : besoin verbatim + mode + depth + timestamp. Ce verbatim devient le champ « Demande initiale » de l'US.
4. **Branche** : si `{{GIT_DEFAULT_BRANCH}}` est à jour → `git checkout -b {{GIT_PREFIX_FEATURE}}<slug>`, branche **provisoire** des Phases 0-5 (US, plan). Le code d'une tranche, T1 comprise et même si le run n'en a qu'une, s'écrit sur `{{GIT_PREFIX_FEATURE}}<slug>-Tn`, créée en Phase 6 ; c'est celle-là que la Phase 8 pousse. Autre branche courante → demander confirmation.
5. Initialise `TRANSCRIPT.md` (format : `transcript-format.md`) avec une ligne d'horodatage par phase : durée par étape, sous-agents lancés (type, modèle), attentes de l'utilisateur. Une piste de gain de temps n'abaisse jamais le palier de review et ne saute jamais la passe `cso`.
6. Affiche l'**annonce coût** (`SKILL.md`).

---

## Phase 1 — Routing

| Signal dans le besoin | Agents convoqués |
|---|---|
| Nouvelle route API / authentification / permissions / upload / paiement | + **cso** |
| Route existante qui accepte un ID de ressource en query/path (`*_id`, `scope=…`) | + **cso** (risque IDOR : un format valide ≠ une ressource qui appartient à l'appelant) |
| Feature data / nouveau KPI / requête lourde / agrégation / modèle de données | + **data-engineer** |
{{#IF HAS_AI_FEATURE}}
| Feature IA : LLM, prompts, parsers, rapports IA, chatbot, contexte chaîné | + **ai-llm-engineer** (+ souvent **cso** : scrub des données perso, logs de tokens anormaux) |
{{/IF}}
{{#IF HAS_DESIGN_SYSTEM}}
| Nouvelle page / composant UI / refonte | + **designer-uxui** + **integrateur** (binôme conception + intégration) |
| Maquette déjà validée (ou bundle de design) à passer en code | + **integrateur** (seul si le design est tranché) |
{{/IF}}
| Refacto pur sans impact utilisateur | **full-stack-lead + qa** uniquement |
| Feature complète « classique » | **full-stack-lead + qa + po-metier + spécialistes signalés** |
| Typo / one-liner / petit sujet éligible express | 🛑 refuse d'orchestrer : typo → édition directe ; bug évident → `/fix-bug` ; sinon `/dev-express` (Phase 0, étape 1 bis) |

Plafonds `--depth` : `lean` max 3 agents hors PO (si plus de signaux, garder dans l'ordre `cso` → `data-engineer` → `ai-llm-engineer` → `designer-uxui` et documenter les exclus) ; `standard` max 4, sauf risque sécurité/données/IA majeur ; `full` sans plafond autre que la pertinence.

{{#IF HAS_GROWTH_TEAM}}
**Signal commercial** (refonte pricing, différenciateur majeur, nouveau segment, onboarding) : détecté, **jamais auto-convoqué**. `semi` : `AskUserQuestion` (défaut Non). `auto` : noté au TRANSCRIPT, pas d'escalade.
{{/IF}}

Écrit `01-routing.md` (justification, agents exclus, signal commercial détecté même sans escalade). Met à jour le TRANSCRIPT.

---

## Phase 2 — PO rédige l'US

**Pré-étape quand le run part d'une entrée de backlog de plus d'un mois** : avant de déléguer, le tech-lead vérifie lui-même (10-15 min) que le chemin décrit est encore atteignable, preuve `fichier:ligne` : (1) les surfaces citées portent-elles l'action décrite ? (2) un utilisateur du rôle visé peut-il y arriver ? (3) le défaut a-t-il déjà été corrigé ? Toute réponse négative va **en tête du mandat du PO**. Sans ça, le PO écrit une US complète sur une prémisse fausse, le Round 1 la démonte, et l'US plus le brief QA sont à réécrire.

Délègue à `po-metier` avec le besoin : il produit l'US (`docs/us/US-<slug>.md` + copie `02-us.md`), le besoin verbatim recopié tel quel dans « Demande initiale », découpée en **tranches** (T1 = MVP démontrable seule, taille S ou M, test indépendant par tranche, critères d'acceptation numérotés rattachés à leur tranche) avec un tableau « Suivi des tranches ».

**Checkpoint `semi`** : l'US s'affiche dans le chat (restitution, le fichier en lien, cf. `_partage/fil-de-progression.md` § Demander une validation), puis « Valide l'US ? (oui / modifier / stop) ». « modifier » → `AskUserQuestion` puis re-délégation ; « stop » → arrêt propre, état sauvegardé. `auto` : passe à la Phase 3, loggé.

---

## Phase 5 — Plan final

Consolide : US, avis Round 1, arbitrages Round 2, puis `/fullstack-lead-tech` en sous-routine (UX/UI, tests, sécurité, performance). Sortie : `05-plan-final.md` + copie `docs/plans/PLAN-<slug>.md`.

**Découpe par tranche, jamais par couche** : le plan reprend les tranches de l'US et ordonne les lots par tranche (Lot 0 socle = ce qui sert ≥ 2 tranches ; puis T1 → Tn). Une PR = une tranche (ou deux tranches S). Seuils indicatifs : tranche ≤ 2 j, PR ≤ ~800 lignes hors tests, sinon une « justification de complexité » dans le plan. Le point « démontrable » de chaque tranche (test E2E vert ou capture) est celui où le run peut livrer une PR partielle sans code mort.

**Anti-pattern « lot monolithique »** : un lot qui touche 3+ fichiers actifs simultanément, ou cumule 3+ verbes d'action sur des fichiers différents (patcher X + monter Y + supprimer Z + migrer W), est **pré-découpé dans le plan** en sous-lots d'un fichier actif chacun. Sinon l'agent dev bute en Phase 6 sur des couplages impossibles à exécuter atomiquement, et le découpage se fait a posteriori en auto-arbitrage. Pour chaque lot proposé, lister les fichiers actifs touchés ; si > 2 et couplés, forcer le découpage.

Le plan porte une section « Hypothèses à lever au smoke réel » (« aucune » sinon).

**Checkpoint `semi`** : le plan s'affiche dans le chat (une ligne par tranche et par lot : à quoi ça sert, ce que ça touche ; décisions à trancher), puis « Valide le plan ? (oui / ajuste / stop) ». Résumé des décisions clés au TRANSCRIPT.

---

## Phase 6 — Implémentation (TDD strict, une tranche = un worker frais)

**TDD systématique** : le dev (`full-stack-worker`, `integrateur` en pair sur l'UI, `ai-llm-engineer` si IA) écrit ses tests unitaires/API/intégration en cycle RED → GREEN → REFACTOR → `/verify` → commit, à partir du brief QA (oracle). Le QA reste en silence radio entre le Round 1 et le lot final de chaque PR ; exception : 0-2 échanges courts si un cas du brief est réellement ambigu.

**Constantes métier** : avant tout littéral métier (statut, rôle, plan, URL) dans du code applicatif, chercher d'abord s'il existe une constante exportée, et l'importer ; jamais de redéclaration. À inclure dans chaque mandat de worker.

**Le tech-lead ne code jamais** : un worker à contexte frais exécute tous les lots de la tranche, l'orchestrateur ne reçoit qu'**un retour par tranche** (plus ses propres rapports de review). Un run à une seule tranche passe par le même pattern.

### Pattern spawn tranche

Le contexte relu à chaque message domine la facture : l'orchestrateur reste vivant toute l'US (Phases 0-5 une fois, checkpoints, tableau de suivi, merges sur ordre) mais le code d'une tranche ne s'écrit jamais dans un contexte déjà lourd. Les plafonds (prompt ≈ 500 mots, retour ≤ 600 tokens) bornent **ce qui entre dans le contexte de l'orchestrateur**, jamais le travail du worker : entre les deux il lit, teste et itère autant qu'il faut.

**Rappels worker** (bloc recopié en tête des prompts « Tranche Tn » et « Correction Tn ») :

```
Dépôt : <chemin ABSOLU du checkout du run> ; toute commande git en git -C <abs>.
Environnement : vérifie la version du runtime ({{STACK_LANGUAGE_BACKEND}}) avant npm/npx/tests ; le shell par défaut peut en avoir une autre.
Garde-branche avant chaque commit : test "$(git -C <abs> branch --show-current)" = {{GIT_PREFIX_FEATURE}}<slug>-Tn || { echo ABORT-WRONG-BRANCH; exit 1; }
git add nominatif (jamais -A ni .) ; jamais d'amend ; hors du code de la tranche, tu n'écris que pr-body-Tn.md et 06-implementation-Tn.log dans le dossier de run (ni rapports de review, ni 06-base-Tn.sha, ni 06-mandat-Tn.md) ; ne pousse pas, n'ouvre pas la PR : rends la main.
```

**Avant chaque `Agent`** : l'orchestrateur écrit le mandat composé dans `<run>/06-mandat-Tn.md` (trace du mandat envoyé), puis un contrôle fail-closed : aucun chevron de gabarit non substitué (`<run-id>`, `<slug>`, `<abs>`, `Tn` littéral…) et la présence de `git -C /`. Un mandat laissé avec ses placeholders fait lire un plan introuvable et rend la garde-branche toujours fausse : un spawn entier perdu. Le prompt passé à `Agent` est le contenu de ce fichier, relu après écriture.

**Worker tranche** — agent `full-stack-worker` (le `full-stack-lead` en mode worker, qui lit son mandat dans `full-stack-lead.md`), aussi pour « Correction Tn » ; `integrateur` en pair sur l'UI ; `ai-llm-engineer` si IA. Prompt type :

```
Tranche Tn — <slug>/Tn — <titre>.
<Rappels worker, recopiés ici>
Branche : {{GIT_PREFIX_FEATURE}}<slug>-Tn EXISTANTE, créée par l'orchestrateur depuis origin/{{GIT_DEFAULT_BRANCH}} à jour : git -C <abs> checkout {{GIT_PREFIX_FEATURE}}<slug>-Tn, jamais -b ni -B, ne refetch pas {{GIT_DEFAULT_BRANCH}}, jamais depuis la tranche précédente.
Premier commit, SEULEMENT si docs/plans/PLAN-<slug>.md est non suivi (T1) : docs(plan), avant tout lot.
Plan : Read <abs>/.claude/call-call-tech-lead-runs/<run-id>/05-plan-final.md, section « Tranche n ».
Brief QA : Read <abs>/.claude/call-call-tech-lead-runs/<run-id>/03-round1-qa.md, sections <sections applicables>.
US : tranche n — son « test indépendant » est ta définition de fini.
Workflow : lot par lot, RED → GREEN → REFACTOR → /verify → commit ; quels tests à chaque étape : /verify § Quels tests, à quel moment. Ni suite entière ni E2E avant de rendre la main : l'orchestrateur les lance en arrière-plan dès ton dernier commit. Aucun commit après le dernier lot, sauf pour corriger un test rouge. Un test d'intégration n'impose jamais un réglage que l'outil réel choisit seul : il passe ce que le vrai appelant passe. Checkpoint démontrable (capture ou test ciblé vert).
Rends la main dès le dernier commit ; prépare le BROUILLON du body de PR (impacts, étapes de vérification) dans <run>/pr-body-Tn.md.
Retour (≤ 600 tokens, français clair, une ligne par rubrique, lisible sans ouvrir le code) :
  Tranche : Tn ✓ ou ⚠ · Branche · Commits : n · HEAD : <hash7>
  Tests : ciblés P/T sur chaque commit · /verify V/8 sur chaque commit
  Démontrable : <la preuve, en une phrase>
  Non vérifié : <ce que tu n'as PAS pu contrôler et pourquoi>
  Décisions prises · Reste / hors scope · Risques · Détail : 06-implementation-Tn.log
```

**Sections du brief QA par sous-lot** : API + helpers : A, B, C, D, E, H (+ G si IA) ; IA : G, H ; UI : A, B, F, H ; page : A, F, H ; lot final (E2E + relecture) : toutes. **Interdit** : injecter le contenu du brief ou du plan dans le prompt (~20-40 k tokens dupliqués dans le contexte de l'orchestrateur à chaque lot) ; le worker les lit lui-même. Lot 0 (socle de migration) : pas de TDD, pas de brief.

**Taille** : tranche S = un worker ; tranche M = un worker par groupe de sous-lots (`.api`+`.ia`, puis `.ui`, puis `.page`+`.e2e`), chacun repartant frais avec la même section du plan et `06-implementation-Tn.log` comme passation.

**Sous-lot UI** (si UI) : `integrateur` prend markup + CSS, le dev prend la logique, avec un contrat explicite de hooks DOM. Sujet visuel subjectif (couleur, taille, disposition) : 2-3 variantes en preview côte à côte, l'utilisateur tranche **avant** le commit. Smoke visuel avant chaque commit qui touche du markup. **Cap de 3 itérations** de boucle preview/screenshot par état UI : au-delà, `semi` → `AskUserQuestion` (capture, diagnostic, hypothèse) ; `auto` → on garde le meilleur état atteint et le TRANSCRIPT le dit.

**Lot final de chaque PR** : `qa` est re-convoquée **une seule fois par PR**, mandat plafonné à 300 mots : relit la couverture produite par le dev (verdict oui/non par section du brief, cas oubliés signalés) et écrit les E2E. Cas oubliés → c'est le dev qui écrit les tests rouges manquants. Si le scope a été réduit en cours de run (PR partielle), le mandat QA cite les sections qui s'appliquent et celles reportées.

**Checkpoint « démontrable »** : le test indépendant de la tranche passe. `semi` : « On livre Tn seule, ou on enchaîne Tn+1 dans la même PR ? » (deux tranches S max par PR).

### Garde avant la review

Un sous-agent peut avoir commité ailleurs ou sur une mauvaise base ; une PR empilée sur sa parente finit en conflit dès le squash de celle-ci. Avant **chaque** review (passe de correction comprise), l'orchestrateur vérifie en `git -C <abs>` : branche = `{{GIT_PREFIX_FEATURE}}<slug>-Tn` ; aucune fusion/rebase/cherry-pick en cours ; arbre propre (`status --porcelain` vide : un fichier oublié au `git add` nominatif passe les tests locaux et casse après merge) ; sha rendu par le worker = HEAD ; ≥ 1 commit depuis la base ; `merge-base HEAD origin/{{GIT_DEFAULT_BRANCH}}` = la base notée à la création de la branche (`06-base-Tn.sha`) ; la branche n'existe pas sur `origin` avec une histoire non mergée. Verdict horodaté ajouté à `<run>/06-garde.log`, la ligne « garde ok sur <sha7> » recopiée en tête du rapport de review. Si le projet fournit un script de garde, l'utiliser plutôt que ces commandes. Un retard sur `{{GIT_DEFAULT_BRANCH}}` est une information, jamais un rebase automatique.

### Séquence après le dernier commit

Dès le dernier commit du dernier lot (visible dans `git log`, sans attendre le retour), en parallèle :
- la **suite entière** de l'espace touché (`{{CMD_UNIT_TEST}}`, `{{CMD_INT_TEST}}`) en arrière-plan ;
- l'**E2E au niveau calculé** par `bash $CLAUDE_PROJECT_DIR/.claude/hooks/e2e-level.sh <abs> origin/{{GIT_DEFAULT_BRANCH}} HEAD` (`aucun`, `specs` ou `smoke` ; jamais jugé par l'agent ; un seul run E2E à la fois, tous worktrees confondus) ;
- le **test manuel local** (Phase 7, point 4), pour que la review le voie ;
- le **smoke réel des hypothèses** de la section 6.1 du plan, avant la première review : un défaut trouvé là repart au worker sans passe de review ;
- la passe **`cso`** (`model: "opus"` explicite) si le diff touche un chemin sensible (liste : `bash $CLAUDE_PROJECT_DIR/.claude/hooks/review-level.sh --sensitive`, source unique, jamais recopiée).

La review ne part qu'une fois la suite verte et ces passes jouées ; un rouge de la suite est un finding hors review.

### Review

Jouée par l'orchestrateur : `Skill(skill="review-pr")`, pipeline complet, chercheurs et vérificateurs en sous-agents frais (des yeux qui n'ont pas écrit le code). Un sous-agent ne pouvant pas en spawner d'autres, il n'y a pas de « reviewer worker ». Le palier est calculé par `review-level.sh` depuis le diff. Rapport : `.claude/reviews/<sha HEAD>.md`, copie dans `07-review-Tn.md`.

### Boucle de correction

🔴 ou 🟠 → `semi` : relance du worker sans question (hors cas « à trancher » ci-dessous) ; `auto` : autonome. On relance le **worker de la tranche** (`SendMessage` à son identifiant, contexte intact) ; un worker frais seulement s'il dépasse ≈ 300 k de contexte ou ne répond plus (un worker frais met 20 à 40 min à relire plan, brief et code avant son premier commit). **Un seul worker de correction par passe**, tous les findings ouverts dans son mandat ; le code ne s'écrit jamais dans le contexte de l'orchestrateur. Zéro dette de review : jamais de push avec un finding ouvert.

**Concevoir le correctif avant de le coder** : pour tout 🔴 et tout 🟠 sur un chemin sensible, l'orchestrateur écrit dans le mandat trois lignes par finding : (a) l'**invariant** que le correctif rétablit, en une phrase ; (b) le **cas symétrique ou inverse** du scénario (et la limite du mécanisme existant que le correctif emprunte : plafond, throttle, clé de dédup) — pour un contrôle de chemin, ses trois bornes : égal à la racine, sous elle, par un alias ; (c) le **test** qui compose les vraies fonctions du projet, doublures posées seulement à la frontière système (disque, réseau, processus), jamais sur une fonction du projet. Sans ces lignes le mandat ne part pas : un correctif écrit vite sur un mandat de 10 lignes est la première source du 🔴 suivant. Le worker recopie la ligne CONCEPTION dans le body du commit qui corrige.

**Prompt type « Correction Tn »** :

```
Correction Tn — <slug>/Tn.
<Rappels worker>
Branche EXISTANTE {{GIT_PREFIX_FEATURE}}<slug>-Tn : git -C <abs> checkout (jamais -b ni -B).
Findings : Read <run>/07-review-Tn.md, dernière passe (🔴 et 🟠 ouverts), hors « contesté » ou « à trancher ».
CONCEPTION <fichier:ligne> — invariant rétabli : … · cas symétrique : … · test : …
Findings hors review (passe cso, test rouge) : <fichier:ligne + attendu, recopié par l'orchestrateur>.
Un finding réfuté sur pièce : ne le corrige pas, écris l'argument (fichier:ligne) dans ton retour.
Un commit par finding ou groupe cohérent, /verify sur chaque commit ; pas de suite entière (l'orchestrateur la relance si le delta le justifie). Aucun commit après le dernier finding, sauf test rouge.
Retour (≤ 400 tokens) : HEAD · commits (hash7 + finding), tests, contestés, non vérifié.
```

**« À trancher »** : un 🟠 qui exige une décision produit, ou qu'un worker a contesté sur pièce → `semi` : checkpoint utilisateur ; `auto` : listé dans l'encadré « À trancher » de la PR et le run s'arrête après la PR de Tn, sans merge autonome.

**Séquentiel, pas parallèle** : un seul run E2E à la fois, et les tranches se touchent. Le parallélisme reste réservé aux lots indépendants à l'intérieur d'une tranche.

**Lisibilité humaine** : tout ce que l'orchestrateur écrit ou reçoit se lit sans ouvrir de code. Fiche de retour en français clair, une ligne par rubrique nommée ; le TRANSCRIPT reçoit par tranche un paragraphe « ce que ça change, en clair » ; chaque checkpoint pose une question qu'on tranche en une phrase. Messages entre deux outils : ce qui vient de finir, ce que ça change, ce qui reste, sans identifiant interne.

Log temps réel dans `06-implementation-Tn.log`. **Pas de push** dans cette phase.

---

## Phase 7 — QA & sécu (review verte acquise en Phase 6)

Par tranche :
1. **Review verte** : rapport `.claude/reviews/<sha HEAD>.md` présent, 0 🔴 et 0 🟠 ouvert. Ne pas rejouer une passe sur le même sha. Sinon retour à la boucle de la Phase 6.
2. **`cso` passe finale** : jouée en Phase 6 avant la première review ; ici on vérifie seulement qu'elle a rendu sans bloquant. Opus explicite : elle relit le diff avec la checklist sécurité complète, **indépendamment des findings du Round 1**, puis valide que les bloquants du Round 1 sont traités. Sa correction est un commit du worker, relu par la review. Elle se rejoue sur le delta d'un correctif de review qui touche un chemin sensible.
3. **Pyramide de tests** jouée par l'orchestrateur en Séquence et **consignée** dans `08-qa-Tn.md` (un champ manquant ou « non vérifié » se recopie tel quel, jamais complété). `/qa-flow` corrige un échec en `--last-failed` sans relancer la suite complète. Un correctif de test est un commit : retour à la boucle.
4. **Test manuel local** (si la tranche touche l'interface ou un parcours utilisateur) : l'orchestrateur joue le parcours des critères d'acceptation sur le serveur local, dans un vrai navigateur (règle : `.claude/skills/_partage/test-manuel-local.md`), consigné dans `08-qa-Tn.md` avec un statut ✓ / ✗ / non joué (raison) / sans objet (raison). Un ✗ repart au worker (« Correction Tn »).

---

## Phase 8 — Ship

**Checkpoint `semi`** : la synthèse s'affiche (ce qui change, écart au cadrage, à valider, pas fait, test manuel), le brouillon du body en lien, puis « Prêt à push + PR ? (oui / stop) ».

Par tranche, l'orchestrateur (jamais le worker) :
- Valide la branche `{{GIT_PREFIX_FEATURE}}<slug>-Tn` et la review verte ; recopie les « à trancher » du rapport dans l'encadré du body.
- Complète `pr-body-Tn.md` (template `.github/pull_request_template.md` s'il existe) avec les règles de `/ship-pr` : ligne de statut (`/review-pr 0 🔴 0 🟠 · N à trancher`, nombre de passes, test manuel local), étapes « À vérifier » issues des 🟠 corrigés, encadré « À trancher » si besoin.
- **Secrets** : chaque texte qui sort (body, rapport de review, TRANSCRIPT) est relu dans sa version finale juste avant publication ; une valeur suspecte (clé, token, contenu de fichier d'environnement) sort du texte avant, jamais après.
- Push `git push -u origin {{GIT_PREFIX_FEATURE}}<slug>-Tn` (la porte `review-gate` exige le rapport du sha exact qui part ; tout commit ajouté après la review se re-reviewe), puis `gh pr create --base {{GIT_DEFAULT_BRANCH}} --title "<type>(<scope>): <slug>/Tn — …" --body-file <run>/pr-body-Tn.md`.
- Poste le rapport de review en commentaire de la PR (`gh pr comment <n> --body-file .claude/reviews/<sha>.md`, commande séparée) et, une fois le TRANSCRIPT à jour et relu, le TRANSCRIPT aussi : le dossier de run est gitignoré et peut disparaître avec le worktree.
- URL dans `09-pr.md`. **Ne merge pas.**
- Commits avec accents : message écrit dans un fichier puis `git commit -F <fichier>` (nom unique par commit), jamais un heredoc quoté dans `-m`.

**Une PR = un contexte frais** : en direct (session solo), on clôt après la PR et la tranche suivante repart en session neuve ; sous `/call-tech-lead` multi-tranches, la session principale reste vivante toute l'US et ce sont les workers qui portent chaque tranche à contexte frais.

### Boucle tranches — merge avant la suivante, jamais d'empilement

1. PR de Tn ouverte, review verte → tableau « Suivi des tranches » : `PR #n`. Un « à trancher » ouvert suspend l'ordre permanent de merge. « Review verte » pour merger = 0 🔴, 0 🟠 ouvert **et** 0 « à trancher » : avant tout merge autonome, relire le body de la PR (`gh pr view <n> --json body --jq .body`) : ligne de statut ET encadré doivent dire zéro ; une ligne absente ou un gabarit non rempli = stop.
2. **Merge de Tn avant Tn+1.** `semi` : checkpoint « PR #n prête, review verte — merge et j'enchaîne Tn+1 ? » (l'utilisateur merge, ou dit « merge » = ordre explicite). `auto` : merge autonome **uniquement** si la demande initiale contient « merge chaque tranche après review verte » ; sinon le run s'arrête proprement après la PR de T1 et le dit.
3. **Point de santé avant Tn+1** : `{{GIT_DEFAULT_BRANCH}}` à jour et sa dernière exécution de tests verte. Rouge = on répare d'abord, jamais de tranche par-dessus une régression.
4. Tn+1 repart de `origin/{{GIT_DEFAULT_BRANCH}}` frais ; le tableau de suivi passe Tn à `✅ PR #n`.

Pourquoi jamais d'empilement : une PR empilée sur sa parente finit en conflit dès le squash de celle-ci ; une base fraîche par tranche coûte moins qu'un merge de rattrapage, et chaque PR se revert seule.

**Batch de plusieurs PR indépendantes** : après les avoir toutes créées, laisser le working tree sur la branche de la PR la plus prioritaire et le dire (« working tree actuel : `<branche>` ») ; le serveur de dev suit le working tree, pas une branche figée.

**Backlog** : la feature qui résout une entrée du backlog du projet le dit dans la PR (« Résout `<slug>/Tn` ») ; la clôture se fait **au merge**, pas avant. Dettes et suites repérées en cours de run : liste de fin de session, jamais inscrites d'office, l'utilisateur décide. Fin de run : résumé en français (`SKILL.md`), suggestion de `/retro`.
