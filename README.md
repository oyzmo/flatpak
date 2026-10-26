# flatpak.oyzmo.no

The Flatpak repository for apps by oyzmo, served by GitHub Pages at
<https://flatpak.oyzmo.no/>.

- Install Bindle: open [`bindle.flatpakref`](https://flatpak.oyzmo.no/bindle.flatpakref)
  in GNOME Software, or `flatpak install https://flatpak.oyzmo.no/bindle.flatpakref`.
  Updates then arrive through GNOME Software's Updates page / `flatpak update`.
- Add the whole repo: `flatpak remote-add --if-not-exists oyzmo https://flatpak.oyzmo.no/oyzmo.flatpakrepo`

`repo/` is an OSTree repository, signed with the key in `oyzmo.gpg`
(fingerprint `D7E0 928E 8C3C 9F33 7EDB  33C0 82C7 3A44 E204 0291`). It is
written by each app's `buildflatpak.sh`; nothing here is edited by hand.
