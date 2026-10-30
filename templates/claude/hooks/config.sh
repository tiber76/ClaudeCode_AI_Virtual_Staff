# config.sh — réglages des hooks de .claude/hooks/ (sourcé par review-dir.sh).
# /setup-project remplace les placeholders ; un placeholder resté tel quel vaut « défaut ».
# Toutes les variables possibles sont décrites en tête de review-dir.sh.

REVIEW_BASE_BRANCH="{{GIT_DEFAULT_BRANCH}}"
PROTECTED_BRANCHES="{{GIT_DEFAULT_BRANCH}} {{GIT_PROD_BRANCH}}"
FIX_BRANCH_PREFIX="{{GIT_PREFIX_FIX}}"
# Dossier des specs E2E (« none » ou vide si le projet n'a pas d'E2E) : e2e-level.sh en dérive E2E_SPEC_RE.
E2E_DIR="{{DIR_TESTS_E2E}}"
