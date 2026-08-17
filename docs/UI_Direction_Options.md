# UI Direction — four options to pick from

> For the owner to choose a *direction* before any UI is rebuilt. Each names
> real games/apps you can look up in ten seconds, says what it would mean on
> our screen, and gives the honest downside. Codex mockups of each applied to
> our own frame follow once the new room is wired (so they're not mocked on the
> old room).
>
> What's wrong today, so the options have something to fix: grey placeholder
> buttons (the Settings button literally uses a stylebox named `placeholder`),
> text-only music controls (`<<` `Play` `>>`), a heavy dark dialogue box across
> her body, and a focus card that reads as a debug panel. The warm painted room
> is fighting a default-engine UI.

---

## A. Video-call chrome
**Look up:** FaceTime · Discord voice call · 腾讯会议 / 微信视频 · Zoom
**On our screen:** thin translucent glass pills; her name tag + a green "通话中" dot + elapsed time top-left (we already have the CallStatusPill — this direction leans into it); controls as small round glyph buttons along the bottom edge like a call bar (mute/music/settings/hang-up-style "leave"); the dialogue box becomes a chat bubble that slides in from her side, like a message in a call.
**Why it fits:** it *is* the premise — you're on a call with her. Opening D already frames it as a co-work app. Zero learning curve for a Chinese audience (everyone knows 微信视频).
**Downside:** can feel cold/corporate if overdone; the risk is looking like a work tool. Needs the warm colour temperature and rounded shapes to stay hers.
**Best for:** the 小红书 clip — the "she's on a call with me" read is instant.

## B. Cozy paper / journal
**Look up:** Animal Crossing (dialogue + menus) · Coffee Talk · Spiritfarer · Unpacking · A Short Hike
**On our screen:** cream/kraft-paper cards with soft rounded corners and a hairline warm border; hand-drawn line icons for music/settings/tasks; the dialogue box as a paper note with her name on a little tab; the focus timer as a paper card with a hand-drawn ring.
**Why it fits:** matches the room's palette and the plant/botanical-print motif already in the art; reads "gentle" and "handmade", which is the game's whole feeling. Coffee Talk is the closest sibling in genre.
**Downside:** paper UI over an already-detailed painting can get busy; needs discipline (few elements, lots of margin). Icons must be drawn/sourced in one consistent hand.
**Best for:** the *game* — the version people would want to sit in for 25 minutes.

## C. Lo-fi minimal dark
**Look up:** the "lofi girl" stream overlay · Spotify · Endel · Forest (专注森林) · Tide (潮汐)
**On our screen:** almost no chrome; a single slim dark translucent bar at the bottom for music with real glyphs; timer as large thin numerals with nothing around them; dialogue as plain text with a soft gradient scrim behind it, no box; settings hidden behind one small icon.
**Why it fits:** it's a focus app; the less UI the more the room and Yua carry the frame; screenshots look clean and modern.
**Downside:** dark bars fight the warm painting at the edges; "minimal" can read as "unfinished" if the type and spacing aren't excellent — this direction has the least margin for error.
**Best for:** people who'd actually use it daily; least "游戏感".

## D. Anime visual-novel plate
**Look up:** Blue Archive · Steins;Gate · Doki Doki · 恋与深空 (Love and Deepspace)
**On our screen:** a decorated dialogue plate at the bottom with an ornamental name badge for 由亚, thin diagonal accent lines, chips styled as VN choice buttons; system panels with a subtle pattern.
**Why it fits:** Yua's art is anime; a Chinese audience knows this language instantly; it makes "story" legible.
**Downside:** it *is* a game UI — it undercuts the "this is a call app" premise the whole design rests on, and it's the most crowded of the four. Also the most likely to look derivative.
**Best for:** the story episodes; least good for the co-presence/focus half.

---

## My recommendation (art director hat)

**A as the frame, B as the material.** Call-app *structure* (name tag, 通话中, call bar, chat-bubble dialogue) rendered in *paper/warm* materials rather than glass-grey — so it reads as a call *with her*, in *her* room. That keeps the premise legible in a 30-second clip (A's strength) without going cold (A's weakness), and it uses the botanical motif already in the art. C is the fallback if A+B gets busy. I'd avoid D for this game.

## What happens after you pick

1. Codex mocks the chosen direction (and one alternate) onto our real frame — you check the *look*.
2. Claude builds it as a Godot theme + a few icon assets (Kenney/Lucide are free), one panel at a time, screenshotting each.
3. Nothing about game logic changes; this is `data/theme/project_chill.tres` + scene styling.
