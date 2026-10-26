#!/usr/bin/env bash
# Put the site live: push it to GitHub (served by Pages as flatpak.oyzmo.no,
# which is when GNOME Software sees the updates) and back it up to the NAS.
# Asks first, and says so when there is nothing new.
set -euo pipefail

SITE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ok()  { printf '\033[32m✔ %s\033[0m\n' "$*"; }
err() { printf '\033[31m✘ %s\033[0m\n' "$*" >&2; }

# Fail fast, and say why, when GitHub can't be reached over SSH, instead of
# hanging for minutes on the connect (port 22 is blocked on some networks).
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o ConnectTimeout=10}"
gh_ssh="$(ssh -o ConnectTimeout=10 -T git@github.com 2>&1 || true)"
case "$gh_ssh" in
    *"successfully authenticated"*) ;;
    *)  echo "GitHub can't be reached over SSH: ${gh_ssh%%$'\n'*}" >&2
        echo "If port 22 is blocked on this network, use port 443:" >&2
        echo "  https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port" >&2
        exit 1 ;;
esac

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
