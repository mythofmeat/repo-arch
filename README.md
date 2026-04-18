# repo-arch

Aggregated Arch Linux package repository for `mythofmeat` personal projects.

This repo does not hold source code. It holds the pacman-compatible package
database (`repo-arch.db`, `repo-arch.files`) and `.pkg.tar.zst` artifacts as
assets on a single rolling GitHub Release tagged `latest`. Project CIs push
into that release on tag builds.

## Consuming the repo

In `/etc/pacman.conf`:

```ini
[repo-arch]
SigLevel = Optional TrustAll
Server = https://github.com/mythofmeat/repo-arch/releases/download/latest
```

Then:

```sh
sudo pacman -Sy
sudo pacman -S shore-daemon shore-cli shore-tui shore-matrix
```

The repo is public so no auth is required. (Project source repos stay
private; only the compiled package binaries are published here.)

## Publishing into the repo (for project CIs)

Project workflows call `gh` with a PAT that has **Contents: Read+Write** on
this repo. The flow on each tag build:

1. Build `.pkg.tar.zst` via `makepkg`.
2. `gh release download latest -R mythofmeat/repo-arch -p '*.db.tar.zst' -p '*.pkg.tar.zst'`
3. Extract existing db, run `repo-add repo-arch.db.tar.zst <new pkgs>` to merge.
4. `gh release upload latest -R mythofmeat/repo-arch --clobber <new pkgs> *.db *.db.tar.zst *.files *.files.tar.zst`

The `--clobber` flag replaces existing same-named assets so the release stays
coherent.
