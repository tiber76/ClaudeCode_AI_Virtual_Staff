---
name: setup-project
description: |
  Questionnaire interactif qui remplit tous les placeholders du starter kit en une
  seule fois. Lance ce skill après avoir copié le kit dans un nouveau projet pour
  adapter les 13 agents, 15 skills et la doc au contexte spécifique : stack,
  rôles utilisateurs, entités métier, ton éditorial, sécurité, pricing.
  Produit un rapport de configuration et un backlog des TODOs résiduels.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
triggers:
  - setup project
  - initialise le kit
  - configure le starter kit
  - setup-project
  - init kit équipes
---

# /setup-project

## Objectif
Configurer le starter kit d'équipes virtuelles Claude Code en une seule session, via un questionnaire structuré. À la fin, tous les placeholders `{{VARIABLE}}` dans `.claude/agents/`, `.claude/skills/` et `docs/` sont remplacés par les valeurs du projet.

## Quand l'utiliser
- **Juste après** avoir copié le starter kit dans un nouveau projet.
- **Une seule fois** par projet. Pour ré-éditer ensuite, modifie les fichiers directement.

## Prérequis
Le kit doit être copié à la racine du projet :
- `.claude/agents/*.md` (13 agents avec placeholders)
- `.claude/skills/*/SKILL.md` (15 skills avec placeholders)
- `.claude/commands/*.md` (15 alias)
- `docs/GUIDE-LLM.md` (squelette 12 sections)
- `docs/EQUIPES-LLM.md` (doc équipe)
- `docs/COUTS-LLM.md` (estimations tokens)
- `backlog.md` (à la racine)

Vérifier avec `ls .claude/agents/ | head -3` avant de lancer.

## Garde-fous

- ❌ JAMAIS modifier des fichiers hors de `.claude/`, `docs/` ou `backlog.md`.
- ❌ JAMAIS écraser un projet existant : si `docs/GUIDE-LLM.md` existe déjà et n'a pas de placeholders `{{...}}`, le skill s'arrête en demandant confirmation.
- ✅ Backup automatique avant modifications : le skill crée `.claude.backup-<timestamp>/` avant tout remplacement.

## Étapes

### Étape 0 — Vérifications préalables

```bash
# Vérifier que le kit est bien copié
ls -la .claude/agents/ .claude/skills/ docs/GUIDE-LLM.md backlog.md

# Compter les placeholders résiduels
grep -r "{{" .claude/ docs/ | wc -l
```

Si 0 placeholder → le kit est déjà configuré, arrêter.
Si erreur listing → le kit n'est pas copié, demander à l'utilisateur de le copier d'abord.

Créer un backup :
```bash
cp -r .claude .claude.backup-$(date +%Y%m%d-%H%M%S)
cp -r docs docs.backup-$(date +%Y%m%d-%H%M%S)
cp backlog.md backlog.backup-$(date +%Y%m%d-%H%M%S).md
```

### Étape 1 — Questionnaire (via `AskUserQuestion`)

Pose les questions en **6 vagues thématiques**, pas toutes d'un coup (fatigue cognitive).

**Vague A — Identité projet** (5 questions)

1. **Nom du projet** (string court, sert de `{{PROJECT_NAME}}`)
2. **One-liner produit** (1 phrase, sert de `{{PROJECT_TAGLINE}}`)
3. **Type de projet** : SaaS B2B / SaaS B2C / App mobile / CLI / Open source / Internal tool / Marketplace
4. **Modèle business** : freemium / free trial / subscription / pay-per-use / open source / none
5. **Langue UI principale** : FR / EN / multilingue

**Vague B — Stack technique** (8 questions)

6. **Langage backend principal** (ex: Node.js 22, Python 3.12, Go 1.22, Ruby 3.3)
7. **Framework backend** (ex: Next.js 16, Express, FastAPI, Rails, Gin, NestJS, autre)
8. **Base de données principale** (ex: PostgreSQL, MySQL, MongoDB, SQLite, Firestore)
9. **Client DB / ORM** (ex: Prisma, Drizzle, SQLAlchemy, ActiveRecord, raw SQL, Supabase SDK)
10. **Framework UI** (ex: React 19, Vue 3, Svelte 5, Next.js + React, vanilla JS, native SwiftUI, none pour CLI)
11. **Auth** : maison / Auth0 / Clerk / Supabase Auth / NextAuth / Firebase Auth / autre / none
12. **Déploiement** : Vercel / Fly.io / Railway / AWS / Docker+K8s / Netlify / autre
13. **Framework tests** : Jest / Vitest / Pytest / RSpec / Go testing / autre — et **E2E** : Playwright / Cypress / Puppeteer / none

**Vague C — Intégrations** (4 questions, optionnelles)

14. **Paiement** : Stripe / LemonSqueezy / Paddle / autre / none
15. **Email transactionnel** : Resend / Postmark / SendGrid / SES / autre / none
16. **Monitoring / observabilité** : Sentry / Datadog / LogRocket / none / autre
17. **LLM dans le produit** : Anthropic Claude / OpenAI / Google Gemini / Mistral / autre / none (active/désactive `ai-llm-engineer`)

**Vague D — Domaine métier** (5 questions)

18. **Rôles utilisateurs** (liste libre, 2-5 rôles) — ex: "owner, admin, member, viewer"
19. **Rôle admin principal** (celui qui a tous les droits) — ex: "owner"
20. **Entités métier principales** (3-7 entités) — ex: "Issue, Project, Team, Member"
21. **Y a-t-il un workflow par statuts ?** (true/false) — Si oui, liste des statuts principaux
22. **Plans de pricing** (si SaaS) — liste des tiers avec features gated, ou "none"

**Vague E — Ton & sécurité** (4 questions)

23. **Registre éditorial** : formel / direct / warm / technique / décalé / premium accessible / autre
24. **3-5 mots bannis** (ex: "révolutionnaire, disruptif, game-changer, synergie")
25. **Contraintes sécurité** : RGPD (true/false), 2FA (true/false/prévue), données sensibles à documenter
26. **Endpoints critiques à rate-limiter** (liste ou "none")

**Vague F — Git & équipe** (3 questions)

27. **Branche de dev par défaut** : develop (défaut) / main / master / autre
28. **Taille équipe** : solo / 2-5 / 5-15 / 15+
29. **Agents à activer** : liste des 13 agents avec case à cocher (pré-cochés selon les réponses précédentes)

### Étape 2 — Synthèse & validation

Affiche un récap :
```
📋 Configuration proposée pour {{PROJECT_NAME}}

IDENTITÉ
├── Nom : <valeur>
├── Type : <valeur>
└── Langue UI : <valeur>

STACK
├── Backend : <valeur>
├── Frontend : <valeur>
├── DB : <valeur>
└── Tests : <valeur>

DOMAINE
├── Rôles : <liste>
├── Entités : <liste>
└── Statuts : <liste ou N/A>

AGENTS ACTIVÉS (X/13)
├── ✅ po-metier
├── ✅ full-stack-lead
├── ❌ ai-llm-engineer (désactivé : pas de LLM dans le produit)
└── ...

Prêt à appliquer ? (y/n/modifier)
```

Si "modifier" → proposer de modifier une section spécifique, relancer juste cette partie.

### Étape 3 — Application des remplacements

Pour chaque fichier avec placeholders (`.claude/agents/*.md`, `.claude/skills/*/SKILL.md`, `docs/*.md`) :

1. Lire le fichier.
2. Remplacer tous les `{{VARIABLE}}` connus par leur valeur.
3. Évaluer les blocs conditionnels `{{#IF FLAG}}...{{/IF}}` :
   - Si FLAG est true → garder le contenu sans les balises.
   - Si FLAG est false → supprimer le bloc entier.
4. Pour les variables non-résolues (cas rare) : laisser un commentaire HTML `<!-- TODO: remplacer {{VAR}} manuellement -->`.
5. Sauvegarder.

### Étape 4 — Suppression des agents désactivés

Pour chaque agent non activé dans la vague F :
```bash
rm .claude/agents/<nom>.md
```

Et supprimer les références à cet agent dans :
- `.claude/skills/tech-lead/SKILL.md` (matrice de routing)
- `.claude/skills/growth-lead/SKILL.md` (matrice de routing)
- `docs/EQUIPES-LLM.md`

### Étape 5 — Vérification finale

```bash
# Chercher les placeholders résiduels
grep -rn "{{" .claude/ docs/ | grep -v ".template.md" | grep -v "{{#IF" | grep -v "{{/IF}}"
```

Si placeholder résiduel → ajouter entrée dans `backlog.md` P1 : "Remplacer `{{VAR}}` dans `<fichier>` (résidu setup)".

### Étape 6 — Rapport final

Écrit `.claude/setup-report.md` :

```markdown
# Rapport de configuration — {{PROJECT_NAME}}

**Date** : <YYYY-MM-DD HH:MM>
**Branche** : <branche courante>

## Configuration appliquée

- Projet : <nom> (<type>, <business model>)
- Stack : <summary>
- Rôles : <liste>
- Entités : <liste>

## Agents activés (X/13)

| Agent | Activé | Justification |
|---|---|---|
| po-metier | ✅ | — |
| ai-llm-engineer | ❌ | Pas de LLM dans le produit |
| ... | | |

## Fichiers modifiés

- 13 → X agents (N supprimés)
- 15 → Y skills
- 6 docs mises à jour

## Placeholders résiduels (à traiter manuellement)

- `docs/GUIDE-LLM.md:42` → `{{SPECIFIC_VARIABLE}}` (ajouté au backlog P1)
- ...

## Prochaines étapes suggérées

1. Relire `docs/GUIDE-LLM.md` et compléter les sections §6 (architecture projet) et §12 (pièges — vide au démarrage).
2. Relancer un run test : `/redige-us "Ajoute un bouton d'export CSV"` — vérifier que l'US utilise les bons rôles.
3. Après 2-3 features, lancer `/retro` pour enrichir le §12 du GUIDE-LLM.
4. Si besoin de modifier la config : éditer les fichiers directement.

## Backup

Les fichiers originaux sont dans :
- `.claude.backup-<timestamp>/`
- `docs.backup-<timestamp>/`

Tu peux les supprimer après vérification :
```bash
rm -rf .claude.backup-* docs.backup-* backlog.backup-*
```
```

### Étape 7 — Commit initial suggéré

Propose (sans exécuter automatiquement) :
```bash
git add .claude/ docs/ backlog.md
git commit -m "chore(claude-kit): setup initial configuration pour <projet>"
```

## Gestion des erreurs

### Si l'utilisateur arrête en cours
- Les modifications appliquées ne sont pas rollback automatiquement.
- Les backups restent disponibles pour rollback manuel : `rm -rf .claude && mv .claude.backup-<ts> .claude`.

### Si une question n'a pas de réponse claire
- Proposer une valeur par défaut raisonnable.
- Ajouter `TODO` dans le backlog pour affiner plus tard.

### Si le kit n'est pas copié
- Signaler l'erreur et donner la commande exacte :
  ```bash
  # Depuis la racine du kit :
  cp -r templates/claude <projet>/.claude
  cp -r templates/docs <projet>/docs
  cp templates/backlog.template.md <projet>/backlog.md
  ```

## Anti-patterns à éviter
- ❌ Lancer le skill sans avoir copié le kit au préalable.
- ❌ Modifier `.claude/settings.local.json` — fichier hors scope du skill.
- ❌ Supprimer les backups avant validation complète.
- ❌ Re-lancer le skill sur un projet déjà configuré (écraserait les personnalisations).

## Référence
- `docs/PLACEHOLDERS.md` — dictionnaire complet des variables.
- `docs/GUIDE-ADAPTATION.md` — procédure manuelle équivalente (si le skill échoue).

## 💰 Coût indicatif

Tokens : ~40-100k brut · ~15-30k effective (avec prompt caching)
Équivalent API : ~$0.2-0.5
Durée : 15-30 min (majoritairement passé à répondre aux questions)
