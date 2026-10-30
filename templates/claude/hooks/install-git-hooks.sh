#!/usr/bin/env bash
# install-git-hooks.sh — branche le hook git pre-push du kit (.claude/hooks/pre-push) sur le dépôt courant.
#
# À lancer une fois par clone, depuis le dépôt (worktrees compris : ils partagent les hooks du dépôt).
# Idempotent. Trois cas :
#   - aucun hook pre-push : pose un petit hook qui appelle .claude/hooks/pre-push ;
#   - un hook pre-push du kit déjà là (marqueur claude-kit:pre-push) : le met à jour ;
#   - un autre hook pre-push, ou core.hooksPath réglé (husky…) : ne touche à rien et affiche la ligne
#     à ajouter dans le hook existant (exit 1 tant qu'elle n'y est pas).
# --status : dit seulement si le hook est branché (exit 0) ou non (exit 1).
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR

. "$(cd "$(dirname "$0")" && pwd)/review-dir.sh"
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "install-git-hooks : à lancer depuis un dépôt git" >&2; exit 1; }
TARGET=$(prepush_target "$ROOT") || { echo "install-git-hooks : dossier des hooks git introuvable" >&2; exit 1; }
LINE="bash \"\$(git rev-parse --show-toplevel)/.claude/hooks/pre-push\" \"\$@\" || exit 1  # $PREPUSH_MARK"

if [ "${1:-}" = "--status" ]; then
  if prepush_installed "$ROOT"; then echo "hook pre-push du kit branché : $TARGET"; exit 0; fi
  echo "hook pre-push du kit absent : $TARGET"; exit 1
fi

if [ -f "$TARGET" ] && ! grep -q "$PREPUSH_MARK" "$TARGET"; then
  echo "Un hook pre-push existe déjà ($TARGET) : il n'est pas modifié."
  echo "Ajouter cette ligne dans ce hook (avant toute autre commande qui lit l'entrée standard) :"
  echo "  $LINE"
  exit 1
fi
if [ -n "$(git -C "$ROOT" config --get core.hooksPath 2>/dev/null)" ] && [ ! -f "$TARGET" ]; then
  echo "core.hooksPath est réglé ($(git -C "$ROOT" config --get core.hooksPath)) : le hook pre-push vit dans $TARGET."
  echo "Le créer (exécutable) avec cette ligne, ou l'ajouter au hook du gestionnaire (husky…) :"
  echo "  $LINE"
  exit 1
fi
if [ -f "$TARGET" ] && grep -q "$PREPUSH_MARK" "$TARGET" && ! grep -q '^# claude-kit-wrapper' "$TARGET"; then
  echo "hook pre-push du kit déjà branché dans $TARGET (ligne ajoutée à la main) : rien à faire."
  exit 0
fi

mkdir -p "$(dirname "$TARGET")"
cat > "$TARGET" <<'EOF_HOOK'
#!/bin/sh
# claude-kit-wrapper — posé par .claude/hooks/install-git-hooks.sh (claude-kit:pre-push), ne pas éditer.
# Appelle le hook pre-push du kit du worktree courant ; s'il manque, le push est refusé.
ROOT=$(git rev-parse --show-toplevel) || exit 1
for h in "$ROOT/.claude/hooks/pre-push" "$ROOT/.codex/hooks/pre-push"; do
  [ -f "$h" ] && exec bash "$h" "$@"
done
echo "🛑 pre-push : .claude/hooks/pre-push introuvable dans $ROOT — push refusé (réinstaller les hooks du kit, ou retirer $0)." >&2
exit 1
EOF_HOOK
chmod +x "$TARGET"
echo "hook pre-push du kit branché : $TARGET"
