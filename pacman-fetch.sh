#!/bin/sh
# pacman XferCommand wrapper that injects a bearer token for github.com
# requests. All other URLs pass through as plain curl downloads.
#
# Install:
#   sudo install -Dm755 pacman-fetch.sh /usr/local/bin/pacman-github-fetch
#   echo 'REPO_ARCH_TOKEN=<your-PAT>' | sudo tee -a /etc/environment
#
# In /etc/pacman.conf under [options]:
#   XferCommand = /usr/local/bin/pacman-github-fetch %u %o
#
# And change [repo-arch]'s Server to the plain URL (no userinfo):
#   Server = https://github.com/mythofmeat/repo-arch/releases/download/latest
#
# Rationale: embedding the token in the Server URL works for the initial
# request to github.com but breaks on the 302 redirect to GitHub's S3-backed
# asset store if curl's redirect handling drops the Basic auth. Passing the
# token as a header lets curl handle the redirect correctly — the bearer
# header is dropped on cross-host redirect (as it should be), and S3's
# presigned URL handles its own auth from there.

set -eu
url="$1"
out="$2"

case "$url" in
    *github.com*)
        if [ -z "${REPO_ARCH_TOKEN:-}" ]; then
            echo "pacman-github-fetch: REPO_ARCH_TOKEN not set" >&2
            exit 1
        fi
        exec curl -fLC - -o "$out" \
            -H "Authorization: Bearer ${REPO_ARCH_TOKEN}" \
            -H "Accept: application/octet-stream" \
            "$url"
        ;;
    *)
        exec curl -fLC - -o "$out" "$url"
        ;;
esac
