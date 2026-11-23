import Foundation

/// Ten questions and where the child is in them.
///
/// Position arithmetic is clamped the same way `PagerPosition` clamps the
/// deck's, so an off-by-one at either end is a wrong number rather than a
/// crash. All mutation is through the three methods below; nothing else
/// touches `index`.
struct QuizRound: Hashable {
    /// How a question ended. A skip is deliberately *not* an outcome that
    /// reaches the ledger — see `skip()`.
    enum Outcome: Hashable {
        case correctFirstTry
        case missedFirstTry
        case skipped
    }

    let questions: [QuizQuestion]
    private(set) var index: Int = 0
    /// Keyed by question id. Absent until the child's first tap, which is the
    /// only tap that counts.
    private(set) var outcomes: [Int: Outcome] = [:]

    init(questions: [QuizQuestion]) {
        self.questions = questions
    }

    // MARK: - Position

    var current: QuizQuestion? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    var isFinished: Bool { index >= questions.count }

    /// How many of the ten dots are filled: the questions behind him.
    var dotsFilled: Int { min(index, questions.count) }

    var count: Int { questions.count }

    // MARK: - Progress

    /// Records the child's answer, and ignores every tap after the first.
    ///
    /// With a wrong tile staying live he always reaches the right answer in
    /// the end, so "answered correctly" is always true and worthless. The
    /// first tap is the honest measure (quiz design §7.2).
    mutating func recordFirstTap(correct: Bool) {
        guard let current, outcomes[current.id] == nil else { return }
        outcomes[current.id] = correct ? .correctFirstTry : .missedFirstTry
    }

    /// Whether this question has already been answered once, which is what
    /// the view uses to decide if a tap still counts.
    var currentIsAnswered: Bool {
        guard let current else { return false }
        return outcomes[current.id] != nil
    }

    mutating func advance() {
        guard !isFinished else { return }
        index += 1
    }

    /// Abandons the current question without judging it.
    ///
    /// A skip cannot tell "doesn't know it" from "has wandered off", so
    /// guessing either way would poison the ledger the scheduler depends on.
    /// It records `skipped`, which the ledger ignores.
    mutating func skip() {
        guard let current else { return }
        if outcomes[current.id] == nil { outcomes[current.id] = .skipped }
        advance()
    }

    // MARK: - Results

    var firstTryCorrectCount: Int {
        outcomes.values.filter { $0 == .correctFirstTry }.count
    }

    var answeredCount: Int {
        outcomes.values.filter { $0 != .skipped }.count
    }

    /// The cards he missed on the first tap, in the order they were asked —
    /// what the finish screen shows the parent.
    var missedCards: [LetterCard] {
        questions
            .filter { outcomes[$0.id] == .missedFirstTry }
            .map(\.target)
    }
}
