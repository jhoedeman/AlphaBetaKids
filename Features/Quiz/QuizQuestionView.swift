import SwiftUI

/// One question: a prompt, four choices, and ten dots.
///
/// Stateless about the round — `QuizView` owns that — but it does own which
/// tiles have been tapped wrong, because that is per-question scratch and
/// resets when the question changes.
struct QuizQuestionView: View {
    let question: QuizQuestion
    let leadingCase: LetterCase
    let dotsFilled: Int
    let totalQuestions: Int
    let onTap: (QuizChoice, _ isCorrect: Bool) -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tiles the child has tried and got wrong. Per question, so it clears
    /// when the question does — which `.id(question.id)` upstream guarantees.
    @State private var rejected: Set<String> = []
    @State private var accepted: String?
    @State private var shaking: String?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        VStack(spacing: 18) {
            prompt

            // Addressed to the adult: the child cannot read it, and does not
            // need to (quiz design §1).
            Text(question.instruction)
                .font(Theme.labelFont(size: 14, relativeTo: .footnote))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(question.choices) { choice in
                    tile(choice)
                }
            }

            dots
        }
        .padding(20)
        .frame(maxWidth: 460)
        // The back of a card proved this ceiling for four-up content; the
        // same geometry needs the same cap.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .overlay(alignment: .topTrailing) { skipButton }
    }

    // MARK: - Prompt

    @ViewBuilder
    private var prompt: some View {
        switch question.style {
        case .pictureToLetter:
            Text(question.promptWord?.emoji ?? "")
                .font(.system(size: 96))
                .accessibilityLabel(question.promptWord?.text ?? "")
        case .letterToPicture:
            Text(question.target.front(leading: leadingCase))
                .font(Theme.letterFont(size: 96))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel(question.target.spokenDescription(for: leadingCase))
        }
    }

    // MARK: - Choices

    private func tile(_ choice: QuizChoice) -> some View {
        let isAccepted = accepted == choice.id
        let isRejected = rejected.contains(choice.id)

        return Button {
            tap(choice)
        } label: {
            Group {
                switch choice {
                case .letter(let card):
                    Text(card.front(leading: leadingCase))
                        .font(Theme.letterFont(size: 44))
                        .foregroundStyle(isAccepted ? Theme.onSuccess : Theme.accent)
                case .picture(_, let word):
                    Text(word.emoji)
                        .font(.system(size: 46))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, minHeight: 86)
            // Surface, not background: a tile filled with the screen colour
            // is invisible, and the child has nothing to aim at. White chips
            // on grey is the idiom the control bar already uses.
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isAccepted ? Theme.success : Theme.surface)
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
            )
            // Dimmed, but deliberately still tappable: a wrong answer is not
            // removed, so the child can keep trying and the parent can point
            // at it (quiz design §6.3).
            .opacity(isRejected ? 0.35 : 1)
            .scaleEffect(isAccepted ? 1.06 : 1)
            .modifier(ShakeEffect(shaking: shaking == choice.id && !reduceMotion))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.spokenLabel(leading: leadingCase))
        // Movement says nothing to VoiceOver, so the state has to be spoken.
        .accessibilityValue(isAccepted ? "Correct" : (isRejected ? "Not this one" : ""))
    }

    private func tap(_ choice: QuizChoice) {
        let isCorrect = choice.id == question.correctChoice.id
        Haptics.impactLight()

        if isCorrect {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                accepted = choice.id
            }
        } else {
            rejected.insert(choice.id)
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .default) {
                shaking = choice.id
            }
            // The shake is one-shot; clear it so a second tap shakes again.
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                if shaking == choice.id { shaking = nil }
            }
        }
        onTap(choice, isCorrect)
    }

    // MARK: - Furniture

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalQuestions, id: \.self) { index in
                Circle()
                    .fill(index < dotsFilled ? Theme.accent : Theme.textSecondary.opacity(0.25))
                    .frame(width: 9, height: 9)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(min(dotsFilled + 1, totalQuestions)) of \(totalQuestions)")
    }

    /// Present but quiet, like the card front's flip affordance. Without it a
    /// child who stalls leaves the round unfinishable and the only exit is
    /// closing the app — the ending the fixed round exists to avoid.
    private var skipButton: some View {
        Button(action: onSkip) {
            Image(systemName: "forward.end")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary.opacity(0.45))
                .padding(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip this question")
    }
}

/// A one-shot horizontal wobble.
///
/// `Animatable` on a travelling value rather than a repeating animation, so
/// it is a single gesture with a definite end instead of something that has
/// to be switched off.
private struct ShakeEffect: ViewModifier, Animatable {
    var shaking: Bool

    private var travel: CGFloat { shaking ? 1 : 0 }

    func body(content: Content) -> some View {
        content.offset(x: sin(travel * .pi * 3) * 9)
            .animation(.easeInOut(duration: 0.32), value: shaking)
    }
}

#Preview("Picture, pick the letter") {
    let deck = try! CardDeck.load()
    var generator = SystemRandomNumberGenerator()
    let round = QuizGenerator.round(deck: deck, mode: .pictureToLetter, using: &generator)

    ZStack {
        Theme.background.ignoresSafeArea()
        QuizQuestionView(question: round.questions[0], leadingCase: .upper,
                         dotsFilled: 3, totalQuestions: 10,
                         onTap: { _, _ in }, onSkip: {})
    }
}

#Preview("Letter, pick the picture") {
    let deck = try! CardDeck.load()
    var generator = SystemRandomNumberGenerator()
    let round = QuizGenerator.round(deck: deck, mode: .letterToPicture, using: &generator)

    ZStack {
        Theme.background.ignoresSafeArea()
        QuizQuestionView(question: round.questions[0], leadingCase: .upper,
                         dotsFilled: 7, totalQuestions: 10,
                         onTap: { _, _ in }, onSkip: {})
    }
}
