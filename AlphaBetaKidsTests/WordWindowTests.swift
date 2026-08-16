import Foundation
import Testing
@testable import AlphaBetaKids

/// The sliding window into each card's word pool (SPEC §3.6).
///
/// This is the part of the pool feature that can actually be tested — the
/// arithmetic is pure, so the properties that matter (always four, never a
/// repeat inside one window, nothing in the pool unreachable) are checked
/// here rather than by flipping cards by hand.
struct WordWindowTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    private var cards: [LetterCard] { Self.deck.allCards }

    // MARK: - The set the child opens on

    /// The whole reason the pool is ordered rather than shuffled: a session
    /// starts on the four words the child has been consolidating.
    @Test(arguments: Self.deck.allCards)
    func visitZeroShowsTheFirstFour(card: LetterCard) {
        #expect(card.shownWords(forVisit: 0) == Array(card.words.prefix(4)))
    }

    // MARK: - Shape

    @Test(arguments: Self.deck.allCards)
    func everyVisitShowsFourWords(card: LetterCard) {
        for visit in 0..<24 {
            let shown = card.shownWords(forVisit: visit)
            #expect(shown.count == 4,
                    "\(card.lower) visit \(visit) showed \(shown.count)")
        }
    }

    /// A window that wrapped past the end of a short pool could show the same
    /// word twice on one card face.
    @Test(arguments: Self.deck.allCards)
    func noWindowRepeatsAWord(card: LetterCard) {
        for visit in 0..<24 {
            let shown = card.shownWords(forVisit: visit).map(\.text)
            #expect(Set(shown).count == shown.count,
                    "\(card.lower) visit \(visit) repeats: \(shown)")
        }
    }

    // MARK: - Nothing in the pool is unreachable

    /// Writing a tenth word that no child ever sees would be worse than not
    /// writing it, because it would look done.
    @Test(arguments: Self.deck.allCards)
    func everyWordInThePoolIsEventuallyShown(card: LetterCard) {
        var seen: Set<String> = []
        for visit in 0..<(card.words.count * 2) {
            seen.formUnion(card.shownWords(forVisit: visit).map(\.text))
        }
        let missing = Set(card.words.map(\.text)).subtracting(seen)
        #expect(missing.isEmpty, "\(card.lower) never shows \(missing.sorted())")
    }

    // MARK: - Pools too small to cycle

    /// x, q, z and u ran out of words that a small child knows, and a card
    /// with nothing to cycle must sit still rather than reshuffle four words
    /// into a different order every time.
    @Test func poolsOfExactlyFourNeverChange() {
        let fixed = cards.filter { $0.words.count == LetterCard.shownWordCount }
        #expect(!fixed.isEmpty, "expected some cards to have no spare words")

        for card in fixed {
            for visit in 0..<12 {
                #expect(card.shownWords(forVisit: visit) == card.words,
                        "\(card.lower) changed at visit \(visit)")
            }
        }
    }

    // MARK: - The window returns home

    @Test(arguments: Self.deck.allCards)
    func theCycleClosesOnItself(card: LetterCard) {
        let period = card.words.count  // stepping by 4 mod n repeats by n at worst
        #expect(card.shownWords(forVisit: period) == card.shownWords(forVisit: 0),
                "\(card.lower) does not return to its first four")
    }
}
