#!/usr/bin/env bash
# push-target-guard.sh — refuse un push direct sur une branche protégée (défaut : develop, main).
#
# Le garde regarde CE QUI PART (la destination des références poussées), jamais la branche du disque :
# on bloque quand la DESTINATION est une branche protégée, quelle que soit l'opération — création,
# mise à jour, suppression. Tout le reste passe, y compris l'effacement d'une branche de travail.
# Les branches protégées se règlent dans PROTECTED_BRANCHES (review-dir.sh / config.sh optionnel).
#
# Deux modes, détectés sur l'entrée standard :
#
# 1. Hook PreToolUse de Claude Code (stdin = payload JSON, jq requis). Analyse la commande Bash :
#    chaque push est jugé sur sa destination. Exit 2 + message sur stderr = bloqué.
#      - `<remote> <src>:<dst>` ou `<remote> <dst>` : destination explicite ;
#      - sans référence : la branche courante part (refusée si protégée) ;
#      - `--all`, `--mirror` : refusés (ils poussent aussi les branches protégées).
#
# 2. Hook git pre-push (stdin = lignes `<réf locale> <sha local> <réf distante> <sha distant>`).
#    Sortie : EXACTEMENT une ligne, code de sortie toujours 0 (le verdict est la ligne) :
#      bloque <branche>   une référence au moins vise une branche protégée
#      rien <n>           n références, toutes des effacements : rien ne part
#      verifie <n>        au moins une référence apporte des objets : les autres portes se jouent
#      muette <raison>    ligne non conforme : on ne sait pas ce qui part, le hook appelant refuse
#
# Auto-test : push-target-guard.test.sh.
set -u
set -f   # aucune expansion de chemin : une référence n'est jamais un motif
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR

. "$(cd "$(dirname "$0")" && pwd)/review-dir.sh"

INPUT=$(cat)
FIRST=$(printf '%s' "$INPUT" | tr -d '[:space:]' | cut -c1)

# ── Mode 1 : PreToolUse ──────────────────────────────────────────────────────────────────────
if [ "$FIRST" = "{" ]; then
  CMD=""; CWD=""
  if command -v jq >/dev/null 2>&1 \
     && CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) \
     && CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null); then :
  else
    if printf '%s' "$INPUT" | grep -qE 'git[^"]*push'; then
      echo "🛑 push-target-guard : payload illisible (jq absent ou en erreur) alors que la commande ressemble à un push — fermé par défaut." >&2
      exit 2
    fi
    exit 0
  fi
  [ -n "$CMD" ] || exit 0

  block() {
    echo "🛑 push-target-guard : $1 — jamais de push direct sur une branche protégée ($PROTECTED_BRANCHES) ; passer par une branche de travail et une PR." >&2
    exit 2
  }

  while IFS= read -r seg || [ -n "$seg" ]; do
    # tokens du segment ; on cherche « git [-C dir] push »
    # shellcheck disable=SC2206
    toks=($seg)
    n=${#toks[@]}; i=0; dir=""
    while [ "$i" -lt "$n" ] && [ "${toks[$i]}" != "git" ]; do i=$((i+1)); done
    [ "$i" -lt "$n" ] || continue
    i=$((i+1))
    if [ "${toks[$i]:-}" = "-C" ]; then dir=${toks[$((i+1))]:-}; i=$((i+2)); fi
    [ "${toks[$i]:-}" = "push" ] || continue
    i=$((i+1))
    dir=$(printf '%s' "$dir" | tr -d "\"'")
    repo_dir="$CWD"; [ -z "$dir" ] || { [ -d "$dir" ] && repo_dir="$dir"; }
    { [ -n "$repo_dir" ] && [ -d "$repo_dir" ]; } || repo_dir="$PWD"
    positional=()
    while [ "$i" -lt "$n" ]; do
      t=$(printf '%s' "${toks[$i]}" | tr -d "\"'")
      case "$t" in
        --all|--mirror) block "« push $t » pousse aussi les branches protégées" ;;
        -o|--push-option) i=$((i+1)) ;;   # l'option prend un argument
        -*) ;;
        *) positional+=("$t") ;;
      esac
      i=$((i+1))
    done
    # positional[0] = remote, le reste = références
    refs=("${positional[@]:1}")
    if [ "${#refs[@]}" -eq 0 ]; then
      cur=$(git -C "$repo_dir" branch --show-current 2>/dev/null || true)
      if [ -n "$cur" ] && is_protected "$cur"; then block "la branche courante « $cur » est protégée"; fi
      continue
    fi
    for r in "${refs[@]}"; do
      r=${r#+}                      # +force
      case "$r" in
        *:*) dst=${r#*:} ;;         # <src>:<dst> → dst (« :dst » = suppression, même cible)
        *)   dst=$r ;;
      esac
      dst=${dst#refs/heads/}
      if [ "$dst" = "HEAD" ]; then
        dst=$(git -C "$repo_dir" branch --show-current 2>/dev/null || true)
      fi
      if [ -n "$dst" ] && is_protected "$dst"; then block "destination « $dst » protégée"; fi
    done
  done < <(printf '%s' "$CMD" | tr ';|&' '\n')
  exit 0
fi

# ── Mode 2 : pre-push git ────────────────────────────────────────────────────────────────────
CR=$(printf '\r')
BLOQUE=""; MUETTE=""; N=0; SUPPR=0; LIGNE=0
lref=""; lsha=""; rref=""; rsha=""; extra=""

sha_ok() {
  case "$1" in ''|*[!0-9a-f]*) return 1 ;; esac
  case "${#1}" in 40|64) return 0 ;; esac
  return 1
}

while read -r lref lsha rref rsha extra || [ -n "$lref$lsha$rref$rsha$extra" ]; do
  [ -n "$lref$lsha$rref$rsha$extra" ] || continue
  LIGNE=$((LIGNE + 1))
  lref=${lref%"$CR"}; lsha=${lsha%"$CR"}; rref=${rref%"$CR"}; rsha=${rsha%"$CR"}; extra=${extra%"$CR"}
  if [ -n "$extra" ] || [ -z "$lref" ] || [ -z "$rref" ] || ! sha_ok "$lsha" || ! sha_ok "$rsha"; then
    [ -n "$MUETTE" ] || MUETTE="ligne $LIGNE non conforme : 4 champs attendus, shas en 40 ou 64 caractères hexa"
    continue
  fi
  N=$((N + 1))
  # Destination : refs/heads/ optionnel ; refs/tags/<nom> n'est pas une branche (le sujet du test, jamais son motif).
  _dest=${rref#refs/heads/}
  if is_protected "$_dest"; then BLOQUE=$PROTECTED_HIT; fi
  # Effacement = le sha LOCAL (2ᵉ champ) est nul ; à la création, c'est le sha distant (4ᵉ) qui l'est.
  case "$lsha" in *[!0]*) ;; *) SUPPR=$((SUPPR + 1)) ;; esac
done <<< "$INPUT"

if [ -n "$BLOQUE" ]; then printf '%s\n' "bloque $BLOQUE"
elif [ -n "$MUETTE" ]; then printf '%s\n' "muette $MUETTE"
elif [ "$N" -gt 0 ] && [ "$SUPPR" = "$N" ]; then printf '%s\n' "rien $N"
else printf '%s\n' "verifie $N"
fi
exit 0
