# Checklist — Mise en place sur un nouveau projet

Checklist pas à pas pour installer le starter kit sur un projet sans contexte préalable. Compte **~2-4h** pour une installation soignée (la plupart du temps passe à remplir le GUIDE-LLM et à adapter les agents au domaine).

---

## Phase 1 — Pré-requis (15 min)

- [ ] Ton projet est un repo git.
- [ ] Tu utilises Claude Code (ou l'Agent SDK équivalent).
- [ ] Tu as un plan Claude Max (le kit suppose un quota généreux — sur API pure, ajuste la répartition Opus/Sonnet vers Sonnet partout).
- [ ] Tu as `gh` CLI installé (`brew install gh` si besoin) pour les PR.
- [ ] Ton projet a au minimum **deux branches** : `main` (prod, protégée) et `develop` (intégration). Si pas encore le cas : `git checkout -b develop && git push -u origin develop`.

---

## Phase 2 — Copie des fichiers (10 min)

- [ ] Depuis la racine de ton nouveau projet :
  ```bash
  cp -r /chemin/vers/starter-kit-equipes-claude/templates/claude ./.claude
  cp -r /chemin/vers/starter-kit-equipes-claude/templates/docs ./docs
  cp /chemin/vers/starter-kit-equipes-claude/templates/backlog.template.md ./backlog.md
  ```

- [ ] Vérifie la structure finale :
  ```
  ton-projet/
  ├── .claude/
  │   ├── agents/           ← 13 fichiers .md
  │   ├── skills/           ← 15 dossiers avec SKILL.md
  │   ├── commands/         ← 15 fichiers .md (redirections vers skills)
  │   └── settings.local.json
  ├── backlog.md
  └── docs/
      ├── GUIDE-LLM.md
      ├── EQUIPES-LLM.md
      ├── COUTS-LLM.md
      └── formats/
  ```

- [ ] Ajoute au `.gitignore` (si pas déjà présent) :
  ```
  .claude/tech-lead-runs/
  .claude/growth-lead-runs/
  ```

---

## Phase 3 — Remplissage du GUIDE-LLM (60-90 min)

C'est **l'étape la plus importante**. Le GUIDE-LLM est lu à chaque session — il doit refléter ton projet fidèlement.

Ouvre `docs/GUIDE-LLM.md` et remplis chaque section :

- [ ] **§0 Git flow** : confirme `develop` comme branche par défaut, règles de merge, hotfix.
- [ ] **§1 Clean code** : adapte aux conventions de ton langage (camelCase/snake_case, limites fichier/fonction).
- [ ] **§2 Refactorisation** : garde les principes génériques.
- [ ] **§3 Performance** : liste tes règles perf DB/frontend (index, requêtes, optim).
- [ ] **§4 Tests** : renseigne ton framework (Jest, Vitest, Pytest, RSpec…) + les commandes exactes (`npm test`, `pnpm test`, `pytest`…).
- [ ] **§5 Avant commit** : checklist que tu veux imposer avant tout commit.
- [ ] **§6 Architecture** : décris la structure de dossiers de ton projet + patterns obligatoires (auth, erreurs, validation).
- [ ] **§7 Sécurité** : liste les secrets, les endpoints sensibles, le rate-limit, l'auth, la 2FA si applicable.
- [ ] **§8 UX/UI** : ton éditorial, langue UI, a11y, z-index, CSP si web.
- [ ] **§9 Déploiement** : comment tu déploies (Vercel, Fly.io, Docker…).
- [ ] **§10 Architecture spécifique** : si ton projet a des patterns métier particuliers (architecture non standard, invariants data, règles métier critiques), documente-les ici. Sinon laisse vide.
- [ ] **§11 IA** : si tu utilises Claude / OpenAI / autres, documente l'infra (budget guard, prompt caching, validator, scrub PII).
- [ ] **§12 Pièges connus** : vide au démarrage. Se remplit via `/retro` au fur et à mesure.

**Règle d'or** : si tu hésites sur une règle, mets-la — quitte à la retirer plus tard. Un guide trop permissif produit du code médiocre.

---

## Phase 4 — Adaptation des agents (45 min)

Chaque agent contient des placeholders qui doivent être remplis. Ouvre `.claude/agents/*.md` un par un :

### Agents tech

- [ ] **po-metier.md** : vérifie que les rôles utilisateurs listés correspondent à ton produit. Liste tes entités métier principales (celles qui structurent le domaine). Documente ton ton éditorial dans le GUIDE-LLM §8.
- [ ] **full-stack-lead.md** : remplace la stack (Next.js 16 + Supabase + vanilla JS) par la tienne. Liste les helpers critiques de ton projet (`lib/auth`, `lib/db`, etc.). Ajoute les pièges spécifiques détectés.
- [ ] **designer-uxui.md** : documente ton design system (palette, typographie, composants UI, règles d'accessibilité). Si tu n'as pas de DS, mets les 4 états obligatoires (empty/loading/error/success) comme base.
- [ ] **qa.md** : renseigne ton framework (Jest, Playwright, Cypress, Pytest…), tes commandes exactes, ta pyramide (unit/integration/E2E).
- [ ] **cso.md** : liste les endpoints auth, 2FA, RGPD, audit, rate-limit si applicable à ton domaine.
- [ ] **data-engineer.md** : si ton projet a une dimension data (KPI, agrégations, ETL), documente-les. Sinon, simplifie.
- [ ] **ai-llm-engineer.md** : si tu n'utilises pas Claude/LLM dans ton produit, **supprime cet agent**. Sinon, adapte à ta stack IA.

### Agents growth

- [ ] **growth-lead.md** : positionnement, ICP, funnel, canaux principaux.
- [ ] **sales-b2b.md** : si tu es B2C, **supprime cet agent** ou remplace par `sales-b2c`.
- [ ] **customer-success.md** : décris ton onboarding, tes moments de vérité, tes canaux de support.
- [ ] **copywriter-brand.md** : voice & tone, mots bannis, mots signatures.
- [ ] **content-seo.md** : mots-clés cibles, audiences, distribution.
- [ ] **marketing-analytics.md** : tes sources de tracking (GA4, Segment, Mixpanel…), tes KPI growth.

### Règle de simplification

**Si un agent ne sert à rien sur ton projet, supprime-le.** N'essaie pas de tout garder. Les agents inutiles polluent le routing de l'orchestrateur.

Exemples :
- Pas d'IA produit → supprime `ai-llm-engineer.md`.
- Produit B2C (pas de sales cycle) → supprime `sales-b2b.md`.
- Pas d'agrégations data → fusionne `data-engineer.md` dans `full-stack-lead.md`.

---

## Phase 5 — Adaptation des skills (30 min)

Les skills `/tech-lead` et `/growth-lead` contiennent une matrice de routing qui référence les agents. Si tu as supprimé des agents phase 4 :

- [ ] Ouvre `.claude/skills/tech-lead/SKILL.md` :
  - Dans la section "L'équipe virtuelle", retire les agents que tu as supprimés.
  - Dans la section "Phase 1 — Routing", retire les lignes de la matrice qui font référence à ces agents.
  - Met à jour la section "Répartition Opus/Sonnet".

- [ ] Même chose pour `.claude/skills/growth-lead/SKILL.md`.

- [ ] Les autres skills (`/redige-us`, `/ship-pr`, etc.) référencent le GUIDE-LLM avec des paragraphes `§X`. Vérifie que les numéros de section correspondent à ton GUIDE-LLM rempli phase 3.

---

## Phase 6 — Configuration des commandes (5 min)

Les fichiers dans `.claude/commands/*.md` sont des raccourcis qui redirigent vers les skills. Vérifie que chacun existe :

```bash
ls .claude/commands/*.md
# Doit contenir : tech-lead.md, growth-lead.md, redige-us.md, lead-tech.md,
# investigate-bug.md, review-pr.md, qa-flow.md, ship-pr.md, security-audit.md,
# retro.md, redige-brief.md, ship-landing.md, audit-funnel.md, brief-demo.md,
# retro-campagne.md
```

Si un skill a été supprimé phase 5, supprime sa commande correspondante.

---

## Phase 7 — Premier run de test (15 min)

Lance un petit run pour valider que tout tourne :

1. Ouvre Claude Code à la racine de ton projet.
2. Vérifie qu'il charge bien le GUIDE-LLM en début de session (il doit mentionner "Backlog : ... en attente").
3. Lance :
   ```
   /tech-lead "Ajoute un bouton 'Exporter CSV' dans la vue X qui déclenche un téléchargement du listing courant" --mode=semi
   ```
4. Observe le déroulé :
   - Phase 0 : affichage du coût estimé.
   - Phase 1 : routing (quels agents).
   - Phase 2 : PO rédige l'US → checkpoint validation.
   - Phase 3 : round 1 (avis indépendants en parallèle).
   - Phase 4 : débats.
   - Phase 5 : plan final → checkpoint validation.
   - Phase 6 : implémentation.
   - Phase 7 : review + QA.
   - Phase 8 : PR (mais pas de merge).

5. Si ça bloque quelque part → lis l'erreur, corrige l'agent/skill concerné, relance.

---

## Phase 8 — Rituels de capitalisation (continu)

- [ ] Après chaque feature non-triviale → `/retro` pour capitaliser les leçons.
- [ ] À chaque nouveau piège identifié → propose un ajout au GUIDE-LLM §12.
- [ ] À chaque dette technique détectée → ajoute une entrée dans `backlog.md`.
- [ ] Trimestriel → `/audit-funnel` côté growth, audit manuel côté tech.
- [ ] Mensuel → `/security-audit` pour balayer les régressions sécu.

---

## Checkpoint final — Tu es prêt quand...

- [ ] Le GUIDE-LLM reflète ton projet (plus aucun placeholder `{{...}}` non résolu).
- [ ] Tous les agents gardés sont remplis (pas de placeholder `{{…}}` oublié).
- [ ] Un `/tech-lead` de test a produit une PR ouverte sans erreur.
- [ ] Un `/retro` de test a proposé un ajout au GUIDE-LLM §12 (même fictif).
- [ ] `backlog.md` existe avec une entrée fictive pour valider le rappel en début de session.

À partir de là : tu utilises le kit au quotidien sur ton projet.
