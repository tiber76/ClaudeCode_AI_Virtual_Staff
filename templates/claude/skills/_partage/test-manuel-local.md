# Test manuel local — l'agent voit la chose marcher, puis le dit

Source unique. `/dev-express`, `/fix-bug`, `/ship-pr`, `/call-tech-lead` et le bloc « Terminé » de `fil-de-progression.md` renvoient ici, ils ne recopient pas la règle.

**Pourquoi** : des tests verts ne disent pas qu'un écran s'affiche et se comporte comme promis. `/verify` vérifie le rendu d'un composant par commit ; ce fichier exige un parcours complet, joué comme le ferait l'utilisateur, et un compte rendu lu en fin de session. Il s'ajoute aux tests unitaires, d'intégration et E2E : il ne remplace aucun d'eux.

## Quand — obligatoire

Un bug ou une US, et tout autre sujet (dette, tâche) dont le diff touche du **code servi par l'application** : composant, page, fichier statique, CSS, route API, helper appelé par une page. Condition propre au test manuel : elle ne suit pas le niveau d'E2E de `/ship-pr` (un diff peut avoir un E2E `aucun` et du code servi).

Diff sans code servi (docs, skills, scripts, config, migration seule) → ligne `Test manuel local : sans objet (<raison>)`. L'absence se dit, elle ne se tait pas.

## Comment

1. **Serveur** : lancer `{{CMD_DEV}}` depuis le worktree courant, via l'outil de preview de la session quand il existe, sinon en arrière-plan. Lire le port réel dans la sortie du serveur. Un serveur déjà lancé ne se réutilise que s'il a été démarré depuis ce worktree ; jamais l'adresse d'un autre dossier (le parcours serait joué sur le code d'un autre).
2. **Navigateur** : un vrai navigateur piloté par la session (volet navigateur intégré, extension navigateur, outil de preview). Aucun navigateur exposé : « non joué (aucun navigateur) », jamais un ✓.
3. **Compte** : un compte de test (variables d'environnement de test du projet, ou compte frais créé pour l'occasion). Jamais un compte réel, jamais la production, jamais une vraie carte. Les valeurs de connexion ne s'écrivent nulle part (chat, commit, PR).
4. **Scénario** : tiré de la note de cadrage (cas de test) ou des critères d'acceptation de l'US, pas inventé après coup. Pour un bug : d'abord reproduire le symptôme du ticket tel que décrit (sur le code d'avant le correctif quand c'est possible), puis constater le comportement corrigé. Pour une US : le parcours nominal de chaque critère, plus un cas d'erreur.
5. **Rôle** : le rôle qui vit le scénario, pas toujours l'administrateur ; un droit refusé se constate avec le rôle refusé.
6. **Relevé** : le texte réel lu à l'écran, l'état de la console du navigateur (zéro erreur nouvelle), au besoin une capture. Un ✓ sans ce relevé n'est pas un ✓.
7. **Captures remises à l'utilisateur** (en session) : chaque capture du relevé est envoyée dans le chat avec une légende (le texte lu à l'écran), **avant** le message final, qui dit combien (`captures envoyées : <n>`). Des images laissées dans un dossier temporaire ne sont pas livrées. Aucune capture prise : le message le dit (`captures envoyées : 0 (<raison>)`).

## Les statuts — jamais d'autre

- **✓ joué et conforme** : scénario, rôle, résultat lu à l'écran, en une ligne.
- **✗ cassé** : ce qui a été vu et où. C'est un défaut du travail livré : correctif (test rouge d'abord si c'est du code applicatif), puis on rejoue. Jamais une PR avec un ✗. Sont des ✗, jamais des « non joué » : l'écran du scénario atteint avec un comportement faux ; l'écran inatteignable à cause du diff (connexion, build, démarrage du serveur, erreur de la page).
- **non joué (<raison>)** : l'écran du scénario est inatteignable pour une cause que le diff n'explique pas : compte de test absent, secret manquant, port occupé, service externe injoignable. La raison est nommée et l'utilisateur reçoit la commande ou le parcours à jouer lui-même. Jamais un ✓ supposé, jamais « à priori ça marche ».
- **sans objet (<raison>)** : diff sans code servi. Jamais utilisé pour une difficulté d'outillage.

Un correctif de review ou de test qui touche du code servi après le test manuel : rejouer le parcours concerné sur le dernier commit, le statut se rapporte au commit qui part.

## Où le statut apparaît

- **Message final** (`✅ Terminé`) : rubrique `**Test manuel local**` juste avant `**Preuves**`, avec le scénario, le rôle, le résultat lu et le nombre de captures envoyées. Les E2E restent dans `Preuves` : deux lignes distinctes.
- **Ligne de statut de la PR** : `test manuel local ✓ (<scénario court>) | ✗ | non joué (<raison>) | sans objet (<raison>)`.
- **TRANSCRIPT** : ligne `Test manuel local :` du gabarit.
- **Body de PR, section « À vérifier »** : les étapes à rejouer par l'utilisateur reprennent ce parcours.

## Ce que ça ne fait pas

- Pas de test manuel de la production ni d'un environnement partagé : local uniquement.
- Pas de remplacement d'un E2E : un parcours qui mérite d'être gardé devient un E2E (`qa`), pas une habitude de test à la main.
- Pas de capture obligatoire dans la PR, sauf changement visible à l'écran.
