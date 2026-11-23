import SwiftUI
import Testing
import UIKit
@testable import AlphaBetaKids

struct ThemeTests {

    /// The load-bearing test for SPEC §7.2. `Font.custom` falls back silently
    /// on a name that doesn't resolve, so a typo — or a future Andika release
    /// that renames a face — would ship an app that looks fine while showing
    /// double-story `a` and `g`, the exact letterforms Andika was bundled to
    /// avoid. This fails loudly instead.
    @Test(arguments: Theme.Face.allCases)
    func everyBundledFaceResolvesByPostScriptName(face: Theme.Face) {
        #expect(UIFont(name: face.rawValue, size: 24) != nil,
                "PostScript name '\(face.rawValue)' didn't resolve — is the .ttf in Content/Resources and listed in UIAppFonts?")
        #expect(Theme.isAvailable(face))
    }

    /// Guards the specific trap: the filenames are Andika-Regular/SemiBold/
    /// Bold, but only two of those are real PostScript names.
    @Test func regularIsNamedAndikaNotAndikaRegular() {
        #expect(Theme.Face.regular.rawValue == "Andika")
        #expect(UIFont(name: "Andika-Regular", size: 24) == nil,
                "If this now resolves, SIL changed the naming — revisit Theme.Face.")
    }

    @Test func facesCoverTheThreeBundledWeights() {
        #expect(Set(Theme.Face.allCases.map(\.rawValue))
            == ["Andika", "Andika-SemiBold", "Andika-Bold"])
    }
}

/// Contrast is arithmetic, so it is checked rather than eyeballed.
///
/// Only `success` is covered: it is the one token added after the palette was
/// settled, and the one whose job — reading unmistakably as approval — fails
/// quietly if it is too close to what it sits on.
struct ThemeContrastTests {

    private static func resolved(_ color: Color, dark: Bool) -> UIColor {
        UIColor(color).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light))
    }

    /// WCAG relative luminance.
    private static func luminance(_ color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    private static func contrast(_ a: UIColor, _ b: UIColor) -> CGFloat {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    @Test(arguments: [false, true])
    func theCorrectTileCarriesItsGlyphLegibly(dark: Bool) {
        let ratio = Self.contrast(Self.resolved(Theme.success, dark: dark),
                                  Self.resolved(Theme.onSuccess, dark: dark))
        #expect(ratio >= 4.5,
                "success vs its glyph is \(String(format: "%.2f", ratio)):1 in \(dark ? "dark" : "light")")
    }

    @Test(arguments: [false, true])
    func theCorrectTileStandsOutFromTheCard(dark: Bool) {
        let ratio = Self.contrast(Self.resolved(Theme.success, dark: dark),
                                  Self.resolved(Theme.surface, dark: dark))
        #expect(ratio >= 3.0,
                "success vs surface is \(String(format: "%.2f", ratio)):1 in \(dark ? "dark" : "light")")
    }

    /// Approval must not be mistakable for the accent, which is already the
    /// colour of every letter on screen.
    ///
    /// Measured as hue separation, not contrast ratio: a contrast ratio is a
    /// *luminance* comparison, and a green and a blue of similar darkness sit
    /// around 1.1:1 while being plainly different to look at. Luminance is the
    /// wrong instrument for "are these two colours telling the child different
    /// things".
    ///
    /// Hue is not the only channel carrying the message — the correct tile
    /// also fills, and §10 adds an announcement for VoiceOver — so this is a
    /// belt-and-braces check rather than the whole accessibility story.
    @Test(arguments: [false, true])
    func successIsADifferentHueFromTheAccent(dark: Bool) {
        func hue(_ color: UIColor) -> CGFloat {
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            return h * 360
        }
        let success = hue(Self.resolved(Theme.success, dark: dark))
        let accent = hue(Self.resolved(Theme.accent, dark: dark))
        let apart = min(abs(success - accent), 360 - abs(success - accent))
        #expect(apart >= 45,
                "success and accent are only \(Int(apart))° apart in \(dark ? "dark" : "light")")
    }
}
