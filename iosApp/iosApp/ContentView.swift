import SwiftUI
import PilotPartnerSdk

/// Root with a two-tab view: pure SwiftUI consumer of the SDK on the
/// left, full Compose Multiplatform UI on the right. Side-by-side
/// validates that partners can choose either integration style.
struct ContentView: View {
    var body: some View {
        TabView {
            SwiftEventsTab()
                .tabItem {
                    Label("Swift", systemImage: "swift")
                }

            NavigationView {
                ComposeEventsScreen(client: PartnerClientHolder.shared)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Events (Compose)")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Compose", systemImage: "rectangle.3.group")
            }
        }
    }
}

/// Native SwiftUI implementation — same SDK, hand-rolled UI in Swift.
private struct SwiftEventsTab: View {
    @StateObject private var vm = EventsViewModel()

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Events (Swift)")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await vm.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Refresh")
                    }
                }
                .onAppear {
                    Task { if vm.events.isEmpty { await vm.loadMore() } }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.events.isEmpty {
            ProgressView("Loading events…")
        } else if let error = vm.error, vm.events.isEmpty {
            errorState(error)
        } else if vm.events.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No events")
                    .font(.headline)
                Text("The partner API returned an empty page for this org.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        } else {
            List(vm.events, id: \.eventUUID) { event in
                EventRow(event: event)
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                Task { await vm.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct EventRow: View {
    let event: EventListItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: event.imageUrl.flatMap(URL.init(string:))) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name).font(.headline)
                if let venue = event.venueName {
                    Text(venue).font(.subheadline).foregroundColor(.secondary)
                }
                Text(event.startDate).font(.caption).foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }

    private var placeholder: some View {
        Color.secondary.opacity(0.15)
            .overlay(Image(systemName: "calendar").foregroundColor(.secondary))
    }
}
