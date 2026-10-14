#!/usr/bin/env bash
set -e

APP_NAME="JetsamChanger"
OUTPUT_DIR="./build"
PAYLOAD_DIR="$OUTPUT_DIR/Payload"
APP_DIR="$PAYLOAD_DIR/$APP_NAME.app"

echo "=== Building $APP_NAME for iOS 17.x - 18.x ==="

rm -rf "$OUTPUT_DIR"
mkdir -p "$APP_DIR"

# Copy Plist & Assets
cp "JetsamChanger/Resources/Info.plist" "$APP_DIR/Info.plist"

echo "[*] Compiling Swift & Objective-C sources..."
# If using swiftc / clang on macOS or Linux toolchain:
if command -v swiftc &> /dev/null; then
    swiftc \
        -target arm64-apple-ios17.0 \
        -sdk $(xcrun --show-sdk-path --sdk iphoneos) \
        -import-objc-header JetsamChanger/JetsamChanger-Bridging-Header.h \
        -I JetsamChanger/Core/Kernel \
        JetsamChanger/App/JetsamChangerApp.swift \
        JetsamChanger/Core/Process/ProcessManager.swift \
        JetsamChanger/UI/Theme.swift \
        JetsamChanger/UI/ContentView.swift \
        JetsamChanger/UI/ProcessDetailView.swift \
        JetsamChanger/UI/KernelConsoleView.swift \
        JetsamChanger/Core/Kernel/KernelMemory.c \
        JetsamChanger/Core/Kernel/KernelExploit.m \
        JetsamChanger/Core/Kernel/JetsamModifier.m \
        -o "$APP_DIR/$APP_NAME"
fi

# Codesign with ldid
if command -v ldid &> /dev/null; then
    echo "[*] Applying entitlements with ldid..."
    ldid -S"JetsamChanger/Resources/JetsamChanger.entitlements" "$APP_DIR/$APP_NAME"
fi

# Package into IPA & TIPA
echo "[*] Packaging into $APP_NAME.tipa and $APP_NAME.ipa..."
cd "$OUTPUT_DIR"
zip -r9 "$APP_NAME.ipa" Payload
cp "$APP_NAME.ipa" "$APP_NAME.tipa"
cd ..

echo "=== Build Complete: $OUTPUT_DIR/$APP_NAME.tipa ==="
