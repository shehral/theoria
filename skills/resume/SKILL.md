---
name: resume
description: Resume an interrupted research session from the last completed stage
argument-hint: "[session-name]"
disable-model-invocation: true
effort: high
---

# Theoria Resume

## Available Sessions

!`ls ".theoria/sessions" 2>/dev/null | grep -v archive || echo "No sessions to resume."`

Read the session directories at `.theoria/sessions/` (excluding `archive/`) and for each, read its `state.json` to show: name, topic, current stage, completed stages, and last updated timestamp.

## Instructions

If the user specified a session name in $ARGUMENTS, load that session. Otherwise, if only one session exists, load it automatically. If multiple sessions exist, ask the user which one to resume.

### Loading a Session

1. Read the session's state.json:
```bash
SESSION_DIR=".theoria/sessions/<name>"
cat "$SESSION_DIR/state.json"
```

2. Load all completed stage outputs:
   - For each stage in `completed_stages`, read the key output files
   - This reconstructs the research context

3. Load the taste profile:
```bash
cat "$HOME/.theoria/taste.json" 2>/dev/null
```

### Stage Continuation Map

Based on `current_stage` in state.json, continue from:

| current_stage | Action |
|---------------|--------|
| `ORIENT` | Orient stage was interrupted. Re-run the orient agent. |
| `DESIGN` | Orient is done. Present directions for user to choose. |
| `EXECUTE` | Design is done. Check for partial execute results, then run/resume experimenter. |
| `SYNTHESIZE` | Execute is done. Run synthesizer agent. |
| `WRITE` | Synthesis is done. Run writer agent. |
| `NARRATE` | Paper is written. Run narrator agent. |
| `COMPOUND` | Guides are done. Create knowledge card. |
| `REVIEW` | Knowledge saved. Run reviewer agent. |
| `COMPLETED` | Session is done. Show final output summary. |

### Context Reconstruction

For each completed stage, load the essential outputs:

- **ORIENT completed**: Read `orient/landscape.md` and `orient/gaps.json`
- **DESIGN completed**: Read `design/chosen.json` and `design/methodology.md`
- **EXECUTE completed**: Read `execute/results/` summary and `execute/log.md`
- **SYNTHESIZE completed**: Read `synthesize/assessment.json` and `synthesize/claims.json`

Present a summary of what was accomplished and what comes next, then proceed with the research loop from the current stage (following the same procedure as `/theoria:explore`).
