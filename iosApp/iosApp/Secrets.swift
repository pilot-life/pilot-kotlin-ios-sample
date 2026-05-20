import Foundation

/// Reads partner-API secrets at runtime.
///
/// Lookup order, highest precedence first:
///   1. Environment variable (handy on the simulator via the scheme's
///      "Arguments → Environment Variables" pane).
///   2. `Secrets.xcconfig` next to this file (gitignored — local dev).
///   3. Built-in fallbacks. They will 401 against the real API; that's
///      the intended "you forgot to set secrets" signal.
///
/// In a real partner app, fetch the API key from your own backend or
/// Keychain instead. APK / IPA strings are trivially recoverable.
enum Secrets {
    static var apiKey: String { read("PILOT_API_KEY", default: "missing-PILOT_API_KEY") }
    static var organizationUuid: String { read("PILOT_ORG_UUID", default: "00000000-0000-0000-0000-000000000000") }
    static var gatewaySecret: String? { read("PILOT_GATEWAY_SECRET", default: "").nonEmpty }
    static var baseUrl: String? { read("PILOT_BASE_URL", default: "").nonEmpty }
    /// `PRODUCTION` / `SANDBOX` / `STAGING` / `DEV`. Defaults to `SANDBOX`.
    static var environment: String { read("PILOT_ENVIRONMENT", default: "SANDBOX") }

    private static func read(_ name: String, default fallback: String) -> String {
        if let env = ProcessInfo.processInfo.environment[name], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: name) as? String, !plist.isEmpty {
            return plist
        }
        return fallback
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
