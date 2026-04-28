# Couts LLM — Estimations & optimisations {{PROJECT_NAME}}

Estimations par run pour les skills et agents. Les montants doivent etre actualises avec les prix reels de ton fournisseur et les chiffres observes dans tes transcripts.

---

## Disclaimer

Les tokens peuvent partir vite avec une equipe virtuelle, en particulier sur les gros modeles, les contextes longs et les runs `--depth=full`. Ces estimations ne sont pas une garantie de cout : surveille la console fournisseur et garde les premiers runs en `--depth=lean` ou `standard`.

Le systeme doit etre ajuste au fil du projet. Apres les runs importants, lance `/retro` ou `$retro` pour identifier les agents vraiment utiles, reduire les prompts trop longs, mettre a jour le routing et documenter les bonnes pratiques dans `docs/GUIDE-LLM.md`.

Si tu utilises Claude Code, tu peux ajouter le monitoring local gratuit **Claude Code Usage Monitor** : https://github.com/tiber76/monitor-ccu. Il lit `~/.claude/projects/` et affiche les couts/tokens par session, les modeles et les sous-agents sans API key ni service externe.

---

## Prerequis — prix a actualiser

Ce fichier ne doit pas figer une grille tarifaire : Anthropic, OpenAI et les plans equipes changent. La bonne pratique est de remplir cette section avec :

| Fournisseur | Modele premium | Modele standard | Modele economique | Source tarifaire |
|---|---|---|---|---|
| Claude | Opus | Sonnet | Haiku | A renseigner |
| OpenAI Codex | gpt-5.5 / gpt-5.3-codex | gpt-5.4-mini | gpt-5.4-nano si disponible | A renseigner |

**Prompt caching / contexte reutilise** : quand le fournisseur le permet, garder les instructions stables dans les prompts system et mettre les variables dans le message utilisateur. Les gains reels dependent du provider et du plan.

---

## Profils de profondeur

Les orchestrateurs acceptent `--depth=lean|standard|full`.

| Profil | Usage | Agents | Round 2 | Gain attendu |
|---|---|---|---|---|
| `lean` | Tache localisee, risque faible, besoin clair | 2-3 agents cibles | Seulement risque bloquant | -40 a -70% |
| `standard` | Feature classique | 3-4 agents utiles | Seulement friction actionnable | Reference |
| `full` | Architecture, securite, data, IA, go-to-market structurant | Tous les agents pertinents | Debat complet si utile | +30 a +80% |

Regle par defaut : commencer en `standard`, retrograder en `lean` si le besoin est simple, passer en `full` uniquement si le risque le justifie.

---

## Estimations par skill

| Skill | Tokens brut | Avec cache / contexte reutilise | Commentaire |
|---|---|---|---|
| `/call-tech-lead --depth=lean` | 180-450k | 45-120k | 2-3 agents, round 2 rare |
| `/call-tech-lead --depth=standard` | 350-900k | 90-240k | 3-4 agents, bon defaut |
| `/call-tech-lead --depth=full` | 600k-1.4M | 150-350k | Pour les vrais arbitrages multi-domaines |
| `/call-growth-lead --depth=lean` | 120-300k | 35-90k | Brief ou campagne localisee |
| `/call-growth-lead --depth=standard` | 250-650k | 70-190k | Initiative commerciale classique |
| `/call-growth-lead --depth=full` | 400-900k | 110-260k | Positionnement, pricing, lancement majeur |
| Skill solo (`/audit-funnel`, `/ship-landing`, etc.) | 80-200k | 30-60k | Preferable si le scope est etroit |
| Agent solo | 20-50k | 10-20k | Ideal pour une question fermee |

---

## Repartition type d'un `/call-tech-lead --depth=standard`

| Phase | Tokens | Optimisation |
|---|---|---|
| 0-1 Intake & routing | 15-30k | Refuser les demandes triviales |
| 2 PO redige US | 30-70k | Reutiliser une US existante |
| 3 Round 1 (3-4 agents) | 120-280k | Avis courts limites a 300 mots |
| 4 Round 2 facultatif | 0-120k | Lancer seulement si friction actionnable |
| 5 Plan final | 40-100k | Referencer les artefacts precedents |
| 6 Implementation | 120-350k | Scope de fichiers explicite |
| 7 Review + QA | 40-130k | Tests cibles, pas de matrice inutile |
| 8 Ship | 10-25k | Resume concis |
| **Total brut** | **350-900k** | — |

---

## Top 10 optimisations sans baisse de qualite

### 1. Utiliser `--depth=lean` quand le risque est faible — economie 40-70%
Un besoin localise n'a pas besoin de toute l'equipe. Exemple : correction UI simple, endpoint isole, wording, petit flux QA.

### 2. Rendre le round 2 facultatif — economie 15-35%
Si les avis du round 1 convergent, ecrire "Aucune friction actionnable detectee" et passer au plan. Relancer un agent seulement pour trancher une contradiction concrete.

### 3. Refuser d'orchestrer les triviaux — economie 80-95%
Typo, one-liner, refacto mineur ou question de doc doivent etre traites directement ou par un skill solo.

### 4. Fournir le contexte precis en input — economie 20-40%
Fichiers concernes, contrainte produit, US existante, logs, captures, budget et definition of done evitent les clarifications.

### 5. Reutiliser les artefacts — economie 30%
Preferer `/call-tech-lead "implemente PLAN-X.md"` a une demande vague qui force les agents a recreer le contexte.

### 6. Agent solo pour questions fermees — economie 90%
Exemple : "Demande a `sales-b2b` comment repondre a cette objection." Pas besoin d'orchestrateur.

### 7. Skill specialise si le scope est clair — economie 60-80%
`/fullstack-lead-tech`, `/audit-funnel`, `/ship-landing`, `/review-pr` ou `/qa-flow` suffisent souvent.

### 8. Scope agents explicite — economie 15-30%
Exemple : "skip cso, pas de signal securite" ou "skip content-seo, pas de besoin SEO".

### 9. Modeles adaptes au role
Utiliser le modele le plus fort seulement pour les arbitrages complexes. Garder les agents d'execution ou d'analyse cadree sur un modele plus economique.

### 10. Mode semi pour les runs a risque
Un checkpoint peut economiser un run entier si la direction initiale est mauvaise. En revanche, le mode auto reste utile pour les taches classiques bien cadrees.

---

## Leviers a eviter

- Ne pas mettre tous les agents sur le modele le plus economique : les arbitrages complexes chutent en qualite.
- Ne pas sauter le round 1 sur un sujet ambigu : les avis independants font la valeur de l'orchestration.
- Ne pas supprimer un debat critique : si securite, data, pricing ou architecture divergent vraiment, le round 2 est rentable.
- Ne pas donner trop peu de contexte : les agents le recreeront en clarifications, ce qui coute plus cher.
- Ne pas utiliser `full` par defaut : c'est un mode de risque, pas un mode de confort.

---

## Tracking reel

Pour suivre les vrais couts :

1. Console fournisseur (Anthropic, OpenAI, etc.) pour usage et couts.
2. `TRANSCRIPT.md` : chaque run orchestre doit inclure tokens, agents, depth, round 2 lance ou non.
3. Logs applicatifs si tu mesures les runs en CI ou dans un outil interne.
4. Claude Code : `monitor-ccu` pour suivre localement sessions, modeles, sous-agents et couts.
5. Retro apres les gros runs : decisions utiles, agents inutiles, prompts a raccourcir.
6. Actualisation trimestrielle de ce fichier avec les chiffres observes.
