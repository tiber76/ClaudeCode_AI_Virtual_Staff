# Mettre à jour le kit virtual-staff dans ce projet — prompt à coller

> Fallback non-Node : à utiliser si `npm run update` n'est pas disponible (kit pas cloné, projet sans accès au repo source). Recommandé : `npm run update --target . --apply` depuis le repo cloné.

---

Copie-colle ce prompt dans Claude Code ou OpenAI Codex, **ouvert à la racine du projet à mettre à jour** :

```text
Mets à jour les agents, skills et templates de l'équipe virtuelle dans ce projet.

Objectif : remplacer les fichiers gérés par le kit `virtual-staff-starter-kit`
par leur dernière version, sans toucher au contenu utilisateur.

## Sources

Le kit publie ses fichiers de référence sur :
https://github.com/{{KIT_REPO}}/tree/v{{KIT_VERSION}}/templates

Les hashes attendus sont dans :
https://github.com/{{KIT_REPO}}/blob/v{{KIT_VERSION}}/scripts/manifests/v{{KIT_VERSION}}.json

## Procédure

1. Récupère le manifest v{{KIT_VERSION}} (raw GitHub).
2. Pour chaque chemin listé dans `files`, compare le sha256 local au sha256 du manifest.
3. Classe chaque fichier :
   - `current` (hash identique) → ne rien faire.
   - `missing` (fichier absent) → télécharger le contenu source depuis le repo et écrire.
   - `outdated` (hash différent, mais matche un manifest plus ancien) → backup en `.backup-YYYYMMDD-HHMMSS` puis remplacer.
   - `customized` (hash inconnu) → afficher le diff et **me demander** avant d'écrire.
4. **Ne touche JAMAIS** :
   - `docs/GUIDE-LLM.md`, `docs/EQUIPES-LLM.md`, `docs/COUTS-LLM.md`
   - `.claude/settings.local.json`
   - `backlog.md`
   - Tout fichier qui n'est pas dans le manifest.

## Fichiers concernés (whitelist)

Le manifest liste les chemins kit gérés. En v{{KIT_VERSION}} ils sont typiquement :
- `.claude/agents/*.md`
- `.claude/skills/**/SKILL.md` (+ fichiers internes)
- `.claude/commands/*.md`
- `.codex/agents/*.toml`
- `.agents/skills/**/SKILL.md`
- `AGENTS.md` (racine, si marqueur kit présent)
- `CLAUDE.md` (racine, si marqueur kit présent)
- `docs/formats/*.md`

## Livrable

À la fin, écris `virtual-staff-update-report.md` à la racine du projet :
- Date
- Version cible
- Liste des fichiers touchés (ajout / mise à jour / customisé conservé / customisé écrasé avec backup)
- Tout fichier customisé non remplacé doit être listé pour décision ultérieure.

## Règles de sécurité

- Toujours backup avant écraser un fichier non-current : `<path>.backup-YYYYMMDD-HHMMSS`.
- Mode dry-run par défaut : propose le plan avant d'écrire. Demande "ok pour appliquer ?" avant de patcher.
- Si tu détectes une incohérence dans le manifest (paths absents, hash invalide), stop et signale.

Commence par lire le manifest et lister ce qui changerait. Je validerai avant l'écriture.
```

---

## Variables à remplacer dans ce prompt

| Variable | Valeur | Où la trouver |
|---|---|---|
| `{{KIT_REPO}}` | `<owner>/<repo>` du kit sur GitHub | Cf. ton fork (ex: `your-user/ClaudeCode_AI_Virtual_Staff`) |
| `{{KIT_VERSION}}` | Version cible (ex: `0.4.0`) | `package.json` du kit cloné, ou tag GitHub |

## Rappel

Cette méthode est moins déterministe que `npm run update` (l'AI peut se tromper sur un diff, oublier un fichier, ou rater un cas). Privilégie le script Node sauf si tu n'as pas accès au repo cloné.

Si tu as cloné le kit en local :

```bash
cd /chemin/vers/kit-clone
git pull
node scripts/update.mjs --target /chemin/vers/ton/projet         # dry-run
node scripts/update.mjs --target /chemin/vers/ton/projet --apply # exécute
```
