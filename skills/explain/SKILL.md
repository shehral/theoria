---
name: explain
description: Socratic Q&A and alternative explanations — ask anything about the current research session
argument-hint: "<concept or question> [--brief|--notebook|--audio|--visual|--for \"audience\"]"
disable-model-invocation: true
effort: high
---

# Theoria Explain

## Context

### Current Session
!`cat ".theoria/sessions/$(ls -t ".theoria/sessions" 2>/dev/null | grep -v archive | head -1)/state.json" 2>/dev/null || echo "No active session."`

### Taste Profile
!`cat "$HOME/.theoria/taste.json" 2>/dev/null || echo "No taste profile."`

## Instructions

The user asked: **$ARGUMENTS**

Parse the arguments for flags:
- `--brief`: Generate a Twitter-thread-length summary (5-7 bullet points)
- `--notebook`: Generate a Jupyter notebook (.ipynb) with runnable code + explanations (computational research only)
- `--audio`: Generate a podcast-style script between two narrators discussing the research
- `--visual`: Generate an HTML page with diagrams, charts, and visual explanations
- `--for "audience"`: Regenerate explanation for a specific audience (e.g., `--for "undergraduate biology student"`)

### Default Mode: Socratic Q&A

If no flags are present, enter Socratic Q&A mode:

1. Load the full research context from the most recent session:
   - Read `orient/landscape.md` for field context
   - Read `guides/key-concepts.md` for concept explanations
   - Read `guides/decision-log.md` for research decisions
   - Read `execute/log.md` for methodology details
   - Read `synthesize/assessment.json` for results

2. Answer the user's question using this context. Be conversational and educational.

3. After answering, ask a follow-up question that deepens understanding (Socratic method).

4. Continue the Q&A conversation as long as the user wants.

### --brief Mode

Generate a concise summary:
```markdown
# [Topic] — Key Takeaways

1. **The Problem:** [1 sentence]
2. **The Approach:** [1 sentence]
3. **Key Finding:** [1 sentence]
4. **Why It Matters:** [1 sentence]
5. **Limitation:** [1 sentence]
6. **What's Next:** [1 sentence]
7. **One Surprising Thing:** [1 sentence]
```

### --notebook Mode

Generate a Jupyter notebook (.ipynb JSON):
- Cell 1: Markdown introduction
- Cell 2-N: Alternating code cells (runnable experiments) and markdown cells (explanations)
- Final cell: Summary and exercises

Save to `$SESSION_DIR/guides/notebook.ipynb`

Only available for computational research sessions. If the session used theoretical/survey/empirical mode, explain that notebooks require code-based research.

### --audio Mode

Generate a podcast-style script:
```markdown
# [Topic] — Audio Script

**Host A:** [Enthusiastic explainer]
**Host B:** [Curious questioner]

---

**A:** Welcome to Theoria Explained. Today we're diving into [topic]...
**B:** So wait, what exactly is the problem here?
**A:** Great question. Basically...
```

Save to `$SESSION_DIR/guides/audio-script.md`

### --visual Mode

Generate an HTML file with:
- SVG diagrams for key concepts
- Charts for experimental results
- Visual timeline of the research process
- Interactive-style layout (even though static HTML)

Save to `$SESSION_DIR/guides/visual-summary.html`

### --for "audience" Mode

Regenerate explanations for the specified audience. This overrides the taste profile's assumed_background for this explanation:

1. Parse the audience description (e.g., "undergraduate biology student", "non-technical CEO", "domain expert in NLP")
2. Re-read all guide outputs
3. Generate a new explanation at the appropriate level
4. Save to `$SESSION_DIR/guides/explain-for-<audience-slug>.md`

This is one of Theoria's most novel features — audience-adaptive explanation from the same research.
