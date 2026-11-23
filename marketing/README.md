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

**iPad — 13" slot, 2064 × 2752.** Captured on iPad Pro 13-inch (M5), iOS 26.2,
same five screens in the same order:

1. `ipad-1-card-front.png`
2. `ipad-2-card-back.png`
3. `ipad-3-quiz-start.png`
4. `ipad-4-quiz-picture-to-letter.png`
5. `ipad-5-quiz-letter-to-picture.png`

## A rendering trap, recorded so nobody chases it twice

Downscaled previews of these iPad captures appear to show the tab bar and the
control bar **a second time** near the bottom of the screen. There is no such
duplicate. It is an artifact of the preview scaling, not of the app.

Established by decoding the PNGs: on a 2752px-tall capture, rows 2150–2620
(the band where the phantom chrome appears) are **pure background**, maximum
per-row deviation 0. Independently, walking the app's UIKit view tree and its
CALayer tree at runtime on iPad finds nothing below the card except the
position indicator. Do not trust a scaled-down look at an iPad screenshot;
decode the file.

Note also that SwiftUI batches drawing into large layers, so filtering a layer
walk by frame position will not localize SwiftUI-drawn content — a full-screen
drawing layer has `minY == 0` however far down its contents are painted.
