import SwiftUI

/// The Quiz tab: start, play, finish.
///
/// Owns the only two pieces of quiz state that outlive a view — the round in
/// progress, and the ledger — exactly as `CardsView` owns the deck's order
/// and position. Everything below it is told what to draw.
struct QuizView: View {
    let deck: CardDeck

    /// Shared with the Cards tab on purpose: the parent sets capitals or
    /// lowercase once, and the quiz tests the shapes the child has been
    /// looking at. The quiz offers no toggle of its own.
    @AppStorage("leadingCase") private var leadingCaseRaw = LetterCase.upper.rawValue
    @AppStorage("quizMode") private var quizModeRaw = QuizMode.pictureToLetter.rawValue
    /// The ledger, as one JSON blob (SPEC §2 keeps all persisted state in
    /// `@AppStorage`; the ledger is a value type, so this is the whole store).
    @AppStorage("quizLedger") private var ledgerJSON = "{}"

    @State private var round: QuizRound?
    @State private var finished: QuizRound?
    /// The question an advance is already pending for, so tapping the right
    /// answer twice during the pause does not skip the next question.
    @State private var advancingFrom: Int?

    private var leadingCase: LetterCase {
        LetterCase(rawValue: leadingCaseRaw) ?? .upper
    }

    private var mode: QuizMode {
        QuizMode(rawValue: quizModeRaw) ?? .pictureToLetter
    }

    private var modeBinding: Binding<QuizMode> {
        Binding(get: { mode }, set: { quizModeRaw = $0.rawValue })
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let finished {
                QuizFinishView(
                    round: finished,
                    leadingCase: leadingCase,
                    onPlayAgain: start,
                    onDone: { self.finished = nil }
                )
            } else if let round, let question = round.current {
                playing(round: round, question: question)
            } else {
                QuizStartView(
                    mode: modeBinding,
                    ledgerIsEmpty: QuizLedger(json: ledgerJSON).isEmpty,
                    onStart: start,
                    onResetLedger: resetLedger
                )
            }
        }
    }

    // MARK: - Playing

    private func playing(round: QuizRound, question: QuizQuestion) -> some View {
        VStack(spacing: 0) {
            roundBar
            Spacer(minLength: 0)
            QuizQuestionView(
                question: question,
                leadingCase: leadingCase,
                dotsFilled: round.dotsFilled,
                totalQuestions: round.count,
                onTap: tap
            )
            // Per-question scratch state (which tiles have been tried) lives
            // in the question view, so the identity has to change with the
            // question or a wrong tile would stay dimmed into the next one.
            .id(question.id)
            Spacer(minLength: 0)
        }
    }

    /// Both controls that belong to the round rather than the question, in a
    /// strip of their own. The skip used to float over the question's corner,
    /// which read as detached from everything.
    private var roundBar: some View {
        HStack {
            Button(action: endRound) {
                Text("End")
                    .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("End the round")

            Spacer()

            Button(action: skip) {
                HStack(spacing: 5) {
                    Text("Skip")
                    Image(systemName: "forward.end.fill").font(.system(size: 12))
                }
                .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip this question")
        }
        .padding(.horizontal, 10)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Actions

    private func start() {
        finished = nil
        advancingFrom = nil
        round = QuizGenerator.round(deck: deck, mode: mode)
    }

    /// The child's tap. The round decides whether it counts; the ledger is
    /// written only for the tap that did.
    private func tap(_ choice: QuizChoice, isCorrect: Bool) {
        guard var current = round, let question = current.current else { return }

        let alreadyAnswered = current.currentIsAnswered
        current.recordFirstTap(correct: isCorrect)
        round = current

        if !alreadyAnswered, let outcome = current.outcomes[question.id] {
            var ledger = QuizLedger(json: ledgerJSON)
            ledger.record(outcome, for: question)
            ledgerJSON = ledger.json
        }

        if isCorrect { advance(after: question.id) }
    }

    /// Holds on the green tile for a beat before moving on, so the child sees
    /// that he was right rather than having the screen change out from under
    /// his finger.
    private func advance(after id: Int) {
        guard advancingFrom != id else { return }
        advancingFrom = id
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            // The round may have been ended or restarted in the meantime.
            guard round?.current?.id == id else { return }
            withAnimation(.easeInOut(duration: 0.2)) { step() }
            advancingFrom = nil
        }
    }

    private func skip() {
        guard var current = round else { return }
        Haptics.selection()
        // `skip()` both records and advances; the outcome it records is the
        // one the ledger ignores, so nothing is written here.
        current.skip()
        round = current
        if current.isFinished { finish(current) }
    }

    private func step() {
        guard var current = round else { return }
        current.advance()
        round = current
        if current.isFinished { finish(current) }
    }

    /// Ending early still shows the finish screen, with the questions never
    /// reached named as such rather than counted against him.
    private func endRound() {
        guard let current = round else { return }
        Haptics.selection()
        finish(current)
    }

    private func finish(_ round: QuizRound) {
        self.round = nil
        advancingFrom = nil
        finished = round
    }

    private func resetLedger() {
        var ledger = QuizLedger(json: ledgerJSON)
        ledger.clear()
        ledgerJSON = ledger.json
    }
}

#Preview {
    QuizView(deck: try! CardDeck.load())
}
