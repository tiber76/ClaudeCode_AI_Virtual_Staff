#!/usr/bin/env bash
# push-target-guard.sh — refuse un push direct sur une branche protégée (défaut : la base, develop, main, master).
#
# Le garde regarde CE QUI PART (la destination des références poussées), jamais la branche du disque :
# on bloque quand la DESTINATION est une branche protégée, quelle que soit l'opération — création,
# mise à jour, suppression. Tout le reste passe, y compris l'effacement d'une branche de travail.
# Les branches protégées se règlent dans PROTECTED_BRANCHES (review-dir.sh / config.sh optionnel).
#
# Appelé par le hook git pre-push (pre-push), lancé depuis le dépôt : stdin = les lignes que git donne
# au hook, `<réf locale> <sha local> <réf distante> <sha distant>`. Git les écrit lui-même : aucune
# forme de commande (variable, alias, chemin avec espace) ne change ce qui est jugé.
# Sortie : EXACTEMENT une ligne, code de sortie toujours 0 (le verdict est la ligne) :
#   bloque <branche>   une référence au moins vise une branche protégée
#   rien <n>           n références, toutes des effacements : rien ne part
#   verifie <n>        au moins une référence apporte des objets : la porte de review se joue
#   muette <raison>    ligne non conforme : on ne sait pas ce qui part, le hook appelant refuse
#
# Auto-test : push-target-guard.test.sh.
set -u
set -f   # aucune expansion de chemin : une référence n'est jamais un motif
unset GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX

. "$(cd "$(dirname "$0")" && pwd)/review-dir.sh"
# Avec le défaut, la base résolue du dépôt (ex. trunk) est protégée elle aussi.
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && protect_base "$_ROOT"

INPUT=$(cat)
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
