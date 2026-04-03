# Theoria

> *In ancient Greece, a **theoros** was an envoy sent to observe sacred festivals in other cities — a sacred spectator. **Theoria** meant "the act of witnessing something profound." Aristotle elevated it to mean contemplation, the highest human activity. The word only became "theory" (abstract hypothesis) much later.*

**Theoria** is an understanding-first autonomous research companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It produces publishable papers AND educational companions that help humans understand.

## Install

```bash
# Add the Theoria marketplace (one-time)
claude plugin marketplace add shehral/theoria

# Install the plugin
claude plugin install theoria
```

## What It Does

Every research session produces three outputs:

1. **A publishable paper** — LaTeX, conference-ready, with verified citations
2. **Educational companions** — guides, concept maps, and decision logs that explain what was done and why
3. **Compound knowledge** — structured findings that make future sessions smarter

## Commands

| Command | What It Does |
|---------|-------------|
| `/theoria:explore <topic>` | Full research session: literature search, direction selection, execution, paper + guides |
| `/theoria:taste` | Set up your research profile (domains, venues, risk tolerance, writing style) |
| `/theoria:implement <paper>` | Turn a research paper into citation-anchored code |
| `/theoria:rebuttal` | Generate mock peer reviews and draft rebuttals |
| `/theoria:resume` | Continue an interrupted session |
| `/theoria:explain <concept>` | Ask anything about your research. Supports `--brief`, `--for "audience"` |
| `/theoria:sessions` | List, clean, or archive research sessions |
| `/theoria:status` | Session progress dashboard |
| `/theoria:prune` | Review weak knowledge cards |
| `/theoria:evolve` | View how Theoria has improved over time |
| `/theoria:setup-autonomous` | Configure for long-running unattended sessions |

## Quick Start

```bash
# 1. Add marketplace + install (one-time)
claude plugin marketplace add shehral/theoria
claude plugin install theoria

# 2. Set up your research profile (~2 min)
/theoria:taste

# 3. Start researching
/theoria:explore "your research topic"
```

The system will search literature, propose directions (and wait for your input), execute the research, review results (and wait for your input again), then generate a paper and understanding guides.

## The Research Loop

```
ORIENT → DESIGN → EXECUTE → SYNTHESIZE → WRITE → REVIEW → NARRATE → COMPOUND
            ★                     ★
      (your input)          (your input)
```

Two human checkpoints ensure your judgment shapes the research:
- **DESIGN**: Choose which direction to pursue from proposed options
- **SYNTHESIZE**: Validate results and decide what claims to make

Everything else runs autonomously.

## Research Agents

Theoria dispatches specialized agents for each stage:

| Agent | Role | Access |
|-------|------|--------|
| **orient** | Literature search, field landscape, gap analysis | Network + write (incremental saves) |
| **experimenter** | Research execution (computational, theoretical, survey, empirical) | Full access |
| **synthesizer** | Result validation, uncertainty flagging | Read-only |
| **writer** | LaTeX paper generation | No network (prevents citation fabrication) |
| **reviewer** | Quality gate: citation verification, plagiarism check | Read-only |
| **narrator** | Understanding guides + unified PDF | No network or code |
| **implementer** | Paper-to-code with citation anchoring | Full access |
| **curator** | Knowledge quality gate | Read-only |
| **mock-reviewer** | Simulates conference peer reviewers | Read-only |

Agents that evaluate work cannot modify it. This is enforced at the system level, not just instructions.

## Research Taste

Theoria learns what you value as a researcher and uses it to shape every stage:

- **Risk tolerance** — conservative (validated steps) to aggressive (bigger bets)
- **Novelty vs. rigor** — affects statistical thresholds and paper framing
- **Theory vs. empirical** — selects execution mode and paper structure
- **Writing style** — formal/accessible/narrative, density, audience
- **Target venues** — calibrates paper formatting and review strictness

Run `/theoria:taste` to configure.

## Knowledge System

Each session compounds knowledge for future sessions:

- **Curator-gated** — a quality gate evaluates findings before they enter the knowledge base
- **Hebbian strengthening** — frequently referenced findings get stronger
- **Ebbinghaus decay** — unused findings gradually weaken
- **Searchable frontmatter** — knowledge cards are markdown with YAML tags, grep-searchable
- **Contradiction tracking** — conflicting findings are preserved and surfaced

Run `/theoria:prune` to review weak cards. Run `/theoria:evolve` to see how the system has improved.

## Paper Implementation

Turn any research paper into code:

```bash
/theoria:implement arxiv.org/abs/2401.12345
/theoria:implement "Attention Is All You Need" --full --pytorch
```

Every line is citation-anchored. Every unspecified choice is flagged. Includes a walkthrough Jupyter notebook.

## Mock Peer Review

Get feedback before submitting:

```bash
/theoria:rebuttal
```

Generates 3 reviews from different perspectives (methodologist, domain expert, skeptic), calibrated to your target venue, plus a point-by-point rebuttal draft and revision plan.

## Self-Evolution

Theoria learns from its own failures. After each session, it categorizes what went wrong and writes improvement suggestions to a living log. Over time, the system gets better at research — not just at accumulating findings.

Run `/theoria:evolve` to see the improvement history.

## Storage

| Data | Location | Scope |
|------|----------|-------|
| Taste profile | `~/.theoria/taste.json` | All projects |
| Knowledge cards | `~/.theoria/knowledge/cards/` | All projects |
| Evolution log | `~/.theoria/evolution.md` | All projects |
| Session outputs | `.theoria/sessions/` | Current project |
| Implementations | `.theoria/implementations/` | Current project |

Cross-project data lives in `~/.theoria/`. Session outputs stay with the project.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with a Max or Pro subscription
- That's it. No API keys required (Semantic Scholar free tier works). Optional: Semantic Scholar API key for higher rate limits.

## Why "Theoria"

In 6th century BCE Greece, city-states sent their most perceptive citizens to observe sacred festivals in other cities. These **theoroi** weren't tourists — they were official envoys tasked with witnessing something important and bringing that understanding home. Aristotle elevated the concept to mean the highest form of human activity: pure contemplation, where the mind observes deeply enough to truly understand.

The word became "theory" in English, losing its original weight. Theoria reclaims it. We send agents into the research landscape not to produce, but to comprehend.

## Links

- **Website**: [theoria.shehral.com](https://theoria.shehral.com) (coming soon)
- **Author**: [Ali Shehral](https://shehral.com)

## License

Apache 2.0
