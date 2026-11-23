import Foundation
import Testing
@testable import AlphaBetaKids

struct QuizLedgerTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    /// A question about a known letter in a known style, so tests can assert
    /// on the key rather than on whatever the generator happened to pick.
    private static func question(_ letter: String, _ style: QuestionStyle) -> QuizQuestion {
        let card = deck.quizCards.first { $0.lower == letter }!
        var generator = SeededGenerator(seed: 3)
        return QuizGenerator.question(id: 0, target: card, style: style,
                                      deck: deck, using: &generator)!
    }

    // MARK: - Recording

    @Test func recordingACorrectFirstTap() {
        var ledger = QuizLedger()
        ledger.record(.correctFirstTry, for: Self.question("b", .pictureToLetter))
        let entry = ledger.entry(letter: "b", style: .pictureToLetter)
        #expect(entry?.asked == 1)
        #expect(entry?.firstTryCorrect == 1)
        #expect(entry?.recent == [true])
        #expect(entry?.lastSeenAt != nil)
    }

    @Test func recordingAMiss() {
        var ledger = QuizLedger()
        ledger.record(.missedFirstTry, for: Self.question("b", .pictureToLetter))
        let entry = ledger.entry(letter: "b", style: .pictureToLetter)
        #expect(entry?.asked == 1)
        #expect(entry?.firstTryCorrect == 0)
        #expect(entry?.firstTryMissed == 1)
        #expect(entry?.recent == [false])
    }

    /// The rule lives here rather than in the view, so it is testable and so
    /// no caller has to remember it.
    @Test func aSkipIsNotRecordedAtAll() {
        var ledger = QuizLedger()
        ledger.record(.skipped, for: Self.question("b", .pictureToLetter))
        #expect(ledger.isEmpty)
        #expect(ledger.entry(letter: "b", style: .pictureToLetter) == nil)
    }

    @Test func skipsDoNotDisturbRealAnswers() {
        var ledger = QuizLedger()
        let question = Self.question("b", .pictureToLetter)
        ledger.record(.correctFirstTry, for: question)
        ledger.record(.skipped, for: question)
        #expect(ledger.entry(letter: "b", style: .pictureToLetter)?.asked == 1)
    }

    // MARK: - Letter and style are both keys

    /// Recognising B and recalling B are different skills. A style-blind
    /// ledger would average them and the scheduler would drill the wrong one.
    @Test func theTwoStylesAreCountedSeparately() {
        var ledger = QuizLedger()
        ledger.record(.correctFirstTry, for: Self.question("b", .pictureToLetter))
        ledger.record(.missedFirstTry, for: Self.question("b", .letterToPicture))

        #expect(ledger.entry(letter: "b", style: .pictureToLetter)?.firstTryCorrect == 1)
        #expect(ledger.entry(letter: "b", style: .letterToPicture)?.firstTryCorrect == 0)
        #expect(ledger.entries.count == 2)
    }

    @Test func differentLettersDoNotShareAnEntry() {
        var ledger = QuizLedger()
        ledger.record(.correctFirstTry, for: Self.question("b", .pictureToLetter))
        ledger.record(.correctFirstTry, for: Self.question("m", .pictureToLetter))
        #expect(ledger.entries.count == 2)
        #expect(ledger.entry(letter: "b", style: .pictureToLetter)?.asked == 1)
        #expect(ledger.entry(letter: "m", style: .pictureToLetter)?.asked == 1)
    }

    // MARK: - The rolling window

    @Test func theRecentWindowKeepsNewestFirst() {
        var ledger = QuizLedger()
        let question = Self.question("b", .pictureToLetter)
        ledger.record(.missedFirstTry, for: question)
        ledger.record(.correctFirstTry, for: question)
        #expect(ledger.entry(letter: "b", style: .pictureToLetter)?.recent == [true, false])
    }

    /// The only thing stopping a single `@AppStorage` string from growing
    /// without bound.
    @Test func theRecentWindowStopsAtItsCapButTheCountersDoNot() {
        var ledger = QuizLedger()
        let question = Self.question("b", .pictureToLetter)
        for _ in 0..<(QuizLedger.recentWindow * 3) {
            ledger.record(.correctFirstTry, for: question)
        }
        let entry = ledger.entry(letter: "b", style: .pictureToLetter)
        #expect(entry?.recent.count == QuizLedger.recentWindow)
        #expect(entry?.asked == QuizLedger.recentWindow * 3)
    }

    // MARK: - Storage

    @Test func itRoundTripsThroughJSON() {
        var ledger = QuizLedger()
        ledger.record(.correctFirstTry, for: Self.question("b", .pictureToLetter))
        ledger.record(.missedFirstTry, for: Self.question("q", .letterToPicture))
        #expect(QuizLedger(json: ledger.json) == ledger)
    }

    @Test func anEmptyLedgerRoundTrips() {
        let ledger = QuizLedger()
        #expect(QuizLedger(json: ledger.json).isEmpty)
    }

    /// Losing the history is bad; refusing to launch over it is worse.
    @Test(arguments: ["", "not json", "{\"entries\":", "[]", "null"])
    func unreadableStorageYieldsAnEmptyLedger(blob: String) {
        #expect(QuizLedger(json: blob).isEmpty)
    }

    @Test func clearingEmptiesIt() {
        var ledger = QuizLedger()
        ledger.record(.correctFirstTry, for: Self.question("b", .pictureToLetter))
        #expect(!ledger.isEmpty)
        ledger.clear()
        #expect(ledger.isEmpty)
        #expect(QuizLedger(json: ledger.json).isEmpty)
    }

    // MARK: - A whole round

    @Test func awholeRoundRecordsItsAnswersAndIgnoresItsSkips() {
        var generator = SeededGenerator(seed: 11)
        var round = QuizGenerator.round(deck: Self.deck, mode: .mixed, using: &generator)
        var ledger = QuizLedger()

        // answer, miss, skip, then the rest answered
        let script: [QuizRound.Outcome] = [
            .correctFirstTry, .missedFirstTry, .skipped, .correctFirstTry, .correctFirstTry,
            .skipped, .missedFirstTry, .correctFirstTry, .correctFirstTry, .correctFirstTry,
        ]
        for outcome in script {
            guard let question = round.current else { break }
            ledger.record(outcome, for: question)
            switch outcome {
            case .correctFirstTry: round.recordFirstTap(correct: true)
            case .missedFirstTry: round.recordFirstTap(correct: false)
            case .skipped: break
            }
            round.advance()
        }

        let recorded = ledger.entries.values.reduce(0) { $0 + $1.asked }
        #expect(recorded == 8, "two skips should leave eight recorded")
        let correct = ledger.entries.values.reduce(0) { $0 + $1.firstTryCorrect }
        #expect(correct == 6)
    }
}
