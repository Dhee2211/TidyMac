#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=TidyMac.app
rm -rf $APP
mkdir -p $APP/Contents/MacOS
swiftc -O -parse-as-library -swift-version 5 TidyMac.swift -o $APP/Contents/MacOS/TidyMac
cat > $APP/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>TidyMac</string>
<key>CFBundleExecutable</key><string>TidyMac</string>
<key>CFBundleIdentifier</key><string>local.tidymac</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>TidyMac asks Finder to empty the Trash.</string>
</dict></plist>
EOF
codesign --force --sign - $APP
echo "Built $PWD/$APP"
