---
name: implement
description: Implement a research paper as code — takes an arxiv URL or paper title and produces a citation-anchored Python implementation
argument-hint: "<arxiv URL, arxiv ID, or paper title>"
disable-model-invocation: true
effort: high
---

# Theoria Implement — Paper-to-Code Pipeline

The user wants to implement: **$ARGUMENTS**

You orchestrate a 5-stage pipeline that takes a research paper and produces a citation-anchored Python implementation where every line traces back to a specific paper section or is explicitly flagged as an unspecified choice.

---

## Pre-flight Checks

### Taste Profile
!`cat "$HOME/.theoria/taste.json" 2>/dev/null || echo "No taste profile found. Defaults will be used."`

### Active Theoria Session Context
!`ls ".theoria/sessions/" 2>/dev/null | tail -5 || echo "No active sessions."`

### Parse Arguments — Mode and Framework

```bash
ARGS="$ARGUMENTS"

# Detect mode
MODE="minimal"
if echo "$ARGS" | grep -q -- "--full"; then
  MODE="full"
  ARGS=$(echo "$ARGS" | sed 's/--full//')
fi
if echo "$ARGS" | grep -q -- "--educational"; then
  MODE="educational"
  ARGS=$(echo "$ARGS" | sed 's/--educational//')
fi

# Detect framework
FRAMEWORK="pytorch"
if echo "$ARGS" | grep -q -- "--jax"; then
  FRAMEWORK="jax"
  ARGS=$(echo "$ARGS" | sed 's/--jax//')
fi
if echo "$ARGS" | grep -q -- "--numpy"; then
  FRAMEWORK="numpy"
  ARGS=$(echo "$ARGS" | sed 's/--numpy//')
fi

# Clean remaining args (the paper identifier)
PAPER_INPUT=$(echo "$ARGS" | xargs)

echo "PAPER_INPUT=$PAPER_INPUT"
echo "MODE=$MODE"
echo "FRAMEWORK=$FRAMEWORK"
```

### Resolve Paper Identity

Determine the paper identifier type and normalize to an arXiv ID where possible:

```bash
PAPER_INPUT="<from above>"

# Check if it's an arxiv URL
if echo "$PAPER_INPUT" | grep -qE 'arxiv\.org/(abs|pdf)/'; then
  ARXIV_ID=$(echo "$PAPER_INPUT" | grep -oE '[0-9]{4}\.[0-9]{4,5}(v[0-9]+)?')
  echo "TYPE=arxiv_url"
  echo "ARXIV_ID=$ARXIV_ID"
# Check if it's a bare arxiv ID
elif echo "$PAPER_INPUT" | grep -qE '^[0-9]{4}\.[0-9]{4,5}(v[0-9]+)?$'; then
  ARXIV_ID="$PAPER_INPUT"
  echo "TYPE=arxiv_id"
  echo "ARXIV_ID=$ARXIV_ID"
# Otherwise treat as a title — need to search
else
  echo "TYPE=title"
  echo "TITLE=$PAPER_INPUT"
  echo "ARXIV_ID=unknown"
fi
```

If the type is `title`, use WebSearch to find the paper on arxiv:
- Search: `"$PAPER_INPUT" site:arxiv.org`
- Extract the arXiv ID from the first matching result URL

If still unresolved, present the search results and ask the user to confirm which paper.

### Check for Existing Session Data

If a Theoria session is active and the paper was already found during ORIENT, reuse that data:

```bash
# Search orient data for this paper
for f in ".theoria"/sessions/*/orient/papers.json; do
  if [ -f "$f" ]; then
    MATCH=$(python3 -c "
import json, sys
papers = json.load(open('$f'))
for p in papers:
    aid = p.get('arxiv_id', '')
    if aid and '$ARXIV_ID' != 'unknown' and aid == '$ARXIV_ID':
        print(json.dumps(p, indent=2))
        sys.exit(0)
" 2>/dev/null)
    if [ -n "$MATCH" ]; then
      echo "FOUND_IN_SESSION=$(dirname $(dirname $f))"
      echo "$MATCH"
      break
    fi
  fi
done
```

### Create Implementation Directory

```bash
# Generate slug from paper identifier
if [ "$ARXIV_ID" != "unknown" ]; then
  SLUG=$(echo "$ARXIV_ID" | tr '.' '-')
else
  SLUG=$(echo "$PAPER_INPUT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | head -c 40)
fi

IMPL_DIR=".theoria/implementations/$SLUG"
mkdir -p "$IMPL_DIR"/{paper,src,notebooks}
echo "IMPL_DIR=$IMPL_DIR"
echo "SLUG=$SLUG"
```

---

## Stage 1: ACQUIRE — Fetch the Paper

**Goal:** Obtain the full text of the paper and locate any official code repository.

### 1a. Fetch paper text (ar5iv HTML first)

Try ar5iv for clean HTML text:

```
https://ar5iv.labs.arxiv.org/html/<ARXIV_ID>
```

Use WebFetch to retrieve the page. If successful, extract the paper content and save it:

```bash
cat > "$IMPL_DIR/paper/content.md" << 'PAPER_EOF'
<extracted paper text with section headers preserved>
PAPER_EOF
echo "Paper text saved (ar5iv HTML)."
```

### 1b. Fall back to PDF if ar5iv fails

If ar5iv returns 404, rendering errors, or the paper has no arXiv ID:

```bash
pip install pymupdf 2>/dev/null
curl -sL "https://arxiv.org/pdf/$ARXIV_ID" -o "$IMPL_DIR/paper/paper.pdf"
python3 -c "
import fitz
doc = fitz.open('$IMPL_DIR/paper/paper.pdf')
text = ''
for page in doc:
    text += page.get_text()
with open('$IMPL_DIR/paper/content.md', 'w') as f:
    f.write(text)
print(f'Extracted {len(text)} chars from {len(doc)} pages')
"
```

If PyMuPDF is unavailable, present the user with install options (same pattern as orient agent).

### 1c. Search for official code repository

Check the paper text and arxiv page for GitHub links:

```bash
# Search within paper text
grep -oE 'https?://github\.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+' "$IMPL_DIR/paper/content.md" 2>/dev/null | sort -u
```

Also use WebFetch on the arxiv abstract page to check for code links:

```
https://arxiv.org/abs/<ARXIV_ID>
```

And search Papers With Code:

Use WebSearch: `"<paper title>" site:paperswithcode.com`

Save the code repo URL if found:

```bash
cat > "$IMPL_DIR/paper/metadata.json" << 'META_EOF'
{
  "arxiv_id": "<ARXIV_ID>",
  "title": "<paper title>",
  "authors": ["<extracted from paper>"],
  "acquired_at": "<ISO timestamp>",
  "source": "ar5iv_html | pdf | session_reuse",
  "official_code_repo": "<GitHub URL or null>",
  "papers_with_code_url": "<URL or null>"
}
META_EOF
```

### 1d. Clone official code repo (if found)

If an official code repository was found:

```bash
if [ -n "$CODE_REPO_URL" ]; then
  git clone --depth 1 "$CODE_REPO_URL" "$IMPL_DIR/paper/official-code" 2>/dev/null
  echo "Official code cloned."
else
  echo "No official code repository found."
fi
```

---

## Stage 2: ANALYZE — Identify What to Implement

**Goal:** Classify the paper and scope the implementation.

Read the full paper text from `$IMPL_DIR/paper/content.md` and determine:

### 2a. Paper type classification

Classify as one of:
- **architecture** — new model architecture (transformer variant, CNN design, etc.)
- **training_method** — new training procedure, loss function, or optimization technique
- **inference_technique** — new decoding strategy, pruning method, quantization, etc.
- **dataset_pipeline** — new dataset, data augmentation, or preprocessing technique
- **theoretical** — primarily theoretical contribution (bounds, analysis, proofs)
- **systems** — distributed training, serving, compilation, hardware-aware optimization

### 2b. Core contribution identification

Identify THE single core contribution. Papers often have secondary contributions (ablations, analysis, etc.) but there is one primary thing. State it clearly.

### 2c. Scope classification

For every component mentioned in the paper, classify as:
- **IMPLEMENT** — this is the core contribution, must be implemented
- **REFERENCE** — use an existing library (e.g., standard transformer layers from PyTorch, standard optimizers)
- **OUT_OF_SCOPE** — skip (e.g., specific hardware optimizations, dataset collection)

### 2d. Save analysis

```bash
cat > "$IMPL_DIR/analysis.json" << 'ANALYSIS_EOF'
{
  "paper_type": "<classification>",
  "core_contribution": "<one-sentence description>",
  "core_contribution_sections": ["<paper sections that describe it>"],
  "components": [
    {
      "name": "<component name>",
      "scope": "IMPLEMENT | REFERENCE | OUT_OF_SCOPE",
      "reason": "<why this scope>",
      "paper_sections": ["<relevant sections>"],
      "depends_on": ["<other component names>"]
    }
  ],
  "implementation_order": ["<component names in dependency order>"],
  "estimated_complexity": "low | medium | high",
  "key_equations": ["<equation numbers referenced in paper>"],
  "official_code_available": true | false,
  "analyzed_at": "<ISO timestamp>"
}
ANALYSIS_EOF
echo "Analysis complete."
```

---

## Stage 3: AUDIT — Ambiguity Audit

**Goal:** For every implementation-relevant detail, determine whether the paper fully specifies it, partially specifies it, or leaves it unspecified. This is the critical stage that prevents hallucinated implementations.

### Anti-hallucination rules (ENFORCE STRICTLY)

- If it is not stated in the paper, it is **UNSPECIFIED**. Period.
- Never use phrases like "standard practice", "as usual", "obviously", "typically" to fill gaps.
- Never guess initialization schemes, learning rates, activation functions, or architectural details.
- If official code exists, prefer it over paper text for ambiguous details, but tag as `[FROM_OFFICIAL_CODE]`.
- Distinguish between "the paper implies X" (PARTIALLY_SPECIFIED) and "the paper says X" (SPECIFIED).

### 3a. Audit each implementation detail

For every detail needed to write code, classify as:

**SPECIFIED** — The paper explicitly states this.
- Include exact quote from the paper
- Include section/equation/table reference
- Example: `"We use a learning rate of 3e-4 with cosine annealing" (Section 4.1)`

**PARTIALLY_SPECIFIED** — The paper gives some information but not enough to implement.
- Include what the paper does say
- Identify what is missing
- Example: `"Multi-head attention with h heads" — h is not specified for all model sizes`

**UNSPECIFIED** — The paper does not mention this at all.
- State what default you will use
- List alternatives that are also reasonable
- Example: `"Dropout rate not mentioned — using 0.1. Alternatives: 0.0, 0.05, 0.2"`

### 3b. Resolve from official code

If official code was cloned, check it for every PARTIALLY_SPECIFIED and UNSPECIFIED item:

```bash
# Example: search for learning rate in official code
grep -rn "learning_rate\|lr" "$IMPL_DIR/paper/official-code/" --include="*.py" 2>/dev/null | head -20
```

For items resolved from code, mark as `[FROM_OFFICIAL_CODE]` with the file and line number.

### 3c. Save audit

```bash
cat > "$IMPL_DIR/audit.json" << 'AUDIT_EOF'
{
  "audited_at": "<ISO timestamp>",
  "total_details": 0,
  "specified": 0,
  "partially_specified": 0,
  "unspecified": 0,
  "resolved_from_code": 0,
  "details": [
    {
      "category": "architecture | hyperparameter | training | data | evaluation | initialization | other",
      "detail": "<what needs to be specified>",
      "status": "SPECIFIED | PARTIALLY_SPECIFIED | UNSPECIFIED",
      "paper_quote": "<exact quote or null>",
      "paper_reference": "<section/equation/table or null>",
      "missing": "<what is not specified, or null>",
      "default_choice": "<what we will use if UNSPECIFIED>",
      "alternatives": ["<other reasonable choices>"],
      "resolved_from_code": false,
      "code_reference": "<file:line or null>"
    }
  ]
}
AUDIT_EOF
echo "Audit complete: X specified, Y partially, Z unspecified."
```

---

## Stage 4: IMPLEMENT — Generate Code

**Goal:** Dispatch the implementer agent to produce citation-anchored code.

### Dispatch implementer agent

Use the Agent tool to dispatch the `theoria:implementer` subagent with:

- **Paper text**: Full contents of `$IMPL_DIR/paper/content.md`
- **Analysis**: Full contents of `$IMPL_DIR/analysis.json`
- **Audit**: Full contents of `$IMPL_DIR/audit.json`
- **Official code path**: `$IMPL_DIR/paper/official-code/` (if it exists)
- **Mode**: `$MODE` (minimal / full / educational)
- **Framework**: `$FRAMEWORK` (pytorch / jax / numpy)
- **Implementation directory**: `$IMPL_DIR`
- **Paper metadata**: Full contents of `$IMPL_DIR/paper/metadata.json`

The implementer agent generates files in dependency order:

```
$IMPL_DIR/src/
├── config.py           # All hyperparameters and model config
├── utils.py            # Shared utilities
├── model.py            # Core model / architecture
├── loss.py             # Loss functions (if applicable)
├── data.py             # Data loading / preprocessing (if --full)
├── train.py            # Training loop (if --full)
└── evaluate.py         # Evaluation / metrics (if --full)
```

Plus:
- `$IMPL_DIR/requirements.txt`
- `$IMPL_DIR/REPRODUCTION_NOTES.md`
- `$IMPL_DIR/README.md`
- `$IMPL_DIR/notebooks/walkthrough.ipynb` (the understanding notebook)

### Post-dispatch verification

```bash
echo "=== Implementation outputs ==="
ls -la "$IMPL_DIR/src/" 2>/dev/null
echo "=== Notebooks ==="
ls -la "$IMPL_DIR/notebooks/" 2>/dev/null
echo "=== Top-level files ==="
for f in requirements.txt REPRODUCTION_NOTES.md README.md; do
  if [ -f "$IMPL_DIR/$f" ]; then
    echo "$f exists ($(wc -l < "$IMPL_DIR/$f") lines)"
  else
    echo "WARNING: $f not found"
  fi
done

# Verify citation anchoring — every .py file should have section references
echo "=== Citation anchor density ==="
for f in "$IMPL_DIR/src/"*.py; do
  if [ -f "$f" ]; then
    TOTAL=$(wc -l < "$f")
    ANCHORED=$(grep -c '# §\|# \[UNSPECIFIED\]\|# \[FROM_OFFICIAL_CODE\]' "$f" 2>/dev/null || echo 0)
    echo "$(basename $f): $ANCHORED/$TOTAL lines anchored"
  fi
done
```

---

## Stage 5: WALKTHROUGH — Verify and Present

**Goal:** Verify the implementation works and present results to the user.

The implementer agent generates the walkthrough notebook as part of Stage 4. After it returns, verify the notebook exists and run a basic sanity check:

```bash
if [ -f "$IMPL_DIR/notebooks/walkthrough.ipynb" ]; then
  echo "Walkthrough notebook exists."
  # Quick import test
  cd "$IMPL_DIR" && python3 -c "
import sys
sys.path.insert(0, 'src')
import config
print('config.py imports OK')
import model
print('model.py imports OK')
" 2>&1
else
  echo "WARNING: Walkthrough notebook not generated."
fi
```

---

## Knowledge Integration

### Create knowledge card

If the implementation succeeded, create a knowledge card (markdown with YAML frontmatter):

```bash
CARD_ID="impl-$(date -u +%Y-%m-%d)-${SLUG}"
mkdir -p "$HOME/.theoria/knowledge/cards"
cat > "$HOME/.theoria/knowledge/cards/$CARD_ID.md" << 'CARD_EOF'
<Generate this markdown with YAML frontmatter>
---
id: <CARD_ID>
session_id: <SLUG>
domain: implementation
research_type: computational
status: completed
confidence: 0.8
created_at: <ISO timestamp>
tags:
  - implementation
  - <paper_type>
  - <framework>
methods:
  - paper-implementation
  - <MODE>
papers_referenced:
  - "arxiv:<ARXIV_ID>"
---

# Implementation: <paper_title>

## Key Findings
- <core_contribution from analysis.json>
- Framework: <FRAMEWORK>, Mode: <MODE>

## Implementation Gotchas
- <implementation gotcha 1 — things that were tricky or surprising>
- <implementation gotcha 2>

## Unspecified Choices
- <key choice 1: what was unspecified and what default was used>
- <key choice 2>

## Reusable Patterns
- <pattern 1: reusable code pattern discovered during implementation>
- <pattern 2>

## Connections
- Implements: arxiv:<ARXIV_ID>
- Related to: <adjacent implementations or research sessions>
CARD_EOF
echo "Knowledge card created: $CARD_ID.md"
```

### Update knowledge graph

```bash
GRAPH_FILE="$HOME/.theoria/knowledge/graph.json"
if [ ! -f "$GRAPH_FILE" ]; then
  echo '{"cards": [], "edges": []}' > "$GRAPH_FILE"
fi
# Add card and edges to related cards (e.g., if this paper was found in an orient session)
```

Use jq to add the card node and any `related-to` edges connecting it to existing knowledge cards from sessions that referenced this paper.

---

## Final Output

Present the complete implementation to the user:

```
--- Implementation Complete: $SLUG ---

Paper:  <title> (<ARXIV_ID>)
Mode:   <MODE>
Framework: <FRAMEWORK>

Implementation:
  $IMPL_DIR/
  ├── paper/              # Acquired paper text
  ├── analysis.json       # Paper type: <type>, Core: <contribution>
  ├── audit.json          # X specified, Y partial, Z unspecified
  ├── src/
  │   ├── config.py
  │   ├── utils.py
  │   ├── model.py
  │   └── ...
  ├── notebooks/
  │   └── walkthrough.ipynb
  ├── requirements.txt
  ├── REPRODUCTION_NOTES.md
  └── README.md

Audit Summary:
  Specified:       X details (exact from paper)
  Partially spec:  Y details (some info, filled gaps)
  Unspecified:     Z details (our choices, flagged in code)
  From official code: W details

See REPRODUCTION_NOTES.md for all unspecified choices and known limitations.
```

### Suggested Next Steps

- **Run the walkthrough** — `jupyter notebook $IMPL_DIR/notebooks/walkthrough.ipynb`
- **Check unspecified choices** — `grep -rn "[UNSPECIFIED]" $IMPL_DIR/src/`
- **Compare with official code** — if official code was found, diff key components
- **Train on real data** — if `--full` mode was used, the training loop is ready
- **Start a research session** — `/theoria:explore` to build on this paper

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Paper not found (invalid arXiv ID) | Search by title with WebSearch. Present candidates. Ask user to confirm. |
| ar5iv unavailable AND PyMuPDF not installed | Present install option. Do not silently skip. |
| Paper is not implementable (pure survey, position paper) | Explain why. Suggest `/theoria:explain` for understanding instead. |
| Official code repo is private/deleted | Note it. Proceed with paper text only. More items will be UNSPECIFIED. |
| Import errors in generated code | Implementer agent runs sanity checks. Fix and retry (up to 3 attempts). |
| Paper too long for context | Focus on sections identified in analysis.json. Read section by section rather than all at once. |

---

## Mode Details

### `minimal` (default)
- Implements ONLY the core contribution
- `config.py` + `utils.py` + `model.py` (+ `loss.py` if applicable)
- No training loop, no data pipeline, no evaluation script
- Walkthrough notebook covers the core module only

### `--full`
- Everything in minimal, PLUS:
- `data.py` — data loading and preprocessing
- `train.py` — full training loop with logging
- `evaluate.py` — evaluation metrics and scripts
- Walkthrough notebook includes training on toy data

### `--educational`
- Everything in minimal, PLUS:
- Extra inline comments explaining the theory behind each operation
- `PAPER_GUIDE.md` — section-by-section reading guide for the paper
- Walkthrough notebook includes theory sections between code cells
- Common misconceptions section in REPRODUCTION_NOTES.md

## Framework Details

### `pytorch` (default)
- PyTorch + standard ecosystem (torchvision, torchaudio if needed)
- `nn.Module` subclasses with proper `forward()` signatures
- Shape comments use PyTorch convention: `# (B, T, D)`

### `--jax`
- JAX + Flax (for neural network modules)
- Functional style with explicit PRNG key threading
- Shape comments use JAX convention: `# (batch, seq, dim)`

### `--numpy`
- NumPy only (no deep learning framework)
- Pure Python implementations of all operations
- Suitable for understanding, not for training at scale
- Shape comments use NumPy convention: `# shape: (N, D)`
