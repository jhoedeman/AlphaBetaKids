import SwiftUI

/// What the round came to, addressed to the parent.
///
/// Deliberately not a reward screen. There are no stars, no streak, no
/// "you got 7!" — the child cannot read any of it, and a score he cannot
/// read but can tell is worse than last time is a reason to stop playing.
/// What the parent gets is the one thing worth knowing: which letters need
/// another look.
struct QuizFinishView: View {
    let round: QuizRound
    let leadingCase: LetterCase
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                score
                missed
                buttons
            }
            .padding(20)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background(Theme.background.ignoresSafeArea())
    }

    // MARK: - Score

    /// Scored out of what he actually answered, not out of ten.
    ///
    /// A skip is not a miss — that is the whole reason `QuizRound.skip()`
    /// records its own outcome and the ledger ignores it — so counting skips
    /// against him here would undo that distinction at the last step.
    ///
    /// With nothing answered there is no score to show. "0 of 0" is not a
    /// result, and a giant zero over a round the parent ended after one
    /// question reads as a verdict on the child rather than on the tap that
    /// ended it.
    @ViewBuilder
    private var score: some View {
        VStack(spacing: 6) {
            if round.answeredCount > 0 {
                Text("\(round.firstTryCorrectCount) of \(round.answeredCount)")
                    .font(Theme.letterFont(size: 56, relativeTo: .largeTitle))
                    .foregroundStyle(round.firstTryCorrectCount == round.answeredCount
                                     ? Theme.success : Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("right on the first try")
                    .font(Theme.labelFont(size: 16, relativeTo: .body))
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text("Nothing answered")
                    .font(Theme.labelFont(size: 22, relativeTo: .title2))
                    .foregroundStyle(Theme.textPrimary)
            }
            if let aside {
                Text(aside)
                    .font(Theme.wordFont(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenScore)
        .padding(.top, 8)
    }

    /// Only shown when there is something to explain, so a clean round of ten
    /// says nothing extra.
    ///
    /// An ended-early round says how far it got rather than how much was left:
    /// "7 not reached" asks the parent to subtract, and the figure that
    /// matters to them is the one they stopped at.
    private var aside: String? {
        var parts: [String] = []
        if round.unreachedCount > 0 {
            parts.append("Ended after \(round.count - round.unreachedCount) of \(round.count)")
        }
        if round.skippedCount > 0 {
            parts.append("\(round.skippedCount) skipped")
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ") + "."
    }

    private var spokenScore: String {
        let headline = round.answeredCount > 0
            ? "\(round.firstTryCorrectCount) of \(round.answeredCount) right on the first try."
            : "Nothing answered."
        return headline + (aside.map { " \($0)" } ?? "")
    }

    // MARK: - Missed letters

    @ViewBuilder
    private var missed: some View {
        if round.missedCards.isEmpty {
            // Silent when nothing was answered — the score block has already
            // said so, and saying it twice makes an early exit feel scolded.
            if round.answeredCount > 0 {
                Text("Every one first time.")
                    .font(Theme.wordFont(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 10)
            }
        } else {
            VStack(spacing: 12) {
                Text("Worth another look")
                    .font(Theme.labelFont(size: 14, relativeTo: .footnote))
                    .foregroundStyle(Theme.textSecondary)

                // Wraps on its own, because a round can miss up to ten and a
                // fixed row would push them off a small phone.
                FlowRow(spacing: 10) {
                    ForEach(round.missedCards) { card in
                        Text(card.front(leading: leadingCase))
                            .font(Theme.letterFont(size: 30, relativeTo: .title))
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                            .frame(minWidth: 52, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.surface)
                                    .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
                            )
                            .accessibilityLabel(card.spokenDescription(for: leadingCase))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions

    private var buttons: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.selection()
                onPlayAgain()
            } label: {
                Text("Go again")
                    .font(Theme.labelFont(size: 19, relativeTo: .headline))
                    .foregroundStyle(Theme.surface)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Haptics.selection()
                onDone()
            } label: {
                Text("Done")
                    .font(Theme.labelFont(size: 17, relativeTo: .body))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)
        }
    }
}

/// A line-wrapping row. The missed-letters list is the only place in the app
/// that needs one, and `Layout` is cheaper than nesting guessed-at HStacks.
private struct FlowRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, in: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let widest = rows.map(\.width).max() ?? 0
        return CGSize(width: min(widest, width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, in: bounds.width)
        var y = bounds.minY
        for row in rows {
            // Centred, so one leftover letter on the last line does not sit
            // off to the side.
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width, !row.indices.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}

#Preview("Some missed") {
    let deck = try! CardDeck.load()
    var generator = SystemRandomNumberGenerator()
    var round = QuizGenerator.round(deck: deck, mode: .mixed, using: &generator)
    for step in 0..<10 {
        round.recordFirstTap(correct: step % 3 != 0)
        round.advance()
    }
    return QuizFinishView(round: round, leadingCase: .upper,
                          onPlayAgain: {}, onDone: {})
}

#Preview("Ended early") {
    let deck = try! CardDeck.load()
    var generator = SystemRandomNumberGenerator()
    var round = QuizGenerator.round(deck: deck, mode: .mixed, using: &generator)
    round.skip()
    return QuizFinishView(round: round, leadingCase: .upper,
                          onPlayAgain: {}, onDone: {})
}

#Preview("Clean round") {
    let deck = try! CardDeck.load()
    var generator = SystemRandomNumberGenerator()
    var round = QuizGenerator.round(deck: deck, mode: .pictureToLetter, using: &generator)
    for _ in 0..<10 {
        round.recordFirstTap(correct: true)
        round.advance()
    }
    return QuizFinishView(round: round, leadingCase: .lower,
                          onPlayAgain: {}, onDone: {})
}
