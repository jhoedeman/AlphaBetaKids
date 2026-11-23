import Foundation
import Testing
@testable import AlphaBetaKids

/// The safety properties of a generated question.
///
/// These are the tests the whole phase exists for: a quiz that offers a
/// defensible answer and then shakes at the child for picking it is worse
/// than no quiz, and none of this needs a view to check.
struct QuizGeneratorTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    private static func rounds(_ mode: QuizMode, seeds: Range<UInt64> = 0..<40) -> [QuizRound] {
        seeds.map { seed in
            var generator = SeededGenerator(seed: seed)
            return QuizGenerator.round(deck: deck, mode: mode, using: &generator)
        }
    }

    private static var allQuestions: [QuizQuestion] {
        QuizMode.allCases.flatMap { rounds($0) }.flatMap(\.questions)
    }

    // MARK: - Shape

    @Test(arguments: QuizMode.allCases)
    func aRoundIsTenQuestions(mode: QuizMode) {
        for round in Self.rounds(mode, seeds: 0..<10) {
            #expect(round.questions.count == QuizGenerator.questionsPerRound)
        }
    }

    @Test(arguments: QuizMode.allCases)
    func noLetterIsAskedTwiceInARound(mode: QuizMode) {
        for round in Self.rounds(mode, seeds: 0..<10) {
            let letters = round.questions.map(\.target.lower)
            #expect(Set(letters).count == letters.count, "repeated letter: \(letters)")
        }
    }

    @Test func everyQuestionHasFourChoices() {
        for question in Self.allQuestions {
            #expect(question.choices.count == QuizGenerator.choicesPerQuestion)
        }
    }

    @Test func questionIDsAreTheirPositionInTheRound() {
        for round in Self.rounds(.mixed, seeds: 0..<5) {
            #expect(round.questions.map(\.id) == Array(0..<round.questions.count))
        }
    }

    // MARK: - The answer is right and the rest are wrong

    @Test func theCorrectChoiceStandsForTheTargetCard() {
        for question in Self.allQuestions {
            #expect(question.correctChoice.card.lower == question.target.lower)
        }
    }

    /// The core property. A distractor that stands for the target would be a
    /// second correct answer.
    @Test func everyDistractorIsWrong() {
        for question in Self.allQuestions {
            for (i, choice) in question.choices.enumerated() where i != question.correctIndex {
                #expect(choice.card.lower != question.target.lower,
                        "\(question.target.lower): distractor \(choice.id) is also correct")
            }
        }
    }

    /// Two tiles standing for the same letter would make one of them
    /// arbitrarily "the" wrong answer.
    @Test func noTwoChoicesShareACard() {
        for question in Self.allQuestions {
            let cards = question.choices.map(\.card.lower)
            #expect(Set(cards).count == cards.count, "duplicate card in \(cards)")
        }
    }

    // MARK: - The two content traps

    /// A picture choice carries no caption, so the child names it himself.
    /// Anything whose obvious name starts elsewhere must never be a tile.
    @Test func noFlaggedPictureEverBecomesAChoice() {
        for question in Self.allQuestions {
            for choice in question.choices {
                if case .picture(_, let word) = choice {
                    #expect(word.isPictureClear,
                            "\(word.text) is flagged ambiguous but was offered as a tile")
                }
            }
        }
    }

    /// The prompt in mode A is spoken by the parent, so a flagged picture
    /// would be *answerable* — but it would make the parent say "igloo" over a
    /// picture of a hut, teaching the child that the picture cannot be trusted.
    /// Both modes draw prompts and tiles from the same clear pool.
    @Test func noFlaggedPictureEverBecomesAPrompt() {
        var prompts = 0
        for question in Self.allQuestions {
            guard let prompt = question.promptWord else { continue }
            prompts += 1
            #expect(prompt.isPictureClear,
                    "\(question.target.lower) was prompted with flagged '\(prompt.text)'")
        }
        #expect(prompts > 0, "no mode-A questions were generated, so nothing was checked")
    }

    /// c, k and q are all /k/ in this content, so offering two of them in one
    /// question punishes a child for reasoning from sound to letter.
    @Test func lettersSharingASoundNeverAppearTogether() {
        for question in Self.allQuestions {
            let letters = Set(question.choices.map(\.card.lower))
            for letter in letters {
                let clash = Self.deck.soundClass(for: letter)
                    .intersection(letters)
                    .subtracting([letter])
                #expect(clash.isEmpty,
                        "\(question.target.lower): \(letter) offered alongside \(clash.sorted())")
            }
        }
    }

    // MARK: - Mode

    @Test func aSingleModeRoundOnlyPosesThatKindOfQuestion() {
        for round in Self.rounds(.pictureToLetter, seeds: 0..<10) {
            #expect(round.questions.allSatisfy { $0.style == .pictureToLetter })
        }
        for round in Self.rounds(.letterToPicture, seeds: 0..<10) {
            #expect(round.questions.allSatisfy { $0.style == .letterToPicture })
        }
    }

    @Test func mixedProducesBothKinds() {
        let styles = Set(Self.rounds(.mixed, seeds: 0..<20).flatMap(\.questions).map(\.style))
        #expect(styles == Set(QuestionStyle.allCases))
    }

    @Test func thePromptMatchesTheStyle() {
        for question in Self.allQuestions {
            switch question.style {
            case .pictureToLetter:
                #expect(question.promptWord != nil, "no picture to show")
                #expect(question.choices.allSatisfy {
                    if case .letter = $0 { true } else { false }
                })
            case .letterToPicture:
                #expect(question.promptWord == nil)
                #expect(question.choices.allSatisfy {
                    if case .picture = $0 { true } else { false }
                })
            }
        }
    }

    // MARK: - Every card can still be asked about

    /// `i`, `n`, `q`, `y` and `z` are down to one or two pictures that can
    /// stand alone. If a content edit took the last one, that letter would
    /// silently stop being askable in the picture-choice mode.
    @Test func everyQuizCardCanPoseAPictureChoiceQuestion() {
        for card in Self.deck.quizCards {
            var generator = SeededGenerator(seed: 99)
            let question = QuizGenerator.question(
                id: 0, target: card, style: .letterToPicture,
                deck: Self.deck, using: &generator)
            #expect(question != nil, "\(card.lower) cannot pose a picture question")
        }
    }

    // MARK: - Weighting

    /// The weight is the card's clear-picture count, capped.
    @Test func weightIsTheClearPictureCountUpToTheCap() {
        func card(_ letter: String) -> LetterCard {
            Self.deck.quizCards.first { $0.lower == letter }!
        }
        #expect(QuizGenerator.weight(for: card("z")) == 1)   // zebra alone
        #expect(QuizGenerator.weight(for: card("q")) == 2)   // queen, quiet
        #expect(QuizGenerator.weight(for: card("i")) == 3)   // ice, island, ice cream
        #expect(QuizGenerator.weight(for: card("c")) == QuizGenerator.maxWeight)
        #expect(QuizGenerator.weight(for: card("s")) == QuizGenerator.maxWeight)
    }

    /// The point of the weighting: a card with one usable picture shows that
    /// same picture every time it is asked about, so it should come up less
    /// than a card with a full pool.
    @Test func thinCardsComeUpLessOftenThanFullOnes() {
        var counts: [String: Int] = [:]
        for round in Self.rounds(.mixed, seeds: 0..<300) {
            for question in round.questions {
                counts[question.target.lower, default: 0] += 1
            }
        }
        let z = counts["z"] ?? 0          // weight 1
        let full = counts["c"] ?? 0       // weight 4
        #expect(z < full / 2, "z appeared \(z) times, c \(full) — not thinned")
    }

    /// But never silenced. A letter the quiz skips entirely is worse than one
    /// it covers repetitively.
    @Test func everyQuizCardStillAppearsSometimes() {
        var seen: Set<String> = []
        for round in Self.rounds(.mixed, seeds: 0..<300) {
            for question in round.questions { seen.insert(question.target.lower) }
        }
        let missing = Set(Self.deck.quizCards.map(\.lower)).subtracting(seen)
        #expect(missing.isEmpty, "never asked about: \(missing.sorted())")
    }

    // MARK: - Reproducibility

    @Test func theSameSeedGivesTheSameRound() {
        var a = SeededGenerator(seed: 7)
        var b = SeededGenerator(seed: 7)
        let first = QuizGenerator.round(deck: Self.deck, mode: .mixed, using: &a)
        let second = QuizGenerator.round(deck: Self.deck, mode: .mixed, using: &b)
        #expect(first.questions == second.questions)
    }

    @Test func differentSeedsGiveDifferentRounds() {
        var a = SeededGenerator(seed: 1)
        var b = SeededGenerator(seed: 2)
        let first = QuizGenerator.round(deck: Self.deck, mode: .mixed, using: &a)
        let second = QuizGenerator.round(deck: Self.deck, mode: .mixed, using: &b)
        #expect(first.questions != second.questions)
    }
}
