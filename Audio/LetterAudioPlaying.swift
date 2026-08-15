import SwiftUI

/// The seam for recorded audio (SPEC §8).
///
/// No audio ships in v1 — a parent reads the sound and the words aloud — but
/// the speaker controls are laid out now so that adding recordings later is
/// one new conforming type plus the audio files, with no view changes and no
/// relayout.
///
/// Recorded clips are strongly preferred over `AVSpeechSynthesizer`, which
/// says "bee" for B rather than the /b/ phoneme — the wrong thing for a
/// phonics app to teach.
protocol LetterAudioPlaying: Sendable {
    /// Drives whether the speaker controls are visible at all.
    var isAvailable: Bool { get }
    func playSound(for card: LetterCard)
    func playWord(_ word: Word, on card: LetterCard)
}

/// v1's implementation: there is no audio.
struct SilentAudioPlayer: LetterAudioPlaying {
    var isAvailable: Bool { false }
    func playSound(for card: LetterCard) {}
    func playWord(_ word: Word, on card: LetterCard) {}
}

extension EnvironmentValues {
    @Entry var letterAudio: any LetterAudioPlaying = SilentAudioPlayer()
}
