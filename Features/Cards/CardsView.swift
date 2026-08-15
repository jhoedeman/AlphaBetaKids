import SwiftUI

/// The Cards screen. M3 wires up the pager; M4 replaces the placeholder face
/// with the real flip card, and M5 adds the control bar above it.
struct CardsView: View {
    let deck: CardDeck

    @State private var selectedID = 1

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
                    PlaceholderCardFace(card: card)
                }

                Text("\(position.index + 1) / \(cards.count)")
                    .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
        }
    }
}

/// Stand-in until M4 builds the real front/back faces and the flip. Exists so
/// the paging feel can be evaluated now rather than after the card work.
private struct PlaceholderCardFace: View {
    let card: LetterCard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)

            Text(card.front(leading: .upper))
                .font(Theme.letterFont(size: 160))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .foregroundStyle(Theme.accent)
                .padding(24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.front(leading: .upper))
    }
}

#Preview {
    CardsView(deck: try! CardDeck.load())
}
