import SwiftUI
import UIKit
import PilotPartnerSdk
import PilotPartnerUi

/// Wraps the Compose Multiplatform `UIViewController` returned by
/// `PilotPartnerUi.shared.eventsScreen(...)` in a SwiftUI view via
/// `UIViewControllerRepresentable`.
///
/// This is the canonical Compose-Multiplatform-into-SwiftUI bridge.
/// The `UIViewController` returned by `ComposeUIViewController { ... }`
/// hosts the entire Compose runtime — gesture, layout, accessibility,
/// state all routed through it.
///
/// The shipped iOS entry point in `pilot-partner-ui` renders
/// `EventListWithFilters` with the default `EventsViewModel` wired to
/// the provided `PilotPartnerClient`. Partners who need their own VM
/// or different composition can copy the iOS entry point's source
/// (~30 LOC) and substitute.
struct ComposeEventsScreen: UIViewControllerRepresentable {
    let client: PilotPartnerClient

    func makeUIViewController(context: Context) -> UIViewController {
        PilotPartnerUi.shared.eventsScreen(client: client)
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        // The Compose controller is self-managing; nothing to do.
    }
}
