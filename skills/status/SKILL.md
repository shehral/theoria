---
name: status
description: Show current research session progress and stage details
disable-model-invocation: true
---

# Theoria Status

## Active Session

!`ls -t ".theoria/sessions" 2>/dev/null | grep -v archive | head -1 || echo "No sessions found. Run /theoria:explore to start one."`

!`cat ".theoria/sessions/$(ls -t ".theoria/sessions" 2>/dev/null | grep -v archive | head -1)/state.json" 2>/dev/null || echo ""`

## Taste Profile

!`cat "$HOME/.theoria/taste.json" 2>/dev/null || echo "No taste profile. Run /theoria:taste to create one."`

Based on the session state above, present a clear dashboard showing:
- Session name and topic
- Current stage and completed stages
- For each completed stage, list what files were produced (read the session directory)
- Knowledge base stats (check ~/.theoria/knowledge/)
- Taste profile summary

If the user asks for details about a specific stage, read and summarize the outputs from that stage's directory.
