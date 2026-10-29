# config.sh — réglages des hooks de .codex/hooks/ (sourcé par review-dir.sh).
# /setup-project remplace les placeholders ; un placeholder resté tel quel vaut « défaut ».
# Toutes les variables possibles sont décrites en tête de review-dir.sh.

REVIEW_BASE_BRANCH="{{GIT_DEFAULT_BRANCH}}"
PROTECTED_BRANCHES="{{GIT_DEFAULT_BRANCH}} {{GIT_PROD_BRANCH}}"
