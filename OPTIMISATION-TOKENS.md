# Optimisation Tokens & Modeles

Objectif : garder le benefice de l'equipe virtuelle sans payer un debat complet pour chaque petite tache.

## Disclaimer

Les tokens peuvent monter tres vite avec des gros modeles, beaucoup d'agents ou des contextes longs. Les profils `--depth` reduisent le risque, mais ne remplacent pas le suivi des couts dans la console fournisseur.

La bonne pratique est iterative : lancer `retro` apres les runs importants, regarder quels agents ont vraiment apporte de la valeur, puis ajuster le routing, les prompts et les modeles au besoin reel du projet.

Pour Claude Code, le monitoring peut etre fait avec **Claude Code Usage Monitor** : https://github.com/tiber76/monitor-ccu. C'est un dashboard local gratuit qui lit `~/.claude/projects/` et permet de suivre sessions, modeles, sous-agents, tokens et couts sans API key ni service externe.

## Diagnostic

Le fonctionnement de l'equipe est bon pour les sujets ambigus : avis independants, confrontation, arbitrage, transcript. Le risque principal est la sur-orchestration :

- trop d'agents convoques "au cas ou" ;
- round 2 lance meme sans friction utile ;
- agents premium utilises pour du cadrage simple ;
- prompts round 1 trop longs ;
- revue complete pour des changements locaux.

## Changement Applique

Les orchestrateurs acceptent maintenant :

```text
--depth=lean|standard|full
```

| Depth | Usage | Economie attendue |
|---|---|---:|
| `lean` | petite feature, bug deja compris, refacto localise | 40-70% |
| `standard` | feature produit normale | baseline optimisee |
| `full` | auth, paiement, PII, data model, IA, migration, pricing, GTM majeur | qualite prioritaire |

Le round 2 devient facultatif :

- si aucune friction actionnable n'est detectee, l'orchestrateur ne relance pas les agents ;
- en `lean`, round 2 seulement pour risque bloquant ;
- en `standard`, round 2 seulement si deux avis se contredisent sur une decision concrete ;
- en `full`, round 2 reste disponible pour les arbitrages lourds.

## Routing Recommande

### Tech

| Situation | Agents |
|---|---|
| Refacto interne simple | `full-stack-lead`, `qa` |
| UI simple | `full-stack-lead`, `qa`, `designer-uxui` |
| API classique | `full-stack-lead`, `qa`, `po-metier` si impact utilisateur |
| Auth / permissions / upload / paiement | `full-stack-lead`, `qa`, `cso` |
| Data model / KPI / requete lourde | `full-stack-lead`, `qa`, `data-engineer` |
| Feature IA | `full-stack-lead`, `qa`, `ai-llm-engineer`, `cso` si PII |
| Feature critique transverse | `full` avec tous les specialistes pertinents |

### Growth

| Situation | Agents |
|---|---|
| Landing simple | `growth-lead`, `copywriter-brand`, `marketing-analytics` |
| Article / cluster SEO | `growth-lead`, `content-seo`, `copywriter-brand` |
| Sequence outbound B2B | `growth-lead`, `sales-b2b`, `copywriter-brand` |
| Onboarding / retention | `growth-lead`, `customer-success`, `copywriter-brand` |
| Pricing / repositionnement | `full` avec sales, CS, analytics et copy |

## Matrice Modeles Claude

Les templates Claude utilisent des familles de modeles, pas des noms dates :

| Agent | Famille | Raison |
|---|---|---|
| `full-stack-lead` | Opus | architecture, arbitrage technique complexe |
| `cso` | Opus | threat modeling, securite, arbitrages multi-facteurs |
| `growth-lead` | Opus | strategie, positionnement, arbitrages business |
| `sales-b2b` | Opus | negociation, objections, pricing B2B |
| `po-metier` | Sonnet | cadrage produit structure |
| `designer-uxui` | Sonnet | UX/UI et copy produit |
| `qa` | Sonnet | tests, verification, cartographie risques |
| `data-engineer` | Sonnet | schema, requetes, performance |
| `ai-llm-engineer` | Sonnet | prompts, parsers, validations IA |
| `customer-success` | Sonnet | activation, playbooks, retention |
| `copywriter-brand` | Sonnet | redaction controlee |
| `content-seo` | Sonnet | plans SEO et contenus |
| `marketing-analytics` | Sonnet | funnel, hypotheses, A/B |

## Matrice Modeles Codex

Au 2026-04-28, l'adapter Codex genere ces defaults :

| Agent | Modele | Effort | Raison |
|---|---|---|---|
| `full-stack-lead` | `gpt-5.3-codex` | `high` | agentic coding, architecture, refactor |
| `cso` | `gpt-5.3-codex` | `high` | revue code + threat modeling |
| `qa` | `gpt-5.3-codex` | `medium` | tests, bugs, verification |
| `data-engineer` | `gpt-5.3-codex` | `medium` | schema, requetes, perf |
| `ai-llm-engineer` | `gpt-5.3-codex` | `medium` | prompts + integration code |
| `po-metier` | `gpt-5.4-mini` | `medium` | cadrage produit structure |
| `designer-uxui` | `gpt-5.4-mini` | `medium` | UX/UI et copy produit |
| `growth-lead` | `gpt-5.5` | `high` | arbitrage strategique |
| `sales-b2b` | `gpt-5.5` | `high` | negociation, objections |
| `customer-success` | `gpt-5.4-mini` | `medium` | playbooks et activation |
| `copywriter-brand` | `gpt-5.4-mini` | `medium` | redaction controlee |
| `content-seo` | `gpt-5.4-mini` | `medium` | plans et contenus |
| `marketing-analytics` | `gpt-5.4-mini` | `medium` | funnel, hypotheses, A/B |

## Regles D'Usage

- Commencer par `--depth=lean` si le besoin est localise.
- Utiliser `standard` pour la plupart des features.
- Reserver `full` aux sujets a fort cout d'erreur.
- Limiter les avis round 1 a 200/300/450 mots selon depth.
- Ne pas relancer un agent au round 2 sans contradiction actionnable.
- Ecrire les agents exclus dans le routing : la sobriete doit etre auditable.
- Apres 5-10 runs, relire les transcripts et supprimer les agents rarement utiles.
