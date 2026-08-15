# AlphaBetaKids — Build Specification v1.0

A deliberately small SwiftUI flashcard app that teaches a 3–4 year old to recognize
English letters and their sounds. Derived from the sibling app `../AlphaBeta`, but
**not** a fork: everything that made AlphaBeta general — ten languages, a manifest and
registry, a palette system, SwiftData + CloudKit, a quiz engine — is removed. What's
left is one alphabet, one color, one interaction.

---

## 1. Scope

**In scope for v1:**

- 34 flashcards: 26 letters plus 8 blends (`sh ch th wh ck ng oo ee`).
- Tap a card to flip it. Front shows one case of the letter; back shows the other case
  and four example words, each with an emoji picture.
- A strictly one-card-per-gesture pager, plus large arrow buttons.
- Three controls: which case leads, whether blends are in the deck, and shuffle.
- A Quiz tab that is present but inert.

**Explicitly out of scope** (each was in AlphaBeta and is deliberately cut):

| Cut | Why |
|---|---|
| Language switcher | One language. No manifest, no registry, no `AlphabetProviding`. |
| Color/palette switcher, custom palette builder | Hellenic Blue only, hardcoded. |
| Long-form explanations, pronunciation systems, detail sheet | The card back *is* the detail view. |
| SwiftData, CloudKit, entitlements | Four booleans of state. `@AppStorage` covers it. |
| Quiz engine, streaks, progress tracking | Tab exists; implementation deferred. |
| Wrap-around carousel | Replaced by an explicit restart button (§5.4). |
| Landscape | Portrait only (§2). |

Nothing from AlphaBeta is imported as code except `Support/Haptics.swift`. The Hellenic
Blue hex values are retyped as constants rather than loaded from a `Palettes.json`.

---

## 2. Platform & stack

- **Folder:** `~/Documents/Programs/AlphaBetaKids`, own git repo.
- **Project generation:** xcodegen from `project.yml`.
  **Run it via the real binary path, `~/bin/xcodegen_dist/bin/xcodegen`** — the
  `~/bin/xcodegen` symlink has previously caused resources to be silently dropped from
  the generated project.
- **Bundle ID:** `com.JohnHoedeman.AlphaBetaKids`. **Deployment target:** iOS 18.0.
- **Devices:** iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`), **portrait only**.
  iPhone: `Portrait`. iPad: `Portrait` + `PortraitUpsideDown`.
- **UI:** 100% SwiftUI. UIKit only for haptics and the font-availability check.
- **Dependencies:** none.
- **Persistence:** `@AppStorage` only. No `ModelContainer`, no iCloud capability, no
  background modes.

### Stored state (the complete list)

| Key | Type | Default | Notes |
|---|---|---|---|
| `leadingCase` | `String` | `"upper"` | `upper` \| `lower` — which case is on the front |
| `blendsEnabled` | `Bool` | `false` | Blends **off** by default, per requirement |
| `isShuffled` | `Bool` | `false` | Shuffle *mode*; the order itself is not persisted |
| `lastCardID` | `Int` | `1` | Restored on launch **only when not shuffled** (§5.5) |

---

## 3. Content

### 3.1 File

One bundled `Alphabet.json`. No manifest, no per-language files, no registry.

```json
{
  "version": 1,
  "cards": [
    {
      "id": 2,
      "kind": "letter",
      "upper": "B",
      "lower": "b",
      "soundHint": "b as in ball",
      "wordRule": "startsWith",
      "words": [
        { "text": "bear",   "emoji": "🐻" },
        { "text": "ball",   "emoji": "⚽️" },
        { "text": "bottle", "emoji": "🍼" },
        { "text": "baby",   "emoji": "👶" }
      ]
    }
  ]
}
```

### 3.2 Field rules

| Field | Type | Rule |
|---|---|---|
| `id` | `Int`, required | Stable. 1–26 letters in alphabetical order, 27–34 blends. |
| `kind` | `String`, required | `letter` \| `blend`. Drives only the blends filter. |
| `upper` | `String?` | **Optional.** `ck`, `ng`, `oo`, `ee` have no capital form and omit it. |
| `lower` | `String`, required | Always present. |
| `soundHint` | `String`, required | Small parent-facing line, e.g. `"b as in ball"`. |
| `wordRule` | `String`, required | `startsWith` \| `contains`. Drives the back's label **and** the content test in §11. |
| `words` | array, required | **Exactly 4.** Each `{ text, emoji }`, both non-empty. |
| `soundFile` | `String?` | Reserved for §8. Absent in v1. |
| `words[].audioFile` | `String?` | Reserved for §8. Absent in v1. |

Decoding is strict on required fields and tolerant of unknown ones, so the audio fields
can be added later without a version bump.

### 3.3 The `wordRule` distinction

Nothing in English starts with `oo`, `ee`, `ck`, or `ng`, and no word a small child
knows starts with `x`. Those five cards use `contains`; the other 29 use `startsWith`.
The rule is data, not a special case in view code, and it changes exactly one thing in
the UI — the back's label:

- `startsWith` → **"Words that start with this sound"**
- `contains` → **"Words with this sound"**

### 3.4 Cards with no capital form

`ck`, `ng`, `oo`, `ee` omit `upper`. Consequences, all driven off `upper == nil`:

- The card always shows `lower` on its front, regardless of the `leadingCase` setting.
- Its back shows no case row at all — just the label and the four words.

A fake "Oo" would teach a form the child will never meet in print, so it is not shown.

### 3.5 Content constraints (enforced by test, see §11)

1. Every card has exactly 4 words; every `text` and `emoji` is non-empty.
2. Every word actually satisfies its own `wordRule` — `startsWith` words really begin
   with `lower`, `contains` words really contain it. Case-insensitive.
3. **No letter card's word may begin with a blend that is itself a card.** The `s` card
   must not use "ship", the `c` card must not use "cheese", the `t` card must not use
   "three", the `w` card must not use "whale". Violating this teaches the wrong sound
   for the letter, and it is the single easiest content mistake to make.
4. `id` values are unique; ids 1–26 are `letter`, 27–34 are `blend`.

The full v1.0 draft content is in **Appendix A** and satisfies all four.

---

## 4. Architecture

```
AlphaBetaKids/
├── App/
│   ├── AlphaBetaKidsApp.swift    # @main
│   ├── RootView.swift            # TabView: Cards | Quiz (inert)
│   ├── Info.plist
│   └── Assets.xcassets
├── Content/
│   ├── LetterCard.swift          # Codable model + derived helpers
│   ├── CardDeck.swift            # loads JSON, filters, shuffles
│   └── Resources/
│       ├── Alphabet.json
│       └── Andika-Regular.ttf, Andika-Bold.ttf
├── Features/
│   ├── Cards/
│   │   ├── CardsView.swift       # screen: control bar + pager
│   │   ├── CardPagerView.swift   # TabView(.page) + arrows + restart
│   │   ├── FlipCardView.swift    # flip container, owns isFlipped
│   │   ├── CardFrontView.swift
│   │   ├── CardBackView.swift
│   │   ├── ControlBar.swift      # case toggle, blends pill, shuffle
│   │   └── RestartIndicatorView.swift
│   └── Quiz/
│       └── QuizPlaceholderView.swift
├── Audio/
│   ├── LetterAudioPlaying.swift
│   └── SilentAudioPlayer.swift
├── Theme/
│   └── Theme.swift
└── Support/
    └── Haptics.swift
```

`CardDeck` is a plain value type, not an observable store:

```swift
struct CardDeck {
    let allCards: [LetterCard]                  // decoded once from the bundle
    static func load() throws -> CardDeck
    func visibleCards(blendsEnabled: Bool) -> [LetterCard]
    func ordered(blendsEnabled: Bool, shuffled: Bool,
                 using generator: inout some RandomNumberGenerator) -> [LetterCard]
}
```

Taking the generator as a parameter is what makes shuffling testable (§11).

Every file stays under roughly 120 lines. If one grows past that it is doing too much
and should be split.

---

## 5. Cards screen

### 5.1 Layout, top to bottom

1. **Control bar** (§5.6) — case toggle, blends pill, shuffle toggle.
2. **The pager** — card centred, gutters either side holding the arrow buttons.
3. **Position indicator** — small, subdued, e.g. `4 / 26`. No page dots; 34 dots is
   noise.

### 5.2 The pager — one card per gesture

```swift
TabView(selection: $currentID) { … }
    .tabViewStyle(.page(indexDisplayMode: .never))
```

Page style is chosen precisely because **one page per gesture is structural**. Gesture
velocity is irrelevant: a wild, uncoordinated fling from a small hand advances exactly
one letter and stops there. This is the core requirement, and it is the reason this is
not AlphaBeta's `ScrollView` + `.scrollTargetBehavior(.viewAligned)`, where a hard fling
can carry across several cards.

- Card width ≈ 76% of the frame, height from a 360:260 ratio, centred. The remaining
  width becomes symmetric gutters. Neighbour cards are a full page away and therefore
  not visible — intentional, so there is nothing to grab by accident.
- A light impact haptic fires when the page settles on a new card, but not on first
  appearance.
- **Hard stops at both ends. No wrap-around.** The deck having an end is a feature.

### 5.3 Arrow buttons

A 56pt chevron in each gutter, vertically centred on the card, in the accent color. A
tap moves one card with a spring animation. At the first card the leading chevron is
dimmed and inert.

These exist because a 3–4 year old's tap is far more reliable than their swipe.

### 5.4 Restart

At the **last** card, the trailing chevron cross-fades in place into an
`arrow.counterclockwise` button — same slot, same size, so the child's hand already
knows where it is, and there is never a dead dimmed control there.

Tapping it:

1. Sets selection to the first card **with page animation suppressed** (a
   `Transaction` with `disablesAnimations = true`). Animating across 34 pages would be
   unpleasant to watch.
2. Fires `Haptics.selection()`.
3. Shows `RestartIndicatorView` — a capsule reading **"Back to the beginning!"** —
   which auto-dismisses after 1.5s.

The dismissal timer is a `Task` held in `@State` and **cancelled before each new one is
started**, so rapid repeat taps never leave a stale dismissal in flight. (This is the
bug AlphaBeta's `WrapIndicatorView` had to fix; inherit the fix, not the bug.)

The leading chevron at the first card does *not* jump to the end. A child at card 1
tapping "back" has made a mistake, not a choice.

### 5.5 Shuffle

- Toggling shuffle **on** reorders the visible deck. Toggling it again **reshuffles**
  rather than doing nothing.
- Either direction resets focus to the first card of the new order, un-animated, with a
  light haptic. One predictable rule, rather than "sometimes it keeps your place."
- Only the *mode* persists, not the order. Launching in shuffle mode produces a fresh
  shuffle — which is the desired behaviour anyway — and so **`lastCardID` restore is
  skipped whenever `isShuffled` is true.**
- Shuffling mixes letters and blends together when blends are enabled.

### 5.6 Control bar

| Control | Behaviour |
|---|---|
| **Case toggle** | Segmented, `A` \| `a`. Picks which case leads on every card front. Default `A`. Cards with no `upper` ignore it (§3.4). |
| **Blends pill** | On/off. **Off by default.** Adds the 8 blend cards to the deck. |
| **Shuffle toggle** | Per §5.5. |

Case is a two-way toggle rather than AlphaBeta's independent multi-select pills because
"both on" and "capitals only" would be indistinguishable to the child, and "both off"
would need an empty state for no good reason.

Changing the blends pill keeps focus on the current card when it survives the change,
and otherwise resets to the first card.

**Accepted risk:** three controls sit on screen where a child can poke them. All are
harmless and instantly reversible, and none can leave the child stuck. If this proves
to be a nuisance in use, moving the bar behind a parent gate is a small later change.

---

## 6. Card faces

### 6.1 Front

The glyph, as large as will fit, in the accent color, in the teaching font (§7.2).
`minimumScaleFactor` down to 0.3 with `lineLimit(1)` so two-character blends still fit.

Nothing else, except a small flip affordance in a corner. No English name, no category
label, no letter name. A 3-year-old needs the shape and nothing competing with it.

Which case is shown: `leadingCase` when the card has both forms, otherwise `lower`.

### 6.2 Back

1. **Case row** — the *opposite* case, large, in the accent color, with the front's case
   small beside it so the pairing is visible. Omitted entirely when `upper == nil`.
2. **Label** — per §3.3.
3. **Word grid** — 2×2. Emoji large, word beneath in the teaching font, lowercase.
4. **Speaker buttons** — laid out but hidden while no audio provider is available (§8).

### 6.3 The flip

- Tapping anywhere on the card flips it. `rotation3DEffect` about the Y axis, faces
  swapped at the 90° crossing, ~0.45s spring, light impact haptic.
- **Paging to a different card resets it to the front.** A child must never arrive on a
  back they did not turn themselves.
- Reduce Motion replaces the rotation with a cross-fade.

---

## 7. Theme

### 7.1 Color

`Theme.swift`, static constants only. Values lifted verbatim from AlphaBeta's
`greek-flag` palette, "Hellenic Blue":

| Token | Light | Dark |
|---|---|---|
| `background` | `#E7E9ED` | `#0D1625` |
| `surface` | `#FFFFFF` | `#152040` |
| `accent` | `#1055E8` | `#3D80FF` |
| `textPrimary` | `#1A2845` | `#EEF2FD` |
| `textSecondary` | `#3D5A85` | `#8FA4C8` |

Light/dark resolve from the system color scheme. There is no appearance setting, no
palette picker, and no builder — dark mode support is free because the palette already
carries the values.

### 7.2 The teaching font

Children are taught single-story ⟨ɑ⟩ and ⟨g⟩. SF, and AlphaBeta's Athelas, both draw
double-story forms — so an app that teaches letter shapes with them teaches a shape the
child will not meet in a school book. **Andika** (SIL, OFL 1.1) is designed for exactly
this: single-story `a` and `g`, unambiguous `I`/`l`/`1`.

Bundle `Andika-Regular.ttf` and `Andika-Bold.ttf` in `Content/Resources/`, declared in
`Info.plist` under `UIAppFonts` **by filename**. Ship `OFL.txt` alongside them — the
Open Font License requires the license travel with the font.

Version in use: **Andika 7.000** (SIL).

#### PostScript names — the filenames lie

`UIAppFonts` takes filenames, but `UIFont(name:)` and `Font.custom` take *PostScript*
names, and for Andika those do not match:

| File | PostScript name |
|---|---|
| `Andika-Regular.ttf` | **`Andika`** — not `Andika-Regular` |
| `Andika-Bold.ttf` | `Andika-Bold` |

Verified by reading the TTF `name` tables (nameID 6). Using `"Andika-Regular"` returns
nil and falls through to the fallback — a build that looks fine while teaching the
wrong letterforms, which is the exact failure this font was chosen to prevent.

`Theme` therefore exposes the font through a checked accessor rather than
`Font.custom`, which falls back silently:

```swift
private static func named(_ postScriptName: String, _ size: CGFloat,
                          fallbackWeight: Font.Weight) -> Font {
    UIFont(name: postScriptName, size: size) != nil
        ? .custom(postScriptName, size: size)
        : .system(size: size, weight: fallbackWeight, design: .rounded)
}

/// The hero glyph and the case row.
static func letterFont(size: CGFloat) -> Font {
    named("Andika-Bold", size, fallbackWeight: .bold)
}

/// Example words and labels.
static func wordFont(size: CGFloat) -> Font {
    named("Andika", size, fallbackWeight: .regular)
}
```

So the app builds and runs before the font files arrive, falling back to SF Rounded, and
picks up the correct letterforms the moment they are added.

**Test (`ThemeTests`):** assert both PostScript names resolve to a non-nil `UIFont` once
the resources are bundled. If a future Andika release renames a face, that test fails
loudly instead of the app quietly degrading.

---

## 8. Audio seam

No audio ships in v1. A parent reads the sound and the four words aloud. The seam exists
so recordings drop in later as data plus one new type, with no view changes:

```swift
protocol LetterAudioPlaying {
    var isAvailable: Bool { get }
    func playSound(for card: LetterCard)
    func playWord(_ word: Word, on card: LetterCard)
}

struct SilentAudioPlayer: LetterAudioPlaying {
    var isAvailable: Bool { false }
    func playSound(for card: LetterCard) {}
    func playWord(_ word: Word, on card: LetterCard) {}
}
```

Injected via the environment. Speaker buttons are laid out in `CardBackView` but hidden
while `isAvailable` is false, so adding audio does not reflow the layout.

Recorded clips are strongly preferred over `AVSpeechSynthesizer`, which says "bee" for
B rather than the /b/ phoneme — the wrong thing for a phonics app to teach.

---

## 9. Quiz tab

The tab is visible, selectable, and lands on a themed "Quiz — Coming soon" screen
(`QuizPlaceholderView`), which is also where the real implementation will go.

**Revised during M2.** This section originally specified a *disabled* tab, implemented
by intercepting the `TabView` selection binding and refusing writes that select Quiz.
**That does not work, and was verified not to work on the simulator.** Refusing the
write is a no-op: SwiftUI sees no state change, so it never invalidates the view and
never reconciles the underlying `UITabBarController` back to Cards. The tab bar keeps
whatever the user tapped, and the Quiz screen appears.

SwiftUI genuinely has no disabled-tab API — not on the classic `.tabItem` modifier, not
on the iOS 18 `Tab` type, and `.disabled` on a tab's content does not prevent selection.
The only ways to make it stick are:

- select Quiz and bounce back on the next runloop, which flashes the Quiz screen; or
- overlay hit-testing hacks on the tab bar, which are fragile and break VoiceOver.

Neither is worth it to withhold a screen that is friendlier than a dead control, so the
"coming soon" screen ships instead. If a truly inert tab is wanted later, hiding the tab
entirely until the quiz exists is the clean option — not faking `disabled`.

---

## 10. Accessibility

- Dynamic Type throughout. The hero glyph scales but is capped so it cannot overflow.
- VoiceOver: the card is one element — "Letter B, capital. Tap to turn over." The back
  reads the opposite case, the label, and the four words.
- Reduce Motion: cross-fade instead of the 3D flip; no spring on page changes.
- Arrow buttons carry explicit labels ("Next letter", "Previous letter", "Back to the
  beginning") rather than relying on the chevron glyph.
- Contrast: `#1055E8` on `#FFFFFF` is ≈6.0:1. `#3D80FF` on `#152040` is ≈4.4:1 — clear
  for the large text it is used for, but **just under** the 4.5:1 normal-text bar, so
  the accent must not be used for small body text in dark mode. Accent is for the hero
  glyph, the case row, and controls; body text uses `textPrimary`/`textSecondary`.

---

## 11. Testing

The valuable tests here are content tests. The content is the product, and it is
checked in code rather than by eye:

**`ContentTests`**
- Decodes `Alphabet.json`; asserts 34 cards, 26 `letter` + 8 `blend`, unique ids.
- Every card has exactly 4 words; every `text` and `emoji` non-empty.
- **Every word satisfies its own `wordRule`** (§3.5 rule 2).
- **No letter card's word begins with a blend that is also a card** (§3.5 rule 3).
- Exactly `ck`, `ng`, `oo`, `ee` have `upper == nil`.

**`CardDeckTests`**
- `visibleCards` returns 26 with blends off, 34 with blends on.
- `ordered(shuffled: true, using:)` with a seeded generator returns a permutation of the
  same members — same count, same id set, nothing dropped or duplicated.
- `ordered(shuffled: false, …)` is alphabetical by id.

**`PagerIndexTests`**
- Index clamping at both ends; the last index reports `isAtEnd` so the restart button
  appears; the first reports `isAtStart` so the leading chevron is inert.

---

## 12. Build order

| Milestone | Contents |
|---|---|
| **M1** | `project.yml`, `Alphabet.json` (Appendix A), `LetterCard`, `CardDeck`, all of §11's content and deck tests. Content correct before any UI exists. |
| **M2** | App shell, `RootView` with both tabs and the Quiz interception, `Theme`, font accessor with fallback. |
| **M3** | `CardPagerView` — page style, gutters, arrows, restart button and indicator, position indicator. |
| **M4** | `FlipCardView`, `CardFrontView`, `CardBackView`, word grid, flip-reset-on-page. |
| **M5** | `ControlBar` — case toggle, blends pill, shuffle — and `@AppStorage` wiring. |
| **M6** | Accessibility pass, Reduce Motion, Dynamic Type, iPad portrait check, app icon. |

---

## 13. Open items for John

1. ~~Download Andika.~~ **Done** — Andika 7.000 is in `~/Downloads/Andika-7.000/`.
   Copy `Andika-Regular.ttf`, `Andika-Bold.ttf`, and `OFL.txt` into
   `Content/Resources/`. The app builds and runs without them via the SF Rounded
   fallback (§7.2), so this is not a blocker for M1–M2.
2. **Review Appendix A** — the word and emoji choices, with attention to the flagged
   rows.
3. **App icon.**
4. Later: record audio clips (§8) — 34 letter/blend sounds and 136 words.

---

## Appendix A — Content draft v1.0

Review target. `contains` cards are marked; everything else is `startsWith`.

### Letters

| # | Card | Words |
|---|---|---|
| 1 | A a | apple 🍎 · ant 🐜 · alligator 🐊 · avocado 🥑 |
| 2 | B b | bear 🐻 · ball ⚽️ · bottle 🍼 · baby 👶 |
| 3 | C c | cat 🐱 · cow 🐄 · car 🚗 · cake 🍰 |
| 4 | D d | dog 🐕 · dinosaur 🦕 · door 🚪 · drum 🥁 |
| 5 | E e | elephant 🐘 · egg 🥚 · envelope ✉️ · engine 🚂 |
| 6 | F f | fish 🐟 · frog 🐸 · fire 🔥 · flower 🌸 |
| 7 | G g | goat 🐐 · guitar 🎸 · grapes 🍇 · gift 🎁 |
| 8 | H h | hat 👒 · horse 🐴 · house 🏠 · heart ❤️ |
| 9 | I i | insect 🐛 · iguana 🦎 · ink 🖊️ · igloo 🛖 ⚠️ |
| 10 | J j | juice 🧃 · jet ✈️ · jacket 🧥 · jellyfish 🪼 |
| 11 | K k | key 🔑 · kite 🪁 · kangaroo 🦘 · koala 🐨 |
| 12 | L l | lion 🦁 · leaf 🍃 · lamp 💡 · ladder 🪜 |
| 13 | M m | monkey 🐒 · milk 🥛 · mouse 🐭 · mountain 🏔️ |
| 14 | N n | nose 👃 · nest 🪺 · nut 🥜 · needle 🪡 |
| 15 | O o | octopus 🐙 · orange 🍊 · otter 🦦 · olive 🫒 |
| 16 | P p | pig 🐷 · pizza 🍕 · penguin 🐧 · pencil ✏️ |
| 17 | Q q | queen 👸 · question ❓ · quiet 🤫 · quack 🦆 |
| 18 | R r | rabbit 🐰 · rainbow 🌈 · robot 🤖 · rocket 🚀 |
| 19 | S s | sun ☀️ · snake 🐍 · star ⭐️ · spider 🕷️ |
| 20 | T t | tiger 🐯 · truck 🚚 · train 🚂 · teeth 🦷 |
| 21 | U u | umbrella ☂️ · unicorn 🦄 · up ⬆️ · underwear 🩲 ⚠️ |
| 22 | V v | violin 🎻 · van 🚐 · volcano 🌋 · vegetables 🥕 |
| 23 | W w | water 💧 · watch ⌚️ · wolf 🐺 · worm 🪱 |
| 24 | X x | **(contains)** box 📦 · fox 🦊 · six 6️⃣ · ox 🐂 |
| 25 | Y y | yo-yo 🪀 · yellow 💛 · yarn 🧶 · yawn 🥱 |
| 26 | Z z | zebra 🦓 · zero 0️⃣ · zip 🤐 · zoo 🐘 ⚠️ |

### Blends

| # | Card | Words |
|---|---|---|
| 27 | Sh sh | sheep 🐑 · ship 🚢 · shoe 👟 · shark 🦈 |
| 28 | Ch ch | cheese 🧀 · chair 🪑 · chicken 🐔 · cherry 🍒 |
| 29 | Th th | thumb 👍 · three 3️⃣ · thunder ⛈️ · thread 🧵 |
| 30 | Wh wh | whale 🐳 · wheel 🎡 · wheat 🌾 · whisper 🤫 |
| 31 | ck | **(contains)** duck 🦆 · sock 🧦 · rock 🪨 · clock 🕐 |
| 32 | ng | **(contains)** ring 💍 · king 👑 · wing 🪽 · sing 🎤 |
| 33 | oo | **(contains)** moon 🌙 · spoon 🥄 · boot 👢 · moose 🫎 |
| 34 | ee | **(contains)** tree 🌳 · feet 🦶 · bee 🐝 · sheep 🐑 |

### Content notes

- **Blend collisions avoided.** The `c`, `s`, `t`, `w` cards deliberately use no word
  beginning with `ch`, `sh`, `th`, `wh` — hence "cow" not "chair", "star" not "ship",
  "truck" not "three", "wolf" not "whale". Enforced by §11.
- **Cross-card duplicates removed** so each word teaches one thing, except one
  deliberate case: **sheep** appears on both `sh` and `ee`, where `sh` + `ee` = sheep is
  a genuinely useful thing for a child to notice.
- **`oo` is one sound here, not two.** English spells both /uː/ (moon, spoon) and /ʊ/
  (book, foot) as `oo`. All four words use the long /uː/ so the card teaches one sound.
  The short-`oo` set is omitted rather than mixed in. Worth revisiting if you'd rather
  have a second card.
- **`th` is voiceless only** (thumb, three, thunder, thread), not the voiced /ð/ of
  "the" and "this" — same one-card-one-sound reasoning.
- **`u` mixes /ʌ/ and /juː/** (umbrella, up, underwear vs. unicorn). Both are taught at
  this age and unicorn is too good to drop, but it is the one letter card that is not
  phonetically clean.
- ⚠️ **Flagged for your review:** *igloo* 🛖 (hut emoji standing in), *underwear* 🩲
  (the only picturable fourth option; also reliably funny to a 3-year-old), *zoo* 🐘
  (elephant standing in).
