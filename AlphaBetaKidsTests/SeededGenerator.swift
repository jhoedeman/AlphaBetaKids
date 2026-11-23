import Foundation

/// Deterministic xorshift64 so shuffle behaviour can be asserted rather than
/// hoped at. Seeded through a splitmix-style step so seed 0 doesn't produce
/// the degenerate all-zero state.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

