import SwiftUI

/// The Cards screen: controls, deck, position.
struct CardsView: View {
    let deck: CardDeck

    // The complete persisted state of the app (SPEC §2).
    @AppStorage("leadingCase") private var leadingCaseRaw = LetterCase.upper.rawValue
    @AppStorage("blendsEnabled") private var blendsEnabled = false
    @AppStorage("isShuffled") private var isShuffled = false
    @AppStorage("lastCardID") private var lastCardID = 1

    /// The deck as ordered right now. Held in state rather than computed: a
    /// computed property would reshuffle on every body evaluation, so the
    /// order is rebuilt only on the events that should change it.
    @State private var cards: [LetterCard] = []
    @State private var selectedID = 1
    /// Which card is currently turned over — at most one, since only one card
    /// is focused at a time. Keying the flip to an id rather than giving each
    /// card its own flag is what makes "paging resets the card to its front"
    /// true by construction (SPEC §6.3).
    @State private var flippedCardID: Int?

    private var leadingCase: LetterCase {
        LetterCase(rawValue: leadingCaseRaw) ?? .upper
    }

    private var leadingCaseBinding: Binding<LetterCase> {
        Binding(
            get: { leadingCase },
            set: { leadingCaseRaw = $0.rawValue }
        )
    }

    private var position: PagerPosition {
        .locating(id: selectedID, in: cards)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 10) {
                ControlBar(
                    leadingCase: leadingCaseBinding,
                    blendsEnabled: $blendsEnabled,
                    isShuffled: isShuffled,
                    onShuffle: toggleShuffle
                )

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
        .task { buildInitialDeck() }
        .onChange(of: blendsEnabled) { _, _ in rebuildAfterBlendsChange() }
        .onChange(of: selectedID) { _, newID in
            flippedCardID = nil
            // A position from a shuffled session means nothing in a fresh
            // shuffle, so only alphabetical positions are worth saving.
            if !isShuffled { lastCardID = newID }
        }
    }

    // MARK: - Deck order

    private func buildInitialDeck() {
        cards = deck.ordered(blendsEnabled: blendsEnabled, shuffled: isShuffled)
        let restored = isShuffled ? nil : cards.first { $0.id == lastCardID }
        selectedID = restored?.id ?? cards.first?.id ?? 1
    }

    /// Keeps focus on the same letter when it survives the filter change, and
    /// otherwise falls back to the front of the deck — which is what happens
    /// when blends are switched off while a blend card is showing (SPEC §5.6).
    private func rebuildAfterBlendsChange() {
        let previousID = selectedID
        cards = deck.ordered(blendsEnabled: blendsEnabled, shuffled: isShuffled)

        if !cards.contains(where: { $0.id == previousID }) {
            setSelectionWithoutAnimation(to: cards.first?.id ?? 1)
        }
        flippedCardID = nil
    }

    /// Shuffle is a plain toggle: on gives a fresh random order, off returns
    /// to alphabetical. Each activation reshuffles rather than restoring the
    /// previous order — which is also why only the *mode* is persisted and
    /// never the order itself (SPEC §5.5).
    private func toggleShuffle() {
        Haptics.impactLight()
        isShuffled.toggle()
        cards = deck.ordered(blendsEnabled: blendsEnabled, shuffled: isShuffled)
        // One predictable rule in both directions: start at the front of the
        // new order, rather than sometimes keeping your place.
        setSelectionWithoutAnimation(to: cards.first?.id ?? 1)
        flippedCardID = nil
    }

    /// Jumping the pager an arbitrary distance shouldn't animate through
    /// every page in between.
    private func setSelectionWithoutAnimation(to id: Int) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { selectedID = id }
    }
}

#Preview {
    CardsView(deck: try! CardDeck.load())
}
