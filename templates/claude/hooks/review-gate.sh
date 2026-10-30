#!/usr/bin/env bash
# review-gate.sh — porte de review : aucun commit ne part, aucune PR ne s'ouvre, sans rapport /review-pr valide.
#
# Trois modes :
#   --commit <racine> <sha> <branche>  juge un commit précis. Appelé par le hook git pre-push (pre-push)
#                                      pour chaque branche qui part : c'est le contrôle exact des push.
#   --verdict <rapport>                rejoue la grammaire et le palier d'un rapport à la main (exit 0 = « oui »).
#   (sans argument)                    hook PreToolUse (matcher Bash) de Claude Code — payload JSON sur stdin,
#                                      jq requis. Exit 2 + message sur stderr = commande bloquée. Il ne juge pas
#                                      les push (le hook git le fait) ; il :
#                                        - refuse ce qui désactive le hook git : « push --no-verify », toute
#                                          mention de core.hooksPath, un push qui touche au fichier pre-push ;
#                                        - refuse un push vers un dépôt où le hook git n'est pas installé
#                                          (install-git-hooks.sh le branche) ;
#                                        - juge HEAD avant « gh pr create » (gh ne passe par aucun hook git).
#
# Un commit est valable s'il a le rapport `<REVIEW_DIR>/<sha complet>.md` (écrit par /review-pr) :
#   1. exactement une ligne  **HEAD** : `<sha7>`  égale au sha du fichier (pas un rapport recopié d'un autre commit) ;
#   2. exactement une section `## Verdict`, lue jusqu'au titre suivant, contenant :
#        - **Prêt pour `/ship-pr`** : oui      (« oui » seul, exactement : « non » ou « oui (…) » bloquent)
#        - **À trancher** : N                  (N ≥ 0 ; un « à trancher » bloque le merge, pas le push)
#   3. exactement une ligne  **Niveau** : docs|leger|complet  d'un palier au moins égal à celui que
#      review-level.sh calcule pour ce commit (le palier ne se négocie pas : l'agent ne peut pas s'accorder le léger).
#   4. sur une branche de correctif de bug (FIX_BRANCH_RE, défaut `^fix/`) : la preuve inversée
#      `<REVIEW_DIR>/fix-proof-<sha7>.md` écrite par fix-proof.sh pour ce commit (ligne **HEAD** complète + `Verdict : ok`).
# Un commit déjà contenu dans la base (origin/<base>) n'apporte rien de neuf : il passe sans rapport.
# Limite assumée : la porte lit le sha, la grammaire du verdict et le palier ; elle ne prouve pas que les
# angles du palier ont été joués, ni qui a écrit le rapport. La ligne **Coût** du rapport en est la trace.
#
# Bypass : une ligne `SKIP-review-pr: <raison>` (deux-points et raison obligatoires) en DÉBUT DE LIGNE dans
# le body du commit jugé, sur instruction explicite de l'utilisateur uniquement. Une phrase qui cite la
# convention (« SKIP-review-pr est réservé… ») ne déclenche rien. C'est une déclaration tracée, pas un contrôle.
#
# Réglages : review-dir.sh (config.sh optionnel). Auto-tests : review-gate.test.sh, pre-push.test.sh.
# Écrire un rapport : avec l'outil Write, jamais par un heredoc Bash — le mode PreToolUse lit la commande
# entière, heredoc compris.
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKS_DIR/review-dir.sh"
LEVEL_SH="$HOOKS_DIR/review-level.sh"
BASE_REF=""   # origin/<base>, fixé par set_base une fois le dépôt connu
set_base() { BASE_BRANCH=$(resolve_base "$1"); BASE_REF="origin/$BASE_BRANCH"; }

# verdict_check <rapport> <sha7> → 0 si « oui » ; sinon 1, cause sur stdout.
verdict_check() {
  local r="$1" s="$2" v
  [ -f "$r" ] || { echo "aucun rapport /review-pr pour ce commit"; return 1; }
  [ "$(grep -c '^\*\*HEAD\*\* : ' "$r")" = 1 ] || { echo "la ligne « **HEAD** : … » manque ou est en double (rapport recopié d'un autre commit ?)"; return 1; }
  grep -q "^\*\*HEAD\*\* : \`$s" "$r" || { echo "la ligne HEAD du rapport ne cite pas $s (rapport d'un autre commit)"; return 1; }
  [ "$(grep -c '^## Verdict' "$r")" = 1 ] || { echo "section « ## Verdict » absente ou en double"; return 1; }
  v=$(awk '/^## Verdict/{f=1;print;next} /^## /{f=0} f' "$r")
  printf '%s\n' "$v" | grep -q '^- \*\*Prêt pour `[/$]ship-pr`\*\* : oui$' \
    || { echo "verdict « Prêt pour /ship-pr : oui » absent sous ## Verdict (zéro dette : un « non », une parenthèse ou toute autre forme bloque)"; return 1; }
  printf '%s\n' "$v" | grep -qE '^- \*\*À trancher\*\* : [0-9]+' \
    || { echo "ligne « - **À trancher** : N » absente sous ## Verdict"; return 1; }
  return 0
}

# level_check <rapport> <racine> <sha> → 0 si le palier écrit est ≥ au palier calculé ; sinon 1, cause sur stdout.
level_check() {
  local r="$1" root="$2" sha="$3" out rc calc why reported rank_r rank_c n_commits
  [ -f "$LEVEL_SH" ] || { echo "review-level.sh introuvable à côté de la porte ($HOOKS_DIR) : palier incalculable"; return 1; }
  if ! git -C "$root" rev-parse --verify -q "$BASE_REF" >/dev/null 2>&1; then
    echo "palier de review invérifiable : pas de ref $BASE_REF dans $root — jouer « git fetch origin $BASE_BRANCH » puis relancer (ou régler REVIEW_BASE_BRANCH dans config.sh) (la porte ne se contente jamais d'un palier non calculé)"
    return 1
  fi
  out=$(bash "$LEVEL_SH" "$root" "$BASE_REF" "$sha" 2>&1); rc=$?
  [ "$rc" = 0 ] || { echo "palier incalculable : ${out:-review-level.sh en erreur}"; return 1; }
  calc=$(printf '%s\n' "$out" | sed -n 1p); why=$(printf '%s\n' "$out" | sed -n 2p)
  n_commits=$(git -C "$root" rev-list --count "$BASE_REF..$sha" 2>/dev/null) || n_commits=""
  case "$n_commits" in ''|*[!0-9]*) echo "portée incalculable : « git rev-list $BASE_REF..$sha » n'a pas rendu de compte de commits"; return 1 ;; esac
  if [ "$n_commits" -eq 0 ]; then
    echo "aucun commit devant $BASE_REF : la portée mesurée est vide (rien à pousser, ou ref de base déplacée sur ce commit)"
    return 1
  fi
  [ "$(grep -c '^\*\*Niveau\*\* : ' "$r")" = 1 ] \
    || { echo "la ligne « **Niveau** : … » manque ou est en double dans le rapport (une ligne de gabarit citée dans un bloc de code compte : une seule, en clair ; palier calculé : $calc)"; return 1; }
  reported=$(grep -m1 -E '^\*\*Niveau\*\* : ' "$r" | sed -E 's/^\*\*Niveau\*\* : *([^ (]+).*/\1/')
  rank_r=$(bash "$LEVEL_SH" --rank "$reported" 2>/dev/null) \
    || { echo "palier inconnu dans le rapport : « $reported » (attendu docs|leger|complet ; calculé : $calc)"; return 1; }
  rank_c=$(bash "$LEVEL_SH" --rank "$calc" 2>/dev/null) || { echo "palier calculé illisible : « $calc »"; return 1; }
  [ "$rank_r" -ge "$rank_c" ] \
    || { echo "niveau de review insuffisant : rapport « $reported », palier calculé « $calc » ($why) — rejouer /review-pr au bon palier"; return 1; }
  return 0
}

# proof_check <racine> <sha> <branche> → 0 si rien à exiger ou preuve inversée valable pour ce commit ; sinon 1, cause sur stdout.
proof_check() {
  local root="$1" sha="$2" branch="$3" proof
  if ! printf '%s' "$branch" | grep -qE "$FIX_BRANCH_RE" \
     && ! git -C "$root" log --format=%B "$BASE_REF..$sha" 2>/dev/null | grep -q '^preuve inversée ok'; then
    return 0
  fi
  proof="$root/$(review_dir)/fix-proof-${sha:0:7}.md"
  [ -f "$proof" ] || { echo "branche de correctif sans preuve inversée valable pour ce commit : $proof absent (jouer fix-proof.sh, ou /fix-bug)"; return 1; }
  grep -q "^- \*\*HEAD\*\* : $sha" "$proof" || { echo "la preuve inversée $proof ne cite pas le sha complet du commit (preuve d'un autre commit)"; return 1; }
  grep -q '^Verdict : ok$' "$proof" || { echo "la preuve inversée $proof ne porte pas « Verdict : ok »"; return 1; }
  return 0
}

# check_commit <racine> <sha> <branche> : 0 si le commit peut partir ; sinon message sur stderr et 1.
check_commit() {
  local ROOT="$1" SHA="$2" BRANCH="${3:-}" REPORT CAUSE
  set_base "$ROOT"
  [ -n "$BRANCH" ] || BRANCH="HEAD détaché"
  # Déjà dans la base : rien de neuf ne part avec ce commit.
  if git -C "$ROOT" rev-parse --verify -q "$BASE_REF" >/dev/null 2>&1 \
     && git -C "$ROOT" merge-base --is-ancestor "$SHA" "$BASE_REF" 2>/dev/null; then
    return 0
  fi
  # Bypass : instruction explicite de l'utilisateur, tracée dans le body du commit.
  if git -C "$ROOT" log -1 --format=%B "$SHA" 2>/dev/null | grep -qE '^SKIP-review-pr:[[:space:]]*[^[:space:]]'; then
    echo "⚠️  review-gate : bypass SKIP-review-pr sur ${SHA:0:7} — instruction explicite de l'utilisateur requise, traçable dans le commit." >&2
    return 0
  fi
  REPORT="$ROOT/$(review_dir)/$SHA.md"
  if CAUSE=$(verdict_check "$REPORT" "${SHA:0:7}") && CAUSE=$(level_check "$REPORT" "$ROOT" "$SHA") \
     && CAUSE=$(proof_check "$ROOT" "$SHA" "$BRANCH"); then
    return 0
  fi
  {
    echo "🛑 review-gate : $CAUSE — commit ${SHA:0:7} (branche $BRANCH)."
    echo "   Rapport attendu : $REPORT, écrit par /review-pr (lecture COMPLÈTE du diff, jamais grep seul, même pour des docs)."
    echo "   Il doit porter : exactement une ligne « **HEAD** : \`${SHA:0:7}\` » ; une section « ## Verdict » contenant"
    echo "   « - **Prêt pour \`/ship-pr\`** : oui » (« oui » seul, exactement ; « non » = findings ouverts : corriger puis re-reviewer)"
    echo "   et « - **À trancher** : N » (0 si aucun) ; plus une ligne « **Niveau** : docs|leger|complet » au moins égale"
    echo "   au palier calculé par review-level.sh (base : $BASE_REF)."
    echo "   Chaque nouveau commit change le sha et périme le rapport : rejouer /review-pr avant chaque push."
    echo "   Bypass = une ligne « SKIP-review-pr: <raison> » en début de ligne dans le body du commit, sur instruction explicite de l'utilisateur uniquement."
  } >&2
  return 1
}

case "${1:-}" in
  --verdict)
    [ -n "${2:-}" ] || { echo "usage : review-gate.sh --verdict <rapport.md>" >&2; exit 1; }
    VSHA=$(basename "$2" .md); VDIR=$(cd "$(dirname "$2")" 2>/dev/null && pwd -P)
    VROOT=$(git -C "$VDIR" rev-parse --show-toplevel 2>/dev/null) || { echo "review-gate --verdict : le rapport n'est pas dans un dépôt git ($2)" >&2; exit 1; }
    set_base "$VROOT"
    if CAUSE=$(verdict_check "$2" "$(printf '%s' "$VSHA" | cut -c1-7)") && CAUSE=$(level_check "$2" "$VROOT" "$VSHA"); then exit 0; fi
    echo "review-gate --verdict : $CAUSE" >&2; exit 1 ;;
  --commit)
    [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "usage : review-gate.sh --commit <racine> <sha> <branche>" >&2; exit 2; }
    check_commit "$2" "$3" "${4:-}" || exit 2
    exit 0 ;;
esac

# ── Mode hook PreToolUse ────────────────────────────────────────────────────────────────────
INPUT=$(cat)
CMD=""; CWD=""; JQ_OK=1
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || JQ_OK=0
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null) || JQ_OK=0
else
  JQ_OK=0
fi
if [ "$JQ_OK" = 0 ]; then
  # Payload illisible : fermé par défaut seulement si la commande brute ressemble à un push.
  if printf '%s' "$INPUT" | grep -qE '(git[^"]*push|gh[^"]*pr[^"]*create)'; then
    echo "🛑 review-gate : payload PreToolUse illisible (jq absent ou en erreur) alors que la commande brute ressemble à un push — porte fermée par défaut. Installer jq." >&2
    exit 2
  fi
  exit 0
fi
[ -z "$CMD" ] && exit 0
CWD=${CWD:-$PWD}

refuse() { echo "🛑 review-gate : $1" >&2; exit 2; }

# 1. Rien ne désactive le hook git pre-push.
if printf '%s' "$CMD" | grep -qiE '(-c[[:space:]]*|config[[:space:]].*)core\.hookspath|GIT_CONFIG_(PARAMETERS|COUNT)'; then
  refuse "la commande règle core.hooksPath (git -c, git config, GIT_CONFIG_*) : c'est par là que git trouve le hook pre-push du kit — jamais modifié par un agent."
fi
PUSH_WORD='(^|[^[:alnum:]_.-])push([^[:alnum:]_.-]|$)'
LOOKS_PUSH=0
if printf '%s' "$CMD" | grep -qE "$PUSH_WORD" && printf '%s' "$CMD" | grep -q 'git'; then LOOKS_PUSH=1; fi
if [ "$LOOKS_PUSH" = 1 ]; then
  printf '%s' "$CMD" | grep -qE -- '--no-verify' \
    && refuse "« push --no-verify » saute le hook pre-push (garde des branches protégées + porte de review) — interdit sans instruction explicite de l'utilisateur, qui le lance lui-même."
  printf '%s' "$CMD" | grep -qE 'hooks/pre-push|\.git/hooks' \
    && refuse "un push dans la même commande qu'un accès au hook pre-push — séparer, et ne jamais retirer ce hook."
fi

ACTIONS=$(parse_push_cmd "$CMD" "$CWD")
TAB=$(printf '\t')

# 2. Un push part vers un dépôt où le hook git est branché.
if [ "$LOOKS_PUSH" = 1 ]; then
  DIRS="$CWD"
  while IFS="$TAB" read -r kind dir _rest; do
    case "$kind" in push|opaque) [ -d "$dir" ] && DIRS="$DIRS$TAB$dir" ;; esac
  done <<EOF_ACTIONS
$ACTIONS
EOF_ACTIONS
  IFS="$TAB" read -r -a DIR_LIST <<< "$DIRS"
  for d in "${DIR_LIST[@]}"; do
    R=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || continue
    prepush_installed "$R" || refuse "le hook git pre-push du kit n'est pas installé dans $R : sans lui, rien ne contrôle ce qui part. Lancer « bash $HOOKS_DIR/install-git-hooks.sh » depuis ce dépôt, puis relancer."
  done
fi

# 3. Ouverture de PR : HEAD doit être reviewé (gh ne passe par aucun hook git).
[ -n "$ACTIONS" ] || exit 0
if printf '%s\n' "$ACTIONS" | awk -F'\t' '$1=="commit"{c=1} $1=="pr"&&c{f=1} END{exit !f}'; then
  refuse "commit et ouverture de PR dans la même commande : la porte lit HEAD avant le commit — committer, rejouer /review-pr sur le nouveau HEAD, puis ouvrir la PR dans un appel séparé."
fi
while IFS="$TAB" read -r kind dir _rest; do
  [ "$kind" = pr ] || continue
  [ -d "$dir" ] || refuse "dépôt visé « $dir » non résoluble — écrire le chemin absolu en clair."
  ROOT=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
  protect_base "$ROOT"
  BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null || true)
  if [ -n "$BRANCH" ] && is_protected "$BRANCH"; then continue; fi
  SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null) || continue
  check_commit "$ROOT" "$SHA" "$BRANCH" || exit 2
done <<EOF_ACTIONS
$ACTIONS
EOF_ACTIONS
exit 0
