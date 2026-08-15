import Foundation
import Testing
@testable import AlphaBetaKids

struct PagerIndexTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    // MARK: - Clamping

    @Test func advancingPastTheEndStaysAtTheEnd() {
        var position = PagerPosition(count: 26, index: 25)
        #expect(position.isAtEnd)
        position = position.advanced()
        #expect(position.index == 25)
        #expect(position.isAtEnd)
    }

    @Test func retreatingPastTheStartStaysAtTheStart() {
        var position = PagerPosition(count: 26, index: 0)
        #expect(position.isAtStart)
        position = position.retreated()
        #expect(position.index == 0)
    }

    @Test(arguments: [-5, -1, 26, 100])
    func outOfRangeIndexesAreClamped(index: Int) {
        let position = PagerPosition(count: 26, index: index)
        #expect((0...25).contains(position.index))
    }

    @Test func anEmptyDeckIsBothStartAndEnd() {
        let position = PagerPosition(count: 0, index: 0)
        #expect(position.isEmpty)
        #expect(position.isAtStart)
        #expect(position.isAtEnd)
        #expect(position.advanced().index == 0)
    }

    // MARK: - Edge flags drive the arrow controls

    @Test func onlyTheFirstCardIsAtStart() {
        for index in 0..<26 {
            let position = PagerPosition(count: 26, index: index)
            #expect(position.isAtStart == (index == 0))
        }
    }

    @Test func onlyTheLastCardIsAtEnd() {
        for index in 0..<26 {
            let position = PagerPosition(count: 26, index: index)
            #expect(position.isAtEnd == (index == 25))
        }
    }

    /// The trailing arrow only becomes the restart button on the very last
    /// card, and where that falls depends on the blends filter.
    @Test(arguments: [false, true])
    func restartAppearsOnlyOnTheLastVisibleCard(blendsEnabled: Bool) {
        let cards = Self.deck.visibleCards(blendsEnabled: blendsEnabled)
        let last = PagerPosition.locating(id: cards[cards.count - 1].id, in: cards)
        let secondToLast = PagerPosition.locating(id: cards[cards.count - 2].id, in: cards)

        #expect(last.isAtEnd)
        #expect(!secondToLast.isAtEnd)
        #expect(last.count == (blendsEnabled ? 34 : 26))
    }

    // MARK: - Restart

    @Test func restartReturnsToTheFirstCard() {
        let position = PagerPosition(count: 34, index: 33).restarted()
        #expect(position.index == 0)
        #expect(position.isAtStart)
    }

    // MARK: - Locating by card id

    @Test func locatingFindsTheCardsIndex() {
        let cards = Self.deck.visibleCards(blendsEnabled: false)
        let m = try! #require(cards.first { $0.lower == "m" })
        #expect(PagerPosition.locating(id: m.id, in: cards).index == 12)
    }

    /// When the blends pill is switched off while a blend card is in focus,
    /// its id is no longer in the deck. Focus falls back to the first card
    /// rather than to a nonexistent index (SPEC §5.6).
    @Test func locatingAMissingIDFallsBackToTheFirstCard() {
        let letters = Self.deck.visibleCards(blendsEnabled: false)
        let blend = Self.deck.allCards.first { $0.lower == "sh" }!

        let position = PagerPosition.locating(id: blend.id, in: letters)
        #expect(position.index == 0)
        #expect(position.count == 26)
    }
}
