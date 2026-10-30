#!/usr/bin/env bash
# Auto-test de review-gate.sh : un commit ne part qu'avec un rapport valable pour son sha, au bon palier ;
# le hook PreToolUse empêche de désactiver le hook git et juge HEAD avant une ouverture de PR.
# Lancer : bash .codex/hooks/review-gate.test.sh
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR
HOOKS="$(cd "$(dirname "$0")" && pwd)"
GATE="$HOOKS/review-gate.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1 — $2"; }

W="$TMP/w"
G() { git -C "$W" -c user.email=t@t -c user.name=t "$@"; }
git init -q --bare -b develop "$TMP/o.git"
git clone -q "$TMP/o.git" "$W" 2>/dev/null
G checkout -q -b develop
echo base > "$W/README.md"; G add README.md; G commit -q -m base; G push -q origin develop
echo ".codex/" >> "$W/.git/info/exclude"

# commit_gate <attendu> <libellé> [branche] : juge HEAD comme le ferait le hook pre-push
commit_gate() {
  local want="$1" label="$2" br="${3:-$(G branch --show-current)}" rc
  bash "$GATE" --commit "$W" "$(G rev-parse HEAD)" "$br" >/dev/null 2>"$TMP/err"; rc=$?
  if [ "$rc" = "$want" ]; then ok "$label"; else bad "$label" "exit $rc au lieu de $want ($(head -c 200 "$TMP/err"))"; fi
}
# hook <attendu> <commande> <libellé> : joue le mode PreToolUse
hook() {
  local want="$1" cmd="$2" label="$3" rc
  jq -n --arg c "$cmd" --arg d "$W" '{tool_input:{command:$c},cwd:$d}' | bash "$GATE" >/dev/null 2>"$TMP/err"; rc=$?
  if [ "$rc" = "$want" ]; then ok "$label"; else bad "$label" "exit $rc au lieu de $want ($(head -c 200 "$TMP/err"))"; fi
}
# rapport <niveau> <verdict> : écrit le rapport du HEAD courant
rapport() {
  local sha sha7; sha=$(G rev-parse HEAD); sha7=${sha:0:7}
  mkdir -p "$W/.codex/reviews"
  {
    echo "# Review — work"; echo
    echo "**HEAD** : \`$sha7\`"
    echo "**Niveau** : $1 (calculé : test)"
    echo; echo "## Verdict"
    echo "- **Prêt pour \`/ship-pr\`** : $2"
    echo "- **À trancher** : 0"
  } > "$W/.codex/reviews/$sha.md"
}
nouvelle_branche() { G checkout -q develop; G branch -q -D "${1:-work}" 2>/dev/null; G checkout -q -b "${1:-work}"; }

echo "Commit jugé (mode --commit, celui du hook pre-push)"
nouvelle_branche
commit_gate 0 "commit déjà dans la base : passe sans rapport"
echo more >> "$W/README.md"; G commit -qam doc
commit_gate 2 "aucun rapport : bloqué"
rapport docs non;            commit_gate 2 "verdict « non » : bloqué"
rapport docs "oui (à voir)"; commit_gate 2 "verdict « oui (…) » : bloqué"
rapport docs oui;            commit_gate 0 "docs + oui : passe"
bash "$GATE" --verdict "$W/.codex/reviews/$(G rev-parse HEAD).md" && ok "--verdict rejoue la grammaire (exit 0)" || bad "--verdict" "devait rendre 0"
OLD=$(G rev-parse HEAD)
echo more >> "$W/README.md"; G commit -qam doc2
cp "$W/.codex/reviews/$OLD.md" "$W/.codex/reviews/$(G rev-parse HEAD).md"
commit_gate 2 "ligne HEAD d'un autre sha : bloqué"

echo "Palier"
nouvelle_branche
mkdir -p "$W/src/auth"; echo "x = 1" > "$W/src/auth/login.js"; G add -A; G commit -qm auth
rapport docs oui;     commit_gate 2 "chemin sensible relu au palier docs : bloqué"
rapport leger oui;    commit_gate 2 "chemin sensible relu au palier leger : bloqué"
rapport complet oui;  commit_gate 0 "chemin sensible relu au palier complet : passe"
nouvelle_branche
echo more >> "$W/README.md"; G commit -qam doc
rapport complet oui;  commit_gate 0 "palier supérieur au calcul : passe"
rapport vide oui;     commit_gate 2 "palier inconnu : bloqué"

echo "Branche de correctif"
nouvelle_branche fix/bug
mkdir -p "$W/src"; echo "x = 1" > "$W/src/a.js"; G add -A; G commit -qm fix
rapport leger oui;    commit_gate 2 "fix/* sans preuve inversée : bloqué"
commit_gate 2 "poussée vers une destination fix/* depuis une autre branche : preuve exigée" fix/autre
SHA=$(G rev-parse HEAD)
printf '# Preuve\n\n- **HEAD** : %s\n\nVerdict : ok\n' "$SHA" > "$W/.codex/reviews/fix-proof-${SHA:0:7}.md"
commit_gate 0 "fix/* avec preuve valable : passe"

echo "Bypass"
nouvelle_branche
echo more >> "$W/README.md"; G commit -qam doc
commit_gate 2 "sans rapport : bloqué"
G commit -q --amend -m "doc" -m "SKIP-review-pr: sur instruction de l'utilisateur"
commit_gate 0 "SKIP-review-pr: <raison> en début de ligne : passe"
G commit -q --amend -m "doc" -m "on ne doit pas écrire SKIP-review-pr au milieu d'une phrase"
commit_gate 2 "simple mention de la convention : bloqué"
G commit -q --amend -m "doc" -m "SKIP-review-pr est réservé aux instructions humaines"
commit_gate 2 "phrase qui commence par la convention : bloqué"
G commit -q --amend -m "doc"

echo "Hook PreToolUse"
hook 0 "git status"                                   "commande sans push ignorée"
hook 0 "docker push registry/app"                     "push d'un autre outil ignoré"
hook 2 "git push origin work"                         "hook git absent : push refusé, installation demandée"
hook 2 "\\git push origin work"                        "\\git push sans hook git : refusé"
(cd "$W" && bash "$HOOKS/install-git-hooks.sh" >/dev/null) && ok "install-git-hooks pose le hook" || bad "install-git-hooks" "devait rendre 0"
hook 0 "git push origin work"                         "hook git branché : le push est laissé au hook git"
hook 0 "GIT=git; \$GIT push origin \$(git branch --show-current)" "forme dynamique : laissée au hook git"
hook 2 "git push --no-verify origin work"             "--no-verify refusé"
hook 2 "git -c core.hooksPath=/dev/null push"         "git -c core.hooksPath refusé"
hook 2 "git config core.hooksPath /tmp/vide"          "git config core.hooksPath refusé"
hook 2 "GIT_CONFIG_COUNT=1 git push"                  "GIT_CONFIG_* refusé"
hook 2 "rm .git/hooks/pre-push && git push"           "push qui touche au fichier du hook : refusé"
hook 2 "gh pr create --title x"                       "ouverture de PR sans rapport : bloquée"
hook 2 "cd $W && gh pr create --title x"              "cd <dépôt> && gh pr create : jugé"
rapport docs oui
hook 0 "gh pr create --title x"                       "ouverture de PR avec rapport : passe"
hook 2 "git -C $W commit -qam x && gh pr create"      "commit puis ouverture de PR dans le même appel : refusé"

echo "Payload illisible"
printf 'pas du json git push' | bash "$GATE" >/dev/null 2>&1; [ $? = 2 ] && ok "payload illisible ressemblant à un push : fermé" || bad "payload illisible" "devait rendre 2"
printf 'pas du json' | bash "$GATE" >/dev/null 2>&1; [ $? = 0 ] && ok "payload illisible sans push : ignoré" || bad "payload illisible" "devait rendre 0"

echo; echo "review-gate : $PASS ok, $FAIL en échec"
[ "$FAIL" = 0 ]
