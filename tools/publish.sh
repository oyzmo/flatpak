#!/usr/bin/env bash
# Publish an app that flatpak-builder has already built into its own local
# OSTree repo: sign its refs into this site's repo/, refresh the summary,
# appstream and static deltas, verify, write the .flatpak bundle with this
# repo's address and key inside (so a bundle install gets its updates from
# here), and commit the site. Pushing it live is tools/push.sh.
#
#   tools/publish.sh <local-repo> <app-id> <name> <version> <bundle-path>
#
# Environment: FLATPAK_URL (default https://flatpak.oyzmo.no/repo/) — only the
# bundle carries it, so a test can point it at a local web server.
# FLATPAK_GNUPG — the signing key's GPG home; it never lives in this repo.
set -euo pipefail

[ $# -eq 5 ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
SRC="$1" APP_ID="$2" NAME="$3" VERSION="$4" BUNDLE="$5"

SITE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$SITE/repo"
URL="${FLATPAK_URL:-https://flatpak.oyzmo.no/repo/}"
GNUPG="${FLATPAK_GNUPG:-$HOME/.local/share/oyzmo-flatpak/gnupg}"
KEY=D7E0928E8C3C9F337EDB33C082C73A44E2040291
# Old builds kept per app besides the newest, for rollback and for static
# deltas from recent versions.
KEEP_DEPTH=3

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m✔ %s\033[0m\n' "$*"; }
err()  { printf '\033[31m✘ %s\033[0m\n' "$*" >&2; }

gpg --homedir "$GNUPG" --list-secret-keys "$KEY" >/dev/null 2>&1 \
    || { err "No signing key in $GNUPG."; exit 1; }
sign=(--gpg-sign="$KEY" --gpg-homedir="$GNUPG")

# The app plus its own extensions (.Debug, .Locale), nothing else the local
# repo may hold.
mapfile -t refs < <(ostree refs --repo="$SRC" \
    | grep -E "^(app|runtime)/${APP_ID//./\\.}(\.[A-Za-z]+)?/" || true)
[ ${#refs[@]} -gt 0 ] || { err "$SRC holds no build of $APP_ID."; exit 1; }

bold "Signing $NAME $VERSION into $REPO…"
for ref in "${refs[@]}"; do
    # Unchanged content (a rebuild of the same version) adds no commit.
    flatpak build-commit-from "${sign[@]}" --no-update-summary \
        --src-repo="$SRC" --src-ref="$ref" --subject="$NAME $VERSION" "$REPO" "$ref"
done

bold "Updating the summary, appstream and deltas…"
flatpak build-update-repo "${sign[@]}" --title=oyzmo \
    --homepage=https://oyzmo.no/apps --gpg-import="$SITE/oyzmo.gpg" \
    --generate-static-deltas --prune --prune-depth="$KEEP_DEPTH" "$REPO" >/dev/null
# The checkouts live on a mount that has written 0-byte files before; never
# publish a repo that doesn't verify.
ostree fsck --repo="$REPO" >/dev/null || { err "$REPO failed ostree fsck — don't push it."; exit 1; }

bold "Creating $(basename "$BUNDLE")…"
# Bundle to a real filesystem first, then copy in, for the same reason.
stage="$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/oyzmo-bundle.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
flatpak build-bundle --repo-url="$URL" --gpg-keys="$SITE/oyzmo.gpg" \
    --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
    "$REPO" "$stage/bundle.flatpak" "$APP_ID"
mkdir -p "$(dirname "$BUNDLE")"
cp "$stage/bundle.flatpak" "$BUNDLE"
[ "$(stat -c%s "$BUNDLE")" = "$(stat -c%s "$stage/bundle.flatpak")" ] \
    || { err "Copying the bundle to $BUNDLE came out wrong."; exit 1; }

git -C "$SITE" add -A
if git -C "$SITE" diff --cached --quiet; then
    ok "$NAME $VERSION was already published; bundle written to $BUNDLE"
else
    git -C "$SITE" commit -q -m "$NAME $VERSION"
    ok "Published $NAME $VERSION into $SITE (committed) and wrote $BUNDLE"
    echo "  Make it live with: $SITE/tools/push.sh"
fi
