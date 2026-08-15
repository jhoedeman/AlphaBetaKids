import Foundation

/// Which case leads on the card fronts. Persisted as a raw string in
/// `@AppStorage` (SPEC §2).
enum LetterCase: String, CaseIterable, Codable, Hashable {
    case upper
    case lower

    var opposite: LetterCase { self == .upper ? .lower : .upper }
}

/// A single card is either one of the 26 letters or one of the 8 blends.
/// This drives exactly one thing — the blends filter (SPEC §5.6).
enum CardKind: String, Codable, Hashable {
    case letter
    case blend
}

/// How this card's example words relate to its sound.
///
/// Nothing in English starts with `oo`, `ee`, `ck` or `ng`, and no word a
/// small child knows starts with `x`, so those five cards use `contains`
/// (SPEC §3.3). It's data rather than a special case in view code, and it
/// changes one thing in the UI: the label above the word grid.
enum WordRule: String, Codable, Hashable {
    case startsWith
    case contains

    var backLabel: String {
        switch self {
        case .startsWith: "Words that start with this sound"
        case .contains: "Words with this sound"
        }
    }

    /// The check the content test in `ContentTests` enforces against every
    /// word of every card.
    func isSatisfied(by word: String, sound: String) -> Bool {
        let word = word.lowercased()
        let sound = sound.lowercased()
        switch self {
        case .startsWith: return word.hasPrefix(sound)
        case .contains: return word.contains(sound)
        }
    }
}

struct Word: Codable, Hashable, Identifiable {
    let text: String
    let emoji: String
    /// Reserved for recorded audio (SPEC §8). Absent in v1.
    let audioFile: String?

    var id: String { text }
}

struct LetterCard: Codable, Hashable, Identifiable {
    let id: Int
    let kind: CardKind
    /// Absent for `ck`, `ng`, `oo` and `ee`, which have no capital form. A
    /// fake "Oo" would teach a shape the child will never meet in print, so
    /// it isn't invented (SPEC §3.4).
    let upper: String?
    let lower: String
    let soundHint: String
    let wordRule: WordRule
    let words: [Word]
    /// Reserved for recorded audio (SPEC §8). Absent in v1.
    let soundFile: String?

    var hasCasePair: Bool { upper != nil }

    /// The glyph on the front. Cards with no capital form always show their
    /// lowercase, whatever the case toggle says.
    func front(leading: LetterCase) -> String {
        guard let upper else { return lower }
        return leading == .upper ? upper : lower
    }

    /// The glyph on the back — the opposite case — or `nil` when there is no
    /// pair to show, in which case the back shows only the words.
    func back(leading: LetterCase) -> String? {
        guard let upper else { return nil }
        return leading == .upper ? lower : upper
    }
}

/// Top level of `Alphabet.json`.
struct AlphabetFile: Codable, Hashable {
    let version: Int
    let cards: [LetterCard]
}
