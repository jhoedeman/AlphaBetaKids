import SwiftUI

/// Holds the Quiz tab's place in the shell. Unreachable in v1 — `RootView`'s
/// selection binding refuses to select the Quiz tab (SPEC §9) — but kept as
/// the landing spot for the real implementation rather than leaving the tag
/// pointing at `EmptyView`.
struct QuizPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "graduationcap")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
                Text("Quiz")
                    .font(Theme.labelFont(size: 22, relativeTo: .title2))
                    .foregroundStyle(Theme.textPrimary)
                Text("Coming soon.")
                    .font(Theme.wordFont(size: 17))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

#Preview {
    QuizPlaceholderView()
}
