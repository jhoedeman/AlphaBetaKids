import Foundation
import Testing
@testable import AlphaBetaKids

/// Position and scoring for a round in progress.
struct QuizRoundTests {
    private static let deck: CardDeck = {
        do { return try CardDeck.load() } catch { fatalError("\(error)") }
    }()

    private static func freshRound(seed: UInt64 = 5) -> QuizRound {
        var generator = SeededGenerator(seed: seed)
        return QuizGenerator.round(deck: deck, mode: .mixed, using: &generator)
    }

    // MARK: - Position

    @Test func aFreshRoundStartsOnTheFirstQuestionWithNoDotsFilled() {
        let round = Self.freshRound()
        #expect(round.index == 0)
        #expect(round.dotsFilled == 0)
        #expect(round.isFinished == false)
        #expect(round.current?.id == 0)
    }

    @Test func advancingFillsADotAndEndsAfterTheLastQuestion() {
        var round = Self.freshRound()
        for step in 1...round.count {
            round.advance()
            #expect(round.dotsFilled == step)
        }
        #expect(round.isFinished)
        #expect(round.current == nil)
    }

    /// Clamped rather than crashing, the way `PagerPosition` clamps the deck.
    @Test func advancingPastTheEndIsHarmless() {
        var round = Self.freshRound()
        for _ in 0..<(round.count + 5) { round.advance() }
        #expect(round.index == round.count)
        #expect(round.dotsFilled == round.count)
    }

    // MARK: - Only the first tap counts

    /// A wrong tile stays tappable, so the child always arrives at the right
    /// answer in the end. Were later taps recorded, every question would read
    /// as correct and the ledger would say nothing.
    @Test func onlyTheFirstTapIsRecorded() {
        var round = Self.freshRound()
        round.recordFirstTap(correct: false)
        round.recordFirstTap(correct: true)
        round.recordFirstTap(correct: true)
        #expect(round.firstTryCorrectCount == 0)
        #expect(round.missedCards.count == 1)
    }

    @Test func currentIsAnsweredFlipsOnTheFirstTapOnly() {
        var round = Self.freshRound()
        #expect(round.currentIsAnswered == false)
        round.recordFirstTap(correct: true)
        #expect(round.currentIsAnswered)
        round.advance()
        #expect(round.currentIsAnswered == false)
    }

    @Test func scoringCountsFirstTapsAcrossTheRound() {
        var round = Self.freshRound()
        let pattern = [true, false, true, true, false, true, true, true, false, true]
        for correct in pattern {
            round.recordFirstTap(correct: correct)
            round.advance()
        }
        #expect(round.firstTryCorrectCount == pattern.filter { $0 }.count)
        #expect(round.missedCards.count == pattern.filter { !$0 }.count)
        #expect(round.answeredCount == pattern.count)
    }

    @Test func missedCardsComeBackInTheOrderTheyWereAsked() {
        var round = Self.freshRound()
        let expected = [round.questions[0].target.lower, round.questions[2].target.lower]
        round.recordFirstTap(correct: false); round.advance()
        round.recordFirstTap(correct: true);  round.advance()
        round.recordFirstTap(correct: false); round.advance()
        #expect(round.missedCards.map(\.lower) == expected)
    }

    // MARK: - Skipping

    /// A skip cannot tell "doesn't know it" from "has wandered off", so it is
    /// not scored either way — it must not reach the ledger.
    @Test func skippingAdvancesWithoutScoring() {
        var round = Self.freshRound()
        round.skip()
        #expect(round.index == 1)
        #expect(round.firstTryCorrectCount == 0)
        #expect(round.missedCards.isEmpty)
        #expect(round.answeredCount == 0)
    }

    @Test func skippingAnAnsweredQuestionKeepsTheAnswer() {
        var round = Self.freshRound()
        round.recordFirstTap(correct: true)
        round.skip()
        #expect(round.firstTryCorrectCount == 1)
        #expect(round.answeredCount == 1)
    }

    @Test func aRoundOfNothingButSkipsScoresNothingAndStillFinishes() {
        var round = Self.freshRound()
        for _ in 0..<round.count { round.skip() }
        #expect(round.isFinished)
        #expect(round.answeredCount == 0)
        #expect(round.missedCards.isEmpty)
        #expect(round.skippedCount == round.count)
    }

    // MARK: - What the finish screen reports

    /// The finish screen scores out of what was answered, so the three kinds
    /// of non-answer have to stay apart: skipped, never reached, and wrong.
    /// Lumping any two together would show the parent a number that reads as
    /// "he got these wrong" when he did not.
    @Test func theThreeKindsOfUnansweredAreCountedSeparately() {
        var round = Self.freshRound()
        round.recordFirstTap(correct: true)   // 1 right
        round.advance()
        round.recordFirstTap(correct: false)  // 1 wrong
        round.advance()
        round.skip()                          // 1 skipped
        round.skip()                          // 2 skipped
        // Ended here, with six never reached.

        #expect(round.firstTryCorrectCount == 1)
        #expect(round.missedCards.count == 1)
        #expect(round.answeredCount == 2)
        #expect(round.skippedCount == 2)
        #expect(round.unreachedCount == round.count - 4)
        // The invariant the screen leans on: every question is in exactly one
        // of the four buckets.
        #expect(round.answeredCount + round.skippedCount + round.unreachedCount == round.count)
    }

    @Test func aRoundPlayedToTheEndLeavesNothingUnreached() {
        var round = Self.freshRound()
        for _ in 0..<round.count {
            round.recordFirstTap(correct: true)
            round.advance()
        }
        #expect(round.unreachedCount == 0)
        #expect(round.skippedCount == 0)
        #expect(round.answeredCount == round.count)
    }

    /// The case that distinguishes "unreached" from "behind the cursor".
    ///
    /// `QuizView` holds on the green tile for a beat before advancing, so
    /// "End" can land while the current question is answered but not yet
    /// stepped past. Counting unreached as `count - index` would then count
    /// that question twice — once as answered, once as unreached — and the
    /// finish screen's figures would add up to eleven.
    @Test func endingWhileTheAnsweredQuestionIsStillCurrentCountsItOnce() {
        var round = Self.freshRound()
        round.recordFirstTap(correct: true)
        // No advance: this is mid-pause.

        #expect(round.index == 0)
        #expect(round.answeredCount == 1)
        #expect(round.unreachedCount == round.count - 1)
        #expect(round.answeredCount + round.skippedCount + round.unreachedCount == round.count)
    }

    @Test func anUntouchedRoundIsEntirelyUnreached() {
        let round = Self.freshRound()
        #expect(round.unreachedCount == round.count)
        #expect(round.answeredCount == 0)
        #expect(round.skippedCount == 0)
    }
}
