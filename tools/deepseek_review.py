import os
import sys
from pathlib import Path

sys.path.insert(0, "D:/Project Chill/project-chill/tools/python_libs")

from openai import APIConnectionError, APIStatusError, APITimeoutError, OpenAI

PYTHON_HINT = (
    "& 'C:\\Users\\zengh\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe' "
    "tools\\deepseek_review.py scripts\\core\\main_scene.gd"
)

if len(sys.argv) < 2:
    print("Tell me which file to review.")
    print("Example:")
    print(PYTHON_HINT)
    sys.exit(1)

script_path = Path(sys.argv[1])

if not script_path.exists():
    print(f"File not found: {script_path}")
    sys.exit(1)

script_text = script_path.read_text(encoding="utf-8")
print(f"Loaded file: {script_path}")
print("Calling DeepSeek now. This can take 10-60 seconds...")

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    print("DEEPSEEK_API_KEY is not set in this PowerShell window.")
    print('First run: $env:DEEPSEEK_API_KEY="paste-your-key-here"')
    sys.exit(1)

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com",
    timeout=60.0,
)

prompt = f"""
You are reviewing a Godot 4 project file for Project Chill.

Project Chill direction:
- 2D fixed-camera online focus companion game.
- Yua is a warm peer presence, not a teacher or supervisor.
- Focus is optional and player-initiated.
- Completed focus sessions and total focus time drive story progression.
- Light chat/clicking can add warmth, but should not unlock major story milestones.
- Scripted dialogue is the backbone.
- AI should be bounded, optional, and fail-safe.
- Avoid large rewrites unless necessary.

Please review this file and give:
1. Bugs or risky behavior.
2. Places where the file conflicts with the Project Chill direction.
3. Small beginner-friendly improvements.
4. Suggested edits, but only if they are simple and low-risk.

File: {script_path}

```text
{script_text}
```
"""

try:
    response = client.chat.completions.create(
        model="deepseek-v4-pro",
        messages=[
            {
                "role": "system",
                "content": "You are a careful Godot 4 code and narrative reviewer. Be specific, practical, and concise.",
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],
        stream=False,
    )
except APITimeoutError:
    print("DeepSeek did not respond within 60 seconds. Try again, or review a smaller file.")
    sys.exit(1)
except APIConnectionError as error:
    print("Could not connect to DeepSeek. Check your internet connection or firewall.")
    print(error)
    sys.exit(1)
except APIStatusError as error:
    print(f"DeepSeek returned an error: HTTP {error.status_code}")
    print(error.response.text)
    sys.exit(1)

print("\nDeepSeek response:\n")
print(response.choices[0].message.content)
