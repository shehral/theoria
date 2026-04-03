#!/bin/bash
# SubagentStop hook — enforces human checkpoints after orient and synthesizer.
# These are the two mandatory review gates in every research session.
# Even in autonomous/bypass mode, these checkpoints pause for human judgment.

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_name // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_DIR="$HOME/.theoria"
mkdir -p "$LOG_DIR"

# Log the checkpoint event
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"checkpoint\", \"after_agent\": \"$AGENT\"}" >> "$LOG_DIR/audit.log"

if [ "$AGENT" = "orient" ]; then
  echo "DESIGN CHECKPOINT: Literature search complete. Review the findings and select a research direction before proceeding."
elif [ "$AGENT" = "synthesizer" ]; then
  echo "SYNTHESIZE CHECKPOINT: Result review complete. Review the assessment and confirm claims before writing the paper."
fi
