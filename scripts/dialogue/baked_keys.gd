extends RefCounted

# Build-time API keys for builds that have no environment variables to read.
#
# The browser build is the only thing that needs this. On the owner's PC the
# game reads MINIMAX_API_KEY from the Windows environment; a page running in
# someone else's browser has no environment, so without a key baked into the
# build the web demo falls back to the offline mock replies.
#
# ── THIS FILE MUST STAY EMPTY IN GIT ────────────────────────────────────────
# The value below is written by .github/workflows/publish-web-demo.yml from the
# MINIMAX_API_KEY repository secret, in the build runner only, and is never
# committed. CI refuses to build if a key is found committed here.
#
# Do not paste a key in and commit it: this repository is public, so the key
# would be readable by anyone on earth, immediately and permanently.
# ─────────────────────────────────────────────────────────────────────────────
#
# Understand the trade-off even when CI fills it in. A key inside a browser
# build is readable by anyone who can load the page and look at the downloaded
# files. The itch.io page password is the only thing limiting who that is. This
# is an accepted risk for a demo shared with close family and friends. If the
# demo is ever made public, or the audience grows past people you know, remove
# the secret and move the key behind a small server-side proxy instead.
const MINIMAX_API_KEY := ""
