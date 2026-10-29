# review-dir.sh — configuration commune des hooks de review + dossier de la preuve.
# SOURCÉ par les autres scripts (jamais exécuté seul). Source unique des valeurs par défaut.
#
# Réglages (tous optionnels) : copier un fichier `.claude/hooks/config.sh` à côté des hooks et y
# poser les variables à changer. Il est sourcé ici, une seule fois, avant les défauts.
#
#   REVIEW_BASE_BRANCH    branche de base des PR (défaut : develop)
#   PROTECTED_BRANCHES    branches où le push direct est refusé, séparées par des espaces (défaut : "develop main")
#   REVIEW_DIR            dossier des rapports, relatif à la racine du dépôt (défaut : .claude/reviews)
#   FIX_BRANCH_RE         regex ERE des branches de correctif de bug, qui exigent une preuve inversée (défaut : ^fix/)
#   REVIEW_LIGHT_MAX     seuil de lignes applicatives du palier `leger` (défaut : 150)
#   REVIEW_SENSITIVE_RE   regex ERE des chemins sensibles (un seul suffit pour le palier `complet`)
#   REVIEW_DOC_RE         regex ERE des chemins « texte pur »
#   REVIEW_TEST_RE        regex ERE des chemins de test
#   REVIEW_NONAPP_RE      regex ERE des chemins non applicatifs (docs, config d'outillage)

_HOOKS_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -f "$_HOOKS_SELF_DIR/config.sh" ] && . "$_HOOKS_SELF_DIR/config.sh"
# Un placeholder {{...}} que /setup-project n'a pas remplacé vaut « non réglé » : défaut appliqué.
case "${REVIEW_BASE_BRANCH:-}" in *"{{"*) unset REVIEW_BASE_BRANCH ;; esac
case "${PROTECTED_BRANCHES:-}" in *"{{"*) unset PROTECTED_BRANCHES ;; esac

: "${REVIEW_BASE_BRANCH:=develop}"
: "${PROTECTED_BRANCHES:=develop main}"
: "${REVIEW_DIR:=.claude/reviews}"
: "${FIX_BRANCH_RE:=^fix/}"
: "${REVIEW_LIGHT_MAX:=150}"
: "${REVIEW_SENSITIVE_RE:=(^|/)(auth|authn|authz|security|permissions?|middleware|migrations?|payments?|billing|crypto|secrets?)(/|\.[^/]+$|$)|(^|/)\.github/workflows/|(^|/)(\.husky|\.githooks)/|(^|/)scripts/hooks/|^\.claude/(settings[^/]*\.json$|agents/|hooks/|skills/review-pr/)|(^|/)(Dockerfile[^/]*|docker-compose[^/]*\.ya?ml)$|(^|/)(infra|terraform)/}"
: "${REVIEW_DOC_RE:=\.(md|mdx|txt|rst|example)$}"
: "${REVIEW_TEST_RE:=^((apps|packages|services)/[^/]+/)?(tests?|e2e)/|(^|/)__(tests|snapshots)__/|\.(test|spec)\.[a-z]+$}"
: "${REVIEW_NONAPP_RE:=^docs/|^\.claude/|^\.github/|(^|/)(LICENSE|CODEOWNERS|\.gitignore|\.gitattributes|\.editorconfig|\.nvmrc)$}"

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
