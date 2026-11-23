# Marketing assets

## screenshots/

App Store Connect screenshots, captured 2026-11-23 from the quiz build
(`CURRENT_PROJECT_VERSION` 3 + the quiz).

**iPhone — 6.9" slot, 1320 × 2868.** Captured on iPhone 17 Pro Max, iOS 26.2,
light appearance, status bar overridden to 9:41 / full bars / charged. Five
shots, in upload order:

1. `iphone-1-card-front.png` — the deck, card front
2. `iphone-2-card-back.png` — the back: case pair and four words
3. `iphone-3-quiz-start.png` — the quiz's three modes
4. `iphone-4-quiz-picture-to-letter.png` — picture prompt, letter tiles
5. `iphone-5-quiz-letter-to-picture.png` — letter prompt, picture tiles

**iPad — 13" slot, 2064 × 2752. Not captured.** The app currently draws its
chrome twice on iPad: the tab bar and the control bar appear again as a short
strip at the bottom of the screen, as though a second copy of the window were
laid out in ~340pt and parked there. Reproduced on iPad Pro 13-inch under both
iOS 18.4 and iOS 26.2, on both tabs, surviving relaunch and rotation; the
duplicate is inert (taps do not reach it). Not reproducible on any iPhone.
The source has exactly one `ControlBar`, so this is not a duplicated view in
`CardsView`. Fix it before taking iPad shots — a reviewer opening the app on an
iPad would see the same thing.
