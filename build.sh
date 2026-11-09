#!/usr/bin/env bash
# Build the Nautilus Copy Path extension without installing system packages.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build="$here/.build"
inc="$(pkg-config --cflags libnautilus-extension 2>/dev/null || true)"

if [[ -z "$inc" ]]; then
    mkdir -p "$build"
    if [[ ! -f "$build/usr/include/nautilus/nautilus-extension.h" ]]; then
        tmp="$(mktemp -d "${TMPDIR:-/tmp}/nautilus-copy-path.XXXXXX")"
        trap 'rm -rf "$tmp"' EXIT
        (cd "$tmp" && apt-get download libnautilus-extension-dev >/dev/null)
        dpkg-deb -x "$tmp"/libnautilus-extension-dev_*.deb "$build"
    fi
    inc="-I$build/usr/include/nautilus"
fi

cc -shared -fPIC -O2 -Wall -Wextra \
    $(pkg-config --cflags gtk+-3.0) $inc \
    "$here/copy-path.c" -o "$here/copy-path.so" \
    $(pkg-config --libs gtk+-3.0) \
    -L/usr/lib/$(cc -dumpmachine) -l:libnautilus-extension.so.1

echo "Built $here/copy-path.so"
