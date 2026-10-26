#!/usr/bin/env bash
# Back up the signing key. It exists only on this machine; if it is lost, no
# update can be signed again and everyone has to reinstall. This keeps an
# exported copy in a private repo on the NAS, never on GitHub.
# Restore with: gpg --homedir <dir> --import oyzmo-flatpak-key.asc
set -euo pipefail

KEYS="$HOME/.local/share/oyzmo-flatpak"
GNUPG="${FLATPAK_GNUPG:-$KEYS/gnupg}"
DIR="$KEYS/backup"
KEY=D7E0928E8C3C9F337EDB33C082C73A44E2040291
NAS_REPO=oyzmo-flatpak-key

ok()  { printf '\033[32m✔ %s\033[0m\n' "$*"; }
err() { printf '\033[31m✘ %s\033[0m\n' "$*" >&2; }

gpg --homedir "$GNUPG" --list-secret-keys "$KEY" >/dev/null 2>&1 \
    || { err "No signing key in $GNUPG."; exit 1; }
mkdir -p "$DIR" && chmod 700 "$DIR"
(umask 077; gpg --homedir "$GNUPG" --armor --export-secret-keys "$KEY" > "$DIR/oyzmo-flatpak-key.asc")
cp "$GNUPG/openpgp-revocs.d/$KEY.rev" "$DIR/" 2>/dev/null || true
printf '%s\n' "Signing key for flatpak.oyzmo.no. Restore on a new machine with:" \
    "  mkdir -p -m 700 $GNUPG && gpg --homedir $GNUPG --import oyzmo-flatpak-key.asc" \
    > "$DIR/README"
if [ ! -d "$DIR/.git" ]; then
    git -C "$DIR" init -q -b master
    git -C "$DIR" config user.name oyzmo
    git -C "$DIR" config user.email 74640760+oyzmo@users.noreply.github.com
    git -C "$DIR" remote add nas "softserve:$NAS_REPO.git"
    # Private before the first push, so the key is never readable.
    ssh softserve repo create "$NAS_REPO" --private --hidden >/dev/null 2>&1 || true
fi
ssh softserve repo private "$NAS_REPO" true || { err "Could not make $NAS_REPO private — not pushing."; exit 1; }
git -C "$DIR" add -A
git -C "$DIR" diff --cached --quiet || git -C "$DIR" commit -q -m "Signing key backup"
git -C "$DIR" push -q nas master || { err "Push to the NAS failed."; exit 1; }

check="$(mktemp -d /tmp/keycheck.XXXXXX)"
trap 'rm -rf "$check"' EXIT
if git clone -q "softserve:$NAS_REPO.git" "$check/r" && \
        gpg --show-keys --with-colons "$check/r/oyzmo-flatpak-key.asc" 2>/dev/null | grep -q "$KEY"; then
    ok "Key backed up to softserve:$NAS_REPO.git (private) and verified."
else
    err "The NAS copy did not verify."
    exit 1
fi
