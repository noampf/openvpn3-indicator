#!/usr/bin/env bash
set -euo pipefail

# Simple builder for a Debian package artifact
# Usage:
#   scripts/build_deb.sh            # uses numeric version from git commit count
#   scripts/build_deb.sh 72.0       # or provide an explicit version

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-$(git rev-list --count HEAD).0}"
STAGE_DIR="debian/openvpn3-indicator"

echo "[i] Cleaning previous staging directory"
rm -rf debian
mkdir -p debian

echo "[i] Staging files via Makefile"
make DESTDIR="$STAGE_DIR" BINDIR=/usr/bin DATADIR=/usr/share HARDCODE_PYTHON=/usr/bin/python3 package

echo "[i] Writing DEBIAN/control"
mkdir -p "$STAGE_DIR/DEBIAN"
cat > "$STAGE_DIR/DEBIAN/control" <<EOF
Package: openvpn3-indicator
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-gi, gir1.2-ayatanaappindicator3-0.1, python3-secretstorage, python3-setproctitle, openvpn3-linux (>= 20) | openvpn3
Maintainer: OpenVPN3 Indicator Maintainers <grzegorz.gutowski@uj.edu.pl>
Description: Simple indicator application for OpenVPN3
 A system tray indicator to control OpenVPN3 tunnels via D-Bus.
EOF

echo "[i] Writing DEBIAN/postinst"
cat > "$STAGE_DIR/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
update-desktop-database /usr/share/applications || true
update-mime-database /usr/share/mime || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
  gtk-update-icon-cache -f -t /usr/share/icons/Yaru || true
fi
exit 0
EOF
chmod 0755 "$STAGE_DIR/DEBIAN/postinst"

echo "[i] Building .deb"
dpkg-deb --build "$STAGE_DIR" "openvpn3-indicator_${VERSION}_all.deb"
echo "[i] Built: $(pwd)/openvpn3-indicator_${VERSION}_all.deb"


