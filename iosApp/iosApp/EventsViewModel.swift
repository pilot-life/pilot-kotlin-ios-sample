import Foundation
import PilotPartnerSdk

@MainActor
final class EventsViewModel: ObservableObject {
    @Published private(set) var events: [EventListItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: String?

    private let client = PartnerClientHolder.shared
    private var nextCursor: String?

    func refresh() async {
        events = []
        nextCursor = nil
        await loadMore()
    }

    func loadMore() async {
        if isLoading { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let page = try await client.events.list(
                startsAfter: nil,
                cursor: nextCursor,
                limit: 20,
            )
            events.append(contentsOf: page.events)
            nextCursor = page.nextCursor
        } catch let e as PartnerException.NotFound {
            error = "404 — org not enabled or resource missing. \(e.message ?? "")"
        } catch let e as PartnerException.Network {
            error = "Network error: \(e.message ?? "unknown")"
        } catch let e as PartnerException.RateLimited {
            error = "Rate limited. Retry after \(e.retryAfterSeconds?.intValue ?? 0)s."
        } catch let caught {
            error = caught.localizedDescription
        }
    }
}
