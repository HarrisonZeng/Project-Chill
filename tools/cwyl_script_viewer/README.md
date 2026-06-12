# CWYL Script Viewer

This is a read-only browser viewer for the extracted CWYL script data in:

```text
tmp/cwyl_extract/clean/
```

It is meant for quickly studying the reference structure: episode order, unlock
metadata, player choices, and the response branches caused by those choices.

## Open It

Best local method from the project root:

```powershell
node tools/cwyl_script_viewer/serve_viewer.js
```

Then open:

```text
http://127.0.0.1:8787/tools/cwyl_script_viewer/cwyl_script_viewer.html
```

If you prefer Python and have it on PATH, this also works:

```powershell
python -m http.server 8787
```

Then open:

```text
http://localhost:8787/tools/cwyl_script_viewer/cwyl_script_viewer.html
```

The viewer will try to auto-load:

- `scenario_readable.json`
- `LocalizationMaster.json`
- `ScenarioGroupMaster.json`

If auto-load is blocked by the browser, click **Load files** and select those
three files from `tmp/cwyl_extract/clean/`.

## Share To Phone

Use the stable standalone file:

```text
tools/cwyl_script_viewer/cwyl_script_viewer_stable.html
```

That file has the current CWYL data embedded, so it can be sent to an iPhone and
opened without the rest of the repo.

You can also open the live viewer and click **Save snapshot** to download another
standalone HTML file from the browser.

## Updating Script Data

When the extracted JSON changes, reload the browser page. The viewer reads the
current JSON files and rebuilds the episode list and branches automatically.

The stable file is intentionally frozen. Rebuild it after changing the source
data:

```powershell
node tools/cwyl_script_viewer/build_stable_html.js
```

Then verify it:

```powershell
node tools/cwyl_script_viewer/verify_viewer.js
```
