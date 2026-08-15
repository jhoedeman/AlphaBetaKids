# AlphaBetaKids

A deliberately small SwiftUI flashcard app that teaches a 3–4 year old to recognize
English letters and their sounds. 26 letters plus 8 blends, one card per letter, tap to
turn it over.

- **SPEC.md** — full build specification. Start here; milestones are in §12, and the
  content draft awaiting review is Appendix A.

Derived from the sibling app `../AlphaBeta` (ten non-Latin alphabets, quiz engine,
theming system) but built fresh — one language, one color, one interaction. §1 of the
spec lists what was cut and why.

## Build

Requires Xcode 16 / iOS 18 and [xcodegen](https://github.com/yonaskolb/XcodeGen). The
`.xcodeproj` is generated, not committed:

```
xcodegen generate && open AlphaBetaKids.xcodeproj
```

## License

The app source is MIT — see [`LICENSE`](LICENSE).

The bundled font is **not** covered by that and carries its own terms, below.

## Fonts

Bundles **Andika** 7.000, © 2004–2025 [SIL Global](https://www.sil.org/), with Reserved
Font Names "Andika" and "SIL". Licensed under the SIL Open Font License 1.1 — full text
in [`Content/Resources/OFL.txt`](Content/Resources/OFL.txt).

Andika is designed for early literacy: single-story `a` and `g` and unambiguous `I`/`l`/`1`,
so the letter shapes a child learns here match the ones they meet in a book. See SPEC §7.2
— including the trap that the faces' PostScript names don't match their filenames.
