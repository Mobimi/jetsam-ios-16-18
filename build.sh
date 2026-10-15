#!/usr/bin/env bash
set -ex

APP_NAME="LaraToolbox"
OUTPUT_DIR="./build"
PAYLOAD_DIR="$OUTPUT_DIR/Payload"
APP_DIR="$PAYLOAD_DIR/$APP_NAME.app"

echo "==============================================="
echo "   Building $APP_NAME for iOS 16.0 – 18.4.1+"
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
echo "[*] Compiling C/Obj-C kernel and utility sources..."
xcrun --sdk iphoneos clang -c -target arm64-apple-ios16.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/KernelMemory.c" -o "$OUTPUT_DIR/KernelMemory.o"

xcrun --sdk iphoneos clang -c -target arm64-apple-ios16.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/KernelExploit.m" -o "$OUTPUT_DIR/KernelExploit.o"

xcrun --sdk iphoneos clang -c -target arm64-apple-ios16.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/DylibInjector.m" -o "$OUTPUT_DIR/DylibInjector.o"

xcrun --sdk iphoneos clang -c -target arm64-apple-ios16.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/DaemonManager.m" -o "$OUTPUT_DIR/DaemonManager.o"

xcrun --sdk iphoneos clang -c -target arm64-apple-ios16.0 \
    -isysroot "$SDK_PATH" \
    -fobjc-arc \
    -I"JetsamChanger" \
    -I"JetsamChanger/Core/Kernel" \
    "JetsamChanger/Core/Kernel/JetsamModifier.m" -o "$OUTPUT_DIR/JetsamModifier.o"

# Compile Swift sources with Bridging Header and Link
echo "[*] Compiling Swift UI, Dylib Injector, Daemons and Toolbox sources..."
xcrun --sdk iphoneos swiftc -target arm64-apple-ios16.0 \
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
    -framework UniformTypeIdentifiers \
    "$OUTPUT_DIR/KernelMemory.o" \
    "$OUTPUT_DIR/KernelExploit.o" \
    "$OUTPUT_DIR/JetsamModifier.o" \
    "$OUTPUT_DIR/DylibInjector.o" \
    "$OUTPUT_DIR/DaemonManager.o" \
    "JetsamChanger/App/JetsamChangerApp.swift" \
    "JetsamChanger/Core/Process/ProcessManager.swift" \
    "JetsamChanger/UI/Theme.swift" \
    "JetsamChanger/UI/ContentView.swift" \
    "JetsamChanger/UI/DylibInjectorView.swift" \
    "JetsamChanger/UI/LaunchDaemonsView.swift" \
    "JetsamChanger/UI/ExploitTweaksView.swift" \
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

# Also create aliases
cp "$APP_NAME.ipa" "JetsamChanger.ipa"
cp "$APP_NAME.tipa" "JetsamChanger.tipa"
cd ..

echo "==============================================="
echo "   Build Succeeded!"
echo "   Artifact: $OUTPUT_DIR/$APP_NAME.tipa"
echo "   Artifact: $OUTPUT_DIR/$APP_NAME.ipa"
echo "==============================================="
