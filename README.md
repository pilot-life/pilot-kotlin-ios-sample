# pilot-kotlin-ios-sample

A minimal SwiftUI app that integrates the
[`life.pilot:pilot-partner-sdk`](https://github.com/pilot-life/pilot-kotlin)
Kotlin Multiplatform XCFramework on iOS. Used as the **iOS integration
canary** to catch consumer-facing issues (Swift-bridged type names,
exception bridging, framework embedding, async/await across the
Kotlin/Native boundary) before they reach partners.

Android counterpart:
[pilot-life/pilot-kotlin-android-sample](https://github.com/pilot-life/pilot-kotlin-android-sample).

## What it does

- `PilotSampleApp` → `ContentView` renders a SwiftUI list of events
  fetched via `client.events.list(...)`.
- `EventsViewModel` (`@MainActor`, `ObservableObject`) catches typed
  `PartnerException.NotFound` / `RateLimited` / `Network` cases in
  Swift `catch` clauses — proves the typed-exception bridge works.
- `PartnerClientHolder` wires the SDK builder with the right
  Swift-bridged enum names (`Ktor_client_loggingLogLevel.info`,
  `PartnerEnvironment.sandbox`).
- `Secrets` reads `PILOT_*` env vars / Info.plist entries — same
  precedence pattern as the Android sample's `BuildConfig` flow.

## Prerequisites

- macOS with Xcode 16+ (Xcode 26 verified)
- An Apple Silicon Mac (the XCFramework includes
  `ios-arm64` + `ios-arm64_x86_64-simulator` slices)
- A sibling checkout of [pilot-life/pilot-kotlin](https://github.com/pilot-life/pilot-kotlin)
  at `../pilot-kotlin` — or set `PILOT_KOTLIN_DIR` to point elsewhere.

## Build & run

### From the CLI

```bash
# 1. Build the XCFramework from your pilot-kotlin checkout and drop
#    it into Frameworks/ — picked up automatically by FRAMEWORK_SEARCH_PATHS.
./scripts/build-xcframework.sh

# 2. Compile the iOS app for a simulator.
cd iosApp
xcodebuild \
    -project iosApp.xcodeproj \
    -scheme iosApp \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    CODE_SIGNING_ALLOWED=NO \
    build
```

`scripts/build-xcframework.sh` runs
`./gradlew :pilot-partner-sdk:assembleXCFramework` in your pilot-kotlin
checkout, then copies the resulting `.xcframework` into `Frameworks/`.
The Xcode project's `FRAMEWORK_SEARCH_PATHS` points at that directory.

### From Xcode

```bash
open iosApp/iosApp.xcodeproj
```

Pick an iOS Simulator destination → `⌘R`. The app launches, calls the
partner API with whatever you set in `PILOT_*` env vars, and renders
the event list.

## Configuring secrets

Three sources, highest precedence first. **Do not commit real keys.**

| Source | Where | Best for |
| --- | --- | --- |
| Environment variable | Scheme → Run → Arguments → Environment Variables | One-off `⌘R` sessions |
| `Info.plist` key | Build settings → Info.plist Values | Sticky per-machine |
| `Secrets.swift` fallback | Compiled in | Last-resort dev defaults (will 401) |

Recognized variables (same names as the Android sample):

```
PILOT_API_KEY=pk_test_…
PILOT_ORG_UUID=00000000-0000-0000-0000-000000000000
PILOT_GATEWAY_SECRET=                  # only on dev/sandbox without Oathkeeper
PILOT_ENVIRONMENT=SANDBOX              # PRODUCTION / SANDBOX / STAGING / DEV
PILOT_BASE_URL=                        # optional — overrides PILOT_ENVIRONMENT
```

> Hitting a localhost backend? Set `PILOT_BASE_URL=http://10.0.2.2:3000/partner/v1/`
> on Android; on the iOS simulator, `http://localhost:3000/partner/v1/`
> works because the simulator shares the host's network namespace.

## Pointing at your own pilot-kotlin checkout

`scripts/build-xcframework.sh` assumes `../pilot-kotlin`. Override if
yours lives elsewhere:

```bash
PILOT_KOTLIN_DIR=/path/to/pilot-kotlin ./scripts/build-xcframework.sh
```

## What's intentionally NOT here yet

- **`PilotPartnerUi.framework`** — the Compose Multiplatform UI library
  is built and links cleanly (verified via
  `:pilot-partner-ui:linkDebugFrameworkIosSimulatorArm64`) but isn't yet
  embedded in this sample. The SDK alone is enough to prove the
  network + types bridge into Swift. Wiring Compose into a SwiftUI app
  is a follow-up — Compose Multiplatform exposes a
  `UIViewController`-shaped entrypoint, but integration patterns vary
  (full-screen vs. embedded vs. mixed). File an issue when you need it.
- **A built XCFramework binary in the repo.** It's 39M and produced from
  source; `scripts/build-xcframework.sh` rebuilds it on demand.

## Layout

```
.
├── iosApp/
│   ├── iosApp.xcodeproj/
│   │   ├── project.pbxproj
│   │   └── xcshareddata/xcschemes/iosApp.xcscheme
│   └── iosApp/
│       ├── PilotSampleApp.swift     # @main App
│       ├── ContentView.swift         # SwiftUI list + AsyncImage
│       ├── EventsViewModel.swift     # @MainActor ObservableObject
│       ├── PartnerClientHolder.swift # SDK builder wiring
│       ├── Secrets.swift             # env / Info.plist secret resolution
│       ├── Assets.xcassets/
│       └── Preview Content/
├── Frameworks/                       # populated by build-xcframework.sh, gitignored
│   └── PilotPartnerSdk.xcframework
└── scripts/
    └── build-xcframework.sh          # one-shot bridge to ../pilot-kotlin's gradle
```
