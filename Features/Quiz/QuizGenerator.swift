import Foundation

/// Builds rounds. **This is the seam the adaptive scheduler replaces.**
///
/// Today it picks eligible letters uniformly at random. When the scheduler
/// arrives it will weight that choice by what the ledger says is weak and how
/// long since each letter was last seen — and nothing outside this one type
/// has to change. The generator takes its `RandomNumberGenerator` as an
/// `inout` parameter for the same reason `CardDeck.ordered(…using:)` does:
/// a seeded generator makes rounds reproducible in tests.
enum QuizGenerator {
    static let questionsPerRound = 10
    static let choicesPerQuestion = 4

    static func round<G: RandomNumberGenerator>(
        deck: CardDeck,
        mode: QuizMode,
        using generator: inout G
    ) -> QuizRound {
        let targets = deck.quizCards
            .shuffled(using: &generator)
            .prefix(questionsPerRound)

        let questions = targets.enumerated().compactMap { position, target in
            question(
                id: position,
                target: target,
                style: mode.resolve(using: &generator),
                deck: deck,
                using: &generator
            )
        }
        return QuizRound(questions: questions)
    }

    static func round(deck: CardDeck, mode: QuizMode) -> QuizRound {
        var generator = SystemRandomNumberGenerator()
        return round(deck: deck, mode: mode, using: &generator)
    }

    // MARK: - One question

    static func question<G: RandomNumberGenerator>(
        id: Int,
        target: LetterCard,
        style: QuestionStyle,
        deck: CardDeck,
        using generator: inout G
    ) -> QuizQuestion? {
        // Letters already spoken for. Seeded with the target's whole sound
        // class — c/k/q are all /k/ here, so a child shown a key who taps C is
        // doing exactly what the cards taught him — and then grown as each
        // distractor is chosen, because two *distractors* that share a sound
        // are the same defect between themselves. Choosing C and K as wrong
        // answers for B leaves two tiles that are equally not-B for the same
        // reason, which is the shape the test caught.
        var blocked = deck.soundClass(for: target.lower)

        switch style {
        case .pictureToLetter:
            // The parent says the word aloud here, so a flagged picture would
            // still *work* — but it would work by contradicting itself. Saying
            // "igloo" over a picture of a hut teaches the child that the
            // picture is unreliable, which is the one thing a picture in this
            // app must not be. There are 150 clear pictures, so the stricter
            // rule costs nothing and both modes now draw from the same pool.
            guard let prompt = target.words
                .filter(\.isPictureClear)
                .randomElement(using: &generator)
            else { return nil }

            var distractors: [QuizChoice] = []
            for candidate in deck.quizCards.shuffled(using: &generator) {
                guard !blocked.contains(candidate.lower) else { continue }
                blocked.formUnion(deck.soundClass(for: candidate.lower))
                distractors.append(.letter(candidate))
                if distractors.count == choicesPerQuestion - 1 { break }
            }
            guard distractors.count == choicesPerQuestion - 1 else { return nil }

            return assemble(id: id, style: style, target: target, prompt: prompt,
                            correct: .letter(target), distractors: distractors,
                            using: &generator)

        case .letterToPicture:
            // Choices here are pictures with nothing naming them, so only
            // pictures that can stand alone are eligible — both for the
            // answer and for the wrong ones.
            guard let answer = target.words
                .filter(\.isPictureClear)
                .randomElement(using: &generator)
            else { return nil }

            // `blocked` doubles as the one-picture-per-card guard: adding a
            // letter's whole sound class also adds the letter itself.
            var distractors: [QuizChoice] = []
            for candidate in deck.picturePool().shuffled(using: &generator) {
                guard !blocked.contains(candidate.card.lower) else { continue }
                blocked.formUnion(deck.soundClass(for: candidate.card.lower))
                distractors.append(.picture(card: candidate.card, word: candidate.word))
                if distractors.count == choicesPerQuestion - 1 { break }
            }
            guard distractors.count == choicesPerQuestion - 1 else { return nil }

            return assemble(id: id, style: style, target: target, prompt: nil,
                            correct: .picture(card: target, word: answer),
                            distractors: distractors, using: &generator)
        }
    }

    private static func assemble<G: RandomNumberGenerator>(
        id: Int,
        style: QuestionStyle,
        target: LetterCard,
        prompt: Word?,
        correct: QuizChoice,
        distractors: [QuizChoice],
        using generator: inout G
    ) -> QuizQuestion {
        // Shuffled once, at generation, so the tiles do not reshuffle
        // underneath a child's finger on every redraw.
        let choices = (distractors + [correct]).shuffled(using: &generator)
        let correctIndex = choices.firstIndex(of: correct) ?? 0
        return QuizQuestion(id: id, style: style, target: target,
                            promptWord: prompt, choices: choices,
                            correctIndex: correctIndex)
    }
}
