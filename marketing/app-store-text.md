# App Store text

Drafts for the 1.0 listing, written 2026-11-23 when the quiz shipped.

**All three sections were applied on 2026-11-23.** Sections 1 and 2 went to
App Store Connect and read back byte-for-byte identical to the text below.
Section 3 was applied to `docs/index.html`; the effective date moved from
15 August to 23 November 2026, as that page's own "Changes to this policy"
section promises.

App `6801923268` · version `1.0` (`68fd668c-a39b-419c-a627-13ac3d858387`) ·
en-US localization `154c8e4d-63ef-4904-973b-d07c68f90aac`.

---

## 1. Description

**What changes:** the first line gains a clause, a two-paragraph quiz section
is inserted after blends, and nothing else is touched. The "Also included"
list and the privacy closer stand as they are.

The quiz is deliberately described without two claims the app cannot back:
nothing says it adapts to the child (the ledger records history but nothing
reads it for scheduling yet), and nothing says it covers blends (it draws only
from the single-letter cards).

```text
A simple, quiet way for a young child to meet the alphabet — and to find out what has stuck.

Twenty-six letter cards, one at a time. Each card shows a single large letter. Tap it and the card turns over to reveal the other case — lowercase on the back of a capital, capital on the back of a lowercase — along with four everyday words that begin with that sound, each with a picture.

Swipe to the next letter. Cards snap one at a time and stay put, so an uncoordinated swipe from a small hand moves exactly one card, never five.

Switch on blends and digraphs to add eight more cards — sh, ch, th, wh, ck, ng, oo, ee — the letter pairs that make a sound of their own and that trip up new readers.

When you want to check, there is a quiz. Ten questions, four big tiles, no timer and nothing to beat. Pick the kind of question that suits the moment: you name a picture and the child finds the letter it starts with, or you name a letter and the child finds a picture that begins with it — or mix the two together.

A wrong tile dims and the child tries again; it is the first tap that counts. At the end you get the score and, more useful than the score, the letters worth coming back to.

Also included:
• A capital/lowercase toggle, so you can lead with whichever case you are working on
• Shuffle, for when the child has learned the order instead of the letters
• A tap to start over when you reach Z
• Andika, a typeface designed for early literacy, with the single-story "a" and "g" a child will meet in books

No accounts. No ads. No in-app purchases. No internet connection — the app has no network code at all, and nothing your child does in it leaves the device.
```

**If you would rather not touch the opening line,** drop the appended clause
and the line reverts to the live wording. The quiz paragraphs work without it;
the only cost is that the quiz goes unmentioned until below the fold.

---

## 2. App Review notes

**Why this matters more than the description.** A reviewer reads these as
instructions. The live notes say the app "opens straight to the flashcards"
and then describe card mechanics only — a reviewer following them finds a Quiz
tab nobody mentioned.

The load-bearing paragraph is the third one. In "Picture, pick the letter"
there is **no word on screen** by design, because the adult says it aloud. A
reviewer testing alone, with no adult to prompt them, could reasonably read a
captionless picture as a missing-content bug. That paragraph exists to prevent
a rejection on a misunderstanding.

```text
No account, login, or demo credentials are needed. The app has no network code at all, and no in-app purchases, ads, or external links.

CARDS TAB — the app opens here
Tap a card to flip it and see the opposite case plus four example words, each with a picture. Swipe, or use the arrows, to change letters. The control bar along the bottom holds a capital/lowercase toggle, Shuffle, and a Blends pill that adds eight digraph cards (sh, ch, th, wh, ck, ng, oo, ee).

QUIZ TAB — new in this build
Tap "Quiz" in the tab bar, choose one of three modes, then tap Start.

Please note that this app is built to be used by an adult together with the child, so the adult is meant to read each question aloud. In "Picture, pick the letter" a picture appears with no word beside it and the child taps the letter that picture starts with — there is no caption by design, and if you are testing alone the intended word is simply what the picture shows. In "Letter, pick the picture" a letter appears and the child taps a picture beginning with it. "Mixed" alternates between the two.

A round is ten questions, four tiles each. A wrong tile dims so the child can try again, and the first tap is the one that is scored. "Skip" moves on without scoring; "End" finishes the round early. The finish screen gives the score, names any letters that were missed, and offers "Go again" or "Done".

The quiz covers 25 of the 26 letters. X is omitted deliberately: its example words (box, fox, axe, ox) contain the x sound rather than begin with it, so "which letter does box start with?" has no right answer on an X tile. Every other letter appears.

"Clear what the quiz remembers" on the quiz start screen erases the on-device record of which letters have been answered correctly. That record never leaves the device and is not used for anything a reviewer needs to set up.

All on-screen text is written for the adult reading it aloud rather than for the child, which is why the app ships no recorded audio.
```

Contact name, phone and email are separate fields and need no change.

---

## Applying these

Both are single `asc` calls against the en-US localization once approved:

- description → `asc localizations update`
- review notes → `asc review details-update`

---

## 3. Privacy policy — the patch the quiz made necessary **(applied)**

Not App Store text, but it is the one piece of listing-adjacent writing the
quiz invalidated, and it matters more than the other two because a children's
privacy policy that enumerates what the app stores has to enumerate it
*correctly*.

`docs/index.html` says **"The app remembers four settings"** and lists four.
The app now persists **six** `@AppStorage` keys. The two it does not mention:

| Key | What it holds |
|---|---|
| `quizMode` | which of the three question styles was last chosen |
| `quizLedger` | a per-letter, per-style record of which quiz questions were answered correctly |

`quizMode` is a preference like the other four. **`quizLedger` is not** — it is
a record of how the child performed, which is a different kind of thing from
"which card you were last looking at", even though it never leaves the device
and contains no name, identifier, or timestamp.

Everything else in the policy still holds, and I checked rather than assumed:
there is no `openURL`, `Link(`, `UIApplication.shared.open` or `SFSafari`
anywhere in the app, so "does not link out to a website, store, or any other
app" is still true.

### Replacement for lines 88–97, as applied

```html
<p>The app remembers a few things so it picks up where you left off:</p>
<ul>
  <li>whether cards lead with the capital or the lowercase letter;</li>
  <li>whether the blends and digraphs are switched on;</li>
  <li>whether the deck is shuffled;</li>
  <li>which card you were last looking at;</li>
  <li>which kind of quiz question you last chose;</li>
  <li>which letters have been answered correctly in the quiz, and in which
      kind of question.</li>
</ul>
<p>The first five are ordinary app preferences. The last is a simple tally so
the quiz can tell you which letters to come back to — it records letters and
right-or-wrong, nothing else: no name, no date, no identifier of any kind. You
can erase it at any time with "Clear what the quiz remembers" on the quiz
start screen.</p>
<p>All of it is held in the app's own private storage on the device. None of it
is personal information, none of it is transmitted anywhere, and all of it is
deleted along with the app if you remove it.</p>
```

The effective date on line 75 moved from **15 August 2026** to
**23 November 2026**.

**This does not affect App Privacy answers in App Store Connect.** Those ask
what you *collect*, and the answer is still nothing — data that never leaves
the device is not collected. The policy page is the only thing that needs the
edit.
