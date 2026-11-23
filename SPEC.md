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
  A portrait-only iPad app **must also set `UIRequiresFullScreen`** to opt out of
  multitasking, or App Store Connect fails the upload with ITMS-90474 (it did, on
  the first attempt at 1.0 build 1). `xcodebuild` warns about this at archive time
  — "All interface orientations must be supported unless the app requires full
  screen" — and that warning is load-bearing, not cosmetic. The key is still
  honoured by Apple's validator when building against the iOS 26 SDK; verified with
  `asc xcode validate` on 2026-08-15, not assumed.
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
| `quizMode` | `String` | `"pictureToLetter"` | `pictureToLetter` \| `letterToPicture` \| `mixed` (§9) |
| `quizLedger` | `String` | `"{}"` | The quiz ledger as one JSON blob (§9). Unreadable JSON decodes to an empty ledger rather than crashing |

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

1. Every card has a pool of **4 to 10** words; every `text` and `emoji` is non-empty.
2. Every word actually satisfies its own `wordRule` — `startsWith` words really begin
   with `lower`, `contains` words really contain it. Case-insensitive.
3. **No letter card's word may begin with a blend that is itself a card.** The `s` card
   must not use "ship", the `c` card must not use "cheese", the `t` card must not use
   "three", the `w` card must not use "whale". Violating this teaches the wrong sound
   for the letter, and it is the single easiest content mistake to make.
4. `id` values are unique; ids 1–26 are `letter`, 27–34 are `blend`.

Two further rules bite only at pool scale, where ~260 words compete for pictures:

5. **No emoji is used on two different cards**, so a child never meets the same picture
   standing for two sounds. Three pairs are exempt because both words genuinely denote
   the same thing: 🤫 (q/wh), 🦆 (q/ck), 🐑 (sh/ee).
6. **No word appears on two cards**, exempting "sheep" (sh/ee) for the same reason.

The full content is in **Appendix A**.

### 3.6 Word pools and the display window

Each card carries a pool of up to 10 words and shows **4 at a time**. Four is a layout
constraint, not a preference — it is what fits at the accessibility-1 Dynamic Type cap
(§6.2).

**The window slides by 4 on each arrival at the card, and wraps.** For a pool of 10 the
starts run 0, 4, 8, 2, 6 and then repeat, so the whole pool is seen across five arrivals
rather than the first four being shown forever with a tail nobody reaches. `shownWords`
is pure arithmetic on the card, so this is tested directly (§11).

Three properties are deliberate and each is enforced by a test:

- **Visit 0 always shows the first four.** Every session opens on the set the child is
  consolidating; novelty accumulates within a sitting rather than across days. This is
  why the pool is an *ordered* list and never shuffled, and why the window count is
  in-memory rather than `@AppStorage`.
- **Flipping never changes the words.** The window advances on arrival at a card, not on
  turning one over. A card that rewrites itself when you turn it twice stops being an
  object with a back.
- **Pools of exactly 4 sit still.** x, q, z and u ran out of words a small child knows;
  those cards must not reorder four words into a different arrangement every visit.

Pool sizes fall well short of 10 for 21 of the 34 cards, which is expected and accepted —
English has almost nothing pictorial starting with x, and a word the child does not know
is worse than no word. Adding a picture that no window ever reaches would be worse still,
because it would look done.

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
│       ├── QuizView.swift        # owns the round and the ledger
│       ├── QuizStartView.swift   # mode picker, Start, ledger reset
│       ├── QuizQuestionView.swift
│       ├── QuizFinishView.swift
│       ├── QuizMode.swift        # QuizMode + QuestionStyle
│       ├── QuizQuestion.swift    # QuizChoice + QuizQuestion
│       ├── QuizRound.swift       # ten questions and the outcomes
│       ├── QuizGenerator.swift   # the scheduler seam (§9.5)
│       └── QuizLedger.swift
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

- Shuffle is a plain two-state toggle: **on** gives a random order, **off** returns to
  alphabetical. Every activation produces a *fresh* shuffle rather than restoring the
  previous one, so off-then-on is how you get a different order.

  (This sentence originally read "toggling it again reshuffles rather than doing
  nothing", which was ambiguous — it could be read as the second tap reshuffling instead
  of switching off, leaving no way to get back to alphabetical order. A plain toggle is
  what "shuffle mode" was chosen to mean. If reshuffle-on-repeat is wanted, it needs a
  separate affordance for returning to A–Z.)
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

Reserving that space costs something the first implementation missed: an in-flow speaker
on one end of the case row shifts the two glyphs off the card's centre line, by 18pt as
measured on device — visible, because the label and the emoji grid directly beneath *are*
centred. The row therefore carries a hidden clone of the speaker on its leading edge. Any
future control added to this row needs the same treatment, or it will pull the letters
off-centre again.

Recorded clips are strongly preferred over `AVSpeechSynthesizer`, which says "bee" for
B rather than the /b/ phoneme — the wrong thing for a phonics app to teach.

---

## 9. Quiz tab

Ten multiple-choice questions, four tiles each, **driven by the parent**. The parent
reads every question aloud; the child taps. Nothing on any quiz screen is written for a
three-year-old to read, and the app never assumes he is holding the device alone. The
full reasoning is in `design/2026-11-23-quiz-design.md`; this section records what
shipped.

### 9.1 The two kinds of question

| Style | Prompt | Tiles | What it tests |
|---|---|---|---|
| `pictureToLetter` | a picture | four letters | the parent names it; the child finds the sound's letter |
| `letterToPicture` | a letter | four pictures | the parent names it; the child finds something starting with it |

`QuizMode` adds a third option, **mixed**, which is a *round* setting: each question
still resolves to one of the two styles. Keeping `QuizMode` and `QuestionStyle` as
separate types makes "no question is mixed" structural rather than a comment.

### 9.2 Which content the quiz may use

Narrower than the card deck, for two independent reasons.

**Only the 25 `startsWith` letter cards.** The word pools encode "this card's *sound*
occurs in this word", which is not what a letter quiz needs. 🌙 is filed under `oo`, but
a child says "moon" — offering it as a wrong answer for M would punish a right one.
Inside the 25, every word begins with its own card's letter, so a word borrowed from
another card can never also be correct. Blends, the `contains` cards, and `x` are out.

**Only pictures that can stand alone.** A tile carries no caption, so the child names it
himself: 🥕 filed as "vegetables" is a carrot to him, 🛖 filed as "igloo" is a hut.
Those carry `"ambiguousPicture": true` in `Alphabet.json` and are excluded from the quiz
entirely — not as a tile, and not as a prompt either, since a prompt the parent has to
contradict teaches that pictures cannot be trusted. **59 of 208 flagged; 149 remain.**
Every one of the 25 keeps at least one, which §11 pins.

**Sound classes.** `Alphabet.json` carries a top-level `soundClasses`, currently
`[["c","k","q"]]`. Letters in one group are never offered together, because a child
shown a key who reasons from sound to letter and taps C is doing exactly what the cards
taught him. The rule applies between *distractors* too, not just against the target.

### 9.3 A round

Ten questions, no letter twice. The child's **first tap** is what counts: a wrong tile
dims but stays live, so he always reaches the answer eventually and "answered correctly"
would be worthless. A correct tap turns the tile `success` and the round advances after
a short hold.

Three outcomes are kept apart, and never conflated: **right first try**, **missed first
try**, and **skipped**. A skip cannot distinguish "doesn't know it" from "has wandered
off", so it is scored nowhere and recorded nowhere. **End** stops a round early; the
questions never reached are counted as such, not as misses.

### 9.4 Screens

- `QuizStartView` — the three modes with a line of explanation each, Start, and the
  ledger reset (confirmed, placed last, shown only when there is something to clear).
- `QuizQuestionView` — prompt, the parent's instruction line, a 2×2 grid, ten dots.
- `QuizFinishView` — first-tap score out of what was *answered*, the letters worth
  another look, go again or leave. No stars, no streak: the child cannot read a score,
  and one he can tell is worse than last time is a reason to stop playing.
- `QuizView` owns the round and the ledger and switches between the three. The **End**
  and **Skip** controls live in its round bar, because both belong to the round rather
  than to any one question.

### 9.5 The ledger

`QuizLedger` records, per letter **and** style, how often it was asked, how often it was
right first try, when it was last seen, and a rolling window of the last 8 outcomes.
Keyed by both because recognising B and recalling B are different skills, and a
style-blind record would average them and drill the wrong one.

**Nothing reads it for scheduling yet.** It exists now because the adaptive ordering
wanted next needs history, and history cannot be backfilled.

`QuizGenerator.round(deck:mode:using:)` is the seam that scheduler replaces. Today it
picks eligible letters uniformly at random; when the scheduler arrives it will weight
that by what the ledger says is weak and how long since each letter was seen, and
nothing outside that one function moves.

### 9.6 What the quiz is not

No adaptive ordering (yet), no blends, no recorded audio, no cumulative progress view,
no trend reporting. The ledger keeps counters and recency rather than an event log, so a
months-long trend line is the thing deliberately traded away.

### 9.7 History

This section once specified a *disabled* Quiz tab, implemented by intercepting the
`TabView` selection binding and refusing writes. **That does not work, and was verified
not to work on the simulator**: refusing the write is a no-op, so SwiftUI never
invalidates and never reconciles the underlying `UITabBarController` back. It was then
revised to a "coming soon" screen. Both are moot — the tab goes somewhere now — but the
finding is kept because it is not obvious: SwiftUI has no disabled-tab API, on neither
`.tabItem` nor the iOS 18 `Tab` type, and `.disabled` on a tab's content does not
prevent selection. Hiding a tab entirely is the clean option; faking `disabled` is not.

---

## 10. Accessibility

- Dynamic Type throughout, with caps chosen per surface because this is a fixed-size
  card rather than a scroll view. Card front `...accessibility2`; card back
  `...accessibility1`, since it carries a case row, a label, and four words on one
  canvas; control bar and position indicator `...accessibility1`.
  **Every control frame is a minimum, not a fixed size**, so the capsules grow with the
  type instead of letting their glyphs overflow — verified at AX3, where fixed frames
  had the `A`/`a` spilling outside their capsule.
- VoiceOver: the card is one element — "Letter B, capital. Tap to turn over." The back
  reads the opposite case, the label, and the four words.
- VoiceOver in the quiz: tiles announce their letter or their **word** (a bare emoji
  reads as a Unicode name or as nothing). Correctness is **announced outright** via
  `AccessibilityNotification.Announcement`, because a shake and a fill say nothing and a
  tile's `accessibilityValue` is only re-read if focus happens to be on it. The dots are
  one element reading "Question 3 of 10". The round bar carries
  `accessibilitySortPriority(0)` against the question's `1`, so the first thing read is
  the question rather than "End the round" — the bar is the parent's, the question is
  the child's.
- Reduce Motion: cross-fade instead of the 3D flip; no spring on page changes. In the
  quiz, a wrong tile **shakes** normally and **dips in opacity and back** under Reduce
  Motion — the same substitution, a cross-fade in place of a movement. Without it a
  second tap on an already-dim tile would give no feedback at all.
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
- Every card has a pool of **4 to 10** words (§3.5 rule 1); every `text` and `emoji`
  non-empty; no word repeated within a card.
- **Every word satisfies its own `wordRule`** (§3.5 rule 2).
- **No letter card's word begins with a blend that is also a card** (§3.5 rule 3).
- No emoji on two cards, bar the three honest exceptions (§3.5 rule 5); no keycap digits
  bar `zero` and `three`.
- Exactly `ck`, `ng`, `oo`, `ee` have `upper == nil`.
- Quiz eligibility (§9.2): the quiz cards are exactly the 25 `startsWith` letters; every
  one of their words begins with its own letter; 59 pictures flagged and 149 pooled; and
  **every one of the 25 keeps at least one clear picture** — the test that catches a
  future content edit flagging a card's last usable one.
- `soundClasses` names only real cards, and C, K, Q resolve to one group.

**`CardDeckTests`**
- `visibleCards` returns 26 with blends off, 34 with blends on.
- `ordered(shuffled: true, using:)` with a seeded generator returns a permutation of the
  same members — same count, same id set, nothing dropped or duplicated.
- `ordered(shuffled: false, …)` is alphabetical by id.

**`PagerIndexTests`**
- Index clamping at both ends; the last index reports `isAtEnd` so the restart button
  appears; the first reports `isAtStart` so the leading chevron is inert.

**`WordWindowTests`**
- The sliding window over a pool of up to 10 (§3.6): visit 0 is always the first four;
  the window wraps; a full pool of ten is seen across five arrivals with nothing
  stranded.

**`QuizGeneratorTests`** — the safety properties, and the reason the engine is value
types. A quiz that offers a defensible answer and then shakes at the child for picking
it is worse than no quiz.
- Ten questions, no letter twice, four choices, no two choices sharing a card.
- **Every distractor is wrong** — a distractor standing for the target would be a second
  correct answer.
- **No flagged picture ever becomes a tile, and none ever becomes a prompt** (§9.2).
- **C, K and Q never appear together**, including between two distractors.
- Every one of the 25 can pose a picture-choice question.
- A seeded generator is reproducible; two seeds differ.

**`QuizRoundTests`**
- Only the first tap is recorded; later taps on the same question change nothing.
- A skip advances and scores nothing.
- The four buckets — right, missed, skipped, never reached — always sum to the round,
  **including when the round is ended while the current question is answered but not yet
  stepped past**, which is the case that distinguishes "unreached" from "behind the
  cursor".

**`QuizLedgerTests`**
- A skip reaches the ledger nowhere; a mode-A answer does not move mode-B numbers; the
  recency window rolls at its cap; the whole thing round-trips through JSON unchanged;
  `clear()` empties it; unreadable JSON yields an empty ledger.

**`ThemeTests` / `ThemeContrastTests`**
- Every bundled Andika face resolves by **PostScript** name (§7.2) — `Font.custom` falls
  back silently, so a typo would ship the wrong letterforms looking fine.
- `success` clears 4.5:1 against its glyph and 3:1 against the surface, in both
  appearances. Separation from the accent is checked as **hue**, not contrast ratio: a
  contrast ratio is a luminance comparison, and a green and a blue of similar darkness
  sit near 1.1:1 while being plainly different to look at.

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
| **Q1–Q6** | The quiz (§9), built after M6 against `design/2026-11-23-quiz-design.md`: content flags and sound classes, the engine, the ledger, the question screen, start and finish, then its own accessibility and spec pass. |

---

## 13. Open items for John

1. ~~Download Andika.~~ **Done** — Andika 7.000 is in `~/Downloads/Andika-7.000/`.
   Copy `Andika-Regular.ttf`, `Andika-Bold.ttf`, and `OFL.txt` into
   `Content/Resources/`. The app builds and runs without them via the SF Rounded
   fallback (§7.2), so this is not a blocker for M1–M2.
2. **Review Appendix A** — the word and emoji choices, with attention to the flagged
   rows.
3. ~~App icon.~~ **Done** — John's artwork ships as light and dark variants
   (`AppIcon-light.png` / `AppIcon-dark.png`, 1024×1024, no alpha), wired through
   `AppIcon.appiconset/Contents.json` with the dark one tagged
   `appearance: luminosity / dark`. Verified in the compiled `Assets.car`: the dark
   rendition carries `UIAppearanceDark`.

   No **tinted** variant is supplied, so iOS derives one automatically. Add a third
   entry with `appearance: luminosity, value: tinted` if the derived one looks wrong.
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
| 20 | T t | tiger 🐯 · truck 🚚 · tent ⛺️ · teeth 🦷 |
| 21 | U u | umbrella ☂️ · unicorn 🦄 · up ⬆️ · underwear 🩲 ⚠️ |
| 22 | V v | violin 🎻 · van 🚐 · volcano 🌋 · vegetables 🥕 |
| 23 | W w | water 💧 · watch ⌚️ · wolf 🐺 · worm 🪱 |
| 24 | X x | **(contains)** box 📦 · fox 🦊 · axe 🪓 · ox 🐂 |
| 25 | Y y | yo-yo 🪀 · yellow 💛 · yarn 🧶 · yawn 🥱 |
| 26 | Z z | zebra 🦓 · zero 0️⃣ ⚠️ · zip 🤐 · zoo 🦒 |

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
  (the only picturable fourth option; also reliably funny to a 3-year-old), *zero* 0️⃣
  (see the non-pictorial note below).

### Verification (2026-08-15)

Appendix A was diffed mechanically against `Alphabet.json` — all 34 rows match, and
every §3.5 rule was re-derived from the JSON rather than trusted from the test suite.
Two classes of problem surfaced that reading the table doesn't reveal, since they are
properties of the *set* rather than of any one row:

**Duplicate pictures.** For a pre-reader the emoji is the content, so two cards sharing
one picture teaches a collision. Fixed: `t`/train 🚂 → **tent ⛺️** (🚂 now belongs to
`e`/engine alone), `z`/zoo 🐘 → **🦒** (🐘 now belongs to `e`/elephant alone).

Left alone deliberately: 🤫 on `q`/quiet and `wh`/whisper, and 🦆 on `q`/quack and
`ck`/duck — in both pairs the two words genuinely denote the same thing, so the shared
picture is honest rather than confusing. 🐑 on `sh`/sheep and `ee`/sheep stays as the
documented deliberate case.

**Non-pictorial emoji.** A child who cannot yet read letters generally cannot read
numerals either, so a keycap digit carries no meaning for the target user. Fixed:
`x`/six 6️⃣ → **axe 🪓**, which also satisfies the `contains` rule.

Not fixed, because the words themselves are worth more than the pictures: `z`/zero 0️⃣,
`th`/three 3️⃣, and `u`/up ⬆️. Three and up are genuinely good teaching words whose only
fault is being hard to picture; replacing them would cost more than the weak emoji does.
Candidates if you ever want them pictorial anyway.

**One phonics wrinkle, undocumented until now:** `o`/orange is r-coloured /ɔr/, a
different vowel from octopus, otter and olive. This is the same category as the `u`
mixture noted above, and left for the same reason — orange is too useful a word for this
age to drop over it.
