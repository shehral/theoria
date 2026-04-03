---
name: setup-autonomous
description: Configure Theoria for autonomous long-running research sessions (Tier 2/3 autonomy)
disable-model-invocation: true
---

# Theoria Autonomous Setup

This skill helps you configure your Claude Code settings for autonomous research sessions. Theoria itself cannot modify your user or project settings -- you apply the configuration yourself.

## Current Settings

!`cat .claude/settings.json 2>/dev/null || echo "No project settings found (.claude/settings.json does not exist)."`

## Autonomy Tiers

Theoria supports three levels of autonomy:

### Tier 1: Interactive (Default)

Standard Claude Code permissions. The system pauses for approval on every sensitive action (file writes, bash commands, network requests).

- **Best for:** First-time users, unfamiliar research domains, learning how Theoria works
- **No configuration needed** -- this is the default behavior

### Tier 2: Sandbox + Bypass (Recommended)

Pre-approved permission rules let research run unattended. Dangerous operations are explicitly denied. Human checkpoints at DESIGN and SYNTHESIZE are still enforced via SubagentStop hooks.

- **Best for:** Experienced users running multi-hour research sessions
- **Requires:** Adding permission rules to your `.claude/settings.json`

### Tier 3: Full Autonomy

Everything from Tier 2, plus extended turn limits for overnight or HPC sessions. The audit log becomes your primary review mechanism.

- **Best for:** Overnight sessions on dedicated machines, HPC clusters, batch research
- **Requires:** Permission rules + agent configuration in `.claude/settings.json`, plus a commitment to reviewing the audit log afterward

## Configuration

### Tier 2 Settings

Add this to your project's `.claude/settings.json` (or your user-level `~/.claude/settings.json`):

```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *)",
      "Bash(uv run *)",
      "Bash(pip install *)",
      "Bash(tectonic *)",
      "Bash(curl -s https://api.semanticscholar.org/*)",
      "Bash(curl -s https://export.arxiv.org/*)",
      "Bash(curl -sL https://arxiv.org/pdf/*)",
      "Bash(mkdir *)",
      "Bash(cat *)",
      "Bash(ls *)",
      "Bash(jq *)",
      "Bash(chmod *)",
      "Write(*)",
      "Edit(*)",
      "Read(*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(* --force *)",
      "Bash(* --hard *)",
      "Bash(chmod 777 *)",
      "Write(.env*)",
      "Write(*credentials*)",
      "Write(*secret*)"
    ]
  }
}
```

### Tier 3 Settings

Same permission rules as Tier 2, plus an agent turn limit:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *)",
      "Bash(uv run *)",
      "Bash(pip install *)",
      "Bash(tectonic *)",
      "Bash(curl -s https://api.semanticscholar.org/*)",
      "Bash(curl -s https://export.arxiv.org/*)",
      "Bash(curl -sL https://arxiv.org/pdf/*)",
      "Bash(mkdir *)",
      "Bash(cat *)",
      "Bash(ls *)",
      "Bash(jq *)",
      "Bash(chmod *)",
      "Write(*)",
      "Edit(*)",
      "Read(*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(* --force *)",
      "Bash(* --hard *)",
      "Bash(chmod 777 *)",
      "Write(.env*)",
      "Write(*credentials*)",
      "Write(*secret*)"
    ]
  },
  "agent": {
    "maxTurns": 100
  }
}
```

## Important Notes

- **These settings live in YOUR config, not the plugin's.** Theoria cannot set these for you. The plugin's hooks and agent dispatch rules are separate from Claude Code's permission system.
- **Human checkpoints are STILL enforced in bypass mode.** The DESIGN checkpoint (after orient) and SYNTHESIZE checkpoint (after synthesizer) are implemented as SubagentStop hooks. These fire regardless of your permission settings and will pause the session for human review.
- **The deny list is your safety net.** It prevents destructive commands (`rm -rf`, `sudo`, `--force`, `--hard`) and blocks writing to sensitive files (`.env`, credentials, secrets).
- **Start with Tier 2** for your first autonomous session to verify everything works before moving to Tier 3.

## After Applying Settings

Review the audit log after every autonomous session:

```
cat ~/.theoria/audit.log
```

## Verification

After applying your settings, test the setup:

1. Run `/theoria:explore "test topic"` and verify the orient stage runs without permission prompts
2. Verify the DESIGN checkpoint still pauses for human input (it should, even in bypass mode)
3. Check that `~/.theoria/audit.log` is being populated with tool_use events
