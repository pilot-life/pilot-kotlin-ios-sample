#!/usr/bin/env bash
# Build (or rebuild) the SDK XCFramework from a sibling pilot-kotlin
# checkout and symlink it into Frameworks/ so the Xcode project picks
# it up via FRAMEWORK_SEARCH_PATHS = $(PROJECT_DIR)/../Frameworks.
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

echo "==> Building XCFramework in $PILOT_KOTLIN_DIR"
( cd "$PILOT_KOTLIN_DIR" && ./gradlew :pilot-partner-sdk:assembleXCFramework )

XCFRAMEWORK_SRC="$PILOT_KOTLIN_DIR/pilot-partner-sdk/build/XCFrameworks/release/PilotPartnerSdk.xcframework"
if [[ ! -d "$XCFRAMEWORK_SRC" ]]; then
    echo "error: expected $XCFRAMEWORK_SRC after assembleXCFramework but it doesn't exist" >&2
    exit 1
fi

mkdir -p "$SAMPLE_DIR/Frameworks"
rm -rf "$SAMPLE_DIR/Frameworks/PilotPartnerSdk.xcframework"
cp -R "$XCFRAMEWORK_SRC" "$SAMPLE_DIR/Frameworks/PilotPartnerSdk.xcframework"

echo "==> Installed XCFramework at $SAMPLE_DIR/Frameworks/PilotPartnerSdk.xcframework"
echo "    size: $(du -sh "$SAMPLE_DIR/Frameworks/PilotPartnerSdk.xcframework" | cut -f1)"
