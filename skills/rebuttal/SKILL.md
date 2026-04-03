---
name: rebuttal
description: Generate mock peer reviews of your paper and draft rebuttals — pre-submission confidence builder
argument-hint: "[session-name]"
disable-model-invocation: true
effort: high
---

# Theoria Rebuttal — Mock Review + Rebuttal Draft

Pre-submission confidence builder. Generates 3 mock peer reviews from different perspectives, then drafts point-by-point rebuttals.

## Session Context

!`ls .theoria/sessions/ 2>/dev/null | grep -v archive | tail -1 || echo "No sessions found."`

!`cat "$HOME/.theoria/taste.json" 2>/dev/null | grep -o '"venues":[^]]*]' || echo "No venue preference set."`

## Instructions

### Step 1: Load the Paper

If $ARGUMENTS specifies a session name, use that. Otherwise use the most recent session.

Read:
- `.theoria/sessions/<slug>/paper/main.tex` (the paper)
- `.theoria/sessions/<slug>/orient/papers.json` (literature corpus)
- `.theoria/sessions/<slug>/synthesize/claims.json` or `synthesize/assessment.json` (self-assessment)
- `.theoria/sessions/<slug>/review/quality-report.json` (automated review)

If the paper hasn't been written yet (no paper/main.tex), inform the user and suggest running `/theoria:explore` first.

### Step 2: Determine Target Venue

Check the taste profile for preferred venues. Use the first venue as the target for calibrating review strictness. If no venue set, use "generic" (moderate strictness).

### Step 3: Generate 3 Mock Reviews

Dispatch the `theoria:mock-reviewer` agent THREE times, each with a different persona:

**Review 1 — Methodologist:**
Dispatch with persona="Methodologist". Focus: experimental design, statistical rigor, reproducibility.

**Review 2 — Domain Expert:**
Dispatch with persona="Domain Expert". Focus: novelty, positioning, missing citations.

**Review 3 — Skeptic:**
Dispatch with persona="Skeptic". Focus: overclaiming, limitations, failure modes.

Pass each reviewer:
- The paper content
- The orient corpus
- The synthesize assessment
- The quality report
- The persona instruction
- The target venue for strictness calibration

### Step 4: Synthesize Reviews

After all 3 reviews are received, analyze:
- **Consensus issues**: weaknesses mentioned by 2+ reviewers (highest priority to address)
- **Unique insights**: weaknesses only one reviewer caught (may be persona-specific or genuine blind spots)
- **Overall assessment**: average score, range, likely outcome at target venue
- **Strongest defense**: which strengths were universally recognized

### Step 5: Draft Rebuttal

Write a rebuttal that addresses every weakness point-by-point:

```markdown
# Rebuttal Draft

## Meta-Review Summary
- Average score: X/10 | Range: [low]-[high]
- Consensus strengths: [list]
- Consensus weaknesses: [list]
- Likely outcome at [venue]: [assessment]

## Point-by-Point Responses

### R1-W1: [Weakness from Reviewer 1]
**Reviewer said:** "[exact quote]"
**Response:** [Address the concern directly. Either:]
- **Accept + propose fix:** "We agree this is a limitation. We will add [specific revision]."
- **Partially accept:** "While [aspect] is valid, we note that [defense]. We will clarify [revision]."
- **Defend:** "We respectfully disagree because [evidence from the paper/experiments]."

### R1-W2: [Next weakness]
...

## Revision Plan (Priority Order)

### Critical (address before submission)
1. [Revision with specific section/experiment to add]
2. [Revision]

### Important (would strengthen the paper)
3. [Revision]
4. [Revision]

### Minor (nice to have)
5. [Revision]
```

### Step 6: Save Outputs

Create the rebuttal directory and save all outputs:

```bash
SLUG="<session-slug>"
mkdir -p ".theoria/sessions/$SLUG/rebuttal"
```

Save these files:
- `.theoria/sessions/<slug>/rebuttal/review-1-methodologist.md`
- `.theoria/sessions/<slug>/rebuttal/review-2-domain-expert.md`
- `.theoria/sessions/<slug>/rebuttal/review-3-skeptic.md`
- `.theoria/sessions/<slug>/rebuttal/rebuttal-draft.md`
- `.theoria/sessions/<slug>/rebuttal/revision-plan.md`

Update the session state.json to record that rebuttal was generated.

### Step 7: Present to User

Show:
1. A summary table of all 3 reviews (scores, recommendations)
2. The consensus issues (most important to address)
3. The revision plan (prioritized)
4. Ask if they want to read any specific review in full

Note: The rebuttal is a DRAFT. The researcher should review and personalize it before submission. Real reviewers will ask different questions — this is for preparation, not prediction.
