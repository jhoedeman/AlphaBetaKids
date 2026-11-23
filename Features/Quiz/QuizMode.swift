import Foundation

/// What the parent picks on the start screen.
///
/// Three options, but a *question* is only ever one of two things — see
/// `QuestionStyle`. Keeping them as separate types makes "no question is
/// mixed" structural rather than a comment someone has to remember.
enum QuizMode: String, CaseIterable, Codable, Hashable {
    case pictureToLetter
    case letterToPicture
    case mixed

    /// Worded for the adult reading it, since the child cannot read any of it.
    var title: String {
        switch self {
        case .pictureToLetter: "Picture, pick the letter"
        case .letterToPicture: "Letter, pick the picture"
        case .mixed: "Mixed"
        }
    }

    var detail: String {
        switch self {
        case .pictureToLetter: "You name the picture; he finds the letter it starts with."
        case .letterToPicture: "You name the letter; he finds something starting with it."
        case .mixed: "Both kinds, shuffled together."
        }
    }

    /// Which kind of question to pose next. Only `mixed` consults the
    /// generator; the other two are already decided.
    func resolve<G: RandomNumberGenerator>(using generator: inout G) -> QuestionStyle {
        switch self {
        case .pictureToLetter: .pictureToLetter
        case .letterToPicture: .letterToPicture
        case .mixed: Bool.random(using: &generator) ? .pictureToLetter : .letterToPicture
        }
    }
}

/// What a single question actually is. Deliberately has no `mixed` case.
///
/// This is also the ledger's second key: recognising B and recalling B are
/// different skills, and a mode-blind record would average the two and drill
/// the wrong one.
enum QuestionStyle: String, CaseIterable, Codable, Hashable {
    /// A picture is shown; the four choices are letters.
    case pictureToLetter
    /// A letter is shown; the four choices are pictures.
    case letterToPicture
}
