# Règles transverses — les invariants du système

Les règles listées ici s'appliquent à **tous les projets** qui utilisent ce kit, quelle que soit la stack ou le domaine. Elles sont le résultat de plusieurs mois d'itération sur un vrai projet en production — chacune a été écrite après un incident évité ou subi.

Tu peux adapter la forme, **pas le fond**.

---

## § Git & Livraison

### R1 — Ne JAMAIS merger sans ordre explicite
Créer une PR est autorisé. La merger nécessite une instruction humaine explicite.

> "ok pour le PR" ≠ "merge la PR". Il faut "merge", "go merge", "tu peux merger".

**Pourquoi** : un merge mal intentionné peut casser prod. Le coût d'un "merge ?" à l'humain est ~1 seconde, le coût d'un rollback après merge accidentel est plusieurs heures.

### R2 — Ne JAMAIS commit sur main ou develop directement
- `main` = prod, protégée.
- `develop` = intégration, jamais de commit direct.
- Toute modification passe par une branche `feature/*`, `fix/*`, ou `hotfix/*` (ce dernier uniquement sur demande explicite).

### R3 — Ne JAMAIS push force, no-verify, amend sans demande explicite
Ces trois opérations peuvent détruire du travail. Elles sont autorisées uniquement si l'humain dit "force push", "skip hooks", "amend".

### R4 — PR toujours base `develop` (sauf hotfix)
`gh pr create --base develop`. Une PR vers `main` est **toujours** un hotfix (demande explicite requise).

### R5 — Supprimer une branche = ordre explicite
Pas de nettoyage automatique post-merge. L'humain décide.

---

## § Migrations & Données

### R6 — L'humain joue les migrations SQL
Le kit produit des fichiers `.sql` idempotents (`CREATE ... IF NOT EXISTS`). **Jamais** d'exécution directe de migration depuis l'orchestrateur. L'humain :
1. Applique en staging.
2. Teste.
3. Applique en prod.

**Pourquoi** : une migration mal testée peut corrompre la prod. La sécurité se gagne en séparant "produire le SQL" (sûr) de "l'exécuter" (risqué).

### R7 — Backup avant opération DB risquée
Toute opération qui touche la prod en écriture :
- Backup récent obligatoire.
- Vérifier le plan d'exécution avant (`EXPLAIN` sur gros UPDATE).
- Préférer des opérations idempotentes.

---

## § Sécurité

### R8 — Jamais de secrets dans le code
- `.env.*` dans `.gitignore`.
- Secrets en env vars serveur uniquement.
- Pas de clé API hardcodée, même dans les tests.

### R9 — Validation côté serveur obligatoire
Ne jamais faire confiance aux inputs client. Toute donnée qui traverse une frontière serveur est validée et sanitizée.

### R10 — Rate limiting sur endpoints sensibles
Auth, paiement, contact, upload : rate limit in-memory ou Redis. Même en dev (bypass ciblé pour tests uniquement).

### R11 — Escape XML/HTML = 5 caractères
`&`, `<`, `>`, `"`, `'` — **toujours les 5**. L'erreur classique est d'oublier les quotes ("XML = balises") et de laisser une CVE attribute-injection latente sur les attributs HTML.

### R12 — PII dans du JSONB = scrub avant persistance
Les colonnes JSONB (rapports IA, logs enrichis) accumulent des PII dérivées impossibles à purger a posteriori (pas de candidate_id dans le JSON). Règle : **scrub server-side à la persistance**, PII jamais en base.

### R13 — RGPD Art. 17 = chemin de purge dès la conception
Pour toute nouvelle table qui contient des PII :
- Documenter le chemin de purge.
- Tester la cascade ON DELETE.
- Si PII dérivée dans JSONB → scrub amont (R12).

---

## § Tests

### R14 — Pas de code mergé sans tests sur les changements
Chaque évolution = au moins un test. Pas d'exception "trivial, pas besoin".

### R15 — E2E obligatoires avant PR
Smoke + critical au minimum. Si échec → `--last-failed` (pas re-run complet).

### R16 — Tests unit en plus des E2E quand c'est possible
Un bug caché par 3000 tests E2E verts = un composant sans test unit. Extrais les fonctions pures et teste-les.

### R17 — Ne jamais mocker la DB en test d'intégration
Un test d'intégration qui mock la DB ne vaut rien. Si tu mock, c'est un test unit, nomme-le comme tel.

### R18 — Ne jamais modifier un test pour qu'il passe
Si un test échoue, c'est soit le code, soit le test. Diagnostique avant de modifier. Modifier un test pour faire disparaître une erreur = bug masqué en prod.

---

## § Clean Code

### R19 — Fichier > 300 lignes = refactoriser
Au-delà, la lisibilité s'effondre. Découpe en sous-modules cohérents.

### R20 — Fonction > 40 lignes = découper
Single Responsibility. Une fonction = une chose.

### R21 — Composant React > 150 lignes = extraire la logique pure
La logique non-JSX est extraite en fonctions pures testables (`lib/<domain>-pure.js`), testées en unit pur sans DOM. Règle absolue — si tu ne peux pas extraire, **refacto avant** d'ajouter de la logique.

### R22 — Pas de commentaires "quoi"
Le code lisible > commentaires. Commenter uniquement le **pourquoi** (contrainte cachée, workaround bug spécifique).

### R23 — Pas de code commenté
Supprimer ou mettre dans un commit séparé "chore: remove dead code".

### R24 — Catch silencieux interdit
`try { ... } catch {}` est toujours un bug potentiel masqué. Toujours logger ou remonter l'erreur.

### R25 — Pas de `console.log` en prod
Sauf erreurs critiques. Sinon → `lib/logger` avec niveaux.

---

## § IA / LLM (si applicable)

### R26 — Faits déterministes calculés serveur, injectés dans le prompt
Trends, streaks, deltas → fonction serveur pure qui produit les chiffres, injectée dans le prompt comme `[FAITS MESURÉS]`. L'IA **commente**, elle n'**invente** pas.

### R27 — Seuil pragmatique pour bypasser le template IA
Pas de `total > 0` strict (trop sensible aux parasites). Préférer `total < 3` pour bypass + étiquetage explicite des zones de données dans le prompt (`[ÉTAT AGRÉGÉ]` vs `[PÉRIODE ANALYSÉE]`).

### R28 — Validator synchro avec lexique du prompt
Si le prompt autorise "points" mais le validator blackliste "points" → self-lock garanti. Tout terme du prompt doit être cohérent avec le validator.

### R29 — Structured outputs = pattern officiel `tool_choice`, pas `output_config`
Les paramètres `output_config` ne sont pas contraignants de manière fiable sur les SDK actuels. Passe par `tool_choice: { type: 'tool', name: 'X' }` + lecture dans `response.content[0].input`.

### R30 — Parser strict + log anomalies
Si `insights.length > 0` mais mapping produit `[]` exploitable → throw `PARSE_EMPTY_INSIGHTS`. Log Sentry si `insights === [] && tokens > 0`.

### R31 — Budget guard sur les appels Claude
Helper `callClaude()` qui vérifie `isBudgetExceeded()` avant chaque appel. Évite le DoS économique (boucle qui explose le budget).

### R32 — Prompt caching = system prompt stable, variable dans user message
Sinon le cache casse à chaque run (coût × 10).

### R33 — Few-shot avec exemple de reformulation autorisée
Pour chaque unité interdite dans le prompt, fournir un exemple positif (MAUVAIS → BON). Interdire sans alternative = Claude choisit par défaut lexical.

---

## § Process

### R34 — Backlog scanné en début de session
Rappel systématique : "N P0 / N P1 en attente — traiter avant ?"

### R35 — Backlog nettoyé au merge
Déplacer entrée vers `✅ Fait` **dans la foulée** du `gh pr merge`, jamais plus tard (règle "nettoyer au merge").

### R36 — Retro systématique après feature non-triviale
Après merge d'une feature > 1 jour ou résolution d'un bug complexe, `/retro` pour capitaliser.

### R37 — Ajout au GUIDE-LLM §12 via retro uniquement
Pas d'ajout direct dans le GUIDE-LLM. Passe par `/retro` qui propose un diff, tu valides, puis commit séparé `docs(guide-llm): ajout piège X`.

### R38 — Mémoire persistante pour les apprentissages transverses
Si une leçon est transverse (préférence workflow, pattern Claude), l'écrire dans la mémoire Claude Code (`~/.claude/projects/.../memory/`). Si c'est spécifique au projet → GUIDE-LLM.

### R39 — Sujets visuels subjectifs = 2-3 options en preview avant commit
Couleurs, tailles, dispositions : produire 2-3 variantes descriptibles en preview DOM côte à côte, l'humain tranche, **puis** commit la version retenue. Pas de ping-pong commit → feedback → commit.

### R40 — Découpe en lots atomiques pour features non-triviales
PR via orchestrateur = 6-8 commits atomiques (DB, tests rouges, impl, UI, E2E, etc.), pas un monolithe. Facilite revue et rollback.

---

## § Collaboration LLM

### R41 — Ne jamais cacher un auto-arbitrage en mode auto
Tout arbitrage pris sans l'humain en mode auto est **explicitement** tracé dans le TRANSCRIPT avec justification. La confiance se gagne par la transparence.

### R42 — Challenge factuel round 2
Quand un agent propose de modifier du code existant, il doit citer les lignes exactes (`fichier.js:L42-55`). Sans ligne exacte = hypothèse non vérifiée. L'orchestrateur lit le fichier cité pour valider — si le changement proposé est déjà en place, la reco est supprimée du plan.

### R43 — Mandat data/tech lead élargi à l'audit de l'existant
Quand on ajoute de la logique dans un module, l'audit efficience ne porte pas que sur le **nouveau** scope — il couvre aussi **l'existant** sur ce module (prompts, caching, requêtes). Évite les rework post-livraison.

### R44 — Diff stats avant commit merge auto-résolu
Après `git merge -X ours` ou rebase auto, **toujours** vérifier `git diff --cached --stat` avant commit. Un merge auto-résolu peut avoir dupliqué du code silencieusement.

### R45 — Squash merges cassent `git branch --merged`
Après une PR squash-mergée, `git branch --merged develop` pense que la branche n'est pas mergée. **Source de vérité** = `gh pr list --state all`. Jamais supprimer de branche sur le seul critère git.

---

## Comment utiliser ce fichier

- Le **GUIDE-LLM.md** de ton projet **reprend** les règles pertinentes au projet.
- Chaque règle a un ID (R1-R45) pour la référencer dans les agents et skills.
- Ajoute tes règles spécifiques projet au GUIDE-LLM, pas ici (ce fichier reste stable cross-projet).
- Relis ces règles trimestriellement — elles sont la colonne vertébrale du système.
