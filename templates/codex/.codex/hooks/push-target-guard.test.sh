#!/usr/bin/env bash
# Auto-test de push-target-guard.sh : prouve que le garde regarde la DESTINATION des références poussées.
# Lancer : bash .codex/hooks/push-target-guard.test.sh
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR
GUARD="$(cd "$(dirname "$0")" && pwd)/push-target-guard.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1 — $2"; }

# Dépôt jetable sur la branche de travail « feature/x ».
REPO="$TMP/repo"; mkdir -p "$REPO"
git -C "$REPO" init -q -b feature/x
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

# Mode 1 : payload PreToolUse. attendu = 0 (laisse passer) ou 2 (bloque).
hook() { # hook <attendu> <commande> <libellé>
  local want="$1" cmd="$2" label="$3" rc
  jq -n --arg c "$cmd" --arg d "$REPO" '{tool_input:{command:$c},cwd:$d}' | bash "$GUARD" >/dev/null 2>"$TMP/err"; rc=$?
  if [ "$rc" = "$want" ]; then ok "$label"; else bad "$label" "exit $rc au lieu de $want ($(cat "$TMP/err"))"; fi
}
echo "Mode PreToolUse"
hook 0 "git push origin feature/x"                "branche de travail explicite passe"
hook 0 "git push"                                  "sans référence, branche courante de travail passe"
hook 0 "git push -u origin HEAD"                   "HEAD = branche de travail passe"
hook 0 "git push origin --delete feature/x"        "suppression d'une branche de travail passe"
hook 0 "git status"                                "commande sans push ignorée"
hook 2 "git push origin main"                      "destination main bloquée"
hook 2 "git push origin develop"                   "destination develop bloquée"
hook 2 "git push origin feature/x:develop"         "src:dst vers develop bloqué"
hook 2 "git push origin HEAD:refs/heads/main"      "refs/heads/main bloqué"
hook 2 "git push origin :develop"                  "suppression de develop bloquée"
hook 2 "git push --force origin +main"             "force sur main bloqué"
hook 2 "git push --all origin"                     "--all bloqué"
hook 2 "git push --mirror origin"                  "--mirror bloqué"
hook 2 "echo ok && git push origin DEVELOP"        "casse ignorée, segment enchaîné"
hook 2 "git -C $REPO push origin main"             "git -C <dir> push main bloqué"
git -C "$REPO" checkout -q -b main
hook 2 "git push"                                  "sans référence, branche courante protégée bloquée"
git -C "$REPO" checkout -q feature/x

# Mode 2 : lignes de pre-push. attendu = la ligne de verdict (et exit 0, une seule ligne).
A=1111111111111111111111111111111111111111; B=2222222222222222222222222222222222222222
NUL=0000000000000000000000000000000000000000
pre() { # pre <attendu> <entrée> <libellé>
  local want="$1" input="$2" label="$3" out rc
  out=$(printf '%s' "$input" | bash "$GUARD" 2>"$TMP/err"); rc=$?
  if [ "$rc" = 0 ] && [ "$out" = "$want" ] && [ ! -s "$TMP/err" ]; then ok "$label"; else bad "$label" "« $out » (exit $rc) au lieu de « $want »"; fi
}
echo "Mode pre-push"
pre "verifie 1"  "refs/heads/feature/x $A refs/heads/feature/x $NUL"$'\n'  "création d'une branche de travail"
pre "bloque develop" "refs/heads/feature/x $A refs/heads/develop $B"$'\n' "destination develop"
pre "bloque main"    "refs/heads/feature/x $A refs/heads/MAIN $B"$'\n'    "destination main (casse)"
pre "rien 1"     "(delete) $NUL refs/heads/feature/x $B"$'\n'              "effacement d'une branche de travail"
pre "bloque develop" "(delete) $NUL refs/heads/develop $B"$'\n'            "effacement de develop"
pre "verifie 1"  "refs/heads/x $A refs/tags/develop $NUL"$'\n'             "un tag nommé develop n'est pas la branche"
pre "muette ligne 1 non conforme : 4 champs attendus, shas en 40 ou 64 caractères hexa" "refs/heads/x zzz refs/heads/y $B"$'\n' "ligne non conforme"
pre "bloque develop" "refs/heads/a $A refs/heads/a $NUL"$'\n'"refs/heads/b $A refs/heads/develop $B"$'\n' "develop en 2ᵉ position gagne"
pre "verifie 0"  ""                                                       "entrée vide : on ne sait pas, portes jouées"

echo; echo "push-target-guard : $PASS ok, $FAIL en échec"
[ "$FAIL" = 0 ]
