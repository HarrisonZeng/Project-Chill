# AI Dialogue Infrastructure

## 1. Goal

Provide robust infrastructure for a mostly-scripted companion game that can optionally generate AI replies while preserving continuity through explicit memory.

## 2. Why Hybrid Works Best

Scripted dialogue gives:

- tone control
- narrative consistency
- predictable QA

AI dialogue gives:

- flexible free chat moments
- natural responses to custom user text

Use scripted as the backbone and AI as an augmentation layer.

## 3. Runtime Flow

1. User action arrives (choice click or typed message).
2. `dialogue_router.gd` decides path:
   - scripted node available -> scripted manager
   - AI mode enabled or fallback needed -> AI service
3. Response text returned.
4. `memory_manager.gd` extracts candidate facts.
5. `voice_manager.gd` resolves audio (prebaked or runtime TTS).
6. UI shows text and plays audio.
7. `session_manager.gd` persists updated state.

## 4. Suggested Data Contracts

### 4.1 Scripted node (JSON)

```json
{
  "id": "greeting_morning_01",
  "speaker": "companion",
  "text": "Good morning. Did you sleep well?",
  "choices": [
    { "id": "yes", "text": "Yeah, pretty well.", "next": "smalltalk_01" },
    { "id": "no", "text": "Not really.", "next": "comfort_01" },
    { "id": "ai_mode", "text": "(Type my own response)", "next": "AI_MODE" }
  ],
  "tags": ["greeting"]
}
```

### 4.2 Memory entry (JSON)

```json
{
  "id": "mem_20260312_001",
  "fact": "User will go to school tomorrow.",
  "topic": "school",
  "type": "plan",
  "confidence": 0.92,
  "last_seen_at": "2026-03-12T20:10:00+08:00",
  "follow_up_tag": "ask_about_school",
  "expires_in_days": 7
}
```

### 4.3 Session state (JSON)

```json
{
  "last_login_at": "2026-03-13T19:02:00+08:00",
  "last_node_id": "smalltalk_01",
  "pending_follow_ups": ["ask_about_school"],
  "recent_summary": "User mentioned school and exam preparation.",
  "memories": []
}
```

## 5. Memory Strategy That Actually Holds Up

Use explicit extraction rules before model-based extraction.

Rule examples:

- if text contains "go to school" or "school tomorrow" -> create `ask_about_school`
- if text contains "exam" -> create `ask_about_exam`

Optional second pass:

- AI can propose additional memories
- memory manager only accepts proposals that pass validation

This keeps memory consistent and reduces hallucinated facts.

## 6. Prompt Assembly (AI Mode)

Build prompt sections in this order:

1. persona profile (stable)
2. style constraints (short, warm, in-character)
3. safety boundaries
4. recent memory summary (short)
5. current user message

Do not send entire conversation logs by default.

## 7. Voice Pipeline

### Scripted lines

- pre-generate files during content build
- map line id -> audio file path

### AI lines

- runtime TTS request
- cache using `sha256(line_text + voice_id)`
- reuse cached audio on repeated lines

Fallback:

- if TTS fails, show text and play neutral UI sound

## 8. API Boundary Design

Create one adapter interface so provider can be swapped later:

- `generate_reply(request) -> DialogueResponse`
- `synthesize_voice(text, voice_id) -> AudioStream or file path`

Keep API keys out of scene files. Use local config/environment handling for prototype.

## 9. Minimal Script Skeletons

- `dialogue_router.gd`
- `scripted_dialogue_manager.gd`
- `ai_dialogue_service.gd`
- `memory_manager.gd`
- `session_manager.gd`
- `voice_manager.gd`

## 10. Milestone Acceptance Test

Your target test case:

1. User types: "I need to go to school tomorrow."
2. Game stores memory with `ask_about_school`.
3. User quits and relaunches.
4. First greeting includes school follow-up.
5. Character line has text and voice output.

If this passes, your core architecture is correct.
