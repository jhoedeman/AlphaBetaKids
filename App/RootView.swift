import SwiftUI

enum AppTab: Hashable {
    case cards
    case quiz
}

/// Two-tab shell: the deck, and the quiz.
///
/// Both tabs are live. SPEC §9 once described the Quiz tab as deliberately
/// inert, and before that as *disabled* — which could not be made to work,
/// because refusing the selection binding's write is a no-op SwiftUI never
/// reconciles back. That is all moot now; the tab goes somewhere.
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

    var body: some View {
        TabView(selection: $selectedTab) {
            cardsTab
                .tabItem { Label("Cards", systemImage: "rectangle.stack.fill") }
                .tag(AppTab.cards)

            quizTab
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
            unavailable
        }
    }

    @ViewBuilder
    private var quizTab: some View {
        if let deck {
            QuizView(deck: deck)
        } else {
            unavailable
        }
    }

    private var unavailable: some View {
        ContentUnavailableView(
            "Couldn't load the alphabet",
            systemImage: "exclamationmark.triangle",
            description: Text(loadError ?? "Unknown error")
        )
    }
}

#Preview {
    RootView()
}
