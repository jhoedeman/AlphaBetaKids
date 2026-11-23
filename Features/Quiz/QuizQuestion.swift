import Foundation

/// One of the four things a child can tap.
///
/// Each carries the whole `LetterCard` it stands for rather than just a
/// glyph, so the view can apply the current `leadingCase` at render time and
/// the capital/lowercase toggle does not invalidate a round in progress.
enum QuizChoice: Hashable, Identifiable {
    case letter(LetterCard)
    case picture(card: LetterCard, word: Word)

    /// The card this choice stands for. Two choices in one question never
    /// share a card, so this identifies the answer.
    var card: LetterCard {
        switch self {
        case .letter(let card): card
        case .picture(let card, _): card
        }
    }

    var id: String {
        switch self {
        case .letter(let card): "letter-\(card.lower)"
        case .picture(_, let word): "picture-\(word.text)"
        }
    }

    /// What VoiceOver should say. A bare emoji reads as its Unicode name or
    /// not at all, so the picture choices announce their word.
    func spokenLabel(leading: LetterCase) -> String {
        switch self {
        case .letter(let card): card.spokenDescription(for: leading)
        case .picture(_, let word): word.text
        }
    }
}

/// A single question: one prompt, four choices, one of them right.
struct QuizQuestion: Hashable, Identifiable {
    /// Position in its round, from 0.
    let id: Int
    let style: QuestionStyle
    /// The card being tested. The correct choice is the one standing for it.
    let target: LetterCard
    /// The picture shown above the choices in `pictureToLetter`.
    ///
    /// May be a picture flagged `ambiguousPicture` — that flag only bars a
    /// picture from being an unlabelled *choice*. Here the parent reads the
    /// word aloud, which is exactly what settles it.
    let promptWord: Word?
    let choices: [QuizChoice]
    let correctIndex: Int

    var correctChoice: QuizChoice { choices[correctIndex] }

    /// The line the parent reads out. The child cannot read it; that is the
    /// point — see the quiz design §1.
    var instruction: String {
        switch style {
        case .pictureToLetter:
            "Which letter does \(promptWord?.text ?? target.lower) start with?"
        case .letterToPicture:
            "Which one starts with this sound?"
        }
    }
}
