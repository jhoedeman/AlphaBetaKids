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
    /// Letters that share a sound in this content, from `Alphabet.json`.
    let soundClasses: [[String]]

    init(allCards: [LetterCard], soundClasses: [[String]] = []) {
        self.allCards = allCards
        self.soundClasses = soundClasses
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
        return CardDeck(allCards: file.cards, soundClasses: file.soundClasses ?? [])
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

    // MARK: - Quiz eligibility

    /// The only cards a letter quiz may draw on.
    ///
    /// The word pools were authored around "this card's *sound* occurs in this
    /// word", which is not the relation a letter quiz needs. On blend and
    /// `contains` cards the two diverge badly — 🌙 is filed under `oo` but a
    /// child reading it says "moon", and offering it as a wrong answer for M
    /// punishes a correct one. Restricting to `startsWith` letter cards closes
    /// that: within these 25, every word begins with its own card's letter, so
    /// a word borrowed from card Y can never be right for card X.
    ///
    /// 25 cards (every letter but `x`). See the quiz design §5.
    var quizCards: [LetterCard] {
        allCards.filter { $0.kind == .letter && $0.wordRule == .startsWith }
    }

    /// Every picture a quiz may show *without a word beside it*, paired with
    /// the card it belongs to.
    ///
    /// Word-level safety is not picture-level safety: a tile carries no
    /// caption, so the child names it himself, and 🥕 filed as "vegetables"
    /// is a carrot to him. Those are flagged in the content and dropped here.
    /// 150 of the 208 words on `quizCards` survive, and every one of the 25
    /// keeps at least one — which `ContentTests` pins.
    func picturePool() -> [(card: LetterCard, word: Word)] {
        quizCards.flatMap { card in
            card.words.filter(\.isPictureClear).map { (card: card, word: $0) }
        }
    }

    /// The letters that must never be offered alongside `letter` as wrong
    /// answers, including `letter` itself. Falls back to just the letter when
    /// it shares a sound with nothing.
    func soundClass(for letter: String) -> Set<String> {
        for group in soundClasses where group.contains(letter) {
            return Set(group)
        }
        return [letter]
    }
}
