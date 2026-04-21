# Contribuer au Starter Kit — Équipes virtuelles Claude Code

Merci de vouloir améliorer ce kit. Quelques principes pour que les contributions restent cohérentes.

---

## Philosophie du kit

Ce kit est **opinionated par design**. Les choix structurants (orchestrateur multi-agents, TRANSCRIPT, backlog racine, garde-fous git, répartition Opus/Sonnet) sont le résultat de plusieurs mois d'itération sur un projet réel. Ils ne sont pas négociables sans discussion.

En revanche, **tout** peut être amélioré : clarté de la doc, portabilité des placeholders, qualité des agents, couverture de patterns nouveaux.

---

## Ce qui est bienvenu

### Issues
- Bug dans le skill `/setup-project` (placeholder non résolu, bloc conditionnel incorrect).
- Incohérence entre un agent et le GUIDE-LLM template.
- Retour d'adoption : "j'ai utilisé le kit sur un projet X, voici ce qui a coincé".
- Idée de nouvel agent pour un domaine non couvert (mobile, embarqué, ML ops, etc.).
- Idée de nouveau skill utilitaire.

### Pull requests
- Correction de typo / bug / placeholder manquant.
- Ajout d'un agent nouveau (respect du format de `_TEMPLATE-agent.md`).
- Ajout d'un skill nouveau (respect du format de `_TEMPLATE-skill.md`).
- Amélioration de la doc méta (README, PATTERNS, REGLES, etc.).
- Ajout de traductions (si tu veux porter le kit en anglais).

---

## Ce qui n'est PAS bienvenu

- Pull requests qui réintroduisent du contexte spécifique d'un projet (nom d'entreprise, stack hardcodée, domaine métier hardcodé).
- Pull requests qui cassent les garde-fous git absolus (§0 REGLES-TRANSVERSES).
- Pull requests qui augmentent massivement la complexité sans apporter de valeur (sur-engineering).
- Pull requests qui ajoutent des dépendances lourdes (le kit est pensé "zero dependency").

---

## Workflow de contribution

1. **Ouvre une issue** avant de coder quoi que ce soit de substantiel. Ça évite de produire 500 lignes qui ne matchent pas la vision.
2. **Fork + branche dédiée** (`feat/xxx`, `fix/xxx`, `docs/xxx`).
3. **Teste ton changement** sur un projet vide : copie le kit, lance `/setup-project`, vérifie que ça tourne.
4. **Respecte le format des agents/skills** : frontmatter YAML cohérent, structure H2/H3, ton direct, sections standards.
5. **Mets à jour `PLACEHOLDERS.md`** si tu introduis un nouveau placeholder.
6. **Pull request** avec :
   - Description claire du problème résolu.
   - Référence à l'issue correspondante.
   - Screenshots ou extraits de TRANSCRIPT si pertinent.

---

## Tester un changement localement

Le kit n'a pas de test suite automatisée (c'est du markdown + YAML). Le test de référence, c'est :

```bash
# 1. Crée un projet vide
mkdir /tmp/test-project && cd /tmp/test-project
git init

# 2. Copie le kit
cp -r <chemin-kit>/templates/claude ./.claude
cp -r <chemin-kit>/templates/docs ./docs
cp <chemin-kit>/templates/backlog.template.md ./backlog.md

# 3. Renomme les templates
mv .claude/settings.template.json .claude/settings.local.json
mv docs/GUIDE-LLM.template.md docs/GUIDE-LLM.md
mv docs/EQUIPES-LLM.template.md docs/EQUIPES-LLM.md
mv docs/COUTS-LLM.template.md docs/COUTS-LLM.md

# 4. Ouvre Claude Code et lance
/setup-project

# 5. Vérifie qu'il n'y a plus de placeholder non résolu
grep -r "{{" .claude/ docs/ | grep -v ".template.md" | grep -v "{{#IF"
# Résultat attendu : vide
```

---

## Style de rédaction

### Agents et skills
- Ton **à la 2e personne** ("Tu es...", "Tu dois...").
- **Direct, concret, tranché**. Pas de "on pourrait", "il serait intéressant".
- **Pas d'emojis** sauf cas très spécifiques (délimiteurs de phases dans TRANSCRIPT).
- **Exemples concrets** > théorie abstraite.

### Documentation méta
- Ton **neutre et informatif**.
- **Exemples génériques** (pas d'exemple spécifique à un projet).
- **Tables et listes** > paragraphes longs quand c'est possible.

### Commits
- Format : `<type>(<scope>): <description>` (ex: `feat(agents): add mobile-ios-lead`)
- Types : `feat`, `fix`, `refactor`, `docs`, `chore`
- Pas de commit "WIP" ou "fix" seul.

---

## Code de conduite

- **Respect mutuel**. Discussions techniques franches, jamais personnelles.
- **Feedback constructif**. Si tu critiques une décision, propose une alternative.
- **Transparence**. Dis ce que tu ne sais pas, ne prétends pas le contraire.

---

## Questions

Ouvre une issue avec le label `question`. Ce n'est pas un forum, mais les questions aident à identifier ce qui manque dans la doc.
