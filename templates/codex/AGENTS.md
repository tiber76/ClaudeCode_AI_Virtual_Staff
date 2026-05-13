<!-- virtual-staff-kit:AGENTS.md v0.4.0 -->
# AGENTS.md — Equipe virtuelle Codex {{PROJECT_NAME}}

Ce fichier donne a Codex les regles transverses du projet. Les details projet vivent dans `docs/GUIDE-LLM.md`, les dettes dans `backlog.md`, les skills dans `.agents/skills/`, et les agents specialises dans `.codex/agents/`.

> Ce fichier provient du kit `virtual-staff-starter-kit`. Tu peux le personnaliser, mais ne supprime pas la ligne de marqueur en tete : elle permet au script `npm run update` de detecter et mettre a jour ce fichier sans ecraser tes modifications.

## Debut de session

1. Lire `docs/GUIDE-LLM.md` si present.
2. Lire `backlog.md` si present et rappeler en une phrase le nombre de P0/P1/P2 ouverts, sans traiter le backlog sans accord explicite.
3. Verifier la branche courante avant toute modification.
4. Ne jamais merger, supprimer une branche, force push, amend ou executer une migration de production sans instruction explicite.

## Orchestration

- Pour une feature non triviale, utiliser le skill `$call-tech-lead`.
- Pour une initiative marketing/growth, utiliser `$call-growth-lead`.
- Pour un bug, commencer par `$investigate-bug` sauf si la cause est deja isolee.
- Les runs orchestres ecrivent leurs artefacts sous `.codex/runs/<skill>/<YYYYMMDD-HHMMSS-slug>/`.
- Les subagents Codex sont convoques explicitement par l'orchestrateur, avec avis independants au round 1 puis debat cible au round 2.

## Verification

- Toute evolution doit avoir une verification adaptee au risque : test unitaire, integration, E2E, build ou revue manuelle documentee.
- Les resultats des commandes doivent etre resumes dans le transcript de run quand un skill orchestre le travail.
- Les migrations SQL sont produites comme fichiers idempotents, jamais executees automatiquement contre staging/prod.

## Livraison

- PR autorisee si les checks demandes sont passes.
- Merge interdit sans ordre explicite contenant clairement `merge` ou equivalent.
- Apres merge d'une feature non triviale, lancer `$retro` pour capitaliser dans `docs/GUIDE-LLM.md` et/ou le backlog.

## Token efficiency — regles transverses

> Principe central : raisonnement profond, output court. La reflexion interne peut etre longue ; la reponse user-facing reste minimale.

- Zero phrase transitoire avant un tool call. Tool call direct.
- Zero recap narratif apres un tool call evident. Si le diff est visible, une ligne suffit.
- Actions multiples → bullet list ultra-courte : `• Fix → fichier.ts`, `• Commit → feat(x)`.
- Fin de reponse : une ligne de statut OU une question directe.
- Pas de preambules de politesse. Action directe.
- Pas de tableaux decoratifs pour 2 items. Tableaux gardes pour ≥3 lignes × ≥2 colonnes utiles.
- Pas de caveats defensifs sur points evidents. Caveats reserves aux risques reels : securite, data loss, breaking change, RGPD, perf.
- Pas de devinette sur API, version, flag, SHA, nom de package. Verifier avant d'affirmer.
- Pas de re-lecture d'un fichier deja lu sans changement.
- Skip fichiers > 100 KB sauf necessite concrete.
- **Lecture ciblee obligatoire** : pour tout fichier > 100 lignes, `ripgrep` ou `grep -n` d'abord pour localiser, puis lecture avec offset/limit (30-50 lignes max).

**Override** : ces regles s'effacent des qu'un sujet touche securite, data loss, breaking change, RGPD, migration prod, paiement, PII. La on detaille a fond.

**Ce qui ne change pas** : prompts d'agents (round 1/2 reste verbeux par design), commit messages exhaustifs, doc projet.

## Delegation aux skills — eviter l'injection inline

Quand un skill ou un agent doit consommer un document long (US, plan, brief, transcript) :

- **A faire** : passer le **chemin absolu** au sous-agent. Le sous-agent lit lui-meme.
- **A eviter** : interpoler le contenu inline dans le prompt du sous-agent. Sur un run multi-agents, l'injection inline d'un document de 200-500 lignes coute typiquement **14 a 35 k tokens evitables**.

Cette regle vaut pour tous les orchestrateurs (`$call-tech-lead`, `$call-growth-lead`) et tout skill qui delegue a un agent.

## Compaction et survie contextuelle

Quand le contexte se remplit, le runtime peut auto-compacter la conversation. Quand la compaction se declenche, **preserver imperativement** dans le resume (ordre de priorite) :

### Doit survivre (compact = perte = bug grave)

1. Regles binaires en cours (PR vers branche cible, pas de merge sans demande, pas de migration executee, pas de `--no-verify`/`--amend`/`--force`).
2. Branche git courante + etat worktree (nom de branche, fichiers modifies non commites, commit en cours d'ecriture).
3. Decisions prises pendant la session non encore commitees (choix produit, copy validee, arbitrage technique).
4. Liste des fichiers edites (path absolu) + resume 1 ligne par fichier.
5. Numeros de PR / issues mentionnes.
6. Verdicts d'agents `$call-tech-lead` s'ils ne sont pas ecrits dans `.codex/runs/`.

### Bon a garder (utile mais reconstructible)

- Resultats `ripgrep` / `grep` qui ont guide une decision.
- Outputs de tests significatifs (echecs — pas les passes).
- Maquettes / preview choisies parmi N options (option retenue + raison).

### Peut etre jete (recompactable)

- Lectures de fichiers entiers re-accessibles via lecture ciblee.
- `git status` / `git log` (rejouables).
- Brouillons d'agents non retenus.
- Outputs informationnels (ls, cat, head).

### Apres une compaction, toujours :

1. `git status` + `git branch --show-current`.
2. `git diff --stat`.
3. Si commit en cours d'ecriture : reconfirmer le contenu staged avant `git commit`.
4. Si PR en cours : `gh pr view` pour recuperer l'etat distant.
