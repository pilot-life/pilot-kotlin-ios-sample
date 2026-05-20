import SwiftUI
import UIKit
import PilotPartnerUi

/// Wraps the Compose Multiplatform `UIViewController` returned by
/// `PilotPartnerUi.shared.eventsScreen(...)` in a SwiftUI view via
/// `UIViewControllerRepresentable`.
///
/// The factory takes config primitives rather than a `PilotPartnerClient`.
/// Kotlin/Native builds each KMP library as a self-contained framework
/// and types from one don't auto-bridge into another — so passing a
/// shared SDK-typed client across the framework boundary would force a
/// Swift cast between two distinct types that happen to wrap the same
/// Kotlin class. Taking primitives sidesteps the issue and gives partners
/// a simpler "you only need this much to render" API.
struct ComposeEventsScreen: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        PilotPartnerUi.shared.eventsScreen(
            apiKey: Secrets.apiKey,
            organizationUuid: Secrets.organizationUuid,
            environment: Secrets.environment,
            baseUrl: Secrets.baseUrl,
            gatewaySecret: Secrets.gatewaySecret,
        )
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        // The Compose controller is self-managing; nothing to do.
    }
}
