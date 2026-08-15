import Foundation
import Testing
@testable import AlphaBetaKids

/// Deterministic xorshift64 so shuffle behaviour can be asserted rather than
/// hoped at. Seeded through a splitmix-style step so seed 0 doesn't produce
/// the degenerate all-zero state.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

struct CardDeckTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    // MARK: - Filtering

    @Test func blendsOffShowsOnlyTheTwentySixLetters() {
        let visible = Self.deck.visibleCards(blendsEnabled: false)
        #expect(visible.count == 26)
        #expect(visible.allSatisfy { $0.kind == .letter })
    }

    @Test func blendsOnShowsTheWholeDeck() {
        let visible = Self.deck.visibleCards(blendsEnabled: true)
        #expect(visible.count == 34)
        #expect(visible.filter { $0.kind == .blend }.count == 8)
    }

    // MARK: - Ordering

    @Test(arguments: [false, true])
    func unshuffledIsAlphabeticalByID(blendsEnabled: Bool) {
        let ordered = Self.deck.ordered(blendsEnabled: blendsEnabled, shuffled: false)
        #expect(ordered.map(\.id) == ordered.map(\.id).sorted())
    }

    /// The property that actually matters: shuffling reorders and does not
    /// drop, duplicate, or invent cards.
    @Test(arguments: [UInt64] (0..<25))
    func shuffleIsAPermutation(seed: UInt64) {
        var generator = SeededGenerator(seed: seed)
        let shuffled = Self.deck.ordered(blendsEnabled: true, shuffled: true, using: &generator)
        let expected = Self.deck.visibleCards(blendsEnabled: true)

        #expect(shuffled.count == expected.count)
        #expect(Set(shuffled.map(\.id)) == Set(expected.map(\.id)))
        #expect(shuffled.sorted { $0.id < $1.id } == expected)
    }

    @Test func shuffleRespectsTheBlendsFilter() {
        var generator = SeededGenerator(seed: 7)
        let shuffled = Self.deck.ordered(blendsEnabled: false, shuffled: true, using: &generator)
        #expect(shuffled.count == 26)
        #expect(shuffled.allSatisfy { $0.kind == .letter })
    }

    @Test func sameSeedGivesTheSameOrder() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        let first = Self.deck.ordered(blendsEnabled: true, shuffled: true, using: &a)
        let second = Self.deck.ordered(blendsEnabled: true, shuffled: true, using: &b)
        #expect(first.map(\.id) == second.map(\.id))
    }

    /// Guards against a shuffle that silently does nothing. With 34 cards an
    /// identity permutation is astronomically unlikely, but requiring only
    /// that *some* seed reorders keeps this from ever flaking.
    @Test func shufflingActuallyReorders() {
        let inOrder = Self.deck.visibleCards(blendsEnabled: true).map(\.id)
        let reordered = (0..<10).contains { seed in
            var generator = SeededGenerator(seed: UInt64(seed))
            return Self.deck.ordered(blendsEnabled: true, shuffled: true, using: &generator)
                .map(\.id) != inOrder
        }
        #expect(reordered)
    }
}
