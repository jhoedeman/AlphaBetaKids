import Foundation

enum CardDeckError: LocalizedError {
    case resourceMissing(String)

    var errorDescription: String? {
        switch self {
        case .resourceMissing(let name):
            "Couldn't find \(name) in the app bundle."
        }
    }
}

/// The whole content layer: a plain value type over the decoded
/// `Alphabet.json`. Deliberately not an observable store — there is one
/// alphabet, it never changes at runtime, and the only variability is which
/// subset is showing and in what order.
struct CardDeck: Hashable {
    let allCards: [LetterCard]

    init(allCards: [LetterCard]) {
        self.allCards = allCards
    }

    /// Tests run hosted inside AlphaBetaKids.app (the .xctest bundle lives in
    /// its PlugIns), so `Bundle.main` is the app bundle carrying
    /// Content/Resources — not the xctest bundle itself. Same arrangement as
    /// the sibling AlphaBeta project.
    static func load(from bundle: Bundle = .main) throws -> CardDeck {
        guard let url = bundle.url(forResource: "Alphabet", withExtension: "json") else {
            throw CardDeckError.resourceMissing("Alphabet.json")
        }
        let file = try JSONDecoder().decode(AlphabetFile.self, from: Data(contentsOf: url))
        return CardDeck(allCards: file.cards)
    }

    /// The 26 letters, or all 34 cards when blends are switched on. Always in
    /// `id` order — `ordered(…)` is what applies shuffling.
    func visibleCards(blendsEnabled: Bool) -> [LetterCard] {
        blendsEnabled ? allCards : allCards.filter { $0.kind == .letter }
    }

    /// The deck as the pager should show it.
    ///
    /// Takes the generator so shuffling is testable — a seeded generator lets
    /// `CardDeckTests` assert the result is a genuine permutation rather than
    /// merely "some array of cards".
    func ordered<G: RandomNumberGenerator>(
        blendsEnabled: Bool,
        shuffled: Bool,
        using generator: inout G
    ) -> [LetterCard] {
        let cards = visibleCards(blendsEnabled: blendsEnabled)
        return shuffled ? cards.shuffled(using: &generator) : cards
    }

    func ordered(blendsEnabled: Bool, shuffled: Bool) -> [LetterCard] {
        var generator = SystemRandomNumberGenerator()
        return ordered(blendsEnabled: blendsEnabled, shuffled: shuffled, using: &generator)
    }
}
