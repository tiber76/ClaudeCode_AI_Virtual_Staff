#!/usr/bin/env bash
# Auto-test de review-gate.sh : la porte exige un rapport valable pour le sha de HEAD, au bon palier.
# Lancer : bash .codex/hooks/review-gate.test.sh
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR
GATE="$(cd "$(dirname "$0")" && pwd)/review-gate.sh"
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

PUSH_CMD="git -C $W push origin work"
# gate <attendu> <commande> <libellé> : joue la porte sur un payload PreToolUse
gate() {
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

echo "Hors périmètre"
nouvelle_branche
echo more >> "$W/README.md"; G commit -qam doc
gate 0 "git status"                                 "commande sans push ignorée"
gate 0 "git -C $W push origin --delete work"        "suppression de branche ignorée"
gate 0 "git -C $W push --tags"                      "push de tags ignoré"

echo "Rapport absent ou invalide"
gate 2 "$PUSH_CMD"                                  "aucun rapport : bloqué"
gate 2 "gh pr create --title x"                     "ouverture de PR sans rapport : bloquée"
rapport docs non;     gate 2 "$PUSH_CMD"            "verdict « non » : bloqué"
rapport docs "oui (à voir)"; gate 2 "$PUSH_CMD"     "verdict « oui (…) » : bloqué"
rapport docs oui;     gate 0 "$PUSH_CMD"            "docs + oui : passe"
bash "$GATE" --verdict "$W/.codex/reviews/$(G rev-parse HEAD).md" && ok "--verdict rejoue la grammaire (exit 0)" || bad "--verdict" "devait rendre 0"

echo "Rapport d'un autre commit"
OLD=$(G rev-parse HEAD)
echo more >> "$W/README.md"; G commit -qam doc2
cp "$W/.codex/reviews/$OLD.md" "$W/.codex/reviews/$(G rev-parse HEAD).md"
gate 2 "$PUSH_CMD"                                  "ligne HEAD d'un autre sha : bloqué"

echo "Palier"
nouvelle_branche
mkdir -p "$W/src/auth"; echo "x = 1" > "$W/src/auth/login.js"; G add -A; G commit -qm auth
rapport docs oui;     gate 2 "$PUSH_CMD"            "chemin sensible relu au palier docs : bloqué"
rapport leger oui;    gate 2 "$PUSH_CMD"            "chemin sensible relu au palier leger : bloqué"
rapport complet oui;  gate 0 "$PUSH_CMD"            "chemin sensible relu au palier complet : passe"
nouvelle_branche
echo more >> "$W/README.md"; G commit -qam doc
rapport complet oui;  gate 0 "$PUSH_CMD"            "palier supérieur au calcul : passe"
rapport vide oui;     gate 2 "$PUSH_CMD"            "palier inconnu : bloqué"

echo "Branche de correctif"
nouvelle_branche fix/bug
mkdir -p "$W/src"; echo "x = 1" > "$W/src/a.js"; G add -A; G commit -qm fix
rapport leger oui;    gate 2 "git -C $W push origin fix/bug" "fix/* sans preuve inversée : bloqué"
SHA=$(G rev-parse HEAD)
printf '# Preuve\n\n- **HEAD** : %s\n\nVerdict : ok\n' "$SHA" > "$W/.codex/reviews/fix-proof-${SHA:0:7}.md"
gate 0 "git -C $W push origin fix/bug"              "fix/* avec preuve valable : passe"

echo "Bypass"
nouvelle_branche
echo more >> "$W/README.md"; G commit -qam doc
gate 2 "$PUSH_CMD"                                  "sans rapport : bloqué"
G commit -q --amend -m "doc" -m "SKIP-review-pr sur instruction de l'utilisateur"
gate 0 "$PUSH_CMD"                                  "SKIP-review-pr en début de ligne : passe"
G commit -q --amend -m "doc" -m "on ne doit pas écrire SKIP-review-pr au milieu d'une phrase"
gate 2 "$PUSH_CMD"                                  "simple mention de la convention : bloqué"

echo "Payload illisible"
printf 'pas du json git push' | bash "$GATE" >/dev/null 2>&1; [ $? = 2 ] && ok "payload illisible ressemblant à un push : fermé" || bad "payload illisible" "devait rendre 2"
printf 'pas du json' | bash "$GATE" >/dev/null 2>&1; [ $? = 0 ] && ok "payload illisible sans push : ignoré" || bad "payload illisible" "devait rendre 0"

echo; echo "review-gate : $PASS ok, $FAIL en échec"
[ "$FAIL" = 0 ]
