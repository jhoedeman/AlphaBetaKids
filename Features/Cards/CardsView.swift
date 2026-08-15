import SwiftUI

/// M2 skeleton: the themed screen frame the Cards tab lives in. M3 adds the
/// pager and arrows, M4 the card faces and flip, M5 the control bar.
struct CardsView: View {
    let deck: CardDeck

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Aa")
                    .font(Theme.letterFont(size: 120))
                    .foregroundStyle(Theme.accent)

                Text("\(deck.visibleCards(blendsEnabled: false).count) letters, \(deck.allCards.count) cards")
                    .font(Theme.wordFont(size: 17))
                    .foregroundStyle(Theme.textSecondary)

                if !Theme.isAvailable(.bold) {
                    Label("Andika not bundled — showing SF Rounded", systemImage: "exclamationmark.triangle")
                        .font(Theme.labelFont(size: 13, relativeTo: .footnote))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
        }
    }
}

#Preview {
    CardsView(deck: try! CardDeck.load())
}
