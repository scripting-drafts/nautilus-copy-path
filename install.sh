#!/usr/bin/env bash
# Install the Nautilus Copy Path extension for the current user.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base="$HOME/.local/lib/nautilus-copy-path"
wrapper="$HOME/.local/bin/nautilus-copy-path"
service="$HOME/.local/share/dbus-1/services/org.gnome.Nautilus.service"

if [[ ! -f "$here/copy-path.so" || "$here/copy-path.c" -nt "$here/copy-path.so" ]]; then
    "$here/build.sh"
fi

install -d "$base" "$base/system-extensions" "$base/extensions-3.0" \
           "$HOME/.local/bin" "$(dirname "$service")"
install -m 0755 "$here/copy-path.so" "$base/copy-path.so"
install -m 0755 "$here/nautilus-copy-path.sh" "$wrapper"

if [[ -f "$service" ]] && ! grep -qF "$wrapper" "$service"; then
    cp -f "$service" "$service.before-copy-path"
fi

cat > "$service" <<EOF
[D-BUS Service]
Name=org.gnome.Nautilus
Exec=$wrapper --gapplication-service
EOF

nautilus -q 2>/dev/null || true
echo "Installed. Open Files and use Copy Path in the right-click menu."
