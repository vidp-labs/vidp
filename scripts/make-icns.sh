#!/bin/bash
# Regenerates resources/vidp.icns from resources/AppIcon*.png.
# Run on your Mac (NOT inside the Homebrew sandbox: iconutil needs
# system services the brew build sandbox denies). Commit the result.
set -euo pipefail
cd "$(dirname "$0")/.."

ICONSET="$(mktemp -d)/AppIcon.iconset"
trap 'rm -rf "$ICONSET"' EXIT
mkdir -p "$ICONSET"
cp resources/AppIcon16.png "$ICONSET/icon_16x16.png"
cp resources/AppIcon32.png "$ICONSET/icon_16x16@2x.png"
cp resources/AppIcon32.png "$ICONSET/icon_32x32.png"
cp resources/AppIcon64.png "$ICONSET/icon_32x32@2x.png"
cp resources/AppIcon128.png "$ICONSET/icon_128x128.png"
cp resources/AppIcon256.png "$ICONSET/icon_128x128@2x.png"
cp resources/AppIcon256.png "$ICONSET/icon_256x256.png"
cp resources/AppIcon512.png "$ICONSET/icon_256x256@2x.png"
cp resources/AppIcon512.png "$ICONSET/icon_512x512.png"
cp resources/AppIcon1024.png "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o resources/vidp.icns
rm -rf "$ICONSET"

echo "Wrote resources/vidp.icns"
