# Example 1: Simple Single Dispatch

Dispatch a focused task to one specialist agent.

## Scenario

You need a security review of your auth module. Claude excels at this.

## Command

```bash
./scripts/dispatch.sh --approve-reads single claude \
  "Review src/auth/ for security vulnerabilities. Check for:
   - OWASP Top 10 issues
   - Input validation gaps
   - Token handling weaknesses
   Report each finding with severity, file:line, and fix recommendation."
```

## What Happens

1. `dispatch.sh` validates the request and creates a tracked Claude session
2. Claude runs as a full agent with file access (read-only via `--approve-reads`)
3. Claude reads files in `src/auth/`, analyzes, and produces findings
4. Output captured to `~/.multi-agent-dispatch/sessions/dispatch-*/stdout.log`
5. Session closed automatically

## Expected Output

```
[INFO] Dispatching to claude: dispatch-1711800000
[OK] Session created: dispatch-1711800000
[INFO] Executing in claude session=dispatch-1711800000

--- Output from claude (dispatch-1711800000) ---
## Security Review: src/auth/

### Critical
1. **SQL Injection** in `src/auth/login.ts:45`
   - User input passed directly to query without parameterization
   - Fix: Use parameterized queries

### High
2. **Weak Token Expiry** in `src/auth/tokens.ts:23`
   - JWT tokens expire after 30 days
   - Fix: Reduce to 1 hour with refresh token pattern

### Medium
3. **Missing Rate Limiting** in `src/auth/login.ts:12`
   - No rate limit on login attempts
   - Fix: Add rate limiter (e.g., 5 attempts per minute per IP)

### Summary
- 1 Critical, 1 High, 1 Medium findings
- Recommend addressing Critical immediately
--- End output ---

[OK] Dispatch completed: claude/dispatch-1711800000
```

## Variations

```bash
# Implementation task -> Codex (fast, focused)
./scripts/dispatch.sh single codex "Implement email notification service with retry logic"

# UI component -> Gemini (strong at frontend)
./scripts/dispatch.sh single gemini "Create a responsive data table component with sorting and pagination"

# Code refactoring -> Codex (efficient pattern matching)
./scripts/dispatch.sh single codex "Refactor src/utils/helpers.ts to use ES modules and remove dead code"
```
