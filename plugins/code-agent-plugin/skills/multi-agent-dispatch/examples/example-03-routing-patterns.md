# Example 3: Pattern-Based Routing

Configure automatic routing so tasks go to the best agent based on file paths.

## Setup

Edit `~/.multi-agent-dispatch/config.json`:

```json
{
  "version": "1.0",
  "routes": [
    { "pattern": "src/ui/*", "agent": "gemini" },
    { "pattern": "src/components/*", "agent": "gemini" },
    { "pattern": "src/api/*", "agent": "codex" },
    { "pattern": "src/services/*", "agent": "codex" },
    { "pattern": "src/auth/*", "agent": "claude" },
    { "pattern": "src/security/*", "agent": "claude" },
    { "pattern": "*", "agent": "codex" }
  ],
  "parallelism": 3,
  "timeout_seconds": 1800
}
```

## Usage

```bash
# Routes to gemini (matches src/ui/*)
./scripts/dispatch.sh route src/ui/Button.tsx "Add disabled state and loading spinner"

# Routes to codex (matches src/api/*)
./scripts/dispatch.sh route src/api/users.ts "Add pagination to the list endpoint"

# Routes to claude (matches src/auth/*)
./scripts/dispatch.sh route src/auth/tokens.ts "Review token refresh logic for race conditions"

# Routes to codex (fallback default)
./scripts/dispatch.sh route README.md "Update installation instructions"
```

## Output

```
[INFO] Routing src/ui/Button.tsx -> gemini
[INFO] Dispatching to gemini: route-1711800000
[OK] Session created: route-1711800000
[INFO] Executing in gemini session=route-1711800000

--- Output from gemini (route-1711800000) ---
Updated Button.tsx with:
- Added `disabled` prop with visual styling (opacity + cursor)
- Added `loading` prop with animated spinner SVG
- Spinner replaces button text while loading
- Disabled state prevents click events
- Added aria-busy attribute for accessibility

Files modified: src/ui/Button.tsx (+28 lines)
--- End output ---

[OK] Dispatch completed: gemini/route-1711800000
```

## Routing Logic

The router matches file paths against patterns in order. First match wins.

| File Path | Matches Pattern | Routes To |
|-----------|----------------|-----------|
| `src/ui/Modal.tsx` | `src/ui/*` | gemini |
| `src/api/auth.ts` | `src/api/*` | codex |
| `src/auth/jwt.ts` | `src/auth/*` | claude |
| `package.json` | `*` (fallback) | codex |

## Advanced: Multi-Step Routing Workflow

Combine routing with batch dispatch for complex features:

```bash
# Feature touches multiple areas - dispatch each to its specialist
./scripts/dispatch.sh batch \
  "gemini:Add file upload UI in src/ui/FileUpload.tsx with drag-and-drop and preview" \
  "codex:Implement file upload API in src/api/upload.ts with multipart handling and S3 storage" \
  "claude:Review file upload security: validate file types, size limits, scan for malware patterns"
```

Each agent works on the part of the codebase where it excels, all running in parallel.
