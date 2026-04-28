---
name: ship-landing
description: |
  Concevoir et livrer une landing page {{PROJECT_NAME}} complète — wireframe,
  copy hero→FAQ, CTA, proof social, tracking events et UTM. Respecte l'ADN de
  marque ({{TONE_REGISTER}}), zéro mot banni ({{TONE_BANNED_WORDS}}), placeholders
  pour chiffres non disponibles. Produit un fichier Markdown prêt à implémenter
  dans docs/growth/landings/<slug>.md.
---

> Adapter Codex genere depuis le template Claude. Invoquer explicitement avec `$ship-landing` ou laisser Codex le choisir par sa description.
> Les artefacts de run Codex sont attendus sous `.codex/runs/<skill>/<timestamp-slug>/`.
# $ship-landing

## Objectif

Produire une **landing page {{PROJECT_NAME}} complète**, prête à être implémentée par `designer-uxui` + `full-stack-lead`. Cible conversion (signup, démo, lead magnet, selon `{{BUSINESS_MODEL}}`), alignée voice & tone.

## Format d'invocation

```
$ship-landing <besoin> [--type=hero|feature|pricing|comparatif|guide-gate]
```

- `--type=hero` : homepage principale
- `--type=feature` : landing pour une feature précise
{{#IF HAS_PRICING_TIERS}}
- `--type=pricing` : page tarifs
{{/IF}}
- `--type=comparatif` : landing "{{PROJECT_NAME}} vs [concurrent]" ou "{{PROJECT_NAME}} vs [alternative low-tech]"
- `--type=guide-gate` : landing gated pour un lead magnet (guide PDF, benchmark)

Par défaut : détecte le type depuis le besoin.

## Flux

### 1. Recherche contextuelle

- Lit l'ADN marque dans `.codex/agents/copywriter-brand.toml` (voir `{{TONE_REGISTER}}`, `{{TONE_BANNED_WORDS}}`, `{{TONE_SIGNATURE_PHRASES}}`, `{{TONE_EXAMPLES}}`)
- Lit le positionnement dans `.agents/skills/call-growth-lead/SKILL.md`
- Lit les pages existantes pertinentes (homepage, pricing, etc.)
- Identifie l'ICP cible et le stage du funnel (TOFU/MOFU/BOFU)

### 2. Questions minimales (si brief pas fourni)

Max 3 questions :
- ICP cible (segments définis dans le positionnement)
- Offre principale (signup, démo, lead magnet, trial{{#IF HAS_PRICING_TIERS}}, upgrade plan{{/IF}})
- Preuve sociale disponible (logos, verbatim, chiffres client ou placeholder)

### 3. Génère la landing

Format markdown structuré, sauvegardé dans `docs/growth/landings/<slug>.md`.

### 4. Auto-review par copywriter-brand

Si invoqué via `$call-growth-lead`, l'agent `copywriter-brand` produit. Sinon, le skill invoque l'agent en tool Agent pour valider le ton (`{{TONE_REGISTER}}`, zéro mot de `{{TONE_BANNED_WORDS}}`).

## Template landing standard

```markdown
# Landing : <titre>

**Slug** : <slug>
**Type** : <hero|feature|pricing|comparatif|guide-gate>
**ICP cible** : <segment>
**Stage funnel** : <TOFU / MOFU / BOFU>
**Objectif conversion** : <signup / demo / lead magnet / upgrade>
**Date** : <YYYY-MM-DD>

---

## 📦 Meta

```
<title>...</title>
<meta name="description" content="..."> (140-160 car)
<meta property="og:title" content="...">
<meta property="og:description" content="...">
<meta property="og:image" content="...">
<link rel="canonical" href="<url canonique>">
```

**Mots-clés cible** (3-5) : <liste>

---

## 🎯 Hero

**Eyebrow** (≤ 30 car) : <label court>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

**Headline H1** (≤ 12 mots, 1 ligne sur desktop) : <headline>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

**Sub-headline** (≤ 30 mots) : <sub>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`). Doit inclure la proposition de valeur + éventuelle levée de friction (gratuité essai, pas de CB, etc.).

**CTA primary** : <texte bouton>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

**CTA secondary** : <texte bouton>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

**Visuel hero** : screenshot réel produit (pas mockup générique)
> Capturer une vue clé du produit avec data seed représentative.

**Trust bar sous hero** :
- `<À remplir en prod : volumes d'usage réels, ex nombre d'utilisateurs actifs, volume traité>`

---

## 🏆 Social proof bar

**Logos clients** (6 max, cohérents par secteur) : `<placeholder : logos à ajouter quand clients signés>`

**Verbatim court** (1 ligne percutante) :
> "<verbatim>" — <Prénom + rôle + boîte>
> Exemple placeholder : `<À remplir : verbatim client>`

---

## 🔥 Problem agitation (3 bullets)

### Headline section
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`) — phrase qui nomme le problème central que résout {{PROJECT_NAME}}.

### Bullets
1. **<douleur 1>** : <1 phrase factuelle>
2. **<douleur 2>** : <…>
3. **<douleur 3>** : <…>

> Exemples à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

---

## ✨ Solution (3 colonnes feature → benefit)

### Headline section
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`) — promesse produit en une phrase.

### Colonne 1 — <feature>
**Icône** : <suggestion>
**Titre** : <3-5 mots>
**Description** (2-3 lignes) : <benefit oriented user>
**Preuve** : <benchmark ou chiffre client>
> Si pas de chiffre client validé : `<À mesurer en prod : métrique cible>`.

### Colonne 2 — <feature>
[idem]

### Colonne 3 — <feature>
[idem]

---

## 📊 Proof (étude de cas ou benchmark)

### Headline section
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

### Bloc étude de cas
**Avant** : <situation initiale + douleur chiffrée>
> `<Client X>` : <contexte + métrique de douleur>.

**Après** : <situation finale + chiffre>
> `<Client X>` : <résultat + métrique de gain>.

**Verbatim** :
> "<verbatim>" — <sponsor>
> `<À remplir : verbatim client autorisé>`

**CTA secondaire** : "Lire l'étude de cas complète"

---

## ⚖️ Comparatif (optionnel selon type)

| | **Alternative low-tech** | **Concurrent direct** | **{{PROJECT_NAME}}** |
|---|---|---|---|
| <critère différenciant 1> | ❌ / ⚠️ | ❌ / ⚠️ | ✅ |
| <critère différenciant 2> | ❌ | ⚠️ | ✅ |
| <critère différenciant 3> | ❌ | ❌ | ✅ |
| Prix | <coût caché> | <€/user> | <€/user> |

> Lister uniquement les critères **pertinents pour l'ICP** ; pas de longue liste exhaustive.

---

{{#IF HAS_PRICING_TIERS}}
## 💰 Pricing teaser (si pas page pricing dédiée)

**À partir de** : **<€> / user / mois** (plan <tier d'entrée>)
**Essai** : `<TRIAL_DURATION>` — <conditions essai>.
**CTA** : "Voir tous les plans"

---
{{/IF}}

## ❓ FAQ (6-8 questions, objections sales)

> Chaque réponse doit respecter `{{TONE_REGISTER}}` et ne jamais employer un mot de `{{TONE_BANNED_WORDS}}`.

**1. Est-ce que {{PROJECT_NAME}} remplace [outil existant du persona] ?**
> Réponse factuelle : positionnement complémentaire ou substitution, avec % de clients qui gardent l'outil existant si pertinent.

**2. Combien de temps pour prendre l'outil en main ?**
> Durée onboarding self-service + offre formation si applicable.

**3. <question spécifique ICP primaire>**
> Réponse ancrée sur une feature signature.

**4. Quelles intégrations ?**
> `<À remplir en prod : liste intégrations dispos. Sinon : "Au roadmap Q<N>. On documente l'avancement.">`

{{#IF HAS_RGPD}}
**5. Est-ce que nos données sont en Europe ?**
> Hébergement + conformité RGPD documentée, DPA sur demande.
{{/IF}}

{{#IF IS_B2B}}
**6. Comment ça marche le plan Enterprise / tier haut ?**
> SSO, SLA, support dédié, onboarding sur-mesure, custom pricing.
{{/IF}}

{{#IF HAS_PRICING_TIERS}}
**7. Essai gratuit, c'est vraiment sans engagement ?**
> Conditions de l'essai (CB ou pas, durée, ce qui se passe à la fin).

**8. Et après l'essai ?**
> Choix du plan (`{{PRICING_PLANS_LIST}}`) + modalités de paiement. Ou arrêt sans surprise.
{{/IF}}

---

## 🎯 Final CTA

**Headline** : <phrase clôture>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`) — reprend le bénéfice principal.

**Sub** : <levée de friction finale>
> Exemple à adapter au ton ADN (voir `{{TONE_EXAMPLES}}`).

**CTA primary** : <texte bouton>
**CTA secondary** : <texte bouton>

---

## 📡 Tracking & UTM

**Events à tracker** :
- `landing_viewed` : path, utm_*, device, referrer
- `cta_primary_clicked` : cta_location (hero / middle / bottom)
- `cta_secondary_clicked` : cta_location
- `faq_opened` : question_id
- `scroll_depth_reached` : 25/50/75/100
- `signup_started` : from_landing=<slug>

**UTM conventions** pour campagnes entrantes :
- `utm_source=<google|linkedin|newsletter|outbound|partner>`
- `utm_medium=<cpc|organic|email|social|referral>`
- `utm_campaign=<slug-campagne>`
- `utm_content=<variant-a|variant-b>`

---

## 🧪 A/B test suggestions (2 max)

| Variant A | Variant B | Hypothèse | Métrique primaire |
|---|---|---|---|
| Headline "Question" | Headline "Contrast" | <raison> | Taux conversion visit → signup |
| CTA <version 1> | CTA <version 2> | <raison> | Click-through rate CTA |

---

## ✅ Checklist qualité (review copywriter-brand)

- [ ] Zéro mot banni (voir `{{TONE_BANNED_WORDS}}`)
- [ ] Phrases ≤ 20 mots
- [ ] Preuves sociales placeholders clairement marqués `<À remplir>`
- [ ] FAQ couvre les 6 objections principales de l'ICP
- [ ] CTA primary cohérent hero + milieu + bottom
- [ ] Meta description 140-160 car, inclut mot-clé + bénéfice
- [ ] Tracking plan events + UTM défini
- [ ] Canonical URL définie
- [ ] Open Graph + Twitter Card défini

---

## 🛠️ Handoff implémentation

**Pour `designer-uxui`** :
- Respecte le design system du projet (voir `{{DESIGN_SYSTEM_NAME}}` si défini)
- Composants réutilisables à privilégier
- Visual hero : screenshot réel produit

**Pour `full-stack-lead`** :
- Page front dans la structure de routage du projet (`{{STACK_FRAMEWORK_FRONTEND}}`)
- Événements tracking : instrumenter via helper analytics central
- Schema Article + FAQ + BreadcrumbList (SEO)
- Performance : LCP < 2.5s (optim images WebP, font preload)

**Pour `marketing-analytics`** :
- Valider tracking plan + UTM conventions
- Configurer dashboard suivi conversions
```

## Règles absolues

- ❌ **Jamais publier** la landing. Ce skill produit un markdown, `full-stack-lead` implémente, l'humain décide du déploiement.
- ❌ **Jamais fabriquer** un chiffre {{PROJECT_NAME}}. Placeholder `<À remplir en prod>` obligatoire.
- ❌ **Jamais utiliser** un mot de `{{TONE_BANNED_WORDS}}`.
- ✅ Références concurrents OK sur comparatifs, factuelles uniquement.

## Anti-patterns

- ❌ Landing avec 5+ CTA différents → 1 primary + 1 secondary max par section
- ❌ FAQ < 6 questions → objections non couvertes
- ❌ Hero sans visuel produit réel → risque abstraction
- ❌ Tournures vagues ("nos experts", "notre solution")
- ❌ Stock photo au lieu de screenshot
- ❌ Tracking plan absent → landing publiée = data perdue
- ❌ Meta description absente ou dupliquée

## Référence

- `.codex/agents/copywriter-brand.toml` — ton, mots bannis, templates
- `.codex/agents/designer-uxui.toml` — design system
- `.codex/agents/marketing-analytics.toml` — tracking plan
- `.agents/skills/call-growth-lead/SKILL.md` — positionnement
- `docs/growth/landings/` — landings existantes

## 💰 Coût indicatif

Tokens : ~80-200k brut · ~30-60k effective (avec prompt caching 90%)
Équivalent API : ~$0.4-1
Détail complet et optimisations : `docs/COUTS-LLM.md`.
