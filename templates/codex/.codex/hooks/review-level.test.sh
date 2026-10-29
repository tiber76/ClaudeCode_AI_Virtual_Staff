#!/usr/bin/env bash
# Auto-test de review-level.sh : le palier suit le diff (vide | docs | leger | complet).
# Lancer : bash .codex/hooks/review-level.test.sh
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR
LEVEL="$(cd "$(dirname "$0")" && pwd)/review-level.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1 — $2"; }

G() { git -C "$TMP/w" -c user.email=t@t -c user.name=t "$@"; }
git init -q --bare -b develop "$TMP/o.git"
git clone -q "$TMP/o.git" "$TMP/w" 2>/dev/null
G checkout -q -b develop
echo base > "$TMP/w/README.md"; G add README.md; G commit -q -m base; G push -q origin develop

# palier <libellé> <attendu> : le dernier état de la branche courante vs origin/develop
palier() {
  local got
  got=$(bash "$LEVEL" "$TMP/w" origin/develop HEAD | sed -n 1p)
  if [ "$got" = "$2" ]; then ok "$1 → $2"; else bad "$1" "« $got » au lieu de « $2 »"; fi
}
reset_branch() { G checkout -q develop; G branch -q -D work 2>/dev/null; G checkout -q -b work; }
lines() { seq 1 "$1" | sed 's/^/x = /'; }

reset_branch; palier "aucun commit" vide

reset_branch; echo more >> "$TMP/w/README.md"; G commit -qam doc
palier "Markdown seul" docs

reset_branch; mkdir -p "$TMP/w/src"; lines 20 > "$TMP/w/src/a.js"; G add -A; G commit -qm app
palier "20 lignes applicatives" leger

reset_branch; mkdir -p "$TMP/w/tests"; lines 400 > "$TMP/w/tests/a.test.js"; G add -A; G commit -qm tests
palier "tests seuls (même gros)" leger

reset_branch; mkdir -p "$TMP/w/src"; lines 400 > "$TMP/w/src/b.js"; G add -A; G commit -qm gros
palier "400 lignes applicatives" complet

reset_branch; mkdir -p "$TMP/w/src/auth"; lines 3 > "$TMP/w/src/auth/login.js"; G add -A; G commit -qm auth
palier "3 lignes sous auth/ (chemin sensible)" complet

reset_branch; mkdir -p "$TMP/w/.agents/skills/review-pr"; echo x > "$TMP/w/.agents/skills/review-pr/SKILL.md"; G add -A; G commit -qm skill
palier "la procédure de review elle-même (Markdown) est sensible" complet

reset_branch; mkdir -p "$TMP/w/docs"; echo x > "$TMP/w/docs/guide.md"; G add -A; G commit -qm docs
palier "docs/ seul" docs

reset_branch; mkdir -p "$TMP/w/.github/workflows"; echo x > "$TMP/w/.github/workflows/ci.yml"; G add -A; G commit -qm ci
palier "workflow CI" complet

# --rank et --sensitive
[ "$(bash "$LEVEL" --rank leger)" = 2 ] && ok "--rank leger = 2" || bad "--rank" "attendu 2"
bash "$LEVEL" --rank n_importe_quoi >/dev/null 2>&1 && bad "--rank inconnu" "devait échouer" || ok "--rank inconnu échoue"
[ -n "$(bash "$LEVEL" --sensitive)" ] && ok "--sensitive imprime la regex" || bad "--sensitive" "vide"

# Réglage par config.sh : un dossier maison devient sensible.
CFG="$TMP/hk"; mkdir -p "$CFG"; cp "$LEVEL" "$(dirname "$LEVEL")/review-dir.sh" "$CFG/"
echo 'REVIEW_SENSITIVE_RE="(^|/)billing-core/"' > "$CFG/config.sh"
reset_branch; mkdir -p "$TMP/w/billing-core"; echo x > "$TMP/w/billing-core/a.js"; G add -A; G commit -qm cfg
got=$(bash "$CFG/review-level.sh" "$TMP/w" origin/develop HEAD | sed -n 1p)
[ "$got" = complet ] && ok "config.sh : chemin sensible maison" || bad "config.sh" "« $got »"

echo; echo "review-level : $PASS ok, $FAIL en échec"
[ "$FAIL" = 0 ]
