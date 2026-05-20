#!/usr/bin/env bash
# Build (or rebuild) both XCFrameworks from a sibling pilot-kotlin
# checkout and symlink them into Frameworks/ so the Xcode project picks
# them up via FRAMEWORK_SEARCH_PATHS = $(PROJECT_DIR)/../Frameworks.
#
# Override PILOT_KOTLIN_DIR if your library checkout lives elsewhere.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PILOT_KOTLIN_DIR="${PILOT_KOTLIN_DIR:-$SAMPLE_DIR/../pilot-kotlin}"

if [[ ! -d "$PILOT_KOTLIN_DIR" ]]; then
    echo "error: pilot-kotlin checkout not found at $PILOT_KOTLIN_DIR" >&2
    echo "       set PILOT_KOTLIN_DIR=/path/to/pilot-kotlin and retry, or" >&2
    echo "       git clone https://github.com/pilot-life/pilot-kotlin \"$PILOT_KOTLIN_DIR\"" >&2
    exit 1
fi

echo "==> Building XCFrameworks in $PILOT_KOTLIN_DIR"
( cd "$PILOT_KOTLIN_DIR" && ./gradlew :pilot-partner-sdk:assembleXCFramework :pilot-partner-ui:assembleXCFramework )

mkdir -p "$SAMPLE_DIR/Frameworks"

for module in pilot-partner-sdk pilot-partner-ui; do
    case "$module" in
        pilot-partner-sdk) name="PilotPartnerSdk" ;;
        pilot-partner-ui)  name="PilotPartnerUi"  ;;
    esac
    src="$PILOT_KOTLIN_DIR/$module/build/XCFrameworks/release/$name.xcframework"
    if [[ ! -d "$src" ]]; then
        echo "error: expected $src after assembleXCFramework but it doesn't exist" >&2
        exit 1
    fi
    rm -rf "$SAMPLE_DIR/Frameworks/$name.xcframework"
    cp -R "$src" "$SAMPLE_DIR/Frameworks/$name.xcframework"

    # Kotlin/Native ships every framework slice with only `iPhoneOS` in
    # CFBundleSupportedPlatforms — even the simulator slice. Static
    # frameworks survive (Xcode doesn't validate their Info.plist on
    # link-only), but dynamic frameworks (Compose Multiplatform's
    # PilotPartnerUi) get rejected at embed time on iOS Simulator with
    # "Unable to find a destination matching ...". Patch the simulator
    # slice's Info.plist to include `iPhoneSimulator`. Harmless for
    # static frameworks; required for dynamic ones.
    sim_plist="$SAMPLE_DIR/Frameworks/$name.xcframework/ios-arm64_x86_64-simulator/$name.framework/Info.plist"
    if [[ -f "$sim_plist" ]]; then
        /usr/libexec/PlistBuddy -c "Print :CFBundleSupportedPlatforms" "$sim_plist" 2>/dev/null \
            | grep -q "iPhoneSimulator" \
            || /usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms: string iPhoneSimulator" "$sim_plist"
    fi

    echo "==> Installed $name.xcframework ($(du -sh "$SAMPLE_DIR/Frameworks/$name.xcframework" | cut -f1))"
done
