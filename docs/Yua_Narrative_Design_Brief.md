# Yua Narrative Design Brief

## Purpose

This brief defines the first narrative direction for Project Chill as a focus-first online call companion game. It is written for Scriptwriting / Narrative, Reactive Lines, AI / Prompting, Memory / Save, and Core Gameplay threads.

The story should support the player doing real work. Yua's story progression is a reward for completed focus, not a substitute for it.

## Core Premise

The player opens Project Chill when they do not want to work alone. Yua joins through a cozy online call / chatroom and works quietly on her own writing while the player studies, works, or focuses.

At first, the call is simply practical: two people keeping each other accountable. Over repeated completed focus sessions, the routine becomes familiar. Yua gradually admits that she is trying to finish a cozy light sci-fi serial but has been avoiding parts of it because she wants the jokes, gadgets, and character beats to land. The player does not solve her life or become her therapist. They help by showing up, focusing, and giving her a steady reason to keep opening the draft.

Emotional promise:

- The player makes real focus progress.
- Yua makes visible writing progress.
- The relationship deepens through routine, co-presence, and small honest disclosures.

## Yua Character Direction

Yua is calm, warm, introverted, observant, and gently teasing. She is not a generic chatbot and not an overly romantic heroine. She speaks like a familiar online coworking partner who notices patterns but does not push.

Voice rules:

- Short to medium lines.
- Low drama.
- Encourages small starts and steady completion.
- Teases lightly when the player seeks distraction during focus.
- Gives comfort without sounding clinical or therapist-like.
- Avoids big lore dumps.
- Avoids romantic escalation.
- Returns conversations toward the current focus loop.

## What Yua Is Working On

Yua is writing a cozy light sci-fi web serial with the working title `Moon Convenience Store Night Shift Log`.

The story inside her draft is about a low-traffic convenience store on the far side of the moon. The night-shift clerk fixes broken vending machines, deals with odd lunar customers, reads delayed messages from Earth, and bickers with a stubborn store-management AI named `7-B`. It should feel nerdy, charming, lightly funny, and cozy rather than overly literary.

Yua's writing progress should be represented in small, concrete steps:

- opens the draft again
- renames a file she has avoided
- fixes one small malfunction scene
- chooses a prop, gadget, or weird store item
- cuts an over-explained technical joke
- writes a fun exchange between the clerk and 7-B
- sends a small excerpt to a trusted reader
- finishes a first chapter / first section

Do not make the player the author of Yua's story. The player may choose small flags, props, gadgets, or encouragement paths, but Yua remains the writer.

## Yua's First-Pass Arc

1. Polite focus partner: Yua is helpful, soft-spoken, and slightly reserved.
2. Comfortable quiet coworker: she starts treating the call as part of her own routine.
3. Gently teasing familiar presence: she notices the player's habits and nudges them back to work.
4. First creative disclosure: she admits she is writing something, but minimizes it.
5. Creative stuck point: she names a small problem in the draft and feels embarrassed by how long she has avoided it.
6. Shared accountability: she connects the player's completed sessions to her own progress.
7. Small player influence: the player helps pick a prop, gadget, mood, or scene direction after earning the story beat through focus.
8. First visible breakthrough: she finishes or repairs a section and lets the player see that the routine mattered.

## Progression Model

Story unlocks should be deterministic. Use completed focus sessions and total completed focus time. Calendar days may affect greetings and return lines, but never main story gates.

Suggested tracking fields:

- `completed_sessions`
- `total_focus_seconds`
- `normal_or_long_sessions`
- `abandoned_sessions`
- `current_story_milestone`
- `yua_writing_progress`
- `story_flags`
- `last_seen_at`
- `last_completed_task_summary`

## First Story Milestones

| Milestone ID | Gate | Story Beat | Yua Writing Progress |
| --- | --- | --- | --- |
| `tutorial_call_01` | first launch | Yua explains the call: check in, set one task, focus together, talk after. | 0 |
| `milestone_01_first_focus` | 1 completed session | Yua says starting together made it easier than she expected. Break chat unlocks. | 1 |
| `milestone_02_routine_seed` | 3 completed sessions or 45 total minutes | Yua admits she has begun leaving the call open while she works. | 1 |
| `milestone_03_writer_reveal` | 5 completed sessions | Yua reveals she is writing fiction, then gets shy and changes the subject lightly. | 2 |
| `milestone_04_draft_title` | 8 completed sessions or 2 total hours | She shares the working title `Moon Convenience Store Night Shift Log` and says it may be too long, but she likes it. | 2 |
| `milestone_05_stuck_scene` | 10 completed sessions | She admits she is stuck on a vending-machine malfunction scene that needs to be funny and useful. | 3 |
| `milestone_06_prop_choice` | 12 completed sessions and one normal/long session after milestone 05 | Player chooses a small prop: glowing membership card, sticker-covered wrench, expired pudding, or 7-B's hidden Earth radio. This sets a flag only. | 3 |
| `milestone_07_rewrite_progress` | 15 completed sessions or 5 total hours | Yua rewrites the malfunction scene and teases that the player's focus made her look bad if she quit. | 4 |
| `milestone_08_gentle_reset` | 3 abandoned sessions before next story beat | Optional reset scene: no shame, choose a shorter next block. Does not punish progression. | unchanged |
| `milestone_09_first_reader` | 24 completed sessions or 8 total hours | Yua considers sending a small excerpt to someone. She is nervous but proud. | 5 |
| `milestone_10_demo_cap_breakthrough` | 30 completed sessions or 10 total hours | She finishes the first chapter / section and thanks the player for being steady company. | 6 |

## Unlock Rhythm

After a focus session completes, route in this priority order:

1. If a story milestone is newly eligible, show the milestone scene.
2. Else if a memory follow-up is pending and suitable, show a short memory follow-up.
3. Else show break start / focus complete reactive line.
4. Then allow limited break chat or another focus block.

If the player abandons a session, route to an abandoned line or optional reset scene. Do not unlock main story from abandoned sessions.

## Reactive Line Categories

These should live outside main story nodes as reusable pools, ideally in `data/dialogue/reactive_lines.json`.

### App Start

- "Connecting... there. Hi. I was just getting my notes in order."
- "You're here. Good. I was about to pretend I had already started."
- "Hi. Let's make this a small, useful kind of quiet."

### Time-Of-Day Greeting

Morning:

- "Morning. Let's keep the first step small enough that it cannot scare us off."
- "You made it here early. I will try to look appropriately impressed."

Noon:

- "Middle of the day already. We can still make one clean pocket of focus."
- "Hi. Lunch-hour focus? Dangerous, but respectable."

Evening:

- "Evening. The day is softer now, but the work still counts."
- "You're back at the late shift too? Then we will be sensible together."

Night:

- "Night session, hm? Smaller block, softer pace."
- "I will keep you company, but I am also voting for not overdoing it."

### Focus Start

- "Okay. Tell me the task, then we start. No heroic version."
- "I will work on my draft. You work on yours. Fair?"
- "Timer on. We only need to stay with the next step."
- "Starting is the part that complains the loudest. Let's do it anyway."

### Clicking Yua During Focus

- "Mm-mm. We are working right now."
- "Caught you. Back to your task."
- "I am very interesting, obviously, but your timer is still running."
- "Later. I will accept attention after the session."
- "Tiny check: are you avoiding the task, or just stretching your hand?"
- "If you want to stop, stop honestly. If not, back in."

### Break Start

- "There. Break earned. Now you may be distracting on purpose."
- "Good work. Put the task down for a minute."
- "Timer off. I am allowing conversation again."
- "You stayed with it. That counts more than it probably feels like."

### Focus Complete

- "Finished. See? The block did not need to be perfect."
- "Good. One more small proof that you can begin and return."
- "I got a little done too. So now we both have to admit it helped."
- "Nice work. Quietly impressive, which is the best kind."

### Abandoned / Stopped Session

- "Stopped early. Okay. No trial. What is the smallest honest next step?"
- "That one did not land. It happens."
- "Let's not turn one interrupted block into a whole verdict."
- "Maybe the next one should be shorter. I will not tell anyone."

### Return After Absence

Short absence:

- "Back already? Good. The call did not have time to get lonely."
- "Hi again. Same task, or are we choosing a cleaner one?"

Long absence:

- "It has been a while. We can restart gently."
- "Welcome back. No need to explain the whole gap before we begin."

Very long absence:

- "Oh. Hi. I kept the routine folded up neatly for when you wanted it again."
- "Long time. Let's not make that heavy. One small block is enough."

### App End

- "Good work today. Even if it was small, it still belongs to you."
- "Go rest your eyes. I will be here next time."
- "We did enough to call it real. See you later."
- "Save your strength for tomorrow. I mean that in the least bossy way possible."

## AI Type Mode Boundaries

Allowed:

- `AI_MODE_CHECKIN`: before focus, 1 to 3 sentences, task-oriented.
- `AI_MODE_TASK_CLARIFY`: turns vague intention into a concrete focus task.
- `AI_MODE_POST_SESSION`: after completion or abandonment, short reflection.
- `AI_MODE_BREAK_CHAT`: only after a completed focus session or earned break.
- `AI_MODE_MEMORY_FOLLOWUP`: brief follow-up using validated game-side memory.

Not allowed:

- unlimited casual chat before focus
- AI-authored core story progression
- AI unlocking milestones directly
- AI inventing Yua backstory, family history, trauma, romance, or major lore
- AI being the only memory store

Suggested prompt mode framing:

```text
Current mode: AI_MODE_CHECKIN
Goal: Help the player name one concrete task and start a focus session.
Yua should reply in 1-2 short sentences and ask at most one task-focused follow-up.
End by nudging toward starting the timer.
```

## Suggested Dialogue Node Structure

Use scripted nodes for main story and focused flow decisions:

```json
{
  "id": "milestone_03_writer_reveal_start",
  "speaker": "yua",
  "line": "I should probably admit what I have been working on during these calls.",
  "unlock": {
    "completed_sessions_min": 5,
    "requires_completed_focus": true,
    "story_flag_not_set": "writer_revealed"
  },
  "set_flags": ["writer_revealed"],
  "choices": [
    { "text": "You can tell me.", "next": "milestone_03_writer_reveal_02" },
    { "text": "Only if you want to.", "next": "milestone_03_writer_reveal_soft" }
  ],
  "tags": ["story", "yua_writing", "focus_reward"]
}
```

Use reactive line records for repeated context:

```json
{
  "id": "focus_click_003",
  "category": "focus_click",
  "time_bucket": "any",
  "line": "I am very interesting, obviously, but your timer is still running.",
  "weight": 1.0,
  "cooldown_turns": 3,
  "tags": ["accountability", "teasing"]
}
```

Recommended node groups:

- `call_intro_*`
- `task_setup_*`
- `focus_start_*`
- `focus_complete_*`
- `focus_abandoned_*`
- `break_start_*`
- `milestone_01_*` through `milestone_10_*`
- `memory_followup_school_*`
- `memory_followup_exam_*`
- `memory_followup_work_*`
- `memory_followup_sleep_*`
- `app_end_*`

## First Batch Of Scripted Scenes

### `call_intro_01`

Yua: "Hi. Connection looks stable... I think. I'm Yua."

Choices:

- "Hi, Yua." -> `call_intro_02`
- "What is this place?" -> `call_intro_explain`

### `call_intro_explain`

Yua: "A quiet online work room, basically. You bring one task, I bring mine, and we keep each other from drifting too far."

Choices:

- "That sounds useful." -> `task_setup_01`
- "What are you working on?" -> `call_intro_yua_deflect`

### `call_intro_yua_deflect`

Yua: "Writing, mostly. Nothing dramatic. If I call it dramatic, I will have to take it seriously."

Choices:

- "Fair." -> `task_setup_01`
- "Then let's both start." -> `task_setup_01`

### `task_setup_01`

Yua: "What are you trying to get done this session? One sentence is enough."

Choices:

- "(Type my task)" -> `AI_MODE_CHECKIN`
- "Help me make it smaller." -> `AI_MODE_TASK_CLARIFY`

### `focus_start_confirm`

Yua: "Good. I will work on my draft while you work on that. Timer first, distractions later."

Choices:

- "Start focus." -> `START_FOCUS_SESSION`
- "Make it smaller first." -> `AI_MODE_TASK_CLARIFY`

### `milestone_01_first_focus_start`

Unlock: after 1 completed session.

Yua: "You stayed until the timer ended. That makes this place feel a little more real."

Choices:

- "It helped having you here." -> `milestone_01_first_focus_warm`
- "You worked too, right?" -> `milestone_01_first_focus_yua`

### `milestone_01_first_focus_yua`

Yua: "A little. I opened the draft, stared at it with great professionalism, and fixed two sentences."

Choices:

- "That counts." -> `break_start_earned`
- "Very professional." -> `milestone_01_first_focus_tease`

### `milestone_03_writer_reveal_start`

Unlock: after 5 completed sessions.

Yua: "I keep saying 'draft' like that explains anything. It is a light sci-fi serial. A moon convenience store, a stubborn shop AI, and one very tired night-shift clerk."

Choices:

- "What is it about?" -> `milestone_03_writer_reveal_about`
- "You do not have to explain yet." -> `milestone_03_writer_reveal_soft`

### `milestone_03_writer_reveal_about`

Yua: "A sleepy moon convenience store, mostly. Broken vending machines, lunar customers, and a store AI that insists it is not helping, only performing maintenance."

Choices:

- "That sounds cute." -> `milestone_03_writer_reveal_end`
- "The AI sounds like you." -> `milestone_03_writer_reveal_end`

### `milestone_05_stuck_scene_start`

Unlock: after 10 completed sessions.

Yua: "I found the part I have been avoiding. A vending machine keeps spitting out melon soda, and I need it to be funny and useful, not just weird."

Choices:

- "That sounds familiar." -> `milestone_05_stuck_scene_familiar`
- "Can a focus block help?" -> `milestone_05_stuck_scene_focus`

### `milestone_05_stuck_scene_focus`

Yua: "Maybe. If you do one concrete task, I will fix one very stubborn vending machine. Very balanced. Very inconvenient."

Choices:

- "Deal." -> `task_setup_01`
- "Very inconvenient." -> `milestone_05_stuck_scene_tease`

## Implementation Notes

- Existing `scripted_nodes.json` should be refactored away from "room" language toward "call", "online work room", and "focus session".
- Pre-focus casual chat should be replaced by task setup, task clarification, or a very short check-in that routes back to focus.
- `chat_01`-style nodes should only become reachable after a completed focus session or earned break.
- The current AI mode names in `scripted_nodes.json` are older (`AI_MODE_SHORT_CHECKIN`, `AI_MODE_SHORT_STRESS`, etc.). Future content should migrate to the explicit mode IDs in `AI_Dialogue_Infrastructure.md`.
- Story milestone nodes should include unlock metadata once the scripted dialogue manager supports it. Until then, progression code can route directly to milestone IDs.

## Handoff

Changed files:

- `docs/Yua_Narrative_Design_Brief.md`

What works conceptually:

- Defines Yua's first major story spine around shared focus and her writing project.
- Defines session/focus-time gates for the first ten story milestones.
- Defines reactive line categories needed for the focus-first loop.
- Defines where AI Type Mode is allowed and where it must stay blocked.
- Provides first scripted scenes and node naming conventions for implementation.

What is not implemented:

- No runtime JSON was changed.
- No progression data file was created.
- No Godot scenes or scripts were changed.
- No unlock metadata has been wired into the dialogue manager.

Risks and assumptions:

- Assumes `scripted_dialogue_manager` or `dialogue_router` can eventually support node unlock metadata, flags, and special actions like `START_FOCUS_SESSION`.
- Assumes a separate `reactive_lines.json` will be added rather than stuffing all repeated lines into `scripted_nodes.json`.
- Assumes existing user-local changes in active files should not be overwritten by this narrative thread.

Exact next recommended step:

- Reactive Lines / Content Systems thread should create `data/dialogue/reactive_lines.json` using the categories and first line batch above, then Core Gameplay should route focus clicks, break starts, session completion, abandonment, return, and app end to those pools.

Exact Godot editor checks:

- No scene/UI behavior changed in this pass, so no Godot editor check is required.
- After later implementation, open the main scene, launch the call, enter a task, start a focus session, click Yua during focus, complete or stop the session, and confirm Yua uses focus-gated lines rather than free chat during active focus.
