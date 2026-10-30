#!/usr/bin/env bash
# Auto-test de push-target-guard.sh : prouve que le garde regarde la DESTINATION des références poussées.
# Lancer : bash .claude/hooks/push-target-guard.test.sh
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR
GUARD="$(cd "$(dirname "$0")" && pwd)/push-target-guard.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1 — $2"; }

# Dépôt jetable : le hook git tourne depuis le dépôt.
REPO="$TMP/repo"; mkdir -p "$REPO"
git -C "$REPO" init -q -b feature/x
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

A=1111111111111111111111111111111111111111; B=2222222222222222222222222222222222222222
NUL=0000000000000000000000000000000000000000
pre() { # pre <attendu> <entrée> <libellé> [dépôt]
  local want="$1" input="$2" label="$3" out rc
  out=$(cd "${4:-$REPO}" && printf '%s' "$input" | bash "$GUARD" 2>"$TMP/err"); rc=$?
  if [ "$rc" = 0 ] && [ "$out" = "$want" ] && [ ! -s "$TMP/err" ]; then ok "$label"; else bad "$label" "« $out » (exit $rc) au lieu de « $want » ($(head -c 200 "$TMP/err"))"; fi
}
pre "verifie 1"  "refs/heads/feature/x $A refs/heads/feature/x $NUL"$'\n'  "création d'une branche de travail"
pre "bloque develop" "refs/heads/feature/x $A refs/heads/develop $B"$'\n' "destination develop"
pre "bloque main"    "refs/heads/feature/x $A refs/heads/MAIN $B"$'\n'    "destination main (casse)"
pre "bloque master"  "HEAD $A refs/heads/master $B"$'\n'                  "destination master (défaut)"
pre "rien 1"     "(delete) $NUL refs/heads/feature/x $B"$'\n'              "effacement d'une branche de travail"
pre "bloque develop" "(delete) $NUL refs/heads/develop $B"$'\n'            "effacement de develop"
pre "verifie 1"  "refs/heads/x $A refs/tags/develop $NUL"$'\n'             "un tag nommé develop n'est pas la branche"
pre "muette ligne 1 non conforme : 4 champs attendus, shas en 40 ou 64 caractères hexa" "refs/heads/x zzz refs/heads/y $B"$'\n' "ligne non conforme"
pre "bloque develop" "refs/heads/a $A refs/heads/a $NUL"$'\n'"refs/heads/b $A refs/heads/develop $B"$'\n' "develop en 2ᵉ position gagne"
pre "verifie 0"  ""                                                       "entrée vide : on ne sait pas, portes jouées"

# Base résolue protégée par défaut : un dépôt dont la branche par défaut du remote est « trunk ».
TRUNK="$TMP/trunk"
git init -q --bare -b trunk "$TMP/t.git"
git clone -q "$TMP/t.git" "$TRUNK" 2>/dev/null
git -C "$TRUNK" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$TRUNK" push -q origin HEAD:trunk 2>/dev/null
git -C "$TRUNK" remote set-head origin trunk >/dev/null 2>&1
pre "bloque trunk" "refs/heads/x $A refs/heads/trunk $B"$'\n' "base résolue (trunk) protégée par défaut" "$TRUNK"

echo; echo "push-target-guard : $PASS ok, $FAIL en échec"
[ "$FAIL" = 0 ]
