import SwiftUI

enum AppTab: Hashable {
    case cards
    case quiz
}

/// Two-tab shell. Cards is the whole app for now; Quiz is present but inert
/// (SPEC §9).
struct RootView: View {
    @State private var selectedTab: AppTab = .cards

    private let deck: CardDeck?
    private let loadError: String?

    init() {
        do {
            deck = try CardDeck.load()
            loadError = nil
        } catch {
            deck = nil
            loadError = error.localizedDescription
        }
    }

    /// The Quiz tab is selectable and lands on a "coming soon" screen.
    ///
    /// SPEC §9 originally called for a *disabled* tab, intercepting the
    /// selection binding to refuse the write. That does not work: refusing
    /// the write is a no-op, so SwiftUI sees no state change, never
    /// invalidates, and never reconciles the underlying tab controller back —
    /// the tab bar simply keeps whatever the user tapped. Making it stick
    /// needs either a visible flash (select Quiz, then bounce back on the
    /// next runloop) or hit-testing hacks over the tab bar that break
    /// VoiceOver. Neither is worth it to withhold a screen that is friendlier
    /// than a dead control anyway.
    var body: some View {
        TabView(selection: $selectedTab) {
            cardsTab
                .tabItem { Label("Cards", systemImage: "rectangle.stack.fill") }
                .tag(AppTab.cards)

            QuizPlaceholderView()
                .tabItem { Label("Quiz", systemImage: "graduationcap.fill") }
                .tag(AppTab.quiz)
        }
        .tint(Theme.accent)
    }

    @ViewBuilder
    private var cardsTab: some View {
        if let deck {
            CardsView(deck: deck)
        } else {
            ContentUnavailableView(
                "Couldn't load the alphabet",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError ?? "Unknown error")
            )
        }
    }
}

#Preview {
    RootView()
}
