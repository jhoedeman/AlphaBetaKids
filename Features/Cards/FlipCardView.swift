import SwiftUI

/// Turns the card over (SPEC §6.3).
///
/// Deliberately stateless: whether this card is flipped is owned by
/// `CardsView`, which keys it to a single card id. That is what makes
/// "paging to a different card resets it to the front" true by construction
/// rather than by cleanup — and it keeps the off-screen neighbours rendering
/// their fronts while they slide past.
struct FlipCardView: View {
    let card: LetterCard
    let leadingCase: LetterCase
    let isFlipped: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var angle: Double { isFlipped ? 180 : 0 }

    var body: some View {
        Group {
            if reduceMotion {
                crossFade
            } else {
                flip
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.impactLight()
            withAnimation(reduceMotion
                ? .easeInOut(duration: 0.25)
                : .spring(response: 0.45, dampingFraction: 0.78)) {
                onTap()
            }
        }
    }

    private var flip: some View {
        ZStack {
            CardFrontView(card: card, leadingCase: leadingCase)
                .modifier(FaceVisibility(angle: angle, face: .front))

            CardBackView(card: card, leadingCase: leadingCase)
                // Pre-rotated so it reads correctly once the container has
                // turned the card around.
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .modifier(FaceVisibility(angle: angle, face: .back))
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
    }

    private var crossFade: some View {
        ZStack {
            CardFrontView(card: card, leadingCase: leadingCase)
                .opacity(isFlipped ? 0 : 1)
            CardBackView(card: card, leadingCase: leadingCase)
                .opacity(isFlipped ? 1 : 0)
        }
    }
}

/// Hides whichever face is pointing away, switching exactly at the 90°
/// crossing.
///
/// This has to be `Animatable` rather than a plain `.opacity(isFlipped ...)`:
/// a plain opacity animates on its own curve alongside the rotation, so both
/// faces are partly visible through the middle of the turn and the back's
/// text shows through the front. Driving visibility off the interpolated
/// angle means the swap happens at the one instant the card is edge-on.
private struct FaceVisibility: ViewModifier, Animatable {
    enum Face { case front, back }

    var angle: Double
    let face: Face

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        // A spring can overshoot past 180°, so this is a threshold rather
        // than an equality check.
        let isFacingViewer = face == .front ? angle < 90 : angle >= 90
        content.opacity(isFacingViewer ? 1 : 0)
    }
}

#Preview {
    @Previewable @State var flipped = false

    ZStack {
        Theme.background.ignoresSafeArea()
        FlipCardView(
            card: try! CardDeck.load().allCards[1],
            leadingCase: .upper,
            isFlipped: flipped
        ) {
            flipped.toggle()
        }
        .frame(width: 289, height: 400)
    }
}
