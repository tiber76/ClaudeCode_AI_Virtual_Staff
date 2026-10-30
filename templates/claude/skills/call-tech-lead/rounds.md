# Rounds 1 & 2 — détail des phases 3 et 4 de `/call-tech-lead`

> Document compagnon du `SKILL.md`, à lire avant la Phase 3. `<abs>` = chemin absolu du checkout du run.

---

## Phase 3 — Round 1 : avis indépendants (en parallèle)

Pour **chaque agent convoqué sauf le PO** (déjà intervenu), plusieurs appels `Agent` dans le même message.

**Modèle** : `cso` est lancé avec `model: "sonnet"` explicite en Round 1 comme en Round 2 (sa passe finale de Phase 6 est en Opus) ; les autres agents gardent le modèle de leur frontmatter.

Prompt type :

> « Lis l'US : `<abs>/.claude/call-call-tech-lead-runs/<run-id>/02-us.md` (chemin absolu instancié, pas le placeholder). Donne ton avis depuis ton rôle : risques, contraintes, propositions, points à challenger chez les autres experts. **Cite des fichiers existants avec lignes exactes (`fichier.ext:L42-55`)** quand tu proposes de modifier du code existant — sans ligne exacte, c'est une hypothèse à vérifier. Budget : `lean` 200 mots, `standard` 300, `full` 450 (le plus restrictif entre mots et tokens). Format structuré (bullets). »

**Interdit** : injecter le contenu de `02-us.md` dans le prompt. Chaque agent le lit via `Read` ; l'injection dupliquerait l'US × N dans le contexte parent.

### Spécificités par agent

#### `qa` — le brief oracle

Le brief du Round 1 est l'**oracle** que le dev consulte pendant toute la Phase 6 (le QA n'écrit PAS les tests acceptance/intégration, le dev les écrit en TDD). Donc **maximum de clarté dès le départ** : pas de « à préciser plus tard ». Cas réellement ambigu : `AskUserQuestion` à l'utilisateur en Round 1, pas un report en Phase 6.

Tableau de couverture US → tests, sections **obligatoires selon le routing** (le mandat dit « sections obligatoires : … ; SKIP : … avec raison », gain typique 20-30 %) :

| Section | Quand obligatoire | Quand SKIP |
|---|---|---|
| A. Cas nominaux | toujours | jamais |
| B. Cas alternatifs (rôles/permissions) | toujours | jamais |
| C. Cas d'erreur (validation, 4xx) | toujours | jamais |
| D. Cas limites (volumes, données extrêmes) | toujours | jamais |
| E. Concurrence / race | si écriture en base | feature en lecture seule |
| F. UI/UX (dimensions, états visuels) | si `designer-uxui` ou `integrateur` convoqué | feature back-only |
| G. IA (prompts, parsers, hallucination) | si `ai-llm-engineer` convoqué | aucune IA |
| H. Injection / sécurité des entrées | si `cso` convoqué OU entrée utilisateur persistée | refacto interne pur |

Règles du mandat :
- **Chaque cas inscrit en B, C, D, H cite le `fichier:ligne` du code qui implémente le comportement attendu.** Sans cible identifiable → drapeau « cas hors architecture actuelle, vérifier en Phase 5 » plutôt qu'un oracle qui prescrit un comportement absent du code (faux trous détectés en Phase 6, tests inventés qui passent sans rien valider).
- Composant UI > 100 lignes : « quelles fonctions pures extraites et testables sans DOM ? ».
- Test E2E qui clique un élément par identifiant : identifier la vue parente par recherche dans le code ; si elle n'est pas active par défaut, activer l'onglet/la vue **avant** l'assertion.
- Test E2E qui dépend d'un drapeau calculé côté serveur à partir de données : tracer la chaîne `rôle → donnée en base → drapeau → prop UI → rendu` et exiger la fixture dédiée ; ne pas supposer que le rôle implique la donnée.
- Feature visuelle : au moins une assertion de dimension (taille utilisable) en plus de la visibilité (« structure présente ≠ utilisable »).
- Un test E2E qui enregistre recharge, rouvre et relit la valeur ; il ne vérifie pas ce qu'il vient d'écrire.
- **Relecture du lot final** : si une décision a réduit le scope en cours de run, le mandat cite les sections qui s'appliquent à la PR partielle et celles reportées ; sans ce cadrage la QA signale des cas hors scope comme bloquants.

#### `full-stack-lead`

- **Questions fermées, faits fournis, effort borné** : ≈ 5 questions fermées, les faits que l'orchestrateur a déjà (chemins, lignes, décisions) collés dans le mandat, un repère de ≈ 25 actions — au-delà, il répond avec ce qu'il a et nomme ce qu'il n'a pas vérifié. Un ordre de grandeur prouvé par une ligne de code vaut un comptage exhaustif.
- Handler POST qui renvoie une entité pour rafraîchir une liste/un sélecteur : **mise à jour optimiste synchrone** avant tout refetch (sinon race garantie en E2E).
- Refonte UI qui **double une classe legacy en compatibilité** : inventaire **exhaustif** des règles CSS héritées par recherche dans `{{DIR_STYLES}}` (tableau classe | fichier:ligne | règle | conflit possible), étendu aux classes redéfinies par les dernières PR. Sinon le layout casse silencieusement.
- Migration d'un mount conditionnel (script legacy → composant) : chercher où le conteneur est **réellement** rendu avant le verdict ; JSX inline qui coexiste = drapeau P0 « plus complexe que prévu ».

#### `data-engineer`

Mandat **élargi** : audit d'efficience du module touché (requêtes, routes, cache existants) en plus du surcoût du nouveau scope ; challenge le legacy ET dit ce qui est déjà optimal (à ne pas re-proposer).
{{#IF HAS_DESIGN_SYSTEM}}

#### `designer-uxui`

Sujet visuel subjectif : « produis 2-3 variantes descriptibles en preview côte à côte (pas de code définitif), l'utilisateur tranche avant la Phase 6 ».

#### `integrateur`

« Recherche exhaustive des classes, tokens et composants existants réutilisables ; tableau inventaire (élément | existe ? | fichier:ligne | action) ; signale tout token manquant au designer ; propose le découpage avec le full-stack-lead (qui prend markup+CSS, qui prend logique+handlers, hooks DOM explicites). »
{{/IF}}
{{#IF HAS_AI_FEATURE}}

#### `ai-llm-engineer`

Mandat : scrub des données personnelles, sorties structurées (le mécanisme officiel, pas une config décorative), seuils de confiance, synchro validateur ↔ lexique du prompt, budget guard, chaînage inter-rapports.
{{/IF}}

### Sortie

Chaque avis → `03-round1-<agent>.md`. TRANSCRIPT : extrait de 3-5 lignes par avis sous `### Round 1 — avis <agent>`.

---

## Phase 4 — Round 2 : challenges croisés (facultatif)

### Règle de skip — convergence forte

Le tech-lead évalue 4 critères : (1) **architecture** : pas de divergence sur le découpage technique ; (2) **sécurité** : `cso` sans bloquant Critique/Élevé ; (3) **sémantique** : accord sur les contrats de données ; (4) **brief QA cadré** : aucun cas « à préciser plus tard ». **Les 4 remplis → Round 2 sauté**, fusion Phases 4+5 ; le TRANSCRIPT le dit (« Phase 4 sautée — convergence forte sur archi/sécu/sémantique/brief ») et `04-round2-debates.md` porte « Aucune friction actionnable » + 3-5 lignes de justification. Au moins un critère KO → Round 2 **uniquement sur les points de divergence**, jamais sur les consensus.

`--depth=lean` : Round 2 seulement pour une friction bloquante ou un risque sécurité/données/IA ; sinon une note de synthèse sans redéléguer.

### Débats sur frictions

Exemples de frictions : le CSO veut un rate-limit strict, le PO objecte un usage massif légitime ; le designer veut un modal plein écran, le dev signale un blocage du scroll mobile ; la donnée veut une agrégation SQL, le QA la juge dure à mocker.

Pour chaque friction :
1. Délègue à l'agent A (même `model` qu'en Round 1) : « L'agent B dit : `<avis B>`. Tu as dit : `<ton avis>`. Challenge ou concède : 150 mots. **Si ta réponse implique de modifier du code existant, cite les lignes exactes que tu as lues. Sans ligne exacte, c'est une hypothèse non vérifiée : lis AVANT de répondre.** Si un compromis est possible, propose-le. »
2. Même prompt inversé à l'agent B.
3. **Vérification factuelle du tech-lead** : pour toute reco qui touche du code existant, lis le fichier cité. Reco déjà en place (reco fantôme) → supprimée du plan, pas de travail inutile.
4. **Croisement intra-agent** : avant d'arbitrer, relis tous les findings du même agent et cherche les contradictions mutuelles (un CSO qui produit une rafale de findings peut en avoir un qui nie l'hypothèse d'un autre) ; les traiter ensemble. Un agent qui invoque la « défense en profondeur » sans citer le scénario concret qu'elle protège dans le modèle actuel : défense périmée, on simplifie.
5. Synthèse dans `04-round2-debates.md` :

```markdown
## Débat N — <titre>
**<agent A>** ouvre : > <avis initial>
**<agent B>** répond : > <challenge ou concession>
**<agent A>** contre-réponse : > <...>
**✅ Décision tech-lead** : <arbitrage clair avec justification>
```

### Escalade

- `semi` : désaccord persistant après 2 rounds sur un point Critique → `AskUserQuestion` à l'utilisateur.
- `auto` : le tech-lead tranche seul et le consigne : « Auto-arbitrage sans escalade : <raison> ».

TRANSCRIPT : débats complets sous `## ⚔️ Phase 4 — Débats`.
