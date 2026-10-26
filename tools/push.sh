#!/usr/bin/env bash
# Put the site live: push it to GitHub (served by Pages as flatpak.oyzmo.no,
# which is when GNOME Software sees the updates) and back it up to the NAS.
# Asks first, and says so when there is nothing new.
set -euo pipefail

SITE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ok()  { printf '\033[32m✔ %s\033[0m\n' "$*"; }
err() { printf '\033[31m✘ %s\033[0m\n' "$*" >&2; }

git -C "$SITE" fetch -q origin 2>/dev/null || true
pending="$(git -C "$SITE" log --format='  %s' origin/master..master 2>/dev/null || true)"
if [ -z "$pending" ]; then
    ok "flatpak.oyzmo.no is up to date — nothing new to publish."
    exit 0
fi
echo "  Not yet on flatpak.oyzmo.no:"
echo "$pending"
read -rp "Publish now? [y/N] " answer
[[ "$answer" == [yY]* ]] || { echo "  Cancelled."; exit 0; }
git -C "$SITE" push -q origin master || { err "Push to GitHub failed."; exit 1; }
git -C "$SITE" push -q nas master || err "Backup push to the NAS failed (GitHub is fine)."
ok "Published. GNOME Software shows the update within a few minutes."
