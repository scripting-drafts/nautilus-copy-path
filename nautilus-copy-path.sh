#!/usr/bin/env bash
# Launch Nautilus with the user-built Copy Path extension overlaid on the
# system extension directory. Falls back to a normal launch if unavailable.
set -euo pipefail

base="$HOME/.local/lib/nautilus-copy-path"
bin="${NAUTILUS_BIN:-$HOME/.local/bin/nautilus}"
if [[ ! -x "$bin" ]]; then
    bin="/usr/bin/nautilus"
fi

if [[ -d /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0 ]]; then
    ext_dir="/usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0"
else
    ext_dir="/usr/lib/nautilus/extensions-3.0"
fi

if [[ -f "$base/copy-path.so" && -d "$ext_dir" && -x /usr/bin/bwrap ]]; then
    mkdir -p "$base/system-extensions" "$base/extensions-3.0"
    for f in "$ext_dir"/*.so; do
        name="${f##*/}"
        if [[ "$name" == "copy-path.so" ]]; then
            continue
        fi
        ln -sfn "$base/system-extensions/$name" "$base/extensions-3.0/$name"
    done
    ln -sfn "$base/copy-path.so" "$base/extensions-3.0/copy-path.so"
    if /usr/bin/bwrap --dev-bind / / \
        --ro-bind "$ext_dir" "$base/system-extensions" \
        --ro-bind "$base/extensions-3.0" "$ext_dir" \
        /bin/true 2>/dev/null; then
        exec /usr/bin/bwrap --dev-bind / / \
            --ro-bind "$ext_dir" "$base/system-extensions" \
            --ro-bind "$base/extensions-3.0" "$ext_dir" \
            "$bin" "$@"
    fi
fi

exec "$bin" "$@"
