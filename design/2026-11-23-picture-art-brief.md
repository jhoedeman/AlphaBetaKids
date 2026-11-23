# Picture art brief

**Why this exists.** 59 of the 208 words on the quiz cards carry
`"ambiguousPicture": true` and are barred from the quiz (see
`2026-11-23-quiz-design.md` §5). Nearly all of them are flagged because of the
*emoji*, not the word: 🛖 is a hut, so "igloo" fails; 🌰 is a chestnut, so
"acorn" fails. Drawn artwork removes most of that.

**The one test every picture has to pass.** A three-year-old sees it with no
word beside it and no adult speaking. Whatever he calls it must start with this
card's letter. Not "what is it" — "what would *he* call it".

Two corollaries worth holding onto while drawing:

- **Draw the thing, not a scene.** 🍴 fails because the emoji includes a knife.
  A fork alone passes. 📿 fails as loose beads; worn around a neck it reads as
  a necklace.
- **Specificity beats accuracy.** A botanically perfect yak is a cow to him.
  No drawing rescues a word he doesn't have.

---

## 1. Free wins — no drawing needed **(done 2026-11-23)**

These were flagged by my judgment, and I had them wrong for an American child.
All six flags are now lifted: **53 of 209 flagged, 156 clear.**

| Card | Picture | Flagged as | Why I now think it's fine |
|---|---|---|---|
| f | 🏈 football | "ball" | The emoji *is* an American football. A US child says "football". |
| l | 🐞 ladybug | "bug" | US children say "ladybug" specifically; it's a named favorite. |
| l | 🍭 lollipop | "candy" | The emoji is unmistakably a lollipop, and the word is common. |
| j | 🧥 jacket | "coat" | American. "Jacket" is the default word here, not "coat". |
| j | 👖 jeans | "trousers" | American. No US child says "trousers". |
| a | 🚑 ambulance | "truck" | Red cross, lights, the word is common from picture books. |

That was **+6 pictures and +2 for `j`** (3 → 5) for the price of editing a
JSON field. `a` went 4 → 5, `f` 8 → 9, `l` 7 → 9.

---

## 2. The five thin cards, and what to draw

Current clear-picture counts: **z 1, i 2, n 2, q 2, y 2**, u 3, j 3.

### `i` — 2 → 4

| Draw | Notes |
|---|---|
| **igloo** ★ | The best single example of why drawing helps. White snow-brick dome, arched tunnel entrance, blue shadow, snow around it. The emoji 🛖 is a thatched hut; a drawn igloo is only ever an igloo. |
| **ice cream** ★ | A cone with two scoops. The only candidate in the whole emoji repertoire that already works — draw it anyway so it matches. |

Not worth drawing: *insect* (he says "bug"), *iguana* ("lizard"), *ink*
("paint"). The words are wrong, not the pictures.

### `n` — 2 → 6

| Draw | Notes |
|---|---|
| **net** ★ | Butterfly net on a stick, or a fishing net. Emoji only has 🥅, a soccer goal. Strong silhouette at tile size. |
| **nail** ★ | One nail, large, half-driven into a plank. Keep the hammer out of frame — a hammer in shot makes it "hammer", and H already has one. |
| **necklace** ★ | Redraw: beads **worn around a neck**. Loose on a table they're "beads". |
| **needle** ★ | Redraw: a sewing needle with thread through the eye, thread trailing. |

Marginal: *noodles* (risks "pasta"), *nurse* (risks "doctor"), *nut* (risks
"peanut" — a bowl of mixed nuts would help). Skip *night*, *notebook*,
*newspaper*.

### `y` — 2 → 5

| Draw | Notes |
|---|---|
| **yogurt** ★ | A tub with the foil half-peeled, a spoon, berries on top. Toddlers know this object cold. Emoji has nothing for it. |
| **yellow** ★ | Redraw as a **plain blob or splash of yellow**, nothing else in frame. 💛 fails because he says "heart". See the note on color words below. |
| **yarn** ★ | Redraw: a ball of yarn with two knitting needles stuck through it. 🧶 alone reads as "wool" or "ball"; the needles make it yarn. |

Not worth drawing: *yacht* (he says "boat" and doesn't have the word), *yak*
("cow").

### `q` — 2 → 3, and that is the ceiling

| Draw | Notes |
|---|---|
| **quilt** | Patchwork **squares** filling the frame, obviously stitched, a corner turned down. Risk: he says "blanket". Make the patches the subject, not the bed. |

*quack* is a duck and always will be. *question mark* is not a picture.
*quill* is a feather. *quarter* is a coin. **Q has three good words in a
three-year-old's vocabulary and that is all there is.**

### `z` — 1 → 2, possibly 3

| Draw | Notes |
|---|---|
| **zipper** ★ | Rename the word from "zip" to **"zipper"** and draw a real zipper — metal teeth, pull tab, fabric either side, half open. 🤐 is a zipped *mouth*. |
| **zoo** | Entrance arch with an elephant and a giraffe behind it. Risk: he says "animals". Only works for a child who has been to one. Your call. |

Nothing else exists. Z words a three-year-old owns: zebra, zoo, zipper, zero.
**Z tops out at 2–3 no matter how good the art is**, and that is a fact about
English, not about effort.

---

## 3. Color words — a category worth opening deliberately

Two flagged words are colors: `green` 💚 and `yellow` 💛. Both fail because the
emoji is a *heart*, and he says "heart".

A plain swatch — a torn paint blob, a crayon scribble filling the frame, a
solid rounded square — is a real picture for a color word, and a child being
taught colors names it readily. If you draw these, keep them **absolutely
empty of other objects**: a paintbrush in frame makes it "paint", a crayon
makes it "crayon".

This only matters for `y` (2 clear) and `g` (6 clear), so it is one real gain
and one nice-to-have. Don't open it wider — "red" and "blue" would land on
cards that are already full.

---

## 4. Worth redrawing even though they're not on thin cards

Each of these is a good word with a bad emoji. They widen the distractor pool,
which is what makes a round feel varied.

| Card | Word | What the emoji gets wrong | Draw instead |
|---|---|---|---|
| a | acorn | 🌰 is a chestnut | Acorn with its cap, one oak leaf |
| a | arm | 💪 is a flexed bicep | A whole arm, shoulder to open hand |
| c | cup | 🥤 is a soda cup with a straw | A child's cup with a handle |
| f | fork | 🍴 includes a knife | One fork, alone |
| g | glove | 🧤 reads as a mitten | Five separate fingers |
| h | honey | 🍯 reads as "jar" | Pot with a dipper and a drip, a bee above |
| m | muffin | 🧁 is a frosted cupcake | Plain muffin in a paper case, domed top, no frosting |
| v | vest | 🦺 is a hi-vis safety vest | A child's puffy vest, no sleeves, zipped |

---

## 5. What drawing cannot fix

Listed so nobody spends an afternoon on them. In every case the **word** is the
problem — he has a different, earlier word for the thing.

*alligator* → crocodile · *angel* → baby · *alarm* → clock · *envelope* → letter ·
*engine* → train · *eagle* → bird · *earth* → world · *gift* → present ·
*goose* → bird · *hedgehog* → porcupine · *jet* → plane · *jigsaw* → puzzle ·
*koala* → bear · *kitten* → cat · *insect* → bug · *iguana* → lizard ·
*ink* → paint · *night* → city · *notebook* → book · *oyster* → shell ·
*ocean* → water · *quack* → duck · *rose* → flower · *swan* → bird ·
*telephone* → phone · *vegetables* → food · *video* → (not a thing) ·
*wood* → log · *yacht* → boat · *zero* → (a numeral, not a picture)

---

## 6. If you draw all of this

| Card | Now | After |
|---|---|---|
| i | 2 | 4 |
| n | 2 | 6 |
| y | 2 | 5 |
| z | 1 | 2–3 |
| q | 2 | 3 |
| j | ~~3~~ **5** | 5 — done, no drawing needed |

Plus roughly eight redraws elsewhere. **Call it 20 drawings for the thin cards
and 8 for the pool**, and every card clears four except `q` and `z`, which
cannot be fixed by any means.

---

## 7. How the app would take them

Not built yet, and deliberately small when it is. `Word` gains an optional
field beside `emoji`:

```json
{ "text": "igloo", "emoji": "🛖", "image": "igloo" }
```

The view prefers `image` when present and falls back to `emoji`, exactly the
way `audioFile` is reserved in SPEC §8. A word with an `image` is clear by
definition, so `ambiguousPicture` stays on the row as a record of why the emoji
was never enough.

Format: PNG or PDF vector in the asset catalog, square, legible at **46pt** —
that is the size in a quiz tile, and it is the real constraint. Test every
drawing at that size before calling it done; half of what reads at 200pt is
mud at 46.
