# AI Dialogue Infrastructure

## 1. Goal

Provide robust AI support for a focus-first online companion game while preserving authored story progression and deterministic game-side memory.

AI should make Yua feel responsive during check-ins and reflections. It should not replace the focus loop or scripted story milestones.

## 2. Why Hybrid Works Best

Scripted dialogue gives:

- stable character voice
- authored story progression
- predictable unlocks
- safe QA
- reusable reactive line pools

AI dialogue gives:

- natural task check-ins
- personalized encouragement
- memory extraction from player text
- post-session reflection
- limited break chat after focus

Use scripted content as the backbone and AI as a bounded augmentation layer.

## 3. Runtime Flow

Primary focus loop:

1. Game enters call state.
2. Yua gives a scripted/time-aware greeting.
3. Player enters a task or answers a short check-in.
4. `memory_manager.gd` extracts deterministic memory candidates.
5. Optional AI check-in response is generated using persona, task, current mode, and memory context.
6. Player starts focus session.
7. During focus, route clicks to reactive "back to work" line pools, not open chat.
8. Session finishes or is abandoned.
9. Progression state updates completed sessions, total focus time, and milestone eligibility.
10. Yua gives scripted/reactive completion line.
11. If unlocked, player can enter break chat, reflection, or story milestone.
12. Save/profile state persists.

## 4. AI Modes

Use explicit mode IDs so prompts stay bounded.

Suggested modes:

- `AI_MODE_CHECKIN`: before focus, understand what the player is working on.
- `AI_MODE_TASK_CLARIFY`: help turn vague task text into a focus intention.
- `AI_MODE_POST_SESSION`: short reflection after a completed/abandoned session.
- `AI_MODE_BREAK_CHAT`: limited casual chat during unlocked breaks.
- `AI_MODE_MEMORY_FOLLOWUP`: ask about a remembered school/work/exam/sleep context.

Avoid general always-on chat before focus.

## 5. Suggested Data Contracts

### 5.1 Scripted Story Node

```json
{
  "id": "episode_01_start",
  "speaker": "yua",
  "line": "It is easier to start when someone else is starting too.",
  "unlock": {
    "completed_sessions_min": 1
  },
  "choices": [
    { "text": "Then let's start together.", "next": "focus_setup_01" },
    { "text": "What are you working on?", "next": "episode_01_yua_work" }
  ],
  "tags": ["story", "focus_partner"]
}
```

### 5.2 Reactive Line

```json
{
  "id": "click_work_001",
  "mode": "focus_work",
  "time_bucket": "any",
  "line": "Mm-mm. We are working right now.",
  "weight": 1.0,
  "tags": ["accountability"]
}
```

### 5.3 Memory Entry

```json
{
  "id": "mem_20260505_001",
  "fact": "User is working on computer science class material.",
  "topic": "school",
  "type": "task_context",
  "confidence": 0.9,
  "last_seen_at": "2026-05-05T20:10:00+08:00",
  "follow_up_tag": "ask_about_school",
  "expires_in_days": 14,
  "source_message": "I need to study for my computer science class."
}
```

### 5.4 Session State

```json
{
  "last_seen_at": "2026-05-05T20:10:00+08:00",
  "completed_sessions": 4,
  "total_focus_seconds": 7200,
  "current_task": "computer science homework",
  "last_session_result": "completed",
  "current_story_milestone": "episode_03_unlocked",
  "yua_writing_progress": 2,
  "pending_follow_ups": ["ask_about_school"],
  "recent_summary": "User has been studying computer science and prefers shorter focus blocks.",
  "memories": []
}
```

## 6. Memory Strategy

Use deterministic extraction first.

Rule examples:

- if text contains "school", "class", or "campus" -> topic `school`
- if text contains "exam", "test", "midterm", or "final" -> topic `exam`
- if text contains "work", "job", "shift", "deadline", or "project" -> topic `work`
- if text contains "sleep", "tired", "rest", "insomnia", or "nap" -> topic `sleep`
- if text contains focus duration preferences -> store preferred session length

Optional AI proposals can suggest additional memory, but `memory_manager.gd` must validate before accepting.

## 7. Prompt Assembly

Build prompt sections in this order:

1. Yua persona
2. current AI mode
3. current task/session context
4. progress summary: completed sessions, total focus time, current milestone
5. memory summary
6. runtime rules
7. current player message

Never send full conversation history by default.

## 8. AI Output Rules

AI replies should:

- stay in character as Yua
- be 1-3 sentences by default
- be voice-friendly even before voice is implemented
- support focus rather than distract from it
- ask at most one gentle follow-up
- return toward starting or resuming work

AI replies should not:

- invent Yua backstory or major lore
- say it is an AI/model
- unlock story directly
- promise real-world outcomes
- offer unlimited pre-focus conversation

## 9. API Boundary Design

Keep one adapter interface so providers can be swapped later:

- `generate_reply(request) -> DialogueResponse`
- optional future: `synthesize_voice(text, voice_id) -> AudioStream or file path`

Keep API keys out of scene files. Use local config/environment handling for prototype.

## 10. Voice Status

Voice is optional and fail-safe.

The current practical path is hybrid: scripted lines can use pre-generated clips from `assets/audio/voice_cache/`, while Type Mode replies remain text-first with a runtime cache path prepared for future TTS. Voice generation must not block dialogue, focus flow, scripted progression, or Type Mode fallback behavior.

See `docs/YUA_VOICE_ARCHITECTURE.md` for the current implementation and manual Godot setup steps.

## 11. Milestone Acceptance Test

Target test case:

1. User launches the call.
2. User enters: "I need to study for computer science."
3. Game stores a school/class memory tag.
4. User starts and completes a focus session.
5. Completed session count and total focus time persist.
6. Break chat or a scripted story milestone unlocks.
7. On a later launch, Yua can naturally reference the class context.

If this passes, AI, memory, and focus progression are working together correctly.
