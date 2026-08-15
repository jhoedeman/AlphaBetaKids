import Foundation
import Testing
@testable import AlphaBetaKids

/// Raw values that cross a persistence boundary. Renaming any of these cases
/// compiles cleanly and breaks silently at runtime, which is exactly the kind
/// of failure worth a test.
struct PreferencesTests {

    /// `LetterCase` is stored in UserDefaults under "leadingCase". A rename
    /// would quietly reset every user's case preference to the default.
    @Test func letterCaseRawValuesAreStable() {
        #expect(LetterCase.upper.rawValue == "upper")
        #expect(LetterCase.lower.rawValue == "lower")
        #expect(LetterCase(rawValue: "upper") == .upper)
        #expect(LetterCase(rawValue: "lower") == .lower)
    }

    /// The default is capitals, so an unreadable stored value must land there
    /// rather than anywhere else.
    @Test func unknownStoredCaseFallsBackToCapitals() {
        #expect(LetterCase(rawValue: "") == nil)
        #expect(LetterCase(rawValue: "Upper") == nil)
        #expect((LetterCase(rawValue: "garbage") ?? .upper) == .upper)
    }

    @Test func oppositeFlipsBothWays() {
        #expect(LetterCase.upper.opposite == .lower)
        #expect(LetterCase.lower.opposite == .upper)
        #expect(LetterCase.upper.opposite.opposite == .upper)
    }

    /// These cross the JSON boundary rather than UserDefaults — a rename
    /// would fail to decode Alphabet.json at launch.
    @Test func jsonRawValuesAreStable() {
        #expect(CardKind.letter.rawValue == "letter")
        #expect(CardKind.blend.rawValue == "blend")
        #expect(WordRule.startsWith.rawValue == "startsWith")
        #expect(WordRule.contains.rawValue == "contains")
    }
}
