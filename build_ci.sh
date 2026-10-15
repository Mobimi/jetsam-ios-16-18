#!/usr/bin/env bash
set -ex

APP_NAME="JetsamChanger"
OUTPUT_DIR="build_output"
PAYLOAD_DIR="$OUTPUT_DIR/Payload"
APP_DIR="$PAYLOAD_DIR/$APP_NAME.app"

echo "==============================================="
echo "   Building $APP_NAME for iOS 17.x – 18.x"
echo "==============================================="

rm -rf "$OUTPUT_DIR"
mkdir -p "$APP_DIR"

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
echo "[*] Using iOS SDK: $SDK_PATH"

# Copy Info.plist and Assets
echo "[*] Copying resources..."
cp "JetsamChanger/Resources/Info.plist" "$APP_DIR/Info.plist"
printf "APPL????" > "$APP_DIR/PkgInfo"

# Compile C / Objective-C sources
echo "[*] Compiling C/Obj-C kernel sources..."
xcrun --sdk iphoneos clang -c -target arm64-apple-ios17.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/KernelMemory.c" -o "$OUTPUT_DIR/KernelMemory.o"

xcrun --sdk iphoneos clang -c -target arm64-apple-ios17.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/KernelExploit.m" -o "$OUTPUT_DIR/KernelExploit.o"

xcrun --sdk iphoneos clang -c -target arm64-apple-ios17.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/JetsamModifier.m" -o "$OUTPUT_DIR/JetsamModifier.o"

# Compile Swift sources with Bridging Header and Link
echo "[*] Compiling Swift UI and Process sources..."
xcrun --sdk iphoneos swiftc -target arm64-apple-ios17.0 \
    -sdk "$SDK_PATH" \
    -parse-as-library \
    -import-objc-header "JetsamChanger/JetsamChanger-Bridging-Header.h" \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    -framework Foundation \
    -framework UIKit \
    -framework SwiftUI \
    -framework Security \
    -framework CoreGraphics \
    "$OUTPUT_DIR/KernelMemory.o" \
    "$OUTPUT_DIR/KernelExploit.o" \
    "$OUTPUT_DIR/JetsamModifier.o" \
    "JetsamChanger/App/JetsamChangerApp.swift" \
    "JetsamChanger/Core/Process/ProcessManager.swift" \
    "JetsamChanger/UI/Theme.swift" \
    "JetsamChanger/UI/ContentView.swift" \
    "JetsamChanger/UI/AppListView.swift" \
    "JetsamChanger/UI/ProcessDetailView.swift" \
    "JetsamChanger/UI/SettingsView.swift" \
    "JetsamChanger/UI/KernelConsoleView.swift" \
    -o "$APP_DIR/$APP_NAME"

# Codesign with ldid
if command -v ldid &> /dev/null; then
    echo "[*] Applying entitlements with ldid..."
    ldid -S"JetsamChanger/Resources/JetsamChanger.entitlements" "$APP_DIR/$APP_NAME"
fi

# Package into IPA & TIPA
echo "[*] Packaging .ipa and .tipa..."
cd "$OUTPUT_DIR"
zip -r9 "$APP_NAME.ipa" Payload
cp "$APP_NAME.ipa" "$APP_NAME.tipa"
cd ..

echo "==============================================="
echo "   Build Succeeded!"
echo "   Artifact: $OUTPUT_DIR/$APP_NAME.tipa"
echo "   Artifact: $OUTPUT_DIR/$APP_NAME.ipa"
echo "==============================================="
