#!/usr/bin/env bash
# e2e-level.sh — niveau d'E2E à jouer avant une PR, calculé depuis le diff, jamais jugé.
#
# Usage : e2e-level.sh [racine] [base] [head]
#         e2e-level.sh --sensitive        # affiche la liste des chemins sensibles
# Sortie : ligne 1 = aucun | specs | smoke ; ligne 2 = la raison ;
#          puis « spec<TAB>chemin » par spec E2E ajouté ou modifié à jouer.
# Code de sortie : 0 = niveau rendu ; 1 = erreur (l'appelant retombe sur « smoke »).
#
# Niveaux :
#   smoke  le diff touche un chemin sensible (e2e-sensitive.txt) : on joue le smoke
#          ET les specs listés, dans le même run
#   specs  aucun chemin sensible, mais un spec E2E est ajouté ou modifié : ces specs seuls
#   aucun  tout le reste : pas d'E2E avant PR (le nightly ou la CI E2E du projet, s'il en a un, rejoue tout ; sinon, le dire dans la PR)
#
# Réglages (variables d'environnement, ou éditer les valeurs ci-dessous) :
#   E2E_DEFAULT_BRANCH  branche de comparaison (défaut : la branche de base, resolve_base de review-dir.sh)
#   E2E_DIR             dossier des specs E2E (config.sh) ; « none » ou vide = le projet n'a pas d'E2E
#   E2E_SPEC_RE         regex ERE des fichiers de spec E2E
#   E2E_SENSITIVE_FILE  fichier des chemins sensibles (défaut : e2e-sensitive.txt à côté du script)
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
# Même configuration que les hooks de review (config.sh optionnel, source unique).
[ -f "$HERE/review-dir.sh" ] && . "$HERE/review-dir.sh"
# Placeholder non remplacé ou « none » : pas de dossier E2E déclaré.
case "${E2E_DIR:-}" in *"{""{"*|none|NONE|None) E2E_DIR="" ;; esac
E2E_DIR=${E2E_DIR%/}
if [ -n "${E2E_SPEC_RE:-}" ]; then SPEC_RE=$E2E_SPEC_RE
elif [ -n "$E2E_DIR" ]; then
  # Les fichiers de spec sous le dossier déclaré (chemin échappé), plus les emplacements usuels.
  SPEC_RE="^$(printf '%s' "$E2E_DIR" | sed 's/[.[\*^$()+?{|]/\\&/g')/(.*/)?[^/]+\.(spec|test|cy)\.[a-z]+$|(^|/)(e2e|cypress/e2e)/(.*/)?[^/]+\.(spec|test|cy)\.[cm]?[jt]sx?$"
else
  SPEC_RE="(^|/)(e2e|tests/e2e|cypress/e2e)/(.*/)?[^/]+\.(spec|test|cy)\.[cm]?[jt]sx?$"
fi
SENSITIVE_FILE="${E2E_SENSITIVE_FILE:-$HERE/e2e-sensitive.txt}"

# Charge les globs : un par ligne, sans commentaires ni lignes vides.
load_globs() {
  [ -f "$SENSITIVE_FILE" ] || return 0
  sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$SENSITIVE_FILE" | awk 'NF'
}

case "${1:-}" in
  --sensitive)
    globs=$(load_globs)
    if [ -z "$globs" ]; then echo "(aucun chemin sensible configuré : $SENSITIVE_FILE)"; else printf '%s\n' "$globs"; fi
    exit 0 ;;
  -h|--help)
    sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
esac

ROOT="${1:-.}"
ROOT=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null) || { echo "e2e-level : pas un dépôt git : $ROOT" >&2; exit 1; }
BASE="${2:-origin/${E2E_DEFAULT_BRANCH:-$(resolve_base "$ROOT")}}"; HEAD_REF="${3:-HEAD}"
g() { git -C "$ROOT" -c core.quotePath=false "$@"; }
g rev-parse --verify -q "$BASE" >/dev/null || { echo "e2e-level : base introuvable : $BASE" >&2; exit 1; }
g rev-parse --verify -q "$HEAD_REF" >/dev/null || { echo "e2e-level : head introuvable : $HEAD_REF" >&2; exit 1; }

# Fichiers du diff (statut + chemin), plus l'arbre de travail non commité quand HEAD_REF = HEAD.
DIFF=$(g diff --no-renames --name-status "$BASE...$HEAD_REF" 2>/dev/null) || { echo "e2e-level : diff impossible ($BASE...$HEAD_REF)" >&2; exit 1; }
if [ "$(g rev-parse "$HEAD_REF^{commit}")" = "$(g rev-parse HEAD)" ]; then
  extra=$(g diff --no-renames --name-status HEAD 2>/dev/null; g ls-files --others --exclude-standard | awk '{print "A\t" $0}')
  [ -z "$extra" ] || DIFF="$DIFF"$'\n'"$extra"
fi
[ -n "$(printf '%s' "$DIFF" | tr -d '[:space:]')" ] || { echo "e2e-level : diff vide ($BASE...$HEAD_REF) : mauvaise base ou rien à comparer" >&2; exit 1; }

globs=$(load_globs)
specs=""; sensitive=""

while IFS=$'\t' read -r st path; do
  [ -n "${path:-}" ] || continue
  if [[ "$path" =~ $SPEC_RE ]]; then
    case "$st" in D*) ;; *) specs="$specs$path"$'\n' ;; esac
    continue
  fi
  [ -n "$globs" ] || continue
  while IFS= read -r glob; do
    # shellcheck disable=SC2254
    case "$path" in $glob) sensitive="$sensitive$path"$'\n'; break ;; esac
  done <<< "$globs"
done <<< "$DIFF"

specs=$(printf '%s' "$specs" | sort -u | awk 'NF')
sensitive=$(printf '%s' "$sensitive" | sort -u | awk 'NF')

if [ -n "$sensitive" ]; then
  echo "smoke"
  echo "chemin sensible touché : $(printf '%s\n' "$sensitive" | head -3 | paste -sd' ' -)"
elif [ -n "$specs" ]; then
  echo "specs"
  echo "spec E2E ajouté ou modifié, aucun chemin sensible"
else
  echo "aucun"
  echo "aucun chemin sensible, aucun spec E2E touché : pas d'E2E avant PR (nightly ou CI E2E du projet s'il en a un)"
  exit 0
fi
[ -z "$specs" ] || printf '%s\n' "$specs" | awk '{print "spec\t" $0}'
exit 0
