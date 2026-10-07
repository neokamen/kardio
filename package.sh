#!/usr/bin/env bash
set -e

PLASMOID_NAME="org.kde.plasma.kardio"
VERSION=$(grep '"Version"' metadata.json | cut -d '"' -f 4)
FILENAME="${PLASMOID_NAME}-v${VERSION}.plasmoid"

echo "[STATUS] Packaging $PLASMOID_NAME version $VERSION..."

zip -ry "$FILENAME" \
    metadata.json \
    org.kde.plasma.kardio.svg \
    kardio-banner.svg \
    contents \
    LICENSE \
    README.md \
    -x "*.git*" \
    -x "install.sh" \
    -x "package.sh" \
    -x "*.DS_Store"

echo "[OK] Created package: $FILENAME"

