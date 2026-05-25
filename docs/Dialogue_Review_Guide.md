# Dialogue Review Guide

This guide is for sharing Project Chill's conversation script with friends who do not use Godot or code editors.

## What To Send Friends

Send these two files:

1. `tools/dialogue_viewer/dialogue_viewer.html`
2. `data/dialogue/scripted_nodes.json`

Optional:

- `data/dialogue/reactive_lines.json`, if you want them to also see short repeatable focus/click lines.

Friends open the HTML file in a browser, then load the JSON file. The viewer reads the current script file each time, so it keeps working as the script changes.

## Friend Steps

1. Open `dialogue_viewer.html` in Chrome, Edge, or Firefox.
2. Click `Load scripted_nodes.json`.
3. Choose the `scripted_nodes.json` file.
4. Click nodes in the left list or the flow map.
5. Use Search to find a line, tag, unlock, choice, or node id.
6. Turn on `Review mode` to suggest line edits, choice edits, unlock edits, tags, or comments.
7. Click `Export review notes` when done.
8. If they made direct script edits, also click `Export revised JSON`.

## What The Viewer Shows

- `Conversation Flow`: how one node links to another through choices.
- `Node Details`: the line text, speaker, choices, unlock gate, tags, and flags.
- `Unlocks`: nodes with deterministic progression gates.
- `Flags`: nodes that set story or relationship state.
- `Issues`: missing links or orphan nodes that may need checking.
- `Changed`: nodes with friend edits or comments in review mode.

## Track Changes Workflow

Use this workflow when collecting friend feedback:

1. Give each friend the same `scripted_nodes.json`.
2. Ask them to turn on `Review mode`.
3. They can edit text directly or leave comments without touching the game project.
4. They export `dialogue_review_notes.md`.
5. You review the notes and decide what to apply to the real script.
6. If you trust their direct edits, compare their `scripted_nodes.reviewed.json` against the current file before replacing anything.

The HTML viewer does not write into the project by itself. That is intentional: friends can freely suggest changes without accidentally breaking the game.

## Creating A One-File Snapshot

If you want one easy file to send:

1. Open the viewer.
2. Load `scripted_nodes.json`.
3. Click `Export shareable HTML`.
4. Send the exported `dialogue_viewer_snapshot.html`.

That snapshot contains the loaded script at the moment you exported it. For the newest script later, export a new snapshot or ask friends to load the newest JSON.

## Notes For Script Editing

- `choices[].next` should point to another node id, an `ACTION_...` target, an `AI_MODE_...` target, or an `EXIT...` target.
- Story unlocks should stay deterministic and based on focus progress, not casual chat.
- Light interactions can be warm and remembered, but they should not unlock major Yua story milestones by themselves.
- Yua should feel like a peer working beside the player, not a teacher or supervisor.
