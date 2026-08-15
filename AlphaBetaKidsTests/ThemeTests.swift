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
