import SwiftUI

/// The pager: one card per gesture, arrows in the gutters, restart at the end.
///
/// `TabView`'s page style is the whole point (SPEC §5.2). One page per gesture
/// is *structural* there — swipe velocity is irrelevant, so an uncoordinated
/// fling from a small hand advances exactly one letter and stops. That is why
/// this is not the sibling app's `ScrollView` + `.viewAligned`, where a hard
/// fling skates across several cards.
///
/// Card content is injected so this file owns paging and nothing else; M4
/// passes the real flip card.
struct CardPagerView<CardContent: View>: View {
    let cards: [LetterCard]
    @Binding var selectedID: Int
    @ViewBuilder let cardContent: (LetterCard) -> CardContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showRestartIndicator = false
    @State private var restartDismissTask: Task<Void, Never>?
    @State private var hasAppeared = false
    /// Restart fires its own `.selection()` haptic, so the settle haptic that
    /// the resulting selection change would otherwise trigger is skipped.
    @State private var suppressSettleHaptic = false

    /// Preserves the 260:360 card proportions from the sibling app.
    private let cardAspectRatio: CGFloat = 360.0 / 260.0
    /// Leaves ~14% of the width as a gutter on each side — just enough to
    /// hold a 56pt arrow without it overlapping the card.
    private let cardWidthFraction: CGFloat = 0.72
    /// Stops the card ballooning on iPad, where 72% of the width would be
    /// absurd. The extra width becomes gutter instead.
    private let maxCardWidth: CGFloat = 420
    private let arrowSize: CGFloat = 56

    private var position: PagerPosition {
        .locating(id: selectedID, in: cards)
    }

    var body: some View {
        GeometryReader { geometry in
            let card = cardSize(fitting: geometry.size)

            ZStack(alignment: .top) {
                TabView(selection: $selectedID) {
                    ForEach(cards) { item in
                        cardContent(item)
                            .frame(width: card.width, height: card.height)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                arrowOverlay
                    .frame(maxHeight: .infinity)

                if showRestartIndicator {
                    RestartIndicatorView()
                        .padding(.top, 8)
                        .transition(reduceMotion
                            ? .opacity
                            : .move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .onAppear { hasAppeared = true }
        .onChange(of: selectedID) { _, _ in
            guard hasAppeared else { return }
            guard !suppressSettleHaptic else {
                suppressSettleHaptic = false
                return
            }
            Haptics.impactLight()
        }
        .onDisappear { restartDismissTask?.cancel() }
    }

    // MARK: - Layout

    /// Width-driven, then height-capped so a short screen shrinks the card
    /// rather than clipping it.
    private func cardSize(fitting available: CGSize) -> CGSize {
        var width = min(available.width * cardWidthFraction, maxCardWidth)
        var height = width * cardAspectRatio
        if height > available.height {
            height = available.height
            width = height / cardAspectRatio
        }
        return CGSize(width: width, height: height)
    }

    // MARK: - Arrows

    private var arrowOverlay: some View {
        HStack {
            arrowButton(
                systemImage: "chevron.left",
                label: "Previous letter",
                isEnabled: !position.isAtStart
            ) {
                select(position.retreated(), animated: true)
            }

            Spacer()

            // One button in one slot whose symbol swaps at the end of the
            // deck, rather than a dimmed dead control plus a separate restart
            // appearing elsewhere — the child's hand already knows this spot
            // (SPEC §5.4).
            arrowButton(
                systemImage: position.isAtEnd ? "arrow.counterclockwise" : "chevron.right",
                label: position.isAtEnd ? "Back to the beginning" : "Next letter",
                isEnabled: !cards.isEmpty
            ) {
                if position.isAtEnd {
                    restart()
                } else {
                    select(position.advanced(), animated: true)
                }
            }
            .contentTransition(.symbolEffect(.replace))
        }
        .padding(.horizontal, 2)
    }

    private func arrowButton(
        systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.accent : Theme.textSecondary.opacity(0.3))
                .frame(width: arrowSize, height: arrowSize)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    // MARK: - Movement

    private func select(_ target: PagerPosition, animated: Bool) {
        guard !cards.isEmpty, target.index < cards.count else { return }
        let id = cards[target.index].id
        guard id != selectedID else { return }

        if animated && !reduceMotion {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedID = id
            }
        } else {
            withoutPageAnimation { selectedID = id }
        }
    }

    private func restart() {
        guard let firstID = cards.first?.id else { return }

        if firstID != selectedID {
            suppressSettleHaptic = true
            // Deliberately un-animated: animating a page transition across
            // all 34 cards would be unpleasant to watch (SPEC §5.4).
            withoutPageAnimation { selectedID = firstID }
        }

        Haptics.selection()
        showIndicator()
    }

    private func withoutPageAnimation(_ change: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, change)
    }

    private func showIndicator() {
        withAnimation(reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.3, dampingFraction: 0.8)) {
            showRestartIndicator = true
        }

        // Cancel before replacing, so rapid repeat taps never leave a stale
        // dismissal in flight that hides a freshly-shown indicator.
        restartDismissTask?.cancel()
        restartDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                showRestartIndicator = false
            }
        }
    }
}
