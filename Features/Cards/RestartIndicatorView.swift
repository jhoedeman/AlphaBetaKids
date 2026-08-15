import SwiftUI

/// The capsule shown for ~1.5s after tapping the restart button (SPEC §5.4).
struct RestartIndicatorView: View {
    var body: some View {
        Text("Back to the beginning!")
            .font(Theme.labelFont(size: 15, relativeTo: .subheadline))
            .foregroundStyle(Theme.surface)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Theme.accent, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        RestartIndicatorView()
    }
}
