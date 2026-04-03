---
name: publish
description: Bundle and upload research session artifacts to theoria.shehral.com
argument-hint: "[session-name]"
disable-model-invocation: true
effort: high
---

# Theoria Publish

Publish a research session's artifacts to theoria.shehral.com.

## Pre-flight

### Auth Token
!`cat "$HOME/.theoria/auth.json" 2>/dev/null | grep -o '"token":"[^"]*"' || echo "NO_AUTH: Run /theoria:login first to authenticate."`

### Available Sessions
!`ls .theoria/sessions/ 2>/dev/null | grep -v archive || echo "No sessions found in this project."`

### Taste Profile
!`cat "$HOME/.theoria/taste.json" 2>/dev/null | grep -o '"name":"[^"]*"' || echo "No taste profile."`

## Instructions

### Step 1: Select Session

If $ARGUMENTS specifies a session name, use that. Otherwise, list available sessions and ask the user which one to publish.

Read the session's `state.json`:
```bash
cat ".theoria/sessions/<slug>/state.json"
```

Verify the session has completed at least through the WRITE stage. Check that `completed_stages` includes "WRITE". If not:
> This session hasn't produced a paper yet. Run `/theoria:explore` or `/theoria:resume` to complete it first.

### Step 2: Check Auth

Read the auth token from `~/.theoria/auth.json`. If the file doesn't exist or has no token:
> No auth token found. Run `/theoria:login` to authenticate with theoria.shehral.com first.

### Step 3: Inventory Available Artifacts

Check which artifacts exist:

```bash
SLUG="<session-slug>"
SESSION=".theoria/sessions/$SLUG"

# Paper
[ -f "$SESSION/paper/main.pdf" ] && echo "PAPER: available" || echo "PAPER: not found"
[ -f "$SESSION/paper/main.tex" ] && echo "TEX: available" || echo "TEX: not found"

# Guide
[ -f "$SESSION/guides/guide.pdf" ] && echo "GUIDE_PDF: available" || echo "GUIDE_PDF: not found"
[ -f "$SESSION/guides/field-landscape.md" ] && echo "GUIDE_MD: available" || echo "GUIDE_MD: not found"

# Implementation
[ -d ".theoria/implementations/$SLUG" ] && echo "IMPLEMENTATION: available" || echo "IMPLEMENTATION: not found"
```

Present to the user:
```
Available artifacts for "<session topic>":
  [x] Paper (PDF + LaTeX source)
  [x] Understanding Guide (educational companion)
  [ ] Implementation (not found — run /theoria:implement to create)

Which would you like to publish? (all / paper / guide / or pick individually)
```

Wait for user selection.

### Step 4: Build Publish Bundle

Construct the v1.0.0 publish bundle JSON. Read data from session outputs:

**Session metadata** — from `state.json` and taste profile:
- `id`: session slug
- `title`: from paper title or state.json topic
- `abstract`: from the paper's abstract section (grep from main.tex between `\begin{abstract}` and `\end{abstract}`)
- `authorName`: from `~/.theoria/taste.json` → `researcher.name`
- `authorEmail`: from `~/.theoria/taste.json` → `researcher.email` (optional)
- `domain`: from `~/.theoria/taste.json` → `researcher.domains[0]`
- `tags`: from session topic words + domain
- `keyFinding`: from synthesize stage (first claim from claims.json or assessment summary)

**Paper bundle** (if selected):
- `title`: paper title
- `abstract`: extracted from main.tex
- `venue`: from taste profile `preferences.venues[0]` or "generic"
- `pdfBase64`: base64-encode the PDF:
  ```bash
  base64 -i ".theoria/sessions/$SLUG/paper/main.pdf"
  ```
- `texSource`: read the raw .tex file:
  ```bash
  cat ".theoria/sessions/$SLUG/paper/main.tex"
  ```
- `citations`: read from `orient/papers.json` and map to the citation schema:
  ```json
  [{"id": "bibtex_key", "title": "...", "authors": ["..."], "year": 2024, "venue": "...", "arxivId": "..."}]
  ```

**Guide bundle** (if selected):
- `title`: "Understanding Guide: <topic>"
- `mdxContent`: concatenate all guide markdown files (field-landscape.md, key-concepts.md, decision-log.md, methodology.md) into one MDX document with section headers
- `estimatedReadTime`: estimate from word count (roughly 200 words/minute)

**Implementation bundle** (if selected):
- `title`: "Implementation: <paper title>"
- `language`: "python" (default) or from implementation metadata
- `readmeContent`: read README.md from implementation directory
- `codeFiles`: read all .py files from implementation src/ directory:
  ```json
  [{"path": "model.py", "content": "..."}, {"path": "train.py", "content": "..."}]
  ```

### Step 5: Publish

Construct the full bundle as JSON and POST it:

```bash
TOKEN=$(cat "$HOME/.theoria/auth.json" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Write bundle to temp file (too large for inline curl)
# The bundle JSON should already be written to a temp file by this point

curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/theoria-publish-bundle.json \
  "https://theoria.shehral.com/api/publish"
```

Note: The bundle can be large (PDF is base64-encoded). Write it to `/tmp/theoria-publish-bundle.json` first, then POST with `-d @file`.

### Step 6: Handle Response

Parse the response:

**200 — Success:**
```json
{
  "success": true,
  "urls": {
    "session": "https://theoria.shehral.com/sessions/<id>",
    "paper": "https://theoria.shehral.com/papers/<id>",
    "guide": "https://theoria.shehral.com/guides/<id>",
    "implementation": "https://theoria.shehral.com/implementations/<id>"
  }
}
```

Show the user:
```
Published successfully!

  Session:        https://theoria.shehral.com/sessions/<id>
  Paper:          https://theoria.shehral.com/papers/<id>
  Guide:          https://theoria.shehral.com/guides/<id>
  Implementation: https://theoria.shehral.com/implementations/<id>
```

**401 — Unauthorized:**
> Your auth token is invalid or expired. Run `/theoria:login` to re-authenticate.

**400 — Validation Error:**
Show the specific errors from the response body. Common issues:
- Missing required fields
- Invalid PDF encoding
- Session already published (ask if they want to update)

**500 — Server Error:**
> Server error. Try again in a few minutes. If the problem persists, check https://theoria.shehral.com for status.

### Step 7: Update Session State

On successful publish, update the session's state.json:

```bash
# Add publish metadata to state.json
python3 -c "
import json
with open('.theoria/sessions/$SLUG/state.json') as f:
    state = json.load(f)
state['published_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
state['published_urls'] = {
    'session': '<session_url>',
    'paper': '<paper_url>',
    'guide': '<guide_url>',
    'implementation': '<implementation_url>'
}
with open('.theoria/sessions/$SLUG/state.json', 'w') as f:
    json.dump(state, f, indent=2)
print('Session state updated with publish metadata.')
"
```

### Step 8: Clean Up

```bash
rm -f /tmp/theoria-publish-bundle.json
```
