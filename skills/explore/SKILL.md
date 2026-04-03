---
name: explore
description: Start a new research session — literature search, direction selection, experiments, paper + understanding guides
argument-hint: "<research topic>"
disable-model-invocation: true
effort: high
---

# Theoria Explore — Research Session Orchestrator

The user wants to explore: **$ARGUMENTS**

You are the orchestrator for a full 8-stage research session. You dispatch specialized agents, manage human checkpoints, save all outputs, and maintain session state for resume capability.

---

## Pre-flight Checks

### Taste Profile
!`cat "$HOME/.theoria/taste.json" 2>/dev/null || echo "WARNING: No taste profile found. Run /theoria:taste first for personalized results."`

### Knowledge Base
!`cat "$HOME/.theoria/knowledge/graph.json" 2>/dev/null || echo "Knowledge base: empty (first session)."`

---

## Session Creation

Create a new session for this research topic.

1. **Generate a slug** from the topic: lowercase, hyphens only, max 40 characters. Strip filler words. Examples:
   - "sparse attention mechanisms for 1M+ context" -> `sparse-attention-1m-context`
   - "Can we distill chain-of-thought reasoning?" -> `distill-chain-of-thought`
   - "Neural scaling laws" -> `neural-scaling-laws`

2. **Check for collisions and create the directory:**

```bash
SLUG="<generated-slug>"
BASE_DIR=".theoria/sessions"
mkdir -p "$BASE_DIR"
if [ -d "$BASE_DIR/$SLUG" ]; then
  COUNTER=2
  while [ -d "$BASE_DIR/$SLUG-$COUNTER" ]; do
    COUNTER=$((COUNTER + 1))
  done
  SLUG="$SLUG-$COUNTER"
fi
SESSION_DIR="$BASE_DIR/$SLUG"
mkdir -p "$SESSION_DIR"/{orient,design,execute,synthesize,paper,guides,review,knowledge}
echo "SESSION_DIR=$SESSION_DIR"
echo "SLUG=$SLUG"
```

3. **Initialize state.json:**

```bash
cat > "$SESSION_DIR/state.json" << EOF
{
  "session_id": "$SLUG",
  "topic": "$ARGUMENTS",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_stage": "ORIENT",
  "completed_stages": [],
  "human_decisions": [],
  "taste_profile_version": "$(jq -r '.updated_at // "none"' "$HOME/.theoria/taste.json" 2>/dev/null || echo "defaults")",
  "outputs": {}
}
EOF
echo "Session initialized: $SLUG"
```

From this point forward, use `$SESSION_DIR` to refer to this session's directory in all commands and agent dispatches.

---

## Stage 1: ORIENT

**Goal:** Build a comprehensive picture of the research landscape before any original work begins.

### Pre-dispatch state update

```bash
jq '.current_stage = "ORIENT" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Dispatch orient agent

Use the Agent tool to dispatch the `theoria:orient` subagent with:

- **Topic**: $ARGUMENTS
- **Taste profile**: The full taste JSON loaded in pre-flight (or note that defaults are being used)
- **Knowledge context**: Any relevant prior knowledge cards from the knowledge base check
- **Session directory**: $SESSION_DIR

The orient agent will search Semantic Scholar and arXiv, retrieve full-text PDFs where possible, build a citation graph, perform gap analysis, and produce running narration.

### Parse orient output

The orient agent returns labeled output blocks. Parse each one and save:

1. Extract `ORIENT_PAPERS_JSON` block -> save as `$SESSION_DIR/orient/papers.json`
2. Extract `ORIENT_CITATION_GRAPH_JSON` block -> save as `$SESSION_DIR/orient/citation-graph.json`
3. Extract `ORIENT_GAPS_JSON` block -> save as `$SESSION_DIR/orient/gaps.json`
4. Extract `ORIENT_PRIOR_KNOWLEDGE_JSON` block -> save as `$SESSION_DIR/orient/prior-knowledge.json`
5. Extract `ORIENT_LANDSCAPE_MD` block -> save as `$SESSION_DIR/orient/landscape.md`
6. Extract `ORIENT_RUNNING_NOTES` block -> save as `$SESSION_DIR/guides/running-notes.md`
7. Extract `ORIENT_STATS_JSON` block -> save as `$SESSION_DIR/orient/stats.json`

### Post-dispatch state update

```bash
STATS=$(cat "$SESSION_DIR/orient/stats.json" 2>/dev/null || echo '{}')
PAPERS_COUNT=$(jq 'length' "$SESSION_DIR/orient/papers.json" 2>/dev/null || echo "0")
GAPS_COUNT=$(jq 'length' "$SESSION_DIR/orient/gaps.json" 2>/dev/null || echo "0")
jq --arg papers "$PAPERS_COUNT" --arg gaps "$GAPS_COUNT" --argjson stats "$STATS" '
  .completed_stages += ["ORIENT"] |
  .current_stage = "DESIGN" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .outputs.orient = {
    "papers_found": ($papers | tonumber),
    "gaps_identified": ($gaps | tonumber),
    "stats": $stats
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
echo "ORIENT complete. Found $PAPERS_COUNT papers, identified $GAPS_COUNT gaps."
```

---

## Stage 2: DESIGN (Human Checkpoint)

**Goal:** Propose research directions based on orient findings, score them against the taste profile, and get the researcher's approval before committing resources to execution.

### Pre-dispatch state update

```bash
jq '.current_stage = "DESIGN" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Analyze orient outputs and propose directions

Read the orient outputs:
- `$SESSION_DIR/orient/gaps.json` — the identified research gaps with taste alignment scores
- `$SESSION_DIR/orient/landscape.md` — the field landscape summary
- `$SESSION_DIR/orient/papers.json` — the full paper corpus
- `$SESSION_DIR/orient/citation-graph.json` — citation relationships

Based on these findings, propose **2-3 research directions**. For each direction, provide:

1. **Title**: A concise name for the direction
2. **Description**: What the direction involves (2-3 sentences)
3. **Novelty**: What is new about this approach and why it hasn't been done
4. **Feasibility**: How likely this is to produce meaningful results within one session
5. **Risk level**: Low / Medium / High — with justification
6. **Taste alignment score**: 0.0-1.0, computed from:
   - Does it match the researcher's `contribution_type` preferences?
   - Does it align with their `risk_tolerance`?
   - Is the `novelty_vs_rigor` balance right?
   - Does it suit their `theory_vs_empirical` orientation?
   - Explain the scoring breakdown.
7. **Recommended research mode**: `computational`, `theoretical`, `survey`, or `empirical` — based on what this direction requires and the researcher's `theory_vs_empirical` preference
8. **Estimated effort**: Low / Medium / High
9. **Key papers**: Which papers from the orient corpus are most relevant to this direction
10. **Gaps addressed**: Which gaps from `gaps.json` this direction targets

### Taste-aware ranking

Rank the directions by taste alignment. If the taste profile indicates:
- **risk_tolerance = conservative**: Lead with the safest, most well-supported direction
- **risk_tolerance = moderate**: Lead with a balanced option, include one ambitious one
- **risk_tolerance = aggressive**: Lead with the most novel/ambitious direction

Present your **recommendation** with a clear explanation of why you recommend it, grounded in the taste profile and field gaps.

### Present to researcher

Format the directions clearly with all scores and reasoning. Then state:

> I recommend **Direction [N]: [Title]** because [explanation grounded in taste profile and gaps].
>
> Which direction would you like to pursue? You can also:
> - Modify any direction (add constraints, change scope, combine elements)
> - Propose your own direction based on the landscape
> - Ask me to explain any aspect of the analysis in more detail

**THIS IS A MANDATORY CHECKPOINT. STOP HERE AND WAIT FOR THE USER'S RESPONSE.**

Do NOT proceed to Stage 3 until the user has:
- Selected a direction (by number, name, or their own proposal)
- Confirmed they want to proceed
- Provided any additional constraints or modifications

### After user responds

Save the design outputs:

1. Save all proposed directions to `$SESSION_DIR/design/directions.json`:
```json
[
  {
    "id": 1,
    "title": "...",
    "description": "...",
    "novelty": "...",
    "feasibility": "...",
    "risk_level": "...",
    "taste_alignment": 0.0,
    "taste_alignment_breakdown": { "contribution_type": 0.0, "risk": 0.0, "novelty_rigor": 0.0, "theory_empirical": 0.0 },
    "recommended_mode": "...",
    "estimated_effort": "...",
    "key_papers": ["..."],
    "gaps_addressed": ["..."]
  }
]
```

2. Save the chosen direction to `$SESSION_DIR/design/chosen.json`:
```json
{
  "direction_id": 1,
  "title": "...",
  "description": "...",
  "research_mode": "...",
  "user_modifications": "Any modifications the user requested, or null",
  "user_constraints": "Any additional constraints, or null",
  "chosen_at": "<ISO timestamp>",
  "rationale": "Why the user chose this direction (from their response)"
}
```

3. Write a detailed methodology document to `$SESSION_DIR/design/methodology.md` that covers:
   - Specific research questions to answer
   - Methods to employ (based on the chosen research mode)
   - Expected outputs and success criteria
   - Known risks and mitigation strategies
   - Timeline/scope within this session

### Post-checkpoint state update

```bash
jq --arg choice "$(jq -r '.title' "$SESSION_DIR/design/chosen.json")" '
  .completed_stages += ["DESIGN"] |
  .current_stage = "EXECUTE" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .human_decisions += [{
    "stage": "DESIGN",
    "decision": ("Chose direction: " + $choice),
    "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
  }] |
  .outputs.design = {
    "directions_proposed": 3,
    "chosen_direction": $choice
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

---

## Stage 3: EXECUTE

**Goal:** Conduct the actual research work based on the chosen direction and methodology.

### Pre-dispatch state update

```bash
jq '.current_stage = "EXECUTE" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Detect research mode

Determine the research mode from the chosen direction and taste profile:

- **theory_vs_empirical >= 0.7**: Computational/ML mode — dispatch experimenter with code execution capabilities
- **theory_vs_empirical <= 0.3**: Theoretical mode — dispatch experimenter for formal analysis and proofs
- **Chosen direction specifies survey/analysis**: Survey mode
- **Chosen direction specifies empirical-non-code**: Empirical design mode
- **Default (0.4-0.6)**: Mixed mode — experimenter does both theoretical analysis and empirical validation

The `research_mode` field in `design/chosen.json` takes precedence if the user explicitly selected a mode.

### Dispatch experimenter agent

Use the Agent tool to dispatch the `theoria:experimenter` subagent with:

- **Chosen direction**: Full contents of `$SESSION_DIR/design/chosen.json`
- **Methodology**: Full contents of `$SESSION_DIR/design/methodology.md`
- **Orient corpus**: `$SESSION_DIR/orient/papers.json` (for reference during experiments)
- **Taste profile**: The loaded taste JSON (affects experiment scope, ablation depth, rigor level)
- **Session directory**: `$SESSION_DIR` (experimenter writes directly to `$SESSION_DIR/execute/`)
- **Research mode**: The detected mode from above
- **Running notes path**: `$SESSION_DIR/guides/running-notes.md` (experimenter appends to existing orient notes)

The experimenter agent has full tool access (Read, Write, Edit, Bash, Grep, Glob, WebFetch, WebSearch) and will:
- Create experiment code in `execute/code/` (computational mode)
- Write proofs in `execute/proofs/` (theoretical mode)
- Build taxonomy in `execute/taxonomy.json` (survey mode)
- Design methodology in `execute/design/` (empirical mode)
- Save results to `execute/results/`
- Generate figures to `execute/figures/`
- Log all work to `execute/log.md`
- Append running notes to `guides/running-notes.md`

### Post-dispatch verification and state update

After the experimenter returns, verify outputs exist:

```bash
echo "=== Execute outputs ==="
ls -la "$SESSION_DIR/execute/" 2>/dev/null
echo "=== Results ==="
ls -la "$SESSION_DIR/execute/results/" 2>/dev/null
echo "=== Log ==="
if [ -f "$SESSION_DIR/execute/log.md" ]; then echo "Log exists"; wc -l "$SESSION_DIR/execute/log.md"; else echo "WARNING: No execution log found"; fi
```

```bash
jq '
  .completed_stages += ["EXECUTE"] |
  .current_stage = "SYNTHESIZE" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .outputs.execute = {
    "mode": "<detected-mode>",
    "outputs_verified": true
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
echo "EXECUTE complete."
```

---

## Stage 4: SYNTHESIZE (Human Checkpoint)

**Goal:** Critically review the execution results, assess novelty and validity, flag uncertainties, and get the researcher's approval before writing.

### Pre-dispatch state update

```bash
jq '.current_stage = "SYNTHESIZE" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Dispatch synthesizer agent

Use the Agent tool to dispatch the `theoria:synthesizer` subagent with:

- **Execute outputs**: All contents of `$SESSION_DIR/execute/` (results, log, figures)
- **Original direction**: `$SESSION_DIR/design/chosen.json`
- **Methodology**: `$SESSION_DIR/design/methodology.md`
- **Orient corpus**: `$SESSION_DIR/orient/papers.json` (for novelty checking against existing work)
- **Gaps**: `$SESSION_DIR/orient/gaps.json` (to verify if gaps were actually addressed)
- **Taste profile**: The loaded taste JSON (affects judgment thresholds)

The synthesizer agent is READ-ONLY (Read, Grep, Glob only) and returns its assessment as structured text.

### Parse synthesizer output

The synthesizer returns an assessment. Save the full output to `$SESSION_DIR/synthesize/assessment.md`.

Extract and save structured data:
- `$SESSION_DIR/synthesize/claims.json` — each claim with evidence strength and confidence level
- `$SESSION_DIR/synthesize/novelty-check.json` — novelty assessment against the orient corpus
- `$SESSION_DIR/synthesize/uncertainties.json` — flagged uncertainties with reasoning

### Present to researcher

Present the synthesis to the user clearly:

1. **Key findings**: What the research produced (2-5 bullet points)
2. **Claim strength assessment**: For each major claim:
   - The claim itself
   - Supporting evidence (specific results, metrics, proofs)
   - Confidence level: High / Medium / Low
   - How this confidence was determined
3. **Novelty check**: Is this actually new relative to the orient corpus? What specifically is the contribution?
4. **Flagged uncertainties**: What we're least confident about, and why
5. **Recommendation**: One of:
   - **Proceed to writing** — results are solid enough to write up
   - **Run additional experiments** — specific gaps in the evidence need filling
   - **Pivot** — results don't support the hypothesis, suggest alternative direction
   - **Stop and compound** — enough learned to be valuable even without a paper

Then state:

> Based on the synthesis, I recommend: **[recommendation]**.
>
> Would you like to:
> - Proceed to writing the paper
> - Run additional experiments (I'll re-enter EXECUTE with specific targets)
> - Pivot to a different direction (I'll return to DESIGN with what we've learned)
> - Stop here and save what we've learned to the knowledge base

**THIS IS A MANDATORY CHECKPOINT. STOP HERE AND WAIT FOR THE USER'S RESPONSE.**

Do NOT proceed to Stage 5 until the user has confirmed how to proceed.

### After user responds

Handle the user's decision:
- **Proceed**: Continue to Stage 5 (WRITE)
- **More experiments**: Loop back to Stage 3 (EXECUTE) with additional targets. Update state.json to reflect the re-entry.
- **Pivot**: Loop back to Stage 2 (DESIGN) with accumulated knowledge. Update state.json.
- **Stop**: Jump to Stage 8 (COMPOUND) to save learnings, skip WRITE/REVIEW/NARRATE.

```bash
jq --arg decision "<user's decision summary>" '
  .completed_stages += ["SYNTHESIZE"] |
  .current_stage = "WRITE" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .human_decisions += [{
    "stage": "SYNTHESIZE",
    "decision": $decision,
    "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
  }] |
  .outputs.synthesize = {
    "recommendation": "<synthesizer recommendation>",
    "human_decision": $decision
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

---

## Stage 5: WRITE

**Goal:** Generate a publishable LaTeX paper from all prior stage outputs.

### Pre-dispatch state update

```bash
jq '.current_stage = "WRITE" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Dispatch writer agent

Use the Agent tool to dispatch the `theoria:writer` subagent with:

- **Orient outputs**: `$SESSION_DIR/orient/` (landscape, papers, gaps for related work and framing)
- **Design outputs**: `$SESSION_DIR/design/` (direction and methodology for introduction and methods)
- **Execute outputs**: `$SESSION_DIR/execute/` (results, figures, code, proofs for the main body)
- **Synthesize outputs**: `$SESSION_DIR/synthesize/` (claims and assessment for discussion)
- **Taste profile**: The loaded taste JSON (writing_style section: tone, density, audience)
- **Target venue**: From taste profile `preferences.venues[0]` or user specification
- **LaTeX template path**: `${CLAUDE_PLUGIN_ROOT}/templates/latex/<venue>/` (if available)
- **Session directory**: `$SESSION_DIR` (writer saves to `$SESSION_DIR/paper/`)

The writer agent has tools: Read, Write, Edit, Grep, Glob. No network access (prevents citation fabrication). It will:
- Generate `paper/main.tex` with venue-appropriate formatting
- Generate `paper/references.bib` with only verifiable citations from orient corpus
- Save any figures to `paper/figures/`
- Include AI-assistance disclosure in acknowledgments (per CLAUDE.md)

### Post-dispatch verification

```bash
echo "=== Paper outputs ==="
ls -la "$SESSION_DIR/paper/" 2>/dev/null
if [ -f "$SESSION_DIR/paper/main.tex" ]; then echo "main.tex exists"; wc -l "$SESSION_DIR/paper/main.tex"; else echo "ERROR: main.tex not found"; fi
if [ -f "$SESSION_DIR/paper/references.bib" ]; then echo "references.bib exists"; wc -l "$SESSION_DIR/paper/references.bib"; else echo "ERROR: references.bib not found"; fi
```

```bash
jq '
  .completed_stages += ["WRITE"] |
  .current_stage = "REVIEW" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .outputs.write = {
    "paper_generated": true
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
echo "WRITE complete."
```

---

## Stage 6: REVIEW (Quality Gate)

**Goal:** Independent quality check of the paper before finalizing. Verify citations, check claim-evidence binding, flag issues.

### Pre-dispatch state update

```bash
jq '.current_stage = "REVIEW" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Dispatch reviewer agent

Use the Agent tool to dispatch the `theoria:reviewer` subagent with:

- **Paper**: `$SESSION_DIR/paper/main.tex` and `$SESSION_DIR/paper/references.bib`
- **Orient papers**: `$SESSION_DIR/orient/papers.json` (for citation verification)
- **Execute results**: `$SESSION_DIR/execute/` (for claim-evidence binding verification)
- **Synthesize claims**: `$SESSION_DIR/synthesize/claims.json` (for checking all claims are properly supported)

The reviewer agent is READ-ONLY (Read, Grep, Glob only). No network, no write access. It returns a quality report as structured text.

### Parse and handle review output

Save the review output to `$SESSION_DIR/review/quality-report.json` with structure:

```json
{
  "overall_quality": "pass | pass-with-warnings | fail",
  "critical_issues": [],
  "warnings": [],
  "citation_check": {
    "total_citations": 0,
    "verified": 0,
    "unverified": 0,
    "fabricated_suspected": 0
  },
  "claim_evidence_binding": {
    "total_claims": 0,
    "well_supported": 0,
    "weakly_supported": 0,
    "unsupported": 0
  },
  "suggestions": []
}
```

**Handle based on result:**

- **CRITICAL issues found**: Present each critical issue to the user. State what's wrong and how it could be fixed. Ask:
  > The review found [N] critical issues. Would you like me to:
  > 1. Fix them (re-dispatch writer with specific corrections)
  > 2. Proceed anyway (issues will be noted in the quality report)
  > 3. Review the issues in detail first

  Wait for user response if critical issues exist.

- **Warnings only (no critical issues)**: Note the warnings in output, proceed automatically. State:
  > Review passed with [N] warnings. See `review/quality-report.json` for details. Proceeding to narration.

- **Clean pass**: Proceed to narration.

### Post-review state update

```bash
QUALITY=$(jq -r '.overall_quality' "$SESSION_DIR/review/quality-report.json" 2>/dev/null || echo "unknown")
CRITICAL=$(jq '.critical_issues | length' "$SESSION_DIR/review/quality-report.json" 2>/dev/null || echo "0")
WARNINGS=$(jq '.warnings | length' "$SESSION_DIR/review/quality-report.json" 2>/dev/null || echo "0")
jq --arg quality "$QUALITY" --arg critical "$CRITICAL" --arg warnings "$WARNINGS" '
  .completed_stages += ["REVIEW"] |
  .current_stage = "NARRATE" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .outputs.review = {
    "quality": $quality,
    "critical_issues": ($critical | tonumber),
    "warnings": ($warnings | tonumber)
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
echo "REVIEW complete. Quality: $QUALITY ($CRITICAL critical, $WARNINGS warnings)"
```

---

## Stage 7: NARRATE

**Goal:** Generate understanding guides that help the researcher (and others) deeply understand the research, the field, and the decisions made.

### Pre-dispatch state update

```bash
jq '.current_stage = "NARRATE" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Dispatch narrator agent

Use the Agent tool to dispatch the `theoria:narrator` subagent with:

- **Orient outputs**: `$SESSION_DIR/orient/` (landscape, papers for field context)
- **Design outputs**: `$SESSION_DIR/design/` (directions, chosen direction, methodology for decision context)
- **Execute outputs**: `$SESSION_DIR/execute/` (results, log for methodology explanation)
- **Synthesize outputs**: `$SESSION_DIR/synthesize/` (assessment for findings narrative)
- **Running notes**: `$SESSION_DIR/guides/running-notes.md` (accumulated from orient + execute)
- **Taste profile**: The loaded taste JSON (learning_style section: primary format, depth, assumed_background)
- **Session directory**: `$SESSION_DIR` (narrator saves to `$SESSION_DIR/guides/`)

The narrator agent has tools: Read, Write, Grep, Glob. No network or code execution. It will generate:

- `guides/field-landscape.md` — Accessible overview of the research field, its history, key players, and current state. Written for the researcher's `assumed_background` level.
- `guides/key-concepts.md` — Deep explanation of the core concepts needed to understand this research. Uses the researcher's `primary` learning style (visual, interactive, narrative, etc.).
- `guides/decision-log.md` — Complete record of every decision made during the session: why each direction was considered, why the chosen one was selected, what trade-offs were made, what the human decided at each checkpoint.
- `guides/methodology.md` — Detailed walkthrough of the research methodology: what was done, why each step, how to reproduce, what to watch out for.

### Post-dispatch verification

```bash
echo "=== Guide outputs ==="
for guide in field-landscape.md key-concepts.md decision-log.md methodology.md; do
  if [ -f "$SESSION_DIR/guides/$guide" ]; then
    echo "$guide exists ($(wc -l < "$SESSION_DIR/guides/$guide") lines)"
  else
    echo "WARNING: $guide not found"
  fi
done
```

```bash
jq '
  .completed_stages += ["NARRATE"] |
  .current_stage = "COMPOUND" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .outputs.narrate = {
    "guides_generated": true
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
echo "NARRATE complete."
```

---

## Stage 8: COMPOUND

**Goal:** Extract reusable knowledge from this session and integrate it into the knowledge base for future sessions.

### Pre-dispatch state update

```bash
jq '.current_stage = "COMPOUND" | .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
```

### Extract knowledge card (draft)

Create a draft knowledge card summarizing this session's key contributions. Read:
- `$SESSION_DIR/synthesize/claims.json` — the validated claims
- `$SESSION_DIR/design/chosen.json` — the research direction
- `$SESSION_DIR/orient/gaps.json` — the gaps that were addressed
- `$SESSION_DIR/orient/landscape.md` — the field context

Knowledge cards use **markdown with YAML frontmatter** (not JSON). This makes them grep-searchable, human-readable, and machine-parseable. See `knowledge/schema.json` for the full format specification.

Build the draft knowledge card (do NOT persist to `~/.theoria/knowledge/cards/` yet — the curator must approve first):

```bash
CARD_ID="theoria-$(date -u +%Y-%m-%d)-$(echo "$SLUG" | head -c 40)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$SESSION_DIR/knowledge/draft-card.md" << 'CARD_EOF'
<Generate this markdown with YAML frontmatter>
---
id: <CARD_ID>
session_id: <SLUG>
domain: <primary research domain, lowercase hyphenated>
research_type: <computational|theoretical|survey|empirical>
status: <completed|partial|negative-result>
confidence: <0.0-1.0>
taste_alignment: <0.0-1.0>
strength: 0.0
access_count: 0
last_accessed: <ISO timestamp>
created_at: <ISO timestamp>
tags:
  - <tag1>
  - <tag2>
  - <tag3>
methods:
  - <method1>
  - <method2>
papers_referenced:
  - "arxiv:<id1>"
  - "arxiv:<id2>"
---

# <Descriptive Title of Research Contribution>

## Key Findings
- <finding 1 with specific metrics where available>
- <finding 2>

## Limitations
- <limitation 1>
- <limitation 2>

## Implementation Gotchas
- <practical issue 1 discovered during execution>
- <practical issue 2>

## Connections
- Builds on: <prior work this extends>
- Contradicts: <conflicting findings, or [none]>
- Related to: <adjacent work with different trade-offs>
CARD_EOF
echo "Draft knowledge card created: $CARD_ID.md"
```

### Dispatch curator agent (quality gate)

Use the Agent tool to dispatch the `theoria:curator` subagent with:

- **Proposed card**: The draft card at `$SESSION_DIR/knowledge/draft-card.md`
- **Session directory**: `$SESSION_DIR` (for evidence verification via `synthesize/claims.json`, `execute/results/`, etc.)
- **Knowledge base**: `~/.theoria/knowledge/cards/` and `~/.theoria/knowledge/graph.json`

The curator is READ-ONLY and returns a structured verdict.

### Parse curator verdict

The curator returns a `CURATOR_VERDICT` block. Parse the verdict and handle accordingly:

- **`ACCEPT`**: Persist the card to `~/.theoria/knowledge/cards/` with `memory.created_strength: 0.7` and `memory.strength: 0.7`. Update the knowledge graph with recommended edges.
- **`ACCEPT_WITH_CAVEAT`**: Persist with `memory.created_strength: 0.4` and `memory.strength: 0.4`. Add caveats to the card's `limitations` array. Update the knowledge graph.
- **`REJECT`**: Do NOT persist the card. Save the curator's rejection reason to `$SESSION_DIR/knowledge/curator-verdict.json` for the researcher's reference. Inform the user what was rejected and why.
- **`MERGE`**: Do NOT create a new card. Instead, update the existing card identified by `merge_target.card_id` using the curator's merge strategy. Save the verdict for reference.

Save the full curator verdict:

```bash
cat > "$SESSION_DIR/knowledge/curator-verdict.json" << 'VERDICT_EOF'
<curator verdict JSON>
VERDICT_EOF
```

### Persist accepted card

If the curator's verdict is `ACCEPT` or `ACCEPT_WITH_CAVEAT`:

```bash
# Extract card ID from the draft card's YAML frontmatter
CARD_ID=$(grep '^id: ' "$SESSION_DIR/knowledge/draft-card.md" | sed 's/^id: //')
STRENGTH=$(jq -r '.initial_strength' "$SESSION_DIR/knowledge/curator-verdict.json")

# Update the strength field in the YAML frontmatter and persist
sed "s/^strength: .*/strength: $STRENGTH/" "$SESSION_DIR/knowledge/draft-card.md" > "$HOME/.theoria/knowledge/cards/$CARD_ID.md"

echo "Knowledge card persisted: $CARD_ID.md (strength: $STRENGTH)"
```

### Update knowledge graph

```bash
GRAPH_FILE="$HOME/.theoria/knowledge/graph.json"
if [ ! -f "$GRAPH_FILE" ]; then
  echo '{"version": "1.0.0", "cards": [], "edges": [], "domains": []}' > "$GRAPH_FILE"
fi
```

Add the new card to the graph and create edges recommended by the curator:
- `builds-on` — if this session's findings extend a prior card's work
- `contradicts` — if any findings conflict with a prior card (both preserved, flagged for researcher)
- `related-to` — if topically connected to existing cards

Use jq to update the graph JSON, adding the new card node and the curator's recommended edges.

### Update taste profile compound stats

```bash
if [ -f "$HOME/.theoria/taste.json" ]; then
  DOMAIN="<primary domain from this session>"
  jq --arg domain "$DOMAIN" '
    .compound.sessions_completed += 1 |
    .compound.knowledge_cards += 1 |
    .compound.domains_explored = (.compound.domains_explored + [$domain] | unique)
  ' "$HOME/.theoria/taste.json" > "$HOME/.theoria/taste.json.tmp" && mv "$HOME/.theoria/taste.json.tmp" "$HOME/.theoria/taste.json"
  echo "Taste profile updated: sessions_completed incremented, domain added."
fi
```

### Self-Evolution Analysis

At the end of every session, analyze what went wrong (or suboptimally) and write improvement suggestions to the cross-project evolution log. This is how Theoria gets better at research over time.

**Review these session artifacts for issues:**
1. `$SESSION_DIR/state.json` — check for any `_FAILED` stages, error entries, or re-entries (loops back to DESIGN/EXECUTE)
2. `$SESSION_DIR/guides/decision-log.md` — look for course corrections, rejected directions, user overrides
3. `$SESSION_DIR/review/quality-report.json` — check for warnings, critical issues, weak citation binding
4. `$SESSION_DIR/orient/stats.json` — check if search required broadening iterations
5. `$SESSION_DIR/synthesize/uncertainties.json` — check for high-uncertainty claims

**Categorize each issue into one of:**
- `search-quality` — orient did not find good papers, had to broaden too many times
- `direction-quality` — proposed directions were weak, user rejected multiple times
- `execution-failure` — experiments crashed, code errors, resource limits
- `synthesis-gap` — claims did not hold up, too many uncertainties
- `writing-quality` — reviewer found issues, citation problems
- `explanation-quality` — guides needed regeneration, audience mismatch

**For each issue, write a specific, actionable improvement suggestion.**

Also note what worked well (patterns to reinforce in future sessions).

Append to the evolution log:

```bash
mkdir -p "$HOME/.theoria"
cat >> "$HOME/.theoria/evolution.md" << 'EVOLUTION_EOF'

## Session: <SLUG> (<YYYY-MM-DD>)

### Issues Found
- [<category>] <Specific description of what went wrong.>
  **Suggestion:** <Concrete, actionable improvement that would prevent this in future sessions.>

- [<category>] <Another issue, if any.>
  **Suggestion:** <Another improvement.>

### What Worked Well
- <Pattern or approach that succeeded and should be preserved.>
- <Another positive observation.>
EVOLUTION_EOF
echo "Self-evolution log updated: ~/.theoria/evolution.md"
```

If no issues were found (clean session with no failures, no rejected directions, no review warnings), still append a brief entry noting the clean run and what worked well. Every session contributes to the evolution log.

**Important:** Suggestions should be specific and grounded in this session's actual experience. Avoid generic advice like "be more thorough." Instead, write things like "For topics in quantitative finance, also search SSRN and Google Scholar, not just arXiv/Semantic Scholar" or "Default batch size should be adaptive based on available GPU memory. Add a pre-flight memory check."

### Mark session complete

```bash
VERDICT=$(jq -r '.verdict' "$SESSION_DIR/knowledge/curator-verdict.json" 2>/dev/null || echo "unknown")
jq --arg verdict "$VERDICT" '
  .completed_stages += ["COMPOUND"] |
  .current_stage = "COMPLETED" |
  .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
  .outputs.compound = {
    "curator_verdict": $verdict,
    "knowledge_card_created": ($verdict == "ACCEPT" or $verdict == "ACCEPT_WITH_CAVEAT"),
    "graph_updated": ($verdict == "ACCEPT" or $verdict == "ACCEPT_WITH_CAVEAT"),
    "taste_updated": true,
    "evolution_updated": true
  }
' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
echo "COMPOUND complete. Curator verdict: $VERDICT. Session fully finished."
```

---

## Final Output

Present the complete session results to the researcher:

```
--- Research Session Complete: $SLUG ---

Topic:  $ARGUMENTS

Paper:
  $SESSION_DIR/paper/main.tex
  $SESSION_DIR/paper/references.bib

Understanding Guides:
  $SESSION_DIR/guides/
  ├── field-landscape.md    — Overview of the research field
  ├── key-concepts.md       — Core concepts explained
  ├── decision-log.md       — Every decision and why
  ├── methodology.md        — How to reproduce this research
  └── running-notes.md      — Real-time narration from the session

Quality Report:
  $SESSION_DIR/review/quality-report.json

Knowledge:
  Card saved to knowledge base. Future sessions on related
  topics will build on what we learned here.

Self-Evolution:
  Improvement suggestions written to ~/.theoria/evolution.md
  Run /theoria:evolve to review and apply suggestions.
```

### Compilation Menu

If you want to compile the paper to PDF:

1. **tectonic** (recommended — downloads packages automatically):
   ```bash
   cd "$SESSION_DIR/paper" && tectonic main.tex
   ```

2. **pdflatex** (standard LaTeX):
   ```bash
   cd "$SESSION_DIR/paper" && pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex
   ```

3. **Skip** — keep .tex only, compile later

### Suggested Next Steps

- **Read the guides** — Start with `field-landscape.md` for a bird's eye view, then `key-concepts.md` for depth
- **Compile the paper** — Use one of the compilation options above
- **Explore related directions** — The orient stage found other gaps worth investigating. Run `/theoria:explore` with a related topic to build on this session.
- **Review the decision log** — `decision-log.md` captures your reasoning at each checkpoint, useful for future reference
- **Check the quality report** — `review/quality-report.json` has detailed findings
- **Review self-evolution** — Run `/theoria:evolve` to see accumulated improvement suggestions across sessions

---

## Failure Handling

If any stage fails during the session:

1. **Save partial results** — Write whatever was produced to the session directory before surfacing the error
2. **Update state.json** — Record the failure in state so `/theoria:resume` knows where to pick up:
   ```bash
   jq --arg stage "<failed-stage>" --arg error "<error description>" '
     .current_stage = ($stage + "_FAILED") |
     .updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
     .error = {
       "stage": $stage,
       "message": $error,
       "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
     }
   ' "$SESSION_DIR/state.json" > "$SESSION_DIR/state.json.tmp" && mv "$SESSION_DIR/state.json.tmp" "$SESSION_DIR/state.json"
   ```
3. **Present clearly** — Tell the user what was accomplished, what failed, and why
4. **Suggest recovery options**:
   - **Retry** — Run the failed stage again (transient errors, API issues)
   - **Broaden scope** — If orient found too little, widen the search terms
   - **Pivot** — If execute failed fundamentally, return to DESIGN with new constraints
   - **Stop and compound** — Save whatever was learned, even from a partial session. Knowledge from failure is still knowledge.
5. **Never silently skip** — The decision log must record any failure and the recovery choice

## Resume Support

This skill supports `/theoria:resume`. If a session's `state.json` shows an incomplete stage:
- Read the `current_stage` field to determine where to resume
- Check `completed_stages` to know what's already done
- Load outputs from completed stages (they're saved to disk)
- Continue from the current stage, skipping completed ones
- If `current_stage` ends in `_FAILED`, offer to retry or skip that stage
