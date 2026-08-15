import SwiftUI
import UIKit

/// The entire visual system: five colors and one font family.
///
/// There is no ThemeManager, no palette registry, and no picker — unlike the
/// sibling AlphaBeta app, this one has exactly one look (SPEC §7). Light and
/// dark resolve from the system automatically, which is free because the
/// palette already carries both sets of values.
enum Theme {

    // MARK: - Color

    /// "Hellenic Blue", lifted verbatim from AlphaBeta's `greek-flag` palette.
    static let background = Color(light: 0xE7_E9_ED, dark: 0x0D_16_25)
    static let surface = Color(light: 0xFF_FF_FF, dark: 0x15_20_40)
    static let accent = Color(light: 0x10_55_E8, dark: 0x3D_80_FF)
    static let textPrimary = Color(light: 0x1A_28_45, dark: 0xEE_F2_FD)
    static let textSecondary = Color(light: 0x3D_5A_85, dark: 0x8F_A4_C8)

    // MARK: - Type

    /// The three bundled Andika faces, keyed by **PostScript** name.
    ///
    /// These do not match the filenames, and there is no pattern to infer:
    /// `Andika-Regular.ttf` registers as plain `Andika`, and SIL ships
    /// SemiBold as its own family ("Andika SemiBold", subfamily "Regular")
    /// whose PostScript name happens to be `Andika-SemiBold`. Looking up by
    /// PostScript name sidesteps the family weirdness entirely. See SPEC §7.2.
    enum Face: String, CaseIterable {
        case regular = "Andika"
        case semibold = "Andika-SemiBold"
        case bold = "Andika-Bold"

        /// Used only when the font files are missing from the bundle.
        var fallbackWeight: Font.Weight {
            switch self {
            case .regular: .regular
            case .semibold: .semibold
            case .bold: .bold
            }
        }
    }

    /// Andika is a literacy font: single-story `a` and `g`, unambiguous
    /// `I`/`l`/`1`. That is the whole reason it is bundled — an app teaching
    /// letter shapes to a pre-reader must not teach shapes the child will not
    /// meet in a book.
    ///
    /// Deliberately not `Font.custom` directly: that falls back silently on a
    /// wrong or missing name, producing a build that looks fine while showing
    /// the wrong letterforms — exactly the failure this font prevents.
    static func font(_ face: Face, size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        isAvailable(face)
            ? .custom(face.rawValue, size: size, relativeTo: style)
            : .system(size: size, weight: face.fallbackWeight, design: .rounded)
    }

    static func isAvailable(_ face: Face) -> Bool {
        UIFont(name: face.rawValue, size: 12) != nil
    }

    /// The hero glyph and the case row on the card back.
    static func letterFont(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        font(.bold, size: size, relativeTo: style)
    }

    /// The example words.
    static func wordFont(size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        font(.regular, size: size, relativeTo: style)
    }

    /// Labels and controls.
    static func labelFont(size: CGFloat, relativeTo style: Font.TextStyle = .subheadline) -> Font {
        font(.semibold, size: size, relativeTo: style)
    }
}

private extension Color {
    /// Builds a color that resolves per appearance, so light/dark works
    /// without an asset catalog entry per token.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
