#!/bin/bash
# SessionStart hook — loads taste profile into Claude's context
# Fires on: startup, resume

# Ensure cross-project storage exists
mkdir -p "$HOME/.theoria/knowledge/cards"

TASTE_FILE="$HOME/.theoria/taste.json"
if [ -f "$TASTE_FILE" ]; then
  DOMAINS=$(jq -r '.researcher.domains // [] | join(", ")' "$TASTE_FILE" 2>/dev/null || echo "unknown")
  RISK=$(jq -r '.preferences.risk_tolerance // "moderate"' "$TASTE_FILE" 2>/dev/null || echo "moderate")
  NOVELTY=$(jq -r '.preferences.novelty_vs_rigor // 0.5' "$TASTE_FILE" 2>/dev/null || echo "0.5")
  THEORY=$(jq -r '.preferences.theory_vs_empirical // 0.5' "$TASTE_FILE" 2>/dev/null || echo "0.5")
  VENUES=$(jq -r '.preferences.venues // [] | join(", ")' "$TASTE_FILE" 2>/dev/null || echo "none set")
  BACKGROUND=$(jq -r '.learning_style.assumed_background // "graduate-cs"' "$TASTE_FILE" 2>/dev/null || echo "graduate-cs")
  SESSIONS=$(jq -r '.compound.sessions_completed // 0' "$TASTE_FILE" 2>/dev/null || echo "0")
  echo "THEORIA TASTE PROFILE LOADED:"
  echo "  Domains: $DOMAINS"
  echo "  Risk: $RISK | Novelty/Rigor: $NOVELTY | Theory/Empirical: $THEORY"
  echo "  Venues: $VENUES"
  echo "  Background: $BACKGROUND"
  echo "  Sessions completed: $SESSIONS"
  echo ""
  echo "Respect these preferences in all research decisions. Run /theoria:taste to update."
else
  echo "THEORIA: No taste profile found. Run /theoria:taste to create your research profile before starting a session."
fi
