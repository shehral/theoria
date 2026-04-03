---
name: evolve
description: View Theoria's self-improvement log and apply suggested improvements
disable-model-invocation: true
---

# Theoria Evolve — Self-Improvement Log

View and act on Theoria's accumulated self-improvement suggestions. These are generated at the end of each research session by analyzing failures, suboptimal outcomes, and course corrections.

## Current Evolution Log

!`cat "$HOME/.theoria/evolution.md" 2>/dev/null || echo "No evolution log found. Complete a research session with /theoria:explore to generate self-improvement data."`

---

## How to Read This

The evolution log accumulates across all research sessions. Each entry records:
- **Session**: Which session produced the observation
- **Issues Found**: Categorized problems with specific improvement suggestions
- **What Worked Well**: Patterns to preserve and reinforce

### Issue Categories

| Category | Meaning |
|----------|---------|
| `search-quality` | Orient did not find good papers, had to broaden too many times |
| `direction-quality` | Proposed directions were weak, user rejected multiple times |
| `execution-failure` | Experiments crashed, code errors, resource limits hit |
| `synthesis-gap` | Claims did not hold up, too many uncertainties flagged |
| `writing-quality` | Reviewer found issues, citation problems |
| `explanation-quality` | Guides needed regeneration, audience mismatch |

## Trend Analysis

To see which categories are persistent problems, ask:

> "Which issue categories appear most frequently across sessions?"

Theoria will scan the evolution log and report:
- How many sessions each category appeared in
- Whether the frequency is increasing or decreasing
- Which specific suggestions have been made repeatedly (indicating they should be applied)

## Applying Suggestions

You can ask to apply specific suggestions from the log. This means:
- Updating agent prompts (e.g., adding a new search source to the orient agent)
- Adding patterns to CLAUDE.md (e.g., a default behavior change)
- Adjusting default parameters (e.g., adaptive batch sizing)

To apply a suggestion, say something like:

> "Apply the suggestion about searching SSRN for finance topics"
> "Apply all persistent search-quality suggestions"

Theoria will show you the proposed changes for approval before making them.

## Key Insight

This is different from knowledge compounding (which is about research findings). Self-evolution is about the research **process** improving. The system literally gets better at research over time by learning from its own failures.
