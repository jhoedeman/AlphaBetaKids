import Foundation

/// What the child has got right and wrong, per letter and per kind of
/// question.
///
/// Nothing reads this for scheduling yet. It exists now because the adaptive
/// ordering the owner wants next needs history, and history cannot be
/// backfilled — every session played before the ledger exists is lost to it.
///
/// **Counters plus recency, not an event log.** Proper spaced repetition needs
/// to know not only how often a letter is missed but how long since it was
/// seen, or the child is drilled forever on his worst letters and never
/// revisits the ones he has quietly forgotten. What that trades away is a
/// months-long trend line, which nobody has asked for — see the quiz design
/// §6.5.
///
/// **Keyed by letter *and* style.** Recognising B and recalling B are
/// different skills; a style-blind record would average them and drill the
/// wrong one.
struct QuizLedger: Codable, Hashable {
    /// How many recent outcomes are kept per entry. Long enough to show a
    /// trend within a sitting, short enough that the blob cannot grow.
    static let recentWindow = 8

    struct Entry: Codable, Hashable {
        var asked = 0
        var firstTryCorrect = 0
        var lastSeenAt: Date?
        /// Most recent first, capped at `recentWindow`.
        var recent: [Bool] = []

        var firstTryMissed: Int { asked - firstTryCorrect }
    }

    private(set) var entries: [String: Entry] = [:]

    // MARK: - Reading

    /// Composite key, because JSON object keys have to be strings. The
    /// separator is one a letter can never contain.
    static func key(letter: String, style: QuestionStyle) -> String {
        "\(letter)|\(style.rawValue)"
    }

    func entry(letter: String, style: QuestionStyle) -> Entry? {
        entries[Self.key(letter: letter, style: style)]
    }

    var isEmpty: Bool { entries.isEmpty }

    // MARK: - Writing

    /// Takes the outcome rather than a `Bool` so that **ignoring a skip is a
    /// property of the ledger**, not a rule the calling view has to remember.
    ///
    /// A skip cannot tell "doesn't know it" from "has wandered off", and
    /// guessing either way would poison the very data the scheduler depends
    /// on. So it is not recorded at all.
    mutating func record(
        _ outcome: QuizRound.Outcome,
        for question: QuizQuestion,
        at date: Date = .now
    ) {
        let correct: Bool
        switch outcome {
        case .correctFirstTry: correct = true
        case .missedFirstTry: correct = false
        case .skipped: return
        }

        let key = Self.key(letter: question.target.lower, style: question.style)
        var entry = entries[key] ?? Entry()
        entry.asked += 1
        if correct { entry.firstTryCorrect += 1 }
        // Truncated to the second, because that is the resolution ISO-8601
        // storage keeps. Without this the in-memory ledger and the one read
        // back from `@AppStorage` differ by a fraction of a second and are
        // never equal — scheduling cares about days, so nothing is lost.
        entry.lastSeenAt = Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down))
        entry.recent.insert(correct, at: 0)
        if entry.recent.count > Self.recentWindow {
            entry.recent.removeLast(entry.recent.count - Self.recentWindow)
        }
        entries[key] = entry
    }

    mutating func clear() { entries = [:] }

    // MARK: - @AppStorage

    // Dates as ISO-8601 so the stored blob stays readable and stable across
    // anything that might change about epoch handling.
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// An unreadable blob yields an empty ledger rather than a crash. Losing
    /// the history is bad; refusing to launch over it is worse.
    init(json: String) {
        guard let data = json.data(using: .utf8),
              let decoded = try? Self.decoder.decode(QuizLedger.self, from: data)
        else {
            self.init()
            return
        }
        self = decoded
    }

    init() {}

    var json: String {
        guard let data = try? Self.encoder.encode(self),
              let string = String(data: data, encoding: .utf8)
        else { return "{}" }
        return string
    }
}
