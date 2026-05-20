# Vertical Slice 01 Spec: Co-Presence First Session

## Goal

The first polished slice should prove: I showed up, engaged however I liked, Yua was present with her own work, and the game remembered me.

## Exact Flow

1. Launch the game.
   - Yua appears as the main subject of a cozy online co-working call.
   - Save touched: `last_seen_at`, `profile_version`, return metadata.
   - Required blocker first: fix the split-save bug so `main_scene.gd` and `memory_manager.gd` read/write one profile file, not both `user://player_profile.json` and `user://data/saves/player_profile.json`.

2. Time-aware greeting.
   - Yua greets based on morning/noon/evening/night and return rhythm.
   - She does not ask for a task as a requirement.
   - Save touched: `last_greeting_bucket`, `return_count` or equivalent return rhythm field.

3. Cozy idle co-presence.
   - Yua is visibly present and doing her own thing: reading, typing, looking back at the call, pausing.
   - The player can stay here without pressure.
   - Save touched: accumulated app time may be tracked, but pure idle time does not advance story or relationship progression.

4. Branch A: player starts optional focus.
   - Player may start the timer with or without entering a task.
   - If a task is entered, Yua acknowledges it lightly as a peer: "你做那个，我也把这段改完。"
   - If no task is entered, Yua still accepts the session: "不写任务也可以。那就先一起安静一会儿。"
   - On completion, Yua reacts as someone who was also working, not as a grader.
   - This is the branch that advances story/relationship progression: accumulated focus time and completed sessions move `yua_openness` and `story_flags`, and fuel Yua's writing payoff.
   - Save touched: `focus_started_count`, `completed_focus_count`, `total_focus_seconds`, optional `last_task_text`, `engaged_interaction_count`, `engaged_time_seconds`, `yua_openness`, `story_flags`.

5. Branch B: player engages without focus.
   - Player may click Yua, send one bounded Type Mode line, or watch a short self-talk beat.
   - This is remembered and adds small ambient warmth, but it does not advance story/relationship milestones - those come from focus time.
   - Yua can share a small honest line about her own work, then returns to quiet.
   - Save touched: `engaged_interaction_count`, `engaged_time_seconds`, `last_meaningful_interaction_at`, memory tags if player text contains useful validated context. Does NOT advance `yua_openness` milestones or `story_flags`.

6. Branch C: player does nothing.
   - The app remains pleasant and alive.
   - Yua may idle visually, but no story or relationship progress advances.
   - Save touched: `last_seen_at` only, plus non-progression UI/session state if needed.

7. Save and relaunch.
   - On relaunch, Yua recognizes return context without implying the player owes an explanation.
   - Example: "你又来了。那我把这边的文档也打开。"
   - Save touched: one profile file containing engagement, focus, memory, story flags, timestamps, and UI preferences.

## Save Fields

All progression fields must live in one profile file after migration:

- `profile_version`
- `last_seen_at`
- `last_meaningful_interaction_at`
- `return_count` or return rhythm summary
- `engaged_interaction_count`
- `engaged_time_seconds`
- `focus_started_count`
- `completed_focus_count`
- `total_focus_seconds`
- `current_focus_task` or `last_task_text`, optional and nullable
- `memory_tags` / validated memory entries
- `story_flags`
- `current_story_milestone`
- `yua_openness` or relationship progress
- `corrupted_save_recovery` metadata if recovery was needed

`ScriptedDialogueManager._register_node` must preserve `unlock`, `set_flags`, `tags`, and `speaker` before milestone routing can rely on JSON metadata.

## UI States

### Idle / Co-Presence

- Visible: Yua/video stage as the largest visual subject, subtle date/time, compact call controls, Type Mode entry, optional focus control.
- Hidden or minimized: dev toolbar, test/debug controls, bulky task panel unless opened.
- The focus timer is one tool, not the hero control. The default screen fantasy is "Yua is here working too."

### Focus Active

- Visible: Yua, compact timer status, stop/pause control, optional current task if provided.
- Limited: Type Mode and click reactions should stay brief because both people are working.
- Hidden or disabled: long chat choices, distracting debug/test panels.

### Chat Active

- Visible: dialogue panel and bounded Type Mode.
- Yua can answer briefly, then naturally return to her own work.
- This state can be reached through meaningful engagement, not only after a completed focus session.

## AI Calls Allowed

- Time-aware greeting: scripted first; AI optional only for a short variant if fallback exists.
- Type Mode: allowed after the player actively sends text. Reply length 1-3 sentences.
- Task understanding: allowed only if the player volunteers a task or asks for help making it smaller.
- Post-focus reflection: allowed after focus completion or abandonment, but must not quiz the player.
- Memory extraction: allowed as a proposal layer only; game-side validation decides what persists.
- Fallback: if AI fails, use scripted lines and keep the flow playable.

AI must not unlock story, invent major Yua lore, require task entry, or become unlimited chat. The natural limit is that Yua is busy with her own work.

## Yua Payoff Beat

Trigger for slice: a completed focus session (and/or a small threshold of accumulated focus time) in the first session. Focus is the required driver of this beat; light interactions alone do not trigger it. The payoff reads as Yua pushing through her own avoidance because the player put in focused time alongside her. Exact thresholds are PROPOSED - confirm with owner.

Sample Mandarin lines:

- "刚才你在这边的时候，我把那个空了很久的文件打开了。"
- "不是很大的进展。只是……我终于没有继续假装它不存在。"
- "我还不太敢说它到底是什么。先当成一个很小、很别扭的故事吧。"
- "等我多改一点，也许可以给你看一小段。现在还不行，我会害羞。"

The concrete creative project is to be defined by the narrative session; this spec only demonstrates the shape and tone of the co-presence payoff.

## Verification Checklist

1. First launch shows Yua in a call-like composition with a time-aware greeting and no mandatory task prompt.
2. Player can remain in idle co-presence without being forced into focus.
3. Clicking Yua or sending a Type Mode line is remembered and adds ambient warmth, but does NOT advance story milestones, `yua_openness`, or story flags on its own.
4. Pure AFK idling does not advance `engaged_interaction_count`, `yua_openness`, or story flags.
5. Player can start focus with no task text, complete it, and see focus progress persist.
6. Player can enter a task voluntarily; memory extraction handles it as optional context.
7. Completed focus / accumulated focus time is the required route to the slice payoff; without it the payoff beat does not trigger.
8. Relaunch recognizes the player from the one consolidated profile file.
9. AI failure still leaves scripted greeting, idle, focus, Type Mode fallback, and relaunch recognition working.
10. Known asset warning is visible in implementation docs: `assets/bgm/Persona 5 chill mix - GVirusInfected.mp3` is placeholder only and must be replaced before Steam.
11. If `assets/video/yua_idle_loop.ogv` does not appear despite `VideoStage` wiring, treat it as an import/playback/composition bug, not a missing asset.
