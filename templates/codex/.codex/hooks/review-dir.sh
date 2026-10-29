# review-dir.sh — configuration commune des hooks de review + dossier de la preuve.
# SOURCÉ par les autres scripts (jamais exécuté seul). Source unique des valeurs par défaut.
#
# Réglages (tous optionnels) : copier un fichier `.codex/hooks/config.sh` à côté des hooks et y
# poser les variables à changer. Il est sourcé ici, une seule fois, avant les défauts.
#
#   REVIEW_BASE_BRANCH    branche de base des PR (défaut : la branche par défaut du remote, origin/HEAD,
#                         sinon develop si elle existe, sinon main — calculé par resolve_base)
#   PROTECTED_BRANCHES    branches où le push direct est refusé, séparées par des espaces
#                         (défaut : base + "develop main master" ; vide = aucune branche protégée)
#   FIX_BRANCH_PREFIX     préfixe des branches de correctif (ex. fix/) : fixe FIX_BRANCH_RE à ^<préfixe>
#   REVIEW_DIR            dossier des rapports, relatif à la racine du dépôt (défaut : .codex/reviews)
#   FIX_BRANCH_RE         regex ERE des branches de correctif de bug, qui exigent une preuve inversée (défaut : ^fix/)
#   REVIEW_LIGHT_MAX     seuil de lignes applicatives du palier `leger` (défaut : 150)
#   REVIEW_SENSITIVE_RE   regex ERE des chemins sensibles (un seul suffit pour le palier `complet`)
#   REVIEW_DOC_RE         regex ERE des chemins « texte pur »
#   REVIEW_TEST_RE        regex ERE des chemins de test
#   REVIEW_NONAPP_RE      regex ERE des chemins non applicatifs (docs, config d'outillage)

_HOOKS_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -f "$_HOOKS_SELF_DIR/config.sh" ] && . "$_HOOKS_SELF_DIR/config.sh"

# Un placeholder que /setup-project n'a pas remplacé vaut « non réglé » (jamais une valeur littérale).
_PH='{''{'
case "${REVIEW_BASE_BRANCH:-}" in *"$_PH"*) unset REVIEW_BASE_BRANCH ;; esac
case "${FIX_BRANCH_PREFIX:-}" in *"$_PH"*|'') ;; *) FIX_BRANCH_RE="^${FIX_BRANCH_PREFIX}" ;; esac
if [ -n "${PROTECTED_BRANCHES+x}" ]; then
  # Retire mot par mot les placeholders non remplacés ; s'il ne reste rien d'un réglage non vide : défaut.
  _pb=""; _had=0
  for _w in $PROTECTED_BRANCHES; do _had=1; case "$_w" in *"$_PH"*) ;; *) _pb="$_pb $_w" ;; esac; done
  if [ "$_had" = 1 ] && [ -z "$_pb" ]; then unset PROTECTED_BRANCHES; else PROTECTED_BRANCHES=${_pb# }; fi
fi

# resolve_base <racine> → la branche de base des PR sur stdout : REVIEW_BASE_BRANCH, sinon origin/develop
# si elle existe (git flow : origin/HEAD y pointe souvent sur main), sinon origin/HEAD, sinon main, master.
resolve_base() {
  local root="$1" b
  if [ -n "${REVIEW_BASE_BRANCH:-}" ]; then printf '%s\n' "$REVIEW_BASE_BRANCH"; return; fi
  if git -C "$root" rev-parse --verify -q refs/remotes/origin/develop >/dev/null 2>&1; then printf 'develop\n'; return; fi
  b=$(git -C "$root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) && [ -n "$b" ] \
    && { printf '%s\n' "${b#origin/}"; return; }
  for b in main master; do
    git -C "$root" rev-parse --verify -q "refs/remotes/origin/$b" >/dev/null 2>&1 && { printf '%s\n' "$b"; return; }
  done
  printf 'develop\n'
}

: "${PROTECTED_BRANCHES=${REVIEW_BASE_BRANCH:+$REVIEW_BASE_BRANCH }develop main master}"
: "${REVIEW_DIR:=.codex/reviews}"
: "${FIX_BRANCH_RE:=^fix/}"
: "${REVIEW_LIGHT_MAX:=150}"
: "${REVIEW_SENSITIVE_RE:=(^|/)(auth|authn|authz|security|permissions?|middleware|migrations?|payments?|billing|crypto|secrets?)(/|\.[^/]+$|$)|(^|/)\.github/workflows/|(^|/)(\.husky|\.githooks)/|(^|/)scripts/hooks/|^\.(codex/(config\.toml$|agents/|hooks/)|agents/skills/review-pr/)|(^|/)(Dockerfile[^/]*|docker-compose[^/]*\.ya?ml)$|(^|/)(infra|terraform)/}"
: "${REVIEW_DOC_RE:=\.(md|mdx|rst)$}"
: "${REVIEW_TEST_RE:=^((apps|packages|services)/[^/]+/)?(tests?|e2e)/|(^|/)__(tests|snapshots)__/|\.(test|spec)\.[a-z]+$}"
: "${REVIEW_NONAPP_RE:=^docs/|^\.codex/|^\.github/|(^|/)(LICENSE|CODEOWNERS|\.gitignore|\.gitattributes|\.editorconfig|\.nvmrc)$}"

# review_dir → le dossier de la preuve (relatif à la racine du dépôt) sur stdout.
review_dir() { printf '%s\n' "$REVIEW_DIR"; }

# is_protected <branche> → 0 si la branche est dans PROTECTED_BRANCHES (casse ignorée) ; la branche protégée
# correspondante est alors dans PROTECTED_HIT.
PROTECTED_HIT=""
is_protected() {
  local b p
  b=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  for p in $PROTECTED_BRANCHES; do
    if [ "$b" = "$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]')" ]; then PROTECTED_HIT=$p; return 0; fi
  done
  return 1
}

# parse_push_cmd <commande> <dossier courant> → une ligne par action trouvée, dans l'ordre de la commande :
#   push<TAB><dossier visé><TAB><arguments après « push », séparés par des espaces>
#   pr<TAB><dossier visé>                      (gh pr create)
#   commit<TAB><dossier visé>                  (un commit avant le push change HEAD sous la porte)
#   opaque<TAB><dossier><TAB><segment>         (« push » via une commande indéterminée : $VAR, eval)
# Les guillemets tombent (« bash -c "git push" » devient une suite de jetons) ; ; | & ( ) et retours
# à la ligne coupent les segments ; « cd <dossier> » change le dossier des segments suivants ; les options
# globales de git (-C, -c, --git-dir…) sont sautées. Le doute penche vers « ça pousse » (porte fermée).
parse_push_cmd() {
  local cmd="$1" cur="${2:-$PWD}" seg t i n dir tool sub args _f
  local -a toks
  [ -n "$cur" ] || cur=$PWD
  case $- in *f*) _f=1 ;; *) _f=0; set -f ;; esac
  while IFS= read -r seg || [ -n "$seg" ]; do
    # shellcheck disable=SC2206
    toks=($seg); n=${#toks[@]}
    [ "$n" -gt 0 ] || continue
    if [ "${toks[0]}" = cd ]; then
      t=${toks[1]:-$HOME}
      case "$t" in /*) cur=$t ;; *) cur="$cur/$t" ;; esac
      continue
    fi
    i=0
    while [ "$i" -lt "$n" ]; do
      case "${toks[$i]}" in git|*/git|gh|*/gh) break ;; esac
      i=$((i+1))
    done
    if [ "$i" -ge "$n" ]; then
      case " $seg " in
        *" push "*) case "$seg" in *'$'*|*eval*) printf 'opaque\t%s\t%s\n' "$cur" "$seg" ;; esac ;;
      esac
      continue
    fi
    tool=${toks[$i]##*/}; i=$((i+1)); dir=$cur
    if [ "$tool" = git ]; then
      while [ "$i" -lt "$n" ]; do
        case "${toks[$i]}" in
          -C) t=${toks[$((i+1))]:-}; case "$t" in /*) dir=$t ;; *) dir="$dir/$t" ;; esac; i=$((i+2)) ;;
          -c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env) i=$((i+2)) ;;
          -*) i=$((i+1)) ;;
          *) break ;;
        esac
      done
      sub=${toks[$i]:-}; i=$((i+1))
      case "$sub" in
        push) args="${toks[*]:$i}"; printf 'push\t%s\t%s\n' "$dir" "$args" ;;
        commit) printf 'commit\t%s\n' "$dir" ;;
      esac
    else
      while [ "$i" -lt "$n" ]; do
        case "${toks[$i]}" in
          -R|--repo) i=$((i+2)) ;;
          -*) i=$((i+1)) ;;
          *) break ;;
        esac
      done
      if [ "${toks[$i]:-}" = pr ] && [ "${toks[$((i+1))]:-}" = create ]; then printf 'pr\t%s\n' "$dir"; fi
    fi
  done < <(printf '%s\n' "$cmd" | tr -d "\"'" | tr ';|&()' '\n\n\n\n\n')
  [ "$_f" = 1 ] || set +f
}
