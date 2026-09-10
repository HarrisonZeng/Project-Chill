# Yua voice auditions — round 2, 2026-09-10

Owner rejected round 1: insufficient anime/cute character, recital-like cadence,
and accents. Owner requested both 元气俏皮 and 慵懒可爱.

Four NEW designed voices, not pitch-shifted versions of round 1:
- A: 元气俏皮 / 清脆 — bright, springy, quick comic reactions.
- B: 元气俏皮 / 甜亮 — sweeter head resonance and expressive inflection.
- C: 慵懒可爱 / 软糯 — soft, relaxed, slightly slower; supported articulation.
- D: 慵懒可爱 / 小傲娇 — relaxed delivery with dry, lightly defiant humor.

All four design previews say the SAME sentence:
「我这次真的不打游戏了。真的。你按啊。」
Each also has one short acting sample with its own audition-only text. The acting
samples use speech-2.8-hd, Chinese language boost, zero pitch shift, and modest
speed/emotion settings. Full prompts and voice IDs are in the audition manifest.

These are intended directions, not listening-based claims of achieved quality.
No English or Japanese generated in this round: first establish the Chinese voice.
No changes to authored script, game casting or runtime code. Round 1 remains for
comparison; new candidates appear first in the Chinese tab.

Listen: open scenes/tools/voice_audition.tscn and press F6. Start with 二轮 A–D,
then the four / 表演 entries. Pick by native pronunciation, anime identity, cuteness,
and whether it sounds like she is reacting rather than reading.

Reproduce: node tools/voice/round2.mjs with MINIMAX_API_KEY in the environment.
It reuses successful samples and never saves the credential.

Verification: Godot import succeeded; 51/51 voice checks passed. All 31 clips decode (round 2 adds eight clips, about 39 seconds).
