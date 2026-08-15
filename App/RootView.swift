import SwiftUI

/// M1 placeholder — enough to give the app target something to launch so the
/// content tests have a host to run inside. M2 replaces this with the real
/// two-tab shell (SPEC §9) and M3–M5 fill in the Cards screen.
struct RootView: View {
    private let deck = try? CardDeck.load()

    var body: some View {
        VStack(spacing: 12) {
            Text("AlphaBetaKids")
                .font(.largeTitle.weight(.bold))
            if let deck {
                Text("\(deck.allCards.count) cards loaded")
                    .foregroundStyle(.secondary)
            } else {
                Text("Alphabet.json failed to load")
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

#Preview {
    RootView()
}
