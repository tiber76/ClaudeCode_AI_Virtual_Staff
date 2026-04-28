# AGENTS.md — Equipe virtuelle Codex {{PROJECT_NAME}}

Ce fichier donne a Codex les regles transverses du projet. Les details projet vivent dans `docs/GUIDE-LLM.md`, les dettes dans `backlog.md`, les skills dans `.agents/skills/`, et les agents specialises dans `.codex/agents/`.

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
