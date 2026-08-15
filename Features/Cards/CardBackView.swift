import SwiftUI

/// The back of a card: the opposite case, and four example words with emoji
/// pictures (SPEC §6.2).
///
/// The emoji carry the meaning — a pre-reader can't read "bottle", so the
/// picture is the content and the word is there for the adult reading along.
struct CardBackView: View {
    let card: LetterCard
    let leadingCase: LetterCase

    @Environment(\.letterAudio) private var audio

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        CardSurface {
            VStack(spacing: 14) {
                if let opposite = card.back(leading: leadingCase) {
                    caseRow(opposite: opposite)
                }

                Text(card.wordRule.backLabel)
                    .font(Theme.labelFont(size: 13, relativeTo: .footnote))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(card.words) { word in
                        wordCell(word)
                    }
                }
            }
            // Centre the stack as a whole rather than letting the grid
            // stretch. Cards with no case row (ck, ng, oo, ee) would
            // otherwise strand the label at the top with dead space around
            // the grid.
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// The opposite case, large — that's the point of turning the card over —
    /// with the front's case small alongside so the pairing is visible.
    /// Absent entirely for `ck`, `ng`, `oo` and `ee`, which have no capital
    /// form (SPEC §3.4).
    private func caseRow(opposite: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(opposite)
                .font(Theme.letterFont(size: 62))
                .foregroundStyle(Theme.accent)

            Text(card.front(leading: leadingCase))
                .font(Theme.letterFont(size: 30))
                .foregroundStyle(Theme.textSecondary)

            speakerButton
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    /// Laid out but invisible while no audio provider is available, so that
    /// adding recordings later does not reflow the card (SPEC §8).
    private var speakerButton: some View {
        Button {
            audio.playSound(for: card)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
        }
        .opacity(audio.isAvailable ? 1 : 0)
        .allowsHitTesting(audio.isAvailable)
        .accessibilityHidden(!audio.isAvailable)
        .accessibilityLabel("Play the sound")
    }

    private func wordCell(_ word: Word) -> some View {
        VStack(spacing: 2) {
            Text(word.emoji)
                .font(.system(size: 40))
            Text(word.text)
                .font(Theme.wordFont(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        if card.back(leading: leadingCase) != nil {
            parts.append(card.spokenDescription(for: leadingCase.opposite))
        }
        parts.append(card.wordRule.backLabel)
        parts.append(card.words.map(\.text).joined(separator: ", "))
        return parts.joined(separator: ". ")
    }
}

#Preview("Letter") {
    ZStack {
        Theme.background.ignoresSafeArea()
        CardBackView(card: try! CardDeck.load().allCards[1], leadingCase: .upper)
            .frame(width: 289, height: 400)
    }
}

#Preview("Blend with no capital") {
    ZStack {
        Theme.background.ignoresSafeArea()
        CardBackView(
            card: try! CardDeck.load().allCards.first { $0.lower == "oo" }!,
            leadingCase: .upper
        )
        .frame(width: 289, height: 400)
    }
}
