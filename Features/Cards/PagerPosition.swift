import Foundation

/// The pager's index arithmetic, pulled out of the view so the paging rules
/// are testable on their own (SPEC §11).
///
/// Every transition clamps rather than wrapping. The deck having a hard end
/// is deliberate — past the last card you get the restart button, not a
/// silent loop back to A (SPEC §5.2, §5.4).
struct PagerPosition: Equatable {
    let count: Int
    private(set) var index: Int

    init(count: Int, index: Int = 0) {
        self.count = max(0, count)
        self.index = Self.clamp(index, count: self.count)
    }

    private static func clamp(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(0, index), count - 1)
    }

    var isEmpty: Bool { count == 0 }

    /// The leading chevron is inert here.
    var isAtStart: Bool { index <= 0 }

    /// The trailing chevron becomes the restart button here.
    var isAtEnd: Bool { isEmpty || index >= count - 1 }

    func advanced() -> PagerPosition {
        PagerPosition(count: count, index: index + 1)
    }

    func retreated() -> PagerPosition {
        PagerPosition(count: count, index: index - 1)
    }

    func restarted() -> PagerPosition {
        PagerPosition(count: count, index: 0)
    }

    func moved(to index: Int) -> PagerPosition {
        PagerPosition(count: count, index: index)
    }

    /// Position of `id` within `cards`, falling back to the first card when
    /// the id is no longer in the deck — which is what happens when the
    /// blends filter removes the card currently in focus (SPEC §5.6).
    static func locating(id: Int, in cards: [LetterCard]) -> PagerPosition {
        PagerPosition(count: cards.count, index: cards.firstIndex { $0.id == id } ?? 0)
    }
}
