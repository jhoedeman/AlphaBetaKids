import SwiftUI

/// The Cards screen. M5 adds the control bar above the pager and moves
/// `leadingCase` / blends / shuffle into `@AppStorage`.
struct CardsView: View {
    let deck: CardDeck

    @State private var selectedID = 1
    /// Which card is currently turned over — at most one, since only one card
    /// is focused at a time. Keying the flip to an id rather than giving each
    /// card its own flag is what makes "paging resets the card to its front"
    /// true by construction: change the selection, clear this, done. A child
    /// should never arrive on a back they didn't turn (SPEC §6.3).
    @State private var flippedCardID: Int?

    /// M5 replaces this with the case toggle, stored in `@AppStorage`.
    private let leadingCase: LetterCase = .upper

    private var cards: [LetterCard] {
        // M5 makes this respond to the blends pill and shuffle.
        deck.visibleCards(blendsEnabled: false)
    }

    private var position: PagerPosition {
        .locating(id: selectedID, in: cards)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 8) {
                CardPagerView(cards: cards, selectedID: $selectedID) { card in
                    FlipCardView(
                        card: card,
                        leadingCase: leadingCase,
                        isFlipped: flippedCardID == card.id
                    ) {
                        flippedCardID = (flippedCardID == card.id) ? nil : card.id
                    }
                }

                Text("\(position.index + 1) / \(cards.count)")
                    .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
        }
        .onChange(of: selectedID) { _, _ in
            flippedCardID = nil
        }
    }
}

#Preview {
    CardsView(deck: try! CardDeck.load())
}
