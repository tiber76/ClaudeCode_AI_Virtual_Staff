#!/usr/bin/env bash
# review-level.sh — le palier de review d'une branche, calculé depuis le diff, jamais jugé.
#
# Pourquoi : la méthode de review doit suivre le risque du diff, et c'est ce script qui décide, pas
# l'agent qui relit. Le hook review-gate recalcule le palier pour HEAD et refuse un rapport d'un
# niveau inférieur.
#
# Usage :
#   review-level.sh <racine du dépôt> [base] [head]   → ligne 1 : vide | docs | leger | complet
#                                                        ligne 2 : la raison, lisible
#   review-level.sh --rank <palier>                   → 0 | 1 | 2 | 3 (pour comparer)
#   review-level.sh --sensitive                       → la regex des chemins sensibles
#   review-level.sh --files <racine> [base] [head]    → une ligne « <classe><TAB><chemin> » par fichier du diff,
#                                                        classe ∈ sensible | doc | test | nonapp | lock | app
# base par défaut : origin/<REVIEW_BASE_BRANCH> ; head par défaut : HEAD. Le diff est celui de la PR
# (base...head) : le palier mesure le risque de ce qui part, pas du dernier commit.
#
# Paliers :
#   vide    — aucun fichier dans le diff : rien à relire, le skill s'arrête.
#   docs    — aucun fichier applicatif ni de test, aucun chemin sensible → 1 chercheur.
#   leger   — ≤ REVIEW_LIGHT_MAX lignes applicatives hors tests ET aucun chemin sensible → 5 chercheurs.
#             Un diff de tests seuls est « leger », jamais « docs » : un test supprimé est un candidat.
#   complet — tout le reste : les 8 angles. Un seul chemin sensible suffit.
#
# Ordre d'évaluation d'un chemin (il compte) :
#   1. la procédure de review et les agents (.codex/agents/, .codex/skills/review-pr/) → sensible,
#      même en Markdown : ils fixent les outils des sous-agents et la procédure elle-même ;
#   2. texte pur → doc ; 3. test ; 4. sensible ; 5. non applicatif ; 6. verrou ; 7. applicatif.
# Réglages : voir review-dir.sh (config.sh optionnel).
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR

. "$(cd "$(dirname "$0")" && pwd)/review-dir.sh"

PROC_RE='^\.codex/(agents/|skills/review-pr/)'
LOCKFILE_RE='(^|/)(pnpm-lock\.yaml|package-lock\.json|yarn\.lock|Cargo\.lock|poetry\.lock|composer\.lock|Gemfile\.lock|go\.sum)$'
NONCANON_RE='^"|(^|/)\.\.?(/|$)|//'

cls=""; seg=""
classify_path() {
  local path="$1"; seg=""
  if [[ "$path" =~ $PROC_RE ]]; then cls=sensible; seg="${BASH_REMATCH[0]}"
  elif [[ "$path" =~ $REVIEW_DOC_RE ]]; then cls=doc
  elif [[ "$path" =~ $NONCANON_RE ]]; then cls=sensible; seg="chemin non canonique"
  elif [[ "$path" =~ $REVIEW_TEST_RE ]]; then cls=test
  elif [[ "$path" =~ $REVIEW_SENSITIVE_RE ]]; then cls=sensible; seg="${BASH_REMATCH[0]#/}"
  elif [[ "$path" =~ $REVIEW_NONAPP_RE ]]; then cls=nonapp
  elif [[ "$path" =~ $LOCKFILE_RE ]]; then cls=lock
  else cls=app
  fi
}

case "${1:-}" in
  --rank)
    case "${2:-}" in vide) echo 0 ;; docs) echo 1 ;; leger) echo 2 ;; complet) echo 3 ;; *) echo "palier inconnu : ${2:-}" >&2; exit 1 ;; esac
    exit 0 ;;
  --sensitive)
    printf '%s\n' "$REVIEW_SENSITIVE_RE"; exit 0 ;;
  ""|-h|--help)
    sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 1 ;;
  --files)
    MODE=files; shift; [ -n "${1:-}" ] || { echo "usage : review-level.sh --files <racine> [base] [head]" >&2; exit 1; } ;;
esac
MODE="${MODE:-palier}"

ROOT="$1"; BASE="${2:-origin/$REVIEW_BASE_BRANCH}"; HEAD_REF="${3:-HEAD}"
git -C "$ROOT" rev-parse --verify -q "$BASE" >/dev/null || { echo "review-level : base introuvable : $BASE (dépôt $ROOT)" >&2; exit 1; }
git -C "$ROOT" rev-parse --verify -q "$HEAD_REF" >/dev/null || { echo "review-level : head introuvable : $HEAD_REF" >&2; exit 1; }

# --no-renames : un déplacement apparaît comme suppression + ajout, chemins en plein.
NUMSTAT=$(git -C "$ROOT" -c core.quotePath=false diff --no-renames --numstat "$BASE...$HEAD_REF" 2>/dev/null) || { echo "review-level : diff impossible ($BASE...$HEAD_REF)" >&2; exit 1; }

app_lines=0; app_files=0; test_files=0; nonapp_files=0; sensitive=""; binaire=""
while IFS=$'\t' read -r add del path; do
  [ -n "${path:-}" ] || continue
  bin=""; [ "$add" = "-" ] && bin=1
  [ "$add" = "-" ] && add=0; [ "$del" = "-" ] && del=0
  classify_path "$path"
  if [ "$MODE" = files ]; then printf '%s\t%s\n' "$cls" "$path"; continue; fi
  case "$cls" in
    sensible)
      app_files=$((app_files+1)); app_lines=$((app_lines + add + del))
      [ -n "$bin" ] && binaire="${binaire:+$binaire, }$path"
      case "$sensitive" in *"$seg"*) ;; *) sensitive="${sensitive:+$sensitive, }$seg" ;; esac ;;
    doc|nonapp) nonapp_files=$((nonapp_files+1)) ;;
    test) test_files=$((test_files+1)) ;;
    lock) app_files=$((app_files+1)) ;;
    app)
      app_files=$((app_files+1)); app_lines=$((app_lines + add + del))
      [ -n "$bin" ] && binaire="${binaire:+$binaire, }$path" ;;
  esac
done <<< "$NUMSTAT"
[ "$MODE" = files ] && exit 0

if [ "$app_files" = 0 ] && [ "$nonapp_files" = 0 ] && [ "$test_files" = 0 ]; then
  echo "vide"
  echo "aucun fichier dans le diff $BASE...$HEAD_REF : rien à relire"
elif [ -n "$sensitive" ]; then
  echo "complet"
  echo "$app_lines ligne(s) applicative(s) hors tests sur $app_files fichier(s), chemin(s) sensible(s) : $sensitive"
elif [ "$app_files" = 0 ] && [ "$test_files" = 0 ]; then
  echo "docs"
  echo "aucun fichier applicatif ni de test touché ($nonapp_files fichier(s) docs/config)"
elif [ -n "$binaire" ]; then
  echo "complet"
  echo "fichier(s) applicatif(s) binaire(s), diff illisible donc poids inconnu : $binaire"
elif [ "$app_lines" -le "$REVIEW_LIGHT_MAX" ]; then
  echo "leger"
  echo "$app_lines ligne(s) applicative(s) hors tests sur $app_files fichier(s), $test_files de tests, aucun chemin sensible (seuil $REVIEW_LIGHT_MAX)"
else
  echo "complet"
  echo "$app_lines ligne(s) applicative(s) hors tests sur $app_files fichier(s), au-delà du seuil $REVIEW_LIGHT_MAX"
fi
exit 0
