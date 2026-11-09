#!/usr/bin/env bash
# Remove the Nautilus Copy Path extension and restore the previous launcher.
set -euo pipefail

base="$HOME/.local/lib/nautilus-copy-path"
wrapper="$HOME/.local/bin/nautilus-copy-path"
service="$HOME/.local/share/dbus-1/services/org.gnome.Nautilus.service"
backup="$service.before-copy-path"

nautilus -q 2>/dev/null || true

if [[ -f "$backup" ]]; then
    mv -f "$backup" "$service"
else
    bin="$HOME/.local/bin/nautilus"
    [[ -x "$bin" ]] || bin="/usr/bin/nautilus"
    cat > "$service" <<EOF
[D-BUS Service]
Name=org.gnome.Nautilus
Exec=$bin --gapplication-service
EOF
fi

rm -f "$wrapper"
rm -rf "$base"
echo "Removed. Files will launch normally on next open."
