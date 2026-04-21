---
name: nom-skill
description: |
  Description courte qui aide Claude à décider quand invoquer ce skill.
  Mentionne : ce que ça fait, quand invoquer, quel livrable produit.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent              # si le skill orchestre d'autres agents
  - AskUserQuestion    # si le skill peut poser des questions
triggers:
  - mot-clé 1
  - mot-clé 2
  - mot-clé 3
---

# /nom-skill

## Objectif
{{OBJECTIF_EN_UNE_PHRASE}}. Livrable unique : {{FICHIER_OU_ACTION}}.

## Quand l'utiliser
- {{CAS_USAGE_1}}
- {{CAS_USAGE_2}}
- {{CAS_USAGE_3}}

## Format d'invocation (si arguments)

```
/nom-skill <argument> [--flag=valeur]
```

## Garde-fous absolus (cf. GUIDE-LLM §0)

- ❌ {{REGLE_1}}
- ❌ {{REGLE_2}}
- ✅ {{CE_QUI_EST_AUTORISE}}

## Principes

1. **{{PRINCIPE_1}}**
2. **{{PRINCIPE_2}}**
3. **{{PRINCIPE_3}}**

## Étapes

### 1. {{ETAPE_1_TITRE}}
{{ETAPE_1_DETAIL}}

```bash
{{COMMANDE_EVENTUELLE}}
```

### 2. {{ETAPE_2_TITRE}}
{{ETAPE_2_DETAIL}}

### 3. {{ETAPE_3_TITRE}}
{{ETAPE_3_DETAIL}}

### N. Sauvegarde / Sortie
- Déterminer un slug kebab-case depuis {{SOURCE_SLUG}}.
- Écrire le fichier {{CHEMIN_SORTIE}}.
- Afficher le chemin + extrait dans la réponse.

## Format de sortie attendu

```markdown
# <titre du livrable>

<structure complète du format>
```

## Anti-patterns à éviter
- ❌ {{ANTI_1}}
- ❌ {{ANTI_2}}
- ❌ {{ANTI_3}}

## Référence GUIDE-LLM
- §X ({{SECTION_1}})
- §Y ({{SECTION_2}})

## 💰 Coût indicatif

Tokens : ~{{TOKENS_BRUT}}k brut · ~{{TOKENS_EFFECTIVE}}k effective (avec prompt caching)
Équivalent API : ~${{COUT_API}}
Détail complet : `docs/COUTS-LLM.md`.
