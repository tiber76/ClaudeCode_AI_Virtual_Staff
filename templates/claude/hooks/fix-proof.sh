#!/usr/bin/env bash
# fix-proof — la preuve inversée d'un fix de bug (/fix-bug).
#
# Pourquoi : un test vert après un fix ne prouve pas qu'il reproduit CE bug (il peut être vert sans le fix).
# Ce script débranche la pièce réparée pour vérifier que c'était bien elle qui était en panne :
#   1. il crée un worktree git TEMPORAIRE (détaché sur HEAD) et y recopie l'état courant de l'arbre de travail
#      (modifs non commitées et fichiers neufs compris) : l'arbre de travail réel n'est JAMAIS modifié ;
#   2. dans ce worktree, il remet la version d'AVANT des fichiers du fix (les tests restent en place) et lance
#      la commande de test : elle doit ÉCHOUER ;
#   3. il remet le fix et relance : elle doit PASSER ;
#   4. il écrit une preuve dans .claude/reviews/fix-proof-<sha7 de HEAD>.md (lue par le rapport de /review-pr
#      et par review-gate.sh quand il vérifie les branches de fix).
#
# Usage (depuis n'importe où dans le dépôt) :
#   fix-proof.sh --test "<commande de test>" [--cwd <sous-dossier>] [--base <ref>] [--link <dossier>]...
#                -- <fichier source du fix>...
#     --test  la commande qui reproduit le bug (ex. "npx jest tests/api/foo.test.ts --no-coverage"),
#             exécutée par `bash -c` dans le worktree temporaire. Ne jamais y mettre de secret : elle est
#             recopiée dans la preuve.
#     --cwd   sous-dossier (relatif, sans `..`) d'où lancer la commande (monorepo). Défaut : racine du dépôt.
#     --base  référence d'AVANT le fix. Défaut : HEAD si un des fichiers du fix est modifié / non suivi /
#             supprimé dans l'arbre de travail (fix non commité), HEAD~1 sinon (HEAD est le commit du fix).
#             Explicite quand d'autres commits ont suivi : --base <commit du fix>~1.
#     --link  dossier ignoré par git à relier dans le worktree (symlink vers l'original), pour que les
#             dépendances soient trouvées. Répétable. Défaut : node_modules, vendor, .venv à la racine et
#             sous --cwd s'ils existent.
#     --      puis les fichiers SOURCE du fix, relatifs à la racine, sans `..` ; jamais les fichiers de test
#             (ils restent présents dans les deux runs).
# Sorties : 0 = preuve ok (ligne « preuve inversée ok : … » sur stdout) ;
#   1 = STOP-… sur stderr (STOP-TEST-VERT-SANS-FIX : le test passe sans le fix, il ne reproduit pas le bug ;
#       STOP-TEST-ROUGE-AVEC-FIX : le fix ne corrige pas ce que le test mesure ; STOP-COMMANDE : exit 126/127,
#       la commande n'a rien mesuré ; STOP-BASE, STOP-FICHIER, STOP-CHEMIN, STOP-WORKTREE, STOP-PREUVE) ;
#   2 = usage.
# Limites assumées : la preuve atteste que le test est rouge sans les fichiers listés et vert avec ; elle ne
# juge ni la pertinence du test ni l'exhaustivité de la liste des fichiers du fix (c'est le travail de la
# review, angle « altitude »). Un test qui dépend de services externes ou d'un état hors dépôt (base de
# données, réseau) mesure l'environnement autant que le fix : le dire dans la preuve.
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR

usage() { sed -n '2,/^set -u$/p' "$0" | sed '$d' >&2; exit 2; }
stop() { printf '%s\n' "$*" >&2; exit 1; }

# `pnpm run … --` ou npm transmettent parfois un « -- » en tête : on l'absorbe.
[ "${1:-}" = "--" ] && shift
[ $# -ge 1 ] || usage

TEST=""; CWD=""; BASE_ARG=""; LINKS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --test) [ $# -ge 2 ] || usage; TEST="$2"; shift 2 ;;
    --cwd)  [ $# -ge 2 ] || usage; CWD="$2"; shift 2 ;;
    --base) [ $# -ge 2 ] || usage; BASE_ARG="$2"; shift 2 ;;
    --link) [ $# -ge 2 ] || usage; LINKS="$LINKS
$2"; shift 2 ;;
    -h|--help) usage ;;
    --) shift; break ;;
    *) usage ;;
  esac
done
[ -n "$TEST" ] || usage
[ $# -ge 1 ] || usage

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || stop "STOP-WORKTREE : pas dans un dépôt git"
cd "$ROOT" || exit 1

# Chemins : relatifs, sans `..`, jamais sous .git/.
bad_path() {
  case "$1" in
    ""|/*|~*|..|../*|*/..|*/../*|.git|.git/*) return 0 ;;
  esac
  return 1
}
if [ -n "$CWD" ]; then
  bad_path "$CWD" && stop "STOP-CHEMIN : --cwd doit être relatif au dépôt, sans « .. »"
  [ -d "$CWD" ] || stop "STOP-CHEMIN : --cwd introuvable : $CWD"
fi
FILES=""
for f in "$@"; do
  f="${f%/}"
  bad_path "$f" && stop "STOP-CHEMIN : fichier du fix invalide : $f"
  [ -L "$f" ] && stop "STOP-CHEMIN : lien symbolique refusé : $f"
  FILES="$FILES
$f"
done

HEAD_SHA="$(git rev-parse HEAD 2>/dev/null)" || stop "STOP-BASE : dépôt sans commit"
HEAD7="${HEAD_SHA:0:7}"   # même découpe que review-gate.sh (jamais --short, qui s'allonge si ambigu)

# Le fix est-il non commité ? (un des fichiers modifié, non suivi ou supprimé dans l'arbre de travail)
DIRTY=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -n "$(git status --porcelain -- "$f" 2>/dev/null)" ]; then DIRTY=1; fi
done <<EOF2
$FILES
EOF2

if [ -n "$BASE_ARG" ]; then
  BASE="$BASE_ARG"; ORIGIN="explicite"
elif [ "$DIRTY" -eq 1 ]; then
  BASE="HEAD"; ORIGIN="fix non commité"
else
  BASE="HEAD~1"; ORIGIN="HEAD est le commit du fix"
fi
BASE_SHA="$(git rev-parse --verify --quiet "$BASE^{commit}")" || stop "STOP-BASE : référence introuvable : $BASE"

# Chaque fichier du fix doit exister avec le fix ou dans la base (sinon la liste est une faute de frappe).
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ ! -e "$f" ] && ! git cat-file -e "$BASE_SHA:$f" 2>/dev/null; then
    stop "STOP-FICHIER : $f n'existe ni dans l'arbre de travail ni dans la base $BASE"
  fi
done <<EOF3
$FILES
EOF3

# Worktree temporaire, hors du dépôt, supprimé en sortie quoi qu'il arrive.
WT_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/fix-proof.XXXXXX")" || stop "STOP-WORKTREE : mktemp a échoué"
WT="$WT_PARENT/wt"
cleanup() {
  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1
  git -C "$ROOT" worktree prune >/dev/null 2>&1
  rm -rf "$WT_PARENT"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
git -C "$ROOT" worktree add --detach "$WT" "$HEAD_SHA" >/dev/null 2>&1 || stop "STOP-WORKTREE : git worktree add a échoué"

# Superpose l'état courant (modifs indexées ou non, fichiers neufs, suppressions) sur le worktree.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -e "$ROOT/$f" ] && [ ! -d "$ROOT/$f" ]; then
    mkdir -p "$WT/$(dirname "$f")"
    cp -p "$ROOT/$f" "$WT/$f"
  else
    rm -f "$WT/$f"
  fi
done <<EOF4
$( { git -C "$ROOT" -c core.quotePath=false diff --name-only HEAD; git -C "$ROOT" -c core.quotePath=false ls-files -o --exclude-standard; } | sort -u)
EOF4

# Dépendances : symlinks vers les dossiers ignorés par git.
link_dir() {
  local d="$1"
  [ -d "$ROOT/$d" ] || return 0
  [ -e "$WT/$d" ] && return 0
  mkdir -p "$WT/$(dirname "$d")"
  ln -s "$ROOT/$d" "$WT/$d"
}
for d in node_modules vendor .venv; do
  link_dir "$d"
  [ -n "$CWD" ] && link_dir "$CWD/$d"
done
while IFS= read -r d; do
  [ -n "$d" ] || continue
  bad_path "$d" && stop "STOP-CHEMIN : --link invalide : $d"
  link_dir "$d"
done <<EOF5
$LINKS
EOF5

RUN_DIR="$WT"
[ -n "$CWD" ] && RUN_DIR="$WT/$CWD"
run_test() { ( cd "$RUN_DIR" && bash -c "$TEST" ) >"$1" 2>&1; }

# --- Phase 1 : SANS le fix (version de la base pour chaque fichier du fix) ---
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if git cat-file -e "$BASE_SHA:$f" 2>/dev/null; then
    mkdir -p "$WT/$(dirname "$f")"
    git -C "$ROOT" show "$BASE_SHA:$f" >"$WT/$f" || stop "STOP-BASE : lecture de $f à $BASE impossible"
  else
    rm -f "$WT/$f"
  fi
done <<EOF6
$FILES
EOF6
run_test "$WT_PARENT/sans-fix.out"; RC_SANS=$?
[ "$RC_SANS" -eq 126 ] || [ "$RC_SANS" -eq 127 ] && stop "STOP-COMMANDE : exit $RC_SANS sans le fix, la commande n'a rien mesuré"
[ "$RC_SANS" -eq 0 ] && stop "STOP-TEST-VERT-SANS-FIX : le test passe sans le fix, il ne reproduit pas le bug"

# --- Phase 2 : AVEC le fix (état courant de l'arbre de travail) ---
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -e "$ROOT/$f" ]; then
    mkdir -p "$WT/$(dirname "$f")"
    cp -p "$ROOT/$f" "$WT/$f"
  else
    rm -f "$WT/$f"
  fi
done <<EOF7
$FILES
EOF7
run_test "$WT_PARENT/avec-fix.out"; RC_AVEC=$?
[ "$RC_AVEC" -eq 126 ] || [ "$RC_AVEC" -eq 127 ] && stop "STOP-COMMANDE : exit $RC_AVEC avec le fix, la commande n'a rien mesuré"
[ "$RC_AVEC" -ne 0 ] && stop "STOP-TEST-ROUGE-AVEC-FIX : le fix ne corrige pas ce que le test mesure (exit $RC_AVEC)"

# --- Preuve ---
_FP_HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$_FP_HERE/review-dir.sh" ] && . "$_FP_HERE/review-dir.sh"
PROOF_DIR="$ROOT/${REVIEW_DIR:-.claude/reviews}"
mkdir -p "$PROOF_DIR" || stop "STOP-PREUVE : dossier $PROOF_DIR impossible à créer"
PROOF="$PROOF_DIR/fix-proof-$HEAD7.md"
{
  echo "# Preuve inversée — fix-proof-$HEAD7"
  echo
  echo "- **Date** : $(date '+%Y-%m-%d %H:%M:%S')"
  echo "- **HEAD** : $HEAD_SHA"
  echo "- **Base (avant le fix)** : $BASE_SHA ($ORIGIN)"
  echo "- **Commande de test** : \`$TEST\`${CWD:+ (depuis $CWD)}"
  echo "- **Sans le fix** : exit $RC_SANS (attendu : échec)"
  echo "- **Avec le fix** : exit $RC_AVEC (attendu : 0)"
  echo
  echo "## Fichiers du fix (contenu AVEC le fix)"
  echo
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -e "$ROOT/$f" ]; then
      echo "- \`$f\` $(git hash-object "$ROOT/$f")"
    else
      echo "- \`$f\` ABSENT (supprimé par le fix)"
    fi
  done <<EOF8
$FILES
EOF8
  echo
  echo "## Dernières lignes du test sans le fix"
  echo
  echo '```'
  tail -n 15 "$WT_PARENT/sans-fix.out"
  echo '```'
  echo
  echo "Verdict : ok"
} >"$PROOF" 2>/dev/null || stop "STOP-PREUVE : écriture de $PROOF impossible"

echo "preuve inversée ok : test rouge sans le fix (exit $RC_SANS), vert avec (exit 0), base ${BASE_SHA:0:7} ($ORIGIN) — preuve : ${REVIEW_DIR:-.claude/reviews}/fix-proof-$HEAD7.md"
exit 0
