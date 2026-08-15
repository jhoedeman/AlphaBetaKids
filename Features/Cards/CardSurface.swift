import SwiftUI

/// The physical card: surface color, corner radius, shadow. Shared by both
/// faces so they are guaranteed to be the same object mid-flip.
struct CardSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}
