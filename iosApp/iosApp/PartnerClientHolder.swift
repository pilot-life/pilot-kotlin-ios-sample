import Foundation
import PilotPartnerSdk

/// Process-wide singleton mirroring `PartnerClientHolder` in the
/// Android sample. The integration guide's "reuse one PilotPartnerClient
/// per app process" guidance applies equally to iOS — the underlying
/// Ktor Darwin engine pools NSURLSession connections internally.
enum PartnerClientHolder {
    static let shared: PilotPartnerClient = build()

    private static func build() -> PilotPartnerClient {
        let env: PartnerEnvironment = {
            switch Secrets.environment.uppercased() {
            case "PRODUCTION": return PartnerEnvironment.production
            case "STAGING":    return PartnerEnvironment.staging
            case "DEV":        return PartnerEnvironment.dev
            default:           return PartnerEnvironment.sandbox
            }
        }()

        let builder = PilotPartnerClient.companion.builder()
            .apiKey(value: Secrets.apiKey)
            .organizationUuid(value: Secrets.organizationUuid)
            .logging(level: Ktor_client_loggingLogLevel.info)

        if let gw = Secrets.gatewaySecret {
            _ = builder.gatewaySecret(value: gw)
        }

        if let url = Secrets.baseUrl {
            _ = builder.baseUrl(url: url)
        } else {
            _ = builder.environment(env: env)
        }

        return builder.build()
    }
}
