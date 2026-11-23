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

    /// The most a card's picture count can count for when choosing targets.
    /// Above this, more pictures stop buying more turns — the point is to
    /// thin out the letters that repeat themselves, not to crown the letters
    /// with the fullest pools.
    static let maxWeight = 4

    /// How often this card should come up, relative to the others.
    ///
    /// A card with one usable picture shows that same picture every time it
    /// is asked about — `z` is a zebra, always, in both styles. Weighting by
    /// how many clear pictures a card has makes that happen a quarter as
    /// often as a card with four or more, without ever making `z` unaskable.
    /// Silencing it would be worse: a letter the quiz never covers is not an
    /// improvement on a letter it covers repetitively.
    ///
    /// **This is the crudest possible version of the scheduler** (quiz design
    /// §6.5) — it looks at the content and not at the child. When the ledger
    /// is read, this is the function that grows a second half.
    static func weight(for card: LetterCard) -> Int {
        min(card.words.filter(\.isPictureClear).count, maxWeight)
    }

    static func round<G: RandomNumberGenerator>(
        deck: CardDeck,
        mode: QuizMode,
        using generator: inout G
    ) -> QuizRound {
        // Chosen one at a time, without replacement, so no letter repeats
        // inside a round while the weighting still applies to each pick.
        var remaining = deck.quizCards
        var questions: [QuizQuestion] = []

        while questions.count < questionsPerRound, !remaining.isEmpty {
            let style = mode.resolve(using: &generator)
            guard let target = pickTarget(from: remaining, using: &generator) else { break }
            remaining.removeAll { $0.id == target.id }

            // The id is the question's position in the round, so it is taken
            // from what has been built rather than from how many cards have
            // been tried — a card that cannot pose this kind of question
            // leaves no gap in the numbering.
            if let question = question(id: questions.count, target: target,
                                       style: style, deck: deck, using: &generator) {
                questions.append(question)
            }
        }
        return QuizRound(questions: questions)
    }

    private static func pickTarget<G: RandomNumberGenerator>(
        from candidates: [LetterCard],
        using generator: inout G
    ) -> LetterCard? {
        let weights = candidates.map(weight(for:))
        let total = weights.reduce(0, +)
        guard total > 0 else { return candidates.randomElement(using: &generator) }

        var roll = Int.random(in: 0..<total, using: &generator)
        for (card, weight) in zip(candidates, weights) {
            roll -= weight
            if roll < 0 { return card }
        }
        return candidates.last
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
