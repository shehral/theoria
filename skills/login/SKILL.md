---
name: login
description: Authenticate with GitHub for publishing research to theoria.shehral.com
disable-model-invocation: true
---

# Theoria Login

Authenticate with theoria.shehral.com to enable publishing research sessions.

## Current Auth Status

!`cat "$HOME/.theoria/auth.json" 2>/dev/null && echo "" && echo "Token already configured." || echo "No auth token found."`

## Instructions

### If a token already exists

Show the user when it was created (from auth.json `created_at`). Ask if they want to replace it. If not, exit.

### Authentication Flow

1. Open the login page in the user's default browser:

```bash
# macOS
open "https://theoria.shehral.com/auth/login" 2>/dev/null || \
# Linux
xdg-open "https://theoria.shehral.com/auth/login" 2>/dev/null || \
echo "Open this URL in your browser: https://theoria.shehral.com/auth/login"
```

2. Tell the user:

> Sign in with GitHub in your browser. After authentication, you'll see a publish token on the page. Copy it and paste it here.

3. Wait for the user to paste their token.

4. Validate the token format — it should start with `thpub_`. If it doesn't:

> That doesn't look like a Theoria publish token (should start with `thpub_`). Please copy the full token from the page at theoria.shehral.com/auth/token.

5. Save the token:

```bash
mkdir -p "$HOME/.theoria"
cat > "$HOME/.theoria/auth.json" << EOF
{
  "token": "<pasted_token>",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

6. Verify the token works by checking the API response code:

```bash
TOKEN="<pasted_token>"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "https://theoria.shehral.com/api/publish")
echo "API response: $HTTP_CODE"
```

- `400` = Token is valid (rejected because no body, not because of auth). Success.
- `401` = Token is invalid. Ask user to try again.
- `403` = Token is expired or revoked. Ask user to re-authenticate.
- Other = Network or server error. Token might be fine, suggest trying `/theoria:publish` anyway.

7. Confirm:

> Authenticated successfully. You can now publish research sessions with `/theoria:publish`.
