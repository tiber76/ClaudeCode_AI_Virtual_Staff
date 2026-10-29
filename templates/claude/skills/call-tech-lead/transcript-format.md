# TRANSCRIPT.md — format de `/call-tech-lead`

> Document compagnon du `SKILL.md`, chargé à l'init du TRANSCRIPT (Phase 0) puis à chaque mise à jour de phase. Mis à jour **incrémentalement** : on peut suivre le run avec `tail -f .claude/call-call-tech-lead-runs/<run>/TRANSCRIPT.md`.

## Discipline append-only — jamais de `Read` + `Write` complet

Pattern **interdit** : lire tout le TRANSCRIPT, le modifier mentalement, le réécrire. Sur un run long il atteint 30-50 k tokens et serait relu 8-10 fois.

Pattern **obligatoire** : le TRANSCRIPT initial se termine par un marker unique, et chaque update est un `Edit` qui remplace le marker par `<nouvelle phase>` suivie du marker.

```markdown
<!-- END_OF_TRANSCRIPT - ne pas supprimer, marker append-only -->
```

Aucun `Read` n'est nécessaire. Besoin de relire une décision passée : `Read` ciblé (`offset` + `limit`) sur la section.

## Format

```markdown
# TRANSCRIPT — <titre US> — run du <timestamp>

**Mode** : auto | semi · **Depth** : lean | standard | full
**Branches** : {{GIT_PREFIX_FEATURE}}<slug> (provisoire), {{GIT_PREFIX_FEATURE}}<slug>-Tn
**Agents convoqués** : <liste>
**Démarrage / Fin / Durée totale** : <HH:MM:SS> / <HH:MM:SS> / XmYs
**PR** : <urls> · **Coût estimé** : ~Xk tokens (~$Y)

---

## 📥 Phase 0 — Input
> <besoin verbatim>
Décisions : branche, mode, depth, bascule `/dev-express` écartée (raison).

## 🎯 Phase 1 — Routing
Analyse (3-5 lignes) · agents convoqués · agents exclus + raison · signal commercial détecté (même sans escalade).

## 📝 Phase 2 — US
Extrait 5-10 lignes + tableau des tranches · [Détail : `02-us.md`]
Checkpoint semi : ✅ validé / 🔧 modifiée / ⛔ stoppé.

## 💬 Phase 3 — Round 1
Un bloc par agent (« <agent> dit : » + 3-5 lignes + points saillants). QA : couverture proposée (N tests, répartition unit/intégration/E2E).

## ⚔️ Phase 4 — Débats (ou « Phase 4 sautée — convergence forte »)
Par débat : ouverture, réponse, contre, **✅ Décision tech-lead**.

## 📐 Phase 5 — Plan final
Architecture · UX/UI · Sécurité · Tests · Migration ({{DIR_MIGRATIONS}} ou « aucune ») · Tranches et effort · Hypothèses à lever au smoke réel.
Checkpoint semi : ✅ / 🔧 / ⛔.

## 🛠️ Phase 6 — Implémentation (par tranche)
| Tranche | Worker (modèle) | Commits | Tests | /verify | Passes de review | HEAD |
Pour chaque tranche, un paragraphe **« ce que ça change, en clair »** (texte vu à l'écran, exemple chiffré ; pas de jargon).
Boucle de correction : findings, conception du correctif, résultat. Boucle preview interrompue (si cap atteint) : itérations, raison, décision.

## ✅ Phase 7 — QA & sécu (par tranche)
- Review : rapport `<sha7>`, N passes, 🔴 X / 🟠 Y · N à trancher
- `cso` passe finale : ✅ / ⛔ (raison), modèle réellement passé à l'appel
- Tests unit + intégration : ✅ / ❌ · E2E (niveau calculé : aucun | specs | smoke) : ✅ <sha7>
- Test manuel local : ✓ <scénario, rôle, ce qui s'affiche> | ✗ <quoi, corrigé en <sha7>> | non joué (raison) | sans objet (raison)

## 🚀 Phase 8 — PR
URL · base {{GIT_DEFAULT_BRANCH}} · Mergée : ❌ NON (sauf ordre explicite) · merge de Tn avant Tn+1.

## 📊 Synthèse
Durée, tokens, escalades utilisateur (N), auto-arbitrages (M), itérations de correction (K).
Prochaines étapes : migration à jouer par l'utilisateur ({{DIR_MIGRATIONS}}), vérification manuelle de la PR, « merge la PR » pour lancer le merge, `/retro` après merge, liste de fin de session (dettes repérées, à décider).

<!-- END_OF_TRANSCRIPT - ne pas supprimer, marker append-only -->
```

## Synthèse coût — footer obligatoire

```markdown
## 📊 Synthèse coût
- Tokens totaux : ~Xk (entrée, sortie, cache lu, cache écrit) · Équivalent API : ~$Y
- Par agent (avec le modèle **réellement passé** à l'appel : c'est la trace qui rend un oubli visible) :
  full-stack-lead, full-stack-worker (par tranche), cso (Round / passe finale), qa, po-metier, … : ~Xk (~$Y)
- Durée totale : <MmSs>
```

Ordre de grandeur (à remesurer sur le projet) : le pipeline de review et les workers de tranche pèsent l'essentiel ; les rounds d'avis ~20-30 % ; l'orchestrateur ~10 %. Leviers sans baisse de qualité : `--depth=lean` quand le risque est faible, Round 2 sauté sans friction, contexte précis en entrée, scope d'agents explicite (« skip cso, aucun signal sécurité »), référence à une US/un plan existant plutôt que de repartir de zéro, `/fullstack-lead-tech` seul si l'US est claire et sans débat à mener. Trace systématiquement `depth`, agents invoqués et Round 2 lancé/non lancé.

**Quand le jeu en vaut la chandelle** : feature complexe (> 1 h de conception seul), qui touche sécurité + données + UI, ou utilisateur absent (mode auto). Pas pour un bug trivial, une typo ou un refacto mineur : le skill refuse.
