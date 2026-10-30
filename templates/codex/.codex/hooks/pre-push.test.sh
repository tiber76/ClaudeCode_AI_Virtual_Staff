#!/usr/bin/env bash
# Auto-test de bout en bout du hook git pre-push : de vrais push vers un dépôt jetable.
# Prouve que git lui-même refuse ce qui part sans review ou vers une branche protégée,
# quelle que soit l'écriture de la commande. Lancer : bash .codex/hooks/pre-push.test.sh
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR
HOOKS="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1 — $2"; }

# depot <dossier> : clone jetable avec les hooks du kit copiés (non suivis) dans .codex/hooks/
depot() {
  local d="$1"
  git init -q --bare -b develop "$d.git"
  git clone -q "$d.git" "$d" 2>/dev/null
  git -C "$d" checkout -q -b develop
  echo base > "$d/README.md"; git -C "$d" add README.md
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m base
  git -C "$d" push -q origin develop
  echo ".codex/" >> "$d/.git/info/exclude"
  mkdir -p "$d/.codex/hooks"; cp -p "$HOOKS"/* "$d/.codex/hooks/"
}
W="$TMP/w"; depot "$W"
G() { git -C "$W" -c user.email=t@t -c user.name=t "$@"; }
remote_a() { git -C "$W" ls-remote --exit-code origin "refs/heads/$1" >/dev/null 2>&1; }
# envoi <attendu ok|refus> <libellé> <commande…> : lance un vrai push, vérifie son issue
envoi() {
  local want="$1" label="$2" rc; shift 2
  (cd "$W" && "$@") >/dev/null 2>"$TMP/err"; rc=$?
  if { [ "$want" = ok ] && [ "$rc" = 0 ]; } || { [ "$want" = refus ] && [ "$rc" != 0 ]; }; then ok "$label"
  else bad "$label" "exit $rc ($(head -c 300 "$TMP/err"))"; fi
}
rapport() {
  local sha; sha=$(G rev-parse HEAD); mkdir -p "$W/.codex/reviews"
  printf '# Review\n\n**HEAD** : `%s`\n**Niveau** : %s (calculé : test)\n\n## Verdict\n- **Prêt pour `/ship-pr`** : oui\n- **À trancher** : 0\n' \
    "${sha:0:7}" "$1" > "$W/.codex/reviews/$sha.md"
}

echo "Installation"
(cd "$W" && bash .codex/hooks/install-git-hooks.sh --status >/dev/null); [ $? = 1 ] && ok "--status avant installation : absent" || bad "--status" "devait rendre 1"
(cd "$W" && bash .codex/hooks/install-git-hooks.sh >/dev/null) && ok "installation" || bad "installation" "devait rendre 0"
(cd "$W" && bash .codex/hooks/install-git-hooks.sh >/dev/null) && ok "réinstallation idempotente" || bad "réinstallation" "devait rendre 0"
(cd "$W" && bash .codex/hooks/install-git-hooks.sh --status >/dev/null) && ok "--status après installation : branché" || bad "--status" "devait rendre 0"

echo "Ce qui part"
G checkout -q -b feature/x
echo more >> "$W/README.md"; G commit -qam doc
envoi refus "branche sans rapport : refusée par git"                 git push -q origin feature/x
remote_a feature/x && bad "rien n'est parti" "feature/x existe sur le remote" || ok "rien n'est parti"
envoi refus "forme dynamique sans rapport : refusée aussi"            sh -c 'B=$(git branch --show-current); GIT=git; $GIT push -q origin "$B"'
envoi refus "destination develop : refusée"                           git push -q origin HEAD:develop
rapport docs
envoi ok    "branche avec rapport : part"                             git push -q origin feature/x
remote_a feature/x && ok "la branche est sur le remote" || bad "la branche est sur le remote" "absente"
envoi refus "destination develop, même reviewée : refusée"            git push -q origin HEAD:develop
envoi ok    "effacement d'une branche de travail : passe"             git push -q origin --delete feature/x
G tag v0.1
envoi ok    "tag : passe"                                             git push -q origin v0.1

echo "Worktree"
G worktree add -q -b feature/wt "$TMP/wt" develop 2>/dev/null
mkdir -p "$TMP/wt/.codex/hooks"; cp -p "$HOOKS"/* "$TMP/wt/.codex/hooks/"
echo wt >> "$TMP/wt/README.md"; git -C "$TMP/wt" -c user.email=t@t -c user.name=t commit -qam wt
(cd "$TMP/wt" && git push -q origin feature/wt) >/dev/null 2>&1; [ $? != 0 ] && ok "worktree sans rapport : refusé (hook partagé)" || bad "worktree" "devait être refusé"

echo "Hook du kit manquant"
mv "$W/.codex/hooks/pre-push" "$TMP/pre-push.bak"
envoi refus "pre-push du kit absent : push refusé, jamais ouvert"     git push -q origin feature/x
mv "$TMP/pre-push.bak" "$W/.codex/hooks/pre-push"

echo "Hook existant ou core.hooksPath"
F="$TMP/f"; depot "$F"
printf '#!/bin/sh\necho autre\n' > "$F/.git/hooks/pre-push"; chmod +x "$F/.git/hooks/pre-push"
(cd "$F" && bash .codex/hooks/install-git-hooks.sh >/dev/null); [ $? = 1 ] && ok "hook étranger : pas d'installation, ligne à ajouter" || bad "hook étranger" "devait rendre 1"
grep -q '^echo autre$' "$F/.git/hooks/pre-push" && ! grep -q 'claude-kit' "$F/.git/hooks/pre-push" && ok "hook étranger intact" || bad "hook étranger intact" "modifié"
P="$TMP/p"; depot "$P"
git -C "$P" config core.hooksPath .githooks
(cd "$P" && bash .codex/hooks/install-git-hooks.sh >/dev/null); [ $? = 1 ] && ok "core.hooksPath réglé : ligne à ajouter" || bad "core.hooksPath" "devait rendre 1"
LINE=$(cd "$P" && bash .codex/hooks/install-git-hooks.sh 2>/dev/null | tail -1 | sed 's/^  //')
mkdir -p "$P/.githooks"; printf '#!/bin/sh\n%s\n' "$LINE" > "$P/.githooks/pre-push"; chmod +x "$P/.githooks/pre-push"
(cd "$P" && bash .codex/hooks/install-git-hooks.sh --status >/dev/null) && ok "ligne ajoutée : --status branché" || bad "--status" "devait rendre 0"
git -C "$P" checkout -q -b feature/p; echo p >> "$P/README.md"; git -C "$P" -c user.email=t@t -c user.name=t commit -qam p
(cd "$P" && git push -q origin feature/p) >/dev/null 2>&1; [ $? != 0 ] && ok "via core.hooksPath : push sans rapport refusé" || bad "via core.hooksPath" "devait être refusé"

echo; echo "pre-push : $PASS ok, $FAIL en échec"
[ "$FAIL" = 0 ]
