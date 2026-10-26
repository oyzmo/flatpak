# flatpak.oyzmo.no

The Flatpak repository for apps by oyzmo, served by GitHub Pages at
<https://flatpak.oyzmo.no/>. Apps installed from here get their updates
through GNOME Software's Updates page, or with `flatpak update`.

## Install an app

Open the app's `.flatpakref` link in GNOME Software, or run the command for it.

[Bindle](https://flatpak.oyzmo.no/bindle.flatpakref), a small Markdown editor:

```sh
flatpak install https://flatpak.oyzmo.no/bindle.flatpakref
```

[wdill](https://flatpak.oyzmo.no/wdill.flatpakref), a 3D print file viewer:

```sh
flatpak install https://flatpak.oyzmo.no/wdill.flatpakref
```

[rmMeta](https://flatpak.oyzmo.no/rmmeta.flatpakref), which removes hidden
metadata from photos and documents:

```sh
flatpak install https://flatpak.oyzmo.no/rmmeta.flatpakref
```

## Add the whole repository

```sh
flatpak remote-add --if-not-exists oyzmo https://flatpak.oyzmo.no/oyzmo.flatpakrepo
```

## How it works

`repo/` is an OSTree repository, signed with the key in `oyzmo.gpg`, whose
fingerprint is:

```
D7E0 928E 8C3C 9F33 7EDB  33C0 82C7 3A44 E204 0291
```

It is written by `tools/publish.sh`, which each app's flatpak build script
calls; nothing in it is edited by hand. `tools/push.sh` puts the site live,
and `tools/backup-key.sh` backs the signing key up to the NAS. The key itself
lives in `~/.local/share/oyzmo-flatpak/`, never in this repository.
