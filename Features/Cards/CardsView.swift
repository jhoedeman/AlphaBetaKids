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
    /// Arrivals per card id, which picks each card's window into its word pool
    /// (SPEC §3.6). Deliberately *not* persisted: every session opens on the
    /// first four words of every card, so the set the child is consolidating
    /// is the one they meet first, and novelty is what accumulates within a
    /// sitting.
    @State private var visits: [Int: Int] = [:]
    /// Set immediately before the launch restore moves the pager, and cleared
    /// by the `onChange` that move causes. Without it, restoring to card 5
    /// counts as leaving card 1 and quietly advances a card the child never
    /// saw.
    @State private var isRestoringPosition = false

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
                        isFlipped: flippedCardID == card.id,
                        visit: visits[card.id] ?? 0
                    ) {
                        flippedCardID = (flippedCardID == card.id) ? nil : card.id
                    }
                }

                Text("\(position.index + 1) / \(cards.count)")
                    .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Theme.textSecondary)
                    // Spoken in full rather than hidden — "3 / 26" reads as
                    // nonsense, but a VoiceOver user still needs to know
                    // where they are in the deck.
                    .accessibilityLabel("Card \(position.index + 1) of \(cards.count)")
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
            .padding(.vertical, 12)
        }
        .task { buildInitialDeck() }
        .onChange(of: blendsEnabled) { _, _ in rebuildAfterBlendsChange() }
        .onChange(of: selectedID) { oldID, newID in
            flippedCardID = nil
            // Counted on departure rather than arrival, so the *next* time the
            // child comes back to this card it has moved on a set — which is
            // what "cycles on arrival" means from the card's point of view,
            // and needs no special case for the card you start on.
            if isRestoringPosition {
                isRestoringPosition = false
            } else {
                visits[oldID, default: 0] += 1
            }
            // A position from a shuffled session means nothing in a fresh
            // shuffle, so only alphabetical positions are worth saving.
            if !isShuffled { lastCardID = newID }
        }
    }

    // MARK: - Deck order

    private func buildInitialDeck() {
        cards = deck.ordered(blendsEnabled: blendsEnabled, shuffled: isShuffled)
        let restored = isShuffled ? nil : cards.first { $0.id == lastCardID }
        let target = restored?.id ?? cards.first?.id ?? 1
        // Flag before mutating, so the resulting onChange sees it whenever it
        // runs — the ordering between the two is not ours to rely on.
        if target != selectedID { isRestoringPosition = true }
        selectedID = target
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
