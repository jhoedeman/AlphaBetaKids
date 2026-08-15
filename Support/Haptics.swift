import UIKit

/// Thin wrapper over `UIFeedbackGenerator` — one of the two UIKit
/// dependencies the spec allows (§2), since SwiftUI has no native haptics
/// API. Carried over from the sibling AlphaBeta app.
enum Haptics {
    static func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
