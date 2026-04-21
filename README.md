# Starter Kit — Équipes virtuelles Claude Code

Un kit portable pour installer sur **n'importe quel projet** un système d'équipes virtuelles Claude Code, skills orchestrés, commandes et rituels de gouvernance. Testé en production sur un SaaS B2B depuis plusieurs mois, puis dépouillé de tout contexte spécifique pour être utilisable partout.

> **Pour qui ?** Un développeur solo ou une petite équipe qui veut orchestrer Claude Code comme une vraie équipe d'ingénieurs + produit + design + QA + sécu + data + growth, sans perdre 3 semaines à tout réinventer.

---

## Ce que tu obtiens

1. **13 agents spécialisés** (.claude/agents/) couvrant toute la chaîne de valeur logicielle et commerciale :
   - Équipe tech (7 agents) : PO, Full-Stack Lead, Designer UX/UI, QA Lead, CSO, Data Engineer, AI/LLM Engineer
   - Équipe growth (6 agents) : Growth Lead, Sales B2B, Customer Success, Copywriter & Brand, Content & SEO, Marketing Analytics

2. **15 skills** (.claude/skills/) qui orchestrent ces agents ou livrent un artefact précis :
   - Orchestrateurs : `/call-tech-lead`, `/call-growth-lead`
   - Pré-PR tech : `/redige-us`, `/fullstack-lead-tech`, `/investigate-bug`, `/review-pr`, `/qa-flow`, `/ship-pr`, `/security-audit`
   - Post-livraison : `/retro`, `/retro-campagne`
   - Growth : `/redige-brief`, `/ship-landing`, `/audit-funnel`, `/brief-demo`

3. **Un GUIDE-LLM.md** (doc/GUIDE-LLM.md) : source de vérité projet, 12 sections (git flow, clean code, tests, sécurité, UX, architecture, pièges connus).

4. **Un système de backlog** (backlog.md) avec rappel systématique en début de session.

5. **Un format de livrables standardisé** (US, plan tech, brief growth, landing, retro) dans `docs/`.

6. **Des rituels de capitalisation** : chaque bug/feature non-triviale termine par un `/retro` qui enrichit le GUIDE-LLM §12 (pièges connus) et la mémoire persistante.

---

## Philosophie

Les 5 principes non-négociables qui font que le système tient :

### 1. Un orchestrateur ≠ un agent
Les skills `/call-tech-lead` et `/call-growth-lead` **convoquent dynamiquement** des agents spécialisés, les font débattre, puis tranchent. L'orchestrateur n'est jamais un agent lui-même.

### 2. Round 1 (avis indépendants) → Round 2 (débats croisés) → arbitrage
Pattern rigoureux pour éviter l'écho de groupe : chaque agent donne son avis sans voir celui des autres, puis on force les confrontations sur les points de friction, puis l'orchestrateur tranche avec justification.

### 3. Traçabilité totale via TRANSCRIPT.md
Chaque run orchestré produit un fichier `TRANSCRIPT.md` qui documente qui a dit quoi, quelles frictions ont été arbitrées et pourquoi. Relecture asynchrone possible, audit post-mortem facile.

### 4. Escalade humaine explicite, pas automatique
Le skill tech ne convoque **jamais** les agents commerciaux sans ton accord explicite (et vice-versa). Pas d'auto-escalade, pas de surprise, pas de tokens brûlés.

### 5. Règles absolues git + migrations + secrets
- Ne JAMAIS merger une PR sans ordre explicite.
- Ne JAMAIS commit sur `main` / `develop` directement.
- Ne JAMAIS exécuter une migration SQL (l'humain joue en staging puis prod).
- Ne JAMAIS push force / `--no-verify` / `--amend` sans demande explicite.

---

## Par où commencer

Lis dans cet ordre :

| Fichier | Pour quoi faire |
|---|---|
| **[README.md](README.md)** (ce fichier) | Vue d'ensemble |
| **[CHECKLIST-KICKOFF.md](CHECKLIST-KICKOFF.md)** | La checklist pas à pas pour démarrer sur ton nouveau projet |
| **[GUIDE-ADAPTATION.md](GUIDE-ADAPTATION.md)** | Le questionnaire de cadrage + mapping spécifique → générique |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | La structure de fichiers et la logique de chargement Claude Code |
| **[PATTERNS.md](PATTERNS.md)** | Les patterns méta (orchestrateur, rounds, TRANSCRIPT, Opus/Sonnet) |
| **[REGLES-TRANSVERSES.md](REGLES-TRANSVERSES.md)** | Les règles git + sécurité + RGPD + process |
| **templates/** | Tous les fichiers à copier-adapter |

---

## Workflow d'adoption — version courte (15 min)

1. Copie le contenu du dossier `templates/` à la racine de ton nouveau projet (voir [CHECKLIST-KICKOFF.md](CHECKLIST-KICKOFF.md) pour la procédure exacte).
2. Lance `/setup-project` dans Claude Code : questionnaire de ~30 questions, le skill remplit automatiquement tous les placeholders.
3. Lance une première feature via `/call-tech-lead "..."` en mode `--mode=semi` pour valider que l'orchestrateur tourne.
4. Affine les agents au fur et à mesure — la première version n'est jamais parfaite (voir [GUIDE-ADAPTATION.md](GUIDE-ADAPTATION.md)).

Workflow détaillé dans [CHECKLIST-KICKOFF.md](CHECKLIST-KICKOFF.md).

---

## Ce que ce kit NE résout PAS

- **Le contexte métier de ton produit** : tu dois l'apporter. Les agents sont des squelettes — leur valeur vient de ce que tu y injectes (domaine, rôles utilisateurs, contraintes, ton éditorial).
- **La mémoire de Claude** : Claude Code a son propre système de mémoire persistante (`~/.claude/projects/.../memory/`). Ce kit ne le remplace pas, mais s'intègre avec.
- **Le MCP / les hooks** : non inclus. Si tu veux auto-exécuter des commandes à certains moments du cycle, configure-le dans `.claude/settings.local.json` séparément.
- **Le tracking des coûts Claude API** : le kit documente des estimations, mais ne monitore pas. Utilise la console Anthropic si tu veux des métriques réelles.

---

## Évolution

Ce kit est un **point de départ**, pas une bible. À mesure que tu capitalises sur ton projet :

- Enrichis le §12 "Pièges connus" du GUIDE-LLM à chaque `/retro`.
- Ajoute des sections spécifiques à ton domaine dans les agents.
- Crée de nouveaux skills utilitaires si tu identifies un pattern répété.
- Affine la répartition Opus/Sonnet selon ton plan Claude et tes besoins de raisonnement.

Le kit source est né minimaliste, il s'est étoffé au fil des features. Le tien fera pareil.

---

## Licence & attribution

Usage libre, sans attribution requise. Si tu construis quelque chose d'intéressant avec, partage — le pattern mérite d'être répliqué.
