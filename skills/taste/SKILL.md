---
name: taste
description: Calibrate your research taste profile — shapes how Theoria conducts research, selects directions, and generates explanations
argument-hint: "[update|reset|show]"
disable-model-invocation: true
---

# Theoria Taste Calibration

## Current Profile

!`cat "$HOME/.theoria/taste.json" 2>/dev/null || echo "No taste profile found. Let us create one."`

## Instructions

If the user said "update" or "reset", or if no profile exists, conduct the taste calibration interview below. If they said "show", just display the profile above.

### Calibration Interview

Ask these questions ONE AT A TIME. Wait for each answer before asking the next. Be conversational, not robotic.

**1. Identity & Affiliation** (used for paper authorship)
- What's your full name? (as it should appear on papers)
- Email address? (for paper contact info)
- Department or school? (e.g., "Khoury College of Computer Sciences")
- University or organization?
- City, State/Country? (e.g., "San Jose, California")
- Any lab affiliations? (only if you want them on papers — leave blank if none)
- What's your primary research domain(s)? (Can be multiple, e.g., "machine learning and computational biology")
- How would you describe your research experience? (undergraduate / graduate researcher / postdoc / faculty / industry researcher / curious generalist)

**2. Research Preferences**
- What kind of contributions do you value most? Pick 1-3:
  a) Novel theoretical results
  b) Strong empirical improvements
  c) Empirical work with theoretical justification
  d) New frameworks or tools
  e) Comprehensive surveys
  f) Systems work
  g) Benchmarks or datasets
- Where do you typically publish or plan to submit? (e.g., NeurIPS, ICML, ACL, Nature, IEEE, etc.)
- How would you rate your risk tolerance for research directions?
  - Conservative (validated incremental steps, strong baselines)
  - Moderate (balanced, some novel methodology)
  - Aggressive (bigger bets, unconventional directions)
- On a scale of 0 to 10, how much do you value novelty vs. rigor? (0 = pure rigor, 10 = pure novelty)
- On a scale of 0 to 10, how theoretical vs. empirical is your work? (0 = pure theory, 10 = pure empirical)
- Any core research values you'd like Theoria to respect? (e.g., "reproducibility over cleverness", "understand why, not just what")

**3. Writing Style** (optional but recommended)
- How would you describe your preferred paper writing style?
  - Formal and precise
  - Formal but accessible
  - Conversational academic
  - Technical narrative
- How detailed should papers be? (concise / detailed / comprehensive)
- Any example papers whose style you admire? (arXiv IDs are perfect)

**4. Research Style** (optional)
- How thorough should ablation studies be? (minimal / standard / thorough)
- How rigorously should we compare against baselines? (minimal / standard / always)
- Any researchers or labs whose work you follow closely?

**5. Learning Style**
- How do you prefer to learn new concepts?
  a) Written explanations
  b) Visual diagrams and concept maps
  c) Interactive code (Jupyter notebooks)
  d) Conversational Q&A
  e) Mix of everything
- How deep should understanding guides go? (overview / detailed / comprehensive)
- What background should explanations assume? (beginner / undergraduate / graduate CS / domain expert)

### After Collecting All Answers

Create the taste profile JSON and save it:

```bash
mkdir -p "$HOME/.theoria"
cat > "$HOME/.theoria/taste.json" << 'TASTE_EOF'
{
  "version": "1.0.0",
  "created_at": "<ISO timestamp>",
  "updated_at": "<ISO timestamp>",
  "researcher": {
    "name": "<full name from Q1>",
    "email": "<from Q1>",
    "affiliation": {
      "department": "<from Q1 or null>",
      "institution": "<from Q1>",
      "location": "<city, state/country from Q1>",
      "lab": "<from Q1 or null — only if user provided>"
    },
    "domains": ["<from Q1>"],
    "expertise_level": "<from Q1>"
  },
  "preferences": {
    "contribution_type": ["<from Q2>"],
    "venues": ["<from Q2>"],
    "risk_tolerance": "<from Q2>",
    "novelty_vs_rigor": <0.0-1.0 from Q2, divide answer by 10>,
    "theory_vs_empirical": <0.0-1.0 from Q2, divide answer by 10>,
    "values": ["<from Q2>"],
    "writing_style": {
      "tone": "<from Q3>",
      "density": "<from Q3>",
      "audience": "graduate-researchers",
      "example_papers": ["<from Q3>"]
    },
    "research_style": {
      "ablation_preference": "<from Q4>",
      "baseline_comparison": "<from Q4>",
      "statistical_rigor": "medium"
    },
    "following": {
      "researchers": ["<from Q4>"],
      "labs": ["<from Q4>"],
      "topics_rss": []
    }
  },
  "learning_style": {
    "primary": "<from Q5>",
    "preferred_formats": ["<from Q5>"],
    "depth": "<from Q5>",
    "assumed_background": "<from Q5>"
  },
  "compound": {
    "sessions_completed": 0,
    "domains_explored": [],
    "knowledge_cards": 0
  }
}
TASTE_EOF
```

Confirm the profile was saved. Display a summary table showing the key preferences. Mention that the profile will shape all future research sessions.
