#!/usr/bin/env bash
# review-gate.sh — porte de review : bloque `git push` et `gh pr create` sans rapport /review-pr valide.
#
# Branchement : hook PreToolUse (matcher Bash) de Claude Code — le payload JSON arrive sur stdin
# (jq requis). Exit 2 + message sur stderr = commande bloquée. Exit 0 = laissée passer.
#
# La porte exige, pour le commit HEAD, le rapport `<REVIEW_DIR>/<sha complet>.md` (écrit par /review-pr) :
#   1. exactement une ligne  **HEAD** : `<sha7>`  égale au sha du fichier (pas un rapport recopié d'un autre commit) ;
#   2. exactement une section `## Verdict`, lue jusqu'au titre suivant, contenant :
#        - **Prêt pour `/ship-pr`** : oui      (« oui » seul, exactement : « non » ou « oui (…) » bloquent)
#        - **À trancher** : N                  (N ≥ 0 ; un « à trancher » bloque le merge, pas le push)
#   3. exactement une ligne  **Niveau** : docs|leger|complet  d'un palier au moins égal à celui que
#      review-level.sh calcule pour HEAD (le palier ne se négocie pas : l'agent ne peut pas s'accorder le léger).
#   4. sur une branche de correctif de bug (FIX_BRANCH_RE, défaut `^fix/`) : la preuve inversée
#      `<REVIEW_DIR>/fix-proof-<sha7>.md` écrite par fix-proof.sh pour HEAD (ligne **HEAD** complète + `Verdict : ok`).
# Limite assumée : la porte lit le sha, la grammaire du verdict et le palier ; elle ne prouve pas que les
# angles du palier ont été joués, ni qui a écrit le rapport. La ligne **Coût** du rapport en est la trace.
#
# Bypass : une ligne `SKIP-review-pr …` en DÉBUT DE LIGNE dans le body du commit HEAD, sur instruction
# explicite de l'utilisateur uniquement (une simple mention de la convention dans un texte est ignorée).
#
# Rejouer à la main : bash review-gate.sh --verdict <racine>/.claude/reviews/<sha>.md
# Réglages : review-dir.sh (config.sh optionnel). Auto-test : review-gate.test.sh.
# Écrire un rapport : avec l'outil Write, jamais par un heredoc Bash — cette porte lit la commande
# entière, heredoc compris, et bloquerait un texte qui cite un push ou une ouverture de PR.
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKS_DIR/review-dir.sh"
LEVEL_SH="$HOOKS_DIR/review-level.sh"
BASE_REF="origin/$REVIEW_BASE_BRANCH"

# verdict_check <rapport> <sha7> → 0 si « oui » ; sinon 1, cause sur stdout.
verdict_check() {
  local r="$1" s="$2" v
  [ -f "$r" ] || { echo "aucun rapport /review-pr pour ce commit"; return 1; }
  [ "$(grep -c '^\*\*HEAD\*\* : ' "$r")" = 1 ] || { echo "la ligne « **HEAD** : … » manque ou est en double (rapport recopié d'un autre commit ?)"; return 1; }
  grep -q "^\*\*HEAD\*\* : \`$s" "$r" || { echo "la ligne HEAD du rapport ne cite pas $s (rapport d'un autre commit)"; return 1; }
  [ "$(grep -c '^## Verdict' "$r")" = 1 ] || { echo "section « ## Verdict » absente ou en double"; return 1; }
  v=$(awk '/^## Verdict/{f=1;print;next} /^## /{f=0} f' "$r")
  printf '%s\n' "$v" | grep -q '^- \*\*Prêt pour `/ship-pr`\*\* : oui$' \
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
    echo "palier de review invérifiable : pas de ref $BASE_REF dans $root — jouer « git fetch origin $REVIEW_BASE_BRANCH » puis relancer (la porte ne se contente jamais d'un palier non calculé)"
    return 1
  fi
  out=$(bash "$LEVEL_SH" "$root" "$BASE_REF" "$sha" 2>&1); rc=$?
  [ "$rc" = 0 ] || { echo "palier incalculable : ${out:-review-level.sh en erreur}"; return 1; }
  calc=$(printf '%s\n' "$out" | sed -n 1p); why=$(printf '%s\n' "$out" | sed -n 2p)
  n_commits=$(git -C "$root" rev-list --count "$BASE_REF..$sha" 2>/dev/null) || n_commits=""
  case "$n_commits" in ''|*[!0-9]*) echo "portée incalculable : « git rev-list $BASE_REF..$sha » n'a pas rendu de compte de commits"; return 1 ;; esac
  if [ "$n_commits" -eq 0 ]; then
    echo "aucun commit devant $BASE_REF : la portée mesurée est vide (rien à pousser, ou ref de base déplacée sur HEAD). Vérifier « git rev-list --count $BASE_REF..HEAD »"
    return 1
  fi
  [ "$(grep -c '^\*\*Niveau\*\* : ' "$r")" = 1 ] \
    || { echo "la ligne « **Niveau** : … » manque ou est en double dans le rapport (une ligne de gabarit citée dans un bloc de code compte : une seule, en clair ; palier calculé : $calc)"; return 1; }
  reported=$(grep -m1 -E '^\*\*Niveau\*\* : ' "$r" | sed -E 's/^\*\*Niveau\*\* : *([^ (]+).*/\1/')
  rank_r=$(bash "$LEVEL_SH" --rank "$reported" 2>/dev/null) \
    || { echo "palier inconnu dans le rapport : « $reported » (attendu docs|leger|complet ; calculé pour HEAD : $calc)"; return 1; }
  rank_c=$(bash "$LEVEL_SH" --rank "$calc" 2>/dev/null) || { echo "palier calculé illisible : « $calc »"; return 1; }
  [ "$rank_r" -ge "$rank_c" ] \
    || { echo "niveau de review insuffisant : rapport « $reported », palier calculé « $calc » ($why) — rejouer /review-pr au bon palier"; return 1; }
  return 0
}

# proof_check <racine> <sha> <branche> → 0 si rien à exiger ou preuve inversée valable pour HEAD ; sinon 1, cause sur stdout.
proof_check() {
  local root="$1" sha="$2" branch="$3" proof
  if ! printf '%s' "$branch" | grep -qE "$FIX_BRANCH_RE" \
     && ! git -C "$root" log --format=%B "$BASE_REF..$sha" 2>/dev/null | grep -q '^preuve inversée ok'; then
    return 0
  fi
  proof="$root/$(review_dir)/fix-proof-${sha:0:7}.md"
  [ -f "$proof" ] || { echo "branche de correctif sans preuve inversée valable pour HEAD : $proof absent (jouer fix-proof.sh sur HEAD, ou /fix-bug)"; return 1; }
  grep -q "^- \*\*HEAD\*\* : $sha" "$proof" || { echo "la preuve inversée $proof ne cite pas le sha complet de HEAD (preuve d'un autre commit)"; return 1; }
  grep -q '^Verdict : ok$' "$proof" || { echo "la preuve inversée $proof ne porte pas « Verdict : ok »"; return 1; }
  return 0
}

# --verdict <rapport> : rejoue les conditions à la main (exit 0 = « oui »).
if [ "${1:-}" = "--verdict" ]; then
  [ -n "${2:-}" ] || { echo "usage : review-gate.sh --verdict <rapport.md>" >&2; exit 1; }
  VSHA=$(basename "$2" .md); VDIR=$(cd "$(dirname "$2")" 2>/dev/null && pwd -P)
  VROOT=$(git -C "$VDIR" rev-parse --show-toplevel 2>/dev/null) || { echo "review-gate --verdict : le rapport n'est pas dans un dépôt git ($2)" >&2; exit 1; }
  if CAUSE=$(verdict_check "$2" "$(printf '%s' "$VSHA" | cut -c1-7)") && CAUSE=$(level_check "$2" "$VROOT" "$VSHA"); then exit 0; fi
  echo "review-gate --verdict : $CAUSE" >&2; exit 1
fi

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
    echo "🛑 review-gate : payload PreToolUse illisible (jq absent ou en erreur) alors que la commande brute ressemble à un push — porte fermée par défaut." >&2
    exit 2
  fi
  exit 0
fi
[ -z "$CMD" ] && exit 0

# Seules les commandes qui poussent ou ouvrent une PR sont jugées (segments séparés par ; | &).
TRIG='(^|[[:space:](])(git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]|[;&|)]|$)|gh[[:space:]]+pr[[:space:]]+create([[:space:]]|[;&|)]|$))'
SEGS=$(printf '%s' "$CMD" | tr ';|&' '\n')
TRIG_SEGS=$(printf '%s\n' "$SEGS" | grep -E "$TRIG" || true)
[ -n "$TRIG_SEGS" ] || exit 0
# Exemptions : rien d'applicatif ne part (tags, suppression de branche — push-target-guard garde les branches protégées).
REELS=$(printf '%s\n' "$TRIG_SEGS" | grep -vE '(--tags|--delete|[[:space:]]:[^[:space:]])' || true)
[ -n "$REELS" ] || exit 0

# Dépôt visé : `git -C <dir>` du segment, puis `cd <dir>`, puis le cwd du payload. Jamais de repli silencieux.
strip_quotes() { tr -d "\"'"; }
SEG=$(printf '%s\n' "$REELS" | head -1)
C_DIR=$(printf '%s' "$SEG" | grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $3}' | strip_quotes)
CD_DIR=$(printf '%s' "$CMD" | grep -oE '(^|[;&|][[:space:]]*)cd[[:space:]]+[^[:space:];&|]+' | head -1 | awk '{print $NF}' | strip_quotes)
DIR=""
for cand in "$C_DIR" "$CD_DIR"; do
  [ -n "$cand" ] || continue
  if [ -d "$cand" ]; then DIR="$cand"; break; fi
  echo "🛑 review-gate : dépôt visé « $cand » non résoluble (variable non développée, ~, dossier absent) — la porte ne se rabat jamais sur le dépôt courant : écrire le chemin absolu en clair." >&2
  exit 2
done
[ -n "$DIR" ] || for cand in "$CWD" "$PWD"; do
  if [ -n "$cand" ] && [ -d "$cand" ]; then DIR="$cand"; break; fi
done
ROOT=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null) || exit 0   # hors dépôt : pas notre affaire
BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null || true)
# Branche protégée : c'est push-target-guard qui juge (la review n'a pas de sens sur la base elle-même).
if [ -n "$BRANCH" ] && is_protected "$BRANCH"; then exit 0; fi
[ -n "$BRANCH" ] || BRANCH="HEAD détaché"
SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null) || exit 0

# Bypass : instruction explicite de l'utilisateur, tracée dans le body du commit.
if git -C "$ROOT" log -1 --format=%B 2>/dev/null | grep -qE '^SKIP-review-pr([[:space:]]|$)'; then
  echo "⚠️  review-gate : bypass SKIP-review-pr sur ${SHA:0:7} — instruction explicite de l'utilisateur requise, traçable dans le commit." >&2
  exit 0
fi

REPORT="$ROOT/$(review_dir)/$SHA.md"
gate_fail() {
  {
    echo "🛑 review-gate : $1 — HEAD ${SHA:0:7} (branche $BRANCH)."
    echo "   Rapport attendu : $REPORT, écrit par /review-pr (lecture COMPLÈTE du diff, jamais grep seul, même pour des docs)."
    echo "   Il doit porter : exactement une ligne « **HEAD** : \`${SHA:0:7}\` » ; une section « ## Verdict » contenant"
    echo "   « - **Prêt pour \`/ship-pr\`** : oui » (« oui » seul, exactement ; « non » = findings ouverts : corriger puis re-reviewer)"
    echo "   et « - **À trancher** : N » (0 si aucun) ; plus une ligne « **Niveau** : docs|leger|complet » au moins égale"
    echo "   au palier calculé par review-level.sh."
    echo "   Chaque nouveau commit change le sha et périme le rapport : rejouer /review-pr avant chaque push."
    echo "   Bypass = une ligne « SKIP-review-pr … » en début de ligne dans le body du commit HEAD, sur instruction explicite de l'utilisateur uniquement."
  } >&2
  exit 2
}
CAUSE=$(verdict_check "$REPORT" "${SHA:0:7}") || gate_fail "$CAUSE"
CAUSE=$(level_check "$REPORT" "$ROOT" "$SHA") || gate_fail "$CAUSE"
CAUSE=$(proof_check "$ROOT" "$SHA" "$BRANCH") || gate_fail "$CAUSE"
exit 0
