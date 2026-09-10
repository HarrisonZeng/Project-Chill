# Reproduce the audition set

From PowerShell in the project directory:

```powershell
$env:MINIMAX_API_KEY = [Environment]::GetEnvironmentVariable('MINIMAX_API_KEY', 'User')
node tools/voice/generate_auditions.mjs
```

Uses Node + the installed mmx-cli. Reads a credential from the environment;
never writes it. Standard synthesis uses mmx; voice design and delivery emotions
use MiniMax's documented HTTP API. All files remain local unless you publish them.

The manifest records voice prompts, spoken text and parameters. A-D hold the
text/speed constant; E-F change the voice-design prompt; G-I explore delivery;
English/Japanese each compare the same custom voice with a stock native voice.

Open `scenes/tools/voice_audition.tscn` in Godot and F6 to listen.
See `docs/YUA_VOICE_ARCHITECTURE.md` for integration and checks.
