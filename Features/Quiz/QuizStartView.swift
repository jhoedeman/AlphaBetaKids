import SwiftUI

/// The quiz's front door, and the only screen in the app written for the
/// adult rather than the child.
///
/// The quiz is parent-driven by design (quiz design §1) — the parent reads
/// each question aloud — so the mode choice, the explanation of what each
/// mode does, and the reset all live here, before the child is looking at
/// anything. Nothing on this screen is meant for a three-year-old to operate.
struct QuizStartView: View {
    @Binding var mode: QuizMode
    let ledgerIsEmpty: Bool
    let onStart: () -> Void
    let onResetLedger: () -> Void

    @State private var isConfirmingReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                VStack(spacing: 10) {
                    ForEach(QuizMode.allCases, id: \.self) { option in
                        modeRow(option)
                    }
                }

                startButton

                if !ledgerIsEmpty {
                    resetButton
                }
            }
            .padding(20)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        // Parent-facing text, so it scales to the same ceiling as the control
        // bar rather than the card's larger one.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background(Theme.background.ignoresSafeArea())
        .confirmationDialog(
            "Clear what the quiz remembers?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive, action: onResetLedger)
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Every letter starts over. This can't be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text("Quiz")
                .font(Theme.labelFont(size: 26, relativeTo: .title))
                .foregroundStyle(Theme.textPrimary)
            // The one instruction that matters. Everything else about the
            // quiz assumes the two of them are sitting together.
            Text("Ten questions. Read each one aloud and let him tap the answer.")
                .font(Theme.wordFont(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Mode

    private func modeRow(_ option: QuizMode) -> some View {
        let isSelected = mode == option
        return Button {
            guard !isSelected else { return }
            Haptics.selection()
            mode = option
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(Theme.labelFont(size: 17, relativeTo: .body))
                        .foregroundStyle(Theme.textPrimary)
                    Text(option.detail)
                        .font(Theme.wordFont(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.4))
            }
            .multilineTextAlignment(.leading)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.07), radius: 5, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title). \(option.detail)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Actions

    private var startButton: some View {
        Button {
            Haptics.selection()
            onStart()
        } label: {
            Text("Start")
                .font(Theme.labelFont(size: 19, relativeTo: .headline))
                .foregroundStyle(Theme.surface)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Quiet, last, and behind a confirmation — it throws away history that
    /// cannot be rebuilt, and the device is in a three-year-old's hands.
    private var resetButton: some View {
        Button {
            isConfirmingReset = true
        } label: {
            Text("Clear what the quiz remembers")
                .font(Theme.labelFont(size: 13, relativeTo: .footnote))
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
}

#Preview("Nothing recorded yet") {
    QuizStartView(mode: .constant(.pictureToLetter), ledgerIsEmpty: true,
                  onStart: {}, onResetLedger: {})
}

#Preview("With history") {
    QuizStartView(mode: .constant(.mixed), ledgerIsEmpty: false,
                  onStart: {}, onResetLedger: {})
}
