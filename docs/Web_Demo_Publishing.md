# Publishing the Web Demo

How to put a playable Project Chill in the browser, on a link you can send to
friends and supporters, that updates itself whenever you push new work.

**The short version:** the game is exported to a browser build by GitHub, then
uploaded to an itch.io page. You never run the export yourself. You push your
work to `main`, wait about three minutes, and the link is new.

**The live demo:** <https://hzen666.itch.io/project-relax> — set up 2026-08-13.
The one-time setup below is already done; it is kept as a record of how, and for
if the page ever has to be rebuilt.

---

## Why itch.io

- Your friends need a link and nothing else. No download, no install, no
  "unknown publisher" warning from Windows.
- The page can be **private** — restricted to people with a password or a secret
  link — so a rough demo isn't sitting in public.
- The URL never changes when you update. People can bookmark it.
- It handles the awkward browser-hosting details (correct file types, gzip) that
  a plain web host gets wrong.

---

## One-time setup (about 15 minutes)

You only do this once. After that, publishing is automatic.

### 1. Make the itch.io page

1. Make an account at <https://itch.io> if you don't have one.
2. Go to <https://itch.io/game/new>.
3. Fill in:
   - **Title** — e.g. `Project Chill`
   - **Project URL** — the last part of the web address. Write down what you
     choose; you need it in step 3. If you pick `project-chill` and your
     username is `yuadev`, your link will be `https://yuadev.itch.io/project-chill`.
   - **Kind of project** — choose **HTML**.
   - **Uploads** — skip this entirely. GitHub uploads the game for you.
4. Under **Embed options**:
   - **Viewport dimensions**: `1600` × `900`
   - Tick **Fullscreen button**
   - Tick **Mobile friendly** only if you want phone visitors; the layout is
     built for a desktop-sized window, so it will be cramped on a phone.
   - Leave **SharedArrayBuffer support** switched **off**. The build is made
     without threads on purpose so it works without it.
5. Under **Visibility & access**, choose **Restricted** and either set a
   password or add specific itch.io accounts. This is the setting that keeps the
   demo to your friends and supporters.
6. Click **Save**.

### 2. Get your itch.io API key

1. Go to <https://itch.io/user/settings/api-keys>.
2. Click **Generate new API key**.
3. Copy the long string of characters. Treat it like a password.

### 3. Tell GitHub about it

1. In this repository on GitHub, go to
   **Settings → Secrets and variables → Actions → New repository secret**.
   - **Name**: `BUTLER_API_KEY`
   - **Secret**: paste the key from step 2
   - Click **Add secret**.
2. Open `.github/workflows/publish-web-demo.yml` and edit the two lines near the
   top so they match the page you made in step 1:

   ```yaml
   ITCH_USER: yuadev          # your itch.io username
   ITCH_GAME: project-chill   # the Project URL you chose
   ```

That's the whole setup.

---

## Publishing an update

Push your work to `main`. That's it.

GitHub rebuilds the browser version and uploads it. It takes roughly three
minutes. To watch it happen, open the **Actions** tab in the repository — a
green tick means the demo is live with your latest changes.

You can also publish without pushing: **Actions → Publish web demo → Run
workflow**.

If a run fails, the red entry in the Actions tab will say which step broke.
Nothing is uploaded when a build fails, so a broken build can never replace a
working demo.

---

## Things worth knowing

**Your uncommitted work is not in the demo.** The build is made from what is on
GitHub, not from what is on your computer. If you changed dialogue in Godot but
haven't committed and pushed it, the browser version will still show the old
lines. This is the single most likely reason for "I fixed that already, why is
it still wrong?"

**Saves live in the browser.** Each player's progress is stored in their own
browser, per device. Clearing site data wipes it, and a player who opens the
link on their phone and then their laptop will have two separate saves. Nothing
is stored on a server.

**The AI replies are the built-in mock ones.** The AI provider needs an API key
from the environment, and there is no such key in a browser build — so it falls
back to the scripted mock replies automatically. This is deliberate: a real key
shipped in a browser build would be readable by anyone who opens the page, and
anyone could then spend your credits. Do not add one to the workflow.

**The debug bar is hidden.** The episode jumper, the save reset, and the
"3 秒试玩" timer option only appear in the editor and in debug builds, so
players can't skip through the story. They still work normally when you press
F5 in Godot.

**First load is about 25 MB.** Fine on wifi, noticeable on mobile data. Most of
it is the game engine itself, which the browser caches after the first visit.

---

## If you want to shrink the download later

`export_presets.cfg` already leaves out the unused material: `assets/bgm/archive/`,
`assets/art/concepts/`, `assets/video/`, and the three music tracks not currently
in the playlist (`track_city_pop_v2`, `track_neo_soul`, `track_piano_trio`).

**If you add one of those three tracks to the playlist in Godot, remove it from
the `exclude_filter` line in `export_presets.cfg`** — otherwise the game will
look for a track that isn't in the build.

The remaining music is about 11 MB of the download. Re-exporting those three
MP3s at a lower bitrate would be the next real saving.

---

## The Chinese font, and why it's bundled

The theme asks for LXGW WenKai / PingFang SC / Microsoft YaHei by name. That
works on your machine because those fonts are installed on it. **A browser build
has no access to installed fonts**, so every Chinese character would render as
an empty box.

So the repo carries `assets/fonts/chill_kai_gb.woff2` — a cut-down copy of LXGW
WenKai (1.5 MB, about 7,900 characters: all of GB2312 plus everything the script
uses). It is wired into the theme as a *fallback*, so on your PC nothing changes
and in the browser it fills the gap.

Two characters had to be swapped because that font has no glyph for them: the
close button `✕` became `×`, and the log button `📜` became `▤`.

To rebuild the font (only needed if characters ever go missing):

```
pip install fonttools brotli
python3 tools/fonts/build_web_font.py
```

The build fails on purpose if the font is missing from the export, so this can't
silently regress.

---

## Checking a build yourself

Open the **Actions** tab, click a finished run, and download the `web-demo`
artifact — that's the exact build that went to itch.io. It cannot be opened by
double-clicking `index.html`; browsers block that. Serve it instead:

```
cd web-demo
python3 -m http.server 8000
```

Then open <http://127.0.0.1:8000>.
