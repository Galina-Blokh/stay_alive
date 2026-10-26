#!/bin/zsh
# Builds "Stay Alive.app" and installs it into ~/Applications.
set -e
cd "$(dirname "$0")"

APP="build/Stay Alive.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/icon.iconset

swiftc -O -parse-as-library StayAlive.swift -o "$APP/Contents/MacOS/StayAlive"

# App icon
swift make_icon.swift build/icon_1024.png
for s in 16 32 128 256 512; do
  sips -z $s $s build/icon_1024.png --out build/icon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) build/icon_1024.png --out build/icon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/icon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Stay Alive</string>
  <key>CFBundleDisplayName</key><string>Stay Alive</string>
  <key>CFBundleIdentifier</key><string>local.stayalive</string>
  <key>CFBundleExecutable</key><string>StayAlive</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP"

mkdir -p ~/Applications
# Sync in place (not delete + copy) so a Dock pin keeps pointing at the app.
rsync -a --delete "$APP/" ~/Applications/"Stay Alive.app/"
echo "Installed: ~/Applications/Stay Alive.app"
