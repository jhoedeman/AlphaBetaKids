import SwiftUI

/// The three parent-facing controls above the deck (SPEC §5.6).
///
/// Case is a two-way toggle rather than the sibling app's independent
/// multi-select pills: with one card per letter, "both on" and "capitals
/// only" would be indistinguishable to the child, and "both off" would need
/// an empty state for no good reason.
struct ControlBar: View {
    @Binding var leadingCase: LetterCase
    @Binding var blendsEnabled: Bool
    let isShuffled: Bool
    let onShuffle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            caseToggle
            blendsPill
            shuffleButton
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Case

    private var caseToggle: some View {
        HStack(spacing: 2) {
            caseSegment(.upper, glyph: "A")
            caseSegment(.lower, glyph: "a")
        }
        .padding(3)
        .background(Theme.surface, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Letter case")
    }

    private func caseSegment(_ value: LetterCase, glyph: String) -> some View {
        let isSelected = leadingCase == value
        return Button {
            guard !isSelected else { return }
            Haptics.selection()
            leadingCase = value
        } label: {
            Text(glyph)
                .font(Theme.letterFont(size: 21, relativeTo: .body))
                .foregroundStyle(isSelected ? Theme.surface : Theme.textSecondary)
                .frame(width: 38, height: 32)
                .background(isSelected ? Theme.accent : .clear, in: Capsule())
        }
        .accessibilityLabel(value == .upper ? "Capitals" : "Lowercase")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Blends

    private var blendsPill: some View {
        Button {
            Haptics.selection()
            blendsEnabled.toggle()
        } label: {
            Text("Blends")
                .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
                .foregroundStyle(blendsEnabled ? Theme.surface : Theme.textSecondary)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(blendsEnabled ? Theme.accent : Theme.surface, in: Capsule())
        }
        .accessibilityLabel("Blends")
        .accessibilityValue(blendsEnabled ? "On" : "Off")
        .accessibilityAddTraits(blendsEnabled ? [.isSelected] : [])
    }

    // MARK: - Shuffle

    private var shuffleButton: some View {
        Button(action: onShuffle) {
            Image(systemName: "shuffle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isShuffled ? Theme.surface : Theme.textSecondary)
                .frame(width: 44, height: 38)
                .background(isShuffled ? Theme.accent : Theme.surface, in: Capsule())
        }
        .accessibilityLabel("Shuffle")
        .accessibilityValue(isShuffled ? "On" : "Off")
        .accessibilityAddTraits(isShuffled ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var leadingCase: LetterCase = .upper
    @Previewable @State var blends = false
    @Previewable @State var shuffled = false

    ZStack {
        Theme.background.ignoresSafeArea()
        ControlBar(
            leadingCase: $leadingCase,
            blendsEnabled: $blends,
            isShuffled: shuffled,
            onShuffle: { shuffled.toggle() }
        )
    }
}
