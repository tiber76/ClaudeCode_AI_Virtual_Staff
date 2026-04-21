# Guide d'adaptation — Personnaliser le kit au-delà du setup automatique

Le skill `/setup-project` remplit automatiquement les placeholders via un questionnaire. Ce guide couvre ce que tu peux faire **en plus** pour personnaliser ton kit : ajouter des agents spécifiques à ton domaine, adapter les pièges connus, étoffer les pre-brief des skills.

---

## Deux modes d'adaptation

### Mode 1 — Setup automatique (recommandé)

```
/setup-project
```

Le skill pose ~30 questions en 6 vagues (identité, stack, intégrations, domaine, ton, git/équipe), puis remplit tous les placeholders `{{VARIABLE}}` dans :
- Les 13 agents `.claude/agents/*.md`
- Les 15 skills `.claude/skills/*/SKILL.md`
- `docs/GUIDE-LLM.md` (squelette 12 sections)
- `docs/EQUIPES-LLM.md`
- `backlog.md`

Durée : 15-30 minutes.

**Couvre 80% des besoins**. Pour les 20% restants (personnalisation fine par domaine), continue avec ce guide.

### Mode 2 — Remplissage manuel

Si tu ne veux pas lancer `/setup-project` (ex: éditeur préféré, projet déjà configuré partiellement), édite les fichiers directement. Réfère-toi à [`PLACEHOLDERS.md`](PLACEHOLDERS.md) pour la liste complète des variables à remplacer.

---

## Au-delà du setup — Personnalisations fines

### 1. Remplir le GUIDE-LLM §10 (Architecture spécifique)

`/setup-project` laisse cette section vide — elle est pour **les patterns métier uniques à ton projet** (conventions internes, architecture non standard, règles spécifiques qui ne rentrent pas dans les 9 autres sections).

Exemples de ce qui va dans §10 :
- Patterns d'architecture inhabituels (ex: système de plugins, event-sourcing, CQRS maison)
- Règles métier critiques non triviales (ex: "le statut X ne peut suivre que Y ou Z")
- Patterns de migration progressive (ex: V1 → V2 coexistent avec règles précises)
- Invariants data non documentés ailleurs

À remplir **avant** ton premier `/tech-lead` important.

### 2. Enrichir le GUIDE-LLM §12 (Pièges connus)

Cette section est **vide au démarrage** — c'est normal. Elle grandit via `/retro` après chaque bug résolu ou feature non-triviale.

Format d'un piège :

```markdown
### Titre court du piège

- **Symptôme** : ce qu'on observe en pratique
- **Cause** : la cause racine (pas le symptôme)
- **Incident de référence** : date + PR/commit si applicable
- **Mitigation** :
  - action 1
  - action 2
- **Principe général** : la leçon transverse à retenir
```

Chaque entrée doit :
1. Décrire un **vrai incident** (pas une hypothèse théorique)
2. Avoir une **cause racine identifiée** (pas juste "bug de cache")
3. Proposer des **mitigations concrètes et applicables**
4. Idéalement contenir un **exemple de code** (before/after)

### 3. Personnaliser les agents pour ton domaine

Les 13 agents sont volontairement **agnostiques domaine** — ils parlent de rôles, d'entités, de stack avec des placeholders. Pour qu'ils soient vraiment pertinents sur ton projet, tu peux ajouter des sections spécifiques :

**Dans `.claude/agents/po-metier.md`**, après `/setup-project` :
- Ajoute une section "Modules / features actuels" avec les pages/modules clés de ton produit
- Si ton domaine a un vocabulaire spécifique (jargon métier), documente-le
- Ajoute des exemples concrets de "bonnes US" et "mauvaises US" sur ton produit

**Dans `.claude/agents/full-stack-lead.md`** :
- Liste les helpers critiques de ton projet avec leur rôle (extrais-les de ton repo)
- Documente les patterns obligatoires (format des handlers API, structure des réponses)
- Liste les fichiers "à manipuler avec précaution" (composants de 500+ lignes, logique métier concentrée)

**Dans `.claude/agents/qa.md`** :
- Liste tes helpers de test (fixtures, mocks, factories)
- Documente les commandes exactes pour chaque niveau de la pyramide
- Pour tout domaine temporel/calendaire : documente les cas limites à tester systématiquement

**Dans `.claude/agents/cso.md`** :
- Liste les endpoints rate-limités avec leurs seuils
- Documente les rôles et permissions matriciellement
- Si RGPD s'applique : documente les tables avec PII et les chemins de purge

### 4. Ajouter un agent spécifique à ton domaine

Si ton projet a une dimension particulière non couverte par les 13 agents standard, crée-en un nouveau.

Exemples réalistes :
- `mobile-ios-lead.md` — expert Swift/SwiftUI + App Store + certificats
- `mobile-android-lead.md` — expert Kotlin/Compose + Play Store + ProGuard
- `ml-ops-engineer.md` — expert MLflow + model registry + A/B testing modèles
- `embedded-systems-lead.md` — expert RTOS + drivers + tests HIL
- `blockchain-architect.md` — expert contracts + audit + gas optimization
- `ui-animation-lead.md` — expert Framer Motion + design motion principles
- `accessibility-auditor.md` — expert WCAG 2.2 + screen readers + axe-core

Base-toi sur `_TEMPLATE-agent.md` pour la structure. N'oublie pas de :
1. Ajouter l'agent à la matrice de routing dans `.claude/skills/tech-lead/SKILL.md` (phase 1)
2. Ajouter l'agent à `docs/EQUIPES-LLM.md`
3. Définir son modèle (Opus pour raisonnement complexe, Sonnet sinon)

### 5. Créer un skill utilitaire répété

Si tu te surprends à refaire une séquence de tâches régulièrement, transforme-la en skill.

Exemples typiques :
- `/daily-standup` — génère un standup depuis `git log --since=yesterday`
- `/update-deps` — lance `npm outdated` + groupe les updates par risque
- `/design-review` — checklist design appliquée à un composant spécifique
- `/perf-profile` — lance un profiler sur une route et produit un rapport

Base-toi sur `_TEMPLATE-skill.md`. Pour qu'il soit invocable via `/<nom>`, ajoute une commande correspondante dans `.claude/commands/<nom>.md`.

### 6. Adapter la répartition Opus/Sonnet à ton plan

Par défaut, les agents les plus lourds en raisonnement sont en Opus (`full-stack-lead`, `cso`, `growth-lead`, `sales-b2b`). Le reste en Sonnet.

Si tu es :
- **Sur API pure** (tu payes chaque token) : passe le maximum en Sonnet, voire Haiku pour certains (`po-metier`, `copywriter-brand`). Réduit les coûts de 3-5×.
- **Sur Max 20x avec usage intense** : tu peux garder tout en Opus pour la qualité, mais surveille le weekly cap.
- **Projet critique / décisions à gros impact** : passe `qa` et `designer-uxui` en Opus aussi (sujets où une erreur coûte cher).

Édite le frontmatter `model: sonnet` → `model: opus` dans le fichier de l'agent concerné.

### 7. Ajouter des "Triggers" pour déclencher des skills automatiquement

Dans le frontmatter de chaque skill, tu peux lister des phrases-clés qui déclenchent le skill quand tu les écris en langage naturel :

```yaml
triggers:
  - orchestre cette feature
  - lance l'équipe
  - fait une feature complète
```

Ajoute les tournures que tu utilises naturellement. Claude Code détecte la phrase et propose d'invoquer le skill.

---

## Cycle d'itération recommandé

Ne cherche pas à tout configurer parfaitement dès le jour 1. Itère :

### Semaine 1
- `/setup-project` pour le gros œuvre.
- Remplis §6 (Architecture) et §7 (Sécurité) du GUIDE-LLM à la main.
- Lance 2-3 features via `/tech-lead` pour valider que la mécanique tourne.

### Semaines 2-4
- Après chaque feature : `/retro` → enrichit §12 avec les pièges rencontrés.
- Ajoute des sections spécifiques aux agents si tu vois qu'ils manquent de contexte métier.
- Supprime les agents que tu n'invoques jamais (bruit dans le routing).

### Mois 2+
- Ajoute un agent spécifique si un domaine récurrent n'est pas couvert.
- Crée un skill utilitaire si tu identifies une séquence répétée.
- Audit : lance `/security-audit` trimestriel, `/audit-funnel` trimestriel si growth.

---

## Erreurs fréquentes à l'adaptation

### 1. Vouloir tout garder
Tentation de garder les 13 agents "au cas où". Résultat : orchestrateur confus, tokens brûlés. **Supprime agressivement** ce qui ne sert pas à ton projet.

### 2. Sous-spécifier le domaine
Si `po-metier.md` ne contient pas les rôles et entités **spécifiques** à ton produit, il rédige des US génériques inutiles. Prends 30 min pour bien le remplir après `/setup-project`.

### 3. Copier un exemple sans réfléchir
Les exemples de chiffres ou de listes dans le kit (ex: "3-5 rôles", "5-10 entités") ne sont pas des vérités gravées. Ajuste à ton projet.

### 4. Oublier `backlog.md`
Fichier à la racine, pas dans `docs/`. Il est **lu en début de session**. Si tu le mets dans `docs/`, le rappel ne se déclenche pas.

### 5. GUIDE-LLM trop long dès le démarrage
Garde 400-500 lignes max au démarrage. §12 se remplit au fil du temps via `/retro`.

### 6. Ne pas tester avec un run à blanc
Lance un `/redige-us` test **avant** de lancer un vrai `/tech-lead`. Si `/redige-us` produit des choses bizarres, `/tech-lead` produira du pire.

### 7. Ignorer les signaux de sur-orchestration
Si `/tech-lead` déclenche 6 agents pour une feature qui aurait pu être faite en 30 min d'`Edit` direct, tu as un problème de routing — soit le skill détecte trop de signaux, soit tu dois apprendre à passer par des skills plus ciblés (`/lead-tech` seul, agent solo).

---

## Références

- [PLACEHOLDERS.md](PLACEHOLDERS.md) — dictionnaire complet des variables
- [CHECKLIST-KICKOFF.md](CHECKLIST-KICKOFF.md) — procédure kickoff pas à pas
- [PATTERNS.md](PATTERNS.md) — patterns méta du système
- [ARCHITECTURE.md](ARCHITECTURE.md) — structure des fichiers + flux
