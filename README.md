# flatpak.oyzmo.no

The Flatpak repository for apps by oyzmo, served by GitHub Pages at
<https://flatpak.oyzmo.no/>.

- Install an app: open its `.flatpakref` in GNOME Software, or
  `flatpak install https://flatpak.oyzmo.no/<app>.flatpakref` with `<app>` one of
  [`bindle`](https://flatpak.oyzmo.no/bindle.flatpakref),
  [`wdill`](https://flatpak.oyzmo.no/wdill.flatpakref),
  [`rmmeta`](https://flatpak.oyzmo.no/rmmeta.flatpakref).
  Updates then arrive through GNOME Software's Updates page / `flatpak update`.
- Add the whole repo: `flatpak remote-add --if-not-exists oyzmo https://flatpak.oyzmo.no/oyzmo.flatpakrepo`

`repo/` is an OSTree repository, signed with the key in `oyzmo.gpg`
(fingerprint `D7E0 928E 8C3C 9F33 7EDB  33C0 82C7 3A44 E204 0291`). It is
written by `tools/publish.sh`, which each app's flatpak build script calls;
nothing in it is edited by hand. `tools/push.sh` puts the site live and
`tools/backup-key.sh` backs the signing key up to the NAS (the key itself
lives in `~/.local/share/oyzmo-flatpak/`, never in this repo).
