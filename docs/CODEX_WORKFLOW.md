# Codex Workflow

## Branch Rules

- stable branch: `main`
- integration branch: optional, created by the manager thread when needed
- worker branch naming: `codex/<thread-name>`

Examples:

- `codex/scriptwriting`
- `codex/memory-session`
- `codex/ai-prompting`
- `codex/reactive-lines`
- `codex/ui-scene`

## Worker Order

Use this order unless the manager thread explicitly changes it:

1. Scriptwriting / Narrative
2. Memory / Save / Session
3. AI / Prompting
4. Reactive Lines / Content Systems
5. Core Gameplay
6. UI / Scene Design
7. QA / Playtest

## Worker Handoff Template

Every worker should return:

- changed files
- what now works
- what is intentionally not implemented
- risks or assumptions
- exact next recommended step
- exact Godot checks if applicable

## Manager Checklist

For each worker handoff:

1. verify no movement/player-avatar logic was introduced
2. verify node-path changes are documented
3. verify AI is still optional and bounded
4. verify scripted story/progression remains primary
5. verify progression is focus-session based, not calendar-day based
6. verify casual chat is restricted during active focus
7. merge or reject with a short written rationale

## Manual Godot Checkpoints

After any accepted merge affecting scenes or flow:

1. open the main scene
2. confirm Yua appears in the online call composition
3. enter a task/check-in
4. start a focus session
5. click Yua during focus and confirm an accountability line
6. finish or stop the session
7. confirm progress/session state updates
8. test AI check-in/reflection once if affected
9. relaunch and confirm any intended follow-up behavior

## Travel / Machine Transfer

When moving to a new machine:

1. clone the repo
2. read `AGENTS.md`
3. read `docs/CODEX_TAKEOVER_PLAYBOOK.md`
4. read `docs/THREAD_HANDOFF.md`
5. start a manager thread using the prompt from `docs/CODEX_THREAD_PROMPTS.md`
