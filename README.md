# repo-arch

Aggregated Arch Linux package repository for `mythofmeat` personal projects.

This repo does not hold source code. It holds the pacman-compatible package
database (`repo-arch.db`, `repo-arch.files`) and `.pkg.tar.zst` artifacts as
assets on a single rolling GitHub Release tagged `latest`. Project CIs push
into that release on tag builds.

## Consuming the repo

The repo is private, so a PAT (fine-grained, scoped to this repo, **Contents:
Read**) is mandatory. Embedding it in the Server URL *does not work* — the
release-asset 302 redirect to GitHub's S3 backend drops the Basic auth
header and the download 404s. Use the wrapper script below instead.

### 1. Install the fetch wrapper

```sh
sudo install -Dm755 pacman-fetch.sh /usr/local/bin/pacman-github-fetch
```

### 2. Provide the token via environment

```sh
echo 'REPO_ARCH_TOKEN=<your-PAT>' | sudo tee /etc/environment.d/repo-arch.conf
# or append to /etc/environment if you prefer — systemd-aware shells pick up both
```

### 3. Configure pacman

In `/etc/pacman.conf`, under `[options]`:

```ini
XferCommand = /usr/local/bin/pacman-github-fetch %u %o
```

And the repo section (no userinfo in the URL now):

```ini
[repo-arch]
SigLevel = Optional TrustAll
Server = https://github.com/mythofmeat/repo-arch/releases/download/latest
```

The wrapper only injects auth when the URL hits `github.com`; other Arch
mirrors pass through as plain curl downloads.

### 4. Sync and install

```sh
sudo pacman -Sy
sudo pacman -S shore-daemon shore-cli shore-tui shore-matrix
```

## Publishing into the repo (for project CIs)

Project workflows call `gh` with a PAT that has **Contents: Read+Write** on
this repo. The flow on each tag build:

1. Build `.pkg.tar.zst` via `makepkg`.
2. `gh release download latest -R mythofmeat/repo-arch -p '*.db.tar.zst' -p '*.pkg.tar.zst'`
3. Extract existing db, run `repo-add repo-arch.db.tar.zst <new pkgs>` to merge.
4. `gh release upload latest -R mythofmeat/repo-arch --clobber <new pkgs> *.db *.db.tar.zst *.files *.files.tar.zst`

The `--clobber` flag replaces existing same-named assets so the release stays
coherent.
