---
name: brief-demo
description: |
  {{#IF IS_B2B}}
  Prépare une démo personnalisée {{PROJECT_NAME}} pour un prospect B2B : recherche
  prospect/entreprise, scénario démo adapté à son ICP, 3 moments de vérité,
  objections anticipées, next step qualifié. Produit un dossier dans
  docs/growth/demos/<prospect>.md. Invoquer avant chaque démo importante, ou pour
  construire un template démo par ICP.
  {{/IF}}
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$brief-demo` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
{{#IF IS_B2B}}

# $brief-demo

## Objectif

Produire un **brief démo actionnable** pour un prospect B2B : qui il est, ce qui le fait bouger, ce qu'on lui montre (pas tout), ce qu'on lui demande, comment on close le next step.

**Règle absolue** : une démo réussie = **3 messages clés, 3 démonstrations, 3 questions**, pas un "tour du produit".

## Format d'invocation

```
$brief-demo <prospect> [--icp=<segment>] [--sector=<secteur>]
```

Exemples :
- `$brief-demo "<Entreprise cible>, <taille>, <localisation>"`
- `$brief-demo "<Entreprise cible>, <rôle DM>, <taille>, <secteur>" --icp=<segment>`

## Flux

### 1. Recherche prospect

- **WebSearch** / **WebFetch** : LinkedIn public, site corporate, actualité récente (financement, acquisition, expansion, annonce stratégique).
- Identifier :
  - **Taille équipe cible** (nombre d'utilisateurs potentiels du produit)
  - **Secteur + spécificités** (volumes, cycles métier, tension)
  - **Stack supposée** (outils existants, intégrations potentielles)
  - **Signaux d'intérêt** (posts LinkedIn, annonces publiques, jobs ouverts sur rôles proches du produit)
  - **Décision-maker (DM) probable** + parcours (LinkedIn)
  - **Champion potentiel** (utilisateur opérationnel influent)

**Règle** : 20-30 min de recherche max. Si pas d'info publique, documenter ("no public data, à demander en discovery").

### 2. Qualification ICP

Remplir :

| Dimension | Valeur prospect | Signal |
|---|---|---|
| ICP | <segment défini dans le positionnement {{PROJECT_NAME}}> | — |
| Taille équipe cible | <X users> | — |
{{#IF HAS_PRICING_TIERS}}
| Plan cible | <tier de `{{PRICING_PLANS_LIST}}`> | — |
{{/IF}}
| ARPA estimé | <€/mois> | — |
| Cycle vente attendu | <2-6 sem / 1-3 mois / 3-9 mois> | — |

### 3. Identification des 3 douleurs probables

Priorisées par probabilité (basée sur recherche + ICP) :

1. **<Douleur #1>** : <phrase ancrée sur le quotidien du DM cible>
2. **<Douleur #2>** : <phrase>
3. **<Douleur #3>** : <phrase>

### 4. Scénario démo — 3 moments de vérité

**Durée cible** : 30 min segment entry / 45 min segment mid / 60 min segment high-touch (dont 20% Q/R minimum).

#### Moment 1 — "Le moment quotidien" (10-15 min)

**Message clé** : "Voici ce que vous gagnez dans votre routine <journalière/hebdo>."

**Démo** :
1. Ouvrir l'écran principal avec data seed contextuelle au prospect
2. Montrer la **feature usage quotidien** (la plus utilisée)
3. Ouvrir la **vue synthèse / reporting** qui répond à la question principale du DM

**Story** : phrase courte qui contraste "aujourd'hui chez eux" vs "avec {{PROJECT_NAME}}", ancrée sur une douleur concrète.

**À éviter** : la longue explication du modèle de données.

#### Moment 2 — "La feature signature ICP" (10-15 min)

Pour chaque segment ICP défini dans le positionnement {{PROJECT_NAME}}, lister la **feature signature** qui répond à sa douleur #1.

**Démo ciblée sur la douleur principale** du segment.

**Question posée** : "Comment vous faites ça aujourd'hui ? Combien de temps ça vous prend ?"

#### Moment 3 — "Le moment décisif" (5-10 min)

Adapter au segment ICP :
- Segment entry : la feature "plus" qui finit de convaincre
- Segment mid : le calcul ROI explicite
- Segment high-touch : sécurité, conformité, intégrations (voir `{{#IF HAS_RGPD}}RGPD{{/IF}}` et SSO si applicable)

**Question posée** : "Ça répond à quoi chez vous ?"

### 5. Objections anticipées (top 3)

Basées sur ICP + contexte prospect. Voir `.codex/agents/sales-b2b.toml` pour la liste complète.

**Top 3 à préparer** :

| Objection probable | Réponse | Proof à montrer |
|---|---|---|
| "On a déjà [outil concurrent/alternative]" | <positionnement : remplace / complète, avec chiffre client si dispo> | Comparatif |
| "C'est trop cher" | <payback en <N> mois via <métrique>> | Calculette ROI ou chiffre client |
| "Prouvez-moi que ça marche" | <offre d'essai / pilote selon `{{BUSINESS_MODEL}}`> | Essai/pilote immédiat |

### 6. Questions à poser (discovery dans la démo)

**3-5 questions MEDDPICC obligatoires** :

1. **Metrics** : "Quel KPI vous suivez aujourd'hui sur <domaine du produit> ?"
2. **Economic Buyer** : "Qui valide l'investissement outil chez vous ?"
3. **Decision Process** : "Si on est bon, c'est quoi les étapes ?"
4. **Pain** : "Combien de temps/argent ça coûte à votre équipe, actuellement ?"
5. **Champion** : "Qui serait l'utilisateur principal au quotidien ?"

### 7. Next step cible

**Règle** : une démo qui finit sans next step précis = démo ratée.

**Options de next step par segment ICP** :
- **Segment entry** : closing immédiat si `{{BUSINESS_MODEL}}` le permet (essai/signup direct)
- **Segment mid** : pilote cadré sur <N> users / <N> jours
- **Segment high-touch** : atelier multi-stakeholders (sécurité / ops / décideurs) avec 3 créneaux proposés

### 8. Sauvegarde

Dossier `docs/growth/demos/<prospect-slug>.md`.

## Template brief démo complet

```markdown
# Brief démo — <Nom prospect>

**Date démo** : <YYYY-MM-DD>
**Durée** : <30|45|60 min>
**Format** : <visio | sur place>
**Préparation** : <date>
**Auteur** : sales-b2b (via $brief-demo)

---

## 🏢 Fiche prospect

**Nom** : <…>
**Secteur** : <…>
**Taille** : <…>
**Localisation** : <…>
**Actualité récente** : <…>
**Site** : <url>
**LinkedIn entreprise** : <url>

---

## 👤 Interlocuteurs attendus

| Nom | Rôle | Décideur | Champion probable | Lien LinkedIn |
|---|---|---|---|---|
| <…> | <rôle DM> | ✅ | — | <…> |
| <…> | <rôle champion> | — | ✅ | <…> |

---

## 🧠 Hypothèses ICP & pain

**ICP** : <segment>
{{#IF HAS_PRICING_TIERS}}
**Plan cible** : <tier>
{{/IF}}
**ARPA estimé** : <€/mois>

**3 douleurs probables** :
1. <…>
2. <…>
3. <…>

---

## 🎬 Scénario démo — 3 moments

### Moment 1 — <titre>
- Durée : <X min>
- Message clé : <…>
- Démo : <étapes>
- Question : <…>

### Moment 2 — <titre>
[idem]

### Moment 3 — <titre>
[idem]

---

## 🛡️ Top 3 objections attendues

| Objection | Réponse préparée | Proof à dégainer |
|---|---|---|
| <…> | <…> | <…> |

---

## ❓ Discovery obligatoire (MEDDPICC in-démo)

**5 questions à poser** :
1. <…>
2. <…>
3. <…>
4. <…>
5. <…>

---

## 🎯 Next step cible

**Option A (closing)** : <…>
**Option B (fallback)** : <…>

---

## ✅ Checklist préparation

- [ ] Data seed chargée (cohérente avec leur secteur)
- [ ] Vocabulaire adapté (leur taxonomie interne)
- [ ] 2 proofs à portée (étude de cas + comparatif)
{{#IF HAS_RGPD}}
- [ ] Slide bonus sécurité / conformité (RGPD, SSO) si segment high-touch
{{/IF}}
- [ ] Calendly next step ouvert dans un onglet
- [ ] Enregistrement démo (si autorisé)

---

## 📝 Post-démo (à remplir après)

**Date** : <…>
**Qualification MEDDPICC** :
- M : <…>
- E : <…>
- D (criteria) : <…>
- D (process) : <…>
- P : <…>
- I (pain) : <…>
- C (champion) : <…>
- C (competition) : <…>

**Next step pris** : <…>
**Quote probable** : <…%> de closing
**Actions prévues** : <liste>
```

## Règles

- ❌ **Jamais publier** les notes de recherche prospect (données perso/public mais sensibles)
- ❌ **Jamais inventer** une preuve {{PROJECT_NAME}} (chiffre client, logo)
- ❌ **Jamais dépasser** 3 moments en démo → "feature dump" = démo ratée
- ✅ Personnalisation visible (vocabulaire, data seed adaptée, question sur leur contexte)
- ✅ Question > affirmation : la démo est un dialogue

## Anti-patterns

- ❌ Démo qui balance 10+ features → recadre 3 moments
- ❌ Démo sans question au prospect → monologue
- ❌ Démo sans next step → pas de closing
- ❌ Démo avec data seed générique → prépare data contextuelle
- ❌ Démo sans préparation ICP (même script pour tous les segments) → déjà perdu

## Référence

- `.codex/agents/sales-b2b.toml` — méthodo MEDDPICC, objections types
- `.codex/agents/customer-success.toml` — handoff post-signature
- `.agents/skills/call-growth-lead/SKILL.md` — positionnement
- `docs/growth/demos/` — briefs existants

## 💰 Coût indicatif

Tokens : ~80-200k brut · ~30-60k effective (avec prompt caching 90%)
Équivalent API : ~$0.4-1
Détail complet et optimisations : `docs/COUTS-LLM.md`.

{{/IF}}
