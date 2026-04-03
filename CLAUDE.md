# Theoria — Understanding-First Research Companion

You have the Theoria plugin installed. Theoria helps researchers conduct autonomous research sessions that produce three outputs:
1. **A publishable paper** (LaTeX, conference-ready)
2. **Educational companions** (understanding guides that explain the research)
3. **Compound knowledge** (structured findings that improve future sessions)

## Storage Layout

Theoria splits storage by purpose:

### Cross-project (user-level): `~/.theoria/`
- `~/.theoria/taste.json` — researcher taste profile
- `~/.theoria/knowledge/cards/` — knowledge cards (markdown with YAML frontmatter, grep-searchable)
- `~/.theoria/knowledge/graph.json` — knowledge graph index
- `~/.theoria/evolution.md` — self-improvement log (accumulated across sessions)
- `~/.theoria/audit.log` — audit trail
- `~/.theoria/config.json` — plugin config (API keys etc.)

### Project-local: `.theoria/`
- `.theoria/sessions/<slug>/` — session outputs (orient/, design/, execute/, paper/, guides/, etc.)
- `.theoria/sessions/<slug>/state.json` — session state
- `.theoria/implementations/<slug>/` — paper implementations

### Plugin infrastructure: `${CLAUDE_PLUGIN_DATA}`
- Only for caches and installed dependencies — nothing user-facing

The SessionStart hook creates `~/.theoria/` and subdirectories on first run.

## Core Commands

| Command | Purpose |
|---------|---------|
| `/theoria:explore <topic>` | Start a new research session |
| `/theoria:taste` | Calibrate your research taste profile |
| `/theoria:resume` | Continue an interrupted session |
| `/theoria:status` | Check current session progress |
| `/theoria:sessions` | List, clean, or archive sessions |
| `/theoria:explain <concept>` | Socratic Q&A or alternative explanations |
| `/theoria:prune` | Review weak knowledge cards — retire, merge, or boost |
| `/theoria:rebuttal [session]` | Mock peer reviews + rebuttal drafts for pre-submission confidence |
| `/theoria:evolve` | View self-improvement log and apply suggested improvements |
| `/theoria:implement <paper>` | Implement a research paper as citation-anchored code |
| `/theoria:publish [session]` | Bundle and upload session artifacts to theoria.shehral.com |
| `/theoria:login` | Authenticate with GitHub for publishing access |
| `/theoria:setup-autonomous` | Configure Tier 2/3 autonomy |

## Research Loop

Every research session follows this loop:

1. **ORIENT** — Search literature, build field landscape, identify gaps
2. **DESIGN** (checkpoint) — Propose directions, score against taste, get human approval
3. **EXECUTE** — Conduct research (computational, theoretical, survey, or empirical mode)
4. **SYNTHESIZE** (checkpoint) — Review results, flag uncertainties, get human approval
5. **WRITE** — Generate LaTeX paper with venue-aware template
6. **REVIEW** — Quality gate (citation verification, claim-evidence binding, plagiarism check)
7. **NARRATE** — Generate understanding guides (field landscape, key concepts, decisions, methodology)
8. **COMPOUND** — Extract knowledge cards for future sessions

## Taste Profile

The researcher's taste profile (stored in `~/.theoria/taste.json`) shapes every stage:
- **risk_tolerance**: conservative/moderate/aggressive — affects experiment scope and direction selection
- **novelty_vs_rigor**: 0.0-1.0 — affects statistical thresholds and framing
- **theory_vs_empirical**: 0.0-1.0 — selects EXECUTE mode and paper structure
- **contribution_type**: what kind of work they value
- **venues**: target conferences/journals
- **writing_style**: tone, density, audience
- **learning_style**: how understanding guides are generated

Always load and respect the taste profile. If no taste profile exists, suggest running `/theoria:taste` first.

### Taste Behavioral Mappings

**risk_tolerance:**
- `conservative` → max 3 experiments, each building on validated results. DESIGN proposes only well-supported directions. ORIENT prioritizes highly-cited established work.
- `moderate` → up to 5 experiments, 1-2 speculative. DESIGN includes one higher-risk option alongside safe choices.
- `aggressive` → up to 10 experiments, including speculative approaches. DESIGN actively seeks contrarian or underexplored directions.

**novelty_vs_rigor (0.0 = pure rigor, 1.0 = pure novelty):**
- `0.0-0.3` → SYNTHESIZE applies strict statistical thresholds (p<0.01). WRITE emphasizes methodology and reproducibility.
- `0.4-0.6` → Balanced. Standard statistical thresholds (p<0.05). WRITE balances novelty claims with rigorous evaluation.
- `0.7-1.0` → SYNTHESIZE accepts weaker evidence for novel findings. WRITE leads with the novelty angle.

**theory_vs_empirical (0.0 = pure theory, 1.0 = pure empirical):**
- `0.0-0.3` → EXECUTE uses theoretical mode. WRITE emphasizes formal results and proofs.
- `0.4-0.6` → Mixed. EXECUTE combines theoretical analysis with empirical validation.
- `0.7-1.0` → EXECUTE uses computational mode. WRITE emphasizes experimental results and ablations.

## Session State

Sessions are stored at `.theoria/sessions/<slug>/` (project-local). Each session has:
- `state.json` — current stage, completed stages, human decisions, timestamps
- Stage subdirectories: `orient/`, `design/`, `execute/`, `synthesize/`, `paper/`, `guides/`, `review/`, `knowledge/`

Always save state after completing each stage. This enables `/theoria:resume` to recover from interruptions.

## Agent Dispatch Rules

When dispatching research agents, use the `theoria:` namespace:

| Agent | Tools | disallowedTools | Purpose |
|-------|-------|-----------------|---------|
| `theoria:orient` | Read Write Grep Glob Bash WebFetch WebSearch | Edit | Literature search. Write for incremental saves (prevents context overflow). No Edit. |
| `theoria:experimenter` | Read Write Edit Bash Grep Glob WebFetch WebSearch | — | Research execution. Full access for code/analysis. |
| `theoria:synthesizer` | Read Grep Glob | Write Edit Bash WebFetch WebSearch | Result review. Read-only, no network. |
| `theoria:writer` | Read Write Edit Grep Glob | WebFetch WebSearch | Paper generation. No network (prevents citation fabrication). |
| `theoria:reviewer` | Read Grep Glob | Write Edit Bash WebFetch WebSearch | Quality gate. Read-only, no network. |
| `theoria:curator` | Read Grep Glob | Write Edit Bash WebFetch WebSearch | Knowledge quality gate. Read-only, no network. |
| `theoria:mock-reviewer` | Read Grep Glob | Write Edit Bash WebFetch WebSearch | Mock peer review. Read-only, no network. |
| `theoria:narrator` | Read Write Grep Glob | WebFetch WebSearch Bash | Guide generation. No network or code execution. |

These `disallowedTools` restrictions are system-enforced by Claude Code (tools are completely removed from the agent's context).

## Knowledge System

Knowledge cards are **markdown files with YAML frontmatter** stored in `~/.theoria/knowledge/cards/<id>.md` (cross-project). The YAML frontmatter contains structured metadata (id, domain, tags, methods, confidence, etc.) and the markdown body contains human-readable findings, limitations, implementation gotchas, and connections.

This format is:
- **Grep-searchable**: `grep -l "domain: efficient-transformers" ~/.theoria/knowledge/cards/*.md`
- **Human-readable**: open any card and understand it immediately
- **Machine-parseable**: YAML frontmatter can be parsed by Python/Node for the graph index

The graph index at `~/.theoria/knowledge/graph.json` tracks relationships between cards:
- `builds-on` — this finding extends prior work
- `contradicts` — this finding conflicts with a prior card (both preserved, surfaced during ORIENT)
- `related-to` — topically connected
- `supersedes` — this card replaces a retired/merged card

### Memory Model (Neuroscience-Grounded)

Each knowledge card has a `memory` block in its YAML frontmatter:
- `strength` (0.0-1.0) — Hebbian strength, increases on access, decays over time
- `access_count` — how many times orient has referenced this card
- `last_accessed` — timestamp of last orient reference
- `created_strength` — initial strength from curator (ACCEPT=0.7, ACCEPT_WITH_CAVEAT=0.4)
- `decay_rate` — Ebbinghaus decay rate per day (default 0.02, halves in ~35 days)

**Hebbian strengthening**: When orient references a card: `new_strength = min(1.0, old_strength + 0.1)`, `access_count += 1`, `last_accessed = now`.

**Ebbinghaus decay**: Computed on read: `effective_strength = strength * (1 - decay_rate) ^ days_since_access`.

**Pruning**: Cards with effective strength < 0.3 or not accessed in 60+ days are surfaced by `/theoria:prune` for review, merge, or retirement to `~/.theoria/knowledge/archive/`.

Always check the knowledge base during ORIENT for prior findings on related topics. Use grep on frontmatter fields for fast discovery. When referencing a card, apply Hebbian strengthening to keep useful knowledge strong.

## Human Checkpoints

Two checkpoints are mandatory (even in autonomous mode):
1. **DESIGN checkpoint**: After proposing directions, WAIT for human approval before executing.
2. **SYNTHESIZE checkpoint**: After reviewing results, WAIT for human approval before writing.

These are enforced by SubagentStop hooks.

## Running Narration

During ORIENT and EXECUTE, produce lightweight commentary saved to `guides/running-notes.md`. This gives the researcher real-time understanding of what's happening. In autonomous mode, these notes accumulate for later reading.

## AI Disclosure

Auto-insert AI-assistance disclosure in every paper's acknowledgments section. Use venue-specific language when available. The researcher can customize or disable via taste profile. Record the decision in the session's decision log.

## Publishing

Theoria can publish research sessions to [theoria.shehral.com](https://theoria.shehral.com).

### Auth Flow
1. User runs `/theoria:login` — opens browser to theoria.shehral.com/auth/login
2. User signs in with GitHub OAuth
3. User copies the `thpub_` token from the page and pastes it in Claude
4. Token saved to `~/.theoria/auth.json`

### What Gets Published
- **Paper**: PDF (base64-encoded) + LaTeX source + citation metadata
- **Guide**: MDX content from the narrate stage (field landscape, key concepts, decision log, methodology)
- **Implementation**: Code files + README from the implement stage

### Publish Bundle
Format version: `1.0.0`. The bundle includes session metadata, paper, guide, and implementation sections. Each section is optional — publish what you have.

### Published URLs
After publishing, artifacts are available at:
- `theoria.shehral.com/sessions/<id>` — full session view
- `theoria.shehral.com/papers/<id>` — paper viewer
- `theoria.shehral.com/guides/<id>` — Distill-style interactive guide
- `theoria.shehral.com/implementations/<id>` — code walkthrough

### Requirements
- Completed session (at least through WRITE stage)
- Auth token from `/theoria:login`

## Failure Handling

When a stage fails:
- Save partial results and current state before surfacing the error
- Present the failure clearly with what was accomplished and what failed
- Suggest recovery options (retry, broaden scope, pivot, or stop and compound what was learned)
- Never silently skip a failure — the decision log must record it
