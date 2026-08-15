import SwiftUI

/// The front of a card: the glyph, and nothing that competes with it.
///
/// No English name, no letter name, no category label — a 3-year-old needs
/// the shape (SPEC §6.1). The only other mark is a small flip affordance.
struct CardFrontView: View {
    let card: LetterCard
    let leadingCase: LetterCase

    private var glyph: String { card.front(leading: leadingCase) }

    var body: some View {
        CardSurface {
            ZStack(alignment: .bottomTrailing) {
                Text(glyph)
                    .font(Theme.letterFont(size: 180))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary.opacity(0.45))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.spokenDescription(for: leadingCase))
        .accessibilityHint("Tap to turn over")
    }
}

extension LetterCard {
    /// VoiceOver phrasing for a face. Spelling the case out matters here —
    /// "B" and "b" are read identically otherwise.
    func spokenDescription(for shownCase: LetterCase) -> String {
        guard hasCasePair else { return lower }
        return shownCase == .upper ? "Capital \(lower)" : "Lowercase \(lower)"
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        CardFrontView(
            card: try! CardDeck.load().allCards[1],
            leadingCase: .upper
        )
        .frame(width: 289, height: 400)
    }
}
