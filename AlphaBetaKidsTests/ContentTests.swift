import Foundation
import Testing
@testable import AlphaBetaKids

/// The content *is* the product here, so it's verified in code rather than by
/// eye (SPEC §11). Every rule in SPEC §3.5 has a test below.
///
/// Tests run hosted inside AlphaBetaKids.app, so `Bundle.main` is the app
/// bundle carrying Content/Resources.
struct ContentTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    private var cards: [LetterCard] { Self.deck.allCards }

    // MARK: - Shape

    @Test func decodesTheExpectedDeck() throws {
        #expect(cards.count == 34)
        #expect(cards.filter { $0.kind == .letter }.count == 26)
        #expect(cards.filter { $0.kind == .blend }.count == 8)
    }

    @Test func idsAreUniqueAndCorrectlyPartitioned() {
        #expect(Set(cards.map(\.id)).count == cards.count)
        #expect(cards.filter { $0.kind == .letter }.map(\.id).sorted() == Array(1...26))
        #expect(cards.filter { $0.kind == .blend }.map(\.id).sorted() == Array(27...34))
    }

    @Test func lettersAreAlphabeticalByID() {
        let letters = cards.filter { $0.kind == .letter }.sorted { $0.id < $1.id }
        #expect(letters.map(\.lower) == "abcdefghijklmnopqrstuvwxyz".map(String.init))
    }

    // MARK: - SPEC §3.5 rule 1 — every card has four complete words

    @Test(arguments: Self.deck.allCards)
    func hasAPoolOfFourToTenCompleteWords(card: LetterCard) {
        #expect((4...10).contains(card.words.count),
                "\(card.lower) has a pool of \(card.words.count)")
        for word in card.words {
            #expect(!word.text.isEmpty, "\(card.lower) has an empty word")
            #expect(!word.emoji.isEmpty, "\(card.lower)/\(word.text) has no emoji")
        }
        #expect(!card.soundHint.isEmpty, "\(card.lower) has no sound hint")
    }

    @Test(arguments: Self.deck.allCards)
    func wordsAreNotRepeatedWithinACard(card: LetterCard) {
        #expect(Set(card.words.map(\.text)).count == card.words.count,
                "\(card.lower) repeats a word")
    }

    // MARK: - SPEC §3.5 rule 2 — every word satisfies its own wordRule

    @Test(arguments: Self.deck.allCards)
    func everyWordSatisfiesItsRule(card: LetterCard) {
        for word in card.words {
            #expect(card.wordRule.isSatisfied(by: word.text, sound: card.lower),
                    "\(card.lower): '\(word.text)' fails \(card.wordRule.rawValue)")
        }
    }

    @Test func exactlyTheExpectedCardsUseTheContainsRule() {
        let containsCards = Set(cards.filter { $0.wordRule == .contains }.map(\.lower))
        #expect(containsCards == ["x", "ck", "ng", "oo", "ee"])
    }

    // MARK: - SPEC §3.5 rule 3 — the easiest content mistake to make

    /// A letter card must never use a word beginning with a blend that is
    /// itself a card: "ship" on the `s` card teaches /ʃ/ as the sound of S.
    /// Deliberate exceptions run the other way (the `ee` card uses "sheep"),
    /// so this checks letter cards only.
    @Test func noLetterCardUsesAWordStartingWithABlend() {
        let blendPrefixes = cards
            .filter { $0.kind == .blend && $0.wordRule == .startsWith }
            .map(\.lower)

        for card in cards where card.kind == .letter {
            for word in card.words {
                let text = word.text.lowercased()
                for blend in blendPrefixes where text.hasPrefix(blend) {
                    Issue.record("""
                        Letter card '\(card.lower)' uses '\(word.text)', which starts \
                        with the blend '\(blend)' — that teaches the wrong sound.
                        """)
                }
            }
        }
    }

    // MARK: - Pictures

    /// For a pre-reader the emoji *is* the content, so two cards sharing one
    /// picture teaches a collision — the child sees the same elephant for
    /// "elephant" and for "zoo". Reading the content table doesn't reveal
    /// this, because it's a property of the set rather than of any one row.
    ///
    /// The exceptions are pairs where both words genuinely denote the same
    /// thing, so the shared picture is honest rather than confusing.
    @Test func picturesAreNotReusedAcrossCards() {
        let allowed: Set<Set<String>> = [
            ["q", "wh"],   // 🤫 quiet / whisper
            ["q", "ck"],   // 🦆 quack / duck
            ["sh", "ee"],  // 🐑 sheep — sh + ee = sheep, deliberate
        ]

        var cardsByEmoji: [String: Set<String>] = [:]
        for card in cards {
            for word in card.words {
                cardsByEmoji[word.emoji, default: []].insert(card.lower)
            }
        }

        for (emoji, owners) in cardsByEmoji where owners.count > 1 {
            #expect(allowed.contains(owners),
                    "\(emoji) is shared by \(owners.sorted().joined(separator: ", "))")
        }
    }

    /// A child who cannot yet read letters generally cannot read numerals
    /// either, so a keycap digit is not a picture to them. `z`/zero and
    /// `th`/three are knowingly kept — see the verification notes in the spec
    /// — but nothing new should join them.
    @Test func picturesAreNotKeycapDigits() {
        let knownExceptions = ["zero", "three"]
        for card in cards {
            for word in card.words where !knownExceptions.contains(word.text) {
                #expect(!word.emoji.unicodeScalars.contains { ("0"..."9").contains(Character($0)) },
                        "\(card.lower)/\(word.text) uses a keycap digit, not a picture")
            }
        }
    }

    // MARK: - Quiz eligibility (quiz design §5)

    /// The quiz may only draw on letter cards whose rule is `startsWith`.
    /// Everything else files pictures under a sound they contain rather than
    /// the letter they begin with — 🌙 lives on `oo` but a child says "moon".
    @Test func quizCardsAreTheTwentyFiveStartsWithLetters() {
        let quiz = Self.deck.quizCards
        #expect(quiz.count == 25)
        #expect(Set(quiz.map(\.lower)) == Set("abcdefghijklmnopqrstuvwyz".map(String.init)))
        #expect(!quiz.contains { $0.lower == "x" })
    }

    /// The property that makes distractors safe without further filtering:
    /// inside the 25, a word always begins with its own card's letter, so one
    /// borrowed from another card can never be a correct answer.
    @Test func everyQuizWordBeginsWithItsOwnCardsLetter() {
        for card in Self.deck.quizCards {
            for word in card.words {
                #expect(word.text.lowercased().hasPrefix(card.lower),
                        "\(card.lower): '\(word.text)' does not begin with it")
            }
        }
    }

    /// Word-level safety is not picture-level safety. A tile carries no
    /// caption, so a picture whose obvious name starts elsewhere is a trap.
    @Test func thePicturePoolIsTheClearPicturesOnly() {
        let all = Self.deck.quizCards.flatMap(\.words)
        let flagged = all.filter { !$0.isPictureClear }
        #expect(all.count == 209, "expected 209 words on the quiz cards")
        #expect(flagged.count == 53, "expected 53 flagged pictures")
        #expect(Self.deck.picturePool().count == 156)
    }

    /// The one that catches a future content edit flagging a card's last
    /// usable picture — that card would silently stop being able to pose a
    /// picture-choice question at all.
    @Test func everyQuizCardKeepsAtLeastOneClearPicture() {
        for card in Self.deck.quizCards {
            let clear = card.words.filter(\.isPictureClear)
            #expect(!clear.isEmpty, "\(card.lower) has no picture that can stand alone")
        }
    }

    @Test func flaggedPicturesAreNeverInThePicturePool() {
        let pooled = Set(Self.deck.picturePool().map(\.word.text))
        for card in Self.deck.quizCards {
            for word in card.words where !word.isPictureClear {
                #expect(!pooled.contains(word.text),
                        "\(word.text) is flagged but still pooled")
            }
        }
    }

    // MARK: - Sound classes

    /// c, k and q are all /k/ in this content, so they must never be offered
    /// as each other's wrong answers.
    @Test func cKAndQShareASoundClass() {
        #expect(Self.deck.soundClass(for: "c") == ["c", "k", "q"])
        #expect(Self.deck.soundClass(for: "k") == ["c", "k", "q"])
        #expect(Self.deck.soundClass(for: "q") == ["c", "k", "q"])
    }

    @Test func aLetterWithNoSharedSoundIsAloneInItsClass() {
        #expect(Self.deck.soundClass(for: "b") == ["b"])
        #expect(Self.deck.soundClass(for: "m") == ["m"])
    }

    @Test func soundClassesOnlyNameRealCards() {
        let known = Set(cards.map(\.lower))
        for group in Self.deck.soundClasses {
            for letter in group {
                #expect(known.contains(letter), "sound class names unknown card '\(letter)'")
            }
        }
    }

    // MARK: - SPEC §3.4 — cards with no capital form

    @Test func exactlyTheExpectedCardsLackACapitalForm() {
        let caseless = Set(cards.filter { !$0.hasCasePair }.map(\.lower))
        #expect(caseless == ["ck", "ng", "oo", "ee"])
    }

    @Test(arguments: Self.deck.allCards)
    func caselessCardsAlwaysShowLowercase(card: LetterCard) {
        guard !card.hasCasePair else { return }
        #expect(card.front(leading: .upper) == card.lower)
        #expect(card.front(leading: .lower) == card.lower)
        #expect(card.back(leading: .upper) == nil)
    }

    @Test(arguments: Self.deck.allCards)
    func casedCardsShowTheOppositeOnTheBack(card: LetterCard) throws {
        guard card.hasCasePair else { return }
        let upper = try #require(card.upper)
        #expect(card.front(leading: .upper) == upper)
        #expect(card.back(leading: .upper) == card.lower)
        #expect(card.front(leading: .lower) == card.lower)
        #expect(card.back(leading: .lower) == upper)
    }

    // MARK: - Labels

    @Test func wordRuleDrivesTheBackLabel() {
        #expect(WordRule.startsWith.backLabel == "Words that start with this sound")
        #expect(WordRule.contains.backLabel == "Words with this sound")
    }
}
