# Quiz — design

**Date:** 2026-11-23
**Status:** approved design, not yet built
**Spec:** supersedes SPEC §9, which currently only explains why a placeholder ships

---

## 1. Intent

AlphaBetaKids is used by a parent and a three-year-old **together**, never by the child
alone. The two of them want different things from the same session:

- The parent wants to teach his son to read, and to see whether it is working.
- The son wants a bright screen that reacts when he pokes it.

The quiz is the half of the app where the child does something and the app answers. The
cards are for showing; the quiz is for checking.

The single most important consequence: **the on-screen text is for the parent.** The
child cannot read, but he is never alone with the device, so the app does not have to be
comprehensible to a non-reader. The parent reads the prompt aloud, supplies the
encouragement, and corrects the misses. This is what makes the whole feature possible
without recorded audio.

## 2. Goals

1. The parent can run a short drill and see, at the end, what his son actually knew.
2. The child gets an immediate, physical-feeling response to every tap.
3. The app accumulates a record of which letters are weak, so a later release can
   reorder questions toward them.

## 3. Non-goals (deliberately out of this release)

- **Blends in the quiz.** "Which picture has the *oo* sound?" is a real skill, a later
  rung, and the content is not safe for it (see §5).
- **Recorded audio.** The §8 seam stays dormant. The parent is the audio.
- **A manual "drill only A–F" picker.** The adaptive scheduler does this job better and
  automatically; a hand-picker would be built to be thrown away.
- **The adaptive scheduler itself.** Only the seam it plugs into, and the ledger it will
  read. The owner expects to build this soon after.
- **Long-term trend reporting.** The ledger shape does not support a months-long trend
  line; see §6 for what was traded away and why.

## 4. Anti-goals (this fails even if it ships and works)

- **Anything absorbing enough to play alone.** No autoplay, no streaks, no unlockables,
  no reward treadmill. If the child will sit with it without the parent, it has failed on
  the owner's own terms.
- **Punishing a wrong answer.** No red X, no buzzer, no score counting down in front of
  him. A three-year-old who feels bad stops playing.
- **Measuring instead of teaching.** The parent is in the room; the app's job is to
  create the moment where teaching happens, not to grade.

## 5. Constraints

**From the platform and existing spec:**

- `@AppStorage` only — no `ModelContainer`, no iCloud, no background modes (SPEC §2).
- iOS 18, iPhone + iPad, portrait only.
- One palette, one font family. No new theme surface (SPEC §7).
- Dynamic Type caps and VoiceOver parity as elsewhere (SPEC §10).

**From the content — the trap that shapes question generation:**

The word pools were authored around *"this card's sound occurs in this word"*, which is
**not** the relation a letter quiz needs (*"this word starts with this letter"*). The two
diverge badly on blend and `contains` cards:

| Card | Pictures whose first letter is a different card |
|---|---|
| `oo` | moon (M), spoon (S), boot (B), broom (B), book (B), cookie (C) |
| `ck` | duck (D), sock (S), rock (R), clock (C), backpack (B) |
| `ee` | tree (T), feet (F), bee (B), sheep (S), sleep (S), coffee (C) |
| `ng` | ring (R), king (K), wing (W), sing (S), tongue (T) |
| `sh` `ch` `th` `wh` | every word starts with S / C / T / W respectively |
| `x` | box (B), fox (F), axe (A), ox (O) |

Showing 🌙 and expecting "oo" is wrong — the honest answer is M. Offering 🌙 as a
*distractor* for M is worse: the child who picks it is right and the app says no.

**The rule that resolves it:** the quiz draws only from the **25 letter cards whose
`wordRule` is `startsWith`** — every letter except `x`. That is **208 pictures**, at
least four on every card.

This filter makes distractors safe at the level of **words**: within those 25 cards every
word begins with its own card's letter, so a word borrowed from card Y can never be a
correct answer for card X. A test must pin this, since it breaks silently the moment
anything outside the 25 is admitted.

**It is not safe at the level of pictures, and mode B's choices are pictures.** A picture
has no caption, so the child names it himself — and his name for it often starts with a
different letter than the word it is filed under:

| Prompt | Tile | Filed under | What he sees |
|---|---|---|---|
| C | 🥕 | v / vegetables | carrot |
| C | 🐈 | k / kitten | cat |
| B | 🏈 | f / football | ball |
| D | 🦆 | q / quack | duck |
| P | ☎️ | t / telephone | phone |
| W | 🌊 | o / ocean | water |

Mode A is immune — the parent says "this is a carrot" and the question is settled. Mode B
has nothing naming the tiles, so this is §5's own worse case reached through the picture
instead of the word: the child who taps it is right and the app shakes at him.

**Resolution: an `ambiguousPicture` flag in the content, excluding that picture from mode
B** (both as a correct answer and as a distractor). It stays available in mode A, where
the parent's voice disambiguates it. A hand audit of all 208 flagged **58**, leaving
**150** usable in mode B. The full list is in Appendix A.

The cost is smaller than it looks, because a card needs only **one** unambiguous picture
to serve as a correct answer — the three distractors come from the global pool of 150.
**No card loses mode B.** Five get thin on correct answers: `i` 2, `n` 2, `q` 2, `y` 2,
`z` 1. If that proves dull in use, the fix is more words on those cards, not a change
here.

## 6. Approaches considered

### 6.1 Who judges the answer — **app judges** (chosen)

- *Parent judges:* app shows a letter, child says the sound, parent taps "got it" / "not
  yet." Closest to paper flashcards; handles sounds the child can only say aloud; needs
  no distractors at all.
- *App judges (chosen):* multiple choice, child taps, app reacts.

Chosen because the tapping is the child's entire reason for being at the table. The cost
accepted: every question needs plausible wrong answers, and the child can score by luck.

### 6.2 Question type — **both, parent-selected, plus mixed** (chosen)

- **A — picture, pick the letter.** 🐻 with four letters below. The parent names the
  picture aloud, so the child never has to recognise an emoji he does not know.
- **B — letter, pick the picture.** `B` with four pictures below. Leans harder on
  vocabulary, but exercises recall in the reading direction.
- **Mixed.** Interleaved within a round.

Originally recommended parent-picks-one, on the grounds that a consistent target for ten
questions is enough to ask of a three-year-old. The owner's son is further along than
that, so **all three are offered on the start screen** and the parent chooses. Mixed is
nearly free: the per-question generator has to support both modes regardless.

### 6.3 Wrong-answer feedback — **shake and dim** (chosen)

Four behaviours were built as clickable mockups and tried:

- *Nothing happens.* Wrong taps ignored entirely; failure never becomes a moment. Too
  little signal — the child cannot tell trying from succeeding.
- *Shake and dim (chosen).* The wrong tile shakes, fades back, **stays on screen and
  stays tappable.** Unmistakable "not that one" with nothing that reads as punishment,
  and it cues the parent to say the sound again.
- *Wrong ones disappear.* Most forgiving, but the field narrows to a correct answer the
  child reaches by elimination without knowing it.
- *Mark wrong, reveal, advance.* Rejected on sight: that is assessment, and it fights the
  intent in §1.

### 6.4 Session shape — **fixed round of ten** (chosen)

- *Endless until closed.* Simplest, but every ending is the parent confiscating the
  device — which is the part that actually goes wrong with a three-year-old.
- *Fixed round of ten (chosen).* A row of dots fills as he goes, then a finish screen.
  The round ends itself, so stopping is not a confiscation, and the dots tell him how
  much is left in a form he can read without reading. Roughly two to three minutes.
- *Parent picks the length.* Deferred to a setting if ten proves wrong.

### 6.5 The ledger — **counters plus recency** (chosen)

- *Counters only* — `asked` and `firstTry` per letter. Enough to weight selection toward
  weak letters; cannot say when a letter was last seen.
- *Counters plus recency (chosen)* — adds `lastSeenAt` and the last few outcomes per
  letter. This is the shape real spaced repetition needs: scheduling has to know not just
  how often B is missed but how long since it appeared, or the child is drilled forever
  on his worst letters and never revisits the ones he has quietly forgotten.
- *Full event log* — every question stamped and kept. Forecloses nothing and is the only
  option that supports a months-long trend line. **Traded away knowingly:** nobody has
  asked for a trend chart, and an event log would have to be aggregated into the chosen
  shape before the scheduler could use it anyway.

### 6.7 Ambiguous pictures in mode B — **flag and exclude** (chosen)

- *Flag and exclude (chosen).* A content pass plus one JSON field. Preserves mode B as
  the recall exercise it was chosen to be. Cost quantified in §5.
- *Print the word under each picture tile,* as the card backs already do. Free and
  visually consistent, but it only helps the parent explain afterwards — the child still
  cannot read "vegetables", so he is still shaken for a correct answer. A mitigation.
- *Accept it.* Reproduces the exact defect the §5 filter exists to prevent.

### 6.6 Architecture — **value types and view state** (chosen; no real alternative)

Everything in this app is plain value types with pure functions and view-owned `@State`:
`CardDeck`, `PagerPosition`, `LetterCard.shownWords(forVisit:)`. That is why 44 tests run
without a view. The quiz fits the same mold.

Rejected: an `@Observable QuizSession` class would be the app's first observable store,
reachable from nowhere else, for no benefit. SwiftData for the ledger would break SPEC §2
and bring a migration story for twenty-five integers.

## 7. The design

### 7.1 Screens

**Start.** Replaces `QuizPlaceholderView`. Three mode choices — *Picture, pick the
letter* / *Letter, pick the picture* / *Mixed* — and a Start control. Worded for the
adult reading it.

**Question.** One prompt (a large picture, or a large letter in the app's accent), a line
of instruction text addressed to the parent, and **four choices in a 2×2 grid** reusing
the geometry already proven on the card back. A row of ten dots shows position in the
round.

**Finish.** First-tap results, addressed to the parent: "7 of 10 first try", and which
letters were missed. Controls to go again or leave. The child's reward is the dots having
filled; the information is the parent's.

### 7.2 Rules

- Ten questions per round, **no letter repeated within a round** (25 eligible, 10 drawn).
- Four choices, one correct.
- Correct tap: the tile turns green, then the next question arrives.
- Wrong tap: shake, dim, remains tappable. No limit on attempts.
- **Only the first tap of each question is recorded.** With a wrong tile staying live the
  child always arrives at the right answer eventually, so "answered correctly" is always
  true and worthless as a signal. The first tap is the honest measure.
- Case follows the existing `leadingCase` toggle (SPEC §2) rather than a second control.
- **C, K and Q never appear as each other's distractors.** Every C word here is hard /k/
  and every K word is /k/, so a child shown 🔑 who reasons from sound to letter and taps
  C is doing exactly what the app taught him. A small sound-class table in content, and a
  test, keep them apart. (Builder's call: the same table is the natural home for any
  later pair, but C/K/Q is the only collision in the current content.)
- **A parent-facing skip** sits on the question screen, styled like the card front's flip
  affordance — present, low-contrast, not something a three-year-old reaches for. Without
  it a child who stalls or wanders off leaves the round unfinishable, and the only exit is
  closing the app: the confiscation ending that §6.4 chose the fixed round to avoid. There
  is also a way to end the round early.
- **A skipped question records nothing.** It is not a measurement — a skip cannot
  distinguish "doesn't know it" from "has lost interest", and guessing would poison the
  ledger the scheduler depends on. The ledger stays a two-outcome record.
- **The correct tile uses a new `success` token** in `Theme`, with light and dark values
  and a contrast check alongside the existing ones. This is a deliberate exception to §5's
  "no new theme surface", which was aimed at palette switching, not at semantic colour:
  the accent is already the colour of the letters themselves, so a correct tile turning
  accent-blue would read as emphasis rather than as approval.

### 7.3 The selection seam

Question generation goes through one function from the start — today returning an
eligible letter at random, later returning a weakness-and-recency-weighted one. It takes
its `RandomNumberGenerator` as a parameter, exactly as `CardDeck.ordered(…)` does, so
rounds can be tested with a seed. Nothing else changes when the scheduler lands.

### 7.4 Stored state (extends the SPEC §2 table)

| Key | Type | Default | Notes |
|---|---|---|---|
| `quizMode` | `String` | `"pictureToLetter"` | last mode chosen on the start screen |
| `quizLedger` | `String` (JSON) | `"{}"` | per-letter record, below |

Ledger entry **per letter and per mode**: times asked, times correct on first tap, when
last seen, and a short rolling window of recent first-tap outcomes. Mode is recorded
because recognising B and recalling B are different skills — a mode-blind ledger averages
the two and would drill the wrong one. Mixed-mode questions attribute to whichever mode
that question actually was. Fifty entries at most, encoded as JSON in a single
`@AppStorage` string — no new persistence stack.

**A reset control clears the ledger.** The app has no settings surface today, so this is
the one new parent-facing affordance: reachable from the quiz start screen, confirmed
before it wipes, and placed where a child won't hit it. It matters for a shared device, a
sibling, and for clearing the junk data generated while testing. No cumulative *view* in
this release — there is nothing to show until the scheduler gives the numbers meaning.

## 8. Testing

Following SPEC §11, the valuable tests are the ones that do not need a view:

- A generated round has ten questions, no repeated letter, and four choices each.
- **Every question's distractors are wrong** — the core safety property.
- **No question ever draws on a card outside the 25** (`startsWith` letters). This is the
  test that stops the blend trap in §5 from reappearing.
- Seeded generation is reproducible; two different seeds give different rounds.
- Ledger: first tap is what gets recorded; later taps on the same question do not; the
  recency window rolls and does not grow.
- Round-in-progress arithmetic — position, dots filled, when the round is over.
- **No flagged picture ever appears in mode B**, as correct answer or distractor — the
  test that stops the §5 picture trap from reappearing.
- **C, K and Q never co-occur** in one question's choices.
- A skipped question leaves the ledger untouched.
- Ledger entries are keyed by letter *and* mode; a mode-A answer does not move mode-B
  numbers.
- Every one of the 25 cards can still produce a mode-B question (guards against a future
  content edit flagging a card's last usable picture).

## 9. Left to the builder

- Animation timings and the exact shake curve; the mockup's values are a starting point.
- Whether a round in progress survives backgrounding, or restarts. Restarting is fine.
- Layout specifics inside the existing theme — spacing, tile size, how the 2×2 grid
  adapts between iPhone and iPad.
- Where the prompt text sits relative to the picture.
- Whether the finish screen names missed letters as glyphs, words, or both.
- The exact `success` green, subject to the contrast check.
- Where the skip and end-round controls sit, and the reset's confirmation wording.

## 10. Known doc drift to fix while in here

SPEC §11 still says "Every card has exactly 4 words"; §3.5 was updated to pools of 4–10
but §11 was missed.

---

## Appendix A — pictures flagged `ambiguousPicture`

Excluded from mode B only; still used in mode A, where the parent names them.
Judged by hand on 2026-11-23 against the question "what would a three-year-old
call this, with no word next to it?"

| Card | Picture | Filed as | He'd likely say |
|---|---|---|---|
| a | 🐊 | alligator | crocodile |
| a | 🌰 | acorn | nut |
| a | 🚑 | ambulance | truck |
| a | 👼 | angel | baby |
| a | 💪 | arm | muscle |
| a | ⏰ | alarm | clock |
| c | 🥤 | cup | drink |
| e | ✉️ | envelope | letter |
| e | 🚂 | engine | train |
| e | 🦅 | eagle | bird |
| e | 🌍 | earth | world |
| f | 🍴 | fork | knife |
| f | 🏈 | football | ball |
| g | 🎁 | gift | present |
| g | 🧤 | glove | mitten |
| g | 💚 | green | heart |
| g | 🪿 | goose | duck |
| h | 🍯 | honey | jar |
| h | 🦔 | hedgehog | porcupine |
| i | 🐛 | insect | bug |
| i | 🦎 | iguana | lizard |
| i | 🖊️ | ink | pen |
| i | 🛖 | igloo | hut |
| j | ✈️ | jet | airplane |
| j | 🧥 | jacket | coat |
| j | 👖 | jeans | pants |
| j | 🧩 | jigsaw | puzzle |
| k | 🐨 | koala | bear |
| k | 🐈 | kitten | cat |
| l | 🍭 | lollipop | candy |
| l | 🐞 | ladybug | bug |
| l | 🦙 | llama | alpaca |
| m | 🧁 | muffin | cupcake |
| n | 🥜 | nut | peanut |
| n | 🪡 | needle | thread |
| n | 📰 | newspaper | paper |
| n | 🌃 | night | city |
| n | 🍜 | noodles | soup |
| n | 📓 | notebook | book |
| n | 📿 | necklace | beads |
| o | 🌊 | ocean | water |
| q | ❓ | question | question mark (not a picture) |
| q | 🦆 | quack | duck |
| r | 🌹 | rose | flower |
| s | 🦢 | swan | bird |
| t | 🚕 | taxi | car |
| t | ☎️ | telephone | phone |
| u | ⬆️ | up | arrow (not a picture) |
| v | 🥕 | vegetables | carrot |
| v | 🦺 | vest | jacket |
| v | 📹 | video | camera |
| w | 🪵 | wood | log |
| y | 💛 | yellow | heart |
| y | 🧶 | yarn | ball |
| y | 🛥️ | yacht | boat |
| z | 0️⃣ | zero | digit (not a picture) |
| z | 🤐 | zip | zipper face |
| z | 🦒 | zoo | giraffe |

**58 of 208 flagged; 150 remain usable in mode B.**
